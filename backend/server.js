/**
 * Xstream API — Backend proxy (Node.js / Express)
 * ------------------------------------------------------------------
 * Hides the TMDB and Groq API keys from the Flutter APK, applies a
 * short in-memory cache to absorb Render cold starts, and enriches
 * Groq recommendations with full TMDB metadata before returning them
 * to the app.
 *
 * Routes
 *   GET /                            → service identity
 *   GET /api/health                  → liveness + key checks
 *   GET /api/tmdb/*                  → transparent TMDB proxy (cached)
 *   GET /api/ai/recommend            → Groq recs enriched with TMDB
 *
 * Env vars (see .env.example)
 *   TMDB_API_KEY   TMDB v3 API key
 *   GROQ_API_KEY   Groq API key
 *   PORT           HTTP port (Render sets this automatically; default 8080)
 *
 * Requires Node 18+ (uses the built-in global fetch).
 */

import 'dotenv/config';
import express from 'express';
import cors from 'cors';

// ─── Configuration ──────────────────────────────────────────────────────────

const PORT = process.env.PORT || 8080;

/**
 * API keys. We fall back to the shared dev keys so the server boots
 * out-of-the-box during local development, but production deployments
 * MUST inject real keys via the Render dashboard.
 */
const TMDB_API_KEY = process.env.TMDB_API_KEY;
const GROQ_API_KEY = process.env.GROQ_API_KEY;

const TMDB_BASE = 'https://api.themoviedb.org/3';
const TMDB_IMAGE_BASE = 'https://image.tmdb.org/t/p';
const GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions';
const GROQ_MODEL = 'llama-3.3-70b-versatile';

/** Upstream timeouts (ms). */
const TMDB_TIMEOUT_MS = 15_000;
const GROQ_TIMEOUT_MS = 30_000;

/** Cache TTLs (ms). */
const TTL_LIST = 5 * 60 * 1000; // 5 min — trending, top_rated, discover, genre lists
const TTL_DETAIL = 30 * 60 * 1000; // 30 min — full detail pages (stable metadata)
const TTL_SEARCH = 10 * 60 * 1000; // 10 min — search/multi
const TTL_AI = 60 * 1000; // 1 min — short cache so identical moods don't re-hit Groq

// ─── Mood / language label maps (mirror the Flutter app) ───────────────────

const MOOD_LABELS = {
  'feel-good': 'Feel Good',
  emotional: 'Emotional',
  'mind-bending': 'Mind-Bending',
  adrenaline: 'Adrenaline',
  chill: 'Chill & Cozy',
};

const LANGUAGE_LABELS = {
  en: 'English',
  hi: 'Hindi',
  ko: 'Korean',
  es: 'Spanish',
  ja: 'Japanese',
  fr: 'French',
};

/** Resolve a mood code (or already-human label) to its display label. */
function resolveMoodLabel(raw) {
  const key = String(raw || '').trim().toLowerCase();
  if (!key) return 'something good';
  return MOOD_LABELS[key] || String(raw);
}

/** Resolve a language code (or already-human label) to its display label. */
function resolveLanguageLabel(raw) {
  const key = String(raw || '').trim().toLowerCase();
  if (!key) return 'Any';
  return LANGUAGE_LABELS[key] || String(raw);
}

// ─── In-memory cache ────────────────────────────────────────────────────────

/**
 * Tiny Map-based TTL cache. Entries store `{ value, expires }`. A periodic
 * sweep prevents unbounded growth on long-running processes.
 *
 * Render's free tier recycles the container every so often, so the cache
 * is best-effort — it just smooths over short bursts of duplicate traffic
 * and cold-starts.
 */
const cache = new Map();

function cacheGet(key) {
  const entry = cache.get(key);
  if (!entry) return null;
  if (Date.now() > entry.expires) {
    cache.delete(key);
    return null;
  }
  return entry.value;
}

function cacheSet(key, value, ttlMs) {
  cache.set(key, { value, expires: Date.now() + ttlMs });
}

/** Periodic janitor — drop expired entries every 5 minutes. */
setInterval(() => {
  const now = Date.now();
  for (const [k, v] of cache) {
    if (now > v.expires) cache.delete(k);
  }
}, 5 * 60 * 1000).unref();

