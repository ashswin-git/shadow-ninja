extends Area2D

@export var speed: float = 600.0
@export var direction: int = 1
@export var damage: int = 1
@export var is_enemy_projectile: bool = false

func _ready() -> void:
	if is_enemy_projectile: add_to_group("EnemyProjectiles")

const LIFETIME := 1.6   # Phase 5: kunai expire off-screen and return to the pool (were never freed)
var _age := 0.0
func reset() -> void:
	_age = 0.0; set_deferred("monitoring", true)

func _done() -> void:
	if has_meta("pool_key"): Pool.give(self)
	else: queue_free()

func _physics_process(delta: float) -> void:
	position.x += speed * direction * delta
	_age += delta
	if _age > LIFETIME and not is_enemy_projectile: _done()

func _on_body_entered(body: Node2D) -> void:
	if is_enemy_projectile:
		if body.has_method("take_damage"):
			body.take_damage(damage)
			queue_free()
	else:
		if body.has_method("take_damage"):
			body.take_damage(damage)
			_done()
		elif body is TileMap or body.is_in_group("World"):
			_done()
