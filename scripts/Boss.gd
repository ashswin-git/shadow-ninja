extends CharacterBody2D

@export var boss_id: int = 1
var health: int = 20
var max_health: int = 20
var speed: float = 120.0
var direction: int = 1
var attack_timer: float = 0.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var shuriken_scene = preload("res://scenes/Shuriken.tscn")
@onready var spr: Sprite2D = $Animator/Body/Sprite2D
@onready var anim: CreatureAnimator = $Animator
const HIT_FLASH_TIME := 0.06
# multi-frame sword moves (polish pass). Strip: 0 idle, 1 walk | 2 heavy windup, 3 impact,
# 4 follow-through | 5 iai stance, 6 dash draw-cut, 7 rising crescent.
# Timings are visual only; attack period, speed and projectiles are unchanged.
const CUT_SEQ := [[3, 0.18], [4, 0.34], [2, 0.08]]                 # phase 1: heavy overhead cut (windup held by the telegraph)
const CUT2_SEQ := [[6, 0.26], [7, 0.3], [4, 0.22]]                 # phase 2: iai dash draw-cut -> rising crescent
const TELE_POSE := 2
const TELE_POSE_P2 := 5
const CUT_LUNGE_PX := 34.0
const ARC_RADIUS := 110.0
var _seq: Array = []
var _seq_t := 0.0

signal boss_defeated

func _ready() -> void:
	add_to_group("Bosses")
	if boss_id == 1:
		health = 15
	elif boss_id == 2:
		health = 25
	elif boss_id == 3:
		health = 40
	max_health = health
	_setup_visual()
	GameManager.play_sfx("boss_roar")
	# Phase 2: 2.4 s intro (name card, boss holds and taunts; cannot be hurt or attack)
	_intro_t = INTRO_TIME
	var info: Array = BOSS_INFO[boss_id - 1]
	CombatUI.boss_intro.call_deferred(get_tree().current_scene, info[0], info[1], info[2], INTRO_TIME)
	if boss_id == 3: _home_y = global_position.y - 70.0

# ---------------- Phase 2: intro, 3 patterns x 2 phases, death sequence ----------------
const INTRO_TIME := 2.4
const BOSS_INFO := [
	["RIN THE PALE BLADE", "Swordmaster of the Moon Court", Color(0.7, 0.85, 1.0)],
	["GORRAH THE STONE ONI", "The mountain that walks", Color(1.0, 0.55, 0.2)],
	["SMOKE LORD VEY", "He who drifts between lanterns", Color(0.75, 0.45, 1.0)]]
const PHASE2_TOAST := ["PHASE 2 - CRIMSON FURY", "PHASE 2 - MOLTEN CORE", "PHASE 2 - CHOKING DARK"]
const CONTACT_R := 70.0
var _intro_t := 0.0
var _pattern := 0
var _rush_t := 0.0
var _rush_v := 0.0
var _rush_hit := false
var _stun_t := 0.0
var _home_y := 0.0
var dead := false
var _summoned := false

func _player() -> Node2D:
	var sc = get_tree().current_scene
	return sc.get_node_or_null("Player") if sc else null

func _pdx() -> float:
	var pl := _player()
	return (pl.global_position.x - global_position.x) if pl else 0.0

func _floor_y() -> float:
	var pl := _player()
	return (pl.global_position.y + 24.0) if pl and pl.is_on_floor() else 660.0

