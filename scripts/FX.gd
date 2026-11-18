extends Node
# Original combat VFX helpers (all procedural).
class_name FX

static func ink_slash(parent: Node, pos: Vector2, dir: int, col := Color(0.02, 0.02, 0.05, 0.98), r := 84.0) -> void:
	# NA2-style crescent: wide ink body, hot white core, cyan edge, lingering ghost arcs.
	var layers = [[30.0, col, 0.0, 0.30], [16.0, Color(0.55, 0.85, 1, 0.95), 6.0, 0.24], [7.0, Color(1, 1, 1, 1), 10.0, 0.18], [22.0, Color(0, 0, 0, 0.55), -14.0, 0.40]]
	for k in range(layers.size()):
		var L = layers[k]
		var l = Line2D.new()
		l.width = L[0]; l.default_color = L[1]
		var w = Curve.new(); w.add_point(Vector2(0, 0.0)); w.add_point(Vector2(0.55, 1)); w.add_point(Vector2(1, 0.05)); l.width_curve = w
		var g = Gradient.new(); g.set_color(0, Color(1, 1, 1, 0)); g.set_color(1, Color(1, 1, 1, 1)); l.gradient = g
		for i in range(18):
			var a = lerp(-1.5, 1.25, i / 17.0)
			l.add_point(Vector2(cos(a) * dir, sin(a)) * (r - L[2]))
		l.global_position = pos; l.begin_cap_mode = Line2D.LINE_CAP_ROUND; l.end_cap_mode = Line2D.LINE_CAP_ROUND
		l.modulate = L[1]; l.default_color = Color(1, 1, 1)
		parent.add_child(l)
		var tw = l.create_tween()
		tw.tween_property(l, "modulate:a", 0.0, L[3]).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(l, "scale", Vector2(1.3, 1.12), L[3])
		tw.parallel().tween_property(l, "rotation", 0.25 * dir, L[3])
		tw.tween_callback(l.queue_free)
	sparks(parent, pos + Vector2(r * 0.8 * dir, 0), Color(0.75, 0.92, 1), 10, dir)

static func sparks(parent: Node, pos: Vector2, col: Color, n := 14, dir := 0) -> void:
	var p = Pool.particles()
	p.amount = n; p.lifetime = 0.35; p.explosiveness = 1.0
	p.direction = Vector2(dir, -0.3) if dir != 0 else Vector2(0, -1); p.spread = 55.0 if dir != 0 else 180.0
	p.initial_velocity_min = 260; p.initial_velocity_max = 560; p.damping_min = 300; p.damping_max = 500
	p.gravity = Vector2(0, 600); p.scale_amount_min = 2; p.scale_amount_max = 4; p.color = col
	_roundify(p); Pool.fire(p, parent, pos, 0.7)

const BOSS_BURST_SCALE := 2.6     # bosses: bigger, longer, more particles
static func death_burst(parent: Node, pos: Vector2, size := 1.0) -> void:
	# ink + crimson particle burst, 44 particles at size 1, plus a fading ink ring.
	# `size` scales count, speed, particle size, ring and lifetime (bosses use BOSS_BURST_SCALE).
	var life := 0.7 * sqrt(size)
	for c in [[Color(0.85, 0.08, 0.12), 26, 5.0], [Color(0.0, 0.0, 0.0), 18, 8.0]]:
		var p = CPUParticles2D.new()
		p.one_shot = true; p.emitting = true; p.amount = int(c[1] * size); p.lifetime = life; p.explosiveness = 1.0
		p.spread = 180.0; p.initial_velocity_min = 160 * size; p.initial_velocity_max = 420 * size; p.damping_min = 120; p.damping_max = 260
		p.gravity = Vector2(0, 700); p.scale_amount_min = c[2] * 0.5 * sqrt(size); p.scale_amount_max = c[2] * sqrt(size); p.color = c[0]
		_roundify(p); p.global_position = pos; parent.add_child(p)
		parent.get_tree().create_timer(life + 0.5).timeout.connect(p.queue_free)
	var rings := 1 if size <= 1.0 else 2
	for r in range(rings):
		var ring = Line2D.new(); ring.width = 6 * sqrt(size); ring.default_color = Color(1, 1, 1, 0.9) if r == 0 else Color(1, 0.25, 0.3, 0.8)
		for i in range(33): ring.add_point(Vector2(cos(i * TAU / 32), sin(i * TAU / 32)) * 20)
		ring.global_position = pos; parent.add_child(ring)
		var tw = ring.create_tween(); tw.tween_interval(0.08 * r)
		tw.tween_property(ring, "scale", Vector2(4, 4) * size, 0.25 * sqrt(size)); tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.25 * sqrt(size)); tw.tween_callback(ring.queue_free)

