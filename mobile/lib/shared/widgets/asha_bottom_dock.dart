import 'package:flutter/material.dart';

class AshaDockItem {
  final IconData icon;
  final String label;
  final bool isAction;

  const AshaDockItem({
    required this.icon,
    required this.label,
    this.isAction = false,
  });
}

/// Shared fixed navigation bar for Home, Map, Triage, Tasks, and Profile.
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
      minimum: EdgeInsets.zero,
      child: Material(
        color: Colors.white,
        elevation: 4,
        shadowColor: const Color(0x22000000),
        child: Container(
          decoration: BoxDecoration(
            border: const Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(items.length, (idx) {
                  final item = items[idx];
                  final isSelected = idx == currentIndex;
                  const activeColor = Color(0xFF1E4231);
                  const inactiveColor = Color(0xFF6B7280);
                  final actionColor = const Color(0xFFDC2626);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
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
                              width: item.isAction
                                  ? 38
                                  : (isSelected ? 42 : 38),
                              height: item.isAction ? 38 : 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: item.isAction
                                    ? actionColor
                                    : isSelected
                                    ? activeColor
                                    : Colors.transparent,
                                shape: item.isAction
                                    ? BoxShape.circle
                                    : BoxShape.rectangle,
                                borderRadius: item.isAction
                                    ? null
                                    : BorderRadius.circular(10),
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
                                  size: item.isAction
                                      ? 22
                                      : (isSelected ? 20 : 22),
                                  color: item.isAction || isSelected
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
