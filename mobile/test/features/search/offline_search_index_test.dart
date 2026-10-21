import 'package:flutter_test/flutter_test.dart';

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
}
