# ART NEEDS (production pass)

Art the user (or an artist) should supply. Until then the game uses the placeholders noted.
All art must be original (no JJK, no Ninja Arashi 2 assets). Hero look: spiky indigo-black
hair, half-face oni-fang mask, crimson scarf, dark coat, blue aura (SPEC §3).

Common format for hero frames: PNG, transparent background, painted at 1.5x gameplay scale
(the game draws them at 1/1.5), character 170-230 px tall in the file, feet 3 px above the
bottom edge, body centred horizontally, facing RIGHT. Sheets are uniform cells; re-run
`python3 tools/gen_hero_sheets.py` after replacing source frames, or deliver finished sheets
with the same cell layout.

## Phase 1 — hero

| # | File | Size (per cell) | Frames | Poses | Placeholder now |
|---|------|-----------------|--------|-------|-----------------|
| 1 | assets/sprites/hero/hero_run_sheet.png | 140 x 189 (8 x 1) | 8 | contact R, down R, passing R, up R, contact L, down L, passing L, up L | 4 painted keys (run1-4) + 4 derived "lifted" in-betweens (scaled copies of the next key) |
| 2 | assets/sprites/hero/hero_idle_sheet.png | 120 x 200 (6 x 1) | 6 | breathing loop: neutral, inhale 1, inhale 2 (shoulders up, scarf lift), hold, exhale 1, exhale 2 | 1 painted idle frame scaled for breathing |
| 3 | assets/sprites/hero/hero_slash_sheet.png row 0 | 288 x 229 (5 x 3 sheet) | 5 | hit 1 overhead→forward cut: windup, raise, contact, through, follow | existing painted s_* frames |
| 4 | hero_slash_sheet.png row 1 | 288 x 229 | 5 | hit 2 return backhand (low→high): windup, swing, contact, through, recover | reused s_follow / s_over / a_contact / a_down / s_recover (air poses on the ground) |
| 5 | hero_slash_sheet.png row 2 | 288 x 229 | 5 | hit 3 heavy finisher (two-hand rising or spinning cut): deep windup, launch, contact, over, settle | reused s_windup (squashed), s_high, s_through, s_over, a_follow |
| 6 | assets/sprites/hero/throw_*.png | ~160 x 190 | 4 | kunai throw: reach back, release (arm extended), follow, recover | single run1 frame + lean |
| 7 | assets/sprites/hero/domain_*.png | ~180 x 230 | 5 | DOMAIN rite: hand sign, blade raised, moon pose hold (2 frames), release | s_high + rise |
| 8 | assets/sprites/hero/victory_*.png | ~160 x 230 | 6 | victory: sheathe, turn to camera, fist up / scarf flutter (hold loop 3) | j_rise hop + s_recover |
| 9 | assets/sprites/hero/dead_*.png | ~220 x 160 | 4 | knocked down: stagger, fall, on ground, fade | hurt frame tilted and faded |
| 10 | assets/sprites/hero/double_jump_*.png | ~140 x 160 | 4 | somersault tuck (4 rotations) | j_tuck frame spun in code |
| 11 | assets/sprites/hero/wall_*.png | ~110 x 175 | 3 | wall slide loop (coat/scarf flutter) | single wall frame |

Notes
- Placeholder in-betweens are made by tools/gen_hero_sheets.py from the existing original
  painted frames; no outside art was used.
- The rim outline is a shader (painted.gdshader `outline_width`), so frames should NOT have a
  baked outline (the soft blue aura already painted on the frames is fine).

## Phase 2 — enemies and bosses

Now in game: one original painted 4-frame strip per character (tools/gen_phase2_art.py from
art_src/p2_*.jpg): 0 idle, 1 move, 2 windup, 3 attack. ALERT / CHASE / RECOVER / HURT / DIE
reuse those frames with procedural lean, squash, flash, topple and fade. Final art should be
uniform-cell strips (PNG, transparent, facing RIGHT, feet 3 px above the bottom, stored at 1.5x).

