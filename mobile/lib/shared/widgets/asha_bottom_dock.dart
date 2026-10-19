import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

class AshaDockItem {
  final IconData icon;
  final String label;
  final String route;

  const AshaDockItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}

/// Floating bottom navigation pill dock inspired by Zevoa's modern super-app layout.
/// Features a dark carbon pill (`#121A15`, radius 28dp, height 64dp) with active white pill indicator.
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
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      height: 64,
      decoration: BoxDecoration(
        color: AshaColors.carbonBlack,
        borderRadius: AshaShapes.dockBorderRadius,
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(18, 26, 21, 0.22),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (idx) {
          final item = items[idx];
          final isSelected = idx == currentIndex;

          return GestureDetector(
            onTap: () => onTabSelected(idx),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 16 : 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    size: 20,
                    color: isSelected ? AshaColors.carbonBlack : Colors.white70,
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AshaColors.carbonBlack,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
