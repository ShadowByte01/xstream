# Backend API Reference

This document describes the HTTP API exposed by the Xstream backend proxy
(`backend/` folder). The backend is a thin Node.js/Express app whose only
purpose is to **hide the TMDB and Groq API keys** behind a CORS-friendly
proxy. It stores **no per-user state** — no database, no sessions, no cookies.

- **Base URL**: whatever you deploy to (e.g. `https://xstream-api.onrender.com`).
- **Content-Type**: `application/json` for all responses.
- **Auth**: none. The backend is publicly callable, but it only forwards to
  TMDB (read-only) and Groq (free tier). There's nothing to abuse.
- **Rate limiting**: none on our side. TMDB rate-limits at ~50 req/sec per
  key; Groq's free tier has its own limits.

> 📌 The Flutter app calls this API via [`ApiClient`](../lib/data/services/api_client.dart)
> (a Dio singleton) and [`TmdbService`](../lib/data/services/tmdb_service.dart)
> / [`AiService`](../lib/data/services/ai_service.dart).

---

## 📋 Table of Contents

1. [Health](#health)
2. [TMDB Proxy (`/api/tmdb/*`)](#tmdb-proxy)
3. [AI Recommendations (`/api/ai/recommend`)](#ai-recommendations)
4. [Error Responses](#error-responses)
5. [Caching](#caching)
6. [CORS](#cors)
7. [Examples](#examples)

---

## Health

### `GET /api/health`

Returns the service status plus the reachability of upstream APIs. Used by
Render's uptime checks and keep-alive pingers (see
[`DEPLOYMENT.md`](./DEPLOYMENT.md#keep-alive-ping-for-render-free-tier)).

#### Request

```http
GET /api/health HTTP/1.1
Host: xstream-api.onrender.com
```

No query parameters, no auth.

#### Response — `200 OK`

```json
{
  "status": "ok",
  "tmdb": true,
  "groq": true,
  "uptime": 142.37,
  "version": "1.0.0",
  "timestamp": "2026-06-26T14:32:11.872Z"
}
```

| Field       | Type      | Meaning                                                 |
| :--------- | :-------- | :------------------------------------------------------ |
| `status`   | `string`  | `"ok"` if the service is up, `"degraded"` if any upstream is unreachable |
| `tmdb`     | `boolean` | `true` if the last TMDB probe succeeded (cached for 60s) |
| `groq`     | `boolean` | `true` if the last Groq probe succeeded (cached for 60s) |
| `uptime`   | `number`  | Process uptime in seconds                               |
| `version`  | `string`  | Backend version (semver)                                |
| `timestamp`| `string`  | ISO-8601 server time                                    |

#### Example

```bash
curl https://xstream-api.onrender.com/api/health
```

---

## TMDB Proxy

Every path under `/api/tmdb/*` is forwarded to `https://api.themoviedb.org/3/*`
with the `api_key` query parameter appended. The response is the verbatim
TMDB JSON payload.

### URL mapping

| Xstream backend path                         | TMDB API path                                   |
| :------------------------------------------- | :---------------------------------------------- |
| `GET /api/tmdb/trending/movie/day`           | `/trending/movie/day`                            |
| `GET /api/tmdb/trending/tv/week`             | `/trending/tv/week`                              |
| `GET /api/tmdb/trending/all/week`            | `/trending/all/week`                             |
| `GET /api/tmdb/movie/top_rated`              | `/movie/top_rated`                               |
| `GET /api/tmdb/movie/upcoming`               | `/movie/upcoming`                                |
| `GET /api/tmdb/movie/now_playing`            | `/movie/now_playing`                             |
| `GET /api/tmdb/tv/popular`                   | `/tv/popular`                                    |
| `GET /api/tmdb/tv/top_rated`                 | `/tv/top_rated`                                  |
| `GET /api/tmdb/genre/{movie\|tv}/list`       | `/genre/{movie\|tv}/list`                        |
| `GET /api/tmdb/discover/movie`               | `/discover/movie`                                |
| `GET /api/tmdb/discover/tv`                  | `/discover/tv`                                   |
| `GET /api/tmdb/movie/{id}`                   | `/movie/{id}`                                    |
| `GET /api/tmdb/tv/{id}`                      | `/tv/{id}`                                       |
| `GET /api/tmdb/movie/{id}/similar`           | `/movie/{id}/similar`                            |
| `GET /api/tmdb/tv/{id}/similar`              | `/tv/{id}/similar`                               |
| `GET /api/tmdb/movie/{id}/videos`            | `/movie/{id}/videos`                             |
| `GET /api/tmdb/tv/{id}/videos`               | `/tv/{id}/videos`                                |
| `GET /api/tmdb/movie/{id}/keywords`          | `/movie/{id}/keywords`                           |
| `GET /api/tmdb/tv/{id}/keywords`             | `/tv/{id}/keywords`                              |
| `GET /api/tmdb/search/multi`                 | `/search/multi`                                  |
| `GET /api/tmdb/person/{id}`                  | `/person/{id}`                                   |
| `GET /api/tmdb/company/{id}`                 | `/company/{id}`                                  |

### Query parameters

Any query parameters you send are forwarded to TMDB **as-is**, plus the
implicit `api_key`. Common ones:

| Parameter           | Used by                                  | Example                          |
| :------------------ | :--------------------------------------- | :------------------------------- |
| `page`              | list / discover / search endpoints        | `?page=2`                        |
| `query`             | `/search/multi`                          | `?query=inception`               |
| `with_genres`       | `/discover/{movie\|tv}`                  | `?with_genres=28` (Action)        |
| `with_companies`    | `/discover/movie`                        | `?with_companies=2` (Paramount)   |
| `sort_by`           | `/discover/*`                            | `?sort_by=popularity.desc`       |
| `append_to_response`| `/movie/{id}` and `/tv/{id}`             | `?append_to_response=credits,videos,keywords,watch/providers` |

### Response

The verbatim TMDB response — see
[TMDB's official docs](https://developer.themoviedb.org/reference/intro)
for the schema of each endpoint. Examples below.

---

### Examples — TMDB

#### Trending movies (today)

```bash
curl 'https://xstream-api.onrender.com/api/tmdb/trending/movie/day'
```

```json
{
  "page": 1,
  "results": [
    {
      "adult": false,
      "backdrop_path": "/abc123.jpg",
      "id": 693134,
      "title": "Dune: Part Two",
      "original_language": "en",
      "original_title": "Dune: Part Two",
      "overview": "Follow the mythic journey…",
      "poster_path": "/1pdf.jpg",
      "media_type": "movie",
      "genre_ids": [878, 12],
      "popularity": 247.8,
      "release_date": "2024-02-27",
      "video": false,
      "vote_average": 8.2,
      "vote_count": 4521
    }
  ],
  "total_pages": 10,
  "total_results": 200
}
```

#### Movie details with appended responses

```bash
curl 'https://xstream-api.onrender.com/api/tmdb/movie/693134?append_to_response=credits,videos,keywords,watch/providers'
```

Returns the standard TMDB movie response plus `credits`, `videos`,
`keywords`, and `watch/providers` blocks. The Flutter app's `MediaDetail.fromTmdb`
parses all of these.

#### Search with pagination

```bash
curl 'https://xstream-api.onrender.com/api/tmdb/search/multi?query=batman&page=2'
```

#### Discover by genre

```bash
curl 'https://xstream-api.onrender.com/api/tmdb/discover/movie?with_genres=28&sort_by=popularity.desc&page=1'
```

#### Person with filmography

```bash
curl 'https://xstream-api.onrender.com/api/tmdb/person/138?append_to_response=movie_credits,tv_credits'
```

---

## AI Recommendations

### `GET /api/ai/recommend`

Returns 15 AI-curated movie picks for the given mood, free-text, and language.
The backend assembles the system + user prompt and calls
**Groq's `llama-3.3-70b-versatile`** model. Each recommendation is enriched
with TMDB poster/rating data before being returned.

#### Request

| Parameter  | Type   | Required | Description                                              |
| :--------- | :----- | :------: | :------------------------------------------------------- |
| `mood`     | string | ✅       | One of: `feel-good`, `emotional`, `mind-bending`, `adrenaline`, `chill` |
| `text`     | string | ❌       | Free-text additional context (e.g. "something with a twist ending"). URL-encode if needed. |
| `language` | string | ✅       | ISO 639-1 code: `en`, `hi`, `ko`, `es`, `ja`, `fr`         |

```http
GET /api/ai/recommend?mood=feel-good&text=&language=en HTTP/1.1
Host: xstream-api.onrender.com
```

#### Response — `200 OK`

```json
[
  {
    "title": "The Peanut Butter Falcon",
    "year": 2019,
    "match": 94,
    "reason": "A heartwarming adventure about friendship and following your dreams.",
    "id": 501170,
    "media_type": "movie",
    "poster": "https://image.tmdb.org/t/p/w500/xxxxx.jpg",
    "backdrop": "https://image.tmdb.org/t/p/original/yyyyy.jpg",
    "rating": 8.1,
    "overview": "A young man with Down syndrome escapes…",
    "genres": ["Adventure", "Comedy", "Drama"],
    "runtime": 93
  },
  {
    "title": "Little Miss Sunshine",
    "year": 2006,
    "match": 92,
    "reason": "A dysfunctional family road trip that's both hilarious and tender.",
    "id": 46719,
    "media_type": "movie",
    "poster": "https://image.tmdb.org/t/p/w500/zzzz.jpg",
    "backdrop": "https://image.tmdb.org/t/p/original/wwww.jpg",
    "rating": 7.8,
    "overview": "A family determined to get their young daughter…",
    "genres": ["Comedy", "Drama"],
    "runtime": 101
  }
]
```

The response is always a JSON array of up to 15 objects. The Flutter app
parses each with `AiRecommendation.fromJson` and tolerates missing fields
with sensible defaults.

##### Fields

| Field        | Type            | Notes                                                    |
| :----------- | :-------------- | :------------------------------------------------------- |
| `title`      | string          | Always present. Untitled entries are filtered out client-side. |
| `year`       | integer         | Release year. `0` if unknown.                            |
| `match`      | integer (80–99) | Match percentage, generated by the LLM.                  |
| `reason`     | string          | One-sentence justification. May be empty.                |
| `id`         | integer?        | TMDB movie ID if the backend found a match. `null` if not found. |
| `media_type` | string          | Always `"movie"` for now (TV recommendations are planned). |
| `poster`     | string          | TMDB poster URL. Empty string if not found.              |
| `backdrop`   | string          | TMDB backdrop URL. Empty string if not found.            |
| `rating`     | number?         | TMDB vote average (0–10). `null` if not found.           |
| `overview`   | string          | TMDB overview. Empty if not found.                       |
| `genres`     | string[]        | TMDB genre names. Empty array if not found.              |
| `runtime`    | integer?        | Runtime in minutes. `null` if not found.                 |

#### Errors

| Status | Cause                                            | Body                                                |
| :----- | :----------------------------------------------- | :-------------------------------------------------- |
| 400    | Missing or invalid `mood` / `language`           | `{"error": {"message": "Invalid mood"}}`            |
| 429    | Groq rate-limit hit                              | `{"error": {"message": "Groq rate limit exceeded. Try again in a minute."}}` |
| 500    | Groq returned malformed JSON or a non-200        | `{"error": {"message": "AI service error: <details>"}}` |
| 503    | Groq unreachable (network / outage)              | `{"error": {"message": "AI service is unavailable right now."}}` |

#### Example

```bash
curl 'https://xstream-api.onrender.com/api/ai/recommend?mood=adrenaline&text=heist&language=en'
```

#### How it works (backend pseudocode)

```text
1. Validate mood ∈ {feel-good, emotional, mind-bending, adrenaline, chill}
   and language ∈ {en, hi, ko, es, ja, fr}.
2. Build the system prompt:
   "You are XAI, a movie recommendation engine. Return 15 movies
   matching the user's mood and constraints as JSON: [{title, year,
   reason}]. Match score 80-99. Reasons must be one sentence."
3. Build the user prompt: "Mood: {mood}. Language: {language}. Notes: {text}."
4. POST to Groq's /v1/chat/completions with model llama-3.3-70b-versatile.
5. Parse the JSON response (tolerant of code fences / trailing commas).
6. For each movie, search TMDB /search/movie, take the first result, fetch
   /movie/{id} to enrich with poster, rating, overview, genres, runtime.
7. Return the enriched array.
```

The enrichment step is what makes the response payload larger than a raw
LLM call — but it means the client doesn't have to do 15 extra round-trips.

---

## Error Responses

All errors return a JSON object with an `error.message` field (the Flutter
app reads this for user-facing toasts):

```json
{
  "error": {
    "message": "Human-readable description.",
    "code": "TMDB_401",
    "upstream": "tmdb"
  }
}
```

| `code`         | HTTP | Meaning                                              |
| :------------- | :--- | :--------------------------------------------------- |
| `BAD_REQUEST`  | 400  | Missing/invalid query parameter                       |
| `NOT_FOUND`    | 404  | TMDB returned 404 (e.g. unknown movie ID)            |
| `TMDB_401`     | 401  | Backend's `TMDB_API_KEY` env var is wrong or missing |
| `TMDB_429`     | 429  | TMDB rate limit (rare — TMDB is generous)            |
| `TMDB_5XX`     | 502  | TMDB returned a 5xx                                  |
| `GROQ_429`     | 429  | Groq free-tier rate limit                            |
| `GROQ_5XX`     | 502  | Groq returned a 5xx                                   |
| `UPSTREAM_TIMEOUT` | 504 | TMDB or Groq didn't respond in 15s                |
| `INTERNAL`     | 500  | Anything else — check Render logs                    |

---

## Caching

The backend applies a tiny in-memory cache to absorb Render cold-start
latency and protect against accidental DoS:

| Resource                         | TTL    | Reasoning                                  |
| :------------------------------- | :----- | :----------------------------------------- |
| `/api/tmdb/*` GET responses      | 60s    | Trending / popular / top_rated change slowly; this absorbs cold-start bursts |
| `/api/tmdb/movie/{id}` etc.      | 60s    | Same movie detail rarely changes; the Flutter client also has its own widget-level cache |
| `/api/ai/recommend`              | **not cached** | AI responses are user-specific (mood + text + language combination) |
| `/api/health` `tmdb`/`groq` flags| 60s    | Avoids hammering upstreams on every health ping |

The cache is a simple `Map<string, {body, expiresAt}>` — process-local, so a
cold start wipes it. There's no Redis or shared cache.

---

## CORS

The backend sends permissive CORS headers:

```http
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, OPTIONS
Access-Control-Allow-Headers: Content-Type
```

This is fine because:

- The Flutter app doesn't send cookies (no `credentials: 'include'`).
- All endpoints are read-only.
- There's nothing secret to leak — the API keys live server-side only.

If you fork the backend and add authenticated endpoints, **tighten CORS** to
your specific origin.

---

## Examples

### Quick smoke test

```bash
# Health
curl -s https://xstream-api.onrender.com/api/health | jq

# Trending
curl -s 'https://xstream-api.onrender.com/api/tmdb/trending/movie/day' | jq '.results[0] | {title, rating: .vote_average, poster: .poster_path}'

# Search
curl -s 'https://xstream-api.onrender.com/api/tmdb/search/multi?query=dune' | jq '.results | length'

# AI
curl -s 'https://xstream-api.onrender.com/api/ai/recommend?mood=chill&language=en' | jq '.[0:3] | .[] | {title, match, reason}'
```

### Calling from Dart (the Flutter app)

```dart
// See lib/data/services/api_client.dart
final api = ApiClient.instance;

// TMDB
final data = await api.get('/api/tmdb/trending/movie/day');
final results = (data['results'] as List).cast<Map<String, dynamic>>();

// AI
final recs = await api.get('/api/ai/recommend', query: {
  'mood': 'feel-good',
  'text': '',
  'language': 'en',
});
final list = (recs as List).cast<Map<String, dynamic>>();
```

### Calling from Node.js (for backend tests)

```js
const res = await fetch('https://xstream-api.onrender.com/api/health');
const json = await res.json();
console.log(json.status, json.tmdb, json.groq);
```

---

## Rate Limits & Cost

- **TMDB**: ~50 req/sec per API key (free, no quota). Effectively unlimited
  for personal use.
- **Groq free tier**: rate-limited on requests-per-minute and
  tokens-per-minute. Hitting it returns 429. The backend forwards the 429;
  the Flutter app shows a friendly "AI service is rate-limited, try again
  in a minute" message.
- **Render free tier**: 750 instance-hours/month (enough for ~31 days of
  continuous running if you keep it warm). Spins down after 15 min idle.

If you outgrow free tiers, upgrade Render to a paid instance ($7/month) and
Groq to a paid plan.

---

## Versioning

The backend is versioned independently of the Flutter app. The version is
returned in `/api/health` and `package.json`. Breaking changes will bump the
major version and be documented in [`CHANGELOG.md`](../CHANGELOG.md).

Current API version: **v1** (no breaking changes since initial release).

---

<p align="center">
  <em>Questions? Open an issue or read the backend source in <code>backend/</code>.</em>
</p>
