import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/media_item.dart';
import '../../shared/providers/app_providers.dart';
import 'most_viewed_badge.dart';
import 'rating_badge.dart';

/// A single poster card used in carousels and grids.
///
/// Faithfully ports the web app's `MovieCard` — poster with blur-up
/// loading, rating badge, optional rank number, continue-watching
/// progress bar, most-viewed corner ribbon, and a tap action that
/// navigates to the Details page.
class MovieCard extends ConsumerWidget {
  const MovieCard({
    super.key,
    required this.item,
    this.rank,
    this.onRemove,
    this.width = 124,
  });

  final MediaItem item;
  final int? rank;
  final VoidCallback? onRemove;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inList = StorageActions.instance.isInWatchlist(item.id, item.mediaType);
    final isMv = item.isMostViewed ||
        StorageActions.instance.isMostViewed(item.id, item.mediaType);

    final card = GestureDetector(
      onTap: () => context.go('/details/${item.mediaType}/${item.id}'),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Poster area ──
            Stack(
              children: [
                if (rank != null)
                  Positioned(
                    left: -8,
                    bottom: -16,
                    child: _RankNumber(rank: rank!),
                  ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(left: rank != null ? 32 : 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 2 / 3,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Poster image
                          CachedNetworkImage(
                            imageUrl: item.imageSrc,
                            fit: BoxFit.cover,
                            fadeInDuration: const Duration(milliseconds: 300),
                            placeholder: (_, __) => Container(
                              color: AppColors.backgroundCard,
                              child: const Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.backgroundCard,
                              child: const Icon(Icons.broken_image_outlined,
                                  color: AppColors.textMuted, size: 28),
                            ),
                          ),
                          // Gradient overlay for legibility
                          const _PosterGradient(),
                          // Rating badge
                          if (item.rating > 0 && rank == null)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: RatingBadge(rating: item.rating),
                            ),
                          // Most viewed corner ribbon
                          if (isMv && rank == null)
                            const Positioned(
                              top: 0,
                              left: 0,
                              child: MostViewedBadge(variant: MvVariant.corner),
                            ),
                          // Continue watching progress bar
                          if (item.progress != null && item.progress! > 0)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: _ProgressBar(progress: item.progress!),
                            ),
                          // Hover-style quick actions
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: _CardActions(
                              inList: inList,
                              onPlay: () =>
                                  context.go('/watch/${item.mediaType}/${item.id}'),
                              onToggleList: () async {
                                await StorageActions.instance
                                    .toggleWatchlist(item);
                                bumpStorage(ref);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Title + year
            Padding(
              padding: EdgeInsets.only(left: rank != null ? 32 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.h3.copyWith(fontSize: 13),
                  ),
                  if (item.releaseYear.isNotEmpty)
                    Text(
                      item.releaseYear,
                      style: AppTextStyles.caption,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (onRemove == null) return card;

    return Stack(
      children: [
        card,
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black87,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close,
                  size: 14, color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}

class _PosterGradient extends StatelessWidget {
  const _PosterGradient();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.transparent,
              Colors.black.withValues(alpha: 0.75),
            ],
            stops: const [0, 0.55, 1],
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});
  final int progress;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      height: 3,
      color: Colors.black54,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: (progress / 100).clamp(0.0, 1.0),
        child: Container(color: accent),
      ),
    );
  }
}

class _CardActions extends StatefulWidget {
  const _CardActions({
    required this.inList,
    required this.onPlay,
    required this.onToggleList,
  });

  final bool inList;
  final VoidCallback onPlay;
  final VoidCallback onToggleList;

  @override
  State<_CardActions> createState() => _CardActionsState();
}

class _CardActionsState extends State<_CardActions> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _hovered ? 1 : 0,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CircleBtn(
                icon: Icons.play_arrow_rounded,
                filled: true,
                onTap: widget.onPlay,
              ),
              _CircleBtn(
                icon: widget.inList ? Icons.check : Icons.add,
                filled: false,
                onTap: widget.onToggleList,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: filled ? Colors.white : Colors.white.withValues(alpha: 0.25),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: filled ? Colors.black : Colors.white,
        ),
      ),
    );
  }
}

class _RankNumber extends StatelessWidget {
  const _RankNumber({required this.rank});
  final int rank;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$rank',
      style: GoogleFonts.bebasNeue(
        fontSize: 80,
        height: 0.85,
        letterSpacing: -4,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = AppColors.textMuted.withValues(alpha: 0.6),
      ),
    );
  }
}
