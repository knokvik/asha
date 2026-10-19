import 'clinical_assessment.dart';
import 'sourced_value.dart';

enum EncounterType { initial, followUp }

extension EncounterTypeX on EncounterType {
  String get wireName => this == EncounterType.initial ? 'INITIAL' : 'FOLLOW_UP';
  static EncounterType fromWire(Object? value) => value == 'FOLLOW_UP' ? EncounterType.followUp : EncounterType.initial;
}

enum InputMode { voice, manual, mixed }

extension InputModeX on InputMode {
  String get wireName => name.toUpperCase();
  static InputMode fromWire(Object? value) =>
      InputMode.values.firstWhere((mode) => mode.wireName == value, orElse: () => InputMode.manual);
}

/// Capture metadata (architecture.md §7.1 `capture`).
class CaptureMetadata {
  const CaptureMetadata({
    this.inputMode = InputMode.manual,
    this.language = 'hi-IN',
    this.transcriptRaw,
    this.transcriptConfidence,
    this.audioRetained = false,
  });

  final InputMode inputMode;
  final String language;
  final String? transcriptRaw;
  final double? transcriptConfidence;
  final bool audioRetained;

  JsonMap toJson() => {
    'input_mode': inputMode.wireName,
    'language': language,
    'transcript_raw': transcriptRaw,
    'transcript_confidence': transcriptConfidence,
    'audio_retained': audioRetained,
  };

  factory CaptureMetadata.fromJson(Object? raw) {
    final map = (raw as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    return CaptureMetadata(
      inputMode: InputModeX.fromWire(map['input_mode']),
      language: map['language'] as String? ?? 'hi-IN',
      transcriptRaw: map['transcript_raw'] as String?,
      transcriptConfidence: (map['transcript_confidence'] as num?)?.toDouble(),
      audioRetained: map['audio_retained'] == true,
    );
  }
}

/// SI-9 traceability block. Every stored result records all five versions.
class VersionStamp {
  const VersionStamp({
    required this.app,
    this.schema = ClinicalAssessmentDocument.schemaVersion,
    required this.ruleset,
    required this.engine,
    required this.extractor,
    required this.asrModel,
  });

  final String app;
  final String schema;
  final String ruleset;
  final String engine;
  final String extractor;
  final String asrModel;

  JsonMap toJson() => {
    'app': app,
    'schema': schema,
    'ruleset': ruleset,
    'engine': engine,
    'extractor': extractor,
    'asr_model': asrModel,
  };

  factory VersionStamp.fromJson(Object? raw) {
    final map = (raw as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    return VersionStamp(
      app: map['app'] as String? ?? 'unknown',
      schema: map['schema'] as String? ?? ClinicalAssessmentDocument.schemaVersion,
      ruleset: map['ruleset'] as String? ?? 'unknown',
      engine: map['engine'] as String? ?? 'unknown',
      extractor: map['extractor'] as String? ?? 'unknown',
      asrModel: map['asr_model'] as String? ?? 'none',
    );
  }
}

class PatientDemographics {
  const PatientDemographics({
    required this.ageMonths,
    this.sex = PatientSex.unknown,
    this.village,
    this.weightKg,
    this.caregiverContact,
  });

  final int ageMonths;
  final PatientSex sex;
  final String? village;
  final double? weightKg;
  final String? caregiverContact;

  JsonMap toJson() => {
    'age_months': ageMonths,
    'sex': sex.wireName,
    'village': village,
    'weight_kg': weightKg,
    'caregiver_contact': caregiverContact,
  };

  factory PatientDemographics.fromJson(Object? raw) {
    final map = (raw as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    return PatientDemographics(
      ageMonths: (map['age_months'] as num?)?.toInt() ?? -1,
      sex: PatientSexX.fromWire(map['sex']),
      village: map['village'] as String?,
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      caregiverContact: map['caregiver_contact'] as String?,
    );
  }
}

/// The full on-the-wire `ClinicalAssessment` of architecture.md §7.1.
///
/// The engine never sees this class — it consumes [toEngineAssessment], the
/// flattened dotted-path projection. Keeping the two apart is what stops
/// transport concerns (ids, versions, transcripts) leaking into clinical logic.
class ClinicalAssessmentDocument {
  const ClinicalAssessmentDocument({
    required this.assessmentId,
    required this.patientId,
    required this.workerId,
    required this.deviceId,
    required this.createdAtDevice,
    required this.patient,
    required this.fields,
    required this.versions,
    this.supersedesId,
    this.encounterType = EncounterType.initial,
    this.followupId,
    this.consentObtained = true,
    this.capture = const CaptureMetadata(),
    this.workerOverride = const WorkerOverride(),
    this.workerNotes,
    this.previousBand,
    this.symptomsImproved,
  });

  static const schemaVersion = '1.0.0';

