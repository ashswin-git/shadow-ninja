extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -500.0
const DOUBLE_JUMP_VELOCITY = -450.0
const DASH_SPEED = 900.0
const WALL_SLIDE_SPEED = 80.0
const COYOTE_TIME = 0.12
const JUMP_BUFFER_TIME = 0.12

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var can_double_jump: bool = true
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_dir: int = 1
var health: int = 3
var max_health: int = 3
var checkpoint_position: Vector2 = Vector2(100, 300)

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var shake_intensity: float = 0.0
var shake_duration: float = 0.0

@onready var sprite: Sprite2D = $Animator/Body/Sprite2D
@onready var anim: PlayerAnimator = $Animator
## facing (+1 right / -1 left); was the sign of sprite.scale.x, now owned here and mirrored by the animator
var facing: int = 1
@export var hit_stop_enabled: bool = true
const HIT_STOP_TIME := 0.05
const IDLE_EMOTE_AFTER := 5.0
var _idle_time := 0.0
@onready var camera: Camera2D = $Camera2D
@onready var shuriken_scene = preload("res://scenes/Shuriken.tscn")

signal health_changed(new_health)
signal died

var invuln := 0.0
func _ready() -> void:
	checkpoint_position = global_position
	# painted hero at gameplay scale (textures stored at 1.5x, feet on the collision bottom)
	# brighter grade + stronger moon rim so face, fang mask and scarf read at play size
	FX.painted(sprite, Color(0.6, 0.85, 1.0), 0.75, Color(1.3, 1.27, 1.38), 0.03)
	sprite.scale = Vector2(1.0 / 1.5, 1.0 / 1.5)
	sprite.offset = Vector2(0, 28.0 * 1.5 - (sprite.texture.get_height() / 2.0 - 3.0))
	anim.textures = _with_sheets(TEX)
	# rim outline (Phase 1): thin moon-blue ink line around the painted silhouette
	(sprite.material as ShaderMaterial).set_shader_parameter("outline_width", OUTLINE_PX)
	(sprite.material as ShaderMaterial).set_shader_parameter("outline_color", OUTLINE_COLOR)

## Phase 1 sprite sheets (tools/gen_hero_sheets.py): uniform cells sliced into AtlasTextures.
## keys: idle_0..5, run_0..7, c0_0..c2_4 (combo hit row, cell). Single pose frames stay in TEX.
const SHEETS := {
	"idle": [preload("res://assets/sprites/hero/hero_idle_sheet.png"), 6, 1],
	"run": [preload("res://assets/sprites/hero/hero_run_sheet.png"), 8, 1],
	"c": [preload("res://assets/sprites/hero/hero_slash_sheet.png"), 5, 3],
}
const OUTLINE_PX := 1.5
const OUTLINE_COLOR := Color(0.55, 0.8, 1.0, 0.85)
func _with_sheets(base: Dictionary) -> Dictionary:
	var d := base.duplicate()
	for k in SHEETS:
		var tex: Texture2D = SHEETS[k][0]
		var cols: int = SHEETS[k][1]; var rows: int = SHEETS[k][2]
		var cw := tex.get_width() / cols; var ch := tex.get_height() / rows
		for r in range(rows):
			for c in range(cols):
				var at := AtlasTexture.new(); at.atlas = tex
				at.region = Rect2(c * cw, r * ch, cw, ch)
				d[("%s_%d" % [k, c]) if rows == 1 else ("%s%d_%d" % [k, r, c])] = at
	return d

const LOOK_AHEAD_PX := 90.0
const LOOK_AHEAD_SHARP := 2.5
const RUN_DUST_EVERY := 0.22
var _run_dust_t := 0.0
var _was_floor := true
var _fall_vy := 0.0
func _process(delta: float) -> void:
	_domain_tick(delta)
	# camera look-ahead in the facing direction while moving (smooth follow stays on Camera2D)
	if camera:
		var la := 0.0
		if absf(velocity.x) > 10.0 and not GameManager.reduced_motion: la = facing * LOOK_AHEAD_PX
		camera.position.x = lerpf(camera.position.x, la, 1.0 - exp(-LOOK_AHEAD_SHARP * delta))
	if invuln > 0.0:
		invuln -= delta
		sprite.visible = invuln <= 0.0 or int(invuln * 20.0) % 2 == 0
	if shake_duration > 0:
		shake_duration -= delta
		if camera:
			camera.offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
	elif camera:
		camera.offset = Vector2.ZERO

