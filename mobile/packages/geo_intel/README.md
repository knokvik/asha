# Offline maps and geo intelligence

The Map tab is an embedded `flutter_map`. Streets are local PNG tiles in
`assets/geo/pcmc.mbtiles`. Walking routes use `assets/geo/roads.json`. Nothing
on this screen opens another map app or a tile server.

## What ships

- `mobile/assets/geo/pcmc.mbtiles` — street raster, zooms 8–14, around the
  Pimpri-Chinchwad sample. Read by `MbTilesTileProvider` through `sqlite3`.
  There is no tile URL.
- `mobile/assets/geo/roads.json` — simplified walk graph for the same area.
- `mobile/assets/geo/facilities.geojson` — 40 synthetic facilities, one of every
  directory category, spread across W1–W8. The W3 diagnostic lab is pinned next
  to the cached fix so the NS1 ranking is obvious.
- Ward polygons and weekly counts are the same files the triage engine already
  uses: `packages/triage/lib/data/pack/wards.geojson` and `disease_counts.csv`.
  Ward lookup is `WardIndex` from that package. W3 dengue-like weeks 9–12 are
  1, 2, 3, 5. The outbreak threshold is 3, so week 12 paints W3 red and shows
  `Dengue module ACTIVE — 5 cases/week, 4-week trend ↑`.
- Households and referral pins are the small JSON files beside the tiles. They
  stand in for the on-device household and referral tables in this demo.

The cached fix is 18.64, 73.84, inside W3. The map opens there. It does not
call a geocoder.

## Deviations from the module brief

| Brief | This module |
| --- | --- |
| `maplibre_gl` and a MapLibre style | Embedded `flutter_map` and a local street MBTiles file. `maplibre_gl` was not added. |
| tilemaker on a Geofabrik Maharashtra `.osm.pbf` | `mobile/tool/generate_pcmc_mbtiles.py` draws the PCMC sample from a local Overpass extract. The full Maharashtra file is multi-gigabyte and is not in the app. |
| Live ABDM HFR and Overpass downloads | `mobile/tool/poi_import.py` accepts an HFR CSV (`--hfr`) and an Overpass JSON (`--overpass`). With neither file it writes the 40 synthetic POIs. They are marked `synthetic` and are not an official registry extract. |
| `geolocator` | The screen uses the shipped cached fix. It does not request location permission and does not call a platform location API. |
| `fl_chart` sparklines | A 12-bar row drawn in the ward sheet. |

A tap on a facility draws the walk on this map and can place a phone call.
The line is the route. It does not open Organic Maps, Google Maps, or OsmAnd.

The older Visit route screen (`/route-map`) is a separate Rampur hamlet map and
still requests OpenStreetMap tiles. This module does not.

## Regenerate the pack

From `mobile/`:

```sh
python3 tool/poi_import.py --out assets/geo/facilities.geojson
python3 tool/generate_pcmc_mbtiles.py
python3 tool/airplane_map_check.py
```

Optional live inputs, when you have them offline-cached already:

```sh
python3 tool/poi_import.py --hfr hfr.csv --overpass overpass.json --out assets/geo/facilities.geojson
```

A future street basemap, if disk allows:

1. Clip a Maharashtra `.osm.pbf` to `73.74,18.62,73.90,18.70` (do not download the full state extract onto this machine).
2. Run tilemaker at zooms 8–14 and keep the file under 40 MB.
3. Replace `assets/geo/pcmc.mbtiles`. The app does not care how the tiles were drawn.

## Tests

```sh
cd mobile/packages/geo_intel && dart test
cd mobile && flutter test test/features/map/geo_map_screen_test.dart
python3 mobile/tool/airplane_map_check.py
```

The widget test never opens a socket. It checks that the Map tab launches
`om://map` at 18.64, 73.84 with the facility pins and draws no search field.
The pure tests check W3, the NS1-versus-delivery order, the sparkline series,
the greedy visit order, and the Organic Maps navigate URI.
