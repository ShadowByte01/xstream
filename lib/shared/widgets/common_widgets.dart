import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// A horizontally scrollable row of genre filter pills.
///
/// Mirrors the pill filters on the Movies / Series / Anime pages.
class GenrePills extends StatelessWidget {
  const GenrePills({
    super.key,
    required this.genres,
    required this.selectedId,
    required this.onSelected,
    this.allLabel = 'All',
  });

  final List<({int id, String name})> genres;
  final int? selectedId; // null = "All"
  final ValueChanged<int?> onSelected;
  final String allLabel;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: genres.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final bool isAll = i == 0;
          final bool active = isAll ? selectedId == null : selectedId == genres[i - 1].id;
          final label = isAll ? allLabel : genres[i - 1].name;
          return GestureDetector(
            onTap: () => onSelected(isAll ? null : genres[i - 1].id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? accent
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                      ? accent
                      : Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: AppTextStyles.bodyPrimary.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A centered circular loading indicator with an optional message.
class LoadingOverlay extends StatelessWidget {
  LoadingOverlay({super.key, this.message, this.size = 40});
  final String? message;
  final double size;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: accent,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 14),
            Text(message!, style: AppTextStyles.body),
          ],
        ],
      ),
    );
  }
}

/// A friendly empty-state for lists (history, watchlist, likes).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.h2, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!,
                  style: AppTextStyles.body, textAlign: TextAlign.center),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              _ActionPill(label: actionLabel!, onTap: onAction!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          label,
          style: AppTextStyles.button.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

/// A simple page header (title + optional back button) used on
/// Movies / Series / Anime / New & Popular / Search.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.showBack = false,
    this.onBack,
  });

  final String title;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          if (showBack) ...[
            GestureDetector(
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
              child: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              ),
            ),
          ],
          Text(title, style: AppTextStyles.h1),
        ],
      ),
    );
  }
}
