extends SceneTree
func _initialize() -> void:
	var a = load("res://scripts/anim/player_animator.gd").new()
	var body = Node2D.new(); body.name = "Body"; a.add_child(body)
	var spr = Sprite2D.new(); spr.name = "Sprite2D"; body.add_child(spr)
	var tr = Line2D.new(); tr.name = "SlashTrail"; a.add_child(tr)
	root.add_child(a)
	_run.call_deferred(a, body, tr)

func _run(a, body, tr) -> void:
	await process_frame
	var seen := []
	a.state_changed.connect(func(n, o): seen.append(a.State.keys()[n]))
	var dt := 1.0 / 60.0
	var steps = [
		["idle", Vector2.ZERO, true, false, false, 30],
		["run", Vector2(300, 0), true, false, false, 30],
		["jump", Vector2(0, -500), false, false, false, 10],
		["fall", Vector2(0, 400), false, false, false, 10],
		["land", Vector2(0, 0), true, false, false, 5],
		["wall", Vector2(0, 80), false, true, false, 10],
		["dash", Vector2(900, 0), false, false, true, 10],
		["idle2", Vector2.ZERO, true, false, false, 10],
	]
	var minsy := 1.0
	for s in steps:
		for i in range(s[5]):
			a.update_motion(s[1], s[2], s[3], s[4], dt); minsy = min(minsy, body.scale.y)
	print("min body.scale.y over sequence (land squash)=", snapped(minsy, 0.001))
	a.play_hurt(); var mx := 0.0
	for i in range(10): a.update_motion(Vector2.ZERO, true, false, false, dt); mx = max(mx, body.scale.x)
	print("hurt: max body.scale.x=", snapped(mx, 0.001))
	for i in range(30): a.update_motion(Vector2.ZERO, true, false, false, dt)
	a.play_slash(); var pts := 0
	for i in range(8): a.update_motion(Vector2.ZERO, true, false, false, dt); pts = max(pts, tr.get_point_count())
	print("trail points during slash=", pts)
	# timed state must finish before RUN takes over
	a.play_slash(); a.update_motion(Vector2(300,0), true, false, false, dt); print("state 1 frame into slash while running: ", a.State.keys()[a.state])
	for i in range(50): a.update_motion(Vector2.ZERO, true, false, false, dt)
	print("trail points after fade=", tr.get_point_count())
	a.play_throw(); for i in range(12): a.update_motion(Vector2.ZERO, true, false, false, dt)
	a.play_hurt(); for i in range(20): a.update_motion(Vector2.ZERO, true, false, false, dt)
	for k in ["wave", "victory", "taunt", "bow"]:
		a.play_emote(k); for i in range(30): a.update_motion(Vector2.ZERO, true, false, false, dt)
		print("emote ", k, " state after 0.5s=", a.State.keys()[a.state], " rot=", snapped(body.rotation, 0.01), " y=", snapped(body.position.y, 0.1))
		for i in range(60): a.update_motion(Vector2.ZERO, true, false, false, dt)
		print("  after 1.5s: ", a.State.keys()[a.state])
	a.play_emote("wave"); a.update_motion(Vector2.ZERO, true, false, false, dt)
	a.update_motion(Vector2(300, 0), true, false, false, dt); print("after moving during emote: ", a.State.keys()[a.state])
	a.set_facing(-1); a.update_motion(Vector2(-300, 0), true, false, false, dt); print("root scale.x after facing left: ", a.scale.x)
	a.play_dead(); for i in range(40): a.update_motion(Vector2(300,0), true, false, false, dt)
	print("dead state sticky: ", a.State.keys()[a.state], " body alpha=", snapped(body.modulate.a, 0.01))
	a.revive(); a.update_motion(Vector2.ZERO, true, false, false, dt)
	print("states seen: ", seen)
	_frames(a)
	quit()

# character pass: the painted frame (frame_key + sprite texture) must change through each move
func _frames(a) -> void:
	var tex := {}
	for k in ["idle", "run1", "run2", "run3", "run4", "wall", "j_crouch", "j_launch", "j_rise", "j_tuck", "j_apex",
			"j_fall0", "j_fall", "j_preland", "j_land", "s_windup", "s_high", "s_contact", "s_through", "s_over",
			"s_follow", "s_recover", "a_windup", "a_contact", "a_down", "a_follow", "hurt", "dash", "dash_stop"]:
		tex[k] = load("res://assets/sprites/hero/%s.png" % k)
	a.textures = tex
	var spr: Sprite2D = a.get_node("Body/Sprite2D")
	var dt := 1.0 / 60.0
	var g := 980.0
	for i in range(10): a.update_motion(Vector2.ZERO, true, false, false, dt)
	# full jump: v0 = -500 (SPEC), gravity 980 until back on the floor
	var vy := -500.0
	var seq := []
	a.update_motion(Vector2(0, vy), false, false, false, dt)
	while vy < 500.0:
		vy += g * dt
		a.update_motion(Vector2(0, vy), false, false, false, dt)
		if seq.is_empty() or seq[-1] != a.frame_key: seq.append(a.frame_key)
	a.update_motion(Vector2.ZERO, true, false, false, dt); seq.append(a.frame_key)
	print("FRAMES jump: ", seq, " distinct=", _distinct(seq))
	for i in range(30): a.update_motion(Vector2.ZERO, true, false, false, dt)
	a.play_slash(); seq = []
	for i in range(30):
		a.update_motion(Vector2.ZERO, true, false, false, dt)
		if seq.is_empty() or seq[-1] != a.frame_key: seq.append(a.frame_key)
	print("FRAMES ground slash: ", seq, " distinct=", _distinct(seq), " air=", a.air_slash)
	for i in range(30): a.update_motion(Vector2.ZERO, true, false, false, dt)
	a.update_motion(Vector2(0, -300), false, false, false, dt)
	a.play_slash(); seq = []
	var air_flag: bool = a.air_slash
	for i in range(22):
		a.update_motion(Vector2(0, -100 + i * 10), false, false, false, dt)
		if seq.is_empty() or seq[-1] != a.frame_key: seq.append(a.frame_key)
	print("FRAMES air slash: ", seq, " distinct=", _distinct(seq), " air=", air_flag)
	seq = []
	for i in range(40):
		a.update_motion(Vector2(300, 0), true, false, false, dt)
		if seq.is_empty() or seq[-1] != a.frame_key: seq.append(a.frame_key)
	print("FRAMES run: ", seq)
	a.play_hurt(); a.update_motion(Vector2.ZERO, true, false, false, dt)
	print("FRAMES hurt: ", a.frame_key, " texture=", spr.texture.resource_path.get_file())
	a.update_motion(Vector2(900, 0), false, false, true, dt)
	for i in range(25): a.update_motion(Vector2(900, 0), false, false, true, dt)
	print("FRAMES dash: ", a.frame_key)
	a.update_motion(Vector2.ZERO, true, false, false, dt); a.update_motion(Vector2.ZERO, true, false, false, dt)
	print("FRAMES after grounded dash: ", a.frame_key)
	for i in range(20): a.update_motion(Vector2.ZERO, true, false, false, dt)
	print("FRAMES 0.33s after dash: ", a.frame_key)
	print("FRAMES sprite feet offset check: tex h=", spr.texture.get_height(), " offset.y=", spr.offset.y)

func _distinct(seq: Array) -> int:
	var d := {}
	for k in seq: d[k] = true
	return d.size()
