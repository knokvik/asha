FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
RUN if [ -d "content_packs_source/geo" ] && [ -d "content_packs_source/l10n" ]; then \
        python scripts/build_content_packs.py --source content_packs_source/geo --language-source content_packs_source/l10n --output content_packs/map-india.zip ; \
    fi
RUN chmod +x entrypoint.sh

EXPOSE 8000

CMD ["./entrypoint.sh"]
