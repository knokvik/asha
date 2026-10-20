import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/asha_bottom_nav.dart';

/// Screen 4: Today's Due List matching the master reference image.
/// Top Bar: [ < ]  Today's Due List  [ 📅 ]
/// Filter Pills: All (12), Overdue (3), Upcoming (5)
/// Detailed Beneficiary Due Cards (Savitri Devi, Meena Kumari, Rekha Sharma, Kamla Bai, Lata Devi)
/// Fixed 4-item bottom navigation dock (Tasks active).
class DueListScreen extends StatefulWidget {
  final int initialTab;

  const DueListScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<DueListScreen> createState() => _DueListScreenState();
}

class _DueListScreenState extends State<DueListScreen> {
  late int _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      bottomNavigationBar: const AshaBottomNav(index: 2),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top App Bar: [ < ]  Today's Due List  [ 📅 ]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
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

                  const Text(
                    "Today's Due List",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                      fontFamily: 'SF Pro Display',
                    ),
                  ),

                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Calendar View: October 2026 Monthly Roster active.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.calendar_today_outlined,
                        size: 20,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Filter Pills matching Screen 4: All (12) | Overdue (3) | Upcoming (5)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  _buildFilterPill(0, 'All (12)'),
                  const SizedBox(width: 8),
                  _buildFilterPill(1, 'Overdue (3)'),
                  const SizedBox(width: 8),
                  _buildFilterPill(2, 'Upcoming (5)'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 3. Due Task List Cards
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                children: [
                  // 1. Savitri Devi (Overdue - 10:00 AM)
                  if (_selectedFilter == 0 || _selectedFilter == 1) ...[
                    _buildDueCard(
                      avatarInitials: 'SD',
                      avatarBg: const Color(0xFFFEE2E2),
                      avatarColor: const Color(0xFFDC2626),
                      name: 'Savitri Devi',
                      subtitle: 'W7 • ANC Visit',
                      badgeText: 'Overdue',
                      badgeBg: const Color(0xFFFEE2E2),
                      badgeColor: const Color(0xFFEF4444),
                      timeText: '10:00 AM',
                      onTap: () => context.push('/beneficiary/sav-01'),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // 2. Meena Kumari (Today - 11:30 AM)
                  if (_selectedFilter == 0 || _selectedFilter == 2) ...[
                    _buildDueCard(
                      avatarInitials: 'MK',
                      avatarBg: const Color(0xFFDCFCE7),
                      avatarColor: const Color(0xFF16A34A),
                      name: 'Meena Kumari',
                      subtitle: 'W6 • Child Immunization',
                      badgeText: 'Today',
                      badgeBg: const Color(0xFFDCFCE7),
                      badgeColor: const Color(0xFF16A34A),
                      timeText: '11:30 AM',
                      onTap: () => context.push('/beneficiary/sav-01'),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // 3. Rekha Sharma (Today - 1:00 PM)
                  if (_selectedFilter == 0 || _selectedFilter == 2) ...[
                    _buildDueCard(
                      avatarInitials: 'RS',
                      avatarBg: const Color(0xFFDBEAFE),
                      avatarColor: const Color(0xFF2563EB),
                      name: 'Rekha Sharma',
                      subtitle: 'W7 • Follow-up',
                      badgeText: 'Today',
                      badgeBg: const Color(0xFFDCFCE7),
                      badgeColor: const Color(0xFF16A34A),
                      timeText: '1:00 PM',
                      onTap: () => context.push('/beneficiary/sav-01'),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // 4. Kamla Bai (Tomorrow)
                  if (_selectedFilter == 0 || _selectedFilter == 2) ...[
                    _buildDueCard(
                      avatarInitials: 'KB',
                      avatarBg: const Color(0xFFF3E8FF),
                      avatarColor: const Color(0xFF9333EA),
                      name: 'Kamla Bai',
                      subtitle: 'W8 • NCD Screening',
                      badgeText: 'Tomorrow',
                      badgeBg: const Color(0xFFF3F4F6),
                      badgeColor: const Color(0xFF6B7280),
                      timeText: null,
                      onTap: () => context.push('/beneficiary/sav-01'),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // 5. Lata Devi (Tomorrow)
                  if (_selectedFilter == 0 || _selectedFilter == 2) ...[
                    _buildDueCard(
                      avatarInitials: 'LD',
                      avatarBg: const Color(0xFFFFEDD5),
                      avatarColor: const Color(0xFFEA580C),
                      name: 'Lata Devi',
                      subtitle: 'W6 • PNC Visit',
                      badgeText: 'Tomorrow',
                      badgeBg: const Color(0xFFF3F4F6),
                      badgeColor: const Color(0xFF6B7280),
                      timeText: null,
                      onTap: () => context.push('/beneficiary/sav-01'),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(int index, String label) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E4231) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E4231) : const Color(0xFFE5E7EB),
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF4B5563),
            fontFamily: 'SF Pro Display',
          ),
        ),
      ),
    );
  }

  Widget _buildDueCard({
    required String avatarInitials,
    required Color avatarBg,
    required Color avatarColor,
    required String name,
    required String subtitle,
    required String badgeText,
    required Color badgeBg,
    required Color badgeColor,
    String? timeText,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: avatarBg,
                child: Text(
                  avatarInitials,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: avatarColor,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: const [
                        Icon(Icons.home_outlined, size: 13, color: Color(0xFF9CA3AF)),
                        SizedBox(width: 4),
                        Icon(Icons.person_outline_rounded, size: 13, color: Color(0xFF9CA3AF)),
                      ],
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: badgeColor,
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF9CA3AF),
                        size: 18,
                      ),
                    ],
                  ),
                  if (timeText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      timeText,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
