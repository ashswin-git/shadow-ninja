extends Control
# Measured NA2-style touch cluster (original art). Sizes are 1280x720.
# Chevrons have no disc. Action discs are ~75% opaque. Visual skill discs may
# be ~90 px but the hit target stays >= 110 px.

## Phase 4: remappable. The coordinates in _ready() are the SPEC §5 defaults and stay the
## layout whenever GameManager.touch_layout is empty. Overrides (Settings > Edit touch layout),
## the left-handed mirror and the control-size scale are applied in _place().
## Placement is clamped out of PLAYER_ZONE (screen centre, where the camera keeps the hero and
## bosses) and the HUD band, so a custom layout can never cover them; Level also fades buttons.
const PLAYER_ZONE := Rect2(380, 0, 520, 720)
const HUD_BAND := 200.0
var edit_mode := false
var force_visible := false
var defaults := {}     # action -> default centre (SPEC §5)
var _drag: Control = null
signal layout_changed

func _ready() -> void:
	visible = force_visible or OS.has_feature("mobile") or DisplayServer.is_touchscreen_available() or "--show-touch" in OS.get_cmdline_user_args()
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Move: bare ornate chevrons (no rocker bar under them). Centres (102, 600) and (291, 594).
	_chev("move_left", "chev_l", Vector2(102, 600), Vector2(160, 108))
	_chev("move_right", "chev_r", Vector2(291, 594), Vector2(160, 108))
	# L1 is the 2-button tutorial cluster; dash + DOMAIN appear from L2 / bosses.
	var cluster4 := GameManager.current_level >= 2 or edit_mode
	if cluster4:
		_disc("jump", "jump", Vector2(1177, 532), 135)
		_disc("dash", "dash", Vector2(1019, 561), 120)
		_disc("domain", "domain", Vector2(1047, 426), 90)
		_disc("attack", "slash", Vector2(1214, 390), 90)
	else:
		_disc("jump", "jump", Vector2(1190, 558), 150)
		_disc("attack", "slash", Vector2(1205, 414), 132)
	_gear()

## Custom / mirrored / scaled centre for an action, clamped out of the player zone.
func _place(action: String, centre: Vector2) -> Vector2:
	defaults[action] = centre
	var c: Vector2 = GameManager.touch_layout.get(action, centre)
	if GameManager.left_handed and not GameManager.touch_layout.has(action): c.x = 1280.0 - c.x
	return c

static func clamp_centre(c: Vector2, half: Vector2) -> Vector2:
	c.x = clampf(c.x, half.x, 1280.0 - half.x); c.y = clampf(c.y, HUD_BAND + half.y, 720.0 - half.y)
	var l := PLAYER_ZONE.position.x - half.x; var r := PLAYER_ZONE.end.x + half.x
	if c.x > l and c.x < r: c.x = l if c.x - l < r - c.x else r
	return c

func _wire(b: Button, action: String) -> void:
	b.set_meta("action", action)
	b.button_down.connect(func():
		if edit_mode: return
		Input.action_press(action); b.scale = Vector2(0.94, 0.94); GameManager.vibrate(12))
	b.button_up.connect(func():
		if edit_mode: return
		Input.action_release(action); b.scale = Vector2.ONE)
	b.gui_input.connect(func(ev):
		if not edit_mode: return
		if ev is InputEventScreenTouch or ev is InputEventMouseButton:
			_drag = b if ev.pressed else null
			if not ev.pressed: layout_changed.emit()
		elif (ev is InputEventScreenDrag or ev is InputEventMouseMotion) and _drag == b:
			var half := b.size / 2.0
			b.position = clamp_centre(b.position + half + ev.relative, half) - half)

## Current centres (for saving from the editor).
func current_layout() -> Dictionary:
	var d := {}
	for c in get_children():
		if c is Button and c.has_meta("action"): d[c.get_meta("action")] = c.position + c.size / 2.0
	return d

func _chev(action: String, tex: String, centre: Vector2, sz: Vector2) -> void:
	centre = _place(action, centre); sz *= GameManager.control_scale
	centre = clamp_centre(centre, sz / 2.0) if GameManager.touch_layout.has(action) else centre
	var b := Button.new()
	b.name = "Btn_" + action
	b.focus_mode = Control.FOCUS_NONE
	b.position = centre - sz / 2.0
	b.size = sz
	b.custom_minimum_size = sz
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, empty)
	var ic := TextureRect.new()
	ic.texture = load("res://assets/ui/%s.png" % tex)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.set_anchors_preset(Control.PRESET_FULL_RECT)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.modulate = Color(1, 1, 1, 0.92)
	b.add_child(ic)
	b.pivot_offset = sz / 2.0
	_wire(b, action)
	add_child(b)

func _disc(action: String, icon: String, centre: Vector2, visual: float) -> void:
	centre = _place(action, centre); visual *= GameManager.control_scale
	var hit: float = maxf(visual, 110.0)
	if GameManager.touch_layout.has(action): centre = clamp_centre(centre, Vector2(hit, hit) / 2.0)
	var b := Button.new()
	b.name = "Btn_" + action
	b.focus_mode = Control.FOCUS_NONE
	b.position = centre - Vector2(hit, hit) / 2.0
	b.size = Vector2(hit, hit)
	b.custom_minimum_size = Vector2(hit, hit)
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, empty)
	# visual disc: black-indigo lacquer face, forged gold rim + studs, ~80% opaque
	var disc := TextureRect.new()
	disc.texture = load("res://assets/ui/disc_action.png")
	disc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	disc.modulate = Color(1, 1, 1, 0.80)
	disc.size = Vector2(visual, visual)
	disc.position = Vector2((hit - visual) / 2.0, (hit - visual) / 2.0)
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(disc)
	var ic := TextureRect.new()
	ic.texture = load("res://assets/ui/btn_%s.png" % icon)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.position = disc.position + Vector2(visual * 0.19, visual * 0.19)
	ic.size = Vector2(visual * 0.62, visual * 0.62)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.modulate = Color(1, 1, 1, 0.95)
	b.add_child(ic)
	b.pivot_offset = Vector2(hit, hit) / 2.0
	_wire(b, action)
	add_child(b)

func _gear() -> void:
	# ø 60, centre (1249, 44)
	var sz := 60.0
	var b := Button.new()
	b.name = "Btn_pause"
	b.focus_mode = Control.FOCUS_NONE
	b.position = Vector2(1249, 44) - Vector2(sz, sz) / 2.0
	b.size = Vector2(sz, sz)
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, empty)
	var gi := TextureRect.new()
	gi.texture = load("res://assets/ui/btn_gear.png")
	gi.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gi.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gi.position = Vector2(0, 0); gi.size = Vector2(60, 60)
	gi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gi.modulate = Color(1, 1, 1, 0.92)
	b.add_child(gi)
	b.pressed.connect(func():
		release_all()
		var lvl = get_tree().current_scene
		if lvl and lvl.has_method("open_pause"):
			lvl.open_pause()
		elif lvl and lvl.has_node("CanvasLayer/PauseMenu"):
			lvl.get_node("CanvasLayer/PauseMenu").show()
			get_tree().paused = true)
	add_child(b)

func release_all() -> void:
	for a in ["move_left", "move_right", "jump", "dash", "throw", "domain", "attack"]:
		Input.action_release(a)
	for c in get_children():
		if c is Button: c.scale = Vector2.ONE
