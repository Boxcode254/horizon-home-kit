# Sony Bravia X950G notes

This fork is tuned for a **Sony Bravia X950G** (2019, Android TV 9 Pie, 3 GB RAM, 4K panel),
but the same build works on other Android TV 8+ devices.

## What this fork changes

- **Sony-friendly labels:** “TV settings”, “TV CHANGES”, and “your TV home” replace the
  projector wording on non-XGIMI devices.
- **XGIMI-only settings hidden:** the power-button tweak is not shown on a Sony TV.
- **Sharper 4K artwork:** full-screen backdrops now load at 1920 px instead of 1280 px.
- **Sony install notes:** this file, plus `windows/find-tv.bat`.
- `xgimi-power-*.bat` remains in the repo for XGIMI owners but is **not** for this TV.

Everything else — the ad-free home screen, Nuvio rows, Live TV guide, NextDNS panel and
speed tweaks — is unchanged.

## Compatibility

| Check | X950G |
|---|---|
| OS | Android TV 9 Pie (API 28) — app minimum is Android 8 / API 26 |
| RAM | 3 GB — launcher uses roughly 160 MB |
| Display | 3840 × 2160, 16:9 — landscape UI |
| Remote | D-pad + Home + Back — fully navigable |
| Install | ADB over Wi-Fi on port 5555 |
| HDMI shortcut | Sony HDMI inputs are exposed through `TvInputManager` |
| Live TV | The kit's guide is IPTV via Nuvio, **not** Sony's antenna/tuner |

If your X950G is still on Android 8 Oreo, update it to the latest Sony firmware first.
The launcher is built against Android 9 APIs.

## Install

1. On the TV:
   - Settings → Device Preferences → About → tap **Build** seven times.
   - Back → **Developer options** → turn on **ADB debugging**
     (Sony may call it *USB debugging* or *Network debugging*).
   - Keep the TV and this PC on the same Wi-Fi/LAN.
2. On the PC, in `windows/`:
   - `get-adb.bat` — downloads Google's platform-tools.
   - `find-tv.bat` — scans port 5555 and writes `found-projector.txt`
     (`find-projector.bat` still works; the name is historical).
   - `setup-config.bat` — enter the TV address, e.g. `192.168.1.50:5555`.
3. Download `HorizonHome.apk` from this fork's **Releases → latest** and put it in `windows/`.
4. Run `install-horizon.bat`.
   - Accept the **“Allow ADB debugging?”** prompt on the TV (tick *Always allow*).
   - The script installs the APK, grants permissions, makes Horizon the home screen,
     enables the accessibility Home-button helper, and pushes your optional keys.
5. Press **Home** on the Sony remote. Horizon should open.
6. Optional:
   - Install **Nuvio** on the TV and add your addons. Without Nuvio, the streaming and
     Continue Watching rows stay empty.
   - Add a TMDB key for artwork: `setup-config.bat` asks for it.
   - Follow `livetv-addon/README.md` for your own Cloudflare-hosted Live TV guide.

## Do not run on the Sony

- `windows/xgimi-power-full-off.bat`
- `windows/xgimi-power-standby.bat`

These change XGIMI's `power_key_definition`; they have no meaning on a Bravia.

## Undo

- `windows/use-original-home.bat` — restores the previous home screen, Home-button
  accessibility list, and launcher default.
- `windows/uninstall-horizon.bat` — removes Horizon Home.
- Keep the `windows/backup/` folder; the undo scripts read it.

If the TV gets stuck on a black screen after switching launchers, reconnect with
`adb connect <TV-IP>:5555` and run `use-original-home.bat`, or open Android TV Settings
from the remote and pick the stock launcher.

## Known Sony quirks

- **Memory panel:** Horizon reads per-app memory by talking to the TV's own ADB port at
  `127.0.0.1:5555`. If Sony doesn't expose adbd on loopback, the panel shows a message;
  the rest of the home screen is unaffected.
- **Home button:** takeover uses `cmd package set-home-activity` plus an accessibility
  service. Android 9 supports both, but some Sony firmware may briefly show the stock
  launcher before Horizon comes forward. The installer sets the default; a reboot can help.
- **TV settings:** the gear uses `com.android.tv.settings` when present and falls back to
  Sony's standard Settings app.
- **4K artwork:** 1920 px backdrops are a balance between sharpness and memory. If the
  launcher feels heavy, change `WALL_W` in `HomeActivity.java` back to `1280` and use
  `w1280` in `HomeActivity`/`ServiceActivity`.
- **Public signing key:** `launcher/kit.keystore` is public so builds can update each other.
  Only install the APK from this fork's Releases (or build it yourself) — anyone with the
  repo can sign an APK with the same key.

## Build

The fork's GitHub Actions workflow builds on every push that touches `launcher/**` and
publishes the APK as the `latest` release. To build locally you need JDK 17 and Android SDK
build-tools 34 + platform 30:

```bash
BUILD_TOOLS=34.0.0 VERSION_CODE=200 launcher/build.sh
```
