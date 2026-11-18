extends Control
# Lightweight hub sub-screens. Original chrome, no fake IAP, no ads settings.

func _ready() -> void:
	GameManager.play_music("menu")
	var bg := TextureRect.new()
	bg.texture = load("res://assets/ui/menu_bg.png")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = Color(0.32, 0.34, 0.42)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var strip := TextureRect.new()
	strip.texture = load("res://assets/ui/top_strip.png")
	strip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	strip.size = Vector2(1280, 96)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(strip)
	# framed lacquer card for the honest placeholder copy
	var card := TextureRect.new()
	card.texture = load("res://assets/ui/meta_plate.png")
	card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card.position = Vector2(160, 120); card.size = Vector2(960, 520)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card)

	var home := TextureButton.new()
	home.texture_normal = load("res://assets/ui/icon_home.png")
	home.ignore_texture_size = true
	home.stretch_mode = TextureButton.STRETCH_SCALE
	home.position = Vector2(1190, 16); home.size = Vector2(64, 64)
	home.pressed.connect(func():
		GameManager.play_sfx("click")
		GameManager.change_scene("res://scenes/Hub.tscn"))
	add_child(home)

	wallet = Label.new(); wallet.position = Vector2(760, 26); wallet.size = Vector2(400, 40)
	wallet.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_serif(wallet, 26, Color(1.0, 0.86, 0.45)); add_child(wallet); _wallet()
	var mode: String = GameManager.meta_mode
	var title := Label.new()
	title.position = Vector2(80, 20); title.size = Vector2(800, 56)
	_serif(title, 38, Color(1.0, 0.90, 0.64))
	if ResourceLoader.exists("res://content/original/fonts/SourceSerifPro-Bold.ttf"):
		title.add_theme_font_override("font", load("res://content/original/fonts/SourceSerifPro-Bold.ttf"))
	title.add_theme_constant_override("outline_size", 6)
	add_child(title)

	match mode:
		"settings":
			title.text = "SETTINGS"
			_settings()
		"info":
			title.text = "INFO"
			_body("Move with the chevrons or A / D.\nJump: Space   Slash: J   Kunai: K\nDash: Shift (from Mist Hollow)\nDOMAIN: L — our unique rite.\nStars come from coins found in a stage.")
		"skills":
			title.text = "SKILLS"
			_skills()
		"shop":
			title.text = "SHOP"
			_shop()
		"artifact":
			title.text = "ARTIFACTS"
			_artifact()
		"challenge":
			title.text = "DAILY CHALLENGE"
			_challenge()
		"controls":
			title.text = "TOUCH LAYOUT"
			_controls()
		_:
			title.text = "INFO"
			_body("")

var wallet: Label
var info: Label
var _sel := ""

func _wallet() -> void:
	wallet.text = "COINS %d    GEMS %d" % [GameManager.total_coins, GameManager.total_gems]

func _info(pos := Vector2(200, 560), w := 880.0) -> void:
	info = Label.new(); info.position = pos; info.size = Vector2(w, 60); info.autowrap_mode = TextServer.AUTOWRAP_WORD
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_serif(info, 24 if GameManager.big_text else 20, Color(0.95, 0.92, 0.85)); add_child(info)

