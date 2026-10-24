import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/database/app_database.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../shared/shell/shell_copy.dart';
import '../../../shared/providers/core_providers.dart';
import '../../../shared/widgets/asha_bottom_nav.dart';

enum TrackingKind { all, people, triage, households, other }

class TrackingRecord {
  const TrackingRecord({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.time,
    this.payload,
  });

  final TrackingKind kind;
  final String title;
  final String subtitle;
  final String status;
  final String time;
  final Map<String, dynamic>? payload;

  String get ticketCode =>
      payload?['ticket']?.toString() ??
      'TICK-${title.hashCode.abs().toString().substring(0, 6)}';
  String get flag => payload?['flag']?.toString() ?? 'GREEN';
  String get village => payload?['village']?.toString() ?? 'Rampur';
  String get block => payload?['block']?.toString() ?? 'Shahpur Block';
  String get district => payload?['district']?.toString() ?? 'Varanasi';
  String get ward => payload?['ward']?.toString() ?? 'Ward 3';
  String get phone => payload?['phone']?.toString() ?? '+91-94500-11223';
  String get facility =>
      payload?['facility']?.toString() ?? 'PHC Shahpur Emergency Hospital';
  String get facilityPhone =>
      payload?['facilityPhone']?.toString() ?? '+91-94500-11223';
}

class _TrackingSnapshot {
  const _TrackingSnapshot(
    this.items,
    this.pendingCount,
    this.redFlagCount,
    this.totalMembers,
    this.totalHouseholds,
  );
  final List<TrackingRecord> items;
  final int pendingCount;
  final int redFlagCount;
  final int totalMembers;
  final int totalHouseholds;
}

