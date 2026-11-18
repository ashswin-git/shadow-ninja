class_name CombatUI
## Phase 2 shared combat feedback: enemy hit bars, floating damage numbers, coin / health-orb
## drops, telegraph helpers and the boss intro card. Visual + pickups only.

const DROP_COIN_CHANCE := 0.5      # mon coin: +1 to the running coin total (not the stage star count)
const DROP_ORB_CHANCE := 0.15      # health orb: heals 1 heart, never above max (3)
const DROP_LIFETIME := 8.0

static func scene_of(n: Node) -> Node:
	return n.get_tree().current_scene if n.is_inside_tree() else null

static func damage_number(n: Node, pos: Vector2, amount: int, col := Color(1, 0.92, 0.6), text := "") -> void:
	var sc := scene_of(n)
	if sc == null: return
	var l: Label = Pool.take("dmg_label", func(): return Label.new())
	l.modulate = Color.WHITE
	l.text = text if text != "" else str(amount)
	l.add_theme_font_size_override("font_size", 30 if text == "" else 22)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.02))
	l.add_theme_constant_override("outline_size", 7)
	l.z_index = 40
	l.position = pos + Vector2(randf_range(-14, 6), -70)
	sc.add_child(l)
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 42, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.6).set_delay(0.25)
	tw.chain().tween_callback(func(): Pool.give(l))

## small two-tone bar above an enemy; hidden until the first hit
static func make_bar(owner: Node2D, width := 54.0, y := -96.0) -> Node2D:
	var root := Node2D.new(); root.name = "HitBar"; root.position = Vector2(-width / 2.0, y); root.z_index = 30
	var bg := ColorRect.new(); bg.size = Vector2(width + 4, 8); bg.position = Vector2(-2, -2); bg.color = Color(0.04, 0.02, 0.03, 0.85)
	var fill := ColorRect.new(); fill.name = "Fill"; fill.size = Vector2(width, 4); fill.color = Color(0.92, 0.22, 0.22)
	root.add_child(bg); root.add_child(fill)
	root.visible = false
	owner.add_child(root)
	return root

static func set_bar(bar: Node2D, ratio: float) -> void:
	if bar == null: return
	bar.visible = ratio < 1.0 and ratio > 0.0
	var fill: ColorRect = bar.get_node("Fill")
	var w: float = bar.get_child(0).size.x - 4
	fill.size.x = maxf(0.0, w * ratio)
	fill.color = Color(0.92, 0.22, 0.22) if ratio > 0.34 else Color(1.0, 0.55, 0.15)

## "!" plus an optional ring that shrinks over `dur`
static func telegraph(owner: Node2D, dur: float, y := -100.0, ring_r := 0.0, col := Color(1, 0.25, 0.2)) -> void:
	var warn := Label.new(); warn.text = "!"; warn.position = Vector2(-8, y)
	warn.add_theme_font_size_override("font_size", 34); warn.add_theme_color_override("font_color", col)
	warn.add_theme_color_override("font_outline_color", Color(0, 0, 0)); warn.add_theme_constant_override("outline_size", 8)
	warn.z_index = 30
	owner.add_child(warn)
	var tw := warn.create_tween(); tw.tween_property(warn, "position:y", y - 8, dur); tw.tween_callback(warn.queue_free)
	if ring_r > 0.0:
		ground_ring(owner, Vector2(0, -20), ring_r, dur, col, true)

## warning circle (world space if `world`, else local to owner) that fills then vanishes
static func ground_ring(owner: Node, pos: Vector2, r: float, dur: float, col := Color(1, 0.25, 0.2), local := false) -> Node2D:
	var ring := Line2D.new(); ring.width = 4; ring.default_color = Color(col, 0.85); ring.z_index = 5
	for i in range(33): ring.add_point(Vector2(cos(i * TAU / 32), sin(i * TAU / 32) * 0.35) * r)
	var disc := Polygon2D.new(); var pts := PackedVector2Array()
	for i in range(32): pts.append(Vector2(cos(i * TAU / 32), sin(i * TAU / 32) * 0.35) * r)
	disc.polygon = pts; disc.color = Color(col, 0.18); disc.scale = Vector2(0.05, 0.05)
	ring.add_child(disc)
	ring.position = pos
	if local: owner.add_child(ring)
	else:
		var sc := scene_of(owner)
		if sc == null: return ring
		sc.add_child(ring)
	var tw := ring.create_tween(); tw.tween_property(disc, "scale", Vector2.ONE, dur); tw.tween_callback(ring.queue_free)
	return ring

static func drop_loot(n: Node, pos: Vector2, rich := false) -> void:
	var sc := scene_of(n)
	if sc == null: return
	if rich:
		for i in range(3): _spawn_drop(sc, pos + Vector2(-30 + i * 30, 0), "coin")
		_spawn_drop(sc, pos, "orb")
		return
	if randf() < DROP_COIN_CHANCE: _spawn_drop(sc, pos, "coin")
	if randf() < DROP_ORB_CHANCE: _spawn_drop(sc, pos + Vector2(18, 0), "orb")