## Lacquer card button: title, sub line, state colour. Tween on press via UIJuice.
func _card(pos: Vector2, sz: Vector2, head: String, sub: String, state: String, icon_id: String = "") -> Button:
	var b := Button.new(); b.position = pos; b.size = sz; b.focus_mode = Control.FOCUS_ALL
	var sb := StyleBoxFlat.new(); sb.set_corner_radius_all(10); sb.set_border_width_all(3)
	var cols := {"owned": [Color(0.10, 0.20, 0.16, 0.92), Color(0.45, 0.9, 0.6)], "equipped": [Color(0.12, 0.22, 0.30, 0.95), Color(0.5, 0.85, 1.0)],
		"buyable": [Color(0.20, 0.13, 0.06, 0.92), Color(0.95, 0.75, 0.35)], "poor": [Color(0.12, 0.10, 0.09, 0.9), Color(0.5, 0.42, 0.3)],
		"locked": [Color(0.07, 0.07, 0.08, 0.9), Color(0.3, 0.3, 0.32)]}
	var c: Array = cols.get(state, cols["poor"])
	sb.bg_color = c[0]; sb.border_color = c[1]
	if GameManager.high_contrast: sb.set_border_width_all(5)
	for st in ["normal", "hover", "pressed", "focus"]: b.add_theme_stylebox_override(st, sb)
	var l := Label.new(); l.text = head + "\n" + sub; l.position = Vector2(10, 6); l.size = sz - Vector2(20, 12)
	# rich art pass: painted lacquer emblem on the left of the card (tools/gen_rich_ui.py)
	var ip := "res://assets/ui/icons/%s.png" % icon_id
	if icon_id != "" and ResourceLoader.exists(ip):
		var ic := TextureRect.new(); ic.texture = load(ip); ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; var isz := minf(sz.y - 16.0, 92.0)
		ic.position = Vector2(8, (sz.y - isz) * 0.5); ic.size = Vector2(isz, isz); ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if state == "locked": ic.modulate = Color(0.35, 0.35, 0.38)
		b.add_child(ic); l.position.x = isz + 14; l.size.x = sz.x - isz - 22
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD; l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_serif(l, 22 if GameManager.big_text else 19, Color(1, 0.95, 0.85) if state != "locked" else Color(0.55, 0.55, 0.58))
	b.add_child(l); add_child(b); UIJuice.bind_button(b); UIJuice.pop_in(b, fmod(0.03 * get_child_count(), 0.4))
	return b

func _reload() -> void:
	get_tree().reload_current_scene()

# ---------------- SKILLS: 3 branches x 3 tiers, tap to inspect, tap again to learn ----------------
func _skills() -> void:
	var bx := {"BLADE": 200, "SHADOW": 500, "SPIRIT": 800}
	for br in bx:
		var h := Label.new(); h.text = br; h.position = Vector2(bx[br], 128); h.size = Vector2(280, 30)
		h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; _serif(h, 24, Color(1, 0.86, 0.5)); add_child(h)
	for s in Progression.SKILLS:
		var st := Progression.skill_state(s["id"])
		var sub: String = "LEARNED" if st == "owned" else ("LOCKED" if st == "locked" else "%d coins" % s["cost"])
		var b := _card(Vector2(bx[s["branch"]], 168 + (s["tier"] - 1) * 128), Vector2(280, 108), s["name"], sub, st, s["id"])
		b.pressed.connect(func():
			GameManager.play_sfx("click")
			if _sel == s["id"] and st == "buyable":
				if Progression.buy_skill(s["id"]): GameManager.vibrate(30); _reload(); return
			_sel = s["id"]
			info.text = s["text"] + {"buyable": "   — tap again to learn", "poor": "   — need more coins", "locked": "   — learn the tier above first", "owned": ""}[st])
	_info()
	info.text = "Tap a skill to read it. Skills add effects; base moves stay as they are."

