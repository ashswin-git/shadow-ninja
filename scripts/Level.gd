extends Node2D

var level_number: int = 1
var coins_collected: int = 0
var total_coins_in_level: int = 3
var stars: int = 0

@onready var player = $Player
@onready var health_label = $CanvasLayer/HUD/HealthLabel
@onready var coins_label = $CanvasLayer/HUD/CoinsLabel
@onready var level_label = $CanvasLayer/HUD/LevelLabel
@onready var pause_menu = $CanvasLayer/PauseMenu
@onready var victory_screen = $CanvasLayer/VictoryScreen
@onready var game_over_screen = $CanvasLayer/GameOverScreen
@onready var boss_health_bar = $CanvasLayer/HUD/BossHealthBar if has_node("CanvasLayer/HUD/BossHealthBar") else null
@onready var rotate_prompt = $CanvasLayer/RotatePrompt if has_node("CanvasLayer/RotatePrompt") else null

var active_boss = null
var lmeta: LevelMeta

func _ready() -> void:
	level_number = GameManager.current_level
	level_label.text = LEVEL_NAMES[clamp(level_number - 1, 0, 11)]

	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	victory_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	game_over_screen.process_mode = Node.PROCESS_MODE_ALWAYS

	build_parallax()
	if ARENA_TINT.has(level_number):   # Phase 2: Gorrah's ochre quarry / Vey's violet smoke
		for pb in get_children():
			if pb is ParallaxBackground:
				for layer in pb.get_children():
					if layer is CanvasItem: layer.modulate = layer.modulate * ARENA_TINT[level_number]
	build_level_layout()
	build_hud()
	# (stage-name banner toast dropped in the polish pass: COA asked for no name banners in play)
	var cam = player.get_node("Camera2D")
	cam.limit_left = 0; cam.limit_right = 1280; cam.limit_bottom = 860; cam.limit_top = -400
	if not stage_info.is_empty():
		cam.limit_right = stage_info["width"]; cam.limit_bottom = 720; cam.limit_top = StageBuilder.ROWS_ABOVE * 32
		_stage_ambience()
	_update_coins()
	player.connect("health_changed", _on_player_health_changed)
	player.connect("died", _on_player_died)
	_setup_player_over_touch()
	GameManager.play_music(MusicDirector.track_for_level(level_number))
	lmeta = LevelMeta.new(); lmeta.name = "LevelMeta"; add_child(lmeta); lmeta.setup(self)

func build_level_layout() -> void:
	var world_node = $World
	var coins_node = $Coins
	var enemies_node = $Enemies
	var traps_node = $Traps
	var checkpoints_node = $Checkpoints
	var portals_node = $Portals

	for c in coins_node.get_children(): c.queue_free()
	for c in enemies_node.get_children(): c.queue_free()
	for t in traps_node.get_children(): t.queue_free()
	for cp in checkpoints_node.get_children(): cp.queue_free()
	for p in portals_node.get_children(): p.queue_free()
	for b in world_node.get_children():
		if b.name != "Floor":
			b.queue_free()

	for node in get_tree().get_nodes_in_group("Bosses"):
		node.queue_free()

	if level_number in [4, 8, 12]:
		total_coins_in_level = 3
		var boss_id = 1 if level_number == 4 else (2 if level_number == 8 else 3)
		var boss_scene = load("res://scenes/Boss.tscn")
		var boss = boss_scene.instantiate()
		boss.boss_id = boss_id
		boss.global_position = Vector2(1000, 500) if boss_id == 1 else Vector2(900, 550)
		add_child(boss)
		active_boss = boss
		boss.connect("boss_defeated", _on_boss_defeated)

		if boss_health_bar:
			boss_health_bar.max_value = boss.max_health
			boss_health_bar.value = boss.health
			boss_health_bar.show()

		add_platform(Vector2(-16, 560), Vector2(32, 320))
		add_platform(Vector2(1296, 560), Vector2(32, 320))
		if boss_id == 1:
			# Rin's pine-clearing arena: open floor, two escape ledges, a high retreat tower on the right
			add_platform(Vector2(300, 520), Vector2(192, 32))
			add_platform(Vector2(640, 420), Vector2(160, 32))
			add_platform(Vector2(1120, 470), Vector2(128, 32))
			add_platform(Vector2(1120, 600), Vector2(64, 200))
			var trap_b = load("res://scenes/Trap.tscn")
			for x in [520, 760]:
				var t = trap_b.instantiate(); t.global_position = Vector2(x, 684); traps_node.add_child(t)
			add_checkpoint(Vector2(120, 636))
			add_coin(Vector2(300, 470)); add_coin(Vector2(640, 370)); add_coin(Vector2(1120, 420))
			player.global_position = Vector2(120, 600); player.reset_physics_interpolation()
		elif boss_id == 2:
			# Phase 2 arena - Gorrah's quarry: two broken stone pillars to vault his shockwaves,
			# a mid ledge, walls he stuns himself on when he charges
			add_platform(Vector2(640, 600), Vector2(1280, 32))
			add_platform(Vector2(330, 470), Vector2(128, 28))
			add_platform(Vector2(950, 470), Vector2(128, 28))
			add_platform(Vector2(640, 360), Vector2(176, 28))
			add_checkpoint(Vector2(200, 636))
			add_coin(Vector2(330, 420)); add_coin(Vector2(640, 310)); add_coin(Vector2(950, 420))
		else:
			# Phase 2 arena - Vey's smoke shrine: three floating altars over an open floor
			add_platform(Vector2(640, 600), Vector2(1280, 32))
			add_platform(Vector2(250, 440), Vector2(150, 24))
			add_platform(Vector2(640, 330), Vector2(150, 24))
			add_platform(Vector2(1030, 440), Vector2(150, 24))
			add_checkpoint(Vector2(200, 636))
			add_coin(Vector2(250, 390)); add_coin(Vector2(640, 280)); add_coin(Vector2(1030, 390))
	elif level_number == 1:
		# Ash Snow Gate: gentle staircase up to the gate, low-risk intro
		for p in [[Vector2(360,600),Vector2(192,32)],[Vector2(560,520),Vector2(192,32)],[Vector2(780,440),Vector2(256,32)],[Vector2(1020,540),Vector2(192,32)]]:
			add_platform(p[0], p[1])
		total_coins_in_level = 4
		for c in [Vector2(360,550),Vector2(560,470),Vector2(780,390),Vector2(1020,490)]: add_coin(c)
		_spawn_enemy(Vector2(780,400), false)
		_spawn_enemy(Vector2(640,660), false)
		add_checkpoint(Vector2(560,486))
		add_portal(Vector2(1190,620))
	elif level_number == 2:
		# Mist Hollow: zig-zag ledges over a spike pit, ranged sentry
		for p in [[Vector2(260,560),Vector2(160,32)],[Vector2(470,460),Vector2(160,32)],[Vector2(690,360),Vector2(192,32)],[Vector2(910,470),Vector2(160,32)],[Vector2(1120,560),Vector2(192,32)]]:
			add_platform(p[0], p[1])
		total_coins_in_level = 5
		for c in [Vector2(260,510),Vector2(470,410),Vector2(690,310),Vector2(910,420),Vector2(1120,510)]: add_coin(c)
		var trap_scene2 = load("res://scenes/Trap.tscn")
		for x in [420, 560, 700, 840]:
			var t = trap_scene2.instantiate(); t.global_position = Vector2(x, 684); traps_node.add_child(t)
		_spawn_enemy(Vector2(690,320), true)
		_spawn_enemy(Vector2(1120,520), false)
		add_checkpoint(Vector2(690,326))
		add_portal(Vector2(1210,620))
	elif StageBuilder.has_stage(level_number):
		# Phase 3: hand-built TileMap stage (scripts/levels/stage_data.gd)
		if has_node("World/Floor"): $World/Floor.free()
		stage_info = StageBuilder.build(self, level_number)
		total_coins_in_level = stage_info["coins"]
	else:
		total_coins_in_level = 3 + (level_number % 3)

		var plat_count = 2 + (level_number % 4)
		for i in range(plat_count):
			var px = 300 + i * 250
			var py = 580 - (i % 2) * 120 - (level_number * 5) % 60
			add_platform(Vector2(px, py), Vector2(300, 32))

		for i in range(total_coins_in_level):
			var cx = 350 + i * 200
			var cy = 450 - (i % 2) * 100
			add_coin(Vector2(cx, cy))

		# Phase 2: generic stages field the new roster (same count and spawn spots as before)
		var roster: Array = LEVEL_ROSTER.get(level_number, ["oni", "kitsune"])
		var enemy_count = 1 + level_number % 3
		for i in range(enemy_count):
			var k: String = roster[i % roster.size()]
			var enemy = EnemyFactory.make(k)
			enemy.global_position = Vector2(500 + i * 220, 380 if k == "crow_scout" else 520)
			enemies_node.add_child(enemy)

		var trap_scene = load("res://scenes/Trap.tscn")
		var trap_count = level_number % 3
		for i in range(trap_count):
			var trap = trap_scene.instantiate()
			trap.global_position = Vector2(450 + i * 300, 670)
			traps_node.add_child(trap)

		add_checkpoint(Vector2(600, 636))
		add_portal(Vector2(1150, 620))

	for node in get_tree().get_nodes_in_group("Coins"):
		node.connect("body_entered", func(body): _on_coin_collected(node, body))
	for node in get_tree().get_nodes_in_group("Checkpoints"):
		node.connect("body_entered", func(body): _on_checkpoint_reached(node, body))
	for node in get_tree().get_nodes_in_group("Portals"):
		node.connect("body_entered", func(body): _on_portal_entered(body))
	for node in get_tree().get_nodes_in_group("Traps"):
		node.connect("body_entered", func(body): _on_trap_entered(body))

