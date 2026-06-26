import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/media_item.dart';
import '../../data/services/tmdb_service.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/widgets/content_row.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/movie_card.dart';

/// Anime page — animation genre + secondary genre filter.
///
/// Ports the web app's `Anime.jsx`: discovery uses the Animation genre
/// (16) optionally combined with a second genre. "All" shows the
/// Trending Anime carousel.
class AnimeScreen extends ConsumerStatefulWidget {
  const AnimeScreen({super.key});

  @override
  ConsumerState<AnimeScreen> createState() => _AnimeScreenState();
}

class _AnimeScreenState extends ConsumerState<AnimeScreen> {
  final _tmdb = TmdbService.instance;
  // Anime-friendly secondary genres (same IDs as the web app).
  static const _animeGenres = {28, 12, 35, 18, 10751, 14, 878, 53};
  List<({int id, String name})> _genres = const [];
  int? _selectedGenre;
  List<MediaItem> _genreResults = const [];
  List<MediaItem> _anime = const [];
  bool _loading = true;
  bool _genreLoading = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final results = await Future.wait([
        _tmdb.genreList('movie'),
        _tmdb.animationMovies(),
      ]);
      if (!mounted) return;
      setState(() {
        _genres = (results[0] as List<Genre>)
            .where((g) => _animeGenres.contains(g.id))
            .map((g) => (id: g.id, name: g.name))
            .toList();
        _anime = results[1] as List<MediaItem>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _selectGenre(int? id) async {
    setState(() {
      _selectedGenre = id;
      _genreLoading = true;
    });
    if (id == null) {
      setState(() => _genreLoading = false);
      return;
    }
    try {
      // Combine Animation(16) + selected genre.
      final results =
          await _tmdb.discoverByGenre('movie', '16,$id');
      if (!mounted) return;
      setState(() {
        _genreResults = results;
        _genreLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _genreLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return LoadingOverlay(message: 'Loading anime…');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: PageHeader(title: 'Anime')),
            SliverToBoxAdapter(
              child: GenrePills(
                genres: _genres,
                selectedId: _selectedGenre,
                onSelected: _selectGenre,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            if (_selectedGenre == null)
              SliverToBoxAdapter(
                child: ContentRow(
                  title: 'Trending Anime',
                  icon: Icons.auto_awesome_rounded,
                  iconColor: AppColors.sparkles,
                  items: _anime,
                ),
              )
            else if (_genreLoading)
              const SliverFillRemaining(
                child: const LoadingOverlay(message: 'Filtering…'),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 130,
                    childAspectRatio: 0.52,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => MovieCard(item: _genreResults[i]),
                    childCount: _genreResults.length,
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
