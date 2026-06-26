import 'package:flutter/material.dart';

/// Central color palette for Xstream.
///
/// Mirrors the web app's CSS variables (`--color-bg-base: #050505`,
/// accent `#E50914`, etc.) so the Android app feels like a native
/// continuation of the same brand.
class AppColors {
  AppColors._();

  // ── Core surfaces ──
  static const Color background = Color(0xFF050505);
  static const Color backgroundElevated = Color(0xFF111114);
  static const Color backgroundCard = Color(0xFF16161A);
  static const Color surfaceGlass = Color(0x8C0C0C10); // rgba(12,12,16,0.55)

  // ── Text ──
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA3A3A3);
  static const Color textMuted = Color(0xFF6B6B72);

  // ── Borders / dividers ──
  static const Color glassBorder = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const Color hairline = Color(0x1AFFFFFF);

  // ── Accent (overridable at runtime via Settings) ──
  /// Default Netflix-style red.
  static const Color accent = Color(0xFFE50914);
  static const Color accentSoft = Color(0x29E50914); // 16% opacity

  // ── Rating colors ──
  static const Color ratingHigh = Color(0xFF22C55E); // >= 8
  static const Color ratingMid = Color(0xFFEAB308); // 6 – 7.9
  static const Color ratingLow = Color(0xFFEF4444); // < 6

  // ── Misc brand accents used on row titles ──
  static const Color flame = Color(0xFFF97316);
  static const Color star = Color(0xFFEAB308);
  static const Color tv = Color(0xFF3B82F6);
  static const Color clapperboard = Color(0xFFEF4444);
  static const Color zap = Color(0xFFEAB308);
  static const Color calendar = Color(0xFF8B5CF6);
  static const Color sparkles = Color(0xFFF43F5E);
  static const Color clock = Color(0xFF22D3EE);
  static const Color crown = Color(0xFFF59E0B);
  static const Color listPlus = Color(0xFFEC4899);

  /// Preset accent swatches offered in Settings.
  static const List<AccentSwatch> accentSwatches = [
    AccentSwatch(name: 'Xstream Red', color: Color(0xFFE50914)),
    AccentSwatch(name: 'Royal Blue', color: Color(0xFF2563EB)),
    AccentSwatch(name: 'Emerald', color: Color(0xFF10B981)),
    AccentSwatch(name: 'Purple', color: Color(0xFF8B5CF6)),
    AccentSwatch(name: 'Amber', color: Color(0xFFF59E0B)),
    AccentSwatch(name: 'Rose', color: Color(0xFFF43F5E)),
    AccentSwatch(name: 'Cyan', color: Color(0xFF06B6D4)),
  ];

  /// Returns a rating color following the web app's rule:
  /// green >= 8, yellow >= 6, red otherwise.
  static Color ratingColor(double rating) {
    if (rating >= 8) return ratingHigh;
    if (rating >= 6) return ratingMid;
    return ratingLow;
  }
}

/// A named accent color preset.
class AccentSwatch {
  const AccentSwatch({required this.name, required this.color});
  final String name;
  final Color color;
}