func add_platform(pos: Vector2, size: Vector2) -> void:
	var body = StaticBody2D.new()
	body.add_to_group("World")
	body.collision_mask = 2
	body.position = pos
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)

	_platform_visual(body, size)
	$World.add_child(body)

# painted per-stage ground (original art): snow-capped ishigaki stone (snow), mossy
# boardwalk over river stones (forest / Mist Hollow), petal-strewn shrine slabs (Rin's court)
const GROUND = {
	"snow": {"walk": 6.0, "pwalk": 4.0, "under": Color(0.119, 0.166, 0.247)},
	"forest": {"walk": 31.0, "pwalk": 22.0, "under": Color(0.039, 0.064, 0.07)},
	"boss": {"walk": 14.0, "pwalk": 9.0, "under": Color(0.033, 0.016, 0.016)},
}
var _theme := "snow"

func _platform_visual(body: Node2D, size: Vector2) -> void:
	var g = GROUND[_theme]
	var cap_tex: Texture2D = load("res://assets/env/plat_%s.png" % _theme)
	var top := -size.y / 2.0
	var w := size.x + 8.0
	var root := Control.new(); root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.position = Vector2(-w / 2.0, top - g["pwalk"])
	body.add_child(root)
	var cap_h := float(cap_tex.get_height())
	if size.y > 40.0:
		# wall / pillar: tiled masonry body under the cap
		var bt := TextureRect.new(); bt.texture = load("res://assets/env/body_%s.png" % _theme)
		bt.stretch_mode = TextureRect.STRETCH_TILE; bt.mouse_filter = Control.MOUSE_FILTER_IGNORE; bt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bt.position = Vector2(2, cap_h * 0.6); bt.size = Vector2(w - 4, size.y + g["pwalk"] - cap_h * 0.6)
		root.add_child(bt)
	var cap := TextureRect.new(); cap.texture = cap_tex
	cap.stretch_mode = TextureRect.STRETCH_TILE; cap.mouse_filter = Control.MOUSE_FILTER_IGNORE; cap.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cap.size = Vector2(w, cap_h)
	root.add_child(cap)
	# shaded ends so ledges read as solid blocks, not cut strips
	var vis_h := maxf(cap_h, size.y + g["pwalk"])
	for side in [0, 1]:
		var gt := GradientTexture2D.new(); gt.width = 16; gt.height = 4
		var gr := Gradient.new(); gr.set_color(0, Color(0, 0, 0, 0.75)); gr.set_color(1, Color(0, 0, 0, 0)); gt.gradient = gr
		if side == 1: gt.fill_from = Vector2(1, 0); gt.fill_to = Vector2(0, 0)
		var e := TextureRect.new(); e.texture = gt; e.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; e.mouse_filter = Control.MOUSE_FILTER_IGNORE
		e.size = Vector2(12, vis_h - 6); e.position = Vector2(0 if side == 0 else w - 12, 6)
		root.add_child(e)
	# soft contact shadow under floating ledges
	if size.y <= 40.0:
		var sh := TextureRect.new(); var sg := GradientTexture2D.new(); sg.width = 8; sg.height = 16
		var sgr := Gradient.new(); sgr.set_color(0, Color(0, 0, 0, 0.45)); sgr.set_color(1, Color(0, 0, 0, 0)); sg.gradient = sgr
		sg.fill_from = Vector2(0, 0); sg.fill_to = Vector2(0, 1)
		sh.texture = sg; sh.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; sh.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sh.position = Vector2(6, cap_h - 2); sh.size = Vector2(w - 12, 14); root.add_child(sh)

