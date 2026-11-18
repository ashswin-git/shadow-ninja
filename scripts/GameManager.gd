extends Node

const SAVE_PATH = "user://shadow_ninja_save.json"

var current_level: int = 1
var unlocked_level: int = 1
var level_stars: Dictionary = {} # level_num -> int (0-3)
var total_coins: int = 0
var total_gems: int = 0
var music_on: bool = true
var meta_mode: String = "info"
var current_act: int = 0
## Settings live in their own file (not the save). Phase 4 adds volumes, control size,
## left-handed mirror, haptics, text size, high contrast and a remappable touch layout.
const SETTINGS_PATH = "user://shadow_ninja_settings.cfg"
var reduced_motion: bool = false
var music_vol: float = 0.8
var sfx_vol: float = 1.0
var control_scale: float = 1.0      # 0.85 / 1.0 / 1.15
var left_handed: bool = false
var haptics: bool = true
var big_text: bool = false
var high_contrast: bool = false
var touch_layout: Dictionary = {}   # action -> Vector2 centre; empty = SPEC §5 default
## Phase 4 save meta (skills, shop, artifacts, challenge, stats) — see scripts/meta/save_data.gd
var meta: Dictionary = SaveData.meta_defaults()
var challenge_active := false

func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("display", "reduced_motion", reduced_motion)
	cf.set_value("display", "big_text", big_text)
	cf.set_value("display", "high_contrast", high_contrast)
	cf.set_value("audio", "music_vol", music_vol)
	cf.set_value("audio", "sfx_vol", sfx_vol)
	cf.set_value("controls", "scale", control_scale)
	cf.set_value("controls", "left_handed", left_handed)
	cf.set_value("controls", "haptics", haptics)
	cf.set_value("controls", "layout", touch_layout)
	cf.save(SETTINGS_PATH)

func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(SETTINGS_PATH) == OK:
		reduced_motion = bool(cf.get_value("display", "reduced_motion", false))
		big_text = bool(cf.get_value("display", "big_text", false))
		high_contrast = bool(cf.get_value("display", "high_contrast", false))
		music_vol = float(cf.get_value("audio", "music_vol", 0.8))
		sfx_vol = float(cf.get_value("audio", "sfx_vol", 1.0))
		control_scale = float(cf.get_value("controls", "scale", 1.0))
		left_handed = bool(cf.get_value("controls", "left_handed", false))
		haptics = bool(cf.get_value("controls", "haptics", true))
		touch_layout = cf.get_value("controls", "layout", {})
	apply_audio()

func vibrate(ms: int = 30) -> void:
	if haptics and OS.has_feature("mobile"): Input.vibrate_handheld(ms)

var audio_pool: Array[AudioStreamPlayer] = []
var pool_index: int = 0
const POOL_SIZE = 12

func _ready() -> void:
	if not InputMap.has_action("domain"):
		InputMap.add_action("domain")
		var k = InputEventKey.new(); k.physical_keycode = KEY_L
		InputMap.action_add_event("domain", k)
	if not InputMap.has_action("attack"):
		InputMap.add_action("attack")
		var k2 = InputEventKey.new(); k2.physical_keycode = KEY_J
		InputMap.action_add_event("attack", k2)
	# J was bound to both dash and attack: dash -> Shift / I, attack keeps J
	for ev in InputMap.action_get_events("dash"):
		if ev is InputEventKey and ev.physical_keycode == KEY_J: InputMap.action_erase_event("dash", ev)
	for kc in [KEY_SHIFT, KEY_I]:
		var kd = InputEventKey.new(); kd.physical_keycode = kc; InputMap.action_add_event("dash", kd)
	# project.godot events carried mismatched keycode+physical pairs (e.g. Right+D, Enter+Space),
	# so A/D/Space never fired on desktop/web. Add explicit physical bindings.
	var binds = {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE, KEY_W, KEY_UP], "attack": [KEY_J], "throw": [KEY_K], "domain": [KEY_L]}
	for a in binds:
		if not InputMap.has_action(a): InputMap.add_action(a)
		for kc in binds[a]:
			var e2 = InputEventKey.new(); e2.physical_keycode = kc; InputMap.action_add_event(a, e2)
	load_game()
	load_settings()
	for i in range(POOL_SIZE):
		var p = AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		audio_pool.append(p)
	music = MusicDirector.new(); music.name = "Music"; add_child(music)

func save_game() -> void:
	SaveData.save_file(SAVE_PATH, save_dict())

func save_dict() -> Dictionary:
	return {"version": SaveData.CURRENT_VERSION, "unlocked_level": unlocked_level, "level_stars": level_stars,
		"total_coins": total_coins, "total_gems": total_gems, "music_on": music_on, "meta": meta}

func load_game(path: String = SAVE_PATH) -> void:
	apply_save(SaveData.load_file(path))

func apply_save(d: Dictionary) -> void:
	unlocked_level = int(d.get("unlocked_level", 1))
	level_stars = d.get("level_stars", {})
	total_coins = int(d.get("total_coins", 0))
	total_gems = int(d.get("total_gems", 0))
	music_on = bool(d.get("music_on", true))
	meta = d.get("meta", SaveData.meta_defaults())
	apply_audio()

func complete_level(lvl: int, stars: int, coins: int) -> void:
	if lvl >= unlocked_level and lvl <= 12:
		unlocked_level = lvl + 1
	var prev_stars = level_stars.get(str(lvl), 0)
	if stars > prev_stars:
		level_stars[str(lvl)] = stars
	total_coins += coins
	if lvl in [4, 8, 12]:
		total_gems += 1
	save_game()

## Phase 5: CC0 SFX (assets/audio/sfx/*.ogg, Kenney) first, original .wav fallback.
## Streams are cached; players are a fixed pool on the "SFX" bus (volume = Settings SFX slider).
var _sfx_cache := {}
func play_sfx(name: String, pitch_jitter := 0.06) -> void:
	var st = _sfx_cache.get(name)
	if st == null:
		for path in ["res://assets/audio/sfx/%s.ogg" % name, "res://assets/audio/%s.wav" % name]:
			if ResourceLoader.exists(path): st = load(path); break
		_sfx_cache[name] = st if st != null else false
	if not st or DisplayServer.get_name() == "headless": return   # Dummy driver: see MusicDirector.play
	var player = audio_pool[pool_index]
	pool_index = (pool_index + 1) % POOL_SIZE
	player.stream = st
	player.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	player.play()

var music: MusicDirector
func play_music(track: String) -> void:
	if music: music.play(track)

func music_bus_db() -> float:
	return linear_to_db(maxf(music_vol, 0.001)) if music_on else -80.0

func add_menu_bg(root: Control) -> void:
	# Painted Kyoto title vista (original art made for this game) + painted hero, mist and snow.
	if root.has_node("ColorRect"):
		root.get_node("ColorRect").visible = false
	var n = 0
	var t = TextureRect.new()
	t.texture = load("res://assets/ui/menu_bg.png")
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(t); root.move_child(t, n); n += 1
	# slow cinematic drift on the painting
	t.pivot_offset = Vector2(640, 360)
	var dtw = t.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	dtw.tween_property(t, "scale", Vector2(1.04, 1.04), 9.0); dtw.tween_property(t, "scale", Vector2(1.0, 1.0), 9.0)
	# cold spirit aura behind the hero
	var gt = GradientTexture2D.new(); gt.fill = GradientTexture2D.FILL_RADIAL; gt.fill_from = Vector2(0.5, 0.5); gt.fill_to = Vector2(1.0, 0.5)
	var g = Gradient.new(); g.set_color(0, Color(0.30, 0.55, 1.0, 0.55)); g.set_color(1, Color(0.1, 0.2, 0.6, 0.0)); gt.gradient = g
	var glow = TextureRect.new(); glow.texture = gt; glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.position = Vector2(360, 120); glow.size = Vector2(560, 600); glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(glow); root.move_child(glow, n); n += 1
	var gtw = glow.create_tween().set_loops(); gtw.tween_property(glow, "modulate:a", 0.6, 2.2); gtw.tween_property(glow, "modulate:a", 1.0, 2.2)
	# left-side darkening so the framed title reads
	var lg = GradientTexture2D.new(); lg.fill_from = Vector2(0, 0); lg.fill_to = Vector2(1, 0)
	var lgg = Gradient.new(); lgg.set_color(0, Color(0.01, 0.02, 0.05, 0.65)); lgg.set_color(1, Color(0, 0, 0, 0)); lg.gradient = lgg
	var lgr = TextureRect.new(); lgr.texture = lg; lgr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lgr.position = Vector2(0, 0); lgr.size = Vector2(620, 720); lgr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(lgr); root.move_child(lgr, n); n += 1
	var hero = TextureRect.new(); hero.name = "MenuHero"; hero.texture = load("res://assets/ui/hero_menu.png"); hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; hero.size = Vector2(420, 480); hero.position = Vector2(210, 200)
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE; hero.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	root.add_child(hero); root.move_child(hero, n); n += 1
	var htw = hero.create_tween().set_loops().set_trans(Tween.TRANS_SINE); htw.tween_property(hero, "position:y", 194.0, 1.6); htw.tween_property(hero, "position:y", 206.0, 1.6)
	var vg = GradientTexture2D.new(); vg.fill = GradientTexture2D.FILL_RADIAL; vg.fill_from = Vector2(0.5, 0.45); vg.fill_to = Vector2(1.05, 1.05)
	var vgg = Gradient.new(); vgg.set_color(0, Color(0, 0, 0, 0)); vgg.set_color(1, Color(0, 0, 0.02, 0.55)); vgg.add_point(0.55, Color(0, 0, 0, 0)); vg.gradient = vgg
	var shade = TextureRect.new(); shade.texture = vg; shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade); root.move_child(shade, n)
	var mist = make_mist(520, 30.0); mist.modulate = Color(1, 1, 1, 0.55); root.add_child(mist); root.move_child(mist, n + 1)
	var pet = make_petals(Vector2(700, 10)); pet.position = Vector2(700, -20); pet.modulate = Color(3, 3, 3); root.add_child(pet); root.move_child(pet, n + 2)

