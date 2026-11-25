# Migration plan: CleanYourTV → Horizon Home

> Status: **in progress on the UR2** — A, B and D are live; C and F are pending;
> the image-flicker issue is deferred. Backup and rollback rehearsal are complete.
> Scope chosen by the owner: **A + B + C + D + F**.
> Excluded: E (NextDNS), G (speed tweaks), all XGIMI-only features.

## Scope

| ID | Feature | Included |
|---|---|---|
| A | Horizon Home launcher: apps row, clock/weather, HDMI/Wi-Fi/settings, ambient | yes |
| B | Nuvio: Continue Watching + streaming-service pages | yes |
| C | Live TV guide: own Cloudflare Worker + Nuvio | yes |
| D | Memory panel: per-app memory and free-up (local ADB) | yes |
| E | NextDNS ad/tracker blocking | no |
| F | Nuvio home layout: 5 collections / 58 folders | yes |
| G | Animation/recommendation speed tweaks | no |
| — | XGIMI wall scenes, power-button tweaks | no |

The APK still contains the excluded code paths, but the install will leave them
unconfigured. The NextDNS pill is hidden unless a profile ID and API key exist.

## Live status (2026-11-25)

| Item | State |
|---|---|
| Home | `com.horizon.home/.HomeActivity` — verified after reboot |
| CleanYourTV | still installed and enabled as the fallback |
| Stock launcher | still disabled |
| A — core home | live: apps, clock/weather, HDMI, Wi-Fi, settings |
| B — Nuvio | live: `com.nuvio.app`; Continue Watching and streaming tiles |
| C — Live TV | pending: needs the Cloudflare Worker |
| D — memory panel | live: per-app memory via the app's local ADB key |
| F — Nuvio layout | pending: export current layout before any Push |
| E / G / XGIMI | not configured |
| Backup | local only; rollback rehearsal passed |
| Known issue | image/poster/app-icon flicker on the UR2; 1280 px art and row-reload guards reduce it, not fully resolved; deferred |

## Before migration

From `Boxcode254/cleanyourtv` (commit `4bb9b0d`):

| | |
|---|---|
| TV | Sony BRAVIA 4K UR2 (`BRAVIA_UR2_4K`, MediaTek mt5893) — confirmed |
| OS | Android TV 10 (API 29) |
| RAM | 2.3 GB |
| Home | `com.gathin.tvhome/.MainActivity` |
| Stock launcher | `com.google.android.tvlauncher` — disabled |
| Disabled packages | 56 (10 in the repo list, 48 applied earlier) |
| Theme | `themes/mombasa-tvos` (Apple TV style, Mombasa wallpaper) |
| Font | SF Pro local build — **not in the repo, not redistributable** |
| Accessibility | `HomeKeyService` / `InputKeyService` may be enabled |

The installed APK is a local build that the repo cannot reproduce exactly
because the SF Pro font is deliberately excluded. Pull it before changing
anything.

## Target state

| | |
|---|---|
| Home | `com.horizon.home/.HomeActivity` |
| CleanYourTV | still installed, package enabled, **not Home** |
| Stock Google launcher | still disabled |
| CleanYourTV accessibility helpers | disabled (Sony cleared the ADB-set helper after reboot; the Home key still works via the default launcher) |
| Backups | local only, outside git |

## Phase 0 — confirm

- [ ] Confirm the TV is the **UR2**, not the X950G. If it is the X950G, stop and redo
      the device section; the cleanyourtv repo describes the UR2.
- [ ] TV and PC on the same LAN.
- [ ] Developer options → ADB debugging on.
- [ ] `TV_HOST` known (or run `windows\find-tv.bat`).
- [ ] Nuvio installed and signed in on the TV.
- [ ] Cloudflare account available for the Live TV Worker.
- [ ] Nuvio Personalized account available for the home layout.
- [ ] Read-only preflight passes.

Preflight, all read-only:

