extends Control
# Act select: cinematic preview + diamond stage nodes + a boss node. Not a grid list.

const ACTS := [
	{"name": "ACT 1", "subtitle": "Ash Snow", "preview": "preview_act1", "stages": [1, 2, 3], "boss": 4},
	{"name": "ACT 2", "subtitle": "Mist Hollow", "preview": "preview_act2", "stages": [5, 6, 7], "boss": 8},
	{"name": "ACT 3", "subtitle": "Night Palace", "preview": "preview_act3", "stages": [9, 10, 11], "boss": 12},
]

var act: int = 0

func _ready() -> void:
	GameManager.play_music("menu")
	# Retire the old grid/list chrome if the packed scene still has it.
	for n in ["ColorRect", "TitleLabel", "GridContainer", "BackButton"]:
		if has_node(n):
			get_node(n).hide()
			get_node(n).queue_free()
	act = clampi(int((GameManager.unlocked_level - 1) / 4), 0, 2)
	GameManager.current_act = act
	_build_bg()
	_rebuild()

func _build_bg() -> void:
	var bg := TextureRect.new()
	bg.texture = load("res://assets/ui/menu_bg.png")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = Color(0.42, 0.46, 0.55)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.name = "BG"
	add_child(bg)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.25)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var strip := TextureRect.new()
	strip.texture = load("res://assets/ui/top_strip.png")
	strip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	strip.size = Vector2(1280, 74)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(strip)

func _add(n: Node) -> void:
	n.set_meta("chrome", true)
	add_child(n)

func _rebuild() -> void:
	for c in get_children():
		if c.name != "BG" and not (c is TextureRect and c.modulate.a < 0.6):
			# keep bg + mist (first two after bg). Simpler: wipe all but first two.
			pass
	# Clear previous chrome; keep the painted backdrop.
	for c in get_children():
		if c.get_meta("chrome", false):
			c.queue_free()
	var A = ACTS[act]

	# top metal ACT banner + star / token totals + home
	var banner := Label.new()
	banner.text = A["name"]
	banner.position = Vector2(80, 16); banner.size = Vector2(260, 48)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_serif(banner, 30, Color(0.93, 0.90, 0.82))
	var bs := StyleBoxTexture.new()
	bs.texture = load("res://assets/ui/stage_banner.png")
	bs.texture_margin_left = 40; bs.texture_margin_right = 40
	bs.texture_margin_top = 18; bs.texture_margin_bottom = 18
	banner.add_theme_stylebox_override("normal", bs)
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.add_theme_color_override("font_color", Color(1.0, 0.92, 0.70))
	_add(banner)

	var stars := 0
	for k in GameManager.level_stars.keys():
		stars += int(GameManager.level_stars[k])
	var bosses := 0
	for b in [4, 8, 12]:
		if int(GameManager.level_stars.get(str(b), 0)) > 0: bosses += 1
	var sic := TextureRect.new()
	sic.texture = load("res://assets/ui/star_full.png")
	sic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sic.position = Vector2(372, 20); sic.size = Vector2(34, 34)
	sic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add(sic)
	var tot := Label.new()
	tot.text = "%d / 36" % stars
	tot.position = Vector2(412, 18); tot.size = Vector2(120, 40)
	_serif(tot, 22, Color(1.0, 0.88, 0.55))
	_add(tot)
	var bic := TextureRect.new()
	bic.texture = load("res://assets/ui/node_boss.png")
	bic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bic.position = Vector2(536, 14); bic.size = Vector2(44, 44)
	bic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add(bic)
	var tot2 := Label.new()
	tot2.text = "%d / 3" % bosses
	tot2.position = Vector2(584, 18); tot2.size = Vector2(100, 40)
	_serif(tot2, 22, Color(1.0, 0.70, 0.62))
	_add(tot2)

	var home := TextureButton.new()
	home.texture_normal = load("res://assets/ui/icon_home.png")
	home.ignore_texture_size = true
	home.stretch_mode = TextureButton.STRETCH_SCALE
	home.position = Vector2(1190, 10); home.size = Vector2(64, 64)
	home.pressed.connect(func():
		GameManager.play_sfx("click")
		GameManager.change_scene("res://scenes/Hub.tscn"))
	_add(home)

	# framed cinematic preview
	var prev := TextureRect.new()
	prev.texture = load("res://assets/ui/%s.png" % A["preview"])
	prev.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	prev.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	prev.position = Vector2(160, 84); prev.size = Vector2(960, 360)
	prev.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add(prev)

	var al := TextureButton.new()
	al.texture_normal = load("res://assets/ui/arrow_act_l.png")
	al.ignore_texture_size = true
	al.stretch_mode = TextureButton.STRETCH_SCALE
	al.position = Vector2(70, 200); al.size = Vector2(70, 110)
	al.pressed.connect(func(): act = (act + 2) % 3; GameManager.current_act = act; _rebuild())
	_add(al)
	var ar := TextureButton.new()
	ar.texture_normal = load("res://assets/ui/arrow_act_r.png")
	ar.ignore_texture_size = true
	ar.stretch_mode = TextureButton.STRETCH_SCALE
	ar.position = Vector2(1140, 200); ar.size = Vector2(70, 110)
	ar.pressed.connect(func(): act = (act + 1) % 3; GameManager.current_act = act; _rebuild())
	_add(ar)

	# bottom diamond nodes + boss node
	var stages: Array = A["stages"]
	var xs := [250, 470, 690]
	for i in range(stages.size()):
		_node(stages[i], Vector2(xs[i], 500), false)
	_node(A["boss"], Vector2(960, 500), true)

