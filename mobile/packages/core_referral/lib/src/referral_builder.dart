import 'package:core_model/core_model.dart';

import 'referral_labels.dart';
import 'referral_note.dart';

/// Builds the two-tier referral note of §11.2.
///
/// Pure template rendering. Given the same record it produces the same bytes,
/// which is what makes a referral auditable months later.
abstract final class ReferralNoteBuilder {
  static const _rule = '────────────────────────────────────────';

  static ReferralNote build({
    required ClinicalAssessmentDocument document,
    required ClinicalTriageResult result,
    required ReferralContext context,
    String locale = 'en',
  }) {
    final header = _actionHeader(document: document, result: result, context: context, locale: locale);
    final body = _fullRecord(document: document, result: result, context: context, locale: locale);

    return ReferralNote(
      actionHeader: header,
      plainText: [
        _rule,
        ReferralLabels.section('title', locale),
        ReferralLabels.section('generatedBy', locale),
        ReferralLabels.section('disclaimer', locale),
        _rule,
        header,
        _rule,
        body,
        _rule,
      ].join('\n'),
      structured: _structured(document: document, result: result, context: context, locale: locale),
    );
  }

  // ── Tier 1 ────────────────────────────────────────────────────────────────
  //
  // At most 8 lines, readable in five seconds in a corridor. Every line here
  // earns its place by removing a phone call the doctor would otherwise make.

  static String _actionHeader({
    required ClinicalAssessmentDocument document,
    required ClinicalTriageResult result,
    required ReferralContext context,
    required String locale,
  }) {
    final lines = <String>[
      '${ReferralLabels.bandSymbol(result.band)} ${ReferralLabels.bandImperative(result.band, locale)}',
      _identityLine(document, context),
      _summaryLine(document, locale),
      '${ReferralLabels.section('why', locale)}: ${_primaryReason(result, locale)}',
      '${ReferralLabels.section('dangerSigns', locale)}: ${_dangerSignSummary(document, locale)}',
    ];

    final notChecked = _notCheckedSummary(document, result, locale);
    if (notChecked != null) {
      lines.add('${ReferralLabels.section('notChecked', locale)}: $notChecked');
    }
    if (result.escalatedByWorker) {
      lines.add('${ReferralLabels.section('escalated', locale)}: ${document.workerOverride.note ?? "—"}');
    }
    lines.add(_workerLine(context));

    return lines.where((line) => line.trim().isNotEmpty).join('\n');
  }

  static String _identityLine(ClinicalAssessmentDocument document, ReferralContext context) {
    final parts = <String>[
      context.patientLocalCode,
      _sexWord(document.patient.sex),
      formatAge(document.patient.ageMonths),
      if (document.patient.weightKg != null) '${document.patient.weightKg} kg',
      if (document.patient.village != null && document.patient.village!.isNotEmpty) document.patient.village!,
    ];
    return parts.join(' · ');
  }

  /// Complaints with durations plus the two numbers a clinician looks for first.
  static String _summaryLine(ClinicalAssessmentDocument document, String locale) {
    final complaints = <String>[];
    for (final entry in const {
      FieldPaths.fever: FieldPaths.feverDurationDays,
      FieldPaths.cough: FieldPaths.coughDurationDays,
      FieldPaths.diarrhoea: FieldPaths.diarrhoeaDurationDays,
    }.entries) {
      final symptom = document.fields[entry.key];
      if (symptom == null || symptom.value?.toString().toUpperCase() != 'YES') continue;
      final duration = document.fields[entry.value]?.value;
      final label = ReferralLabels.field(entry.key, locale).toUpperCase();
      complaints.add(duration == null ? label : '$label ${duration}d');
    }

    final vitals = <String>[];
    final temperature = document.fields[FieldPaths.temperatureC];
    if (temperature != null && temperature.isKnown) {
      vitals.add('${ReferralLabels.field(FieldPaths.temperatureC, locale)} ${temperature.value}');
    }
    final respiratoryRate = document.fields[FieldPaths.respiratoryRate];
    if (respiratoryRate != null && respiratoryRate.isKnown) {
      vitals.add('RR ${respiratoryRate.value}');
    }

    final segments = [complaints.join(' + '), vitals.join(' · ')].where((s) => s.isNotEmpty);
    return segments.join(' · ');
  }

  /// Exactly one WHY line — the highest-severity fired rule, with its numbers.
  /// Additional reasons belong to Tier 2 (§11.2).
  static String _primaryReason(ClinicalTriageResult result, String locale) {
    if (result.firedRules.isEmpty) return '—';
    final primary = result.firedRules.first;
    return '${primary.reasonText} [${primary.ruleId}]';
  }