```powershell
adb connect <TV_IP>:5555
adb devices
adb shell getprop ro.product.model
adb shell getprop ro.build.version.release
adb shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME
adb shell pm path com.gathin.tvhome
adb shell dumpsys package com.horizon.home
```

## Phase 1 — backup (gate: review before continuing)

Create a local folder outside the repo:

```text
%USERPROFILE%\Documents\TV-Backups\ur2-pre-horizon-<timestamp>\
```

Back up:

- [ ] `cleanyourtv.apk` — `pm path` then `adb pull`
- [ ] `cleanyourtv-package.txt` — version, path, signer, install dates
- [ ] `device.txt` — model, build, Android version
- [ ] `home-before.txt` — `resolve-activity` result
- [ ] `accessibility.txt` — exact `enabled_accessibility_services` and
      `accessibility_enabled`
- [ ] `settings.txt` — animation scales, private DNS, screensaver, TV
      recommendations, default input
- [ ] `packages-disabled.txt` — `pm list packages -d`
- [ ] `before-home.png` — `adb exec-out screencap -p`
- [ ] `mombasa-theme/` — copy of `themes/mombasa-tvos/config.json`
- [ ] `debloat.txt` — copy of `my-tv/tv-lists/debloat.txt`
- [ ] `cleanyourtv.bundle` — `git bundle` of the private repo at `4bb9b0d`
- [ ] `SHA256SUMS.txt` — hashes of the APK and important files

Best-effort app data:

```powershell
adb shell run-as com.gathin.tvhome ls -R files shared_prefs
```

If `run-as` is refused (release build), record that fact. `allowBackup="false"`
means `adb backup` is not a reliable fallback. The APK, theme config, and repo
bundle are the guaranteed backups.

No IPs, keys, ADB private keys, Wi-Fi credentials, or account screenshots go
into any repository. The backup folder stays local.

## Phase 2 — install Horizon without switching Home

```powershell
adb install -r windows\HorizonHome.apk
adb shell am start -n com.horizon.home/.HomeActivity
```

- [ ] Horizon renders; screenshot it.
- [ ] `adb logcat -d -s AndroidRuntime` has no crash.
- [ ] CleanYourTV is still Home at this point.

Gate: do not touch Home until Horizon has rendered successfully.

## Phase 3 — switch Home

1. Save the original accessibility list (already in `accessibility.txt`).
2. Set Horizon's accessibility service. This intentionally disables
   CleanYourTV's Home/Input helpers while Horizon is Home.
3. Set Home and verify:

```powershell
adb shell settings put secure enabled_accessibility_services com.horizon.home/com.horizon.home.HomeButtonService
adb shell settings put secure accessibility_enabled 1
adb shell cmd package set-home-activity --user 0 com.horizon.home/.HomeActivity
adb shell am start -n com.horizon.home/.HomeActivity
adb shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME
```

- [ ] Resolver says `com.horizon.home/.HomeActivity`.
- [ ] Home button opens Horizon.
- [ ] CleanYourTV is still installed (`pm path com.gathin.tvhome` succeeds).

Note: on the UR2, Sony cleared `enabled_accessibility_services` after a reboot even
though Horizon was still the default Home. The Home key still opened Horizon via the
default-launcher route, so the accessibility helper is optional on this TV. If it is
needed, enable it through TV Settings → Accessibility; do not rely on the ADB-written
value surviving a boot.

Do **not** disable or uninstall `com.gathin.tvhome` or
`com.google.android.tvlauncher`.

## Phase 4 — feature setup

### A. Core home

- [ ] Greeting name (`--es name Emmanuel` on first launch, or Settings → Your name).
- [ ] Weather on/off; clock.
- [ ] Theme/edge margin.
- [ ] Apps row shows the apps you actually use.
- [ ] HDMI, Wi-Fi, TV settings shortcuts work.

### B. Nuvio

- [ ] Nuvio installed and signed in.
- [ ] Addons installed; Continue Watching populates.
- [ ] Streaming-service pages open titles in Nuvio.
- [ ] TMDB key added locally for artwork (not committed).

### C. Live TV

