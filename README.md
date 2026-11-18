# Shadow Ninja

An original 2D action platformer built in **Godot 4.3** (GDScript). Kyoto-inspired stages, painted character art, fluid ninja movement, a unique **DOMAIN** special move, and three named bosses.

**Current version: 1.2.0** (Android `versionCode` 3), package `com.ashswin.shadowninja`.

The signed 1.2.0 Android APK is published on [Releases](https://github.com/ashswin-git/shadow-ninja/releases).

## Features

- **Movement:** run, jump, double jump, dash, wall slide, and wall jump
- **Combat:** melee slash combo, kunai, and the DOMAIN special
- **12 stages** across three acts, with traps, vertical sections, and weather
- **Bosses:** Rin the Pale Blade (L4), Gorrah the Stone Oni (L8), Smoke Lord Vey (L12)
- **Progression:** skills, shop, artifacts, and a versioned save format
- **Controls:** keyboard on desktop; remappable on-screen touch controls on mobile
- **Presentation:** painted parallax stages, stereo music loops, and a 90+ FPS setup (uncapped `max_fps`, vsync, 2D physics interpolation)

## Controls

| Action | Keyboard | Touch |
|---|---|---|
| Move left / right | `A` / `D` or arrow keys | On-screen left / right |
| Jump / double jump | `Space` | Jump button |
| Dash | `J` | Dash button |
| Attack / throw | `K` | Attack button |
| DOMAIN | (in-game binding) | DOMAIN button |
| Pause | `Escape` | Pause |

Default touch layout follows the project spec (SPEC §5). Do not change those defaults, unique stage layouts, gameplay numbers, or the v2 save format without an explicit decision.

## Open the project

1. Install [Godot 4.3-stable](https://godotengine.org/download/archive/4.3-stable/).
2. Clone this repository and open the project folder in Godot.
3. The first open will regenerate `.godot/` import caches (that folder is not in git).
4. Press **F5** to play.

Optional headless checks (from the project root, after imports exist):

```bash
godot --headless --path . --quit
godot --headless --path . -- --phase4
godot --headless --path . -- --phase5 --p5levels=1,2,3,4,5,6,7,8,9,10,11,12
```

## Build the Android APK

The official 1.2.0 APK was exported with Godot **4.3-stable**, `gl_compatibility` (mobile), arm64-v8a only, Gradle build **off**, minSdk 21, targetSdk 34.

1. Point the Android export preset's custom release template at a Godot 4.3 Android release export template.
2. Keep your upload keystore **outside** this repo. Paths and passwords in `export_presets.cfg` are left blank on purpose.
3. Export:

```bash
godot --headless --path . --export-release Android build/ShadowNinja-1.2.0.apk
```

4. If the export is unsigned, sign it locally with `apksigner` and your private keystore. Do not put the keystore or its password in git or in a chat message.

Do not overwrite older release APKs; use a new versioned filename for new builds.

`export_game.py` and `build_apk.py` are leftover helpers. They read a local `keystore/keystore.properties` file (not in this repo). Prefer the Godot export command above.

## Official 1.2.0 APK

See the [v1.2.0 release](https://github.com/ashswin-git/shadow-ninja/releases/tag/v1.2.0) for `ShadowNinja-1.2.0.apk`.

- Size: 45.5 MiB (47,673,565 bytes)
- SHA-256: `2948f03f79e080fe6a2c94151f32c4db4bc851bb40bc5bb7fd0f3144d7737d0b`

## What changed in 1.2.0

Rich-art pass on top of 1.1.0, with the version name/code bumped to 1.2.0 / 3:

- Painted per-scenario parallax plates for all 12 stages
- 90+ FPS setup (uncapped max FPS, vsync, 2D physics interpolation)
- Hero / enemy / boss / FX / UI art imported lossless
- 8 arranged stereo music loops (per-boss themes plus a victory loop)
- Original lacquer-and-gold emblem icons on Skills / Shop / Artifact cards
- Crystal snow-flake and glow ember weather sprites, plus a domain-cast SFX

Gameplay numbers, unique stage layouts, the v2 save format, and default controls were not changed for this release.

This source matches git commit `f968d2b351e174df116a04ce18c1aab71c1e4b0e` (local `feature/production-pass` at the time of the 1.2.0 APK), with build outputs, signing files, and third-party App Store reference screenshots omitted from git.

## License and art

Game code and original art in this repository are project originals (plus CC0 / OFL third-party fonts and SFX credited in `ASSET_LICENSES.md` and `third_party/CREDITS.md`). Folder names such as `assets/na2/` are historical style labels for **original procedural** plates generated in-repo; they are not ripped commercial assets. Third-party store screenshots used only as layout reference are not included.
