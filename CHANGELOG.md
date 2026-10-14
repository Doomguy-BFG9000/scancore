# Changelog

Downloads for every version are on the [releases page](https://github.com/medium-gh/scancore/releases).

## 1.1.4 — 2026-10-14

- Fixed (Android): the app crashed while watching anime, often right after tapping the video. Qt WebView runs JavaScript result callbacks on the Android UI thread, while the interface runs on Qt's own thread, so the two clashed inside the JavaScript engine. The player now reports its position through the page title, which Qt hands over safely.
- Phone: long shelf titles no longer run under the "More" button, and the shelf arrows are hidden (swipe instead). The home screen's quick links hide when they would overlap the greeting in landscape.

## 1.1.3 — 2026-10-14

- Player (desktop): the top bar and episode list now really hide while the video plays. A playing video kept them awake in 1.1.1 and 1.1.2; now only moving the mouse brings them back.
- Player (phone): in landscape the side rail hides after a few seconds, leaving only the video. Tap the video to bring it back.

## 1.1.2 — 2026-10-14

- Fixed: the Linux AppImage could crash on newer distributions (for example Arch) with an NSS version error from the anime player. It now uses the system's NSS libraries as intended.
- Fixed: leaving full screen with Esc or F11 now also takes the video player out of full screen (this fix did not take effect in 1.1.1).

## 1.1.1 — 2026-10-14

- Fixed: on Linux, the app crashed shortly after starting (often while opening Anime) when MangoHud was enabled globally (`MANGOHUD=1`). SCANCORE now opts out of the MangoHud layer; set `DISABLE_MANGOHUD=0` to keep it.
- Fixed: the player's own full-screen button stopped working after leaving full screen with Esc or F11.
- Player (desktop): the video now fills the window. The top bar and episode list float over it and hide after a few seconds without mouse movement. New full-screen button, also on the F key.
- Player (phone): portrait shows the controls, skip button and episode list under the video instead of on top of it. Landscape goes full screen with a slim side rail.
- Anime home (phone): the search field, Browse/Schedule buttons and slide dots no longer overlap.

## 1.1.0 — 2026-10-14

- In-app updates with an update banner, and an option to install updates automatically.
- Optional scancore.onl account: sign in or sign up from the new welcome screen or Settings to sync your library and reading history with the website.
- First-run welcome screens.

## 1.0.0 — 2026-10-14

- First release: comics, novels and anime in one app for Linux, Windows, macOS and Android, with a local library, history, downloads and backups.
