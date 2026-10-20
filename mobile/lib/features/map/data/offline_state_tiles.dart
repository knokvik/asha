import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// One state the worker can keep on the phone.
class IndiaStateRegion {
  const IndiaStateRegion({
    required this.name,
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  final String name;
  final double south;
  final double west;
  final double north;
  final double east;

  String get slug => name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}

class StateTilePlan {
  const StateTilePlan({
    required this.region,
    required this.minZoom,
    required this.maxZoom,
    required this.tiles,
  });

  final IndiaStateRegion region;
  final int minZoom;
  final int maxZoom;
  final List<TileCoordinates> tiles;

  /// PNG tiles at this zoom are about 12 KB each.
  int get estimatedBytes => tiles.length * 12 * 1024;

  String get estimatedLabel {
    final mb = estimatedBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';
  }
}

/// Null means the whole-India street map. A slug means that state's saved pack.
final selectedMapSlug = ValueNotifier<String?>(null);

const streetTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

const streetTileHeaders = {'User-Agent': 'com.nhm.asha.asha_platform'};

/// Keeps a state street map on disk. Zoom stops where the pack would pass 8 MB.
class OfflineStateTiles {
  OfflineStateTiles(this.root);

  final Directory root;

  static const hardCapBytes = 8 * 1024 * 1024;

  static Future<OfflineStateTiles> open() async {
    final docs = await getApplicationDocumentsDirectory();
    final root = Directory('${docs.path}/offline_maps');
    await root.create(recursive: true);
    return OfflineStateTiles(root);
  }

  Directory directoryFor(IndiaStateRegion region) => Directory('${root.path}/${region.slug}');

  Future<bool> isReady(IndiaStateRegion region) async {
    final dir = directoryFor(region);
    final marker = File('${dir.path}/done.json');
    if (!marker.existsSync()) return false;
    final blocked = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.png') && file.lengthSync() < 12000)
        .isNotEmpty;
    if (!blocked) return true;
    await dir.delete(recursive: true);
    if (selectedMapSlug.value == region.slug) await select(null);
    return false;
  }

  Future<void> loadSelection() async {
    final marker = File('${root.path}/selected.json');
    if (!marker.existsSync()) return;
    final json = jsonDecode(await marker.readAsString()) as Map<String, Object?>;
    selectedMapSlug.value = json['slug'] as String?;
  }

  Future<void> select(IndiaStateRegion? region) async {
    selectedMapSlug.value = region?.slug;
    await File('${root.path}/selected.json').writeAsString(jsonEncode({'slug': region?.slug}));
  }

  Future<StateTilePlan?> savedPlan(IndiaStateRegion region) async {
    final marker = File('${directoryFor(region).path}/done.json');
    if (!marker.existsSync()) return null;
    final json = jsonDecode(await marker.readAsString()) as Map<String, Object?>;
    return StateTilePlan(
      region: region,
      minZoom: json['minZoom'] as int,
      maxZoom: json['maxZoom'] as int,
      tiles: const [],
    );
  }

  static StateTilePlan planFor(IndiaStateRegion region) {
    var maxZoom = 12;
    var tiles = _tilesFor(region, 7, maxZoom);
    while (tiles.length * 12 * 1024 > hardCapBytes && maxZoom > 7) {
      maxZoom -= 1;
      tiles = _tilesFor(region, 7, maxZoom);
    }
    return StateTilePlan(region: region, minZoom: 7, maxZoom: maxZoom, tiles: tiles);
  }

  /// Downloads missing tiles. Returns how many files were written.
  Future<int> download(
    StateTilePlan plan, {
    required void Function(int done, int total) onProgress,
    required bool Function() isCancelled,
  }) async {
    final dir = directoryFor(plan.region);
    await dir.create(recursive: true);
    final client = http.Client();
    var written = 0;
    var present = 0;
    try {
      const batch = 2;
      for (var i = 0; i < plan.tiles.length; i += batch) {
        if (isCancelled()) break;
        final slice = plan.tiles.skip(i).take(batch);
        await Future.wait(slice.map((tile) async {
          final file = File('${dir.path}/${tile.z}/${tile.x}/${tile.y}.png');
          if (file.existsSync() && file.lengthSync() >= 12000) {
            present += 1;
            return;
          }
          await file.parent.create(recursive: true);
          final response = await client.get(
            Uri.parse('https://tile.openstreetmap.org/${tile.z}/${tile.x}/${tile.y}.png'),
            headers: streetTileHeaders,
          );
          final bytes = response.bodyBytes;
          final png = bytes.length >= 8 && bytes[0] == 0x89 && bytes[1] == 0x50;
          if (response.statusCode == 200 && png && bytes.length >= 12000) {
            await file.writeAsBytes(bytes, flush: true);
            written += 1;
          }
        }));
        onProgress(math.min(i + batch, plan.tiles.length), plan.tiles.length);
      }
    } finally {
      client.close();
    }
    if (!isCancelled() && written + present > 0) {
      await File('${dir.path}/done.json').writeAsString(
        jsonEncode({
          'name': plan.region.name,
          'minZoom': plan.minZoom,
          'maxZoom': plan.maxZoom,
          'tiles': plan.tiles.length,
        }),
      );
    }
    return written + present;
  }

  TileProvider providerFor(IndiaStateRegion region) => _FileTileProvider(directoryFor(region));

  static List<TileCoordinates> _tilesFor(IndiaStateRegion region, int minZoom, int maxZoom) {
    final tiles = <TileCoordinates>[];
    for (var z = minZoom; z <= maxZoom; z++) {
      final x0 = _x(region.west, z);
      final x1 = _x(region.east, z);
      final y0 = _y(region.north, z);
      final y1 = _y(region.south, z);
      for (var x = math.min(x0, x1); x <= math.max(x0, x1); x++) {
        for (var y = math.min(y0, y1); y <= math.max(y0, y1); y++) {
          tiles.add(TileCoordinates(x, y, z));
        }
      }
    }
    return tiles;
  }

  static int _x(double lon, int z) => ((lon + 180) / 360 * (1 << z)).floor();

  static int _y(double lat, int z) {
    final rad = lat * math.pi / 180;
    final merc = (1 - math.log(math.tan(rad) + 1 / math.cos(rad)) / math.pi) / 2;
    return (merc * (1 << z)).floor();
  }
}

class _FileTileProvider extends TileProvider {
  _FileTileProvider(this.directory);

  final Directory directory;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final file = File('${directory.path}/${coordinates.z}/${coordinates.x}/${coordinates.y}.png');
    if (file.existsSync() && file.lengthSync() >= 12000) return FileImage(file);
    return NetworkImage(
      'https://tile.openstreetmap.org/${coordinates.z}/${coordinates.x}/${coordinates.y}.png',
      headers: streetTileHeaders,
    );
  }
}
