<p align="center">
  <img src="./assets/images/poster.jpg" alt="Xstream — Cinematic streaming for Android" width="100%" />
</p>

<h1 align="center">🎬 Xstream</h1>

<p align="center">
  <em>A Premium, Privacy-First Cinematic Streaming Experience for Android</em>
</p>

<p align="center">
  <a href="https://flutter.dev"><img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.3%2B-02569B?style=for-the-badge&logo=flutter&logoColor=white" /></a>
  <a href="https://dart.dev"><img alt="Dart" src="https://img.shields.io/badge/Dart-3.3%2B-0175C2?style=for-the-badge&logo=dart&logoColor=white" /></a>
  <a href="https://www.android.com"><img alt="Android" src="https://img.shields.io/badge/Android-5.0%2B-3DDC84?style=for-the-badge&logo=android&logoColor=white" /></a>
  <a href="https://riverpod.dev"><img alt="Riverpod" src="https://img.shields.io/badge/Riverpod-2.5-1C1C24?style=for-the-badge&logo=dart&logoColor=white" /></a>
  <a href="https://render.com"><img alt="Render" src="https://img.shields.io/badge/Backend-Render-46E3B7?style=for-the-badge&logo=render&logoColor=black" /></a>
  <a href="https://www.themoviedb.org/"><img alt="TMDB" src="https://img.shields.io/badge/Data-TMDB-01B4E4?style=for-the-badge&logo=themoviedatabase&logoColor=white" /></a>
  <a href="https://groq.com"><img alt="Groq" src="https://img.shields.io/badge/AI-Groq-F55036?style=for-the-badge&logo=groq&logoColor=white" /></a>
  <a href="./LICENSE"><img alt="License" src="https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge&logo=opensource&logoColor=white" /></a>
  <img alt="Made with Love" src="https://img.shields.io/badge/Made%20with-%E2%9D%A4-red?style=for-the-badge" />
</p>

<p align="center">
  <a href="#about">About</a> ·
  <a href="#-features">Features</a> ·
  <a href="#-tech-stack">Tech Stack</a> ·
  <a href="#-project-structure">Project Structure</a> ·
  <a href="#-getting-started">Getting Started</a> ·
  <a href="#-configuration">Configuration</a> ·
  <a href="#-privacy-first">Privacy</a> ·
  <a href="#-roadmap">Roadmap</a> ·
  <a href="#-contributing">Contributing</a>
</p>

---

## 📖 Table of Contents