/**
 * Classify a TMDB sub-path (the bit after `/api/tmdb/`) into a cache TTL.
 *   - search/*                       → 10 min (TTL_SEARCH)
 *   - {type}/{id} (pure detail)      → 30 min (TTL_DETAIL)
 *   - {type}/{id}/{videos,keywords}  → 30 min (stable metadata)
 *   - {type}/{id}/similar            → 5 min  (changes with popularity)
 *   - person/*, company/*            → 30 min (TTL_DETAIL)
 *   - everything else (lists)        → 5 min  (TTL_LIST)
 */
function classifyTmdbTtl(subPath) {
  if (subPath.startsWith('search/')) return TTL_SEARCH;
  if (/^(movie|tv)\/\d+$/.test(subPath)) return TTL_DETAIL;
  if (/^(movie|tv)\/\d+\/(videos|keywords)$/.test(subPath)) return TTL_DETAIL;
  if (/^(movie|tv)\/\d+\/similar$/.test(subPath)) return TTL_LIST;
  if (subPath.startsWith('person/') || subPath.startsWith('company/'))
    return TTL_DETAIL;
  return TTL_LIST;
}

// ─── HTTP helpers ───────────────────────────────────────────────────────────

/**
 * fetch() with a hard timeout. Resolves to the raw Response so callers can
 * decide how to stream/parse the body. Throws an Error with a useful
 * `code` property so the route handler can map it to a proper status.
 */
async function fetchWithTimeout(url, options = {}, timeoutMs = 15_000) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetch(url, { ...options, signal: controller.signal });
  } catch (err) {
    if (err.name === 'AbortError') {
      const e = new Error(`Upstream timeout after ${timeoutMs}ms: ${url}`);
      e.code = 'TIMEOUT';
      throw e;
    }
    const e = new Error(`Upstream fetch failed: ${err.message}`);
    e.code = 'UPSTREAM_ERROR';
    e.cause = err;
    throw e;
  } finally {
    clearTimeout(timer);
  }
}

/**
 * Forward a GET to TMDB and return parsed JSON.
 *
 * @param {string} subPath  Path after `/api/tmdb/` (e.g. `trending/movie/day`)
 * @param {URLSearchParams} [params]  Query params from the client
 * @param {number} [ttlMs]  Cache TTL (auto-classified if omitted)
 */
async function tmdbGet(subPath, params, ttlMs) {
  const ttl = ttlMs ?? classifyTmdbTtl(subPath);

  // Build a stable cache key from the path + sorted query.
  const cacheParams = new URLSearchParams(params);
  cacheParams.sort();
  const cacheKey = `tmdb:${subPath}?${cacheParams.toString()}`;

  const cached = cacheGet(cacheKey);
  if (cached) return { data: cached, cached: true };

  const url = new URL(`${TMDB_BASE}/${subPath}`);
  // Copy client params (page, query, with_genres, append_to_response, …)
  if (params) for (const [k, v] of params.entries()) url.searchParams.set(k, v);
  url.searchParams.set('api_key', TMDB_API_KEY);

  const res = await fetchWithTimeout(url.toString(), {}, TMDB_TIMEOUT_MS);
  if (!res.ok) {
    const body = await res.text().catch(() => '');
    const e = new Error(`TMDB ${res.status} for ${subPath}: ${body.slice(0, 200)}`);
    e.code = 'UPSTREAM_STATUS';
    e.status = res.status;
    throw e;
  }

  const data = await res.json();
  cacheSet(cacheKey, data, ttl);
  return { data, cached: false };
}

// ─── Express app ────────────────────────────────────────────────────────────

const app = express();
app.use(cors()); // allow all origins — the Flutter app needs this
app.use(express.json());

// Routes are registered below. The central error handler lives at the
// very bottom of the file (it must be registered AFTER the routes that
// call `next(err)`, otherwise Express cannot find it).

// ── Root ──────────────────────────────────────────────────────────────────

app.get('/', (_req, res) => {
  res.json({
    name: 'Xstream API',
    version: '1.0.0',
    status: 'running',
  });
});

// ── Health check ──────────────────────────────────────────────────────────

/**
 * Liveness probe + key sanity check. We do *not* actually call upstream
 * APIs here (that would make the health check slow and rate-limit-prone);
 * we simply report whether the keys are configured. Render pings this
 * endpoint to keep the container warm.
 */
