class_name Mechanics
## Phase 3 stage mechanics (one inner class each). All hazards deal 1 damage (SPEC 4);
## numbers below are new content, listed in the Phase 3 report.
const T := 32.0
const MOVE_PERIOD := 4.0          # s for a full there-and-back trip (moving platform / lift)
const CRUMBLE_DELAY := 0.45       # s of shaking before a crumble tile drops
const CRUMBLE_RESPAWN := 2.5
const SPRING_VELOCITY := -820.0   # px/s launch (normal jump is -500)
const SPIKE_CYCLE := [1.2, 0.4, 1.0]   # off, warning, on (s)
const SAW_PERIOD := 2.4
const WIND_PUSH := 150.0          # px/s horizontal drift during a gust
const WIND_CYCLE := [2.2, 1.6, 0.5]    # gust on, calm, warning (s)
const WATER_RISE := 28.0          # px/s
const GATE_RECLOSE := 7.0
const ROPE_JUMP_BOOST := -350.0   # px/s added upward when letting go of a rope
const LIGHT_PLAYER := 1.6         # light texture scale around the hero in dark rooms
const LIGHT_LANTERN := 3.4

static func player_of(n: Node) -> Node2D:
	var sc := n.get_tree().current_scene if n.is_inside_tree() else null
	return sc.get_node_or_null("Player") if sc else null

static func box(n: CollisionObject2D, size: Vector2, offset := Vector2.ZERO) -> void:
	var cs := CollisionShape2D.new(); var sh := RectangleShape2D.new(); sh.size = size; cs.shape = sh; cs.position = offset; n.add_child(cs)

static func tile_rect(n: Node, size: Vector2, tex: Texture2D, region: Rect2) -> void:
	var a := AtlasTexture.new(); a.atlas = tex; a.region = region
	var tr := TextureRect.new(); tr.texture = a; tr.stretch_mode = TextureRect.STRETCH_TILE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; tr.size = size; tr.position = -size / 2.0
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE; n.add_child(tr)

## ---------------- moving platform / lift ----------------
class MovingPlatform extends AnimatableBody2D:
	var travel := Vector2(T * 8, 0)
	var width := 3
	var tex: Texture2D
	var region := Rect2()
	var _start := Vector2.ZERO
	var _t := 0.0
	func _ready() -> void:
		collision_layer = 1; sync_to_physics = true
		_start = position
		var sz := Vector2(width * T, 14)
		Mechanics.box(self, sz, Vector2(0, -T / 2.0 + 7))
		var vis := Node2D.new(); vis.position = Vector2(0, -T / 2.0 + 7); add_child(vis)
		Mechanics.tile_rect(vis, Vector2(width * T, 16), tex, region)
		var ch := Line2D.new(); ch.width = 2; ch.default_color = Color(0.1, 0.08, 0.06, 0.8)   # hanging chains
		for side in [-1, 1]:
			var l := Line2D.new(); l.width = 2; l.default_color = Color(0.15, 0.12, 0.1, 0.7)
			l.add_point(Vector2(side * width * T * 0.4, -T / 2.0)); l.add_point(Vector2(side * width * T * 0.4, -T / 2.0 - 900)); add_child(l)
	func _physics_process(delta: float) -> void:
		_t += delta
		position = _start + travel * (0.5 - 0.5 * cos(_t * TAU / Mechanics.MOVE_PERIOD))