## Fading, toppling copy of a sprite left where the hero fell (respawn stays instant).
static func death_ghost(parent: Node, spr: Sprite2D) -> void:
	if spr == null or parent == null or not spr.is_inside_tree(): return
	var g = Sprite2D.new(); g.texture = spr.texture; g.offset = spr.offset; g.material = spr.material
	g.modulate = Color(0.75, 0.8, 1.0, 0.9); parent.add_child(g)
	g.global_transform = spr.global_transform
	var tw = g.create_tween()
	tw.tween_property(g, "rotation", g.rotation - 1.35 * signf(g.global_transform.x.x), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(g, "modulate:a", 0.0, 0.6)
	tw.tween_callback(g.queue_free)

static var _dot_tex: GradientTexture2D
static func _dot() -> GradientTexture2D:
	# soft round particle so sparks/ink read as droplets, not square pixels
	if _dot_tex == null:
		_dot_tex = GradientTexture2D.new(); _dot_tex.width = 16; _dot_tex.height = 16
		_dot_tex.fill = GradientTexture2D.FILL_RADIAL; _dot_tex.fill_from = Vector2(0.5, 0.5); _dot_tex.fill_to = Vector2(1.0, 0.5)
		var g := Gradient.new(); g.set_color(0, Color(1, 1, 1, 1)); g.set_color(1, Color(1, 1, 1, 0)); g.add_point(0.55, Color(1, 1, 1, 0.9))
		_dot_tex.gradient = g
	return _dot_tex

static func _roundify(p: CPUParticles2D) -> void:
	p.texture = _dot()
	p.scale_amount_min /= 10.0; p.scale_amount_max /= 10.0

static func silhouette(spr: CanvasItem, keep_sat := 0.55, rim := Color(0.72, 0.86, 1)) -> void:
	var m = ShaderMaterial.new(); m.shader = preload("res://assets/shaders/silhouette.gdshader")
	m.set_shader_parameter("keep_sat", keep_sat); m.set_shader_parameter("rim_color", rim)
	spr.material = m

static func painted(spr: CanvasItem, rim := Color(0.72, 0.86, 1), rim_amt := 0.45, tint := Color(1, 1, 1), lift := 0.0) -> void:
	var m = ShaderMaterial.new(); m.shader = preload("res://assets/shaders/painted.gdshader")
	m.set_shader_parameter("rim_color", rim); m.set_shader_parameter("rim_amt", rim_amt)
	m.set_shader_parameter("tint", tint); m.set_shader_parameter("lift", lift)
	spr.material = m

static func flash(spr: CanvasItem, dur := 0.1) -> void:
	if spr == null or not (spr.material is ShaderMaterial): return
	var m: ShaderMaterial = spr.material
	m.set_shader_parameter("flash", 1.0)
	var tw = spr.create_tween(); tw.tween_method(func(v): m.set_shader_parameter("flash", v), 1.0, 0.0, dur)

static func hit_burst(parent: Node, pos: Vector2, col := Color(0.6, 0.9, 1)) -> void:
	var p = Pool.particles()
	p.amount = 30; p.lifetime = 0.5; p.explosiveness = 1.0
	p.spread = 180.0; p.initial_velocity_min = 140; p.initial_velocity_max = 320
	p.gravity = Vector2(0, 400); p.scale_amount_min = 3; p.scale_amount_max = 6; p.color = col
	_roundify(p); Pool.fire(p, parent, pos, 0.8)
	var star = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in range(16):
		var rr = 58.0 if i % 2 == 0 else 12.0
		pts.append(Vector2(cos(i * PI / 8), sin(i * PI / 8)) * rr)
	star.polygon = pts; star.color = Color(1, 1, 1, 0.95); star.global_position = pos; parent.add_child(star)
	var tw = star.create_tween(); tw.tween_property(star, "scale", Vector2(1.6, 1.6), 0.12); tw.parallel().tween_property(star, "modulate:a", 0.0, 0.12)
	tw.tween_callback(star.queue_free)

static func freeze(tree: SceneTree, dur: float) -> void:
	tree.paused = true
	tree.create_timer(dur, true).timeout.connect(func(): tree.paused = false)

static func hit_stop(tree: SceneTree, dur := 0.06) -> void:
	Engine.time_scale = 0.05
	tree.create_timer(dur, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)

static func dust(parent: Node, pos: Vector2, n := 8, dir := 0) -> void:
	## soft grey-blue puffs for landings (dir 0, both sides) and run steps (dir = kick-back side)
	var p = Pool.particles()
	p.amount = maxi(n, 1); p.lifetime = 0.45; p.explosiveness = 0.9
	p.direction = Vector2(dir if dir != 0 else 1, -0.35); p.spread = 30.0 if dir != 0 else 180.0
	p.initial_velocity_min = 30; p.initial_velocity_max = 110 if dir == 0 else 60
	p.gravity = Vector2(0, -30); p.damping_min = 60; p.damping_max = 120
	p.scale_amount_min = 4; p.scale_amount_max = 9; p.color = Color(0.82, 0.86, 0.95, 0.55)
	var g := Gradient.new(); g.set_color(0, Color(1, 1, 1, 0.8)); g.set_color(1, Color(1, 1, 1, 0)); p.color_ramp = g
	_roundify(p); Pool.fire(p, parent, pos, 0.7)

static func afterimage(parent: Node, spr: Sprite2D) -> void:
	var g = Sprite2D.new(); g.texture = spr.texture
	g.offset = spr.offset; g.hframes = spr.hframes; g.frame = spr.frame
	g.modulate = Color(0.4, 0.75, 1, 0.6); parent.add_child(g)
	g.global_transform = spr.global_transform   # keeps the animator's flip, lean and squash
	var tw = g.create_tween(); tw.tween_property(g, "modulate:a", 0.0, 0.25); tw.tween_callback(g.queue_free)

static func toast(scene: Node, text: String, col := Color(0.7, 0.9, 1)) -> void:
	# NA2-inspired gold serif banner (original art): top-centre plate with diamond caps.
	var hud = scene.get_node_or_null("CanvasLayer/HUD")
	if hud == null: return
	var banner = Control.new()
	banner.name = "LevelToast"
	banner.anchor_left = 0.5; banner.anchor_right = 0.5; banner.anchor_top = 0.0; banner.anchor_bottom = 0.0
	banner.offset_left = -256; banner.offset_right = 256; banner.offset_top = 128; banner.offset_bottom = 184
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# forged gold-rimmed lacquer plate with crimson-jewel end caps (original art)
	var plate = TextureRect.new(); plate.texture = load("res://assets/ui/stage_banner.png")
	plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plate.set_anchors_preset(Control.PRESET_FULL_RECT); plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(plate)
	var l = Label.new(); l.text = text
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 28)
	l.add_theme_color_override("font_color", Color(1.0, 0.92, 0.70))
	l.add_theme_color_override("font_outline_color", Color(0.18, 0.10, 0.02)); l.add_theme_constant_override("outline_size", 6)
	if ResourceLoader.exists("res://content/original/fonts/SourceSerifPro-Bold.ttf"):
		l.add_theme_font_override("font", load("res://content/original/fonts/SourceSerifPro-Bold.ttf"))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(l)
	hud.add_child(banner); banner.z_index = 30
	banner.modulate.a = 0.0
	var tw = banner.create_tween()
	tw.tween_property(banner, "modulate:a", 1.0, 0.18)
	tw.parallel().tween_property(banner, "offset_top", 136.0, 0.18).from(118.0)
	tw.tween_interval(1.65)
	tw.tween_property(banner, "modulate:a", 0.0, 0.22)
	tw.tween_callback(banner.queue_free)