func add_coin(pos: Vector2) -> void:
	var coin_scene = load("res://scenes/Coin.tscn")
	var coin = coin_scene.instantiate()
	coin.global_position = pos
	$Coins.add_child(coin)

func add_checkpoint(pos: Vector2) -> void:
	var cp_scene = load("res://scenes/Checkpoint.tscn")
	var cp = cp_scene.instantiate()
	cp.global_position = pos
	$Checkpoints.add_child(cp)

func add_portal(pos: Vector2) -> void:
	var portal_scene = load("res://scenes/Portal.tscn")
	var portal = portal_scene.instantiate()
	portal.global_position = pos
	$Portals.add_child(portal)

# polish: a touch button fades while the hero or Rin is behind it, so neither is lost under the
# right-hand cluster (layout and hit areas unchanged; only the button art's alpha changes)
const TOUCH_FADE_A := 0.35
func _fade_touch_over_actors(delta: float) -> void:
	if touch_controls == null or not touch_controls.visible: return
	var pts: Array = []
	if player and is_instance_valid(player): pts.append(player.get_global_transform_with_canvas().origin + Vector2(0, -30))
	if active_boss and is_instance_valid(active_boss): pts.append(active_boss.get_global_transform_with_canvas().origin + Vector2(0, -30))
	for b in touch_controls.get_children():
		if not (b is Button): continue
		var r: Rect2 = Rect2(b.global_position, b.size * b.scale).grow(36.0)
		var hide := false
		for q in pts:
			if r.has_point(q): hide = true
		b.modulate.a = move_toward(b.modulate.a, TOUCH_FADE_A if hide else 1.0, delta * 4.0)

func _process(delta: float) -> void:
	_fade_touch_over_actors(delta)
	if active_boss and is_instance_valid(active_boss) and boss_health_bar:
		if active_boss.health < boss_health_bar.value:
			# chip flash so a hit on the boss is visible on the bar
			boss_health_bar.modulate = Color(2.2, 2.2, 2.2)
			var bt = boss_health_bar.create_tween(); bt.tween_property(boss_health_bar, "modulate", Color.WHITE, 0.25)
		boss_health_bar.value = active_boss.health
	if OS.has_feature("web") and rotate_prompt:
		var sz = DisplayServer.window_get_size()
		rotate_prompt.visible = (sz.y > sz.x)
	_sync_player_vis()

const RESULT_STAR_DELAY := 0.25
const RESULT_STAR_STAGGER := 0.12
const HUD_HIT_SHAKE := 7.0
const HUD_HIT_SHAKE_TIME := 0.25
var _last_hp := 3
func _on_player_health_changed(hp: int) -> void:
	if hp_count_label:
		hp_count_label.text = str(hp)
	# HUD shakes on hits only (not on heal / respawn refill)
	if hp < _last_hp and has_node("CanvasLayer/HUD"):
		UIJuice.shake($CanvasLayer/HUD, HUD_HIT_SHAKE, HUD_HIT_SHAKE_TIME)
	_last_hp = hp

func _on_player_died() -> void:
	# Silent checkpoint revive — no death/revive card (not in the sampled frames).
	pass

func _on_coin_collected(coin, body) -> void:
	if body == player:
		coins_collected += 1
		_update_coins()
		GameManager.play_sfx("coin")
		_coin_floater(coin.global_position)
		coin.queue_free()

func _on_checkpoint_reached(cp, body) -> void:
	if body == player:
		if player.checkpoint_position.distance_to(cp.global_position) > 8.0: GameManager.play_sfx("checkpoint", 0.0)
		player.checkpoint_position = cp.global_position
		if lmeta: lmeta.on_checkpoint()

func _on_portal_entered(body) -> void:
	if body == player:
		stars = 3 if coins_collected >= total_coins_in_level else (2 if coins_collected > 0 else 1)
		GameManager.complete_level(level_number, stars, coins_collected)
		GameManager.play_sfx("win")
		GameManager.play_music("victory")
		show_results(stars, false)
		if lmeta:
			var cr := lmeta.challenge_result()
			if cr != "": FX.toast(self, cr)

func _on_trap_entered(body) -> void:
	if body == player:
		player.take_damage(1)

func _on_boss_defeated() -> void:
	stars = 3
	GameManager.complete_level(level_number, stars, coins_collected)
	GameManager.play_sfx("boss_win", 0.0)
	GameManager.play_music("victory")
	if player and is_instance_valid(player) and player.get("anim"):
		player.anim.play_victory()
	if boss_health_bar:
		boss_health_bar.hide()
	await show_ko(true)
	show_results(stars, true)

func _on_next_pressed() -> void:
	get_tree().paused = false
	var nxt = level_number + 1
	if nxt > 12:
		GameManager.change_scene("res://scenes/LevelSelect.tscn")
	else:
		GameManager.goto_level(nxt)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		pause_menu.visible = not pause_menu.visible
		get_tree().paused = pause_menu.visible
		if pause_menu.visible and touch_controls: touch_controls.release_all()
		if pause_menu.visible: _drop_toast()
		get_viewport().set_input_as_handled()

const HEART_FULL = preload("res://assets/ui/heart_full.png")
const HEART_EMPTY = preload("res://assets/ui/heart_empty.png")
var heart_icons: Array = []
var coin_count_label: Label
var domain_bar: ProgressBar
@onready var touch_controls = $CanvasLayer/TouchControls if has_node("CanvasLayer/TouchControls") else null

func _spawn_enemy(pos: Vector2, ranged: bool) -> void:
	var e = load("res://scenes/Enemy.tscn").instantiate()
	e.global_position = pos
	e.is_ranged = ranged
	$Enemies.add_child(e)

const PLATE_KEY := {1: "snow_village", 2: "mist_forest", 4: "boss_rin", 8: "boss_gorrah", 12: "boss_vey"}
func _plate_key() -> String:
	if PLATE_KEY.has(level_number): return PLATE_KEY[level_number]
	if StageBuilder.has_stage(level_number): return String(StageData.STAGES[level_number]["scenario"])
	return ""