static func _spawn_drop(sc: Node, pos: Vector2, kind: String) -> void:
	var a := Area2D.new(); a.collision_layer = 0; a.collision_mask = 2; a.add_to_group("Drops")
	var cs := CollisionShape2D.new(); var sh := CircleShape2D.new(); sh.radius = 16; cs.shape = sh; a.add_child(cs)
	var sp := Sprite2D.new()
	if kind == "coin":
		sp.texture = load("res://assets/sprites/coin.png"); sp.scale = Vector2(0.5, 0.5)
	else:
		sp.texture = load("res://assets/sprites/glow.png"); sp.modulate = Color(1.0, 0.35, 0.45); sp.scale = Vector2(0.5, 0.5)
		var core := Sprite2D.new(); core.texture = sp.texture; core.modulate = Color(1, 0.85, 0.9); core.scale = Vector2(0.45, 0.45); sp.add_child(core)
	a.add_child(sp)
	a.global_position = pos + Vector2(0, -20)
	sc.add_child.call_deferred(a)
	a.set_meta("kind", kind)
	a.body_entered.connect(func(b): _pickup(a, b))
	var hop := a.create_tween()
	hop.tween_property(a, "position:y", pos.y - 60, 0.18).set_ease(Tween.EASE_OUT)
	hop.tween_property(a, "position:y", pos.y + 6, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	hop.tween_interval(DROP_LIFETIME - 1.5)
	hop.tween_property(a, "modulate:a", 0.0, 1.0)
	hop.tween_callback(a.queue_free)

static func _pickup(a: Area2D, body: Node) -> void:
	if not is_instance_valid(a) or a.get_meta("taken", false): return
	if not body.has_method("take_damage") or not ("max_health" in body): return
	a.set_meta("taken", true)
	if a.get_meta("kind") == "coin":
		GameManager.total_coins += 1
		GameManager.play_sfx("coin")
		damage_number(a, a.global_position + Vector2(0, 40), 1, Color(1, 0.85, 0.35), "+1 MON")
	else:
		if body.health < body.max_health:
			body.health += 1
			body.emit_signal("health_changed", body.health)
		GameManager.play_sfx("coin")
		damage_number(a, a.global_position + Vector2(0, 40), 1, Color(1, 0.5, 0.6), "+1 HEART")
	a.queue_free.call_deferred()

## boss intro card: letterbox bars + name / title plate for `dur` seconds
static func boss_intro(sc: Node, title: String, sub: String, col: Color, dur := 2.4) -> void:
	var cl := CanvasLayer.new(); cl.layer = 12; cl.name = "BossIntro"; sc.add_child(cl)
	var bars := []
	for top in [true, false]:
		var b := ColorRect.new(); b.color = Color(0, 0, 0, 0.92); b.size = Vector2(1280, 90)
		b.position = Vector2(0, -90 if top else 720); cl.add_child(b); bars.append([b, top])
	var plate := ColorRect.new(); plate.color = Color(0.02, 0.0, 0.02, 0.7); plate.position = Vector2(0, 470); plate.size = Vector2(1280, 110)
	cl.add_child(plate)
	var edge := ColorRect.new(); edge.color = col; edge.position = Vector2(0, 470); edge.size = Vector2(1280, 3); cl.add_child(edge)
	var l := Label.new(); l.text = title; l.position = Vector2(0, 478); l.size = Vector2(1280, 60)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if ResourceLoader.exists("res://content/original/fonts/SourceSerifPro-Bold.ttf"):
		l.add_theme_font_override("font", load("res://content/original/fonts/SourceSerifPro-Bold.ttf"))
	l.add_theme_font_size_override("font_size", 52); l.add_theme_color_override("font_color", Color(1, 0.93, 0.78))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0)); l.add_theme_constant_override("outline_size", 10)
	cl.add_child(l)
	var s := Label.new(); s.text = sub; s.position = Vector2(0, 538); s.size = Vector2(1280, 30)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.add_theme_font_size_override("font_size", 22); s.add_theme_color_override("font_color", col)
	cl.add_child(s)
	var tw := cl.create_tween().set_parallel(true)
	for bt in bars:
		tw.tween_property(bt[0], "position:y", 0.0 if bt[1] else 630.0, 0.35)
	for c in [plate, edge, l, s]:
		c.modulate.a = 0.0; tw.tween_property(c, "modulate:a", 1.0, 0.3).set_delay(0.2)
	var out := cl.create_tween()
	out.tween_interval(dur - 0.4)
	out.tween_property(cl, "offset:y", 0.0, 0.0)
	for c in cl.get_children(): out.parallel().tween_property(c, "modulate:a", 0.0, 0.4)
	out.tween_callback(cl.queue_free)
