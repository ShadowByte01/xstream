---
name: 🐛 Bug Report
about: Something isn't working as expected in the Xstream Android app
title: "[BUG] "
labels: ["bug", "needs-triage"]
assignees: []
---

# 🐛 Bug Report

Thanks for taking the time to file a bug! The more detail you provide, the
faster we can reproduce and fix it.

## Describe the bug

A clear, concise description of what the bug is.

```text
Example: When I tap "Play" on a TV show, the player opens but shows a blank
screen instead of the video.
```

## To Reproduce

Steps to reproduce the behavior. Be specific — assume we've never seen your
setup.

1. Open the app on …
2. Tap on …
3. Scroll down to …
4. Tap …
5. See error

## Expected behavior

What you expected to happen.

```text
Example: The video should start playing in the WebView.
```

## Actual behavior

What actually happened.

```text
Example: The WebView loads, but stays blank. The server picker is visible
but switching servers doesn't help.
```

## Screenshots / Screen recording

If applicable, add screenshots or a screen recording to help explain the
problem. On Android, you can take a screenshot with **Power + Volume Down**,
or record the screen via the Quick Settings tile.

> ⚠️ Please **don't** include screenshots of personal data (your watchlist,
> ratings, etc.) if you'd prefer to keep those private.

## Environment

Please fill in as much as you can:

| Field                | Value                                  |
| :------------------- | :------------------------------------- |
| **Device**           | _(e.g. Pixel 7, Galaxy S22, OnePlus 11)_ |
| **Android version**  | _(e.g. Android 14, Android 12)_         |
| **App version**      | _(Settings → About, or the APK filename, e.g. 1.0.0)_ |
| **App build**        | _(debug / release / split-per-abi)_     |
| **Installed from**   | _(GitHub Release / sideloaded APK / built from source / Play Store)_ |
| **Backend URL**      | _(e.g. `https://xstream-api.onrender.com` — no API keys please!) |
| **Network**          | _(Wi-Fi / Mobile data / Both)_          |
| **Consent status**   | _(Accepted / Declined / Not asked yet)_ |
| **Accent color**     | _(if relevant — e.g. Emerald)_          |

## Logs

Run `flutter logs` (or `adb logcat | grep -i flutter`) while reproducing the
bug and paste the relevant output here. Wrap it in triple backticks.

```text
Paste log output here. Redact any URLs that contain your backend domain if
you'd prefer.
```

If the bug is a crash, the full stack trace is essential.

## Streaming server (if applicable)

If the bug is on the Watch page, tell us which server you were using:

- [ ] Peachify
- [ ] Xstream
- [ ] Xstream Pro
- [ ] Xstream Premium
- [ ] Xstream Ultra
- [ ] Xstream Max
- [ ] Turbo
- [ ] NHD
- [ ] 4K
- [ ] Premium
- [ ] MultiEmbed

And whether switching servers fixes it: ☐ Yes ☐ No ☐ Didn't try

## Additional context

Anything else that might be relevant:

- Did it work before? If so, what version?
- Did you upgrade Android / Flutter / the backend recently?
- Is it intermittent or always reproducible?
- Any workarounds you've found?

---

## Checklist

Before submitting, please confirm:

- [ ] I have searched the [existing issues](https://github.com/<your-org>/xstream/issues?q=is%3Aissue+label%3Abug) for duplicates.
- [ ] I have reproduced this on the **latest released version** (or `main`).
- [ ] I have removed any API keys, backend URLs containing secrets, or other
      sensitive information from this report.
- [ ] I have run `flutter logs` and included the relevant output.

Thank you! 🙏