var rope = null   # Phase 3: Mechanics.Rope currently held (it drives position while held)
func _physics_process(delta: float) -> void:
	if rope != null:
		if Input.is_action_just_pressed("jump"):
			velocity = rope.release() + Vector2(0, Mechanics.ROPE_JUMP_BOOST)
			can_double_jump = true
			GameManager.play_sfx("jump")
			move_and_slide()
		_update_anim()
		return
	if is_dashing:
		velocity = Vector2(dash_dir * DASH_SPEED, 0)
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
		move_and_slide()
		_update_anim()
		return

	# Coyote time & Ground check
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		can_double_jump = true
	else:
		coyote_timer -= delta
		if is_on_wall() and velocity.y > 0:
			velocity.y = min(velocity.y + gravity * delta, WALL_SLIDE_SPEED)
			can_double_jump = true
		else:
			velocity.y += gravity * delta

	# Jump Buffer update
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME

	# Handle Jump
	if jump_buffer_timer > 0:
		if is_on_floor() or coyote_timer > 0.0:
			velocity.y = JUMP_VELOCITY
			jump_buffer_timer = 0.0
			coyote_timer = 0.0
			can_double_jump = true
			GameManager.play_sfx("jump")
		elif is_on_wall():
			velocity.y = JUMP_VELOCITY
			velocity.x = -sign(velocity.x) * SPEED * 1.5
			jump_buffer_timer = 0.0
			can_double_jump = true
			GameManager.play_sfx("jump")
		elif can_double_jump:
			velocity.y = DOUBLE_JUMP_VELOCITY
			jump_buffer_timer = 0.0
			can_double_jump = false
			GameManager.play_sfx("jump")
			anim.play_double_jump()   # visual only

	# Handle Dash
	if Input.is_action_just_pressed("dash") and not is_dashing:
		is_dashing = true
		dash_timer = 0.2
		dash_dir = facing
		GameManager.play_sfx("dash")
		if dash_cd_toast <= 0.0: FX.toast(get_tree().current_scene, "SHADE STEP"); dash_cd_toast = 3.0
		trigger_shake(8.0, 0.15)

	if Input.is_action_just_pressed("domain"):
		cast_domain()
	if Input.is_action_just_pressed("attack"):
		if slash_cd > 0.0: attack_buffer = ATTACK_BUFFER   # input buffer: fires the moment the cooldown ends
		else: do_slash()
	_vfx_tick(delta)

	# Handle Throw Shuriken
	if Input.is_action_just_pressed("throw"):
		throw_shuriken()

	# Get input direction
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
		facing = 1 if direction > 0 else -1
		anim.set_facing(facing)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	_feel_tick(delta)
	_update_anim()

	if global_position.y > 1000:
		die()

func _feel_tick(delta: float) -> void:
	## landing + run dust (visual only)
	var on_floor := is_on_floor()
	if on_floor and not _was_floor and _fall_vy > 250.0:
		FX.dust(get_tree().current_scene, global_position + Vector2(0, 28), 10 if not GameManager.reduced_motion else 4, 0)
		GameManager.play_sfx("land", 0.12)
	if on_floor and absf(velocity.x) > 10.0 and not is_dashing:
		_run_dust_t -= delta
		if _run_dust_t <= 0.0:
			_run_dust_t = RUN_DUST_EVERY
			if not GameManager.reduced_motion: FX.dust(get_tree().current_scene, global_position + Vector2(-10 * facing, 28), 3, -facing)
	_was_floor = on_floor
	_fall_vy = velocity.y if not on_floor else 0.0

func trigger_shake(intensity: float = 10.0, duration: float = 0.2) -> void:
	if GameManager.reduced_motion: return
	shake_intensity = intensity
	shake_duration = duration

func throw_shuriken() -> void:
	var s = Pool.take("kunai", func(): return shuriken_scene.instantiate()); s.reset()
	s.global_position = global_position + Vector2(20 * facing, -10)
	s.direction = facing
	anim.play_throw()   # cancels a slash only inside its cancel window (visual)
	get_tree().current_scene.add_child(s)
	GameManager.play_sfx("shuriken")
	if Progression.has_skill("twin_kunai"):   # same kunai (speed 600, damage unchanged), second one angled up
		var s2 = Pool.take("kunai", func(): return shuriken_scene.instantiate()); s2.reset()
		s2.global_position = global_position + Vector2(20 * facing, -30); s2.direction = facing
		get_tree().current_scene.add_child(s2)

