extends Control
# Home hub after PLAY: STORY + mode tiles. Original art, no orange timer, no IAP.

func _ready() -> void:
	GameManager.play_music("menu")
	# painted Kyoto backdrop (same plate as the title, dimmed and hazed so the tiles read)
	var bg := TextureRect.new()
	bg.texture = load("res://assets/ui/menu_bg.png")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = Color(0.62, 0.66, 0.76)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var rg := GradientTexture2D.new(); rg.fill_from = Vector2(0, 0); rg.fill_to = Vector2(1, 0)
	var rgg := Gradient.new(); rgg.set_color(0, Color(0, 0, 0, 0)); rgg.set_color(1, Color(0.01, 0.01, 0.04, 0.75)); rg.gradient = rgg
	var rgr := TextureRect.new(); rgr.texture = rg; rgr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rgr.position = Vector2(420, 0); rgr.size = Vector2(860, 720); rgr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rgr)
	var mist := GameManager.make_mist(560, 24.0); mist.modulate = Color(1, 1, 1, 0.5)
	add_child(mist)
	# falling snow motes
	if GameManager.has_method("make_petals"):
		var pet = GameManager.make_petals(Vector2(700, 8), 40)
		pet.position = Vector2(640, -20)
		pet.modulate = Color(2.2, 2.2, 2.4)
		add_child(pet)

	# top currency strip (gold + gems only; no unconfirmed timer)
	var strip := TextureRect.new()
	strip.texture = load("res://assets/ui/currency_bar.png")
	strip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	strip.size = Vector2(1280, 52)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(strip)
	_icon_count(Vector2(24, 8), "hud_gold", "%d" % GameManager.total_coins, Color(0.80, 0.64, 0.23))
	_icon_count(Vector2(200, 8), "hud_gem", "%d" % GameManager.total_gems, Color(0.36, 0.78, 0.90))

	# large hero on the left (menu art may be modelled)
	var hero := TextureRect.new()
	hero.texture = load("res://assets/ui/hero_menu.png")
	hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.position = Vector2(40, 80)
	hero.size = Vector2(460, 620)
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(hero)

	# left column: SETTINGS, INFO
	_metal_btn("SETTINGS", Vector2(36, 70), Vector2(220, 48), _open_settings)
	_metal_btn("INFO", Vector2(36, 128), Vector2(220, 48), _open_info)

	# STORY painting
	var story := TextureButton.new()
	story.texture_normal = load("res://assets/ui/hub_story.png")
	story.ignore_texture_size = true
	story.stretch_mode = TextureButton.STRETCH_SCALE
	story.position = Vector2(560, 70)
	story.size = Vector2(680, 280)
	story.pressed.connect(_open_story)
	add_child(story)
	UIJuice.slide_in(story, Vector2(0, 24), 0.0)
	UIJuice.bind_button(story)
	var cap := Label.new()
	cap.text = "STORY"
	cap.position = Vector2(560, 70)
	cap.size = Vector2(680, 48)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_serif(cap, 30, Color(1.0, 0.90, 0.64))
	cap.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	cap.add_theme_constant_override("outline_size", 6)
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cap)

	# 2x2 mode tiles
	var tiles := [
		["SKILLS", "hub_skills", Vector2(560, 368), _open_meta.bind("skills")],
		["SHOP", "hub_shop", Vector2(910, 368), _open_meta.bind("shop")],
		["ARTIFACT", "hub_artifact", Vector2(560, 534), _open_meta.bind("artifact")],
		["CHALLENGE", "hub_challenge", Vector2(910, 534), _open_meta.bind("challenge")],
	]
	for t in tiles:
		var b := TextureButton.new()
		b.texture_normal = load("res://assets/ui/%s.png" % t[1])
		b.ignore_texture_size = true
		b.stretch_mode = TextureButton.STRETCH_SCALE
		b.position = t[2]
		b.size = Vector2(330, 150)
		b.pressed.connect(t[3])
		add_child(b)
		UIJuice.pop_in(b, 0.08 + 0.06 * tiles.find(t))
		UIJuice.bind_button(b)
		var lb := Label.new()
		lb.text = t[0]
		lb.position = t[2] + Vector2(8, 110)
		lb.size = Vector2(314, 36)
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_serif(lb, 22, Color(1.0, 0.92, 0.70))
		lb.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		lb.add_theme_constant_override("outline_size", 5)
		lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(lb)
		UIJuice.pop_in(lb, 0.08 + 0.06 * tiles.find(t))

func _icon_count(pos: Vector2, icon: String, text: String, col: Color) -> void:
	var ic := TextureRect.new()
	ic.texture = load("res://assets/ui/%s.png" % icon)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.position = pos; ic.size = Vector2(36, 36)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ic)
	var l := Label.new()
	l.text = text
	l.position = pos + Vector2(40, 2)
	l.size = Vector2(120, 36)
	_serif(l, 22, col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)

func _metal_btn(text: String, pos: Vector2, sz: Vector2, cb: Callable) -> void:
	var b := GameManager.wood_button(text, sz.x, sz.y, false)
	b.position = pos
	b.pressed.connect(cb)
	add_child(b)

func _serif(l: Label, size: int, col: Color) -> void:
	if ResourceLoader.exists("res://content/original/fonts/SourceSerifPro-Bold.ttf"):
		l.add_theme_font_override("font", load("res://content/original/fonts/SourceSerifPro-Bold.ttf"))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)

func _open_story() -> void:
	GameManager.play_sfx("click")
	GameManager.change_scene("res://scenes/LevelSelect.tscn")

func _open_settings() -> void:
	GameManager.play_sfx("click")
	GameManager.meta_mode = "settings"
	GameManager.change_scene("res://scenes/Meta.tscn")

func _open_info() -> void:
	GameManager.play_sfx("click")
	GameManager.meta_mode = "info"
	GameManager.change_scene("res://scenes/Meta.tscn")

func _open_meta(mode: String) -> void:
	GameManager.play_sfx("click")
	GameManager.meta_mode = mode
	GameManager.change_scene("res://scenes/Meta.tscn")
