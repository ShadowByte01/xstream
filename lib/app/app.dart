import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../shared/providers/app_providers.dart';

/// Root widget for the Xstream app.
///
/// Rebuilds the theme whenever the user changes the accent colour in
/// Settings, and configures edge-to-edge system UI on every rebuild
/// (some Android versions reset it after route pops).
class XstreamApp extends ConsumerWidget {
  const XstreamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);
    final router = buildAppRouter();

    // Build a theme seeded with the user's accent colour.
    final theme = buildAppTheme().copyWith(
      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: accent,
        surface: AppColors.backgroundElevated,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        brightness: Brightness.dark,
      ),
    );

    return MaterialApp.router(
      title: 'Xstream',
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: router,
      builder: (context, child) {
        // Keep the system UI bars in sync across pushes/pops.
        SystemChrome.setSystemUiOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: AppColors.background,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
        );
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: AppColors.background,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