## Phase 4 perks (scripts/meta/progression.gd): wards, ghost dash, second breath, tea.
var wards := 0
var _breath_used := false
var _tea_used := false
signal ward_changed(n)
signal slash_hit(count)

func take_damage(amount: int) -> void:
	# short i-frames so overlapping boss shuriken / contact can't chain-hit (softer boss melee)
	if invuln > 0.0: return
	if is_dashing and Progression.has_skill("ghost_step"): return
	if wards > 0:
		wards -= 1; invuln = 0.9; emit_signal("ward_changed", wards); GameManager.play_sfx("block")
		FX.toast(get_tree().current_scene, "WARD"); FX.sparks(get_tree().current_scene, global_position, Color(0.6, 0.85, 1.0), 14)
		GameManager.vibrate(20); return
	invuln = 0.9
	health -= amount
	GameManager.vibrate(45)
	if health <= 0 and Progression.has_skill("second_breath") and not _breath_used:
		_breath_used = true; health = 1; FX.toast(get_tree().current_scene, "SECOND BREATH")
	elif health == 1 and not _tea_used and int(GameManager.meta["shop"]["tea"]) > 0:
		_tea_used = true; GameManager.meta["shop"]["tea"] = int(GameManager.meta["shop"]["tea"]) - 1
		health = 2; FX.toast(get_tree().current_scene, "HEALING TEA"); GameManager.save_game()
	emit_signal("health_changed", health)
	GameManager.play_sfx("hit")
	trigger_shake(14.0, 0.3)
	flash_hit()
	anim.play_hurt()
	if health <= 0:
		die()

func flash_hit() -> void:
	if sprite:
		FX.flash(sprite, 0.15)
		FX.sparks(get_tree().current_scene, global_position, Color(0.9, 0.1, 0.15), 16)

func die() -> void:
	if rope != null: rope.release()
	FX.death_ghost(get_tree().current_scene, sprite)
	GameManager.meta["stats"]["deaths"] = int(GameManager.meta["stats"]["deaths"]) + 1
	emit_signal("died")
	global_position = checkpoint_position
	reset_physics_interpolation()
	health = max_health
	velocity = Vector2.ZERO
	emit_signal("health_changed", health)
	trigger_shake(20.0, 0.4)
	anim.revive(); anim.play_land(1.0)

## painted hero pose frames, packed in one atlas in Phase 5 (tools/gen_atlas.py -> HeroAtlas)
var TEX: Dictionary = HeroAtlas.textures()
var _slash_pose := 0.0
var _run_t := 0.0
func _update_anim() -> void:
	# pose textures, squash/stretch, bob and lean now come from PlayerAnimator
	var dt := get_physics_process_delta_time()
	anim.update_motion(velocity, is_on_floor(), is_on_wall(), is_dashing, dt)
	if is_on_floor() and absf(velocity.x) < 1.0 and not is_dashing:
		_idle_time += dt
		if _idle_time > IDLE_EMOTE_AFTER:
			_idle_time = 0.0
			anim.play_emote("wave")
	else:
		_idle_time = 0.0

const DOMAIN_COOLDOWN := 6.0
const DOMAIN_RADIUS := 280.0
var domain_cd := 0.0
var domains_cast := 0
signal domain_changed(ratio)

func _notification(what: int) -> void:
	pass

func _domain_tick(delta: float) -> void:
	if domain_cd > 0.0:
		domain_cd = max(0.0, domain_cd - delta)
		emit_signal("domain_changed", 1.0 - domain_cd / DOMAIN_COOLDOWN)

var dash_cd_toast := 0.0
var _ai_t := 0.0
var _aura: Sprite2D
var slash_cd := 0.0
func _vfx_tick(delta: float) -> void:
	dash_cd_toast -= delta; slash_cd -= delta
	if _aura == null:
		_aura = Sprite2D.new(); _aura.texture = load("res://assets/sprites/aura.png"); _aura.z_index = -1
		add_child(_aura)
		var tw = _aura.create_tween().set_loops()
		tw.tween_property(_aura, "scale", Vector2(1.15, 1.15), 0.6); tw.tween_property(_aura, "scale", Vector2(0.95, 0.95), 0.6)
	_aura.position = Vector2.ZERO  # aura stays centred on the body (sprite now lives under Animator/Body)
	if is_dashing:
		_ai_t -= delta
		if _ai_t <= 0.0:
			_ai_t = 0.03 if not GameManager.reduced_motion else 0.08
			FX.afterimage(get_tree().current_scene, sprite)
	# attack input buffer + 3-hit combo window
	attack_buffer -= delta
	_combo_t -= delta
	if attack_buffer > 0.0 and slash_cd <= 0.0:
		attack_buffer = 0.0
		do_slash()

