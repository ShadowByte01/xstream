import 'media_item.dart';

/// Full detail payload for a movie or TV show — everything the Details
/// and Watch screens need.
class MediaDetail {
  const MediaDetail({
    required this.id,
    required this.title,
    required this.mediaType,
    this.tagline = '',
    this.overview = '',
    this.posterPath,
    this.backdropPath,
    this.releaseDate = '',
    this.runtime,
    this.voteAverage = 0,
    this.voteCount = 0,
    this.status = '',
    this.budget = 0,
    this.revenue = 0,
    this.originalLanguage = '',
    this.originalTitle = '',
    this.spokenLanguages = const [],
    this.genres = const [],
    this.cast = const [],
    this.crew = const [],
    this.videos = const [],
    this.keywords = const [],
    this.productionCompanies = const [],
    this.networks = const [],
    this.createdBy = const [],
    this.seasons = const [],
    this.numberOfSeasons = 0,
    this.numberOfEpisodes = 0,
    this.flatrateProviders = const [],
    this.rentProviders = const [],
    this.buyProviders = const [],
  });

  final int id;
  final String title;
  final String mediaType;
  final String tagline;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final String releaseDate;
  final int? runtime;
  final double voteAverage;
  final int voteCount;
  final String status;
  final int budget;
  final int revenue;
  final String originalLanguage;
  final String originalTitle;
  final List<String> spokenLanguages;
  final List<Genre> genres;
  final List<CastMember> cast;
  final List<CrewMember> crew;
  final List<Video> videos;
  final List<Keyword> keywords;
  final List<ProductionCompany> productionCompanies;
  final List<ProductionCompany> networks;
  final List<String> createdBy;
  final List<SeasonInfo> seasons;
  final int numberOfSeasons;
  final int numberOfEpisodes;
  final List<WatchProvider> flatrateProviders;
  final List<WatchProvider> rentProviders;
  final List<WatchProvider> buyProviders;

  String get releaseYear =>
      releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '';

