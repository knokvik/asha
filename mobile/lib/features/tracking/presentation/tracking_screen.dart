import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
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
}

class _TrackingSnapshot {
  const _TrackingSnapshot(this.items, this.pendingCount);
  final List<TrackingRecord> items;
  final int pendingCount;
}

class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key});

  Future<_TrackingSnapshot> _load(AppDatabase db) async {
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
    final householdNames = {for (final h in households) h.id: h.headName};
    final memberNames = {for (final m in members) m.id: m.name};
    final items = <TrackingRecord>[];
    for (final referral in referrals) {
      items.add(
        TrackingRecord(
          kind: TrackingKind.triage,
          title: 'Ticket ${_short(referral.id)}',
          subtitle:
              '${referral.triageFlag.toUpperCase()} · ${memberNames[referral.memberId] ?? 'Beneficiary'}',
          status: referral.status,
          time: _time(referral.updatedAt),
          payload: {
            'ticket': referral.id,
            'member': memberNames[referral.memberId] ?? referral.memberId,
            'flag': referral.triageFlag,
            'facility': referral.destinationFacilityId ?? 'Not selected',
            'outcome': referral.outcome ?? 'Awaiting PHC update',
            'sync': referral.syncStatus,
          },
        ),
      );
    }
    for (final member in members) {
      items.add(
        TrackingRecord(
          kind: TrackingKind.people,
          title: member.name,
          subtitle:
              householdNames[member.householdId] ?? 'Household not linked',
          status: member.syncStatus,
          time: _time(member.updatedAt),
          payload: {
            'personId': member.id,
            'phone': member.phone ?? 'Not recorded',
            'consent': member.consentStatus,
            'household':
                householdNames[member.householdId] ?? member.householdId,
          },
        ),
      );
    }
    for (final household in households) {
      items.add(
        TrackingRecord(
          kind: TrackingKind.households,
          title: household.headName,
          subtitle: '${household.village} · ${household.memberCount} members',
          status: household.syncStatus,
          time: _time(household.updatedAt),
          payload: {
            'householdId': household.id,
            'location':
                '${household.latitude ?? '—'}, ${household.longitude ?? '—'}',
            'proof': household.landmarkNotes ?? 'No notes',
            'members': household.memberCount,
          },
        ),
      );
    }
    for (final encounter in encounters) {
      items.add(
        TrackingRecord(
          kind: TrackingKind.other,
          title: encounter.programCode.toUpperCase(),
          subtitle:
              '${encounter.encounterType} · ${memberNames[encounter.memberId] ?? encounter.memberId}',
          status: encounter.syncStatus,
          time: _time(encounter.updatedAt),
          payload: {
            'encounterId': encounter.id,
            'notes': encounter.visitNotes ?? 'No visit notes',
            'status': encounter.status,
            'program': encounter.programCode,
          },
        ),
      );
    }
    for (final packet in queue.take(20)) {
      items.add(
        TrackingRecord(
          kind: TrackingKind.other,
          title: 'Sync ${packet.targetTable}',
          subtitle:
              '${packet.operation.toUpperCase()} · ${_short(packet.recordId)}',
          status: packet.syncStatus,
          time: _time(packet.createdAt),
          payload: {
            'recordId': packet.recordId,
            'operation': packet.operation,
            'attempts': packet.attemptCount,
            'error': packet.errorMessage ?? 'No error',
          },
        ),
      );
    }
    items.sort((a, b) => b.time.compareTo(a.time));
    return _TrackingSnapshot(
      items,
      queue.where((item) => item.syncStatus != 'synced').length,
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        title: const Text('Tracking'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      bottomNavigationBar: const AshaBottomNav(index: 0),
      body: FutureBuilder<_TrackingSnapshot>(
        future: _load(db),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load local tracking: ${snapshot.error}'),
            );
          }
          return _TrackingBody(snapshot.data ?? const _TrackingSnapshot([], 0));
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
  final _labels = const {
    TrackingKind.all: 'All',
    TrackingKind.people: 'People',
    TrackingKind.triage: 'Triage',
    TrackingKind.households: 'Households',
    TrackingKind.other: 'Other',
  };

  @override
  Widget build(BuildContext context) {
    final visible = widget.snapshot.items
        .where((item) => _filter == TrackingKind.all || item.kind == _filter)
        .toList();
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _labels.entries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(entry.value),
                        selected: _filter == entry.key,
                        onSelected: (_) => setState(() => _filter = entry.key),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),
          if (visible.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('Nothing recorded in this section yet.'),
                ),
              ),
            ),
          ...visible.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                onTap: () => context.push('/tracking/detail', extra: item),
                leading: CircleAvatar(
                  backgroundColor: _color(item.kind).withValues(alpha: .12),
                  child: Icon(_icon(item.kind), color: _color(item.kind)),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text('${item.subtitle}\n${item.time}'),
                isThreeLine: true,
                trailing: _status(item.status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _status(String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: value == 'synced' || value == 'treated' || value == 'acknowledged'
          ? Colors.green.shade50
          : Colors.orange.shade50,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      value,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: value == 'synced'
            ? Colors.green.shade800
            : Colors.orange.shade800,
      ),
    ),
  );
  static IconData _icon(TrackingKind kind) => switch (kind) {
    TrackingKind.people => Icons.person_outline_rounded,
    TrackingKind.triage => Icons.emergency_outlined,
    TrackingKind.households => Icons.home_work_outlined,
    _ => Icons.assignment_outlined,
  };
  static Color _color(TrackingKind kind) => switch (kind) {
    TrackingKind.people => Colors.blue,
    TrackingKind.triage => Colors.red,
    TrackingKind.households => Colors.green,
    _ => Colors.deepPurple,
  };
}

class TrackingDetailScreen extends StatelessWidget {
  const TrackingDetailScreen({super.key, required this.record});

  final TrackingRecord record;

  @override
  Widget build(BuildContext context) {
    final entries =
        record.payload?.entries.toList() ?? const <MapEntry<String, dynamic>>[];
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        title: const Text('Activity details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Card(
            color: const Color(0xFF174B35),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _TrackingBodyState._icon(record.kind),
                    color: Colors.white,
                    size: 30,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    record.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    record.subtitle,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'CURRENT STATUS',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      _DetailStatusChip(record.status),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Record information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _detailRow('Recorded', record.time),
                  ...entries.map(
                    (entry) =>
                        _detailRow(_pretty(entry.key), entry.value.toString()),
                  ),
                ],
              ),
            ),
          ),
          if (record.kind == TrackingKind.triage) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.sync_rounded, color: Color(0xFF174B35)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        record.status == 'created'
                            ? 'This ticket is waiting for the next sync or PHC acknowledgement.'
                            : 'PHC updates and referral outcomes are retained here and flow back to the originating worker during sync.',
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    ),
  );

  static String _pretty(String value) => value
      .replaceAll('_', ' ')
      .replaceFirstMapped(
        RegExp(r'^.'),
        (match) => match.group(0)!.toUpperCase(),
      );
}

class _DetailStatusChip extends StatelessWidget {
  const _DetailStatusChip(this.status);
  final String status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      status,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