func _physics_process(delta: float) -> void:
	if dead:
		return
	if boss_id == 3:
		velocity.y = (_home_y + sin(_anim_t * 1.6) * 16.0 - global_position.y) * 3.0
	elif not is_on_floor():
		velocity.y += gravity * delta
	if _intro_t > 0.0:
		_intro_t -= delta
		velocity.x = 0.0
		var dx := _pdx()
		if absf(dx) > 4.0: direction = 1 if dx > 0 else -1
		move_and_slide(); _animate(delta)
		return
	if _stun_t > 0.0:
		_stun_t -= delta; velocity.x = 0.0
		move_and_slide(); _animate(delta)
		return
	if _rush_t > 0.0:
		_rush_t -= delta
		velocity.x = _rush_v
		var pl := _player()
		if pl and not _rush_hit and pl.global_position.distance_to(global_position) < CONTACT_R:
			_rush_hit = true; pl.take_damage(1)
		move_and_slide()
		if is_on_wall():
			_rush_t = 0.0
			if boss_id == 2:   # Gorrah slams into the wall: stunned, open to hits
				_stun_t = 0.9; GameManager.play_sfx("boss_roar")
				if pl and pl.has_method("trigger_shake"): pl.trigger_shake(10.0, 0.3)
				FX.toast(get_tree().current_scene, "STUNNED", Color(1, 0.8, 0.4))
		_animate(delta)
		return
	velocity.x = direction * speed * (0.6 if boss_id == 2 else 1.0)
	move_and_slide()

	if is_on_wall():
		direction *= -1
	_animate(delta)

	attack_timer += delta
	var period = 1.1 if phase2 else 1.8
	if attack_timer >= period - 0.6 and not telegraphing:
		_telegraph()
	if attack_timer >= period:
		attack_timer = 0.0; telegraphing = false
		special_attack()

var phase2 := false
var telegraphing := false
func _telegraph() -> void:
	telegraphing = true
	var warn = Label.new(); warn.text = "!"; warn.position = Vector2(-10, -130)
	warn.add_theme_font_size_override("font_size", 56); warn.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	warn.add_theme_color_override("font_outline_color", Color(0, 0, 0)); warn.add_theme_constant_override("outline_size", 10)
	add_child(warn)
	var ring = Line2D.new(); ring.width = 4; ring.default_color = Color(1, 0.2, 0.2, 0.8)
	for i in range(33): ring.add_point(Vector2(cos(i * TAU / 32), sin(i * TAU / 32)) * 90)
	ring.position = Vector2(0, -30); add_child(ring)
	FX.flash(spr, 0.3)
	_pose = (TELE_POSE_P2 if phase2 else TELE_POSE) if boss_id == 1 else 1; _pose_t = 0.6
	anim.play_windup(0.6)
	var tr = ring.create_tween(); tr.tween_property(ring, "scale", Vector2(0.3, 0.3), 0.6); tr.tween_callback(ring.queue_free); tr.tween_callback(warn.queue_free)
	_pattern_tell()

func _pattern_tell() -> void:
	## extra tell for the coming pattern (0.6 s ahead)
	var dx := _pdx()
	if absf(dx) > 4.0: direction = 1 if dx > 0 else -1
	var rush := (boss_id == 1 and _pattern == 1) or (boss_id == 2 and _pattern == 2)
	if rush:
		var ln := Line2D.new(); ln.width = 6; ln.default_color = Color(1, 0.2, 0.2, 0.0)
		ln.add_point(Vector2(0, 50)); ln.add_point(Vector2(direction * 1300, 50)); add_child(ln)
		var t := ln.create_tween(); t.tween_property(ln, "default_color:a", 0.7, 0.5); t.tween_callback(ln.queue_free)
	if boss_id == 3 and _pattern == 2:
		var pl := _player()
		if pl:
			var n := 5 if phase2 else 3
			for i in range(n):
				var x := pl.global_position.x + (i - (n - 1) / 2.0) * 130.0
				var p := Vector2(clampf(x, 40, 1240), _floor_y())
				CombatUI.ground_ring(self, p, 46.0, 0.85, Color(0.7, 0.35, 1.0))
				get_tree().create_timer(0.85).timeout.connect(_pillar.bind(p))

