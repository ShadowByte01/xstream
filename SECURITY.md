# Security Policy

## 🔒 Supported Versions

Xstream is a hobby/community project. We actively maintain only the **latest
released version** and the `main` branch. Security fixes are backported to the
most recent release tag only.

| Version | Supported          | Notes                                |
| :------ | :----------------- | :----------------------------------- |
| 1.0.x   | ✅ Active          | Initial Android release              |
| < 1.0   | ❌ Not supported   | Pre-release builds — upgrade         |

If you installed Xstream from a source other than our official GitHub Releases
(or a Google Play Store listing, if/when published), we cannot guarantee its
integrity. Always prefer official distribution channels.

---

## 📣 Reporting a Vulnerability

**Please DO NOT open a public GitHub issue for security vulnerabilities.**

Instead, report them privately:

- 📧 **Email**: **xstream@example.com**
- 📝 **Subject**: `[SECURITY] <short description>`
- 🔐 **PGP** (optional): _(publish a key in a future release — for now,
  standard email is fine for low-severity reports)_

### What to include

A great report has:

1. **Description** of the issue and its real-world impact.
2. **Affected component** — the Flutter app (`lib/`), the backend proxy
   (`backend/`), or both.
3. **Reproduction steps** — numbered, self-contained, no assumptions.
4. **Proof of concept** — code, screenshots, or a screen recording.
5. **Suggested fix** (optional but very welcome).
6. **Your preferred public credit name/handle** (or "anonymous").

### Response timeline

| Step                              | Target        |
| :-------------------------------- | :------------ |
| Acknowledgement of receipt        | ≤ 72 hours    |
| Initial assessment (triage)       | ≤ 7 days      |
| Fix or mitigation plan            | ≤ 30 days     |
| Public disclosure (after fix)     | ≤ 90 days     |

We will keep you informed at every step. If you don't hear back within 72
hours, please follow up — email sometimes eats things.

---

## 🎯 Scope

### In scope

- The **Flutter app** in this repository (`lib/`, `android/`).
- The **Node.js/Express backend proxy** in this repository (`backend/`).
- The **deployment process** documented in [`docs/DEPLOYMENT.md`](./docs/DEPLOYMENT.md).
- The **CI workflow** in `.github/workflows/`.
- Our **official GitHub Releases** (APK artifacts attached to a release).

### Out of scope

- **Third-party streaming embed providers** (VidLink, VidSrc, VidSrc.pro,
  VidSrc.cc, MultiEmbed, Peachify). Xstream renders these inside an Android
  `WebView`; we have no control over their infrastructure, ads, cookies, or
  content. Report their issues to them, not us.
