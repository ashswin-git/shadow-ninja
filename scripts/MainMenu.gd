extends Control

func _on_play_pressed() -> void:
	GameManager.play_sfx("click")
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
