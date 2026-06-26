import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../models/media_item.dart';

/// Privacy-first local persistence layer.
///
/// A faithful port of the web app's `lib/storage.js` — there is **no
/// backend account**. Everything (history, watchlist, likes, ratings,
/// view counts, accent colour, autoplay pref) lives on-device in
/// [SharedPreferences], gated behind a cookie-consent equivalent.
///
/// Changes notify listeners via the [notify] callback so Riverpod
/// providers can rebuild reactively.
class StorageService {
  StorageService._(this._prefs);
  static StorageService? _instance;

  static Future<StorageService> init() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    _instance = StorageService._(prefs);
    return _instance!;
  }

  static StorageService get I {
    assert(_instance != null, 'Call StorageService.init() first');
    return _instance!;
  }

  final SharedPreferences _prefs;

  /// Reactive listeners (Riverpod subscribes to these).
  final Set<VoidCallback> _listeners = {};
  void addListener(VoidCallback cb) => _listeners.add(cb);
  void removeListener(VoidCallback cb) => _listeners.remove(cb);
  void _notify() {
    for (final cb in List.of(_listeners)) {
      cb();
    }
  }

  // ────────────────────────── Consent ──────────────────────────

  static const _kConsent = '${AppConstants.storagePrefix}consent';

  /// Returns `'accepted'`, `'declined'` or `null` (no choice yet).
  String? get consent => _prefs.getString(_kConsent);
  DateTime? get consentDate =>
      _prefs.containsKey('${_kConsent}_at')
          ? DateTime.fromMillisecondsSinceEpoch(
              _prefs.getInt('${_kConsent}_at') ?? 0)
          : null;

  bool get isPersonalizationAllowed => consent == 'accepted';

  Future<void> acceptConsent() async {
    await _prefs.setString(_kConsent, 'accepted');
    await _prefs.setInt('${_kConsent}_at', DateTime.now().millisecondsSinceEpoch);
    _notify();
  }

  Future<void> declineConsent() async {
    await _prefs.setString(_kConsent, 'declined');
    await _prefs.setInt('${_kConsent}_at', DateTime.now().millisecondsSinceEpoch);
    await wipeAllPersonalData();
  }

  // ────────────────────────── History ──────────────────────────

  List<HistoryEntry> getHistory() {
    final raw = _prefs.getString('${AppConstants.storagePrefix}history');
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> addToHistory(HistoryEntry entry) async {
    if (!isPersonalizationAllowed) return;
    final list = getHistory()
        .where((h) => !(h.id == entry.id && h.mediaType == entry.mediaType))
        .toList();
    list.insert(0, entry);
    await _prefs.setString(
      '${AppConstants.storagePrefix}history',
      jsonEncode(list.take(AppConstants.maxHistory).toList()),
    );
    _notify();
  }

  Future<void> updateHistoryProgress(
    int id,
    String mediaType,
    int progress, [
    int? season,
    int? episode,
  ]) async {
    if (!isPersonalizationAllowed) return;
    final list = getHistory().map((h) {
      if (h.id == id && h.mediaType == mediaType) {
        return h.copyWith(
          progress: progress,
          season: season ?? h.season,
          episode: episode ?? h.episode,
          watchedAt: DateTime.now().toIso8601String(),
        );
      }
      return h;
    }).toList();
    await _prefs.setString(
      '${AppConstants.storagePrefix}history',
      jsonEncode(list),
    );
    _notify();
  }

  Future<void> removeFromHistory(int id, String mediaType) async {
    final list = getHistory()
        .where((h) => !(h.id == id && h.mediaType == mediaType))
        .toList();
    await _prefs.setString(
      '${AppConstants.storagePrefix}history',
      jsonEncode(list),
    );
    _notify();
  }

  Future<void> clearHistory() async {
    await _prefs.remove('${AppConstants.storagePrefix}history');
    _notify();
  }

  // ────────────────────────── Watchlist ──────────────────────────

  List<MediaItem> getWatchlist() {
    final raw = _prefs.getString('${AppConstants.storagePrefix}watchlist');
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => _mediaFromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return const [];
    }
  }

  bool isInWatchlist(int id, String mediaType) =>
      getWatchlist().any((m) => m.id == id && m.mediaType == mediaType);

  Future<bool> toggleWatchlist(MediaItem item) async {
    final list = getWatchlist();
    final exists = list.any((m) => m.id == item.id && m.mediaType == item.mediaType);
    final next = exists
        ? list.where((m) => !(m.id == item.id && m.mediaType == item.mediaType)).toList()
        : [item, ...list];
    if (isPersonalizationAllowed) {
      await _prefs.setString(
        '${AppConstants.storagePrefix}watchlist',
        jsonEncode(next.map(_mediaToJson).toList()),
      );
      _notify();
    }
    return !exists;
  }

  // ────────────────────────── Likes ──────────────────────────

  List<MediaItem> getLikes() {
    final raw = _prefs.getString('${AppConstants.storagePrefix}likes');
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => _mediaFromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return const [];
    }
  }

  bool isLiked(int id, String mediaType) =>
      getLikes().any((m) => m.id == id && m.mediaType == mediaType);

  Future<bool> toggleLike(MediaItem item) async {
    final list = getLikes();
    final exists = list.any((m) => m.id == item.id && m.mediaType == item.mediaType);
    final next = exists
        ? list.where((m) => !(m.id == item.id && m.mediaType == item.mediaType)).toList()
        : [item, ...list];
    if (isPersonalizationAllowed) {
      await _prefs.setString(
        '${AppConstants.storagePrefix}likes',
        jsonEncode(next.map(_mediaToJson).toList()),
      );
      _notify();
    }
    return !exists;
  }

  // ────────────────────────── Ratings ──────────────────────────

  Map<String, int> getRatings() {
    final raw = _prefs.getString('${AppConstants.storagePrefix}ratings');
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as Map).map(
        (k, v) => MapEntry(k.toString(), (v as num).toInt()),
      );
    } catch (_) {
      return {};
    }
  }

  int getRating(int id, String mediaType) =>
      getRatings()['$mediaType-$id'] ?? 0;

  Future<void> setRating(int id, String mediaType, int value) async {
    if (!isPersonalizationAllowed) return;
    final ratings = getRatings();
    if (value <= 0) {
      ratings.remove('$mediaType-$id');
    } else {
      ratings['$mediaType-$id'] = value;
    }
    await _prefs.setString(
      '${AppConstants.storagePrefix}ratings',
      jsonEncode(ratings),
    );
    _notify();
  }

  // ────────────────────────── View counts ──────────────────────────

  Map<String, int> getViewCounts() {
    final raw = _prefs.getString('${AppConstants.storagePrefix}views');
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as Map).map(
        (k, v) => MapEntry(k.toString(), (v as num).toInt()),
      );
    } catch (_) {
      return {};
    }
  }

  Future<int> registerView(int id, String mediaType) async {
    if (!isPersonalizationAllowed) return 0;
    final counts = getViewCounts();
    final key = '$mediaType-$id';
    counts[key] = (counts[key] ?? 0) + 1;
    await _prefs.setString(
      '${AppConstants.storagePrefix}views',
      jsonEncode(counts),
    );
    _notify();
    return counts[key]!;
  }

  ({int id, String mediaType, int count})? getMostViewed() {
    final counts = getViewCounts();
    if (counts.isEmpty) return null;
    final entry = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final parts = entry.key.split('-');
    if (parts.length < 2) return null;
    return (
      id: int.tryParse(parts.last) ?? 0,
      mediaType: parts.first,
      count: entry.value,
    );
  }

  bool isMostViewed(int id, String mediaType) {
    final mv = getMostViewed();
    return mv != null && mv.id == id && mv.mediaType == mediaType;
  }

  List<HistoryEntry> getMostViewedList([int limit = 10]) {
    final counts = getViewCounts();
    final history = getHistory();
    final list = counts.entries.map((e) {
      final parts = e.key.split('-');
      final id = int.tryParse(parts.last) ?? 0;
      final mediaType = parts.first;
      final meta = history
          .where((h) => h.id == id && h.mediaType == mediaType)
          .firstOrNull;
      return (
        id: id,
        mediaType: mediaType,
        count: e.value,
        meta: meta,
      );
    }).where((x) => x.count > 0).toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return list.take(limit).where((x) => x.meta != null).map((x) => x.meta!).toList();
  }

  // ────────────────────────── Preferences ──────────────────────────

  static const _kAccent = '${AppConstants.storagePrefix}accent';
  static const _kAutoplay = '${AppConstants.storagePrefix}autoplay';
  static const _kSeenIntro = '${AppConstants.storagePrefix}seen_intro';
  static const _kServer = '${AppConstants.storagePrefix}preferred_server';

  String get accentColor => _prefs.getString(_kAccent) ?? '#E50914';
  Future<void> setAccentColor(String hex) async {
    await _prefs.setString(_kAccent, hex);
    _notify();
  }

  bool get autoplayNext => _prefs.getBool(_kAutoplay) ?? true;
  Future<void> setAutoplayNext(bool v) async {
    await _prefs.setBool(_kAutoplay, v);
    _notify();
  }

  bool get hasSeenIntro => _prefs.getBool(_kSeenIntro) ?? false;
  Future<void> setSeenIntro() async {
    await _prefs.setBool(_kSeenIntro, true);
    _notify();
  }

  String get preferredServerId => _prefs.getString(_kServer) ?? '';
  Future<void> setPreferredServerId(String id) async {
    await _prefs.setString(_kServer, id);
    _notify();
  }

  // ────────────────────────── Wipe ──────────────────────────

  Future<void> wipeAllPersonalData() async {
    await Future.wait([
      _prefs.remove('${AppConstants.storagePrefix}history'),
      _prefs.remove('${AppConstants.storagePrefix}watchlist'),
      _prefs.remove('${AppConstants.storagePrefix}likes'),
      _prefs.remove('${AppConstants.storagePrefix}ratings'),
      _prefs.remove('${AppConstants.storagePrefix}views'),
    ]);
    _notify();
  }
}

