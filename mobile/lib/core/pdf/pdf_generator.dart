import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../features/incentives/domain/claim_models.dart';
import '../../features/incentives/domain/earnings_models.dart';
import '../../features/referral/domain/referral_models.dart';
import 'register_models.dart';
import 'template_manager.dart';

/// PDF generation service using the `pdf` Dart package.
///
/// Implements Requirements 10.1, 10.2:
/// - Print-ready referral notes supporting both standard A4 and thermal printer layouts (58mm / 80mm).
/// - High-contrast emergency banner with clinical priority colour.
/// - Structured sections: Patient demographics, vitals & observations, triggering rules,
///   actions taken, destination facility, transit mode, and referring ASHA contact.
class PdfGenerator {
  /// Generates a print-ready PDF document for a [StructuredReferralNote].
  ///
  /// If [thermalLayout] is true, formats for 80mm thermal receipt printers;
  /// otherwise formats for standard A4 paper.
  static Future<Uint8List> generateReferralPdf(
    StructuredReferralNote note, {
    bool thermalLayout = false,
  }) async {
    final pdf = pw.Document();

    final pageFormat = thermalLayout
        ? const PdfPageFormat(
            72 * PdfPageFormat.mm,
            double.infinity,
            marginAll: 4 * PdfPageFormat.mm,
          )
        : PdfPageFormat.a4.copyWith(
            marginTop: 15 * PdfPageFormat.mm,
            marginBottom: 15 * PdfPageFormat.mm,
            marginLeft: 15 * PdfPageFormat.mm,
            marginRight: 15 * PdfPageFormat.mm,
          );

    final flagColor = note.triageFlag.name == 'red'
        ? PdfColors.red800
        : (note.triageFlag.name == 'yellow' ? PdfColors.orange800 : PdfColors.green800);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) {
          if (thermalLayout) {
            return _buildThermalContent(note, flagColor);
          }
          return _buildStandardA4Content(note, flagColor);
        },
      ),
    );

    return pdf.save();
  }

  /// Builds standard A4 clinical referral note.
  static pw.Widget _buildStandardA4Content(
    StructuredReferralNote note,
    PdfColor flagColor,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'NATIONAL HEALTH MISSION — ASHA CLINICAL REFERRAL SLIP',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                ),
                pw.Text(
                  'Ayushman Bharat • Comprehensive Primary Health Care',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Ref ID: ${note.referralId}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                pw.Text(
                  'Date: ${note.createdAt.toIso8601String().substring(0, 16).replaceAll('T', ' ')}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                ),
              ],
            ),
          ],
        ),
        pw.Divider(thickness: 1.5, color: PdfColors.grey400),
        pw.SizedBox(height: 8),

        // Urgent Triage Banner
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: pw.BoxDecoration(
            color: flagColor,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'TRIAGE SEVERITY: ${note.triageFlag.label}',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              ),
              if (note.triageFlag.name == 'red')
                pw.Text(
                  'IMMEDIATE ATTENTION REQUIRED',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                ),
            ],
          ),
        ),
        if (note.overrideFlag != null) ...[
          pw.SizedBox(height: 4),
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            color: PdfColors.orange50,
            child: pw.Text(
              'ASHA Clinical Override: ${note.overrideFlag} (Reason: ${note.overrideReason})',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900),
            ),
          ),
        ],
        pw.SizedBox(height: 12),

        // Chief Complaint Box
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Chief Complaint / Reason: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Expanded(
                child: pw.Text(note.primaryReason, style: const pw.TextStyle(fontSize: 10)),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),

        // Patient Details Table
        pw.Text('1. PATIENT DEMOGRAPHICS & IDENTIFIERS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _tableCell('Name', isHeader: true),
                _tableCell('Age / Sex', isHeader: true),
                _tableCell('ABHA ID', isHeader: true),
                _tableCell('Village / Hamlet', isHeader: true),
                _tableCell('Contact Phone', isHeader: true),
              ],
            ),
            pw.TableRow(
              children: [
                _tableCell(note.patient.name),
                _tableCell('${note.patient.formattedAge} / ${note.patient.sex}'),
                _tableCell(note.patient.abhaId ?? 'None'),
                _tableCell('${note.patient.village ?? ""}${note.patient.hamlet != null ? " / ${note.patient.hamlet}" : ""}'),
                _tableCell(note.patient.contactPhone ?? 'Not recorded'),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 12),

        // Measured Vitals and Triggering Findings
        pw.Text('2. MEASURED VITALS & CLINICAL OBSERVATIONS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        pw.SizedBox(height: 4),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300, width: 0.5)),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (note.vitalsAndSymptoms.isNotEmpty) ...[
                pw.Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: note.vitalsAndSymptoms.entries.map((e) {
                    return pw.Text(
                      '${e.key.replaceAll('_', ' ').toUpperCase()}: ${e.value}',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                    );
                  }).toList(),
                ),
                pw.Divider(color: PdfColors.grey200),
              ],
              pw.Text('Triggering Clinical Rules:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              if (note.triggeringReasons.isNotEmpty)
                ...note.triggeringReasons.map((r) => pw.Text(' • $r', style: const pw.TextStyle(fontSize: 9)))
              else
                pw.Text(' • Normal vitals check / missing data escalation', style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
        ),
        pw.SizedBox(height: 12),

        // Actions Taken by ASHA
        pw.Text('3. ACTIONS ALREADY TAKEN BY ASHA PRIOR TO REFERRAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        pw.SizedBox(height: 4),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300, width: 0.5)),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: note.actionsAlreadyTaken.isNotEmpty
                ? note.actionsAlreadyTaken.map((a) => pw.Text(' ✓ $a', style: const pw.TextStyle(fontSize: 9))).toList()
                : [pw.Text(' ✓ Preliminary triage assessment and family counselling', style: const pw.TextStyle(fontSize: 9))],
          ),
        ),
        pw.SizedBox(height: 12),

        // Destination Facility & Transport
        pw.Text('4. DESTINATION FACILITY & TRANSIT DETAILS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        pw.SizedBox(height: 4),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300, width: 0.5)),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Referred Facility: ${note.destinationFacility?.name ?? "Designated Facility"}',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Facility Level: ${note.destinationFacility?.level.displayName ?? "PHC/CHC"}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                  ),
                  if (note.transportArranged != null)
                    pw.Text('Transport Arranged: ${note.transportArranged}', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              if (note.destinationFacility?.contactPhone != null)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Facility Phone: ${note.destinationFacility!.contactPhone}', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Ambulance: 108 / 102', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
            ],
          ),
        ),
        pw.Spacer(),

        // Signatures & Disclaimer Footer
        pw.Divider(thickness: 1, color: PdfColors.grey400),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Referring ASHA Worker: ${note.asha.name}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.Text('ASHA ID: ${note.asha.id} | Phone: ${note.asha.phone ?? "N/A"}', style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Receiving Medical Officer / Nurse Sign: ________________', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('Arrival Time: ______:______ AM/PM', style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Text(
            'This note was generated on an offline digital device for immediate clinical triage handoff.',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
        ),
      ],
    );
  }

  /// Builds compact 80mm thermal receipt layout for mobile thermal printers.
  static pw.Widget _buildThermalContent(
    StructuredReferralNote note,
    PdfColor flagColor,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Center(
          child: pw.Text('NHM ASHA REFERRAL SLIP', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Center(
          child: pw.Text('Ref: ${note.referralId}', style: const pw.TextStyle(fontSize: 7)),
        ),
        pw.Center(
          child: pw.Text(
            note.createdAt.toIso8601String().substring(0, 16).replaceAll('T', ' '),
            style: const pw.TextStyle(fontSize: 7),
          ),
        ),
        pw.Divider(thickness: 1),

        // Urgent flag
        pw.Container(
          width: double.infinity,
          color: flagColor,
          padding: const pw.EdgeInsets.all(4),
          child: pw.Center(
            child: pw.Text(
              '*** ${note.triageFlag.label} ***',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            ),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text('REASON: ${note.primaryReason}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        pw.Divider(thickness: 0.5),

        // Patient
        pw.Text('PATIENT: ${note.patient.name}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        pw.Text('Age/Sex: ${note.patient.formattedAge} / ${note.patient.sex}', style: const pw.TextStyle(fontSize: 7)),
        if (note.patient.contactPhone != null)
          pw.Text('Phone: ${note.patient.contactPhone}', style: const pw.TextStyle(fontSize: 7)),
        pw.Divider(thickness: 0.5),

        // Vitals
        pw.Text('VITALS & OBSERVATIONS:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ...note.vitalsAndSymptoms.entries.map(
          (e) => pw.Text('• ${e.key}: ${e.value}', style: const pw.TextStyle(fontSize: 7)),
        ),
        pw.Divider(thickness: 0.5),

        // Actions
        pw.Text('ACTIONS TAKEN:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ...note.actionsAlreadyTaken.map((a) => pw.Text('✓ $a', style: const pw.TextStyle(fontSize: 7))),
        pw.Divider(thickness: 0.5),

        // Destination
        pw.Text('REFERRED TO:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        pw.Text(note.destinationFacility?.name ?? 'Designated PHC/CHC', style: const pw.TextStyle(fontSize: 7)),
        if (note.destinationFacility?.contactPhone != null)
          pw.Text('Ph: ${note.destinationFacility!.contactPhone}', style: const pw.TextStyle(fontSize: 7)),
        pw.Divider(thickness: 0.5),

        // ASHA
        pw.Text('ASHA: ${note.asha.name} (${note.asha.phone ?? "N/A"})', style: const pw.TextStyle(fontSize: 7)),
        pw.SizedBox(height: 6),
        pw.Center(
          child: pw.Text('Emergency: 108 / 102', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ),
      ],
    );
  }

  static pw.Widget _tableCell(
    String text, {
    bool isHeader = false,
    bool alignRight = false,
    double fontSize = 8.0,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Writes generated PDF bytes to the local application storage.
  static Future<File> savePdfToFile(
    Uint8List bytes,
    String referralId, {
    Directory? overrideDirectory,
  }) async {
    final dir = overrideDirectory ?? await getApplicationDocumentsDirectory();
    final pdfDir = Directory(p.join(dir.path, 'referrals'));
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }
    final file = File(p.join(pdfDir.path, '$referralId.pdf'));
    return file.writeAsBytes(bytes, flush: true);
  }

  // ── Official Government Register Generation (Requirement 34.1) ─────────────

  /// Generates a print-ready PDF for official Government Registers (Requirement 34.1).
  ///
  /// Supports: Village Survey, RCH, HBNC, HBYC, PNC, High-Risk Pregnancy, CBAC, TB, and Immunization registers.
  static Future<Uint8List> generateRegisterPdf(
    RegisterPageData pageData, {
    RegisterTemplateConfig? customTemplate,
    bool landscape = true,
  }) async {
    final pdf = pw.Document();
    final template = customTemplate ?? TemplateManager().getTemplate(pageData.type);

    final pageFormat = (landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4).copyWith(
      marginTop: 10 * PdfPageFormat.mm,
      marginBottom: 10 * PdfPageFormat.mm,
      marginLeft: 12 * PdfPageFormat.mm,
      marginRight: 12 * PdfPageFormat.mm,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        header: (context) => _buildRegisterHeader(pageData, template),
        footer: (context) => _buildRegisterFooter(context, template),
        build: (context) => [
          _buildRegisterTable(pageData, template),
          pw.SizedBox(height: 10),
          _buildRegisterSummaryAndSignatures(pageData),
        ],
      ),
    );

    return pdf.save();
  }

  // ── Monthly ASHA Progress Report (MPR) (Requirement 34.2) ───────────────────

  /// Generates the standard Monthly ASHA Progress Report (MPR) (Requirement 34.2).
  static Future<Uint8List> generateMonthlyReportPdf(RegisterPageData pageData) async {
    final pdf = pw.Document();
    final template = TemplateManager().getTemplate(RegisterType.monthlyReport);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginTop: 12 * PdfPageFormat.mm,
          marginBottom: 12 * PdfPageFormat.mm,
          marginLeft: 12 * PdfPageFormat.mm,
          marginRight: 12 * PdfPageFormat.mm,
        ),
        header: (context) => _buildMonthlyReportHeader(pageData),
        footer: (context) => _buildRegisterFooter(context, template),
        build: (context) => [
          _buildRegisterTable(pageData, template),
          pw.SizedBox(height: 12),
          _buildMonthlyReportSignatures(pageData),
        ],
      ),
    );

    return pdf.save();
  }

  // ── Family-Friendly Cards & Summaries (Requirement 34.5) ────────────────────

  /// Generates a family-friendly card (MCP Update, Child Vaccination, Referral Slip) (Requirement 34.5).
  static Future<Uint8List> generateFamilyFriendlyCardPdf(FamilyFriendlyCardData cardData) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginTop: 12 * PdfPageFormat.mm,
          marginBottom: 12 * PdfPageFormat.mm,
          marginLeft: 12 * PdfPageFormat.mm,
          marginRight: 12 * PdfPageFormat.mm,
        ),
        build: (context) => _buildFamilyFriendlyCardContent(cardData),
      ),
    );

    return pdf.save();
  }

  // ── Register Table & Header Helpers ─────────────────────────────────────────

  static pw.Widget _buildRegisterHeader(RegisterPageData pageData, RegisterTemplateConfig template) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'GOVERNMENT OF INDIA • NATIONAL HEALTH MISSION',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                ),
                pw.Text(
                  template.title,
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                ),
                pw.Text(
                  template.subtitle,
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.blueGrey100,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                  ),
                  child: pw.Text(
                    'Form: ${template.type.formCode}',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Reporting Period: ${pageData.reportingPeriod}',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          padding: const pw.EdgeInsets.all(5),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Village: ${pageData.villageName}', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('HWC / Sub-Centre: ${pageData.subCentreName}', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('PHC: ${pageData.phcName}', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('Block: ${pageData.blockName}', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('ASHA: ${pageData.ashaName} (${pageData.ashaId})', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
        pw.SizedBox(height: 6),
      ],
    );
  }

  static pw.Widget _buildRegisterFooter(pw.Context context, RegisterTemplateConfig template) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 0.5, color: PdfColors.grey400),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              template.footerDisclaimer,
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildRegisterTable(RegisterPageData pageData, RegisterTemplateConfig template) {
    final columnWidths = <int, pw.TableColumnWidth>{};
    for (int i = 0; i < template.columns.length; i++) {
      columnWidths[i] = pw.FlexColumnWidth(template.columns[i].flex);
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: columnWidths,
      children: [
        // Header Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
          children: template.columns.map((col) {
            pw.TextAlign align = pw.TextAlign.left;
            if (col.alignment == 'center') align = pw.TextAlign.center;
            if (col.alignment == 'right') align = pw.TextAlign.right;

            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 3),
              child: pw.Text(
                col.header,
                textAlign: align,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
          }).toList(),
        ),

        // Data Rows
        ...pageData.rows.asMap().entries.map((entry) {
          final idx = entry.key;
          final row = entry.value;
          final isEven = idx % 2 == 0;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.white : PdfColors.grey50,
            ),
            children: template.columns.map((col) {
              final val = row[col.key]?.toString() ?? '-';
              pw.TextAlign align = pw.TextAlign.left;
              if (col.alignment == 'center') align = pw.TextAlign.center;
              if (col.alignment == 'right') align = pw.TextAlign.right;

              final isAlert = val.contains('HIGH RISK') || val.contains('DUE') || val.contains('Positive');

              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 3),
                child: pw.Text(
                  val,
                  textAlign: align,
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: isAlert ? pw.FontWeight.bold : pw.FontWeight.normal,
                    color: isAlert ? PdfColors.red800 : PdfColors.black,
                  ),
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  static pw.Widget _buildRegisterSummaryAndSignatures(RegisterPageData pageData) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        // Summary totals
        pw.Expanded(
          flex: 2,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Record Verification & Statistics:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ...pageData.summaryTotals.entries.map((e) {
                  return pw.Text('• ${e.key}: ${e.value}', style: const pw.TextStyle(fontSize: 7.5));
                }),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 16),
        // Verification signatures
        pw.Expanded(
          flex: 3,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SizedBox(height: 16),
                  pw.Container(width: 100, height: 0.5, color: PdfColors.grey500),
                  pw.SizedBox(height: 2),
                  pw.Text('Signature of ASHA', style: const pw.TextStyle(fontSize: 7.5)),
                  pw.Text(pageData.ashaName, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SizedBox(height: 16),
                  pw.Container(width: 100, height: 0.5, color: PdfColors.grey500),
                  pw.SizedBox(height: 2),
                  pw.Text('Verified by ANM / CHO', style: const pw.TextStyle(fontSize: 7.5)),
                  pw.Text('Sub-Centre: ${pageData.subCentreName}', style: const pw.TextStyle(fontSize: 7)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SizedBox(height: 16),
                  pw.Container(width: 100, height: 0.5, color: PdfColors.grey500),
                  pw.SizedBox(height: 2),
                  pw.Text('Countersigned by MO I/C', style: const pw.TextStyle(fontSize: 7.5)),
                  pw.Text('PHC ${pageData.phcName}', style: const pw.TextStyle(fontSize: 7)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildMonthlyReportHeader(RegisterPageData pageData) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                'NATIONAL HEALTH MISSION • MONTHLY ASHA PROGRESS REPORT (MPR)',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
              ),
              pw.Text(
                'Ayushman Bharat • Sub-Centre & Village Level Service Delivery Monitoring',
                style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('ASHA: ${pageData.ashaName} (${pageData.ashaId})', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
              pw.Text('Village: ${pageData.villageName}', style: const pw.TextStyle(fontSize: 8.5)),
              pw.Text('PHC: ${pageData.phcName}', style: const pw.TextStyle(fontSize: 8.5)),
              pw.Text('Month: ${pageData.reportingPeriod}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
      ],
    );
  }

  static pw.Widget _buildMonthlyReportSignatures(RegisterPageData pageData) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.SizedBox(height: 20),
            pw.Container(width: 130, height: 0.5, color: PdfColors.black),
            pw.SizedBox(height: 4),
            pw.Text('ASHA Worker Signature', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
            pw.Text('Date: ________________', style: const pw.TextStyle(fontSize: 7.5)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.SizedBox(height: 20),
            pw.Container(width: 130, height: 0.5, color: PdfColors.black),
            pw.SizedBox(height: 4),
            pw.Text('ANM / CHO Verification', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
            pw.Text('Remarks: Verified with RCH Portal', style: const pw.TextStyle(fontSize: 7.5)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.SizedBox(height: 20),
            pw.Container(width: 130, height: 0.5, color: PdfColors.black),
            pw.SizedBox(height: 4),
            pw.Text('Medical Officer In-Charge', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
            pw.Text('Official Seal & Date', style: const pw.TextStyle(fontSize: 7.5)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildFamilyFriendlyCardContent(FamilyFriendlyCardData cardData) {
    final isUrgent = cardData.cardType == FamilyCardType.referralSlip;
    final primaryColor = isUrgent ? PdfColors.red800 : PdfColors.teal800;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header Banner
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: pw.BoxDecoration(
            color: primaryColor,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'NATIONAL HEALTH MISSION • AYUSHMAN BHARAT',
                    style: const pw.TextStyle(color: PdfColors.white, fontSize: 8),
                  ),
                  pw.Text(
                    cardData.cardType.title,
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 13, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              if (isUrgent)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  color: PdfColors.white,
                  child: pw.Text(
                    'URGENT / आपातकालीन',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.red800),
                  ),
                ),
            ],
          ),
        ),
        pw.SizedBox(height: 10),

        // Beneficiary Details Box
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            color: PdfColors.grey50,
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Beneficiary: ${cardData.beneficiaryName}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  if (cardData.guardianName != null)
                    pw.Text('Guardian: ${cardData.guardianName}', style: const pw.TextStyle(fontSize: 9)),
                  if (cardData.dateOfBirth != null)
                    pw.Text('DOB / Age: ${cardData.dateOfBirth}', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if (cardData.rchId != null)
                    pw.Text('RCH ID: ${cardData.rchId}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  if (cardData.abhaId != null)
                    pw.Text('ABHA: ${cardData.abhaId}', style: const pw.TextStyle(fontSize: 8.5)),
                  if (cardData.village != null)
                    pw.Text('Village: ${cardData.village}', style: const pw.TextStyle(fontSize: 8.5)),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 10),

        // Key Health Summary
        pw.Text('1. Health Summary & Vitals', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: cardData.clinicalSummary.entries.map((e) {
              final val = '${e.value}';
              final isRed = val.contains('RED') || val.contains('Severe');
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(
                      width: 160,
                      child: pw.Text(
                        '${e.key}:',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        val,
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: isRed ? pw.FontWeight.bold : pw.FontWeight.normal,
                          color: isRed ? PdfColors.red800 : PdfColors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        pw.SizedBox(height: 10),

        // Checklist / Immunization / Action Items
        pw.Text('2. Actions & Services Checklist', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          ),
          child: pw.Column(
            children: cardData.keyChecklist.map((item) {
              final isDue = item['status']?.contains('DUE') ?? false;
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('• ${item['check']}', style: const pw.TextStyle(fontSize: 8.5)),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: pw.BoxDecoration(
                        color: isDue ? PdfColors.amber100 : PdfColors.green100,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                      ),
                      child: pw.Text(
                        item['status'] ?? 'Recorded',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: isDue ? PdfColors.amber900 : PdfColors.green900,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        pw.SizedBox(height: 12),

        // Next Appointment / Visit Banner
        if (cardData.nextVisitDate != null) ...[
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              border: pw.TableBorder.all(color: PdfColors.blue200, width: 0.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              children: [
                pw.Text('Next Due Health Visit: ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                pw.Text(cardData.nextVisitDate!, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
        ],

        // Emergency Helplines & Contact
        pw.Spacer(),
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          color: PdfColors.grey100,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Your ASHA Worker: ${cardData.ashaContact}', style: const pw.TextStyle(fontSize: 8.5)),
              pw.Text('Emergency Ambulance: 108 • Helpline: 102', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
            ],
          ),
        ),
      ],
    );
  }

  /// Generates an official printable PDF monthly earnings statement (Requirement 55.5).
  ///
  /// Suitable for banking, loan, or microfinance applications:
  /// - Full header with NHM authority banner and statement period
  /// - Worker identity and administrative assignment block
  /// - Categorized financial totals: Total Earned, Paid, Approved, Claimed, Eligible
  /// - Reconciled bank/PFMS disbursement ledger with transaction references
  /// - Complete task-level ledger with de-identified beneficiary references and amounts
  /// - Official certification and signature block
  static Future<Uint8List> generateEarningsStatementPdf(EarningsStatement stmt) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'NATIONAL HEALTH MISSION',
                      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                    ),
                    pw.Text(
                      'Department of Health & Family Welfare',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    border: pw.Border.all(color: PdfColors.blue800, width: 0.8),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                  ),
                  child: pw.Text(
                    'OFFICIAL EARNINGS STATEMENT',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Divider(color: PdfColors.blue900, thickness: 1.2),
            pw.SizedBox(height: 6),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated on: ${stmt.generatedAt.toIso8601String().substring(0, 10)} via ASHA Digital Platform',
              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
            ),
          ],
        ),
        build: (context) => [
          // 1. Worker & Administrative Profile
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text('ASHA Worker: ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Text(stmt.workerName, style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Text('ASHA ID: ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Text(stmt.ashaId, style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Text('Statement Period: ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Text(stmt.period, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Village: ${stmt.village}', style: const pw.TextStyle(fontSize: 8.5)),
                    pw.Text('Sub-centre: ${stmt.subcentre}', style: const pw.TextStyle(fontSize: 8.5)),
                    pw.Text('PHC: ${stmt.phc}', style: const pw.TextStyle(fontSize: 8.5)),
                    pw.Text('Block: ${stmt.block}', style: const pw.TextStyle(fontSize: 8.5)),
                    pw.Text('District: ${stmt.district}, ${stmt.state}', style: const pw.TextStyle(fontSize: 8.5)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // 2. Financial Summary Highlights Box
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey50,
              border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryStat('TOTAL EARNED', 'Rs. ${stmt.totals.totalEarned.toStringAsFixed(2)}', PdfColors.green900),
                _buildSummaryStat('PAID (DBT)', 'Rs. ${stmt.totals.paidAmount.toStringAsFixed(2)}', PdfColors.green800),
                _buildSummaryStat('APPROVED (PENDING)', 'Rs. ${stmt.totals.approvedAmount.toStringAsFixed(2)}', PdfColors.blue800),
                _buildSummaryStat('UNDER VERIFICATION', 'Rs. ${stmt.totals.claimedAmount.toStringAsFixed(2)}', PdfColors.amber800),
                _buildSummaryStat('ELIGIBLE PIPELINE', 'Rs. ${stmt.totals.eligibleAmount.toStringAsFixed(2)}', PdfColors.teal800),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // 3. Bank Disbursement & Reconciliation Ledger
          if (stmt.reconciliations.isNotEmpty) ...[
            pw.Text(
              'PAYMENT DISBURSEMENT & BANK RECONCILIATION',
              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
            ),
            pw.SizedBox(height: 5),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.2),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(2.5),
                4: const pw.FlexColumnWidth(1.5),
                5: const pw.FlexColumnWidth(2.0),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _tableCell('Period', isHeader: true),
                    _tableCell('Approved', isHeader: true, alignRight: true),
                    _tableCell('Paid (DBT)', isHeader: true, alignRight: true),
                    _tableCell('Bank Ref / UTR', isHeader: true),
                    _tableCell('Payment Date', isHeader: true),
                    _tableCell('Status', isHeader: true),
                  ],
                ),
                ...stmt.reconciliations.map(
                  (rec) => pw.TableRow(
                    children: [
                      _tableCell(rec.claimPeriod),
                      _tableCell('Rs. ${rec.approvedAmount.toStringAsFixed(2)}', alignRight: true),
                      _tableCell('Rs. ${rec.paidAmount.toStringAsFixed(2)}', alignRight: true),
                      _tableCell(rec.bankReference),
                      _tableCell(rec.paymentDate.toIso8601String().substring(0, 10)),
                      _tableCell(rec.reconciliationStatus),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 14),
          ],

          // 4. Itemized Tasks Breakdown
          pw.Text(
            'ITEMIZED SERVICE DELIVERIES & INCENTIVE LEDGER',
            style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
          ),
          pw.SizedBox(height: 5),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.1),
              1: const pw.FlexColumnWidth(1.4),
              2: const pw.FlexColumnWidth(3.0),
              3: const pw.FlexColumnWidth(1.3),
              4: const pw.FlexColumnWidth(1.2),
              5: const pw.FlexColumnWidth(1.2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _tableCell('Date', isHeader: true),
                  _tableCell('Code', isHeader: true),
                  _tableCell('Service / Task Description', isHeader: true),
                  _tableCell('Beneficiary', isHeader: true),
                  _tableCell('Status', isHeader: true),
                  _tableCell('Amount', isHeader: true, alignRight: true),
                ],
              ),
              ...stmt.lineItems.map(
                (item) => pw.TableRow(
                  children: [
                    _tableCell(item.serviceDate.toIso8601String().substring(0, 10)),
                    _tableCell(item.activityCode),
                    _tableCell(item.activityName),
                    _tableCell(item.memberCodedId),
                    _tableCell(item.status.toUpperCase()),
                    _tableCell('Rs. ${item.amount.toStringAsFixed(2)}', alignRight: true),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 24),

          // 5. Official Certification & Signatures Box
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CERTIFICATION',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'This is an electronically verified statement of performance incentives earned under the National Health Mission. '
                  'The health activities listed above correspond to clinical encounter records logged by the accredited ASHA worker and verified '
                  'in accordance with state and national programme guidelines.',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
                ),
                pw.SizedBox(height: 35),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _signatureBox('Signature of ASHA Worker'),
                    _signatureBox('Signature of ANM / Verifier'),
                    _signatureBox('Medical Officer In-Charge / BPMU'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generates the printable NHM ASHA monthly claim voucher PDF (Requirements 56.1, 56.7, Property 12).
  ///
  /// Official format containing:
  /// - Scheme title & State Department of Health & Family Welfare
  /// - ASHA worker credentials & administrative geography
  /// - Detailed task line items with de-identified beneficiary IDs, evidence links, and rates
  /// - Verification & approval certification box with signatures
  static Future<Uint8List> generateClaimVoucherPdf({
    required IncentiveClaimModel claim,
    required String workerName,
    required String workerAshaId,
    String village = 'Rampur',
    String phc = 'PHC Rampur',
    String subCenter = 'SC Rampur-A',
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          // 1. Header
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue800, width: 2)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'NATIONAL HEALTH MISSION - STATE HEALTH SOCIETY',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'ASHA MONTHLY PERFORMANCE INCENTIVE CLAIM VOUCHER',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Official Format for ANM / AF Verification and BPMU Payment Processing (ASHA Soft / PFMS)',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'PERIOD: ${claim.claimPeriod}',
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: pw.BoxDecoration(
                        color: claim.status == 'approved'
                            ? PdfColors.green100
                            : (claim.status == 'submitted' ? PdfColors.blue100 : PdfColors.amber100),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                      ),
                      child: pw.Text(
                        'STATUS: ${claim.status.toUpperCase()}',
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                          color: claim.status == 'approved'
                              ? PdfColors.green900
                              : (claim.status == 'submitted' ? PdfColors.blue900 : PdfColors.amber900),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'VOUCHER ID: ${claim.id.substring(0, claim.id.length > 8 ? 8 : claim.id.length)}',
                      style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // 2. ASHA & Location Details
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: const pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('ASHA Name: $workerName', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text('ASHA ID: $workerAshaId', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800)),
                      pw.SizedBox(height: 2),
                      pw.Text('Village: $village', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800)),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Sub-Centre: $subCenter', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800)),
                      pw.SizedBox(height: 2),
                      pw.Text('PHC / Sector: $phc', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800)),
                      pw.SizedBox(height: 2),
                      pw.Text('Payment Reference: ${claim.paymentReference ?? "Pending Allocation"}',
                          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800)),
                    ],
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    border: pw.Border.all(color: PdfColors.blue300, width: 1),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text('TOTAL CLAIM', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Rs. ${claim.totalAmount.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text('${claim.lineItems.length} Activities',
                          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // 3. Claim Line Items Table (Req 56.1, 56.7)
          pw.Text(
            'CLAIM LINE ITEMS (MINIMUM DE-IDENTIFIED BENEFICIARY RECORDS)',
            style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(55), // Date
              1: const pw.FixedColumnWidth(110), // Task Code (prevent truncation, Property 12)
              2: const pw.FlexColumnWidth(2.0), // Task Name
              3: const pw.FixedColumnWidth(60), // Beneficiary Coded ID
              4: const pw.FixedColumnWidth(50), // Evidence ID
              5: const pw.FixedColumnWidth(48), // Status
              6: const pw.FixedColumnWidth(55), // Amount
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _tableCell('Date', isHeader: true),
                  _tableCell('Task Code', isHeader: true),
                  _tableCell('Task Description', isHeader: true),
                  _tableCell('Beneficiary ID', isHeader: true),
                  _tableCell('Evidence ID', isHeader: true),
                  _tableCell('Status', isHeader: true),
                  _tableCell('Amount', isHeader: true, alignRight: true),
                ],
              ),
              ...claim.lineItems.map(
                (item) => pw.TableRow(
                  children: [
                    _tableCell(item.serviceDate.toIso8601String().substring(0, 10)),
                    _tableCell(item.activityCode, fontSize: 7.0),
                    _tableCell(item.activityName),
                    _tableCell(item.memberCodedId),
                    _tableCell(item.evidenceRecordId.isNotEmpty
                        ? (item.evidenceRecordId.length > 8
                            ? item.evidenceRecordId.substring(0, 8)
                            : item.evidenceRecordId)
                        : '-'),
                    _tableCell(item.status.toUpperCase()),
                    _tableCell('Rs. ${item.amount.toStringAsFixed(2)}', alignRight: true),
                  ],
                ),
              ),
              // Total Row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _tableCell('Total', isHeader: true),
                  _tableCell(''),
                  _tableCell('${claim.lineItems.length} Activities Claimed', isHeader: true),
                  _tableCell(''),
                  _tableCell(''),
                  _tableCell(''),
                  _tableCell('Rs. ${claim.totalAmount.toStringAsFixed(2)}', isHeader: true, alignRight: true),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // 4. Verifier & BPMU Certification Box
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'STATUTORY VERIFICATION & SIGN-OFF',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'I hereby certify that the above community health and clinical activities were completed during the specified month '
                  'in accordance with NHM operational guidelines. Individual claim line items have been verified against primary encounter '
                  'registers and clinical registers prior to payment authorization.',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
                ),
                pw.SizedBox(height: 35),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _signatureBox('Signature of ASHA Worker'),
                    _signatureBox('Signature of ANM / AF'),
                    _signatureBox('Signature of BPMU / MOIC'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSummaryStat(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
        pw.SizedBox(height: 3),
        pw.Text(value, style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }

  static pw.Widget _signatureBox(String title) {
    return pw.Column(
      children: [
        pw.Container(width: 140, height: 1, color: PdfColors.grey500),
        pw.SizedBox(height: 4),
        pw.Text(title, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
      ],
    );
  }
}
