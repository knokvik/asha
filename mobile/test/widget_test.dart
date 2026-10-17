import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asha_platform/app/app.dart';

void main() {
  testWidgets('AshaApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AshaApp()));
    await tester.pumpAndSettle();
    expect(find.byType(AshaApp), findsOneWidget);
  });
}