# ---------------- SHOP: health consumables + skins ----------------
func _shop() -> void:
	var sh: Dictionary = GameManager.meta["shop"]
	var i := 0
	var all := [{"id": "ashen", "kind": "skin", "name": "Ashen (default)", "cost": 0, "text": "The original moon-blue grade."}] + Progression.SHOP
	for it in all:
		var id: String = it["id"]; var st := "buyable"; var sub := "%d coins" % it["cost"]
		if it["kind"] == "skin" and id in sh["skins"]:
			st = "equipped" if sh["skin"] == id else "owned"; sub = "EQUIPPED" if st == "equipped" else "OWNED — tap to wear"
		elif it["kind"] == "consumable":
			sub += "   (have %d)" % int(sh[id])
			if GameManager.total_coins < int(it["cost"]): st = "poor"
		elif GameManager.total_coins < int(it["cost"]): st = "poor"
		var b := _card(Vector2(200 + (i % 3) * 300, 150 + (i / 3) * 170), Vector2(280, 150), it["name"], sub, st, id)
		if it.has("tint"): b.get_children().filter(func(n): return n is Label)[0].add_theme_color_override("font_color", Color(1, 1, 1) * it["tint"])
		b.pressed.connect(func():
			GameManager.play_sfx("click")
			if it["kind"] == "skin" and id in sh["skins"]: Progression.equip_skin(id); _reload(); return
			if _sel == id and st == "buyable":
				if Progression.buy_item(id): GameManager.vibrate(30); _reload(); return
			_sel = id; info.text = it["text"] + ("   — tap again to buy" if st == "buyable" else ("   — need more coins" if st == "poor" else "")))
		i += 1
	_info(Vector2(200, 500))
	info.text = "Coins come from stages, combos and the daily challenge. No real-money purchases."

# ---------------- ARTIFACTS: passives bought with gems, 2 slots ----------------
func _artifact() -> void:
	var ar: Dictionary = GameManager.meta["artifacts"]
	var slots := Label.new(); slots.text = "EQUIPPED %d / %d" % [ar["equipped"].size(), Progression.MAX_EQUIPPED]
	slots.position = Vector2(200, 128); slots.size = Vector2(880, 30); slots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_serif(slots, 24, Color(0.6, 0.85, 1.0)); add_child(slots)
	var i := 0
	for a in Progression.ARTIFACTS:
		var id: String = a["id"]; var st := "poor"; var sub := "%d gem%s" % [a["gems"], "" if a["gems"] == 1 else "s"]
		if id in ar["equipped"]: st = "equipped"; sub = "EQUIPPED — tap to remove"
		elif id in ar["owned"]: st = "owned"; sub = "OWNED — tap to equip"
		elif GameManager.total_gems >= int(a["gems"]): st = "buyable"
		var b := _card(Vector2(200 + (i % 2) * 450, 170 + (i / 2) * 170), Vector2(430, 150), a["name"], sub + "\n" + a["text"], st, id)
		b.pressed.connect(func():
			GameManager.play_sfx("click")
			if st in ["owned", "equipped"]:
				if not Progression.toggle_artifact(id): info.text = "Both slots are full. Remove one first."; return
				_reload(); return
			if st == "buyable" and _sel == id:
				Progression.unlock_artifact(id); _reload(); return
			_sel = id; info.text = a["text"] + ("   — tap again to unlock" if st == "buyable" else "   — gems come from bosses and challenge streaks"))
		i += 1
	_info(Vector2(200, 520))
	info.text = "Artifacts are passives. Equip up to two."

# ---------------- CHALLENGE: one seeded stage + rule per day ----------------
func _challenge() -> void:
	var dl := Progression.daily()
	var names := ["Ash Snow Gate", "Mist Hollow", "Lantern Row", "Rin's Moon Court", "Bamboo Veil", "Torii Falls Cave", "Kiyomizu Ledge", "Ember Shrine", "Willow Canal", "Frost Pagoda", "Night Palace", "Throne of Night"]
	_body("%s\n\nStage %d — %s\nRule: %s — %s\nReward: %d coins (every %d-day streak also pays a gem)\nStreak: %d day%s\n\n%s" % [dl["day"], dl["stage"], names[dl["stage"] - 1],
		dl["mod"]["name"], dl["mod"]["text"], Progression.CHALLENGE_REWARD, Progression.CHALLENGE_STREAK_GEM, dl["streak"], "" if dl["streak"] == 1 else "s",
		"CLEARED TODAY — come back tomorrow." if dl["done"] else ("Reach stage %d in the story to open today's challenge." % dl["stage"] if dl["stage"] > GameManager.unlocked_level else "")], Vector2(200, 150), 880)
	var go := GameManager.wood_button("START" if not dl["done"] else "PLAY AGAIN (no reward)", 420, 64, true)
	go.position = Vector2(430, 520)
	if dl["stage"] > GameManager.unlocked_level: go.disabled = true; go.text = "LOCKED"
	go.pressed.connect(func():
		GameManager.play_sfx("click")
		GameManager.challenge_active = not dl["done"]
		GameManager.goto_level(dl["stage"]))
	add_child(go); UIJuice.bind_button(go)

