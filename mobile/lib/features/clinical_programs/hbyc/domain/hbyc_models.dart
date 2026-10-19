import '../../../../core/triage/models/triage_result.dart';

/// HBYC visit milestones per NHSRC guidelines (Requirement 13.1).
enum HbycMilestone {
  month3('m3', '3 Months', 90, 'HBYC 3rd Month Visit'),
  month6('m6', '6 Months', 180, 'HBYC 6th Month Visit'),
  month9('m9', '9 Months', 270, 'HBYC 9th Month Visit'),
  month12('m12', '12 Months', 365, 'HBYC 12th Month Visit'),
  month15('m15', '15 Months', 455, 'HBYC 15th Month Visit');

  final String code;
  final String label;
  final int ageInDays;
  final String visitTitle;

  const HbycMilestone(this.code, this.label, this.ageInDays, this.visitTitle);

  static HbycMilestone fromCode(String code) {
    return HbycMilestone.values.firstWhere(
      (m) => m.code.toLowerCase() == code.toLowerCase() || m.name.toLowerCase() == code.toLowerCase(),
      orElse: () => HbycMilestone.month3,
    );
  }

  static HbycMilestone fromAgeDays(int ageDays) {
    if (ageDays < 135) return HbycMilestone.month3; // up to ~4.5 months
    if (ageDays < 225) return HbycMilestone.month6; // up to ~7.5 months
    if (ageDays < 315) return HbycMilestone.month9; // up to ~10.5 months
    if (ageDays < 410) return HbycMilestone.month12; // up to ~13.5 months
    return HbycMilestone.month15;
  }
}

/// Infant feeding practice classification (Requirement 13.2).
enum FeedingPractice {
  exclusiveBreastfeeding('exclusive_bf', 'Exclusive Breastfeeding (0-6 months)'),
  complementaryWithBf('comp_with_bf', 'Complementary Feeding + Continued Breastfeeding'),
  complementaryNoBf('comp_no_bf', 'Complementary Feeding without Breastfeeding'),
  animalMilkOnly('animal_milk_only', 'Animal Milk / Formula Only'),
  inadequateDiversity('inadequate_diversity', 'Inadequate Dietary Diversity');

  final String code;
  final String label;
  const FeedingPractice(this.code, this.label);
}

/// Child developmental milestone item (Requirement 13.2, 13.3).
class HbycMilestoneItem {
  final String id;
  final String domain; // Gross Motor, Fine Motor, Language/Cognitive, Social
  final String prompt;
  final String promptHi; // Hindi plain-language prompt
  final HbycMilestone milestone;
  final bool isRedFlagIfAbsent;

  const HbycMilestoneItem({
    required this.id,
    required this.domain,
    required this.prompt,
    required this.promptHi,
    required this.milestone,
    this.isRedFlagIfAbsent = false,
  });
}