  /// The explicit negative line. Absence of a danger sign is clinical
  /// information, and stating it prevents a call back to ask.
  static String _dangerSignSummary(ClinicalAssessmentDocument document, String locale) {
    final screened = FieldPaths.mandatoryDangerSigns;
    final positive = <String>[];
    var answered = 0;

    for (final path in screened) {
      final value = document.fields[path];
      if (value == null || !value.isKnown) continue;
      answered++;
      if (value.value?.toString().toUpperCase() == 'YES') {
        positive.add(ReferralLabels.field(path, locale));
      }
    }

    if (positive.isEmpty) {
      // §11.2.1 wording: "none of 7 present".
      return '${ReferralLabels.section('noneOf', locale)} $answered '
          '${ReferralLabels.section('present', locale)}';
    }
    return '${positive.join(', ')} ${ReferralLabels.section('present', locale)} '
        '(${positive.length}/${screened.length})';
  }

  /// Every unobtainable or unanswered field a doctor might otherwise assume is
  /// normal. This is the line that removes the most back-and-forth (§11.2).
  static String? _notCheckedSummary(
    ClinicalAssessmentDocument document,
    ClinicalTriageResult result,
    String locale,
  ) {
    final missing = _missingFields(document, result);
    if (missing.isEmpty) return null;
    return missing.map((path) => ReferralLabels.field(path, locale)).join(', ');
  }

  static List<String> _missingFields(ClinicalAssessmentDocument document, ClinicalTriageResult result) {
    final missing = <String>{...result.flooredBy, ...result.blockingQuestions};
    for (final path in [FieldPaths.temperatureC, FieldPaths.respiratoryRate, FieldPaths.muacMm]) {
      final value = document.fields[path];
      if (value == null || !value.isKnown) missing.add(path);
    }
    final ordered = missing.toList()..sort();
    return ordered;
  }

  static String _workerLine(ReferralContext context) {
    final parts = <String>[
      'ASHA ${context.workerName} (${context.workerCode})',
      formatTimestamp(context.generatedAt),
      if (context.workerContact != null && context.workerContact!.isNotEmpty)
        'reachable ${context.workerContact}',
    ];
    return parts.join(' · ');
  }

  // ── Tier 2 ────────────────────────────────────────────────────────────────

