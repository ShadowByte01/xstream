# Changelog

All notable changes to **Xstream** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- _(nothing yet — contribute the next entry!)_

### Changed
- _(nothing yet)_

### Deprecated
- _(nothing yet)_

### Removed
- _(nothing yet)_

### Fixed
- _(nothing yet)_

### Security
- _(nothing yet)_

---

## [1.0.0] — 2026-06-26

### Summary

🎉 **Initial Android release.** Port all features from the Xstream React/Vite
web app into a production-ready Flutter app, backed by a Node.js/Express proxy
on Render's free tier. Privacy-first: no accounts, no analytics, all personal
data in `SharedPreferences` on the device.

### Added

#### 🎬 Streaming & Playback
- **11 branded streaming servers**: Peachify, Xstream, Xstream Pro, Xstream
  Premium, Xstream Ultra, Xstream Max, Turbo, NHD, 4K, Premium, MultiEmbed —
  each backed by 6 distinct embed providers (VidLink, VidSrc, VidSrc.pro,
  VidSrc.cc, MultiEmbed, Peachify).
- **WebView-based player** (`webview_flutter`) rendering the same third-party
  embeds the web app used.
- **Season & episode selector** for TV shows with poster thumbnails per season.
- **Fullscreen player** with landscape lock, wake-lock, and hardware
  back-button to exit fullscreen.
- **Autoplay next episode** (toggleable in Settings).
- **One-tap server switching** when a provider is slow or down.

#### 🧭 Browsing & Discovery
- **Home** page with hero carousel, Continue Watching, Most Viewed, Trending
  Now, AI section, My List, Top Rated, Action, Animation.
- **Movies / Series / Anime / New & Popular** pages, each with horizontal
  genre chips and infinite-scroll grids.
- **Search** with multi-search (movies + TV), media-type filter chips, and
  infinite-scroll pagination.
- **Details** page: synopsis, cast carousel, trailers grid, TMDB rating +
  personal 5-star rating, where-to-watch providers, keywords, similar titles,
  production companies, networks.
- **Person** pages with actor biography + filmography (movie & TV credits).
- **Company** pages with studio logo, description, and top movies by popularity.

#### 🤖 AI-Powered Recommendations
- **XAI Recommends** — pick a mood (Feel Good, Emotional, Mind-Bending,
  Adrenaline, Chill & Cozy), optionally add custom free-text, pick a language
  (EN/HI/KO/ES/JA/FR), and get **15 AI-curated movie picks** with a match
  percentage (80–99%) and a one-line reason for each.
- Powered by **Groq's `llama-3.3-70b-versatile`** via the backend proxy.
- Each recommendation is enriched with TMDB metadata (poster, rating,
  overview) before display.

#### 👤 Personalization (all local, all privacy-gated)
- **Watch History** — last 60 titles with progress bars and season/episode
  markers for TV.
- **My List** — bookmark anything for later.
- **Likes** — a separate tap-to-like stream.
- **Personal 5-star ratings** — your rating overlays the TMDB score.
- **Most Viewed Badge** — the title you've watched the most gets a crown;
  Profile highlights your top 10.
- **Cookie-consent gate** on first launch — decline and the app stores
  nothing personal at all.

#### 🎨 Theming & UI
- **Cinematic dark-first design** with `#050505` base, glassmorphic surfaces,
  hairline borders.
- **Dynamic accent theming** — 7 preset swatches (Xstream Red, Royal Blue,
  Emerald, Purple, Amber, Rose, Cyan) switchable from Settings; the entire
  `ColorScheme` rebuilds instantly.
- **Per-poster color extraction** via `palette_generator` for hero gradients
  that match the artwork.
- **Bebas Neue + Inter** typography pairing.
- **Spring physics** animations, edge-to-edge system bars, splash intro
  animation on first launch.

#### 🏗 Architecture & Infrastructure
- **Flutter 3.3+ / Dart 3.3+** codebase with sound null safety.
- **Riverpod 2.5** for state management — providers in
  `lib/shared/providers/app_providers.dart`.
- **go_router 14** with a shell route hosting the bottom nav, plus
  full-screen routes for Details / Watch / Person / Company.
- **Dio 5.5** HTTP client with `--dart-define=BACKEND_URL` injection.
- **SharedPreferences** storage layer (`xs_` namespace, ported from the web
  app's `localStorage` keys).
- **Node.js/Express backend proxy** (`backend/`) that hides the TMDB and Groq
  API keys, with a short in-memory cache to absorb Render cold-start latency.
- **GitHub Actions CI** (`.github/workflows/flutter.yml`) running
  `flutter pub get` + `flutter analyze` on every push/PR to `main`.
- **Issue templates** (bug report, feature request) and a **PR template**.
- **MIT License**, **Code of Conduct** (Contributor Covenant 2.1),
  **Contributing guide**, **Security policy**.

#### 🔒 Privacy
- **No accounts, no analytics SDKs, no cloud sync.**
- **API keys never ship inside the APK** — they live on the backend.
- **One-tap Clear All Data** from Profile.
- Android `allowBackup="false"` and `fullBackupContent="false"` — no ADB
  backup of personal data.

### Android Manifest Permissions
- `INTERNET` — required for API + image CDN + streaming embeds.
- `ACCESS_NETWORK_STATE` — used by `connectivity_plus` for offline detection.
- `WAKE_LOCK` — keeps the screen on while watching.

### Minimum Requirements
- **Android 5.0 (API 21)** or higher.
- **Target SDK 34** (Android 14).
- **ARM, ARM64, x86_64** supported.

### Known Limitations
- Phone-only, portrait-locked (tablet/foldable layout is on the roadmap).
- No offline mode yet (planned).
- No widget tests yet (planned).
- Backend free-tier on Render can take ~30s to wake from cold start; the
  in-memory cache mitigates this once warm.

### Credits
- Original web app by **Abhinit Kumar / XHub**.
- Metadata by **TMDB**.
- AI recommendations by **Groq** (`llama-3.3-70b-versatile`).

---

## Versioning Reference

Given a version `MAJOR.MINOR.PATCH`:

- **MAJOR** — incompatible API changes (e.g. switching state management,
  rewriting the backend protocol).
- **MINOR** — new features, backwards-compatible (a new screen, a new server).
- **PATCH** — bug fixes, backwards-compatible.

Pre-release versions append `-alpha.N`, `-beta.N`, `-rc.N` (e.g.
`1.1.0-beta.2`).

---

[Unreleased]: https://github.com/<your-org>/xstream/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/<your-org>/xstream/releases/tag/v1.0.0
