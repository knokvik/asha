import 'models.dart';

/// English pre-referral lines from the IMCI treat column.
const imciActionText = <String, String>{
  'refer_urgently': 'Refer urgently to the health facility.',
  'first_dose_antibiotic': 'Give the first dose of an appropriate antibiotic.',
  'prevent_low_blood_sugar': 'Prevent low blood sugar: breastfeed or give sugar water.',
  'ors': 'Start ORS and continue feeding.',
  'antimalarial': 'Give the first dose of the antimalarial if malaria is confirmed.',
  'keep_warm': 'Keep the child warm on the way.',
  'follow_up': 'Tell the caregiver the day to come back.',
};

class ReferralNote {
  const ReferralNote({
    required this.result,
    required this.patient,
    required this.facility,
    required this.urgency,
    required this.actions,
    required this.suspectedDisease,
    required this.outbreakContext,
    required this.vitals,
    required this.symptoms,
    required this.wardId,
    required this.referralId,
    this.suggestedFacilityId,
  });

  final TriageResult result;
  final PatientProfile patient;
  final FacilityProfile facility;
  final String urgency;
  final List<String> actions;
  final String suspectedDisease;

  /// Filled from the ward pack. Empty when no outbreak module is active.
  final String outbreakContext;
  final Vitals vitals;
  final Symptoms symptoms;
  final String wardId;
  final String referralId;

  /// Null until the maps module picks a facility. The name on [facility] is the fallback.
  final String? suggestedFacilityId;

  factory ReferralNote.fromResult(
    TriageResult result,
    PatientProfile patient,
    FacilityProfile facility, {
    String outbreakContext = '',
    String wardId = '',
    String referralId = '',
    Vitals vitals = const Vitals(),
    Symptoms symptoms = const Symptoms(),
    String? suggestedFacilityId,
  }) {
    final actions = <String>[];
    for (final rule in result.firedRules) {
      for (final action in rule.actions) {
        final line = imciActionText[action] ?? action;
        if (!actions.contains(line)) actions.add(line);
      }
    }
    final disease = result.firedRules
        .where((rule) => rule.severity == result.flag && rule.suspectedDisease.isNotEmpty)
        .map((rule) => rule.suspectedDisease)
        .toSet()
        .join('; ');
    return ReferralNote(
      result: result,
      patient: patient,
      facility: facility,
      urgency: result.flag.urgency,
      actions: actions,
      suspectedDisease: disease,
      outbreakContext: outbreakContext,
      vitals: vitals,
      symptoms: symptoms,
      wardId: wardId,
      referralId: referralId.isEmpty ? patient.id : referralId,
      suggestedFacilityId: suggestedFacilityId,
    );
  }

  String toMarkdown() {
    final buffer = StringBuffer()
      ..writeln('# Referral ${result.flag.wireName}')
      ..writeln()
      ..writeln('Urgency: $urgency')
      ..writeln('Facility: ${facility.name}')
      ..writeln()
      ..writeln('## Patient')
      ..writeln('- ABHA: ${patient.abhaId}')
      ..writeln('- Name: ${patient.name}')
      ..writeln('- Age: ${patient.ageMonths} months')
      ..writeln('- Sex: ${patient.sex}')
      ..writeln('- Village: ${patient.village}')
      ..writeln('- Ward: ${wardId.isEmpty ? 'not set' : wardId}')
      ..writeln()
      ..writeln('## Assessment')
      ..writeln('- Respiratory rate: ${_num(vitals.respiratoryRate, '/min')}')
      ..writeln('- Temperature: ${_num(vitals.tempC, 'C')}')
      ..writeln('- Weight: ${_num(vitals.weightKg, 'kg')}')
      ..writeln('- Weight-for-age Z: ${_num(vitals.weightForAgeZscore, '')}')
      ..writeln('- Signs: ${symptoms.notedSigns.isEmpty ? 'none recorded' : symptoms.notedSigns.join(', ')}')
      ..writeln()
      ..writeln('## Why')
    ;
    if (result.firedRules.isEmpty) {
      buffer.writeln('- No IMCI sign fired. Home care.');
    } else {
      for (final rule in result.firedRules) {
        buffer.writeln('- ${rule.ruleId} (${rule.severity.wireName}): ${rule.reasonText}');
      }
    }
    buffer
      ..writeln()
      ..writeln('## Before referral');
    if (actions.isEmpty) {
      buffer.writeln('- Counsel on home care and when to return.');
    } else {
      for (final action in actions) {
        buffer.writeln('- $action');
      }
    }
    if (result.followUpDays != null) {
      buffer.writeln('- Follow up in ${result.followUpDays} days.');
    }
    buffer
      ..writeln()
      ..writeln('## Suspected')
      ..writeln(suspectedDisease.isEmpty ? 'Not named by a rule.' : suspectedDisease)
      ..writeln()
      ..writeln('## Suggested facility')
      ..writeln(suggestedFacilityId ?? 'Not chosen yet. ${facility.name} is the placeholder.')
      ..writeln()
      ..writeln('## Outbreak context')
      ..writeln(outbreakContext.isEmpty ? 'Not supplied.' : outbreakContext);
    return buffer.toString().trimRight();
  }

