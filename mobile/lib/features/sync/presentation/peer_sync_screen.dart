import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/sync/nearby_peer_transport.dart';
import '../../../core/sync/peer_sync_service.dart';

class PeerSyncScreen extends StatefulWidget {
  const PeerSyncScreen({super.key});

  @override
  State<PeerSyncScreen> createState() => _PeerSyncScreenState();
}

class _PeerSyncScreenState extends State<PeerSyncScreen> {
  final _packetController = TextEditingController();
  final _service = PeerSyncService();
  final _nearby = NearbyPeerTransport(workerName: 'ASHA Setu worker');
  final Map<String, String> _nearbyEndpoints = {};
  String? _packet;
  String? _message;

  @override
  void dispose() {
    _packetController.dispose();
    _nearby.stop();
    super.dispose();
  }

  Future<void> _startNearby({required bool advertise}) async {
    void status(String message) {
      if (mounted) setState(() => _message = message);
    }
    if (advertise) {
      await _nearby.startAdvertising(onStatus: status);
    } else {
      await _nearby.startDiscovery(
        onFound: (id, name) {
          if (mounted) setState(() => _nearbyEndpoints[id] = name);
        },
        onStatus: status,
      );
    }
  }

  Future<void> _showPacket() async {
    final packet = await _service.createContextPacket();
    if (!mounted) return;
    setState(() {
      _packet = packet;
      _message = packet == null
          ? 'No synced area context is available yet.'
          : 'Show this code to another ASHA worker nearby.';
    });
  }

  Future<void> _importPacket() async {
    final result = await _service.importContextPacket(_packetController.text.trim());
    if (!mounted) return;
    setState(() {
      _message = result.imported
          ? '${result.hotspotCount} shared area signals received. Disease radar and adaptive triage are updated.'
          : result.error;
    });
    if (result.imported) _packetController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Peer area sync')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: ListTile(
              leading: Icon(Icons.people_alt_outlined),
              title: Text('Share area context without a tower'),
              subtitle: Text('Only aggregate disease signals are exchanged. Patient records never leave this phone through peer sync.'),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Direct nearby exchange', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _startNearby(advertise: true),
                icon: const Icon(Icons.wifi_tethering),
                label: const Text('Wait for ASHA'),
              ),
              OutlinedButton.icon(
                onPressed: () => _startNearby(advertise: false),
                icon: const Icon(Icons.radar),
                label: const Text('Find nearby ASHAs'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  await _nearby.stop();
                  if (mounted) setState(() => _message = 'Nearby exchange stopped.');
                },
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('Stop'),
              ),
            ],
          ),
          if (_nearbyEndpoints.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final endpoint in _nearbyEndpoints.entries)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.phone_android),
                  title: Text(endpoint.value),
                  subtitle: const Text('Nearby phone found'),
                  trailing: FilledButton(
                    onPressed: () => _nearby.requestConnection(
                      endpoint.key,
                      onStatus: (message) {
                        if (mounted) setState(() => _message = message);
                      },
                    ),
                    child: const Text('Connect'),
                  ),
                ),
              ),
          ],
          if (_nearby.endpoints.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final endpoint in _nearby.endpoints.entries)
              FilledButton.icon(
                onPressed: () => _nearby.sendContext(
                  endpoint.key,
                  onStatus: (message) {
                    if (mounted) setState(() => _message = message);
                  },
                ),
                icon: const Icon(Icons.send),
                label: Text('Send signals to ${endpoint.value.endpointName}'),
              ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _showPacket,
            icon: const Icon(Icons.qr_code_2),
            label: const Text('Show my area signals'),
          ),
          if (_packet != null) ...[
            const SizedBox(height: 12),
            Center(child: QrImageView(data: _packet!, size: 260)),
            SelectableText(_packet!, maxLines: 3),
          ],
          const SizedBox(height: 20),
          const Text('Receive from another ASHA', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          TextField(
            controller: _packetController,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Paste the peer packet text here',
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _importPacket,
            icon: const Icon(Icons.download_done_outlined),
            label: const Text('Import shared signals'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!, style: TextStyle(color: _message!.contains('updated') ? Colors.green.shade800 : Colors.black87)),
          ],
        ],
      ),
    );
  }
}
