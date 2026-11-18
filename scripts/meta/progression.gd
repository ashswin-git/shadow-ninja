class_name Progression
## Phase 4 meta: Skills tree, Shop, Artifacts, daily Challenge.
## None of these change the locked SPEC numbers (run/jump/dash/hearts/i-frames/slash/kunai
## speed/DOMAIN radius-damage-duration/boss HP/hitbox). Perks only add things on top.

const SKILLS := [
	# branch, tier, id, name, cost (coins), text
	{"id": "combo_ink", "branch": "BLADE", "tier": 1, "name": "Combo Ink", "cost": 120, "text": "Every 10-hit combo pays 5 coins."},
	{"id": "twin_kunai", "branch": "BLADE", "tier": 2, "name": "Twin Kunai", "cost": 260, "text": "Each throw adds a second kunai one head-height higher."},
	{"id": "moon_finisher", "branch": "BLADE", "tier": 3, "name": "Moon Finisher", "cost": 420, "text": "3rd combo hit knocks foes back hard."},
	{"id": "rite_echo", "branch": "SHADOW", "tier": 1, "name": "Rite Echo", "cost": 150, "text": "DOMAIN also wipes enemy projectiles."},
	{"id": "ghost_step", "branch": "SHADOW", "tier": 2, "name": "Ghost Step", "cost": 280, "text": "Untouchable during a dash (0.2 s)."},
	{"id": "moon_veil", "branch": "SHADOW", "tier": 3, "name": "Moon Veil", "cost": 450, "text": "Casting DOMAIN grants a ward that blocks 1 hit."},
	{"id": "coin_sense", "branch": "SPIRIT", "tier": 1, "name": "Coin Sense", "cost": 100, "text": "Coins drift to you from 90 px."},
	{"id": "iron_ward", "branch": "SPIRIT", "tier": 2, "name": "Iron Ward", "cost": 300, "text": "A ward blocks the first hit in each stage."},
	{"id": "second_breath", "branch": "SPIRIT", "tier": 3, "name": "Second Breath", "cost": 480, "text": "First KO each stage leaves you at 1 heart instead."},
]
const SHOP := [
	{"id": "tea", "kind": "consumable", "name": "Healing Tea", "cost": 60, "text": "Auto-restores 1 heart at 1 heart. One per stage."},
	{"id": "talisman", "kind": "consumable", "name": "Ward Talisman", "cost": 90, "text": "Blocks 1 hit in your next stage."},
	{"id": "crimson", "kind": "skin", "name": "Crimson Ronin", "cost": 300, "tint": Color(1.25, 0.78, 0.78), "text": "Blood-red scarf grade."},
	{"id": "jade", "kind": "skin", "name": "Jade Monk", "cost": 400, "tint": Color(0.8, 1.2, 0.95), "text": "Bamboo-green grade."},
	{"id": "moonlit", "kind": "skin", "name": "Moonlit", "cost": 500, "tint": Color(0.92, 1.0, 1.35), "text": "Silver moon grade."},
]
const ARTIFACTS := [
	{"id": "fox_bell", "name": "Fox Bell", "gems": 1, "text": "Coin pull radius 160 px."},
	{"id": "moon_mirror", "name": "Moon Mirror", "gems": 1, "text": "Foes stay slowed 3 s after DOMAIN (was 2 s)."},
	{"id": "crow_feather", "name": "Crow Feather", "gems": 1, "text": "Secret walls shimmer from afar."},
	{"id": "stone_heart", "name": "Stone Heart", "gems": 2, "text": "Ward renews at every checkpoint."},
]
const MAX_EQUIPPED := 2
const CHALLENGE_STAGES := [3, 5, 6, 7, 9, 10, 11]
const CHALLENGE_MODS := [
	{"id": "no_hit", "name": "Untouched", "text": "Finish without taking a hit."},
	{"id": "all_coins", "name": "Gold Path", "text": "Collect every coin."},
	{"id": "timed", "name": "Swift Shadow", "text": "Finish in under 4:00.", "limit": 240.0},
	{"id": "no_domain", "name": "Bare Blade", "text": "Finish without DOMAIN."},
]
const CHALLENGE_REWARD := 100
const CHALLENGE_STREAK_GEM := 3   # every 3-day streak also pays 1 gem

static func meta() -> Dictionary: return GameManager.meta
static func has_skill(id: String) -> bool: return id in meta()["skills"]
static func equipped(id: String) -> bool: return id in meta()["artifacts"]["equipped"]
static func skill(id: String) -> Dictionary:
	for s in SKILLS: if s["id"] == id: return s
	return {}

