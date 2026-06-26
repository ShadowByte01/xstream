/// A single AI-generated movie recommendation (from the Groq LLM).
class AiRecommendation {
  const AiRecommendation({
    required this.title,
    required this.year,
    required this.match,
    required this.reason,
    this.id,
    this.mediaType = 'movie',
    this.poster = '',
    this.backdrop = '',
    this.rating,
    this.overview = '',
    this.genres = const [],
    this.runtime,
  });

  final String title;
  final int year;
  final int match; // 80–99
  final String reason;
  final int? id;
  final String mediaType;
  final String poster;
  final String backdrop;
  final double? rating;
  final String overview;
  final List<String> genres;
  final int? runtime;

  factory AiRecommendation.fromJson(Map<String, dynamic> json) {
    return AiRecommendation(
      title: (json['title'] ?? 'Untitled') as String,
      year: (json['year'] as num?)?.toInt() ?? 0,
      match: (json['match'] as num?)?.toInt() ?? 80,
      reason: (json['reason'] ?? '') as String,
      id: (json['id'] as num?)?.toInt(),
      mediaType: (json['media_type'] ?? 'movie') as String,
      poster: (json['poster'] ?? '') as String,
      backdrop: (json['backdrop'] ?? '') as String,
      rating: (json['rating'] as num?)?.toDouble(),
      overview: (json['overview'] ?? '') as String,
      genres: (json['genres'] as List?)
              ?.map((g) => g.toString())
              .toList() ??
          const [],
      runtime: (json['runtime'] as num?)?.toInt(),
    );
  }
}

/// Mood options for the AI recommender — mirrors the web app's `MOODS`.
class AiMood {
  const AiMood({
    required this.id,
    required this.label,
    required this.desc,
    required this.icon,
  });

  final String id;
  final String label;
  final String desc;
  final AiMoodIcon icon;
}

enum AiMoodIcon { smile, heart, brain, flame, moon }

const List<AiMood> aiMoods = [
  AiMood(id: 'feel-good', label: 'Feel Good', desc: 'Uplifting, heartwarming, joyful', icon: AiMoodIcon.smile),
  AiMood(id: 'emotional', label: 'Emotional', desc: 'Deep, moving, tearjerking', icon: AiMoodIcon.heart),
  AiMood(id: 'mind-bending', label: 'Mind-Bending', desc: 'Twists, psychological, mysterious', icon: AiMoodIcon.brain),
  AiMood(id: 'adrenaline', label: 'Adrenaline', desc: 'Action-packed, intense, thrilling', icon: AiMoodIcon.flame),
  AiMood(id: 'chill', label: 'Chill & Cozy', desc: 'Relaxing, lighthearted, easy-watch', icon: AiMoodIcon.moon),
];

const List<AiLanguage> aiLanguages = [
  AiLanguage(id: 'en', label: 'English'),
  AiLanguage(id: 'hi', label: 'Hindi'),
  AiLanguage(id: 'ko', label: 'Korean'),
  AiLanguage(id: 'es', label: 'Spanish'),
  AiLanguage(id: 'ja', label: 'Japanese'),
  AiLanguage(id: 'fr', label: 'French'),
];

class AiLanguage {
  const AiLanguage({required this.id, required this.label});
  final String id;
  final String label;
}