app.get('/api/health', (_req, res) => {
  res.json({
    status: 'ok',
    time: new Date().toISOString(),
    tmdb: Boolean(TMDB_API_KEY),
    groq: Boolean(GROQ_API_KEY),
  });
});

// ── TMDB catch-all proxy ──────────────────────────────────────────────────

/**
 * `GET /api/tmdb/*` → `https://api.themoviedb.org/3/<*>?<client query>&api_key=<key>`
 *
 * Everything after `/api/tmdb/` is forwarded verbatim to TMDB. All client
 * query params are preserved (so `append_to_response`, `with_genres`,
 * `page`, etc. all work). Responses are cached with a TTL based on the
 * path classification above.
 *
 * Examples (Flutter → backend → TMDB):
 *   /api/tmdb/trending/movie/day       → /trending/movie/day
 *   /api/tmdb/discover/movie?with_genres=28 → /discover/movie?with_genres=28
 *   /api/tmdb/movie/550?append_to_response=credits → /movie/550?...
 *   /api/tmdb/search/multi?query=batman → /search/multi?query=batman
 */
app.get('/api/tmdb/*', async (req, res, next) => {
  try {
    // req.params[0] holds everything after `/api/tmdb/`.
    const subPath = (req.params[0] || '').replace(/^\/+/, '');
    if (!subPath) {
      return res.status(400).json({
        error: { code: 'BAD_PATH', message: 'Missing TMDB path.' },
      });
    }

    const params = new URLSearchParams(req.query);
    const { data, cached } = await tmdbGet(subPath, params);

    if (cached) res.setHeader('X-Xstream-Cache', 'HIT');
    else res.setHeader('X-Xstream-Cache', 'MISS');
    res.json(data);
  } catch (err) {
    next(err);
  }
});

// ── AI recommendations ────────────────────────────────────────────────────

/**
 * `GET /api/ai/recommend?mood=<id>&text=<free text>&language=<code>`
 *
 * Pipeline:
 *   1. Build system + user prompts (exact text — see PROMPTS below).
 *   2. Call Groq chat completions with response_format=json_object,
 *      temperature 0.7, max_tokens 4096.
 *   3. Defensively parse the model output (array OR object with
 *      recommendations/movies/results key).
 *   4. For each of the 15 movies, search TMDB and fetch full details in
 *      parallel (Promise.all) — attaches id, poster, backdrop, rating,
 *      overview, genres[], runtime.
 *   5. Return a JSON array of enriched recommendations.
 */

const SYSTEM_PROMPT = `You are XAI, an elite AI movie recommendation engine built into Xstream — a premium cinematic streaming platform. You deeply understand cinema, emotions, genres, and what makes a perfect movie-night choice.

Your job: Given the user's mood and preferences, recommend exactly 15 movies that would be the PERFECT fit right now.

CRITICAL RULES:
- Only recommend REAL movies that actually exist. No fake titles.
- Each movie must have a real release year between 2000-2025.
- Prefer movies with rating >= 7.0 on TMDB.
- Match the language preference when possible, but quality matters more.
- "match" percentage should reflect how well the movie fits the mood (80-99%).
- "reason" should be a compelling 1-2 sentence pitch about why this movie is perfect for their current mood. No spoilers.
- Sort by match percentage descending.
- Return exactly 15 movies, no more, no less.

Respond with ONLY valid JSON array, no markdown, no explanation:
[
  {
    "title": "Exact Movie Title",
    "year": 2023,
    "match": 96,
    "reason": "Why this movie is perfect for you right now..."
  },
  ...
]`;

/** Strip markdown fences and extract the first JSON array/object from a string. */
function extractJson(raw) {
  if (!raw) return null;
  let text = String(raw).trim();

  // Strip ```json ... ``` fences if the model added them anyway.
  text = text.replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/i, '').trim();

  // Try a direct parse first.
  try {
    return JSON.parse(text);
  } catch {
    /* fall through to regex extraction */
  }

  // Fallback: pull the first balanced [...] or {...} block out of the text.
  const arrayMatch = text.match(/\[[\s\S]*\]/);
  if (arrayMatch) {
    try {
      return JSON.parse(arrayMatch[0]);
    } catch {
      /* ignore */
    }
  }
  const objectMatch = text.match(/\{[\s\S]*\}/);
  if (objectMatch) {
    try {
      return JSON.parse(objectMatch[0]);
    } catch {
      /* ignore */
    }
  }
  return null;
}

