import 'package:flutter_test/flutter_test.dart';
import 'package:asha_platform/core/database/app_database.dart';
import 'package:asha_platform/core/triage/models/triage_flag.dart';
import 'package:asha_platform/core/triage/models/triage_inputs.dart';
import 'package:asha_platform/features/referral/domain/facility_capabilities.dart';
import 'package:asha_platform/features/referral/domain/offline_referral_router.dart';

FacilityDirectoryData _facility({
  required String id,
  required String name,
  required String level,
  required double latitude,
  required String services,
}) {
  return FacilityDirectoryData(
    id: id,
    name: name,
    facilityLevel: level,
    district: 'Test district',
    latitude: latitude,
    longitude: 77,
    servicesJson: services,
    isActive: true,
    lastUpdatedAt: 1,
  );
}

void main() {
  final facilities = [
    _facility(
      id: 'wrong-phc',
      name: 'Nearest Generic PHC',
      level: 'PHC',
      latitude: 20.001,
      services: '["OUTPATIENT"]',
    ),
    _facility(
      id: 'blood-fru',
      name: 'Verified FRU with blood and delivery',
      level: 'FRU',
      latitude: 20.03,
      services:
          '["blood_bank:yes", "delivery_room:yes", "route_network_v1:yes"]',
    ),
    _facility(
      id: 'nrc',
      name: 'District NRC',
      level: 'DH',
      latitude: 20.04,
      services: '["nrc:yes"]',
    ),
    _facility(
      id: 'snake',
      name: 'Antivenom and blood unit',
      level: 'CHC',
      latitude: 20.05,
      services: '["antivenom:yes", "blood_bank:yes", "route_network_v1:yes", "route_ferry_safe:yes"]',
    ),
    _facility(
      id: 'abhwc',
      name: 'Ayushman Arogya Mandir',
      level: 'SUB_CENTRE',
      latitude: 20.06,
      services: '["ab_hwc:yes", "cho:yes", "ncd_clinic:yes"]',
    ),
    _facility(
      id: 'pharmacy',
      name: 'Jan Aushadhi Kendra',
      level: 'PHC',
      latitude: 20.07,
      services: '["janaushadhi:yes"]',
    ),
  ];

  test('obstetric bleeding requires blood and delivery capacity', () {
    final plan = OfflineReferralRouter.plan(
      allFacilities: facilities,
      request: const OfflineRoutingRequest(
        triageFlag: TriageFlag.red,
        obstetricBleeding: true,
      ),
      ashaLatitude: 20,
      ashaLongitude: 77,
    );

    expect(plan.destinations.map((item) => item.facility.id), ['blood-fru']);
    expect(plan.destinations.single.hasExactCapabilities, isTrue);
    expect(plan.emergencyNumber, '102');
  });

  test('MUAC strictly below 115 mm routes to NRC, not nearest PHC', () {
    final plan = OfflineReferralRouter.plan(
      allFacilities: facilities,
      request: const OfflineRoutingRequest(
        triageFlag: TriageFlag.red,
        muacMm: 114.9,
      ),
    );

    expect(plan.scenario, ReferralRoutingScenario.severeAcuteMalnutrition);
    expect(plan.destinations.single.facility.id, 'nrc');
  });

  test('MUAC exactly 115 mm does not falsely classify SAM', () {
    final request = const OfflineRoutingRequest(
      triageFlag: TriageFlag.yellow,
      muacMm: 115,
    );
    expect(request.scenario, ReferralRoutingScenario.routine);
  });

  test('snakebite requires antivenom and blood and prefers tagged routes', () {
    final plan = OfflineReferralRouter.plan(
      allFacilities: facilities,
      request: const OfflineRoutingRequest(
        triageFlag: TriageFlag.red,
        snakebite: true,
        avoidFerryCrossings: true,
      ),
    );

    expect(plan.destinations.single.facility.id, 'snake');
    expect(
      plan.destinations.single.facility.hasCapability(
        FacilityCapability.antivenom,
      ),
      isTrue,
    );
    expect(plan.warnings, isEmpty);
  });

  test('high BP routes to AB-HWC with CHO/NCD capability', () {
    final inputs = TriageInputs(values: {'systolic_bp': 160});
    final request = OfflineRoutingRequest.fromTriageInputs(
      inputs,
      triageFlag: TriageFlag.yellow,
    );
    final plan = OfflineReferralRouter.plan(
      allFacilities: facilities,
      request: request,
    );

    expect(plan.scenario, ReferralRoutingScenario.highBloodPressure);
    expect(plan.destinations.single.facility.id, 'abhwc');
  });

  test('specialised routing does not fall back to an unverified facility', () {
    final plan = OfflineReferralRouter.plan(
      allFacilities: facilities.where((row) => row.id == 'wrong-phc').toList(),
      request: const OfflineRoutingRequest(
        triageFlag: TriageFlag.red,
        snakebite: true,
      ),
    );

    expect(plan.destinations, isEmpty);
    expect(plan.warnings.single, contains('No locally verified facility'));
  });
}
