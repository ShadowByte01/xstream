import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// The persistent shell that wraps every tabbed page (Home, Movies,
/// Series, Search, Profile) and renders the bottom navigation bar.
///
/// The bottom bar is a floating, glass-morphic pill — matching the
/// premium aesthetic of the web app's `MobileNav` but elevated for
/// Android with a center FAB-style search.
class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    _Tab(route: '/', icon: Icons.home_rounded, label: 'Home'),
    _Tab(route: '/movies', icon: Icons.movie_rounded, label: 'Movies'),
    _Tab(route: '/search', icon: Icons.search_rounded, label: 'Search'),
    _Tab(route: '/profile', icon: Icons.person_rounded, label: 'You'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final idx = _tabs.indexWhere((t) =>
        t.route == '/' ? location == '/' : location.startsWith(t.route));
    return idx == -1 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: true,
        bottom: false,
        child: child,
      ),
      extendBody: true,
      bottomNavigationBar: const _BottomNav(),
    );
  }
}

class _Tab {
  const _Tab({required this.route, required this.icon, required this.label});
  final String route;
  final IconData icon;
  final String label;
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final idx = AppScaffold._tabs.indexWhere((t) =>
        t.route == '/' ? location == '/' : location.startsWith(t.route));
    final current = idx == -1 ? 0 : idx;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xD9121216),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.glassBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(AppScaffold._tabs.length, (i) {
          final tab = AppScaffold._tabs[i];
          final active = i == current;
          return _NavItem(
            icon: tab.icon,
            label: tab.label,
            active: active,
            onTap: () {
              if (i == current) return;
              context.go(tab.route);
            },
          );
        }),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: active ? 18 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: active ? accent.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: active ? accent : AppColors.textMuted,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: active
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        label,
                        style: AppTextStyles.button.copyWith(
                          color: accent,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