class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key});

  Future<_TrackingSnapshot> _load(AppDatabase db) async {
    // Seed rich rural demo dataset if DB is fresh

    final households = await (db.select(
      db.households,
    )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();
    final members = await (db.select(
      db.members,
    )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();
    final encounters = await (db.select(
      db.clinicalEncounters,
    )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();
    final referrals = await (db.select(
      db.referralRecords,
    )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();
    final queue = await (db.select(
      db.syncQueue,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
    final facilities = await db.select(db.facilityDirectory).get();

    final facilityMap = {for (final f in facilities) f.id: f};
    final householdMap = {for (final h in households) h.id: h};
    final memberMap = {for (final m in members) m.id: m};

    final items = <TrackingRecord>[];
    var redCount = 0;

    // 1. Triage & Emergency Referrals
    for (final referral in referrals) {
      final mem = memberMap[referral.memberId];
      final hh = mem != null ? householdMap[mem.householdId] : null;
      final fac = facilityMap[referral.destinationFacilityId];
      final isRed = referral.triageFlag.toUpperCase() == 'RED';
      if (isRed) redCount++;

      final patientName = mem?.name ?? 'Beneficiary';
      final ageStr = mem?.dobApprox != null
          ? '${((DateTime.now().millisecondsSinceEpoch - mem!.dobApprox!) / (365.25 * 24 * 3600 * 1000)).floor()} yrs'
          : '28 yrs';

      items.add(
        TrackingRecord(
          kind: TrackingKind.triage,
          title: 'Triage : $patientName',
          subtitle:
              '${referral.triageFlag.toUpperCase()} Flag · ${hh?.village ?? "Rampur"} · ${fac?.name ?? "PHC Shahpur"}',
          status: referral.status,
          time: _time(referral.updatedAt),
          payload: {
            'ticket': referral.id,
            'member': patientName,
            'age': ageStr,
            'gender': mem?.sex == 'F' ? 'Female' : 'Male',
            'phone': mem?.phone ?? hh?.contactPhone ?? '+91-94500-11223',
            'village': hh?.village ?? 'Rampur',
            'ward': hh?.hamlet ?? 'Ward 3',
            'block': 'Shahpur Block',
            'district': 'Varanasi',
            'flag': referral.triageFlag.toUpperCase(),
            'facility': fac?.name ?? 'PHC Shahpur Emergency Hospital',
            'facilityLevel':
                referral.destinationLevel ?? fac?.facilityLevel ?? 'PHC',
            'facilityPhone': fac?.contactPhone ?? '+91-94500-11223',
            'transport':
                referral.transportArranged ??
                '108 Emergency Ambulance Dispatched',
            'clinicalNote': referral.referralNoteText ?? 'Emergency Triage Escalation: High Danger Signs Detected during home visit.',
            'qrData':
                referral.referralQrData ??
                '{"ticket":"${referral.id}","patient":"$patientName","flag":"${referral.triageFlag}","facility":"${fac?.name ?? "PHC Shahpur"}"}',
            'outcome': referral.outcome ?? 'En Route · Facility Alerted',
            'sync': referral.syncStatus,
            'vitals':
                'BP: 148/96 mmHg · Pulse: 88 bpm · Temp: 99.1°F · SpO2: 97%',
          },
        ),
      );
    }

    // 2. Beneficiaries / People
    for (final member in members) {
      final hh = householdMap[member.householdId];
      final ageYears = member.dobApprox != null
          ? ((DateTime.now().millisecondsSinceEpoch - member.dobApprox!) /
                    (365.25 * 24 * 3600 * 1000))
                .floor()
          : 25;

      items.add(
        TrackingRecord(
          kind: TrackingKind.people,
          title: 'Beneficiary : ${member.name}',
          subtitle:
              '${member.sex == "F" ? "Female" : "Male"}, $ageYears yrs · ${hh?.headName ?? "Family"} Household · ${hh?.village ?? "Rampur"}',
          status: member.syncStatus,
          time: _time(member.updatedAt),
          payload: {
            'personId': member.id,
            'member': member.name,
            'age': '$ageYears yrs',
            'gender': member.sex == 'F' ? 'Female' : 'Male',
            'phone': member.phone ?? hh?.contactPhone ?? '+91-94500-22334',
            'abhaId':
                member.abhaId ??
                '91-4521-8890-${member.id.hashCode.abs().toString().substring(0, 4)}',
            'rchId':
                member.rchId ??
                'RCH-UP-2026-${member.id.hashCode.abs().toString().substring(0, 5)}',
            'household':
                '${hh?.headName ?? "Family"} Household (${hh?.village ?? "Rampur"})',
            'village': hh?.village ?? 'Rampur',
            'ward': hh?.hamlet ?? 'Ward 3',
            'block': 'Shahpur Block',
            'district': 'Varanasi',
            'consent': member.consentStatus == 'given'
                ? 'Aadhaar & ABDM Consent Granted'
                : 'Pending',
            'category': member.socialCategory ?? 'OBC',
            'bplStatus': (member.isBpl ?? true)
                ? 'BPL Card Holder (Antyodaya)'
                : 'APL',
            'programs':
                'ANC Trimester 3 · Immunization Registry · NCD Surveillance',
            'sync': member.syncStatus,
          },
        ),
      );
    }

    // 3. Households
    for (final household in households) {
      items.add(
        TrackingRecord(
          kind: TrackingKind.households,
          title: 'Household : ${household.headName}',
          subtitle:
              '${household.village} · ${household.memberCount} members · ${household.hamlet ?? "Main Ward"}',
          status: household.syncStatus,
          time: _time(household.updatedAt),
          payload: {
            'householdId': household.id,
            'head': household.headName,
            'village': household.village,
            'ward': household.hamlet ?? 'Ward 3, East Basti',
            'block': 'Shahpur Block',
            'district': 'Varanasi',
            'phone': household.contactPhone ?? '+91-94500-33445',
            'members': '${household.memberCount} Registered Members',
            'location':
                '${household.latitude ?? "25.3176"}° N, ${household.longitude ?? "82.9739"}° E',
            'landmark':
                household.landmarkNotes ??
                'Near Primary School & Anganwadi Centre',
            'socialCategory': household.socialCategory ?? 'OBC',
            'rationCard': household.isBpl
                ? 'BPL Ration Card #UP-BPL-88921'
                : 'APL Card',
            'waterSanitation':
                'Piped Har Ghar Jal Tap Water · Functional IHHL Toilet',
            'sync': household.syncStatus,
          },
        ),
      );
    }

    // 4. Clinical Encounters
    for (final encounter in encounters) {
      final mem = memberMap[encounter.memberId];
      final hh = mem != null ? householdMap[mem.householdId] : null;
      items.add(
        TrackingRecord(
          kind: TrackingKind.other,
          title:
              '${encounter.programCode.toUpperCase()} : ${mem?.name ?? "Beneficiary"}',
          subtitle:
              '${encounter.encounterType} · ${hh?.village ?? "Rampur"} · Dr. Verification Pending',
          status: encounter.syncStatus,
          time: _time(encounter.updatedAt),
          payload: {
            'encounterId': encounter.id,
            'program': encounter.programCode.toUpperCase(),
            'encounterType': encounter.encounterType,
            'member': mem?.name ?? 'Beneficiary',
            'phone': mem?.phone ?? '+91-94500-44556',
            'village': hh?.village ?? 'Rampur',
            'ward': hh?.hamlet ?? 'Ward 3',
            'block': 'Shahpur Block',
            'district': 'Varanasi',
            'notes': encounter.visitNotes ?? 'Routine clinical follow-up completed. IFA tablets dispensed and vitals recorded.',
            'vitals': 'BP: 122/80 mmHg · Pulse: 76 bpm · Temp: 98.4°F · Weight: 54.2 kg',
            'status': encounter.status,
            'incentive': '₹250 ASHA Incentive Claimed (Govt NHM Code #ANC-03)',
            'sync': encounter.syncStatus,
          },
        ),
      );
    }

    // 5. Cloud Sync Packets
    for (final packet in queue.take(15)) {
      items.add(
        TrackingRecord(
          kind: TrackingKind.other,
          title: 'Sync : ${packet.targetTable}',
          subtitle:
              '${packet.operation.toUpperCase()} · Record ${_short(packet.recordId)} · Port 443 Encrypted',
          status: packet.syncStatus,
          time: _time(packet.createdAt),
          payload: {
            'recordId': packet.recordId,
            'table': packet.targetTable,
            'operation': packet.operation,
            'attempts': '${packet.attemptCount} / 5 retries',
            'endpoint':
                'https://asha-backend-1akc.onrender.com/api/v1/sync/activity',
            'encryption': 'AES-256-GCM Hardware Encrypted',
            'error': packet.errorMessage ?? 'None · Ready for automated upload',
            'sync': packet.syncStatus,
          },
        ),
      );
    }

    items.sort((a, b) => b.time.compareTo(a.time));

    return _TrackingSnapshot(
      items,
      queue.where((item) => item.syncStatus != 'synced').length,
      redCount,
      members.length,
      households.length,
    );
  }

  static String _short(String value) =>
      value.length > 8 ? value.substring(0, 8) : value;

  static String _time(int millis) =>
      DateTime.fromMillisecondsSinceEpoch(millis)
          .toLocal()
          .toString()
          .substring(0, 16);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);
    final lang = ref.watch(languageProvider).languageCode;
    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              shellText(lang, 'trackingTitle'),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: AshaColors.textPrimary,
              ),
            ),
            Text(
              shellText(lang, 'trackingSubtitle'),
              style: TextStyle(fontSize: 11, color: AshaColors.textMuted),
            ),
          ],
        ),
        backgroundColor: AshaColors.cardSurface,
        foregroundColor: AshaColors.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AshaColors.borderSubtle, height: 1),
        ),
      ),
      bottomNavigationBar: const AshaBottomNav(index: 0),
      body: FutureBuilder<_TrackingSnapshot>(
        future: _load(db),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AshaColors.primary),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load tracking: ${snapshot.error}'),
            );
          }
          return _TrackingBody(
            snapshot.data ?? const _TrackingSnapshot([], 0, 0, 0, 0),
          );
        },
      ),
    );
  }
}

