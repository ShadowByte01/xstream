import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/person.dart';
import '../../data/services/tmdb_service.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/movie_card.dart';

/// Person (actor / crew) detail page with filmography.
///
/// Ports the web app's `Person.jsx`.
class PersonScreen extends ConsumerStatefulWidget {
  const PersonScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<PersonScreen> createState() => _PersonScreenState();
}

class _PersonScreenState extends ConsumerState<PersonScreen> {
  final _tmdb = TmdbService.instance;
  Person? _person;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await _tmdb.personDetails(widget.id);
      if (!mounted) return;
      setState(() {
        _person = p;
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
        body: LoadingOverlay(message: 'Loading profile…'),
      );
    }
    final p = _person;
    if (p == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Person not found.', style: AppTextStyles.body)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background,
            leading: _backBtn(context),
            title: Text(p.name, style: AppTextStyles.h3),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 130,
                      child: AspectRatio(
                        aspectRatio: 2 / 3,
                        child: p.profileUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: p.profileUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                    color: AppColors.backgroundCard),
                                errorWidget: (_, __, ___) => Container(
                                  color: AppColors.backgroundCard,
                                  child: const Icon(Icons.person,
                                      size: 50, color: AppColors.textMuted),
                                ),
                              )
                            : Container(
                                color: AppColors.backgroundCard,
                                child: const Icon(Icons.person,
                                    size: 50, color: AppColors.textMuted),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: AppTextStyles.h1),
                        const SizedBox(height: 12),
                        if (p.knownForDepartment.isNotEmpty)
                          _infoRow('Known For', p.knownForDepartment),
                        if (p.gender > 0) _infoRow('Gender', p.genderLabel),
                        if (p.birthday != null)
                          _infoRow('Birthday', p.birthday!),
                        if (p.placeOfBirth != null &&
                            p.placeOfBirth!.isNotEmpty)
                          _infoRow('Birthplace', p.placeOfBirth!),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (p.biography.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Biography', style: AppTextStyles.h2),
                    const SizedBox(height: 8),
                    Text(p.biography, style: AppTextStyles.body),
                  ],
                ),
              ),
            ),
          if (p.knownFor.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Text('Known For', style: AppTextStyles.h2),
              ),
            ),
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
                  (context, i) => MovieCard(item: p.knownFor[i]),
                  childCount: p.knownFor.length,
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _backBtn(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pop(),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Icon(Icons.arrow_back_ios_new_rounded, size: 18),
      ),
    );
  }

  Widget _infoRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: AppTextStyles.label),
          const SizedBox(height: 2),
          Text(v, style: AppTextStyles.bodyPrimary),
        ],
      ),
    );
  }
}
