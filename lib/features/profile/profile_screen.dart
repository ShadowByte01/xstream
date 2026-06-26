import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/widgets/movie_card.dart';
import 'settings_sheet.dart';

/// Profile / "My Xstream" page.
///
/// Ports the web app's `Profile.jsx`: an avatar header, consent + privacy
/// info, and three tabs — Watch History, My List, Liked. A gear icon opens
/// the [SettingsSheet] (accent colour, autoplay, clear data).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    final watchlist = ref.watch(watchlistProvider);
    final likes = ref.watch(likesProvider);
    final ratings = ref.watch(ratingsProvider);
    final consent = ref.watch(consentProvider);
    final accent = Theme.of(context).colorScheme.primary;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              accent.withValues(alpha: 0.4),
                              accent,
                            ],
                          ),
                        ),
                        child: const Icon(Icons.person_rounded,
                            size: 32, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('My Xstream', style: AppTextStyles.h1),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.shield_rounded,
                                    size: 13, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'No sign-in · data stays on this device',
                                    style: AppTextStyles.caption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_rounded),
                        onPressed: () => _openSettings(context, ref),
                      ),
                    ],
                  ),
                ),
              ),
              if (ratings.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: accent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star_rounded, size: 18, color: accent),
                        const SizedBox(width: 8),
                        Text(
                          "You've rated ${ratings.length} title${ratings.length > 1 ? 's' : ''}",
                          style: AppTextStyles.bodyPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  child: TabBar(
                    tabs: [
                      _Tab(
                        icon: Icons.history_rounded,
                        label: 'History',
                        count: history.length,
                      ),
                      _Tab(
                        icon: Icons.playlist_add_check_rounded,
                        label: 'My List',
                        count: watchlist.length,
                      ),
                      _Tab(
                        icon: Icons.favorite_rounded,
                        label: 'Liked',
                        count: likes.length,
                      ),
                    ],
                    labelColor: accent,
                    unselectedLabelColor: AppColors.textMuted,
                    indicatorColor: accent,
                    indicatorSize: TabBarIndicatorSize.label,
                  ),
                ),
              ),
            ],
            body: TabBarView(
              children: [
                _GridTab(
                  items: history
                      .map((h) => h.toMediaItem().copyWith(progress: h.progress))
                      .toList(),
                  emptyIcon: Icons.play_circle_outline_rounded,
                  emptyTitle: 'No watch history yet',
                  emptySubtitle: 'Movies and series you watch will appear here.',
                  onRemove: history.isNotEmpty
                      ? (item) async {
                          await StorageActions.instance
                              .removeFromHistory(item.id, item.mediaType);
                          bumpStorage(ref);
                        }
                      : null,
                  onClear: history.isNotEmpty
                      ? () async {
                          await StorageActions.instance.clearHistory();
                          bumpStorage(ref);
                        }
                      : null,
                ),
                _GridTab(
                  items: watchlist,
                  emptyIcon: Icons.playlist_add_rounded,
                  emptyTitle: 'Your list is empty',
                  emptySubtitle: 'Add movies to watch later!',
                ),
                _GridTab(
                  items: likes,
                  emptyIcon: Icons.favorite_border_rounded,
                  emptyTitle: 'No liked titles yet',
                  emptySubtitle: 'Tap the heart on any title to like it.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SettingsSheet(),
    ).then((_) => bumpStorage(ref));
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.count,
  });

  final IconData icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count',
                  style: const TextStyle(fontSize: 11)),
            ),
          ],
        ],
      ),
    );
  }
}

class _GridTab extends StatelessWidget {
  const _GridTab({
    required this.items,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.onRemove,
    this.onClear,
  });

  final List<dynamic> items;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final void Function(dynamic)? onRemove;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyState(
        icon: emptyIcon,
        title: emptyTitle,
        subtitle: emptySubtitle,
        actionLabel: 'Browse',
        onAction: () => context.go('/'),
      );
    }

    return CustomScrollView(
      slivers: [
        if (onClear != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text('${items.length} title${items.length > 1 ? 's' : ''}',
                      style: AppTextStyles.caption),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text('Clear All'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.ratingLow,
                    ),
                  ),
                ],
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          sliver: SliverGrid(
            gridDelegate:
                const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 130,
              childAspectRatio: 0.52,
              crossAxisSpacing: 10,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final item = items[i];
                return MovieCard(
                  item: item as dynamic,
                  onRemove: onRemove != null ? () => onRemove!(item) : null,
                );
              },
              childCount: items.length,
            ),
          ),
        ),
      ],
    );
  }
}