static func skill_state(id: String) -> String:
	if has_skill(id): return "owned"
	var s := skill(id)
	for p in SKILLS:
		if p["branch"] == s["branch"] and p["tier"] == s["tier"] - 1 and not has_skill(p["id"]): return "locked"
	return "buyable" if GameManager.total_coins >= int(s["cost"]) else "poor"

static func buy_skill(id: String) -> bool:
	if skill_state(id) != "buyable": return false
	GameManager.total_coins -= int(skill(id)["cost"]); meta()["skills"].append(id); GameManager.save_game(); GameManager.play_sfx("buy", 0.0); return true

static func shop_item(id: String) -> Dictionary:
	for s in SHOP: if s["id"] == id: return s
	return {}

static func buy_item(id: String) -> bool:
	var it := shop_item(id); var sh: Dictionary = meta()["shop"]
	if it.is_empty() or GameManager.total_coins < int(it["cost"]): return false
	if it["kind"] == "skin":
		if id in sh["skins"]: return false
		sh["skins"].append(id)
	else:
		if int(sh[id]) >= 9: return false
		sh[id] = int(sh[id]) + 1
	GameManager.total_coins -= int(it["cost"]); GameManager.save_game(); GameManager.play_sfx("buy", 0.0); return true

static func equip_skin(id: String) -> void:
	if id in meta()["shop"]["skins"]: meta()["shop"]["skin"] = id; GameManager.save_game()

static func skin_tint() -> Color:
	var it := shop_item(meta()["shop"]["skin"])
	return it.get("tint", Color.WHITE)

static func artifact(id: String) -> Dictionary:
	for a in ARTIFACTS: if a["id"] == id: return a
	return {}

static func unlock_artifact(id: String) -> bool:
	var a := artifact(id); var ar: Dictionary = meta()["artifacts"]
	if a.is_empty() or id in ar["owned"] or GameManager.total_gems < int(a["gems"]): return false
	GameManager.total_gems -= int(a["gems"]); ar["owned"].append(id); GameManager.save_game(); GameManager.play_sfx("buy", 0.0); return true

static func toggle_artifact(id: String) -> bool:
	var ar: Dictionary = meta()["artifacts"]
	if not id in ar["owned"]: return false
	if id in ar["equipped"]: ar["equipped"].erase(id)
	elif ar["equipped"].size() < MAX_EQUIPPED: ar["equipped"].append(id)
	else: return false
	GameManager.save_game(); return true

# ---- perk values read by Player / Level ----
static func magnet_radius() -> float:
	return 160.0 if equipped("fox_bell") else (90.0 if has_skill("coin_sense") else 0.0)
static func stage_wards() -> int:
	var w := 1 if has_skill("iron_ward") else 0
	if int(meta()["shop"]["talisman"]) > 0: w += 1
	return w

# ---- daily challenge (deterministic per calendar day) ----
static func day_key(d: Dictionary = {}) -> String:
	if d.is_empty(): d = Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]

static func daily(d: Dictionary = {}) -> Dictionary:
	var key := day_key(d)
	var h: int = absi(hash(key))
	var stage: int = CHALLENGE_STAGES[h % CHALLENGE_STAGES.size()]
	var mod: Dictionary = CHALLENGE_MODS[(h / 7) % CHALLENGE_MODS.size()]
	var c: Dictionary = meta()["challenge"]
	if c["day"] != key: c["day"] = key; c["done"] = false
	return {"day": key, "stage": stage, "mod": mod, "done": c["done"], "streak": int(c["streak"])}

## Called by Level on stage clear while a challenge run is active. Returns reward text or "".
static func finish_challenge(run: Dictionary) -> String:
	var dl := daily(); var m: String = dl["mod"]["id"]
	var ok := false
	match m:
		"no_hit": ok = int(run.get("hits", 1)) == 0
		"all_coins": ok = int(run.get("coins", 0)) >= int(run.get("total", 1))
		"timed": ok = float(run.get("time", 999.0)) <= float(dl["mod"]["limit"])
		"no_domain": ok = int(run.get("domains", 1)) == 0
	if not ok or dl["done"]: return "" if not ok else "Already cleared today."
	var c: Dictionary = meta()["challenge"]
	var y := Time.get_date_dict_from_unix_time(int(Time.get_unix_time_from_system()) - 86400)
	c["streak"] = int(c["streak"]) + 1 if c["last_done_day"] == day_key(y) else 1
	c["last_done_day"] = dl["day"]; c["done"] = true
	GameManager.total_coins += CHALLENGE_REWARD
	var txt := "+%d coins" % CHALLENGE_REWARD
	if int(c["streak"]) % CHALLENGE_STREAK_GEM == 0: GameManager.total_gems += 1; txt += "  +1 gem (streak)"
	GameManager.save_game()
	return txt
