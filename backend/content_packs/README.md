# Published content packs

This directory holds generated artifacts only; ZIP files are intentionally
ignored by Git. Source data remains in the repository under `mobile/`, where
it can be reviewed and updated without accidentally adding it to the APK.

## Delivery flow

1. The Render or Docker build runs `scripts/build_content_packs.py`.
2. The script allowlists the eight all-India map files and writes
   `map-india.zip`; it also creates one `ui-<language>.zip` archive for every
   non-English UI language catalog.
3. `GET /api/v1/packs` lists only published packs and their size, version and
   SHA-256 checksum. `GET /api/v1/packs/{id}` serves only a known archive.
4. The app downloads a selected archive to a staging directory in private app
   storage, checks the SHA-256 response header, validates every archive path,
   then atomically installs it under `content-packs/<pack-id>`.
5. Removing a pack removes only that private content directory. Clinical data,
   offline records and credentials are never in a pack and are not removed.

Render's generated ZIPs are suitable for the current small map payload. When
map packs grow or download traffic rises, publish the same immutable ZIPs to a
versioned Supabase Storage or object-storage bucket and keep this API as the
allowlisted manifest/signing layer; the mobile integrity and installation flow
does not change.
