extends Control

func _ready() -> void:
	var grid = $GridContainer
	for i in range(1, 13):
		var btn = Button.new()
		btn.text = "Level " + str(i)
		btn.custom_minimum_size = Vector2(100, 80)
		if i > GameManager.unlocked_level:
			btn.disabled = true
		else:
			btn.pressed.connect(func(): _load_level(i))
		grid.add_child(btn)

func _load_level(lvl: int) -> void:
	GameManager.current_level = lvl
	GameManager.play_sfx("click")
	get_tree().change_scene_to_file("res://scenes/Level.tscn")

func _on_back_pressed() -> void:
	GameManager.play_sfx("click")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