| # | File | Cell size | Frames wanted | Poses | Placeholder now |
|---|------|-----------|---------------|-------|-----------------|
| 12 | assets/sprites/p2/oni_brute.png | 256 x 294 | 12 | idle 2, walk 4, shield-block 1, windup 2, smash 2, die 1 | 4 painted frames |
| 13 | assets/sprites/p2/kitsune_archer.png | 203 x 261 | 11 | idle 2, walk 4, nock 1, draw 2, release 1, die 1 | 4 painted frames |
| 14 | assets/sprites/p2/shadow_assassin.png | 259 x 222 | 11 | idle 2, run 4, vanish 1, appear 1, coil 1, dash-slash 2 | 4 painted frames + spark smoke |
| 15 | assets/sprites/p2/bomb_monk.png | 205 x 253 | 10 | idle 2, walk 4, light fuse 2, throw 2 | 4 painted frames |
| 16 | assets/sprites/p2/crow_scout.png | 139 x 157 | 8 | flap 4, shriek 2, dive 1, hit 1 | 4 painted frames (flap uses 0-1) |
| 17 | assets/sprites/p2/boss_gorrah.png | 331 x 369 | 14 | idle 2, walk 4, slam windup 2, slam 1, throw 2, charge 2, stunned 1 | 4 painted frames |
| 18 | assets/sprites/p2/boss_vey.png | 306 x 361 | 14 | float 3, cast windup 2, cast 2, censer sweep 3, vanish 2, die 2 | 4 painted frames |
| 19 | assets/na2-style backdrops for L8 / L12 | 1280 x 720 per layer | — | Gorrah quarry (stone, ochre dust) and Vey smoke shrine (violet haze) sky / mid / near layers | shared red-moon boss layers with a colour tint |
| 20 | Rin death / intro frames | Rin strip cell | 4 | intro taunt 2, defeated kneel 2 | existing strip + procedural fade |
| 21 | Projectile art | 64 x 64 each | 1-2 | arrow, bomb (2 fuse frames), boulder, shock wave, smoke bolt, moon crescent | drawn with Line2D / polygons |
| 22 | Phase 3 parallax plates per scenario (Gion rooftops, bamboo, waterfall cave, burning shrine, canal, frozen pagoda, night palace) | 1280 x 720 per layer, 4+ layers | — | sky / far / mid / near painted layers | existing snow / forest / boss layers with a per-scenario tint |
| 23 | assets/tiles/stage_tiles.png | 32 x 32 tiles, 7 rows | 8 per row | top, fill, one-way plank, roof top, roof fill, dark fill for each scenario | recoloured env art + procedural roof and plank tiles |
| 24 | Mechanic props | 32-96 px | 1-4 | spring (2 frames), saw blade (spin), timed spike (3 states), gate + switch (2 states), lantern (flicker), rope + anchor, moving platform / canal boat, crumble tile (3 crack stages) | Polygon2D / ColorRect / Line2D placeholders |
| 25 | Rising water + waterfall surface | 1280 x 64 strip, tiling | 4 | animated surface loop | translucent ColorRect |
| 26 | Weather particles | 16-32 px | 1-3 | snow flake, rain streak, ember, petal | CPUParticles2D default quads |
| 27 | Skill icons | 96 x 96 | 9 | Combo Ink, Twin Kunai, Moon Finisher, Rite Echo, Ghost Step, Moon Veil, Coin Sense, Iron Ward, Second Breath | text-only lacquer cards |
| 28 | Shop item art | 128 x 128 | 5 + 3 skin previews | Healing Tea, Ward Talisman; Crimson Ronin / Jade Monk / Moonlit hero previews | text cards; skins are a colour grade on the existing hero |
| 29 | Artifact art | 128 x 128 | 4 | Fox Bell, Moon Mirror, Crow Feather, Stone Heart (for the existing artifact ring) | text cards |
| 30 | Ink-wipe brush texture | 1280 x 720 alpha | 1 | hand-painted brush edge for transitions | procedural noise edge shader |
| 31 | Tutorial / hint card frame | 640 x 96 9-slice | 1 | parchment / lacquer frame | StyleBoxFlat panel |
| 32 | Music (composer) | OGG loops, mono/stereo, ~30-60 s | 5 | menu, act 1 (snow/Gion), act 2 (bamboo/cave/shrine), act 3 (canal/pagoda/palace), boss | procedural koto/flute/taiko loops (tools/gen_music.py) |
| 33 | Bespoke SFX | OGG, short | ~6 | DOMAIN cast, boss roars x3, saw whirr loop, wind gust loop, water rise loop | Kenney CC0 picks + original boss_roar.wav |
| 34 | Play Store feature graphic | 1024 x 500 PNG/JPG, no alpha | 1 | key art: hero silhouette on a Kyoto rooftop under the red moon, "SHADOW NINJA" title area left/centre (original art only) | none yet; could be cropped from a release screenshot as a stopgap |
| 35 | Play Store phone screenshots (final) | 1920 x 1080 (16:9) | 8 | clean captures with no debug text, ideally with marketing captions | ui-mockups/release_*.png + phase4/phase5 captures at 1280 x 720 |
