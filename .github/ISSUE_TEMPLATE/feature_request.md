---
name: 💡 Feature Request
about: Suggest a new feature or improvement for Xstream
title: "[FEATURE] "
labels: ["enhancement", "needs-triage"]
assignees: []
---

# 💡 Feature Request

Thanks for taking the time to suggest a feature! Xstream is community-driven,
and the best ideas come from the people who use it every day.

## Is your feature request related to a problem?

A clear, concise description of what the problem is.

```text
Example: I keep losing track of which episode I'm on for shows I'm binging
across multiple seasons. The Watch page remembers, but the Home "Continue
Watching" row only shows the most recent one — I want to see all in-progress
shows grouped by series.
```

## Describe the solution you'd like

A clear, concise description of what you want to happen.

```text
Example: Add a "Continue Watching — Series" section to the Home page that
groups all in-progress TV shows, each showing the latest unwatched episode
with a thumbnail and a "S3 E7" badge. Tapping it goes straight to the Watch
page for that episode.
```

If you have a specific UX in mind, sketch it! Text mockups are fine:

```
┌─────────────────────────────────┐
│ ▶ Continue Watching — Series     │
├─────────────────────────────────┤
│ ┌──────┐  ┌──────┐  ┌──────┐    │
│ │ img  │  │ img  │  │ img  │    │
│ │      │  │      │  │      │    │
│ │S3 E7 │  │S1 E4 │  │S5 E12│    │
│ └──────┘  └──────┘  └──────┘    │
│  Title 1   Title 2   Title 3    │
└─────────────────────────────────┘
```

## Describe alternatives you've considered

Any alternative solutions or features you've thought about.

```text
Example: I could just use the existing History page, but it mixes movies and
TV shows and sorts by watchedAt, not by show. I'd rather have a dedicated
section on Home.
```

## Privacy check

Xstream is **privacy-first by default**. Please check any boxes that apply:

- [ ] This feature can be implemented with **on-device storage only** (no new
      network calls, no account, no cloud sync).
- [ ] This feature requires **new network calls** (specify what data is sent
      and to whom below).
- [ ] This feature requires an **account or login** _(strongly discouraged —
      please explain why on-device storage is insufficient)_.
- [ ] This feature requires **cloud sync** _(strongly discouraged — please
      explain why on-device only is insufficient)_.

If you ticked any of the last three, please describe the privacy implications
in detail:

```text
Example: This feature sends the user's mood + custom text + language code
to our backend, which forwards it to Groq. No user identifier is sent. The
backend does not log or store the request.
```

## Audience

Who is this feature for?

- [ ] All users
- [ ] Power users only (advanced setting OK)
- [ ] Users on slow networks / offline
- [ ] Users with accessibility needs
- [ ] Tablet / foldable users
- [ ] Other: _(please specify)_

## Priority (your opinion)

How important is this to you?

- [ ] **Nice to have** — would make the app slightly better
- [ ] **Should have** — would meaningfully improve my experience
- [ ] **Must have** — the app is hard to use without it

## Mockups / Screenshots

If you have any mockups, sketches, or screenshots from other apps that do
this well, paste them here.

## Are you willing to implement this yourself?

We're a small community project — features with a willing contributor ship
much faster!

- [ ] Yes, I'd like to implement this and submit a PR.
- [ ] Yes, but I'd need some guidance.
- [ ] No, but I'm happy to help review a PR.
- [ ] No, just suggesting.

## Additional context

Anything else? Links to relevant issues, related features, upstream API
capabilities, etc.

---

## Checklist

- [ ] I have searched the [existing issues](https://github.com/<your-org>/xstream/issues?q=is%3Aissue+label%3Aenhancement) for duplicates.
- [ ] I have read the [Privacy](../README.md#-privacy-first) section of the README and considered whether my feature respects Xstream's privacy-first philosophy.
- [ ] I have considered whether this feature can be implemented without new
      network calls or accounts.

Thank you! 🙏
