extends Control

@onready var quit_button = $VBoxContainer/QuitButton
@onready var controls_popup = $ControlsPopup
@onready var rotate_prompt = $RotatePrompt if has_node("RotatePrompt") else null

func _ready() -> void:
	GameManager.play_music("menu")
	GameManager.add_menu_bg(self)
	# Title screen: stacked serif title on the left, one thin PLAY on the right.
	if has_node("VBoxContainer"):
		$VBoxContainer.visible = false
	if has_node("ControlsPopup"):
		$ControlsPopup.hide()
	# Move the menu hero toward the centre of the painted vista.
	if has_node("MenuHero"):
		var hero = $MenuHero
		hero.position = Vector2(420, 160)
		hero.size = Vector2(440, 520)

	# ornate lacquer + gold-inlay frame behind the stacked serif title (Kenney CC0 lattice border)
	var tf := TextureRect.new()
	tf.texture = load("res://assets/ui/title_frame.png")
	tf.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tf.position = Vector2(40, 132); tf.size = Vector2(440, 288)
	tf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tf)

	var title := Label.new()
	title.text = "SHADOW\nNINJA"
	title.position = Vector2(70, 150)
	title.size = Vector2(380, 230)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if ResourceLoader.exists("res://content/original/fonts/SourceSerifPro-Bold.ttf"):
		title.add_theme_font_override("font", load("res://content/original/fonts/SourceSerifPro-Bold.ttf"))
	title.add_theme_font_size_override("font_size", 84)
	title.add_theme_color_override("font_color", Color(0.98, 0.90, 0.68))
	title.add_theme_color_override("font_outline_color", Color(0.10, 0.05, 0.01))
	title.add_theme_constant_override("outline_size", 10)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 5)
	title.add_theme_constant_override("line_spacing", -14)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	# solid physical PLAY: crimson lacquer plate, forged gold rim and studs
	var play := Button.new()
	play.text = "PLAY"
	play.focus_mode = Control.FOCUS_NONE
	play.position = Vector2(900, 330)
	play.size = Vector2(300, 64)
	if ResourceLoader.exists("res://content/original/fonts/SourceSerifPro-Bold.ttf"):
		play.add_theme_font_override("font", load("res://content/original/fonts/SourceSerifPro-Bold.ttf"))
	play.add_theme_font_size_override("font_size", 34)
	play.add_theme_color_override("font_color", Color(1.0, 0.94, 0.78))
	play.add_theme_color_override("font_hover_color", Color(1, 1, 0.9))
	play.add_theme_color_override("font_pressed_color", Color(1, 0.85, 0.6))
	play.add_theme_color_override("font_outline_color", Color(0.25, 0.02, 0.02))
	play.add_theme_constant_override("outline_size", 8)
	for st in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxTexture.new()
		sb.texture = load("res://assets/ui/play_btn.png")
		if st == "hover": sb.modulate_color = Color(1.12, 1.08, 1.05)
		if st == "pressed": sb.modulate_color = Color(0.8, 0.75, 0.7)
		play.add_theme_stylebox_override(st, sb)
	play.pivot_offset = Vector2(150, 32)
	play.pressed.connect(_on_play_pressed)
	add_child(play)
	UIJuice.pop_in(play, 0.15)
	UIJuice.bind_button(play)

func _process(_delta: float) -> void:
	if OS.has_feature("web") and rotate_prompt:
		var sz = DisplayServer.window_get_size()
		rotate_prompt.visible = (sz.y > sz.x)

func _on_play_pressed() -> void:
	GameManager.play_sfx("click")
	GameManager.change_scene("res://scenes/Hub.tscn")

func _on_controls_pressed() -> void:
	pass

func _on_close_controls_pressed() -> void:
	pass

func _on_quit_pressed() -> void:
	get_tree().quit()