  static String _fullRecord({
    required ClinicalAssessmentDocument document,
    required ClinicalTriageResult result,
    required ReferralContext context,
    required String locale,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('${ReferralLabels.section('patient', locale)}: ${context.patientLocalCode}'
        '    AGE: ${formatAge(document.patient.ageMonths)}'
        '    SEX: ${document.patient.sex.wireName}');
    if (document.patient.village != null) {
      buffer.writeln('VILLAGE: ${document.patient.village}'
          '${document.patient.weightKg != null ? '    WEIGHT: ${document.patient.weightKg} kg' : ''}');
    }
    buffer.writeln('ASSESSED BY: ASHA ${context.workerName} (${context.workerCode})');
    buffer.writeln('DATE/TIME: ${formatTimestamp(document.createdAtDevice)}');
    buffer.writeln('${ReferralLabels.section('encounter', locale)}: ${document.encounterType.wireName}');
    if (document.previousBand != null) {
      buffer.writeln('PREVIOUS BAND: ${document.previousBand}');
    }
    buffer.writeln();

    _writeComplaints(buffer, document, locale);
    _writeVitals(buffer, document, locale);
    _writeScreenedDangerSigns(buffer, document, locale);

    buffer.writeln('${ReferralLabels.section('triage', locale)}: '
        '${ReferralLabels.bandSymbol(result.band)} ${ReferralLabels.bandImperative(result.band, locale)}');
    buffer.writeln();

    buffer.writeln(ReferralLabels.section('whyBand', locale));
    for (final rule in result.firedRules) {
      buffer.writeln('  - [${rule.ruleId}] ${rule.reasonText}'
          '${rule.sourceRef != null ? ' (${rule.sourceRef})' : ''}');
    }
    buffer.writeln();

    final limitations = _limitations(document, result, locale);
    if (limitations.isNotEmpty) {
      buffer.writeln(ReferralLabels.section('limitations', locale));
      for (final line in limitations) {
        buffer.writeln('  - $line');
      }
      buffer.writeln();
    }

    buffer.writeln(ReferralLabels.section('advice', locale));
    buffer.writeln('  - ${ReferralLabels.advice(result.adviceKey, locale)}');
    buffer.writeln();

    if (document.workerNotes != null && document.workerNotes!.trim().isNotEmpty) {
      buffer.writeln(ReferralLabels.section('workerNote', locale));
      buffer.writeln('  ${document.workerNotes!.trim()}');
      buffer.writeln();
    }

    // SI-9 — the versions that produced this decision travel with it.
    buffer.writeln('Ruleset ${result.rulesetVersion} · Engine ${result.engineVersion} '
        '· Extractor ${document.versions.extractor} · ASR ${document.versions.asrModel} '
        '· App ${context.appVersion}');
    buffer.write(ReferralLabels.section('footer', locale));

    return buffer.toString();
  }

  static void _writeComplaints(
    StringBuffer buffer,
    ClinicalAssessmentDocument document,
    String locale,
  ) {
    buffer.writeln(ReferralLabels.section('complaints', locale));
    var any = false;
    for (final entry in const {
      FieldPaths.fever: FieldPaths.feverDurationDays,
      FieldPaths.cough: FieldPaths.coughDurationDays,
      FieldPaths.diarrhoea: FieldPaths.diarrhoeaDurationDays,
      FieldPaths.difficultyBreathing: null,
      FieldPaths.bloodInStool: null,
      FieldPaths.vomiting: null,
    }.entries) {
      final value = document.fields[entry.key];
      if (value == null || value.value?.toString().toUpperCase() != 'YES') continue;
      any = true;
      final duration = entry.value == null ? null : document.fields[entry.value!]?.value;
      buffer.writeln('  - ${ReferralLabels.field(entry.key, locale)}'
          '${duration != null ? ' — $duration days' : ''}');
    }
    if (!any) buffer.writeln('  - —');
    buffer.writeln();
  }

  static void _writeVitals(StringBuffer buffer, ClinicalAssessmentDocument document, String locale) {
    buffer.writeln(ReferralLabels.section('vitals', locale));
    const units = {
      FieldPaths.temperatureC: '°C',
      FieldPaths.respiratoryRate: '/min',
      FieldPaths.muacMm: 'mm',
    };
    for (final path in units.keys) {
      final value = document.fields[path];
      final label = ReferralLabels.field(path, locale).padRight(22, '.');
      if (value != null && value.isKnown) {
        buffer.writeln('  $label ${value.value} ${units[path]}');
      } else {
        buffer.writeln('  $label ${ReferralLabels.section('notMeasured', locale)}');
      }
    }
    buffer.writeln();
  }

  static void _writeScreenedDangerSigns(
    StringBuffer buffer,
    ClinicalAssessmentDocument document,
    String locale,
  ) {
    buffer.writeln(ReferralLabels.section('screened', locale));
    for (final path in FieldPaths.mandatoryDangerSigns) {
      final value = document.fields[path];
      final label = ReferralLabels.field(path, locale).padRight(36, '.');
      buffer.writeln('  $label ${ReferralLabels.answer(value?.isKnown == true ? value!.value : null, locale)}');
    }
    buffer.writeln();
  }

  static List<String> _limitations(
    ClinicalAssessmentDocument document,
    ClinicalTriageResult result,
    String locale,
  ) {
    final lines = <String>[];
    for (final path in result.flooredBy) {
      lines.add('${ReferralLabels.field(path, locale)} — '
          '${ReferralLabels.section('notMeasured', locale)}; related criteria could not be excluded.');
    }
    for (final path in _missingFields(document, result)) {
      if (result.flooredBy.contains(path)) continue;
      lines.add('${ReferralLabels.field(path, locale)} — '
          '${ReferralLabels.section('notMeasured', locale)}.');
    }
    if (result.escalatedByWorker) {
      lines.add('Band raised to RED by the health worker, not by a rule threshold.');
    }
    return lines;
  }

  // ── Structured output (§11.3) ─────────────────────────────────────────────

  static JsonMap _structured({
    required ClinicalAssessmentDocument document,
    required ClinicalTriageResult result,
    required ReferralContext context,
    required String locale,
  }) => {
    'schema_version': '1.0.0',
    'assessment_id': document.assessmentId,
    'patient_local_code': context.patientLocalCode,
    'band': result.band.wireName,
    'band_imperative': ReferralLabels.bandImperative(result.band, locale),
    'generated_at': context.generatedAt.toIso8601String(),
    'worker': {
      'name': context.workerName,
      'code': context.workerCode,
      'contact': context.workerContact,
    },
    'primary_reason': result.firedRules.isEmpty
        ? null
        : {
            'rule_id': result.firedRules.first.ruleId,
            'text': result.firedRules.first.reasonText,
            'evidence': result.firedRules.first.evidence,
            'source_ref': result.firedRules.first.sourceRef,
          },
    'all_reasons': result.firedRules.map((rule) => rule.toJson()).toList(growable: false),
    'danger_signs_screened': {
      for (final path in FieldPaths.mandatoryDangerSigns)
        path: document.fields[path]?.isKnown == true ? document.fields[path]!.value : null,
    },
    'not_checked': _missingFields(document, result),
    'floored_by': result.flooredBy,
    'escalated_by_worker': result.escalatedByWorker,
    'advice_key': result.adviceKey,
    'versions': {
      'ruleset': result.rulesetVersion,
      'engine': result.engineVersion,
      'extractor': document.versions.extractor,
      'asr_model': document.versions.asrModel,
      'app': context.appVersion,
    },
  };

  // ── Formatting helpers ────────────────────────────────────────────────────

  /// "2 y 0 m" — the form a pediatrician reads fastest.
  static String formatAge(int ageMonths) {
    if (ageMonths < 0) return '—';
    final years = ageMonths ~/ 12;
    final months = ageMonths % 12;
    return years == 0 ? '$months m' : '$years y $months m';
  }

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String formatTimestamp(DateTime time) {
    final day = time.day.toString().padLeft(2, '0');
    final month = _monthNames[time.month - 1];
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$day-$month $hour:$minute';
  }

  static String _sexWord(PatientSex sex) => switch (sex) {
    PatientSex.male => 'Male',
    PatientSex.female => 'Female',
    PatientSex.other => 'Other',
    PatientSex.unknown => 'Sex unknown',
  };
}
