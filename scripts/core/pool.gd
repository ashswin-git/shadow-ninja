class_name Pool
## Phase 5 object pooling for short-lived nodes (hit particles, dust, damage numbers, kunai).
## take() returns a detached node (reused or new); give() detaches it and keeps it for reuse.
## Pools are capped so a burst never pins memory. Stats are printed by the --phase5 profiler.

const CAP := 48
static var _free := {}
static var stats := {"new": 0, "reused": 0}

static func take(key: String, factory: Callable) -> Node:
	var arr: Array = _free.get(key, [])
	while not arr.is_empty():
		var n = arr.pop_back()
		if is_instance_valid(n):
			stats["reused"] += 1; n.set_meta("pooled", false)
			if n.get_parent(): n.get_parent().remove_child(n)
			return n
	stats["new"] += 1
	var nn: Node = factory.call(); nn.set_meta("pool_key", key)
	return nn

static func give(n: Node) -> void:
	if not is_instance_valid(n): return
	var key: String = n.get_meta("pool_key", "")
	var arr: Array = _free.get(key, [])
	if key == "" or arr.size() >= CAP:
		n.queue_free(); return
	if n.get_meta("pooled", false): return
	n.set_meta("pooled", true)
	_detach.call_deferred(n)
	arr.append(n); _free[key] = arr

static func _detach(n: Node) -> void:
	if is_instance_valid(n) and n.get_meta("pooled", false) and n.get_parent(): n.get_parent().remove_child(n)

## Pooled one-shot CPUParticles2D, reset to defaults; caller configures, then call fire().
static func particles() -> CPUParticles2D:
	var p: CPUParticles2D = take("particles", func(): return CPUParticles2D.new())
	p.emitting = false; p.one_shot = true; p.direction = Vector2(1, 0); p.spread = 45.0
	p.damping_min = 0.0; p.damping_max = 0.0; p.color_ramp = null; p.explosiveness = 0.0
	p.gravity = Vector2(0, 980); p.initial_velocity_min = 0.0; p.initial_velocity_max = 0.0
	p.scale_amount_min = 1.0; p.scale_amount_max = 1.0; p.color = Color.WHITE; p.modulate = Color.WHITE
	return p

static func fire(p: CPUParticles2D, parent: Node, pos: Vector2, life: float) -> void:
	if p.get_parent() != parent:
		if p.get_parent(): p.get_parent().remove_child(p)
		parent.add_child(p)
	p.global_position = pos; p.restart(); p.emitting = true
	var tw := p.create_tween(); tw.tween_interval(life); tw.tween_callback(give.bind(p))   # dies with p
