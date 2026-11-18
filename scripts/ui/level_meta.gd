class_name LevelMeta
extends Node
## Phase 4 in-stage layer: combo counter, ward pips, coin magnet, artifacts, daily-challenge
## tracking, tutorial / mechanic hint cards, HUD safe-area margins and accessibility options.

const COMBO_TIMEOUT := 2.0
const COMBO_INK_EVERY := 10
const COMBO_INK_COINS := 5
const HINT_TIME := 3.2
const TEACH_HINTS := {
	"spring_teach": "SPRING — land on it to launch high.",
	"moving_teach": "MOVING PLATFORM — ride it across.",
	"crumble_teach": "CRUMBLING FLOOR — it drops 0.45 s after you land. Keep running.",
	"wind_teach": "WIND — gusts push you. Cross in the calm.",
	"dark_teach": "DARK ROOM — lanterns light the way.",
	"water_teach": "RISING WATER — climb before it reaches you.",
	"spikes_teach": "TIMED SPIKES — they flash, then rise.",
	"saw_teach": "SAW — read its path, then pass.",
	"rope_teach": "ROPE — jump into it, swing, jump again to let go.",
	"switch_teach": "SWITCH — touch it to open the gate.",
}
const L1_STEPS := [["move_right", "MOVE — hold → (or D) to run"], ["jump", "JUMP — tap Jump (Space), tap again in the air"], ["attack", "SLASH — tap Slash (J). Three in a row is a combo"]]

var lvl: Node
var player: Node
var hud: Control
var combo := 0
var _combo_t := 0.0
var combo_label: Label
var ward_label: Label
var hint_panel: PanelContainer
var hint_label: Label
var _hint_t := 0.0
var _seen := {}
var _tut_step := -1
# challenge run stats
var run_time := 0.0
var run_hits := 0
var _last_hp := 3

func setup(level: Node) -> void:
	lvl = level; player = level.player; hud = level.get_node("CanvasLayer/HUD")
	_apply_safe_area()
	var tint := Progression.skin_tint()
	if player.get("sprite"): player.sprite.self_modulate = tint
	if GameManager.high_contrast and player.get("sprite"):
		var m := player.sprite.material as ShaderMaterial
		if m: m.set_shader_parameter("outline_width", 3.0); m.set_shader_parameter("outline_color", Color(1, 0.95, 0.3, 1))
	# wards (Iron Ward skill + one Ward Talisman per stage)
	player.wards = Progression.stage_wards()
	if int(GameManager.meta["shop"]["talisman"]) > 0:
		GameManager.meta["shop"]["talisman"] = int(GameManager.meta["shop"]["talisman"]) - 1; GameManager.save_game()
	player.ward_changed.connect(_on_ward)
	player.slash_hit.connect(_on_slash_hit)
	player.health_changed.connect(func(hp):
		if hp < _last_hp: run_hits += 1
		_last_hp = hp)
	combo_label = _label(Vector2(980, 96), 30, Color(1.0, 0.86, 0.45)); combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	combo_label.size = Vector2(240, 40); combo_label.modulate.a = 0.0
	ward_label = _label(Vector2(148, 92), 18, Color(0.6, 0.85, 1.0))
	_on_ward(player.wards)
	if GameManager.big_text:
		for c in hud.get_children(): if c is Label: c.add_theme_font_size_override("font_size", 26)
	if GameManager.high_contrast:
		var plate := ColorRect.new(); plate.color = Color(0, 0, 0, 0.55); plate.position = Vector2(110, 10); plate.size = Vector2(110, 108)
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE; hud.add_child(plate); hud.move_child(plate, 0)
	_build_hint()
	if Progression.equipped("crow_feather"):
		var sf = lvl.get_node_or_null("World/SecretFront")
		if sf: sf.modulate.a = 0.6
	if GameManager.challenge_active:
		var dl := Progression.daily()
		show_hint("DAILY CHALLENGE — " + dl["mod"]["name"] + ": " + dl["mod"]["text"], 4.0)
	elif lvl.level_number == 1 and not bool(GameManager.meta.get("tutorial_done", false)):
		_tut_step = 0; show_hint(L1_STEPS[0][1], 999.0)

func _label(pos: Vector2, size: int, col: Color) -> Label:
	var l := Label.new(); l.position = pos; l.size = Vector2(240, 30)
	l.add_theme_font_size_override("font_size", size); l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color.BLACK); l.add_theme_constant_override("outline_size", 6)
	if ResourceLoader.exists("res://content/original/fonts/SourceSerifPro-Bold.ttf"):
		l.add_theme_font_override("font", load("res://content/original/fonts/SourceSerifPro-Bold.ttf"))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE; hud.add_child(l); return l

## Respect notches / rounded corners: shift the HUD by the display safe area (0 on desktop).
func _apply_safe_area() -> void:
	var m := safe_margins()
	if m == Vector4.ZERO: return
	for c in hud.get_children():
		if c is Control and c != lvl.boss_health_bar and c.anchor_left == 0.0 and c.anchor_top == 0.0:
			c.position += Vector2(m.x, m.y)

