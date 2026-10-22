import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_as.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_or.dart';
import 'app_localizations_pa.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('as'),
    Locale('bn'),
    Locale('en'),
    Locale('gu'),
    Locale('hi'),
    Locale('kn'),
    Locale('ml'),
    Locale('mr'),
    Locale('or'),
    Locale('pa'),
    Locale('ta'),
    Locale('te'),
  ];

  /// Application title shown in the app bar
  ///
  /// In en, this message translates to:
  /// **'Asha'**
  String get appTitle;

  /// Shown on the PIN setup screen during initial setup
  ///
  /// In en, this message translates to:
  /// **'Setting up encrypted storage...'**
  String get settingUp;

  /// Title on the PIN setup / welcome screen
  ///
  /// In en, this message translates to:
  /// **'ASHA Digital Platform'**
  String get pinSetupTitle;

  /// Title on unlock screen when PIN is already configured
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// Title on initial PIN configuration screen
  ///
  /// In en, this message translates to:
  /// **'Security Setup'**
  String get securitySetup;

  /// Field label for creating new PIN
  ///
  /// In en, this message translates to:
  /// **'Create PIN (4–8 digits)'**
  String get createPin;

  /// Field label for confirming PIN
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get confirmPin;

  /// Field label for entering security PIN
  ///
  /// In en, this message translates to:
  /// **'Security PIN'**
  String get securityPin;

  /// Button label to unlock local encrypted database
  ///
  /// In en, this message translates to:
  /// **'Unlock Database'**
  String get unlockDatabase;

  /// Button label to submit initial PIN
  ///
  /// In en, this message translates to:
  /// **'Set PIN & Initialize'**
  String get setPinAndInitialize;

  /// Validation error when PINs do not match
  ///
  /// In en, this message translates to:
  /// **'PINs do not match. Please re-enter.'**
  String get pinMismatch;

  /// Validation error for invalid PIN length
  ///
  /// In en, this message translates to:
  /// **'PIN must be between 4 and 8 numeric digits.'**
  String get pinLengthError;

  /// Error message when maximum failed attempts reached
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Supervisor OTP required.'**
  String get tooManyAttempts;

  /// Error message for wrong PIN
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN. Please try again.'**
  String get incorrectPin;

  /// Sync status indicator — record saved locally but not yet synced
  ///
  /// In en, this message translates to:
  /// **'Saved on phone'**
  String get savedOnPhone;

  /// Sync status indicator — record confirmed on server
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get synced;

  /// Sync status indicator — sync error requiring user action
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get needsAttention;

  /// Navigation label for the home / due-list screen
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Title of the daily due task list screen
  ///
  /// In en, this message translates to:
  /// **'Today\'s Tasks'**
  String get dueList;

  /// Navigation label for the household registry
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get household;

  /// Plural label for households
  ///
  /// In en, this message translates to:
  /// **'Households'**
  String get households;

  /// Action label for registering a new household
  ///
  /// In en, this message translates to:
  /// **'Register Household'**
  String get registerHousehold;

  /// Navigation label for the triage workflow
  ///
  /// In en, this message translates to:
  /// **'Triage'**
  String get triage;

  /// Navigation label for the referral workflow
  ///
  /// In en, this message translates to:
  /// **'Referral'**
  String get referral;

  /// Plural label for referrals
  ///
  /// In en, this message translates to:
  /// **'Referrals'**
  String get referrals;

  /// Navigation label for the training / learning module
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get learning;

  /// Navigation label for the earnings / incentives screen
  ///
  /// In en, this message translates to:
  /// **'Incentives'**
  String get incentives;

  /// Navigation label for the settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Label for language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Title of the language selector dialog or screen
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Generic save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Generic cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Generic submit button label
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// Generic next step button label
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Generic back button label
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Generic done button label
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Generic skip button label
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// Generic search button or placeholder label
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Triage result label for red (urgent referral) flag
  ///
  /// In en, this message translates to:
  /// **'RED — Refer immediately'**
  String get triageFlagRed;

  /// Triage result label for yellow (monitor) flag
  ///
  /// In en, this message translates to:
  /// **'YELLOW — Monitor closely'**
  String get triageFlagYellow;

  /// Triage result label for green (home care) flag
  ///
  /// In en, this message translates to:
  /// **'GREEN — Continue home care'**
  String get triageFlagGreen;

  /// Disclaimer shown alongside every triage result
  ///
  /// In en, this message translates to:
  /// **'This is clinical decision support. Your judgment as an ASHA is the final decision.'**
  String get triageDisclaimer;

  /// Instruction for urgent referral
  ///
  /// In en, this message translates to:
  /// **'Immediate referral required'**
  String get referImmediately;

  /// Emergency instruction to call 108 ambulance
  ///
  /// In en, this message translates to:
  /// **'Call 108 ambulance immediately'**
  String get callAmbulanceImmediately;

  /// Banner shown when the device has no network connectivity
  ///
  /// In en, this message translates to:
  /// **'Working offline — data saved on phone'**
  String get offlineIndicator;

  /// Warning shown when device storage falls below the configured threshold
  ///
  /// In en, this message translates to:
  /// **'Storage is running low. Some cached data can be cleared.'**
  String get lowStorageWarning;

  /// Title on the informed consent screen
  ///
  /// In en, this message translates to:
  /// **'Your Health Information'**
  String get consentTitle;

  /// Button label for granting consent
  ///
  /// In en, this message translates to:
  /// **'I agree'**
  String get consentGrant;

  /// Button label for declining consent
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get consentDecline;

  /// Title on the emergency dial screen
  ///
  /// In en, this message translates to:
  /// **'Emergency Contacts'**
  String get emergencyDialTitle;

  /// Label for the 108 ambulance dial action
  ///
  /// In en, this message translates to:
  /// **'Ambulance (108)'**
  String get ambulanceLabel;

  /// Label for the 102 obstetric transport dial action
  ///
  /// In en, this message translates to:
  /// **'Obstetric transport (102)'**
  String get obstetricTransportLabel;

  /// Clinical term for antenatal care
  ///
  /// In en, this message translates to:
  /// **'Antenatal Care (ANC)'**
  String get anc;

  /// Clinical term for postnatal care
  ///
  /// In en, this message translates to:
  /// **'Postnatal Care (PNC)'**
  String get pnc;

  /// Clinical term for home based newborn care
  ///
  /// In en, this message translates to:
  /// **'Home Based Newborn Care (HBNC)'**
  String get hbnc;

  /// Clinical term for home based young child care
  ///
  /// In en, this message translates to:
  /// **'Home Based Young Child Care (HBYC)'**
  String get hbyc;

  /// Clinical term for non-communicable diseases
  ///
  /// In en, this message translates to:
  /// **'Non-Communicable Diseases (NCD)'**
  String get ncd;

  /// Clinical term for immunization / vaccination
  ///
  /// In en, this message translates to:
  /// **'Immunization'**
  String get immunization;

  /// Clinical term for MUAC tape measurement
  ///
  /// In en, this message translates to:
  /// **'Mid-Upper Arm Circumference (MUAC)'**
  String get muac;

  /// Clinical term for jaundice (yellow skin/eyes)
  ///
  /// In en, this message translates to:
  /// **'Jaundice'**
  String get jaundice;

  /// Clinical term for anemia / low hemoglobin
  ///
  /// In en, this message translates to:
  /// **'Anemia'**
  String get anemia;

  /// Clinical term for child malnutrition
  ///
  /// In en, this message translates to:
  /// **'Malnutrition'**
  String get malnutrition;

  /// Clinical term for SAM
  ///
  /// In en, this message translates to:
  /// **'Severe Acute Malnutrition (SAM)'**
  String get severeMalnutrition;

  /// Clinical term for diarrhea
  ///
  /// In en, this message translates to:
  /// **'Diarrhea'**
  String get diarrhea;

  /// Clinical term for ORS preparation
  ///
  /// In en, this message translates to:
  /// **'Oral Rehydration Salts (ORS)'**
  String get ors;

  /// Clinical term for fever
  ///
  /// In en, this message translates to:
  /// **'Fever'**
  String get fever;

  /// Clinical term for rapid respiratory rate
  ///
  /// In en, this message translates to:
  /// **'Fast Breathing / Pneumonia'**
  String get fastBreathing;

  /// Clinical term for hypertension
  ///
  /// In en, this message translates to:
  /// **'High Blood Pressure'**
  String get hypertension;

  /// Clinical term for diabetes
  ///
  /// In en, this message translates to:
  /// **'Diabetes'**
  String get diabetes;

  /// Tooltip or label for tap-to-hear audio prompt button
  ///
  /// In en, this message translates to:
  /// **'Tap to listen'**
  String get tapToListen;

  /// Status shown while TTS or voice clip is playing
  ///
  /// In en, this message translates to:
  /// **'Playing audio instructions...'**
  String get playingAudio;

  /// Button label to halt playing audio
  ///
  /// In en, this message translates to:
  /// **'Stop audio'**
  String get stopAudio;

  /// Spoken instruction for PIN setup screen
  ///
  /// In en, this message translates to:
  /// **'Please set your 4 to 8 digit security PIN.'**
  String get audioPromptPinSetup;

  /// Spoken instruction for daily due list
  ///
  /// In en, this message translates to:
  /// **'Here is your task list for today.'**
  String get audioPromptDueList;

  /// Spoken instruction for red triage result
  ///
  /// In en, this message translates to:
  /// **'Emergency flag red. Immediate referral required.'**
  String get audioPromptTriageRed;

  /// Spoken instruction for yellow triage result
  ///
  /// In en, this message translates to:
  /// **'Flag yellow. Close monitoring and home care required.'**
  String get audioPromptTriageYellow;

  /// Spoken instruction for green triage result
  ///
  /// In en, this message translates to:
  /// **'Flag green. Standard home care and follow-up.'**
  String get audioPromptTriageGreen;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'as',
    'bn',
    'en',
    'gu',
    'hi',
    'kn',
    'ml',
    'mr',
    'or',
    'pa',
    'ta',
    'te',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'as':
      return AppLocalizationsAs();
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'ml':
      return AppLocalizationsMl();
    case 'mr':
      return AppLocalizationsMr();
    case 'or':
      return AppLocalizationsOr();
    case 'pa':
      return AppLocalizationsPa();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
