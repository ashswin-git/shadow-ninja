extends Control
# Centred wood/metal card. World stays visible; no frosted full-screen plate.

var _ui_hidden := false
var _card: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Hide the old stacked pause chrome from the packed scene.
	for c in get_children():
		c.visible = false
	_build()

func _build() -> void:
	# light dim only — the world remains readable
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.28)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	_card = Control.new()
	_card.position = Vector2(430, 90)
	_card.size = Vector2(420, 540)
	add_child(_card)
	var panel := TextureRect.new()
	panel.texture = load("res://assets/ui/wood_panel.png")
	panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(panel)

	var rows := [
		["RESUME", _on_resume_pressed],
		["RESTART", _on_restart_pressed],
		["MUSIC: ON", _toggle_music],
		["HIDE UI", _toggle_hide],
		["MAIN MENU", _on_menu_pressed],
	]
	for i in range(rows.size()):
		var b: Button = GameManager.wood_button(rows[i][0], 320, 64, false)
		b.position = Vector2(50, 70 + i * 82)
		b.name = "Row_%d" % i
		b.pressed.connect(rows[i][1])
		_card.add_child(b)
	_refresh_music()
	for i in range(rows.size()):
		UIJuice.bind_button(_card.get_node("Row_%d" % i))
	visibility_changed.connect(_on_shown)

func _on_shown() -> void:
	if not visible or _card == null: return
	UIJuice.pop_in(_card, 0.0, 0.2)
	for i in range(5):
		var b = _card.get_node_or_null("Row_%d" % i)
		if b: UIJuice.slide_in(b, Vector2(0, 18), 0.06 + 0.04 * i, 0.2)

func _refresh_music() -> void:
	var b = _card.get_node_or_null("Row_2")
	if b: b.text = "MUSIC: " + ("ON" if GameManager.music_on else "OFF")

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_resume_pressed()
		get_viewport().set_input_as_handled()

func _on_resume_pressed() -> void:
	GameManager.play_sfx("click")
	hide()
	get_tree().paused = false
	var lvl = get_tree().current_scene
	if lvl and lvl.has_method("apply_hide_ui"):
		lvl.apply_hide_ui(_ui_hidden)

func _on_restart_pressed() -> void:
	GameManager.play_sfx("click")
	get_tree().paused = false
	get_tree().reload_current_scene()

func _toggle_music() -> void:
	GameManager.music_on = not GameManager.music_on
	GameManager.apply_audio()
	GameManager.play_sfx("click")
	_refresh_music()

func _toggle_hide() -> void:
	_ui_hidden = not _ui_hidden
	GameManager.play_sfx("click")
	var b = _card.get_node_or_null("Row_3")
	if b: b.text = "SHOW UI" if _ui_hidden else "HIDE UI"

func _on_menu_pressed() -> void:
	GameManager.play_sfx("click")
	get_tree().paused = false
	GameManager.change_scene("res://scenes/Hub.tscn")
