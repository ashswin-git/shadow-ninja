extends Control

func _ready() -> void:
	visible = DisplayServer.is_touchscreen_available()

func _on_left_pressed() -> void:
	Input.action_press("move_left")

func _on_left_released() -> void:
	Input.action_release("move_left")

func _on_right_pressed() -> void:
	Input.action_press("move_right")

func _on_right_released() -> void:
	Input.action_release("move_right")

func _on_jump_pressed() -> void:
	Input.action_press("jump")

func _on_jump_released() -> void:
	Input.action_release("jump")

func _on_dash_pressed() -> void:
	Input.action_press("dash")

func _on_dash_released() -> void:
	Input.action_release("dash")

func _on_throw_pressed() -> void:
	Input.action_press("throw")

func _on_throw_released() -> void:
	Input.action_release("throw")
