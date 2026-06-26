import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/media_item.dart';

/// The auto-rotating hero banner at the top of the Home page.
///
/// Ports the web app's `Hero` component — cross-fading backdrops with a
/// dynamically extracted dominant color glow, title, meta chips, and
/// Play / More Info buttons. Thumbnail strip + dot indicators let the
/// user jump between featured titles.
class HeroCarousel extends ConsumerStatefulWidget {
  const HeroCarousel({super.key, required this.items});

  final List<MediaItem> items;

  @override
  ConsumerState<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends ConsumerState<HeroCarousel>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  int _current = 0;
  Color _dominant = const Color(0xFF141414);
  final Map<int, Color> _paletteCache = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _extractColor(0);
    _startAutoPlay();
  }

  void _startAutoPlay() {
    Future.delayed(const Duration(seconds: 6), () {
      if (!mounted) return;
      final next = (_current + 1) % widget.items.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
      );
      _startAutoPlay();
    });
  }

  Future<void> _extractColor(int index) async {
    if (_paletteCache.containsKey(index)) {
      setState(() => _dominant = _paletteCache[index]!);
      return;
    }
    final item = widget.items[index];
    final url = item.backdropSrc.isNotEmpty ? item.backdropSrc : item.imageSrc;
    if (url.isEmpty) return;
    try {
      final provider = CachedNetworkImageProvider(url);
      final palette = await PaletteGenerator.fromImageProvider(
        provider,
        maximumColorCount: 8,
      );
      final color = palette.dominantColor?.color ??
          palette.darkVibrantColor?.color ??
          const Color(0xFF141414);
      _paletteCache[index] = color;
      if (mounted && _current == index) {
        setState(() => _dominant = color);
      }
    } catch (_) {
      // keep default
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final item = widget.items[_current];

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.62,
      child: Stack(
        children: [
          // ── Cross-fading backdrops ──
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              child: CachedNetworkImage(
                key: ValueKey(_current),
                imageUrl: item.backdropSrc.isNotEmpty
                    ? item.backdropSrc
                    : item.imageSrc,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (_, __) => Container(color: AppColors.background),
                errorWidget: (_, __, ___) =>
                    Container(color: AppColors.backgroundCard),
              ),
            ),
          ),

          // ── Dynamic color radial glow ──
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.5, -0.3),
                    radius: 1.0,
                    colors: [
                      _dominant.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6],
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom gradient for legibility ──
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      AppColors.background.withValues(alpha: 0.6),
                      AppColors.background,
                    ],
                    stops: const [0, 0.4, 0.75, 1],
                  ),
                ),
              ),
            ),
          ),

          // ── Content ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'X',
                            style: AppTextStyles.display.copyWith(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('FILM', style: AppTextStyles.label),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Title
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.display.copyWith(
                        fontSize: 38,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.85),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Meta chips
                    Row(
                      children: [
                        if (item.rating > 0) ...[
                          Icon(Icons.star_rounded,
                              size: 15, color: AppColors.accent),
                          const SizedBox(width: 3),
                          Text(item.rating.toStringAsFixed(1),
                              style: AppTextStyles.bodyPrimary
                                  .copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(width: 12),
                        ],
                        if (item.releaseYear.isNotEmpty)
                          Text(item.releaseYear,
                              style: AppTextStyles.bodyPrimary),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Buttons
                    Row(
                      children: [
                        _HeroButton(
                          label: 'Play',
                          icon: Icons.play_arrow_rounded,
                          filled: true,
                          onTap: () => context
                              .go('/watch/${item.mediaType}/${item.id}'),
                        ),
                        const SizedBox(width: 10),
                        _HeroButton(
                          label: 'More Info',
                          icon: Icons.info_outline_rounded,
                          filled: false,
                          onTap: () => context
                              .go('/details/${item.mediaType}/${item.id}'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Dot indicators
                    Row(
                      children: List.generate(
                        widget.items.length,
                        (i) => GestureDetector(
                          onTap: () => _pageController.animateToPage(i,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOut),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 6),
                            width: i == _current ? 22 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: i == _current
                                  ? AppColors.accent
                                  : AppColors.textMuted,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── PageView for swipe ──
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.items.length,
              onPageChanged: (i) {
                setState(() => _current = i);
                _extractColor(i);
              },
              itemBuilder: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
        decoration: BoxDecoration(
          color: filled ? Colors.white : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(100),
          border: filled
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 20, color: filled ? Colors.black : Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.button
                  .copyWith(color: filled ? Colors.black : Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
