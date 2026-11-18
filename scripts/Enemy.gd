extends CharacterBody2D

@export var is_ranged: bool = false
@export var patrol_distance: float = 150.0
var start_x: float = 0.0
var direction: int = 1
var speed: float = 100.0
var health: int = 2
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var shoot_timer: float = 0.0

@onready var shuriken_scene = preload("res://scenes/Shuriken.tscn")
@onready var spr: Sprite2D = $Animator/Body/Sprite2D
@onready var anim: CreatureAnimator = $Animator
const HIT_FLASH_TIME := 0.06
const WINDUP_AT := 1.55           # ranged: shoot_timer value where the throw windup starts
# oni melee attack (character pass): telegraph -> strike -> recover. Damage stays 1 (SPEC 4: contact = 1).
const ONI_REACH := 92.0          # px ahead of the oni that starts an attack
const ONI_REACH_Y := 60.0
const ONI_HIT_REACH := 112.0      # px ahead that the naginata strike connects (blade + lunge)
const ONI_HIT_Y := 50.0
const ONI_WINDUP := 0.5           # telegraph hold (s)
const ONI_COOLDOWN := 1.3
const ONI_DAMAGE := 1
const ONI_SEQ := [[4, 0.5], [5, 0.1], [6, 0.16], [3, 0.26]]   # windup, strike, strike low, thrust/recover
const KIT_THROW_HOLD := 0.42
const KIT_FACE_RANGE := 640.0     # kitsune turns to face the hero inside this range
var _seq: Array = []
var _seq_t := 0.0
var _oni_cd := 0.0
var _struck := false

func _ready() -> void:
	add_to_group("Enemies")
	_setup_visual()
	start_x = global_position.x

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if not is_ranged:
		_oni_cd = maxf(_oni_cd - delta, 0.0)
		if _seq.is_empty():
			velocity.x = direction * speed
			if abs(global_position.x - start_x) > patrol_distance:
				direction *= -1
			_try_oni_attack()
		else:
			velocity.x = 0   # plants his feet for the swing
	else:
		velocity.x = 0
		var pl = _player()
		if pl and absf(pl.global_position.x - global_position.x) < KIT_FACE_RANGE and shoot_timer < WINDUP_AT:
			direction = 1 if pl.global_position.x > global_position.x else -1
		shoot_timer += delta
		if shoot_timer >= 2.0:
			shoot_timer = 0.0
			shoot()

	move_and_slide()

	if is_on_wall() and _seq.is_empty() and not is_ranged:
		direction *= -1
	_animate(delta)

func _player() -> Node2D:
	var sc = get_tree().current_scene
	return sc.get_node_or_null("Player") if sc else null

func _try_oni_attack() -> void:
	if _oni_cd > 0.0: return
	var pl = _player()
	if pl == null: return
	var dy = absf(pl.global_position.y - global_position.y)
	var dx = (pl.global_position.x - global_position.x) * direction
	if dy < ONI_REACH_Y and dx > 0.0 and dx < ONI_REACH:
		_seq = ONI_SEQ.duplicate(true); _seq_t = 0.0; _struck = false
		_oni_cd = ONI_COOLDOWN
		anim.play_windup(ONI_WINDUP)
		_telegraph_glint()

func _telegraph_glint() -> void:
	# small red "!" + blade glint so the strike is read before it lands
	var warn = Label.new(); warn.text = "!"; warn.position = Vector2(-8, -96)
	warn.add_theme_font_size_override("font_size", 34); warn.add_theme_color_override("font_color", Color(1, 0.25, 0.2))
	warn.add_theme_color_override("font_outline_color", Color(0, 0, 0)); warn.add_theme_constant_override("outline_size", 8)
	add_child(warn)
	var tw = warn.create_tween(); tw.tween_property(warn, "position:y", -104.0, ONI_WINDUP); tw.tween_callback(warn.queue_free)
	FX.flash(spr, 0.12)

