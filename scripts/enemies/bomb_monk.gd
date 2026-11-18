extends EnemyBase
## Bomb Monk: holds ~260 px off, lights a fuse (telegraph), lobs a bomb that lands, shows a
## blast ring for its fuse time, then explodes (radius 70).
func _configure() -> void:
	kind = "bomb_monk"; max_health = 3; walk_speed = 40.0; chase_speed = 60.0
	sight = 460.0; attack_range = 420.0; windup_time = 0.6; attack_time = 0.25; recover_time = 0.7; cooldown = 1.6
	strip_path = "res://assets/sprites/p2/bomb_monk.png"; rim = Color(1.0, 0.75, 0.45); bar_y = -130.0
func _chase(dx: float, _dy: float, _d: float) -> void:
	var ad := absf(dx)
	velocity.x = (-direction if ad < 180.0 else (direction if ad > 340.0 else 0)) * chase_speed * _slow()
func _can_attack(dx: float, dy: float) -> bool: return absf(dx) < attack_range and dy < 160.0
func _attack_start() -> void:
	var pl := player()
	if pl == null: return
	var t := 0.85; var g := 900.0
	var from := global_position + Vector2(20 * direction, -40)
	var to := pl.global_position + Vector2(0, 24)
	var v := Vector2((to.x - from.x) / t, (to.y - from.y - 0.5 * g * t * t) / t)
	var b := EnemyProjectile.spawn(get_tree().current_scene, "bomb", from, v, g)
	b.floor_y = to.y; b.fuse = 0.7; b.life = 3.5
