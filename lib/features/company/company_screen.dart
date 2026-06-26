import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/tmdb_service.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/movie_card.dart';

/// Production company detail page.
///
/// Ports the web app's `Company.jsx`: logo, name, HQ, homepage link,
/// and a grid of movies produced by the studio.
class CompanyScreen extends ConsumerStatefulWidget {
  const CompanyScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends ConsumerState<CompanyScreen> {
  final _tmdb = TmdbService.instance;
  dynamic _company;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await _tmdb.companyDetails(widget.id);
      if (!mounted) return;
      setState(() {
        _company = c;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: LoadingOverlay(message: 'Loading studio…'),
      );
    }
    final c = _company;
    if (c == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Company not found.', style: AppTextStyles.body)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
            ),
          ),
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: c.logoUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: CachedNetworkImage(
                              imageUrl: c.logoUrl,
                              fit: BoxFit.contain,
                              placeholder: (_, __) => const SizedBox.shrink(),
                              errorWidget: (_, __, ___) => const SizedBox.shrink(),
                            ),
                          )
                        : Center(
                            child: Text(c.name[0],
                                style: AppTextStyles.h1),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name, style: AppTextStyles.h1),
                        Text('Production Studio',
                            style: AppTextStyles.label),
                        if (c.headquarters != null &&
                            c.headquarters!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  size: 13, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(c.headquarters!,
                                    style: AppTextStyles.caption,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (c.homepage != null && c.homepage!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: GestureDetector(
                  onTap: () => launchUrl(Uri.parse(c.homepage!)),
                  child: Row(
                    children: [
                      const Icon(Icons.open_in_new_rounded,
                          size: 14, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Text('Visit Official Website',
                          style: AppTextStyles.bodyPrimary
                              .copyWith(color: AppColors.accent)),
                    ],
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text('Produced by ${c.name}', style: AppTextStyles.h2),
            ),
          ),
          if (c.movies.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 130,
                  childAspectRatio: 0.52,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => MovieCard(item: c.movies[i]),
                  childCount: c.movies.length,
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No movies found for this studio.',
                    style: AppTextStyles.body),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}
