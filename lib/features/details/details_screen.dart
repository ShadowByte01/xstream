import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/media_detail.dart';
import '../../data/models/media_item.dart';
import '../../data/services/tmdb_service.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/content_row.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/most_viewed_badge.dart';
import '../../shared/widgets/rating_badge.dart';

/// The full detail page for a movie or TV show.
///
/// Ports the web app's `Details.jsx`: backdrop hero with poster, title,
/// rating ring, your-rating stars, genres, overview, Play/Trailer/
/// My-List/Like/Share actions, cast grid, trailers, info grid,
/// production companies, where-to-watch, keywords, and similar titles.
class DetailsScreen extends ConsumerStatefulWidget {
  const DetailsScreen({super.key, required this.type, required this.id});

  final String type;
  final int id;

  @override
  ConsumerState<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends ConsumerState<DetailsScreen> {
  final _tmdb = TmdbService.instance;
  MediaDetail? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await _tmdb.details(widget.type, widget.id);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
      // Register a view (for the "Most Viewed" badge).
      await StorageActions.instance.registerView(detail.id, widget.type);
      bumpStorage(ref);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load details.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: AppColors.background, body: LoadingOverlay(message: 'Loading…'));
    if (_detail == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(_error ?? 'Not found', style: AppTextStyles.body),
        ),
      );
    }

    final d = _detail!;
    final accent = Theme.of(context).colorScheme.primary;
    final inList =
        StorageActions.instance.isInWatchlist(d.id, d.mediaType);
    final liked = StorageActions.instance.isLiked(d.id, d.mediaType);
    final userRating = StorageActions.instance.getRating(d.id, d.mediaType);
    final isMv = StorageActions.instance.isMostViewed(d.id, d.mediaType);
    final similar = d.mediaType == 'movie'
        ? <MediaItem>[]
        : <MediaItem>[]; // similar fetched below

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Backdrop hero ──
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.5,
            pinned: false,
            stretch: true,
            backgroundColor: AppColors.background,
            leading: _BackBtn(),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: d.backdropUrl.isNotEmpty
                        ? d.backdropUrl
                        : d.posterUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: AppColors.backgroundCard),
                    errorWidget: (_, __, ___) =>
                        Container(color: AppColors.backgroundCard),
                  ),
                  // Bottom gradient → background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                          AppColors.background,
                        ],
                        stops: const [0, 0.5, 1],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Poster + info ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 110,
                      child: AspectRatio(
                        aspectRatio: 2 / 3,
                        child: CachedNetworkImage(
                          imageUrl: d.posterUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: AppColors.backgroundCard),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.backgroundCard,
                            child: const Icon(Icons.movie_outlined,
                                color: AppColors.textMuted),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (d.tagline.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '"${d.tagline}"',
                              style: AppTextStyles.body.copyWith(
                                fontStyle: FontStyle.italic,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(d.title,
                                  style: AppTextStyles.h1.copyWith(fontSize: 22)),
                            ),
                            if (isMv)
                              const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: MostViewedBadge(variant: MvVariant.pill),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (d.releaseYear.isNotEmpty)
                              _MetaChip(icon: Icons.calendar_today_rounded, label: d.releaseYear),
                            if (d.runtimeLabel.isNotEmpty)
                              _MetaChip(icon: Icons.schedule_rounded, label: d.runtimeLabel),
                            if (d.mediaType == 'tv' && d.numberOfSeasons > 0)
                              _MetaChip(
                                  icon: Icons.tv_rounded,
                                  label: '${d.numberOfSeasons} Season${d.numberOfSeasons > 1 ? 's' : ''}'),
                            _MetaChip(
                                icon: Icons.public_rounded,
                                label: d.originalLanguage.toUpperCase()),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Rating row
                        Row(
                          children: [
                            _RatingRing(percent: (d.voteAverage * 10).round()),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('User Score',
                                    style: AppTextStyles.h3.copyWith(fontSize: 14)),
                                Text('${d.voteCount} votes',
                                    style: AppTextStyles.caption),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Genres ──
          if (d.genres.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: d.genres
                      .map((g) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Text(g.name,
                                style: AppTextStyles.bodyPrimary
                                    .copyWith(fontSize: 12)),
                          ))
                      .toList(),
                ),
              ),
            ),

          // ── Overview ──
          if (d.overview.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(d.overview, style: AppTextStyles.body),
              ),
            ),

          // ── Your rating ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Text('Your Rating', style: AppTextStyles.h3),
                  const SizedBox(width: 12),
                  _StarRating(
                    rating: userRating,
                    onRate: (v) async {
                      await StorageActions.instance
                          .setRating(d.id, d.mediaType, v);
                      bumpStorage(ref);
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Action buttons ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _ActionButton(
                    label: 'Play',
                    icon: Icons.play_arrow_rounded,
                    filled: true,
                    onTap: () => context.go('/watch/${d.mediaType}/${d.id}'),
                  ),
                  _ActionButton(
                    label: 'My List',
                    icon: inList ? Icons.check : Icons.add,
                    filled: false,
                    active: inList,
                    onTap: () async {
                      await StorageActions.instance
                          .toggleWatchlist(d.toMediaItem());
                      bumpStorage(ref);
                    },
                  ),
                  _ActionButton(
                    label: 'Like',
                    icon: liked ? Icons.favorite : Icons.favorite_border,
                    filled: false,
                    active: liked,
                    onTap: () async {
                      await StorageActions.instance
                          .toggleLike(d.toMediaItem());
                      bumpStorage(ref);
                    },
                  ),
                  _ActionButton(
                    label: 'Share',
                    icon: Icons.share_rounded,
                    filled: false,
                    onTap: () => Share.share(
                        'Watch ${d.title} on Xstream — ${d.mediaType == 'movie' ? 'Movie' : 'Series'}'),
                  ),
                ],
              ),
            ),
          ),

          // ── Cast ──
          if (d.cast.isNotEmpty)
            SliverToBoxAdapter(
              child: _CastRow(cast: d.cast.take(12).toList()),
            ),

          // ── Trailers ──
          if (d.videos.isNotEmpty)
            SliverToBoxAdapter(
              child: _TrailersRow(videos: d.videos),
            ),

          // ── Info grid ──
          SliverToBoxAdapter(
            child: _InfoGrid(detail: d),
          ),

          // ── Production ──
          if (d.productionCompanies.isNotEmpty)
            SliverToBoxAdapter(
              child: _ProductionRow(companies: d.productionCompanies),
            ),

          // ── Where to watch ──
          if (d.flatrateProviders.isNotEmpty ||
              d.rentProviders.isNotEmpty ||
              d.buyProviders.isNotEmpty)
            SliverToBoxAdapter(
              child: _ProvidersBlock(detail: d),
            ),

          // ── Keywords ──
          if (d.keywords.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: d.keywords.take(15).map((kw) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(kw.name,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary)),
                    );
                  }).toList(),
                ),
              ),
            ),

          // ── Similar ──
          SliverToBoxAdapter(
            child: _SimilarBlock(type: d.mediaType, id: d.id),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
      ),
    );
  }
}

