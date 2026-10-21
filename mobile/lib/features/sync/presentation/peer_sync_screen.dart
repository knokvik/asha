import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/l10n/language_provider.dart';
import '../../../core/sync/nearby_peer_transport.dart';
import '../../../core/sync/peer_sync_service.dart';
import '../../../shared/shell/shell_copy.dart';

class PeerSyncScreen extends ConsumerStatefulWidget {
  const PeerSyncScreen({super.key});

  @override
  ConsumerState<PeerSyncScreen> createState() => _PeerSyncScreenState();
}

class _PeerSyncScreenState extends ConsumerState<PeerSyncScreen> {
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
    final lang = ref.read(languageProvider).languageCode;
    final packet = await _service.createContextPacket();
    if (!mounted) return;
    setState(() {
      _packet = packet;
      _message = packet == null
          ? shellText(lang, 'noSyncedContextYet')
          : shellText(lang, 'showCodeNearby');
    });
  }

  Future<void> _importPacket() async {
    final lang = ref.read(languageProvider).languageCode;
    final result = await _service.importContextPacket(
      _packetController.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _message = result.imported
          ? '${result.hotspotCount} ${shellText(lang, 'sharedSignalsReceived')}'
          : result.error;
    });
    if (result.imported) _packetController.clear();
  }

  Future<void> _scanPacket() async {
    final raw = await showDialog<String>(
      context: context,
      builder: (_) => const _PeerQrScannerDialog(),
    );
    if (!mounted || raw == null || raw.trim().isEmpty) return;
    _packetController.text = raw.trim();
    await _importPacket();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(shellText(lang, 'peerSyncTitle'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.people_alt_outlined),
              title: Text(shellText(lang, 'peerSyncHeader')),
              subtitle: Text(
                shellText(lang, 'peerSyncSub'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            shellText(lang, 'directNearbyExchange'),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
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
                  if (mounted) {
                    setState(() => _message = 'Nearby exchange stopped.');
                  }
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
            label: Text(shellText(lang, 'showSyncQr')),
          ),
          if (_packet != null) ...[
            const SizedBox(height: 12),
            Center(child: QrImageView(data: _packet!, size: 260)),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'This QR shares only aggregated area signals. It does not contain patient records.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Receive from another ASHA',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _scanPacket,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: Text(shellText(lang, 'scanPartnerQr')),
          ),
          const SizedBox(height: 8),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text(
              'Advanced fallback',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'Use only if the camera or Nearby exchange is unavailable.',
            ),
            children: [
              TextField(
                controller: _packetController,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Paste the private peer packet token here',
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _importPacket,
                  icon: const Icon(Icons.download_done_outlined),
                  label: const Text('Import pasted token'),
                ),
              ),
            ],
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(
              _message!,
              style: TextStyle(
                color: _message!.contains('updated')
                    ? Colors.green.shade800
                    : Colors.black87,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PeerQrScannerDialog extends StatefulWidget {
  const _PeerQrScannerDialog();

  @override
  State<_PeerQrScannerDialog> createState() => _PeerQrScannerDialogState();
}

class _PeerQrScannerDialogState extends State<_PeerQrScannerDialog> {
  var _handled = false;
  late final MobileScannerController _scanner = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: SizedBox(
        width: 360,
        height: 470,
        child: Column(
          children: [
            ListTile(
              title: const Text('Scan ASHA area-sync QR'),
              subtitle: const Text(
                'Point the camera at the other worker’s QR.',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MobileScanner(
                  controller: _scanner,
                  onDetect: (capture) {
                    if (_handled) return;
                    final value = capture.barcodes
                        .map((barcode) => barcode.rawValue)
                        .whereType<String>()
                        .firstWhere(
                          (value) => value.trim().isNotEmpty,
                          orElse: () => '',
                        );
                    if (value.isEmpty) return;
                    _handled = true;
                    Navigator.of(context).pop(value);
                  },
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Only aggregate area signals are imported. Patient records are not shared by peer sync.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
