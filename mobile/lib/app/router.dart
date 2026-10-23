import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pin_setup_screen.dart';
import '../core/l10n/language_provider.dart';
import '../features/due_list/presentation/due_list_screen.dart';
import '../features/home/presentation/tools_screen.dart';
import '../features/home/presentation/edit_worker_profile_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/settings/presentation/pack_manager_screen.dart';

// Registry & Households
import '../features/household/presentation/beneficiary_timeline_screen.dart';
import '../features/household/presentation/consent_screen.dart';
import '../features/sync/presentation/peer_sync_screen.dart';
import '../features/household/presentation/household_form_screen.dart';
import '../features/household/presentation/household_list_screen.dart';
import '../features/household/presentation/household_detail_screen.dart';
import '../features/household/presentation/household_profile_screen.dart';
import '../features/search/presentation/search_assistant_screen.dart';
import '../features/triage/presentation/triage_flow_screen.dart';
import '../features/triage/presentation/triage_history_screen.dart';
import '../features/reports/presentation/reports_incentives_screen.dart';
import '../shared/shell/main_shell.dart';
import '../shared/shell/shell_tab.dart';
import '../features/sync/presentation/sync_queue_screen.dart';
import '../features/tracking/presentation/tracking_screen.dart';

// Triage & Referral
import '../features/referral/presentation/referral_slip_screen.dart';
import '../features/triage/presentation/language_bridge_screen.dart';
import '../core/bhasha/home_page.dart';
import '../core/bhasha/settings_store.dart';

// Clinical Programs Hub & Protocols
import '../features/clinical_programs/presentation/programs_hub_screen.dart'
    show ProgramsHubScreen;
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
import '../features/reminders/presentation/reminders_screen.dart';
import '../features/sync_status/presentation/sync_status_screen.dart';
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
import '../core/pdf/register_models.dart';
import '../features/vhsnd/presentation/health_education_library_screen.dart';
import '../features/vhsnd/domain/vhsnd_models.dart';
import '../features/due_list/presentation/route_map_screen.dart';
import '../features/due_list/presentation/coverage_analysis_screen.dart';
import '../features/due_list/domain/route_models.dart';
import '../features/teleconsultation/presentation/teleconsultation_screen.dart';
import '../features/map/presentation/india_map_page.dart';
import '../shared/providers/core_providers.dart';
import '../shared/providers/user_profile_provider.dart';

/// Returns the authenticated ASHA worker's ID from [userProfileProvider] when
/// a Riverpod [Ref] is available, otherwise falls back to the demo sentinel
/// 'asha-01'. All clinical-program routes pass this value so that records are
/// attributed to the correct worker rather than a hardcoded placeholder.
String _workerId(Ref? ref) {
  if (ref == null) return 'asha-01';
  final profile = ref.read(userProfileProvider);
  return profile.maybeWhen(data: (p) => p.ashaId, orElse: () => 'asha-01');
}

/// Notifier holding current authenticated worker role ('asha', 'af', 'admin', etc.).
/// Default is 'asha'.
class UserRoleNotifier extends Notifier<String> {
  @override
  String build() => 'asha';

  void setRole(String role) => state = role;
}

final userRoleProvider = NotifierProvider<UserRoleNotifier, String>(
  UserRoleNotifier.new,
);

/// Helper constructing smooth SF Pro right-to-left slide page transitions.
Page<dynamic> _buildSlidePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.fastOutSlowIn,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      );
    },
  );
}

