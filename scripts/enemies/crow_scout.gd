extends EnemyBase
## Crow Scout: flies a patrol loop, shrieks (telegraph), dives at where the hero was, then
## climbs back to its patrol height. 1 HP.
var home_y := 0.0
var _dive := Vector2.ZERO
func _configure() -> void:
	kind = "crow_scout"; max_health = 1; walk_speed = 90.0; chase_speed = 110.0; flying = true
	sight = 380.0; sight_y = 320.0; attack_range = 300.0; windup_time = 0.5; attack_time = 0.85; recover_time = 0.9; cooldown = 1.2
	patrol_distance = 180.0; vis_feet = 20.0
	strip_path = "res://assets/sprites/p2/crow_scout.png"; rim = Color(0.9, 0.5, 0.5); bar_y = -80.0
func _hitbox() -> Vector2: return Vector2(40, 30)
func _ready() -> void:
	super._ready(); home_y = global_position.y
	collision_mask = 0          # flies through platforms
func _physics_process(delta: float) -> void:
	if state in [S.PATROL, S.CHASE, S.ALERT]:
		velocity.y = (home_y + sin(_anim_t * 3.0) * 12.0 - global_position.y) * 3.0
	super._physics_process(delta)
func _chase(dx: float, _dy: float, _d: float) -> void:
	velocity.x = direction * chase_speed * _slow() if absf(dx) > 120.0 else 0.0
func _can_attack(dx: float, _dy: float) -> bool:
	var pl := player()
	return pl != null and absf(dx) < attack_range and pl.global_position.y > global_position.y + 40.0
func _windup_tick(_d: float) -> void:
	velocity.y = -40.0
	var pl := player()
	if pl: _dive = (pl.global_position - global_position).normalized() * 400.0
func _attack_start() -> void: GameManager.play_sfx("dash")
func _attack_tick(_d: float) -> void:
	velocity = _dive * _slow()
	var pl := player()
	if pl and not _hit_done and pl.global_position.distance_to(global_position) < 40.0:
		_hit_done = true; pl.take_damage(1)
func _recover_tick(_d: float) -> void:
	velocity = Vector2(velocity.x * 0.95, (home_y - global_position.y) * 2.5)
func _animate(delta: float) -> void:
	super._animate(delta)
	if state in [S.PATROL, S.CHASE, S.ALERT, S.HURT]: spr.frame = int(_anim_t * 8.0) % 2
	elif state == S.RECOVER: spr.frame = int(_anim_t * 10.0) % 2
	anim.rotation = 0.5 if state == S.ATTACK else 0.0
