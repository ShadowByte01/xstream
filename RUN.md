# 🚀 Xstream — Step-by-Step Run Guide

> **Read this first.** This is the only guide you need to get Xstream running on your phone.
> Total time: **~30 minutes** (most of it is waiting for Render to deploy).

---

## 📋 What You'll End Up With

- A **backend API** running on Render (free) that hides your TMDB + Groq API keys
- The **Xstream Android app** running on your phone/emulator, streaming movies & series

---

## 🛠️ Prerequisites (install these first)

| # | Tool | Why | Download |
|---|------|-----|----------|
| 1 | **Flutter 3.3+** | Builds the Android app | https://docs.flutter.dev/get-started/install |
| 2 | **Android Studio** (or just the Android SDK) | Android emulator + SDK | https://developer.android.com/studio |
| 3 | **Node.js 18+** | Runs the backend locally (optional) | https://nodejs.org/ |
| 4 | **Git** | Clone the repo | https://git-scm.com/ |
| 5 | A **TMDB account** (free) | Get a movie database API key | https://www.themoviedb.org/ |
| 6 | A **Groq account** (free) | Get an AI API key for recommendations | https://console.groq.com/ |
| 7 | A **Render account** (free) | Host the backend | https://render.com/ |

### Verify Flutter is installed

Open a terminal and run:

```bash
flutter --version
flutter doctor
```

Make sure `flutter doctor` shows **green checkmarks** for at least **Flutter** and **Android toolchain**. If it shows red, follow the hints it gives you.

---

## 📥 Step 1 — Unzip & explore the project

1. Unzip `xstream.zip` to any folder, e.g. `~/projects/`:

   ```bash
   # macOS / Linux
   unzip xstream.zip -d ~/projects/
   cd ~/projects/xstream

   # Windows (PowerShell)
   Expand-Archive xstream.zip -DestinationPath C:\projects\
   cd C:\projects\xstream
   ```

2. The folder structure should look like this:

   ```
   xstream/
   ├── lib/              ← Flutter app source (39 Dart files)
   ├── backend/          ← Node.js API proxy (deploys to Render)
   ├── android/          ← Android native config
   ├── assets/           ← Logo + poster images
   ├── docs/             ← Architecture, deployment, API docs
   ├── pubspec.yaml      ← Flutter dependencies
   ├── README.md         ← Full project readme
   ├── RUN.md            ← This file
   ├── LICENSE           ← MIT
   └── ...                ← CODE_OF_CONDUCT, CONTRIBUTING, etc.
   ```

---

## 🔑 Step 2 — Get your free API keys

### 2a. TMDB API key (for movie/TV data)

1. Go to **https://www.themoviedb.org/** → sign up (free)
2. Go to **Settings → API** → click **"Request API Key"**
3. Choose **Developer** key
4. Accept the terms, fill any application URL (use `https://example.com`)
5. Copy your **API Key (v3 auth)** — it looks like `73b899e5db067b7de7fd3c8f32be0710`

   > 📝 Save this somewhere — you'll paste it into Render in Step 3.

### 2b. Groq API key (for AI recommendations)

1. Go to **https://console.groq.com/** → sign in (free)
2. Go to **API Keys** → click **"Create API Key"**
3. Name it `xstream` → **Create**
4. Copy the key — it starts with `gsk_...`

   > 📝 Save this too — you'll paste it into Render in Step 3.

---

## ☁️ Step 3 — Deploy the backend to Render (FREE)

This is the most important step. The backend hides your API keys so they're NOT inside the APK.

### 3a. Push the project to GitHub