/**
 * Normalise the LLM's reply into an array of recommendation objects.
 * Handles arrays directly or objects wrapped under common keys.
 */
function normaliseRecommendations(parsed) {
  if (Array.isArray(parsed)) return parsed;
  if (parsed && typeof parsed === 'object') {
    for (const key of ['recommendations', 'movies', 'results', 'data', 'items', 'list']) {
      if (Array.isArray(parsed[key])) return parsed[key];
    }
    // Last-ditch: return the first array value we can find.
    for (const v of Object.values(parsed)) {
      if (Array.isArray(v)) return v;
    }
  }
  return [];
}

/**
 * Enrich a single recommendation with TMDB metadata.
 * On any failure, returns the original rec (with empty TMDB fields) so the
 * app still has something to render.
 */
async function enrichRecommendation(rec) {
  const title = String(rec?.title || '').trim();
  const base = {
    title,
    year: Number(rec?.year) || 0,
    match: Math.max(80, Math.min(99, Number(rec?.match) || 80)),
    reason: String(rec?.reason || ''),
    id: null,
    media_type: 'movie',
    poster: '',
    backdrop: '',
    rating: null,
    overview: '',
    genres: [],
    runtime: null,
  };

  if (!title) return base;

  try {
    // 1. Search TMDB for the title.
    const searchUrl = new URL(`${TMDB_BASE}/search/multi`);
    searchUrl.searchParams.set('query', title);
    searchUrl.searchParams.set('api_key', TMDB_API_KEY);

    const searchRes = await fetchWithTimeout(searchUrl.toString(), {}, TMDB_TIMEOUT_MS);
    if (!searchRes.ok) return base;
    const searchData = await searchRes.json();
    const results = Array.isArray(searchData?.results) ? searchData.results : [];

    // 2. Pick the first movie/tv result that actually has a poster.
    const hit = results.find(
      (r) =>
        r &&
        (r.media_type === 'movie' || r.media_type === 'tv') &&
        r.poster_path,
    );
    if (!hit) return base;

    const mediaType = hit.media_type;
    const tmdbId = hit.id;

    // 3. Fetch full details (gives us backdrop, rating, runtime, genres, overview).
    const detailUrl = new URL(`${TMDB_BASE}/${mediaType}/${tmdbId}`);
    detailUrl.searchParams.set('api_key', TMDB_API_KEY);
    const detailRes = await fetchWithTimeout(detailUrl.toString(), {}, TMDB_TIMEOUT_MS);
    if (!detailRes.ok) {
      // Fall back to whatever the search result gave us.
      return {
        ...base,
        id: tmdbId,
        media_type: mediaType,
        poster: hit.poster_path ? `${TMDB_IMAGE_BASE}/w500${hit.poster_path}` : '',
        backdrop:
          hit.backdrop_path ? `${TMDB_IMAGE_BASE}/original${hit.backdrop_path}` : '',
        rating: typeof hit.vote_average === 'number' ? hit.vote_average : null,
        overview: String(hit.overview || ''),
      };
    }
    const detail = await detailRes.json();

    const posterPath = detail.poster_path || hit.poster_path;
    const backdropPath = detail.backdrop_path || hit.backdrop_path;
    const genres = Array.isArray(detail.genres)
      ? detail.genres.map((g) => g.name).filter(Boolean)
      : [];

    return {
      ...base,
      id: detail.id ?? tmdbId,
      media_type: mediaType,
      poster: posterPath ? `${TMDB_IMAGE_BASE}/w500${posterPath}` : '',
      backdrop: backdropPath ? `${TMDB_IMAGE_BASE}/original${backdropPath}` : '',
      rating: typeof detail.vote_average === 'number' ? detail.vote_average : null,
      overview: String(detail.overview || ''),
      genres,
      runtime:
        mediaType === 'movie'
          ? detail.runtime ?? null
          : detail.episode_run_time?.[0] ?? null,
    };
  } catch (err) {
    console.warn(`[ai] enrichment failed for "${title}": ${err.message}`);
    return base;
  }
}

