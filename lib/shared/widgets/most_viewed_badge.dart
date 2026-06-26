import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// The variants available for the [MostViewedBadge].
enum MvVariant { corner, ribbon, pill }

/// A badge that marks the most-viewed title on the device.
///
/// Ports the web app's `MostViewedBadge` — an animated flame with a
/// shine-sweep effect. Three variants:
/// - [MvVariant.corner] — small corner ribbon for poster cards
/// - [MvVariant.ribbon] — vertical ribbon for the Details poster
/// - [MvVariant.pill] — horizontal pill for inline use
class MostViewedBadge extends StatefulWidget {
  const MostViewedBadge({super.key, this.variant = MvVariant.pill});

  final MvVariant variant;

  @override
  State<MostViewedBadge> createState() => _MostViewedBadgeState();
}

class _MostViewedBadgeState extends State<MostViewedBadge>
    with TickerProviderStateMixin {
  late final AnimationController _flame;
  late final AnimationController _shine;

  @override
  void initState() {
    super.initState();
    _flame = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _flame.dispose();
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.variant) {
      case MvVariant.corner:
        return _corner();
      case MvVariant.ribbon:
        return _ribbon();
      case MvVariant.pill:
        return _pill();
    }
  }

  Widget _pill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B00), Color(0xFFE50914)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.5),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: Tween(begin: 0.85, end: 1.15).animate(
              CurvedAnimation(parent: _flame, curve: Curves.easeInOut),
            ),
            child: const Icon(Icons.local_fire_department_rounded,
                size: 14, color: Colors.white),
          ),
          const SizedBox(width: 4),
          Text(
            'MOST VIEWED',
            style: AppTextStyles.label.copyWith(
              color: Colors.white,
              fontSize: 9,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _corner() {
    return ClipPath(
      clipper: _CornerClipper(),
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF6B00), Color(0xFFE50914)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 6,
              top: 8,
              child: ScaleTransition(
                scale: Tween(begin: 0.8, end: 1.2).animate(
                  CurvedAnimation(parent: _flame, curve: Curves.easeInOut),
                ),
                child: const Icon(Icons.local_fire_department_rounded,
                    size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ribbon() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B00), Color(0xFFE50914)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: Tween(begin: 0.85, end: 1.15).animate(
              CurvedAnimation(parent: _flame, curve: Curves.easeInOut),
            ),
            child: const Icon(Icons.local_fire_department_rounded,
                size: 18, color: Colors.white),
          ),
          Text(
            'TOP',
            style: AppTextStyles.label
                .copyWith(color: Colors.white, fontSize: 9, letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}

class _CornerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(size.width, 0);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// A reusable section title row (icon + label) used above carousels.
class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.icon,
    required this.label,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 22),
      child: Row(
        children: [
          Icon(icon, size: 22, color: iconColor ?? AppColors.accent),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.h2),
        ],
      ),
    );
  }
}
