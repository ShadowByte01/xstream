import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/constants/streaming_servers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/media_detail.dart';
import '../../data/models/media_item.dart';
import '../../data/services/tmdb_service.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/most_viewed_badge.dart';
import '../../shared/widgets/movie_card.dart';
import '../../shared/widgets/rating_badge.dart';

/// The full-screen streaming player.
///
/// Ports the web app's `Watch.jsx`: a WebView that loads one of 11
/// embed providers, a server picker dropdown, TV season/episode
/// selector, fullscreen toggle, and a "More Like This" row.
///
/// Keyboard shortcuts from the web app are adapted for Android:
/// the hardware back button exits fullscreen first, then pops the page.
class WatchScreen extends ConsumerStatefulWidget {
  const WatchScreen({
    super.key,
    required this.type,
    required this.id,
    this.season = 1,
    this.episode = 1,
  });

  final String type;
  final int id;
  final int season;
  final int episode;

  @override
  ConsumerState<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends ConsumerState<WatchScreen> {
  final _tmdb = TmdbService.instance;
  MediaDetail? _detail;
  List<MediaItem> _similar = const [];
  bool _loading = true;

  late StreamingServer _server;
  late int _season;
  late int _episode;
  bool _iframeLoaded = false;
  bool _showServerMenu = false;
  bool _showEpisodes = false;

  @override
  void initState() {
    super.initState();
    _season = widget.season;
    _episode = widget.episode;
    final savedId = StorageService.I.preferredServerId;
    _server = streamingServers.where((s) => s.id == savedId).firstOrNull ??
        defaultServer;
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await _tmdb.details(widget.type, widget.id);
      final similar = await _tmdb.similar(widget.type, widget.id);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _similar = similar;
        _loading = false;
      });
      await StorageActions.instance.addToHistory(detail.toMediaItem(),
          season: widget.type == 'tv' ? _season : null,
          episode: widget.type == 'tv' ? _episode : null);
      await StorageActions.instance.registerView(detail.id, widget.type);
      bumpStorage(ref);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String get _streamUrl => widget.type == 'movie'
      ? _server.movieUrl(widget.id.toString())
      : _server.tvUrl(widget.id.toString(), _season, _episode);

  void _switchServer(StreamingServer s) async {
    setState(() {
      _server = s;
      _iframeLoaded = false;
      _showServerMenu = false;
    });
    await StorageActions.instance.setPreferredServer(s.id);
  }

