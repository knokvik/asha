import 'package:core_model/core_model.dart';

/// Localised label tables for the referral note.
///
/// These are data, not a translation service: the note must render identically
/// every time from the same record, so nothing here calls out to anything.
abstract final class ReferralLabels {
  static const supportedLocales = ['en', 'hi', 'mr'];

  static String _pick(Map<String, String> table, String locale) =>
      table[locale] ?? table['en'] ?? '';

  /// §11.2 — the band word must be a plain imperative, not just a colour.
  static String bandImperative(TriageBand band, String locale) => _pick(switch (band) {
    TriageBand.red => const {'en': 'RED — SEE NOW', 'hi': 'लाल — अभी देखें', 'mr': 'लाल — आत्ताच पाहा'},
    TriageBand.yellow => const {'en': 'YELLOW — SEE TODAY', 'hi': 'पीला — आज देखें', 'mr': 'पिवळा — आज पाहा'},
    TriageBand.green => const {
      'en': 'GREEN — ROUTINE FOLLOW-UP',
      'hi': 'हरा — नियमित फॉलो-अप',
      'mr': 'हिरवा — नियमित पाठपुरावा',
    },
    TriageBand.needsMoreInfo => const {
      'en': 'INCOMPLETE — MORE INFORMATION NEEDED',
      'hi': 'अपूर्ण — अधिक जानकारी चाहिए',
      'mr': 'अपूर्ण — अधिक माहिती आवश्यक',
    },
    TriageBand.outOfScope => const {
      'en': 'OUT OF SCOPE — CONTACT PHC',
      'hi': 'दायरे से बाहर — PHC से संपर्क करें',
      'mr': 'कक्षेबाहेर — PHC शी संपर्क करा',
    },
  }, locale);

  static String bandSymbol(TriageBand band) => switch (band) {
    TriageBand.red => '[RED]',
    TriageBand.yellow => '[YELLOW]',
    TriageBand.green => '[GREEN]',
    TriageBand.needsMoreInfo => '[CHECK]',
    TriageBand.outOfScope => '[PHC]',
  };

  /// Human labels for the fields a doctor reads, keyed by dotted path.
  static const _fieldLabels = <String, Map<String, String>>{
    FieldPaths.unableToDrinkOrBreastfeed: {
      'en': 'Unable to drink/breastfeed',
      'hi': 'पीने/स्तनपान में असमर्थ',
      'mr': 'पिणे/स्तनपान करण्यास असमर्थ',
    },
    FieldPaths.vomitsEverything: {
      'en': 'Vomits everything',
      'hi': 'सब कुछ उल्टी',
      'mr': 'सर्व उलटी होते',
    },
    FieldPaths.convulsionsThisIllness: {
      'en': 'Convulsions this illness',
      'hi': 'इस बीमारी में ऐंठन',
      'mr': 'या आजारात आकडी',
    },
    FieldPaths.convulsingNow: {'en': 'Convulsing now', 'hi': 'अभी ऐंठन', 'mr': 'आत्ता आकडी'},
    FieldPaths.lethargicOrUnconscious: {
      'en': 'Lethargic / unconscious',
      'hi': 'सुस्त / बेहोश',
      'mr': 'सुस्त / बेशुद्ध',
    },
    FieldPaths.chestIndrawing: {'en': 'Chest indrawing', 'hi': 'छाती धंसना', 'mr': 'छाती आत ओढणे'},
    FieldPaths.stridorWhenCalm: {
      'en': 'Stridor when calm',
      'hi': 'शांत होने पर घरघर',
      'mr': 'शांत असताना घरघर',
    },
    FieldPaths.grunting: {'en': 'Grunting', 'hi': 'कराहना', 'mr': 'कण्हणे'},
    FieldPaths.nasalFlaring: {'en': 'Nasal flaring', 'hi': 'नाक फड़कना', 'mr': 'नाक फुगणे'},
    FieldPaths.sunkenEyes: {'en': 'Sunken eyes', 'hi': 'धंसी आंखें', 'mr': 'खोल गेलेले डोळे'},
    FieldPaths.skinPinch: {'en': 'Skin pinch', 'hi': 'त्वचा पिंच', 'mr': 'त्वचा पिंच'},
    FieldPaths.drinkingPattern: {'en': 'Drinking pattern', 'hi': 'पीने का तरीका', 'mr': 'पिण्याची पद्धत'},
    FieldPaths.restlessIrritable: {'en': 'Restless / irritable', 'hi': 'बेचैन / चिड़चिड़ा', 'mr': 'अस्वस्थ / चिडचिड'},
    FieldPaths.stiffNeck: {'en': 'Stiff neck', 'hi': 'गर्दन अकड़न', 'mr': 'ताठ मान'},
    FieldPaths.oedemaBothFeet: {'en': 'Oedema both feet', 'hi': 'दोनों पैरों में सूजन', 'mr': 'दोन्ही पायांना सूज'},
    FieldPaths.visibleSevereWasting: {
      'en': 'Visible severe wasting',
      'hi': 'गंभीर दुबलापन',
      'mr': 'दृश्यमान गंभीर कृशता',
    },
    FieldPaths.feelsHotToTouch: {'en': 'Feels hot to touch', 'hi': 'छूने पर गर्म', 'mr': 'स्पर्शाला गरम'},
    FieldPaths.temperatureC: {'en': 'Temperature', 'hi': 'तापमान', 'mr': 'तापमान'},
    FieldPaths.respiratoryRate: {'en': 'Respiratory rate', 'hi': 'श्वास दर', 'mr': 'श्वसन दर'},
    FieldPaths.muacMm: {'en': 'MUAC', 'hi': 'MUAC', 'mr': 'MUAC'},
    FieldPaths.fever: {'en': 'Fever', 'hi': 'बुखार', 'mr': 'ताप'},
    FieldPaths.cough: {'en': 'Cough', 'hi': 'खांसी', 'mr': 'खोकला'},
    FieldPaths.diarrhoea: {'en': 'Diarrhoea', 'hi': 'दस्त', 'mr': 'जुलाब'},
    FieldPaths.difficultyBreathing: {
      'en': 'Difficulty breathing',
      'hi': 'सांस लेने में कठिनाई',
      'mr': 'श्वास घेण्यास त्रास',
    },
    FieldPaths.bloodInStool: {'en': 'Blood in stool', 'hi': 'मल में खून', 'mr': 'शौचात रक्त'},
    FieldPaths.vomiting: {'en': 'Vomiting', 'hi': 'उल्टी', 'mr': 'उलटी'},
  };

