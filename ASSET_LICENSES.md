# Asset Licenses

All assets used in **Aether Shinobi: Spirit Blade** are either CC0, commercial-use permitted, open-source under OFL, or procedurally generated.

| Asset Path | Description | Source / Generator | License |
| :--- | :--- | :--- | :--- |
| `res://content/original/fonts/OpenSauceSans-Regular.ttf` | UI & HUD Font | Open Sauce Sans / Sand-Box Google | Open Font License (OFL) |
| `res://content/original/fonts/OpenSauceSans-Bold.ttf` | Bold UI Font | Open Sauce Sans / Sand-Box Google | Open Font License (OFL) |
| `res://assets/sprites/*.png` | Character & Environment Sprites | Procedurally generated & Kenney.nl / CC0 asset pack | CC0 1.0 Universal / Public Domain |
| `res://assets/audio/*.wav` | Sound Effects & SFX | Procedurally synthesized / Kenney SFX | CC0 1.0 Universal / Public Domain |
| `res://assets/backgrounds/*.png` | Parallax Backgrounds | Generated via Python PIL & procedural drawing | CC0 1.0 Universal / Public Domain |

## QA-fix art pass (5 Nov 2026)
All sprites, tiles, icons, parallax layers (bg_sky/moon/mountains/trees) and the app icon are original,
generated in-repo by `tools/gen_art.py` (PIL, procedural). Released CC0 by the project. No third-party art shipped.
Reference screenshots (reference/, ui-mockups/) are excluded from the export via .gdignore and are never packaged.

## Phase 3 art (tools/gen_art2.py)
Original hero "Hakuro" (indigo-black spiky hair, half-face oni-detail ninja mask, crimson scarf collar, blue aura), Kyoto backdrop (pagoda, temples, bamboo, machiya, torii), mist, petal, paper lantern, glow: procedurally generated in-repo, CC0. No third-party or franchise assets.

## NA2 UI pass (12 Nov 2026)
- `res://assets/ui/hero_menu.png` — original high-res menu hero (indigo-black hair, half-face oni-fang mask, crimson scarf, blue aura), generated in-repo by `tools/gen_hero_hires.py`. CC0. Same character as `tools/gen_art2.py`; not a 64px upscale.
- `res://content/original/fonts/SourceSerifPro-Regular.ttf` and `SourceSerifPro-Bold.ttf` — Source Serif Pro (Adobe), SIL Open Font License, used for the gold level-name banner.

## Structural UI pass (12 Nov 2026)
- `res://assets/ui/chev_*.png`, `hud_heart/gem/gold.png`, `node_*.png`, `wood_*.png`, `book_page_*.png`, `preview_act*.png`, `hub_*.png`, `boss_cap_*.png`, `icon_home.png`, `arrow_act_*.png`, `currency_bar.png` — original procedural chrome by `tools/gen_ui2.py`. CC0. Layout language only; no NA2 art.
- `res://content/original/fonts/NanumBrushScript-Regular.ttf` — Nanum Brush Script (Naver / Google Fonts), SIL Open Font License, used for Loading and K.O. lettering. Not an NA2 font. The in-repo file is a Latin / Latin-1 subset of the original OFL font, covering Basic Latin, Latin-1, and the glyphs used for Loading and K.O.

## Commercial art pass (12 Nov 2026) — `tools/gen_artpass.py`, `tools/artlib.py`
- **Painted source plates** in `art_src/` (title vista, bamboo valley, crimson moon court, Gion street, hero key art,
  hero pose sheet, ink silhouette strips, wood and washi textures, four hub-tile still lifes) are original images
  generated for this project from text prompts with the Grok Bot image tool. The hero sheets used only this
  project's own earlier hero sketch as reference. No commercial game art, screenshots or characters were used as input.
  Released by the project; `art_src/` is excluded from export.
- **Derived textures**: `assets/ui/*` (menu_bg, hero_menu, portrait, portrait_ring, hud_plate, disc_action, btn_*,
  chev_*, star_*, node_*, lock, arrow_act_*, icon_home, wood_*, book_*, stage_banner, boss_frame/fill/bg,
  domain_frame/fill, title_frame, play_btn, currency_bar, top_strip, meta_plate, hub_*, preview_act*),
  `assets/na2/{snow,forest,boss}_sky.png`, `assets/na2/shared_{far,mid,near}.png`,
  `assets/sprites/player_*.png`, `paper_lantern.png`, `coin.png`. Procedural metal / lacquer / gem shading by `tools/artlib.py`.
- **Kenney CC0** borders, dividers, star and decorative arrow are composited into the chrome — see `third_party/CREDITS.md`.
- Fonts unchanged: Source Serif Pro (OFL), Nanum Brush Script Latin subset (OFL, ~70 KB; full TTF not re-imported).

