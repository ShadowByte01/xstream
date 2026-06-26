import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/media_item.dart';
import '../../data/services/tmdb_service.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/widgets/content_row.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/movie_card.dart';

/// Movies page — genre-filtered browse.
///
/// Ports the web app's `Movies.jsx`: a pill row of genres; when "All" is
/// selected it shows Critically Acclaimed + Action Blockbusters carousels,
/// otherwise a grid of movies for the chosen genre.
class MoviesScreen extends ConsumerStatefulWidget {
  const MoviesScreen({super.key});

  @override
  ConsumerState<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends ConsumerState<MoviesScreen> {
  final _tmdb = TmdbService.instance;
  List<({int id, String name})> _genres = const [];
  int? _selectedGenre;
  List<MediaItem> _genreResults = const [];
  List<MediaItem> _topRated = const [];
  List<MediaItem> _action = const [];
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
        _tmdb.topRatedMovies(),
        _tmdb.actionMovies(),
      ]);
      if (!mounted) return;
      setState(() {
        _genres = (results[0] as List<Genre>).map((g) => (id: g.id, name: g.name)).toList();
        _topRated = results[1] as List<MediaItem>;
        _action = results[2] as List<MediaItem>;
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
      final results = await _tmdb.discoverByGenre('movie', id.toString());
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
    if (_loading) return LoadingOverlay(message: 'Loading movies…');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: PageHeader(title: 'Movies')),
            SliverToBoxAdapter(
              child: GenrePills(
                genres: _genres,
                selectedId: _selectedGenre,
                onSelected: _selectGenre,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            if (_selectedGenre == null) ...[
              SliverToBoxAdapter(
                child: ContentRow(
                  title: 'Critically Acclaimed',
                  icon: Icons.emoji_events_rounded,
                  iconColor: AppColors.star,
                  items: _topRated,
                  isNumbered: true,
                ),
              ),
              SliverToBoxAdapter(
                child: ContentRow(
                  title: 'Action Blockbusters',
                  icon: Icons.bolt_rounded,
                  iconColor: AppColors.flame,
                  items: _action,
                ),
              ),
            ] else if (_genreLoading)
              const SliverFillRemaining(
                child: LoadingOverlay(message: 'Filtering…'),
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
