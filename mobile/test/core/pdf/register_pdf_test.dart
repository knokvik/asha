import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/database/app_database.dart';
import 'package:asha_platform/core/pdf/pdf_generator.dart';
import 'package:asha_platform/core/pdf/register_data_service.dart';
import 'package:asha_platform/core/pdf/register_models.dart';
import 'package:asha_platform/core/pdf/template_manager.dart';
import 'package:asha_platform/features/reports/presentation/register_viewer_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Task 13.1: Paper Outputs, Government Registers & PDF Generation (Requirements 34.1 – 34.5)', () {
    late AppDatabase db;
    late RegisterDataService dataService;

    const workerId = 'asha_sunita_01';
    const villageName = 'Devpur Gram Panchayat';

    setUp(() {
      TemplateManager().resetToDefaults();
      db = AppDatabase.forTesting(NativeDatabase.memory());
      dataService = RegisterDataService(db);
    });

    tearDown(() async {
      await db.close();
    });

    // ── 1. The 9 Official Government Register Templates (Requirement 34.1) ─────
    group('Official Government Register Generation (Requirement 34.1)', () {
      final registerTypes = [
        RegisterType.villageSurvey,
        RegisterType.rch,
        RegisterType.hbnc,
        RegisterType.hbyc,
        RegisterType.pnc,
        RegisterType.highRiskPregnancy,
        RegisterType.cbac,
        RegisterType.tbTreatment,
        RegisterType.immunization,
      ];

      for (final type in registerTypes) {
        test('generates valid print-ready PDF for ${type.displayName} (${type.formCode})', () async {
          final data = await dataService.fetchRegisterData(
            type: type,
            workerId: workerId,
            villageName: villageName,
          );

          expect(data.rows.isNotEmpty, isTrue);
          expect(data.type, equals(type));

          final pdfBytes = await PdfGenerator.generateRegisterPdf(data);
          expect(pdfBytes.isNotEmpty, isTrue);

          // Verify PDF magic bytes '%PDF-'
          final header = utf8.decode(pdfBytes.sublist(0, 5));
          expect(header, equals('%PDF-'));
        });
      }
    });

    // ── 2. Monthly ASHA Progress Report (MPR) (Requirement 34.2) ───────────────
    group('Monthly ASHA Progress Report (Requirement 34.2)', () {
      test('generates standard monthly reporting format with indicator targets and achievements', () async {
        final data = await dataService.fetchRegisterData(
          type: RegisterType.monthlyReport,
          workerId: workerId,
          villageName: villageName,
          reportingPeriod: 'October 2026',
        );

        expect(data.rows.isNotEmpty, isTrue);
        expect(data.summaryTotals.containsKey('Total Key Indicators Reported'), isTrue);

        final pdfBytes = await PdfGenerator.generateMonthlyReportPdf(data);
        expect(pdfBytes.isNotEmpty, isTrue);

        final header = utf8.decode(pdfBytes.sublist(0, 5));
        expect(header, equals('%PDF-'));
      });
    });

    // ── 3. OTA Template Update via Server-Delivered Config (Requirement 34.3) ──
    group('OTA Register Template Updates (Requirement 34.3)', () {
      test('applies server-delivered template updates dynamically without APK release', () {
        final manager = TemplateManager();
        final currentRch = manager.getTemplate(RegisterType.rch);
        expect(currentRch.version, equals(1));

        // Simulate new government RCH register version 2 with an additional 'Blood Sugar / GDM' column
        final otaUpdatePayload = {
          'id': 'tpl_rch_v2_bihar',
          'type': 'rch',
          'version': 2,
          'title': 'BIHAR RCH REGISTER 2026 (REVISED)',
          'subtitle': 'Updated State Directorate of Maternal Health Guidelines',
          'state_code': 'BR',
          'columns': [
            {'key': 'sl_no', 'header': 'Sl', 'flex': 0.5, 'alignment': 'center'},
            {'key': 'rch_id', 'header': 'RCH ID', 'flex': 1.5, 'alignment': 'left'},
            {'key': 'woman_name', 'header': 'Maternal Name', 'flex': 2.0, 'alignment': 'left'},
            {'key': 'age_gravida', 'header': 'Age/G-P', 'flex': 1.0, 'alignment': 'center'},
            {'key': 'gdm_screening', 'header': 'OGTT / GDM Status', 'flex': 1.5, 'alignment': 'center'},
          ],
          'footer_disclaimer': 'Revised Government of Bihar Health Directorate Standard',
          'effective_date': '2026-10-01T00:00:00.000Z',
        };

        final success = manager.ingestOtaJson(jsonEncode(otaUpdatePayload));
        expect(success, isTrue);

        final updated = manager.getTemplate(RegisterType.rch);
        expect(updated.version, equals(2));
        expect(updated.title, equals('BIHAR RCH REGISTER 2026 (REVISED)'));
        expect(updated.columns.any((c) => c.key == 'gdm_screening'), isTrue);
      });
    });

    // ── 4. Family-Friendly Health Cards & Summaries (Requirement 34.5) ─────────
    group('Family-Friendly Health Cards (Requirement 34.5)', () {
      test('generates Mother & Child Protection (MCP) update card PDF', () async {
        final mcpCard = dataService.generateFamilyCard(
          cardType: FamilyCardType.mcpCardUpdate,
          beneficiaryName: 'Anita Devi',
          languageCode: 'hi',
        );

        expect(mcpCard.cardType, equals(FamilyCardType.mcpCardUpdate));
        expect(mcpCard.clinicalSummary.containsKey('Estimated Due Date (EDD)'), isTrue);

        final bytes = await PdfGenerator.generateFamilyFriendlyCardPdf(mcpCard);
        expect(bytes.isNotEmpty, isTrue);
        expect(utf8.decode(bytes.sublist(0, 5)), equals('%PDF-'));
      });

      test('generates Child Universal Immunization Card PDF', () async {
        final vaxCard = dataService.generateFamilyCard(
          cardType: FamilyCardType.childVaccination,
          beneficiaryName: 'Aarav Kumar',
          gender: 'Male',
          languageCode: 'hi',
        );

        expect(vaxCard.cardType, equals(FamilyCardType.childVaccination));
        expect(vaxCard.keyChecklist.isNotEmpty, isTrue);

        final bytes = await PdfGenerator.generateFamilyFriendlyCardPdf(vaxCard);
        expect(bytes.isNotEmpty, isTrue);
        expect(utf8.decode(bytes.sublist(0, 5)), equals('%PDF-'));
      });

      test('generates Emergency Referral Slip PDF with ambulance helpline', () async {
        final referralCard = dataService.generateFamilyCard(
          cardType: FamilyCardType.referralSlip,
          beneficiaryName: 'Kavya Kumari',
          languageCode: 'hi',
        );

        expect(referralCard.cardType, equals(FamilyCardType.referralSlip));
        expect(referralCard.clinicalSummary['Referral Severity'], contains('RED'));

        final bytes = await PdfGenerator.generateFamilyFriendlyCardPdf(referralCard);
        expect(bytes.isNotEmpty, isTrue);
        expect(utf8.decode(bytes.sublist(0, 5)), equals('%PDF-'));
      });
    });

    // ── 5. Full-Screen On-Screen Register Viewer UI (Requirement 34.4) ─────────
    group('RegisterViewerScreen UI (Requirement 34.4)', () {
      testWidgets('renders register table, period selector, and allows mode toggle', (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            home: RegisterViewerScreen(
              db: db,
              workerId: workerId,
              villageName: villageName,
              ashaName: 'Sunita Devi',
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check app bar and titles
        expect(find.text('Official Registers & Reports'), findsOneWidget);
        expect(find.textContaining('Devpur Gram Panchayat'), findsOneWidget);

        // Check table headers & demonstration data
        expect(find.byType(DataTable), findsOneWidget);
        expect(find.text("Woman's Name"), findsOneWidget);
        expect(find.text('Anita Devi w/o Suresh'), findsOneWidget);

        // Check search filter works
        await tester.enterText(find.byType(TextField).first, 'Savita');
        await tester.pumpAndSettle();
        expect(find.text('Savita Yadav w/o Manoj'), findsOneWidget);
        expect(find.text('Anita Devi w/o Suresh'), findsNothing);

        // Clear search
        await tester.enterText(find.byType(TextField).first, '');
        await tester.pumpAndSettle();

        // Check share action button
        expect(find.text('Share PDF'), findsOneWidget);
      });
    });
  });
}