const ATTACK_BUFFER := 0.15   # an attack pressed this close to the end of the cooldown is queued
const COMBO_WINDOW := 0.65    # next hit within this time of the last one continues the 3-hit combo
var attack_buffer := 0.0
var combo_step := 0
var _combo_t := 0.0
func do_slash() -> void:
	if slash_cd > 0.0: return
	slash_cd = 0.28   # unchanged: every combo hit is the same 1-damage, ~80 reach, 0.28 s slash
	_slash_pose = 0.16
	combo_step = (combo_step % 3) + 1 if _combo_t > 0.0 else 1
	_combo_t = COMBO_WINDOW
	anim.play_slash(combo_step)
	var dir = facing
	var c = global_position + Vector2(40 * dir, -6)
	FX.ink_slash(get_tree().current_scene, c, dir)
	GameManager.play_sfx("slash")
	var hit := false
	var hits := 0
	for e in get_tree().get_nodes_in_group("Enemies") + get_tree().get_nodes_in_group("Bosses"):
		if is_instance_valid(e) and e.global_position.distance_to(c) < 80 and e.has_method("take_damage"):
			FX.hit_burst(get_tree().current_scene, e.global_position)
			FX.sparks(get_tree().current_scene, e.global_position, Color(1, 0.15, 0.2), 18, dir)
			e.take_damage(1); hit = true; hits += 1
			if combo_step == 3 and Progression.has_skill("moon_finisher") and e.is_in_group("Enemies") and is_instance_valid(e):
				var kt = e.create_tween(); kt.tween_property(e, "global_position:x", e.global_position.x + 70 * dir, 0.18).set_ease(Tween.EASE_OUT)
	if hits > 0: emit_signal("slash_hit", hits); GameManager.play_sfx("enemy_hit")
	if hit:
		if hit_stop_enabled and not GameManager.reduced_motion: FX.hit_stop(get_tree(), HIT_STOP_TIME)
		trigger_shake(7.0, 0.15)

func cast_domain() -> void:
	if domain_cd > 0.0:
		return
	domain_cd = DOMAIN_COOLDOWN
	domains_cast += 1
	emit_signal("domain_changed", 0.0)
	if Progression.has_skill("moon_veil") and wards < 1: wards = 1; emit_signal("ward_changed", wards)
	if Progression.has_skill("rite_echo"):
		for pr in get_tree().get_nodes_in_group("EnemyProjectiles"): pr.queue_free()
	anim.play_domain_cast()
	FX.cut_in(get_tree().current_scene, "VEIL OF THE STILL MOON")
	FX.freeze(get_tree(), 0.6)
	await get_tree().create_timer(0.62, true).timeout
	for i in range(4):
		var a = i * PI / 2 + 0.4
		FX.ink_slash(get_tree().current_scene, global_position + Vector2(cos(a), sin(a)) * 60, 1 if i % 2 == 0 else -1, Color(0.05, 0.05, 0.12, 0.95), 120.0)
	var fx = preload("res://scripts/DomainFX.gd").new()
	fx.max_r = DOMAIN_RADIUS
	fx.global_position = global_position
	get_tree().current_scene.add_child(fx)
	GameManager.play_sfx("domain", 0.0)   # rich art pass: bespoke gong + shimmer (tools/gen_rich_props.py)
	trigger_shake(10.0, 0.3)
	for e in get_tree().get_nodes_in_group("Enemies") + get_tree().get_nodes_in_group("Bosses"):
		if is_instance_valid(e) and e.global_position.distance_to(global_position) <= DOMAIN_RADIUS:
			if e.has_method("take_damage"):
				FX.hit_burst(get_tree().current_scene, e.global_position, Color(1.0, 0.86, 0.5))
				e.take_damage(3)
			if "speed" in e:
				var old = e.speed
				e.speed = old * 0.3
				get_tree().create_timer(3.0 if Progression.equipped("moon_mirror") else 2.0).timeout.connect(func(): if is_instance_valid(e): e.speed = old)
