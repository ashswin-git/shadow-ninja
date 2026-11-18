# Shadow Ninja — Google Play Store Listing & Asset Specification

## 1. App Metadata
- **App Name**: Shadow Ninja
- **Package Name**: `com.ashswin.shadowninja`
- **Current Version**: `1.1.0` (Version Code: `2`)
- **Target SDK**: Android 34 (API level 34)
- **Min SDK**: Android 5.0 (API level 21), read from the exported APK with aapt
- **Supported Architectures**: `arm64-v8a` (slim optimized release build)

---

## 2. Store Assets Checklist
Play needs at least 2 phone screenshots (16:9, 320-3840 px sides); the brief asks for 8. Current captures are 1280 x 720 and need recapture at 1920 x 1080 without debug text (ART_NEEDS item 35).
- `ui-mockups/release_*.png` (Phase 6 captures) are also candidates.
- **App Icon (512x512 PNG)**: `assets/ui/icon_512.png` (Included in project repo).
- **Feature Graphic (1024x500 PNG/JPG, no alpha)**: NOT YET MADE. Logged as `docs/ART_NEEDS.md` item 34 (original key art needed).
- **Phone Screenshots (8 Candidate Files in `ui-mockups/`)**:
  1. `ui-mockups/phase4_skills.png` — Skills & Progression Tree
  2. `ui-mockups/phase4_shop.png` — Merchant Shop & Healing Teas
  3. `ui-mockups/phase4_artifact.png` — Ancient Artifacts Equipping
  4. `ui-mockups/phase4_hud_combo.png` — In-Game HUD & Combo Counter
  5. `ui-mockups/phase5_tower_top.png` — L3 Gion Rooftops, tower climb
  6. `ui-mockups/phase5_backtrack_switch.png` — L10 Frozen Pagoda, backtrack switch
  7. `ui-mockups/phase5_canal_run.png` — L9 Canal, boat run
  8. `ui-mockups/phase4_settings.png` — Audio, Touch Controls & Accessibility Settings

---

## 3. Descriptions

### Short Description (≤ 80 characters)
> Fast-paced 2D action platformer set in feudal Japan with ink-wash visuals.

### Full Description (≤ 4000 characters)
Step into the shadows as an elite shinobi in **Shadow Ninja**, a precision 2D action platformer featuring original hand-painted Kyoto art, fluid combat, and traditional Japanese atmosphere.

**Key Features:**
- **Dynamic Combat & Movement:** Master a 3-hit slash combo, double jump, wall slide, dash, and shuriken throwing with fully remappable touch controls.
- **Epic Boss Battles:** Test your skills against formidable bosses (Rin, Gorrah, and Vey) across multi-phase encounters in unique arenas.
- **Immersive Acts & Stages:** Traverse 12 meticulously designed levels across snow-covered villages, Gion rooftops, bamboo forests, waterfall caves, burning shrines, canal boats, and frozen pagodas.
- **Progression & Upgrades:** Unlock powerful skills in the lacquer skill tree, equip mystical artifacts (Fox Bell, Crow Feather), purchase healing teas, and collect hidden coins and gems.
- **Zero Ads & Offline Play:** Enjoy an uninterrupted gaming experience with no mandatory online connection, zero banner ads, and local-only save data.

---

## 4. Content Rating & IARC Questionnaire Notes
- **Category**: Action / Arcade
- **Content Rating (expected, to be confirmed by the IARC questionnaire)**: around PEGI 7 / ESRB Everyone 10+ for mild fantasy violence
- **IARC Questionnaire Answers**:
  - Does the app contain violence? Yes (Cartoon / fantasy sword combat against fictional enemies and demons).
  - Blood / Gore / Fear? No blood, gore, or frightening imagery.
  - User-generated content / Interactivity? None (Single-player offline experience).
  - Ads / In-App Purchases (IAP)? None (Completely ad-free, no real-money transactions).

---

## 5. Data Safety & Privacy Notes
- **Data Collection**: None. The app does not collect, store, or transmit any personal or device data.
- **Permissions**: The Android manifest does not request `INTERNET` permission. All game state, progression, and settings are saved locally on device (`user://shadow_ninja_save.json` and `user://shadow_ninja_settings.cfg`).
- **Data Sharing**: No data is shared with third parties.