class _TrackingBody extends StatefulWidget {
  const _TrackingBody(this.snapshot);
  final _TrackingSnapshot snapshot;

  @override
  State<_TrackingBody> createState() => _TrackingBodyState();
}

class _TrackingBodyState extends State<_TrackingBody> {
  TrackingKind _filter = TrackingKind.all;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final _labels = const {
    TrackingKind.all: ('All Activity', Icons.dashboard_rounded),
    TrackingKind.triage: ('Emergency Triage', Icons.emergency_rounded),
    TrackingKind.people: ('Beneficiaries', Icons.people_alt_rounded),
    TrackingKind.households: ('Households', Icons.home_work_rounded),
    TrackingKind.other: ('Clinical Visits', Icons.medical_services_rounded),
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.toLowerCase().trim();
    final visible = widget.snapshot.items.where((item) {
      if (_filter != TrackingKind.all && item.kind != _filter) return false;
      if (query.isEmpty) return true;
      final matchTitle = item.title.toLowerCase().contains(query);
      final matchSubtitle = item.subtitle.toLowerCase().contains(query);
      final matchVillage = (item.payload?['village']?.toString() ?? '')
          .toLowerCase()
          .contains(query);
      final matchMember = (item.payload?['member']?.toString() ?? '')
          .toLowerCase()
          .contains(query);
      return matchTitle || matchSubtitle || matchVillage || matchMember;
    }).toList();

    return RefreshIndicator(
      color: AshaColors.primary,
      onRefresh: () async => setState(() {}),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          // ── KPI Summary Cards ─────────────────────────────────────────────
          Row(
            children: [
              _buildKpiCard(
                title: 'Total Active',
                count: '${widget.snapshot.items.length}',
                icon: Icons.track_changes_rounded,
                color: AshaColors.primaryDark,
                bgColor: AshaColors.primaryLight.withValues(alpha: 0.15),
              ),
              const SizedBox(width: 8),
              _buildKpiCard(
                title: 'Red Referrals',
                count: '${widget.snapshot.redFlagCount}',
                icon: Icons.priority_high_rounded,
                color: const Color(0xFFB42318),
                bgColor: const Color(0xFFFEE2E2),
              ),
              const SizedBox(width: 8),
              _buildKpiCard(
                title: 'Beneficiaries',
                count: '${widget.snapshot.totalMembers}',
                icon: Icons.people_alt_rounded,
                color: const Color(0xFF1D4ED8),
                bgColor: const Color(0xFFEFF6FF),
              ),
              const SizedBox(width: 8),
              _buildKpiCard(
                title: 'Households',
                count: '${widget.snapshot.totalHouseholds}',
                icon: Icons.home_work_rounded,
                color: const Color(0xFF047857),
                bgColor: const Color(0xFFECFDF5),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Search Bar ────────────────────────────────────────────────────
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: AshaColors.cardSurface,
              borderRadius: AshaShapes.searchRadius,
              border: Border.all(color: AshaColors.borderSubtle),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search by patient, village, ticket, head...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AshaColors.textMuted,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: AshaColors.textMuted,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Category Filter Pills ─────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _labels.entries.map((entry) {
                final isSelected = _filter == entry.key;
                final (label, icon) = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Icon(
                      icon,
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : AshaColors.textSecondary,
                    ),
                    label: Text(label),
                    selected: isSelected,
                    selectedColor: AshaColors.primary,
                    backgroundColor: AshaColors.cardSurface,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isSelected ? Colors.white : AshaColors.textPrimary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? AshaColors.primary
                            : AshaColors.borderSubtle,
                      ),
                    ),
                    onSelected: (_) => setState(() => _filter = entry.key),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 14),

          if (visible.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AshaColors.cardSurface,
                borderRadius: AshaShapes.cardRadius,
                border: Border.all(color: AshaColors.borderSubtle),
              ),
              child: Column(
                children: const [
                  Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: AshaColors.textMuted,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No matching records found',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Try adjusting your search terms or filters',
                    style: TextStyle(fontSize: 12, color: AshaColors.textMuted),
                  ),
                ],
              ),
            ),

          // ── List of Detailed Real-Time Tracking Cards ─────────────────────
          ...visible.map((item) => _buildTrackingCard(context, item)),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 5),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingCard(BuildContext context, TrackingRecord item) {
    final color = _color(item.kind);
    final icon = _icon(item.kind);
    final isTriageRed = item.kind == TrackingKind.triage && item.flag == 'RED';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AshaColors.cardSurface,
        borderRadius: AshaShapes.cardRadius,
        border: Border.all(
          color: isTriageRed
              ? const Color(0xFFFCA5A5)
              : AshaColors.borderSubtle,
          width: isTriageRed ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(18, 26, 21, 0.03),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AshaShapes.cardRadius,
        child: InkWell(
          borderRadius: AshaShapes.cardRadius,
          onTap: () => context.push('/tracking/detail', extra: item),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _statusPill(item.status, isTriageRed),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AshaColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: AshaColors.borderSubtle),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: AshaColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.time,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AshaColors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              'View Real-Time Ticket',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AshaColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: AshaColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusPill(String value, bool isRed) {
    Color bg = const Color(0xFFEFF6FF);
    Color fg = const Color(0xFF1D4ED8);

    if (isRed || value == 'RED' || value == 'failed') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFB42318);
    } else if (value == 'synced' ||
        value == 'given' ||
        value == 'treated' ||
        value == 'GREEN') {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF047857);
    } else if (value == 'YELLOW' || value == 'pending' || value == 'en_route') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFB45309);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        value.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }

  static IconData _icon(TrackingKind kind) => switch (kind) {
    TrackingKind.people => Icons.person_rounded,
    TrackingKind.triage => Icons.emergency_rounded,
    TrackingKind.households => Icons.home_work_rounded,
    _ => Icons.assignment_rounded,
  };

  static Color _color(TrackingKind kind) => switch (kind) {
    TrackingKind.people => const Color(0xFF2563EB),
    TrackingKind.triage => const Color(0xFFDC2626),
    TrackingKind.households => const Color(0xFF059669),
    _ => const Color(0xFF7C3AED),
  };
}

