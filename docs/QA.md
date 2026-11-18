# Shadow Ninja v1.1.0 (versionCode 2): QA checklist and test matrix

Phase 6, 14 Nov 2026 (IST). Branch `feature/production-pass`.
Box: Godot 4.3-stable official editor binary for the checks; Mesa llvmpipe (software GL) under xvfb for the captures. No Android device or working emulator was available. The AVD hangs at boot because nested KVM stalls, so **nothing below has run on Android yet**.

## How to re-run
| Check | Command (from the project root, with `G=godot` (or the path to your Godot 4.3 binary)) |
|---|---|
| Clean exit | `$G --headless --path . --quit` |
| Save / meta / touch | `$G --headless --path . -- --phase4` |
| Audio + per-stage profile, every stage | `$G --headless --path . -- --phase5 --profile --p5levels=1,2,3,4,5,6,7,8,9,10,11,12` |
| Bot run-through, tile stages | `$G --headless --path . --fixed-fps 60 -- --runthrough=N` (N = 3,5,6,7,9,10,11) |
| Release tape + screenshots | `xvfb-run -a -s "-screen 0 1280x720x24" $G --path . --rendering-driver opengl3 --resolution 1280x720 --write-movie /tmp/rel.avi --fixed-fps 30 -- --release` |

## Results verified here (14 Nov 2026)
- **Clean exit:** `--quit` prints only the engine banner, exit 0. Fixed in 4a740ff (no ObjectDB / resource leaks; Shuriken UID warning gone).
- **`--phase4`:** ALL PASS, 30/30 checks.
  - Save v1 to v2 migration keeps every key, writes a v1 backup, and round-trips.
  - A corrupt save falls back to defaults and the original is kept aside.
  - Skills tiers, shop, and artifacts (2 slots, a 3rd is refused) pass. The daily challenge is deterministic.
  - Touch-control drag is clamped. The default jump centre is (1177, 532), matching SPEC §5.
  - The L1 tutorial works, and wards and the combo counter work.
- **`--phase5 --profile`, all 12 stages:** each stage loads and runs for 12 s with no script errors.
  - Headless frame time averages 6.9 ms on every stage. p99 ranges from 9.6 ms (L4) to 16.3 ms (L9); max is 28 ms (L10).
  - The headless numbers include CPU and physics only, with no GPU work.
  - Nodes max out at 208–969 (L5 is the most).
  - Pool: 64 new, 401 reused.
  - Buses are Master / Music / SFX. There are 5 music tracks (26.7–36.9 s), and none of the 19 SFX is missing.
- **Bot run-throughs.** All 7 tile stages finished. Game time is the bot's, so it's slower than a skilled human. The bot also uses "assists": teleporting to the next chunk after 8 s stuck.

| Stage | Time | Deaths | Assists | Coins |
|---|---|---|---|---|
| L3 Gion | 2:10 | 2 | 5 | 22/52 |
| L5 Bamboo | 2:35 | 3 | 4 | 13/44 |
| L6 Cave | 3:09 | 12 | 7 | 11/32 |
| L7 Shrine | 3:58 | 8 | 6 | 13/42 |
| L9 Canal | 2:20 | 3 | 4 | 13/34 |
| L10 Pagoda | 2:19 | 1 | 5 | 15/41 |
| L11 Palace | 3:08 | 7 | 8 | 13/39 |

- **Media:** `ui-mockups/playtest_release.mp4` (27.6 s, 6.2 MB, H.264 + AAC) and `ui-mockups/release_{menu,stage,mechanic,boss}.png`. Checked by eye: none is blank.
- **APK:** signed with v1/v2/v3 and verified with apksigner. aapt reads versionName 1.1.0 / versionCode 2, minSdk 21, targetSdk 34, and the package has no INTERNET permission.

## Test matrix
✔ = verified here · ◐ = partly (bot or headless only) · ☐ = needs a real device