func make_petals(extent: Vector2, amount: int = 60) -> CPUParticles2D:
	var p = CPUParticles2D.new()
	p.texture = load("res://assets/sprites/petal.png")
	p.amount = amount; p.lifetime = 9.0; p.preprocess = 9.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = extent
	p.direction = Vector2(-0.4, 1); p.spread = 25.0
	p.gravity = Vector2(-10, 18)
	p.initial_velocity_min = 25.0; p.initial_velocity_max = 60.0
	p.angular_velocity_min = -90.0; p.angular_velocity_max = 90.0
	p.angle_min = 0.0; p.angle_max = 360.0
	p.scale_amount_min = 0.6; p.scale_amount_max = 1.3
	p.color = Color(1, 1, 1, 0.9)
	return p

func make_mist(y: float, speed: float) -> Node2D:
	var n = Node2D.new()
	for i in range(2):
		var sp = Sprite2D.new(); sp.texture = load("res://assets/backgrounds/bg_mist.png")
		sp.centered = false; sp.position = Vector2(i * 1280, y); n.add_child(sp)
	var tw = n.create_tween().set_loops()
	tw.tween_property(n, "position:x", -1280.0, 1280.0 / speed).from(0.0)
	return n

# ---- Capture / demo driver (only active with user args) ----
var _cap_args: PackedStringArray
var _t := 0.0
func _process(delta: float) -> void:
	if not OS.is_debug_build():
		set_process(false); return
	if _cap_args.is_empty():
		_cap_args = OS.get_cmdline_user_args()
		if _cap_args.is_empty(): _cap_args = PackedStringArray(["none"])
		_cap_start()
	if "--autoplay" in _cap_args:
		_autoplay(delta)

func _cap_start() -> void:
	for a in _cap_args:
		if a.begins_with("--shot="):
			var what = a.substr(7)
			match what:
				"select": get_tree().change_scene_to_file.call_deferred("res://scenes/LevelSelect.tscn")
				"hub": get_tree().change_scene_to_file.call_deferred("res://scenes/Hub.tscn")
				"l1": current_level = 1; get_tree().change_scene_to_file.call_deferred("res://scenes/Level.tscn")
				"domain": current_level = 1; get_tree().change_scene_to_file.call_deferred("res://scenes/Level.tscn")
				"l2": current_level = 2; get_tree().change_scene_to_file.call_deferred("res://scenes/Level.tscn")
				"ctltest": current_level = 2; get_tree().change_scene_to_file.call_deferred("res://scenes/Level.tscn"); _ctl_test(); return
				"dmgtest": current_level = 4; get_tree().change_scene_to_file.call_deferred("res://scenes/Level.tscn"); _dmg_test(); return
				"boss": current_level = 4; get_tree().change_scene_to_file.call_deferred("res://scenes/Level.tscn")
				"pause": current_level = 1; get_tree().change_scene_to_file.call_deferred("res://scenes/Level.tscn")
				"ko": current_level = 4; get_tree().change_scene_to_file.call_deferred("res://scenes/Level.tscn")
				"results": current_level = 1; get_tree().change_scene_to_file.call_deferred("res://scenes/Level.tscn")
				"resultsboss": current_level = 4; get_tree().change_scene_to_file.call_deferred("res://scenes/Level.tscn")
				"loading": _shot_loading(); return
				"skills", "shop", "artifact", "challenge", "settings":
					meta_mode = what; get_tree().change_scene_to_file.call_deferred("res://scenes/Meta.tscn")
			_shoot_later(ProjectSettings.globalize_path("res://ui-mockups/") + "real_%s.png" % what)
	if "--autoplay" in _cap_args:
		current_level = 1
		get_tree().change_scene_to_file.call_deferred("res://scenes/Level.tscn")
	if "--showcase" in _cap_args:
		_showcase()
	if "--phase1" in _cap_args:
		_phase1_showcase()
	if "--phase2" in _cap_args:
		_phase2_showcase()
	if "--phase3" in _cap_args:
		_phase3_showcase()
	if "--phase4" in _cap_args:
		_phase4_showcase()
	if "--phase5" in _cap_args:
		_phase5_showcase()
	if "--release" in _cap_args:
		_release_showcase()
	for a in _cap_args:
		if a.begins_with("--clip="): _clip(int(a.substr(7)))
	for a in _cap_args:
		if a.begins_with("--runthrough="): _runthrough(int(a.substr(13)))

func _shoot_later(path: String) -> void:
	# Time-based wait so llvmpipe (low FPS) still catches the level-name banner.
	await get_tree().create_timer(0.35 if "--early" in _cap_args else 0.85, true, false, true).timeout
	if "--early" in _cap_args: path = path.replace(".png", "_toast.png")
	if "--move" in _cap_args:
		Input.action_press("move_right")
		for i in range(25): await get_tree().process_frame
		Input.action_press("jump")
		for i in range(14): await get_tree().process_frame
		Input.action_release("jump"); Input.action_release("move_right")
	if "--front" in _cap_args:
		var lvl = get_tree().current_scene
		var pl = lvl.get_node_or_null("Player")
		if pl:
			var cam = pl.get_node_or_null("Camera2D")
			var center := Vector2(640, 360)
			if cam:
				center = cam.get_screen_center_position()
				# Freeze the camera so the player can walk into the on-screen button cluster.
				var hold = Camera2D.new()
				hold.global_position = center
				lvl.add_child(hold)
				hold.make_current()
			pl.global_position = Vector2(center.x + 470, pl.global_position.y)
			await get_tree().create_timer(0.2, true, false, true).timeout
	if "--domain" in _cap_args:
		Input.action_press("domain")
		for i in range(2): await get_tree().process_frame
		Input.action_release("domain")
		for i in range(14): await get_tree().process_frame
		if "--late" in _cap_args:
			for i in range(48): await get_tree().process_frame
	for a in _cap_args:
		if a.begins_with("--waitms="):
			await get_tree().create_timer(float(a.substr(9)) / 1000.0, true, false, true).timeout
	var what := ""
	for a in _cap_args:
		if a.begins_with("--shot="): what = a.substr(7)
	var lvl = get_tree().current_scene
	if what == "pause" and lvl and lvl.has_method("open_pause"):
		lvl.open_pause()
		await get_tree().create_timer(0.25, true, false, true).timeout
	if what == "ko" and lvl and lvl.has_method("show_ko"):
		lvl.show_ko(false)
		await get_tree().create_timer(0.35, true, false, true).timeout
	if what in ["results", "resultsboss"] and lvl and lvl.has_method("show_results"):
		lvl.show_results(3, what == "resultsboss")
		await get_tree().create_timer(0.35, true, false, true).timeout
	if "--attack" in _cap_args:
		Input.action_press("attack")
		for i in range(2): await get_tree().physics_frame
		Input.action_release("attack")
		for i in range(4): await get_tree().physics_frame
	var plp = get_tree().current_scene.get_node_or_null("Player") if get_tree().current_scene else null
	if plp: print("SHOT player screen pos ", plp.get_global_transform_with_canvas().origin)
	for a in _cap_args:
		if a.begins_with("--settle="):
			await get_tree().create_timer(float(a.substr(9)) / 1000.0, true, false, true).timeout
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()

var _phase := -1
var _vic := 0.0
func _autoplay(delta: float) -> void:
	_t += delta
	var acts = ["move_left", "move_right", "jump", "dash", "throw", "domain", "attack"]
	for a in acts: Input.action_release(a)
	var t = fmod(_t, 10.0)
	var lvl = 1 if _t < 10.0 else (2 if _t < 18.0 else 4)
	if lvl != current_level and _t < 30.0:
		current_level = lvl
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/Level.tscn")
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	if get_tree().paused and _t < 30.0:
		_vic += delta
		if _vic > 1.5:
			_vic = 0.0; get_tree().paused = false
			_t = 10.0 if _t < 10.0 else (18.0 if _t < 18.0 else _t)
		return
	_vic = 0.0
	if fmod(_t * 10.0, 4.0) < 1.0: Input.action_press("attack")
	if fmod(t, 6.0) < 3.8: Input.action_press("move_right")
	else: Input.action_press("move_left")
	if fmod(t, 1.1) < 0.12: Input.action_press("jump")
	if fmod(t, 3.3) < 0.05: Input.action_press("throw")
	if fmod(t, 4.7) < 0.05: Input.action_press("dash")
	if fmod(t, 7.0) > 2.0 and fmod(t, 7.0) < 2.05: Input.action_press("domain")
	if lvl == 4: Input.action_release("move_left"); Input.action_release("move_right"); Input.action_press("move_right" if fmod(t, 4.0) < 2.0 else "move_left")
	if _t > 30.5: get_tree().quit()

func _dmg_test() -> void:
	for i in range(30): await get_tree().process_frame
	var lvl = get_tree().current_scene
	var pl = lvl.get_node("Player"); var b = get_tree().get_nodes_in_group("Bosses")[0]
	var e = preload("res://scenes/Enemy.tscn").instantiate() if ResourceLoader.exists("res://scenes/Enemy.tscn") else null
	if e: lvl.add_child(e); e.global_position = b.global_position + Vector2(-120, 0)
	pl.global_position = b.global_position + Vector2(-150, 0)
	var bh = b.health; var eh = e.health if e else -1
	pl.cast_domain()
	for i in range(60): await get_tree().process_frame
	print("DMGTEST boss ", bh, " -> ", b.health if is_instance_valid(b) else "dead", " enemy ", eh, " -> ", (e.health if is_instance_valid(e) else "dead"))
	get_tree().quit()