func build_parallax() -> void:
	var pb = ParallaxBackground.new()
	add_child(pb); move_child(pb, 0)
	var theme = "boss" if level_number in [4, 8, 12] else ("forest" if level_number % 4 in [2, 3] else "snow")
	if StageBuilder.has_stage(level_number): theme = StageBuilder.theme_for(level_number)
	_theme = theme
	# NA2-style: desaturated fogged parallax + god rays, black near silhouettes (original procedural art)
	var layers = [["sky", 0.0], ["far", 0.15], ["rays", 0.25], ["mid", 0.4], ["near", 0.7]]
	# rich art pass: full-colour painted plates per scenario (assets/parallax/<key>/), drawn scaled down for hi-dpi
	var pkey := _plate_key()
	var plates := pkey != "" and ResourceLoader.exists("res://assets/parallax/%s/sky.webp" % pkey)
	for l in layers:
		var pl = ParallaxLayer.new()
		pl.motion_scale = Vector2(l[1], 0.0)
		var sp = Sprite2D.new()
		if plates and l[0] != "rays":
			sp.texture = load("res://assets/parallax/%s/%s.webp" % [pkey, l[0]])
			sp.scale = Vector2.ONE * (720.0 / sp.texture.get_height())
			pl.set_meta("plate", true)
		elif l[0] in ["far", "mid", "near"]:
			# shared painted silhouettes (white), tinted per theme
			sp.texture = load("res://assets/na2/shared_%s.png" % l[0])
			sp.modulate = LAYER_TINT[theme][l[0]]
			if l[0] in ["mid", "near"]:
				# polish: shaded painted layers (rim light, value ramp, mottling) instead of flat silhouettes
				var hm = ShaderMaterial.new(); hm.shader = preload("res://assets/shaders/painted_layer.gdshader")
				hm.set_shader_parameter("rim_color", LAYER_RIM[theme][l[0]])
				hm.set_shader_parameter("hud_clear", l[0] == "near")
				if l[0] == "mid": hm.set_shader_parameter("rim_px", 3.0)
				sp.material = hm
		else:
			sp.texture = load("res://assets/na2/%s_%s.png" % [theme, l[0]])
		# painted silhouettes are 2560 wide (mirrored, seamless); others 1280
		pl.motion_mirroring = Vector2(sp.texture.get_width() * sp.scale.x, 0) if l[1] > 0.0 else Vector2.ZERO
		if plates and l[0] == "rays": sp.modulate.a = 0.6
		sp.centered = false
		pl.add_child(sp)
		pb.add_child(pl)
		if l[0] == "rays":
			var tw = sp.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
			tw.tween_property(sp, "modulate:a", 0.55, 3.0); tw.tween_property(sp, "modulate:a", 1.0, 3.0)
	$Background.visible = false
	for m in [[0.3, 300, 0.7, 18.0], [0.55, 430, 1.0, -26.0]]:
		var mlay = ParallaxLayer.new(); mlay.motion_scale = Vector2(m[0], 0); mlay.motion_mirroring = Vector2(1280, 0); pb.add_child(mlay)
		var ms = Sprite2D.new(); ms.texture = load("res://assets/na2/mist.png"); ms.centered = false; ms.position = Vector2(0, m[1]); ms.modulate.a = m[2]; mlay.add_child(ms)
		var mt = ms.create_tween().set_loops()
		mt.tween_property(ms, "position:x", m[3] * 4, 6.0); mt.tween_property(ms, "position:x", 0.0, 6.0)
	var fpb = ParallaxBackground.new(); fpb.layer = 2; add_child(fpb); $CanvasLayer.layer = 5
	# screen-space vignette (darkens edges like NA2's painted framing)
	var vcl = CanvasLayer.new(); vcl.layer = 3; add_child(vcl)
	var vg = GradientTexture2D.new(); vg.fill = GradientTexture2D.FILL_RADIAL; vg.fill_from = Vector2(0.5, 0.45); vg.fill_to = Vector2(1.05, 1.05)
	var gr = Gradient.new(); gr.set_color(0, Color(0, 0, 0, 0)); gr.set_color(1, Color(0, 0, 0, 0.6)); gr.add_point(0.55, Color(0, 0, 0, 0)); vg.gradient = gr
	var vr = TextureRect.new(); vr.texture = vg; vr.size = Vector2(1280, 720); vr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; vr.mouse_filter = Control.MOUSE_FILTER_IGNORE; vcl.add_child(vr)
	# (old flat black fence-post / grass foreground strip retired: the painted ground carries the foreground now)
	var ml = ParallaxLayer.new(); ml.motion_scale = Vector2(0.75, 0); pb.add_child(ml)
	ml.add_child(GameManager.make_mist(500, 40.0))
	var pet = GameManager.make_petals(Vector2(900, 10), 90); pet.position = Vector2(640, -60); add_child(pet)
	if theme != "boss": pet.modulate = Color(3, 3, 3)  # snow/ash flakes instead of petals
	# swaying paper lanterns with pulsing glow along the street
	for x in ([470, 1150] if not level_number in [4, 8, 12] else [90, 1190]):
		var pivot = Node2D.new(); pivot.position = Vector2(x, 380); add_child(pivot)
		var g = Sprite2D.new(); g.texture = load("res://assets/sprites/glow.png"); g.position = Vector2(0, 30)
		g.modulate = Color(1, 1, 1, 0.8); pivot.add_child(g)
		var l = Sprite2D.new(); l.texture = load("res://assets/sprites/paper_lantern.png"); l.position = Vector2(0, 26); pivot.add_child(l)
		var tw = pivot.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
		tw.tween_property(pivot, "rotation", 0.12, 1.4 + x * 0.0004); tw.tween_property(pivot, "rotation", -0.12, 1.4 + x * 0.0004)
		var tg = g.create_tween().set_loops()
		tg.tween_property(g, "modulate:a", 0.45, 0.9); tg.tween_property(g, "modulate:a", 0.85, 0.9)
	# painted stage ground strip (walk line at the Floor body's y)
	var g = GROUND[_theme]
	var gtex: Texture2D = load("res://assets/env/ground_%s.png" % _theme)
	var floor_tr = TextureRect.new()
	floor_tr.texture = gtex
	floor_tr.stretch_mode = TextureRect.STRETCH_TILE; floor_tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	floor_tr.position = Vector2(-1280, -g["walk"]); floor_tr.size = Vector2(3840, gtex.get_height())
	var under = ColorRect.new()
	under.color = g["under"]
	under.position = Vector2(-1280, gtex.get_height() - g["walk"] - 2); under.size = Vector2(3840, 600)
	$World/Floor.add_child(under)
	$World/Floor.add_child(floor_tr)
	$World/Floor/VisualFloor.visible = false
	$World/Floor/VisualFloorGlow.visible = false

