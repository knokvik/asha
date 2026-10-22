// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Asha';

  @override
  String get settingUp => 'Setting up encrypted storage...';

  @override
  String get pinSetupTitle => 'ASHA Digital Platform';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get securitySetup => 'Security Setup';

  @override
  String get createPin => 'Create PIN (4–8 digits)';

  @override
  String get confirmPin => 'Confirm PIN';

  @override
  String get securityPin => 'Security PIN';

  @override
  String get unlockDatabase => 'Unlock Database';

  @override
  String get setPinAndInitialize => 'Set PIN & Initialize';

  @override
  String get pinMismatch => 'PINs do not match. Please re-enter.';

  @override
  String get pinLengthError => 'PIN must be between 4 and 8 numeric digits.';

  @override
  String get tooManyAttempts => 'Too many attempts. Supervisor OTP required.';

  @override
  String get incorrectPin => 'Incorrect PIN. Please try again.';

  @override
  String get savedOnPhone => 'Saved on phone';

  @override
  String get synced => 'Synced';

  @override
  String get needsAttention => 'Needs attention';

  @override
  String get home => 'Home';

  @override
  String get dueList => 'Today\'s Tasks';

  @override
  String get household => 'Household';

  @override
  String get households => 'Households';

  @override
  String get registerHousehold => 'Register Household';

  @override
  String get triage => 'Triage';

  @override
  String get referral => 'Referral';

  @override
  String get referrals => 'Referrals';

  @override
  String get learning => 'Learning';

  @override
  String get incentives => 'Incentives';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get submit => 'Submit';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get done => 'Done';

  @override
  String get skip => 'Skip';

  @override
  String get search => 'Search';

  @override
  String get triageFlagRed => 'RED — Refer immediately';

  @override
  String get triageFlagYellow => 'YELLOW — Monitor closely';

  @override
  String get triageFlagGreen => 'GREEN — Continue home care';

  @override
  String get triageDisclaimer =>
      'This is clinical decision support. Your judgment as an ASHA is the final decision.';

  @override
  String get referImmediately => 'Immediate referral required';

  @override
  String get callAmbulanceImmediately => 'Call 108 ambulance immediately';

  @override
  String get offlineIndicator => 'Working offline — data saved on phone';

  @override
  String get lowStorageWarning =>
      'Storage is running low. Some cached data can be cleared.';

  @override
  String get consentTitle => 'Your Health Information';

  @override
  String get consentGrant => 'I agree';

  @override
  String get consentDecline => 'Not now';

  @override
  String get emergencyDialTitle => 'Emergency Contacts';

  @override
  String get ambulanceLabel => 'Ambulance (108)';

  @override
  String get obstetricTransportLabel => 'Obstetric transport (102)';

  @override
  String get anc => 'Antenatal Care (ANC)';

  @override
  String get pnc => 'Postnatal Care (PNC)';

  @override
  String get hbnc => 'Home Based Newborn Care (HBNC)';

  @override
  String get hbyc => 'Home Based Young Child Care (HBYC)';

  @override
  String get ncd => 'Non-Communicable Diseases (NCD)';

  @override
  String get immunization => 'Immunization';

  @override
  String get muac => 'Mid-Upper Arm Circumference (MUAC)';

  @override
  String get jaundice => 'Jaundice';

  @override
  String get anemia => 'Anemia';

  @override
  String get malnutrition => 'Malnutrition';

  @override
  String get severeMalnutrition => 'Severe Acute Malnutrition (SAM)';

  @override
  String get diarrhea => 'Diarrhea';

  @override
  String get ors => 'Oral Rehydration Salts (ORS)';

  @override
  String get fever => 'Fever';

  @override
  String get fastBreathing => 'Fast Breathing / Pneumonia';

  @override
  String get hypertension => 'High Blood Pressure';

  @override
  String get diabetes => 'Diabetes';

  @override
  String get tapToListen => 'Tap to listen';

  @override
  String get playingAudio => 'Playing audio instructions...';

  @override
  String get stopAudio => 'Stop audio';

  @override
  String get audioPromptPinSetup =>
      'Please set your 4 to 8 digit security PIN.';

  @override
  String get audioPromptDueList => 'Here is your task list for today.';

  @override
  String get audioPromptTriageRed =>
      'Emergency flag red. Immediate referral required.';

  @override
  String get audioPromptTriageYellow =>
      'Flag yellow. Close monitoring and home care required.';

  @override
  String get audioPromptTriageGreen =>
      'Flag green. Standard home care and follow-up.';
}
