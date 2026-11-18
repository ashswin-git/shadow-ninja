class_name EnemyBase
extends CharacterBody2D
## Phase 2 base enemy: PATROL -> ALERT -> CHASE -> WINDUP (telegraph) -> ATTACK -> RECOVER,
## plus HURT and DIE. Art is a 4-frame painted strip (0 idle, 1 move, 2 windup, 3 attack);
## CreatureAnimator adds bob / windup lean / attack lunge / hurt squash. Subclasses set stats
## in _configure() and override the hooks below. All enemy damage to the hero is 1 (SPEC 4).

signal state_changed(new_state: int, old_state: int)
enum S { PATROL, ALERT, CHASE, WINDUP, ATTACK, RECOVER, HURT, DIE }

# --- stats (subclasses override in _configure) ---
var kind := "enemy"
var max_health := 2
var health := 2
var walk_speed := 60.0
var chase_speed := 110.0
var sight := 340.0
var sight_y := 140.0
var attack_range := 90.0
var windup_time := 0.5
var attack_time := 0.25
var recover_time := 0.6
var cooldown := 1.0
var alert_time := 0.35
var flying := false
var patrol_distance := 140.0
var strip_path := ""
var vis_feet := 28.0              # collision bottom (px below origin)
var rim := Color(1.0, 0.6, 0.5)
var bar_y := -110.0

var state: int = S.PATROL
var direction := 1
var start_x := 0.0
var speed := 0.0                  # DOMAIN slow multiplies this (Player.cast_domain)
var _st := 0.0
var _cd := 0.0
var _anim_t := 0.0
var _hit_done := false
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var anim: CreatureAnimator
var spr: Sprite2D
var _bar: Node2D
const VIS_SCALE := 1.0 / 1.5

func _init() -> void:
	collision_layer = 4; collision_mask = 1
	_configure()
	health = max_health
	speed = walk_speed
	anim = CreatureAnimator.new(); anim.name = "Animator"; anim.feet_y = vis_feet
	var body := Node2D.new(); body.name = "Body"; body.position = Vector2(0, vis_feet); anim.add_child(body)
	spr = Sprite2D.new(); spr.name = "Sprite2D"; spr.position = Vector2(0, -vis_feet); body.add_child(spr)
	add_child(anim)
	var cs := CollisionShape2D.new(); var sh := RectangleShape2D.new(); sh.size = _hitbox(); cs.shape = sh
	cs.position = Vector2(0, vis_feet - sh.size.y / 2.0); add_child(cs)

func _configure() -> void: pass
func _hitbox() -> Vector2: return Vector2(32, 48)

func _ready() -> void:
	add_to_group("Enemies")
	start_x = global_position.x
	spr.texture = load(strip_path)
	spr.hframes = 4
	spr.scale = Vector2(VIS_SCALE, VIS_SCALE)
	spr.offset = Vector2(0, vis_feet / VIS_SCALE - (spr.texture.get_height() / 2.0 - 3.0))
	FX.painted(spr, rim, 0.45, Color(1.12, 1.1, 1.1), 0.02)
	_bar = CombatUI.make_bar(self, 54.0, bar_y)
	_anim_t = randf() * 2.0

func player() -> Node2D:
	var sc = get_tree().current_scene
	return sc.get_node_or_null("Player") if sc else null

func set_state(s: int) -> void:
	if s == state: return
	var old := state
	state = s; _st = 0.0
	state_changed.emit(s, old)
	_enter(s)

func _enter(s: int) -> void:
	match s:
		S.ALERT: CombatUI.telegraph(self, alert_time, bar_y - 10, 0.0, Color(1, 0.85, 0.3))
		S.WINDUP:
			_hit_done = false
			anim.play_windup(windup_time)
			FX.flash(spr, 0.12)
			_telegraph()
		S.ATTACK: anim.play_attack(attack_time, 14.0); _attack_start()
		S.RECOVER: _cd = cooldown
		S.HURT: anim.play_hurt()