- [ ] Deploy `livetv-addon/worker-bundle.js` to a Cloudflare Worker.
- [ ] Configure countries/languages at `<worker-url>/configure`.
- [ ] Add the addon link to Nuvio and to `windows/config.bat` (gitignored).
- [ ] Horizon's Live TV tile opens the guide; preview and full-screen work.
- [ ] Keep the Worker URL out of git.

### D. Memory panel

- [ ] Local ADB works on `127.0.0.1:5555`; accept the prompt on the TV.
- [ ] Memory panel shows free/used memory and per-app rows.
- [ ] “Free up” closes background apps without killing Horizon.

### F. Nuvio home layout

- [ ] Export or screenshot the current Nuvio Personalized layout **before**
      changing it (`personalized.virtualpavi.com`).
- [ ] Rebuild the template collections (`nuvio/collections-template.json`):
      Discover, Streaming Services, Genres, Anime, Formats.
- [ ] Ask before **Push**; it replaces the current collections.
- [ ] Verify Nuvio's Home matches the layout.

## Phase 5 — verification

- [ ] Home button after a reboot.
      Reboot passed: Horizon remained Home; Sony cleared the accessibility helper, but
      the Home key still opened Horizon through the default launcher.
- [ ] HDMI input switching.
- [ ] Wi-Fi/Ethernet pill.
- [ ] TV settings shortcut.
- [ ] Back/ambient mode.
- [ ] Netflix, YouTube, Prime Video, TizenTube launch from the apps row.
- [ ] Nuvio Continue Watching and service pages.
- [ ] Live TV guide preview/full screen.
- [ ] Memory panel.
- [ ] No crash loop: `adb logcat -d -s AndroidRuntime`.
- [ ] Memory sane: `adb shell dumpsys meminfo com.horizon.home`.
- [ ] If 1920 px artwork is too heavy on 2.3 GB RAM, revert to 1280 px.

## Phase 6 — rollback rehearsal

Before calling the migration complete, switch Home back to CleanYourTV, verify,
then switch back to Horizon.

```powershell
adb shell cmd package set-home-activity --user 0 com.gathin.tvhome/.MainActivity
adb shell settings put secure enabled_accessibility_services "<ORIGINAL_LIST>"
adb shell settings put secure accessibility_enabled <ORIGINAL_VALUE>
adb shell am start -n com.gathin.tvhome/.MainActivity
adb shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME
```

- [ ] CleanYourTV opens and the Mombasa theme is intact.
- [ ] Switch back to Horizon and re-verify Home.
- [ ] Only after this passes, consider whether to uninstall Horizon? No — keep it.

If the TV shows a black screen, ADB still works; set Home back to
`com.gathin.tvhome/.MainActivity` and restore the accessibility list. Do not
factory reset.

## Rollback after the migration

1. Restore Home to `com.gathin.tvhome/.MainActivity`.
2. Restore `enabled_accessibility_services` and `accessibility_enabled` from
   `accessibility.txt`.
3. Reboot if the launcher does not return.
4. CleanYourTV's APK and data are still on the TV; nothing was uninstalled.
5. If Horizon must be removed: `adb uninstall com.horizon.home` (only after
   CleanYourTV is confirmed Home).

## Risks

| Risk | Mitigation |
|---|---|
| Exact SF Pro APK not in git | Pull it before any change; keep it in the local backup |
| App data not backupable (`allowBackup=false`) | Keep CleanYourTV installed; back up theme/config; screenshot layout |
| Accessibility helpers fight for Home | Record the exact list; set Horizon only; restore on rollback |
| Stock launcher disabled | Keep CleanYourTV installed as fallback; do not disable it |
| `set-home-activity` prints Success but doesn't stick | Always verify with `resolve-activity` |
| TV IP changes | DHCP reservation, or scan with `find-tv.bat` |
| 2.3 GB RAM + 1920 px art | Monitor meminfo; fall back to 1280 px |
| Secret leakage | Backups outside git; no `config.bat`, keys, IPs, or personal screenshots in the repo |
