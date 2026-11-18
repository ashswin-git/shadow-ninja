class_name EnemyProjectile
extends Area2D
## Phase 2 enemy / boss projectile: straight, arcing (gravity) or ground wave. 1 damage to the hero.
## kind: "arrow", "bomb" (arcs, lands, fuse ring, explodes), "wave" (ground shock), "bolt",
## "rock" (arcs, breaks on landing), "crescent".
var vel := Vector2.ZERO
var grav := 0.0
var kind := "arrow"
var life := 4.0
var fuse := 0.7
var blast_r := 70.0
var floor_y := 99999.0          # landing height for arcing shots
var _landed := false
var _t := 0.0
var _vis: Node2D

static func spawn(parent: Node, k: String, pos: Vector2, v: Vector2, g := 0.0) -> EnemyProjectile:
	var p := EnemyProjectile.new()
	p.kind = k; p.vel = v; p.grav = g; p.global_position = pos
	parent.add_child(p)
	return p

func _ready() -> void:
	add_to_group("EnemyProjectiles")
	collision_layer = 8; collision_mask = 2
	var cs := CollisionShape2D.new(); var sh := CircleShape2D.new()
	sh.radius = {"arrow": 7.0, "bomb": 12.0, "wave": 16.0, "bolt": 14.0, "rock": 20.0, "crescent": 22.0}.get(kind, 10.0)
	cs.shape = sh; add_child(cs)
	body_entered.connect(_on_body)
	_vis = Node2D.new(); add_child(_vis)
	match kind:
		"arrow":
			var l := Line2D.new(); l.width = 3; l.default_color = Color(0.85, 0.75, 0.55)
			l.add_point(Vector2(-22, 0)); l.add_point(Vector2(10, 0)); _vis.add_child(l)
			var tip := Polygon2D.new(); tip.polygon = PackedVector2Array([Vector2(10, -4), Vector2(18, 0), Vector2(10, 4)]); tip.color = Color(0.85, 0.9, 1.0); _vis.add_child(tip)
			var fl := Polygon2D.new(); fl.polygon = PackedVector2Array([Vector2(-22, 0), Vector2(-28, -5), Vector2(-16, 0), Vector2(-28, 5)]); fl.color = Color(0.85, 0.2, 0.15); _vis.add_child(fl)
		"bomb", "rock":
			var c := Polygon2D.new(); var pts := PackedVector2Array(); var r := 11.0 if kind == "bomb" else 18.0
			for i in range(14): pts.append(Vector2(cos(i * TAU / 14), sin(i * TAU / 14)) * r * (1.0 if kind == "bomb" else randf_range(0.8, 1.1)))
			c.polygon = pts; c.color = Color(0.08, 0.08, 0.1) if kind == "bomb" else Color(0.36, 0.32, 0.3); _vis.add_child(c)
			if kind == "rock":
				var cr := Line2D.new(); cr.width = 2; cr.default_color = Color(1, 0.5, 0.15)
				cr.add_point(Vector2(-8, -6)); cr.add_point(Vector2(0, 2)); cr.add_point(Vector2(8, -2)); _vis.add_child(cr)
			else:
				var sp := Sprite2D.new(); sp.texture = load("res://assets/sprites/glow.png"); sp.scale = Vector2(0.18, 0.18)
				sp.modulate = Color(1, 0.7, 0.2); sp.position = Vector2(6, -12); _vis.add_child(sp)
		"wave", "crescent":
			var col := Color(1, 0.55, 0.2, 0.9) if kind == "wave" else Color(0.75, 0.9, 1.0, 0.95)
			var l2 := Line2D.new(); l2.width = 10; l2.default_color = col
			var wc := Curve.new(); wc.add_point(Vector2(0, 0.1)); wc.add_point(Vector2(0.5, 1)); wc.add_point(Vector2(1, 0.1)); l2.width_curve = wc
			for i in range(9):
				var a := lerpf(-1.3, 1.3, i / 8.0)
				l2.add_point(Vector2(cos(a) * 18.0, sin(a) * 26.0))
			_vis.add_child(l2)
		"bolt":
			var g := Sprite2D.new(); g.texture = load("res://assets/sprites/glow.png"); g.modulate = Color(0.65, 0.3, 1.0, 0.9); g.scale = Vector2(0.42, 0.42); _vis.add_child(g)
			var c2 := Sprite2D.new(); c2.texture = g.texture; c2.modulate = Color(0.95, 0.85, 1.0); c2.scale = Vector2(0.18, 0.18); _vis.add_child(c2)
	if vel.x < 0: _vis.scale.x = -1

func _physics_process(delta: float) -> void:
	_t += delta
	if _t > life: queue_free(); return
	if _landed:
		if kind == "bomb":
			fuse -= delta
			_vis.modulate = Color(1, 0.4, 0.3) if int(_t * 12.0) % 2 == 0 else Color.WHITE
			if fuse <= 0.0: _explode()
		return
	vel.y += grav * delta
	position += vel * delta
	if kind == "arrow" and grav > 0.0: _vis.rotation = vel.angle() * (1.0 if vel.x >= 0 else -1.0)
	if kind in ["bomb", "rock"]: _vis.rotation += delta * 6.0
	if grav > 0.0 and global_position.y >= floor_y:
		global_position.y = floor_y
		if kind == "bomb":
			_landed = true
			CombatUI.ground_ring(self, global_position + Vector2(0, 8), blast_r, fuse, Color(1, 0.35, 0.15))
		elif kind == "rock":
			FX.sparks(get_tree().current_scene, global_position, Color(0.6, 0.5, 0.4), 10)
			queue_free()

func _explode() -> void:
	FX.death_burst(get_tree().current_scene, global_position, 0.7)
	GameManager.play_sfx("hit")
	var pl = get_tree().current_scene.get_node_or_null("Player")
	if pl and pl.global_position.distance_to(global_position) < blast_r and pl.has_method("take_damage"):
		pl.take_damage(1)
	queue_free()

func _on_body(b: Node) -> void:
	if kind == "bomb": 
		if not _landed: _explode()
		return
	if b.name == "Player" and b.has_method("take_damage"):
		b.take_damage(1)
		if kind != "wave": queue_free()
