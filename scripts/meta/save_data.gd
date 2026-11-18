class_name SaveData
## Versioned save for user://shadow_ninja_save.json (Phase 4).
## v1 (unversioned) = {unlocked_level, level_stars, total_coins, total_gems, music_on}.
## v2 keeps every v1 key at the top level unchanged (old builds can still read it) and adds
## "version" + "meta" (skills, shop, artifacts, challenge, stats, tutorial). Unknown keys are kept.

const CURRENT_VERSION := 2
const BACKUP_SUFFIX := ".v%d.bak"

static func meta_defaults() -> Dictionary:
	return {
		"skills": [],
		"shop": {"tea": 0, "talisman": 0, "skins": ["ashen"], "skin": "ashen"},
		"artifacts": {"owned": [], "equipped": []},
		"challenge": {"day": "", "done": false, "streak": 0, "last_done_day": "", "best_time": {}},
		"stats": {"deaths": 0, "kills": 0, "best_combo": 0},
		"tutorial_done": false,
	}

static func defaults() -> Dictionary:
	return {"version": CURRENT_VERSION, "unlocked_level": 1, "level_stars": {}, "total_coins": 0,
		"total_gems": 0, "music_on": true, "meta": meta_defaults()}

static func version_of(data: Dictionary) -> int:
	return int(data.get("version", 1))

## Returns a migrated deep copy. Never drops keys; fills missing ones with defaults.
static func migrate(src: Dictionary) -> Dictionary:
	var d: Dictionary = src.duplicate(true)
	var v := version_of(d)
	if v < 2:
		# v1 -> v2: normalise numeric types (JSON gives floats), add meta block
		d["unlocked_level"] = int(d.get("unlocked_level", 1))
		d["total_coins"] = int(d.get("total_coins", 0))
		d["total_gems"] = int(d.get("total_gems", 0))
		d["music_on"] = bool(d.get("music_on", true))
		var stars := {}
		var ls = d.get("level_stars", {})
		if ls is Dictionary:
			for k in ls: stars[str(k)] = int(ls[k])
		d["level_stars"] = stars
		d["meta"] = meta_defaults()
		v = 2
	# fill any missing meta keys (forward-compatible partial saves)
	var md: Dictionary = meta_defaults()
	if not (d.get("meta") is Dictionary): d["meta"] = md
	for k in md:
		if not d["meta"].has(k): d["meta"][k] = md[k]
		elif md[k] is Dictionary and d["meta"][k] is Dictionary:
			for k2 in md[k]:
				if not d["meta"][k].has(k2): d["meta"][k][k2] = md[k][k2]
	d["version"] = maxi(v, CURRENT_VERSION)
	return d

## Reads + migrates. Writes a one-time backup of the pre-migration file next to it.
static func load_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return defaults()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null: return defaults()
	var text := f.get_as_text(); f.close()
	var json := JSON.new()
	if json.parse(text) != OK or not (json.get_data() is Dictionary):
		# corrupt file: keep it aside, start fresh rather than crash
		var bad := FileAccess.open(path + ".corrupt", FileAccess.WRITE)
		if bad: bad.store_string(text)
		return defaults()
	var data: Dictionary = json.get_data()
	var v := version_of(data)
	if v < CURRENT_VERSION:
		var bp := path + BACKUP_SUFFIX % v
		if not FileAccess.file_exists(bp):
			var b := FileAccess.open(bp, FileAccess.WRITE)
			if b: b.store_string(text)
	return migrate(data)

static func save_file(path: String, data: Dictionary) -> bool:
	data["version"] = CURRENT_VERSION
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null: return false
	f.store_string(JSON.stringify(data)); f.close()
	return DirAccess.rename_absolute(tmp, path) == OK
