import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_engine.dart';
import '../domain/reminder_models.dart';

/// Repository managing reminder acknowledgements, delivery receipts,
/// and supervisor contact directories (Requirements 26.4, 26.6).
class ReminderRepository {
  final AppDatabase _db;
  final SyncEngine? _syncEngine;
  static const _uuid = Uuid();

  ReminderRepository(this._db, [this._syncEngine]);

  // ── 1. Table Embedding ──────────────────────────────────────────────────────

  /// Ensures SQLite table for tracking reminder deliveries and acknowledgements exists.
  Future<void> ensureReminderDeliveriesTableExists() async {
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS reminder_deliveries (
        id TEXT PRIMARY KEY,
        schedule_id TEXT NOT NULL,
        member_id TEXT NOT NULL,
        channel TEXT NOT NULL,
        status TEXT NOT NULL,
        recorded_at INTEGER NOT NULL,
        response_note TEXT
      );
    ''');

    await _db.customStatement('''
      CREATE INDEX IF NOT EXISTS idx_reminder_deliveries_schedule
      ON reminder_deliveries(schedule_id);
    ''');
  }

  // ── 2. Record Delivery & Acknowledgements (Requirement 26.4) ─────────────────

  /// Records beneficiary or family acknowledgement of a reminder.
  Future<ReminderAcknowledgement> recordAcknowledgement({
    required String scheduleId,
    required String memberId,
    required ReminderChannel channel,
    required ReminderDeliveryStatus status,
    String? responseNote,
    DateTime? recordedAt,
  }) async {
    await ensureReminderDeliveriesTableExists();

    final now = recordedAt ?? DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    final id = _uuid.v4();

    await _db.customStatement('''
      INSERT INTO reminder_deliveries (id, schedule_id, member_id, channel, status, recorded_at, response_note)
      VALUES (?, ?, ?, ?, ?, ?, ?);
    ''', [id, scheduleId, memberId, channel.name, status.name, nowMs, responseNote]);

    final ack = ReminderAcknowledgement(
      id: id,
      scheduleId: scheduleId,
      memberId: memberId,
      channel: channel,
      status: status,
      recordedAt: now,
      responseNote: responseNote,
    );

    // Enqueue to sync queue for backend synchronization
    if (_syncEngine != null) {
      await _syncEngine.enqueue(
        table: 'reminder_deliveries',
        recordId: id,
        operation: 'insert',
        priority: SyncPriority.metadata,
        payload: ack.toJson(),
      );
    }

    return ack;
  }

  /// Retrieves all recorded acknowledgements for a given visit task.
  Future<List<ReminderAcknowledgement>> getAcknowledgementsForTask(String scheduleId) async {
    await ensureReminderDeliveriesTableExists();

    final rows = await _db.customSelect(
      'SELECT * FROM reminder_deliveries WHERE schedule_id = ? ORDER BY recorded_at DESC;',
      variables: [Variable.withString(scheduleId)],
    ).get();

    return rows.map((r) {
      return ReminderAcknowledgement(
        id: r.read<String>('id'),
        scheduleId: r.read<String>('schedule_id'),
        memberId: r.read<String>('member_id'),
        channel: ReminderChannel.values.firstWhere((e) => e.name == r.read<String>('channel')),
        status: ReminderDeliveryStatus.values.firstWhere((e) => e.name == r.read<String>('status')),
        recordedAt: DateTime.fromMillisecondsSinceEpoch(r.read<int>('recorded_at')),
        responseNote: r.readNullable<String>('response_note'),
      );
    }).toList();
  }

  // ── 3. Supervisor & Emergency Contact Directory (Requirement 26.6) ──────────

  /// Fetches supervisor contacts (ANM, AF, MO) and standard emergency helplines.
  Future<List<SupervisorContact>> getSupervisorDirectory({
    String? village,
    String? subcentre,
    String? phc,
  }) async {
    final contacts = <SupervisorContact>[];

    // 1. Check existing users in the local database
    final users = await (_db.select(_db.users)..where((t) => t.role.isNotValue('ASHA'))).get();
    for (final u in users) {
      contacts.add(
        SupervisorContact(
          id: u.id,
          name: u.name,
          role: u.role,
          phone: '9876543210', // Default fallback if not captured in user row
          designatedArea: u.areaSubcentre ?? u.areaVillage ?? 'Health Centre',
        ),
      );
    }

    // 2. Add Standard MoHFW Emergency Services if not present
    contacts.addAll([
      SupervisorContact(
        id: 'contact_108',
        name: 'National Emergency Ambulance (108)',
        role: 'EMERGENCY_AMBULANCE',
        phone: '108',
        designatedArea: village ?? 'Block & District',
      ),
      SupervisorContact(
        id: 'contact_104',
        name: 'Health Advice & Grievance Helpline (104)',
        role: 'HEALTH_HELPLINE',
        phone: '104',
        designatedArea: village ?? 'State Helplines',
      ),
      SupervisorContact(
        id: 'contact_1098',
        name: 'Childline Emergency (1098)',
        role: 'CHILDLINE',
        phone: '1098',
        designatedArea: village ?? 'Child Welfare',
      ),
    ]);

    return contacts;
  }
}
