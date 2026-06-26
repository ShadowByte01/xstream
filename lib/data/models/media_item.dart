/// A lightweight media item used in carousels, grids and cards.
///
/// Mirrors the `toCard()` shape from the web app's `lib/media.js`.
class MediaItem {
  const MediaItem({
    required this.id,
    required this.title,
    this.releaseYear = '',
    this.imageSrc = '',
    this.backdropSrc = '',
    this.overview = '',
    this.rating = 0,
    this.mediaType = 'movie',
    this.posterPath,
    this.backdropPath,
    this.progress,
    this.isMostViewed = false,
  });

  final int id;
  final String title;
  final String releaseYear;
  final String imageSrc;
  final String backdropSrc;
  final String overview;
  final double rating;
  final String mediaType; // 'movie' | 'tv'
  final String? posterPath;
  final String? backdropPath;
  final int? progress; // 0-100, for "Continue Watching"
  final bool isMostViewed;

  MediaItem copyWith({
    int? id,
    String? title,
    String? releaseYear,
    String? imageSrc,
    String? backdropSrc,
    String? overview,
    double? rating,
    String? mediaType,
    String? posterPath,
    String? backdropPath,
    int? progress,
    bool? isMostViewed,
  }) {
    return MediaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      releaseYear: releaseYear ?? this.releaseYear,
      imageSrc: imageSrc ?? this.imageSrc,
      backdropSrc: backdropSrc ?? this.backdropSrc,
      overview: overview ?? this.overview,
      rating: rating ?? this.rating,
      mediaType: mediaType ?? this.mediaType,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      progress: progress ?? this.progress,
      isMostViewed: isMostViewed ?? this.isMostViewed,
    );
  }

  factory MediaItem.fromTmdb(Map<String, dynamic> json, [String? defaultType]) {
    final releaseDate = (json['release_date'] ?? json['first_air_date'] ?? '') as String;
    return MediaItem(
      id: (json['id'] as num).toInt(),
      title: (json['title'] ?? json['name'] ?? json['original_name'] ?? 'Untitled') as String,
      releaseYear: releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '',
      imageSrc: _img(json['poster_path']),
      backdropSrc: _img(json['backdrop_path'], 'original'),
      overview: (json['overview'] ?? '') as String,
      rating: ((json['vote_average'] ?? 0) as num).toDouble(),
      mediaType: (json['media_type'] ?? defaultType ?? _inferType(json)) as String,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
    );
  }

  static String _img(String? path, [String size = 'w500']) {
    if (path == null || path.isEmpty) return '';
    return 'https://image.tmdb.org/t/p/$size$path';
  }

  static String _inferType(Map<String, dynamic> json) {
    if (json['title'] != null) return 'movie';
    if (json['name'] != null) return 'tv';
    return 'movie';
  }
}

/// A genre tag.
class Genre {
  const Genre({required this.id, required this.name});
  final int id;
  final String name;

  factory Genre.fromJson(Map<String, dynamic> json) =>
      Genre(id: (json['id'] as num).toInt(), name: json['name'] as String);
}

/// A YouTube video (trailer / teaser / clip) attached to a title.
class Video {
  const Video({
    required this.id,
    required this.key,
    required this.name,
    required this.type,
    this.official = false,
    this.publishedAt,
  });

  final String id;
  final String key;
  final String name;
  final String type;
  final bool official;
  final String? publishedAt;

  factory Video.fromJson(Map<String, dynamic> json) => Video(
        id: json['id'] as String,
        key: json['key'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        official: (json['official'] ?? false) as bool,
        publishedAt: json['published_at'] as String?,
      );
}

/// A cast member entry on the Details page.
class CastMember {
  const CastMember({
    required this.id,
    required this.name,
    this.character = '',
    this.profilePath,
  });

  final int id;
  final String name;
  final String character;
  final String? profilePath;

  factory CastMember.fromJson(Map<String, dynamic> json) => CastMember(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        character: (json['character'] ?? '') as String,
        profilePath: json['profile_path'] as String?,
      );
}

/// A crew member (director / writer).
class CrewMember {
  const CrewMember({
    required this.id,
    required this.name,
    required this.job,
    this.department = '',
  });

  final int id;
  final String name;
  final String job;
  final String department;

  factory CrewMember.fromJson(Map<String, dynamic> json) => CrewMember(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        job: (json['job'] ?? '') as String,
        department: (json['department'] ?? '') as String,
      );
}

/// A production company.
class ProductionCompany {
  const ProductionCompany({
    required this.id,
    required this.name,
    this.logoPath,
  });

  final int id;
  final String name;
  final String? logoPath;

  factory ProductionCompany.fromJson(Map<String, dynamic> json) =>
      ProductionCompany(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        logoPath: json['logo_path'] as String?,
      );
}

/// A "where to watch" provider entry.
class WatchProvider {
  const WatchProvider({
    required this.id,
    required this.name,
    this.logoPath,
  });

  final int id;
  final String name;
  final String? logoPath;

  factory WatchProvider.fromJson(Map<String, dynamic> json) => WatchProvider(
        id: (json['provider_id'] as num).toInt(),
        name: json['provider_name'] as String,
        logoPath: json['logo_path'] as String?,
      );
}

/// A keyword tag.
class Keyword {
  const Keyword({required this.id, required this.name});
  final int id;
  final String name;

  factory Keyword.fromJson(Map<String, dynamic> json) =>
      Keyword(id: (json['id'] as num).toInt(), name: json['name'] as String);
}
