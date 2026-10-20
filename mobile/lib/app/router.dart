import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pin_setup_screen.dart';
import '../features/due_list/presentation/due_list_screen.dart';
import '../features/home/presentation/dashboard_screen.dart';
import '../features/home/presentation/profile_screen.dart';
import '../features/home/presentation/tools_screen.dart';

// Registry & Households
import '../features/household/presentation/beneficiary_search_screen.dart';
import '../features/household/presentation/beneficiary_timeline_screen.dart';
import '../features/household/presentation/consent_screen.dart';
import '../features/household/presentation/household_form_screen.dart';
import '../features/household/presentation/household_list_screen.dart';
import '../features/household/presentation/household_detail_screen.dart';

// Triage & Referral
import '../features/referral/presentation/referral_slip_screen.dart';
import '../features/triage/presentation/language_bridge_screen.dart';
import '../features/triage/presentation/setu_questions_screen.dart';
import '../features/triage/presentation/triage_assessment_screen.dart';

// Clinical Programs Hub & Protocols
import '../features/clinical_programs/presentation/programs_hub_screen.dart';
import '../features/clinical_programs/anc_pnc/presentation/anc_registration_screen.dart';
import '../features/clinical_programs/anc_pnc/presentation/anc_visit_screen.dart';
import '../features/clinical_programs/anc_pnc/presentation/pnc_visit_screen.dart';
import '../features/clinical_programs/hbnc/presentation/hbnc_visit_screen.dart';
import '../features/clinical_programs/hbyc/presentation/hbyc_visit_screen.dart';
import '../features/clinical_programs/hbyc/domain/hbyc_models.dart';
import '../features/clinical_programs/ncd/presentation/cbac_screening_screen.dart';
import '../features/clinical_programs/ncd/presentation/ncd_register_screen.dart';
import '../features/clinical_programs/immunization/presentation/child_immunization_card_screen.dart';
import '../features/clinical_programs/immunization/presentation/vhsnd_session_screen.dart';
import '../features/clinical_programs/nutrition/presentation/growth_monitoring_screen.dart';
import '../features/clinical_programs/tb/presentation/presumptive_tb_screen.dart';
import '../features/clinical_programs/tb/presentation/tb_treatment_card_screen.dart';
import '../features/clinical_programs/tb/domain/tb_models.dart';

// Operations, Ledger & Inventory
import '../features/learning/presentation/learning_screen.dart';
import '../features/incentives/data/earnings_repository.dart';
import '../features/incentives/domain/incentive_service.dart';
import '../features/incentives/presentation/earnings_screen.dart';
import '../features/devices/presentation/stock_management_screen.dart';
import '../features/devices/data/stock_service.dart';
import '../features/devices/presentation/clinical_calculators_screen.dart';
import '../features/devices/presentation/breath_counter_screen.dart';
import '../features/devices/presentation/measurement_capture_screen.dart';
import '../features/devices/domain/ble_models.dart';
import '../features/reports/presentation/register_viewer_screen.dart';
import '../features/vhsnd/presentation/health_education_library_screen.dart';
import '../features/vhsnd/domain/vhsnd_models.dart';
import '../features/due_list/presentation/route_map_screen.dart';
import '../features/map/presentation/india_map_page.dart';
import '../features/due_list/presentation/coverage_analysis_screen.dart';
import '../features/due_list/domain/route_models.dart';
import '../features/teleconsultation/presentation/teleconsultation_screen.dart';
import '../shared/providers/core_providers.dart';

/// Notifier holding current authenticated worker role ('asha', 'af', 'admin', etc.).
/// Default is 'asha'.
class UserRoleNotifier extends Notifier<String> {
  @override
  String build() => 'asha';

  void setRole(String role) => state = role;
}

final userRoleProvider =
    NotifierProvider<UserRoleNotifier, String>(UserRoleNotifier.new);

