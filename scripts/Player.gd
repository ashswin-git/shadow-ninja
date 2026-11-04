extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -500.0
const DOUBLE_JUMP_VELOCITY = -450.0
const DASH_SPEED = 900.0
const WALL_SLIDE_SPEED = 80.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var can_double_jump: bool = true
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_dir: int = 1
var health: int = 3
var max_health: int = 3
var checkpoint_position: Vector2 = Vector2(100, 300)

@onready var sprite: Sprite2D = $Sprite2D
@onready var shuriken_scene = preload("res://scenes/Shuriken.tscn")

signal health_changed(new_health)
signal died

func _ready() -> void:
	checkpoint_position = global_position

func _physics_process(delta: float) -> void:
	if is_dashing:
		velocity = Vector2(dash_dir * DASH_SPEED, 0)
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
		move_and_slide()
		return

	# Add gravity
	if not is_on_floor():
		if is_on_wall() and velocity.y > 0:
			velocity.y = min(velocity.y + gravity * delta, WALL_SLIDE_SPEED)
		else:
			velocity.y += gravity * delta

	# Handle Jump
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			can_double_jump = true
			GameManager.play_sfx("jump")
		elif is_on_wall():
			velocity.y = JUMP_VELOCITY
			velocity.x = -sign(velocity.x) * SPEED * 1.5
			can_double_jump = true
			GameManager.play_sfx("jump")
		elif can_double_jump:
			velocity.y = DOUBLE_JUMP_VELOCITY
			can_double_jump = false
			GameManager.play_sfx("jump")

	# Handle Dash
	if Input.is_action_just_pressed("dash") and not is_dashing:
		is_dashing = true
		dash_timer = 0.2
		dash_dir = 1 if sprite.scale.x > 0 else -1
		GameManager.play_sfx("dash")

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

func throw_shuriken() -> void:
	var s = shuriken_scene.instantiate()
	s.global_position = global_position + Vector2(20 * sign(sprite.scale.x), -10)
	s.direction = 1 if sprite.scale.x > 0 else -1
	get_tree().current_scene.add_child(s)

func take_damage(amount: int) -> void:
	health -= amount
	emit_signal("health_changed", health)
	GameManager.play_sfx("hit")
	if health <= 0:
		die()

func die() -> void:
	emit_signal("died")
	global_position = checkpoint_position
	health = max_health
	velocity = Vector2.ZERO
	emit_signal("health_changed", health)