- **TMDB** data accuracy or API availability — report at
  [themoviedb.org](https://www.themoviedb.org/).
- **Groq** API availability or model behaviour — report at
  [console.groq.com](https://console.groq.com).
- **Render** infrastructure outages — report at
  [status.render.com](https://status.render.com).
- **Your own deployment** if you modified the source. If you can reproduce the
  issue on the unmodified `main` branch, it's in scope.
- **Self-inflicted key leaks** — if you accidentally commit your `TMDB_API_KEY`
  or `GROQ_API_KEY` to a public fork, that's a you-problem. Rotate the key
  immediately. (We've added a `.gitignore` rule, but please double-check your
  own fork.)
- **Denial of service** against a single Render free-tier instance. We know
  free tier has limits — that's an infrastructure choice, not a vulnerability.
- **Bypassing the cookie-consent gate** by manually editing `SharedPreferences`
  on a rooted device. The consent gate is a UX/privacy-hygiene feature, not a
  security boundary.

---

## 🛡️ Threat Model (summary)

Xstream is **privacy-first by design**, not by bolt-on. Here's how we think
about the main threats:

| Threat                              | Mitigation                                                                                  |
| :---------------------------------- | :------------------------------------------------------------------------------------------ |
| **API keys leaked via APK**         | Keys live on the backend, never in the APK. `BACKEND_URL` is the only secret-adjacent string in the app, and it's a public URL by design. |
| **User data exfiltrated from device** | All personal data (history, watchlist, likes, ratings, view counts) lives in `SharedPreferences` on-device. `android:allowBackup="false"` and `android:fullBackupContent="false"` prevent ADB/cloud backup. No analytics SDKs are bundled. |
| **User data leaked via backend**    | The backend stores **nothing** per-user — no database, no logs of user activity, no cookies. It only forwards requests to TMDB/Groq and caches TMDB responses in-memory for ≤ 60s. |
| **Man-in-the-middle on API calls**  | The backend runs HTTPS (Render provides TLS). The app pins to `https://` URLs only. `android:usesCleartextTraffic="false"` blocks any accidental plaintext. |
| **Malicious embed in the WebView**  | The WebView only loads a fixed set of well-known third-party embed URLs (constructed from TMDB IDs in `lib/core/constants/streaming_servers.dart`). No user-supplied URLs are loaded. JavaScript is enabled (the embeds need it) but the WebView has no access to the app's Dart layer. |
| **Cross-site scripting in the app** | The app's UI is 100% Flutter widgets — no HTML rendering of API responses. The WebView is sandboxed. |
| **Consent bypass**                  | Declining the consent gate disables all personal-data writes via `isPersonalizationAllowed` checks in `StorageService`. Bypassing requires modifying the APK, at which point the attacker already has full device control. |
| **Supply-chain attack on pub.dev**  | We pin versions in `pubspec.yaml`. Before any release we run `flutter pub outdated` and review major bumps. |

### What we explicitly do **not** protect against

- A rooted device. If you root your phone, any app's `SharedPreferences` is
  readable. Use full-disk encryption and don't install Xstream on a rooted
  device if this concerns you.
- A malicious backend operator. If you point `BACKEND_URL` at a backend you
  don't control, that operator can see your TMDB/Groq request patterns (but
  **not** your identity or personal data — the app sends no user identifiers).
  Always point at a backend you deployed yourself.
- Third-party embed cookies. The streaming embeds set their own cookies inside
  the WebView's cookie jar. You can clear these from Android's system settings
  (Apps → Xstream → Storage → Clear data).

---

## 🔄 Responsible Disclosure

We follow a coordinated disclosure model:

1. **You report** privately (see above).
2. **We acknowledge** and triage within 72h.
3. **We fix** (or mitigate) and prepare a release.
4. **We credit you** in the release notes and [`CHANGELOG.md`](./CHANGELOG.md)
   (unless you prefer to remain anonymous).
5. **We publish** the fix and disclose the vulnerability details after a
   reasonable embargo (default 90 days, shorter for low-severity, longer if
   you request it).

We will **not** take legal action against good-faith security researchers who
follow this policy. Please:

- Make a good-faith effort to avoid privacy violations, data destruction, and
  interruption of service.
- Don't access data that isn't yours.
- Don't perform DoS or DDoS.
- Don't social-engineer our maintainers.

---

## 🔑 Dependency Security

We use the following trusted dependencies (all from pub.dev, all pinned):

| Package                    | Why we trust it                                            |
| :------------------------- | :--------------------------------------------------------- |
| `flutter_riverpod`         | Official Riverpod, widely used                             |
| `go_router`                | Official Flutter team package                              |
| `dio`                      | Maintained by the Flutter China community, very widely used |
| `shared_preferences`       | Official Flutter team package                              |
| `webview_flutter`          | Official Flutter team package                              |
| `cached_network_image`     | Maintained by the Flutter community, ~30M downloads         |
| `palette_generator`        | Official Flutter team package                              |
| `url_launcher`             | Official Flutter team package                              |
| `share_plus`               | Maintained by the Flutter Community plugins org            |
| `connectivity_plus`        | Same as above                                              |
| `path_provider`            | Official Flutter team package                              |
| `intl`                     | Official Dart team package                                 |

If you find a vulnerability in a dependency, please report it to the upstream
maintainer **and** to us (so we can patch or pin around it).

---

## ❓ Questions?

Open a private discussion at **xstream@example.com** with subject `[SECURITY-Q]`.
For non-security questions, please use
[GitHub Discussions](https://github.com/<your-org>/xstream/discussions) or open
a regular issue.

---

<p align="center">
  <em>Stay safe out there. 🔐</em>
</p>
