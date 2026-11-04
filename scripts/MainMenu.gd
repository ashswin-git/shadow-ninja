extends Control

@onready var quit_button = $VBoxContainer/QuitButton
@onready var controls_popup = $ControlsPopup
@onready var rotate_prompt = $RotatePrompt if has_node("RotatePrompt") else null

func _ready() -> void:
	if OS.has_feature("web") and quit_button:
		quit_button.hide()
	if controls_popup:
		controls_popup.hide()

func _process(_delta: float) -> void:
	if OS.has_feature("web") and rotate_prompt:
		var sz = DisplayServer.window_get_size()
		rotate_prompt.visible = (sz.y > sz.x)

func _on_play_pressed() -> void:
	GameManager.play_sfx("click")
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")

func _on_controls_pressed() -> void:
	GameManager.play_sfx("click")
	if controls_popup:
		controls_popup.show()

func _on_close_controls_pressed() -> void:
	GameManager.play_sfx("click")
	if controls_popup:
		controls_popup.hide()

func _on_quit_pressed() -> void:
	get_tree().quit()
