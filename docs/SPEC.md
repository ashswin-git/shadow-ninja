> Note: the current public release is **v1.2.0** (versionCode 3). This SPEC was written for an earlier snapshot; some version, path, and APK lines below are historical.

SHADOW NINJA
Specifications and work done
Document date: 12 November 2026, Asia/Calcutta (IST)
This describes the game as it actually is in the latest build, not the older README wishlist.

================================================================
1. GAME IDENTITY
================================================================

Name:                Shadow Ninja
Package:             com.ashswin.shadowninja
Version:             1.0.0 (Android versionCode 1)
Engine:              Godot 4.3 (GDScript), Forward Plus renderer
                     Mobile renderer: gl_compatibility
Resolution:          1280 x 720, landscape (sensor_landscape)
Main scene:          Title / Main Menu
Repository:          https://github.com/ashswin-git/shadow-ninja
Latest game code:    branch ui-overhaul, commit 72820db
                     (local only as of this document; not pushed to GitHub)
Latest APK:          dist/ShadowNinja-1.0.0.apk
                     Built and signed 12 Nov 2026, 8:36 AM IST
                     Size: 26,005,830 bytes (about 24.8 MiB)
                     SHA-256: 7237e4a9ab08d1e641dfcd8eea5d461c23f70c07e79e0fbb6b1067ea989c4d35
                     Signing: Android v1 / v2 / v3
                     Architecture: arm64-v8a only
                     Debug and release keystore signing is set in the export preset

Genre:               Original 2D action platformer, Kyoto / ninja setting
Aim:                 Commercial-looking mobile game with polished UI,
                     original characters, and one unique special move (DOMAIN)

================================================================
2. HARD RULES (STILL IN FORCE)
================================================================

- The game is original. It is not a Ninja Arashi 2 clone of art, audio,
  maps, or characters.
- Ninja Arashi 2 was used only as a layout and measurement reference
  (how menus, HUD and buttons are placed). Its art is not copied.
- Real Jujutsu Kaisen characters are not used, and will not be used,
  unless a licence is confirmed.
- Art in the build is original (painted plates generated for this
  project, plus procedural chrome) or CC0 / OFL:
    * Kenney Fantasy UI Borders (CC0) and Kenney UI Pack (CC0)
      for gold frames, stars and chevron arrows
    * Source Serif Pro (SIL Open Font License) for banners and titles
    * Nanum Brush Script, Latin subset (SIL Open Font License)
      for Loading and K.O. lettering
- gohud was considered but not used: it needs Godot 4.7, this project
  is 4.3.
- Godot Open RPG and Levrault's 2D action-adventure demo (both MIT)
  were studied for UI patterns only; their files were not copied.
- Credits: third_party/CREDITS.md and ASSET_LICENSES.md in the project.

================================================================
3. SETTING AND CHARACTERS
================================================================

Setting:             Winter Kyoto — snow, mist forest, red-moon boss court,
                     pagodas, torii, lanterns, Gion streets.

Hero (original):     Spiky indigo-black hair, half-face oni-fang mask,
                     crimson scarf, dark coat, blue aura.
                     This is the approved look after an earlier hero
                     was rejected for looking too much like Gojo.
                     The painted menu / hub portrait is high quality.
                     The in-game player sprite is still smaller and
                     simpler than the menu hero.

Enemies (original):  Oni-masked ashigaru (melee patrol)
                     Kitsune-masked shuriken thrower (ranged)
                     2 hit points each, 4 painted poses (limited animation)

Bosses (named in code):
  Level 4  — Rin the Pale Blade      15 HP   (painted original art, unique arena)
  Level 8  — Gorrah the Stone Oni    25 HP   (named; no unique art or arena yet)
  Level 12 — Smoke Lord Vey          40 HP   (named; no unique art or arena yet)
  All three currently use Rin's painted sprite.
  At half health a boss enters phase 2: faster, more projectiles,
  redder tint. A telegraph ring and "!" appear before each attack.
  Phase 2 toast: "PHASE 2 - CRIMSON FURY".