  /// `REF|id|FLAG|age|sex|RR|T|top three rule ids|ward`. At most 160 characters.
  /// The child's name and any phone number stay off this line.
  String toSms() {
    final rr = vitals.respiratoryRate == null ? '-' : vitals.respiratoryRate!.round().toString();
    final temp = vitals.tempC == null ? '-' : vitals.tempC!.toStringAsFixed(1);
    final signs = result.firedRules.take(3).map((rule) => rule.ruleId).join(',');
    final ward = wardId.isEmpty ? '-' : wardId;
    final line = 'REF|$referralId|${result.flag.wireName}|${patient.ageMonths}m|${patient.sex}|RR$rr|T$temp|$signs|$ward';
    if (line.length <= 160) return line;
    final shorter = 'REF|$referralId|${result.flag.wireName}|${patient.ageMonths}m|${patient.sex}|RR$rr|T$temp||$ward';
    if (shorter.length <= 160) return shorter;
    return shorter.substring(0, 160);
  }

  /// FHIR R4 document Bundle shaped like an OPConsultation record.
  Map<String, Object?> toFhirBundle() {
    final observations = <Map<String, Object?>>[];
    void addQuantity(String label, num? value, String unit) {
      if (value == null) return;
      observations.add({
        'resourceType': 'Observation',
        'status': 'final',
        'code': {'text': label},
        'valueQuantity': {'value': value, 'unit': unit},
      });
    }

    addQuantity('Respiratory rate', vitals.respiratoryRate, '/min');
    addQuantity('Body temperature', vitals.tempC, 'Cel');
    addQuantity('Body weight', vitals.weightKg, 'kg');
    addQuantity('Weight-for-age Z-score', vitals.weightForAgeZscore, '{Z}');
    final conditions = <Map<String, Object?>>[
      for (final rule in result.firedRules)
        {
          'resourceType': 'Condition',
          'clinicalStatus': {
            'coding': [
              {'code': 'active'},
            ],
          },
          'code': {'text': rule.suspectedDisease.isEmpty ? rule.reasonText : rule.suspectedDisease},
          'severity': {'text': rule.severity.wireName},
          'note': [
            {'text': '${rule.ruleId}: ${rule.reasonText}'},
          ],
        },
    ];

    return {
      'resourceType': 'Bundle',
      'type': 'document',
      'entry': [
        {
          'resource': {
            'resourceType': 'Patient',
            'id': patient.id,
            'identifier': [
              {'system': 'https://healthid.ndhm.gov.in', 'value': patient.abhaId},
            ],
            'name': [
              {'text': patient.name},
            ],
            'gender': _fhirGender(patient.sex),
            'address': [
              {'city': patient.village, 'district': patient.village},
            ],
          },
        },
        {
          'resource': {
            'resourceType': 'Encounter',
            'status': 'finished',
            'class': {'code': 'AMB', 'display': 'ambulatory'},
            'serviceProvider': {
              'display': facility.name,
              'identifier': {'value': facility.id},
            },
          },
        },
        for (final observation in observations) {'resource': observation},
        for (final condition in conditions) {'resource': condition},
      ],
    };
  }
}

String _num(num? value, String unit) {
  if (value == null) return 'not measured';
  final text = value == value.roundToDouble() ? value.toInt().toString() : value.toString();
  return unit.isEmpty ? text : '$text $unit';
}

String _fhirGender(String sex) {
  final value = sex.toLowerCase();
  if (value.startsWith('m')) return 'male';
  if (value.startsWith('f')) return 'female';
  return 'unknown';
}