# Dev-only (--shot=ctltest): drive SPEC section 5 bindings with real key events and the
# touch buttons' own signals, print what the player did, then quit.
func _ctl_key(kc: int, hold_frames := 6) -> void:
	var e := InputEventKey.new(); e.physical_keycode = kc; e.keycode = kc; e.pressed = true
	Input.parse_input_event(e)
	for i in range(hold_frames): await get_tree().physics_frame
	var r := InputEventKey.new(); r.physical_keycode = kc; r.keycode = kc; r.pressed = false
	Input.parse_input_event(r)
	for i in range(2): await get_tree().physics_frame

func _ctl_floor(pl) -> void:
	for i in range(240):
		if pl.is_on_floor() and not pl.is_dashing: break
		await get_tree().physics_frame
	for i in range(4): await get_tree().physics_frame

func _ctl_test() -> void:
	for i in range(40): await get_tree().process_frame
	var lvl = get_tree().current_scene
	var pl = lvl.get_node("Player")
	var states := {}
	pl.anim.state_changed.connect(func(ns, _o): states[PlayerAnimator.State.keys()[ns]] = true)
	var res := []
	for kc in [KEY_A, KEY_LEFT]:
		await _ctl_floor(pl); await _ctl_key(kc, 8); res.append(["move_left %s" % OS.get_keycode_string(kc), pl.velocity.x < 0.0 or pl.facing < 0])
	for kc in [KEY_D, KEY_RIGHT]:
		await _ctl_floor(pl); await _ctl_key(kc, 8); res.append(["move_right %s" % OS.get_keycode_string(kc), pl.facing > 0])
	for kc in [KEY_SPACE, KEY_W, KEY_UP]:
		await _ctl_floor(pl)
		var y0: float = pl.global_position.y
		await _ctl_key(kc, 3)
		for i in range(6): await get_tree().physics_frame
		res.append(["jump %s" % OS.get_keycode_string(kc), pl.global_position.y < y0 - 4.0])
	await _ctl_floor(pl)
	for i in range(20): await get_tree().physics_frame
	await _ctl_key(KEY_J, 2); res.append(["slash J", pl.slash_cd > 0.0])
	var spawned := [0]
	var on_child := func(n): if n.get_script() == preload("res://scripts/Shuriken.gd") and not n.is_enemy_projectile: spawned[0] += 1
	lvl.child_entered_tree.connect(on_child)
	await _ctl_key(KEY_K, 2)
	lvl.child_entered_tree.disconnect(on_child)
	res.append(["kunai K", spawned[0] > 0])
	# DOMAIN key (freezes the tree for the cut-in), then Escape
	await _ctl_floor(pl)
	var dcd0: float = pl.domain_cd
	await _ctl_key(KEY_L, 2); res.append(["domain L (cd %.2f -> %.2f)" % [dcd0, pl.domain_cd], pl.domain_cd > 0.0])
	await get_tree().create_timer(1.2, true, false, true).timeout
	var pm = lvl.get_node_or_null("CanvasLayer/PauseMenu")
	var was_paused := get_tree().paused
	await _ctl_key(KEY_ESCAPE, 2)
	await get_tree().create_timer(0.1, true, false, true).timeout
	res.append(["pause Esc (before paused=%s; after menu visible=%s paused=%s)" % [was_paused, pm.visible if pm else null, get_tree().paused], pm != null and pm.visible and get_tree().paused])
	if pm: pm._on_resume_pressed()
	await get_tree().create_timer(0.1, true, false, true).timeout
	for kc in [KEY_SHIFT, KEY_I]:
		await _ctl_floor(pl)
		var e := InputEventKey.new(); e.physical_keycode = kc; e.keycode = kc; e.pressed = true; Input.parse_input_event(e)
		var dashing := false
		for i in range(20):
			await get_tree().physics_frame
			if pl.is_dashing: dashing = true; break
		var r := InputEventKey.new(); r.physical_keycode = kc; r.keycode = kc; r.pressed = false; Input.parse_input_event(r)
		res.append(["dash %s (paused=%s)" % [OS.get_keycode_string(kc), get_tree().paused], dashing])
		for i in range(20): await get_tree().physics_frame
	# touch: emit each on-screen button's own signals
	var tc = lvl.get_node_or_null("TouchLayer/TouchControls")
	for act in ["move_left", "move_right", "jump", "attack", "dash", "domain", "throw"]:
		var b = tc.get_node_or_null("Btn_" + act) if tc else null
		if b == null: res.append(["touch %s" % act, "no button"]); continue
		b.button_down.emit(); await get_tree().process_frame
		var held := Input.is_action_pressed(act)
		b.button_up.emit(); await get_tree().process_frame
		res.append(["touch %s" % act, held])
	await get_tree().create_timer(1.2, true, false, true).timeout
	var gear = tc.get_node_or_null("Btn_pause") if tc else null
	if gear == null and tc:
		for c in tc.get_children():
			if c is Button and c.name.to_lower().contains("gear"): gear = c
	if gear: gear.pressed.emit(); await get_tree().create_timer(0.1, true, false, true).timeout
	res.append(["pause gear", gear != null and pm != null and pm.visible])
	# reduced-motion gating
	pl.shake_duration = 0.0; pl.trigger_shake(10.0, 0.2)
	var hud = lvl.get_node_or_null("CanvasLayer/HUD")
	if hud and hud.has_meta("_juice_shake_tw"): hud.remove_meta("_juice_shake_tw")
	UIJuice.shake(hud, 6.0, 0.2)
	print("CTLTEST reduced_motion=%s camera_shake_started=%s hud_shake_started=%s" % [reduced_motion, pl.shake_duration > 0.0, hud != null and hud.has_meta("_juice_shake_tw")])
	for r in res: print("CTLTEST ", r[0], " -> ", r[1])
	print("CTLTEST animator states seen: ", states.keys())
	get_tree().quit()

func style_button(b: Button, w := 320.0, h := 72.0) -> void:
	# NA2-style menu button: dark translucent plate, thin silver rules top/bottom, ornate diamond ends.
	b.custom_minimum_size = Vector2(w, h)
	b.add_theme_font_size_override("font_size", 30)
	for st in ["normal", "hover", "pressed", "focus"]:
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.02, 0.02, 0.05, 0.55)
		if st == "hover" or st == "focus": sb.bg_color = Color(0.45, 0.04, 0.14, 0.75)
		if st == "pressed": sb.bg_color = Color(0.7, 0.06, 0.2, 0.9)
		sb.border_color = Color(0.92, 0.94, 0.98, 0.9); sb.border_width_top = 2; sb.border_width_bottom = 2
		sb.content_margin_left = 40; sb.content_margin_right = 40
		b.add_theme_stylebox_override(st, sb)
	b.add_theme_color_override("font_color", Color(0.96, 0.96, 1))
	b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0)); b.add_theme_constant_override("outline_size", 6)
	for side in [0, 1]:
		var d = Polygon2D.new(); d.polygon = PackedVector2Array([Vector2(0, -9), Vector2(9, 0), Vector2(0, 9), Vector2(-9, 0)])
		d.color = Color(0.92, 0.94, 0.98); d.position = Vector2(14 if side == 0 else w - 14, h / 2.0); b.add_child(d)

func apply_audio() -> void:
	# Phase 5 buses: Music = on/off x music volume (ducked by MusicDirector), SFX = sfx volume
	AudioServer.set_bus_volume_db(0, 0.0)
	var mi := AudioServer.get_bus_index(&"Music"); var si := AudioServer.get_bus_index(&"SFX")
	if mi >= 0: AudioServer.set_bus_volume_db(mi, music_bus_db())
	if si >= 0: AudioServer.set_bus_volume_db(si, linear_to_db(maxf(sfx_vol, 0.001)))

func wood_button(text: String, w := 320.0, h := 64.0, gold := false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(w, h)
	b.focus_mode = Control.FOCUS_NONE
	if ResourceLoader.exists("res://content/original/fonts/SourceSerifPro-Regular.ttf"):
		b.add_theme_font_override("font", load("res://content/original/fonts/SourceSerifPro-Regular.ttf"))
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", Color(1.0, 0.93, 0.74) if gold else Color(0.96, 0.88, 0.66))
	b.add_theme_color_override("font_pressed_color", Color(1.0, 0.85, 0.55))
	b.add_theme_color_override("font_hover_color", Color(1, 0.95, 0.80))
	b.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.02))
	b.add_theme_constant_override("outline_size", 5)
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb := StyleBoxTexture.new()
		sb.texture = load("res://assets/ui/wood_btn_gold.png" if gold else "res://assets/ui/wood_btn.png")
		sb.texture_margin_left = 34; sb.texture_margin_right = 34
		sb.texture_margin_top = 22; sb.texture_margin_bottom = 22
		sb.content_margin_left = 30; sb.content_margin_right = 30
		if st == "hover" or st == "focus":
			sb.modulate_color = Color(1.15, 1.1, 1.0)
		if st == "pressed":
			sb.modulate_color = Color(0.85, 0.8, 0.7)
		b.add_theme_stylebox_override(st, sb)
	return b

