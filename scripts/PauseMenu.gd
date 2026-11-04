extends Control

func _on_resume_pressed() -> void:
	GameManager.play_sfx("click")
	hide()
	get_tree().paused = false

func _on_restart_pressed() -> void:
	GameManager.play_sfx("click")
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	GameManager.play_sfx("click")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
