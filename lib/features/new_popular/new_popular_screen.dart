import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/media_item.dart';
import '../../data/services/tmdb_service.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/widgets/content_row.dart';
import '../../shared/widgets/loading_overlay.dart';

/// New & Popular page.
///
/// Ports the web app's `NewPopular.jsx`: Trending Right Now (numbered),
/// Trending Worldwide, In Theaters Now, Coming Soon.
class NewPopularScreen extends ConsumerStatefulWidget {
  const NewPopularScreen({super.key});

  @override
  ConsumerState<NewPopularScreen> createState() => _NewPopularScreenState();
}

class _NewPopularScreenState extends ConsumerState<NewPopularScreen> {
  final _tmdb = TmdbService.instance;
  bool _loading = true;
  List<MediaItem> _trending = const [];
  List<MediaItem> _trendingAll = const [];
  List<MediaItem> _nowPlaying = const [];
  List<MediaItem> _upcoming = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _tmdb.trendingMovies(),
        _tmdb.trendingAll().catchError((_) => <MediaItem>[]),
        _tmdb.nowPlaying().catchError((_) => <MediaItem>[]),
        _tmdb.upcomingMovies(),
      ]);
      if (!mounted) return;
      setState(() {
        _trending = results[0];
        _trendingAll = results[1];
        _nowPlaying = results[2];
        _upcoming = results[3];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LoadingOverlay(message: 'Loading what\'s hot…');
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: PageHeader(title: 'New & Popular')),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: ContentRow(
                title: 'Trending Right Now',
                icon: Icons.local_fire_department_rounded,
                iconColor: AppColors.flame,
                items: _trending,
                isNumbered: true,
              ),
            ),
            if (_trendingAll.isNotEmpty)
              SliverToBoxAdapter(
                child: ContentRow(
                  title: 'Trending Worldwide',
                  icon: Icons.public_rounded,
                  iconColor: AppColors.tv,
                  items: _trendingAll,
                ),
              ),
            if (_nowPlaying.isNotEmpty)
              SliverToBoxAdapter(
                child: ContentRow(
                  title: 'In Theaters Now',
                  icon: Icons.movie_filter_rounded,
                  iconColor: AppColors.clapperboard,
                  items: _nowPlaying,
                ),
              ),
            SliverToBoxAdapter(
              child: ContentRow(
                title: 'Coming Soon',
                icon: Icons.calendar_month_rounded,
                iconColor: AppColors.calendar,
                items: _upcoming,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}