func _oni_strike() -> void:
	anim.play_attack(0.28, 22.0)
	GameManager.play_sfx("dash")
	var c = global_position + Vector2(56 * direction, 6)
	FX.ink_slash(get_tree().current_scene, c, direction)
	var pl = _player()
	if pl == null: return
	var dy = absf(pl.global_position.y - global_position.y)
	var dx = (pl.global_position.x - global_position.x) * direction
	if dy < ONI_HIT_Y and dx > -10.0 and dx < ONI_HIT_REACH and pl.has_method("take_damage"):
		pl.take_damage(ONI_DAMAGE)

# --- painted visual (original art): oni ashigaru (patrol) / kitsune thrower (ranged) ---
const TEX_ONI = preload("res://assets/sprites/enemy_oni.png")
const TEX_KITSUNE = preload("res://assets/sprites/enemy_kitsune.png")
const VIS_SCALE := 1.0 / 1.5
var _anim_t := 0.0
var _attack_pose := 0.0
func _setup_visual() -> void:
	spr.texture = TEX_KITSUNE if is_ranged else TEX_ONI
	spr.hframes = 7   # oni: walk 0-3 + attack 4-6 | kitsune: idle 0-1, raise 2, point 3, windup 4, release 5, follow 6
	spr.frame = 0
	spr.scale = Vector2(VIS_SCALE, VIS_SCALE)
	# feet on the collision bottom (y = 28); frames carry 3 px of padding under the feet
	spr.offset = Vector2(0, 28.0 / VIS_SCALE - (spr.texture.get_height() / 2.0 - 3.0))
	FX.painted(spr, Color(1.0, 0.62, 0.5) if not is_ranged else Color(0.6, 0.95, 1.0), 0.5, Color(1.18, 1.14, 1.14), 0.02)
	_anim_t = randf() * 2.0

var _winding := false
var _thrusting := false
func _animate(delta: float) -> void:
	# frame choice stays here; flip, bob, squash and lean belong to the CreatureAnimator
	_anim_t += delta
	anim.set_facing(direction)
	anim.update_motion(not is_ranged and _seq.is_empty(), delta)
	if not _seq.is_empty():
		_seq_t += delta
		while not _seq.is_empty() and _seq_t >= _seq[0][1]:
			_seq_t -= _seq[0][1]; _seq.pop_front()
			if not _seq.is_empty() and _seq[0][0] == 5 and not _struck:
				_struck = true; _oni_strike()
		if not _seq.is_empty():
			spr.frame = _seq[0][0]
			return
	if _attack_pose > 0.0:
		_attack_pose -= delta
		if is_ranged:
			var el := KIT_THROW_HOLD - _attack_pose
			spr.frame = 5 if el < 0.14 else (6 if el < 0.34 else 3)
		else:
			spr.frame = 3 if _attack_pose < 0.18 else 2
		return
	if is_ranged:
		# idle breathing + a little hop-step shuffle between throws
		spr.frame = 1 if fmod(_anim_t, 1.6) > 1.2 else 0
		if shoot_timer > WINDUP_AT:
			spr.frame = 2 if shoot_timer < WINDUP_AT + 0.12 else 4   # raise, then cock the arm back
			if not _winding: _winding = true; anim.play_windup(2.0 - WINDUP_AT)
		else:
			_winding = false
	else:
		spr.frame = 1 + (int(_anim_t * 6.0) % 2)

func shoot() -> void:
	_attack_pose = KIT_THROW_HOLD
	anim.play_attack(0.25, 12.0)
	var s = shuriken_scene.instantiate()
	s.global_position = global_position + Vector2(20 * direction, -10)
	s.direction = direction
	s.is_enemy_projectile = true
	get_tree().current_scene.add_child(s)

var _bar: Node2D
const MAX_HEALTH := 2
func take_damage(amount: int) -> void:
	health -= amount
	FX.flash(spr, HIT_FLASH_TIME)
	anim.play_hurt()   # recoil + squash (replaces the old position:x knockback tween)
	# Phase 2 feedback: damage number + hit bar; coin / orb drop on death
	CombatUI.damage_number(self, global_position, amount)
	if _bar == null: _bar = CombatUI.make_bar(self, 48.0, -110.0)
	CombatUI.set_bar(_bar, float(health) / float(MAX_HEALTH))
	if health <= 0:
		FX.death_burst(get_tree().current_scene, global_position)
		CombatUI.drop_loot(self, global_position + Vector2(0, 8))
		queue_free()
