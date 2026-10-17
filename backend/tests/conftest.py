"""pytest configuration for the backend test suite.

Uses an in-memory SQLite database via aiosqlite to avoid requiring PostgreSQL
during development and CI.
"""
from __future__ import annotations

import os

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

# Force isolated test settings BEFORE any app module is imported.  ``setdefault``
# is unsafe here: a developer's shell or deployment environment could redirect
# a test run to a production database.
os.environ["DATABASE_URL"] = "sqlite+aiosqlite:///:memory:"
os.environ["SECRET_KEY"] = "test-secret-key-do-not-use-in-prod"
os.environ["DEBUG"] = "true"

from db.session import get_db  # noqa: E402 — must be after env override
from main import app  # noqa: E402
from models.db.base import Base  # noqa: E402
import models.db.models  # noqa: F401, E402

TEST_DB_URL = "sqlite+aiosqlite:///:memory:"


@pytest_asyncio.fixture
async def test_engine():
    engine = create_async_engine(TEST_DB_URL, echo=False)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    await engine.dispose()


@pytest_asyncio.fixture
async def db_session(test_engine):
    """Yield a per-test async session rolled back after each test."""
    AsyncTestSession = async_sessionmaker(test_engine, class_=AsyncSession, expire_on_commit=False)
    async with AsyncTestSession() as session:
        yield session
        await session.rollback()


@pytest_asyncio.fixture
async def async_client(db_session):
    """Async HTTPX client with DB dependency overridden to test session."""

    async def _override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = _override_get_db
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        yield client
    app.dependency_overrides.clear()