static func safe_margins() -> Vector4:
	var ss := DisplayServer.screen_get_size(); var sa := DisplayServer.get_display_safe_area()
	if ss.x <= 0 or sa.size == Vector2i.ZERO or sa.size == ss: return Vector4.ZERO
	var k := 1280.0 / float(ss.x)
	return Vector4(sa.position.x * k, sa.position.y * k, (ss.x - sa.end.x) * k, (ss.y - sa.end.y) * k)

func _on_ward(n: int) -> void:
	ward_label.text = ("WARD x%d" % n) if n > 0 else ""

func _on_slash_hit(n: int) -> void:
	var before := combo
	combo += n; _combo_t = COMBO_TIMEOUT
	combo_label.text = "%d HIT COMBO" % combo if combo >= 2 else ""
	combo_label.modulate.a = 1.0
	if not GameManager.reduced_motion:
		combo_label.pivot_offset = combo_label.size / 2.0; combo_label.scale = Vector2(1.25, 1.25)
		var tw := combo_label.create_tween(); tw.tween_property(combo_label, "scale", Vector2.ONE, 0.15)
	if Progression.has_skill("combo_ink") and combo / COMBO_INK_EVERY > before / COMBO_INK_EVERY:
		GameManager.total_coins += COMBO_INK_COINS
		FX.toast(lvl, "COMBO INK +%d" % COMBO_INK_COINS)
	var st: Dictionary = GameManager.meta["stats"]
	st["best_combo"] = maxi(int(st["best_combo"]), combo)

func _build_hint() -> void:
	hint_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new(); sb.bg_color = Color(0.05, 0.04, 0.03, 0.82); sb.border_color = Color(0.85, 0.68, 0.32)
	sb.set_border_width_all(2); sb.set_corner_radius_all(8); sb.content_margin_left = 18; sb.content_margin_right = 18
	sb.content_margin_top = 8; sb.content_margin_bottom = 8
	hint_panel.add_theme_stylebox_override("panel", sb)
	hint_panel.position = Vector2(340, 150); hint_panel.custom_minimum_size = Vector2(600, 0)
	hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_label = Label.new(); hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 26 if GameManager.big_text else 21)
	hint_label.add_theme_color_override("font_color", Color(1, 0.94, 0.8))
	hint_panel.add_child(hint_label); hud.add_child(hint_panel); hint_panel.modulate.a = 0.0

func show_hint(text: String, dur := HINT_TIME) -> void:
	hint_label.text = text; _hint_t = dur
	var tw := hint_panel.create_tween(); tw.tween_property(hint_panel, "modulate:a", 1.0, 0.2)

func _process(delta: float) -> void:
	if lvl == null or not is_instance_valid(player): return
	run_time += delta
	if _combo_t > 0.0:
		_combo_t -= delta
		if _combo_t <= 0.0:
			combo = 0
			var tw := combo_label.create_tween(); tw.tween_property(combo_label, "modulate:a", 0.0, 0.3)
	if _hint_t > 0.0:
		_hint_t -= delta
		if _hint_t <= 0.0:
			var tw2 := hint_panel.create_tween(); tw2.tween_property(hint_panel, "modulate:a", 0.0, 0.3)
	# L1 tutorial: advance on the taught action
	if _tut_step >= 0 and _tut_step < L1_STEPS.size() and Input.is_action_pressed(L1_STEPS[_tut_step][0]):
		_tut_step += 1
		if _tut_step < L1_STEPS.size(): show_hint(L1_STEPS[_tut_step][1], 999.0)
		else:
			show_hint("Reach the gate. Coins earn stars.", 2.5)
			GameManager.meta["tutorial_done"] = true; GameManager.save_game()
	# Phase 3 teach chunks: one hint card on first entry
	if not lvl.stage_info.is_empty():
		var ci := int(player.global_position.x / (StageData.CHUNK_W * 32.0))
		var names: Array = StageData.STAGES[lvl.level_number]["chunks"]
		if ci >= 0 and ci < names.size() and TEACH_HINTS.has(names[ci]) and not _seen.has(names[ci]):
			_seen[names[ci]] = true; show_hint(TEACH_HINTS[names[ci]])
	# coin magnet (Coin Sense / Fox Bell)
	var r := Progression.magnet_radius()
	if r > 0.0:
		for c in get_tree().get_nodes_in_group("Coins"):
			if is_instance_valid(c):
				var d: Vector2 = player.global_position - c.global_position
				if d.length() < r: c.global_position += d.normalized() * minf(d.length(), 420.0 * delta)

## Stone Heart: ward renews at checkpoints.
func on_checkpoint() -> void:
	if Progression.equipped("stone_heart") and player.wards < 1:
		player.wards = 1; _on_ward(1)

func challenge_result() -> String:
	if not GameManager.challenge_active: return ""
	GameManager.challenge_active = false
	var res := Progression.finish_challenge({"hits": run_hits, "coins": lvl.coins_collected, "total": lvl.total_coins_in_level,
		"time": run_time, "domains": player.domains_cast})
	return "CHALLENGE CLEARED  " + res if res != "" else "Challenge failed — try again tomorrow or retry now."