// ────────────────────────── History entry ──────────────────────────

class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.mediaType,
    required this.title,
    this.posterPath,
    this.imageSrc = '',
    this.backdropPath,
    this.releaseYear = '',
    this.rating = 0,
    this.overview = '',
    this.progress = 0,
    this.season,
    this.episode,
    required this.watchedAt,
  });

  final int id;
  final String mediaType;
  final String title;
  final String? posterPath;
  final String imageSrc;
  final String? backdropPath;
  final String releaseYear;
  final double rating;
  final String overview;
  final int progress;
  final int? season;
  final int? episode;
  final String watchedAt;

  MediaItem toMediaItem() => MediaItem(
        id: id,
        title: title,
        mediaType: mediaType,
        imageSrc: imageSrc.isNotEmpty
            ? imageSrc
            : (posterPath != null
                ? 'https://image.tmdb.org/t/p/w500$posterPath'
                : ''),
        backdropSrc: backdropPath != null
            ? 'https://image.tmdb.org/t/p/original$backdropPath'
            : '',
        releaseYear: releaseYear,
        rating: rating,
        overview: overview,
        posterPath: posterPath,
        backdropPath: backdropPath,
        progress: progress,
      );

  HistoryEntry copyWith({
    int? progress,
    int? season,
    int? episode,
    String? watchedAt,
  }) =>
      HistoryEntry(
        id: id,
        mediaType: mediaType,
        title: title,
        posterPath: posterPath,
        imageSrc: imageSrc,
        backdropPath: backdropPath,
        releaseYear: releaseYear,
        rating: rating,
        overview: overview,
        progress: progress ?? this.progress,
        season: season ?? this.season,
        episode: episode ?? this.episode,
        watchedAt: watchedAt ?? this.watchedAt,
      );

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
        id: (j['id'] as num).toInt(),
        mediaType: j['media_type'] as String,
        title: j['title'] as String,
        posterPath: j['poster_path'] as String?,
        imageSrc: (j['imageSrc'] ?? '') as String,
        backdropPath: j['backdrop_path'] as String?,
        releaseYear: (j['releaseYear'] ?? '') as String,
        rating: ((j['rating'] ?? 0) as num).toDouble(),
        overview: (j['overview'] ?? '') as String,
        progress: (j['progress'] ?? 0) as int,
        season: j['season'] as int?,
        episode: j['episode'] as int?,
        watchedAt: j['watched_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'media_type': mediaType,
        'title': title,
        'poster_path': posterPath,
        'imageSrc': imageSrc,
        'backdrop_path': backdropPath,
        'releaseYear': releaseYear,
        'rating': rating,
        'overview': overview,
        'progress': progress,
        'season': season,
        'episode': episode,
        'watched_at': watchedAt,
      };
}

// ── JSON helpers for MediaItem persistence ──

Map<String, dynamic> _mediaToJson(MediaItem m) => {
      'id': m.id,
      'media_type': m.mediaType,
      'title': m.title,
      'poster_path': m.posterPath,
      'imageSrc': m.imageSrc,
      'releaseYear': m.releaseYear,
      'rating': m.rating,
      'backdrop_path': m.backdropPath,
      'overview': m.overview,
    };

MediaItem _mediaFromJson(Map<String, dynamic> j) => MediaItem(
      id: (j['id'] as num).toInt(),
      mediaType: j['media_type'] as String,
      title: j['title'] as String,
      posterPath: j['poster_path'] as String?,
      imageSrc: (j['imageSrc'] ?? '') as String,
      releaseYear: (j['releaseYear'] ?? '') as String,
      rating: ((j['rating'] ?? 0) as num).toDouble(),
      backdropPath: j['backdrop_path'] as String?,
      overview: (j['overview'] ?? '') as String,
    );

typedef VoidCallback = void Function();

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
