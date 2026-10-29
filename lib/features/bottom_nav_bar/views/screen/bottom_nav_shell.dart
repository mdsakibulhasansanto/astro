import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/chart_palette.dart';

/// App shell with a floating night-sky navigation bar. Each tab keeps its own
/// navigation stack; tapping the current tab returns it to its first page.
class BottomNavShell extends StatelessWidget {
  const BottomNavShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    (icon: Icons.home_outlined, active: Icons.home_rounded, label: 'Home'),
    (icon: Icons.auto_awesome_outlined, active: Icons.auto_awesome, label: 'Astrology'),
    (icon: Icons.grid_view_outlined, active: Icons.grid_view_rounded, label: 'Planner'),
    (icon: Icons.menu_book_outlined, active: Icons.menu_book_rounded, label: 'Reading'),
    (icon: Icons.person_outline_rounded, active: Icons.person_rounded, label: 'Profile'),
  ];

  void _select(int i) {
    if (i != navigationShell.currentIndex) HapticFeedback.selectionClick();
    navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    // Space taken by the system gesture bar or button bar. viewPadding is not
    // affected by the keyboard, so the bar never jumps while typing.
    final view = MediaQuery.viewPaddingOf(context);
    // Large system text would not fit the fixed bar height; cap it here only.
    final textScaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.15);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: Padding(
          // Always leave a gap above the gesture bar, plus side insets in
          // landscape.
          padding: EdgeInsets.fromLTRB(12 + view.left, 6, 12 + view.right, view.bottom + 10),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF222D52), ChartPalette.skyEdge],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0A0F1C).withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _NavItem(
                      icon: _tabs[i].icon,
                      activeIcon: _tabs[i].active,
                      label: _tabs[i].label,
                      selected: i == navigationShell.currentIndex,
                      onTap: () => _select(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _duration = Duration(milliseconds: 260);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 34,
        highlightColor: Colors.transparent,
        splashColor: ChartPalette.gold.withValues(alpha: 0.12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: _duration,
              curve: Curves.easeOutCubic,
              width: selected ? 50 : 40,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: selected
                    ? const LinearGradient(colors: [Color(0xFFFFD873), Color(0xFFF0A93B)])
                    : null,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: ChartPalette.gold.withValues(alpha: 0.45),
                          blurRadius: 14,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: AnimatedSwitcher(
                duration: _duration,
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: Icon(
                  selected ? activeIcon : icon,
                  key: ValueKey(selected),
                  size: 21,
                  color: selected ? const Color(0xFF1B2232) : Colors.white.withValues(alpha: 0.62),
                ),
              ),
            ),
            const SizedBox(height: 5),
            AnimatedDefaultTextStyle(
              duration: _duration,
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 0.2,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? ChartPalette.gold : Colors.white.withValues(alpha: 0.55),
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.fade, softWrap: false),
            ),
          ],
        ),
      ),
    );
  }
}
