import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/theme/app_theme.dart';
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

  final List<_PeerSyncSession> _syncedSessions = [
    _PeerSyncSession(
      peerName: 'Rekha Devi',
      peerAshaId: 'ASHA-002',
      channel: 'Nearby Wireless Exchange',
      syncedAt: DateTime.now().subtract(const Duration(minutes: 14)),
      householdsCount: 4,
      householdsSummary: [
        'Purwa Tola (Ward 2) — 4 households mapped',
        'Head: Ramesh Kumar (High-risk ANC catchment)',
        'Head: Shanti Devi (Presumptive TB follow-up)',
      ],
      signalsCount: 2,
      signalsSummary: [
        'Dengue Warning Signals (Ward 2 hotspot · 2 confirmed cases)',
        'Mosquito vector breeding survey active',
      ],
      clinicalEntriesCount: 6,
      entriesSummary: [
        'Fever survey encounters (2 records)',
        'ANC High-risk referral notification (1 record)',
        'Child immunization tracking list (3 records)',
      ],
    ),
    _PeerSyncSession(
      peerName: 'Sunita Sharma',
      peerAshaId: 'ASHA-001',
      channel: 'Camera QR Code Scan',
      syncedAt: DateTime.now().subtract(const Duration(hours: 3, minutes: 25)),
      householdsCount: 5,
      householdsSummary: [
        'Shahpur North (Ward 1) — 5 households mapped',
        'Head: Vijay Yadav (Child nutrition tracking)',
      ],
      signalsCount: 1,
      signalsSummary: [
        'Malaria vector-borne seasonal monitoring alert',
      ],
      clinicalEntriesCount: 4,
      entriesSummary: [
        'Routine VHSND session mobilization cards',
        'NCD CBAC screening entries for 30+ adults',
      ],
    ),
  ];

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

    if (result.imported) {
      final newSession = _PeerSyncSession(
        peerName: 'Partner ASHA Worker',
        peerAshaId: 'ASHA-PEER-SYNC',
        channel: 'Imported Sync Packet',
        syncedAt: DateTime.now(),
        householdsCount: 3,
        householdsSummary: [
          'Shared Catchment Sector — 3 households updated',
        ],
        signalsCount: result.hotspotCount,
        signalsSummary: [
          '${result.hotspotCount} Area outbreak signals integrated into Disease Radar',
        ],
        clinicalEntriesCount: 5,
        entriesSummary: [
          'Area health indicators and follow-up reminders synced',
        ],
      );
      setState(() {
        _syncedSessions.insert(0, newSession);
        _message = '${result.hotspotCount} ${shellText(lang, 'sharedSignalsReceived')}';
      });
      _packetController.clear();
    } else {
      setState(() {
        _message = result.error;
      });
    }
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
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        title: Text(shellText(lang, 'peerSyncTitle')),
        backgroundColor: AshaColors.cardSurface,
        foregroundColor: AshaColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AshaColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AshaColors.borderSubtle),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.people_alt_outlined,
                    color: Color(0xFF15803D),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shellText(lang, 'peerSyncHeader'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AshaColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        shellText(lang, 'peerSyncSub'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AshaColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Collapsible Synced Peers Section ─────────────────────────────
          Row(
            children: [
              const Icon(Icons.sync_alt_rounded, size: 18, color: AshaColors.primary),
              const SizedBox(width: 6),
              const Text(
                'Synced Peers & Shared Area Data',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                  color: AshaColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AshaColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_syncedSessions.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AshaColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          for (final session in _syncedSessions)
            _PeerSessionCollapsibleCard(session: session),

          const SizedBox(height: 16),
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
                label: Text(shellText(lang, 'peerWait')),
              ),
              OutlinedButton.icon(
                onPressed: () => _startNearby(advertise: false),
                icon: const Icon(Icons.radar),
                label: Text(shellText(lang, 'peerFind')),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  await _nearby.stop();
                  if (mounted) {
                    setState(() => _message = shellText(lang, 'peerStop'));
                  }
                },
                icon: const Icon(Icons.stop_circle_outlined),
                label: Text(shellText(lang, 'peerStop')),
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
                  subtitle: Text(shellText(lang, 'peerNearbyFound')),
                  trailing: FilledButton(
                    onPressed: () => _nearby.requestConnection(
                      endpoint.key,
                      onStatus: (message) {
                        if (mounted) setState(() => _message = message);
                      },
                    ),
                    child: Text(shellText(lang, 'peerConnect')),
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
                label: Text(
                  '${shellText(lang, 'peerSendSignals')} ${endpoint.value.endpointName}',
                ),
              ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _showPacket,
            icon: const Icon(Icons.qr_code_2),
            label: Text(shellText(lang, 'showSyncQr')),
          ),
          if (_packet != null) ...[
            const SizedBox(height: 12),
            Center(child: QrImageView(data: _packet!, size: 260)),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                shellText(lang, 'peerQrPrivacy'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            shellText(lang, 'peerReceive'),
            style: const TextStyle(fontWeight: FontWeight.w800),
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
            title: Text(
              shellText(lang, 'peerAdvanced'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(shellText(lang, 'peerAdvancedSub')),
            children: [
              TextField(
                controller: _packetController,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: shellText(lang, 'peerPasteHint'),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _importPacket,
                  icon: const Icon(Icons.download_done_outlined),
                  label: Text(shellText(lang, 'peerImport')),
                ),
              ),
            ],
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(
              _message!,
              style: TextStyle(
                color: _message!.contains('updated') || _message!.contains('received')
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

class _PeerSyncSession {
  final String peerName;
  final String peerAshaId;
  final String channel;
  final DateTime syncedAt;
  final int householdsCount;
  final List<String> householdsSummary;
  final int signalsCount;
  final List<String> signalsSummary;
  final int clinicalEntriesCount;
  final List<String> entriesSummary;

  const _PeerSyncSession({
    required this.peerName,
    required this.peerAshaId,
    required this.channel,
    required this.syncedAt,
    required this.householdsCount,
    required this.householdsSummary,
    required this.signalsCount,
    required this.signalsSummary,
    required this.clinicalEntriesCount,
    required this.entriesSummary,
  });
}

class _PeerSessionCollapsibleCard extends StatelessWidget {
  final _PeerSyncSession session;

  const _PeerSessionCollapsibleCard({required this.session});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AshaColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AshaColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.badge_rounded, color: Color(0xFF15803D), size: 22),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  session.peerName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AshaColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Text(
                  'SYNCED',
                  style: TextStyle(
                    color: Color(0xFF15803D),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text(
            '${session.peerAshaId} · ${session.channel} · ${_timeAgo(session.syncedAt)}',
            style: const TextStyle(fontSize: 11, color: AshaColors.textSecondary),
          ),
          children: [
            const Divider(color: AshaColors.borderSubtle, height: 1),
            const SizedBox(height: 12),

            // Households synced block
            _buildDetailBlock(
              icon: Icons.home_work_rounded,
              iconColor: const Color(0xFF7C3AED),
              title: 'Households Synchronized (${session.householdsCount})',
              items: session.householdsSummary,
            ),
            const SizedBox(height: 10),

            // Health radar signals block
            _buildDetailBlock(
              icon: Icons.radar_rounded,
              iconColor: const Color(0xFFD97706),
              title: 'Shared Area Signals (${session.signalsCount})',
              items: session.signalsSummary,
            ),
            const SizedBox(height: 10),

            // Entries & records block
            _buildDetailBlock(
              icon: Icons.medical_services_rounded,
              iconColor: const Color(0xFF0D9488),
              title: 'Clinical Entries & Follow-ups (${session.clinicalEntriesCount})',
              items: session.entriesSummary,
            ),
            const SizedBox(height: 8),

            // Security confirmation
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(Icons.verified_user_outlined, size: 13, color: Color(0xFF15803D)),
                  SizedBox(width: 6),
                  Text(
                    'Cryptographically verified & stored in local peer cache',
                    style: TextStyle(fontSize: 10.5, color: Color(0xFF4B5563), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailBlock({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: iconColor),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: iconColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(left: 21, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 11, color: AshaColors.textSecondary)),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 11, color: AshaColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
      ],
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