# Painted loading screen (original art): dimmed Kyoto vista, forged-gold frame, brush-script
# "Loading..." in the subset NanumBrushScript, spinning shuriken and a gold-rimmed progress bar.
func _build_loading(cl: CanvasLayer) -> void:
	var root := Control.new(); root.set_anchors_preset(Control.PRESET_FULL_RECT); root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(root)
	var bg := ColorRect.new(); bg.color = Color(0, 0, 0, 1); bg.set_anchors_preset(Control.PRESET_FULL_RECT); root.add_child(bg)
	var t := TextureRect.new(); t.texture = load("res://assets/ui/menu_bg.png")
	t.set_anchors_preset(Control.PRESET_FULL_RECT); t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; t.modulate = Color(0.62, 0.66, 0.78); t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(t)
	var vg = GradientTexture2D.new(); vg.fill = GradientTexture2D.FILL_RADIAL; vg.fill_from = Vector2(0.5, 0.5); vg.fill_to = Vector2(1.1, 1.1)
	var vgg = Gradient.new(); vgg.set_color(0, Color(0, 0, 0.02, 0.15)); vgg.set_color(1, Color(0, 0, 0.02, 0.8)); vg.gradient = vgg
	var sh := TextureRect.new(); sh.texture = vg; sh.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; sh.set_anchors_preset(Control.PRESET_FULL_RECT)
	sh.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(sh)
	var mist = make_mist(560, 30.0); mist.modulate = Color(1, 1, 1, 0.5); root.add_child(mist)
	# ornate frame
	var fr := TextureRect.new(); fr.texture = load("res://assets/ui/title_frame.png"); fr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fr.size = Vector2(560, 300); fr.position = Vector2(360, 200); fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fr)
	var l := Label.new()
	l.text = "Loading..."
	if ResourceLoader.exists("res://content/original/fonts/NanumBrushScript-Regular.ttf"):
		l.add_theme_font_override("font", load("res://content/original/fonts/NanumBrushScript-Regular.ttf"))
	l.add_theme_font_size_override("font_size", 112)
	l.add_theme_color_override("font_color", Color(1.0, 0.90, 0.64))
	l.add_theme_color_override("font_outline_color", Color(0.10, 0.05, 0.01)); l.add_theme_constant_override("outline_size", 10)
	l.add_theme_color_override("font_shadow_color", Color(0.2, 0.45, 1.0, 0.55)); l.add_theme_constant_override("shadow_offset_x", 0); l.add_theme_constant_override("shadow_offset_y", 4)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = Vector2(360, 222); l.size = Vector2(560, 170)
	root.add_child(l)
	var tip := Label.new(); tip.text = "TIP: " + LOADING_TIPS[randi() % LOADING_TIPS.size()]
	tip.position = Vector2(240, 560); tip.size = Vector2(800, 60); tip.autowrap_mode = TextServer.AUTOWRAP_WORD
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.add_theme_font_size_override("font_size", 24 if big_text else 20)
	tip.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95)); tip.add_theme_color_override("font_outline_color", Color.BLACK)
	tip.add_theme_constant_override("outline_size", 4)
	root.add_child(tip)
	# progress bar in the DOMAIN bar chrome
	var bar := Control.new(); bar.position = Vector2(470, 400); bar.size = Vector2(340, 22); root.add_child(bar)
	var fill := TextureRect.new(); fill.texture = load("res://assets/ui/domain_fill.png"); fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fill.position = Vector2(8, 5); fill.size = Vector2(0, 12); bar.add_child(fill)
	var bfr := TextureRect.new(); bfr.texture = load("res://assets/ui/domain_frame.png"); bfr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bfr.position = Vector2(-10, -4); bfr.size = Vector2(360, 30); bar.add_child(bfr)
	var ftw = fill.create_tween(); ftw.tween_property(fill, "size:x", 324.0, 0.68).set_trans(Tween.TRANS_SINE)
	UIJuice.pop_in(bar, 0.0, 0.18)
	UIJuice.breathe(bar, 0.025, 0.9, 0.2)
	# spinning shuriken either side
	for x in [418.0, 862.0]:
		var sp := Sprite2D.new(); sp.texture = load("res://assets/sprites/shuriken.png"); sp.position = Vector2(x, 411); sp.scale = Vector2(1.5, 1.5)
		sp.modulate = Color(1.0, 0.86, 0.5); root.add_child(sp)
		var stw = sp.create_tween().set_loops(); stw.tween_property(sp, "rotation", TAU, 0.6).as_relative()

const LOADING_TIPS := [
	"Springs launch you far higher than a double jump.",
	"Crumbling floors fall 0.45 s after you land. Keep moving.",
	"Timed spikes flash before they rise.",
	"Gusts pause between blows; cross in the calm.",
	"Jump while on a rope to let go with a boost and a fresh double jump.",
	"Lanterns light dark rooms. Stay near them.",
	"Switches open gates. Some gates close again.",
	"Three slashes in a row make a combo.",
	"Skills, Shop and Artifacts are in the hub.",
	"A daily Challenge pays coins and builds a streak.",
]

## Scene change with a fade or ink-wipe transition (instant fade when Reduced motion is on).
func change_scene(path: String, style := "ink") -> void:
	var cl := CanvasLayer.new(); cl.layer = 90; cl.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(cl)
	var r := ColorRect.new(); r.set_anchors_preset(Control.PRESET_FULL_RECT); r.mouse_filter = Control.MOUSE_FILTER_STOP
	r.color = Color(0.02, 0.02, 0.04, 1)
	cl.add_child(r)
	var dur := 0.05 if reduced_motion else 0.28
	if style == "ink" and not reduced_motion:
		var sm := ShaderMaterial.new(); sm.shader = INK_WIPE; r.material = sm
		sm.set_shader_parameter("progress", 0.0)
		var tw := r.create_tween(); tw.tween_method(func(v): sm.set_shader_parameter("progress", v), 0.0, 1.0, dur)
		await tw.finished
		get_tree().change_scene_to_file(path)
		await get_tree().process_frame
		var tw2 := r.create_tween(); tw2.tween_method(func(v): sm.set_shader_parameter("progress", v), 1.0, 0.0, dur)
		await tw2.finished
	else:
		r.modulate.a = 0.0
		var tw := r.create_tween(); tw.tween_property(r, "modulate:a", 1.0, dur); await tw.finished
		get_tree().change_scene_to_file(path)
		await get_tree().process_frame
		var tw2 := r.create_tween(); tw2.tween_property(r, "modulate:a", 0.0, dur); await tw2.finished
	cl.queue_free()

const INK_WIPE := preload("res://assets/shaders/ink_wipe.gdshader")

func goto_level(n: int) -> void:
	current_level = n
	show_loading("res://scenes/Level.tscn")

func show_loading(path: String) -> void:
	var cl := CanvasLayer.new()
	cl.layer = 80
	cl.name = "LoadingOverlay"
	cl.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(cl)
	_build_loading(cl)
	await get_tree().create_timer(0.7, true, false, true).timeout
	get_tree().change_scene_to_file(path)
	cl.queue_free()

func _shot_loading() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 80
	get_tree().root.add_child(cl)
	_build_loading(cl)
	_shoot_later(ProjectSettings.globalize_path("res://ui-mockups/") + "real_loading.png")


# ---- Dev-only (--showcase): scripted combat tape for review videos / mid-motion stills ----
# Drives real input actions in L1, L2 and L4 (no DOMAIN). With --snap it also saves stills
# to ui-mockups/polish_*.png at fixed beats. Debug builds only (guarded in _process).
const SNAP_DIR := "res://ui-mockups/"  # debug captures only; globalize before save_png
func _sc_wait(sec: float) -> void:
	await get_tree().create_timer(sec, true, false, true).timeout

func _sc_tap(action: String, hold := 0.06) -> void:
	Input.action_press(action); await _sc_wait(hold); Input.action_release(action)

func _sc_snap(name: String) -> void:
	if not "--snap" in _cap_args: return
	var prefix := "polish_"   # never overwrite delivered char_* stills
	for a in _cap_args:
		if a.begins_with("--snap-prefix="): prefix = a.substr(14)
	if prefix.begins_with("char_"): prefix = "polish_"
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(SNAP_DIR) + "%s%s.png" % [prefix, name])
	var sc = get_tree().current_scene
	var plp = sc.get_node_or_null("Player") if sc else null
	print("SNAP ", name, " ", plp.get_global_transform_with_canvas().origin if plp else Vector2.ZERO)

func _sc_level(n: int) -> Node:
	current_level = n
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Level.tscn")
	await _sc_wait(0.9)
	return get_tree().current_scene

func _sc_spawn(lvl: Node, ranged: bool, at: Vector2) -> Node:
	var e = preload("res://scenes/Enemy.tscn").instantiate()
	e.is_ranged = ranged
	lvl.get_node("Enemies").add_child(e)
	e.global_position = at
	e.start_x = at.x
	return e

func _sc_clear_enemies(lvl: Node) -> void:
	for e in get_tree().get_nodes_in_group("Enemies"): e.queue_free()

