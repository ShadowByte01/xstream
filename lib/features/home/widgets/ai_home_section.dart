import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/ai_recommendation.dart';
import '../../../shared/providers/app_providers.dart';
import '../../ai_recommend/ai_recommend_screen.dart';

/// The inline "Can't decide what to watch?" banner on the Home page.
///
/// Ports the web app's `AISection`. Tapping it opens the full-screen
/// [AiRecommendScreen] where the user picks a mood and gets 15 picks.
class AiHomeSection extends ConsumerWidget {
  const AiHomeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.18),
              AppColors.backgroundCard,
            ],
          ),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              size: 13, color: accent),
                          const SizedBox(width: 5),
                          Text('AI Powered',
                              style: AppTextStyles.label
                                  .copyWith(color: accent, fontSize: 10)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Can't decide what to watch?",
                      style: AppTextStyles.h2,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Let XAI analyse your mood and find the perfect movie for you right now.',
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _openAi(context, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome_rounded,
                          size: 18, color: Colors.white),
                      const SizedBox(width: 6),
                      Text('Get Picks',
                          style: AppTextStyles.button
                              .copyWith(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAi(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AiRecommendScreen(),
        fullscreenDialog: true,
      ),
    );
  }
}