# --- painted visual (original art): Rin the Pale Blade ---
const TEX_RIN = preload("res://assets/sprites/boss_rin.png")
const VIS_SCALE := 1.0 / 1.5
var _anim_t := 0.0
var _pose := -1
var _pose_t := 0.0
var _moon_glow: Sprite2D
const TEX_GORRAH = preload("res://assets/sprites/p2/boss_gorrah.png")
const TEX_VEY = preload("res://assets/sprites/p2/boss_vey.png")
func _setup_visual() -> void:
	if boss_id != 1:
		spr.texture = TEX_GORRAH if boss_id == 2 else TEX_VEY
		spr.hframes = 4
		spr.scale = Vector2(VIS_SCALE, VIS_SCALE)
		spr.offset = Vector2(0, 60.0 / VIS_SCALE - (spr.texture.get_height() / 2.0 - 3.0))
		var rimc := Color(1.0, 0.55, 0.25) if boss_id == 2 else Color(0.75, 0.5, 1.0)
		FX.painted(spr, rimc, 0.35, Color(1.05, 1.0, 1.0))
		_moon_glow = Sprite2D.new(); _moon_glow.texture = load("res://assets/sprites/glow.png")
		_moon_glow.modulate = Color(rimc, 0.4); _moon_glow.scale = Vector2(2.6, 3.0); _moon_glow.position = Vector2(0, -30)
		_moon_glow.z_index = -1; add_child(_moon_glow)
		return
	spr.texture = TEX_RIN
	spr.hframes = 8
	spr.scale = Vector2(VIS_SCALE, VIS_SCALE)
	# feet on the collision bottom (y = 60)
	spr.offset = Vector2(0, 60.0 / VIS_SCALE - (spr.texture.get_height() / 2.0 - 3.0))
	FX.painted(spr, Color(0.7, 0.85, 1.0), 0.4, Color(1.0, 0.97, 1.0))
	# cold moonlight glow behind the swordmaster
	_moon_glow = Sprite2D.new(); _moon_glow.texture = load("res://assets/sprites/glow.png")
	_moon_glow.modulate = Color(0.55, 0.75, 1.0, 0.45); _moon_glow.scale = Vector2(2.2, 2.6); _moon_glow.position = Vector2(0, -10)
	_moon_glow.z_index = -1; add_child(_moon_glow)

func _animate(delta: float) -> void:
	_anim_t += delta
	anim.set_facing(direction)
	anim.update_motion(_seq.is_empty() and boss_id != 3, delta)
	if boss_id != 1:
		# Gorrah / Vey strips: 0 idle, 1 windup, 2 attack A, 3 attack B
		if _pose_t > 0.0: _pose_t -= delta; spr.frame = _pose
		elif telegraphing: spr.frame = 1
		elif _rush_t > 0.0: spr.frame = 3
		else: spr.frame = 0
		if _moon_glow:
			_moon_glow.modulate.a = 0.35 + 0.12 * sin(_anim_t * 3.0)
		return
	if not _seq.is_empty():
		_seq_t += delta
		while not _seq.is_empty() and _seq_t >= _seq[0][1]:
			_seq_t -= _seq[0][1]; _seq.pop_front()
			if not _seq.is_empty(): _seq_fx(_seq[0][0])
		if not _seq.is_empty():
			spr.frame = _seq[0][0]
			return
	if _pose_t > 0.0:
		_pose_t -= delta
		spr.frame = _pose
	else:
		spr.frame = 0 if int(_anim_t * 3.0) % 2 == 0 else 1
	if _moon_glow:
		_moon_glow.modulate.a = 0.38 + 0.12 * sin(_anim_t * 3.0)
		if phase2: _moon_glow.modulate = Color(1.0, 0.3, 0.35, _moon_glow.modulate.a)

var attacks_done := 0
func special_attack() -> void:
	attacks_done += 1
	var pat := _pattern
	_pattern = (_pattern + 1) % 3
	match boss_id:
		1:
			if pat == 0: _rin_cut_fan()
			elif pat == 1: _rin_dash()
			else: _rin_crescent()
		2:
			if pat == 0: _gorrah_slam()
			elif pat == 1: _gorrah_boulder()
			else: _gorrah_charge()
		3:
			if pat == 0: _vey_bolts()
			elif pat == 1: _vey_teleport_sweep()
			else: _vey_pillars_cast()

# --- Rin ---
func _rin_dash() -> void:
	## iai dash: crosses the arena along the red line (contact 1 dmg)
	_seq = CUT2_SEQ.duplicate(true); _seq_t = 0.0; _seq_fx(_seq[0][0])
	_rush_v = direction * (760.0 if phase2 else 640.0); _rush_t = 0.45 if phase2 else 0.38; _rush_hit = false
	GameManager.play_sfx("dash")