================================================================
4. GAMEPLAY SPECIFICATIONS
================================================================

Movement
  Run speed:              300
  Jump velocity:          -500
  Double jump velocity:   -450
  Dash speed:             900, lasts 0.2 seconds, toast name "SHADE STEP"
  Wall slide speed:       80 (while holding a wall, falling)
  Wall jump:              yes (pushes off the wall)
  Coyote time:            0.12 seconds
  Jump buffer:            0.12 seconds
  Screen shake and hit flash on hits / dash

Health
  3 hearts. Contact, traps and enemy projectiles deal 1 damage.
  Invulnerability after a hit: 0.9 seconds (sprite blinks).
  On death the player respawns at the last checkpoint with full hearts.
  "K.O." screen plays on a boss death (player or boss).

Combat
  Ashen Crescent (slash):     J / attack button
                              1 damage, reach about 80, cooldown 0.28 s
  Kunai / shuriken:           K / throw button
                              speed 600, 1 damage
  Void Lotus Step (dash):     Shift or I on keyboard
                              Touch dash button is shown from level 2
                              (Mist Hollow) and on boss stages
  Hollow Moon Rite (DOMAIN):  L / DOMAIN control
                              Official move name on the cut-in:
                              "VEIL OF THE STILL MOON"
                              Radius 280, 3 damage to enemies and bosses
                              in range, cooldown 6 seconds
                              Gold moon-ring visual + portrait cut-in
                              DOMAIN bar sits at the bottom centre of the HUD
                              (this is a unique special, not a second HP bar)

Scoring
  Coins in each stage. Completing a normal stage:
    3 stars if every coin is collected
    2 stars if at least one coin is collected
    1 star if the stage is cleared with no coins
  Boss clear always awards 3 stars.
  Beating a boss stage (4, 8 or 12) also adds 1 gem.
  Best star count per stage is saved. Coins add to a running total.
  Progress is saved to user://shadow_ninja_save.json
    (unlocked_level, level_stars, total_coins, total_gems, music_on).

================================================================
5. CONTROLS
================================================================

Action                 Keyboard                         Touch (on-screen)
Move left / right      A / D, or Left / Right arrows    Physical gold d-pad
Jump / double jump     Space, W, or Up                  Jump disc
Slash                  J                                Slash disc
Kunai                  K                                Throw disc (from L2)
Dash                   Shift or I                       Dash disc (from L2)
DOMAIN                 L                                DOMAIN (from L2 / bosses)
Pause                  Escape                           Gear button, top-right

A known earlier bug (A/D/Space did nothing, and J both dashed and slashed)
was found on 5 Nov 2026 and is fixed in the current build.

Pause menu:  Resume, Restart, Music On/Off, Hide UI, Main Menu.
Info screen in the hub also lists these controls.

================================================================
6. SCREENS AND FLOW
================================================================

1) Title          Painted snowy Kyoto, gold "SHADOW NINJA" frame, red PLAY
2) Loading        Painted Kyoto night, gold frame, "Loading..." and a bar
3) Hub            Hero on the left; tiles: Story, Skills, Shop, Artifact,
                  Challenge; Settings and Info; gold and gem counters
4) Act select     ACT 1 / 2 / 3 banner, cinematic preview, diamond stage
                  buttons, lock icons, star totals
5) In-level HUD   Top-left portrait in a gold ring, hearts / gems / coins,
                  stars under the portrait, gold level-name banner,
                  boss bar (boss stages), DOMAIN bar at the bottom,
                  gear (pause), d-pad left, action discs right
6) Pause          Wood-and-gold panel over the live stage
7) Results        Book-style pages: stage number, stars, Next / Restart /
                  Main Menu. Boss results use the same book with a boss variant
8) K.O.           Large brush "K.O." on the red-moon court

Hub tiles that are still placeholders (look finished, content is not):
  Skills     — text only: Ashen Crescent, Void Lotus Step, Hollow Moon Rite.
               "Further paths will open as the story is written."
               There is no real skill tree or unlock spending yet.
  Shop       — "The stall is empty for now. No packs, no paid unlocks."
  Artifact   — empty ring, "Relics will sit here when the story yields them."
  Challenge  — "No challenges are open yet."

