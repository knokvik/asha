FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY backend .
COPY mobile/assets/geo /source-map
COPY mobile/lib/core/l10n/arb /source-l10n
RUN python scripts/build_content_packs.py --source /source-map --language-source /source-l10n --output content_packs/map-india.zip
RUN chmod +x entrypoint.sh

EXPOSE 8000

CMD ["./entrypoint.sh"]