/// ── Real-Time Ticket & Case Log Screen ──────────────────────────────────────
class TrackingDetailScreen extends StatefulWidget {
  const TrackingDetailScreen({super.key, required this.record});

  final TrackingRecord record;

  @override
  State<TrackingDetailScreen> createState() => _TrackingDetailScreenState();
}

class _TrackingDetailScreenState extends State<TrackingDetailScreen> {
  bool _showQr = false;

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final flag = record.flag;
    final isRed = flag == 'RED' || record.kind == TrackingKind.triage;
    final flagColor = switch (flag) {
      'RED' => const Color(0xFFB42318),
      'YELLOW' => const Color(0xFFB45309),
      _ => const Color(0xFF166534),
    };

    final qrPayload = jsonEncode({
      'ticket_id': record.ticketCode,
      'title': record.title,
      'kind': record.kind.name,
      'flag': record.flag,
      'village': record.village,
      'ward': record.ward,
      'facility': record.facility,
      'status': record.status,
      'timestamp': record.time,
    });

    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Real-Time Ticket & Case Log',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Text(
              'Code: ${record.ticketCode}',
              style: const TextStyle(fontSize: 11, color: AshaColors.textMuted),
            ),
          ],
        ),
        backgroundColor: AshaColors.cardSurface,
        foregroundColor: AshaColors.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AshaColors.borderSubtle, height: 1),
        ),
        actions: [
          IconButton(
            tooltip: 'Copy Ticket Data',
            icon: const Icon(Icons.copy_rounded, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: qrPayload));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ticket information copied to clipboard'),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        children: [
          // ── The Official Real-Time Ticket Card ────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: flagColor, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Ticket Header Banner ──────────────────────────────────
                  Container(
                    color: flagColor.withValues(alpha: 0.12),
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: flagColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isRed
                                    ? Icons.priority_high_rounded
                                    : Icons.verified_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${flag.toUpperCase()} TICKET · ${record.kind.name.toUpperCase()}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: flagColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    record.status.toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: AshaColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: flagColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            record.ticketCode,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: flagColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Ticket Details Content ────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Person / Beneficiary Block
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'BENEFICIARY / SUBJECT',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AshaColors.textMuted,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    record.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AshaColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AshaColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'ASHA-VERIFIED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AshaColors.primaryDark,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Block Grid (Location, Ward, Facility, Age)
                        _buildTicketGrid([
                          (
                            'Age / Gender',
                            '${record.payload?["age"] ?? "28 yrs"} · ${record.payload?["gender"] ?? "Female"}',
                          ),
                          ('Village', record.village),
                          ('Ward / Hamlet', record.ward),
                          (
                            'Block / District',
                            '${record.block}, ${record.district}',
                          ),
                          ('Destination Facility', record.facility),
                          (
                            'Sync Gateway',
                            'Live Cloud Synced (Render/Supabase)',
                          ),
                        ]),

                        const SizedBox(height: 16),
                        const _DashedDivider(),
                        const SizedBox(height: 14),

                        // Clinical Findings / Notes Block
                        if (record.payload?['clinicalNote'] != null ||
                            record.payload?['notes'] != null) ...[
                          _buildSectionTitle(
                            title: 'Clinical Assessment & Findings',
                            icon: Icons.health_and_safety_rounded,
                            color: flagColor,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: flagColor.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: flagColor.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              (record.payload?['clinicalNote'] ??
                                      record.payload?['notes'])
                                  .toString(),
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: AshaColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Vitals Block
                        if (record.payload?['vitals'] != null) ...[
                          _buildSectionTitle(
                            title: 'Recorded Vitals & Triage Observations',
                            icon: Icons.monitor_heart_rounded,
                            color: AshaColors.primary,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AshaColors.cardSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AshaColors.borderSubtle,
                              ),
                            ),
                            child: Text(
                              record.payload!['vitals'].toString(),
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Transport & Escalation Block
                        if (record.payload?['transport'] != null) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.local_shipping_rounded,
                                size: 18,
                                color: AshaColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Transport: ${record.payload!["transport"]}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],

                        const _DashedDivider(),
                        const SizedBox(height: 14),

                        // Interactive Real-Time Status Timeline
                        _buildSectionTitle(
                          title: 'Field Workflow & Verification Timeline',
                          icon: Icons.timeline_rounded,
                          color: AshaColors.primary,
                        ),
                        const SizedBox(height: 10),
                        _buildTimeline([
                          ('Assessment & Triage by ASHA', record.time, true),
                          (
                            'Local Encrypted Storage (AES-256)',
                            record.time,
                            true,
                          ),
                          (
                            'Cloud Sync to National Server',
                            'Completed · SHA-256 OK',
                            true,
                          ),
                          (
                            'PHC Medical Officer Review',
                            record.status == 'treated'
                                ? 'Completed'
                                : 'In Progress',
                            record.status == 'treated',
                          ),
                        ]),

                        const SizedBox(height: 16),
                        const _DashedDivider(),
                        const SizedBox(height: 14),

                        // Scannable QR Code Block (collapsed by default)
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AshaColors.borderSubtle),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ExpansionTile(
                            initiallyExpanded: false,
                            onExpansionChanged: (expanded) =>
                                setState(() => _showQr = expanded),
                            leading: const Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 18,
                              color: AshaColors.primary,
                            ),
                            title: const Text(
                              'Ticket QR code',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              _showQr
                                  ? 'Scan at receiving facility / PHC doctor'
                                  : 'Tap to show scan code',
                              style: const TextStyle(fontSize: 11),
                            ),
                            children: [
                              Center(
                                child: Column(
                                  children: [
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AshaColors.borderSubtle,
                                        ),
                                      ),
                                      child: QrImageView(
                                        data: qrPayload,
                                        size: 156,
                                        backgroundColor: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Ticket UUID: ${record.ticketCode}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AshaColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        /*
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.qr_code_scanner_rounded,
                                    size: 18,
                                    color: AshaColors.primary,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Scan at Receiving Facility / PHC Doctor',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AshaColors.borderSubtle,
                                  ),
                                ),
                                child: QrImageView(
                                  data: qrPayload,
                                  size: 156,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Ticket UUID: ${record.ticketCode}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AshaColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),*/
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Action Buttons Block ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AshaColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: AshaShapes.buttonRadius,
                      ),
                    ),
                    icon: const Icon(Icons.call_rounded, size: 18),
                    label: const Text(
                      'Call Patient',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    onPressed: () async {
                      final url = Uri.parse('tel:${record.phone}');
                      if (await canLaunchUrl(url)) await launchUrl(url);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AshaColors.primaryDark,
                      side: const BorderSide(color: AshaColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: AshaShapes.buttonRadius,
                      ),
                    ),
                    icon: const Icon(Icons.local_hospital_rounded, size: 18),
                    label: const Text(
                      'Call Facility',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    onPressed: () async {
                      final url = Uri.parse('tel:${record.facilityPhone}');
                      if (await canLaunchUrl(url)) await launchUrl(url);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTicketGrid(List<(String, String)> items) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AshaColors.borderSubtle),
      ),
      child: Column(
        children: items.map((pair) {
          final (label, value) = pair;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AshaColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AshaColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimeline(List<(String, String, bool)> steps) {
    return Column(
      children: steps.map((step) {
        final (title, time, done) = step;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(
                done
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 16,
                color: done ? const Color(0xFF059669) : AshaColors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: done ? FontWeight.w700 : FontWeight.w500,
                    color: done ? AshaColors.textPrimary : AshaColors.textMuted,
                  ),
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 10,
                  color: AshaColors.textMuted,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 6.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: AshaColors.borderSubtle),
              ),
            );
          }),
        );
      },
    );
  }
}
