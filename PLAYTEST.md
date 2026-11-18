# Playtest: round 5 (real input)
I ran this on 2026-11-05 at about 08:05 IST. It was a desktop debug run under Xvfb at 1280x720. The input was real X11 keypresses sent with xdotool, and the screen was recorded with ffmpeg x11grab.
Video: `ui-mockups/playtest_real.mp4` (40 s). The first 10 s are L1 "Ash Snow Gate"; the next 30 s are the L4 boss "Rin the Pale Blade". The phase-2 frame is in `playtest_phase2.png`.

## Blocking bugs found and fixed
1. **A/D and Space did nothing on the keyboard.** In project.godot, each input event paired a `keycode` (Right/Left/Enter) with a different `physical_keycode` (D/A/Space). Godot matches the keycode first, so only the arrow keys and Enter worked, and the controls screen was wrong. This affected the desktop and web builds. Fix: GameManager adds explicit physical bindings: A/Left, D/Right, Space/W/Up, J slash, K kunai, L DOMAIN.
2. **J was bound to both dash and slash**, so every slash also dashed. Dash is now Shift or I. The controls text is updated.
3. **DOMAIN did too little damage to the boss** (2/15 was hard to see). It now does 3 per cast. Three casts plus slashes reach phase 2 in about 25 s.

## Feel
- FPS: average about 84, minimum 57, maximum 105 (software GL under Xvfb, so a device should be faster). I saw no hitches during the cut-in freeze.
- Input lag: none I could see. Movement and slash respond on the next frame. DOMAIN has a deliberate 0.6 s cut-in freeze.
- Boss: the telegraph ring is readable. The HP bar drops visibly on each DOMAIN. At half health the "PHASE 2 - CRIMSON FURY" toast appears and the boss tint and speed change.
- Nothing got stuck. Death and respawn work. Note: hearts refill on respawn.
- Minor: the boss contact damage is harsh in melee range (I lost 2 hearts in about 5 s). I left it as it is.
