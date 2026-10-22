"""Application configuration loaded from environment variables.

All secrets (SECRET_KEY, DATABASE_URL) should be injected via environment
or a .env file — never committed to source control.
"""
from functools import lru_cache
from typing import Literal
from urllib.parse import urlsplit

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # ── Application ──────────────────────────────────────────────────────────
    APP_NAME: str = "ASHA Digital Platform API"
    APP_VERSION: str = "0.1.0"
    DEBUG: bool = False
    ENVIRONMENT: str = "development"

    @field_validator("DEBUG", mode="before")
    @classmethod
    def parse_debug_environment(cls, value: object) -> object:
        """Accept conventional deployment labels without enabling debug mode."""
        if isinstance(value, str):
            normalized = value.strip().lower()
            if normalized in {"release", "production", "prod"}:
                return False
            if normalized in {"development", "dev"}:
                return True
        return value

    # ── Database ─────────────────────────────────────────────────────────────
    # For production: postgresql+asyncpg://user:pass@host/dbname
    # For tests: sqlite+aiosqlite:///./test.db
    DATABASE_URL: str = "sqlite+aiosqlite:///./asha_dev.db"
    DATABASE_SSL_REQUIRE: bool = False
    # Supabase's shared pooler is the IPv4-compatible option for Render.
    # Use "session" with the Supabase pooler URI on port 5432, or
    # "transaction" with the URI on port 6543.
    DATABASE_POOL_MODE: Literal["auto", "session", "transaction"] = "auto"
    DATABASE_CONNECT_TIMEOUT_SECONDS: float = 15.0

    # ── Security ─────────────────────────────────────────────────────────────
    SECRET_KEY: str = "CHANGE_ME_IN_PRODUCTION_USE_A_LONG_RANDOM_STRING"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30
    OFFLINE_CREDENTIAL_EXPIRE_DAYS: int = 7
    RESEND_API_KEY: str | None = None
    RESEND_FROM_EMAIL: str = "onboarding@resend.dev"

    # ── Rate limiting ─────────────────────────────────────────────────────────
    LOGIN_MAX_ATTEMPTS: int = 5
    LOGIN_LOCKOUT_MINUTES: int = 15

    # ── CORS ─────────────────────────────────────────────────────────────────
    ALLOWED_ORIGINS: list[str] = ["http://localhost:3000", "http://localhost:5173"]

    @field_validator("ALLOWED_ORIGINS", mode="before")
    @classmethod
    def parse_allowed_origins(cls, value: object) -> object:
        """Parse allowed origins from JSON arrays or comma-separated strings."""
        if isinstance(value, str):
            value = value.strip()
            if value.startswith("[") and value.endswith("]"):
                import json
                try:
                    return json.loads(value)
                except Exception:
                    pass
            return [origin.strip() for origin in value.split(",") if origin.strip()]
        return value

    # ── Redis / Celery ────────────────────────────────────────────────────────
    REDIS_URL: str = "redis://localhost:6379/0"
    CELERY_BROKER_URL: str = "redis://localhost:6379/0"
    CELERY_RESULT_BACKEND: str = "redis://localhost:6379/1"

    # ── Sync ─────────────────────────────────────────────────────────────────
    SYNC_BATCH_MAX_RECORDS: int = 500


@lru_cache
def get_settings() -> Settings:
    return Settings()


def get_async_database_url(database_url: str) -> str:
    """Return a SQLAlchemy URL with an async-compatible PostgreSQL driver."""
    url = database_url
    if url.startswith("postgres://"):
        url = url.replace("postgres://", "postgresql+asyncpg://", 1)
    elif url.startswith("postgresql://"):
        url = url.replace("postgresql://", "postgresql+asyncpg://", 1)

    # Automatically URL-encode password if it contains special characters like unencoded '@'
    if "://" in url and "@" in url:
        scheme, rest = url.split("://", 1)
        last_at = rest.rfind("@")
        user_info = rest[:last_at]
        host_info = rest[last_at + 1:]
        if ":" in user_info:
            user, raw_pwd = user_info.split(":", 1)
            import urllib.parse
            encoded_pwd = urllib.parse.quote_plus(urllib.parse.unquote_plus(raw_pwd))
            url = f"{scheme}://{user}:{encoded_pwd}@{host_info}"

    return url


def _is_transaction_pooler(settings: Settings, database_url: str) -> bool:
    """Return whether the configured database is Supavisor transaction mode."""
    if settings.DATABASE_POOL_MODE == "transaction":
        return True
    if settings.DATABASE_POOL_MODE == "session":
        return False

    try:
        return urlsplit(database_url).port == 6543
    except ValueError:
        return False


def get_database_connect_args(settings: Settings) -> dict[str, object]:
    """Build driver connection options without exposing credentials."""
    database_url = get_async_database_url(settings.DATABASE_URL)
    if not database_url.startswith("postgresql+asyncpg://"):
        return {}

    connect_args: dict[str, object] = {
        "timeout": settings.DATABASE_CONNECT_TIMEOUT_SECONDS,
    }
    if settings.DATABASE_SSL_REQUIRE:
        connect_args["ssl"] = "require"

    # Supavisor transaction mode (port 6543) does not support prepared
    # statements. asyncpg otherwise enables its statement cache by default.
    if _is_transaction_pooler(settings, database_url):
        connect_args["statement_cache_size"] = 0

    return connect_args


def get_database_engine_kwargs(settings: Settings) -> dict[str, object]:
    """Return shared SQLAlchemy engine options for API and Alembic.

    A transaction pooler hands a physical connection to a different client
    after each transaction, so SQLAlchemy's own connection pool must be
    disabled for that mode. Session mode keeps the normal application pool.
    """
    database_url = get_async_database_url(settings.DATABASE_URL)
    options: dict[str, object] = {
        "connect_args": get_database_connect_args(settings),
    }
    if _is_transaction_pooler(settings, database_url):
        from sqlalchemy.pool import NullPool

        options["poolclass"] = NullPool
    return options
