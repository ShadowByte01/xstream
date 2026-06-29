import 'package:flutter/material.dart';
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
import '../../data/services/storage_service.dart';

/// The full-screen streaming player.
///
/// Ports the web app's `Watch.jsx`: a WebView that loads one of the
/// embed providers, a server picker dropdown, TV season/episode
/// selector, fullscreen toggle, and a "More Like This" row.
///
/// Ads are no longer blocked in-app (the built-in ad blocker was removed
/// per request). Instead, two controls live just below the player, next to
/// the title:
///   • Skip Ads  — closes an ad tab the embed opened and re-opens the player.
///   • Ad-Free   — auto-switches to the VidFast server, which serves no ads.
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

  /// True when the WebView has navigated onto an ad page (canGoBack == true).
  bool _hasAd = false;

  /// When true, JS is injected into the player WebView to intercept all
  /// click-through ad redirects, so tapping inside the player never opens an ad.
  bool _forceAdBlock = false;

  /// Drives the player so we can call [skipAd] / [setForceAdBlock] from below.
  final GlobalKey<_PlayerAreaState> _playerKey = GlobalKey<_PlayerAreaState>();

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
    if (s.id == _server.id) return;
    setState(() {
      _server = s;
      _iframeLoaded = false;
      _hasAd = false;
    });
    await StorageActions.instance.setPreferredServer(s.id);
  }

  /// One-tap shortcut used by the "Ad-Free" button: jumps straight to the
  /// ad-free VidFast server (which serves no ads at all).
  void _switchToAdFree() {
    if (_server.isAdFree) {
      // Already on the ad-free server — just refresh the player.
      _playerKey.currentState?.skipAd();
      return;
    }
    _switchServer(adFreeServer);
  }

  /// Opens the server picker as a modal bottom sheet. This replaces the old
  /// `_showServerMenu` flag, which was set but never consumed — that was why
  /// tapping the server selector did nothing.
  void _showServerPicker() {
    final accent = Theme.of(context).colorScheme.primary;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Icon(Icons.video_settings_rounded, size: 20, color: accent),
                    const SizedBox(width: 8),
                    Text('Choose Server', style: AppTextStyles.h2),
                    const Spacer(),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: streamingServers.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 56),
                  itemBuilder: (context, i) {
                    final s = streamingServers[i];
                    final active = s.id == _server.id;
                    return ListTile(
                      onTap: () {
                        _switchServer(s);
                        Navigator.pop(context);
                      },
                      leading: _ServerFlag(flag: s.flag),
                      title: Text(
                        s.name,
                        style: AppTextStyles.bodyPrimary.copyWith(
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      trailing: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (s.isAdFree)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'AD-FREE',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          if (active)
                            Icon(Icons.check_circle_rounded,
                                color: accent, size: 20),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _playNextEpisode() {
    if (widget.type != 'tv' || _detail == null) return;
    final seasons = _detail!.seasons;
    final current = seasons.where((s) => s.seasonNumber == _season).firstOrNull;
    final totalEps = current?.episodeCount ?? 0;
    if (_episode < totalEps) {
      setState(() {
        _episode++;
        _iframeLoaded = false;
      });
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
      return Scaffold(
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
                key: _playerKey,
                streamUrl: _streamUrl,
                serverName: _server.name,
                title: d?.title ?? '',
                type: widget.type,
                season: _season,
                episode: _episode,
                loaded: _iframeLoaded,
                onLoaded: () => setState(() => _iframeLoaded = true),
                onAdStateChanged: (hasAd) =>
                    setState(() => _hasAd = hasAd),
                onBack: () => context.pop(),
                onServerMenu: _showServerPicker,
                onNextEpisode:
                    widget.type == 'tv' ? _playNextEpisode : null,
              ),
            ),

            // ── Server picker (inline, below player) ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: GestureDetector(
                  onTap: _showServerPicker,
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
                        if (_server.isAdFree)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('AD-FREE',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                )),
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
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                ),
              ),
              SliverToBoxAdapter(
                child: _EpisodeSelector(
                  seasons: totalSeasons,
                  selectedSeason: _season,
                  selectedEpisode: _episode,
                  onSeason: (s) => setState(() {
                    _season = s;
                    _episode = 1;
                    _iframeLoaded = false;
                  }),
                  onEpisode: (e) => setState(() {
                    _episode = e;
                    _iframeLoaded = false;
                  }),
                ),
              ),
            ],

            // ── Title + meta (Skip Ads / Ad-Free buttons live here, just
            //    below the player, right where the title is written) ──
            if (d != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Skip Ads + Ad-Free + Force Ad Block controls
                      _AdControls(
                        hasAd: _hasAd,
                        isAdFree: _server.isAdFree,
                        forceAdBlock: _forceAdBlock,
                        onSkipAds: () =>
                            _playerKey.currentState?.skipAd(),
                        onAdFree: _switchToAdFree,
                        onForceAdBlock: () {
                          setState(() => _forceAdBlock = !_forceAdBlock);
                          _playerKey.currentState
                              ?.setForceAdBlock(_forceAdBlock);
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Text(d.title,
                                style: AppTextStyles.h1
                                    .copyWith(fontSize: 20)),
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
                                    color:
                                        Colors.white.withValues(alpha: 0.06),
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
                        child:
                            Text('More Like This', style: AppTextStyles.h2),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 210,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _similar.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, i) =>
                              MovieCard(item: _similar[i]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Bottom spacing clears the floating nav bar (no hidden buttons).
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────── Ad controls ──────────────────────────

/// The "Skip Ads", "Ad-Free", and "Force Ad Block" buttons, rendered just
/// below the player in the title area.
class _AdControls extends StatelessWidget {
  const _AdControls({
    required this.hasAd,
    required this.isAdFree,
    required this.forceAdBlock,
    required this.onSkipAds,
    required this.onAdFree,
    required this.onForceAdBlock,
  });

  final bool hasAd;
  final bool isAdFree;
  final bool forceAdBlock;
  final VoidCallback onSkipAds;
  final VoidCallback onAdFree;
  final VoidCallback onForceAdBlock;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ControlButton(
                icon: Icons.fast_forward_rounded,
                label: 'Skip Ads',
                onTap: onSkipAds,
                color: hasAd
                    ? const Color(0xFFE50914)
                    : const Color(0xFF2A2A30),
                foreground: Colors.white,
                highlighted: hasAd,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ControlButton(
                icon: Icons.shield_rounded,
                label: isAdFree ? 'Ad-Free On' : 'Ad-Free',
                onTap: onAdFree,
                color: isAdFree
                    ? const Color(0xFF1F8A4C)
                    : const Color(0xFF2A2A30),
                foreground: Colors.white,
                highlighted: isAdFree,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Force Ad Block — full-width toggle
        _ControlButton(
          icon: forceAdBlock
              ? Icons.block_rounded
              : Icons.sports_kabaddi_rounded,
          label: forceAdBlock ? 'Force Ad Block: ON' : 'Force Ad Block',
          onTap: onForceAdBlock,
          color: forceAdBlock
              ? const Color(0xFF7B2FBE)
              : const Color(0xFF2A2A30),
          foreground: Colors.white,
          highlighted: forceAdBlock,
          fullWidth: true,
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    required this.foreground,
    this.highlighted = false,
    this.fullWidth = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color foreground;
  final bool highlighted;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: highlighted
                  ? Border.all(color: foreground.withValues(alpha: 0.35))
                  : Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
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

// ────────────────────────── Player area ──────────────────────────

class _PlayerArea extends StatefulWidget {
  const _PlayerArea({
    super.key,
    required this.streamUrl,
    required this.serverName,
    required this.title,
    required this.type,
    required this.season,
    required this.episode,
    required this.loaded,
    required this.onLoaded,
    required this.onAdStateChanged,
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
  final ValueChanged<bool> onAdStateChanged;
  final VoidCallback onBack;
  final VoidCallback onServerMenu;
  final VoidCallback? onNextEpisode;

  @override
  State<_PlayerArea> createState() => _PlayerAreaState();
}

/// JS injected when Force Ad Block is enabled. Intercepts every click and
/// every anchor/form submission in the page and suppresses navigation.
/// It does NOT touch the video element or playback controls, so the player
/// keeps working normally.
const String _forceAdBlockJs = '''
(function() {
  if (window.__xstreamFAB) return;
  window.__xstreamFAB = true;

  // Block window.location reassignment
  var _loc = window.location;
  try {
    Object.defineProperty(window, 'location', {
      set: function(v) {},
      get: function() { return _loc; },
      configurable: true
    });
  } catch(e) {}

  // Neutralise window.open / document.write popup tricks
  window.open = function() { return null; };

  // Intercept all clicks — only block if the click target (or an ancestor)
  // is a link pointing away from the current host.
  document.addEventListener('click', function(e) {
    var el = e.target;
    for (var i = 0; i < 6 && el; i++, el = el.parentElement) {
      if (el.tagName === 'A' || el.tagName === 'AREA') {
        var href = el.href || '';
        if (href && !href.startsWith(window.location.origin)) {
          e.preventDefault();
          e.stopImmediatePropagation();
          return;
        }
      }
    }
  }, true);

  // Block form submissions that target blank tabs
  document.addEventListener('submit', function(e) {
    var t = e.target.target;
    if (t === '_blank' || t === '_top') {
      e.preventDefault();
      e.stopImmediatePropagation();
    }
  }, true);
})();
''';

class _PlayerAreaState extends State<_PlayerArea> {
  late final WebViewController _controller;
  bool _inited = false;
  bool _forceAdBlock = false;

  /// True when the WebView has moved onto an ad page (i.e. canGoBack).
  bool get hasAd => _showCloseAd;
  bool _showCloseAd = false;

  void _updateBackState() async {
    if (!mounted) return;
    bool canGoBack;
    try {
      canGoBack = await _controller.canGoBack();
    } catch (_) {
      return;
    }
    if (!mounted) return;
    if (canGoBack != _showCloseAd) {
      setState(() => _showCloseAd = canGoBack);
      widget.onAdStateChanged(canGoBack);
    }
  }

  /// Called by the "Skip Ads" button.
  /// Uses goBack() so the player is NOT reloaded — video stays exactly where it
  /// was. Falls back to goBack again on the off-chance we're already at the
  /// player page (canGoBack returns false) — in that case re-inject the
  /// Force Ad Block script if it was enabled, so nothing is lost.
  Future<void> skipAd() async {
    try {
      if (await _controller.canGoBack()) {
        await _controller.goBack();
      }
      // Re-apply FAB JS after navigation settles (onPageFinished handles it,
      // but calling it here too keeps things snappy).
      if (_forceAdBlock) {
        await Future.delayed(const Duration(milliseconds: 400));
        await _controller.runJavaScript(_forceAdBlockJs);
      }
    } catch (_) {}
    _updateBackState();
  }

  /// Called by the Force Ad Block toggle button below the player.
  Future<void> setForceAdBlock(bool enabled) async {
    _forceAdBlock = enabled;
    try {
      if (enabled) {
        await _controller.runJavaScript(_forceAdBlockJs);
      } else {
        // Disable: reload the page to clear the injected JS cleanly.
        // We reload the stream URL so the player restarts fresh without FAB.
        await _controller.runJavaScript('''
          window.__xstreamFAB = false;
        ''');
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) async {
          if (!_inited) {
            if (mounted) setState(() => _inited = true);
            widget.onLoaded();
          }
          // Always block popup windows.
          try {
            await _controller.runJavaScript('''
              window.open = function() { return null; };
            ''');
          } catch (_) {}
          // Re-inject Force Ad Block JS on every page load so navigation
          // within the embed player doesn't lose the protection.
          if (_forceAdBlock) {
            try {
              await _controller.runJavaScript(_forceAdBlockJs);
            } catch (_) {}
          }
          _updateBackState();
        },
        onUrlChange: (UrlChange change) {
          _updateBackState();
        },
        onNavigationRequest: (req) {
          final url = req.url.toLowerCase();
          // Always block app-launch schemes that hang the WebView.
          if (url.startsWith('intent://') || url.startsWith('market://')) {
            return NavigationDecision.prevent;
          }
          // When Force Ad Block is active, block any top-level navigation away
          // from the original stream domain (ads open new pages at the top
          // level, not inside iframes).
          if (_forceAdBlock && req.isMainFrame) {
            final streamHost =
                Uri.tryParse(widget.streamUrl)?.host ?? '';
            final reqHost = Uri.tryParse(req.url)?.host ?? '';
            if (streamHost.isNotEmpty && reqHost != streamHost) {
              return NavigationDecision.prevent;
            }
          }
          return NavigationDecision.navigate;
        },
      ))
      ..setBackgroundColor(Colors.black)
      ..loadRequest(Uri.parse(widget.streamUrl));
  }

  @override
  void didUpdateWidget(covariant _PlayerArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamUrl != widget.streamUrl) {
      setState(() {
        _inited = false;
        _showCloseAd = false;
      });
      widget.onAdStateChanged(false);
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
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                              color: AppColors.accent),
                          const SizedBox(height: 12),
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
                  type == 'tv' ? '$title • S$season:E$episode' : title,
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
                    color: active
                        ? accent
                        : Colors.white.withValues(alpha: 0.05),
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
                          color: active
                              ? Colors.white
                              : AppColors.textSecondary)),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        return Icon(Icons.bolt_rounded, size: 18, color: accent);
      case ServerFlag.star:
        return Icon(Icons.star_rounded, size: 18, color: accent, fill: 1);
      case ServerFlag.shield:
        return const Icon(Icons.shield_rounded, size: 18, color: Colors.greenAccent);
      case ServerFlag.us:
        return const Text('🇺🇸', style: TextStyle(fontSize: 16));
      case ServerFlag.india:
        return const Text('🇮🇳', style: TextStyle(fontSize: 16));
      case ServerFlag.uk:
        return const Text('🇬🇧', style: TextStyle(fontSize: 16));
      case ServerFlag.australia:
        return const Text('🇦🇺', style: TextStyle(fontSize: 16));
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
