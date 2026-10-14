# Changelog

Downloads for every version are on the [releases page](https://github.com/medium-gh/scancore/releases).

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