## ---------------- crumbling tile ----------------
class Crumble extends StaticBody2D:
	var tex: Texture2D
	var region := Rect2()
	var _cs: CollisionShape2D
	var _vis: Node2D
	var _busy := false
	func _ready() -> void:
		collision_layer = 1
		Mechanics.box(self, Vector2(T, T))
		_cs = get_child(0)
		_vis = Node2D.new(); add_child(_vis)
		Mechanics.tile_rect(_vis, Vector2(T, T), tex, region)
		var cr := Line2D.new(); cr.width = 2; cr.default_color = Color(0.05, 0.03, 0.02, 0.9)
		for p in [Vector2(-10, -16), Vector2(-3, -4), Vector2(4, 2), Vector2(2, 16)]: cr.add_point(p)
		_vis.add_child(cr)
		var a := Area2D.new(); a.collision_layer = 0; a.collision_mask = 2
		Mechanics.box(a, Vector2(T - 4, 8), Vector2(0, -T / 2.0 - 4)); add_child(a)
		a.body_entered.connect(func(b): if b.name == "Player": _trigger())
	func _trigger() -> void:
		if _busy: return
		_busy = true
		GameManager.play_sfx("crumble")
		var tw := create_tween()
		for i in range(6):
			tw.tween_property(_vis, "position:x", 2.0 if i % 2 == 0 else -2.0, Mechanics.CRUMBLE_DELAY / 6.0)
		tw.tween_callback(func(): _cs.set_deferred("disabled", true))
		tw.tween_property(_vis, "position:y", 40.0, 0.3)
		tw.parallel().tween_property(_vis, "modulate:a", 0.0, 0.3)
		tw.tween_interval(Mechanics.CRUMBLE_RESPAWN)
		tw.tween_callback(func(): _cs.set_deferred("disabled", false); _vis.position = Vector2.ZERO; _busy = false)
		tw.tween_property(_vis, "modulate:a", 1.0, 0.25)

## ---------------- spring ----------------
class Spring extends Area2D:
	var _plate: Polygon2D
	func _ready() -> void:
		collision_layer = 0; collision_mask = 2
		Mechanics.box(self, Vector2(28, 14), Vector2(0, 9))
		var coil := Line2D.new(); coil.width = 3; coil.default_color = Color(0.75, 0.6, 0.3)
		for i in range(7): coil.add_point(Vector2(-8 if i % 2 == 0 else 8, 16 - i * 2.2))
		add_child(coil)
		_plate = Polygon2D.new(); _plate.polygon = PackedVector2Array([Vector2(-14, 0), Vector2(14, 0), Vector2(12, 4), Vector2(-12, 4)])
		_plate.color = Color(0.85, 0.2, 0.15); _plate.position = Vector2(0, 2); add_child(_plate)
		body_entered.connect(_on_body)
	func _on_body(b: Node) -> void:
		if b.name != "Player" or b.velocity.y < -50.0: return
		b.velocity.y = Mechanics.SPRING_VELOCITY
		b.can_double_jump = true
		if b.get("anim"): b.anim.play_land(0.8)
		GameManager.play_sfx("spring")
		var tw := _plate.create_tween(); tw.tween_property(_plate, "position:y", 10.0, 0.05); tw.tween_property(_plate, "position:y", 2.0, 0.2).set_trans(Tween.TRANS_ELASTIC)

## ---------------- timed spikes / fire jets ----------------
class TimedSpike extends Area2D:
	var phase := 0.0
	var fire := false
	var _vis: Node2D
	var _on := false
	func _ready() -> void:
		collision_layer = 0; collision_mask = 2
		Mechanics.box(self, Vector2(26, 22), Vector2(0, 5))
		_vis = Node2D.new(); add_child(_vis)
		if fire:
			var g := Sprite2D.new(); g.texture = load("res://assets/sprites/glow.png"); g.modulate = Color(1, 0.5, 0.1, 0.9); g.scale = Vector2(0.35, 0.6); g.position = Vector2(0, -6); _vis.add_child(g)
		var sp := Sprite2D.new(); sp.texture = load("res://assets/sprites/spike.png"); sp.scale = Vector2(0.45, 0.6); sp.position = Vector2(0, 6)
		if fire: sp.modulate = Color(1.0, 0.55, 0.25)
		_vis.add_child(sp)
		var base := ColorRect.new(); base.color = Color(0.08, 0.06, 0.06); base.size = Vector2(30, 4); base.position = Vector2(-15, 14); add_child(base)
	func _physics_process(_d: float) -> void:
		var c: Array = Mechanics.SPIKE_CYCLE
		var period: float = c[0] + c[1] + c[2]
		var t := fmod(Time.get_ticks_msec() / 1000.0 + phase, period)
		var warn: bool = t >= c[0] and t < c[0] + c[1]
		_on = t >= c[0] + c[1]
		_vis.position.y = 0.0 if _on else (10.0 if warn else 22.0)
		_vis.modulate.a = 1.0 if _on else (0.55 + 0.4 * float(int(t * 16.0) % 2) if warn else 0.0)
		if _on:
			for b in get_overlapping_bodies():
				if b.name == "Player": b.take_damage(1)

