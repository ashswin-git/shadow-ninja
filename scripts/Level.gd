extends Node2D

var level_number: int = 1
var coins_collected: int = 0
var total_coins_in_level: int = 3
var stars: int = 0

@onready var player = $Player
@onready var health_label = $CanvasLayer/HUD/HealthLabel
@onready var coins_label = $CanvasLayer/HUD/CoinsLabel
@onready var level_label = $CanvasLayer/HUD/LevelLabel
@onready var pause_menu = $CanvasLayer/PauseMenu
@onready var victory_screen = $CanvasLayer/VictoryScreen
@onready var game_over_screen = $CanvasLayer/GameOverScreen
@onready var boss_health_bar = $CanvasLayer/HUD/BossHealthBar if has_node("CanvasLayer/HUD/BossHealthBar") else null
@onready var rotate_prompt = $CanvasLayer/RotatePrompt if has_node("CanvasLayer/RotatePrompt") else null

var active_boss = null

func _ready() -> void:
	level_number = GameManager.current_level
	level_label.text = "Level " + str(level_number)

	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	victory_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	game_over_screen.process_mode = Node.PROCESS_MODE_ALWAYS

	build_level_layout()

	coins_label.text = "🪙 Coins: 0/" + str(total_coins_in_level)
	player.connect("health_changed", _on_player_health_changed)
	player.connect("died", _on_player_died)

func build_level_layout() -> void:
	var world_node = $World
	var coins_node = $Coins
	var enemies_node = $Enemies
	var traps_node = $Traps
	var checkpoints_node = $Checkpoints
	var portals_node = $Portals

	for c in coins_node.get_children(): c.queue_free()
	for c in enemies_node.get_children(): c.queue_free()
	for t in traps_node.get_children(): t.queue_free()
	for cp in checkpoints_node.get_children(): cp.queue_free()
	for p in portals_node.get_children(): p.queue_free()
	for b in world_node.get_children():
		if b.name != "Floor":
			b.queue_free()

	for node in get_tree().get_nodes_in_group("Bosses"):
		node.queue_free()

	if level_number in [4, 8, 12]:
		total_coins_in_level = 3
		var boss_id = 1 if level_number == 4 else (2 if level_number == 8 else 3)
		var boss_scene = load("res://scenes/Boss.tscn")
		var boss = boss_scene.instantiate()
		boss.boss_id = boss_id
		boss.global_position = Vector2(900, 550)
		add_child(boss)
		active_boss = boss
		boss.connect("boss_defeated", _on_boss_defeated)

		if boss_health_bar:
			boss_health_bar.max_value = boss.max_health
			boss_health_bar.value = boss.health
			boss_health_bar.show()

		add_platform(Vector2(640, 600), Vector2(1280, 32))
		add_portal(Vector2(1150, 520))
		add_checkpoint(Vector2(200, 636))

		add_coin(Vector2(400, 500))
		add_coin(Vector2(650, 500))
		add_coin(Vector2(900, 400))
	else:
		total_coins_in_level = 3 + (level_number % 3)

		var plat_count = 2 + (level_number % 4)
		for i in range(plat_count):
			var px = 300 + i * 250
			var py = 580 - (i % 2) * 120 - (level_number * 5) % 60
			add_platform(Vector2(px, py), Vector2(300, 32))

		for i in range(total_coins_in_level):
			var cx = 350 + i * 200
			var cy = 450 - (i % 2) * 100
			add_coin(Vector2(cx, cy))

		var enemy_scene = load("res://scenes/Enemy.tscn")
		var enemy_count = 1 + level_number % 3
		for i in range(enemy_count):
			var enemy = enemy_scene.instantiate()
			enemy.global_position = Vector2(500 + i * 220, 520)
			enemy.is_ranged = (i % 2 == 1)
			enemies_node.add_child(enemy)

		var trap_scene = load("res://scenes/Trap.tscn")
		var trap_count = level_number % 3
		for i in range(trap_count):
			var trap = trap_scene.instantiate()
			trap.global_position = Vector2(450 + i * 300, 670)
			traps_node.add_child(trap)

		add_checkpoint(Vector2(600, 636))
		add_portal(Vector2(1150, 620))

	for node in get_tree().get_nodes_in_group("Coins"):
		node.connect("body_entered", func(body): _on_coin_collected(node, body))
	for node in get_tree().get_nodes_in_group("Checkpoints"):
		node.connect("body_entered", func(body): _on_checkpoint_reached(node, body))
	for node in get_tree().get_nodes_in_group("Portals"):
		node.connect("body_entered", func(body): _on_portal_entered(body))
	for node in get_tree().get_nodes_in_group("Traps"):
		node.connect("body_entered", func(body): _on_trap_entered(body))