func _showcase() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# ---- L1: run, jump cycle, ground slash, air slash, double jump, oni attack ----
	var lvl = await _sc_level(1)
	var pl = lvl.get_node("Player")
	_sc_clear_enemies(lvl)
	await _sc_wait(0.6)
	Input.action_press("move_right"); await _sc_wait(0.45); _sc_snap("run"); await _sc_wait(1.4); Input.action_release("move_right")
	await _sc_wait(0.5); _sc_snap("face_idle")
	# full jump in place: crouch, rise, tuck, apex, fall, land
	Input.action_press("jump"); await _sc_wait(0.05); _sc_snap("jump_crouch"); await _sc_wait(0.13); _sc_snap("jump_rise"); Input.action_release("jump")
	await _sc_wait(0.3); _sc_snap("jump_apex"); await _sc_wait(0.32); _sc_snap("jump_fall")
	await _sc_wait(0.32); _sc_snap("jump_land")
	await _sc_wait(0.7)
	# ground slash x2
	_sc_tap("attack"); await _sc_wait(0.07); _sc_snap("slash_windup"); await _sc_wait(0.06); _sc_snap("slash"); await _sc_wait(0.22); _sc_snap("slash_follow"); await _sc_wait(0.45)
	_sc_tap("attack"); await _sc_wait(0.8)
	# air slash at the apex
	Input.action_press("jump"); await _sc_wait(0.12); Input.action_release("jump"); await _sc_wait(0.3)
	_sc_tap("attack", 0.03); await _sc_wait(0.1); _sc_snap("air_slash"); await _sc_wait(0.9)
	# double jump somersault
	Input.action_press("jump"); await _sc_wait(0.1); Input.action_release("jump"); await _sc_wait(0.28)
	_sc_tap("jump", 0.05); await _sc_wait(0.12); _sc_snap("double_jump"); await _sc_wait(1.0)
	# oni walks in, telegraphs, strikes; hero takes the hit, then cuts him down
	var oni = _sc_spawn(lvl, false, pl.global_position + Vector2(230, -20))
	oni.direction = -1
	for i in range(240):
		if not oni._seq.is_empty(): break
		await get_tree().physics_frame
	await _sc_wait(0.3); _sc_snap("oni_windup")
	for i in range(120):
		if oni.spr.frame == 5: break
		await get_tree().physics_frame
	_sc_snap("oni_strike")
	await _sc_wait(0.1); _sc_snap("hurt")
	print("SHOWCASE oni strike: player hp ", pl.health)
	await _sc_wait(0.9)
	_sc_tap("attack"); await _sc_wait(0.5); _sc_tap("attack"); await _sc_wait(0.9)
	# ---- L2: kitsune windup + throw (projectile), dash, jump-slash ----
	lvl = await _sc_level(2)
	pl = lvl.get_node("Player")
	_sc_clear_enemies(lvl)
	await _sc_wait(0.2)
	var kit = _sc_spawn(lvl, true, pl.global_position + Vector2(300, -20))
	kit.shoot_timer = 1.2
	var hp0 = pl.health
	await _sc_wait(0.6); _sc_snap("kitsune_windup")
	await _sc_wait(0.27); _sc_snap("kitsune_throw")
	await _sc_wait(0.18); _sc_snap("kitsune_follow")
	await _sc_wait(1.4)
	print("SHOWCASE kitsune throw: player hp ", hp0, " -> ", pl.health)
	# jump over the next star with an air slash, then dash
	Input.action_press("jump"); await _sc_wait(0.12); Input.action_release("jump"); await _sc_wait(0.2); _sc_tap("attack", 0.03)
	await _sc_wait(1.1)
	_sc_tap("dash"); await _sc_wait(0.08); _sc_snap("dash"); await _sc_wait(0.17); _sc_snap("dash_stop"); await _sc_wait(0.6)
	_sc_tap("dash"); await _sc_wait(0.9)
	Input.action_press("move_left"); await _sc_wait(0.5); Input.action_release("move_left")
	await _sc_wait(1.0)
	# ---- L4: Rin telegraph + multi-frame cut, hits on Rin, phase-2 cross-cut ----
	lvl = await _sc_level(4)
	pl = lvl.get_node("Player")
	var boss = get_tree().get_nodes_in_group("Bosses")[0] if not get_tree().get_nodes_in_group("Bosses").is_empty() else null
	if boss:
		boss.attack_timer = 0.0
		pl.global_position = boss.global_position + Vector2(-470, -10)
		boss.direction = -1
		await _sc_wait(1.3); _sc_snap("boss_telegraph")
		await _sc_wait(0.58); _sc_snap("boss_cut")
		await _sc_wait(0.22); _sc_snap("boss_follow")
		await _sc_wait(0.15)
		# hero closes in and lands slashes on Rin (bar chips)
		for i in range(3):
			if not is_instance_valid(boss): break
			pl.global_position = boss.global_position + Vector2(-60, -10); pl.facing = 1; pl.anim.set_facing(1)
			_sc_tap("attack"); await _sc_wait(0.12)
			if i == 1: _sc_snap("boss_hit")
			await _sc_wait(0.4)
		print("SHOWCASE boss hp after slashes ", boss.health if is_instance_valid(boss) else "dead", " bar ", lvl.boss_health_bar.value if lvl.boss_health_bar else -1)
		if is_instance_valid(boss):
			boss.health = boss.max_health / 2 + 1
			boss.take_damage(1)          # crosses into phase 2 (toast + red rim)
			boss.attack_timer = 0.0
			pl.global_position = boss.global_position + Vector2(-240, -10)
			await _sc_wait(0.65); _sc_snap("boss_phase2_iai"); await _sc_wait(0.5); _sc_snap("boss_phase2_dash")
			await _sc_wait(0.28); _sc_snap("boss_phase2_rise")
		await _sc_wait(2.2)
	if "--snap" in _cap_args or "--quit-after-showcase" in _cap_args:
		get_tree().quit()


# ---- Dev-only (--phase1): production-pass Phase 1 check + stills (debug builds only) ----
# Drives real input in L1: run (8-frame sheet), 3-hit combo via buffered presses, dash
# afterimage, double jump, DOMAIN cast pose. Prints the states/frames it saw (PHASE1 lines)
# and with --snap saves ui-mockups/phase1_*.png in this repo.
const P1_DIR := "res://ui-mockups/"
func _p1_snap(name: String) -> void:
	if not "--snap" in _cap_args: return
	var path := ProjectSettings.globalize_path(P1_DIR) + "phase1_%s.png" % name
	get_viewport().get_texture().get_image().save_png(path)
	print("PHASE1 SNAP ", path)

func _phase1_showcase() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var lvl = await _sc_level(1)
	var pl = lvl.get_node("Player")
	_sc_clear_enemies(lvl)
	var seen := {}
	var frames := []
	pl.anim.state_changed.connect(func(ns, _o): seen[PlayerAnimator.State.keys()[ns]] = true)
	var rec := func():
		var k: String = pl.anim.frame_key
		if frames.is_empty() or frames[-1] != k: frames.append(k)
	get_tree().physics_frame.connect(rec)
	await _sc_wait(0.6)
	Input.action_press("move_right"); await _sc_wait(0.5); _p1_snap("run"); await _sc_wait(0.6); Input.action_release("move_right")
	await _sc_wait(0.5)
	print("PHASE1 run frames: ", frames.filter(func(f): return f.begins_with("run_")))
	# a dummy oni to hit: combo on a target (damage numbers unchanged: 1 per hit)
	var oni = _sc_spawn(lvl, false, pl.global_position + Vector2(70, -10))
	oni.direction = -1; oni.health = 99
	if "speed" in oni: oni.speed = 0.0
	await _sc_wait(0.3)
	frames.clear()
	var steps := []
	# mash attack: 2nd/3rd presses arrive mid-cooldown and must be buffered into hits 2 and 3
	for i in range(3):
		_sc_tap("attack", 0.03); await _sc_wait(0.06); steps.append(pl.combo_step)
		if i == 2:
			await _sc_wait(0.1); _p1_snap("combo3")
		elif i == 1:
			await _sc_wait(0.1); _p1_snap("combo2")
		await _sc_wait(0.12 if i < 2 else 0.6)
	print("PHASE1 combo steps: ", steps, " oni hp ", oni.health if is_instance_valid(oni) else "dead")
	print("PHASE1 combo frames: ", frames.filter(func(f): return f.begins_with("c")))
	if is_instance_valid(oni): oni.queue_free()
	await _sc_wait(0.4)
	# dash (afterimage) then slash cancel into dash
	_sc_tap("attack", 0.03); await _sc_wait(0.25); _sc_tap("dash"); await _sc_wait(0.07); _p1_snap("dash_cancel"); await _sc_wait(0.6)
	# jump + double jump
	Input.action_press("jump"); await _sc_wait(0.1); Input.action_release("jump"); await _sc_wait(0.25)
	_sc_tap("jump", 0.05); await _sc_wait(0.12); _p1_snap("double_jump"); await _sc_wait(1.0)
	# throw
	_sc_tap("throw"); await _sc_wait(0.6)
	# hurt
	pl.take_damage(1); await _sc_wait(1.0)
	# DOMAIN rite pose during the cut-in
	Input.action_press("domain"); await _sc_wait(0.05); Input.action_release("domain"); await _sc_wait(0.3); _p1_snap("domain_cast")
	await _sc_wait(1.6)
	pl.anim.play_victory(); await _sc_wait(0.3); _p1_snap("victory"); await _sc_wait(1.8)
	pl.anim.play_dead(); await _sc_wait(0.6); pl.anim.revive(); await _sc_wait(0.3)
	var keys := seen.keys(); keys.sort()
	print("PHASE1 states seen (", keys.size(), "): ", keys)
	get_tree().physics_frame.disconnect(rec)
	get_tree().quit()


# ---- Dev-only (--phase2): new enemy roster + bosses check and stills (debug builds only) ----
func _p2_snap(name: String) -> void:
	if not "--snap" in _cap_args: return
	var path := ProjectSettings.globalize_path("res://ui-mockups/") + "phase2_%s.png" % name
	get_viewport().get_texture().get_image().save_png(path)
	print("PHASE2 SNAP ", path)

