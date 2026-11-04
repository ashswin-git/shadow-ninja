extends Node2D

@export var level_number: int = 1

var coins_collected: int = 0
var total_coins_in_level: int = 3
var stars: int = 0

@onready var player = $Player
@onready var ui_canvas = $CanvasLayer
@onready var health_label = $CanvasLayer/HUD/HealthLabel
@onready var coins_label = $CanvasLayer/HUD/CoinsLabel
@onready var level_label = $CanvasLayer/HUD/LevelLabel
@onready var pause_menu = $CanvasLayer/PauseMenu
@onready var victory_screen = $CanvasLayer/VictoryScreen
@onready var game_over_screen = $CanvasLayer/GameOverScreen

func _ready() -> void:
	level_label.text = "Level " + str(level_number)
	coins_label.text = "Coins: 0/" + str(total_coins_in_level)
	player.connect("health_changed", _on_player_health_changed)
	player.connect("died", _on_player_died)

	# Connect items / portal / traps
	for node in get_tree().get_nodes_in_group("Coins"):
		node.connect("body_entered", func(body): _on_coin_collected(node, body))
	for node in get_tree().get_nodes_in_group("Checkpoints"):
		node.connect("body_entered", func(body): _on_checkpoint_reached(node, body))
	for node in get_tree().get_nodes_in_group("Portals"):
		node.connect("body_entered", func(body): _on_portal_entered(body))
	for node in get_tree().get_nodes_in_group("Traps"):
		node.connect("body_entered", func(body): _on_trap_entered(body))
	for node in get_tree().get_nodes_in_group("Bosses"):
		node.connect("boss_defeated", _on_boss_defeated)

func _on_player_health_changed(hp: int) -> void:
	health_label.text = "HP: " + str(hp) + "/3"

func _on_player_died() -> void:
	pass

func _on_coin_collected(coin, body) -> void:
	if body == player:
		coins_collected += 1
		coins_label.text = "Coins: " + str(coins_collected) + "/" + str(total_coins_in_level)
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
	victory_screen.show()
	get_tree().paused = true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		pause_menu.visible = not pause_menu.visible
		get_tree().paused = pause_menu.visible
