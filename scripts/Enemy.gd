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

func _ready() -> void:
	start_x = global_position.x

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if not is_ranged:
		velocity.x = direction * speed
		if abs(global_position.x - start_x) > patrol_distance:
			direction *= -1
	else:
		velocity.x = 0
		shoot_timer += delta
		if shoot_timer >= 2.0:
			shoot_timer = 0.0
			shoot()

	move_and_slide()

	if is_on_wall():
		direction *= -1

func shoot() -> void:
	var s = shuriken_scene.instantiate()
	s.global_position = global_position + Vector2(20 * direction, -10)
	s.direction = direction
	s.is_enemy_projectile = true
	get_tree().current_scene.add_child(s)

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		queue_free()
