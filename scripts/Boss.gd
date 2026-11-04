extends CharacterBody2D

@export var boss_id: int = 1
var health: int = 20
var max_health: int = 20
var speed: float = 120.0
var direction: int = 1
var attack_timer: float = 0.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var shuriken_scene = preload("res://scenes/Shuriken.tscn")

signal boss_defeated

func _ready() -> void:
	if boss_id == 1:
		health = 15
	elif boss_id == 2:
		health = 25
	elif boss_id == 3:
		health = 40
	max_health = health
	GameManager.play_sfx("boss_roar")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	velocity.x = direction * speed
	move_and_slide()

	if is_on_wall():
		direction *= -1

	attack_timer += delta
	if attack_timer >= 1.5:
		attack_timer = 0.0
		special_attack()

func special_attack() -> void:
	GameManager.play_sfx("shuriken")
	for i in range(3):
		var s = shuriken_scene.instantiate()
		s.global_position = global_position + Vector2(0, -20)
		s.direction = 1 if i % 2 == 0 else -1
		s.speed = 400.0 + i * 100.0
		s.is_enemy_projectile = true
		get_tree().current_scene.add_child(s)

func take_damage(amount: int) -> void:
	health -= amount
	GameManager.play_sfx("hit")
	if health <= 0:
		emit_signal("boss_defeated")
		queue_free()
