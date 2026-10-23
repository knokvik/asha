import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/core_providers.dart';
import 'schedule_visit_sheet.dart';

/// Screen 4: Household Profile matching the exact Asha Platform mobile design.
class HouseholdProfileScreen extends ConsumerStatefulWidget {
  const HouseholdProfileScreen({
    super.key,
    this.name = 'Savitri Devi',
    this.initials = 'SD',
    this.age = 24,
    this.ward = 'W7',
    this.distance = '250 m away',
    this.condition = 'Pregnancy',
    this.stage = '2nd Trimester (20 weeks)',
    this.edd = '15 Mar 2026',
    this.lastVisit = '12 Oct 2026',
    this.riskLevel = 'Normal',
  });

  final String name;
  final String initials;
  final int age;
  final String ward;
  final String distance;
  final String condition;
  final String stage;
  final String edd;
  final String lastVisit;
  final String riskLevel;

  @override
  ConsumerState<HouseholdProfileScreen> createState() =>
      _HouseholdProfileScreenState();
}

class _HouseholdProfileScreenState extends ConsumerState<HouseholdProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  List<VisitSchedule> _scheduledVisits = [];
  List<ClinicalEncounter> _encounters = [];
  List<TriageResult> _triageResults = [];
  List<Member> _householdMembers = [];
  String? _memberId;
  String? _contactPhone;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadLiveRecords();
  }

  Future<void> _loadLiveRecords() async {
    try {
      final db = ref.read(appDatabaseProvider);
      final members = await db.select(db.members).get();
      if (members.isNotEmpty) {
        final member = members.firstWhere(
          (m) => m.name.toLowerCase() == widget.name.toLowerCase(),
          orElse: () => members.first,
        );
        _memberId = member.id;
        _contactPhone = member.phone;

        final visits = await (db.select(db.visitSchedules)
          ..where((v) => v.memberId.equals(member.id))
          ..orderBy([(t) => OrderingTerm.desc(t.dueDate)])).get();

        final encounters = await (db.select(db.clinicalEncounters)
          ..where((e) => e.memberId.equals(member.id))
          ..orderBy([(t) => OrderingTerm.desc(t.encounterDate)])).get();

        final triages = await (db.select(db.triageResults)
          ..orderBy([(t) => OrderingTerm.desc(t.evaluatedAt)])
          ..limit(10)).get();

        final family = await (db.select(db.members)
          ..where((m) => m.householdId.equals(member.householdId))).get();

        if (mounted) {
          setState(() {
            _scheduledVisits = visits;
            _encounters = encounters;
            _triageResults = triages;
            _householdMembers = family;
          });
        }
      }
    } catch (_) {}
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: AshaColors.textPrimary,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/due-list');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AshaColors.textPrimary,
            ),
            onPressed: () => _showMoreSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Profile Header: Avatar, Name, Metadata
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: const Color(0xFFFFE4E6),
                          child: Text(
                            widget.initials,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFE11D48),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AshaColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Age ${widget.age}  •  ${widget.ward}  •  ',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AshaColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 12,
                                    color: Color(0xFF2563EB),
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'ABHA ID linked',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: AshaColors.textMuted,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Ward 7  •  ${widget.distance}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AshaColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tab Bar: Profile, Visits, Triage, Family
                  TabBar(
                    controller: _tabController,
                    labelColor: AshaColors.primary,
                    unselectedLabelColor: AshaColors.textMuted,
                    indicatorColor: AshaColors.primary,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    onTap: (index) => setState(() => _selectedTab = index),
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    tabs: const [
                      Tab(text: 'Profile'),
                      Tab(text: 'Visits'),
                      Tab(text: 'Triage'),
                      Tab(text: 'Family'),
                    ],
                  ),

                  const SizedBox(height: 20),

                  if (_selectedTab != 0) _buildSecondaryPanel(),

                  // Key Information Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AshaColors.cardSurface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AshaColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Key Information',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AshaColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Condition: Pregnancy, 2nd Trimester
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1F2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.favorite_rounded,
                                color: Color(0xFFE11D48),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      widget.condition,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AshaColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Pregnant',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFDC2626),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.stage,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AshaColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(
                            color: AshaColors.borderSubtle,
                            height: 1,
                          ),
                        ),

                        // Detail Rows: EDD, Last Visit, Risk Level
                        _buildDetailRow('EDD', widget.edd),
                        const SizedBox(height: 10),
                        _buildDetailRow('Last Visit', widget.lastVisit),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Risk Level',
                              style: TextStyle(
                                fontSize: 13,
                                color: AshaColors.textSecondary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.riskLevel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Start Assessment Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AshaColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      onPressed: () => context.push('/triage'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Start Assessment',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Bottom Action Strip: Add Visit | Triage | Referral | Call Family
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AshaColors.borderSubtle)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBottomAction(
                    icon: Icons.calendar_today_outlined,
                    label: 'Add Visit',
                    color: AshaColors.textPrimary,
                    onTap: () => _showAddVisitSheet(context),
                  ),
                  _buildBottomAction(
                    icon: Icons.warning_amber_rounded,
                    label: 'Triage',
                    color: AshaColors.alertHighRisk,
                    onTap: () => context.push('/triage'),
                  ),
                  _buildBottomAction(
                    icon: Icons.shortcut_rounded,
                    label: 'Referral',
                    color: AshaColors.teleConsultBlue,
                    onTap: () => context.push('/referral/${_memberId ?? "unregistered_patient"}'),
                  ),
                  _buildBottomAction(
                    icon: Icons.phone_outlined,
                    label: 'Call Family',
                    color: AshaColors.vitalNormal,
                    onTap: _callFamily,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryPanel() {
    final panels = <int, Widget>{
      1: _buildPanel(
        icon: Icons.event_note_outlined,
        title: 'Visits',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_scheduledVisits.isEmpty && _encounters.isEmpty) ...[
              _buildTimelineRow(widget.lastVisit, 'ANC follow-up', 'Completed'),
              const Divider(height: 20),
              _buildTimelineRow('Next due', 'Routine home visit', 'Pending'),
            ] else ...[
              for (final v in _scheduledVisits) ...[
                _buildTimelineRow(
                  _formatDate(DateTime.fromMillisecondsSinceEpoch(v.dueDate)),
                  v.visitType,
                  v.status.toUpperCase(),
                ),
                const Divider(height: 20),
              ],
              for (final e in _encounters) ...[
                _buildTimelineRow(
                  _formatDate(DateTime.fromMillisecondsSinceEpoch(e.encounterDate)),
                  e.encounterType.replaceAll('_', ' '),
                  e.status.toUpperCase(),
                ),
                const Divider(height: 20),
              ],
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('household_profile_add_visit_button'),
                onPressed: () => _showAddVisitSheet(context),
                icon: const Icon(Icons.add),
                label: const Text('Add visit record'),
              ),
            ),
          ],
        ),
      ),
      2: _buildPanel(
        icon: Icons.health_and_safety_outlined,
        title: 'Triage history',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_triageResults.isEmpty) ...[
              _buildTimelineRow(
                widget.lastVisit,
                'Routine screening',
                widget.riskLevel,
              ),
            ] else ...[
              for (final t in _triageResults.take(4)) ...[
                _buildTimelineRow(
                  _formatDate(DateTime.fromMillisecondsSinceEpoch(t.evaluatedAt)),
                  'Clinical Assessment · Rule ${t.ruleVersionId}',
                  t.flag.toUpperCase(),
                ),
                const Divider(height: 20),
              ],
            ],
            const SizedBox(height: 8),
            const Text(
              'Start an assessment to record current symptoms and vitals for this person.',
              style: TextStyle(fontSize: 13, color: AshaColors.textSecondary),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: const Key('household_profile_start_triage_button'),
                onPressed: () => context.push('/triage'),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start assessment'),
              ),
            ),
          ],
        ),
      ),
      3: _buildPanel(
        icon: Icons.groups_outlined,
        title: 'Family',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_householdMembers.isEmpty) ...[
              const Text(
                'Open the household register to view and update linked family members.',
                style: TextStyle(fontSize: 13, color: AshaColors.textSecondary),
              ),
            ] else ...[
              for (final m in _householdMembers) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE8F5E9),
                    child: Text(
                      m.name.isNotEmpty ? m.name[0] : 'M',
                      style: const TextStyle(
                        color: Color(0xFF1E4231),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    m.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    '${m.sex == "F" ? "Female" : "Male"} · ${m.lifecycleStatus}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => context.push('/beneficiary/${m.id}'),
                ),
                const Divider(height: 1),
              ],
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('household_profile_family_button'),
                onPressed: () => context.go('/households'),
                icon: const Icon(Icons.home_work_outlined),
                label: const Text('Open household records'),
              ),
            ),
          ],
        ),
      ),
    };
    return panels[_selectedTab] ?? const SizedBox.shrink();
  }

  Widget _buildPanel({
    required IconData icon,
    required String title,
    required Widget body,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: AshaColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AshaColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AshaColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AshaColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          body,
        ],
      ),
    );
  }

  Widget _buildTimelineRow(String date, String title, String status) {
    return Row(
      children: [
        const Icon(Icons.circle, size: 8, color: AshaColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 12,
                  color: AshaColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          status,
          style: const TextStyle(fontSize: 12, color: AshaColors.vitalNormal),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AshaColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AshaColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.qr_code_rounded),
                title: const Text('View ABHA Health ID QR Card'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showIdDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.event_note_outlined),
                title: const Text('Open visits'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _selectedTab = 1);
                },
              ),
              ListTile(
                leading: const Icon(Icons.health_and_safety_outlined),
                title: const Text('Start triage'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/triage');
                },
              ),
              ListTile(
                leading: const Icon(Icons.groups_outlined),
                title: const Text('Open family'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _selectedTab = 3);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddVisitSheet(BuildContext context) {
    ScheduleVisitBottomSheet.show(
      context,
      beneficiaryName: widget.name,
      memberId: _memberId ?? 'mem_savitri',
      onSaved: () {
        _loadLiveRecords();
      },
    );
  }

  void _showIdDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ABHA Health ID'),
        content: Text('${widget.name}\nABHA ID is linked to this profile.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _callFamily() async {
    final phone = _contactPhone ?? '+91 98765 12340';
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling family phone $phone...')),
    );
  }
}
