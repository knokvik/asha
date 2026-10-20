import 'package:flutter/material.dart';

class AshaDockItem {
  final IconData icon;
  final String label;

  const AshaDockItem({
    required this.icon,
    required this.label,
  });
}

/// Fixed bottom navigation bar matching stitch_untitled_project:
/// Full-width pure white bar, subtle top line, and 4 items:
/// Home, Map, Tasks, Profile.
/// Active item: Soft mint circle (#EAF7EE) with vibrant dark green (#15803D) icon & label.
/// Inactive item: Soft grey (#9CA3AF) icon & label.
class AshaBottomDock extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final List<AshaDockItem> items;

  const AshaBottomDock({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFF3F4F6), width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (idx) {
              final item = items[idx];
              final isSelected = idx == currentIndex;
              const activeColor = Color(0xFF15803D);
              const inactiveColor = Color(0xFF9CA3AF);

              return Expanded(
                child: InkWell(
                  onTap: () => onTabSelected(idx),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFEAF7EE) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            item.icon,
                            size: isSelected ? 20 : 22,
                            color: isSelected ? activeColor : inactiveColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? activeColor : inactiveColor,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