## ---------------- saw ----------------
class Saw extends Area2D:
	var travel := Vector2(T * 3, 0)
	var _start := Vector2.ZERO
	var _spr: Sprite2D
	func _ready() -> void:
		collision_layer = 0; collision_mask = 2
		_start = position
		var cs := CollisionShape2D.new(); var sh := CircleShape2D.new(); sh.radius = 20; cs.shape = sh; add_child(cs)
		_spr = Sprite2D.new(); _spr.texture = load("res://assets/sprites/saw.png"); _spr.scale = Vector2(1.5, 1.5); add_child(_spr)
		var rail := Line2D.new(); rail.width = 3; rail.default_color = Color(0.1, 0.08, 0.08, 0.8); rail.z_index = -1
		rail.add_point(-travel); rail.add_point(travel); add_child(rail)
		rail.set_as_top_level(true); rail.global_position = _start
	func _physics_process(delta: float) -> void:
		_spr.rotation += delta * 12.0
		position = _start + travel * sin(Time.get_ticks_msec() / 1000.0 * TAU / Mechanics.SAW_PERIOD)
		for b in get_overlapping_bodies():
			if b.name == "Player": b.take_damage(1)

## ---------------- wind zone ----------------
class Wind extends Area2D:
	var dir := 1
	var size := Vector2(800, 448)
	var _p: CPUParticles2D
	var _gust := false
	var _t := 0.0
	func _ready() -> void:
		collision_layer = 0; collision_mask = 2
		Mechanics.box(self, size)
		_p = CPUParticles2D.new(); _p.amount = 70; _p.lifetime = 1.2; _p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		_p.emission_rect_extents = size / 2.0; _p.direction = Vector2(dir, 0); _p.spread = 4; _p.gravity = Vector2.ZERO
		_p.initial_velocity_min = 380; _p.initial_velocity_max = 520; _p.scale_amount_min = 1; _p.scale_amount_max = 2
		var tex := GradientTexture2D.new(); tex.width = 26; tex.height = 2
		var g := Gradient.new(); g.set_color(0, Color(1, 1, 1, 0)); g.set_color(1, Color(1, 1, 1, 0.8)); tex.gradient = g
		if dir < 0: tex.fill_from = Vector2(1, 0); tex.fill_to = Vector2(0, 0)
		_p.texture = tex; _p.color = Color(0.85, 0.92, 1.0, 0.7); _p.emitting = false; add_child(_p)
	func _physics_process(delta: float) -> void:
		var c: Array = Mechanics.WIND_CYCLE
		_t = fmod(_t + delta, c[0] + c[1])
		_gust = _t < c[0]
		var warn: bool = not _gust and _t > c[0] + c[1] - c[2]
		_p.emitting = _gust or warn
		_p.speed_scale = 1.0 if _gust else 0.4
		if _gust:
			for b in get_overlapping_bodies():
				if b.name == "Player" and not b.get("rope"): b.global_position.x += dir * Mechanics.WIND_PUSH * delta

## ---------------- dark zone + lanterns ----------------
class DarkZone extends Area2D:
	var size := Vector2(800, 448)
	func _ready() -> void:
		collision_layer = 0; collision_mask = 2
		Mechanics.box(self, size)
		body_entered.connect(func(b): if b.name == "Player": _toggle(true))
		body_exited.connect(func(b): if b.name == "Player": _toggle(false))
	func _toggle(on: bool) -> void:
		var lvl := get_tree().current_scene
		if lvl and lvl.has_method("set_darkness"): lvl.set_darkness(on)