app.get('/api/ai/recommend', async (req, res, next) => {
  try {
    const mood = req.query.mood || '';
    const text = req.query.text || '';
    const language = req.query.language || '';

    if (!mood && !text) {
      return res.status(400).json({
        error: {
          code: 'BAD_INPUT',
          message: 'At least one of `mood` or `text` is required.',
        },
      });
    }

    // Short cache: identical (mood, text, language) won't re-hit Groq for 60s.
    const cacheKey = `ai:${mood}|${text}|${language}`;
    const cached = cacheGet(cacheKey);
    if (cached) {
      res.setHeader('X-Xstream-Cache', 'HIT');
      return res.json(cached);
    }

    const moodLabel = resolveMoodLabel(mood);
    const languageLabel = resolveLanguageLabel(language);
    const userPrompt = `I'm in the mood for: ${moodLabel}. More specifically: "${text}". Preferred language: ${languageLabel}. Give me 15 movie recommendations.`;

    // ── 1. Call Groq ──────────────────────────────────────────────────────
    const groqRes = await fetchWithTimeout(
      GROQ_URL,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${GROQ_API_KEY}`,
        },
        body: JSON.stringify({
          model: GROQ_MODEL,
          temperature: 0.7,
          max_tokens: 4096,
          response_format: { type: 'json_object' },
          messages: [
            { role: 'system', content: SYSTEM_PROMPT },
            { role: 'user', content: userPrompt },
          ],
        }),
      },
      GROQ_TIMEOUT_MS,
    );

    if (!groqRes.ok) {
      const errBody = await groqRes.text().catch(() => '');
      const e = new Error(`Groq ${groqRes.status}: ${errBody.slice(0, 200)}`);
      e.code = 'UPSTREAM_STATUS';
      e.status = groqRes.status === 429 ? 503 : 502;
      e.expose = true;
      throw e;
    }

    const groqJson = await groqRes.json();
    const rawContent = groqJson?.choices?.[0]?.message?.content || '';

    // ── 2. Parse defensively ──────────────────────────────────────────────
    const parsed = extractJson(rawContent);
    const recs = normaliseRecommendations(parsed);

    if (recs.length === 0) {
      console.warn('[ai] Groq returned no usable recommendations:', rawContent.slice(0, 200));
      return res.status(502).json({
        error: {
          code: 'AI_EMPTY',
          message: 'The AI did not return any recommendations. Try again.',
        },
      });
    }

    // ── 3. Enrich with TMDB metadata (in parallel) ────────────────────────
    // Take up to 15 — protects us if the model over/under-shoots.
    const slice = recs.slice(0, 15);
    const enriched = await Promise.all(slice.map(enrichRecommendation));

    // Sort by match % desc (matching the system prompt's instruction).
    enriched.sort((a, b) => b.match - a.match);

    cacheSet(cacheKey, enriched, TTL_AI);
    res.setHeader('X-Xstream-Cache', 'MISS');
    res.json(enriched);
  } catch (err) {
    next(err);
  }
});

// ── 404 fallback (JSON, not HTML) ─────────────────────────────────────────

app.use((req, res) => {
  res.status(404).json({
    error: {
      code: 'NOT_FOUND',
      message: `Route not found: ${req.method} ${req.path}`,
    },
  });
});

// ── Central error handler (must be last) ──────────────────────────────────
//
// Always replies with JSON so the Flutter Dio client can parse
// `error.message` cleanly. Maps upstream timeouts → 504, Groq/TMDB
// upstream errors → 502/503, and anything else → 500.
app.use((err, _req, res, _next) => {
  const status =
    err.status || (err.code === 'TIMEOUT' ? 504 : err.code === 'UPSTREAM_STATUS' ? 502 : 500);
  console.error(`[error] ${err.code || 'ERR'}: ${err.message}`);
  res.status(status).json({
    error: {
      code: err.code || 'INTERNAL',
      message: err.expose
        ? err.message
        : 'Something went wrong on the server.',
    },
  });
});

// ─── Boot ───────────────────────────────────────────────────────────────────

app.listen(PORT, () => {
  console.log(`Xstream API listening on :${PORT}`);
  console.log(`  TMDB key: ${TMDB_API_KEY ? 'configured' : 'MISSING'}`);
  console.log(`  Groq key: ${GROQ_API_KEY ? 'configured' : 'MISSING'}`);
});
