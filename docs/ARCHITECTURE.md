# Architecture

This document describes the high-level architecture of the Xstream Android app,
the backend proxy it depends on, and the data flow between them. It's the
single source of truth for "where does X live and why?".

> 📌 **Audience**: contributors who want to understand the codebase before
> making changes. For a getting-started guide, see
> [`CONTRIBUTING.md`](../CONTRIBUTING.md). For deployment, see
> [`DEPLOYMENT.md`](./DEPLOYMENT.md). For the backend HTTP API, see
> [`API.md`](./API.md).

---

## 🏛 High-Level Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│                          Android Device                                 │
│                                                                         │
│   ┌─────────────────────────────────────────────────────────────────┐  │
│   │                    Xstream Flutter App                           │  │
│   │                                                                 │  │
│   │   ┌─────────────────┐    ┌─────────────────┐                    │  │
│   │   │   UI Layer      │    │   State Layer   │                    │  │
│   │   │  (Widgets)      │◀──▶│  (Riverpod)     │                    │  │
│   │   │  features/*     │    │  providers/     │                    │  │
│   │   └────────┬────────┘    └────────┬────────┘                    │  │
│   │            │                      │                             │  │
│   │            ▼                      ▼                             │  │
│   │   ┌──────────────────────────────────────────┐                  │  │
│   │   │            Data Layer                     │                  │  │
│   │   │  ┌────────────┐  ┌──────────────────────┐ │                  │  │
│   │   │  │ Services   │  │   Models (immutable) │ │                  │  │
│   │   │  │ • ApiClient│  │   • MediaItem        │ │                  │  │
│   │   │  │ • TmdbSvc  │  │   • MediaDetail      │ │                  │  │
│   │   │  │ • AiSvc    │  │   • Person           │ │                  │  │
│   │   │  │ • Storage  │  │   • AiRecommendation │ │                  │  │
│   │   │  └─────┬──────┘  └──────────────────────┘ │                  │  │
│   │   └────────┼──────────────────────────────────┘                  │  │
│   │            │                                                      │  │
│   │   ┌────────▼─────────┐    ┌─────────────────┐                    │  │
│   │   │  SharedPreferences│    │  WebView        │                    │  │
│   │   │  (history, list,  │    │  (stream embeds)│                    │  │
│   │   │   likes, ratings) │    │                 │                    │  │
│   │   └──────────────────┘    └────────┬────────┘                    │  │
│   │                                     │                             │  │
│   └─────────────────────────────────────┼─────────────────────────────┘  │
│                                         │                               │
└─────────────────────────────────────────┼───────────────────────────────┘
                                          │ HTTPS
                                          ▼
                ┌─────────────────────────────────────────┐
                │      Xstream Backend Proxy (Render)      │
                │       Node.js + Express, free tier       │
                │                                          │
                │   • /api/health   ← uptime pings         │
                │   • /api/tmdb/*    ← forwards to TMDB    │
                │   • /api/ai/recommend ← Groq LLM call    │
                │   • In-memory cache (≤ 60s)              │
                │                                          │
                │   Env vars:                              │
                │     TMDB_API_KEY  (server-side only)     │
                │     GROQ_API_KEY  (server-side only)     │
                └──────────┬─────────────────┬─────────────┘
                           │                 │
              ┌────────────▼──────┐  ┌───────▼────────────┐
              │   TMDB REST API   │  │   Groq Cloud API    │
              │  api.themoviedb.  │  │  api.groq.com       │
              │       org/3       │  │   llama-3.3-70b-    │
              │                   │  │     versatile       │
              └─────────┬─────────┘  └─────────────────────┘
                        │
                        ▼
              ┌────────────────────┐
              │  TMDB Image CDN    │
              │ image.tmdb.org/t/p │  ← loaded directly by
              │                    │    cached_network_image
              └────────────────────┘    (no proxy needed)

              ┌──────────────────────────────────────────┐
              │  Third-party stream embeds (WebView)     │
              │  • vidlink.pro   • vidsrc.me             │
              │  • vidsrc.pro    • vidsrc.cc             │
              │  • multiembed.mov • peachify.top         │
              └──────────────────────────────────────────┘
```

### Key design decisions

1. **The backend only hides secrets.** It is a thin proxy — no database, no
   per-user state, no auth. Its sole job is to inject `TMDB_API_KEY` and
   `GROQ_API_KEY` so they never ship in the APK.
2. **The app is the source of truth for personal data.** History, watchlist,
   likes, ratings, view counts — all in `SharedPreferences` on the device.
3. **TMDB images are loaded directly.** `image.tmdb.org` is a public CDN; no
   key required, no proxy needed. `cached_network_image` handles caching.
4. **Stream embeds are rendered in a WebView.** Same approach as the original
   web app's `<iframe>`, just rendered natively. We don't control these
   providers — they're external services.
5. **One backend URL, injected at build time.** `--dart-define=BACKEND_URL=…`
   lets you point at your own Render instance (or `http://10.0.2.2:8080` for
   local development).

---

## 🗂 Folder Structure

```
lib/
├── main.dart                         # entrypoint
├── app/
│   ├── app.dart                      # XstreamApp (MaterialApp.router)
│   └── bootstrap.dart                # system UI, orientation, StorageService.init()
├── core/
│   ├── constants/
│   │   ├── app_constants.dart        # BACKEND_URL, image CDN base, storage prefix
│   │   └── streaming_servers.dart    # 11 branded servers, 6 distinct backends
│   ├── router/
│   │   └── app_router.dart           # GoRouter config + AppRoute names
│   ├── theme/
│   │   ├── app_colors.dart           # palette, 7 accent swatches, rating colors
│   │   └── app_theme.dart            # ThemeData, typography, system UI overlay
│   └── utils/                        # (shared helpers)
├── data/
│   ├── models/                       # immutable Dart models
│   │   ├── media_item.dart           # MediaItem, Genre, Video, CastMember, …
│   │   ├── media_detail.dart         # MediaDetail, SeasonInfo
│   │   ├── person.dart               # Person, Company
│   │   └── ai_recommendation.dart    # AiRecommendation, AiMood, AiLanguage
│   ├── repositories/                 # (repository layer — reserved)
│   └── services/
│       ├── api_client.dart           # Dio singleton, base URL = BACKEND_URL
│       ├── tmdb_service.dart         # all /api/tmdb/* calls
│       ├── ai_service.dart           # /api/ai/recommend
│       └── storage_service.dart      # SharedPreferences, privacy-gated
├── features/                         # one folder per screen
│   ├── splash/                       # IntroSplash animation (first-launch only)
│   ├── home/                         # Home + hero carousel + content rows
│   │   └── widgets/
│   ├── movies/                       # Movies page with genre filters
│   ├── series/                       # Series page
│   ├── anime/                        # Anime page
│   ├── new_popular/                  # New & Popular page
│   ├── search/                       # infinite-scroll multi-search
│   ├── details/                      # full details page (cast, trailers, etc.)
│   ├── watch/                        # WebView player + server picker + S/E selector
│   ├── profile/                      # history, my list, likes, ratings, settings
│   ├── person/                       # actor filmography
│   ├── company/                      # studio page
│   └── ai_recommend/                 # XAI mood picker + 15 results grid
└── shared/
    ├── providers/
    │   └── app_providers.dart        # all Riverpod providers + StorageActions
    └── widgets/                      # AppScaffold, MovieCard, MostViewedBadge, …
```

### Layering rules

- **Widgets** (`features/*/`) only import from `shared/widgets/`, `shared/providers/`,
  `core/`, and `data/models/`. They never call HTTP or `SharedPreferences` directly.
- **Providers** (`shared/providers/`) orchestrate services and expose state to
  widgets. They hold no UI logic.
- **Services** (`data/services/`) are the only layer allowed to touch the
  network (`ApiClient`) or `SharedPreferences` (`StorageService`).
- **Models** (`data/models/`) are immutable, with `fromJson` factories and
  `copyWith` methods. No business logic — only data shape.
- **Core** (`core/`) holds cross-cutting concerns: constants, router, theme.
- **Cross-feature imports are forbidden.** If `features/watch/` needs a widget
  that `features/details/` also needs, it goes in `shared/widgets/`.

---

## 🧠 State Management — Riverpod

We use **Riverpod 2.5** (`flutter_riverpod`). All app-wide providers live in
[`lib/shared/providers/app_providers.dart`](../lib/shared/providers/app_providers.dart).
Feature-local providers (rare) live next to the feature.

### The storage-bump pattern

`StorageService` is a singleton backed by `SharedPreferences`, which has no
reactive API. To make Riverpod rebuild when storage changes, we use a
"bump counter":

```dart
// A state provider that increments every time storage mutates.
final _storageVersionProvider = StateProvider<int>((ref) {
  final storage = ref.watch(storageServiceProvider);
  storage.addListener(() {
    Future.microtask(() => ref.state++);
  });
  return 0;
});

