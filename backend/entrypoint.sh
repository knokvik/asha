#!/bin/sh
set -eu

# Production databases are migrated and seeded before the API begins accepting traffic.
alembic upgrade head
python -m db.seed || true
exec uvicorn main:app --host 0.0.0.0 --port "${PORT:-8000}"