1. [About](#about)
2. [Screenshots](#-screenshots)
3. [Features](#-features)
4. [Tech Stack](#-tech-stack)
5. [Project Structure](#-project-structure)
6. [Getting Started](#-getting-started)
7. [Configuration](#-configuration)
8. [Backend Deployment](#-backend-deployment)
9. [Building the APK](#-building-the-apk)
10. [Watch Page Shortcuts](#-watch-page-shortcuts)
11. [Privacy First](#-privacy-first)
12. [Roadmap](#-roadmap)
13. [Contributing](#-contributing)
14. [License](#-license)
15. [Credits](#-credits)

---

## About

**Xstream** is a premium, privacy-first cinematic streaming app for Android, built with Flutter. It was ported from a popular React/Vite web app into a fully native mobile experience — same dark, glassmorphic aesthetic, same 11-server streaming engine, same AI-powered mood recommendations, now wrapped in a buttery-smooth Flutter UI tuned for touch.

### Why Android (and why Flutter)?

The original Xstream was a Progressive Web App — fast, beautiful, but locked inside a browser tab. The Android port brings it home:

- 📱 **Native phone experience** — edge-to-edge rendering, immersive fullscreen playback, system back-button support, persistent bottom navigation.
- 🎬 **Cinematic UI** — Flutter gives us 120 fps spring animations, glassmorphism and per-poster color extraction with zero DOM overhead.
- 🔒 **Privacy by default** — no accounts, no analytics SDKs, no cloud sync. Every like, rating and watch-progress entry lives in `SharedPreferences` on the device itself.
- 🚀 **One codebase, one APK** — Dart compiles to native ARM; no JavaScript bridge, no web view for the UI layer (only for the third-party stream embeds).

### The Privacy-First Philosophy

Xstream never asks you to sign up. There is no Xstream account, no Xstream database, no Xstream cookies. The only network calls the app makes are:

1. To **your own backend proxy** (deployed on Render's free tier) which forwards requests to **TMDB** (metadata) and **Groq** (AI recommendations).
2. To **TMDB's image CDN** (`image.tmdb.org`) for posters and backdrops.
3. To the **third-party streaming embeds** you choose in the player (VidLink, VidSrc, Peachify, etc.) — the same embeds the web app used, just rendered inside an Android `WebView`.

The app shows a cookie-consent gate on first launch. Decline, and we don't store any history, watchlist, likes or ratings at all. Accept, and everything stays on your phone — wipeable from **Profile → Clear All Data** in one tap.

---

## 📸 Screenshots

> 🚧 **Add your screenshots here.** Drop them in `docs/screenshots/` and update the table below.
>
> | Home | Details | Watch |
> | :--: | :-----: | :---: |
> | _coming soon_ | _coming soon_ | _coming soon_ |
>
> | Profile | AI Recommend | Search |
> | :-----: | :----------: | :----: |
> | _coming soon_ | _coming soon_ | _coming soon_ |

---

## ✨ Features

### 🎨 Cinematic UI

- 🌑 **Dark-first design** with a deep `#050505` base, glassmorphic surfaces, hairline borders.
- 🎨 **Dynamic accent theming** — 7 preset swatches (Xstream Red, Royal Blue, Emerald, Purple, Amber, Rose, Cyan) switchable from Settings; the entire `ColorScheme` rebuilds instantly.
- 🖼️ **Per-poster color extraction** via `palette_generator` for hero gradients that match the artwork.
- 🔤 **Bebas Neue + Inter** typography pairing for that cinematic-poster look.
- 💫 **Spring physics** animations, edge-to-edge system bars, splash intro animation on first launch.

### 🧭 Content Browsing

- 🏠 **Home** — hero carousel, Continue Watching, Most Viewed, Trending Now, AI section, My List, Top Rated, Action, Animation, plus a smart 5-row rotation.
- 🎬 **Movies / Series / Anime / New & Popular** pages, each with horizontal genre chips and infinite-scroll grids.
- 🔍 **Search** — multi-search across movies & TV, with media-type filter chips and infinite scroll pagination.
- 📄 **Details page** — full synopsis, cast carousel, trailers grid, ratings (TMDB vote average + your personal 5-star rating), where-to-watch providers, keywords, similar titles, production companies, networks.
- 🧑‍🎤 **Person pages** — actor biography + filmography (movie & TV credits).
- 🏢 **Company pages** — studio logo, description, and top movies by popularity.

### ▶️ Advanced Playback

- 🎥 **11 branded streaming servers** — Peachify, Xstream, Xstream Pro, Xstream Premium, Xstream Ultra, Xstream Max, Turbo, NHD, 4K, Premium, MultiEmbed — each with its own flag badge.
- 🔄 **One-tap server switching** if a provider is down or slow.
- 📺 **Season & episode selector** for TV shows, with poster thumbnails per season.
- ⛶ **Fullscreen player** with landscape lock, wake-lock, and hardware back-button to exit fullscreen.
- ⏭️ **Autoplay next episode** (toggleable) for binge sessions.
- 🎯 **Continue Watching** progress tracking (capped at 60 entries to keep storage small).

### 🤖 AI-Powered

- ✨ **XAI Recommends** — pick a mood (Feel Good, Emotional, Mind-Bending, Adrenaline, Chill & Cozy), optionally add custom free-text, pick a language (EN/HI/KO/ES/JA/FR), and get **15 AI-curated movie picks** with a match percentage and a one-line reason for each.
- 🦙 Powered by **Groq's `llama-3.3-70b-versatile`** — sub-second inference on Groq's LPU infrastructure.
- 🎯 Each recommendation is enriched with TMDB metadata (poster, rating, overview) before display.

### 🔒 Privacy-First

- 🚫 **No accounts, no analytics, no trackers**.
- 🍪 **Cookie-consent gate** on first launch — decline and the app stores nothing personal.
- 💾 **All data in `SharedPreferences`** — history, watchlist, likes, 5-star ratings, view counts, accent color, autoplay preference, preferred server.
- 🧹 **One-tap Clear All Data** from Profile.
- 🛡️ **Backend proxy hides API keys** — the TMDB key and Groq key never ship inside the APK.

### 👤 Personalization

- 📚 **Watch History** — last 60 titles, with progress bars and season/episode markers for TV.
- ⭐ **My List** — bookmark anything for later.
- ❤️ **Likes** — a separate tap-to-like stream.
- 🌟 **Personal 5-star ratings** — your own rating overlays the TMDB score.
- 👑 **Most Viewed Badge** — the title you've watched the most gets a crown; Profile highlights your top 10.

---

## 🧰 Tech Stack

| Layer            | Technology                                                       | Why                                                            |
| :--------------- | :--------------------------------------------------------------- | :------------------------------------------------------------- |
| Framework        | [Flutter](https://flutter.dev) 3.3+                              | One codebase, native ARM, gorgeous custom UIs                  |
| Language         | [Dart](https://dart.dev) 3.3+                                    | Sound null safety, AOT compilation                             |
| State management | [Riverpod](https://riverpod.dev) 2.5                             | Compile-safe, testable, no `BuildContext` coupling             |
| Routing          | [go_router](https://pub.dev/packages/go_router) 14              | Declarative, deep-linkable, shell routes for bottom nav        |
| HTTP client      | [Dio](https://pub.dev/packages/dio) 5.5                          | Interceptors, timeouts, clean error surface                    |
| Local storage    | [SharedPreferences](https://pub.dev/packages/shared_preferences) | Privacy-first, no DB, no cloud                                 |
| Video playback   | [webview_flutter](https://pub.dev/packages/webview_flutter) 4.8  | Renders the same third-party embeds the web app used           |
| Image loading    | [cachedNetworkImage](https://pub.dev/packages/cached_network_image) 3.4 | Memory + disk caching, fade-ins                          |
| Color extraction | [palette_generator](https://pub.dev/packages/palette_generator)  | Dynamic hero gradients from each poster                        |
| Backend          | [Node.js](https://nodejs.org) + [Express](https://expressjs.com) | Tiny proxy that hides API keys                                 |
| Backend host     | [Render](https://render.com) (free tier)                         | Zero-ops, free SSL, generous free hours                        |
| Metadata API     | [TMDB](https://www.themoviedb.org/)                              | The gold standard for movie/TV data                            |
| AI               | [Groq](https://groq.com) — `llama-3.3-70b-versatile`             | Fast, free-tier LLM for mood-based recommendations             |
| Icons            | Material + cupertino_icons                                       | Native feel                                                    |
| Linting          | [flutter_lints](https://pub.dev/packages/flutter_lints) 4.0      | Strict, consistent code style                                  |

---

## 🗂 Project Structure

```
xstream/
├── android/                         # Native Android shell (Gradle, Kotlin, Manifest)
│   └── app/src/main/
│       ├── AndroidManifest.xml      # INTERNET + WAKE_LOCK permissions, edge-to-edge
│       ├── kotlin/com/xstream/app/  # MainActivity.kt
│       └── res/                     # launcher icons, splash, themes
├── assets/
│   ├── images/                      # poster.jpg, logo.png, app_icon.png
│   └── fonts/                       # Inter (6 weights) + BebasNeue
├── backend/                         # Node.js/Express proxy (deploy to Render)
├── docs/
│   ├── ARCHITECTURE.md              # high-level + data flow
│   ├── DEPLOYMENT.md                # Render + APK + Play Store + GitHub Releases
│   └── API.md                       # backend endpoint reference
├── lib/
│   ├── main.dart                    # entrypoint — ProviderScope + bootstrap()
│   ├── app/
│   │   ├── app.dart                 # XstreamApp — MaterialApp.router + theme
│   │   └── bootstrap.dart           # system UI, orientation, StorageService.init()
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart   # BACKEND_URL, image CDN, storage keys
│   │   │   └── streaming_servers.dart  # 11 branded servers, 6 distinct backends
│   │   ├── router/
│   │   │   └── app_router.dart      # go_router config + AppRoute names
│   │   ├── theme/
│   │   │   ├── app_colors.dart      # palette, 7 accent swatches, rating colors
│   │   │   └── app_theme.dart       # ThemeData, typography, system UI
│   │   └── utils/                   # (helpers)
│   ├── data/
│   │   ├── models/                  # MediaItem, MediaDetail, Person, AiRecommendation
│   │   ├── repositories/            # (repository layer)
│   │   └── services/
│   │       ├── api_client.dart      # Dio singleton, base URL = BACKEND_URL
│   │       ├── tmdb_service.dart    # all /api/tmdb/* calls
│   │       ├── ai_service.dart      # /api/ai/recommend
│   │       └── storage_service.dart # SharedPreferences, privacy-gated
│   ├── features/                    # one folder per screen
│   │   ├── splash/                  # IntroSplash animation
│   │   ├── home/                    # Home + hero carousel + rows
│   │   ├── movies/                  # Movies page with genre filters
│   │   ├── series/                  # Series page
│   │   ├── anime/                   # Anime page
│   │   ├── new_popular/             # New & Popular
│   │   ├── search/                  # infinite-scroll search
│   │   ├── details/                 # full details page
│   │   ├── watch/                   # WebView player + server picker
│   │   ├── profile/                 # history, my list, likes, ratings, settings
│   │   ├── person/                  # actor filmography
│   │   ├── company/                 # studio page
│   │   └── ai_recommend/            # XAI mood picker + results
│   └── shared/
│       ├── providers/
│       │   └── app_providers.dart   # all Riverpod providers + StorageActions
│       └── widgets/                 # AppScaffold, MovieCard, etc.
├── .github/
│   ├── workflows/flutter.yml        # CI: pub get + analyze
│   ├── ISSUE_TEMPLATE/              # bug_report.md, feature_request.md
│   └── PULL_REQUEST_TEMPLATE.md
├── pubspec.yaml                     # deps, fonts, assets, launcher icons
├── analysis_options.yaml            # flutter_lints + custom rules
├── LICENSE                          # MIT
├── README.md                        # you are here
├── CHANGELOG.md
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
└── SECURITY.md
```

---

## 🚀 Getting Started

### Prerequisites

| Tool                       | Version  | Notes                                                  |
| :------------------------- | :------- | :----------------------------------------------------- |
| [Flutter](https://flutter.dev) | 3.3+ | `flutter --version` should report Dart 3.3+           |
| Dart                       | 3.3+     | Ships with Flutter                                      |
| [Android Studio](https://developer.android.com/studio) | latest | Or just the Android SDK + command-line tools |
| An Android device or emulator | API 21+ (Android 5.0+) | Enable USB debugging on a real device   |
| A **TMDB API key**         | v3 auth  | Free at [themoviedb.org/settings/api](https://www.themoviedb.org/settings/api) |
| A **Groq API key**         | free tier | Free at [console.groq.com](https://console.groq.com)   |
| (Optional) [Render](https://render.com) account | free | To host the backend proxy |

### Installation

```bash
# 1. Clone the repo
git clone https://github.com/<your-org>/xstream.git
cd xstream

# 2. Install Flutter dependencies
flutter pub get

# 3. Generate launcher icons (already configured in pubspec.yaml)
dart run flutter_launcher_icons:main

# 4. Run on a connected device / emulator
flutter run --dart-define=BACKEND_URL=https://your-backend.onrender.com
```

> 💡 While developing the backend locally, point `BACKEND_URL` at the Android emulator's host alias:
>
> ```bash
> flutter run --dart-define=BACKEND_URL=http://10.0.2.2:8080
> ```

---

## ⚙️ Configuration

### `BACKEND_URL` (required at build time)

The app never contains your TMDB or Groq keys. Instead it talks to your own backend proxy, whose URL is injected via `--dart-define`:

```bash
# Debug
flutter run --dart-define=BACKEND_URL=https://xstream-api.onrender.com

# Release APK
flutter build apk --release \
  --dart-define=BACKEND_URL=https://xstream-api.onrender.com
```

The default fallback in `lib/core/constants/app_constants.dart` is `https://xstream-api.onrender.com` — change it or always pass `--dart-define` to be safe.

### TMDB image CDN

Hardcoded to `https://image.tmdb.org/t/p` (the public CDN). No key needed.

---

## 🛠 Backend Deployment

The `backend/` folder contains a tiny Node.js/Express app that:

- Proxies every `/api/tmdb/*` path to `https://api.themoviedb.org/3/*`
- Exposes `/api/ai/recommend` which builds a prompt and calls Groq
- Exposes `/api/health` for uptime pings
- Applies a short in-memory cache to absorb Render cold-start latency

**Quick deploy:**

1. Push the `backend/` folder to a new GitHub repo (or a subdirectory of this one).
2. On [render.com](https://render.com) → **New → Web Service** → connect the repo.
3. Set env vars: `TMDB_API_KEY`, `GROQ_API_KEY`, `PORT=8080`.
4. Deploy. Note the URL — it's your `BACKEND_URL`.

For full step-by-step instructions (including the keep-alive ping via [cron-job.org](https://cron-job.org) so the free-tier instance doesn't sleep), see **[docs/DEPLOYMENT.md](./docs/DEPLOYMENT.md)** and **[backend/README.md](./backend/README.md)**.

---

## 📦 Building the APK

### Debug APK

```bash
flutter build apk --debug \
  --dart-define=BACKEND_URL=https://xstream-api.onrender.com
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`

### Release APK

```bash
flutter build apk --release \
  --dart-define=BACKEND_URL=https://xstream-api.onrender.com
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

The release build is configured (in `android/app/build.gradle`) with `minifyEnabled` + `shrinkResources` + ProGuard rules to strip unused code. For distribution you should sign the APK with your own keystore — see [docs/DEPLOYMENT.md](./docs/DEPLOYMENT.md#-signing-the-release-apk).

### Split per ABI (smaller APKs)

```bash
flutter build apk --release --split-per-abi \
  --dart-define=BACKEND_URL=https://xstream-api.onrender.com
```

Produces separate `arm64-v8a`, `armeabi-v7a`, and `x86_64` APKs.

---

## ⌨️ Watch Page Shortcuts

The Watch screen is built around an embedded `WebView`, so most interactions are touch-based. There are a few hardware/system shortcuts worth knowing:

| Action                         | How                                                            |
| :----------------------------- | :------------------------------------------------------------- |
| **Exit fullscreen**            | Press the system **Back** button, or tap the in-player ✕      |
| **Exit the Watch page**        | Press **Back** when not in fullscreen                          |
| **Switch streaming server**    | Tap the server chip row at the top of the player              |
| **Change season / episode**    | Tap the season/episode dropdown below the player (TV only)    |
| **Open cast member**           | Tap any cast card → goes to the Person page                    |
| **Add to My List / Like**      | Tap the ♡ / 📑 buttons in the action bar                       |
| **Rate 1–5 stars**             | Tap the star row in the action bar                            |
| **Share**                      | Tap the share icon (uses `share_plus`)                        |

> 💡 The watch page locks to portrait for the metadata strip; rotate the device (or tap the fullscreen button in the embed) to go landscape for the actual playback.

---

## 🔐 Privacy First

| Question                                   | Answer                                                                                              |
| :----------------------------------------- | :-------------------------------------------------------------------------------------------------- |
| Do I need an account?                      | **No.** Never.                                                                                       |
| Where is my history stored?                | In `SharedPreferences` on **your phone only**.                                                       |
| Do you sync my data to a cloud?            | **No.** Uninstalling the app = data gone forever.                                                    |
| What if I decline the consent gate?        | The app refuses to write any history, watchlist, likes, ratings or view counts. Browsing still works. |
| Can I wipe everything?                     | Yes — **Profile → Clear All Data** in one tap.                                                       |
| Do you collect analytics or crash logs?    | **No.** Zero analytics SDKs are bundled.                                                             |
| What network calls does the app make?      | (1) your backend proxy, (2) TMDB image CDN, (3) the third-party stream embed you pick in the player. |
| Why do the API keys live on the backend?   | So they never ship inside the APK. Decompile it all you want — no keys to find.                      |
| What about the third-party stream embeds?  | Those are external services (VidLink, VidSrc, Peachify, etc.). They set their own cookies. We can't and don't control them. |

For vulnerabilities and disclosure, see **[SECURITY.md](./SECURITY.md)**.

---

## 🗺 Roadmap

- [x] Port all 11 web screens to Flutter
- [x] Riverpod state, go_router shell route, SharedPreferences privacy layer
- [x] 11 branded streaming servers via WebView
- [x] Groq-powered AI recommendations with mood + language
- [x] Dynamic accent theming (7 presets)
- [x] Render backend proxy with in-memory cache
- [ ] Cast & Crew deep-linking from every card
- [ ] Offline mode — cache last 24h of TMDB responses
- [ ] Watch progress sync across devices via encrypted local export/import
- [ ] Material You monochrome icon
- [ ] Tablet / foldable layout (currently phone-only, portrait-locked)
- [ ] Widget tests for the providers and services
- [ ] Play Store listing assets (screenshots, feature graphic)
- [ ] F-Droid build recipe

Have an idea? Open a [feature request](https://github.com/<your-org>/xstream/issues/new?template=feature_request.md).

---

## 🤝 Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

Please read **[CONTRIBUTING.md](./CONTRIBUTING.md)** for the workflow (fork → branch → conventional commit → PR), code style expectations, and the issue/PR templates. By participating you agree to abide by our **[Code of Conduct](./CODE_OF_CONDUCT.md)**.

### Quick start for contributors

```bash
# Fork & clone your fork, then:
git checkout -b feature/my-awesome-feature
flutter pub get
flutter analyze          # must pass with zero issues
flutter run --dart-define=BACKEND_URL=http://10.0.2.2:8080

# Make changes, commit with Conventional Commits:
git commit -m "feat(watch): add double-tap-to-seek gesture"

git push origin feature/my-awesome-feature
# Then open a PR against `main`.
```

---

## 📄 License

Distributed under the **MIT License**. See **[LICENSE](./LICENSE)** for the full text.

```
MIT License
Copyright (c) 2026 Abhinit Kumar & XHub
```

---

## 🙏 Credits

Xstream wouldn't exist without:

- **[Abhinit Kumar / XHub](https://github.com/)** — original author of the Xstream React/Vite web app this Android port is based on. 🙌
- **[TMDB](https://www.themoviedb.org/)** — for the incredible, community-maintained movie & TV metadata. Please consider [contributing](https://www.themoviedb.org/bible) to TMDB.
- **[Groq](https://groq.com)** — for the absurdly fast LPU inference that powers the XAI mood recommendations.
- **[Flutter](https://flutter.dev)** & **[Dart](https://dart.dev)** teams — for the best cross-platform toolkit on the planet.
- **[Render](https://render.com)** — for a generous free tier that lets hobby projects ship real backends.
- The maintainers of every pub.dev package listed in `pubspec.yaml`. 💙
- The third-party embed providers (VidLink, VidSrc, Peachify, MultiEmbed, etc.) — without whom there'd be nothing to watch.

> ⚠️ **Disclaimer:** Xstream is a metadata and player-shell app. It does not host, stream or transmit any video content itself — all playback is rendered from third-party embeds inside an Android WebView. All movie/TV metadata is provided by TMDB. Xstream is not affiliated with TMDB, Groq, Netflix or any streaming provider. Use responsibly and in accordance with your local laws.

---

<p align="center">
  Made with ❤️ by the Xstream community
</p>
