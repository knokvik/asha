import 'dart:convert';

/// Represents individual payment components for an incentive activity (Req 53.3).
class PaymentComponent {
  final double fixedHonorarium;
  final double performanceIncentive;
  final double stateTopUp;
  final double connectivityAllowance;

  const PaymentComponent({
    this.fixedHonorarium = 0.0,
    this.performanceIncentive = 0.0,
    this.stateTopUp = 0.0,
    this.connectivityAllowance = 0.0,
  });

  double get totalRate =>
      fixedHonorarium + performanceIncentive + stateTopUp + connectivityAllowance;

  Map<String, dynamic> toJson() => {
        'fixed_honorarium': fixedHonorarium,
        'performance_incentive': performanceIncentive,
        'state_top_up': stateTopUp,
        'connectivity_allowance': connectivityAllowance,
      };

  factory PaymentComponent.fromJson(Map<String, dynamic> json) {
    return PaymentComponent(
      fixedHonorarium: (json['fixed_honorarium'] as num?)?.toDouble() ?? 0.0,
      performanceIncentive:
          (json['performance_incentive'] as num?)?.toDouble() ?? 0.0,
      stateTopUp: (json['state_top_up'] as num?)?.toDouble() ?? 0.0,
      connectivityAllowance:
          (json['connectivity_allowance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// A single activity entry within the versioned incentive catalogue (Req 53.1).
class IncentiveCatalogueItem {
  final String activityCode;
  final String activityName;
  final String category;
  final PaymentComponent rates;
  final int submissionWindowDays;
  final String requiredEvidenceType;
  final Map<String, dynamic> eligibilityConditions;
  final Map<String, String> descriptions;
  final Map<String, String> audioClips;
  final Map<String, Map<String, String>> ineligibilityMessages;
  final Map<String, Map<String, String>> ineligibilityAudioClips;

  const IncentiveCatalogueItem({
    required this.activityCode,
    required this.activityName,
    required this.category,
    required this.rates,
    this.submissionWindowDays = 60,
    this.requiredEvidenceType = 'CLINICAL_ENCOUNTER',
    this.eligibilityConditions = const {},
    this.descriptions = const {},
    this.audioClips = const {},
    this.ineligibilityMessages = const {},
    this.ineligibilityAudioClips = const {},
  });

  String getDescription(String lang) {
    return descriptions[lang] ??
        descriptions['en'] ??
        descriptions.values.firstOrNull ??
        activityName;
  }

  String? getAudioClip(String lang) {
    return audioClips[lang] ?? audioClips['en'] ?? audioClips.values.firstOrNull;
  }

  String? getIneligibilityMessage(String reasonCode, String lang) {
    final reasons = ineligibilityMessages[reasonCode];
    if (reasons == null) return null;
    return reasons[lang] ?? reasons['en'] ?? reasons.values.firstOrNull;
  }

  String? getIneligibilityAudio(String reasonCode, String lang) {
    final audios = ineligibilityAudioClips[reasonCode];
    if (audios == null) return null;
    return audios[lang] ?? audios['en'] ?? audios.values.firstOrNull;
  }

  Map<String, dynamic> toJson() => {
        'activity_code': activityCode,
        'activity_name': activityName,
        'category': category,
        'rates': rates.toJson(),
        'submission_window_days': submissionWindowDays,
        'required_evidence_type': requiredEvidenceType,
        'eligibility_conditions': eligibilityConditions,
        'descriptions': descriptions,
        'audio_clips': audioClips,
        'ineligibility_messages': ineligibilityMessages,
        'ineligibility_audio_clips': ineligibilityAudioClips,
      };

  factory IncentiveCatalogueItem.fromJson(Map<String, dynamic> json) {
    final rawIneligMsgs = json['ineligibility_messages'] as Map<String, dynamic>? ?? {};
    final ineligMessages = rawIneligMsgs.map((k, v) {
      if (v is Map) {
        return MapEntry(k, Map<String, String>.from(v));
      }
      return MapEntry(k, <String, String>{'en': v.toString()});
    });

    final rawIneligAudios =
        json['ineligibility_audio_clips'] as Map<String, dynamic>? ?? {};
    final ineligAudios = rawIneligAudios.map((k, v) {
      if (v is Map) {
        return MapEntry(k, Map<String, String>.from(v));
      }
      return MapEntry(k, <String, String>{'en': v.toString()});
    });

    return IncentiveCatalogueItem(
      activityCode: json['activity_code'] as String,
      activityName: json['activity_name'] as String? ?? json['activity_code'] as String,
      category: json['category'] as String? ?? 'GENERAL',
      rates: PaymentComponent.fromJson(
          json['rates'] as Map<String, dynamic>? ?? {}),
      submissionWindowDays: json['submission_window_days'] as int? ?? 60,
      requiredEvidenceType:
          json['required_evidence_type'] as String? ?? 'CLINICAL_ENCOUNTER',
      eligibilityConditions:
          Map<String, dynamic>.from(json['eligibility_conditions'] as Map? ?? {}),
      descriptions:
          Map<String, String>.from(json['descriptions'] as Map? ?? {}),
      audioClips: Map<String, String>.from(json['audio_clips'] as Map? ?? {}),
      ineligibilityMessages: ineligMessages,
      ineligibilityAudioClips: ineligAudios,
    );
  }
}

/// A state-specific, versioned incentive catalogue (Req 53.1, 53.2).
class IncentiveCatalogue {
  final String versionId;
  final String stateCode;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final String? description;
  final Map<String, IncentiveCatalogueItem> items;

  IncentiveCatalogue({
    required this.versionId,
    required this.stateCode,
    required this.effectiveFrom,
    this.effectiveTo,
    this.description,
    required Map<String, IncentiveCatalogueItem> items,
  }) : items = Map.unmodifiable(items);

  IncentiveCatalogueItem? getItem(String activityCode) => items[activityCode];

  bool isEffective(DateTime date) {
    if (date.isBefore(effectiveFrom)) return false;
    if (effectiveTo != null && date.isAfter(effectiveTo!)) return false;
    return true;
  }

  Map<String, dynamic> toJson() => {
        'version_id': versionId,
        'state_code': stateCode,
        'effective_from': effectiveFrom.toIso8601String(),
        'effective_to': effectiveTo?.toIso8601String(),
        'description': description,
        'items': items.values.map((i) => i.toJson()).toList(),
      };

  factory IncentiveCatalogue.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    final itemsMap = <String, IncentiveCatalogueItem>{};
    for (final itemJson in itemsList) {
      if (itemJson is Map<String, dynamic>) {
        final item = IncentiveCatalogueItem.fromJson(itemJson);
        itemsMap[item.activityCode] = item;
      }
    }

    return IncentiveCatalogue(
      versionId: json['version_id'] as String,
      stateCode: json['state_code'] as String? ?? 'DEFAULT',
      effectiveFrom: DateTime.parse(json['effective_from'] as String),
      effectiveTo: json['effective_to'] != null
          ? DateTime.parse(json['effective_to'] as String)
          : null,
      description: json['description'] as String?,
      items: itemsMap,
    );
  }

  factory IncentiveCatalogue.fromJsonString(String jsonString) {
    return IncentiveCatalogue.fromJson(
        json.decode(jsonString) as Map<String, dynamic>);
  }
}

/// Status of an incentive event.
class IncentiveStatus {
  static const String eligible = 'eligible';
  static const String deferred = 'deferred';
  static const String ineligible = 'ineligible';
  static const String claimed = 'claimed';
  static const String verified = 'verified';
  static const String approved = 'approved';
  static const String paid = 'paid';
  static const String rejected = 'rejected';
  static const String flaggedReview = 'flagged_review';
}

/// Result of evaluating an activity's eligibility criteria (Req 54.1, 54.2, 54.3, 54.4).
class EligibilityCheckResult {
  final String activityCode;
  final bool isEligible;
  final bool isDeferred;
  final double completionProgress; // 0.0 to 1.0
  final int? completedCount;
  final int? requiredCount;
  final String? ineligibilityReasonCode;
  final String? ineligibilityReasonText;
  final String? audioClipPath;
  final String? evidenceRecordId;
  final PaymentComponent? rates;

  const EligibilityCheckResult({
    required this.activityCode,
    required this.isEligible,
    this.isDeferred = false,
    this.completionProgress = 1.0,
    this.completedCount,
    this.requiredCount,
    this.ineligibilityReasonCode,
    this.ineligibilityReasonText,
    this.audioClipPath,
    this.evidenceRecordId,
    this.rates,
  });

  bool get isPartiallyComplete =>
      !isEligible && isDeferred && completionProgress > 0 && completionProgress < 1.0;
}
