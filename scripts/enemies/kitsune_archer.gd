extends EnemyBase
## Kitsune Archer: keeps 220-460 px away, draws (aim line telegraph), looses one arrow.
var _aim: Line2D
func _configure() -> void:
	kind = "kitsune_archer"; max_health = 2; walk_speed = 45.0; chase_speed = 90.0
	sight = 560.0; attack_range = 520.0; windup_time = 0.75; attack_time = 0.2; recover_time = 0.55; cooldown = 1.4
	strip_path = "res://assets/sprites/p2/kitsune_archer.png"; rim = Color(0.6, 0.9, 1.0); bar_y = -130.0
func _chase(dx: float, _dy: float, _d: float) -> void:
	var ad := absf(dx)
	if ad < 220.0: velocity.x = -direction * chase_speed * _slow()     # back off
	elif ad > 460.0: velocity.x = direction * chase_speed * _slow()
	else: velocity.x = 0.0
func _can_attack(dx: float, dy: float) -> bool: return absf(dx) < attack_range and dy < 90.0
func _telegraph() -> void:
	CombatUI.telegraph(self, windup_time, bar_y - 10)
	_aim = Line2D.new(); _aim.width = 2; _aim.default_color = Color(1, 0.3, 0.25, 0.0)
	_aim.add_point(Vector2(30, -14)); _aim.add_point(Vector2(560, -14)); anim.add_child(_aim)
	var tw := _aim.create_tween(); tw.tween_property(_aim, "default_color:a", 0.75, windup_time)
func _attack_start() -> void:
	if is_instance_valid(_aim): _aim.queue_free()
	GameManager.play_sfx("shuriken")
	EnemyProjectile.spawn(get_tree().current_scene, "arrow", global_position + Vector2(34 * direction, -14), Vector2(520 * direction, 0))
func _exit_tree() -> void:
	if is_instance_valid(_aim): _aim.queue_free()
