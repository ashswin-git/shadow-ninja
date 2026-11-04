extends Control

@onready var grid = $GridContainer

func _ready() -> void:
	for i in range(1, 13):
		var btn = Button.new()
		var stars_won = GameManager.level_stars.get(str(i), 0)
		var star_str = ""
		if i <= GameManager.unlocked_level:
			star_str = "\n" + "★".repeat(stars_won) + "☆".repeat(3 - stars_won)
		else:
			star_str = "\n🔒 Locked"

		btn.text = "Lvl " + str(i) + star_str
		btn.custom_minimum_size = Vector2(130, 90)
		btn.add_theme_font_size_override("font_size", 18)
		if i > GameManager.unlocked_level:
			btn.disabled = true
			btn.modulate = Color(0.5, 0.5, 0.5, 0.7)
		else:
			btn.pressed.connect(func(): _load_level(i))
			btn.modulate = Color(1, 1, 1, 1)
		grid.add_child(btn)

func _load_level(lvl: int) -> void:
	GameManager.current_level = lvl
	GameManager.play_sfx("click")
	get_tree().change_scene_to_file("res://scenes/Level.tscn")

func _on_back_pressed() -> void:
	GameManager.play_sfx("click")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