// Every consumer watches _storageVersionProvider before reading storage.
final historyProvider = Provider<List<HistoryEntry>>((ref) {
  ref.watch(_storageVersionProvider);   // ← re-runs on every bump
  return StorageService.I.getHistory();
});
```

When a widget mutates storage (via `StorageActions.instance.*`), the storage
listener fires, `_storageVersionProvider` increments, and every provider that
watched it re-runs — refreshing `historyProvider`, `watchlistProvider`,
`likesProvider`, `ratingsProvider`, `mostViewedProvider`,
`accentColorProvider`, `autoplayNextProvider`, `preferredServerProvider` and
`consentProvider` in one shot.

### Provider catalogue

| Provider                          | Type                          | Returns                                  |
| :-------------------------------- | :---------------------------- | :--------------------------------------- |
| `storageServiceProvider`          | `Provider<StorageService>`    | The singleton                            |
| `consentProvider`                 | `Provider<ConsentState>`      | `accepted` / `declined` / `needsChoice`  |
| `historyProvider`                 | `Provider<List<HistoryEntry>>`| Last 60 watched entries                  |
| `watchlistProvider`               | `Provider<List<MediaItem>>`   | User's "My List"                         |
| `likesProvider`                   | `Provider<List<MediaItem>>`   | Liked titles                             |
| `ratingsProvider`                 | `Provider<Map<String,int>>`   | Personal 5-star ratings keyed by `type-id` |
| `mostViewedProvider`              | `Provider<MostViewed?>`       | Single most-watched title                |
| `mostViewedListProvider`          | `Provider<List<HistoryEntry>>`| Top 10 most-watched                       |
| `continueWatchingProvider`        | `Provider<List<MediaItem>>`   | History filtered to items with posters   |
| `accentColorProvider`             | `Provider<Color>`             | User's chosen accent                      |
| `autoplayNextProvider`            | `Provider<bool>`              | Autoplay-next-episode toggle              |
| `hasSeenIntroProvider`            | `Provider<bool>`              | Whether the intro splash has played       |
| `preferredServerProvider`         | `StateProvider<StreamingServer>` | Currently-selected streaming server     |
| `aiRecommendationProvider`        | `FutureProvider.family<...>`  | 15 AI picks for a given mood/text/lang    |

### Imperative actions

For mutations (toggle like, set rating, register view, wipe data) we expose
`StorageActions.instance.*` — a thin static facade over `StorageService` so
widgets don't reach into the singleton directly:

```dart
await StorageActions.instance.toggleWatchlist(item);
await StorageActions.instance.setRating(id, mediaType, 4);
await StorageActions.instance.registerView(id, mediaType);
await StorageActions.instance.wipeAll();
```

Each method internally bumps `_storageVersionProvider` via the storage
listener, so the UI refreshes automatically.

---

## 🌊 Data Flow

The canonical flow for a screen that displays TMDB data:

```
   ┌────────────┐
   │   Widget   │  e.g. HomeScreen
   └─────┬──────┘
         │ ref.watch(someFutureProvider)
         ▼
   ┌────────────┐
   │  Provider  │  e.g. a FutureProvider in app_providers.dart
   └─────┬──────┘
         │ calls TmdbService.instance.trendingMovies()
         ▼
   ┌────────────┐
   │  Service   │  TmdbService — builds the path, parses the response
   └─────┬──────┘
         │ _api.get('/api/tmdb/trending/movie/day')
         ▼
   ┌────────────┐
   │  ApiClient │  Dio singleton — base URL = BACKEND_URL
   └─────┬──────┘
         │ HTTPS GET
         ▼
   ┌────────────┐
   │  Backend   │  Render proxy — appends TMDB_API_KEY, forwards
   └─────┬──────┘
         │ HTTPS GET
         ▼
   ┌────────────┐
   │    TMDB    │  api.themoviedb.org/3
   └────────────┘