  static String field(String path, String locale) {
    final table = _fieldLabels[path];
    if (table != null) return _pick(table, locale);
    // Unlabelled fields degrade to the readable leaf name rather than vanishing
    // from the note.
    final leaf = path.contains('.') ? path.split('.').last : path;
    return leaf.replaceAll('_', ' ');
  }

  static String answer(Object? value, String locale) {
    final text = value?.toString().toUpperCase();
    return switch (text) {
      'YES' => _pick(const {'en': 'Yes', 'hi': 'हाँ', 'mr': 'होय'}, locale),
      'NO' => _pick(const {'en': 'No', 'hi': 'नहीं', 'mr': 'नाही'}, locale),
      null || '' => _pick(const {'en': 'Not recorded', 'hi': 'दर्ज नहीं', 'mr': 'नोंद नाही'}, locale),
      _ => value.toString(),
    };
  }

  static String section(String key, String locale) => _pick(switch (key) {
    'title' => const {
      'en': 'REFERRAL / TRIAGE SUMMARY',
      'hi': 'रेफरल / ट्रायेज सारांश',
      'mr': 'रेफरल / ट्रायेज सारांश',
    },
    'generatedBy' => const {
      'en': 'Generated by ASHA Tele-Triage Companion',
      'hi': 'ASHA टेली-ट्रायेज सहयोगी द्वारा तैयार',
      'mr': 'ASHA टेली-ट्रायेज सहाय्यकाद्वारे तयार',
    },
    'disclaimer' => const {
      'en': 'Decision support only — not a diagnosis',
      'hi': 'केवल निर्णय सहायता — निदान नहीं',
      'mr': 'फक्त निर्णय सहाय्य — निदान नाही',
    },
    'why' => const {'en': 'WHY', 'hi': 'कारण', 'mr': 'कारण'},
    'dangerSigns' => const {'en': 'DANGER SIGNS', 'hi': 'खतरे के संकेत', 'mr': 'धोक्याची चिन्हे'},
    'notChecked' => const {'en': 'NOT CHECKED', 'hi': 'जांच नहीं', 'mr': 'तपासले नाही'},
    'patient' => const {'en': 'PATIENT', 'hi': 'रोगी', 'mr': 'रुग्ण'},
    'complaints' => const {'en': 'CHIEF COMPLAINTS', 'hi': 'मुख्य शिकायतें', 'mr': 'मुख्य तक्रारी'},
    'vitals' => const {'en': 'VITALS', 'hi': 'महत्वपूर्ण माप', 'mr': 'महत्त्वाची मापे'},
    'screened' => const {
      'en': 'DANGER SIGNS SCREENED',
      'hi': 'जांचे गए खतरे के संकेत',
      'mr': 'तपासलेली धोक्याची चिन्हे',
    },
    'triage' => const {'en': 'TRIAGE', 'hi': 'ट्रायेज', 'mr': 'ट्रायेज'},
    'whyBand' => const {'en': 'WHY THIS BAND', 'hi': 'यह स्तर क्यों', 'mr': 'हा स्तर का'},
    'limitations' => const {
      'en': 'NOT ASSESSED / LIMITATIONS',
      'hi': 'मूल्यांकन नहीं / सीमाएं',
      'mr': 'मूल्यांकन नाही / मर्यादा',
    },
    'advice' => const {
      'en': 'ADVICE GIVEN TO CAREGIVER',
      'hi': 'देखभालकर्ता को दी गई सलाह',
      'mr': 'काळजीवाहकाला दिलेला सल्ला',
    },
    'workerNote' => const {'en': 'WORKER NOTE', 'hi': 'कार्यकर्ता टिप्पणी', 'mr': 'कार्यकर्ता टिप्पणी'},
    'escalated' => const {
      'en': 'ESCALATED BY WORKER',
      'hi': 'कार्यकर्ता द्वारा बढ़ाया गया',
      'mr': 'कार्यकर्त्याने वाढवले',
    },
    'footer' => const {
      'en': 'This summary is a triage aid for clinician review. It is not a diagnosis.',
      'hi': 'यह सारांश चिकित्सक समीक्षा हेतु ट्रायेज सहायता है। यह निदान नहीं है।',
      'mr': 'हा सारांश डॉक्टरांच्या पुनरावलोकनासाठी ट्रायेज सहाय्य आहे. हे निदान नाही.',
    },
    'noneOf' => const {'en': 'none of', 'hi': 'में से कोई नहीं', 'mr': 'पैकी एकही नाही'},
    'present' => const {'en': 'present', 'hi': 'मौजूद', 'mr': 'उपस्थित'},
    'notMeasured' => const {'en': 'not measured', 'hi': 'मापा नहीं गया', 'mr': 'मोजले नाही'},
    'encounter' => const {'en': 'ENCOUNTER', 'hi': 'भेंट', 'mr': 'भेट'},
    _ => const {'en': ''},
  }, locale);

