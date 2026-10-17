"""Application configuration loaded from environment variables.

All secrets (SECRET_KEY, DATABASE_URL) should be injected via environment
or a .env file — never committed to source control.
"""
from functools import lru_cache

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # ── Application ──────────────────────────────────────────────────────────
    APP_NAME: str = "ASHA Digital Platform API"
    APP_VERSION: str = "0.1.0"
    DEBUG: bool = False

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

    # ── Security ─────────────────────────────────────────────────────────────
    SECRET_KEY: str = "CHANGE_ME_IN_PRODUCTION_USE_A_LONG_RANDOM_STRING"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30
    OFFLINE_CREDENTIAL_EXPIRE_DAYS: int = 7

    # ── Rate limiting ─────────────────────────────────────────────────────────
    LOGIN_MAX_ATTEMPTS: int = 5
    LOGIN_LOCKOUT_MINUTES: int = 15

    # ── CORS ─────────────────────────────────────────────────────────────────
    ALLOWED_ORIGINS: list[str] = ["http://localhost:3000", "http://localhost:5173"]

    # ── Redis / Celery ────────────────────────────────────────────────────────
    REDIS_URL: str = "redis://localhost:6379/0"
    CELERY_BROKER_URL: str = "redis://localhost:6379/0"
    CELERY_RESULT_BACKEND: str = "redis://localhost:6379/1"

    # ── Sync ─────────────────────────────────────────────────────────────────
    SYNC_BATCH_MAX_RECORDS: int = 500


@lru_cache
def get_settings() -> Settings:
    return Settings()