const LAYER_TINT = {   # polish: near layers lifted off pure black so the dark hero never sinks into them
	"snow": {"far": Color(0.84, 0.89, 0.95, 0.42), "mid": Color(0.22, 0.28, 0.38, 0.92), "near": Color(0.15, 0.19, 0.27, 0.96)},
	"forest": {"far": Color(0.82, 0.88, 0.84, 0.42), "mid": Color(0.20, 0.28, 0.27, 0.90), "near": Color(0.12, 0.19, 0.16, 0.96)},
	"boss": {"far": Color(0.63, 0.20, 0.20, 0.42), "mid": Color(0.22, 0.05, 0.07, 0.94), "near": Color(0.16, 0.04, 0.06, 0.96)},
}
const LAYER_RIM = {
	"snow": {"mid": Color(0.80, 0.88, 1.0, 0.55), "near": Color(0.92, 0.96, 1.0, 0.85)},     # snow caps / moonlight
	"forest": {"mid": Color(0.70, 0.85, 0.72, 0.45), "near": Color(0.62, 0.80, 0.55, 0.7)},   # mossy light
	"boss": {"mid": Color(1.0, 0.42, 0.35, 0.5), "near": Color(1.0, 0.35, 0.28, 0.75)},       # ember rim
}
const LEVEL_ROSTER := {
	3: ["crow_scout", "oni"], 5: ["kitsune_archer", "oni_brute", "crow_scout"], 6: ["bomb_monk", "oni"],
	7: ["shadow_assassin", "kitsune_archer"], 9: ["oni_brute", "bomb_monk"], 10: ["shadow_assassin", "crow_scout"],
	11: ["oni_brute", "kitsune_archer", "shadow_assassin"]}
var stage_info := {}
var _ambient := Color.WHITE
var _cmod: CanvasModulate
var _plight: PointLight2D
func _stage_ambience() -> void:
	## Phase 3: per-scenario sky tint, day/night ambience, weather, hero light for dark rooms
	var scen: String = stage_info["scenario"]
	var st: Dictionary = StageData.STAGES[level_number]
	for pb in get_children():
		if pb is ParallaxBackground:
			for layer in pb.get_children():
				if layer is CanvasItem and not layer.has_meta("plate"): layer.modulate = layer.modulate * StageBuilder.SKY_TINT.get(scen, Color.WHITE)
	_ambient = StageBuilder.AMBIENT.get(scen, Color.WHITE) if st["night"] else Color.WHITE
	_cmod = CanvasModulate.new(); _cmod.color = _ambient; add_child(_cmod)
	_plight = PointLight2D.new(); _plight.texture = load("res://assets/sprites/glow.png")
	_plight.texture_scale = Mechanics.LIGHT_PLAYER; _plight.energy = 0.35 if st["night"] else 0.0
	_plight.color = Color(0.7, 0.85, 1.0); player.add_child(_plight)
	_build_weather(st["weather"])

func set_darkness(on: bool) -> void:
	if _cmod == null: return
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_cmod, "color", Color(0.09, 0.09, 0.14) if on else _ambient, 0.6)
	tw.tween_property(_plight, "energy", 1.1 if on else (0.35 if StageData.STAGES[level_number]["night"] else 0.0), 0.6)
	for pb in get_children():
		if pb is ParallaxBackground:
			for layer in pb.get_children():
				if layer is CanvasItem:
					if not layer.has_meta("base_mod"): layer.set_meta("base_mod", layer.modulate)
					var bm: Color = layer.get_meta("base_mod")
					tw.tween_property(layer, "modulate", bm * Color(0.14, 0.14, 0.2, 1.0) if on else bm, 0.6)

func _build_weather(kind: String) -> void:
	var cl := CanvasLayer.new(); cl.layer = 4; cl.name = "Weather"; add_child(cl)
	var p := CPUParticles2D.new(); p.position = Vector2(640, -20)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE; p.emission_rect_extents = Vector2(760, 10)
	match kind:
		"rain":
			p.amount = 220; p.lifetime = 0.9; p.direction = Vector2(-0.25, 1); p.spread = 2; p.gravity = Vector2(0, 0)
			p.initial_velocity_min = 900; p.initial_velocity_max = 1150
			var tx := GradientTexture2D.new(); tx.width = 2; tx.height = 22
			var g := Gradient.new(); g.set_color(0, Color(1, 1, 1, 0)); g.set_color(1, Color(1, 1, 1, 0.6)); tx.gradient = g
			tx.fill_from = Vector2(0, 0); tx.fill_to = Vector2(0, 1); p.texture = tx; p.color = Color(0.7, 0.8, 1.0, 0.55)
		"embers":
			p.position = Vector2(640, 740); p.amount = 70; p.lifetime = 4.0; p.direction = Vector2(0.2, -1); p.spread = 25
			p.gravity = Vector2(0, -10); p.initial_velocity_min = 40; p.initial_velocity_max = 110
			p.texture = load("res://assets/fx/ember.png"); p.scale_amount_min = 0.35; p.scale_amount_max = 0.8; p.color = Color(1.0, 0.55, 0.15, 0.9)
		"petals":
			p.amount = 40; p.lifetime = 7.0; p.direction = Vector2(-0.5, 1); p.spread = 30; p.gravity = Vector2(0, 18)
			p.initial_velocity_min = 30; p.initial_velocity_max = 70; p.angular_velocity_min = -90; p.angular_velocity_max = 90
			p.texture = load("res://assets/sprites/petal.png"); p.scale_amount_min = 0.6; p.scale_amount_max = 1.0
		_:
			p.amount = 90; p.lifetime = 7.0; p.direction = Vector2(-0.2, 1); p.spread = 20; p.gravity = Vector2(0, 14)
			p.initial_velocity_min = 25; p.initial_velocity_max = 60; p.texture = load("res://assets/fx/flake.png")
			p.scale_amount_min = 0.25; p.scale_amount_max = 0.6; p.angular_velocity_min = -40; p.angular_velocity_max = 40
			p.color = Color(0.95, 0.97, 1.0, 0.85)
	p.preprocess = p.lifetime
	cl.add_child(p)

const ARENA_TINT := {8: Color(1.15, 0.85, 0.6), 12: Color(0.75, 0.62, 1.1)}
const LEVEL_NAMES = ["Ash Snow Gate", "Mist Hollow", "Lantern Row", "Rin's Moon Court", "Bamboo Veil", "Torii Falls Cave", "Kiyomizu Ledge", "Ember Shrine", "Willow Canal", "Frost Pagoda", "Night Palace", "Throne of Night"]

