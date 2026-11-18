# Animation audit (baseline 72820db, branch feature/anim-juice)

Scope: Player.gd / Player.tscn, Enemy.gd / Enemy.tscn, Boss.gd / Boss.tscn, FX.gd,
Shuriken.gd / Shuriken.tscn, Level.gd (player-over-touch copy, HUD, pause, results),
TouchControls.gd. Read from source; no runtime profiling.

## Art constraint
All actors are single painted, green-screen-keyed sprites (player: 8 separate
textures; enemies / boss: 4-frame hframes strips). There are no separate limb
layers, so a LegBack/LegFront/ArmBack/ArmFront/Weapon split would cut the painted
character apart. Decision: keep the painted sprite on screen and drive squash /
stretch, bob, lean, recoil and the slash trail on the painted body; limb nodes are
optional and are skipped with a warning when absent (no silhouette / dummy rig).

## Player (Player.gd, Player.tscn)
State changes with no animation (only an instant texture swap in `_update_anim`):
- idle <-> run: hard swap; run cycle is a 4-step texture flip with no bob.
- ground -> air (takeoff): swap to `jump`, no stretch.
- air -> ground (landing): swap back, no squash or impact.
- rising vs falling: same `jump` texture, no distinction (no FALL state).
- wall slide: swap to `wall`, no settle.
- dash: swap to `dash` + afterimages; no lean / stretch.
- slash: `_slash_pose = 0.16` forces the `slash` texture; no lunge, no weapon trail
  on the body (FX.ink_slash is a world decal only).
- throw (`throw_shuriken`): no pose at all.
- hurt (`take_damage`): flash + i-frame blink only, no recoil.
- death (`die`): instant teleport to checkpoint, no death pose.
- no emote / idle breathing.
Instant swaps / direct writes that conflict with a procedural animator:
- `sprite.texture = TEX[k]` every physics frame (owns the texture).
- `sprite.scale.x = abs(...) * sign(direction)` is both the visual flip and the
  facing state read by dash (`dash_dir`), throw and slash. Squash on the same node
  would be overwritten / would corrupt the facing sign.
- `sprite.scale` / `sprite.offset` set once in `_ready` (gameplay scale 1/1.5, feet at y=28).
- `sprite.visible` toggled for the i-frame blink (`_process`).
- `FX.flash` writes the shader `flash` parameter (OK, material only).
- `_aura.position = sprite.position`.
- Level.gd `_sync_player_vis` / `_copy_vis` re-draw the player on CanvasLayer 6 by copying
  the sprite (looks up `player/Sprite2D` by path; decomposes rotation + scale from the
  global transform and resets position to zero). Moving the sprite under an animator
  breaks the lookup, and the decomposition mis-handles a mirrored basis
  (rotation = PI + negative x scale). Must be updated together.
- `FX.afterimage` copies local `scale` and `global_position`, so a parent flip / squash is lost.

## Enemy (Enemy.gd, Enemy.tscn)
- `_animate` writes `spr.scale.x` (facing), `spr.frame`, `spr.position.y` (bob) every frame.
- `take_damage` tweens `$Sprite2D:position:x` for knockback while `_animate` writes
  `position.y` (separate axes, but two owners of the same transform).
- hurt: 0.12 s flash, no squash. Death: instant `queue_free` + burst.
- ranged windup: frame 2 when `shoot_timer > 1.55`, no lean; attack frame swap only.
- patrol turn-around: instant flip.

## Boss (Boss.gd, Boss.tscn)
- `_animate` writes `spr.scale.x`, `spr.frame`, `spr.position.y`.
- telegraph: frame 2 + `FX.flash(0.3)` + red ring + "!" (ring and "!" must stay).
- attack: frame 3 for 0.35 s, no lunge. Hurt: 0.1 s flash, no squash.
- phase 2: `rim_color` set on the material (must stay), speed change, no transition beat.
- death: instant `queue_free`, normal-size burst (same as a grunt).
- Note: all three boss ids use the `boss_rin.png` strip.

## FX.gd
- `hit_stop(tree, 0.06)` sets `Engine.time_scale = 0.05`; not toggleable.
- `death_burst` has a fixed size; no boss scaling.
- `freeze` (DOMAIN cut-in) pauses the tree; unaffected by this pass.

## Shuriken (Shuriken.gd / .tscn)
- Straight-line move, no spin, no spawn pop. (Left as is: projectile visuals are not in
  this pass's list; noted only.)

## Level.gd UI
- HUD: no reaction to damage (hp label text swap only).
- Pause: card appears instantly (`pause_menu.show()`).
- Results: stars appear all at once; book card appears instantly.
- Loading: progress fill tween exists (0.68 s), no pop-in.

## TouchControls.gd
- Buttons scale to 0.94 on press, instant (no easing). `release_all` resets scale.
- SPEC section 5 lists a "Throw disc (from L2)"; the code has no throw disc (L2+ has
  jump / dash / domain / attack). Not changed (layout freeze); reported as a spec conflict.

## Menus
- MainMenu PLAY: instant 0.96 press scale; no entrance.
- Hub tiles, act-select nodes: no hover / press / entrance animation.
