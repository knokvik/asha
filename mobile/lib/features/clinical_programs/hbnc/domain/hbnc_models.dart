import 'package:flutter/foundation.dart';

/// Place of delivery for newborn assessment (NHSRC guidelines).
enum DeliveryPlace {
  home('home', 'Home Delivery'),
  institutionalSubCentre('sub_centre', 'Sub-Centre / HWC'),
  institutionalPhc('phc', 'Primary Health Centre'),
  institutionalChc('chc', 'Community Health Centre'),
  institutionalDh('district_hospital', 'District Hospital / Sub-Divisional Hospital'),
  institutionalPrivate('private_hospital', 'Private Hospital / Nursing Home');

  final String code;
  final String label;
  const DeliveryPlace(this.code, this.label);

  bool get isInstitutional => this != DeliveryPlace.home;
}

/// Mode of delivery.
enum DeliveryType {
  normalVaginal('normal_vaginal', 'Normal Vaginal Delivery'),
  cesareanSection('c_section', 'Cesarean Section (C-Section)'),
  assistedVaginal('assisted_vaginal', 'Assisted (Forceps / Vacuum)');

  final String code;
  final String label;
  const DeliveryType(this.code, this.label);
}

/// Feeding status for newborn.
enum FeedingStatus {
  exclusiveBreastfeeding('exclusive_bf', 'Exclusive Breastfeeding (Normal & Vigorous)'),
  difficultySuckling('difficulty_suckling', 'Difficulty Suckling / Weak Suckle'),
  unableToFeed('unable_to_feed', 'Unable to Breastfeed / Vomits Everything (DANGER SIGN)'),
  prelactealGiven('prelacteal_given', 'Prelacteal Feeds / Animal Milk Given');

  final String code;
  final String label;
  const FeedingStatus(this.code, this.label);

  bool get isDangerSign => this == FeedingStatus.unableToFeed;
}

/// Umbilical cord status.
enum CordStatus {
  cleanAndDry('clean_dry', 'Clean and Dry — Normal Healing'),
  bleeding('bleeding', 'Bleeding from Umbilical Stump (DANGER SIGN)'),
  rednessSwelling('redness_swelling', 'Redness or Swelling Extending to Abdominal Skin (DANGER SIGN)'),
  pusDischarge('pus_discharge', 'Pus Discharge with Foul Smell (DANGER SIGN)');

  final String code;
  final String label;
  const CordStatus(this.code, this.label);

  bool get isDangerSign => this != CordStatus.cleanAndDry;
}

/// Skin condition.
enum SkinStatus {
  clearNormal('clear_normal', 'Clear and Healthy Skin'),
  fewPustules('few_pustules', 'Few Skin Pustules (< 10 pustules)'),
  extensivePustules('extensive_pustules', 'Many or Severe Pustules (≥ 10 or large boils) (DANGER SIGN)'),
  cyanosisOrPallor('cyanosis_pallor', 'Severe Pallor / Blue Lips / Cold Clammy (DANGER SIGN)');

  final String code;
  final String label;
  const SkinStatus(this.code, this.label);

  bool get isDangerSign =>
      this == SkinStatus.extensivePustules || this == SkinStatus.cyanosisOrPallor;
}

/// Eye status.
enum EyeStatus {
  clear('clear', 'Clear, Normal Eyes'),
  wateryDischarge('watery_discharge', 'Mild Watery Discharge'),
  swollenPurulent('swollen_purulent', 'Swollen Eyelids with Pus / Discharge (DANGER SIGN)');

  final String code;
  final String label;
  const EyeStatus(this.code, this.label);

  bool get isDangerSign => this == EyeStatus.swollenPurulent;
}

/// Activity level and alertness.
enum ActivityStatus {
  activeAndAlert('active_alert', 'Active, Alert, Strong Cry'),
  lethargicDrowsy('lethargic_drowsy', 'Lethargic, Drowsy, Floppy / Poor Movement (DANGER SIGN)'),
  convulsions('convulsions', 'Convulsions / Fits / Abnormal Involuntary Movements (DANGER SIGN)');

  final String code;
  final String label;
  const ActivityStatus(this.code, this.label);

  bool get isDangerSign =>
      this == ActivityStatus.lethargicDrowsy || this == ActivityStatus.convulsions;
}

