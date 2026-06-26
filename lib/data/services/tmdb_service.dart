import '../models/media_item.dart';
import '../models/media_detail.dart';
import '../models/person.dart';
import 'api_client.dart';

/// Wraps every TMDB endpoint the app needs.
///
/// All calls are proxied through the Xstream backend (`/api/tmdb/*`) so
/// the TMDB API key never reaches the device. The backend also applies
/// a short in-memory cache to absorb Render cold-start latency.
class TmdbService {
  const TmdbService._();
  static const TmdbService instance = TmdbService._();

  final _api = ApiClient.instance;

  // ── Lists ──

  Future<List<MediaItem>> trendingMovies() =>
      _getList('/api/tmdb/trending/movie/day');

  Future<List<MediaItem>> topRatedMovies() =>
      _getList('/api/tmdb/movie/top_rated');

  Future<List<MediaItem>> upcomingMovies() =>
      _getList('/api/tmdb/movie/upcoming');

  Future<List<MediaItem>> nowPlaying() =>
      _getList('/api/tmdb/movie/now_playing');

  Future<List<MediaItem>> actionMovies() =>
      _discoverMovies(withGenres: '28');

  Future<List<MediaItem>> animationMovies() =>
      _discoverMovies(withGenres: '16');

  Future<List<MediaItem>> trendingTv() =>
      _getList('/api/tmdb/trending/tv/week', defaultType: 'tv');

  Future<List<MediaItem>> trendingAll() =>
      _getList('/api/tmdb/trending/all/week');

  Future<List<MediaItem>> popularTv() =>
      _getList('/api/tmdb/tv/popular', defaultType: 'tv');

  Future<List<MediaItem>> topRatedTv() =>
      _getList('/api/tmdb/tv/top_rated', defaultType: 'tv');

  // ── Genres ──

  Future<List<Genre>> genreList(String type) async {
    final data = await _api.get('/api/tmdb/genre/$type/list');
    final genres = (data['genres'] as List?) ?? const [];
    return genres
        .map((g) => Genre.fromJson(g as Map<String, dynamic>))
        .toList();
  }

  Future<List<MediaItem>> discoverByGenre(
    String type,
    String genreId, {
    int page = 1,
  }) async {
    final data = await _api.get('/api/tmdb/discover/$type', query: {
      'with_genres': genreId,
      'sort_by': 'popularity.desc',
      'page': page,
    });
    final results = (data['results'] as List?) ?? const [];
    return results
        .map((m) => MediaItem.fromTmdb(m as Map<String, dynamic>, type))
        .where((m) => m.posterPath != null)
        .toList();
  }

  Future<List<MediaItem>> _discoverMovies({required String withGenres}) async {
    final data = await _api.get('/api/tmdb/discover/movie',
        query: {'with_genres': withGenres});
    final results = (data['results'] as List?) ?? const [];
    return results
        .map((m) => MediaItem.fromTmdb(m as Map<String, dynamic>, 'movie'))
        .toList();
  }

  // ── Details ──

  Future<MediaDetail> details(String type, int id) async {
    final append = type == 'movie'
        ? 'credits,videos,reviews,keywords,release_dates,watch/providers'
        : 'credits,videos,reviews,keywords,content_ratings,watch/providers';
    final data = await _api.get('/api/tmdb/$type/$id', query: {
      'append_to_response': append,
    });
    return MediaDetail.fromTmdb(data as Map<String, dynamic>, type);
  }

  Future<List<MediaItem>> similar(String type, int id) async {
    final data = await _api.get('/api/tmdb/$type/$id/similar');
    final results = (data['results'] as List?) ?? const [];
    return results
        .map((m) => MediaItem.fromTmdb(m as Map<String, dynamic>, type))
        .where((m) => m.posterPath != null)
        .take(10)
        .toList();
  }

  Future<List<Video>> videos(String type, int id) async {
    final data = await _api.get('/api/tmdb/$type/$id/videos');
    final results = (data['results'] as List?) ?? const [];
    return results
        .map((v) => Video.fromJson(v as Map<String, dynamic>))
        .where((v) => v.key.isNotEmpty)
        .toList();
  }

  Future<List<Keyword>> keywords(String type, int id) async {
    final data = await _api.get('/api/tmdb/$type/$id/keywords');
    final raw = data['keywords'] ?? data['results'] ?? const [];
    return (raw as List)
        .map((k) => Keyword.fromJson(k as Map<String, dynamic>))
        .toList();
  }

  // ── Search ──

  Future<List<MediaItem>> searchMulti(String query) async {
    final data = await _api.get('/api/tmdb/search/multi', query: {'query': query});
    final results = (data['results'] as List?) ?? const [];
    return results
        .where((r) =>
            (r as Map)['media_type'] == 'movie' ||
            r['media_type'] == 'tv')
        .map((m) => MediaItem.fromTmdb(m as Map<String, dynamic>))
        .where((m) => m.posterPath != null || m.backdropPath != null)
        .toList();
  }

  Future<({List<MediaItem> results, int totalPages})> searchMultiPaginated(
    String query, {
    int page = 1,
  }) async {
    final data = await _api.get('/api/tmdb/search/multi', query: {
      'query': query,
      'page': page,
    });
    final results = (data['results'] as List?) ?? const [];
    final filtered = results
        .where((r) =>
            (r as Map)['media_type'] == 'movie' ||
            r['media_type'] == 'tv')
        .map((m) => MediaItem.fromTmdb(m as Map<String, dynamic>))
        .where((m) => m.posterPath != null)
        .toList();
    return (results: filtered, totalPages: (data['total_pages'] ?? 0) as int);
  }

  // ── People & companies ──

  Future<Person> personDetails(int id) async {
    final data = await _api.get('/api/tmdb/person/$id', query: {
      'append_to_response': 'movie_credits,tv_credits',
    });
    return Person.fromJson(data as Map<String, dynamic>);
  }

  Future<Company> companyDetails(int id) async {
    final comp = await _api.get('/api/tmdb/company/$id');
    final moviesData = await _api.get('/api/tmdb/discover/movie', query: {
      'with_companies': id,
      'sort_by': 'popularity.desc',
    });
    final movies = ((moviesData['results'] as List?) ?? const [])
        .map((m) => MediaItem.fromTmdb(m as Map<String, dynamic>, 'movie'))
        .where((m) => m.posterPath != null)
        .toList();
    return Company.fromJson(comp as Map<String, dynamic>, movies);
  }

  // ── Helpers ──

  Future<List<MediaItem>> _getList(
    String path, {
    String? defaultType,
  }) async {
    final data = await _api.get(path);
    final results = (data['results'] as List?) ?? const [];
    return results
        .take(15)
        .map((m) => MediaItem.fromTmdb(m as Map<String, dynamic>, defaultType))
        .toList();
  }
}