static func cut_in(scene: Node, move_name: String) -> void:
	# Special-move cut-in: diagonal ink band, hero portrait, speed lines, move name, white impact frame.
	var cl = CanvasLayer.new(); cl.layer = 20; cl.process_mode = Node.PROCESS_MODE_ALWAYS; scene.add_child(cl)
	var band = Polygon2D.new(); band.polygon = PackedVector2Array([Vector2(0, 250), Vector2(1280, 200), Vector2(1280, 420), Vector2(0, 470)])
	band.color = Color(0.03, 0.04, 0.1, 0.92); cl.add_child(band)
	# forged gold edges on the ink band
	for e in [[Vector2(0, 250), Vector2(1280, 200)], [Vector2(0, 470), Vector2(1280, 420)]]:
		var gl = Line2D.new(); gl.add_point(e[0]); gl.add_point(e[1]); gl.width = 5
		gl.default_color = Color(0.86, 0.66, 0.28, 1); band.add_child(gl)
		var gl2 = Line2D.new(); gl2.add_point(e[0] + Vector2(0, 2)); gl2.add_point(e[1] + Vector2(0, 2)); gl2.width = 1.5
		gl2.default_color = Color(1, 0.93, 0.7, 0.9); band.add_child(gl2)
	for i in range(26):
		var ln = Line2D.new(); var y = randf_range(205, 465); var x = randf_range(0, 1280)
		ln.add_point(Vector2(x, y)); ln.add_point(Vector2(x - randf_range(120, 380), y + 8)); ln.width = randf_range(1, 4)
		ln.default_color = Color(0.5, 0.85, 1, 0.7); cl.add_child(ln)
	var por = TextureRect.new(); por.texture = load("res://assets/ui/portrait.png"); por.position = Vector2(-260, 210); por.size = Vector2(240, 240)
	por.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; cl.add_child(por)
	var pring = TextureRect.new(); pring.texture = load("res://assets/ui/portrait_ring.png"); pring.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pring.position = Vector2(-14, -14); pring.size = Vector2(268, 268); por.add_child(pring)
	var nm = Label.new(); nm.text = move_name; nm.position = Vector2(1300, 300)
	nm.add_theme_font_size_override("font_size", 52); nm.add_theme_color_override("font_color", Color(1.0, 0.92, 0.70))
	if ResourceLoader.exists("res://content/original/fonts/SourceSerifPro-Bold.ttf"):
		nm.add_theme_font_override("font", load("res://content/original/fonts/SourceSerifPro-Bold.ttf"))
	nm.add_theme_color_override("font_shadow_color", Color(0.2, 0.5, 1.0, 0.8)); nm.add_theme_constant_override("shadow_outline_size", 14)
	nm.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.0)); nm.add_theme_constant_override("outline_size", 10); cl.add_child(nm)
	var flash = ColorRect.new(); flash.color = Color(1, 1, 1, 0); flash.size = Vector2(1280, 720); cl.add_child(flash)
	var tw = cl.create_tween()
	tw.tween_property(por, "position:x", 140.0, 0.15)
	tw.parallel().tween_property(nm, "position:x", 430.0, 0.18)
	tw.tween_interval(0.45)
	tw.tween_property(flash, "color:a", 0.9, 0.04)
	tw.tween_property(flash, "color:a", 0.0, 0.12)
	tw.parallel().tween_property(band, "modulate:a", 0.0, 0.15)
	tw.parallel().tween_property(por, "modulate:a", 0.0, 0.15)
	tw.parallel().tween_property(nm, "modulate:a", 0.0, 0.3)
	tw.tween_callback(cl.queue_free)