/// Neonatal jaundice severity.
enum JaundiceStatus {
  none('none', 'No Jaundice Detected'),
  mildFaceEyes('mild_face', 'Mild Yellowing (Face or Eyes Only)'),
  severePalmsSoles('severe_palms_soles', 'Deep Yellow Palms and Soles / Onset on Day 1 (DANGER SIGN)');

  final String code;
  final String label;
  const JaundiceStatus(this.code, this.label);

  bool get isDangerSign => this == JaundiceStatus.severePalmsSoles;
}

/// Maternal lochia and bleeding.
enum MaternalBleedingStatus {
  normalLochia('normal', 'Normal Lochia / Expected Bleeding'),
  excessiveBleeding('excessive', 'Excessive Bleeding (> 2 pads soaked in 1 hour) (DANGER SIGN)'),
  foulSmelling('foul_smelling', 'Foul-Smelling Vaginal Discharge (DANGER SIGN)');

  final String code;
  final String label;
  const MaternalBleedingStatus(this.code, this.label);

  bool get isDangerSign => this != MaternalBleedingStatus.normalLochia;
}

/// Delivery record capturing maternal and newborn delivery event.
///
/// Implements Requirement 12.1:
/// - Enrols newborn into HBNC schedule based on delivery place and birth weight.
@immutable
class HbncDeliveryRecord {
  final String newbornId;
  final String motherId;
  final String householdId;
  final DateTime deliveryDate;
  final DeliveryPlace place;
  final String? facilityName;
  final double birthWeightKg;
  final bool isPreterm;
  final int? gestationalAgeWeeks;
  final DeliveryType deliveryType;
  final List<String> complications;
  final String ashaId;

  const HbncDeliveryRecord({
    required this.newbornId,
    required this.motherId,
    required this.householdId,
    required this.deliveryDate,
    required this.place,
    this.facilityName,
    required this.birthWeightKg,
    this.isPreterm = false,
    this.gestationalAgeWeeks,
    this.deliveryType = DeliveryType.normalVaginal,
    this.complications = const [],
    required this.ashaId,
  });

  /// Low Birth Weight (< 2.5 kg).
  bool get isLbw => birthWeightKg < 2.5;

  /// Very Low Birth Weight (< 1.5 kg).
  bool get isVeryLbw => birthWeightKg < 1.5;

  /// High Risk Newborn: LBW or Preterm (< 37 weeks).
  bool get isHighRisk => isLbw || isPreterm || (gestationalAgeWeeks != null && gestationalAgeWeeks! < 37);
}

/// Planned HBNC visit item with scheduled date and permissible windows.
class HbncScheduleItem {
  final int dayNumber;
  final DateTime targetDate;
  final DateTime dueWindowStart;
  final DateTime dueWindowEnd;
  final bool isAdditionalHighRisk;
  final String label;

  const HbncScheduleItem({
    required this.dayNumber,
    required this.targetDate,
    required this.dueWindowStart,
    required this.dueWindowEnd,
    this.isAdditionalHighRisk = false,
    required this.label,
  });
}

/// Clinical checklist completed during an HBNC home visit.
///
/// Implements Requirement 12.2, 12.3, 12.4:
/// - Captures feeding, weight, temperature, breathing, cord, skin, eyes, activity, jaundice, thermal/KMC, and maternal PNC.
/// - Immediately detects general newborn danger signs and maternal postpartum red flags.
class HbncChecklistData {
  final double? currentWeightKg;
  final double? temperatureC;
  final int? respiratoryRate;
  final bool chestIndrawing;
  final bool grunting;
  final FeedingStatus feedingStatus;
  final CordStatus cordStatus;
  final SkinStatus skinStatus;
  final EyeStatus eyeStatus;
  final ActivityStatus activityStatus;
  final JaundiceStatus jaundiceStatus;
  final bool delayedBathingPracticed;
  final bool keptWarmInWarmChain;
  final bool kmcPracticed;
  final double? kmcHoursPerDay;
  final MaternalBleedingStatus maternalBleeding;
  final bool maternalFever;
  final bool maternalSevereHeadache;
  final String? maternalWoundHealing;
  final bool maternalMastitisOrEngorgement;
  final bool maternalMoodDepressionSigns;
  final List<String> counsellingGiven;

