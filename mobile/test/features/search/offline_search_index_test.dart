import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/features/search/data/clinical_dictionary.dart';
import 'package:asha_platform/features/search/data/offline_search_index.dart';

void main() {
  const csv = '''
id,category,keyword_en,keyword_hi,keyword_mr,name,purpose,dose_or_protocol,how_to_use,when_to_refer,danger_signs,source_ref,approx_price_inr
M01,medicine,paracetamol fever,पैरासिटामोल बुखार,पॅरासिटामोल ताप,Paracetamol,Fever and pain relief,"10–15 mg/kg, every 6h","Give after feeding, never exceed max dose",Fever with danger signs,Convulsions,IMCI,₹10
G01,guide,fever care,बुखार देखभाल,ताप काळजी,Fever home care,Simple fever support,-,Fluids and monitor,Refer if fever persists,Danger signs,IMCI,-
''';

  test('parses quoted fields and ranks medicine plus guide for fever', () {
    final index = OfflineSearchIndex.fromCsv(csv);

    expect(index.entries, hasLength(2));
    final feverIds = index.search('fever').map((entry) => entry.id).toList();
    expect(feverIds, containsAll(['M01', 'G01']));
    expect(index.search('पैरासिटामोल').single.name, 'Paracetamol');
    expect(index.search('fever', category: 'medicine').single.id, 'M01');
  });

  test('returns no matches for blank or unknown input', () {
    final index = OfflineSearchIndex.fromCsv(csv);

    expect(index.search(''), isEmpty);
    expect(index.search('not-in-catalog'), isEmpty);
  });

  test('searchSections organizes fever query into 4 distinct clinical sections', () {
    const richCsv = '''
id,category,keyword_en,keyword_hi,keyword_mr,name,purpose,dose_or_protocol,how_to_use,when_to_refer,danger_signs,source_ref,approx_price_inr
DIS01,disease,fever pyrexia,बुखार ताप,ताप ताप,Fever (Pyrexia),Elevation of body temp,Paracetamol 10-15mg/kg,Tepid sponging,High fever >39C,Convulsions,IMCI,-
M01,medicine,paracetamol fever,पैरासिटामोल बुखार,पॅरासिटामोल ताप,Paracetamol 500mg,Fever and pain relief,1 tab every 6h,Take with water,Fever with convulsions,Convulsions,NLEM,₹10
G01,guide,fever care tepid sponge,बुखार देखभाल,ताप काळजी,Fever home care guide,Tepid sponging SOP,-,Fluids and rest,Fever >5 days,Danger signs,IMCI,-
D01,danger_sign,fever convulsions stiff neck,दौरे बुखार,ताप झटके,High fever with convulsions,Febrile seizure danger sign,-,Do not put objects in mouth,Immediate emergency referral,Convulsions,IMCI,-
''';
    final index = OfflineSearchIndex.fromCsv(richCsv);
    final sections = index.searchSections('fever');

    expect(sections.isNotEmpty, isTrue);
    expect(sections.diseases, isNotEmpty);
    expect(sections.diseases.first.id, 'DIS_FEVER');
    expect(sections.medicines, isNotEmpty);
    expect(sections.medicines.first.id, 'M01');
    expect(sections.guides, isNotEmpty);
    expect(sections.guides.first.id, 'G01');
    expect(sections.dangerSigns, isNotEmpty);
    expect(sections.dangerSigns.first.id, 'D01');
  });

  test('ClinicalDictionary covers comprehensive ASHA disease scope', () {
    expect(ClinicalDictionary.allDiseases.length, greaterThanOrEqualTo(12));

    final fever = ClinicalDictionary.getById('DIS_FEVER');
    expect(fever, isNotNull);
    expect(fever!.nameEn, contains('Fever'));
    expect(fever.counterMeasures, isNotEmpty);
    expect(fever.medicines, isNotEmpty);
    expect(fever.dangerSigns, isNotEmpty);
    expect(fever.referralProtocol, isNotEmpty);

    final feverSearch = ClinicalDictionary.search('fever');
    expect(feverSearch.first.id, 'DIS_FEVER');

    final diarrhoeaSearch = ClinicalDictionary.search('diarrhoea');
    expect(diarrhoeaSearch.first.id, 'DIS_DIARRHOEA');
  });
}
