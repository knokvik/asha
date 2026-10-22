import 'package:asha_platform/core/bhasha/hi_mr_repair.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Hindi roman clinic words become Devanagari before translation', () {
    expect(
      prepareHeardForTranslation('baccha ko fever hai ors do', 'hi'),
      'बच्चा ko बुखार hai ओआरएस do',
    );
  });

  test('Marathi uses Marathi words for the same roman line', () {
    expect(
      prepareHeardForTranslation('baby la fever ahe', 'mr'),
      'बाळ la ताप ahe',
    );
  });

  test('Bengali is not rewritten by the Hindi and Marathi list', () {
    expect(
      prepareHeardForTranslation('<bn> baby ke fever', 'bn'),
      'baby ke fever',
    );
  });

  test('a Dolphin language tag is removed', () {
    expect(prepareHeardForTranslation('<hi> पानी नहीं', 'hi'), 'पानी नहीं');
  });
}