  const HbncChecklistData({
    this.currentWeightKg,
    this.temperatureC,
    this.respiratoryRate,
    this.chestIndrawing = false,
    this.grunting = false,
    this.feedingStatus = FeedingStatus.exclusiveBreastfeeding,
    this.cordStatus = CordStatus.cleanAndDry,
    this.skinStatus = SkinStatus.clearNormal,
    this.eyeStatus = EyeStatus.clear,
    this.activityStatus = ActivityStatus.activeAndAlert,
    this.jaundiceStatus = JaundiceStatus.none,
    this.delayedBathingPracticed = true,
    this.keptWarmInWarmChain = true,
    this.kmcPracticed = false,
    this.kmcHoursPerDay,
    this.maternalBleeding = MaternalBleedingStatus.normalLochia,
    this.maternalFever = false,
    this.maternalSevereHeadache = false,
    this.maternalWoundHealing = 'normal',
    this.maternalMastitisOrEngorgement = false,
    this.maternalMoodDepressionSigns = false,
    this.counsellingGiven = const [],
  });

  /// Identifies all clinical newborn danger signs triggered in this visit.
  List<String> get newbornDangerSigns {
    final signs = <String>[];

    // 1. Feeding danger signs
    if (feedingStatus.isDangerSign) {
      signs.add('Unable to feed / vomit everything');
    }

    // 2. Respiratory danger signs (Fast breathing >= 60 in young infant < 60 days)
    if (respiratoryRate != null && respiratoryRate! >= 60) {
      signs.add('Fast breathing ($respiratoryRate breaths/min >= 60)');
    }
    if (chestIndrawing) {
      signs.add('Severe chest indrawing');
    }
    if (grunting) {
      signs.add('Grunting during respiration');
    }

    // 3. Thermal danger signs
    if (temperatureC != null) {
      if (temperatureC! >= 37.5) {
        signs.add('High fever (${temperatureC!.toStringAsFixed(1)}°C >= 37.5°C)');
      } else if (temperatureC! < 35.5) {
        signs.add('Severe hypothermia (${temperatureC!.toStringAsFixed(1)}°C < 35.5°C)');
      }
    }

    // 4. Umbilical cord danger signs
    if (cordStatus.isDangerSign) {
      signs.add(cordStatus.label);
    }

    // 5. Skin danger signs
    if (skinStatus.isDangerSign) {
      signs.add(skinStatus.label);
    }

    // 6. Eye danger signs
    if (eyeStatus.isDangerSign) {
      signs.add(eyeStatus.label);
    }

    // 7. Activity & CNS danger signs
    if (activityStatus.isDangerSign) {
      signs.add(activityStatus.label);
    }

    // 8. Jaundice danger signs
    if (jaundiceStatus.isDangerSign) {
      signs.add(jaundiceStatus.label);
    }

    return signs;
  }

  /// Identifies maternal postpartum danger signs.
  List<String> get maternalDangerSigns {
    final signs = <String>[];
    if (maternalBleeding.isDangerSign) {
      signs.add(maternalBleeding.label);
    }
    if (maternalFever) {
      signs.add('Maternal postpartum fever');
    }
    if (maternalSevereHeadache) {
      signs.add('Severe postpartum headache with visual disturbances (possible pre-eclampsia)');
    }
    if (maternalWoundHealing == 'infected' || maternalWoundHealing == 'dehiscence') {
      signs.add('Infected perineal or cesarean incision wound');
    }
    return signs;
  }

  /// Whether any newborn or maternal danger sign is present.
  bool get hasAnyDangerSign => newbornDangerSigns.isNotEmpty || maternalDangerSigns.isNotEmpty;
}

/// Data captured for maternal or child death audit review (Requirement 12.6).
class HbncDeathReview {
  final bool isNewbornDeath;
  final bool isMaternalDeath;
  final String deceasedMemberId;
  final DateTime deathDate;
  final String placeOfDeath;
  final String probableCause;
  final List<String> delaysIdentified;
  final bool referralAttempted;
  final String? notes;

  const HbncDeathReview({
    required this.isNewbornDeath,
    required this.isMaternalDeath,
    required this.deceasedMemberId,
    required this.deathDate,
    required this.placeOfDeath,
    required this.probableCause,
    this.delaysIdentified = const [],
    this.referralAttempted = false,
    this.notes,
  });
}
