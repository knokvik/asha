import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_engine.dart';
import '../domain/vhsnd_models.dart';

/// Repository managing VHSND session planning, mobilisation checklists, service delivery,
/// individual beneficiary timeline updates, VHSNC meetings, and offline health education library (Requirements 27.1 – 27.6).
class VhsndRepository {
  final AppDatabase _db;
  final SyncEngine? _syncEngine;
  static const _uuid = Uuid();

  VhsndRepository(this._db, [this._syncEngine]);

  // ── 1. Table Initialisation ──────────────────────────────────────────────────

  /// Ensures SQLite tables for VHSND sessions, beneficiary attendances, VHSNC meetings,
  /// and health education library index exist.
  Future<void> ensureVhsndTablesExist() async {
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS vhsnd_sessions (
        id TEXT PRIMARY KEY,
        village TEXT NOT NULL,
        anganwadi_center TEXT NOT NULL,
        session_date INTEGER NOT NULL,
        status TEXT NOT NULL,
        anm_name TEXT NOT NULL,
        asha_name TEXT NOT NULL,
        aww_name TEXT NOT NULL,
        summary_notes TEXT,
        feedback_notes TEXT,
        completed_at INTEGER
      );
    ''');

    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS vhsnd_beneficiaries (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        member_id TEXT NOT NULL,
        service_type TEXT NOT NULL,
        details TEXT NOT NULL,
        is_mobilised INTEGER NOT NULL DEFAULT 0,
        has_attended INTEGER NOT NULL DEFAULT 0,
        services_delivered TEXT,
        gap_notes TEXT,
        visit_schedule_id TEXT
      );
    ''');

    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS vhsnc_meetings (
        id TEXT PRIMARY KEY,
        village TEXT NOT NULL,
        meeting_date INTEGER NOT NULL,
        participants_count INTEGER NOT NULL,
        decisions_json TEXT NOT NULL,
        actions_json TEXT NOT NULL,
        feedback_summary TEXT,
        recorded_at INTEGER NOT NULL
      );
    ''');

    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS health_education_assets (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        topic TEXT NOT NULL,
        media_type TEXT NOT NULL,
        asset_path TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL,
        language_code TEXT NOT NULL,
        description TEXT NOT NULL,
        tags_json TEXT NOT NULL
      );
    ''');

    await seedDefaultHealthEducationAssets();
  }

  // ── 2. Seed Default Health Education Library (Requirement 27.4) ─────────────

  /// Seeds standard offline multimedia health education assets if not already populated.
  Future<void> seedDefaultHealthEducationAssets() async {
    final existing = await _db.customSelect('SELECT COUNT(*) as count FROM health_education_assets;').getSingle();
    if (existing.read<int>('count') > 0) return;

    final defaultAssets = [
      HealthEducationAsset(
        id: 'hea_anc_01',
        title: 'Maternal Nutrition & MCP Card Care',
        topic: HealthEducationTopic.maternalHealth,
        mediaType: 'audio_clip',
        assetPath: 'assets/audio/anc_nutrition_hindi.mp3',
        durationSeconds: 120,
        languageCode: 'hi',
        description: 'Audio guidance on iron folic acid (IFA) intake, calcium, diet diversity, and danger signs.',
        tags: ['maternal', 'anc', 'ifa', 'nutrition'],
      ),
      HealthEducationAsset(
        id: 'hea_immu_02',
        title: 'Vaccine Routine Schedule & AEFI Safety',
        topic: HealthEducationTopic.immunization,
        mediaType: 'illustrated_card',
        assetPath: 'assets/illustrations/immunization_schedule.png',
        durationSeconds: 0,
        languageCode: 'hi',
        description: 'Illustrated guide to 0-12 months NIS immunization doses and managing post-vaccine fever.',
        tags: ['vaccination', 'child', 'aefi', 'nis'],
      ),
      HealthEducationAsset(
        id: 'hea_newborn_03',
        title: 'Essential Newborn Care & Kangaroo Mother Care (KMC)',
        topic: HealthEducationTopic.newbornCare,
        mediaType: 'video_clip',
        assetPath: 'assets/videos/kmc_technique_demo.mp4',
        durationSeconds: 180,
        languageCode: 'hi',
        description: 'Short video demonstrating skin-to-skin KMC for low-birthweight infants.',
        tags: ['newborn', 'hbnc', 'kmc', 'hypothermia'],
      ),
      HealthEducationAsset(
        id: 'hea_wash_04',
        title: 'Handwashing Steps & Safe Drinking Water',
        topic: HealthEducationTopic.hygieneSanitation,
        mediaType: 'illustrated_card',
        assetPath: 'assets/illustrations/wash_handwashing.png',
        durationSeconds: 0,
        languageCode: 'hi',
        description: 'Visual steps for soap and water handwashing before infant feeding and after latrine use.',
        tags: ['wash', 'sanitation', 'diarrhea', 'water'],
      ),
      HealthEducationAsset(
        id: 'hea_tb_05',
        title: 'TB Cough Warning Signs & Sputum Testing',
        topic: HealthEducationTopic.communicableDisease,
        mediaType: 'audio_clip',
        assetPath: 'assets/audio/tb_awareness_hindi.mp3',
        durationSeconds: 90,
        languageCode: 'hi',
        description: 'Audio clip explaining 2-week cough, night sweats, free testing and DOTS treatment at PHC.',
        tags: ['tb', 'nikshay', 'cough', 'dots'],
      ),
      HealthEducationAsset(
        id: 'hea_ncd_06',
        title: 'Salt Reduction & Blood Pressure Control',
        topic: HealthEducationTopic.ncdPrevention,
        mediaType: 'illustrated_card',
        assetPath: 'assets/illustrations/bp_hypertension_care.png',
        durationSeconds: 0,
        languageCode: 'hi',
        description: 'Illustrated healthy habits for reducing dietary salt, tobacco cessation, and daily walking.',
        tags: ['ncd', 'hypertension', 'cbac', 'lifestyle'],
      ),
    ];

    for (final a in defaultAssets) {
      await _db.customStatement('''
        INSERT INTO health_education_assets (id, title, topic, media_type, asset_path, duration_seconds, language_code, description, tags_json)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
      ''', [a.id, a.title, a.topic.code, a.mediaType, a.assetPath, a.durationSeconds, a.languageCode, a.description, jsonEncode(a.tags)]);
    }
  }

  // ── 3. VHSND Session Planning (Requirement 27.1) ────────────────────────────

  /// Generates a comprehensive VHSND session plan including due beneficiaries across all services
  /// and standard mobilisation checklist.
  Future<VhsndSession> generateVhsndPlan({
    required String village,
    required String anganwadiCenter,
    required DateTime sessionDate,
    String anmName = 'ANM Sunita',
    String ashaName = 'ASHA Suman',
    String awwName = 'AWW Rekha',
  }) async {
    await ensureVhsndTablesExist();

    final sessionId = _uuid.v4();
    final sessionDateMs = sessionDate.millisecondsSinceEpoch;
    final windowStartMs = sessionDate.subtract(const Duration(days: 7)).millisecondsSinceEpoch;
    final windowEndMs = sessionDate.add(const Duration(days: 7)).millisecondsSinceEpoch;

    // 1. Query households in village
    final households = await (_db.select(_db.households)..where((h) => h.village.equals(village))).get();
    final householdMap = {for (final h in households) h.id: h};
    final householdIds = households.map((h) => h.id).toList();

    // 2. Query members
    final members = await (_db.select(_db.members)..where((m) => m.householdId.isIn(householdIds))).get();
    final memberMap = {for (final m in members) m.id: m};
    final memberIds = members.map((m) => m.id).toList();

    // 3. Query due visit schedules in window
    final dueSchedules = await (_db.select(_db.visitSchedules)
          ..where((s) =>
              s.memberId.isIn(memberIds) &
              s.dueDate.isBiggerOrEqualValue(windowStartMs) &
              s.dueDate.isSmallerOrEqualValue(windowEndMs) &
              s.completedAt.isNull() &
              s.skipReason.isNull()))
        .get();

    final dueBeneficiaries = <VhsndDueBeneficiary>[];

    for (final sched in dueSchedules) {
      final member = memberMap[sched.memberId];
      if (member == null) continue;
      final household = householdMap[member.householdId];
      final hamlet = household?.hamlet ?? 'Main Village';

      // Map program code to VHSND service type
      VhsndServiceType serviceType;
      switch (sched.programCode.toLowerCase()) {
        case 'immunization':
          serviceType = VhsndServiceType.immunization;
          break;
        case 'anc':
        case 'pnc':
          serviceType = VhsndServiceType.anc;
          break;
        case 'ncd':
        case 'cbac':
          serviceType = VhsndServiceType.cbac;
          break;
        case 'fp':
        case 'family_planning':
          serviceType = VhsndServiceType.familyPlanning;
          break;
        default:
          serviceType = VhsndServiceType.nutritionCounseling;
      }

      dueBeneficiaries.add(
        VhsndDueBeneficiary(
          memberId: member.id,
          memberName: member.name,
          householdId: member.householdId,
          hamlet: hamlet,
          sex: member.sex,
          serviceType: serviceType,
          dueServiceDetails: sched.visitType,
          visitScheduleId: sched.id,
        ),
      );
    }

    // 4. Standard Mobilisation Checklist (Requirement 27.1)
    final checklist = [
      const MobilisationChecklistItem(
        id: 'mob_01',
        title: 'Coordinate with ANM on Vaccine Indent & Ice Packs',
        description: 'Verify vaccine carrier, diluents, paracetamol syrup, and AD syringes are ready.',
      ),
      const MobilisationChecklistItem(
        id: 'mob_02',
        title: 'Notify Anganwadi Worker (AWW) & Inspect AWC Room',
        description: 'Ensure clean seating, drinking water, handwashing soap, and baby weighing scale.',
      ),
      const MobilisationChecklistItem(
        id: 'mob_03',
        title: 'Household Visits & Due List Mobilisation',
        description: 'Inform all mothers with infants and pregnant women 2 days prior to bring MCP cards.',
      ),
      const MobilisationChecklistItem(
        id: 'mob_04',
        title: 'Set Up Nutrition & IEC Display Corner',
        description: 'Arrange growth charts, IFA tablets, ORS/Zinc packets, and illustrated counseling cards.',
      ),
      const MobilisationChecklistItem(
        id: 'mob_05',
        title: 'Mobilise High-Risk & Dropout Beneficiaries',
        description: 'Conduct focused morning home visits in distant hamlets for overdue vaccinations.',
      ),
    ];

    // 5. Persist Session & Due Beneficiaries in SQLite
    await _db.customStatement('''
      INSERT INTO vhsnd_sessions (id, village, anganwadi_center, session_date, status, anm_name, asha_name, aww_name)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    ''', [sessionId, village, anganwadiCenter, sessionDateMs, VhsndSessionStatus.planned.name, anmName, ashaName, awwName]);

    for (final b in dueBeneficiaries) {
      await _db.customStatement('''
        INSERT INTO vhsnd_beneficiaries (id, session_id, member_id, service_type, details, is_mobilised, has_attended, services_delivered, gap_notes, visit_schedule_id)
        VALUES (?, ?, ?, ?, ?, 0, 0, '[]', NULL, ?);
      ''', [_uuid.v4(), sessionId, b.memberId, b.serviceType.code, b.dueServiceDetails, b.visitScheduleId]);
    }

    return VhsndSession(
      id: sessionId,
      village: village,
      anganwadiCenter: anganwadiCenter,
      sessionDate: sessionDate,
      status: VhsndSessionStatus.planned,
      anmName: anmName,
      ashaName: ashaName,
      anganwadiWorkerName: awwName,
      beneficiaries: dueBeneficiaries,
      mobilisationChecklist: checklist,
    );
  }

  // ── 4. Record Attendance & Update Beneficiary Timelines (Requirement 27.2) ───

  /// Records beneficiary attendance, delivered services, and gaps, updating clinical encounters
  /// and completing scheduled visits in their timeline.
  Future<void> recordSessionAttendanceAndServices({
    required String sessionId,
    required List<VhsndDueBeneficiary> attendances,
    String? sessionSummaryNotes,
    String? communityFeedbackNotes,
  }) async {
    await ensureVhsndTablesExist();

    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    // Update Session status
    await _db.customStatement('''
      UPDATE vhsnd_sessions
      SET status = ?, summary_notes = ?, feedback_notes = ?, completed_at = ?
      WHERE id = ?;
    ''', [VhsndSessionStatus.completed.name, sessionSummaryNotes, communityFeedbackNotes, nowMs, sessionId]);

    for (final b in attendances) {
      // 1. Update session beneficiary record
      await _db.customStatement('''
        UPDATE vhsnd_beneficiaries
        SET is_mobilised = ?, has_attended = ?, services_delivered = ?, gap_notes = ?
        WHERE session_id = ? AND member_id = ?;
      ''', [
        b.isMobilised ? 1 : 0,
        b.hasAttended ? 1 : 0,
        jsonEncode(b.servicesDelivered),
        b.serviceGapNotes,
        sessionId,
        b.memberId,
      ]);

      // 2. If attended and delivered services, update beneficiary timeline (Requirement 27.2)
      if (b.hasAttended && b.servicesDelivered.isNotEmpty) {
        final encounterId = _uuid.v4();

        // Write to clinical encounters
        await _db.into(_db.clinicalEncounters).insert(
              ClinicalEncountersCompanion.insert(
                id: encounterId,
                memberId: b.memberId,
                encounterType: 'vhsnd_service',
                programCode: b.serviceType.code,
                encounterDate: nowMs,
                ashaId: 'asha_vhsnd',
                createdAt: nowMs,
                updatedAt: nowMs,
                status: const Value('completed'),
              ),
            );

        // Mark visit schedule completed if linked
        if (b.visitScheduleId != null) {
          await (_db.update(_db.visitSchedules)..where((s) => s.id.equals(b.visitScheduleId!))).write(
            VisitSchedulesCompanion(
              completedAt: Value(nowMs),
              completedEncounterId: Value(encounterId),
              status: const Value('completed'),
            ),
          );
        }

        // Enqueue to sync queue
        if (_syncEngine != null) {
          await _syncEngine.enqueue(
            table: 'clinical_encounters',
            recordId: encounterId,
            operation: 'insert',
            priority: SyncPriority.clinical,
            payload: {
              'member_id': b.memberId,
              'encounter_type': 'vhsnd_service',
              'services_delivered': b.servicesDelivered,
              'recorded_at': now.toIso8601String(),
            },
          );
        }
      }
    }
  }

  // ── 5. VHSNC Meeting Logging & Feedback Routing (Requirements 27.3, 27.6) ───

  /// Logs a Village Health Sanitation and Nutrition Committee (VHSNC) meeting
  /// and enqueues to sync queue for AF / VHSNC routing.
  Future<VhsncMeetingLog> recordVhsncMeeting({
    required String village,
    required DateTime meetingDate,
    required int participantsCount,
    required List<String> decisionsMade,
    required List<String> agreedFollowUpActions,
    String? communityFeedbackSummary,
  }) async {
    await ensureVhsndTablesExist();

    final now = DateTime.now();
    final id = _uuid.v4();

    await _db.customStatement('''
      INSERT INTO vhsnc_meetings (id, village, meeting_date, participants_count, decisions_json, actions_json, feedback_summary, recorded_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    ''', [
      id,
      village,
      meetingDate.millisecondsSinceEpoch,
      participantsCount,
      jsonEncode(decisionsMade),
      jsonEncode(agreedFollowUpActions),
      communityFeedbackSummary,
      now.millisecondsSinceEpoch,
    ]);

    final log = VhsncMeetingLog(
      id: id,
      village: village,
      meetingDate: meetingDate,
      participantsCount: participantsCount,
      decisionsMade: decisionsMade,
      agreedFollowUpActions: agreedFollowUpActions,
      communityFeedbackSummary: communityFeedbackSummary,
      recordedAt: now,
    );

    // Enqueue to sync queue to route summary to AF and VHSNC (Requirement 27.6)
    if (_syncEngine != null) {
      await _syncEngine.enqueue(
        table: 'vhsnc_meetings',
        recordId: id,
        operation: 'insert',
        priority: SyncPriority.metadata,
        payload: log.toJson(),
      );
    }

    return log;
  }

  // ── 6. Health Education Asset Search (Requirement 27.4) ─────────────────────

  /// Queries offline multimedia health education assets by topic, media type, or search term.
  Future<List<HealthEducationAsset>> searchHealthEducationAssets({
    HealthEducationTopic? topic,
    String? mediaType,
    String? searchQuery,
  }) async {
    await ensureVhsndTablesExist();

    final whereClauses = <String>[];
    final variables = <Variable>[];

    if (topic != null) {
      whereClauses.add('topic = ?');
      variables.add(Variable.withString(topic.code));
    }

    if (mediaType != null) {
      whereClauses.add('media_type = ?');
      variables.add(Variable.withString(mediaType));
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClauses.add('(title LIKE ? OR description LIKE ? OR tags_json LIKE ?)');
      final term = '%${searchQuery.trim()}%';
      variables.addAll([
        Variable.withString(term),
        Variable.withString(term),
        Variable.withString(term),
      ]);
    }

    final sql = StringBuffer('SELECT * FROM health_education_assets');
    if (whereClauses.isNotEmpty) {
      sql.write(' WHERE ${whereClauses.join(' AND ')}');
    }
    sql.write(' ORDER BY title ASC;');

    final rows = await _db.customSelect(sql.toString(), variables: variables).get();

    return rows.map((r) {
      final tagsList = (jsonDecode(r.read<String>('tags_json')) as List<dynamic>).cast<String>();
      return HealthEducationAsset(
        id: r.read<String>('id'),
        title: r.read<String>('title'),
        topic: HealthEducationTopic.fromCode(r.read<String>('topic')),
        mediaType: r.read<String>('media_type'),
        assetPath: r.read<String>('asset_path'),
        durationSeconds: r.read<int>('duration_seconds'),
        languageCode: r.read<String>('language_code'),
        description: r.read<String>('description'),
        tags: tagsList,
      );
    }).toList();
  }

  // ── 7. National Health Campaigns Support (Requirement 27.5) ─────────────────

  /// Fetches active public health campaigns and operational checklists.
  List<CommunityCampaign> getActiveCampaigns(DateTime date) {
    final year = date.year;
    final allCampaigns = [
      CommunityCampaign(
        id: 'camp_polio_01',
        campaignCode: 'pulse_polio',
        title: 'National Immunization Day (Pulse Polio)',
        startDate: DateTime(year, 1, 1),
        endDate: DateTime(year, 12, 31),
        checklistItems: [
          'Verify bivalent oral polio vaccine (bOPV) vial monitor (VVM)',
          'Check marker pens and tally sheet for left little finger inking',
          "House-to-house 'X' and 'P' marking on front doors",
          'Mobilise all children 0–5 years including transit sites and brick kilns',
        ],
        targetDescription: 'All children aged 0–5 years residing in village or in transit.',
      ),
      CommunityCampaign(
        id: 'camp_mda_02',
        campaignCode: 'mda',
        title: 'Mass Drug Administration (MDA - Filariasis)',
        startDate: DateTime(year, 1, 1),
        endDate: DateTime(year, 12, 31),
        checklistItems: [
          'Directly observed ingestion of DEC + Albendazole tablets (no empty stomach)',
          'Age and height dosing scale verification',
          'Document contraindications: pregnant women, children < 2 years, severely ill',
          'Manage and report minor adverse reactions (nausea/dizziness)',
        ],
        targetDescription: 'All community members >= 2 years excluding pregnant women.',
      ),
      CommunityCampaign(
        id: 'camp_ifa_03',
        campaignCode: 'ifa_week',
        title: 'Intensive IFA & Deworming Campaign (Anemia Mukt Bharat)',
        startDate: DateTime(year, 1, 1),
        endDate: DateTime(year, 12, 31),
        checklistItems: [
          'Distribute red IFA tablets for pregnant women and blue for adolescents',
          'Administer Albendazole 400mg chewable tablet under direct observation',
          'Counsel mothers against drinking tea/milk immediately after iron tablets',
        ],
        targetDescription: 'Adolescent girls and boys (10-19 yrs), pregnant and lactating women.',
      ),
      CommunityCampaign(
        id: 'camp_tb_04',
        campaignCode: 'tb_active_case',
        title: 'Active TB Case Finding (ACF) Campaign',
        startDate: DateTime(year, 1, 1),
        endDate: DateTime(year, 12, 31),
        checklistItems: [
          'Screen every household member for 4-symptom complex (cough > 2 weeks, fever, night sweats, weight loss)',
          'Collect 2 sputum samples in sterile falcon cups for presumptive cases',
          'Deliver sputum collection cups to designated microscopy centre (DMC) within 24 hours',
          'Ensure contact screening of all household members of index TB patients',
        ],
        targetDescription: 'Vulnerable and congregate populations: elderly, malnourished, smokers, diabetic.',
      ),
    ];

    return allCampaigns.where((c) => c.isActiveOn(date)).toList();
  }
}