func _physics_process(delta: float) -> void:
	_st += delta; _cd -= delta; _anim_t += delta
	if not flying and not is_on_floor(): velocity.y += gravity * delta
	var pl := player()
	var dx := (pl.global_position.x - global_position.x) if pl else 9999.0
	var dy := absf(pl.global_position.y - global_position.y) if pl else 9999.0
	match state:
		S.PATROL:
			velocity.x = direction * walk_speed * _slow()
			if absf(global_position.x - start_x) > patrol_distance: direction = -1 if global_position.x > start_x else 1
			if absf(dx) < sight and dy < sight_y: set_state(S.ALERT)
		S.ALERT:
			velocity.x = 0.0; _face(dx)
			if _st >= alert_time: _after_alert()
		S.CHASE:
			_face(dx)
			_chase(dx, dy, delta)
			if _cd <= 0.0 and _can_attack(dx, dy): set_state(S.WINDUP)
			elif absf(dx) > sight * 1.7 or dy > sight_y * 2.0: set_state(S.PATROL)
		S.WINDUP:
			velocity.x = 0.0
			_windup_tick(delta)
			if _st >= windup_time: set_state(S.ATTACK)
		S.ATTACK:
			_attack_tick(delta)
			if _st >= attack_time: set_state(S.RECOVER)
		S.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, 1400.0 * delta)
			_recover_tick(delta)
			if _st >= recover_time: set_state(S.CHASE)
		S.HURT:
			velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta)
			if _st >= 0.22: set_state(S.CHASE)
		S.DIE:
			velocity = Vector2.ZERO
			_die_tick()
			return
	move_and_slide()
	if is_on_wall() and state == S.PATROL: direction *= -1
	_animate(delta)

func _slow() -> float:
	return clampf(speed / walk_speed, 0.1, 1.0) if walk_speed > 0.0 else 1.0

func _face(dx: float) -> void:
	if absf(dx) > 4.0: direction = 1 if dx > 0 else -1

# ---------------- hooks ----------------
func _after_alert() -> void: set_state(S.CHASE)
func _chase(dx: float, _dy: float, _delta: float) -> void:
	velocity.x = (direction * chase_speed * _slow()) if absf(dx) > attack_range * 0.7 else 0.0
func _can_attack(dx: float, dy: float) -> bool: return absf(dx) < attack_range and dy < 60.0
func _telegraph() -> void: CombatUI.telegraph(self, windup_time, bar_y - 10)
func _windup_tick(_d: float) -> void: pass
func _attack_start() -> void: pass
func _attack_tick(_d: float) -> void: pass
func _recover_tick(_d: float) -> void: pass
func _blocks(_amount: int) -> bool: return false

## melee hit box in front: returns true if it connected
func melee(reach: float, reach_y := 56.0, back := 10.0) -> bool:
	var pl := player()
	if pl == null or _hit_done: return false
	var dx := (pl.global_position.x - global_position.x) * direction
	if absf(pl.global_position.y - global_position.y) < reach_y and dx > -back and dx < reach and pl.has_method("take_damage"):
		_hit_done = true
		pl.take_damage(1)
		return true
	return false

# ---------------- visuals ----------------
func _animate(_delta: float) -> void:
	anim.set_facing(direction)
	var moving := absf(velocity.x) > 5.0 or flying
	anim.update_motion(moving and state in [S.PATROL, S.CHASE], _delta)
	match state:
		S.WINDUP: spr.frame = 2
		S.ATTACK: spr.frame = 3
		S.RECOVER: spr.frame = 3 if _st < recover_time * 0.4 else 0
		_: spr.frame = (1 if int(_anim_t * 5.0) % 2 == 0 else 0) if moving else 0

# ---------------- damage ----------------
func take_damage(amount: int) -> void:
	if state == S.DIE: return
	if _blocks(amount):
		CombatUI.damage_number(self, global_position, 0, Color(0.7, 0.85, 1.0), "BLOCK")
		FX.sparks(get_tree().current_scene, global_position + Vector2(direction * 24, -10), Color(1, 0.9, 0.6), 10, direction)
		anim.play_hurt()
		return
	health -= amount
	CombatUI.damage_number(self, global_position, amount)
	CombatUI.set_bar(_bar, float(health) / float(max_health))
	FX.flash(spr, 0.06)
	if health <= 0:
		set_state(S.DIE)
		return
	var pl := player()
	if pl: velocity.x = -signf(pl.global_position.x - global_position.x) * 160.0
	# an attack in progress is not interrupted (super armor during ATTACK); otherwise flinch
	if state != S.ATTACK: set_state(S.HURT)
	else: anim.play_hurt()

func _die_tick() -> void:
	if not has_meta("dying"):
		set_meta("dying", true)
		collision_layer = 0
		remove_from_group("Enemies")
		if _bar: _bar.visible = false
		FX.death_burst(get_tree().current_scene, global_position)
		CombatUI.drop_loot(self, global_position + Vector2(0, vis_feet - 20))
		var tw := create_tween().set_parallel(true)
		tw.tween_property(anim, "rotation", -1.2 * direction, 0.45)
		tw.tween_property(self, "modulate:a", 0.0, 0.5)
		tw.chain().tween_callback(queue_free)
