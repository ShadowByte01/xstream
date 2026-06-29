import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The cinematic intro splash shown on first launch.
///
/// Ports the web app's `IntroSplash` — the XStream logo pops in, followed
/// by a light-speed spectrum of colored bars, then a fade to the home page.
/// On subsequent launches it skips straight to home (controlled by the
/// `hasSeenIntro` preference).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _xScale;
  late final AnimationController _bars;
  late final AnimationController _fade;

  static const _barColors = [
    Color(0xFFE50914),
    Color(0xFFFF7B00),
    Color(0xFFB5179E),
    Color(0xFF4361EE),
    Color(0xFF4CC9F0),
    Color(0xFFF72585),
  ];

  @override
  void initState() {
    super.initState();

    _xScale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bars = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _xScale.forward();
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    _bars.forward();
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    _fade.forward();
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    await StorageActions.instance.setSeenIntro();
    if (!mounted) return;
    context.go('/');
  }

  @override
  void dispose() {
    _xScale.dispose();
    _bars.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If the user has already seen the intro, skip immediately.
    final seen = ref.watch(hasSeenIntroProvider);
    if (seen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/');
      });
    }

    return AnimatedBuilder(
      animation: _fade,
      builder: (context, _) {
        return Opacity(
          opacity: 1 - _fade.value,
          child: Container(
            color: AppColors.background,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Spectrum bars ──
                AnimatedBuilder(
                  animation: _bars,
                  builder: (context, _) {
                    return Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: List.generate(_barColors.length, (i) {
                          final delay = i * 0.08;
                          final t = ((_bars.value - delay) / 0.6)
                              .clamp(0.0, 1.0);
                          final ease = Curves.easeOutCubic.transform(t);
                          return Container(
                            width: 10 + ease * 8,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: _barColors[i]
                                  .withValues(alpha: 0.85 * (1 - _fade.value)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          );
                        }),
                      ),
                    );
                  },
                ),
                // ── XStream logo ──
                Center(
                  child: ScaleTransition(
                    scale: Tween(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _xScale,
                        curve: Curves.elasticOut,
                      ),
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
