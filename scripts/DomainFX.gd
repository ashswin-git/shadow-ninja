extends Node2D
# DOMAIN in-world effect: "Veil of the Still Moon" (original art).
# A dry-brush ink enso sweeps open, a forged gold moon sigil turns inside it, a pale moon
# blooms at the centre and the backdrop dims to moonlight. Timing/radius unchanged.
var r := 0.0
var max_r := 280.0
var a := 1.0
var _enso: Sprite2D
var _sigil: Sprite2D
var _moon: Sprite2D
var _wash: Sprite2D
var _dim: ColorRect
var _dim_layer: CanvasLayer
const ENSO = preload("res://assets/fx/domain_enso.png")
const SIGIL = preload("res://assets/fx/domain_sigil.png")
const MOON = preload("res://assets/fx/domain_moon.png")
const GLOW = preload("res://assets/sprites/glow.png")

func _ready() -> void:
	z_index = 5
	var add := CanvasItemMaterial.new(); add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_wash = Sprite2D.new(); _wash.texture = GLOW; _wash.material = add
	_wash.modulate = Color(0.45, 0.6, 1.0, 0.55); add_child(_wash)
	_moon = Sprite2D.new(); _moon.texture = MOON; _moon.material = add; add_child(_moon)
	_enso = Sprite2D.new(); _enso.texture = ENSO; _enso.rotation = randf() * TAU; add_child(_enso)
	_sigil = Sprite2D.new(); _sigil.texture = SIGIL; add_child(_sigil)
	# gold motes rising + ink droplets flung outward
	var motes := CPUParticles2D.new(); motes.amount = 46; motes.lifetime = 1.1; motes.one_shot = true; motes.explosiveness = 0.7
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE_SURFACE; motes.emission_sphere_radius = max_r * 0.7
	motes.direction = Vector2(0, -1); motes.spread = 25.0; motes.gravity = Vector2(0, -60)
	motes.initial_velocity_min = 20; motes.initial_velocity_max = 80; motes.scale_amount_min = 1.5; motes.scale_amount_max = 3.5
	var mg := Gradient.new(); mg.set_color(0, Color(1.0, 0.9, 0.55, 1)); mg.set_color(1, Color(1.0, 0.75, 0.3, 0)); motes.color_ramp = mg
	motes.texture = GLOW; motes.scale_amount_min = 0.06; motes.scale_amount_max = 0.14
	motes.emitting = true; add_child(motes)
	var ink := CPUParticles2D.new(); ink.amount = 28; ink.lifetime = 0.6; ink.one_shot = true; ink.explosiveness = 1.0
	ink.spread = 180.0; ink.initial_velocity_min = 260; ink.initial_velocity_max = 520; ink.damping_min = 300; ink.damping_max = 500
	ink.gravity = Vector2(0, 500); ink.scale_amount_min = 3; ink.scale_amount_max = 7; ink.color = Color(0.02, 0.02, 0.06, 0.95)
	ink.texture = GLOW; ink.scale_amount_min = 0.08; ink.scale_amount_max = 0.2
	ink.emitting = true; add_child(ink)
	# backdrop dims to moonlight (between the sky parallax and the world)
	_dim_layer = CanvasLayer.new(); _dim_layer.layer = -1
	get_tree().current_scene.add_child.call_deferred(_dim_layer)
	_dim = ColorRect.new(); _dim.color = Color(0.02, 0.03, 0.09, 0.0); _dim.size = Vector2(1280, 720)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE; _dim_layer.add_child(_dim)
	var tw = create_tween()
	tw.tween_property(self, "r", max_r, 0.42).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.6)
	tw.tween_property(self, "a", 0.0, 0.45)
	tw.tween_callback(_cleanup)

func _cleanup() -> void:
	if is_instance_valid(_dim_layer): _dim_layer.queue_free()
	queue_free()

func _process(d: float) -> void:
	var k := r / max_r
	var tex_r := ENSO.get_width() * 0.40     # enso radius inside its texture
	var sig_r := SIGIL.get_width() * 0.47
	_enso.scale = Vector2.ONE * (r * 1.06 / tex_r)
	_enso.rotation += d * 0.6
	_enso.modulate = Color(1, 1, 1, 0.92 * a)
	_sigil.scale = Vector2.ONE * (r * 0.86 / sig_r)
	_sigil.rotation -= d * 0.9
	_sigil.modulate = Color(1, 1, 1, clampf(k * 1.4 - 0.2, 0.0, 1.0) * a)
	_moon.scale = Vector2.ONE * (0.25 + 0.75 * k) * (max_r / 280.0) * 0.95
	_moon.modulate = Color(0.85, 0.9, 1.0, 0.6 * a)
	_wash.scale = Vector2.ONE * (r / 64.0) * 1.25
	_wash.modulate.a = 0.5 * a
	if _dim: _dim.color.a = 0.5 * clampf(k * 1.5, 0.0, 1.0) * a