func _phase2_showcase() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var lvl = await _sc_level(3)
	var pl = lvl.get_node("Player")
	_sc_clear_enemies(lvl)
	await _sc_wait(0.2)
	pl.global_position = Vector2(140, 600)
	var seen := {}
	var made := {}
	var spots := {"oni_brute": Vector2(360, 600), "shadow_assassin": Vector2(560, 600), "kitsune_archer": Vector2(760, 600),
		"bomb_monk": Vector2(960, 600), "crow_scout": Vector2(620, 380)}
	for k in spots:
		var e = EnemyFactory.make(k)
		e.global_position = spots[k]
		lvl.get_node("Enemies").add_child(e)
		made[k] = e; seen[k] = {}
		e.state_changed.connect(func(ns, _o): seen[k][EnemyBase.S.keys()[ns]] = true)
	await _sc_wait(0.15); _p2_snap("roster")
	pl.global_position = Vector2(640, 600)
	await _sc_wait(1.3); _p2_snap("attacks")
	await _sc_wait(1.6)
	# shield block: slash the brute from the front
	var br = made["oni_brute"]
	if is_instance_valid(br) and br.state != EnemyBase.S.DIE:
		br.set_state(EnemyBase.S.CHASE); br._cd = 5.0
		pl.global_position = br.global_position + Vector2(-60, -4); pl.facing = 1; pl.anim.set_facing(1); br.direction = -1
		var hp0 = br.health
		_sc_tap("attack"); await _sc_wait(0.12); _p2_snap("brute_block")
		print("PHASE2 brute block: hp ", hp0, " -> ", br.health)
	# kill everything for numbers + drops
	await _sc_wait(0.3)
	for k in made:
		var e = made[k]
		if is_instance_valid(e) and e.state != EnemyBase.S.DIE: e.take_damage(e.health)
	await _sc_wait(0.45); _p2_snap("drops")
	for k in seen:
		var ks: Array = seen[k].keys(); ks.sort()
		print("PHASE2 ", k, " states (", ks.size(), "): ", ks)
	await _sc_wait(0.6)
	# ---- bosses ----
	for lv in [4, 8, 12]:
		lvl = await _sc_level(lv)
		pl = lvl.get_node("Player")
		var boss = get_tree().get_nodes_in_group("Bosses")[0]
		print("PHASE2 boss ", boss.boss_id, " hp ", boss.health, "/", boss.max_health)
		await _sc_wait(0.6)
		if lv == 4: _p2_snap("rin_intro")
		await _sc_wait(1.9)
		var pats := []
		var defeated := [false]
		boss.boss_defeated.connect(func(): defeated[0] = true)
		for i in range(3):
			boss.attack_timer = 1.15
			await _sc_wait(0.62); pats.append(boss.attacks_done)
			if lv == 8 and i == 0: await _sc_wait(0.15); _p2_snap("gorrah_slam")
			if lv == 12 and i == 2: await _sc_wait(0.05); _p2_snap("vey_pillars")
			await _sc_wait(0.9)
		print("PHASE2 boss ", boss.boss_id, " patterns cycled ", pats)
		boss.health = boss.max_health / 2 + 1
		boss.take_damage(1)
		print("PHASE2 boss ", boss.boss_id, " phase2=", boss.phase2, " hp ", boss.health)
		await _sc_wait(0.4)
		if lv == 8:
			boss.attack_timer = 0.5; await _sc_wait(0.75); _p2_snap("gorrah_phase2")
		await _sc_wait(1.0)
		if lv == 12:
			boss.health = 1; boss.take_damage(1)
			await _sc_wait(0.25); _p2_snap("boss_death")
			await _sc_wait(4.0)
			print("PHASE2 vey death sequence finished, boss_defeated emitted: ", defeated[0], " boss freed: ", not is_instance_valid(boss))
	get_tree().quit()


# ---- Dev-only (--phase3): hand-built stages smoke test + stills (debug builds only) ----
func _p3_snap(name: String) -> void:
	if not "--snap" in _cap_args: return
	var path := ProjectSettings.globalize_path("res://ui-mockups/") + "phase3_%s.png" % name
	get_viewport().get_texture().get_image().save_png(path)
	print("PHASE3 SNAP ", path)

func _p3_at(lvl: Node, pl: Node, chunk: String, col: int, row: int) -> void:
	var names: Array = StageData.STAGES[current_level]["chunks"]
	var i := names.find(chunk)
	pl.global_position = Vector2((i * StageData.CHUNK_W + col) * 32 + 16, (StageBuilder.BASE_ROW + row) * 32 + 4)
	pl.velocity = Vector2.ZERO
	pl.checkpoint_position = pl.global_position
	var cam: Camera2D = pl.get_node("Camera2D"); cam.reset_smoothing()

func _phase3_showcase() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var shots := {   # level -> [chunk, col, row(local), hold seconds, snap name or ""]
		3: [["moving_teach", 8, 10, 1.6, "gion_rooftops"], ["spring_teach", 13, 10, 0.25, ""]],
		5: [["wind_test", 4, 10, 1.2, "bamboo_wind"], ["crumble_test", 11, 9, 1.0, ""]],
		6: [["dark_teach", 7, 10, 1.4, "cave_dark"], ["water_teach", 9, 6, 6.0, ""]],
		7: [["saw_spike_test", 3, 10, 1.3, "shrine_saws"]],
		9: [["rope_teach", 6, 10, 0.5, "canal_rope"]],
		10: [["switch_teach", 8, 6, 1.2, "pagoda_switch"]],
		11: [["dark_test", 3, 10, 1.4, ""]],
	}
	var lvls := [3, 5, 6, 7, 9, 10, 11]
	for a in _cap_args:
		if a.begins_with("--p3levels="): lvls = Array(a.substr(11).split(",")).map(func(v): return int(v))
	for lv in lvls:
		var lvl = await _sc_level(lv)
		var pl = lvl.get_node("Player")
		await _sc_wait(0.3)
		var si: Dictionary = lvl.stage_info
		print("PHASE3 L", lv, " ", si["scenario"], " width ", si["width"], "px coins ", si["coins"], " enemies ", si["enemies"],
			" checkpoints ", get_tree().get_nodes_in_group("Checkpoints").size(), " mechanics ", si["mechanics"])
		# smoke test: drop the hero at the start of every chunk; he must land on something
		var names: Array = StageData.STAGES[lv]["chunks"]
		var bad := []
		for e in get_tree().get_nodes_in_group("Enemies"): e.process_mode = Node.PROCESS_MODE_DISABLED
		for i in range(0 if "--nocheck" in _cap_args else names.size()):
			var landed := false
			for col in [1, 2, 3]:
				pl.global_position = Vector2((i * StageData.CHUNK_W + col) * 32 + 16, 300); pl.velocity = Vector2.ZERO
				for f in range(100):
					await get_tree().physics_frame
					if pl.is_on_floor(): landed = true; break
				if landed: break
			if not landed: bad.append(names[i])
		print("PHASE3 L", lv, " chunk landing check: ", "all %d ok" % names.size() if bad.is_empty() else "no floor at " + str(bad))
		for e in get_tree().get_nodes_in_group("Enemies"): e.process_mode = Node.PROCESS_MODE_INHERIT
		pl.health = pl.max_health
		for sh in shots.get(lv, []):
			_p3_at(lvl, pl, sh[0], sh[1], sh[2])
			if sh[0] == "rope_teach":
				await _sc_wait(0.3)
				Input.action_press("move_right"); await _sc_wait(0.12); _sc_tap("jump", 0.15)
				for f in range(90):
					await get_tree().physics_frame
					if pl.rope != null: break
				Input.action_release("move_right")
			if sh[0] == "spring_teach":
				await _sc_wait(0.4); var y0 = pl.global_position.y; var vmin := 0.0
				Input.action_press("move_right")
				for f in range(30):
					await get_tree().physics_frame; vmin = minf(vmin, pl.velocity.y)
				Input.action_release("move_right")
				print("PHASE3 spring: min vy ", int(vmin), " rise ", int(y0 - pl.global_position.y), " px")
			if sh[0] == "switch_teach":
				_sc_tap("jump", 0.15); await _sc_wait(0.5)
			await _sc_wait(sh[3])
			if sh[4] != "": _p3_snap(sh[4])
			match sh[0]:
				"rope_teach": print("PHASE3 rope: hero on rope = ", pl.rope != null)
				"switch_teach":
					var gs := []
					for n in lvl.get_node("World").get_children():
						if n is Mechanics.Gate: gs.append(n._open)
					print("PHASE3 switch: gates open ", gs)
				"water_teach":
					for n in lvl.get_node("World").get_children():
						if n is Mechanics.Water and n._active: print("PHASE3 water rising: level y ", int(n._level), " (bottom ", int(n.bottom), ")")
				"dark_teach", "dark_test": print("PHASE3 dark room: ambient ", lvl._cmod.color)
				"crumble_test":
					var dis := 0
					for n in lvl.get_node("World").get_children():
						if n is Mechanics.Crumble and n._busy: dis += 1
					print("PHASE3 crumble tiles triggered: ", dis)
			await _sc_wait(0.2)
	get_tree().quit()


# ---- Dev-only (--phase4): save migration test, meta systems, UI stills (debug builds only) ----
func _p4_snap(name: String) -> void:
	if not "--snap" in _cap_args: return
	var path := ProjectSettings.globalize_path("res://ui-mockups/") + "phase4_%s.png" % name
	get_viewport().get_texture().get_image().save_png(path)
	print("PHASE4 SNAP ", path)

func _p4_check(label: String, ok: bool) -> bool:
	print("PHASE4 ", "PASS " if ok else "FAIL ", label)
	return ok

func _p4_meta(mode: String) -> void:
	meta_mode = mode; get_tree().change_scene_to_file("res://scenes/Meta.tscn"); await _sc_wait(0.8)