| Stage | Loads (12 s) | Finishes | Boss beatable | Touch | Audio heard | 60 FPS on device |
|---|---|---|---|---|---|---|
| L1 Snow village (hand-built) | ✔ | ☐ (not bot-run) | – | ◐ tutorial | ☐ | ☐ |
| L2 (hand-built) | ✔ | ☐ | – | ☐ | ☐ | ☐ |
| L3 Gion | ✔ | ◐ bot 2:10 | – | ☐ | ☐ | ☐ |
| L4 Boss Rin | ✔ | – | ◐ Phase 2 harness | ☐ | ☐ | ☐ |
| L5 Bamboo | ✔ | ◐ bot 2:35 | – | ☐ | ☐ | ☐ |
| L6 Cave | ✔ | ◐ bot 3:09 | – | ☐ | ☐ | ☐ |
| L7 Shrine | ✔ | ◐ bot 3:58 | – | ☐ | ☐ | ☐ |
| L8 Boss Gorrah | ✔ | – | ◐ Phase 2 harness | ☐ | ☐ | ☐ |
| L9 Canal | ✔ | ◐ bot 2:20 | – | ☐ | ☐ | ☐ |
| L10 Pagoda | ✔ | ◐ bot 2:19 | – | ☐ | ☐ | ☐ |
| L11 Palace | ✔ | ◐ bot 3:08 | – | ☐ | ☐ | ☐ |
| L12 Boss Vey | ✔ | – | ◐ Phase 2 harness | ☐ | ☐ | ☐ |

| System | Status |
|---|---|
| Save v2 + migration, corrupt-file fallback | ✔ `--phase4` |
| Skills / shop / artifacts / daily challenge | ✔ `--phase4` |
| Settings (volumes to bus dB) | ✔ `--phase5` (vol 0.5/0.25 to bus dB) |
| Pause / resume, music ducking | ◐ code path only; ☐ device |
| App backgrounding / resume, rotation lock (sensor_landscape) | ☐ device |
| Remapped touch layout persists across restarts | ◐ `--phase4` clamp; ☐ device |
| Slim export template (custom 4.3 build) starts and renders on Android | ☐ device. **Release blocker until smoke-tested** |
| Notch / cut-out safe area, small screens, 30-min thermals | ☐ device |

## Real-device smoke test (do first)
1. `adb install -r ShadowNinja-1.1.0.apk`, then cold start. The menu should render with music.
2. Play L1 to the end. Then open L4 (Rin) and land hits, a DOMAIN cast, and a kunai.
3. Check every font and glyph renders. The template uses the fallback text server (no complex shaping); ♥, the coin emoji, and the em dash should all appear.
4. Pause, background, and resume, then kill the app and relaunch. The save and settings should persist.
5. Remap a button, restart, and confirm the layout is kept.

## Bug log
| # | Found | Status |
|---|---|---|
| 1 | Headless exit: ObjectDB leaked / 2 resources still in use. menu.ogg playbacks never finish under the Dummy audio driver. | Fixed in 4a740ff |
| 2 | `Shuriken.tscn` had a placeholder texture UID, which caused a warning. | Fixed in 4a740ff |
| 3 | The APK was over 25 MiB (26.8 MB) with the official template. | Fixed: slim template, 17.7 MB signed |
| 4 | Harness runs that quit mid-level print "RID allocations leaked at exit" (dummy meshes, text-server font). Abrupt `quit()` with a live level; a plain `--quit` is clean. | Open, harness-only, cosmetic |
| 5 | The run-through bot needs 4–8 assists per stage (stuck > 8 s). This is bot pathing, not proven level blockers; a human playtest should confirm every stage is clearable. | Open, needs a device |
| 6 | The release tape under `--write-movie` once ran past its end (multi-GB AVI) in an earlier draft of the `--release` mode. The current version ends in 27.6 s. | Fixed |
