"""FastAPI application factory with lifespan, CORS, and router registration.

Task 2.1 — Backend scaffold.
"""
from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from api.v1 import auth, incentives, integrations, referrals, reminders, rules, stock, sync
from core.config import get_settings

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):  # type: ignore[type-arg]
    """Application lifespan: startup → yield → shutdown."""
    # Startup: create all tables (dev/test mode only; prod uses Alembic)
    if settings.DEBUG:
        from db.session import get_engine  # noqa: PLC0415
        from models.db.base import Base  # noqa: PLC0415
        import models.db.models  # noqa: F401, PLC0415 — registers ORM models

        engine = await get_engine()
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)

    yield
    # Shutdown: nothing to clean up (connection pool handles itself)


def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.APP_NAME,
        version=settings.APP_VERSION,
        debug=settings.DEBUG,
        lifespan=lifespan,
    )

    # ── CORS ──────────────────────────────────────────────────────────────────
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.ALLOWED_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # ── Routers ────────────────────────────────────────────────────────────────
    app.include_router(auth.router, prefix="/api/v1")
    app.include_router(sync.router, prefix="/api/v1")
    app.include_router(rules.router, prefix="/api/v1")
    app.include_router(referrals.router, prefix="/api/v1")
    app.include_router(reminders.router, prefix="/api/v1")
    app.include_router(stock.router, prefix="/api/v1")
    app.include_router(incentives.router, prefix="/api/v1")
    app.include_router(integrations.router, prefix="/api/v1")

    @app.get("/healthz", tags=["meta"])
    async def health() -> dict[str, str]:
        return {"status": "ok", "version": settings.APP_VERSION}

    return app


app = create_app()
