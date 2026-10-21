from __future__ import annotations

from urllib.parse import urlsplit

from core.config import (  # noqa: E402
    Settings,
    get_async_database_url,
    get_database_connect_args,
    get_database_engine_kwargs,
)


def test_postgres_urls_use_asyncpg_and_encode_password_characters() -> None:
    url = "postgresql://postgres:pa@ssword@pooler.example.com:5432/postgres"

    normalized = get_async_database_url(url)

    assert normalized.startswith("postgresql+asyncpg://")
    assert urlsplit(normalized).password == "pa%40ssword"


def test_session_pooler_requires_ssl_and_has_connect_timeout() -> None:
    settings = Settings(
        DATABASE_URL=(
            "postgresql://postgres.project-ref:password@"
            "aws-0-ap-south-1.pooler.supabase.com:5432/postgres"
        ),
        DATABASE_SSL_REQUIRE=True,
        DATABASE_POOL_MODE="session",
    )

    args = get_database_connect_args(settings)

    assert args["ssl"] == "require"
    assert args["timeout"] == 15.0
    assert "statement_cache_size" not in args


def test_transaction_pooler_disables_prepared_statements_and_engine_pool() -> None:
    settings = Settings(
        DATABASE_URL=(
            "postgresql://postgres.project-ref:password@"
            "aws-0-ap-south-1.pooler.supabase.com:6543/postgres"
        ),
        DATABASE_SSL_REQUIRE=True,
        DATABASE_POOL_MODE="auto",
    )

    args = get_database_connect_args(settings)
    engine_kwargs = get_database_engine_kwargs(settings)

    assert args["statement_cache_size"] == 0
    assert engine_kwargs["poolclass"].__name__ == "NullPool"
