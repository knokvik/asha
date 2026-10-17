import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/database/app_database.dart';
import 'package:asha_platform/core/sync/sync_engine.dart';
import 'package:asha_platform/features/reminders/data/local_notification_service.dart';
import 'package:asha_platform/features/reminders/data/reminder_repository.dart';
import 'package:asha_platform/features/reminders/domain/communication_launcher.dart';
import 'package:asha_platform/features/reminders/domain/notification_scheduler.dart';
import 'package:asha_platform/features/reminders/domain/reminder_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Task 12.1: Reminders & Beneficiary Communication Tests (Requirements 26.1 – 26.6)', () {
    // ── 1. Quiet Hours Configuration ─────────────────────────────────────────
    group('QuietHoursConfig', () {
      test('identifies times within overnight quiet hours window (21:00 to 07:00)', () {
        const config = QuietHoursConfig(
          enabled: true,
          startHour: 21,
          startMinute: 0,
          endHour: 7,
          endMinute: 0,
        );

        final evening = DateTime(2025, 5, 10, 22, 30);
        final midnight = DateTime(2025, 5, 11, 0, 15);
        final earlyMorning = DateTime(2025, 5, 11, 6, 45);
        final daytime = DateTime(2025, 5, 10, 14, 0);

        expect(config.isWithinQuietHours(evening), isTrue);
        expect(config.isWithinQuietHours(midnight), isTrue);
        expect(config.isWithinQuietHours(earlyMorning), isTrue);
        expect(config.isWithinQuietHours(daytime), isFalse);
      });

      test('identifies times within same-day quiet hours window (13:00 to 15:00)', () {
        const config = QuietHoursConfig(
          enabled: true,
          startHour: 13,
          startMinute: 0,
          endHour: 15,
          endMinute: 0,
        );

        final during = DateTime(2025, 5, 10, 14, 30);
        final after = DateTime(2025, 5, 10, 15, 30);
        final before = DateTime(2025, 5, 10, 12, 0);

        expect(config.isWithinQuietHours(during), isTrue);
        expect(config.isWithinQuietHours(after), isFalse);
        expect(config.isWithinQuietHours(before), isFalse);
      });

      test('respects disabled state', () {
        const config = QuietHoursConfig(enabled: false);
        final evening = DateTime(2025, 5, 10, 23, 0);
        expect(config.isWithinQuietHours(evening), isFalse);
      });

      test('serializes to and deserializes from JSON', () {
        const config = QuietHoursConfig(
          enabled: true,
          startHour: 20,
          startMinute: 30,
          endHour: 6,
          endMinute: 30,
        );
        final json = config.toJson();
        final restored = QuietHoursConfig.fromJson(json);

        expect(restored.enabled, equals(config.enabled));
        expect(restored.startHour, equals(20));
        expect(restored.startMinute, equals(30));
        expect(restored.endHour, equals(6));
        expect(restored.endMinute, equals(30));
      });
    });

    // ── 2. Notification Scheduler Algorithm ──────────────────────────────────
    group('NotificationScheduler', () {
      const config = QuietHoursConfig(
        enabled: true,
        startHour: 21,
        startMinute: 0,
        endHour: 7,
        endMinute: 0,
      );

      test('urgent notifications bypass quiet hours and fire immediately (Req 26.5)', () {
        final eveningTime = DateTime(2025, 5, 10, 23, 30);
        final effective = NotificationScheduler.calculateEffectiveNotificationTime(
          targetTime: eveningTime,
          urgency: NotificationUrgency.urgent,
          quietHoursConfig: config,
        );

        expect(effective, equals(eveningTime));
      });

      test('standard evening notification is deferred to next morning 07:00 (Req 26.5)', () {
        final eveningTime = DateTime(2025, 5, 10, 22, 15);
        final effective = NotificationScheduler.calculateEffectiveNotificationTime(
          targetTime: eveningTime,
          urgency: NotificationUrgency.standard,
          quietHoursConfig: config,
        );

        expect(effective, equals(DateTime(2025, 5, 11, 7, 0)));
      });

      test('standard post-midnight notification is deferred to same morning 07:00 (Req 26.5)', () {
        final midnightTime = DateTime(2025, 5, 11, 3, 30);
        final effective = NotificationScheduler.calculateEffectiveNotificationTime(
          targetTime: midnightTime,
          urgency: NotificationUrgency.standard,
          quietHoursConfig: config,
        );

        expect(effective, equals(DateTime(2025, 5, 11, 7, 0)));
      });

      test('daytime notification fires at exact target time', () {
        final daytime = DateTime(2025, 5, 10, 11, 0);
        final effective = NotificationScheduler.calculateEffectiveNotificationTime(
          targetTime: daytime,
          urgency: NotificationUrgency.standard,
          quietHoursConfig: config,
        );

        expect(effective, equals(daytime));
      });

      test('evaluates batching threshold correctly (Req 26.5)', () {
        expect(NotificationScheduler.shouldBatchNotifications(4, threshold: 5), isFalse);
        expect(NotificationScheduler.shouldBatchNotifications(5, threshold: 5), isTrue);
        expect(NotificationScheduler.shouldBatchNotifications(12, threshold: 5), isTrue);
      });

      test('formats daily batch summary with overdue visits and hamlets', () {
        final summary = NotificationScheduler.formatDailyBatchSummary(
          dueTodayCount: 6,
          overdueCount: 2,
          hamlets: ['North Tola', 'South Basti', 'North Tola', 'East Purwa', 'Harijan Basti'],
        );

        expect(summary['title'], equals('ASHA Daily Workplan: 8 visits due'));
        expect(summary['body'], contains('2 overdue!'));
        expect(summary['body'], contains('6 scheduled for today.'));
        expect(summary['body'], contains('Hamlets: North Tola, South Basti, East Purwa (+1 more).'));
      });

      test('generates stable, positive 31-bit notification IDs', () {
        final id1 = NotificationScheduler.generateStableNotificationId('task_anc_001');
        final id2 = NotificationScheduler.generateStableNotificationId('task_anc_001');
        final id3 = NotificationScheduler.generateStableNotificationId('task_immu_002');

        expect(id1, isPositive);
        expect(id1, equals(id2));
        expect(id1, isNot(equals(id3)));
      });
    });

    // ── 3. Beneficiary Message Templates & Anti-Stigma Privacy Filter ────────
    group('BeneficiaryMessageTemplates & Privacy Protection (Req 26.2, 26.3)', () {
      test('formats bilingual ANC Checkup reminder cleanly', () {
        final hiMsg = BeneficiaryMessageTemplates.formatMessage(
          type: BeneficiaryTemplateType.ancCheckup,
          languageCode: 'hi',
          parameters: {
            'name': 'अनिता देवी',
            'date': '12 मई 2025',
            'facility': 'देवपुर उपकेंद्र',
          },
        );
        expect(hiMsg, contains('नमस्ते अनिता देवी जी'));
        expect(hiMsg, contains('मातृत्व स्वास्थ्य जांच 12 मई 2025'));

        final enMsg = BeneficiaryMessageTemplates.formatMessage(
          type: BeneficiaryTemplateType.ancCheckup,
          languageCode: 'en',
          parameters: {
            'name': 'Anita Devi',
            'date': '12 May 2025',
            'facility': 'Devpur Subcentre',
          },
        );
        expect(enMsg, contains('maternal health checkup is scheduled on 12 May 2025'));
        expect(enMsg, contains('MCP card'));
      });

      test('formats bilingual Immunization reminder', () {
        final hiMsg = BeneficiaryMessageTemplates.formatMessage(
          type: BeneficiaryTemplateType.immunizationDue,
          languageCode: 'hi',
          parameters: {
            'name': 'रोहन',
            'detail': 'पेंटावेलेंट 1',
            'date': '15 मई',
            'facility': 'प्राथमिक स्वास्थ्य केंद्र',
          },
        );
        expect(hiMsg, contains('रोहन का नियमित टीकाकरण (पेंटावेलेंट 1)'));

        final enMsg = BeneficiaryMessageTemplates.formatMessage(
          type: BeneficiaryTemplateType.immunizationDue,
          languageCode: 'en',
          parameters: {
            'name': 'Rohan',
            'detail': 'Pentavalent 1',
            'date': '15 May',
            'facility': 'PHC Devpur',
          },
        );
        expect(enMsg, contains('regular vaccination (Pentavalent 1) for Rohan is due'));
      });

      test('formats HBNC newborn visit reminder', () {
        final hiMsg = BeneficiaryMessageTemplates.formatMessage(
          type: BeneficiaryTemplateType.hbncNewbornVisit,
          languageCode: 'hi',
          parameters: {'name': 'सुनीता'},
        );
        expect(hiMsg, contains('आशा दीदी आज नवजात शिशु और माता की गृह भेंट'));
      });

      test('formats NCD refill and medication adherence reminder', () {
        final ncdMsg = BeneficiaryMessageTemplates.formatMessage(
          type: BeneficiaryTemplateType.ncdRefill,
          languageCode: 'hi',
          parameters: {'name': 'रमेश सिंह', 'date': 'कल', 'facility': 'सीएचसी'},
        );
        expect(ncdMsg, contains('दवा रीफिल'));

        final medMsg = BeneficiaryMessageTemplates.formatMessage(
          type: BeneficiaryTemplateType.medicationAdherence,
          languageCode: 'en',
          parameters: {'name': 'Ramesh'},
        );
        expect(medMsg, contains('remember to take your daily prescribed dose'));
      });

      test('strictly blocks sensitive diagnostic and stigmatizing terms (Requirement 26.2)', () {
        expect(
          BeneficiaryMessageTemplates.containsSensitiveHealthDetails('Followup visit for tuberculosis / TB clinic'),
          isTrue,
        );
        expect(
          BeneficiaryMessageTemplates.containsSensitiveHealthDetails('HIV ART refill due tomorrow'),
          isTrue,
        );
        expect(
          BeneficiaryMessageTemplates.containsSensitiveHealthDetails('Cancer screening report pickup'),
          isTrue,
        );
        expect(
          BeneficiaryMessageTemplates.containsSensitiveHealthDetails('Mental illness and depression evaluation'),
          isTrue,
        );
        expect(
          BeneficiaryMessageTemplates.containsSensitiveHealthDetails('Routine maternal checkup at Devpur Subcentre'),
          isFalse,
        );

        // formatMessage must throw ArgumentError if sensitive details injected
        expect(
          () => BeneficiaryMessageTemplates.formatMessage(
            type: BeneficiaryTemplateType.ancCheckup,
            languageCode: 'en',
            parameters: {
              'name': 'Pooja',
              'facility': 'HIV clinic',
            },
          ),
          throwsArgumentError,
        );
      });
    });

    // ── 4. Communication Launcher Utilities ──────────────────────────────────
    group('CommunicationLauncher (Req 26.3, 26.6)', () {
      test('sanitizes telephone numbers correctly', () {
        expect(CommunicationLauncher.sanitizePhoneNumber('+91 98765-43210'), equals('+919876543210'));
        expect(CommunicationLauncher.sanitizePhoneNumber('098765 43210'), equals('09876543210'));
        expect(CommunicationLauncher.sanitizePhoneNumber('  +91-11-2338-0000  '), equals('+911123380000'));
      });

      test('builds phone URI for one-tap calling', () {
        final uri = CommunicationLauncher.buildPhoneUri('+91 98765 43210');
        expect(uri.scheme, equals('tel'));
        expect(uri.path, equals('+919876543210'));
      });

      test('builds SMS URI with prefilled message parameter', () {
        final uri = CommunicationLauncher.buildSmsUri('+91 98765 43210', 'नमस्ते, कल जांच है।');
        expect(uri.scheme, equals('sms'));
        expect(uri.path, equals('+919876543210'));
        expect(uri.queryParameters['body'], equals('नमस्ते, कल जांच है।'));
      });
    });

    // ── 5. Local Notification Service ────────────────────────────────────────
    group('LocalNotificationService', () {
      late LocalNotificationService notificationService;

      setUp(() {
        notificationService = LocalNotificationService();
      });

      test('initializes and manages active schedules in memory', () async {
        final initialized = await notificationService.initialize();
        expect(initialized, isTrue);
        expect(notificationService.isInitialized, isTrue);
      });

      test('schedules visit reminder with quiet hours handling', () async {
        await notificationService.initialize();

        // Standard notification scheduled during quiet hours (22:00)
        final eveningTime = DateTime(2025, 5, 10, 22, 0);
        final scheduled = await notificationService.scheduleVisitReminder(
          scheduleId: 'sched_anc_001',
          title: 'ANC Checkup Due',
          body: 'Anita Devi is due for ANC-2 today.',
          targetDueDate: eveningTime,
          urgency: NotificationUrgency.standard,
        );

        expect(scheduled.scheduleId, equals('sched_anc_001'));
        // Standard notification deferred to next morning 07:00
        expect(scheduled.scheduledTime, equals(DateTime(2025, 5, 11, 7, 0)));
        expect(notificationService.activeSchedules.length, equals(1));

        // Cancel reminder
        await notificationService.cancelReminder('sched_anc_001');
        expect(notificationService.activeSchedules.length, equals(0));
      });

      test('schedules urgent notification without quiet hours deferral', () async {
        await notificationService.initialize();

        final nightTime = DateTime(2025, 5, 10, 23, 45);
        final urgentRecord = await notificationService.scheduleVisitReminder(
          scheduleId: 'sched_urgent_002',
          title: 'RED Emergency: Severe Preeclampsia',
          body: 'BP 165/110 mmHg. Immediate referral required.',
          targetDueDate: nightTime,
          urgency: NotificationUrgency.urgent,
        );

        // Must fire immediately at nightTime
        expect(urgentRecord.scheduledTime, equals(nightTime));
      });

      test('shows daily summary notification', () async {
        await notificationService.initialize();

        await notificationService.showDailySummaryNotification(
          dueTodayCount: 5,
          overdueCount: 2,
          hamlets: ['North Tola', 'South Basti'],
        );

        final summary = NotificationScheduler.formatDailyBatchSummary(
          dueTodayCount: 5,
          overdueCount: 2,
          hamlets: ['North Tola', 'South Basti'],
        );
        expect(summary['title'], contains('ASHA Daily Workplan'));
        expect(summary['body'], contains('2 overdue!'));
      });
    });

    // ── 6. Reminder Repository & Acknowledgements ────────────────────────────
    group('ReminderRepository & Acknowledgements (Req 26.4, 26.6)', () {
      late AppDatabase db;
      late SyncEngine syncEngine;
      late ReminderRepository repository;

      setUp(() async {
        db = AppDatabase.forTesting(NativeDatabase.memory());
        syncEngine = SyncEngine(db);
        repository = ReminderRepository(db, syncEngine);
      });

      tearDown(() async {
        await db.close();
      });

      test('records beneficiary acknowledgement and enqueues to sync queue', () async {
        final ack = await repository.recordAcknowledgement(
          scheduleId: 'sched_immu_01',
          memberId: 'member_baby_01',
          channel: ReminderChannel.sms,
          status: ReminderDeliveryStatus.acknowledged,
          responseNote: 'Beneficiary confirmed attendance tomorrow morning.',
        );

        expect(ack.id, isNotEmpty);
        expect(ack.scheduleId, equals('sched_immu_01'));
        expect(ack.status, equals(ReminderDeliveryStatus.acknowledged));

        // Query database via repository
        final acks = await repository.getAcknowledgementsForTask('sched_immu_01');
        expect(acks.length, equals(1));
        expect(acks.first.responseNote, equals('Beneficiary confirmed attendance tomorrow morning.'));
        expect(acks.first.channel, equals(ReminderChannel.sms));

        // Verify sync queue record was created
        final syncItems = await db.select(db.syncQueue).get();
        expect(syncItems.length, equals(1));
        expect(syncItems.first.targetTable, equals('reminder_deliveries'));
        expect(syncItems.first.recordId, equals(ack.id));
      });

      test('provides supervisor directory including emergency services (Req 26.6)', () async {
        final contacts = await repository.getSupervisorDirectory(village: 'Devpur');

        expect(contacts, isNotEmpty);
        final phoneNumbers = contacts.map((c) => c.phone).toList();

        // Must include standard national helplines
        expect(phoneNumbers, contains('108'));
        expect(phoneNumbers, contains('104'));
        expect(phoneNumbers, contains('1098'));

        final ambulance = contacts.firstWhere((c) => c.phone == '108');
        expect(ambulance.name, contains('108'));
        expect(ambulance.role, equals('EMERGENCY_AMBULANCE'));
      });
    });
  });
}
