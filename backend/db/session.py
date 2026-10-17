"""Async SQLAlchemy session factory.

Supports both PostgreSQL (production) and SQLite (tests) via the
DATABASE_URL setting.  Multi-tenant listener is installed on the async
session class after engine creation.
"""
from __future__ import annotations

from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from core.config import get_settings
from core.multi_tenant import install_multi_tenant_listener

_settings = get_settings()

# Engine is created lazily so tests can override DATABASE_URL before import.
_engine = create_async_engine(
    _settings.DATABASE_URL,
    echo=_settings.DEBUG,
    pool_pre_ping=True,
)

AsyncSessionLocal = async_sessionmaker(
    _engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

# Wire the multi-tenant ORM listener onto every async session.
install_multi_tenant_listener(AsyncSession)


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """FastAPI dependency: yields a per-request async DB session."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise


async def get_engine():
    """Return the async engine (used by Alembic and tests)."""
    return _engine