  /// §10.7 / §11.2 — the advice line attached to each band.
  static String advice(String adviceKey, String locale) => _pick(switch (adviceKey) {
    'advice.red.urgent_referral' => const {
      'en': 'Take the child to the PHC immediately; do not delay overnight.',
      'hi': 'बच्चे को तुरंत PHC ले जाएं; रात भर देरी न करें।',
      'mr': 'मुलाला ताबडतोब PHC मध्ये न्या; रात्रभर उशीर करू नका.',
    },
    'advice.yellow.prompt_phc' => const {
      'en': 'Visit the PHC today or tomorrow. Return immediately if the child worsens.',
      'hi': 'आज या कल PHC जाएं। बच्चा बिगड़े तो तुरंत लौटें।',
      'mr': 'आज किंवा उद्या PHC ला भेट द्या. मूल बिघडल्यास लगेच परत या.',
    },
    'advice.green.routine_followup' => const {
      'en': 'Home care and routine follow-up. Return immediately if any danger sign appears.',
      'hi': 'घरेलू देखभाल और नियमित फॉलो-अप। कोई खतरे का संकेत दिखे तो तुरंत लौटें।',
      'mr': 'घरगुती काळजी आणि नियमित पाठपुरावा. धोक्याचे चिन्ह दिसल्यास लगेच परत या.',
    },
    'advice.out_of_scope' => const {
      'en': 'Outside the 2–59 month scope of this tool. Contact the PHC for advice.',
      'hi': 'यह उपकरण 2–59 माह के लिए है। सलाह हेतु PHC से संपर्क करें।',
      'mr': 'हे साधन २–५९ महिन्यांसाठी आहे. सल्ल्यासाठी PHC शी संपर्क करा.',
    },
    'advice.needs_more_info' => const {
      'en': 'Assessment incomplete. Answer the listed questions before relying on a band.',
      'hi': 'मूल्यांकन अपूर्ण। स्तर पर भरोसा करने से पहले सूचीबद्ध प्रश्नों के उत्तर दें।',
      'mr': 'मूल्यांकन अपूर्ण. स्तरावर विसंबण्यापूर्वी सूचीबद्ध प्रश्नांची उत्तरे द्या.',
    },
    _ => const {'en': 'Follow local PHC guidance.'},
  }, locale);
}