func _rin_crescent() -> void:
	## moon crescent wave along the floor (jump it); phase 2 sends one each way
	_seq = CUT_SEQ.duplicate(true); _seq_t = 0.0; _seq_fx(_seq[0][0])
	var dirs := [direction, -direction] if phase2 else [direction]
	for d in dirs:
		EnemyProjectile.spawn(get_tree().current_scene, "crescent", global_position + Vector2(d * 50, 30), Vector2(d * 420.0, 0))

# --- Gorrah ---
func _gorrah_slam() -> void:
	_pose = 2; _pose_t = 0.5
	anim.play_attack(0.3, 0.0)
	GameManager.play_sfx("boss_roar")
	var pl := _player()
	if pl and pl.has_method("trigger_shake"): pl.trigger_shake(12.0, 0.35)
	FX.death_burst(get_tree().current_scene, global_position + Vector2(direction * 40, 55), 0.6)
	for d in [-1, 1]:
		EnemyProjectile.spawn(get_tree().current_scene, "wave", global_position + Vector2(d * 60, 44), Vector2(d * 380.0, 0))
	if phase2:   # falling rocks with shadow tells
		for i in range(3):
			var x := randf_range(80.0, 1200.0)
			var fy := 660.0
			CombatUI.ground_ring(self, Vector2(x, fy), 30.0, 0.8, Color(1, 0.5, 0.2))
			var r := EnemyProjectile.spawn(get_tree().current_scene, "rock", Vector2(x, -120), Vector2(0, 0), 900.0)
			r.floor_y = fy; r.life = 3.0; r.vel.y = -200.0

func _gorrah_boulder() -> void:
	_pose = 3; _pose_t = 0.45
	anim.play_attack(0.3, 10.0)
	var pl := _player()
	if pl == null: return
	var shots := 2 if phase2 else 1
	for i in range(shots):
		var t := 0.9 + i * 0.25; var g := 900.0
		var from := global_position + Vector2(direction * 60, -80)
		var to := pl.global_position + Vector2((i * 90.0) * direction, 20)
		var v := Vector2((to.x - from.x) / t, (to.y - from.y - 0.5 * g * t * t) / t)
		var r := EnemyProjectile.spawn(get_tree().current_scene, "rock", from, v, g)
		r.floor_y = to.y + 4.0

func _gorrah_charge() -> void:
	_pose = 3; _pose_t = 0.9
	_rush_v = direction * (560.0 if phase2 else 460.0); _rush_t = 1.4; _rush_hit = false
	GameManager.play_sfx("boss_roar")

# --- Vey ---
func _vey_bolts() -> void:
	_pose = 2; _pose_t = 0.5
	anim.play_attack(0.3, 8.0)
	var pl := _player()
	if pl == null: return
	var n := 5 if phase2 else 3
	var base := (pl.global_position - global_position).angle()
	for i in range(n):
		var a := base + (i - (n - 1) / 2.0) * 0.22
		EnemyProjectile.spawn(get_tree().current_scene, "bolt", global_position + Vector2(0, -20), Vector2(cos(a), sin(a)) * 260.0)

func _vey_teleport_sweep() -> void:
	var pl := _player()
	if pl == null: return
	FX.sparks(get_tree().current_scene, global_position, Color(0.4, 0.2, 0.6), 22)
	var side := 1.0 if global_position.x < pl.global_position.x else -1.0
	var nx := clampf(pl.global_position.x + side * 140.0, 80.0, 1200.0)
	modulate.a = 0.0
	global_position.x = nx
	direction = -1 if side > 0 else 1
	var tw := create_tween(); tw.tween_property(self, "modulate:a", 1.0, 0.25)
	CombatUI.ground_ring(self, Vector2(0, 40), 120.0, 0.55, Color(0.75, 0.4, 1.0), true)
	_pose = 1; _pose_t = 0.55
	get_tree().create_timer(0.55).timeout.connect(_vey_sweep_hit)