# ---------------- SETTINGS ----------------
func _settings() -> void:
	var y := 140.0
	var rows := [
		["MUSIC", func(): return "ON" if GameManager.music_on else "OFF", func(): GameManager.music_on = not GameManager.music_on; GameManager.apply_audio(); GameManager.save_game()],
		["CONTROL SIZE", func(): return {0.85: "SMALL", 1.0: "MEDIUM", 1.15: "LARGE"}.get(GameManager.control_scale, "MEDIUM"), func(): GameManager.control_scale = {0.85: 1.0, 1.0: 1.15, 1.15: 0.85}.get(GameManager.control_scale, 1.0)],
		["LEFT-HANDED", func(): return "ON" if GameManager.left_handed else "OFF", func(): GameManager.left_handed = not GameManager.left_handed],
		["REDUCED MOTION", func(): return "ON" if GameManager.reduced_motion else "OFF", func(): GameManager.reduced_motion = not GameManager.reduced_motion],
		["HAPTICS", func(): return "ON" if GameManager.haptics else "OFF", func(): GameManager.haptics = not GameManager.haptics; GameManager.vibrate(40)],
		["LARGE TEXT", func(): return "ON" if GameManager.big_text else "OFF", func(): GameManager.big_text = not GameManager.big_text],
		["HIGH CONTRAST", func(): return "ON" if GameManager.high_contrast else "OFF", func(): GameManager.high_contrast = not GameManager.high_contrast],
	]
	for i in range(rows.size()):
		var r: Array = rows[i]
		var b := GameManager.wood_button("%s: %s" % [r[0], r[1].call()], 420, 54, false)
		b.position = Vector2(200 if i < 4 else 660, 150 + (i % 4) * 66)
		b.pressed.connect(func():
			r[2].call(); GameManager.save_settings(); GameManager.play_sfx("click")
			b.text = "%s: %s" % [r[0], r[1].call()])
		add_child(b); UIJuice.bind_button(b)
	# volume sliders
	for k in [["MUSIC VOL", "music_vol"], ["SFX VOL", "sfx_vol"]]:
		var yy := 418.0 if k[1] == "music_vol" else 462.0
		var lab := Label.new(); lab.text = k[0]; lab.position = Vector2(660, yy); lab.size = Vector2(140, 34); _serif(lab, 20, Color(1, 0.9, 0.7)); add_child(lab)
		var sl := HSlider.new(); sl.min_value = 0.0; sl.max_value = 1.0; sl.step = 0.05; sl.value = GameManager.get(k[1])
		sl.position = Vector2(800, yy + 6); sl.size = Vector2(280, 24)
		sl.value_changed.connect(func(v):
			GameManager.set(k[1], v); GameManager.apply_audio(); GameManager.save_settings()
			if k[1] == "sfx_vol": GameManager.play_sfx("click"))
		add_child(sl)
	var ed := GameManager.wood_button("EDIT TOUCH LAYOUT", 420, 54, true); ed.position = Vector2(200, 418)
	ed.pressed.connect(func(): GameManager.play_sfx("click"); GameManager.meta_mode = "controls"; GameManager.change_scene("res://scenes/Meta.tscn", "fade"))
	add_child(ed); UIJuice.bind_button(ed)
	var rst := GameManager.wood_button("RESET STAGES", 420, 54, false); rst.position = Vector2(200, 484)
	rst.pressed.connect(func():
		GameManager.play_sfx("click")
		if rst.text != "TAP AGAIN TO CONFIRM": rst.text = "TAP AGAIN TO CONFIRM"; return
		GameManager.unlocked_level = 1; GameManager.level_stars = {}; GameManager.total_coins = 0; GameManager.total_gems = 0
		GameManager.meta = SaveData.meta_defaults(); GameManager.save_game()
		GameManager.change_scene("res://scenes/Hub.tscn"))
	add_child(rst)
	var cl := GameManager.wood_button("CLOSE", 420, 54, false); cl.position = Vector2(660, 540)
	cl.pressed.connect(func(): GameManager.play_sfx("click"); GameManager.change_scene("res://scenes/Hub.tscn"))
	add_child(cl); UIJuice.bind_button(cl)