func build_hud() -> void:
	var hud = $CanvasLayer/HUD
	if victory_screen: victory_screen.hide()
	if health_label: health_label.visible = false
	if coins_label: coins_label.visible = false
	if level_label: level_label.visible = false

	# Compact top-left: round portrait + 3 numeric rows + stars under the portrait.
	var por := TextureRect.new()
	por.texture = load("res://assets/ui/portrait.png")
	por.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	por.position = Vector2(54 - 42, 62 - 42); por.size = Vector2(84, 84)
	hud.add_child(por)
	# forged gold ring with cardinal studs around the painted portrait; centre (54, 62), ø 97
	var ring := TextureRect.new()
	ring.texture = load("res://assets/ui/portrait_ring.png")
	ring.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ring.position = Vector2(54 - 48.5, 62 - 48.5); ring.size = Vector2(97, 97)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(ring)

	# (gold resource plate dropped in the polish pass: the rows float on the scene with ink outlines)

	hp_count_label = _hud_row(hud, 0, "hud_heart", "3", Color(0.90, 0.22, 0.22))
	gem_count_label = _hud_row(hud, 1, "hud_gem", str(GameManager.total_gems), Color(0.36, 0.78, 0.90))
	coin_count_label = _hud_row(hud, 2, "hud_gold", "0", Color(0.80, 0.64, 0.23))

	var srow := HBoxContainer.new()
	srow.position = Vector2(16, 114); srow.add_theme_constant_override("separation", 2)
	srow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(srow)
	hud_stars.clear()
	for k in range(3):
		var st := TextureRect.new()
		st.texture = load("res://assets/ui/star_empty.png")
		st.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		st.custom_minimum_size = Vector2(20, 20)
		srow.add_child(st); hud_stars.append(st)

	# Optional DOMAIN rite bar, bottom-centre — our unique special, not a second HP bar.
	domain_bar = ProgressBar.new()
	domain_bar.max_value = 1.0; domain_bar.value = 1.0; domain_bar.show_percentage = false
	domain_bar.anchor_left = 0.5; domain_bar.anchor_right = 0.5
	domain_bar.anchor_top = 1.0; domain_bar.anchor_bottom = 1.0
	domain_bar.offset_left = -110; domain_bar.offset_right = 110
	domain_bar.offset_top = -36; domain_bar.offset_bottom = -22
	var fs := StyleBoxTexture.new(); fs.texture = load("res://assets/ui/domain_fill.png")
	fs.texture_margin_left = 4; fs.texture_margin_right = 4
	var bs := StyleBoxFlat.new(); bs.bg_color = Color(0.02, 0.03, 0.06, 0.85)
	domain_bar.add_theme_stylebox_override("fill", fs)
	domain_bar.add_theme_stylebox_override("background", bs)
	hud.add_child(domain_bar)
	var dfr := TextureRect.new(); dfr.texture = load("res://assets/ui/domain_frame.png")
	dfr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dfr.position = Vector2(-20, -8); dfr.size = Vector2(260, 30)
	dfr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	domain_bar.add_child(dfr)
	# crescent-moon medallions cap both ends of the DOMAIN bar
	for mx in [-44.0, 226.0]:
		var md := TextureRect.new(); md.texture = load("res://assets/ui/domain_medal.png"); md.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		md.position = Vector2(mx, -12); md.size = Vector2(38, 38); md.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if mx > 0: md.flip_h = true
		domain_bar.add_child(md)
	var dl := Label.new(); dl.text = "DOMAIN"
	dl.anchor_left = 0.5; dl.anchor_right = 0.5; dl.anchor_top = 1.0; dl.anchor_bottom = 1.0
	dl.offset_left = -110; dl.offset_right = 110; dl.offset_top = -56; dl.offset_bottom = -36
	dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dl.add_theme_font_size_override("font_size", 15)
	if ResourceLoader.exists("res://content/original/fonts/SourceSerifPro-Bold.ttf"):
		dl.add_theme_font_override("font", load("res://content/original/fonts/SourceSerifPro-Bold.ttf"))
	dl.add_theme_color_override("font_color", Color(0.74, 0.90, 1))
	dl.add_theme_color_override("font_outline_color", Color(0, 0, 0)); dl.add_theme_constant_override("outline_size", 4)
	hud.add_child(dl)
	player.connect("domain_changed", func(r): domain_bar.value = r)

	if boss_health_bar and active_boss:
		_style_boss_bar()
	_update_coins()

func _hud_row(hud: Control, i: int, icon: String, text: String, col: Color) -> Label:
	var ic := TextureRect.new()
	ic.texture = load("res://assets/ui/%s.png" % icon)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.position = Vector2(118, 18 + i * 26); ic.size = Vector2(22, 22)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(ic)
	var l := Label.new()
	l.text = text
	l.position = Vector2(148, 14 + i * 26); l.size = Vector2(100, 28)
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 6)   # no plate behind the rows any more
	if ResourceLoader.exists("res://content/original/fonts/SourceSerifPro-Bold.ttf"):
		l.add_theme_font_override("font", load("res://content/original/fonts/SourceSerifPro-Bold.ttf"))
	hud.add_child(l)
	return l

func _style_boss_bar() -> void:
	# Ornate winged bar, name on the fill, ~42% wide, ~24 px tall. No unconfirmed PHASE II notch.
	boss_health_bar.show()
	boss_health_bar.show_percentage = false
	boss_health_bar.anchor_left = 0.5; boss_health_bar.anchor_right = 0.5
	boss_health_bar.anchor_top = 0.0; boss_health_bar.anchor_bottom = 0.0
	boss_health_bar.offset_left = -270; boss_health_bar.offset_right = 270
	boss_health_bar.offset_top = 24; boss_health_bar.offset_bottom = 48
	var bf := StyleBoxTexture.new(); bf.texture = load("res://assets/ui/boss_fill.png")
	bf.texture_margin_left = 6; bf.texture_margin_right = 6
	var bb := StyleBoxTexture.new(); bb.texture = load("res://assets/ui/boss_bg.png")
	boss_health_bar.add_theme_stylebox_override("fill", bf)
	boss_health_bar.add_theme_stylebox_override("background", bb)
	# drop any leftover caps / notch / name from earlier passes
	for c in boss_health_bar.get_children():
		c.queue_free()
	# forged gold frame with iron wings and ruby studs, drawn over the fill (original art)
	var fr := TextureRect.new()
	fr.texture = load("res://assets/ui/boss_frame.png")
	fr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fr.position = Vector2(-90, -18); fr.size = Vector2(720, 60)
	fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_health_bar.add_child(fr)
	# Phase 2: phase-2 threshold mark at half health
	var mk := Polygon2D.new()
	mk.polygon = PackedVector2Array([Vector2(0, -7), Vector2(6, 0), Vector2(0, 7), Vector2(-6, 0)])
	mk.color = Color(1.0, 0.86, 0.45); mk.position = Vector2(270, 12)
	var mk2 := Line2D.new(); mk2.width = 2; mk2.default_color = Color(0.1, 0.02, 0.02, 0.9)
	mk2.add_point(Vector2(270, 2)); mk2.add_point(Vector2(270, 22))
	boss_health_bar.add_child(mk2); boss_health_bar.add_child(mk)
	var nm := Label.new()
	nm.text = ["", "RIN THE PALE BLADE", "GORRAH THE STONE ONI", "SMOKE LORD VEY"][active_boss.boss_id if active_boss else 0]
	nm.set_anchors_preset(Control.PRESET_FULL_RECT)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nm.add_theme_font_size_override("font_size", 16)
	if ResourceLoader.exists("res://content/original/fonts/SourceSerifPro-Bold.ttf"):
		nm.add_theme_font_override("font", load("res://content/original/fonts/SourceSerifPro-Bold.ttf"))
	nm.add_theme_color_override("font_color", Color(0.98, 0.86, 0.78))
	nm.add_theme_color_override("font_outline_color", Color(0.20, 0.05, 0.05))
	nm.add_theme_constant_override("outline_size", 4)
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_health_bar.add_child(nm)