================================================================
7. LEVELS — DESIGNED vs ACTUALLY BUILT
================================================================

The act select and code reserve 12 stages in 3 acts.
Only some of them have a unique hand-built layout.

ACT 1 — Ash Snow
  1  Ash Snow Gate       UNIQUE. Intro staircase, 4 coins, 2 melee enemies,
                         1 checkpoint, exit portal. Snow-stone platforms.
  2  Mist Hollow         UNIQUE. Zig-zag ledges over a spike pit, 5 coins,
                         1 ranged + 1 melee enemy, checkpoint, portal.
                         Mossy boardwalk platforms. Dash is introduced here.
  3  Lantern Row         Named only. Uses a generic generated layout,
                         not a unique map.
  4  Rin's Moon Court    UNIQUE boss arena. Open floor, two escape ledges,
                         a high retreat tower on the right, 2 spike traps,
                         3 coins, checkpoint. Petal-strewn red lacquer ground.
                         Boss: Rin the Pale Blade.

ACT 2 — Mist Hollow   (name reused as the act subtitle)
  5  Bamboo Veil         Generic layout
  6  Crimson Torii Path  Generic layout
  7  Kiyomizu Ledge      Generic layout
  8  Ember Shrine        Boss shell (Gorrah the Stone Oni, 25 HP) on a
                         simple generic arena, not a unique designed fight

ACT 3 — Silent Gion
  9  Willow Canal        Generic layout
  10 Frost Pagoda        Generic layout
  11 Silent Gion         Generic layout
  12 Throne of Night     Boss shell (Smoke Lord Vey, 40 HP) on a
                         simple generic arena, not a unique designed fight

Unlocking: the player starts with stage 1 unlocked. Clearing a stage
unlocks the next (up to 12). Acts 2 and 3 stay locked until the
player has reached those stage numbers.

Generic stages: a few platforms, 3+ coins, and a few enemies,
generated from the stage number. They are playable but not designed.

Traps in the unique maps are spike pits. Moving saws, lasers and
similar hazards mentioned in the old README are not in this build.

Themes used for painted ground:
  snow    — Ash Snow Gate
  forest  — Mist Hollow
  boss    — Rin's court (and other boss numbers)

================================================================
8. TECHNICAL STRUCTURE
================================================================

Scenes:   MainMenu, Hub, Meta, LevelSelect, Level, PauseMenu,
          Player, Enemy, Boss, Coin, Checkpoint, Portal, Trap,
          Shuriken, TouchControls, DomainFX (script)

Scripts:  GameManager and ContentPack are autoloads.
          Gameplay lives in Player, Level, Enemy, Boss, FX,
          TouchControls, Hub, LevelSelect, Meta, MainMenu, PauseMenu.

Physics layers: World, Player, Enemy, Projectiles, Items, Traps.

Export:   Android (arm64) and Web presets.
          Reference folders, art_src, tools, docs, third_party and
          ui-mockups are excluded from the shipped APK.

Audio:    Synthesized SFX — jump, dash, hit, coin, shuriken, win,
          boss_roar, click. A Music On/Off toggle is in the pause menu.

================================================================
9. WHAT WAS DONE IN THIS GAME (WORK HISTORY)
================================================================

Early build (through 5–7 November 2026)
  - Project created in Godot 4 as Shadow Ninja.
  - Movement feel: coyote time, jump buffer, screen shake, hit flash,
    wall slide / wall jump, double jump, dash.
  - First real L1 and L2 maps, a boss arena, parallax backgrounds,
    HUD, and touch controls.
  - Android arm64 export with the game data embedded (not an empty APK).
  - An empty first APK was found and rebuilt.
  - Hero was redesigned after looking too much like Gojo; the current
    indigo-hair / oni-mask / crimson-scarf look was approved.
  - DOMAIN was added as the unique special, with a portrait cut-in.
  - Boss telegraph, phase 2, combat VFX (slash trails, sparks, death
    bursts, vignette, i-frames).
  - Keyboard bugs fixed: A/D/Space actually work; dash moved off J
    onto Shift/I so slash and dash are separate.
  - DOMAIN damage raised to 3 so it is visible on the boss.
  - Touch buttons enlarged (about 120–136 px discs).
  - A signed playable APK and playtest video were produced around
    5–7 Nov 2026 (~23 MB at that time).

