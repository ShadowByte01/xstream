/// App-wide constant values.
class AppConstants {
  AppConstants._();

  static const String appName = 'Xstream';
  static const String appTagline = 'Movies. Series. Endless Entertainment.';
  static const String appVersion = '1.0.0';
  static const String appBuild = '1';

  /// Base URL of the Xstream backend proxy (deployed on Render).
  ///
  /// Set this to your Render URL after deploying the `backend/` folder.
  /// While developing locally you can point it at `http://10.0.2.2:8080`
  /// (Android emulator's alias for the host machine's localhost).
  ///
  /// The backend proxies TMDB + Groq so API keys never ship inside the APK.
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://xstream-api.onrender.com',
  );

  /// TMDB image CDN base.
  static const String tmdbImageBase = 'https://image.tmdb.org/t/p';

  /// YouTube thumbnail base (used in the Details trailers grid).
  static const String ytThumbBase = 'https://img.youtube.com/vi';

  /// Storage box / key prefixes — kept identical to the web app's `xs_`
  /// namespace so the behaviour is familiar.
  static const String storagePrefix = 'xs_';

  /// How many history entries to retain (matches the web app's cap).
  static const int maxHistory = 60;
}