var hud_stars: Array = []
var hp_count_label: Label
var gem_count_label: Label

func _update_coins() -> void:
	var won = 0 if coins_collected == 0 else (3 if coins_collected >= total_coins_in_level else (2 if coins_collected * 2 >= total_coins_in_level else 1))
	for k in range(hud_stars.size()):
		hud_stars[k].texture = load("res://assets/ui/star_full.png" if k < won else "res://assets/ui/star_empty.png")
	if coin_count_label:
		coin_count_label.text = str(coins_collected)

# Draw the player (and aura) in front of the large right-side touch buttons.
# Touch stays on its own lower CanvasLayer so input still hits the buttons;
# HUD / pause / victory stay above the player.
var _pvis: Node2D
var _pvis_body: Sprite2D
var _pvis_aura: Sprite2D

func _setup_player_over_touch() -> void:
	$CanvasLayer.layer = 7
	var tcl = CanvasLayer.new()
	tcl.layer = 4
	tcl.name = "TouchLayer"
	add_child(tcl)
	if touch_controls:
		var par = touch_controls.get_parent()
		par.remove_child(touch_controls)
		tcl.add_child(touch_controls)
	var pcl = CanvasLayer.new()
	pcl.layer = 6
	pcl.name = "PlayerVis"
	add_child(pcl)
	_pvis = Node2D.new()
	pcl.add_child(_pvis)
	_pvis_aura = Sprite2D.new()
	_pvis.add_child(_pvis_aura)
	_pvis_body = Sprite2D.new()
	_pvis.add_child(_pvis_body)

func _sync_player_vis() -> void:
	if _pvis == null or player == null or not is_instance_valid(player):
		return
	var spr: Sprite2D = player.get("sprite") as Sprite2D
	if spr == null:
		return
	# Keep the world sprite in the tree (i-frames, afterimages, materials) but don't draw it
	# in world space, so the player isn't hidden behind the right-side touch buttons.
	if spr.visibility_layer != 0:
		spr.visibility_layer = 0
	var xf := spr.get_global_transform_with_canvas()
	_pvis.position = xf.origin
	_copy_vis(_pvis_body, spr, xf)
	var aura: Sprite2D = null
	for c in player.get_children():
		if c is Sprite2D and c != spr:
			aura = c
			break
	if aura and is_instance_valid(aura) and aura.texture:
		if aura.visibility_layer != 0:
			aura.visibility_layer = 0
		_copy_vis(_pvis_aura, aura, aura.get_global_transform_with_canvas())
		_pvis_aura.position = aura.get_global_transform_with_canvas().origin - xf.origin
		_pvis_aura.visible = aura.visible
	else:
		_pvis_aura.visible = false

func _copy_vis(dst: Sprite2D, src: Sprite2D, xf: Transform2D) -> void:
	dst.texture = src.texture
	dst.flip_h = src.flip_h
	dst.flip_v = src.flip_v
	dst.modulate = src.modulate
	dst.self_modulate = src.self_modulate
	dst.material = src.material
	dst.offset = src.offset
	dst.centered = src.centered
	dst.visible = src.visible
	# copy the full basis (rotation, squash / stretch and the animator's mirror flip);
	# the parent _pvis node carries the translation
	dst.transform = Transform2D(xf.x, xf.y, Vector2.ZERO)

func open_pause() -> void:
	if touch_controls: touch_controls.release_all()
	_drop_toast()
	if pause_menu:
		pause_menu.show()
		get_tree().paused = true

func apply_hide_ui(hidden: bool) -> void:
	if has_node("CanvasLayer/HUD"):
		$CanvasLayer/HUD.visible = not hidden
	if touch_controls:
		touch_controls.visible = not hidden
	# Gear is part of touch controls; Esc still opens pause.

func _coin_floater(world_pos: Vector2) -> void:
	var hud = $CanvasLayer/HUD
	var l := Label.new()
	l.text = "+1"
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_color", Color(0.80, 0.64, 0.23))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 4)
	l.position = world_pos * 0 + Vector2(620, 280)  # will set from canvas
	var xf: Transform2D
	if player:
		# approximate screen pos from the collected coin's last world point
		pass
	l.position = Vector2(600, 300)
	# Prefer a true canvas transform when the coin still exists; fallback is fine.
	hud.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 50.0, 0.7)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.7)
	tw.tween_callback(l.queue_free)

