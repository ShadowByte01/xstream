import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/media_item.dart';
import '../../data/services/tmdb_service.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/movie_card.dart';

/// Search page — debounced query, media-type filter, infinite scroll.
///
/// Ports the web app's `Search.jsx`. The query is read from the
/// initial route (pushed by the nav search field) and the user can
/// also type directly here.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _tmdb = TmdbService.instance;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  List<MediaItem> _results = const [];
  bool _loading = false;
  bool _loadingMore = false;
  int _page = 1;
  int _totalPages = 0;
  String _query = '';
  String _filter = 'all'; // all | movie | tv

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery ?? '';
    _controller.text = _query;
    if (_query.isNotEmpty) _search(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !_loadingMore &&
        _page < _totalPages &&
        _query.isNotEmpty) {
      _loadMore();
    }
  }

  Future<void> _search({bool reset = false}) async {
    final q = _controller.text.trim();
    if (q.isEmpty) {
      setState(() => _results = const []);
      return;
    }
    setState(() {
      _query = q;
      _loading = true;
      if (reset) {
        _results = const [];
        _page = 1;
      }
    });
    try {
      final res = await _tmdb.searchMultiPaginated(q, page: 1);
      setState(() {
        _results = res.results;
        _totalPages = res.totalPages;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    final next = _page + 1;
    try {
      final res = await _tmdb.searchMultiPaginated(_query, page: next);
      final existingIds = _results.map((r) => r.id).toSet();
      setState(() {
        _results = [
          ..._results,
          ...res.results.where((r) => !existingIds.contains(r.id)),
        ];
        _page = next;
        _totalPages = res.totalPages;
        _loadingMore = false;
      });
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }

  List<MediaItem> get _filtered =>
      _filter == 'all' ? _results : _results.where((r) => r.mediaType == _filter).toList();

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Search field ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: AppTextStyles.bodyPrimary,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _search(reset: true),
                        onChanged: (_) {
                          // debounced
                          Future.delayed(const Duration(milliseconds: 400), () {
                            if (_controller.text.trim() == _query) return;
                            _search(reset: true);
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search movies, series, anime…',
                          hintStyle: AppTextStyles.body,
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: AppColors.textMuted, size: 22),
                          suffixIcon: _controller.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded,
                                      size: 18, color: AppColors.textMuted),
                                  onPressed: () {
                                    _controller.clear();
                                    _search(reset: true);
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Filter pills ──
            if (_query.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list_rounded,
                        size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    ...['all', 'movie', 'tv'].map((f) {
                      final active = _filter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _filter = f),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
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
                            child: Text(
                              f == 'all'
                                  ? 'All'
                                  : f == 'movie'
                                      ? 'Movies'
                                      : 'TV Shows',
                              style: AppTextStyles.bodyPrimary.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const Spacer(),
                    Text(
                      '${_filtered.length} result${_filtered.length == 1 ? '' : 's'}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            // ── Results ──
            Expanded(
              child: _loading
                  ? const LoadingOverlay(message: 'Searching…')
                  : _filtered.isEmpty
                      ? _query.isEmpty
                          ? _emptyIdle()
                          : _emptyNoResults()
                      : GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 130,
                            childAspectRatio: 0.52,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _filtered.length + (_loadingMore ? 1 : 0),
                          itemBuilder: (context, i) {
                            if (i == _filtered.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                ),
                              );
                            }
                            return MovieCard(item: _filtered[i]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyIdle() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_rounded, size: 56, color: AppColors.textMuted),
          const SizedBox(height: 14),
          Text('Search for movies, series & anime',
              style: AppTextStyles.body),
        ],
      ),
    );
  }

  Widget _emptyNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 56, color: AppColors.textMuted),
            const SizedBox(height: 14),
            Text('No results for "$_query"',
                style: AppTextStyles.h3, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            const Text('Try a different search term',
                style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }
}
