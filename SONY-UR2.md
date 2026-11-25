# Sony Bravia UR2 notes

This fork is tuned for a **Sony BRAVIA 4K UR2** (`BRAVIA_UR2_4K`, MediaTek mt5893,
Android TV 10, 2.3 GB RAM, 4K panel). The same build works on other Android TV 8+
devices.

This is the TV currently running the CleanYourTV launcher. The migration from
CleanYourTV to Horizon Home is documented in
**[MIGRATION-PLAN.md](MIGRATION-PLAN.md)**.

## What this fork changes

- **Sony-friendly labels:** “TV settings”, “TV CHANGES”, and “your TV home” replace
  the projector wording on non-XGIMI devices.
- **XGIMI-only settings hidden:** the power-button tweak is not shown on a Sony TV.
- **Sharper 4K artwork:** full-screen backdrops now load at 1920 px instead of 1280 px.
  On the UR2's 2.3 GB RAM, watch the memory panel; revert to 1280 px if it feels heavy.
- **NextDNS UI hidden unless configured:** the lean profile does not use NextDNS.
- **Sony install notes:** this file, `windows/find-tv.bat`, and the migration plan.
- `xgimi-power-*.bat` remains for XGIMI owners but is **not** for this TV.

## Compatibility

| Check | UR2 |
|---|---|
| OS | Android TV 10 (API 29) — app minimum is Android 8 / API 26 |
| RAM | 2.3 GB — launcher uses roughly 160 MB; 1920 px backdrops use more |
| Display | 3840 × 2160, 16:9 — landscape UI |
| Remote | D-pad + Home + Back — fully navigable |
| Install | ADB over Wi-Fi on port 5555 |
| HDMI shortcut | Sony HDMI inputs are exposed through `TvInputManager` |
| Live TV | The kit's guide is IPTV via Nuvio, **not** Sony's antenna/tuner |

## Install (standalone)

If CleanYourTV is **not** installed:

1. On the TV:
   - Settings → Device Preferences → About → tap **Build** seven times.
   - Back → **Developer options** → turn on **ADB debugging**
     (Sony may call it *USB debugging* or *Network debugging*).
   - Keep the TV and this PC on the same Wi-Fi/LAN.
2. On the PC, in `windows/`:
   - `get-adb.bat` — downloads Google's platform-tools.
   - `find-tv.bat` — scans port 5555 and writes `found-projector.txt`.
   - `setup-config.bat` — enter the TV address, e.g. `192.168.1.50:5555`.
3. Download `HorizonHome.apk` from the fork's **Releases** and put it in `windows/`.
4. Run `install-horizon.bat`.
   - Accept the **“Allow ADB debugging?”** prompt on the TV (tick *Always allow*).
   - The script installs the APK, grants permissions, makes Horizon Home the home
     screen, enables the accessibility Home-button helper, and pushes optional keys.
5. Press **Home** on the Sony remote.

## Replacing CleanYourTV

Do **not** run `install-horizon.bat` blindly on the UR2. CleanYourTV already owns
Home, the stock launcher is disabled, and its accessibility helpers may be enabled.
Use **[MIGRATION-PLAN.md](MIGRATION-PLAN.md)**: back up, install Horizon without
switching Home, verify it renders, then switch Home and rehearse rollback.

The important differences:

- Keep `com.gathin.tvhome` installed as the fallback. Do not uninstall it.
- Do not re-enable the stock Google launcher unless you are rolling back to it.
- Back up the exact `enabled_accessibility_services` list before enabling
  Horizon's `HomeButtonService`.
- Verify Home with `resolve-activity`, not just the `Success` message.
- The CleanYourTV APK on the TV is an SF Pro local build that is not in git;
  pull it before changing anything.

## Do not run on the UR2

- `windows/xgimi-power-full-off.bat`
- `windows/xgimi-power-standby.bat`

These change XGIMI's `power_key_definition`; they have no meaning on a Bravia.

## Undo

Standalone installs:

- `windows/use-original-home.bat` — restores the previous home screen, Home-button
  accessibility list, and launcher default.
- `windows/uninstall-horizon.bat` — removes Horizon Home.
- Keep the `windows/backup/` folder; the undo scripts read it.

CleanYourTV migration: follow the rollback section in
**[MIGRATION-PLAN.md](MIGRATION-PLAN.md)**.

If the TV gets stuck on a black screen after switching launchers, reconnect with
`adb connect <TV-IP>:5555` and set Home back to
`com.gathin.tvhome/.MainActivity`, or open Android TV Settings from the remote and
pick the stock launcher.

## Known Sony quirks

- **Memory panel:** Horizon reads per-app memory by talking to the TV's own ADB port at
  `127.0.0.1:5555`. If Sony doesn't expose adbd on loopback, the panel shows a message;
  the rest of the home screen is unaffected.
- **Home button:** takeover uses `cmd package set-home-activity` plus an accessibility
  service. Android 10 supports both, but some Sony firmware may briefly show the stock
  launcher before Horizon comes forward. The installer sets the default; a reboot can help.
- **TV settings:** the gear uses `com.android.tv.settings` when present and falls back to
  Sony's standard Settings app.
- **4K artwork:** 1920 px backdrops are a balance between sharpness and memory. If the
  launcher feels heavy on 2.3 GB, change `WALL_W` in `HomeActivity.java` back to `1280`
  and use `w1280` in `HomeActivity`/`ServiceActivity`.
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
