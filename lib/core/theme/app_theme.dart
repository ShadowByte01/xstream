import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography scale. Uses Inter (via google_fonts) as the primary font
/// and BebasNeue for display headings — matching the web app.
class AppTextStyles {
  AppTextStyles._();

  static const String displayFontFamily = 'Bebas Neue';

  static TextStyle get display => GoogleFonts.bebasNeue(
        fontSize: 34,
        height: 1.0,
        letterSpacing: 0.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get h1 => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        height: 1.15,
        color: AppColors.textPrimary,
      );

  static TextStyle get h2 => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        height: 1.2,
        color: AppColors.textPrimary,
      );

  static TextStyle get h3 => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodyPrimary => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppColors.textSecondary,
      );

  static TextStyle get button => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );
}

/// Builds the [ThemeData] for the whole app.
///
/// Everything is dark-first; there is no light theme by design — the
/// cinematic black aesthetic is core to the Xstream brand.
ThemeData buildAppTheme() {
  final base = ThemeData.dark(
    useMaterial3: true,
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.accent,
      surface: AppColors.backgroundElevated,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      brightness: Brightness.dark,
    ),
    textTheme: TextTheme(
      displayLarge: AppTextStyles.display,
      headlineLarge: AppTextStyles.h1,
      headlineMedium: AppTextStyles.h2,
      headlineSmall: AppTextStyles.h3,
      bodyLarge: AppTextStyles.bodyPrimary,
      bodyMedium: AppTextStyles.body,
      labelLarge: AppTextStyles.button,
      labelSmall: AppTextStyles.label,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    iconTheme: const IconThemeData(color: AppColors.textPrimary),
    dividerColor: AppColors.hairline,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    useMaterial3: true,
  );
}

/// Configures the system UI (status bar + nav bar) to be transparent
/// over the black background with light icons.
void configureSystemUi() {
  SystemChrome.setSystemUiOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: SystemUiOverlay.values,
  );
}
