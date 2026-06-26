import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/media_item.dart';
import '../../data/services/tmdb_service.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/content_row.dart';
import '../../shared/widgets/hero_carousel.dart';
import '../../shared/widgets/loading_overlay.dart';
import 'widgets/ai_home_section.dart';

/// Home page — the cinematic landing screen.
///
/// Ports the web app's `Home.jsx`: a hero carousel of trending titles,
/// then a stack of content rows (Continue Watching, Most Viewed, Trending,
/// AI section, My List, Top Rated, Trending TV, Now Playing, Action,
/// Upcoming, Animation).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _tmdb = TmdbService.instance;
  bool _loading = true;

  List<MediaItem> _trending = const [];
  List<MediaItem> _topRated = const [];
  List<MediaItem> _upcoming = const [];
  List<MediaItem> _animation = const [];
  List<MediaItem> _trendingTv = const [];
  List<MediaItem> _nowPlaying = const [];
  List<MediaItem> _action = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _tmdb.trendingMovies(),
        _tmdb.topRatedMovies(),
        _tmdb.upcomingMovies(),
        _tmdb.animationMovies(),
        _tmdb.trendingTv().catchError((_) => <MediaItem>[]),
        _tmdb.nowPlaying().catchError((_) => <MediaItem>[]),
        _tmdb.actionMovies().catchError((_) => <MediaItem>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _trending = results[0];
        _topRated = results[1];
        _upcoming = results[2];
        _animation = results[3];
        _trendingTv = results[4];
        _nowPlaying = results[5];
        _action = results[6];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final continueWatching = ref.watch(continueWatchingProvider);
    final mostViewed = ref.watch(mostViewedListProvider);
    final watchlist = ref.watch(watchlistProvider);

    if (_loading) {
      return LoadingOverlay(message: 'Loading cinema…');
    }

    final mvItems = mostViewed
        .map((h) => h.toMediaItem().copyWith(isMostViewed: true))
        .toList();

    final myListItems = watchlist
        .where((w) => w.imageSrc.isNotEmpty || w.posterPath != null)
        .toList();

    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.backgroundCard,
      onRefresh: () async {
        setState(() => _loading = true);
        await _load();
      },
      child: CustomScrollView(
        slivers: [
          // Hero — no top padding so the image bleeds to the status bar
          SliverToBoxAdapter(child: _trending.isEmpty ? const SizedBox.shrink() : HeroCarousel(items: _trending.take(5).toList())),

          // Continue watching
          if (continueWatching.isNotEmpty)
            SliverToBoxAdapter(
              child: ContentRow(
                title: 'Continue Watching',
                icon: Icons.history_rounded,
                iconColor: AppColors.clock,
                items: continueWatching,
                onRemove: (id, mt) async {
                  await StorageActions.instance.removeFromHistory(id, mt);
                  bumpStorage(ref);
                },
              ),
            ),

          // Most viewed
          if (mvItems.isNotEmpty)
            SliverToBoxAdapter(
              child: ContentRow(
                title: 'Most Viewed on Xstream',
                icon: Icons.workspace_premium_rounded,
                iconColor: AppColors.crown,
                items: mvItems,
              ),
            ),

          // Trending today
          SliverToBoxAdapter(
            child: ContentRow(
              title: 'Trending Today',
              icon: Icons.local_fire_department_rounded,
              iconColor: AppColors.flame,
              items: _trending,
              isNumbered: true,
            ),
          ),

          // AI section
          const SliverToBoxAdapter(child: AiHomeSection()),

          // My list
          if (myListItems.isNotEmpty)
            SliverToBoxAdapter(
              child: ContentRow(
                title: 'My List',
                icon: Icons.playlist_add_rounded,
                iconColor: AppColors.listPlus,
                items: myListItems,
              ),
            ),

          // Top rated
          SliverToBoxAdapter(
            child: ContentRow(
              title: 'Top Rated Movies',
              icon: Icons.star_rounded,
              iconColor: AppColors.star,
              items: _topRated,
              isNumbered: true,
            ),
          ),

          // Trending TV
          if (_trendingTv.isNotEmpty)
            SliverToBoxAdapter(
              child: ContentRow(
                title: 'Trending TV Shows',
                icon: Icons.tv_rounded,
                iconColor: AppColors.tv,
                items: _trendingTv,
              ),
            ),

          // Now playing
          if (_nowPlaying.isNotEmpty)
            SliverToBoxAdapter(
              child: ContentRow(
                title: 'Now Playing in Theaters',
                icon: Icons.movie_filter_rounded,
                iconColor: AppColors.clapperboard,
                items: _nowPlaying,
              ),
            ),

          // Action
          if (_action.isNotEmpty)
            SliverToBoxAdapter(
              child: ContentRow(
                title: 'Action Movies',
                icon: Icons.bolt_rounded,
                iconColor: AppColors.zap,
                items: _action,
              ),
            ),

          // Upcoming
          SliverToBoxAdapter(
            child: ContentRow(
              title: 'Upcoming Releases',
              icon: Icons.calendar_month_rounded,
              iconColor: AppColors.calendar,
              items: _upcoming,
            ),
          ),

          // Animation
          SliverToBoxAdapter(
            child: ContentRow(
              title: 'Trending Animation',
              icon: Icons.auto_awesome_rounded,
              iconColor: AppColors.sparkles,
              items: _animation,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}