```

For AI recommendations, the flow is the same but the backend also calls Groq
and assembles the prompt server-side.

For storage mutations:

```
   ┌────────────┐
   │   Widget   │  e.g. tapping the like button
   └─────┬──────┘
         │ StorageActions.instance.toggleLike(item)
         ▼
   ┌────────────┐
   │  Storage   │  StorageService.toggleLike()
   │  Service   │  → _prefs.setString('xs_likes', jsonEncode(...))
   └─────┬──────┘
         │ _notify() → all listeners fire
         ▼
   ┌──────────────────┐
   │ _storageVersion  │  ref.state++
   │ Provider         │
   └─────┬────────────┘
         │ Riverpod marks dependents dirty
         ▼
   ┌────────────┐
   │  Provider  │  likesProvider re-runs → returns new list
   └─────┬──────┘
         │
         ▼
   ┌────────────┐
   │   Widget   │  rebuilds with new state
   └────────────┘
```

---

## 💾 Storage Layer

[`lib/data/services/storage_service.dart`](../lib/data/services/storage_service.dart)
is the privacy-first persistence layer. It's a 1:1 port of the web app's
`lib/storage.js`, just swapped from `localStorage` to `SharedPreferences`.

### Keys (all prefixed with `xs_`)

| Key              | Type                | Purpose                              |
| :--------------- | :------------------ | :----------------------------------- |
| `xs_consent`     | `String`            | `'accepted'` / `'declined'` / unset   |
| `xs_consent_at`  | `int` (ms epoch)    | When the consent decision was made    |
| `xs_history`     | `String` (JSON)     | Last 60 `HistoryEntry` objects        |
| `xs_watchlist`   | `String` (JSON)     | "My List" items                       |
| `xs_likes`       | `String` (JSON)     | Liked items                           |
| `xs_ratings`     | `String` (JSON map) | `{"movie-123": 4, "tv-456": 5}`       |
| `xs_views`       | `String` (JSON map) | `{"movie-123": 7}` (view count)       |
| `xs_accent`      | `String` (hex)      | `'#E50914'` default                   |
| `xs_autoplay`    | `bool`              | `true` default                        |
| `xs_seen_intro`  | `bool`              | `false` until first launch completes  |
| `xs_preferred_server` | `String`       | Server ID, e.g. `'server-1'`          |

### Consent gate

Every personal-data write checks `isPersonalizationAllowed` first:

```dart
Future<void> addToHistory(HistoryEntry entry) async {
  if (!isPersonalizationAllowed) return;   // ← declined consent
  // … write to prefs
}
```

If the user declines the consent gate, the app refuses to store **anything**
personal — it still works as a browser, just with no memory.

### `wipeAllPersonalData()`

Called by:

- The **Clear All Data** button in Profile.
- `declineConsent()` — so toggling consent from accepted → declined wipes
  everything that was stored while accepted.

Removes: history, watchlist, likes, ratings, view counts. Leaves preferences
(accent, autoplay, preferred server, seen-intro) intact since those aren't
"personal data" in the GDPR sense.

---

## 🎥 Streaming Layer

[`lib/core/constants/streaming_servers.dart`](../lib/core/constants/streaming_servers.dart)
defines the streaming surface. The architecture is intentionally split into
two concepts:

### `StreamingBackend` — the URL builder

A `StreamingBackend` knows how to build a movie URL and a TV URL (with
season/episode). There are **6 distinct backends**, one per embed provider:

| # | Provider       | Movie URL                                    | TV URL                                                |
| :-: | :------------- | :------------------------------------------- | :---------------------------------------------------- |
| 0 | VidLink        | `https://vidlink.pro/movie/{id}`             | `https://vidlink.pro/tv/{id}/{s}/{e}`                 |
| 1 | VidSrc.me      | `https://vidsrc.me/embed/movie?tmdb={id}`    | `https://vidsrc.me/embed/tv?tmdb={id}&season={s}&episode={e}` |
| 2 | VidSrc.pro     | `https://vidsrc.pro/embed/movie/{id}`        | `https://vidsrc.pro/embed/tv/{id}/{s}/{e}`            |
| 3 | VidSrc.cc      | `https://vidsrc.cc/v2/embed/movie/{id}`      | `https://vidsrc.cc/v2/embed/tv/{id}/{s}/{e}`          |
| 4 | MultiEmbed     | `https://multiembed.mov/?video_id={id}&tmdb=1` | `https://multiembed.mov/?video_id={id}&tmdb=1&s={s}&e={e}` |
| 5 | Peachify       | `https://peachify.top/embed/movie/{id}`      | `https://peachify.top/embed/tv/{id}/{s}/{e}`          |

