import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

import 'peer_sync_service.dart';

/// Android Nearby Connections transport for the privacy-preserving peer
/// context packet. QR/paste remains available on unsupported platforms.
class NearbyPeerTransport {
  static const _serviceId = 'org.asha.setu.area-context.v1';
  static const _strategy = Strategy.P2P_STAR;

  final PeerSyncService packetService;
  final String workerName;
  final Map<String, ConnectionInfo> _endpoints = {};

  NearbyPeerTransport({PeerSyncService? packetService, required this.workerName})
      : packetService = packetService ?? PeerSyncService();

  Map<String, ConnectionInfo> get endpoints => Map.unmodifiable(_endpoints);

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    final result = await <Permission>[
      Permission.locationWhenInUse,
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.nearbyWifiDevices,
    ].request();
    return result.values.every((status) => status.isGranted || status.isLimited);
  }

  Future<void> startAdvertising({required void Function(String) onStatus}) async {
    if (!await requestPermissions()) {
      onStatus('Nearby permissions are required for direct phone-to-phone sync.');
      return;
    }
    final started = await Nearby().startAdvertising(
      workerName,
      _strategy,
      serviceId: _serviceId,
      onConnectionInitiated: (id, info) => _accept(id, info, onStatus),
      onConnectionResult: (id, status) => onStatus('Peer connection: $status'),
      onDisconnected: (id) {
        _endpoints.remove(id);
        onStatus('Peer disconnected');
      },
    );
    onStatus(started ? 'Waiting for another ASHA to connect' : 'Could not start nearby advertising');
  }

  Future<void> startDiscovery({
    required void Function(String id, String name) onFound,
    required void Function(String) onStatus,
  }) async {
    if (!await requestPermissions()) {
      onStatus('Nearby permissions are required for direct phone-to-phone sync.');
      return;
    }
    final started = await Nearby().startDiscovery(
      workerName,
      _strategy,
      serviceId: _serviceId,
      onEndpointFound: (id, name, _) => onFound(id, name),
      onEndpointLost: (_) {},
    );
    onStatus(started ? 'Looking for nearby ASHA phones' : 'Could not start nearby discovery');
  }

  Future<void> requestConnection(String endpointId, {required void Function(String) onStatus}) async {
    await Nearby().requestConnection(
      workerName,
      endpointId,
      onConnectionInitiated: (id, info) => _accept(id, info, onStatus),
      onConnectionResult: (id, status) => onStatus('Peer connection: $status'),
      onDisconnected: (id) {
        _endpoints.remove(id);
        onStatus('Peer disconnected');
      },
    );
  }

  Future<void> sendContext(String endpointId, {required void Function(String) onStatus}) async {
    final packet = await packetService.createContextPacket();
    if (packet == null) {
      onStatus('No area context is available to share yet.');
      return;
    }
    final bytes = Uint8List.fromList(utf8.encode(packet));
    if (bytes.length > 30 * 1024) {
      onStatus('Area context is too large for a nearby packet; use QR fallback.');
      return;
    }
    await Nearby().sendBytesPayload(endpointId, bytes);
    onStatus('Area signals sent to nearby ASHA');
  }

  Future<void> stop() async {
    await Nearby().stopAllEndpoints();
    _endpoints.clear();
  }

  Future<void> _accept(String id, ConnectionInfo info, void Function(String) onStatus) async {
    _endpoints[id] = info;
    await Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endpointId, payload) async {
        if (payload.type != PayloadType.BYTES || payload.bytes == null) return;
        final result = await packetService.importContextPacket(
          utf8.decode(payload.bytes!),
        );
        onStatus(result.imported
            ? 'Received ${result.hotspotCount} area signals from nearby ASHA'
            : (result.error ?? 'Peer packet rejected'));
      },
      onPayloadTransferUpdate: (_, update) {
        if (update.status == PayloadStatus.FAILURE) onStatus('Peer packet transfer failed');
      },
    );
    onStatus('Connected to ${info.endpointName}');
  }
}