/// Standard RBSK/HBYC milestone repository per visit age (Requirement 13.2).
class HbycMilestonesCatalog {
  static const List<HbycMilestoneItem> items = [
    // ── 3 Months Milestones ──────────────────────────────────────────────────
    HbycMilestoneItem(
      id: 'm3_head_control',
      domain: 'Gross Motor',
      prompt: 'Lifts head and chest steadily when lying on tummy',
      promptHi: 'पेट के बल लेटने पर सिर और छाती ऊपर उठाता है',
      milestone: HbycMilestone.month3,
      isRedFlagIfAbsent: true,
    ),
    HbycMilestoneItem(
      id: 'm3_social_smile',
      domain: 'Social / Emotional',
      prompt: 'Smiles back socially in response to mother/caregiver face or voice',
      promptHi: 'माँ या देखभालकर्ता को देखकर मुस्कुराता है (सामाजिक मुस्कान)',
      milestone: HbycMilestone.month3,
    ),
    HbycMilestoneItem(
      id: 'm3_visual_tracking',
      domain: 'Cognitive / Vision',
      prompt: 'Follows colorful toy or caregiver face moving across visual field',
      promptHi: 'सामने हिलती हुई रंगीन वस्तु या चेहरे को आँखों से देखता है',
      milestone: HbycMilestone.month3,
    ),
    HbycMilestoneItem(
      id: 'm3_turns_to_sound',
      domain: 'Language / Hearing',
      prompt: 'Turns head or reacts towards familiar voice or bell sound',
      promptHi: 'आवाज़ या घंटी की ओर सिर घुमाता है या प्रतिक्रिया देता है',
      milestone: HbycMilestone.month3,
    ),

    // ── 6 Months Milestones ──────────────────────────────────────────────────
    HbycMilestoneItem(
      id: 'm6_roll_over',
      domain: 'Gross Motor',
      prompt: 'Rolls over from tummy to back or back to tummy',
      promptHi: 'पीठ से पेट या पेट से पीठ के बल पलट जाता है',
      milestone: HbycMilestone.month6,
    ),
    HbycMilestoneItem(
      id: 'm6_sit_supported',
      domain: 'Gross Motor',
      prompt: 'Sits briefly with support (tripod/prop sitting)',
      promptHi: 'थोड़े सहारे से बैठता है',
      milestone: HbycMilestone.month6,
      isRedFlagIfAbsent: true,
    ),
    HbycMilestoneItem(
      id: 'm6_transfer_objects',
      domain: 'Fine Motor',
      prompt: 'Reaches out and transfers toy/rattle from one hand to the other',
      promptHi: 'खिलौना एक हाथ से दूसरे हाथ में पकड़ता है',
      milestone: HbycMilestone.month6,
    ),
    HbycMilestoneItem(
      id: 'm6_babbles',
      domain: 'Language',
      prompt: 'Babbles repeating consonant sounds (e.g. ba-ba, da-da, ma-ma)',
      promptHi: 'बा-बा, दा-दा, मा-मा जैसी आवाज़ें निकालता है',
      milestone: HbycMilestone.month6,
    ),
    HbycMilestoneItem(
      id: 'm6_responds_name',
      domain: 'Social / Cognitive',
      prompt: 'Responds by turning or smiling when called by own name',
      promptHi: 'अपना नाम पुकारे जाने पर मुड़कर देखता है',
      milestone: HbycMilestone.month6,
    ),

    // ── 9 Months Milestones ──────────────────────────────────────────────────
    HbycMilestoneItem(
      id: 'm9_sit_unsupported',
      domain: 'Gross Motor',
      prompt: 'Sits steadily without any support for at least 1 minute',
      promptHi: 'बिना किसी सहारे के कम से कम 1 मिनट स्थिर बैठता है',
      milestone: HbycMilestone.month9,
      isRedFlagIfAbsent: true,
    ),
    HbycMilestoneItem(
      id: 'm9_crawls_stands_support',
      domain: 'Gross Motor',
      prompt: 'Crawls on tummy/hands-and-knees or stands holding onto furniture',
      promptHi: 'घुटनों के बल चलता है या सहारा पकड़कर खड़ा होता है',
      milestone: HbycMilestone.month9,
    ),
    HbycMilestoneItem(
      id: 'm9_immature_pincer',
      domain: 'Fine Motor',
      prompt: 'Picks up small pieces of food using fingers against thumb (pincer)',
      promptHi: 'अंगूठे और उँगलियों से खाने का छोटा टुकड़ा उठाता है',
      milestone: HbycMilestone.month9,
    ),
    HbycMilestoneItem(
      id: 'm9_peekaboo_bye',
      domain: 'Social / Play',
      prompt: 'Enjoys playing peek-a-boo and waves bye-bye on cue',
      promptHi: 'लुका-छिपी खेलता है और हाथ हिलाकर बाय-बाय करता है',
      milestone: HbycMilestone.month9,
    ),

    // ── 12 Months Milestones ─────────────────────────────────────────────────
    HbycMilestoneItem(
      id: 'm12_stands_alone',
      domain: 'Gross Motor',
      prompt: 'Stands alone momentarily or takes cruising steps holding furniture',
      promptHi: 'कुछ सेकंड बिना सहारे खड़ा होता है या सहारा लेकर कदम बढ़ाता है',
      milestone: HbycMilestone.month12,
      isRedFlagIfAbsent: true,
    ),
    HbycMilestoneItem(
      id: 'm12_neat_pincer',
      domain: 'Fine Motor',
      prompt: 'Neatly pinches small object (e.g. raisin) between tips of thumb and index finger',
      promptHi: 'अंगूठे और तर्जनी उँगली की नोक से छोटी चीज़ उठाता है',
      milestone: HbycMilestone.month12,
    ),
    HbycMilestoneItem(
      id: 'm12_meaningful_words',
      domain: 'Language',
      prompt: 'Says 1 to 2 specific words with meaning (e.g. Papa, Mummy, Pani)',
      promptHi: 'अर्थ के साथ 1-2 शब्द बोलता है (जैसे पापा, मम्मी, पानी)',
      milestone: HbycMilestone.month12,
    ),
    HbycMilestoneItem(
      id: 'm12_simple_commands',
      domain: 'Cognitive',
      prompt: 'Responds to simple verbal requests like "Give me" or "Come here"',
      promptHi: '"इधर आओ" या "दो" जैसे आसान निर्देश समझकर करता है',
      milestone: HbycMilestone.month12,
    ),

    // ── 15 Months Milestones ─────────────────────────────────────────────────
    HbycMilestoneItem(
      id: 'm15_walks_alone',
      domain: 'Gross Motor',
      prompt: 'Walks independently across the room with good balance',
      promptHi: 'कमरे में बिना सहारे के स्वतंत्र रूप से चलता है',
      milestone: HbycMilestone.month15,
      isRedFlagIfAbsent: true,
    ),
    HbycMilestoneItem(
      id: 'm15_builds_tower_cubes',
      domain: 'Fine Motor',
      prompt: 'Stacks 2 blocks/cups on top of each other without toppling',
      promptHi: 'एक के ऊपर एक दो खिलौने/ब्लॉक रखता है',
      milestone: HbycMilestone.month15,
    ),
    HbycMilestoneItem(
      id: 'm15_vocabulary',
      domain: 'Language',
      prompt: 'Uses 3 to 5 clear words consistently to name items',
      promptHi: 'चीज़ों के नाम के लिए 3 से 5 शब्द स्पष्ट बोलता है',
      milestone: HbycMilestone.month15,
    ),
    HbycMilestoneItem(
      id: 'm15_drinks_cup',
      domain: 'Self-Care / Motor',
      prompt: 'Drinks water or milk from an open cup with minimal spilling',
      promptHi: 'कटोरी या कप से बिना ज़्यादा गिराए पानी पीता है',
      milestone: HbycMilestone.month15,
    ),
  ];