### `StreamingServer` — the branded entry the user sees

A `StreamingServer` is a named, flag-badged entry in the player's server
picker. There are **11 branded servers**, each pointing at one of the 6
backends (some backends are reused under different "brand" names, exactly as
the web app did):

| ID         | Name              | Flag      | Backend     |
| :--------- | :---------------- | :-------- | :---------- |
| `server-0` | Peachify          | `zap`     | Peachify    |
| `server-1` | Xstream           | `zap`     | VidLink     |
| `server-2` | Xstream Pro       | `zap`     | VidSrc.me   |
| `server-3` | Xstream Premium   | `star`    | VidSrc.pro  |
| `server-4` | Xstream Ultra     | `zap`     | VidSrc.cc   |
| `server-5` | Xstream Max       | `zap`     | MultiEmbed  |
| `server-6` | Turbo             | `us`      | VidLink     |
| `server-7` | NHD               | `india`   | VidSrc.me   |
| `server-8` | 4K                | `uk`      | VidSrc.pro  |
| `server-9` | Premium           | `us`      | VidSrc.cc   |
| `server-10`| MultiEmbed        | `australia` | MultiEmbed |

### Rendering

The Watch screen (`lib/features/watch/watch_screen.dart`) loads the chosen
server's URL inside a `WebView` from the `webview_flutter` package. The
WebView:

