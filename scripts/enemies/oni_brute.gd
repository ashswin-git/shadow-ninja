extends EnemyBase
## Oni Brute: slow shield-bearer. Blocks slashes from the front unless winding up, swinging or
## recovering; hit him from behind, after his club smash, or with DOMAIN (3 dmg pierces).
func _configure() -> void:
	kind = "oni_brute"; max_health = 4; walk_speed = 55.0; chase_speed = 100.0
	attack_range = 100.0; windup_time = 0.65; attack_time = 0.28; recover_time = 0.85; cooldown = 0.9
	strip_path = "res://assets/sprites/p2/oni_brute.png"; rim = Color(1.0, 0.55, 0.45); bar_y = -150.0
func _hitbox() -> Vector2: return Vector2(44, 64)
func _blocks(amount: int) -> bool:
	if amount >= 3 or state in [S.WINDUP, S.ATTACK, S.RECOVER, S.DIE]: return false
	var pl := player()
	return pl != null and signf(pl.global_position.x - global_position.x) == float(direction)
func _attack_start() -> void:
	FX.ink_slash(get_tree().current_scene, global_position + Vector2(60 * direction, 10), direction, Color(0.5, 0.1, 0.05, 0.95), 70.0)
	GameManager.play_sfx("hit")
	if melee(118.0, 60.0): FX.sparks(get_tree().current_scene, global_position + Vector2(70 * direction, 0), Color(1, 0.6, 0.2), 12, direction)
	var pl := player()
	if pl and pl.has_method("trigger_shake"): pl.trigger_shake(6.0, 0.15)
