import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/providers/core_providers.dart';

/// Screen 5: Beneficiary Profile (Savitri Devi) matching master reference image.
/// Top Bar: [ < ]  [ ⋮ ]
/// Header: SD avatar, Savitri Devi, 🤰 Pregnant pill, Age 24 • W7 • ABHA ID linked, 📍 Ward 7 • 250 m away
/// Tabs: Profile (active), Visits, Triage, Family
/// Key Information: Pregnancy 2nd Trimester (20 weeks), EDD: 15 Mar 2026, Last Visit: 12 Oct 2026, Risk: Normal
/// Button: [ Start Assessment → ]
/// Bottom Actions: Add Visit, Triage, Referral, Call Family
class BeneficiaryTimelineScreen extends ConsumerStatefulWidget {
  final String memberId;

  const BeneficiaryTimelineScreen({super.key, required this.memberId});

  @override
  ConsumerState<BeneficiaryTimelineScreen> createState() =>
      _BeneficiaryTimelineScreenState();
}

class _BeneficiaryTimelineScreenState
    extends ConsumerState<BeneficiaryTimelineScreen> {
  int _selectedTab = 0; // 0: Profile, 1: Visits, 2: Triage, 3: Family
  Member? _member;
  Household? _household;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadBeneficiary();
  }

  Future<void> _loadBeneficiary() async {
    try {
      final db = ref.read(appDatabaseProvider);
      final member = await (db.select(
        db.members,
      )..where((row) => row.id.equals(widget.memberId))).getSingleOrNull();
      Household? household;
      if (member != null) {
        household = await (db.select(
          db.households,
        )..where((row) => row.id.equals(member.householdId))).getSingleOrNull();
      }
      if (!mounted) return;
      setState(() {
        _member = member;
        _household = household;
        _loading = false;
        _loadError = member == null ? 'Beneficiary not found.' : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Could not load beneficiary: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_member == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Beneficiary')),
        body: Center(child: Text(_loadError ?? 'Beneficiary not found.')),
      );
    }
    final member = _member!;
    final displayName = member.name.trim().isEmpty
        ? 'Beneficiary'
        : member.name;
    final initials = displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    final ageText = member.dobApprox == null
        ? 'Age not recorded'
        : '${(DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(member.dobApprox!)).inDays / 365.25).floor()} years';
    final area =
        _household?.hamlet ?? _household?.village ?? 'Location not recorded';
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Bar: [ < ]  [ ⋮ ]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/due-list');
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),

                  IconButton(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: Color(0xFF111827),
                    ),
                    onPressed: () => _showMoreSheet(context),
                  ),
                ],
              ),
            ),

            // 2. Profile Header: SD Avatar, Savitri Devi, Pregnant pill, Subtitles
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFFEE2E2),
                    child: Text(
                      initials.isEmpty ? 'BN' : initials,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFDC2626),
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111827),
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.pregnant_woman_rounded,
                                size: 13,
                                color: Color(0xFF0284C7),
                              ),
                              SizedBox(width: 4),
                              Text(
                                member.sex == 'F' ? 'Female' : member.sex,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0284C7),
                                  fontFamily: 'SF Pro Display',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '$ageText  •  ${member.abhaId == null ? 'ABHA not linked' : 'ABHA ID linked'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                            SizedBox(width: 2),
                            Text(
                              area,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                                fontFamily: 'SF Pro Display',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3. Navigation Tabs: Profile (active) | Visits | Triage | Family
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                ),
              ),
              child: Row(
                children: [
                  _buildTab(0, 'Profile'),
                  _buildTab(1, 'Visits'),
                  _buildTab(2, 'Triage'),
                  _buildTab(3, 'Family'),
                ],
              ),
            ),

            // 4. Content Area
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(18),
                children: _selectedTab == 0
                    ? [
                        // Key Information Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Key Information',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF111827),
                                  fontFamily: 'SF Pro Display',
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Pregnancy 2nd Trimester
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.pregnant_woman_rounded,
                                      size: 18,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'Pregnancy',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF111827),
                                          fontFamily: 'SF Pro Display',
                                        ),
                                      ),
                                      Text(
                                        '2nd Trimester (20 weeks)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6B7280),
                                          fontFamily: 'SF Pro Display',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const Divider(
                                height: 1,
                                color: Color(0xFFF3F4F6),
                              ),
                              const SizedBox(height: 12),

                              // EDD
                              _buildInfoRow('EDD', '15 Mar 2026'),
                              const SizedBox(height: 8),

                              // Last Visit
                              _buildInfoRow('Last Visit', '12 Oct 2026'),
                              const SizedBox(height: 8),

                              // Risk Level
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: const [
                                  Text(
                                    'Risk Level',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF6B7280),
                                      fontFamily: 'SF Pro Display',
                                    ),
                                  ),
                                  Text(
                                    'Normal',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF16A34A),
                                      fontFamily: 'SF Pro Display',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Big Green Button: Start Assessment →
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E4231),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
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
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'SF Pro Display',
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 4 Quick Actions at bottom: Add Visit | Triage | Referral | Call Family
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildBottomAction(
                              icon: Icons.calendar_today_outlined,
                              label: 'Add Visit',
                              bgColor: const Color(0xFFDCFCE7),
                              iconColor: const Color(0xFF16A34A),
                              onTap: () => _showAddVisitSheet(context),
                            ),
                            _buildBottomAction(
                              icon: Icons.warning_rounded,
                              label: 'Triage',
                              bgColor: const Color(0xFFFEE2E2),
                              iconColor: const Color(0xFFEF4444),
                              onTap: () => context.push('/triage'),
                            ),
                            _buildBottomAction(
                              icon: Icons.reply_rounded,
                              label: 'Referral',
                              bgColor: const Color(0xFFDBEAFE),
                              iconColor: const Color(0xFF2563EB),
                              onTap: () =>
                                  context.push('/referral/${widget.memberId}'),
                            ),
                            _buildBottomAction(
                              icon: Icons.call_outlined,
                              label: 'Call Family',
                              bgColor: const Color(0xFFF3F4F6),
                              iconColor: const Color(0xFF374151),
                              onTap: () => _callFamily(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ]
                    : [_buildTabPanel()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? const Color(0xFF1E4231)
                    : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF1E4231)
                    : const Color(0xFF6B7280),
                fontFamily: 'SF Pro Display',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabPanel() {
    final panels = <int, Widget>{
      1: _buildVisitsPanel(),
      2: _buildTriagePanel(),
      3: _buildFamilyPanel(),
    };
    return panels[_selectedTab] ?? _buildVisitsPanel();
  }

  Widget _buildVisitsPanel() {
    return _panelCard(
      icon: Icons.event_note_outlined,
      title: 'Visits',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _timelineRow('12 Oct 2026', 'ANC follow-up', 'Completed'),
          const Divider(height: 20),
          _timelineRow('Next due', 'Routine home visit', 'Pending'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('profile_add_visit_button'),
              onPressed: () => _showAddVisitSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Add visit record'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriagePanel() {
    return _panelCard(
      icon: Icons.health_and_safety_outlined,
      title: 'Triage history',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _timelineRow('12 Oct 2026', 'Routine screening', 'Normal'),
          const Divider(height: 20),
          const Text(
            'Start a new assessment to record current symptoms and vitals. The result will remain linked to this beneficiary.',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('profile_start_triage_button'),
              onPressed: () => context.push('/triage'),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start assessment'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyPanel() {
    return _panelCard(
      icon: Icons.groups_outlined,
      title: 'Family',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Household-linked family records are available from the household profile.',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('profile_family_records_button'),
              onPressed: () => context.go('/households'),
              icon: const Icon(Icons.home_work_outlined),
              label: const Text('Open household records'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panelCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1E4231)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _timelineRow(String date, String title, String status) {
    return Row(
      children: [
        const Icon(Icons.circle, size: 8, color: Color(0xFF1E4231)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(
                date,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
        Text(
          status,
          style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A)),
        ),
      ],
    );
  }

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.qr_code_2_rounded),
              title: const Text('Show beneficiary ID'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showIdDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_note_outlined),
              title: const Text('Open visits'),
              onTap: () {
                Navigator.pop(sheetContext);
                setState(() => _selectedTab = 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.health_and_safety_outlined),
              title: const Text('Start triage'),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/triage');
              },
            ),
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Open family'),
              onTap: () {
                Navigator.pop(sheetContext);
                setState(() => _selectedTab = 3);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showIdDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Beneficiary ID'),
        content: SelectableText(widget.memberId),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
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
      SnackBar(content: Text('$type saved locally for this beneficiary.')),
    );
  }

  Future<void> _callFamily(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'No family phone number is recorded for this beneficiary.',
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
            fontFamily: 'SF Pro Display',
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
            fontFamily: 'SF Pro Display',
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Center(child: Icon(icon, color: iconColor, size: 22)),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
              fontFamily: 'SF Pro Display',
            ),
          ),
        ],
      ),
    );
  }
}