- Has JavaScript enabled (the embeds require it).
- Has its own cookie jar (separate from the app — and from Android's
  Chrome cookies).
- Cannot bridge to the Dart layer — the embeds are fully sandboxed.

The user can switch servers from the chip row at the top of the player; the
selection is persisted via `StorageActions.instance.setPreferredServer(id)`.

---

## 🧭 Routing — go_router

[`lib/core/router/app_router.dart`](../lib/core/router/app_router.dart) builds
the `GoRouter` used by `MaterialApp.router`. The structure is:

```
GoRouter
├── /splash                       (full-screen, no shell)
├── ShellRoute (hosts AppScaffold → bottom nav)
│   ├── /                         → HomeScreen
│   ├── /movies                   → MoviesScreen
│   ├── /series                   → SeriesScreen
│   ├── /anime                    → AnimeScreen
│   ├── /new-popular             → NewPopularScreen
│   ├── /search                   → SearchScreen
│   └── /profile                  → ProfileScreen
├── /details/:type/:id            (full-screen, no shell)  → DetailsScreen
├── /watch/:type/:id?s=&e=        (full-screen, no shell)  → WatchScreen
├── /person/:id                   (full-screen, no shell)  → PersonScreen
└── /company/:id                  (full-screen, no shell)  → CompanyScreen
```

### Why a shell route?

The shell route hosts the bottom navigation bar. Tabs (Home, Movies, Series,
Anime, New & Popular, Search, Profile) preserve their state when the user
switches between them, because they all live under the same `Navigator` inside
the shell. Watch / Details / Person / Company are pushed above the shell so the
bottom nav is hidden during immersion.

### Type-safe navigation

Route names live in the `AppRoute` class so call sites use
`context.goNamed(AppRoute.details, pathParameters: {'type': 'movie', 'id': '123'});`
instead of stringly-typed paths.

---

## 🎨 Theming — Dynamic Accent Color

[`lib/core/theme/app_colors.dart`](../lib/core/theme/app_colors.dart) and
[`lib/core/theme/app_theme.dart`](../lib/core/theme/app_theme.dart) define the
visual identity.

### Fixed palette

- **Background**: `#050505` (almost-black, cinematic)
- **Background elevated**: `#111114`
- **Background card**: `#16161A`
- **Surface glass**: `rgba(12,12,16,0.55)` — used for glassmorphic surfaces
- **Text primary/secondary/muted**: white / `#A3A3A3` / `#6B6B72`
- **Glass border**: `rgba(255,255,255,0.08)`
- **Rating colors**: green `#22C55E` (≥8), yellow `#EAB308` (6–7.9), red `#EF4444` (<6)
- **Row-title brand accents**: flame, star, tv, clapperboard, zap, calendar,
  sparkles, clock, crown, listPlus — one per content row.

### Accent overrides

The default accent is `#E50914` (Netflix-red) but the user can pick from 7
presets in Settings:

| Swatch        | Hex       |
| :------------ | :-------- |
| Xstream Red   | `#E50914` |
| Royal Blue    | `#2563EB` |
| Emerald       | `#10B981` |
| Purple        | `#8B5CF6` |
| Amber         | `#F59E0B` |
| Rose          | `#F43F5E` |
| Cyan          | `#06B6D4` |