UI and reference (7–12 November 2026)
  - Ninja Arashi 2 gameplay was used only as a layout reference,
    after a request to watch many NA2 videos and build a similar UI.
  - About 25–28 reference frames and a measurement-focused
    NA2_UI_SPEC.md were written (layout only).
  - Structural UI pass: title on the left + PLAY on the right,
    hub with Story / Skills / Shop / Artifact / Challenge,
    act select with diamond stage buttons and a cinematic preview,
    compact top-left HUD, book-style results, gold banners,
    wood pause panel, player drawn in front of the touch buttons.
  - After this pass the layout was NA2-inspired, but the art was
    still a flat geometric prototype (blocky hero, thin trees,
    grey circles, cheap d-pad). That look was rejected as too poor.

Commercial art — menus (12 Nov 2026, ~8:00 AM IST, commit 457b69e)
  - Painted Kyoto title, hub and act-select.
  - Gold-lacquer HUD chrome and buttons, wood pause, book results.
  - Original painted hero key art.
  - Kenney CC0 borders composited as forged gold frames.
  - Menus jumped in quality. In-level art was still weak:
    flat black platforms, old enemy/boss sprites, a flat purple
    DOMAIN circle, a bare black "Loading..." screen.

Commercial art — in-level (12 Nov 2026, ~8:36 AM IST, commit 72820db)
  This is the latest build, answering "level UI is too bad":
  - Painted per-stage ground: snow stone, mossy boardwalk,
    petal-strewn red lacquer, textured stone / shrine floors.
  - New painted oni and kitsune enemies, and painted Rin.
  - DOMAIN is a gold moon ring, not a flat purple disc.
  - Painted loading screen with a gold frame and progress bar.
  - Tree silhouette no longer covers the top-left HUD.
  - Denser HUD and a physical gold d-pad.
  - Layout and gameplay were not changed in these art passes.

GitHub "heavy UI" search (12 Nov 2026)
  - Searched for an open-source game whose UI could be dropped in.
  - No complete GitHub game had a legally usable UI at this quality.
  - Licensed options used: Kenney Fantasy UI Borders, Kenney UI Pack.
  - MIT demos were studied, not copied. gohud was rejected (Godot 4.7).

================================================================
10. CURRENT STATUS (AS OF 12 NOV 2026, 8:36 AM IST BUILD)
================================================================

Done and playable
  - Title, loading, hub, act select, pause, results, K.O.
  - Unique, art-finished stages: Ash Snow Gate, Mist Hollow,
    Rin's Moon Court.
  - Movement, slash, kunai, dash, DOMAIN, checkpoints, coins,
    spikes, save / stars, Android APK.

Clearly better than the morning prototype, but still weak
  - In-game player is still small compared with the menu hero.
  - Enemy and boss animation is only a few poses.
  - Mid and near backgrounds are still silhouettes
    (pagoda, trees, torii), while the sky and ground are painted.
  - Coins, spikes and checkpoints still use the older simpler art.
  - Rin can sit partly under the right-hand touch buttons
    (layout was left unchanged).
  - Skills, Shop, Artifact and Challenge are honest placeholders.
  - Stages 3 and 5–12 do not have unique designed maps
    (3, 5–7, 9–11 are generic; 8 and 12 are named bosses
    without unique art or arenas).
  - No Jujutsu Kaisen content (no licence).
  - Not published on the Play Store.

This document matches the 8:36 AM IST APK (commit 72820db).
Stills:  ui-mockups/ingame_{l1,l2,boss,domain,ko,pause,loading}.png
         and artpass_{menu,hub,select,...}.png for the menu art.
Video:   ui-mockups/playtest_ingame.mp4