func _vey_sweep_hit() -> void:
	if dead or not is_inside_tree(): return
	_pose = 3; _pose_t = 0.35
	anim.play_attack(0.3, 16.0)
	FX.ink_slash(get_tree().current_scene, global_position + Vector2(0, 10), direction, Color(0.4, 0.2, 0.55, 0.9), 120.0)
	var pl := _player()
	if pl and pl.global_position.distance_to(global_position + Vector2(0, 40)) < 120.0: pl.take_damage(1)

func _vey_pillars_cast() -> void:
	_pose = 1; _pose_t = 0.6   # rings were placed by the telegraph; pillars fire from _pillar

func _pillar(p: Vector2) -> void:
	if dead or not is_inside_tree(): return
	var col := Line2D.new(); col.width = 40; col.default_color = Color(0.45, 0.25, 0.7, 0.85)
	col.add_point(p); col.add_point(p + Vector2(0, -260)); col.z_index = 6
	var wc := Curve.new(); wc.add_point(Vector2(0, 1)); wc.add_point(Vector2(1, 0.2)); col.width_curve = wc
	get_tree().current_scene.add_child(col)
	var tw := col.create_tween(); tw.tween_property(col, "modulate:a", 0.0, 0.45); tw.tween_callback(col.queue_free)
	var pl := _player()
	if pl and absf(pl.global_position.x - p.x) < 46.0 and pl.global_position.y > p.y - 280.0: pl.take_damage(1)

func _rin_cut_fan() -> void:
	GameManager.play_sfx("shuriken")
	_pose = -1; _pose_t = 0.0
	_seq = (CUT2_SEQ if phase2 else CUT_SEQ).duplicate(true); _seq_t = 0.0
	_seq_fx(_seq[0][0])
	var n = 4 if phase2 else 3
	if phase2:
		speed = 260.0
		var tw = create_tween(); tw.tween_property(self, "speed", 140.0, 0.8)
	for i in range(n):
		var s = shuriken_scene.instantiate()
		s.global_position = global_position + Vector2(0, -20)
		s.direction = 1 if i % 2 == 0 else -1
		s.speed = 400.0 + i * 100.0
		s.is_enemy_projectile = true
		get_tree().current_scene.add_child(s)

func _seq_fx(frame: int) -> void:
	match frame:
		3: _cut_fx()
		6: _dash_fx()
		7: _rise_fx()

func _dash_fx() -> void:
	## phase-2 iai dash: long visual lunge, crimson draw streak and afterimages (movement unchanged)
	anim.play_attack(0.26, CUT_LUNGE_PX * 2.2)
	var streak = Line2D.new(); streak.width = 10.0; streak.default_color = Color(1.0, 0.25, 0.3, 0.95)
	var wc := Curve.new(); wc.add_point(Vector2(0, 0.0)); wc.add_point(Vector2(0.8, 1.0)); wc.add_point(Vector2(1, 0.3)); streak.width_curve = wc
	streak.add_point(Vector2(-150 * direction, -8)); streak.add_point(Vector2(170 * direction, -8))
	add_child(streak)
	var tw = streak.create_tween(); tw.tween_property(streak, "modulate:a", 0.0, 0.3); tw.tween_callback(streak.queue_free)
	for i in range(3):
		var g := Sprite2D.new(); g.texture = spr.texture; g.hframes = spr.hframes; g.frame = 6
		g.scale = Vector2(spr.scale.x * direction, spr.scale.y); g.offset = spr.offset
		g.position = Vector2(-(i + 1) * 34 * direction, 0); g.modulate = Color(1.0, 0.3, 0.35, 0.45 - i * 0.12)
		add_child(g)
		var gt = g.create_tween(); gt.tween_property(g, "modulate:a", 0.0, 0.25 + i * 0.05); gt.tween_callback(g.queue_free)