  static List<HbycMilestoneItem> forMilestone(HbycMilestone milestone) {
    return items.where((item) => item.milestone == milestone).toList();
  }
}

/// Growth and nutritional assessment values for young child (Requirements 13.2, 13.4).
class HbycGrowthData {
  final double weightKg;
  final double? lengthCm;
  final double? muacCm; // Measured for child >= 6 months
  final bool hasBilateralOedema; // Pitting edema of feet/legs
  final bool hasSevereWasting;
  final bool appetiteTestPassed; // Able to consume RUTF or home porridge

  const HbycGrowthData({
    required this.weightKg,
    this.lengthCm,
    this.muacCm,
    this.hasBilateralOedema = false,
    this.hasSevereWasting = false,
    this.appetiteTestPassed = true,
  });

  /// Evaluates whether the child meets Severe Acute Malnutrition (SAM) criteria (Requirement 13.4, 17.2).
  ///
  /// Criteria per MoHFW guidelines:
  /// 1. MUAC < 11.5 cm (< 115 mm) in child 6–59 months
  /// 2. Bilateral pitting oedema (+, ++, or +++)
  /// 3. Severe visible wasting / failed appetite
  bool isSam({required int ageDays}) {
    if (hasBilateralOedema || hasSevereWasting || !appetiteTestPassed) {
      return true;
    }
    // MUAC is applicable from 6 months (approx 180 days)
    if (ageDays >= 180 && muacCm != null && muacCm! < 11.5) {
      return true;
    }
    return false;
  }

  /// Evaluates whether the child has Moderate Acute Malnutrition (MAM).
  bool isMam({required int ageDays}) {
    if (isSam(ageDays: ageDays)) return false;
    if (ageDays >= 180 && muacCm != null && muacCm! >= 11.5 && muacCm! < 12.5) {
      return true;
    }
    return false;
  }
}

/// Interval illness tracking since previous contact (Requirement 13.2).
class HbycIllnessInterval {
  final bool hadDiarrhoea;
  final int? diarrhoeaDays;
  final bool bloodInStool;
  final bool hadCoughFastBreathing;
  final bool hadFever;
  final int? feverDays;
  final bool hadEarDischarge;
  final bool hadConvulsions;
  final bool isLethargicOrUnconscious;
  final bool wasHospitalised;

  const HbycIllnessInterval({
    this.hadDiarrhoea = false,
    this.diarrhoeaDays,
    this.bloodInStool = false,
    this.hadCoughFastBreathing = false,
    this.hadFever = false,
    this.feverDays,
    this.hadEarDischarge = false,
    this.hadConvulsions = false,
    this.isLethargicOrUnconscious = false,
    this.wasHospitalised = false,
  });

