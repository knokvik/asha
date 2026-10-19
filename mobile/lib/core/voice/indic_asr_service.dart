import 'indic_extractor.dart';

/// Service for Indic speech recognition and auto-filling clinical assessment forms.
class IndicAsrService {
  IndicAsrService({IndicClinicalExtractor? extractor})
      : _extractor = extractor ?? IndicClinicalExtractor();

  final IndicClinicalExtractor _extractor;

  static const List<Map<String, String>> sampleFieldUtterances = [
    {
      'lang': 'hi',
      'label': 'बच्चे को तेज बुखार और उल्टी है',
      'text': 'बच्चे को दो दिन से तेज बुखार है और लगातार उल्टी हो रही है। दूध भी नहीं पी रहा है।',
    },
    {
      'lang': 'hi',
      'label': 'छाती धंसना और तेज सांस (RED Flag)',
      'text': 'बच्चे की छाती धंस रही है और सांस बहुत तेज चल रही है, लेकिन दौरा नहीं आया।',
    },
    {
      'lang': 'mr',
      'label': 'बाळाला ताप आहे, झटके नाहीत (Marathi)',
      'text': 'बाळाला तीन दिवसांपासून ताप आला आहे आणि जुलाब होत आहे, झटके नाहीत.',
    },
    {
      'lang': 'en',
      'label': 'High fever, convulsions, vomiting (English)',
      'text': 'The infant has high fever with convulsions and is unable to drink.',
    },
  ];

  /// Process spoken or typed transcript and return extracted clinical symptoms.
  List<ExtractedSymptom> processSpeech(String text) {
    return _extractor.extract(text);
  }

  /// Map extracted symptoms to question catalogue IDs and affirmative boolean values.
  /// Returns a map of `questionId -> bool`.
  Map<String, bool> mapSymptomsToQuestions(List<ExtractedSymptom> symptoms) {
    final answers = <String, bool>{};

    for (final symptom in symptoms) {
      switch (symptom.concept) {
        case 'CONVULSIONS':
          answers['q_convulsions'] = symptom.isAffirmative;
          break;
        case 'UNABLE_TO_DRINK':
          answers['q_unable_drink'] = symptom.isAffirmative;
          break;
        case 'VOMITING':
          answers['q_vomit_all'] = symptom.isAffirmative;
          break;
        case 'CHEST_INDRAWING':
          answers['q_chest_indrawing'] = symptom.isAffirmative;
          break;
        case 'STRIDOR':
          answers['q_stridor'] = symptom.isAffirmative;
          break;
        case 'FEVER':
          answers['q_fever'] = symptom.isAffirmative;
          break;
        case 'DIARRHEA':
          answers['q_diarrhea'] = symptom.isAffirmative;
          break;
        case 'EDEMA':
          answers['q_bilateral_edema'] = symptom.isAffirmative;
          break;
        case 'LETHARGY':
          answers['q_lethargic'] = symptom.isAffirmative;
          break;
      }
    }

    return answers;
  }
}
