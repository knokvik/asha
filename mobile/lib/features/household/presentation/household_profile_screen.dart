import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';

/// Screen 4: Household Profile matching the exact Asha Platform mobile design.
class HouseholdProfileScreen extends StatefulWidget {
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
  State<HouseholdProfileScreen> createState() => _HouseholdProfileScreenState();
}

class _HouseholdProfileScreenState extends State<HouseholdProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
                    onTap: () => context.push('/referral/unregistered_patient'),
                  ),
                  _buildBottomAction(
                    icon: Icons.phone_outlined,
                    label: 'Call Family',
                    color: AshaColors.vitalNormal,
                    onTap: () => _callFamily(context),
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
            _buildTimelineRow(widget.lastVisit, 'ANC follow-up', 'Completed'),
            const Divider(height: 20),
            _buildTimelineRow('Next due', 'Routine home visit', 'Pending'),
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
            _buildTimelineRow(
              widget.lastVisit,
              'Routine screening',
              widget.riskLevel,
            ),
            const Divider(height: 20),
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
            const Text(
              'Open the household register to view and update linked family members.',
              style: TextStyle(fontSize: 13, color: AshaColors.textSecondary),
            ),
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
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            const ListTile(
              title: Text('Add visit record'),
              subtitle: Text('Choose the visit type to save locally.'),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home visit'),
              onTap: () => _saveVisit(sheetContext, 'Home visit'),
            ),
            ListTile(
              leading: const Icon(Icons.medical_services_outlined),
              title: const Text('ANC follow-up'),
              onTap: () => _saveVisit(sheetContext, 'ANC follow-up'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveVisit(BuildContext sheetContext, String type) {
    Navigator.pop(sheetContext);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$type saved locally for ${widget.name}.')),
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

  void _callFamily(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No family phone number is recorded for this profile.'),
      ),
    );
  }
}