  /// Client-generated UUID v4. Doubles as the sync idempotency key (§13.3).
  final String assessmentId;
  final String patientId;
  final String workerId;
  final String deviceId;
  final DateTime createdAtDevice;
  final String? supersedesId;
  final EncounterType encounterType;
  final String? followupId;
  final bool consentObtained;
  final PatientDemographics patient;

  /// Flat dotted-path field map — the same keys the ruleset addresses.
  final Map<String, SourcedValue> fields;
  final CaptureMetadata capture;
  final WorkerOverride workerOverride;
  final String? workerNotes;
  final VersionStamp versions;
  final String? previousBand;
  final bool? symptomsImproved;

  /// Projection consumed by the pure engine.
  ClinicalAssessment toEngineAssessment() => ClinicalAssessment(
    ageMonths: patient.ageMonths,
    sex: patient.sex,
    fields: fields,
    workerOverride: workerOverride,
    previousBand: previousBand,
    symptomsImproved: symptomsImproved,
  );

  ClinicalAssessmentDocument copyWith({
    Map<String, SourcedValue>? fields,
    CaptureMetadata? capture,
    WorkerOverride? workerOverride,
    String? workerNotes,
    PatientDemographics? patient,
    String? previousBand,
    bool? symptomsImproved,
  }) => ClinicalAssessmentDocument(
    assessmentId: assessmentId,
    patientId: patientId,
    workerId: workerId,
    deviceId: deviceId,
    createdAtDevice: createdAtDevice,
    supersedesId: supersedesId,
    encounterType: encounterType,
    followupId: followupId,
    consentObtained: consentObtained,
    patient: patient ?? this.patient,
    fields: fields ?? this.fields,
    capture: capture ?? this.capture,
    workerOverride: workerOverride ?? this.workerOverride,
    workerNotes: workerNotes ?? this.workerNotes,
    versions: versions,
    previousBand: previousBand ?? this.previousBand,
    symptomsImproved: symptomsImproved ?? this.symptomsImproved,
  );

  /// Groups the flat field map back into the nested §7.1 shape for storage and
  /// sync, so the JSON a pediatrician reads matches the published contract.
  JsonMap toJson() {
    final grouped = <String, JsonMap>{'symptoms': {}, 'danger_signs': {}, 'observations': {}, 'vitals': {}};
    final extra = <String, dynamic>{};
    for (final entry in fields.entries) {
      final split = entry.key.indexOf('.');
      final group = split < 0 ? '' : entry.key.substring(0, split);
      final leaf = split < 0 ? entry.key : entry.key.substring(split + 1);
      if (grouped.containsKey(group)) {
        grouped[group]![leaf] = entry.value.toJson();
      } else {
        extra[entry.key] = entry.value.toJson();
      }
    }
    return {
      'schema_version': schemaVersion,
      'assessment_id': assessmentId,
      'patient_id': patientId,
      'worker_id': workerId,
      'device_id': deviceId,
      'created_at_device': createdAtDevice.toIso8601String(),
      'supersedes_id': supersedesId,
      'encounter_type': encounterType.wireName,
      'followup_id': followupId,
      'consent_obtained': consentObtained,
      'patient': patient.toJson(),
      ...grouped,
      if (extra.isNotEmpty) 'other': extra,
      'capture': capture.toJson(),
      'worker_override': workerOverride.toJson(),
      'worker_notes': workerNotes,
      'previous_band': previousBand,
      'symptoms_improved': symptomsImproved,
      'versions': versions.toJson(),
    };
  }

  factory ClinicalAssessmentDocument.fromJson(JsonMap json) {
    final fields = <String, SourcedValue>{};
    for (final group in const ['symptoms', 'danger_signs', 'observations', 'vitals']) {
      final raw = (json[group] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
      for (final entry in raw.entries) {
        fields['$group.${entry.key}'] = SourcedValue.fromJson(entry.value);
      }
    }
    final other = (json['other'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    for (final entry in other.entries) {
      fields[entry.key] = SourcedValue.fromJson(entry.value);
    }
    return ClinicalAssessmentDocument(
      assessmentId: json['assessment_id'] as String,
      patientId: json['patient_id'] as String,
      workerId: json['worker_id'] as String? ?? 'unknown',
      deviceId: json['device_id'] as String? ?? 'unknown',
      createdAtDevice: DateTime.parse(json['created_at_device'] as String),
      supersedesId: json['supersedes_id'] as String?,
      encounterType: EncounterTypeX.fromWire(json['encounter_type']),
      followupId: json['followup_id'] as String?,
      consentObtained: json['consent_obtained'] != false,
      patient: PatientDemographics.fromJson(json['patient']),
      fields: fields,
      capture: CaptureMetadata.fromJson(json['capture']),
      workerOverride: WorkerOverride.fromJson(json['worker_override']),
      workerNotes: json['worker_notes'] as String?,
      versions: VersionStamp.fromJson(json['versions']),
      previousBand: json['previous_band'] as String?,
      symptomsImproved: json['symptoms_improved'] as bool?,
    );
  }
}
