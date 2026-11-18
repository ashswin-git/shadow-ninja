class_name UIJuice
extends RefCounted
## Static UI motion helpers. All tweens run while the tree is paused (pause / results
## screens) and are skipped or reduced when GameManager.reduced_motion is on.

const POP_TIME := 0.22
const POP_FROM := 0.6
const SLIDE_TIME := 0.28
const PRESS_SCALE := 0.94
const HOVER_SCALE := 1.04
const PRESS_TIME := 0.06
const RELEASE_TIME := 0.16
const SHAKE_STEPS := 6
const BREATHE_PERIOD := 1.6

static func _reduced() -> bool:
	var gm = Engine.get_main_loop().root.get_node_or_null("/root/GameManager") if Engine.get_main_loop() else null
	return gm != null and gm.reduced_motion

static func _centre_pivot(c: Control) -> void:
	var sz := c.size if c.size.x > 0.0 and c.size.y > 0.0 else c.custom_minimum_size
	c.pivot_offset = sz * 0.5

static func _tw(n: Node) -> Tween:
	var t := n.create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	return t

## Scale + fade a control in from POP_FROM with a back-out overshoot.
static func pop_in(c: CanvasItem, delay := 0.0, dur := POP_TIME) -> void:
	if c == null or not c.is_inside_tree(): return
	if c is Control: _centre_pivot(c)
	var target_scale: Vector2 = c.scale
	if _reduced():
		c.modulate.a = 0.0
		var tr := _tw(c); tr.tween_interval(delay); tr.tween_property(c, "modulate:a", 1.0, dur)
		return
	c.scale = target_scale * POP_FROM
	c.modulate.a = 0.0
	var t := _tw(c)
	t.tween_interval(delay)
	t.tween_property(c, "scale", target_scale, dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(c, "modulate:a", 1.0, dur * 0.7)

## Slide a control in from `from_offset` (pixels relative to its resting position).
static func slide_in(c: Control, from_offset := Vector2(0, 40), delay := 0.0, dur := SLIDE_TIME) -> void:
	if c == null or not c.is_inside_tree(): return
	var rest := c.position
	c.modulate.a = 0.0
	if not _reduced(): c.position = rest + from_offset
	var t := _tw(c)
	t.tween_interval(delay)
	t.tween_property(c, "position", rest, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(c, "modulate:a", 1.0, dur * 0.8)

## Hover grow, press squish and springy release for any BaseButton.
static func bind_button(b: BaseButton) -> void:
	if b == null: return
	var set_pivot := func(): b.pivot_offset = b.size * 0.5
	set_pivot.call()
	b.resized.connect(set_pivot)
	var go := func(s: float, d: float, trans: int):
		if not b.is_inside_tree(): return
		if b.has_meta("_juice_tw"):
			var old = b.get_meta("_juice_tw")
			if old is Tween and old.is_valid(): old.kill()
		var t := _tw(b)
		t.tween_property(b, "scale", Vector2(s, s), d).set_trans(trans).set_ease(Tween.EASE_OUT)
		b.set_meta("_juice_tw", t)
	b.mouse_entered.connect(func(): if not b.disabled: go.call(HOVER_SCALE, RELEASE_TIME, Tween.TRANS_SINE))
	b.mouse_exited.connect(func(): go.call(1.0, RELEASE_TIME, Tween.TRANS_SINE))
	b.button_down.connect(func(): go.call(PRESS_SCALE, PRESS_TIME, Tween.TRANS_QUAD))
	b.button_up.connect(func(): go.call(1.0, RELEASE_TIME, Tween.TRANS_BACK))

## Positional shake of a control (e.g. the HUD on a hit). Returns to its rest position.
static func shake(c: CanvasItem, strength := 6.0, dur := 0.25) -> void:
	if c == null or not c.is_inside_tree() or _reduced(): return
	var key := "_juice_shake_rest"
	if c.has_meta("_juice_shake_tw"):
		var old = c.get_meta("_juice_shake_tw")
		if old is Tween and old.is_valid(): old.kill()
	if not c.has_meta(key): c.set_meta(key, c.position)
	var rest: Vector2 = c.get_meta(key)
	var t := _tw(c)
	var step := dur / float(SHAKE_STEPS)
	for i in range(SHAKE_STEPS):
		var k := 1.0 - float(i) / float(SHAKE_STEPS)
		t.tween_property(c, "position", rest + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength * k, step)
	t.tween_property(c, "position", rest, step)
	c.set_meta("_juice_shake_tw", t)

## Slow looping scale pulse (attention / idle). No-op with reduced motion.
static func breathe(c: CanvasItem, amount := 0.03, period := BREATHE_PERIOD, delay := 0.0) -> void:
	if c == null or not c.is_inside_tree() or _reduced(): return
	if delay > 0.0:
		c.get_tree().create_timer(delay, true).timeout.connect(func(): if is_instance_valid(c): breathe(c, amount, period))
		return
	if c is Control: _centre_pivot(c)
	var base: Vector2 = c.scale
	var t := _tw(c).set_loops()
	t.tween_property(c, "scale", base * (1.0 + amount), period * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(c, "scale", base, period * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
