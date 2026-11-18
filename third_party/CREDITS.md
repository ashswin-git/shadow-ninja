# Third-party credits (Shadow Ninja art pass, 12 Nov 2026)

## Kenney — CC0 1.0 (public domain)
- **Fantasy UI Borders** v1.0 — https://kenney.nl/assets/fantasy-ui-borders
  Used: `PNG/Double/Border/*`, `PNG/Double/Divider*/*`, `PNG/Default/Border/panel-border-000.png`.
  9-sliced, recoloured and rendered as forged gold inlay by `tools/gen_artpass.py`
  (pause card, title frame, hub tiles, act previews, book pages, HUD plate, wood buttons, meta card, dividers).
- **UI Pack** v2 — https://kenney.nl/assets/ui-pack
  Used: `PNG/Grey/Double/star.png` (rating stars, re-rendered as gold / iron),
  `PNG/Grey/Double/arrow_decorative_e.png` (engraved inner arrow on the move chevrons).
- Licence text: `third_party/kenney_src/*/License.txt`. Credit "Kenney (www.kenney.nl)" given voluntarily.
- Downloaded from kenney.nl's official download links. Only the files listed above are committed;
  the folder carries `.gdignore` and is excluded from export (`third_party/*`).

## Character animation pass (12 Nov 2026)
- No third-party files added. All new hero, oni, Rin and portrait frames are original painted images
  (see `ASSET_LICENSES.md` → "Character animation pass").

## Polish pass (12 Nov 2026)
- No third-party files added; the HUD plate that carried the Kenney border was retired from the level HUD
  (the Kenney borders are still used by the pause card, hub tiles and other chrome).

## Not used
- gohud (needs Godot 4.7+; project is 4.3).
- No art, audio, fonts, maps or characters from Ninja Arashi 2 or any other commercial game.
  NA2 frames were used for layout/measurement reference only.
- godot-open-rpg / godot-2d-action-adventure-platformer-demo (MIT): studied for patterns only; no files copied.

## Audio pass (Phase 5, 14 Nov 2026)
### Kenney — CC0 1.0 (public domain), https://creativecommons.org/publicdomain/zero/1.0/
- **Impact Sounds** — https://kenney.nl/assets/impact-sounds
- **RPG Audio** — https://kenney.nl/assets/rpg-audio
- **Interface Sounds** — https://kenney.nl/assets/interface-sounds
- **Music Jingles** — https://kenney.nl/assets/music-jingles
- Downloaded 14 Nov 2026 from kenney.nl's official download links (each pack's License.txt: "License: (Creative Commons Zero, CC0)").
  Re-encoded to mono 22.05 kHz Vorbis (q2). Files used:
  - `assets/audio/sfx/back.ogg` ← Interface Sounds `Audio/back_002.ogg`
  - `assets/audio/sfx/block.ogg` ← Impact Sounds `Audio/impactMetal_heavy_000.ogg`
  - `assets/audio/sfx/boss_win.ogg` ← Music Jingles `Audio/Steel jingles/jingles_STEEL16.ogg`
  - `assets/audio/sfx/buy.ogg` ← Interface Sounds `Audio/confirmation_002.ogg`
  - `assets/audio/sfx/checkpoint.ogg` ← Impact Sounds `Audio/impactBell_heavy_000.ogg`
  - `assets/audio/sfx/click.ogg` ← Interface Sounds `Audio/click_002.ogg`
  - `assets/audio/sfx/coin.ogg` ← RPG Audio `Audio/handleCoins.ogg`
  - `assets/audio/sfx/crumble.ogg` ← Impact Sounds `Audio/impactWood_light_002.ogg`
  - `assets/audio/sfx/dash.ogg` ← RPG Audio `Audio/cloth3.ogg`
  - `assets/audio/sfx/enemy_hit.ogg` ← Impact Sounds `Audio/impactPunch_heavy_001.ogg`
  - `assets/audio/sfx/error.ogg` ← Interface Sounds `Audio/error_004.ogg`
  - `assets/audio/sfx/gate.ogg` ← RPG Audio `Audio/doorOpen_1.ogg`
  - `assets/audio/sfx/hit.ogg` ← Impact Sounds `Audio/impactPunch_medium_000.ogg`
  - `assets/audio/sfx/jump.ogg` ← RPG Audio `Audio/cloth1.ogg`
  - `assets/audio/sfx/ko.ogg` ← Music Jingles `Audio/Steel jingles/jingles_STEEL06.ogg`
  - `assets/audio/sfx/land.ogg` ← Impact Sounds `Audio/footstep_snow_001.ogg`
  - `assets/audio/sfx/saw.ogg` ← Impact Sounds `Audio/impactMetal_light_003.ogg`
  - `assets/audio/sfx/shuriken.ogg` ← RPG Audio `Audio/knifeSlice2.ogg`
  - `assets/audio/sfx/slash.ogg` ← RPG Audio `Audio/knifeSlice.ogg`
  - `assets/audio/sfx/spring.ogg` ← Impact Sounds `Audio/impactPlate_light_001.ogg`
  - `assets/audio/sfx/switch.ogg` ← RPG Audio `Audio/metalLatch.ogg`
  - `assets/audio/sfx/win.ogg` ← Music Jingles `Audio/Pizzicato jingles/jingles_PIZZI10.ogg`
### Original (no third-party material)
- Music `assets/audio/music/{menu,act1,act2,act3,boss}.ogg` — procedurally composed and synthesised by
  `tools/gen_music.py` (Karplus-Strong koto, breathy flute, taiko, drone; pentatonic yo / in-sen / hirajoshi).
- `assets/audio/boss_roar.wav` — unchanged from the earlier passes (original).
- Retired original SFX wavs moved to `art_src/old_audio/` (excluded from export).
