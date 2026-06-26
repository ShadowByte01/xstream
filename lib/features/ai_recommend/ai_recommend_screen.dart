import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ai_recommendation.dart';
import '../../data/models/media_item.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/rating_badge.dart';

/// Full-screen AI recommendation experience.
///
/// Ports the web app's `AIRecommendModal`: mood picker, language picker,
/// optional free-text prompt → cinematic loading → list of 15 enriched
/// recommendations with match %, reason, and Watch / Add-to-list actions.
class AiRecommendScreen extends ConsumerStatefulWidget {
  const AiRecommendScreen({super.key});

  @override
  ConsumerState<AiRecommendScreen> createState() => _AiRecommendScreenState();
}

class _AiRecommendScreenState extends ConsumerState<AiRecommendScreen> {
  String? _mood;
  String _language = 'en';
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            Expanded(
              child: _mood == null
                  ? _InputStage(
                      mood: _mood,
                      onMood: (m) => setState(() => _mood = m),
                      language: _language,
                      onLanguage: (l) => setState(() => _language = l),
                      controller: _textController,
                      onSubmit: () => setState(() {}),
                    )
                  : _ResultsStage(
                      mood: _mood!,
                      text: _textController.text.trim(),
                      language: _language,
                      onRetry: () => setState(() => _mood = null),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.auto_awesome_rounded, size: 20, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('XAI Recommends', style: AppTextStyles.h2),
                Text('AI-powered picks tailored to your mood',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _InputStage extends StatelessWidget {
  const _InputStage({
    required this.mood,
    required this.onMood,
    required this.language,
    required this.onLanguage,
    required this.controller,
    required this.onSubmit,
  });

  final String? mood;
  final ValueChanged<String> onMood;
  final String language;
  final ValueChanged<String> onLanguage;
  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      children: [
        // Mood selection
        Text("What's your vibe right now?",
            style: AppTextStyles.h3),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: aiMoods.map((m) {
            final active = mood == m.id;
            return GestureDetector(
              onTap: () => onMood(m.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: (MediaQuery.of(context).size.width - 52) / 2,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: active
                      ? accent.withValues(alpha: 0.15)
                      : AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: active ? accent : AppColors.glassBorder,
                    width: active ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_moodIcon(m.icon), size: 22, color: accent),
                        const SizedBox(width: 8),
                        Text(m.label,
                            style: AppTextStyles.bodyPrimary
                                .copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(m.desc, style: AppTextStyles.caption),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        // Language
        Text('Preferred language', style: AppTextStyles.h3),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: aiLanguages.map((l) {
            final active = language == l.id;
            return GestureDetector(
              onTap: () => onLanguage(l.id),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? accent : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active ? accent : Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(l.label,
                    style: AppTextStyles.bodyPrimary.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : AppColors.textSecondary)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        // Custom text
        Text('Tell XAI more (optional)', style: AppTextStyles.h3),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: TextField(
            controller: controller,
            maxLines: 4,
            maxLength: 300,
            style: AppTextStyles.bodyPrimary,
            decoration: InputDecoration(
              hintText:
                  'e.g. I want a movie about time travel with a twist ending…',
              hintStyle: AppTextStyles.body,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // CTA
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: mood == null ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.backgroundCard,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100)),
            ),
            icon: const Icon(Icons.auto_awesome_rounded, size: 20),
            label: const Text('Get My Recommendations'),
          ),
        ),
      ],
    );
  }

  IconData _moodIcon(AiMoodIcon icon) {
    switch (icon) {
      case AiMoodIcon.smile:
        return Icons.sentiment_satisfied_rounded;
      case AiMoodIcon.heart:
        return Icons.favorite_rounded;
      case AiMoodIcon.brain:
        return Icons.psychology_rounded;
      case AiMoodIcon.flame:
        return Icons.local_fire_department_rounded;
      case AiMoodIcon.moon:
        return Icons.nightlight_rounded;
    }
  }
}

class _ResultsStage extends ConsumerWidget {
  const _ResultsStage({
    required this.mood,
    required this.text,
    required this.language,
    required this.onRetry,
  });

  final String mood;
  final String text;
  final String language;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = ref.watch(aiRecommendationProvider(
      (mood: mood, text: text, language: language),
    ));
    final accent = Theme.of(context).colorScheme.primary;

    return future.when(
      loading: () => _CinematicLoading(),
      error: (err, _) => _ErrorState(
        message: err.toString(),
        onRetry: () => ref.invalidate(aiRecommendationProvider(
          (mood: mood, text: text, language: language),
        )),
        onBack: onRetry,
      ),
      data: (recs) {
        if (recs.isEmpty) {
          return _ErrorState(
            message: 'No recommendations returned. Try a different mood.',
            onRetry: () => ref.invalidate(aiRecommendationProvider(
              (mood: mood, text: text, language: language),
            )),
            onBack: onRetry,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          itemCount: recs.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 18, color: accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Here's what XAI picked for you",
                        style: AppTextStyles.h2,
                      ),
                    ),
                  ],
                ),
              );
            }
            final rec = recs[i - 1];
            return _ResultCard(rec: rec, index: i - 1);
          },
        );
      },
    );
  }
}