# ---------------- TOUCH LAYOUT EDITOR ----------------
var _tc: Control
func _controls() -> void:
	for c in get_children():
		if c is TextureRect and c.texture == load("res://assets/ui/meta_plate.png"): c.visible = false
	var zone := ColorRect.new(); zone.color = Color(0.8, 0.15, 0.1, 0.18)
	zone.position = Vector2(380, 0); zone.size = Vector2(520, 720); zone.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(zone)
	var band := ColorRect.new(); band.color = Color(0.8, 0.15, 0.1, 0.12); band.position = Vector2(0, 96); band.size = Vector2(1280, 104)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(band)
	var zl := Label.new(); zl.text = "HERO / BOSS ZONE\ncontrols can't be placed here"; zl.position = Vector2(380, 300); zl.size = Vector2(520, 80)
	zl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; _serif(zl, 24, Color(1, 0.7, 0.6)); add_child(zl)
	var hero := TextureRect.new(); hero.texture = load("res://assets/sprites/hero/idle.png") if ResourceLoader.exists("res://assets/sprites/hero/idle.png") else null
	hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.position = Vector2(580, 420); hero.size = Vector2(120, 160); hero.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(hero)
	_tc = load("res://scripts/TouchControls.gd").new(); _tc.edit_mode = true; _tc.force_visible = true
	_tc.set_anchors_preset(Control.PRESET_FULL_RECT); _tc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tc)
	var gear = _tc.get_node_or_null("Btn_pause")
	if gear: gear.visible = false
	var hint := Label.new(); hint.text = "Drag a button to move it. Default = SPEC layout."; hint.position = Vector2(200, 100); hint.size = Vector2(880, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; _serif(hint, 22, Color(0.95, 0.92, 0.85)); add_child(hint)
	var y := 210.0
	for t in [["SAVE", func(): GameManager.touch_layout = _tc.current_layout(); GameManager.save_settings(); GameManager.change_scene("res://scenes/Hub.tscn")],
			["RESET TO DEFAULT", func(): GameManager.touch_layout = {}; GameManager.save_settings(); _reload()],
			["CANCEL", func(): GameManager.change_scene("res://scenes/Hub.tscn")]]:
		var b := GameManager.wood_button(t[0], 300, 52, t[0] == "SAVE"); b.position = Vector2(490, y); y += 62
		var cb: Callable = t[1]
		b.pressed.connect(func(): GameManager.play_sfx("click"); cb.call())
		add_child(b)

func _art(tex: String) -> void:
	var a := TextureRect.new()
	a.texture = load("res://assets/ui/%s.png" % tex)
	a.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	a.position = Vector2(720, 170); a.size = Vector2(360, 164)
	a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(a)

func _body(text: String, pos := Vector2(200, 140), width := 880.0) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos; l.size = Vector2(width, 400)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	_serif(l, 26, Color(0.90, 0.90, 0.92))
	add_child(l)

func _serif(l: Label, size: int, col: Color) -> void:
	if ResourceLoader.exists("res://content/original/fonts/SourceSerifPro-Regular.ttf"):
		l.add_theme_font_override("font", load("res://content/original/fonts/SourceSerifPro-Regular.ttf"))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 4)
