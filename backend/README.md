# Xstream API — Backend Proxy

A small Node.js / Express service that hides the **TMDB** and **Groq** API keys
from the Xstream Flutter APK. The Flutter app's `TmdbService` calls
`/api/tmdb/*` and `AiService` calls `/api/ai/recommend`; this proxy forwards
the requests upstream, applies a short in-memory cache, and enriches AI
recommendations with full TMDB metadata.

Built to deploy on Render's free tier.

---

## What it does

| Endpoint                    | Purpose                                                                |
| --------------------------- | ---------------------------------------------------------------------- |
| `GET /`                     | Service identity (`name`, `version`, `status`).                        |
| `GET /api/health`           | Liveness + key-presence probe. Render pings this to keep the service awake. |
| `GET /api/tmdb/*`           | Transparent proxy to `https://api.themoviedb.org/3/<*>`. All client query params (`append_to_response`, `with_genres`, `page`, `query`, …) are forwarded. Responses are cached with TTLs: **5 min** for lists, **10 min** for search, **30 min** for detail pages. |
| `GET /api/ai/recommend`     | Calls Groq (`llama-3.3-70b-versatile`) for 15 movie recs based on `mood`/`text`/`language`, then enriches each one in parallel with TMDB poster, backdrop, rating, overview, genres, and runtime. |

### Example Flutter calls (matched in `TmdbService` / `AiService`)

```text
GET /api/tmdb/trending/movie/day
GET /api/tmdb/discover/movie?with_genres=28&sort_by=popularity.desc&page=1
GET /api/tmdb/movie/550?append_to_response=credits,videos,keywords,watch/providers
GET /api/tmdb/search/multi?query=batman&page=1
GET /api/tmdb/person/138?append_to_response=movie_credits,tv_credits
GET /api/ai/recommend?mood=feel-good&text=quiet%20evening&language=en
```

### Response shape — `/api/ai/recommend`

A JSON array of 15 enriched recommendation objects:

```json
[
  {
    "title": "The Secret Life of Walter Mitty",
    "year": 2013,
    "match": 96,
    "reason": "A gentle, visually stunning escape...",
    "id": 114324,
    "media_type": "movie",
    "poster": "https://image.tmdb.org/t/p/w500/...</jpg>",
    "backdrop": "https://image.tmdb.org/t/p/original/...</jpg>",
    "rating": 7.5,
    "overview": "...",
    "genres": ["Adventure", "Comedy", "Drama"],
    "runtime": 114
  }
]
```

If a movie can't be found on TMDB, the basic LLM fields (`title`, `year`,
`match`, `reason`) are still returned with empty TMDB metadata so the app
always has 15 entries to render.

---

## Environment variables

| Variable       | Required | Default (dev only) | Notes                                            |
| -------------- | -------- | ------------------ | ------------------------------------------------ |
| `TMDB_API_KEY` | yes      | (built-in dev key) | TMDB v3 API key. **Override in production.**     |
| `GROQ_API_KEY` | yes      | (built-in dev key) | Groq API key. **Override in production.**        |
| `PORT`         | no       | `8080`             | Render sets this automatically.                  |

> The dev fallback keys in `server.js` exist only so the server boots
> locally without configuration. **Never rely on them in production** —
> rotate them and inject your own via the Render dashboard.

---

## Local development

```bash
cd xstream/backend
cp .env.example .env          # then edit .env with your real keys
npm install
npm run dev                   # node --watch server.js (auto-reload on save)
```

The server listens on `http://localhost:8080`. Quick smoke tests:

```bash
curl http://localhost:8080/
curl http://localhost:8080/api/health
curl 'http://localhost:8080/api/tmdb/trending/movie/day'
curl 'http://localhost:8080/api/ai/recommend?mood=feel-good&text=quiet&language=en'
```

Point the Flutter app at your local server from the Android emulator with:

```bash
flutter run --dart-define=BACKEND_URL=http://10.0.2.2:8080
```

(`10.0.2.2` is the Android emulator's alias for the host machine's
`localhost`.)

---

## Deploying to Render (step by step)

1. **Push to GitHub.** Commit the whole `xstream/` directory (the Flutter
   app + this `backend/` folder) to a GitHub repo. The backend lives at
   `xstream/backend/` in the repo root.

2. **Create a Web Service on Render.**
   - Dashboard → **New +** → **Blueprint** (preferred, uses `render.yaml`)
     - Pick your repo + branch.
     - Render detects `xstream/backend/render.yaml` and creates the
       `xstream-api` service for you.
   - **OR** do it manually: **New +** → **Web Service**:
     - Runtime: **Node**
     - Build command: `npm install`
     - Start command: `npm start`
     - Root directory: `xstream/backend`
     - Plan: **Free**

3. **Set environment variables** (Environment tab in the service dashboard):
   - `TMDB_API_KEY` — your TMDB v3 key
   - `GROQ_API_KEY` — your Groq key
   - `PORT` is set by Render automatically.

4. **Deploy.** Render runs `npm install` then `npm start`. Tail the logs
   until you see:
   ```
   Xstream API listening on :<port>
     TMDB key: configured
     Groq key: configured
   ```

5. **Verify.** Visit `https://<your-service>.onrender.com/api/health` — you
   should see `{"status":"ok","time":"...","tmdb":true,"groq":true}`.

6. **Wire up the Flutter app.** Update
   `xstream/lib/core/constants/app_constants.dart`:
   ```dart
   --dart-define=BACKEND_URL=https://<your-service>.onrender.com
   ```
   or change the `defaultValue` directly.

---

## Keeping the free tier awake

Render's free web services **sleep after 15 minutes of inactivity** and take
~30 s to spin back up on the next request. To keep the API responsive:

### Recommended — external ping (cron-job.org)

1. Go to [cron-job.org](https://cron-job.org) and create a free account.
2. Add a job pointing at your health endpoint:
   ```
   URL:     https://<your-service>.onrender.com/api/health
   Method:  GET
   Schedule: every 10 minutes
   ```
3. Save. The 10-minute cadence is well under the 15-minute idle window, so
   the container never sleeps.

### Alternatives

- **UptimeRobot** (free tier, 5-minute checks) — same idea, different UI.
- **GitHub Actions cron** — a once-every-10-minutes workflow that runs
  `curl https://<your-service>.onrender.com/api/health`.

> You can also call `/api/health` from inside the Flutter app the first time
> it cold-starts — that both warms the container and gives the user a clear
> "preparing your cinema…" indicator while Render boots.

---

## Architecture notes

- **Why a proxy?** TMDB and Groq keys would otherwise be embedded in the
  APK and trivially extractable. The proxy keeps them server-side.
- **Why a cache?** Render free-tier cold starts take ~30 s. A short TTL
  cache (5–30 min, Map-based) absorbs burst traffic and lets repeated
  navigation between list pages feel instant.
- **Why parallel enrichment?** 15 sequential TMDB calls would add 1–3 s of
  latency. `Promise.all` flattens that to roughly one round-trip.
- **No DB / no state.** Everything is in-memory; restarts wipe the cache
  but not the app's functionality. This matches the privacy-first design
  of the original web app.

---

## License

MIT — see the repo root `LICENSE`.