/// List of routes shared across routerProvider and appRouter
List<RouteBase> _buildAppRoutes(Ref? ref) {
  return [
    GoRoute(
      path: '/',
      redirect: (context, state) => '/home',
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const PinSetupScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/tools',
      builder: (context, state) => const ToolsScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/due-list',
      builder: (context, state) => const DueListScreen(),
    ),
    GoRoute(
      path: '/calendar',
      builder: (context, state) => const DueListScreen(initialTab: 1),
    ),
    GoRoute(
      path: '/coverage',
      builder: (context, state) => const DueListScreen(initialTab: 2),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const BeneficiarySearchScreen(),
    ),
    GoRoute(
      path: '/households',
      builder: (context, state) => const HouseholdListScreen(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => const HouseholdFormScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/household/new',
      builder: (context, state) => const HouseholdFormScreen(),
    ),
    GoRoute(
      path: '/household/:id',
      builder: (context, state) => HouseholdDetailScreen(
        householdId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: '/beneficiary/:id',
      builder: (context, state) => BeneficiaryTimelineScreen(
        memberId: state.pathParameters['id'] ?? '',
      ),
      routes: [
        GoRoute(
          path: 'consent',
          builder: (context, state) => ConsentScreen(
            memberId: state.pathParameters['id'] ?? '',
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/visit/:id',
      builder: (context, state) => BeneficiaryTimelineScreen(
        memberId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: '/triage',
      builder: (context, state) => const TriageAssessmentScreen(),
    ),
    GoRoute(
      path: '/triage/questions',
      builder: (context, state) => const SetuQuestionsScreen(),
    ),
    GoRoute(
      path: '/triage/language',
      builder: (context, state) => const LanguageBridgeScreen(),
    ),
    GoRoute(
      path: '/referral/:id',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is ReferralSlipScreen) return extra;
        return ReferralSlipScreen(memberId: state.pathParameters['id']);
      },
    ),

    // ── Clinical Programs Hub & Direct Routes ──────────────────────────────
    GoRoute(
      path: '/programs',
      builder: (context, state) => const ProgramsHubScreen(),
      routes: [
        GoRoute(
          path: 'anc-register',
          builder: (context, state) => AncRegistrationScreen(
            womanId: state.uri.queryParameters['memberId'] ?? 'mem_pooja_01',
            womanName: state.uri.queryParameters['name'] ?? 'Pooja Devi',
            maternalAgeYears: 24,
            ashaId: 'asha-01',
          ),
        ),
        GoRoute(
          path: 'anc-visit',
          builder: (context, state) => AncVisitScreen(
            womanId: state.uri.queryParameters['memberId'] ?? 'mem_pooja_01',
            womanName: state.uri.queryParameters['name'] ?? 'Pooja Devi',
            visitScheduleId: state.uri.queryParameters['visitId'] ?? 'sched_anc_01',
            contactNumber: int.tryParse(state.uri.queryParameters['contact'] ?? '3') ?? 3,
            gestationWeeks: int.tryParse(state.uri.queryParameters['weeks'] ?? '28') ?? 28,
            ashaId: 'asha-01',
          ),
        ),
        GoRoute(
          path: 'pnc-visit',
          builder: (context, state) => PncVisitScreen(
            motherId: state.uri.queryParameters['memberId'] ?? 'mem_kavita_02',
            motherName: state.uri.queryParameters['name'] ?? 'Kavita Singh',
            visitScheduleId: state.uri.queryParameters['visitId'] ?? 'sched_pnc_01',
            visitDay: int.tryParse(state.uri.queryParameters['day'] ?? '7') ?? 7,
            isInstitutionalDelivery: true,
            ashaId: 'asha-01',
          ),
        ),
        GoRoute(
          path: 'hbnc-visit',
          builder: (context, state) => HbncVisitScreen(
            newbornId: state.uri.queryParameters['memberId'] ?? 'mem_aarav_02',
            motherId: 'mem_kavita_02',
            visitScheduleId: state.uri.queryParameters['visitId'] ?? 'sched_hbnc_01',
            visitTitle: 'HBNC Visit 3 (Day 7)',
            birthWeightKg: 2.7,
            isPreterm: false,
            ashaId: 'asha-01',
          ),
        ),
        GoRoute(
          path: 'hbyc-visit',
          builder: (context, state) => HbycVisitScreen(
            childId: state.uri.queryParameters['memberId'] ?? 'mem_aarav_02',
            childName: state.uri.queryParameters['name'] ?? 'Baby Aarav',
            childDob: DateTime.now().subtract(const Duration(days: 90)),
            visitScheduleId: state.uri.queryParameters['visitId'] ?? 'sched_hbyc_01',
            milestone: HbycMilestone.month3,
            ashaId: 'asha-01',
          ),
        ),
        GoRoute(
          path: 'cbac',
          builder: (context, state) => CbacScreeningScreen(
            memberId: state.uri.queryParameters['memberId'] ?? 'mem_ramprasad_03',
            beneficiaryName: state.uri.queryParameters['name'] ?? 'Ramprasad Verma',
            ageYears: int.tryParse(state.uri.queryParameters['age'] ?? '62') ?? 62,
            sex: state.uri.queryParameters['sex'] ?? 'M',
            ashaId: 'asha-01',
          ),
        ),
        GoRoute(
          path: 'ncd-register',
          builder: (context, state) => const NcdRegisterScreen(
            ashaId: 'asha-01',
          ),
        ),
        GoRoute(
          path: 'immunization',
          builder: (context, state) => ChildImmunizationCardScreen(
            memberId: state.uri.queryParameters['memberId'] ?? 'mem_aarav_02',
            childName: state.uri.queryParameters['name'] ?? 'Baby Aarav',
            dateOfBirth: DateTime.now().subtract(const Duration(days: 90)),
            ashaId: 'asha-01',
          ),
        ),
        GoRoute(
          path: 'growth',
          builder: (context, state) => GrowthMonitoringScreen(
            memberId: state.uri.queryParameters['memberId'] ?? 'mem_aarav_02',
            childName: state.uri.queryParameters['name'] ?? 'Baby Aarav',
            dateOfBirth: DateTime.now().subtract(const Duration(days: 90)),
            sex: 'M',
            ashaId: 'asha-01',
          ),
        ),
        GoRoute(
          path: 'tb-presumptive',
          builder: (context, state) => PresumptiveTbScreen(
            memberId: state.uri.queryParameters['memberId'] ?? 'mem_ramprasad_03',
            beneficiaryName: state.uri.queryParameters['name'] ?? 'Ramprasad Verma',
            ashaId: 'asha-01',
          ),
        ),
        GoRoute(
          path: 'tb-card',
          builder: (context, state) => TbTreatmentCardScreen(
            patient: TbTreatmentPatient(
              id: 'tb_pat_01',
              memberId: 'mem_ramprasad_03',
              beneficiaryName: 'Ramprasad Verma',
              nikshayId: 'NK-2026-8819',
              site: TbSite.pulmonary,
              regimen: TbRegimenType.dsTbDailyFdc,
              startDate: DateTime.now().subtract(const Duration(days: 35)),
              treatmentSupporterName: 'Sunita Sharma',
              treatmentSupporterPhone: '9876543210',
              supporterRelationship: 'ASHA Care Supporter',
              totalDosesPrescribed: 168,
              dosesCompleted: 33,
              consecutiveMissedDoses: 0,
              nikshayPoshanStatus: NikshayPoshanStatus.installmentReceived,
              ashaId: 'asha-01',
            ),
            ashaId: 'asha-01',
          ),
        ),
        GoRoute(
          path: 'vhsnd',
          builder: (context, state) => const VhsndSessionScreen(
            villageName: 'Rampur',
            hamlet: 'Ward 1 (Main Village)',
            anganwadiCenterName: 'Rampur Anganwadi Center 1',
            ashaId: 'asha-01',
          ),
        ),
      ],
    ),

    // ── Training & Micro-Learning ──────────────────────────────────────────
    GoRoute(
      path: '/learning',
      builder: (context, state) {
        if (ref != null) {
          return LearningScreen(database: ref.read(appDatabaseProvider));
        }
        return const _FallbackContainer(title: 'Learning');
      },
    ),

    // ── Monthly Earnings & Incentives ──────────────────────────────────────
    GoRoute(
      path: '/incentives',
      builder: (context, state) {
        if (ref != null) {
          final db = ref.read(appDatabaseProvider);
          final service = IncentiveService(
            db: db,
            syncEngine: ref.read(syncEngineProvider),
          );
          return EarningsScreen(
            repository: EarningsRepository(db: db, incentiveService: service),
            workerId: 'asha-01',
          );
        }
        return const _FallbackContainer(title: 'Incentives');
      },
    ),

    // ── Medicine & Equipment Stock Management ──────────────────────────────
    GoRoute(
      path: '/stock',
      builder: (context, state) {
        if (ref != null) {
          return StockManagementScreen(
            stockService: StockService(ref.read(appDatabaseProvider)),
            workerId: 'asha-01',
            workerName: 'Sunita Sharma (ASHA)',
          );
        }
        return const _FallbackContainer(title: 'Stock Management');
      },
    ),

    // ── Government Registers & PDF Reports ─────────────────────────────────
    GoRoute(
      path: '/reports',
      builder: (context, state) {
        if (ref != null) {
          return RegisterViewerScreen(
            db: ref.read(appDatabaseProvider),
            workerId: 'asha-01',
            ashaName: 'Sunita Sharma',
            villageName: 'Rampur Gram Panchayat',
          );
        }
        return const _FallbackContainer(title: 'Registers & Reports');
      },
    ),

    // ── Zero-Hardware Measurement Aids & Calculators ───────────────────────
    GoRoute(
      path: '/calculators',
      builder: (context, state) => const ClinicalCalculatorsScreen(),
    ),
    GoRoute(
      path: '/breath-counter',
      builder: (context, state) => const BreathCounterScreen(
        childAgeMonths: 12,
        childName: 'Child Assessment',
      ),
    ),

    // ── Bluetooth Medical Device Capture ───────────────────────────────────
    GoRoute(
      path: '/bluetooth',
      builder: (context, state) => const MeasurementCaptureScreen(
        profile: DeviceProfileConfig(
          id: 'bp_omron_01',
          deviceName: 'Digital Blood Pressure Monitor',
          measurementType: MeasurementType.bloodPressure,
          unit: 'mmHg',
          minPlausible: 60,
          maxPlausible: 260,
          secondaryMinPlausible: 40,
          secondaryMaxPlausible: 140,
        ),
        patientId: 'mem_pooja_01',
        patientName: 'Pooja Devi',
        workerId: 'asha-01',
      ),
    ),

    // ── Health Education Multimedia Library ────────────────────────────────
    GoRoute(
      path: '/education',
      builder: (context, state) => HealthEducationLibraryScreen(
        initialAssets: const [
          HealthEducationAsset(
            id: 'hea_01',
            title: 'Antenatal Care & Danger Signs Guide',
            topic: HealthEducationTopic.maternalHealth,
            mediaType: 'audio_clip',
            assetPath: 'assets/audio/anc_guide.mp3',
            durationSeconds: 180,
            description: 'Audio advice on 4 antenatal checkups, IFA tablet consumption, and pre-eclampsia warning signs in Hindi.',
            tags: ['ANC', 'Maternal', 'High Risk'],
          ),
          HealthEducationAsset(
            id: 'hea_02',
            title: 'Essential Newborn Care & KMC Practice',
            topic: HealthEducationTopic.newbornCare,
            mediaType: 'illustrated_card',
            assetPath: 'assets/cards/kmc_poster.png',
            durationSeconds: 120,
            description: 'Illustrated Kangaroo Mother Care instructions for low birth weight infants (<2.5kg).',
            tags: ['HBNC', 'KMC', 'Newborn'],
          ),
          HealthEducationAsset(
            id: 'hea_03',
            title: 'Routine Immunization Schedule & AEFI Safety',
            topic: HealthEducationTopic.immunization,
            mediaType: 'video_clip',
            assetPath: 'assets/video/immunization_schedule.mp4',
            durationSeconds: 240,
            description: 'Vaccine timings from birth to 5 years, fever management after Pentavalent vaccine.',
            tags: ['Vaccines', 'Immunization', 'Child'],
          ),
          HealthEducationAsset(
            id: 'hea_04',
            title: 'Hypertension & Diabetes Prevention (CBAC)',
            topic: HealthEducationTopic.ncdPrevention,
            mediaType: 'illustrated_card',
            assetPath: 'assets/cards/ncd_lifestyle.png',
            durationSeconds: 150,
            description: 'Salt reduction, daily physical activity, and avoiding tobacco to prevent stroke and heart disease.',
            tags: ['NCD', 'Hypertension', 'Diabetes'],
          ),
        ],
        activeCampaigns: [
          CommunityCampaign(
            id: 'camp_01',
            campaignCode: 'pulse_polio',
            title: 'National Immunization Day (Pulse Polio)',
            startDate: DateTime.now().subtract(const Duration(days: 2)),
            endDate: DateTime.now().add(const Duration(days: 5)),
            checklistItems: const ['Booth setup at Anganwadi', 'House-to-house B marking', 'Zero-dose tracking'],
            targetDescription: 'All children 0-5 years in Rampur village',
          ),
          CommunityCampaign(
            id: 'camp_02',
            campaignCode: 'tb_active_case',
            title: 'Active TB Case Finding Campaign',
            startDate: DateTime.now().subtract(const Duration(days: 10)),
            endDate: DateTime.now().add(const Duration(days: 20)),
            checklistItems: const ['Screen all elderly >60', 'Sputum sample collection for cough >2 wks', 'Nikshay entry'],
            targetDescription: 'Vulnerable settlements and brick-kiln hamlets',
          ),
        ],
      ),
    ),

    // ── Offline Route & Hamlet Map ─────────────────────────────────────────
    GoRoute(
      path: '/route-map',
      builder: (context, state) => const RouteMapScreen(
        route: PlannedRoute(
          isOptInGpsUsed: true,
          startLocation: GeoCoordinate(latitude: 25.3176, longitude: 82.9739),
          orderedWaypoints: [
            HamletWaypoint(
              hamlet: 'Ward 2 (Purwa Tola)',
              village: 'Rampur',
              coordinate: GeoCoordinate(latitude: 25.3190, longitude: 82.9750),
              landmarkNotes: ['Near Primary School', 'Old Banyan Tree'],
              tasks: [],
            ),
            HamletWaypoint(
              hamlet: 'Ward 1 (Main Village)',
              village: 'Rampur',
              coordinate: GeoCoordinate(latitude: 25.3210, longitude: 82.9780),
              landmarkNotes: ['Anganwadi Centre 1', 'Panchayat Bhavan'],
              tasks: [],
            ),
            HamletWaypoint(
              hamlet: 'Ward 3 (Basti)',
              village: 'Rampur',
              coordinate: GeoCoordinate(latitude: 25.3250, longitude: 82.9810),
              landmarkNotes: ['Community Handpump', 'Hanuman Mandir'],
              tasks: [],
            ),
          ],
          totalEstimatedDistanceKm: 3.5,
          estimatedWalkingDuration: Duration(minutes: 75),
          blockedWaypoints: [],
        ),
      ),
    ),

    GoRoute(
      path: '/geo-map',
      builder: (context, state) => const IndiaMapPage(),
    ),

    // ── Area Coverage Analysis ─────────────────────────────────────────────
    GoRoute(
      path: '/coverage',
      builder: (context, state) => const CoverageAnalysisScreen(
        report: CoverageAnalysisReport(
          village: 'Rampur Gram Panchayat',
          totalHamlets: 4,
          accessibleHamlets: 3,
          seasonallyBlockedHamlets: 1,
          ashaConsentGiven: true,
          hamletVisitFrequencies: {
            'Ward 1 (Main Village)': 18,
            'Ward 2 (Purwa Tola)': 14,
            'Ward 3 (Basti)': 10,
            'Majra Khurd (Flooded)': 2,
          },
          hamletCompletionRates: {
            'Ward 1 (Main Village)': 0.94,
            'Ward 2 (Purwa Tola)': 0.88,
            'Ward 3 (Basti)': 0.82,
            'Majra Khurd (Flooded)': 0.35,
          },
          accessBarriersHistory: [
            'Majra Khurd culvert waterlogged during monsoon (July-Sept)',
          ],
          workloadRebalanceSuggestions: [
            'Prioritize Majra Khurd dry-season mobile camp',
            'Pair with second ASHA worker for Purwa Tola high-density ANC cohort',
          ],
        ),
      ),
    ),

    // ── Teleconsultation & Support ─────────────────────────────────────────
    GoRoute(
      path: '/support',
      builder: (context, state) => const TeleconsultationScreen(),
    ),

    // ── Settings & Supervisor Guard ────────────────────────────────────────
    GoRoute(
      path: '/settings',
      builder: (context, state) => const DueListScreen(),
    ),
    GoRoute(
      path: '/af',
      builder: (context, state) => const DueListScreen(),
    ),
  ];
}

/// Fallback container in the rare event of uninitialized provider ref
class _FallbackContainer extends StatelessWidget {
  final String title;
  const _FallbackContainer({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title loading...')),
    );
  }
}

/// Provider for app router with role-based guards.
final routerProvider = Provider<GoRouter>((ref) {
  final role = ref.watch(userRoleProvider);

  return GoRouter(
    initialLocation: '/auth',
    redirect: (context, state) {
      final loc = state.uri.path;

      // Root redirect
      if (loc == '/') {
        return '/home';
      }

      // Role-based guard for AF supervisory routes (/af/*)
      if (loc.startsWith('/af')) {
        if (role != 'af' && role != 'admin') {
          return '/home';
        }
      }

      return null;
    },
    routes: _buildAppRoutes(ref),
  );
});

/// Backwards compatibility global reference.
final GoRouter appRouter = GoRouter(
  initialLocation: '/auth',
  routes: _buildAppRoutes(null),
);