func show_ko(then_results := false) -> void:
	apply_hide_ui(true)
	var cl := CanvasLayer.new()
	cl.layer = 15
	cl.name = "KO"
	cl.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(cl)
	var haze := ColorRect.new()
	haze.color = Color(0.55, 0.05, 0.05, 0.22)
	haze.set_anchors_preset(Control.PRESET_FULL_RECT)
	haze.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(haze)
	# ink band with gold edges + a crimson dry-brush enso behind the letters
	var band := ColorRect.new(); band.color = Color(0.02, 0.0, 0.01, 0.62); band.position = Vector2(0, 262); band.size = Vector2(1280, 196)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE; cl.add_child(band)
	for yy in [262.0, 455.0]:
		var gl := ColorRect.new(); gl.color = Color(0.86, 0.68, 0.32, 0.95); gl.position = Vector2(0, yy); gl.size = Vector2(1280, 3)
		gl.mouse_filter = Control.MOUSE_FILTER_IGNORE; cl.add_child(gl)
	var en := Sprite2D.new(); en.texture = load("res://assets/fx/domain_enso.png"); en.position = Vector2(640, 360)
	en.modulate = Color(2.2, 0.25, 0.25, 0.9); en.scale = Vector2(0.62, 0.62); en.rotation = 0.8; cl.add_child(en)
	var etw = en.create_tween(); etw.tween_property(en, "scale", Vector2(0.7, 0.7), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var l := Label.new()
	l.text = "K.O."
	if ResourceLoader.exists("res://content/original/fonts/NanumBrushScript-Regular.ttf"):
		l.add_theme_font_override("font", load("res://content/original/fonts/NanumBrushScript-Regular.ttf"))
	l.add_theme_font_size_override("font_size", 210)
	l.add_theme_color_override("font_color", Color(0.95, 0.12, 0.10))
	l.add_theme_color_override("font_outline_color", Color(0.06, 0.0, 0.0))
	l.add_theme_constant_override("outline_size", 22)
	l.add_theme_color_override("font_shadow_color", Color(0.95, 0.72, 0.30, 0.9))
	l.add_theme_constant_override("shadow_offset_x", 0); l.add_theme_constant_override("shadow_offset_y", 7)
	l.add_theme_constant_override("shadow_outline_size", 22)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.offset_top = 36; l.offset_bottom = 36
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(l)
	await get_tree().create_timer(2.0, true, false, true).timeout
	if is_instance_valid(cl):
		cl.queue_free()

func show_results(star_count: int, is_boss: bool) -> void:
	if touch_controls: touch_controls.release_all()
	apply_hide_ui(true)
	if victory_screen: victory_screen.hide()
	get_tree().paused = true
	var cl := CanvasLayer.new()
	cl.layer = 16
	cl.name = "Results"
	cl.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(cl)
	var bg := TextureRect.new()
	bg.texture = load("res://assets/ui/menu_bg.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.modulate = Color(0.22, 0.22, 0.28)
	cl.add_child(bg)
	# Open book: crimson lacquer cover, left washi page, right dark-wood page. Original art + Kenney CC0 borders.
	var cover := TextureRect.new()
	cover.texture = load("res://assets/ui/book_cover.png")
	cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cover.position = Vector2(200, 40); cover.size = Vector2(880, 640)
	cl.add_child(cover)
	var left := TextureRect.new()
	left.texture = load("res://assets/ui/book_page_l.png")
	left.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	left.position = Vector2(240, 80); left.size = Vector2(400, 560)
	cl.add_child(left)
	var right := TextureRect.new()
	right.texture = load("res://assets/ui/book_page_r.png")
	right.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	right.position = Vector2(640, 80); right.size = Vector2(400, 560)
	cl.add_child(right)

	var head := Label.new()
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.position = Vector2(240, 200); head.size = Vector2(400, 40)
	_book_font(head, 22, Color(0.24, 0.13, 0.06), true)
	cl.add_child(head)
	var mid := Label.new()
	mid.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mid.position = Vector2(240, 240); mid.size = Vector2(400, 80)
	_book_font(mid, 56, Color(0.55, 0.06, 0.06), true)
	cl.add_child(mid)
	var sub := Label.new()
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(240, 330); sub.size = Vector2(400, 40)
	_book_font(sub, 22, Color(0.24, 0.13, 0.06), true)
	cl.add_child(sub)

	if is_boss:
		head.text = "BOSS STAGE"
		mid.text = "COMPLETED"
		mid.add_theme_font_size_override("font_size", 36)
		sub.text = ""
		var blurb := Label.new()
		blurb.text = "The shrine falls silent.\nReturn to the gate and ready\nthe next act."
		blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		blurb.position = Vector2(670, 200); blurb.size = Vector2(340, 140)
		blurb.autowrap_mode = TextServer.AUTOWRAP_WORD
		_book_font(blurb, 20, Color(0.88, 0.86, 0.80))
		cl.add_child(blurb)
		var menu := GameManager.wood_button("MAIN MENU", 280, 60, false)
		menu.position = Vector2(700, 380)
		menu.pressed.connect(func():
			GameManager.play_sfx("click")
			get_tree().paused = false
			GameManager.change_scene("res://scenes/Hub.tscn"))
		cl.add_child(menu)
	else:
		head.text = "STAGE"
		mid.text = str(level_number)
		sub.text = "COMPLETED"
		var row := HBoxContainer.new()
		row.position = Vector2(378, 390)
		row.add_theme_constant_override("separation", 8)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		cl.add_child(row)
		for k in range(3):
			var st := TextureRect.new()
			st.texture = load("res://assets/ui/star_full.png" if k < star_count else "res://assets/ui/star_empty.png")
			st.custom_minimum_size = Vector2(36, 36)
			st.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			row.add_child(st)
			UIJuice.pop_in(st, RESULT_STAR_DELAY + RESULT_STAR_STAGGER * k)
		var cc := Label.new(); cc.position = Vector2(378, 440); cc.size = Vector2(150, 34)
		cc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_book_font(cc, 24, Color(0.24, 0.13, 0.06), true); cl.add_child(cc)
		var ctw := cc.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		ctw.tween_method(func(v): cc.text = "COINS %d" % int(v), 0.0, float(coins_collected), 0.0 if GameManager.reduced_motion else 0.9).set_delay(0.5)
		var nextb := GameManager.wood_button("NEXT STAGE", 280, 60, true)
		nextb.position = Vector2(700, 200)
		nextb.pressed.connect(func():
			GameManager.play_sfx("click")
			get_tree().paused = false
			_on_next_pressed())
		cl.add_child(nextb)
		var rst := GameManager.wood_button("RESTART", 280, 60, false)
		rst.position = Vector2(700, 280)
		rst.pressed.connect(func():
			GameManager.play_sfx("click")
			get_tree().paused = false
			get_tree().reload_current_scene())
		cl.add_child(rst)
		var menu := GameManager.wood_button("MAIN MENU", 280, 60, false)
		menu.position = Vector2(700, 360)
		menu.pressed.connect(func():
			GameManager.play_sfx("click")
			get_tree().paused = false
			GameManager.change_scene("res://scenes/Hub.tscn"))
		cl.add_child(menu)

func _book_font(l: Label, size: int, col: Color, ink := false) -> void:
	var f := "res://content/original/fonts/SourceSerifPro-Bold.ttf" if ink else "res://content/original/fonts/SourceSerifPro-Regular.ttf"
	if ResourceLoader.exists(f):
		l.add_theme_font_override("font", load(f))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if ink:
		# ink on washi: no dark outline, faint paper-light halo
		l.add_theme_color_override("font_outline_color", Color(0.98, 0.93, 0.82, 0.5))
		l.add_theme_constant_override("outline_size", 2)
	else:
		l.add_theme_color_override("font_outline_color", Color(0.10, 0.06, 0.03))
		l.add_theme_constant_override("outline_size", 3)

func _drop_toast() -> void:
	# the level-name banner shouldn't sit on top of the pause card
	for c in $CanvasLayer/HUD.get_children():
		if str(c.name).begins_with("LevelToast"):
			c.queue_free()
