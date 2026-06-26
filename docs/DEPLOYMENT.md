# Deployment Guide

This guide covers the three things you need to ship Xstream:

1. **The backend proxy** → Render (free tier).
2. **The Android APK** → build, sign, publish.
3. **Distribution** → GitHub Releases and (optionally) the Google Play Store.

> 📌 **Prerequisites**: a [GitHub](https://github.com) account, a
> [Render](https://render.com) account (free), a [TMDB API key](https://www.themoviedb.org/settings/api),
> and a [Groq API key](https://console.groq.com). For Play Store distribution
> you'll also need a $25 [Google Play Developer account](https://play.google.com/console/signup).

---

## 📋 Table of Contents

1. [Backend → Render](#1-backend--render)
2. [App → APK Build](#2-app--apk-build)
3. [Signing the Release APK](#-signing-the-release-apk)
4. [Distribution → GitHub Releases](#3-distribution--github-releases)
5. [Distribution → Google Play Store](#4-distribution--google-play-store)
6. [Keep-Alive Ping for Render Free Tier](#-keep-alive-ping-for-render-free-tier)
7. [Rolling Back](#-rolling-back)
8. [Troubleshooting](#-troubleshooting)

---

## 1. Backend → Render

The `backend/` folder is a tiny Node.js/Express app. Its only job is to hide
your TMDB and Groq API keys behind a proxy. Full reference: [`API.md`](./API.md).

### Step-by-step

#### 1.1 Push `backend/` to a GitHub repo

The backend lives in this repo's `backend/` folder. Render needs its own repo
(or a subdirectory of one). Easiest path:

```bash
# Option A — push the whole xstream repo to GitHub
git remote add origin https://github.com/<your-username>/xstream.git
git push -u origin main

# Option B — push only backend/ as its own repo
cd backend
git init && git add . && git commit -m "feat: initial backend proxy"
git branch -M main
git remote add origin https://github.com/<your-username>/xstream-backend.git
git push -u origin main
```

> 💡 Render can deploy from a subdirectory — when you connect the repo, set
> **Root Directory** to `backend/` (Option A).

#### 1.2 Create a Web Service on Render

1. Log into [render.com](https://render.com).
2. **New +** → **Web Service**.
3. Connect your GitHub account and select the repo from step 1.1.
4. Configure:

   | Field                 | Value                                          |
   | :-------------------- | :--------------------------------------------- |
   | **Name**              | `xstream-api` (or whatever you like)            |
   | **Region**            | Closest to your users (e.g. `Oregon`)           |
   | **Branch**            | `main`                                          |
   | **Root Directory**    | `backend/` (Option A) or leave blank (Option B) |
   | **Runtime**           | `Node`                                          |
   | **Build Command**     | `npm install`                                   |
   | **Start Command**     | `node server.js`                                |
   | **Instance Type**     | `Free` (512 MB RAM, spins down after 15 min idle) |

5. Click **Advanced** and add environment variables:

   | Key              | Value                                              |
   | :--------------- | :------------------------------------------------- |
   | `TMDB_API_KEY`   | your TMDB v3 API key (`73b899e5…` style)            |
   | `GROQ_API_KEY`   | your Groq API key (`gsk_…` style)                   |
   | `PORT`           | `8080` (Render injects `PORT` automatically, but set it explicitly for local parity) |
   | `NODE_ENV`       | `production`                                       |
   | `CORS_ORIGIN`    | `*` (the Flutter app doesn't send an Origin header, but be permissive) |

6. Click **Create Web Service**. Render builds and deploys. Note the URL —
   it'll be `https://<name>.onrender.com` (e.g. `https://xstream-api.onrender.com`).

#### 1.3 Verify

```bash
# Health check
curl https://xstream-api.onrender.com/api/health
# → { "status": "ok", "tmdb": true, "groq": true, "uptime": 12.3 }

# TMDB proxy
curl 'https://xstream-api.onrender.com/api/tmdb/trending/movie/day'
# → { "page": 1, "results": [ … ] }

# AI recommend (takes a few seconds — Groq call)
curl 'https://xstream-api.onrender.com/api/ai/recommend?mood=feel-good&language=en'
# → [ { "title": "…", "match": 92, "reason": "…", … }, … ]
```

If all three return JSON, your backend is live. 🎉

#### 1.4 Point the app at your backend

```bash
flutter run --dart-define=BACKEND_URL=https://xstream-api.onrender.com
```

Or for a release build:

```bash
flutter build apk --release \
  --dart-define=BACKEND_URL=https://xstream-api.onrender.com
```

> ⚠️ **Render free-tier cold starts** — after 15 minutes of inactivity, the
> instance spins down. The next request takes ~30s to wake. The backend
> applies a 60-second in-memory cache for TMDB responses, which helps once
> warm, but the very first request after a cold start will be slow. See
> [Keep-Alive Ping](#-keep-alive-ping-for-render-free-tier) below to mitigate.

#### 1.5 Auto-deploy (recommended)

In Render → your service → **Settings** → enable **Auto-Deploy**. Every push
to `main` triggers a rebuild. Disable this if you prefer manual deploys via
the **Manual Deploy → Deploy latest commit** button.

---

## 2. App → APK Build

### 2.1 Prerequisites

- Flutter 3.3+ (`flutter --version`).
- Android SDK with **API 34** and **build-tools 34.0.0**.
- A connected device or emulator for testing (optional, but recommended).

### 2.2 Build a debug APK

```bash
flutter pub get
flutter build apk --debug \
  --dart-define=BACKEND_URL=https://xstream-api.onrender.com
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`

> Debug APKs are signed with the auto-generated debug keystore and are
> fine for testing but **not** for distribution.

### 2.3 Build a release APK

```bash
flutter build apk --release \
  --dart-define=BACKEND_URL=https://xstream-api.onrender.com
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

The release build runs ProGuard (`minifyEnabled true`, `shrinkResources true`,
see `android/app/build.gradle`) to strip unused code and shrink the APK.

### 2.4 Split per ABI (smaller APKs)

A universal release APK includes native code for `arm64-v8a`, `armeabi-v7a`,
and `x86_64` — most users only need one. Splitting produces 3 smaller APKs:

```bash
flutter build apk --release --split-per-abi \
  --dart-define=BACKEND_URL=https://xstream-api.onrender.com
```

Output:

- `app-armeabi-v7a-release.apk` — for older 32-bit ARM devices.
- `app-arm64-v8a-release.apk` — for modern 64-bit ARM devices (most phones).
- `app-x86_64-release.apk` — for emulators.

> 💡 For GitHub Releases, ship all 3 + the universal APK. For Play Store,
> upload an **AAB** (see below) instead — Google handles per-device splits
> automatically.

### 2.5 Build an App Bundle (AAB) for Play Store

```bash
flutter build appbundle --release \
  --dart-define=BACKEND_URL=https://xstream-api.onrender.com
```

Output: `build/app/outputs/bundle/release/app-release.aab`

> ⚠️ The AAB must be **signed with your upload key** before uploading. See
> [Signing the Release APK](#-signing-the-release-apk) below.

---

## 🔏 Signing the Release APK

By default, the release build is signed with the **debug keystore** (see
`android/app/build.gradle`: `signingConfig signingConfigs.debug`). This is
fine for personal testing but **unacceptable for distribution** — Android
will refuse to install an APK signed with a different key than the one
already installed, and Play Store requires a real upload key.

### 3.1 Generate a keystore

```bash
keytool -genkey -v -keystore ~/xstream-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias xstream
```

You'll be prompted for:

- A keystore password (keep this safe — losing it means you can never update
  the app on Play Store).
- A key alias (`xstream` is fine).
- A key password (can be the same as the keystore password).
- Your name, org, city, state, country.

> 🔐 **Back this file up.** Lose it and you can never ship an update to the
  same Play Store listing. Store it in a password manager or a USB stick in
  a drawer.

### 3.2 Reference it from `android/key.properties`

Create `android/key.properties` (this file is gitignored by default — verify
in `.gitignore`):

```properties
storePassword=********
keyPassword=********
keyAlias=xstream
storeFile=/Users/you/xstream-upload.jks
```

### 3.3 Wire it into `android/app/build.gradle`

Add at the top, above the `android {` block:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // … existing config …

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release   // ← was: signingConfigs.debug
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro"
        }
    }
}
```

### 3.4 Rebuild

```bash
flutter build apk --release \
  --dart-define=BACKEND_URL=https://xstream-api.onrender.com
```

The resulting APK is signed with your upload key. Verify with:

```bash
apksigner verify --verbose build/app/outputs/flutter-apk/app-release.apk
```

You should see `Verifies` and `Signed using v1 scheme: true` (and v2/v3).

> 📝 **The current project's `build.gradle` uses `signingConfigs.debug` for
> release** — this is a deliberate choice for first-time setup simplicity.
> Replace it before distributing. See
> [`android/app/build.gradle`](../android/app/build.gradle).

---

## 3. Distribution → GitHub Releases

The simplest way to distribute Xstream is via GitHub Releases. Users
sideload the APK (Android will warn about unknown sources — that's expected).

### 4.1 Tag a release

```bash
git tag -a v1.0.0 -m "Xstream 1.0.0 — Initial Android release"
git push origin v1.0.0
```

### 4.2 Create the release on GitHub

1. Go to **Releases → Draft a new release** on your repo.
2. Select the tag you just pushed (`v1.0.0`).
3. Title: `Xstream v1.0.0`.
4. Description: paste the relevant section from [`CHANGELOG.md`](../CHANGELOG.md).
5. Attach the APK(s):
   - `app-release.apk` (universal)
   - `app-arm64-v8a-release.apk` (smaller for most users)
   - `app-armeabi-v7a-release.apk` (for older devices)
   - `app-x86_64-release.apk` (for emulators)
6. Tick **Set as the latest release**.
7. **Publish release**.

### 4.3 Tell users how to install

In the release notes, include:

> ### How to install
> 1. Download the `app-arm64-v8a-release.apk` (most users) or
>    `app-release.apk` (universal).
> 2. On your phone, open the file (you may need to allow "Install from
>    unknown apps" for your browser/Files app).
> 3. Tap **Install**.
> 4. Open **Xstream** from your app drawer.

---

## 4. Distribution → Google Play Store

### 5.1 Sign up

- $25 one-time fee at [play.google.com/console/signup](https://play.google.com/console/signup).
- Verify your identity (Google requires DUNS for organizations, ID for
  individuals — takes a few days).

### 5.2 Create the app

1. **All apps → Create app**.
2. App name: **Xstream**.
3. Default language: English (US).
4. App type: **App** (not Game).
5. Free / Paid: **Free**.
6. Declarations: tick both. **Create app**.

### 5.3 Set up the app listing

Under **Grow → Store presence → Main store listing**:

| Field                      | Value                                                              |
| :------------------------- | :----------------------------------------------------------------- |
| App name                   | Xstream                                                            |
| Short description (80)     | Movies, series, anime & AI picks — privacy-first, no accounts.     |
| Full description (4000)    | _Paste from README's About + Features sections._                   |
| App icon                   | 512×512 PNG (use `assets/images/app_icon.png`, scaled up)          |
| Feature graphic            | 1024×500 JPG (use `assets/images/poster.jpg` or make a custom one) |
| Phone screenshots          | minimum 2, recommended 3–8 (1080×1920 or 16:9 aspect)              |
| App category               | Entertainment                                                      |
| Tags                       | `Movies`, `Streaming`, `TV Shows`                                  |
| Privacy Policy URL         | **Required** — host a `PRIVACY.md` on your repo's GitHub Pages     |

### 5.4 Privacy Policy

Google requires a hosted Privacy Policy URL before you can publish. The
simplest approach:

1. Create `docs/PRIVACY.md` (you can adapt [`SECURITY.md`](../SECURITY.md)).
2. Enable GitHub Pages on your repo (Settings → Pages → Source: `main` /
   `docs`).
3. Use the resulting URL: `https://<your-username>.github.io/xstream/PRIVACY.md`.

### 5.5 Content rating

Under **Policy and apps → App content**:

- **Target audience**: 18+ (some streaming embeds may serve mature ads).
- **Content rating**: fill out the IARC questionnaire (select "no" for
  everything user-generated — Xstream has none).
- **Ads**: yes, third-party stream embeds show ads. Tick the box.
- **App access**: not needed — no login.
- **Data safety**: this is critical. Fill it out accurately:

| Data collected           | Collected? | Purpose                            |
| :----------------------- | :--------: | :--------------------------------- |
| Approximate location     | No         | —                                  |
| Personal info (name, email) | No      | —                                  |
| Photos and videos        | No         | —                                  |
| App activity (search history, etc.) | No  | All stored locally only, never sent to us |
| App info and performance (crash logs) | No | —                                  |
| Device or other IDs      | No         | —                                  |

> ⚠️ Be honest here. Lying on the Data Safety form is a fast track to
> suspension. Xstream genuinely collects nothing — every byte of personal
> data stays on the user's device.

### 5.6 Upload the AAB

1. **Release → Production → Create new release**.
2. Upload `app-release.aab` (signed with your upload key — see
   [Signing](#-signing-the-release-apk)).
3. Release name: `1.0.0`.
4. Release notes: paste from `CHANGELOG.md`.
5. **Next** → review the rollout → **Start rollout to Production**.

### 5.7 Play App Signing (recommended)

When you first upload, Google will offer **Play App Signing** — let them
manage your app signing key. You keep your upload key (for signing AABs you
upload), Google re-signs with the app signing key for distribution. If you
lose your upload key, you can request a reset; without Play App Signing,
losing your keystore means a new package ID.

### 5.8 Review timeline

- First-time reviews typically take **1–3 days** for apps in Entertainment.
- You'll get an email when approved or if changes are required.
- Subsequent updates review in 1–24 hours.

---

## ⏰ Keep-Alive Ping for Render Free Tier

Render's free tier spins down after 15 minutes of inactivity. The next
request takes ~30s to wake. To keep the backend warm during peak hours,
set up a free cron ping.

### Via cron-job.org (recommended, free)

1. Sign up at [cron-job.org](https://cron-job.org).
2. **Create Cronjob**.
3. URL: `https://xstream-api.onrender.com/api/health`.
4. Schedule: **every 10 minutes** (free tier allows up to 1-minute intervals).
5. Save.

### Via GitHub Actions (alternative)

Create `.github/workflows/keepalive.yml`:

```yaml
name: Keep backend warm
on:
  schedule:
    - cron: '*/10 * * * *'   # every 10 minutes
jobs:
  ping:
    runs-on: ubuntu-latest
    steps:
      - run: curl -fsS https://xstream-api.onrender.com/api/health
```

> ⚠️ GitHub Actions scheduled workflows can be delayed by up to 30 minutes
> during peak load. cron-job.org is more reliable for this use case.

### Via UptimeRobot (alternative, free)

1. Sign up at [uptimerobot.com](https://uptimerobot.com).
2. **Add New Monitor** → type **HTTP(s)**.
3. URL: `https://xstream-api.onrender.com/api/health`.
4. Monitoring interval: **5 minutes** (free tier).
5. Save.

UptimeRobot doubles as an uptime dashboard — handy for seeing when Render
restarts your service.

---

## ↩ Rolling Back

### Backend

In Render → your service → **Deploys**, click any previous deploy →
**Roll back to this deploy**. Takes ~30 seconds.

### App (Play Store)

In Play Console → **Release → Production** → find the release → **Manage** →
**Release overview → Roll back**. Users will receive the previous version on
their next update check.

### App (GitHub Releases)

GitHub Releases can't be "rolled back" — users who downloaded v1.1.0 won't
automatically downgrade to v1.0.0. Instead:

1. Mark v1.1.0 as a **pre-release** (or delete it).
2. Mark v1.0.0 as **Latest** again.
3. Open a known-issues issue and pin it.

---

## 🧯 Troubleshooting

### Backend

| Symptom                                              | Fix                                                                                          |
| :--------------------------------------------------- | :------------------------------------------------------------------------------------------- |
| `curl /api/health` returns 502 / 503                 | Render is still spinning up. Wait 30s and retry. If persistent, check Render logs.           |
| `curl /api/tmdb/*` returns 401 from TMDB             | `TMDB_API_KEY` env var is missing or wrong. Set it in Render → Environment.                  |
| `curl /api/ai/recommend` returns 500                 | `GROQ_API_KEY` env var is missing, or Groq is rate-limiting you. Check logs.                  |
| First request after idle takes 30s+                  | Free-tier cold start. Set up a keep-alive ping (above).                                       |
| `CORS error` in browser console (web test only)      | Flutter apps don't send an Origin header, so CORS doesn't apply. If you're testing with curl
                                                         from a browser, set `CORS_ORIGIN=*` in Render env vars.                                       |

### App build

| Symptom                                              | Fix                                                                                          |
| :--------------------------------------------------- | :------------------------------------------------------------------------------------------- |
| `flutter build apk` fails with `minSdkVersion 21`    | Your Flutter SDK is older than the project requires. Run `flutter upgrade`.                   |
| `Could not resolve all files for configuration`      | Run `flutter clean && flutter pub get`.                                                       |
| APK installs but crashes immediately                 | Likely a missing `--dart-define=BACKEND_URL=…`. Check `adb logcat` for the crash.             |
| WebView shows a blank screen                         | The third-party embed is down. Try a different server in the player's chip row.               |
| `apksigner verify` fails                             | You're trying to verify a debug-signed APK. Build with `--release` after setting up signing. |
| Play Console rejects "app uses APK Signature Scheme v1 only" | Flutter ships v2+v3 by default. Rebuild with current Flutter. If still rejected, file a
                                                            Play Console support ticket.                                                              |

### Runtime

| Symptom                                              | Fix                                                                                          |
| :--------------------------------------------------- | :------------------------------------------------------------------------------------------- |
| App loads but posters don't appear                   | Check internet connectivity. TMDB image CDN (`image.tmdb.org`) must be reachable.             |
| "AI service unavailable" message                     | Backend can't reach Groq. Check `/api/health` `groq` field.                                    |
| History not saving                                   | You probably declined the consent gate. Profile → Settings → Re-enable personalization.       |
| Search returns no results                            | TMDB might be rate-limiting your backend. Wait a minute, retry.                                |

---

<p align="center">
  <em>Ship it. 🚀 And remember: a privacy-first app is a feature, not a
  limitation.</em>
</p>
