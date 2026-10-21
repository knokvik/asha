import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/features/household/data/member_search_repository.dart';
import 'package:asha_platform/features/search/data/offline_search_index.dart';
import 'package:asha_platform/features/search/presentation/search_assistant_screen.dart';

void main() {
  const sampleCsv = '''
id,category,keyword_en,keyword_hi,keyword_mr,name,purpose,dose_or_protocol,how_to_use,when_to_refer,danger_signs,source_ref,approx_price_inr
DIS01,disease,fever pyrexia temperature bukhar,बुखार ताप,ताप ताप,Fever (Pyrexia) / Acute Febrile Illness,Elevation of body temperature ≥37.5°C. Early antipyretic relief and danger sign triage.,"Paracetamol: 10–15 mg/kg every 6h (max 4 doses/24h)","Tepid sponging with room-temperature water, continuous fluid intake, light clothing","High fever >39°C, stiff neck, convulsions, lethargy, fever >5 days","Convulsions, unable to drink, unconscious, stiff neck, petechial rash",IMCI 2014 + NVBDCP,-
M01,medicine,paracetamol fever,पैरासिटामोल बुखार,पॅरासिटामोल ताप,Paracetamol 500mg,Fever and pain relief,10-15 mg/kg every 6h,Take with water,Refer if stiff neck,Convulsions,IMCI,₹10
G01,guide,fever care tepid sponging,बुखार देखभाल,ताप काळजी,Fever home care guide,Tepid sponging SOP,-,Room temperature water,Fever >5 days,Danger signs,IMCI,-
D01,danger_sign,fever convulsions stiff neck,दौरे बुखार,ताप झटके,High fever with convulsions,Febrile seizure danger sign,-,Do not put objects in mouth,Emergency referral,Convulsions,IMCI,-
''';

  testWidgets('renders bottom-docked search bar with integrated back button and shows 4 sections for fever', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final testIndex = OfflineSearchIndex.fromCsv(sampleCsv);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offlineSearchIndexProvider.overrideWith((ref) => Future.value(testIndex)),
          beneficiarySearchResultsProvider('fever').overrideWith((ref) => Future.value([])),
        ],
        child: const MaterialApp(
          home: SearchAssistantScreen(initialQuery: 'fever'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify bottom search bar exists with integrated back button
    expect(find.byKey(const Key('search_assistant_back_button')), findsOneWidget);
    expect(find.byKey(const Key('offline_assistant_search_field')), findsOneWidget);
    expect(find.byKey(const Key('offline_assistant_clear_button')), findsOneWidget);

    // 2. Verify all 4 clinical sections are displayed
    expect(find.text('1. Clinical Conditions & Diseases'), findsOneWidget);
    expect(find.text('2. Medicines & Dosing Protocols'), findsOneWidget);
    expect(find.text('3. Field Guides & Action Protocols'), findsOneWidget);
    expect(find.text('4. Danger Signs & Red Flag Warnings'), findsOneWidget);

    // 3. Verify Disease card is displayed
    expect(find.byKey(const Key('disease_card_DIS_FEVER')), findsOneWidget);
    expect(find.text('Fever (Pyrexia) / Acute Febrile Illness'), findsOneWidget);

    // 4. Tap the Fever card and verify the Clinical Dictionary sheet opens
    await tester.tap(find.byKey(const Key('disease_card_DIS_FEVER')));
    await tester.pumpAndSettle();

    // Verify Clinical Dictionary sections are visible
    expect(find.text('1. Introduction & Clinical Definition'), findsOneWidget);
    expect(find.text('2. Counter Measures & Action Steps'), findsOneWidget);

    // Scroll down the bottom sheet list to view remaining sections
    await tester.scrollUntilVisible(
      find.text('4. Danger Signs & Red Flags (Immediate Referral)'),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('4. Danger Signs & Red Flags (Immediate Referral)'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('5. Facility Referral & Ambulance Protocol'),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('5. Facility Referral & Ambulance Protocol'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('6. Community Counseling & Prevention'),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('6. Community Counseling & Prevention'), findsOneWidget);
  });
}
