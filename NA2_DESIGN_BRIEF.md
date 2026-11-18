# NA2 Restyle Design Brief (1280x720)

## 1. Hex Palettes (Level Types)
- **Snow (L1):** Silhouettes #000000, Rim #ecf0fb, Parallax #7c989a, #6e878d, #556b7d, #344f6b, Accents #742f52 (posts), #e74c3c (spikes/HP).
- **Mist Forest (L2):** Silhouettes #000000, Rim #d8e2dc, Fog mint #7d897f, #717b72, Earth #382e28, Lantern gold #e0b050.
- **Crimson Boss (Boss):** Silhouettes #000000, Rim #ff4757, Sky/Mist #2a1b2e, #1a0f20, Arena stone #1f1f24, Accents #ff3838 (slash/blood).

## 2. HUD Layout (1280x720 px)
- **Top-Left (x: 32, y: 24):** Round portrait (ø 100px), 3 stars, HP bar (w: 220px, h: 24px, red #e74c3c), shuriken counter (blue #3a7bff), coin counter (gold #f1c40f).
- **Top-Right (x: 1140, y: 24):** Gear/Pause button (110x110px).
- **Top-Centre (x: 512, y: 24):** Ornate red boss bar (w: 512px, h: 28px) with 50% midpoint notch marker.
- **Top-Centre Toast (x: 384, y: 90):** Gold serif banner ("NEW ABILITY ACQUIRED").

## 3. Touch Controls (>=130px, 1280x720 px)
- **Bottom-Left (Movement):** D-Pad / Left-Right buttons (ø 140px each) at x: 60, y: 540 and x: 220, y: 540.
- **Bottom-Right (Actions):**
  - JUMP: ø 180px at x: 1080, y: 500
  - ATTACK: ø 150px at x: 900, y: 570
  - SHURIKEN: ø 140px at x: 1080, y: 320
- **Opacity / Style:** 60% alpha grey discs (#333333), pure-black silhouette icons, 2px white rim.

## 4. Menu Layout
- Title screen: Painted dark vista background, vertical Kanji/brush branding, minimalist thin serif "PLAY" button (w: 320, h: 72) centered at (640, 500).
- Level Select: Scrollable map node nodes with 3 gold star indicators per stage.

## 5. Atmosphere & Visual FX
- **Fog / Mist:** Dual parallax ColorRect shader layers (motion scale 0.1, 0.3) with alpha gradient (opacity 0.25–0.4).
- **God-Rays:** Rotated angled white transparent streaks (alpha 0.1) piercing top-down.
- **Silhouettes:** All player, enemy, and ground sprites modulated to pure black (#000000) with 1px rim highlight.
- **Combat Numbers:** Slash trail (Line2D, width 8px fading over 0.15s), hit flash (white/red 0.1s), death burst (red GPUParticles2D, 40 particles), hit-stop (60ms), screen shake (6px / 0.15s).