## In-game art pass (12 Nov 2026) — `tools/gen_ingame.py`
- **New painted source plates** in `art_src/`: `enemy_oni.jpg` (oni-masked ashigaru, 4 poses), `enemy_kitsune.jpg`
  (kitsune-masked shuriken thrower, 4 poses), `boss_rin.jpg` (Rin the Pale Blade, 4 poses), `hero_run.jpg`
  (run cycle + slash of this project's own hero, using `art_src/hero_poses.jpg` as the only reference),
  `ground_snow.jpg`, `ground_forest.jpg`, `ground_boss.jpg` (side-view stage ground strips). All are original images
  generated for this project from text prompts with the Grok Bot image tool; original character designs, no
  commercial game art, screenshots or characters used as input. `art_src/` is excluded from export.
- **Derived textures**: `assets/sprites/enemy_oni.png`, `enemy_kitsune.png`, `boss_rin.png` (4-frame strips),
  `assets/sprites/player_{idle,run,run2,run3,jump,dash,wall,slash}.png`,
  `assets/env/{ground,plat,body}_{snow,forest,boss}.png` (keyed, graded, made seamless),
  `assets/fx/domain_{enso,sigil,moon}.png`, `assets/ui/{hud_plate,dpad_base,domain_medal}.png`
  (procedural ink / gold / lacquer by `tools/gen_ingame.py` + `tools/artlib.py`; HUD plate border is the Kenney
  CC0 border already credited in `third_party/CREDITS.md`).
- Shaders `assets/shaders/painted.gdshader`, `hud_clear.gdshader` — original.
- Retired: `assets/sprites/{boss1,boss2,boss3,enemy_patrol,enemy_ranged,tile,snow_rim}.png`,
  `assets/backgrounds/fg_silhouette.png`.
- No new third-party packs were added in this pass.

## Character animation pass (12 Nov 2026) — `tools/gen_char.py`
- **New painted source sheets** in `art_src/`: `hero2_core.jpg` (idle, 4-frame run, wall slide), `hero2_jump.jpg` +
  `hero2_jump_b.jpg` (crouch, launch, rise, tuck, apex, fall-start, fall, pre-land, land), `hero2_slash.jpg` +
  `hero2_slash_b.jpg` (7-frame ground slash: windup, high guard, contact, through, overswing, follow, recover),
  `hero2_air.jpg` (4-frame downward aerial slash + hurt pose), `oni_attack.jpg` (oni club windup / strike / recover),
  `rin_attack.jpg` (Rin draw / cut / follow-through), `hero2_portrait.jpg` (HUD bust of the same hero).
  All are original images generated for this project with the Grok Bot image tool. The only references used were this
  project's own earlier hero / enemy art (`art_src/hero.jpg`, `hero_poses.jpg`, `enemy_oni.jpg`, `boss_rin.jpg`) and
  the project's own HUD portrait. No commercial game art, screenshots, NA2 frames, JJK likeness or OpenGameArt/CC0
  ninja sprites were used. `art_src/` is excluded from export.
- **Derived textures**: `assets/sprites/hero/*.png` (27 individually-sized hero frames, chroma-keyed, normalised to one
  head size, feet-anchored), `assets/sprites/enemy_oni.png` (7-frame strip: 4 walk/idle + windup, strike, recover),
  `assets/sprites/boss_rin.png` (6-frame strip: 4 originals + draw, cut), `assets/sprites/enemy_kitsune.png`
  (re-keyed from the existing plate, no new poses), `assets/ui/portrait.png` (cropped from `hero2_portrait.jpg`),
  `assets/ui/icon_bg_432.png` (flat colour, adaptive-icon background, fully covered by the opaque foreground).
- Retired: `assets/sprites/player_{idle,run,run2,run3,jump,slash,dash,wall}.png`.
- No new third-party packs were added in this pass.

## Polish pass (12 Nov 2026) — `tools/gen_char.py`, `tools/gen_props.py`
- **New painted source sheets** in `art_src/`: `hero2_dash.jpg` (dash + braking skid of the same hero),
  `kitsune_throw.jpg` (kitsune windup / release / follow-through), `rin_cut.jpg` (Rin heavy windup / impact /
  follow-through), `rin_p2.jpg` (Rin phase-2 iai stance / dash draw-cut / rising crescent), `props_kyoto.jpg`
  (gold mon coin, iron spike row, stone toro lantern). Original images generated for this project with the Grok Bot
  image tool; the only references were this project's own earlier sheets (`hero2_core.jpg`, `enemy_kitsune.jpg`,
  `boss_rin.jpg`, `rin_attack.jpg`). No commercial game art, NA2 frames, JJK likeness or CC0 ninja sprites.
- **Derived textures**: `assets/sprites/hero/*.png` (same 27 frames, readability retouch: midtone lift, charcoal
  mask, brighter face/eyes, cool rim; plus `dash.png`, `dash_stop.png`), `enemy_kitsune.png` (7 frames),
  `boss_rin.png` (8 frames), `assets/sprites/{coin,spike,checkpoint}.png` (2x textures drawn at 0.5).
- `assets/shaders/painted_layer.gdshader` (original): shaded mid / near parallax layers.
- Retired: `assets/ui/hud_plate.png` (gold resource plate), `assets/ui/dpad_base.png` (chevron bar).
- No new third-party packs were added in this pass.
