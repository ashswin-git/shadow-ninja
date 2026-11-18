# Content Packs in Aether Shinobi: Spirit Blade

All game content—including character names, dialogue, level data, palettes, fonts, and UI text—is completely swappable and decoupled from core game scripts via the `ContentPack` autoload (`scripts/ContentPack.gd`).

## Structure

Each content pack resides in `res://content/<pack_name>/`:
- `pack.json`: Metadata, title, theme configuration, color palette definitions, and font references.
- `fonts/`: OFL-licensed font files (e.g. Open Sauce Sans).
- `sprites/`: Custom character and environment sprites.
- `audio/`: Sound effects and music tracks.

## How to Add a New Content Pack

1. Create a new directory under `res://content/`, for example `res://content/cyber_shrine/`.
2. Add a `pack.json` file defining your pack metadata, title, color palette hex codes, and font paths.
3. Place your custom assets (`.png`, `.wav`, `.ttf`) inside your pack directory.
4. In `GameManager` or `ContentPack`, select the active pack by name (default is `"original"`).
5. Core gameplay and UI scripts query `ContentPack` dynamically for strings, fonts, and colors, ensuring zero hardcoding.
