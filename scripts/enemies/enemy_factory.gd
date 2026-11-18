class_name EnemyFactory
## Phase 2 enemy roster. "oni" / "kitsune" are the original Enemy.tscn types (unchanged).
const NEW_KINDS := {
	"oni_brute": "res://scripts/enemies/oni_brute.gd",
	"kitsune_archer": "res://scripts/enemies/kitsune_archer.gd",
	"shadow_assassin": "res://scripts/enemies/shadow_assassin.gd",
	"bomb_monk": "res://scripts/enemies/bomb_monk.gd",
	"crow_scout": "res://scripts/enemies/crow_scout.gd",
}
static func make(k: String) -> Node2D:
	if NEW_KINDS.has(k): return load(NEW_KINDS[k]).new()
	var e = load("res://scenes/Enemy.tscn").instantiate()
	e.is_ranged = (k == "kitsune")
	return e
