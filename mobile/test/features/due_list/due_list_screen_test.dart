import 'package:asha_platform/app/theme/app_theme.dart';
import 'package:asha_platform/features/due_list/presentation/due_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('due list shows calendar above the task cards', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light, home: const DueListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('due_calendar')), findsOneWidget);
    expect(find.byType(CalendarDatePicker), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Savitri Devi'), findsOneWidget);

    await tester.tap(find.byKey(const Key('due_calendar_toggle')));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarDatePicker), findsNothing);

    await tester.tap(find.byKey(const Key('due_calendar_toggle')));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarDatePicker), findsOneWidget);
  });
}
