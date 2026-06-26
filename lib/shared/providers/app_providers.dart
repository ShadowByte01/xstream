import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/streaming_servers.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/ai_recommendation.dart';
import '../../data/models/media_item.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/storage_service.dart';

/// Root provider for the [StorageService] singleton.
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.I;
});

int _storageVersion = 0;
/// Re-builds whenever any storage key changes.
final _storageVersionProvider = Provider<int>((ref) {
  final storage = ref.watch(storageServiceProvider);
  void listener() => ref.invalidateSelf();
  storage.addListener(listener);
  ref.onDispose(() => storage.removeListener(listener));
  return _storageVersion++;
});

// ── Consent ──

enum ConsentState { accepted, declined, needsChoice }

final consentProvider = Provider<ConsentState>((ref) {
  ref.watch(_storageVersionProvider);
  final c = StorageService.I.consent;
  if (c == 'accepted') return ConsentState.accepted;
  if (c == 'declined') return ConsentState.declined;
  return ConsentState.needsChoice;
});

// ── History / Watchlist / Likes ──

final historyProvider = Provider<List<HistoryEntry>>((ref) {
  ref.watch(_storageVersionProvider);
  return StorageService.I.getHistory();
});

final watchlistProvider = Provider<List<MediaItem>>((ref) {
  ref.watch(_storageVersionProvider);
  return StorageService.I.getWatchlist();
});

final likesProvider = Provider<List<MediaItem>>((ref) {
  ref.watch(_storageVersionProvider);
  return StorageService.I.getLikes();
});

final ratingsProvider = Provider<Map<String, int>>((ref) {
  ref.watch(_storageVersionProvider);
  return StorageService.I.getRatings();
});

final mostViewedProvider = Provider<({int id, String mediaType, int count})?>((ref) {
  ref.watch(_storageVersionProvider);
  return StorageService.I.getMostViewed();
});

final mostViewedListProvider = Provider<List<HistoryEntry>>((ref) {
  ref.watch(_storageVersionProvider);
  return StorageService.I.getMostViewedList(10);
});

final continueWatchingProvider = Provider<List<MediaItem>>((ref) {
  final history = ref.watch(historyProvider);
  return history
      .where((h) => h.imageSrc.isNotEmpty || h.posterPath != null)
      .map((h) => h.toMediaItem().copyWith(progress: h.progress))
      .toList();
});

// ── Preferences ──

final accentColorProvider = Provider<Color>((ref) {
  ref.watch(_storageVersionProvider);
  final hex = StorageService.I.accentColor;
  return _hexToColor(hex);
});

final autoplayNextProvider = Provider<bool>((ref) {
  ref.watch(_storageVersionProvider);
  return StorageService.I.autoplayNext;
});

final hasSeenIntroProvider = Provider<bool>((ref) {
  ref.watch(_storageVersionProvider);
  return StorageService.I.hasSeenIntro;
});

final preferredServerProvider = StateProvider<StreamingServer>((ref) {
  ref.watch(_storageVersionProvider);
  final savedId = StorageService.I.preferredServerId;
  return streamingServers
          .where((s) => s.id == savedId)
          .firstOrNull ??
      defaultServer;
});

// ── Actions (imperative helpers used by widgets) ──

class StorageActions {
  StorageActions._();
  static final instance = StorageActions._();

  Future<void> acceptConsent() => StorageService.I.acceptConsent();
  Future<void> declineConsent() => StorageService.I.declineConsent();

  Future<void> addToHistory(MediaItem item, {int? season, int? episode}) =>
      StorageService.I.addToHistory(HistoryEntry(
        id: item.id,
        mediaType: item.mediaType,
        title: item.title,
        posterPath: item.posterPath,
        imageSrc: item.imageSrc,
        backdropPath: item.backdropPath,
        releaseYear: item.releaseYear,
        rating: item.rating,
        overview: item.overview,
        progress: 0,
        season: season,
        episode: episode,
        watchedAt: DateTime.now().toIso8601String(),
      ));

  Future<void> updateProgress(int id, String mt, int progress,
          [int? season, int? episode]) =>
      StorageService.I.updateHistoryProgress(id, mt, progress, season, episode);

  Future<void> removeFromHistory(int id, String mt) =>
      StorageService.I.removeFromHistory(id, mt);
  Future<void> clearHistory() => StorageService.I.clearHistory();

  Future<bool> toggleWatchlist(MediaItem item) =>
      StorageService.I.toggleWatchlist(item);
  bool isInWatchlist(int id, String mt) =>
      StorageService.I.isInWatchlist(id, mt);

  Future<bool> toggleLike(MediaItem item) => StorageService.I.toggleLike(item);
  bool isLiked(int id, String mt) => StorageService.I.isLiked(id, mt);

  Future<void> setRating(int id, String mt, int v) =>
      StorageService.I.setRating(id, mt, v);
  int getRating(int id, String mt) => StorageService.I.getRating(id, mt);

  Future<int> registerView(int id, String mt) =>
      StorageService.I.registerView(id, mt);
  bool isMostViewed(int id, String mt) =>
      StorageService.I.isMostViewed(id, mt);

  Future<void> setAccent(String hex) => StorageService.I.setAccentColor(hex);
  Future<void> setAutoplayNext(bool v) => StorageService.I.setAutoplayNext(v);
  Future<void> setSeenIntro() => StorageService.I.setSeenIntro();
  Future<void> setPreferredServer(String id) =>
      StorageService.I.setPreferredServerId(id);
  Future<void> wipeAll() => StorageService.I.wipeAllPersonalData();
}

// ── AI recommendation future ──

final aiRecommendationProvider = FutureProvider.family<
    List<AiRecommendation>, ({String mood, String text, String language})>(
  (ref, params) async {
    return AiService.instance.getRecommendations(
      mood: params.mood,
      customText: params.text,
      language: params.language,
    );
  },
);

Color _hexToColor(String hex) {
  var h = hex.replaceAll('#', '');
  if (h.length == 6) h = 'FF$h';
  try {
    return Color(int.parse(h, radix: 16));
  } catch (_) {
    return AppColors.accent;
  }
}

/// Re-evaluates a provider after a storage mutation.
void bumpStorage(WidgetRef ref) {
  ref.read(_storageVersionProvider.notifier).state++;
}

@visibleForTesting
void debugBump(WidgetRef ref) => bumpStorage(ref);
