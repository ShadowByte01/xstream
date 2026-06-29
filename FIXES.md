# Xstream — Fixes Applied (v1.0.4+5)

This build addresses every issue reported in the latest review.

## 1. New app logo / icon
- Replaced `assets/images/app_icon.png` and `assets/images/logo.png` with the
  new logo you provided.
- Regenerated **all** Android launcher densities from the new logo:
  - `mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png`
  - `drawable-{mdpi…xxxhdpi}/ic_launcher_foreground.png` (logo inset into the
    adaptive-icon safe zone so the red outline survives the system mask).
- The cinematic splash screen now animates the new logo image in
  (`lib/features/splash/splash_screen.dart`) instead of a drawn letter.
- `flutter_launcher_icons` config still points at `assets/images/app_icon.png`,
  so re-running `flutter pub run flutter_launcher_icons` keeps the new icon.

## 2. Buttons hiding behind the home navigation bar — FIXED
- Root cause: `AppScaffold` used `extendBody: true` with a floating bottom nav
  but reserved **no** space at the bottom of the body, so the last content row
  of every tab screen (Home, Movies, Series, Search, Profile) scrolled under
  the nav pill.
- Fix (`lib/shared/widgets/app_scaffold.dart`): the body now reserves
  `viewPadding.bottom + 84` at the bottom, so content/bottom buttons always
  clear the floating nav bar on every screen.

## 3. App lagging / not responding — FIXED
- Root cause: the in-app ad blocker scanned every navigation URL for keywords
  (`bet`, `casino`, `ads`, `pop`, `track`, `affiliate`, `slot` …). Those
  substrings match **legitimate** URLs too (e.g. "popular", "uploads",
  "soundtrack"), so the WebView kept killing real navigations and the player
  appeared frozen/laggy.
- Fix: the keyword ad blocker was removed (see #4). Only `intent://` and
  `market://` (external-app schemes that would hang the WebView) are still
  blocked. The `canGoBack` ad-state polling was also tightened to avoid
  redundant `setState` calls.

## 4. In-built ad blocker — REMOVED
- The `onNavigationRequest` keyword filter in
  `lib/features/watch/watch_screen.dart` was removed entirely.
- Ads that the embed serves are now handled by the new **Skip Ads** button
  (see #5) and by switching to the ad-free **VidFast** server (see #6).

## 5. Skip Ads button (below the player bar, in the title area)
- A "Skip Ads" button now sits **just below the player, right where the title
  is written** — not on the player bar, and not at the very bottom of the
  screen (`_AdControls` in `watch_screen.dart`).
- When the embed opens an ad tab, tapping **Skip Ads** closes that ad tab
  (`goBack`) and re-opens the player. If there's no ad tab to go back to, it
  reloads the stream URL fresh.
- The button turns red and is highlighted whenever an ad is detected.

## 6. Ad-Free button → auto-switch to VidFast
- A new ad-free server **VidFast** was added to
  `lib/core/constants/streaming_servers.dart` (uses `vidfast.pro`, which
  serves no ads/popups). It's flagged `AdMode.adFree` and shows an "AD-FREE"
  badge in the server picker.
- The **Ad-Free** button (next to Skip Ads, below the player) automatically
  switches the active server to VidFast and reloads the player — so playback
  continues without ads. If already on VidFast, it just refreshes the player.
- The button turns green and reads "Ad-Free On" while VidFast is active.

## 7. Server selector not responding — FIXED
- Root cause: tapping the server selector only set a `_showServerMenu` flag
  that was **never read** by any widget, so nothing appeared.
- Fix (`watch_screen.dart`): tapping the server card (or the player bar's
  server icon) now opens a proper modal bottom sheet (`_showServerPicker`)
  listing every server with its flag, an AD-FREE badge for VidFast, and a
  check mark on the active one. Tapping a server switches instantly.

## Files changed
- `lib/core/constants/streaming_servers.dart` — added VidFast (ad-free) server + helpers
- `lib/features/watch/watch_screen.dart` — removed ad blocker, fixed server picker, added Skip Ads + Ad-Free controls, performance pass
- `lib/shared/widgets/app_scaffold.dart` — reserved bottom space so content isn't hidden behind the nav bar
- `lib/features/splash/splash_screen.dart` — shows the new logo
- `assets/images/app_icon.png`, `assets/images/logo.png` — new logo
- `android/app/src/main/res/mipmap-*/ic_launcher.png` — new icon (all densities)
- `android/app/src/main/res/drawable-*/ic_launcher_foreground.png` — new adaptive foreground
- `pubspec.yaml` — version bump to 1.0.4+5

## Build
```bash
flutter pub get
flutter pub run flutter_launcher_icons      # optional — icons are pre-generated
flutter run
```
