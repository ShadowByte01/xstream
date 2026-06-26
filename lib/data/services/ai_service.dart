import 'package:dio/dio.dart';
import '../models/ai_recommendation.dart';
import 'api_client.dart';

/// Calls the Groq-backed AI recommendation endpoint on the Xstream backend.
///
/// The backend assembles the system + user prompt (so the model name and
/// prompt engineering live server-side) and returns a ready-to-render list
/// of [AiRecommendation], each enriched with TMDB poster/rating data.
class AiService {
  const AiService._();
  static final AiService instance = AiService._();

  final _api = ApiClient.instance;

  Future<List<AiRecommendation>> getRecommendations({
    required String mood,
    String customText = '',
    required String language,
  }) async {
    try {
      final data = await _api.get('/api/ai/recommend', query: {
        'mood': mood,
        'text': customText,
        'language': language,
      });

      final List raw = (data is List)
          ? data
          : (data['recommendations'] ??
              data['movies'] ??
              data['results'] ??
              const []) as List;

      return raw
          .map((r) => AiRecommendation.fromJson(r as Map<String, dynamic>))
          .where((r) => r.title.isNotEmpty)
          .take(15)
          .toList();
    } on DioException catch (e) {
      final msg = e.response?.data?['error']?['message'] ??
          e.response?.data?['message'] ??
          e.message ??
          'AI service is unavailable right now.';
      throw Exception(msg.toString());
    } catch (e) {
      throw Exception('Could not fetch recommendations. Try again.');
    }
  }
}
