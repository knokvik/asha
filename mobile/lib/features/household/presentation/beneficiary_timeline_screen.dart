import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Screen 5: Beneficiary Profile (Savitri Devi) matching master reference image.
/// Top Bar: [ < ]  [ ⋮ ]
/// Header: SD avatar, Savitri Devi, 🤰 Pregnant pill, Age 24 • W7 • ABHA ID linked, 📍 Ward 7 • 250 m away
/// Tabs: Profile (active), Visits, Triage, Family
/// Key Information: Pregnancy 2nd Trimester (20 weeks), EDD: 15 Mar 2026, Last Visit: 12 Oct 2026, Risk: Normal
/// Button: [ Start Assessment → ]
/// Bottom Actions: Add Visit, Triage, Referral, Call Family
class BeneficiaryTimelineScreen extends StatefulWidget {
  final String memberId;

  const BeneficiaryTimelineScreen({
    super.key,
    required this.memberId,
  });

  @override
  State<BeneficiaryTimelineScreen> createState() => _BeneficiaryTimelineScreenState();
}

class _BeneficiaryTimelineScreenState extends State<BeneficiaryTimelineScreen> {
  int _selectedTab = 0; // 0: Profile, 1: Visits, 2: Triage, 3: Family

  @override
  Widget build(BuildContext context) {
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
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Options: Edit Record • Generate ABHA • Transfer Household'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
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
                    child: const Text(
                      'SD',
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
                          'Savitri Devi',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111827),
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.pregnant_woman_rounded, size: 13, color: Color(0xFF0284C7)),
                              SizedBox(width: 4),
                              Text(
                                'Pregnant',
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
                        const Text(
                          'Age 24  •  W7  •  ABHA ID linked',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: const [
                            Icon(Icons.location_on_rounded, size: 12, color: Color(0xFF9CA3AF)),
                            SizedBox(width: 2),
                            Text(
                              'Ward 7 • 250 m away',
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
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
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
                children: [
                  // Key Information Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        const SizedBox(height: 12),

                        // EDD
                        _buildInfoRow('EDD', '15 Mar 2026'),
                        const SizedBox(height: 8),

                        // Last Visit
                        _buildInfoRow('Last Visit', '12 Oct 2026'),
                        const SizedBox(height: 8),

                        // Risk Level
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Scheduled ANC follow-up visit.')),
                          );
                        },
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
                        onTap: () => context.push('/referral/new'),
                      ),
                      _buildBottomAction(
                        icon: Icons.call_outlined,
                        label: 'Call Family',
                        bgColor: const Color(0xFFF3F4F6),
                        iconColor: const Color(0xFF374151),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Dialing Asha Beneficiary Family: +91 98231 00000')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
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
                color: isSelected ? const Color(0xFF1E4231) : Colors.transparent,
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
                color: isSelected ? const Color(0xFF1E4231) : const Color(0xFF6B7280),
                fontFamily: 'SF Pro Display',
              ),
            ),
          ),
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
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, color: iconColor, size: 22),
            ),
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