/// List of routes shared across routerProvider and appRouter
List<RouteBase> _buildAppRoutes(Ref? ref) {
  return [
    GoRoute(
      path: '/',
      redirect: (context, state) =>
          ref?.read(databaseKeyProvider) == null ? '/auth' : '/home',
    ),
    GoRoute(path: '/auth', builder: (context, state) => const PinSetupScreen()),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) =>
          _buildSlidePage(state: state, child: const MainShell()),
    ),
    GoRoute(
      path: '/sync',
      pageBuilder: (context, state) =>
          _buildSlidePage(state: state, child: const SyncQueueScreen()),
    ),
    GoRoute(
      path: '/tools',
      pageBuilder: (context, state) =>
          _buildSlidePage(state: state, child: const ToolsScreen()),
    ),
    GoRoute(
      path: '/tracking',
      pageBuilder: (context, state) =>
          _buildSlidePage(state: state, child: const TrackingScreen()),
      routes: [
        GoRoute(
          path: 'detail',
          pageBuilder: (context, state) {
            final record = state.extra;
            return _buildSlidePage(
              state: state,
              child: record is TrackingRecord
                  ? TrackingDetailScreen(record: record)
                  : const TrackingScreen(),
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: '/profile/edit',
      pageBuilder: (context, state) =>
          _buildSlidePage(state: state, child: const EditWorkerProfileScreen()),
    ),
    GoRoute(
      path: '/profile',
      redirect: (context, state) {
        ref?.read(shellTabProvider.notifier).select(3);
        return '/home';
      },
    ),
    GoRoute(
      path: '/due-list',
      redirect: (context, state) {
        ref?.read(shellTabProvider.notifier).select(2);
        return '/home';
      },
    ),
    GoRoute(
      path: '/calendar',
      pageBuilder: (context, state) => _buildSlidePage(
        state: state,
        child: const DueListScreen(initialTab: 1),
      ),
    ),
    GoRoute(
      path: '/coverage',
      pageBuilder: (context, state) => _buildSlidePage(
        state: state,
        child: const DueListScreen(initialTab: 2),
      ),
    ),
    GoRoute(
      path: '/search',
      pageBuilder: (context, state) => _buildSlidePage(
        state: state,
        child: SearchAssistantScreen(
          initialQuery: state.uri.queryParameters['q'],
        ),
      ),
    ),
    GoRoute(
      path: '/households',
      pageBuilder: (context, state) => _buildSlidePage(
        state: state,
        child: HouseholdListScreen(
          initialQuery: state.uri.queryParameters['q'],
        ),
      ),
      routes: [
        GoRoute(
          path: 'new',
          pageBuilder: (context, state) =>
              _buildSlidePage(state: state, child: const HouseholdFormScreen()),
        ),
      ],
    ),
    GoRoute(
      path: '/household-profile',
      pageBuilder: (context, state) =>
          _buildSlidePage(state: state, child: const HouseholdProfileScreen()),
    ),
    GoRoute(
      path: '/household/new',
      pageBuilder: (context, state) =>
          _buildSlidePage(state: state, child: const HouseholdFormScreen()),
    ),
    GoRoute(
      path: '/household/:id',
      pageBuilder: (context, state) => _buildSlidePage(
        state: state,
        child: HouseholdDetailScreen(
          householdId: state.pathParameters['id'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: '/beneficiary/:id',
      pageBuilder: (context, state) => _buildSlidePage(
        state: state,
        child: BeneficiaryTimelineScreen(
          memberId: state.pathParameters['id'] ?? '',
        ),
      ),
      routes: [
        GoRoute(
          path: 'consent',
          pageBuilder: (context, state) => _buildSlidePage(
            state: state,
            child: ConsentScreen(memberId: state.pathParameters['id'] ?? ''),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/visit/:id',
      pageBuilder: (context, state) => _buildSlidePage(
        state: state,
        child: BeneficiaryTimelineScreen(
          memberId: state.pathParameters['id'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: '/peer-sync',
      pageBuilder: (context, state) =>
          _buildSlidePage(state: state, child: const PeerSyncScreen()),
    ),
    GoRoute(
      path: '/triage',
      pageBuilder: (context, state) =>
          _buildSlidePage(state: state, child: const TriageFlowScreen()),
    ),
    GoRoute(
      path: '/triage/assessment',
      redirect: (context, state) => '/triage',
    ),
    GoRoute(
      path: '/triage/history',
      pageBuilder: (context, state) =>
          _buildSlidePage(state: state, child: const TriageHistoryScreen()),
    ),
    GoRoute(
      path: '/clinical-programs',
      pageBuilder: (context, state) =>
          _buildSlidePage(state: state, child: const ProgramsHubScreen()),
    ),
    GoRoute(
      path: '/interpreter',
      pageBuilder: (context, state) => _buildSlidePage(
        state: state,
        child: HomePage(
          settings: SettingsStore(),
          autoDownloadMissingModels: false,
        ),
      ),
    ),
    GoRoute(
      path: '/interpreter/model',
      pageBuilder: (context, state) => _buildSlidePage(
        state: state,
        child: HomePage(
          settings: SettingsStore(),
          autoDownloadMissingModels: false,
        ),
      ),
    ),
    GoRoute(path: '/triage/questions', redirect: (context, state) => '/triage'),
    GoRoute(
      path: '/triage/language',
      pageBuilder: (context, state) =>
          _buildSlidePage(state: state, child: const LanguageBridgeScreen()),
    ),
    GoRoute(
      path: '/referral/:id',
      pageBuilder: (context, state) {
        final extra = state.extra;
        final widget = extra is ReferralSlipScreen
            ? extra
            : ReferralSlipScreen(memberId: state.pathParameters['id']);
        return _buildSlidePage(state: state, child: widget);
      },
    ),

    // ── Clinical Programs Hub & Direct Routes ──────────────────────────────
    GoRoute(
      path: '/programs',
      pageBuilder: (context, state) =>
          _buildSlidePage(state: state, child: const ProgramsHubScreen()),
      routes: [
        GoRoute(
          path: 'anc-register',
          builder: (context, state) => AncRegistrationScreen(
            womanId: state.uri.queryParameters['memberId'] ?? 'mem_pooja_01',
            womanName: state.uri.queryParameters['name'] ?? 'Pooja Devi',
            maternalAgeYears: 24,
            ashaId: _workerId(ref),
          ),
        ),
        GoRoute(
          path: 'anc-visit',
          builder: (context, state) => AncVisitScreen(
            womanId: state.uri.queryParameters['memberId'] ?? 'mem_pooja_01',
            womanName: state.uri.queryParameters['name'] ?? 'Pooja Devi',
            visitScheduleId:
                state.uri.queryParameters['visitId'] ?? 'sched_anc_01',
            contactNumber:
                int.tryParse(state.uri.queryParameters['contact'] ?? '3') ?? 3,
            gestationWeeks:
                int.tryParse(state.uri.queryParameters['weeks'] ?? '28') ?? 28,
            ashaId: _workerId(ref),
          ),
        ),
        GoRoute(
          path: 'pnc-visit',
          builder: (context, state) => PncVisitScreen(
            motherId: state.uri.queryParameters['memberId'] ?? 'mem_kavita_02',
            motherName: state.uri.queryParameters['name'] ?? 'Kavita Singh',
            visitScheduleId:
                state.uri.queryParameters['visitId'] ?? 'sched_pnc_01',
            visitDay:
                int.tryParse(state.uri.queryParameters['day'] ?? '7') ?? 7,
            isInstitutionalDelivery: true,
            ashaId: _workerId(ref),
          ),
        ),
        GoRoute(
          path: 'hbnc-visit',
          builder: (context, state) => HbncVisitScreen(
            newbornId: state.uri.queryParameters['memberId'] ?? 'mem_aarav_02',
            motherId: 'mem_kavita_02',
            visitScheduleId:
                state.uri.queryParameters['visitId'] ?? 'sched_hbnc_01',
            visitDay:
                int.tryParse(state.uri.queryParameters['day'] ?? '7') ?? 7,
            visitTitle: 'HBNC follow-up',
            birthWeightKg: 2.7,
            isPreterm: false,
            ashaId: _workerId(ref),
          ),
        ),
        GoRoute(
          path: 'hbyc-visit',
          builder: (context, state) => HbycVisitScreen(
            childId: state.uri.queryParameters['memberId'] ?? 'mem_aarav_02',
            childName: state.uri.queryParameters['name'] ?? 'Baby Aarav',
            childDob: DateTime.now().subtract(const Duration(days: 90)),
            visitScheduleId:
                state.uri.queryParameters['visitId'] ?? 'sched_hbyc_01',
            milestone: HbycMilestone.month3,
            ashaId: _workerId(ref),
          ),
        ),
        GoRoute(
          path: 'cbac',
          builder: (context, state) => CbacScreeningScreen(
            memberId:
                state.uri.queryParameters['memberId'] ?? 'mem_ramprasad_03',
            beneficiaryName:
                state.uri.queryParameters['name'] ?? 'Ramprasad Verma',
            ageYears:
                int.tryParse(state.uri.queryParameters['age'] ?? '62') ?? 62,
            sex: state.uri.queryParameters['sex'] ?? 'M',
            ashaId: _workerId(ref),
          ),
        ),
        GoRoute(
          path: 'ncd-register',
          builder: (context, state) =>
              NcdRegisterScreen(ashaId: _workerId(ref)),
        ),
        GoRoute(
          path: 'immunization',
          builder: (context, state) => ChildImmunizationCardScreen(
            memberId: state.uri.queryParameters['memberId'] ?? 'mem_aarav_02',
            childName: state.uri.queryParameters['name'] ?? 'Baby Aarav',
            dateOfBirth: DateTime.now().subtract(const Duration(days: 90)),
            ashaId: _workerId(ref),
          ),
        ),
        GoRoute(
          path: 'growth',
          builder: (context, state) => GrowthMonitoringScreen(
            memberId: state.uri.queryParameters['memberId'] ?? 'mem_aarav_02',
            childName: state.uri.queryParameters['name'] ?? 'Baby Aarav',
            dateOfBirth: DateTime.now().subtract(const Duration(days: 90)),
            sex: 'M',
            ashaId: _workerId(ref),
          ),
        ),
        GoRoute(
          path: 'tb-presumptive',
          builder: (context, state) => PresumptiveTbScreen(
            memberId:
                state.uri.queryParameters['memberId'] ?? 'mem_ramprasad_03',
            beneficiaryName:
                state.uri.queryParameters['name'] ?? 'Ramprasad Verma',
            ashaId: _workerId(ref),
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
              ashaId: _workerId(ref),
            ),
            ashaId: _workerId(ref),
          ),
        ),
        GoRoute(
          path: 'vhsnd',
          builder: (context, state) => VhsndSessionScreen(
            villageName: 'Rampur',
            hamlet: 'Ward 1 (Main Village)',
            anganwadiCenterName: 'Rampur Anganwadi Center 1',
            ashaId: _workerId(ref),
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
            workerId: _workerId(ref),
            language: ref.read(languageProvider).languageCode,
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
            workerId: _workerId(ref),
            workerName: 'Sunita Sharma (ASHA)',
          );
        }
        return const _FallbackContainer(title: 'Stock Management');
      },
    ),

    // ── Government Registers & PDF Reports ─────────────────────────────────
    GoRoute(
      path: '/reports',
      pageBuilder: (context, state) =>
          _buildSlidePage(state: state, child: const ReportsIncentivesScreen()),
    ),
    GoRoute(
      path: '/reports/registers',
      builder: (context, state) {
        if (ref != null) {
          return RegisterViewerScreen(
            db: ref.read(appDatabaseProvider),
            workerId: _workerId(ref),
            ashaName: 'Sunita Sharma',
            villageName: 'Rampur Gram Panchayat',
            initialRegister:
                state.uri.queryParameters['register'] == 'monthly_report'
                ? RegisterType.monthlyReport
                : RegisterType.rch,
            startInPdfMode: state.uri.queryParameters['view'] == 'pdf',
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
      builder: (context, state) => MeasurementCaptureScreen(
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
        workerId: _workerId(ref),
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
            checklistItems: const [
              'Booth setup at Anganwadi',
              'House-to-house B marking',
              'Zero-dose tracking',
            ],
            targetDescription: 'All children 0-5 years in Rampur village',
          ),
          CommunityCampaign(
            id: 'camp_02',
            campaignCode: 'tb_active_case',
            title: 'Active TB Case Finding Campaign',
            startDate: DateTime.now().subtract(const Duration(days: 10)),
            endDate: DateTime.now().add(const Duration(days: 20)),
            checklistItems: const [
              'Screen all elderly >60',
              'Sputum sample collection for cough >2 wks',
              'Nikshay entry',
            ],
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
    GoRoute(path: '/map-packs', redirect: (context, state) => '/packs'),
    GoRoute(
      path: '/india-map',
      pageBuilder: (context, state) =>
          _buildSlidePage(state: state, child: const IndiaMapPage()),
    ),

    GoRoute(
      path: '/geo-map',
      redirect: (context, state) {
        ref?.read(shellTabProvider.notifier).select(1);
        return '/home';
      },
    ),

    // ── Area Coverage Analysis ─────────────────────────────────────────────
    // NOTE: '/coverage' (line ~185) redirects to the DueListScreen coverage tab.
    // This standalone CoverageAnalysisScreen is registered under '/coverage-analysis'
    // to avoid the duplicate route conflict in go_router.
    GoRoute(
      path: '/coverage-analysis',
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
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/packs',
      pageBuilder: (context, state) =>
          _buildSlidePage(state: state, child: const PackManagerScreen()),
    ),
    GoRoute(path: '/af', builder: (context, state) => const DueListScreen()),

    // ── Reminders & Notifications ──────────────────────────────────────────
    GoRoute(
      path: '/reminders',
      pageBuilder: (context, state) =>
          _buildSlidePage(state: state, child: const RemindersScreen()),
    ),

    // ── Beneficiary Registry ───────────────────────────────────────────────
    // The registry feature re-exports the household screens. Route to the
    // household list so deep links to /registry land on a working screen.
    GoRoute(
      path: '/registry',
      redirect: (context, state) {
        final q = state.uri.queryParameters['q'];
        return q != null ? '/households?q=$q' : '/households';
      },
    ),

    // ── Sync Status Summary ────────────────────────────────────────────────
    GoRoute(
      path: '/sync-status',
      pageBuilder: (context, state) =>
          _buildSlidePage(state: state, child: const SyncStatusScreen()),
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
  // A PIN unlock is intentionally session-scoped. On every cold app start the
  // key is null, so the first protected navigation must return to /auth even
  // when a PIN already exists in secure storage.
  final databaseKey = ref.watch(databaseKeyProvider);

  return GoRouter(
    initialLocation: '/auth',
    redirect: (context, state) {
      final loc = state.uri.path;

      // Root redirect
      if (loc == '/') {
        return databaseKey == null ? '/auth' : '/home';
      }

      if (loc != '/auth' && databaseKey == null) {
        return '/auth';
      }

      if (loc == '/auth' && databaseKey != null) {
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
