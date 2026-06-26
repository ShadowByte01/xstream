import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import 'package:xstream/core/theme/app_colors.dart' as ac;
import '../../core/theme/app_theme.dart';
import '../../shared/providers/app_providers.dart';

/// Bottom-sheet settings panel.
///
/// Ports the web app's `SettingsModal`: accent colour picker, autoplay
/// toggle, and a "clear all my data" action with confirmation.
class SettingsSheet extends ConsumerStatefulWidget {
  const SettingsSheet({super.key});

  @override
  ConsumerState<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends ConsumerState<SettingsSheet> {
  bool _confirmClear = false;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final autoplay = ref.watch(autoplayNextProvider);
    final currentHex = StorageService.I.accentColor;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.backgroundElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
            child: Row(
              children: [
                Text('Settings', style: AppTextStyles.h1),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                // ── Accent color ──
                Text('Accent Color', style: AppTextStyles.h3),
                const SizedBox(height: 4),
                Text('Personalize the Xstream theme',
                    style: AppTextStyles.body),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: ac.AppColors.accentSwatches.map((sw) {
                    final selected = currentHex.toLowerCase() ==
                        _colorToHex(sw.color).toLowerCase();
                    return GestureDetector(
                      onTap: () async {
                        await StorageActions.instance
                            .setAccent(_colorToHex(sw.color));
                        bumpStorage(ref);
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: sw.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: sw.color.withValues(alpha: 0.5),
                                        blurRadius: 16,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: selected
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 22)
                                : null,
                          ),
                          const SizedBox(height: 4),
                          Text(sw.name,
                              style: AppTextStyles.caption.copyWith(
                                  fontSize: 10, color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 28),
                // ── Playback ──
                Text('Playback', style: AppTextStyles.h3),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Auto-play next episode',
                                style: AppTextStyles.bodyPrimary),
                            Text(
                                'Automatically play the next episode for TV shows',
                                style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: autoplay,
                        activeColor: accent,
                        onChanged: (v) async {
                          await StorageActions.instance.setAutoplayNext(v);
                          bumpStorage(ref);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),
                // ── Privacy ──
                Text('Privacy & Data', style: AppTextStyles.h3),
                const SizedBox(height: 4),
                Text(
                  'All your history, list & ratings live only on this device. Clear them anytime.',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 12),
                if (!_confirmClear)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          setState(() => _confirmClear = true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ratingLow,
                        side: BorderSide(
                            color: AppColors.ratingLow.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Clear all my data'),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.ratingLow.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.ratingLow.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'This removes history, list, ratings & most-viewed data. Continue?',
                          style: AppTextStyles.body,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () =>
                                    setState(() => _confirmClear = false),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  await StorageActions.instance.wipeAll();
                                  bumpStorage(ref);
                                  if (context.mounted) Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.ratingLow,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Yes, clear it'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 28),
                // ── About ──
                Text('About', style: AppTextStyles.h3),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _aboutRow('Version', '1.0.0'),
                      _aboutRow('Built with', 'Flutter + Riverpod'),
                      _aboutRow('Account', 'No sign-in · on-device only'),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(k, style: AppTextStyles.body),
          const Spacer(),
          Text(v, style: AppTextStyles.bodyPrimary),
        ],
      ),
    );
  }

  String _colorToHex(Color c) {
    final r = (c.r * 255).round();
    final g = (c.g * 255).round();
    final b = (c.b * 255).round();
    return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }
}