func _phase4_showcase() -> void:
	await _sc_wait(0.5)
	var real_save := save_dict().duplicate(true)
	var real_settings := [touch_layout.duplicate(), left_handed, control_scale]
	# 1) migration: a v1 save exactly as the shipped builds write it
	var v1 := {"unlocked_level": 7, "level_stars": {"1": 3, "2": 2, "3": 1, "4": 3, "5": 2, "6": 1}, "total_coins": 1234, "total_gems": 1, "music_on": false, "future_key": "kept"}
	var tp := "user://p4_migration_test.json"
	for f in [tp, tp + ".v1.bak", tp + ".tmp"]: if FileAccess.file_exists(f): DirAccess.remove_absolute(f)
	var fw := FileAccess.open(tp, FileAccess.WRITE); fw.store_string(JSON.stringify(v1)); fw.close()
	var d := SaveData.load_file(tp)
	var ok := true
	ok = _p4_check("v1 detected as version 1", SaveData.version_of(v1) == 1) and ok
	ok = _p4_check("migrated version = %d" % d["version"], d["version"] == 2) and ok
	for k in ["unlocked_level", "total_coins", "total_gems", "music_on"]:
		ok = _p4_check("%s kept (%s -> %s)" % [k, v1[k], d[k]], str(d[k]) == str(v1[k])) and ok
	ok = _p4_check("level_stars kept %s" % JSON.stringify(d["level_stars"]), JSON.stringify(d["level_stars"]) == JSON.stringify(v1["level_stars"])) and ok
	ok = _p4_check("unknown key kept", d.get("future_key") == "kept") and ok
	ok = _p4_check("meta block added", d["meta"].has("skills") and d["meta"].has("challenge")) and ok
	ok = _p4_check("v1 backup written", FileAccess.file_exists(tp + ".v1.bak")) and ok
	SaveData.save_file(tp, d)
	var d2 := SaveData.load_file(tp)
	ok = _p4_check("v2 round-trip identical", JSON.stringify(d2) == JSON.stringify(d)) and ok
	var raw = JSON.parse_string(FileAccess.get_file_as_string(tp))
	ok = _p4_check("v2 file still has v1 top-level keys (old builds can read it)", raw.has("unlocked_level") and raw.has("level_stars") and raw.has("total_coins")) and ok
	var fc := FileAccess.open(tp, FileAccess.WRITE); fc.store_string("{not json"); fc.close()
	ok = _p4_check("corrupt file -> defaults, original kept aside", SaveData.load_file(tp)["unlocked_level"] == 1 and FileAccess.file_exists(tp + ".corrupt")) and ok
	# 2) meta systems on a scratch profile
	apply_save(SaveData.migrate(v1)); total_coins = 3000; total_gems = 4
	ok = _p4_check("tier-2 skill locked before tier 1", Progression.skill_state("twin_kunai") == "locked") and ok
	ok = _p4_check("buy combo_ink", Progression.buy_skill("combo_ink")) and ok
	ok = _p4_check("buy twin_kunai", Progression.buy_skill("twin_kunai")) and ok
	ok = _p4_check("buy coin_sense + iron_ward", Progression.buy_skill("coin_sense") and Progression.buy_skill("iron_ward")) and ok
	ok = _p4_check("shop tea + talisman + crimson skin", Progression.buy_item("tea") and Progression.buy_item("talisman") and Progression.buy_item("crimson")) and ok
	Progression.equip_skin("crimson")
	ok = _p4_check("artifacts fox_bell + crow_feather unlocked/equipped", Progression.unlock_artifact("fox_bell") and Progression.unlock_artifact("crow_feather") and Progression.toggle_artifact("fox_bell") and Progression.toggle_artifact("crow_feather")) and ok
	ok = _p4_check("third artifact refused (2 slots)", Progression.unlock_artifact("moon_mirror") and not Progression.toggle_artifact("moon_mirror")) and ok
	ok = _p4_check("coins %d gems %d after purchases" % [total_coins, total_gems], total_coins == 3000 - 120 - 260 - 100 - 300 - 60 - 90 - 300 and total_gems == 1) and ok
	ok = _p4_check("perks: magnet %d wards %d" % [Progression.magnet_radius(), Progression.stage_wards()], Progression.magnet_radius() == 160.0 and Progression.stage_wards() == 2) and ok
	var dd := {"year": 2026, "month": 11, "day": 14}
	ok = _p4_check("daily challenge deterministic: %s" % str(Progression.daily(dd)), str(Progression.daily(dd)) == str(Progression.daily(dd))) and ok
	# 3) touch layout: default = SPEC §5, custom placements clamp out of the hero zone
	var cc := TouchControls_clamp(Vector2(640, 500), Vector2(67, 67))
	ok = _p4_check("drag jump into hero zone -> clamped to %s" % cc, cc.x <= 380 - 67 or cc.x >= 900 + 67) and ok
	# 4) screens
	for m in ["skills", "shop", "artifact", "challenge", "settings", "controls"]:
		await _p4_meta(m)
		if m != "challenge": _p4_snap(m)
	# 5) in-stage: L1 tutorial card, then L5 with skin, wards, combo counter + teach hint
	meta["tutorial_done"] = false
	var l1 = await _sc_level(1)
	ok = _p4_check("L1 tutorial card shown", l1.lmeta.hint_label.text.begins_with("MOVE")) and ok
	_sc_tap("move_right", 0.2); await _sc_wait(0.3)
	ok = _p4_check("tutorial advanced to JUMP", l1.lmeta.hint_label.text.begins_with("JUMP")) and ok
	var l2 = await _sc_level(2)
	var tc = l2.touch_controls
	if tc:
		var jb = tc.get_node("Btn_jump")
		ok = _p4_check("default jump centre %s == SPEC (1177, 532)" % (jb.position + jb.size / 2.0), (jb.position + jb.size / 2.0).is_equal_approx(Vector2(1177, 532))) and ok
	Progression.buy_item("talisman")   # L2 above used the first one
	var lv = await _sc_level(5)
	var pl = lv.player
	ok = _p4_check("wards at stage start = %d" % pl.wards, pl.wards == 2) and ok
	pl.take_damage(1)
	ok = _p4_check("ward blocked hit (hp %d, wards %d)" % [pl.health, pl.wards], pl.health == 3 and pl.wards == 1) and ok
	for e in get_tree().get_nodes_in_group("Enemies"): e.process_mode = Node.PROCESS_MODE_DISABLED
	var foe = _sc_spawn(lv, false, pl.global_position + Vector2(60, 0))
	if foe: foe.process_mode = Node.PROCESS_MODE_DISABLED; foe.set("health", 99)
	for i in range(4):
		_sc_tap("attack", 0.05); await _sc_wait(0.32)
	ok = _p4_check("combo counter '%s'" % lv.lmeta.combo_label.text, lv.lmeta.combo >= 3) and ok
	_p4_snap("hud_combo")
	# transition still
	change_scene("res://scenes/Hub.tscn", "ink"); await _sc_wait(0.25); await _sc_wait(0.8)
	if "--movie" in _cap_args:   # extra gameplay beat for the playtest video: teach hint + combo in L3
		var l3 = await _sc_level(3)
		_p3_at(l3, l3.player, "moving_teach", 2, 10); await _sc_wait(0.4)
		Input.action_press("move_right")
		for i in range(14):
			_sc_tap("attack", 0.05); await _sc_wait(0.3)
			if i % 4 == 3: _sc_tap("jump", 0.15)
		Input.action_release("move_right")
		await _sc_wait(0.5)
	print("PHASE4 RESULT ", "ALL PASS" if ok else "SOME FAILED")
	# restore the real profile + settings
	apply_save(real_save); save_game()
	touch_layout = real_settings[0]; left_handed = real_settings[1]; control_scale = real_settings[2]
	for f in [tp, tp + ".v1.bak", tp + ".corrupt"]: if FileAccess.file_exists(f): DirAccess.remove_absolute(f)
	await _sc_wait(0.3)
	get_tree().quit()

func TouchControls_clamp(c: Vector2, half: Vector2) -> Vector2:
	return load("res://scripts/TouchControls.gd").clamp_centre(c, half)

# ---- Dev-only (--runthrough=N): bot plays a tile stage start to finish to measure length ----
# Heuristic bot: holds right, jumps at walls / gaps / hazards, double-jumps over long gaps,
# spams slash, rides ropes. No damage immunity. If no progress for 8 s it is "assisted" to the
# next chunk (counted). Run headless with --fixed-fps 60 so game time is exact.
func _runthrough(n: int) -> void:
	await _sc_wait(0.3)
	var lv = await _sc_level(n)
	var pl = lv.player
	var frames := 0; var best_x: float = pl.global_position.x; var stall := 0; var assists := 0
	var deaths0 := int(meta["stats"]["deaths"]); var space = pl.get_world_2d().direct_space_state
	var rope_t := 0
	var names: Array = StageData.STAGES[n]["chunks"]
	var route_chunk := -1; var route_i := 0; var route_t := 0; var route_skips := 0
	var _dl := [0]
	var bx := [0.0]
	pl.died.connect(func():
		_dl[0] += 1; bx[0] = 1.0
		if _dl[0] <= 6 and "--rtdebug" in _cap_args: print("RT death at ", pl.global_position.round(), " hp ", pl.health))
	Input.action_press("move_right")
	while frames < 60 * 900:
		await get_tree().physics_frame
		frames += 1
		if lv.stars > 0: break
		var p: Vector2 = pl.global_position
		if "--rtdebug" in _cap_args and frames % 600 == 0: print("RT f", frames, " rope ", pl.rope != null, " stall ", stall)
		if "--rtdebug" in _cap_args and frames % 600 == 0 and frames > 4400 and frames < 20000: print("RT pos ", p.round(), " floor ", pl.is_on_floor(), " v ", pl.velocity.round())
		if p.x > best_x + 8: best_x = p.x; stall = 0
		else: stall += 1
		if stall > 60 * 8:
			var ci := mini(int(best_x / (StageData.CHUNK_W * 32)) + 1, names.size() - 1)
			pl.global_position = Vector2((ci * StageData.CHUNK_W + 2) * 32 + 16, 300); pl.velocity = Vector2.ZERO
			print("RT assist at x ", int(best_x), " frame ", frames); best_x = pl.global_position.x; stall = 0; assists += 1
			continue
		if frames % 17 == 0: _sc_tap("attack", 0.03)
		if pl.rope != null:
			rope_t += 1
			if rope_t > 40 and pl.velocity.x > 120: _sc_tap("jump", 0.05); rope_t = 0
			continue
		rope_t = 0
		# authored route through vertical / backtracking chunks (chunk "route" waypoints)
		var cidx := clampi(int(p.x / (StageData.CHUNK_W * 32)), 0, names.size() - 1)
		if cidx != route_chunk:
			route_chunk = cidx; route_i = 0; route_t = 0
		var route: Array = StageData.CHUNKS[names[cidx]].get("route", [])
		if route_i < route.size():
			var wp: Array = route[route_i]
			var tgt := Vector2((cidx * StageData.CHUNK_W + wp[0]) * 32 + 16, (StageBuilder.ROWS_ABOVE + wp[1]) * 32 + 16)
			var d := tgt - p
			route_t += 1; stall = 0
			if (absf(d.x) < 30 and absf(d.y) < 56) or route_t > 60 * 7:
				if route_t > 60 * 7: route_skips += 1
				route_i += 1; route_t = 0
			Input.action_release("move_left"); Input.action_release("move_right")
			if absf(d.x) > 10: Input.action_press("move_right" if d.x > 0 else "move_left")
			if d.y < -40 and pl.is_on_floor() and absf(d.x) < 300: _sc_tap("jump", 0.18)
			elif d.y < -20 and not pl.is_on_floor() and pl.velocity.y > 0 and pl.can_double_jump: _sc_tap("jump", 0.12)
			continue
		Input.action_release("move_left"); Input.action_press("move_right")
		var ahead := func(dx: float, dy: float) -> Dictionary:
			var q := PhysicsRayQueryParameters2D.create(p + Vector2(dx, -10), p + Vector2(dx, dy)); q.exclude = [pl.get_rid()]; q.collide_with_areas = false
			return space.intersect_ray(q)
		var wall_q := PhysicsRayQueryParameters2D.create(p + Vector2(0, 0), p + Vector2(40, 0)); wall_q.exclude = [pl.get_rid()]
		var wall: bool = not space.intersect_ray(wall_q).is_empty()
		var gap: bool = ahead.call(56.0, 140.0).is_empty()
		var hz := false
		var aq := PhysicsShapeQueryParameters2D.new(); var cs := CircleShape2D.new(); cs.radius = 26; aq.shape = cs
		aq.transform = Transform2D(0, p + Vector2(70, 10)); aq.collide_with_areas = true; aq.collide_with_bodies = false
		for h in space.intersect_shape(aq, 8):
			var col = h["collider"]
			if col and (col.is_in_group("Hazards") or col.name.begins_with("Trap") or col.name.begins_with("Spike") or col.name.begins_with("Saw")): hz = true
		if pl.is_on_floor() and (wall or gap or hz): _sc_tap("jump", 0.12)
		elif not pl.is_on_floor() and pl.velocity.y > 60 and pl.can_double_jump and ahead.call(24.0, 400.0).is_empty(): _sc_tap("jump", 0.1)
	Input.action_release("move_right")
	var t := frames / 60.0
	print("RUNTHROUGH L%d %s: %s in %d:%02d game time (%d frames), deaths %d, assists %d, route skips %d, coins %d/%d, reached x %d / %d" % [n, lv.stage_info.get("scenario", "?"),
		"FINISHED" if lv.stars > 0 else "NOT FINISHED", int(t) / 60, int(t) % 60, frames, int(meta["stats"]["deaths"]) - deaths0, assists, route_skips, lv.coins_collected, lv.total_coins_in_level, int(best_x), int(lv.stage_info.get("width", 0))])
	get_tree().quit()


