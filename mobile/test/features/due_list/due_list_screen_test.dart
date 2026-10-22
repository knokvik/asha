import 'package:asha_platform/app/theme/app_theme.dart';
import 'package:asha_platform/core/database/app_database.dart';
import 'package:asha_platform/features/due_list/presentation/due_list_screen.dart';
import 'package:asha_platform/shared/providers/core_providers.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('due list shows calendar above the task cards', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() => db.close());
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    await db.into(db.households).insert(
          HouseholdsCompanion.insert(
            id: 'hh_test',
            village: 'Rampur',
            headName: 'Savitri Devi',
            createdAt: nowMs,
            updatedAt: nowMs,
            createdBy: 'test_asha',
          ),
        );
    await db.into(db.members).insert(
          MembersCompanion.insert(
            id: 'mem_test',
            householdId: 'hh_test',
            name: 'Savitri Devi',
            sex: 'F',
            lifecycleStatus: const Value('active'),
            consentStatus: const Value('given'),
            createdAt: nowMs,
            updatedAt: nowMs,
            createdBy: 'test_asha',
          ),
        );
    await db.into(db.visitSchedules).insert(
          VisitSchedulesCompanion.insert(
            id: 'task_test_01',
            memberId: 'mem_test',
            programCode: 'anc',
            visitType: 'ANC Routine Checkup',
            dueDate: nowMs,
            status: const Value('due'),
            createdAt: nowMs,
          ),
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
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