class Lantern extends Area2D:
	var _light: PointLight2D
	var _lit := false
	func _ready() -> void:
		collision_layer = 0; collision_mask = 2
		Mechanics.box(self, Vector2(40, 64), Vector2(0, -16))
		var post := ColorRect.new(); post.color = Color(0.2, 0.18, 0.16); post.size = Vector2(6, 40); post.position = Vector2(-3, -24); add_child(post)
		var l := Sprite2D.new(); l.texture = load("res://assets/sprites/paper_lantern.png"); l.position = Vector2(0, -34); add_child(l)
		_light = PointLight2D.new(); _light.texture = load("res://assets/sprites/glow.png"); _light.texture_scale = Mechanics.LIGHT_LANTERN
		_light.color = Color(1.0, 0.75, 0.45); _light.energy = 0.0; _light.position = Vector2(0, -34); add_child(_light)
		modulate = Color(0.5, 0.5, 0.55)
		body_entered.connect(func(b): if b.name == "Player": _light_up())
	func _light_up() -> void:
		if _lit: return
		_lit = true; modulate = Color.WHITE
		GameManager.play_sfx("checkpoint", 0.0)
		var tw := create_tween(); tw.tween_property(_light, "energy", 1.3, 0.4)

## ---------------- rising water ----------------
class Water extends Area2D:
	var x0 := 0.0
	var x1 := 0.0
	var bottom := 704.0
	var top := 384.0
	var _level := 0.0
	var _active := false
	var _vis: Polygon2D
	var _surf: Line2D
	func _ready() -> void:
		collision_layer = 0; collision_mask = 0
		_level = bottom + 40.0
		_vis = Polygon2D.new(); _vis.color = Color(0.25, 0.5, 0.75, 0.55); _vis.z_index = 8; add_child(_vis)
		_surf = Line2D.new(); _surf.width = 4; _surf.default_color = Color(0.75, 0.9, 1.0, 0.85); _surf.z_index = 9; add_child(_surf)
		var pl := Mechanics.player_of(self)
		if pl: pl.died.connect(_reset)
		_draw_water()
	func _reset() -> void:
		_active = false; _level = bottom + 40.0; _draw_water()
	func _physics_process(delta: float) -> void:
		var pl := Mechanics.player_of(self)
		if pl == null: return
		var px := pl.global_position.x
		if not _active and px > x0 and px < x1 and _level > bottom:
			_active = true
			FX.toast(get_tree().current_scene, "THE WATER IS RISING", Color(0.6, 0.85, 1.0))
		if _active:
			if px > x1 + 40.0:
				_level = minf(_level + 400.0 * delta, bottom + 40.0)    # drains once you are through
				if _level >= bottom + 40.0: _active = false
			else:
				_level = maxf(_level - Mechanics.WATER_RISE * delta, top)
		_draw_water()
		if px > x0 and px < x1 and pl.global_position.y + 20.0 > _level:
			pl.die()
	func _draw_water() -> void:
		var t := Time.get_ticks_msec() / 1000.0
		var pts := PackedVector2Array()
		_surf.clear_points()
		var n := int((x1 - x0) / 32.0) + 1
		for i in range(n + 1):
			var x := x0 + i * 32.0
			var y := _level + sin(t * 3.0 + i * 0.7) * 3.0
			pts.append(Vector2(x, y)); _surf.add_point(Vector2(x, y))
		pts.append(Vector2(x1, bottom + 300)); pts.append(Vector2(x0, bottom + 300))
		_vis.polygon = pts

## ---------------- switch + gates ----------------
class Gate extends AnimatableBody2D:
	var cells := 1
	var reclose := false
	var tex: Texture2D
	var region := Rect2()
	var _start := Vector2.ZERO
	var _open := false
	func _ready() -> void:
		collision_layer = 1; sync_to_physics = false
		_start = position
		var sz := Vector2(T - 4, cells * T)
		Mechanics.box(self, sz, Vector2(0, sz.y / 2.0 - T / 2.0))
		var bars := Node2D.new(); bars.position = Vector2(0, sz.y / 2.0 - T / 2.0); add_child(bars)
		Mechanics.tile_rect(bars, sz, tex, region)
		for x in [-8, 0, 8]:
			var b := ColorRect.new(); b.color = Color(0.75, 0.6, 0.25) if not reclose else Color(0.6, 0.75, 0.9); b.size = Vector2(3, sz.y); b.position = Vector2(x - 1.5, -sz.y / 2.0); bars.add_child(b)
	func open_gate() -> void:
		if _open: return
		_open = true
		GameManager.play_sfx("gate")
		var tw := create_tween(); tw.tween_property(self, "position:y", _start.y - cells * T + 6, 0.6).set_trans(Tween.TRANS_QUAD)
		if reclose:
			tw.tween_interval(Mechanics.GATE_RECLOSE - 1.0)
			for i in range(4): tw.tween_property(self, "modulate", Color(1.6, 0.6, 0.6), 0.12); tw.tween_property(self, "modulate", Color.WHITE, 0.12)
			tw.tween_property(self, "position:y", _start.y, 0.4)
			tw.tween_callback(func(): _open = false)