### How it propagates

1. User taps a swatch → `StorageActions.instance.setAccent('#10B981')`.
2. `xs_accent` is written to `SharedPreferences`.
3. Storage listener fires → `_storageVersionProvider` bumps.
4. `accentColorProvider` re-runs → returns the new `Color`.
5. `XstreamApp` (the root `ConsumerWidget`) `ref.watch`es
   `accentColorProvider` and rebuilds the `ThemeData` with a fresh
   `ColorScheme.dark(primary: accent, secondary: accent, …)`.
6. `MaterialApp.router` propagates the new theme → every widget that uses
   `Theme.of(context).colorScheme.primary` updates instantly.

### Per-poster color extraction

For hero backgrounds, `palette_generator` extracts the dominant color from
each poster and feeds it into a `LinearGradient` — so the hero "feels" the
poster's palette. This is computed once per poster and cached in-memory.

### Typography

- **Bebas Neue** for display headings (`AppTextStyles.display`).
- **Inter** (6 weights: Regular, Medium, SemiBold, Bold, ExtraBold, Black) for
  everything else.
- Both fonts ship in `assets/fonts/` and are declared in `pubspec.yaml`.

---

## 🚀 Bootstrap Sequence

[`lib/app/bootstrap.dart`](../lib/app/bootstrap.dart) runs before the first
frame:

```dart
Future<void> bootstrap() async {
  configureSystemUi();              // edge-to-edge, transparent bars, light icons
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,   // phone-first cinematic experience
  ]);
  await StorageService.init();      // SharedPreferences.getInstance()
}
```

Then `main.dart` wraps the app in `ProviderScope` and runs `XstreamApp`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrap();
  runApp(const ProviderScope(child: XstreamApp()));
}
```

### First-launch flow

1. `bootstrap()` → system UI configured, storage initialized.
2. `XstreamApp` builds → routes to `/splash` if `hasSeenIntroProvider` is
   `false`.
3. Splash animation plays → `setSeenIntro()` → routes to `/` (Home).
4. Home renders → if `consentProvider` is `needsChoice`, the consent banner
   overlays the bottom of the screen.
5. User accepts/declines → personalization is enabled/disabled accordingly.

---

## 🧩 Adding a New Feature — Checklist

When adding a new screen or major feature, follow this checklist:

- [ ] Create `lib/features/<feature>/` with at least `<feature>_screen.dart`.
- [ ] Add the route in `lib/core/router/app_router.dart` (and an `AppRoute`
      name constant).
- [ ] Add any new TMDB calls to `lib/data/services/tmdb_service.dart` (or a
      new service for non-TMDB APIs).
- [ ] Add new Riverpod providers in `lib/shared/providers/app_providers.dart`
      (or a feature-local `providers.dart` for screen-local state).
- [ ] Add a model in `lib/data/models/` if needed — immutable, `fromJson`,
      `copyWith`.
- [ ] If the feature stores anything new, extend `StorageService` with a
      `xs_*` key and gate writes behind `isPersonalizationAllowed`.
- [ ] Run `dart format . && flutter analyze` — must be clean.
- [ ] Update [`CHANGELOG.md`](../CHANGELOG.md) `## [Unreleased]` → Added.
- [ ] Update the README's Features section if user-visible.
- [ ] Open a PR with a Conventional Commit message (`feat(<feature>): …`).

---

## ❓ Open Questions / Future Architecture Work

- **Repository layer** — `lib/data/repositories/` is reserved but unused.
  Services currently call TMDB directly from providers. If we add a second
  data source (e.g. Trakt), we'll need repositories to merge them.
- **Hive** — `hive` + `hive_flutter` are in `pubspec.yaml` but not yet used.
  Planned for offline caching of TMDB responses (roadmap).
- **Code generation** — `riverpod_generator`, `build_runner`, `hive_generator`
  are dev deps but not yet wired up. When we add `@riverpod` annotations,
  `build_runner` will generate `.g.dart` files (already excluded in
  `analysis_options.yaml`).
- **Tests** — the test suite is thin. Widget tests for the providers and
  model tests for `fromJson`/`copyWith` are the priority.

---

<p align="center">
  <em>Architecture is a hypothesis, not a doctrine. Question this document
  when the code disagrees — and update it when you change the code.</em>
</p>