// ────────────────────────── Sub-widgets ──────────────────────────

class _BackBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.bodyPrimary
                  .copyWith(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _RatingRing extends StatelessWidget {
  const _RatingRing({required this.percent});
  final int percent;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.ratingColor(percent / 10);
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: percent / 100,
            strokeWidth: 4,
            color: color,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
          ),
          Center(
            child: Text('${percent}%',
                style: AppTextStyles.h3.copyWith(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _StarRating extends StatefulWidget {
  const _StarRating({required this.rating, required this.onRate});
  final int rating;
  final void Function(int) onRate;

  @override
  State<_StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<_StarRating> {
  int _hover = 0;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Row(
      children: List.generate(5, (i) {
        final v = i + 1;
        final filled = v <= (_hover || widget.rating);
        return GestureDetector(
          onTap: () => widget.onRate(widget.rating == v ? 0 : v),
          child: MouseRegion(
            onEnter: (_) => setState(() => _hover = v),
            onExit: (_) => setState(() => _hover = 0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                filled ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 22,
                color: filled ? accent : AppColors.textMuted,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
    this.active = false,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: filled
              ? Colors.white
              : (active
                  ? accent.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.08)),
          borderRadius: BorderRadius.circular(100),
          border: filled
              ? null
              : Border.all(
                  color: active
                      ? accent
                      : Colors.white.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18,
                color: filled
                    ? Colors.black
                    : (active ? accent : Colors.white)),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.button.copyWith(
                color: filled
                    ? Colors.black
                    : (active ? accent : Colors.white),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CastRow extends StatelessWidget {
  const _CastRow({required this.cast});
  final List<CastMember> cast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Top Cast', style: AppTextStyles.h2),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: cast.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final actor = cast[i];
                return GestureDetector(
                  onTap: () => context.go('/person/${actor.id}'),
                  child: SizedBox(
                    width: 80,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 80,
                            height: 100,
                            child: actor.profilePath != null
                                ? CachedNetworkImage(
                                    imageUrl:
                                        'https://image.tmdb.org/t/p/w185${actor.profilePath}',
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                        color: AppColors.backgroundCard),
                                    errorWidget: (_, __, ___) => Container(
                                      color: AppColors.backgroundCard,
                                      child: const Icon(Icons.person,
                                          color: AppColors.textMuted),
                                    ),
                                  )
                                : Container(
                                    color: AppColors.backgroundCard,
                                    child: const Icon(Icons.person,
                                        color: AppColors.textMuted),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(actor.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyPrimary
                                .copyWith(fontSize: 11, fontWeight: FontWeight.w600)),
                        Text(actor.character,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(fontSize: 10)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TrailersRow extends StatelessWidget {
  const _TrailersRow({required this.videos});
  final List<Video> videos;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Trailers & Videos', style: AppTextStyles.h2),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: videos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final v = videos[i];
                return GestureDetector(
                  onTap: () => _playYoutube(context, v.key),
                  child: SizedBox(
                    width: 200,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl:
                                'https://img.youtube.com/vi/${v.key}/mqdefault.jpg',
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                                color: AppColors.backgroundCard),
                            errorWidget: (_, __, ___) => Container(
                                color: AppColors.backgroundCard),
                          ),
                          Container(
                            color: Colors.black.withValues(alpha: 0.35),
                          ),
                          const Center(
                            child: Icon(Icons.play_circle_fill_rounded,
                                size: 44, color: Colors.white),
                          ),
                          if (v.type == 'Trailer')
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('Trailer',
                                    style: AppTextStyles.label
                                        .copyWith(fontSize: 9, color: Colors.white)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _playYoutube(BuildContext context, String key) {
    // Open in the system browser (url_launcher is available app-wide).
    // Using a simple approach: push a fullscreen webview via Watch route is
    // overkill; instead we surface a bottom sheet with the embed.
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            'https://img.youtube.com/vi/$key/hqdefault.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.black),
          ),
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.detail});
  final MediaDetail detail;

  @override
  Widget build(BuildContext context) {
    final items = <_InfoCard>[];
    if (detail.directors.isNotEmpty) {
      items.add(_InfoCard(
          'Director${detail.directors.length > 1 ? 's' : ''}',
          detail.directors.map((d) => d.name).join(', ')));
    }
    if (detail.writers.isNotEmpty) {
      items.add(_InfoCard('Writers', detail.writers.map((w) => w.name).join(', ')));
    }
    if (detail.status.isNotEmpty) items.add(_InfoCard('Status', detail.status));
    if (detail.releaseDate.isNotEmpty) {
      items.add(_InfoCard('Release Date', detail.releaseDate));
    }
    if (detail.runtime != null && detail.runtime! > 0) {
      items.add(_InfoCard('Runtime', '${detail.runtime} minutes'));
    }
    if (detail.budget > 0) {
      items.add(_InfoCard('Budget', '\$${detail.budget.toLocaleString()}'));
    }
    if (detail.revenue > 0) {
      items.add(_InfoCard('Revenue', '\$${detail.revenue.toLocaleString()}'));
    }
    if (detail.spokenLanguages.isNotEmpty) {
      items.add(_InfoCard('Languages', detail.spokenLanguages.join(', ')));
    }
    if (detail.originalTitle.isNotEmpty &&
        detail.originalTitle != detail.title) {
      items.add(_InfoCard('Original Title', detail.originalTitle));
    }
    if (detail.createdBy.isNotEmpty) {
      items.add(_InfoCard('Created By', detail.createdBy.join(', ')));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Details', style: AppTextStyles.h2),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: items
                  .map((c) => Container(
                        width: (MediaQuery.of(context).size.width - 42) / 2,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.title,
                                style: AppTextStyles.label
                                    .copyWith(color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text(c.value,
                                style: AppTextStyles.bodyPrimary,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard {
  const _InfoCard(this.title, this.value);
  final String title;
  final String value;
}

class _ProductionRow extends StatelessWidget {
  const _ProductionRow({required this.companies});
  final List<ProductionCompany> companies;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Production', style: AppTextStyles.h2),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: companies.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final c = companies[i];
                return GestureDetector(
                  onTap: () => context.go('/company/${c.id}'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: c.logoPath != null
                        ? CachedNetworkImage(
                            imageUrl:
                                'https://image.tmdb.org/t/p/w154${c.logoPath}',
                            height: 30,
                            placeholder: (_, __) => const SizedBox(width: 60),
                            errorWidget: (_, __, ___) => Text(c.name,
                                style: AppTextStyles.bodyPrimary),
                          )
                        : Text(c.name, style: AppTextStyles.bodyPrimary),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProvidersBlock extends StatelessWidget {
  const _ProvidersBlock({required this.detail});
  final MediaDetail detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where to Watch', style: AppTextStyles.h2),
          const SizedBox(height: 12),
          if (detail.flatrateProviders.isNotEmpty) ...[
            Text('Stream', style: AppTextStyles.label),
            const SizedBox(height: 6),
            _providerLogos(detail.flatrateProviders),
            const SizedBox(height: 14),
          ],
          if (detail.rentProviders.isNotEmpty) ...[
            Text('Rent', style: AppTextStyles.label),
            const SizedBox(height: 6),
            _providerLogos(detail.rentProviders.take(5).toList()),
            const SizedBox(height: 14),
          ],
          if (detail.buyProviders.isNotEmpty) ...[
            Text('Buy', style: AppTextStyles.label),
            const SizedBox(height: 6),
            _providerLogos(detail.buyProviders.take(5).toList()),
          ],
        ],
      ),
    );
  }

  Widget _providerLogos(List<WatchProvider> providers) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: providers
          .map((p) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: 'https://image.tmdb.org/t/p/w92${p.logoPath}',
                  width: 40,
                  height: 40,
                  placeholder: (_, __) =>
                      Container(width: 40, height: 40, color: AppColors.backgroundCard),
                  errorWidget: (_, __, ___) =>
                      Container(width: 40, height: 40, color: AppColors.backgroundCard),
                ),
              ))
          .toList(),
    );
  }
}

class _SimilarBlock extends StatefulWidget {
  const _SimilarBlock({required this.type, required this.id});
  final String type;
  final int id;

  @override
  State<_SimilarBlock> createState() => _SimilarBlockState();
}

class _SimilarBlockState extends State<_SimilarBlock> {
  final _tmdb = TmdbService.instance;
  List<MediaItem> _similar = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _tmdb.similar(widget.type, widget.id).then((s) {
      if (mounted) setState(() { _similar = s; _loaded = true; });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _similar.isEmpty) return const SizedBox.shrink();
    return ContentRow(
      title: 'More Like This',
      icon: Icons.recommend_rounded,
      iconColor: AppColors.accent,
      items: _similar,
    );
  }
}

extension on int {
  String toLocaleString() => toString();
}