class Switch extends Area2D:
	var gates: Array = []
	var _lever: Line2D
	var _on := false
	func _ready() -> void:
		collision_layer = 0; collision_mask = 2
		Mechanics.box(self, Vector2(30, 36), Vector2(0, -2))
		var base := ColorRect.new(); base.color = Color(0.25, 0.2, 0.18); base.size = Vector2(24, 8); base.position = Vector2(-12, 8); add_child(base)
		_lever = Line2D.new(); _lever.width = 4; _lever.default_color = Color(0.85, 0.25, 0.2)
		_lever.add_point(Vector2(0, 8)); _lever.add_point(Vector2(0, -12)); _lever.rotation = -0.6; add_child(_lever)
		body_entered.connect(func(b): if b.name == "Player": _flip())
	func _flip() -> void:
		var any_closed := false
		for g in gates:
			if is_instance_valid(g) and not g._open: any_closed = true
		if _on and not any_closed: return
		_on = true
		_lever.rotation = 0.6; _lever.default_color = Color(0.4, 0.95, 0.5)
		GameManager.play_sfx("switch")
		for g in gates:
			if is_instance_valid(g): g.open_gate()
		FX.toast(get_tree().current_scene, "GATE OPEN", Color(0.95, 0.85, 0.5))

## ---------------- rope swing ----------------
class Rope extends Node2D:
	var length := T * 5
	var _theta := 0.0
	var _omega := 0.0
	var _rider: Node2D
	var _cool := 0.0
	var _line: Line2D
	var _grab: Area2D
	func _ready() -> void:
		_line = Line2D.new(); _line.width = 3; _line.default_color = Color(0.55, 0.42, 0.25); add_child(_line)
		var knot := Polygon2D.new(); knot.polygon = PackedVector2Array([Vector2(-6, -4), Vector2(6, -4), Vector2(6, 4), Vector2(-6, 4)]); knot.color = Color(0.3, 0.22, 0.15); add_child(knot)
		_grab = Area2D.new(); _grab.collision_layer = 0; _grab.collision_mask = 2
		var cs := CollisionShape2D.new(); var sh := CircleShape2D.new(); sh.radius = 26; cs.shape = sh; _grab.add_child(cs); add_child(_grab)
		_grab.body_entered.connect(_on_grab)
	func _end() -> Vector2: return Vector2(sin(_theta), cos(_theta)) * length
	func _on_grab(b: Node) -> void:
		if b.name != "Player" or _rider or _cool > 0.0 or b.get("rope") != null: return
		_rider = b; b.rope = self
		_theta = clampf(asin(clampf((b.global_position.x - global_position.x) / length, -1, 1)), -1.2, 1.2)
		_omega = clampf(b.velocity.x / length, -3.0, 3.0)
		b.velocity = Vector2.ZERO
		GameManager.play_sfx("click")
	func release() -> Vector2:
		var v := Vector2(cos(_theta), -sin(_theta)) * _omega * length
		if _rider: _rider.rope = null
		_rider = null; _cool = 0.5
		return v
	func _physics_process(delta: float) -> void:
		_cool -= delta
		var g := 980.0
		if _rider:
			var pump := Input.get_axis("move_left", "move_right") * 2.2
			_omega += (-(g / length) * sin(_theta) + pump) * delta
			_omega *= 0.995
		else:
			_omega += (-(g / length) * sin(_theta)) * delta
			_omega *= 0.985
		_theta = clampf(_theta + _omega * delta, -1.35, 1.35)
		_line.clear_points(); _line.add_point(Vector2.ZERO); _line.add_point(_end())
		_grab.position = _end()
		if _rider and is_instance_valid(_rider):
			_rider.global_position = global_position + _end() + Vector2(0, 14)
			_rider.velocity = Vector2(cos(_theta), -sin(_theta)) * _omega * length