# ---- Dev-only (--phase5): audio/music check, frame-time profile, tall-chunk stills, playtest tape ----
func _p5_snap(name: String) -> void:
	if not "--snap" in _cap_args: return
	var path := ProjectSettings.globalize_path("res://ui-mockups/") + "phase5_%s.png" % name
	get_viewport().get_texture().get_image().save_png(path)
	print("PHASE5 SNAP ", path)

func _p5_tall(lvl: Node, chunk: String, col: int, row34: int) -> void:
	var names: Array = StageData.STAGES[lvl.level_number]["chunks"]
	var i := names.find(chunk)
	lvl.player.global_position = Vector2((i * StageData.CHUNK_W + col) * 32 + 16, (StageBuilder.ROWS_ABOVE + row34) * 32 + 4)
	lvl.player.velocity = Vector2.ZERO

func _p5_profile(n: int, secs: float) -> void:
	var lv = await _sc_level(n)
	var pl = lv.player
	var proc := []; var phys := []; var dc := []; var nodes := 0
	Input.action_press("move_right")
	var f := 0
	var t0 := Time.get_ticks_usec(); var ft := []
	while f < int(secs * 60):
		await get_tree().process_frame
		var t1 := Time.get_ticks_usec(); ft.append((t1 - t0) / 1000.0); t0 = t1
		f += 1
		if f % 40 == 0: _sc_tap("jump", 0.15)
		if f % 15 == 0: _sc_tap("attack", 0.04)
		if f % 90 == 0: _sc_tap("throw", 0.04)
		proc.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		phys.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
		dc.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		nodes = maxi(nodes, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	Input.action_release("move_right")
	proc.sort(); phys.sort(); dc.sort(); ft.sort()
	print("PHASE5 FRAME L%d: wall ms/frame avg %.2f p50 %.2f p95 %.2f p99 %.2f max %.2f (%d frames)" % [n, ft.reduce(func(x, y): return x + y, 0.0) / ft.size(), ft[ft.size() / 2], ft[int(ft.size() * 0.95)], ft[int(ft.size() * 0.99)], ft[-1], ft.size()])
	var avg := func(a: Array) -> float: return a.reduce(func(x, y): return x + y, 0.0) / maxf(1.0, a.size())
	print("PHASE5 PROFILE L%d: process avg %.2f ms p95 %.2f max %.2f | physics avg %.2f p95 %.2f max %.2f | draw calls avg %.0f max %d | nodes max %d" % [n,
		avg.call(proc), proc[int(proc.size() * 0.95)], proc[-1], avg.call(phys), phys[int(phys.size() * 0.95)], phys[-1], avg.call(dc), int(dc[-1]), nodes])

func _phase5_showcase() -> void:
	await _sc_wait(0.4)
	# audio: buses + tracks + sfx resolve
	print("PHASE5 buses: ", range(AudioServer.bus_count).map(func(i): return AudioServer.get_bus_name(i)))
	for t in MusicDirector.TRACKS:
		var st = load(MusicDirector.TRACKS[t])
		print("PHASE5 music %s: %.1f s" % [t, st.get_length()])
	var missing := []
	for nm in ["click", "coin", "slash", "enemy_hit", "hit", "jump", "dash", "shuriken", "land", "spring", "gate", "switch", "crumble", "checkpoint", "block", "buy", "win", "boss_win", "boss_roar", "domain"]:
		if not ResourceLoader.exists("res://assets/audio/sfx/%s.ogg" % nm) and not ResourceLoader.exists("res://assets/audio/%s.wav" % nm): missing.append(nm)
	print("PHASE5 sfx missing: ", missing)
	music_vol = 0.5; sfx_vol = 0.25; apply_audio()
	print("PHASE5 bus dB music %.1f sfx %.1f (vol 0.5 / 0.25)" % [AudioServer.get_bus_volume_db(1), AudioServer.get_bus_volume_db(2)])
	music_vol = 0.8; sfx_vol = 1.0; apply_audio()
	if "--profile" in _cap_args:
		var pl_list := [3, 5, 6, 7, 9, 10, 11, 4]
		for a in _cap_args:
			if a.begins_with("--p5levels="): pl_list = Array(a.substr(11).split(",")).map(func(v): return int(v))
		for n in pl_list: await _p5_profile(n, 12.0)
		print("PHASE5 pool: ", Pool.stats)
		get_tree().quit(); return
	# playtest tape: menu theme -> L3 tower climb still -> L10 backtrack -> L9 canal run -> boss theme
	get_tree().change_scene_to_file("res://scenes/Hub.tscn"); await _sc_wait(2.5)
	var l3 = await _sc_level(3)
	_p5_tall(l3, "tower", 22, 7); await _sc_wait(0.8); _p5_snap("tower_top")
	Input.action_press("move_right"); await _sc_wait(1.6); Input.action_release("move_right")
	var l10 = await _sc_level(10)
	_p5_tall(l10, "backtrack", 26, 31); await _sc_wait(0.3)
	for wp in [[26, 28], [20, 25], [14, 22], [8, 19]]:
		_p5_tall(l10, "backtrack", wp[0], wp[1]); await _sc_wait(0.35)
	_p5_tall(l10, "backtrack", 5, 16); Input.action_press("move_left"); await _sc_wait(0.4); Input.action_release("move_left")
	await _sc_wait(0.5); _p5_snap("backtrack_switch")
	var l9 = await _sc_level(9)
	Input.action_press("move_right")
	for i in range(30):
		if i % 3 == 0: _sc_tap("jump", 0.15)
		_sc_tap("attack", 0.04); await _sc_wait(0.3)
		if i == 14: _p5_snap("canal_run")
	Input.action_release("move_right")
	var l4 = await _sc_level(4)
	for i in range(14):
		_sc_tap("attack", 0.04); await _sc_wait(0.3)
	print("PHASE5 pool: ", Pool.stats)
	get_tree().quit()


func _release_snap(name: String) -> void:
	var path := ProjectSettings.globalize_path("res://ui-mockups/") + "release_%s.png" % name
	get_viewport().get_texture().get_image().save_png(path)
	print("RELEASE SNAP ", path)

func _release_play(secs: float, jump_every: int = 3) -> void:
	Input.action_press("move_right")
	for i in range(int(secs / 0.3)):
		if i % jump_every == 0: _sc_tap("jump", 0.15)
		_sc_tap("attack", 0.04); await _sc_wait(0.3)
	Input.action_release("move_right")

func _release_showcase() -> void:
	# release tape: menu -> L2 run -> L3 tower climb -> L9 canal -> L4 boss (Rin)
	await _sc_wait(0.6)
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	await _sc_wait(2.5)
	_release_snap("menu")
	var l2 = await _sc_level(2)
	await _release_play(3.0)
	_release_snap("stage")
	await _release_play(2.4)
	var l3 = await _sc_level(3)
	_p5_tall(l3, "tower", 22, 7); await _sc_wait(0.8)
	_release_snap("mechanic")
	await _release_play(2.4)
	var l9 = await _sc_level(9)
	await _release_play(5.0)
	var l4 = await _sc_level(4)
	for i in range(16):
		_sc_tap("attack", 0.04); await _sc_wait(0.3)
		if i == 9: _release_snap("boss")
	Input.action_release("move_right")
	await _sc_wait(0.5)
	get_tree().quit()


func _clip(n: int) -> void:
	## rich art pass: short 4.5 s clip of stage n (hero runs, jumps and slashes) + a still at 1.5 s
	var lv = await _sc_level(n)
	if "--tall" in _cap_args: _p5_tall(lv, "tower", 22, 7)
	Input.action_press("move_right")
	for i in range(15):
		if i % 3 == 0: _sc_tap("jump", 0.15)
		_sc_tap("attack", 0.04); await _sc_wait(0.3)
		if i == 5: _release_snap("clip_L%d" % n)
		if i == 8 and "--domain" in _cap_args: lv.player.cast_domain()
	Input.action_release("move_right")
	get_tree().quit()
