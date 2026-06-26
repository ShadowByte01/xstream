import 'media_item.dart';

/// Full person (actor/crew) details + filmography.
class Person {
  const Person({
    required this.id,
    required this.name,
    this.profilePath,
    this.biography = '',
    this.birthday,
    this.placeOfBirth,
    this.knownForDepartment = '',
    this.gender = 0,
    this.movieCredits = const [],
    this.tvCredits = const [],
  });

  final int id;
  final String name;
  final String? profilePath;
  final String biography;
  final String? birthday;
  final String? placeOfBirth;
  final String knownForDepartment;
  final int gender; // 1=female, 2=male
  final List<MediaItem> movieCredits;
  final List<MediaItem> tvCredits;

  String get profileUrl => profilePath != null
      ? 'https://image.tmdb.org/t/p/w500$profilePath'
      : '';

  String get genderLabel {
    switch (gender) {
      case 1:
        return 'Female';
      case 2:
        return 'Male';
      default:
        return 'Other';
    }
  }

  /// Merged + de-duplicated filmography sorted by popularity.
  List<MediaItem> get knownFor {
    final seen = <int>{};
    final merged = [...movieCredits, ...tvCredits]
        .where((m) => m.posterPath != null && seen.add(m.id))
        .toList();
    merged.sort((a, b) => b.rating.compareTo(a.rating));
    return merged.take(20).toList();
  }

  factory Person.fromJson(Map<String, dynamic> json) {
    final movieCredits = (json['movie_credits'] as Map?) ?? {};
    final tvCredits = (json['tv_credits'] as Map?) ?? {};
    return Person(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '') as String,
      profilePath: json['profile_path'] as String?,
      biography: (json['biography'] ?? '') as String,
      birthday: json['birthday'] as String?,
      placeOfBirth: json['place_of_birth'] as String?,
      knownForDepartment: (json['known_for_department'] ?? '') as String,
      gender: ((json['gender'] ?? 0) as num).toInt(),
      movieCredits: ((movieCredits['cast'] ?? []) as List)
          .map((m) => MediaItem.fromTmdb(m as Map<String, dynamic>, 'movie'))
          .toList(),
      tvCredits: ((tvCredits['cast'] ?? []) as List)
          .map((m) => MediaItem.fromTmdb(m as Map<String, dynamic>, 'tv'))
          .toList(),
    );
  }
}

/// Production company details + its film catalogue.
class Company {
  const Company({
    required this.id,
    required this.name,
    this.logoPath,
    this.headquarters,
    this.homepage,
    this.movies = const [],
  });

  final int id;
  final String name;
  final String? logoPath;
  final String? headquarters;
  final String? homepage;
  final List<MediaItem> movies;

  String get logoUrl => logoPath != null
      ? 'https://image.tmdb.org/t/p/w500$logoPath'
      : '';

  factory Company.fromJson(
    Map<String, dynamic> json, [
    List<MediaItem> movies = const [],
  ]) =>
      Company(
        id: (json['id'] as num).toInt(),
        name: (json['name'] ?? '') as String,
        logoPath: json['logo_path'] as String?,
        headquarters: json['headquarters'] as String?,
        homepage: json['homepage'] as String?,
        movies: movies,
      );
}