func _node(lvl: int, pos: Vector2, boss: bool) -> void:
	var unlocked := lvl <= GameManager.unlocked_level
	var b := TextureButton.new()
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_SCALE
	if boss:
		b.texture_normal = load("res://assets/ui/node_boss.png" if unlocked else "res://assets/ui/node_boss_lock.png")
	else:
		b.texture_normal = load("res://assets/ui/node_diamond.png" if unlocked else "res://assets/ui/node_lock.png")
	b.position = pos
	b.size = Vector2(120, 120)
	if unlocked:
		b.pressed.connect(func(): _enter(lvl))
	else:
		b.disabled = true
	_add(b)
	UIJuice.pop_in(b, 0.05 + pos.x / 4000.0)
	if unlocked: UIJuice.bind_button(b)
	if unlocked and not boss:
		var n := Label.new()
		n.text = str(lvl if lvl <= 3 else (lvl - 4 if lvl <= 7 else lvl - 8))
		# show act-local index 1,2,3 or the world number? Diamond nodes usually show stage numbers.
		# Use 1-3 per act for cleanliness, or the real level number. Real numbers (1,2,3,5...) are clearer.
		n.text = str(lvl)
		n.position = pos + Vector2(0, 32)
		n.size = Vector2(120, 56)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_serif(n, 32, Color(0.95, 0.95, 0.97))
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_add(n)
		UIJuice.pop_in(n, 0.05 + pos.x / 4000.0)
	# 3 stars under the diamond
	var won := int(GameManager.level_stars.get(str(lvl), 0))
	var row := HBoxContainer.new()
	row.position = pos + Vector2(18, 112)
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add(row)
	for k in range(3):
		var st := TextureRect.new()
		st.texture = load("res://assets/ui/star_full.png" if (unlocked and k < won) else "res://assets/ui/star_empty.png")
		st.custom_minimum_size = Vector2(22, 22)
		st.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		st.modulate = Color(1, 1, 1, 1 if unlocked else 0.45)
		row.add_child(st)

func _enter(lvl: int) -> void:
	GameManager.play_sfx("click")
	GameManager.goto_level(lvl)

func _serif(l: Label, size: int, col: Color) -> void:
	if ResourceLoader.exists("res://content/original/fonts/SourceSerifPro-Bold.ttf"):
		l.add_theme_font_override("font", load("res://content/original/fonts/SourceSerifPro-Bold.ttf"))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 5)
