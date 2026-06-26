# Contributing to Xstream

First off — **thank you** for taking the time to contribute. 🎉

Xstream is a community-driven, privacy-first Android streaming app, and every
bug report, feature idea, typo fix or pull request makes it better. This
document explains how to work on the codebase, what conventions to follow, and
how to get your changes merged.

> 💡 **TL;DR**: Fork → branch → `flutter analyze` clean → Conventional Commit →
> open a PR against `main`. Be kind. Read the [Code of Conduct](./CODE_OF_CONDUCT.md).

---

## 📋 Table of Contents

1. [Before You Start](#-before-you-start)
2. [Fork & Clone](#-fork--clone)
3. [Development Setup](#-development-setup)
4. [Code Style](#-code-style)
5. [Project Layout](#-project-layout)
6. [Commit Message Convention](#-commit-message-convention)
7. [Branch Naming](#-branch-naming)
8. [Pull Request Process](#-pull-request-process)
9. [Testing Expectations](#-testing-expectations)
10. [Reporting Bugs](#-reporting-bugs)
11. [Feature Requests](#-feature-requests)
12. [Code of Conduct](#-code-of-conduct)

---

## 🧭 Before You Start

- Read the [README](./README.md) so you understand what Xstream is (a Flutter
  Android app + Node.js backend proxy) and what it isn't (a content host).
- Skim [`docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md) — even a 5-minute read
  will save you an hour of "where does this go?".
- Check the [open issues](https://github.com/<your-org>/xstream/issues) for
  anything already in progress. Comment on an issue before starting work so we
  don't duplicate effort.
- This is an Android-first project. iOS, desktop and web targets are **not**
  supported — please don't open PRs adding them.

---

## 🍴 Fork & Clone

```bash
# 1. Click "Fork" on the GitHub repo page (top-right).

# 2. Clone YOUR fork
git clone https://github.com/<your-username>/xstream.git
cd xstream

# 3. Add the upstream remote so you can sync with the main project
git remote add upstream https://github.com/<your-org>/xstream.git
git fetch upstream

# 4. Create your feature branch (see "Branch Naming" below)
git checkout -b feature/my-awesome-feature
```

---

## 🛠 Development Setup

### Prerequisites

- **Flutter 3.3+** and **Dart 3.3+** — verify with `flutter --version`.
- **Android Studio** (or the Android command-line tools) with an emulator or a
  real device on API 21+ (Android 5.0+).
- A working backend. Either:
  - Run the `backend/` folder locally on port `8080` and point the app at
    `http://10.0.2.2:8080` (the Android emulator's host alias), **or**
  - Deploy the backend to Render (see [`docs/DEPLOYMENT.md`](./docs/DEPLOYMENT.md))
    and use that URL.
- A **TMDB API key** and a **Groq API key** for the backend env vars.

### First run

```bash
# Install deps
flutter pub get

# Regenerate launcher icons (if you change assets/images/app_icon.png)
dart run flutter_launcher_icons:main

# Run, injecting your backend URL
flutter run --dart-define=BACKEND_URL=http://10.0.2.2:8080
```

### Keeping your fork up to date

```bash
git fetch upstream
git checkout main
git merge --ff-only upstream/main
git push origin main
```

---

## 🧹 Code Style

- **Linting**: we use [`flutter_lints`](https://pub.dev/packages/flutter_lints)
  4.0 with a few extra rules in [`analysis_options.yaml`](./analysis_options.yaml).
  `flutter analyze` **must pass with zero issues** before a PR can be merged.
- **Formatting**: `dart format .` — every file should be formatted. CI will
  reject unformatted code.
- **Imports**: use relative imports inside `lib/` (e.g.
  `import '../../core/theme/app_colors.dart';`), package imports only for
  third-party packages.
- **No `print()`**: use `debugPrint()` (the linter enforces `avoid_print`).
- **`const` everything**: prefer `const` constructors and `const` literals
  where possible (enforced by lint).
- **Avoid `Container` when a `SizedBox`/`Padding`/`ColoredBox` will do**
  (enforced by `avoid_unnecessary_containers`).
- **Riverpod, not setState**: app state lives in providers in
  `lib/shared/providers/app_providers.dart` (or feature-local providers for
  screen-specific state). Widgets should `ref.watch`/`ref.read` — not call
  `setState` for anything beyond purely local UI flags.
- **Storage mutations**: go through `StorageActions.instance.*` so the
  `_storageVersionProvider` bumps and dependent widgets rebuild.
- **Models**: immutable, `const` constructors, `fromJson` factories. Use
  `copyWith` for updates.
- **Services**: singletons (`static const instance` or `static final instance`)
  that take an `ApiClient` dependency. No business logic in widgets.
- **Files & classes**: one top-level class per file (small helpers OK). File
  names are `snake_case.dart`, class names are `PascalCase`.

### Feature-folder structure

Every screen lives under `lib/features/<feature>/` with this shape:

```
lib/features/watch/
├── watch_screen.dart          # the top-level Widget
├── widgets/                   # (optional) feature-local widgets
│   ├── server_picker.dart
│   └── episode_selector.dart
└── providers.dart             # (optional) feature-local Riverpod providers
```

Shared widgets go in `lib/shared/widgets/`. Shared providers go in
`lib/shared/providers/app_providers.dart`.

---

## 📁 Project Layout

See the [Project Structure](./README.md#-project-structure) section of the
README for the full tree. Quick orientation:

| Folder                          | What lives here                                          |
| :------------------------------ | :------------------------------------------------------- |
| `lib/app/`                      | App root widget + bootstrap                              |
| `lib/core/`                     | Constants, router, theme, utils                          |
| `lib/data/models/`              | Immutable Dart models (`MediaItem`, `MediaDetail`, …)    |
| `lib/data/services/`            | API client + TMDB/AI/Storage services                    |
| `lib/features/<feature>/`       | One folder per screen                                    |
| `lib/shared/providers/`         | App-wide Riverpod providers                              |
| `lib/shared/widgets/`           | Reusable widgets (`MovieCard`, `AppScaffold`, …)         |
| `backend/`                      | Node.js/Express proxy (separate deploy target)           |
| `android/`                      | Native Android shell — usually leave alone               |
| `docs/`                         | Architecture, deployment, API reference                  |
| `.github/`                      | CI workflow, issue templates, PR template                |

---

## 📝 Commit Message Convention

We follow [**Conventional Commits**](https://www.conventionalcommits.org/).
This makes the changelog auto-generatable and the git log genuinely readable.

### Format

```
<type>(<scope>): <subject>

<optional body>

<optional footer>
```

### Types

| Type       | When to use                                                       |
| :--------- | :---------------------------------------------------------------- |
| `feat`     | A new feature (user-visible)                                       |
| `fix`      | A bug fix (user-visible)                                           |
| `docs`     | Documentation-only changes (README, ARCHITECTURE, code comments)  |
| `style`    | Formatting, whitespace, commas — no code logic change             |
| `refactor` | Code restructuring that neither fixes a bug nor adds a feature    |
| `perf`     | Performance improvement                                            |
| `test`     | Adding or correcting tests                                         |
| `build`    | Build system, deps, pubspec, Gradle                                |
| `ci`       | CI config (`.github/workflows/*`)                                  |
| `chore`    | Misc repo upkeep (gitignore, scripts) — not user-facing            |
| `revert`   | Reverts a previous commit                                          |

### Scopes (optional but encouraged)

Use a feature name: `home`, `details`, `watch`, `profile`, `search`, `ai`,
`theme`, `router`, `storage`, `backend`, `android`, `docs`, `ci`, etc.

### Examples

```text
feat(watch): add double-tap-to-seek gesture

Adds a 10-second forward/backward seek on double-tap in the WebView player.
Respects the user's autoplay-next preference.

Closes #142
```

```text
fix(profile): ratings not refreshing after delete

The ratingsProvider wasn't bumping the _storageVersionProvider when a
0-star rating cleared an entry. Now goes through StorageActions.setRating.
```

```text
docs(api): document the /api/ai/recommend response shape
```

```text
refactor(storage): replace ad-hoc JSON with typed fromJson factories
```

### Rules

- Subject line ≤ 72 chars, imperative mood ("add", not "added" or "adds").
- No period at the end of the subject.
- Body wraps at 72 chars, explains **why**, not **what**.
- Reference issues in the footer: `Closes #123`, `Fixes #456`, `Ref #789`.
- **Squash commits** before merging if your branch has WIP/noise commits.

---

## 🌿 Branch Naming

Branches are named `<type>/<short-description>` in kebab-case.

| Type      | Example                                  |
| :-------- | :--------------------------------------- |
| `feature` | `feature/double-tap-seek`                |
| `fix`     | `fix/ratings-not-refreshing`             |
| `docs`    | `docs/deployment-guide`                  |
| `refactor`| `refactor/storage-models`                |
| `chore`   | `chore/upgrade-riverpod`                 |
| `release` | `release/1.1.0` (maintainers only)       |

> Avoid branching off `main` for more than a few days — rebase frequently to
> stay current: `git fetch upstream && git rebase upstream/main`.

---

## 🔀 Pull Request Process

1. **Rebase** your branch on the latest `upstream/main`.
2. Run **`flutter analyze`** — it must be clean.
3. Run **`dart format .`** — diff should be empty.
4. If you added new functionality, **update the docs** (README, CHANGELOG
   `## [Unreleased]` section, ARCHITECTURE if structural).
5. If you changed `pubspec.yaml`, run `flutter pub get` and commit the
   updated `pubspec.lock`.
6. Push to your fork and open a PR against `main`.
7. Fill in the [PR template](./.github/PULL_REQUEST_TEMPLATE.md) — every
   checkbox must be ticked.
8. Request review from a maintainer. Address feedback with new commits (we'll
   squash on merge).
9. **Don't** push merge commits back into your branch unless asked — rebase.

### PR size

Keep PRs **under ~600 lines of diff** where possible. Big features are easier
to review when split into a chain of smaller PRs ("stacked PRs"). If you must
open a large PR, add a "Reviewers: read this first" section explaining the
shape of the change.

### What gets merged

- ✅ Clean `flutter analyze`.
- ✅ Tests pass (when present).
- ✅ Docs updated.
- ✅ Conventional commit messages.
- ✅ No unrelated formatting churn.
- ✅ Maintainer approval.

---

## 🧪 Testing Expectations

We're honest: the test suite is thin right now (roadmap item). That said:

- **Don't break existing tests.** Run `flutter test` before opening a PR.
- **Add tests for new pure logic** — model `fromJson`/`copyWith`, the
  `ratingColor` helper, the URL builders in `streaming_servers.dart`,
  `StorageService` mutations (with a `SharedPreferences` mock).
- **Don't write widget tests for things that require a live network** — mock
  the `ApiClient` instead.
- **Bug-fix PRs should include a regression test** that fails before your fix
  and passes after.

```bash
flutter test                       # run all tests
flutter test --coverage            # generate coverage/lcov.info
```

---

## 🐛 Reporting Bugs

Use the [**bug_report.md** issue template](./.github/ISSUE_TEMPLATE/bug_report.md).
The more of these you fill in, the faster we can reproduce and fix:

- **Device** (Pixel 7, Galaxy S22, etc.) and **Android version**.
- **App version** (Settings → About, or check the APK filename).
- **Backend URL** you're pointing at (no need for the keys, obviously).
- **Steps to reproduce** — numbered list, leave nothing out.
- **Expected vs actual** behavior.
- **Logs** — `flutter logs` output, or a screenshot of any error screen.

### Bug triage

A maintainer will label your issue within 72h (usually much faster). Labels:

| Label           | Meaning                                                    |
| :-------------- | :--------------------------------------------------------- |
| `bug`           | Confirmed reproducible defect                              |
| `needs-repro`   | Maintainer can't reproduce — we need more info from you    |
| `priority:high` | Crashes, data loss, privacy issues                         |
| `priority:low`  | Cosmetic or edge-case                                      |
| `good first issue` | Small, well-scoped — perfect for first contributors     |
| `help wanted`   | Maintainers welcome a community PR                         |

---

## 💡 Feature Requests

Use the [**feature_request.md**](./.github/ISSUE_TEMPLATE/feature_request.md)
template. The best feature requests:

- Describe the **problem** before the solution.
- Sketch the **UX** you have in mind (a wireframe is gold).
- Note any **privacy implications** — we're privacy-first, so features that
  require an account or cloud sync are unlikely to be accepted.
- Are willing to implement it themselves, or help review someone who does. 😄

---

## 📜 Code of Conduct

By participating in this project you agree to abide by our
[**Code of Conduct**](./CODE_OF_CONDUCT.md). Please be excellent to each other.
Report unacceptable behavior to **xstream@example.com**.

---

<p align="center">
  <em>Happy hacking! 🛠️ If you get stuck, open a <code>help wanted</code> issue or ping us in Discussions.</em>
</p>