func _rise_fx() -> void:
	## phase-2 finisher: rising crimson crescent over Rin's head
	anim.play_attack(0.3, CUT_LUNGE_PX * 0.5)
	var arc = Line2D.new(); arc.width = 16.0; arc.default_color = Color(1.0, 0.3, 0.35, 0.95)
	var wc := Curve.new(); wc.add_point(Vector2(0, 0.1)); wc.add_point(Vector2(0.5, 1.0)); wc.add_point(Vector2(1, 0.1)); arc.width_curve = wc
	for i in range(15):
		var a := lerpf(1.2, -2.4, i / 14.0)
		arc.add_point(Vector2(cos(a) * direction, sin(a)) * 120.0)
	arc.position = Vector2(10 * direction, -40); add_child(arc)
	var tw = arc.create_tween(); tw.set_parallel(true)
	tw.tween_property(arc, "modulate:a", 0.0, 0.34); tw.tween_property(arc, "position:y", -70.0, 0.34)
	tw.chain().tween_callback(arc.queue_free)

func _cut_fx() -> void:
	## visible strike: body lunge + a painted-steel crescent in front of the blade
	anim.play_attack(0.3, CUT_LUNGE_PX)
	var arc = Line2D.new(); arc.width = 14.0
	arc.default_color = Color(1.0, 0.35, 0.4, 0.9) if phase2 else Color(0.75, 0.9, 1.0, 0.9)
	var wc := Curve.new(); wc.add_point(Vector2(0, 0.1)); wc.add_point(Vector2(0.6, 1.0)); wc.add_point(Vector2(1, 0.2)); arc.width_curve = wc
	for i in range(13):
		var a := lerpf(-1.3, 1.2, i / 12.0)
		arc.add_point(Vector2(cos(a) * direction, sin(a)) * ARC_RADIUS)
	arc.position = Vector2(30 * direction, 10); add_child(arc)
	var tw = arc.create_tween(); tw.tween_property(arc, "modulate:a", 0.0, 0.28); tw.tween_callback(arc.queue_free)

func take_damage(amount: int) -> void:
	if dead: return
	if _intro_t > 0.0:
		CombatUI.damage_number(self, global_position + Vector2(0, -40), 0, Color(0.8, 0.8, 0.9), "GUARD")
		return
	health -= amount
	CombatUI.damage_number(self, global_position + Vector2(0, -50), amount, Color(1, 0.85, 0.4))
	GameManager.play_sfx("hit")
	FX.flash(spr, HIT_FLASH_TIME)
	anim.play_hurt()
	if not phase2 and health <= max_health / 2:
		phase2 = true; speed = 160.0
		(spr.material as ShaderMaterial).set_shader_parameter("rim_color", Color(1, 0.1, 0.15))
		FX.toast(get_tree().current_scene, PHASE2_TOAST[boss_id - 1], Color(1, 0.4, 0.4))
		if boss_id == 3 and not _summoned:   # Vey calls two crow scouts once
			_summoned = true
			for i in range(2):
				var c = EnemyFactory.make("crow_scout")
				c.global_position = Vector2(200 + i * 880, 300)
				get_tree().current_scene.get_node("Enemies").add_child.call_deferred(c)
	if health <= 0:
		_death_sequence()

func _death_sequence() -> void:
	## 1.6 s: slow-mo, white flashes + bursts, sink and fade, then the KO flow (boss_defeated)
	dead = true
	telegraphing = false; _rush_t = 0.0; _seq.clear()
	collision_layer = 0
	remove_from_group("Bosses")
	GameManager.play_sfx("boss_roar")
	if not GameManager.reduced_motion: Engine.time_scale = 0.35
	for i in range(4):
		FX.flash(spr, 0.12)
		FX.death_burst(get_tree().current_scene, global_position + Vector2(randf_range(-50, 50), randf_range(-60, 20)), 1.0)
		await get_tree().create_timer(0.18, true, false, true).timeout
	Engine.time_scale = 1.0
	FX.death_burst(get_tree().current_scene, global_position, FX.BOSS_BURST_SCALE)
	CombatUI.drop_loot(self, global_position + Vector2(0, 40), true)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(anim, "rotation", -0.5 * direction, 0.6)
	tw.tween_property(self, "modulate:a", 0.0, 0.7)
	tw.tween_property(self, "position:y", position.y + 20.0, 0.7)
	await tw.finished
	emit_signal("boss_defeated")
	queue_free()
