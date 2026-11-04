extends Area2D

@export var speed: float = 600.0
@export var direction: int = 1
@export var damage: int = 1
@export var is_enemy_projectile: bool = false

func _ready() -> void:
	if not is_enemy_projectile:
		GameManager.play_sfx("shuriken")

func _physics_process(delta: float) -> void:
	position.x += speed * direction * delta

func _on_body_entered(body: Node2D) -> void:
	if is_enemy_projectile:
		if body.has_method("take_damage"):
			body.take_damage(damage)
			queue_free()
	else:
		if body.has_method("take_damage"):
			body.take_damage(damage)
			queue_free()
		elif body is TileMap or body.is_in_group("World"):
			queue_free()