  /// Evaluates immediate clinical danger signs.
  List<String> get dangerSigns {
    final list = <String>[];
    if (hadConvulsions) list.add('History of convulsions / fits');
    if (isLethargicOrUnconscious) list.add('Child is lethargic or unconscious');
    if (hadDiarrhoea && bloodInStool) list.add('Dysentery — blood in loose stools');
    if (hadDiarrhoea && (diarrhoeaDays ?? 0) >= 14) list.add('Persistent diarrhoea (>= 14 days)');
    if (hadFever && (feverDays ?? 0) >= 7) list.add('Prolonged fever (>= 7 days)');
    return list;
  }
}

/// Full clinical checklist data collected during an HBYC visit (Requirements 13.2 – 13.5).
class HbycChecklistData {
  final HbycMilestone milestone;
  final FeedingPractice feedingPractice;
  final bool complementaryFeedingStarted; // For >= 6m
  final int mealsPerDay; // Recommended: 2-3 at 6-8m, 3-4 at 9-11m, 3-4 + snacks at 12-15m
  final int foodGroupsCount; // Target >= 4 of 7 food groups
  final bool washedHandsBeforeFeeding;

  // Immunization tracking
  final bool immunizationUpToDate;
  final String? missingVaccinesNotes;

  // Growth & SAM evaluation
  final HbycGrowthData growth;

  // Developmental milestones (map of milestoneId -> achieved)
  final Map<String, bool> milestoneAchievements;

  // Illness interval
  final HbycIllnessInterval illness;

  // Responsive caregiving counselling completed
  final bool responsiveCaregivingCounseled;
  final bool hygieneWashCounseled;
  final bool storyboardShown;
  final bool audioMessagePlayed;
  final String? generalNotes;

  const HbycChecklistData({
    required this.milestone,
    required this.feedingPractice,
    this.complementaryFeedingStarted = false,
    this.mealsPerDay = 0,
    this.foodGroupsCount = 0,
    this.washedHandsBeforeFeeding = true,
    required this.immunizationUpToDate,
    this.missingVaccinesNotes,
    required this.growth,
    required this.milestoneAchievements,
    required this.illness,
    this.responsiveCaregivingCounseled = true,
    this.hygieneWashCounseled = true,
    this.storyboardShown = true,
    this.audioMessagePlayed = false,
    this.generalNotes,
  });

  /// Evaluates whether any expected milestone for this age is delayed (Requirement 13.3).
  List<HbycMilestoneItem> get delayedMilestones {
    final expectedItems = HbycMilestonesCatalog.forMilestone(milestone);
    return expectedItems.where((item) {
      final achieved = milestoneAchievements[item.id] ?? false;
      return !achieved;
    }).toList();
  }

  bool get hasMilestoneDelay => delayedMilestones.isNotEmpty;

  /// Checks if child exhibits SAM (Requirement 13.4).
  bool get isSam => growth.isSam(ageDays: milestone.ageInDays);

  /// Checks if child exhibits MAM.
  bool get isMam => growth.isMam(ageDays: milestone.ageInDays);

  /// Immediate danger signs requiring RED triage.
  List<String> get clinicalDangerSigns {
    final signs = <String>[];
    if (isSam) {
      signs.add('Severe Acute Malnutrition (SAM) — MUAC < 11.5 cm or Bilateral Oedema');
    }
    signs.addAll(illness.dangerSigns);
    return signs;
  }

  bool get hasRedFlag => clinicalDangerSigns.isNotEmpty;
}

/// Result of an HBYC visit record (Requirements 13.2 – 13.5).
class HbycVisitResult {
  final String encounterId;
  final String visitScheduleId;
  final String childId;
  final HbycMilestone milestone;
  final bool isSam;
  final bool isMam;
  final bool hasMilestoneDelay;
  final List<String> delayedMilestoneNames;
  final String? suggestedReferralDestination; // Anganwadi, RBSK/DEIC, NRC, PHC
  final String? prePopulatedReferralReason;
  final bool isRedFlag;
  final TriageResult? triageResult;
  final bool incentiveEligible;
  final String? incentiveEventId;

  const HbycVisitResult({
    required this.encounterId,
    required this.visitScheduleId,
    required this.childId,
    required this.milestone,
    required this.isSam,
    required this.isMam,
    required this.hasMilestoneDelay,
    required this.delayedMilestoneNames,
    this.suggestedReferralDestination,
    this.prePopulatedReferralReason,
    required this.isRedFlag,
    this.triageResult,
    required this.incentiveEligible,
    this.incentiveEventId,
  });
}
