import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';
import '../data/services/storage_service.dart';

/// One-time startup work that must complete before the first frame.
Future<void> bootstrap() async {
  // Configure edge-to-edge + transparent system bars (no white flash).
  configureSystemUi();
  // Lock to portrait for a phone-first cinematic experience.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  // Initialise local storage (history, watchlist, prefs…).
  await StorageService.init();
}
