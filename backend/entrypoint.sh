#!/bin/sh
set -eu

# Production databases are migrated before the API begins accepting traffic.
alembic upgrade head
exec uvicorn main:app --host 0.0.0.0 --port "${PORT:-8000}"
