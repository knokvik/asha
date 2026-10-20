import 'package:flutter/material.dart';

class AshaDockItem {
  final IconData icon;
  final String label;

  const AshaDockItem({required this.icon, required this.label});
}

/// Floating icon-only navigation dock for Home, Map, Tasks, and Profile.
/// The selected item uses a compact rectangular ASHA forest-green treatment.
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
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Material(
        color: const Color(0xFFFCFDFC),
        elevation: 12,
        shadowColor: const Color(0x22000000),
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: SizedBox(
              height: 56,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(items.length, (idx) {
                  final item = items[idx];
                  final isSelected = idx == currentIndex;
                  const activeColor = Color(0xFF1E4231);
                  const inactiveColor = Color(0xFF6B7280);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Semantics(
                        label: item.label,
                        button: true,
                        selected: isSelected,
                        child: InkWell(
                          onTap: () => onTabSelected(idx),
                          borderRadius: BorderRadius.circular(12),
                          splashColor: const Color(0x14000000),
                          highlightColor: Colors.transparent,
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              width: isSelected ? 50 : 42,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? activeColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                transitionBuilder: (child, animation) =>
                                    ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    ),
                                child: Icon(
                                  item.icon,
                                  key: ValueKey('${item.icon}_$isSelected'),
                                  size: isSelected ? 21 : 23,
                                  color: isSelected
                                      ? Colors.white
                                      : inactiveColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