func add_platform(pos: Vector2, size: Vector2) -> void:
	var body = StaticBody2D.new()
	body.add_to_group("World")
	body.collision_mask = 2
	body.position = pos
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)

	var color_rect = ColorRect.new()
	color_rect.size = size
	color_rect.position = -size / 2.0
	color_rect.color = Color(0.15, 0.12, 0.25, 1.0)
	body.add_child(color_rect)

	var line = ColorRect.new()
	line.size = Vector2(size.x, 4)
	line.position = -size / 2.0
	line.color = Color(0.4, 0.7, 1.0, 1.0)
	body.add_child(line)

	$World.add_child(body)

func add_coin(pos: Vector2) -> void:
	var coin_scene = load("res://scenes/Coin.tscn")
	var coin = coin_scene.instantiate()
	coin.global_position = pos
	$Coins.add_child(coin)

func add_checkpoint(pos: Vector2) -> void:
	var cp_scene = load("res://scenes/Checkpoint.tscn")
	var cp = cp_scene.instantiate()
	cp.global_position = pos
	$Checkpoints.add_child(cp)

func add_portal(pos: Vector2) -> void:
	var portal_scene = load("res://scenes/Portal.tscn")
	var portal = portal_scene.instantiate()
	portal.global_position = pos
	$Portals.add_child(portal)

func _process(delta: float) -> void:
	if active_boss and is_instance_valid(active_boss) and boss_health_bar:
		boss_health_bar.value = active_boss.health
	if OS.has_feature("web") and rotate_prompt:
		var sz = DisplayServer.window_get_size()
		rotate_prompt.visible = (sz.y > sz.x)

func _on_player_health_changed(hp: int) -> void:
	health_label.text = "♥ HP: " + str(hp) + "/3"

func _on_player_died() -> void:
	pass

func _on_coin_collected(coin, body) -> void:
	if body == player:
		coins_collected += 1
		coins_label.text = "🪙 Coins: " + str(coins_collected) + "/" + str(total_coins_in_level)
		GameManager.play_sfx("coin")
		coin.queue_free()

func _on_checkpoint_reached(cp, body) -> void:
	if body == player:
		player.checkpoint_position = cp.global_position

func _on_portal_entered(body) -> void:
	if body == player:
		stars = 3 if coins_collected >= total_coins_in_level else (2 if coins_collected > 0 else 1)
		GameManager.complete_level(level_number, stars, coins_collected)
		GameManager.play_sfx("win")
		victory_screen.show()
		get_tree().paused = true

func _on_trap_entered(body) -> void:
	if body == player:
		player.take_damage(1)

func _on_boss_defeated() -> void:
	stars = 3
	GameManager.complete_level(level_number, stars, coins_collected)
	GameManager.play_sfx("win")
	if boss_health_bar:
		boss_health_bar.hide()
	victory_screen.show()
	get_tree().paused = true

func _on_next_pressed() -> void:
	get_tree().paused = false
	GameManager.current_level += 1
	if GameManager.current_level > 12:
		get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")
	else:
		get_tree().reload_current_scene()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		pause_menu.visible = not pause_menu.visible
		get_tree().paused = pause_menu.visible