class _ResultCard extends ConsumerWidget {
  const _ResultCard({required this.rec, required this.index});
  final AiRecommendation rec;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final matchColor = rec.match >= 95
        ? const Color(0xFF4ADE80)
        : rec.match >= 85
            ? const Color(0xFFFACC15)
            : const Color(0xFFFB923C);
    final inList = rec.id != null &&
        StorageActions.instance.isInWatchlist(rec.id!, rec.mediaType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: GestureDetector(
        onTap: () {
          if (rec.id != null) {
            context.go('/details/${rec.mediaType}/${rec.id}');
          }
        },
        child: Row(
          children: [
            // Poster
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: 80,
                height: 120,
                child: rec.poster.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: rec.poster,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: AppColors.backgroundElevated),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.backgroundElevated,
                          child: const Icon(Icons.movie_outlined,
                              color: AppColors.textMuted),
                        ),
                      )
                    : Container(
                        color: AppColors.backgroundElevated,
                        child: const Icon(Icons.movie_outlined,
                            color: AppColors.textMuted),
                      ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (index == 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('BEST PICK',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                          ),
                        Expanded(
                          child: Text(rec.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.h3),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('$rec.match% match',
                            style: AppTextStyles.label.copyWith(
                                color: matchColor, fontSize: 11)),
                        if (rec.year > 0) ...[
                          const SizedBox(width: 8),
                          Text('${rec.year}',
                              style: AppTextStyles.caption),
                        ],
                        if (rec.rating != null) ...[
                          const SizedBox(width: 8),
                          RatingBadge(rating: rec.rating!, compact: true),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(rec.reason,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (rec.id != null)
                          GestureDetector(
                            onTap: () => context.go(
                                '/watch/${rec.mediaType}/${rec.id}'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.play_arrow_rounded,
                                      size: 14, color: Colors.white),
                                  const SizedBox(width: 4),
                                  const Text('Watch',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        if (rec.id != null)
                          GestureDetector(
                            onTap: () async {
                              await StorageActions.instance.toggleWatchlist(
                                // Build a minimal MediaItem for the watchlist.
                                _recToMediaItem(rec),
                              );
                              bumpStorage(ref);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: inList
                                    ? accent.withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: inList
                                      ? accent
                                      : Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Icon(
                                inList ? Icons.check : Icons.add,
                                size: 16,
                                color: inList ? accent : Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CinematicLoading extends StatefulWidget {
  @override
  State<_CinematicLoading> createState() => _CinematicLoadingState();
}

class _CinematicLoadingState extends State<_CinematicLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orb;
  int _msgIndex = 0;

  static const _messages = [
    'Analyzing your mood vibes…',
    'Scanning through thousands of movies…',
    'Matching cinematic DNA patterns…',
    'Finding the perfect picks for you…',
    'Almost there, curating your list…',
    'Finalizing your 15 handpicked movies…',
  ];

  @override
  void initState() {
    super.initState();
    _orb = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return false;
      setState(() => _msgIndex = (_msgIndex + 1) % _messages.length);
      return true;
    });
  }

  @override
  void dispose() {
    _orb.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: Tween(begin: 0.8, end: 1.2).animate(
              CurvedAnimation(parent: _orb, curve: Curves.easeInOut),
            ),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.5),
                    blurRadius: 40,
                  ),
                ],
              ),
              child: Icon(Icons.auto_awesome_rounded,
                  size: 36, color: accent),
            ),
          ),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              _messages[_msgIndex],
              key: ValueKey(_msgIndex),
              style: AppTextStyles.bodyPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 56, color: AppColors.ratingMid),
            const SizedBox(height: 16),
            Text('Something went wrong', style: AppTextStyles.h2),
            const SizedBox(height: 8),
            Text(
              message.replaceFirst('Exception: ', ''),
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: onBack,
                  child: const Text('Go Back'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Helper to convert an AiRecommendation into a minimal MediaItem for the watchlist.
MediaItem _recToMediaItem(AiRecommendation rec) {
  return MediaItem(
    id: rec.id ?? 0,
    title: rec.title,
    releaseYear: rec.year > 0 ? rec.year.toString() : '',
    imageSrc: rec.poster,
    backdropSrc: rec.backdrop,
    overview: rec.reason,
    rating: rec.rating ?? 0,
    mediaType: rec.mediaType,
  );
}