  String get runtimeLabel {
    if (runtime == null || runtime == 0) return '';
    final h = runtime! ~/ 60;
    final m = runtime! % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  String get posterUrl => posterPath != null
      ? 'https://image.tmdb.org/t/p/w500$posterPath'
      : '';
  String get backdropUrl => backdropPath != null
      ? 'https://image.tmdb.org/t/p/original$backdropPath'
      : '';

  List<CrewMember> get directors =>
      crew.where((c) => c.job == 'Director').toList();
  List<CrewMember> get writers => crew
      .where((c) =>
          c.job == 'Screenplay' ||
          c.job == 'Writer' ||
          c.department == 'Writing')
      .take(3)
      .toList();

  Video? get trailer =>
      videos.isEmpty ? null : videos.firstWhere(
        (v) => v.type == 'Trailer',
        orElse: () => videos.first,
      );

  /// Flatten into a [MediaItem] for cards / history.
  MediaItem toMediaItem() => MediaItem(
        id: id,
        title: title,
        releaseYear: releaseYear,
        imageSrc: posterUrl,
        backdropSrc: backdropUrl,
        overview: overview,
        rating: voteAverage,
        mediaType: mediaType,
        posterPath: posterPath,
        backdropPath: backdropPath,
      );

  factory MediaDetail.fromTmdb(
    Map<String, dynamic> json,
    String mediaType,
  ) {
    final credits = (json['credits'] as Map<String, dynamic>?) ?? {};
    final videosJson = (json['videos'] as Map<String, dynamic>?) ?? {};
    final keywordsJson = (json['keywords'] as Map<String, dynamic>?) ??
        (json['keywords'] as List?) ??
        {};
    final providers = (json['watch/providers'] as Map<String, dynamic>?) ??
        (json['watch_providers'] as Map<String, dynamic>?) ??
        {};
    final results = providers['results'] as Map<String, dynamic>?;
    final countryProviders =
        (results?['US'] ?? results?['IN'] ?? results?['AU']) as Map<String, dynamic>?;

    return MediaDetail(
      id: (json['id'] as num).toInt(),
      title: (json['title'] ?? json['name'] ?? 'Untitled') as String,
      mediaType: mediaType,
      tagline: (json['tagline'] ?? '') as String,
      overview: (json['overview'] ?? '') as String,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate: (json['release_date'] ?? json['first_air_date'] ?? '') as String,
      runtime: (json['runtime'] as num?)?.toInt() ??
          (json['episode_run_time'] as List?)?.firstOrNull as int?,
      voteAverage: ((json['vote_average'] ?? 0) as num).toDouble(),
      voteCount: ((json['vote_count'] ?? 0) as num).toInt(),
      status: (json['status'] ?? '') as String,
      budget: ((json['budget'] ?? 0) as num).toInt(),
      revenue: ((json['revenue'] ?? 0) as num).toInt(),
      originalLanguage: (json['original_language'] ?? '') as String,
      originalTitle: (json['original_title'] ?? json['original_name'] ?? '') as String,
      spokenLanguages: ((json['spoken_languages'] ?? []) as List)
          .map((l) => (l as Map)['english_name'] as String)
          .toList(),
      genres: ((json['genres'] ?? []) as List)
          .map((g) => Genre.fromJson(g as Map<String, dynamic>))
          .toList(),
      cast: ((credits['cast'] ?? []) as List)
          .map((c) => CastMember.fromJson(c as Map<String, dynamic>))
          .toList(),
      crew: ((credits['crew'] ?? []) as List)
          .map((c) => CrewMember.fromJson(c as Map<String, dynamic>))
          .toList(),
      videos: ((videosJson['results'] ?? []) as List)
          .map((v) => Video.fromJson(v as Map<String, dynamic>))
          .where((v) => v.key.isNotEmpty)
          .toList(),
      keywords: _parseKeywords(keywordsJson),
      productionCompanies: ((json['production_companies'] ?? []) as List)
          .map((c) => ProductionCompany.fromJson(c as Map<String, dynamic>))
          .toList(),
      networks: ((json['networks'] ?? []) as List)
          .map((c) => ProductionCompany.fromJson(c as Map<String, dynamic>))
          .toList(),
      createdBy: ((json['created_by'] ?? []) as List)
          .map((c) => (c as Map)['name'] as String)
          .toList(),
      seasons: ((json['seasons'] ?? []) as List)
          .map((s) => SeasonInfo.fromJson(s as Map<String, dynamic>))
          .where((s) => s.seasonNumber > 0)
          .toList(),
      numberOfSeasons: ((json['number_of_seasons'] ?? 0) as num).toInt(),
      numberOfEpisodes: ((json['number_of_episodes'] ?? 0) as num).toInt(),
      flatrateProviders: ((countryProviders?['flatrate'] ?? []) as List)
          .map((p) => WatchProvider.fromJson(p as Map<String, dynamic>))
          .toList(),
      rentProviders: ((countryProviders?['rent'] ?? []) as List)
          .map((p) => WatchProvider.fromJson(p as Map<String, dynamic>))
          .toList(),
      buyProviders: ((countryProviders?['buy'] ?? []) as List)
          .map((p) => WatchProvider.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  static List<Keyword> _parseKeywords(dynamic raw) {
    if (raw is Map && raw['keywords'] != null) {
      return (raw['keywords'] as List)
          .map((k) => Keyword.fromJson(k as Map<String, dynamic>))
          .toList();
    }
    if (raw is Map && raw['results'] != null) {
      return (raw['results'] as List)
          .map((k) => Keyword.fromJson(k as Map<String, dynamic>))
          .toList();
    }
    if (raw is List) {
      return raw
          .map((k) => Keyword.fromJson(k as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }
}

/// Season summary inside a TV detail payload.
class SeasonInfo {
  const SeasonInfo({
    required this.id,
    required this.seasonNumber,
    required this.name,
    this.episodeCount = 0,
    this.posterPath,
    this.airDate,
  });

  final int id;
  final int seasonNumber;
  final String name;
  final int episodeCount;
  final String? posterPath;
  final String? airDate;

  factory SeasonInfo.fromJson(Map<String, dynamic> json) => SeasonInfo(
        id: (json['id'] as num).toInt(),
        seasonNumber: (json['season_number'] as num).toInt(),
        name: (json['name'] ?? '') as String,
        episodeCount: ((json['episode_count'] ?? 0) as num).toInt(),
        posterPath: json['poster_path'] as String?,
        airDate: json['air_date'] as String?,
      );
}

extension on List {
  dynamic get firstOrNull => isEmpty ? null : first;
}
