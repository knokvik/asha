import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:sqlite3/sqlite3.dart';

/// Reads PNG tiles from a local MBTiles file. There is no network URL.
class MbTilesTileProvider extends TileProvider {
  MbTilesTileProvider(this.database);

  final Database database;
  final Map<String, Uint8List> _cache = {};

  static final Uint8List blank = Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
    0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x78, 0xF1, 0xE0, 0x08,
    0x00, 0x05, 0x40, 0x02, 0x8D, 0xF0, 0x15, 0x7C, 0x6B, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,
    0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final key = '${coordinates.z}/${coordinates.x}/${coordinates.y}';
    final cached = _cache[key];
    if (cached != null) return MemoryImage(cached);
    final tmsY = (1 << coordinates.z) - 1 - coordinates.y;
    final rows = database.select(
      'SELECT tile_data FROM tiles WHERE zoom_level = ? AND tile_column = ? AND tile_row = ?',
      [coordinates.z, coordinates.x, tmsY],
    );
    final bytes = rows.isEmpty ? blank : rows.first['tile_data'] as Uint8List;
    _cache[key] = bytes;
    return MemoryImage(bytes);
  }

  @override
  void dispose() {
    database.dispose();
    super.dispose();
  }
}

/// Solid local tile used by widget tests. It never builds a URL.
class MemoryTileProvider extends TileProvider {
  MemoryTileProvider(this.bytes);

  final Uint8List bytes;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) => MemoryImage(bytes);
}
