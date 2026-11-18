extends EnemyBase
## Shadow Assassin: on spotting the hero vanishes in smoke and reappears behind him, coils
## (telegraph), then dash-slashes through. Teleports again when the hero gets away.
var _tp_cd := 0.0
func _configure() -> void:
	kind = "shadow_assassin"; max_health = 3; walk_speed = 70.0; chase_speed = 130.0
	attack_range = 150.0; windup_time = 0.5; attack_time = 0.22; recover_time = 0.75; cooldown = 1.3
	strip_path = "res://assets/sprites/p2/shadow_assassin.png"; rim = Color(0.75, 0.5, 1.0); bar_y = -130.0
func _after_alert() -> void:
	_teleport_behind()
	set_state(S.WINDUP)
func _chase(dx: float, dy: float, d: float) -> void:
	_tp_cd -= d
	if absf(dx) > 260.0 and _tp_cd <= 0.0 and dy < 120.0 and _cd <= 0.0:
		_teleport_behind(); set_state(S.WINDUP); return
	super._chase(dx, dy, d)
func _teleport_behind() -> void:
	var pl := player()
	if pl == null: return
	_smoke(global_position)
	var side: int = -pl.facing if "facing" in pl else 1   # behind the hero
	var nx := clampf(pl.global_position.x + side * 110.0, 40.0, 1240.0)
	global_position = Vector2(nx, pl.global_position.y - 4)
	reset_physics_interpolation()
	direction = 1 if pl.global_position.x > nx else -1
	_smoke(global_position)
	_tp_cd = 2.5
func _smoke(p: Vector2) -> void:
	FX.sparks(get_tree().current_scene, p, Color(0.3, 0.2, 0.4), 16)
func _attack_start() -> void:
	velocity.x = 620.0 * direction
	FX.afterimage(get_tree().current_scene, spr)
func _attack_tick(_d: float) -> void:
	velocity.x = 620.0 * direction * _slow()
	if melee(70.0, 56.0, 30.0): FX.sparks(get_tree().current_scene, global_position, Color(0.8, 0.4, 1.0), 12, direction)
