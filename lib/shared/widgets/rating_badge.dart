import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// A small pill showing the TMDB vote average with a color-coded star.
///
/// Mirrors the web app's color rule: green ≥ 8, yellow ≥ 6, red otherwise.
class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.rating, this.compact = false});

  final double rating;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.ratingColor(rating);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 6,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.8), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: AppTextStyles.label.copyWith(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
