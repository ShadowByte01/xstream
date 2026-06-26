# 🚀 Pull Request

Thanks for contributing to Xstream! Please fill in the sections below so we
can review your change quickly.

## 📝 Summary

<!-- One-paragraph description of what this PR does and why. -->

```text
Example: Adds a double-tap-to-seek gesture (10s forward / backward) to the
Watch page's WebView. Respects the user's autoplay-next preference.
```

Fixes #<issue-number> _(if applicable)_

## 🔧 Type of change

<!-- Tick all that apply. -->

- [ ] 🐛 **Bug fix** — non-breaking change which fixes an issue
- [ ] ✨ **New feature** — non-breaking change which adds functionality
- [ ] 💥 **Breaking change** — fix or feature that would cause existing
      functionality to not work as expected (e.g. changing a public API,
      altering the backend protocol, swapping state management)
- [ ] 📚 **Documentation** — README, ARCHITECTURE, CHANGELOG, code comments
- [ ] ♻️ **Refactor** — no functional change, just code reorganization
- [ ] ⚡ **Performance** — speedup or memory reduction
- [ ] 🧪 **Tests** — adding or correcting tests
- [ ] 🔧 **Build / CI** — Gradle, pubspec, GitHub Actions, dependencies
- [ ] 🎨 **Style** — formatting, lint rule fixes (no logic change)

## 📸 Screenshots / Screen recording

<!-- If your change is user-visible, add before/after screenshots or a
     screen recording. Use a thumbnail GIF if the file is large. -->

| Before | After |
| :----: | :---: |
|        |       |

## ✅ Pre-PR checklist

Please confirm you've done each of these. **PRs that fail the checklist will
be returned for revision.**

- [ ] **Rebased** on the latest `upstream/main` (no merge commits in your
      branch unless explicitly requested).
- [ ] **`flutter analyze`** passes with **zero** issues.
- [ ] **`dart format .`** has been run — diff is empty.
- [ ] **`flutter test`** passes (or you've added tests for new logic — see
      below).
- [ ] **No new lint rules** need to be disabled. If you had to use `// ignore:`,
      explain why in a code comment.
- [ ] **No secrets** (API keys, backend URLs containing keys, keystore
      passwords) are committed.
- [ ] **No `print()`** statements left in — use `debugPrint()` if you must.
- [ ] **No `setState`** for app-wide state — use a Riverpod provider.
- [ ] **No `Container`** where a `SizedBox`/`Padding`/`ColoredBox` would do.
- [ ] **Conventional commit** messages (`feat(scope): …`, `fix(scope): …`,
      etc.) — see [CONTRIBUTING.md](../CONTRIBUTING.md#-commit-message-convention).
- [ ] **CHANGELOG.md** updated under `## [Unreleased]` → `Added` / `Changed` /
      `Fixed` / `Security` (as appropriate).
- [ ] **README.md** updated if the feature is user-visible (Features section,
      Project Structure if you added folders, etc.).
- [ ] **ARCHITECTURE.md** updated if you changed the data flow, providers, or
      added a new layer.
- [ ] **API.md** updated if you added/changed a backend endpoint.
- [ ] **pubspec.lock** committed if you changed `pubspec.yaml`.

## 🧪 Tests

<!-- Did you add tests? If not, explain why. -->

- [ ] I added tests for the new logic.
- [ ] I added a regression test for the bug I fixed.
- [ ] Tests aren't applicable — this is a docs/style/visual change.
- [ ] Tests aren't applicable — this is too hard to test without a live
      network / WebView / Groq. _(explain below)_

```text
If "too hard to test", explain what would be needed and we can pair on it.
```

## 🔒 Privacy check

Xstream is **privacy-first by default**. Tick the boxes that apply:

- [ ] My change does **not** add any new network calls.
- [ ] My change does **not** add any new on-device storage keys.
- [ ] My change does **not** send any new data to the backend.
- [ ] My change is **gated behind the consent check** (`isPersonalizationAllowed`)
      if it touches personal data.
- [ ] My change does **not** add any new third-party SDKs.
- [ ] My change does **not** weaken existing privacy protections.

If you ticked any "does not" box and the statement is **false**, please
explain in detail what data is collected, where it's sent, and why it's
necessary.

## 📦 Dependencies

<!-- If you added/changed/removed a dependency, list it here with the reason. -->

- [ ] No dependency changes.
- [ ] Dependency changes:
  - `added`: `package_name@x.y.z` — why:
  - `changed`: `package_name@x.y.z` → `@a.b.c` — why:
  - `removed`: `package_name` — why:

> ⚠️ New dependencies must be **actively maintained**, have **>1M downloads**
> on pub.dev, and have **no known security advisories**. We prefer official
> Flutter team packages where possible.

## 🗒 Notes for the reviewer

<!-- Anything the reviewer should pay extra attention to? Tricky edge cases?
     Trade-offs you considered? -->

```text
Example: The double-tap gesture is implemented with a GestureDetector around
the WebView. I had to disable hit-testing on the WebView itself for the
double-tap to register, which means taps on the embed's controls require a
single-tap (not double). This is a known trade-off — happy to discuss
alternatives.
```

## 🔗 Related issues / PRs

<!-- Link any related issues, PRs, discussions, or external references. -->

- Fixes #
- Related #
- Blocks #
- Blocked by #

---

<p align="center">
  <em>Thank you for your contribution! 🎉 A maintainer will review within
  a few days. Please be patient — we're volunteers.</em>
</p>