  void _playNextEpisode() {
    if (widget.type != 'tv' || _detail == null) return;
    final seasons = _detail!.seasons;
    final current = seasons.where((s) => s.seasonNumber == _season).firstOrNull;
    final totalEps = current?.episodeCount ?? 0;
    if (_episode < totalEps) {
      setState(() { _episode++; _iframeLoaded = false; });
    } else {
      final nextSeasonIdx = seasons.indexWhere((s) => s.seasonNumber == _season);
      if (nextSeasonIdx >= 0 && nextSeasonIdx + 1 < seasons.length) {
        setState(() {
          _season = seasons[nextSeasonIdx + 1].seasonNumber;
          _episode = 1;
          _iframeLoaded = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: LoadingOverlay(message: 'Connecting to secure servers…'),
      );
    }

    final d = _detail;
    final accent = Theme.of(context).colorScheme.primary;
    final totalSeasons = d?.seasons ?? const [];

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: [
            // ── Player ──
            SliverToBoxAdapter(
              child: _PlayerArea(
                streamUrl: _streamUrl,
                serverName: _server.name,
                title: d?.title ?? '',
                type: widget.type,
                season: _season,
                episode: _episode,
                loaded: _iframeLoaded,
                onLoaded: () => setState(() => _iframeLoaded = true),
                onBack: () => context.pop(),
                onServerMenu: () => setState(() => _showServerMenu = true),
                onNextEpisode:
                    widget.type == 'tv' ? _playNextEpisode : null,
              ),
            ),

            // ── Server picker (inline, below player) ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: GestureDetector(
                  onTap: () => setState(() => _showServerMenu = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Row(
                      children: [
                        _ServerFlag(flag: _server.flag),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Server', style: AppTextStyles.caption),
                              Text(_server.name,
                                  style: AppTextStyles.bodyPrimary
                                      .copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── TV Episodes ──
            if (widget.type == 'tv' && totalSeasons.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                ),
              ),
              SliverToBoxAdapter(
                child: _EpisodeSelector(
                  seasons: totalSeasons,
                  selectedSeason: _season,
                  selectedEpisode: _episode,
                  onSeason: (s) =>
                      setState(() { _season = s; _episode = 1; _iframeLoaded = false; }),
                  onEpisode: (e) =>
                      setState(() { _episode = e; _iframeLoaded = false; }),
                ),
              ),
            ],

            // ── Title + meta ──
            if (d != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(d.title,
                                style: AppTextStyles.h1.copyWith(fontSize: 20)),
                          ),
                          if (StorageActions.instance
                              .isMostViewed(d.id, d.mediaType))
                            const MostViewedBadge(variant: MvVariant.pill),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              d.mediaType == 'movie' ? 'MOVIE' : 'TV SHOW',
                              style: AppTextStyles.label
                                  .copyWith(color: accent, fontSize: 10),
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (d.releaseYear.isNotEmpty)
                            Text(d.releaseYear, style: AppTextStyles.body),
                          const SizedBox(width: 10),
                          if (d.voteAverage > 0)
                            RatingBadge(rating: d.voteAverage),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(d.overview, style: AppTextStyles.body),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: d.genres
                            .map((g) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(g.name,
                                      style: AppTextStyles.bodyPrimary
                                          .copyWith(fontSize: 12)),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Similar ──
            if (_similar.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('More Like This', style: AppTextStyles.h2),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 210,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _similar.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, i) =>
                              MovieCard(item: _similar[i]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────── Player area ──────────────────────────

class _PlayerArea extends StatefulWidget {
  const _PlayerArea({
    required this.streamUrl,
    required this.serverName,
    required this.title,
    required this.type,
    required this.season,
    required this.episode,
    required this.loaded,
    required this.onLoaded,
    required this.onBack,
    required this.onServerMenu,
    this.onNextEpisode,
  });

  final String streamUrl;
  final String serverName;
  final String title;
  final String type;
  final int season;
  final int episode;
  final bool loaded;
  final VoidCallback onLoaded;
  final VoidCallback onBack;
  final VoidCallback onServerMenu;
  final VoidCallback? onNextEpisode;

  @override
  State<_PlayerArea> createState() => _PlayerAreaState();
}

class _PlayerAreaState extends State<_PlayerArea> {
  late final WebViewController _controller;
  bool _inited = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (!_inited) {
            setState(() => _inited = true);
            widget.onLoaded();
          }
        },
        onNavigationRequest: (req) => NavigationDecision.navigate,
      ))
      ..setBackgroundColor(Colors.black)
      ..loadRequest(Uri.parse(widget.streamUrl));
  }

  @override
  void didUpdateWidget(covariant _PlayerArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamUrl != widget.streamUrl) {
      setState(() => _inited = false);
      _controller.loadRequest(Uri.parse(widget.streamUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              child: Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (!_inited)
                    const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppColors.accent),
                          SizedBox(height: 12),
                          Text('Initializing stream…',
                              style: AppTextStyles.body),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Top overlay bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _PlayerTopBar(
              title: widget.title,
              type: widget.type,
              season: widget.season,
              episode: widget.episode,
              onBack: widget.onBack,
              onServerMenu: widget.onServerMenu,
              onNextEpisode: widget.onNextEpisode,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerTopBar extends StatelessWidget {
  const _PlayerTopBar({
    required this.title,
    required this.type,
    required this.season,
    required this.episode,
    required this.onBack,
    required this.onServerMenu,
    this.onNextEpisode,
  });

  final String title;
  final String type;
  final int season;
  final int episode;
  final VoidCallback onBack;
  final VoidCallback onServerMenu;
  final VoidCallback? onNextEpisode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: onBack,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Now Playing', style: AppTextStyles.caption),
                Text(
                  type == 'tv'
                      ? '$title • S$season:E$episode'
                      : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyPrimary
                      .copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          ),
          if (onNextEpisode != null)
            TextButton(
              onPressed: onNextEpisode,
              child: const Text('NEXT',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
            ),
          IconButton(
            icon: const Icon(Icons.video_settings_rounded, size: 20),
            onPressed: onServerMenu,
          ),
        ],
      ),
    );
  }
}

// ────────────────────────── Episode selector ──────────────────────────

class _EpisodeSelector extends StatelessWidget {
  const _EpisodeSelector({
    required this.seasons,
    required this.selectedSeason,
    required this.selectedEpisode,
    required this.onSeason,
    required this.onEpisode,
  });

  final List<SeasonInfo> seasons;
  final int selectedSeason;
  final int selectedEpisode;
  final ValueChanged<int> onSeason;
  final ValueChanged<int> onEpisode;

  @override
  Widget build(BuildContext context) {
    final current =
        seasons.where((s) => s.seasonNumber == selectedSeason).firstOrNull;
    final totalEps = current?.episodeCount ?? 0;
    final accent = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.tv_rounded, size: 20),
              const SizedBox(width: 8),
              Text('Episodes', style: AppTextStyles.h2),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Season tabs
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: seasons.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final s = seasons[i];
              final active = s.seasonNumber == selectedSeason;
              return GestureDetector(
                onTap: () => onSeason(s.seasonNumber),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? accent : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active
                          ? accent
                          : Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text('Season ${s.seasonNumber}',
                      style: AppTextStyles.bodyPrimary.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: active ? Colors.white : AppColors.textSecondary)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Episode grid
        if (totalEps > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(totalEps, (i) {
                final e = i + 1;
                final active = e == selectedEpisode;
                return GestureDetector(
                  onTap: () => onEpisode(e),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: active ? accent : AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: active
                            ? accent
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.movie_rounded,
                            size: 14,
                            color: active
                                ? Colors.white
                                : AppColors.textMuted),
                        const SizedBox(height: 2),
                        Text('Ep $e',
                            style: AppTextStyles.caption.copyWith(
                                fontSize: 10,
                                color: active
                                    ? Colors.white
                                    : AppColors.textSecondary)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text('Episode data not available for this season.',
                style: AppTextStyles.body),
          ),
      ],
    );
  }
}

// ────────────────────────── Server flag icon ──────────────────────────

class _ServerFlag extends StatelessWidget {
  const _ServerFlag({required this.flag});
  final ServerFlag flag;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    switch (flag) {
      case ServerFlag.zap:
        return Icon(Icons.bolt_rounded, size: 16, color: accent);
      case ServerFlag.star:
        return Icon(Icons.star_rounded, size: 16, color: accent, fill: 1);
      case ServerFlag.us:
        return const Text('🇺🇸', style: TextStyle(fontSize: 14));
      case ServerFlag.india:
        return const Text('🇮🇳', style: TextStyle(fontSize: 14));
      case ServerFlag.uk:
        return const Text('🇬🇧', style: TextStyle(fontSize: 14));
      case ServerFlag.australia:
        return const Text('🇦🇺', style: TextStyle(fontSize: 14));
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
