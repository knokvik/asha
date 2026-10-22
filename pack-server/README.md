# ASHA Setu Pack Server

This is an independent Render web service for mobile Offline Packs. It does
not connect to PostgreSQL and does not contain patient data.

Render configuration:

- Root directory: `pack-server`
- Build command:
  `python build_packs.py --source ../mobile/assets/geo --language-source ../mobile/lib/core/l10n/arb --output content_packs && pip install -r requirements.txt`
- Start command:
  `uvicorn app:app --host 0.0.0.0 --port $PORT`

Routes:

- `GET /healthz`
- `GET /api/v1/packs`
- `GET /api/v1/packs/map-india`
- `GET /api/v1/packs/ui-hi` and the other supported language packs

The build creates ZIPs from repository sources. The API allowlists pack IDs,
returns SHA-256 metadata, and sends the checksum in `X-Content-SHA256` so the
mobile app can verify each download before installing it.
