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

@onready var sprite: Sprite2D = $Sprite2D
@onready var camera: Camera2D = $Camera2D
@onready var shuriken_scene = preload("res://scenes/Shuriken.tscn")

signal health_changed(new_health)
signal died

func _ready() -> void:
	checkpoint_position = global_position

func _process(delta: float) -> void:
	if shake_duration > 0:
		shake_duration -= delta
		if camera:
			camera.offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
	elif camera:
		camera.offset = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if is_dashing:
		velocity = Vector2(dash_dir * DASH_SPEED, 0)
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
		move_and_slide()
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

	# Handle Dash
	if Input.is_action_just_pressed("dash") and not is_dashing:
		is_dashing = true
		dash_timer = 0.2
		dash_dir = 1 if sprite.scale.x > 0 else -1
		GameManager.play_sfx("dash")
		trigger_shake(8.0, 0.15)

	# Handle Throw Shuriken
	if Input.is_action_just_pressed("throw"):
		throw_shuriken()

	# Get input direction
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
		sprite.scale.x = abs(sprite.scale.x) * sign(direction)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	if global_position.y > 1000:
		die()

func trigger_shake(intensity: float = 10.0, duration: float = 0.2) -> void:
	shake_intensity = intensity
	shake_duration = duration

func throw_shuriken() -> void:
	var s = shuriken_scene.instantiate()
	s.global_position = global_position + Vector2(20 * sign(sprite.scale.x), -10)
	s.direction = 1 if sprite.scale.x > 0 else -1
	get_tree().current_scene.add_child(s)

func take_damage(amount: int) -> void:
	health -= amount
	emit_signal("health_changed", health)
	GameManager.play_sfx("hit")
	trigger_shake(14.0, 0.3)
	flash_hit()
	if health <= 0:
		die()

func flash_hit() -> void:
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 0.2, 0.2), 0.05)
		tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.05)
		tween.tween_property(sprite, "modulate", Color(1, 0.2, 0.2), 0.05)
		tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.05)

func die() -> void:
	emit_signal("died")
	global_position = checkpoint_position
	health = max_health
	velocity = Vector2.ZERO
	emit_signal("health_changed", health)
	trigger_shake(20.0, 0.4)