1. Create a **new GitHub repo** named `xstream` (don't add a README/license — the project already has them)
2. From inside the project folder, run:

   ```bash
   git init
   git add .
   git commit -m "feat: initial Xstream Android app"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/xstream.git
   git push -u origin main
   ```

   > Replace `YOUR_USERNAME` with your GitHub username.

### 3b. Deploy to Render

1. Go to **https://dashboard.render.com/** → sign in with GitHub
2. Click **New +** → **Blueprint**
3. Select your `xstream` repo
4. Render will detect `backend/render.yaml` automatically — click **Apply**
5. Wait for the build to finish (~2–3 min). It will fail the first health check — **that's OK**, because the API keys aren't set yet.

### 3c. Add your API keys to Render

1. In Render, click on your new **`xstream-api`** service
2. Go to the **Environment** tab (left sidebar)
3. Add two environment variables:

   | Key | Value |
   |-----|-------|
   | `TMDB_API_KEY` | *(paste your TMDB key from Step 2a)* |
   | `GROQ_API_KEY` | *(paste your Groq key from Step 2b)* |

4. Click **Save Changes**
5. Render will **auto-redeploy**. Wait for it to show **Live** (green dot)

### 3d. Test the backend

1. At the top of your Render service page, copy the **URL** — it looks like:
   ```
   https://xstream-api-xxxx.onrender.com
   ```
2. Open that URL in your browser. You should see:
   ```json
   {"name":"Xstream API","version":"1.0.0","status":"running"}
   ```
3. Add `/api/health` to the URL:
   ```
   https://xstream-api-xxxx.onrender.com/api/health
   ```
   You should see:
   ```json
   {"status":"ok","time":"...","tmdb":true,"groq":true}
   ```

   ✅ If `tmdb` and `groq` are both `true` — **your backend is live!** Save this URL, you'll need it in Step 5.

   > 💡 **Render free tier sleeps** after 15 min of inactivity. The first request after sleep takes ~30 seconds to wake up. To keep it awake, see [Optional: Keep-alive ping](#-optional-keep-alive-ping) at the bottom.

---

## 📱 Step 4 — Install Flutter dependencies

From inside the project folder:

```bash
flutter pub get
```

This downloads all 15+ packages (Riverpod, go_router, Dio, WebView, etc.). Wait for it to finish.

### Generate the app launcher icon (one-time)

```bash
dart run flutter_launcher_icons
```

This creates the Xstream app icon on your phone's home screen.

---

## ▶️ Step 5 — Run the app on your phone / emulator

### Option A — Run on an Android emulator

1. Open **Android Studio** → **Device Manager** → create a **Pixel 7** emulator (API 34)
2. Start the emulator
3. From the project folder, run:

   ```bash
   flutter run --dart-define=BACKEND_URL=https://xstream-api-xxxx.onrender.com
   ```

   > 🔴 **Replace the URL** with YOUR Render URL from Step 3d (no trailing slash).

### Option B — Run on a real Android phone (recommended)

1. On your phone: **Settings → About phone → tap "Build number" 7 times** to enable Developer options
2. **Settings → Developer options → enable USB debugging**
3. Connect your phone to your computer via USB
4. Run:

   ```bash
   flutter devices          # confirm your phone shows up
   flutter run --dart-define=BACKEND_URL=https://xstream-api-xxxx.onrender.com
   ```

The app will install and launch on your phone. 🎉

---

## 📦 Step 6 — Build a release APK (to share / sideload)

When you're happy with the app, build a standalone APK:

```bash
flutter build apk --release --dart-define=BACKEND_URL=https://xstream-api-xxxx.onrender.com
```

The APK will be at:

```
build/app/outputs/flutter-apk/app-release.apk
```

**To install it on your phone:**
1. Copy `app-release.apk` to your phone (USB, email, Drive — whatever)
2. On your phone, open the file
3. Allow "install from unknown sources" if asked
4. Install → open **Xstream** 🎬

---

## 🧪 Quick troubleshooting

| Problem | Fix |
|---------|-----|
| `flutter doctor` shows red for Android | Install Android SDK via Android Studio → SDK Manager |
| App opens but shows "Loading…" forever | Your `BACKEND_URL` is wrong, OR Render is still deploying. Check the URL in a browser. |
| App loads but images don't show | Internet permission — make sure `AndroidManifest.xml` has `<uses-permission android:name="android.permission.INTERNET"/>` (it already does) |
| Video player is blank | Some streaming servers are occasionally down — tap the server dropdown in the Watch page and pick a different one (11 options) |
| AI recommendations fail | Groq might be rate-limited. Wait a minute and try again. |
| Render service sleeps after 15 min | Set up a keep-alive ping (see below) |
| `flutter pub get` fails | Run `flutter clean` then `flutter pub get` again |

---

## ⏰ Optional: Keep-alive ping

Render's free tier sleeps after 15 min of inactivity. To keep your backend awake 24/7 for free:

1. Go to **https://cron-job.org** → sign up (free)
2. Create a cron job:
   - **URL:** `https://xstream-api-xxxx.onrender.com/api/health`
   - **Schedule:** every **10 minutes**
   - **Save**
3. Done — your backend will never sleep. ✅

Alternatives: **UptimeRobot** (free, 5-min intervals) or a **GitHub Actions** workflow (example in `docs/DEPLOYMENT.md`).

---

## 🧑‍💻 Optional: Run the backend locally (for development)

If you want to develop the backend without Render:

```bash
cd backend
cp .env.example .env       # then edit .env with your API keys
npm install
npm run dev                # starts on http://localhost:8080
```

Then run the Flutter app pointing at the local backend:

```bash
# From the project root
flutter run --dart-define=BACKEND_URL=http://10.0.2.2:8080
```

> `10.0.2.2` is the Android emulator's alias for your computer's `localhost`.
> If using a real phone, use your computer's LAN IP (e.g. `http://192.168.1.50:8080`).

---

## ✅ You're done!

You now have:

- 🎬 A beautiful cinematic streaming app on your Android phone
- 🔒 100% private — no accounts, all your data stays on your device
- 🤖 AI-powered movie recommendations based on your mood
- 📺 11 streaming servers for maximum uptime
- ☁️ A free backend on Render that hides your API keys

**Next steps:**
- ⭐ Star the repo on GitHub
- 🐛 Report bugs via GitHub Issues (use the template in `.github/ISSUE_TEMPLATE/`)
- 🤝 Contribute features — see `CONTRIBUTING.md`
- 📤 Share the APK with friends!

---

**Need more detail?** See:
- `README.md` — full project overview
- `docs/ARCHITECTURE.md` — how the app is structured
- `docs/DEPLOYMENT.md` — advanced deployment options (Play Store, signing, etc.)
- `docs/API.md` — backend API reference

Made with ❤️ by the Xstream community.
