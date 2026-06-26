import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/media_item.dart';
import 'movie_card.dart';

/// A horizontal, snap-scrolling carousel of [MovieCard]s with optional
/// giant rank numbers (for "Top 10" style rows).
///
/// Ports the web app's `Carousel` component.
class ContentRow extends StatelessWidget {
  const ContentRow({
    super.key,
    required this.title,
    required this.icon,
    this.iconColor,
    required this.items,
    this.isNumbered = false,
    this.onRemove,
  });

  final String title;
  final IconData icon;
  final Color? iconColor;
  final List<MediaItem> items;
  final bool isNumbered;
  final void Function(int id, String mediaType)? onRemove;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 22, color: iconColor ?? AppColors.accent),
                const SizedBox(width: 8),
                Text(title, style: AppTextStyles.h2),
              ],
            ),
          ),
          // Horizontal list
          SizedBox(
            height: isNumbered ? 230 : 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final item = items[i];
                return MovieCard(
                  item: isNumbered
                      ? item.copyWith(isMostViewed: i == 0 && item.isMostViewed)
                      : item,
                  rank: isNumbered ? i + 1 : null,
                  width: isNumbered ? 140 : 124,
                  onRemove: onRemove != null
                      ? () => onRemove!(item.id, item.mediaType)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
