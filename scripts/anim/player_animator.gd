class_name PlayerAnimator
extends Node2D
## Frame + motion animator for the painted hero (character pass: 27 painted pose frames,
## see assets/sprites/hero/). Jump, ground slash and air slash play real painted frame
## sequences; squash / lean / recoil are layered on top.
## Rig: Body (Node2D) holding the painted Sprite2D and, optionally, LegBack / LegFront /
## ArmBack / ArmFront (ArmFront may hold Weapon). SlashTrail (Line2D) is a sibling of Body.
## The hero art is one painted sprite per pose, so the limb nodes are optional: when they
## are missing the animator warns once and drives squash, bob, lean, recoil and the trail
## on the painted body instead. Facing is this node's scale.x (+1 right, -1 left).

signal state_changed(new_state: int, old_state: int)

## Phase 1: 13 gameplay states (+ EMOTE for idle flavour). Ground SLASH is a 3-hit combo
## (combo_step 1..3) played from hero_slash_sheet.png; idle / run play their sheets.
enum State { IDLE, RUN, JUMP, FALL, DOUBLE_JUMP, WALL_SLIDE, DASH, SLASH, THROW, HURT, DOMAIN_CAST, VICTORY, DEAD, EMOTE }

# --- thresholds -----------------------------------------------------------------
const RUN_SPEED_MIN := 10.0          # px/s horizontal before RUN
const FALL_SPEED_MIN := 40.0         # px/s downward before FALL (else JUMP apex)
const LAND_IMPACT_MIN := 120.0       # px/s downward speed that counts as a landing
const LAND_IMPACT_FULL := 900.0      # px/s that gives the full land squash
# --- timed state lengths (s) -------------------------------------------------------
# frame sequences: [frame, seconds]; SLASH / AIR_SLASH length is the sum
const SLASH_SEQ := [["s_windup", 0.07], ["s_high", 0.04], ["s_contact", 0.06], ["s_through", 0.06],
	["s_over", 0.06], ["s_follow", 0.13], ["s_recover", 0.14]]   # polish: longer windup / follow-through holds
const AIR_SLASH_SEQ := [["a_windup", 0.06], ["a_contact", 0.07], ["a_down", 0.08], ["a_follow", 0.12]]
# blade angle (rad, facing right, y down: -PI/2 up, 0 forward, PI/2 down) at the START of each frame
const SLASH_BLADE := [-2.3, -1.2, -0.1, 0.25, 1.3, 2.3, 2.3]
const AIR_BLADE := [-1.7, 0.3, 1.2, 2.2]
const SLASH_TIME := 0.56            # legacy single-slash length (limb-rig fallback)
# 3-hit ground combo: 5 sheet cells per hit (row r of hero_slash_sheet -> keys "c<r>_<i>")
const COMBO_SEQ := [
	[0.06, 0.05, 0.07, 0.08, 0.12],      # hit 1: overhead -> forward cut
	[0.05, 0.05, 0.07, 0.08, 0.12],      # hit 2: return backhand
	[0.08, 0.05, 0.07, 0.10, 0.18]]      # hit 3: heavy finisher (longer windup + recover)
const COMBO_BLADE := [
	[-2.3, -1.2, -0.1, 0.6, 2.0],
	[2.2, 1.0, 0.1, -0.8, -1.8],
	[-2.4, -1.4, -0.2, 1.0, 2.4]]
const COMBO_TRAIL_W := [16.0, 15.0, 24.0]
const COMBO_TRAIL_COL := [Color(0.78, 0.92, 1.0, 0.95), Color(0.7, 0.86, 1.0, 0.9), Color(1.0, 0.88, 0.6, 0.98)]
const CANCEL_FRAME := 3              # from this cell on (follow/recover) jump, dash, throw or the next hit cancel
const IDLE_FRAMES := 6
const RUN_SHEET_FRAMES := 8
const DOMAIN_CAST_TIME := 0.9
const VICTORY_TIME := 1.8
const AIR_SLASH_TIME := 0.33
const THROW_TIME := 0.2
const HURT_TIME := 0.32
const LAND_HOLD := 0.18              # landing pose hold (s) after a real drop
const LAND_HOLD_RUN := 0.09
# jump cycle: frame by time since takeoff, then by vertical speed (px/s)
const JUMP_CROUCH_T := 0.11
const JUMP_LAUNCH_T := 0.19
const JUMP_VY_RISE := -260.0
const JUMP_VY_TUCK := -90.0
const JUMP_VY_APEX := 90.0
const JUMP_VY_FALL0 := 260.0
const JUMP_VY_FALL := 480.0
const DOUBLE_JUMP_SPIN_T := 0.32
const BODY_CENTRE_Y := -34.0         # px above the feet: spin pivot
const EMOTE_TIME := 1.2
# --- run cycle ---------------------------------------------------------------------
const RUN_FRAMES := ["run1", "run2", "run3", "run4"]
const RUN_FPS := 20.0                # 8-frame sheet: same 0.4 s cycle as the old 4 keys at 10 fps
const RUN_BOB_PX := 2.5
const RUN_LEAN := 0.06               # rad, forward lean while running
# --- idle breathing ----------------------------------------------------------------
const BREATH_HZ := 0.55
const BREATH_AMT := 0.018            # scale.y amplitude
# --- smoothing (exponential, 1/s) --------------------------------------------------
const LIMB_SHARPNESS := 18.0
const LEAN_SHARPNESS := 14.0
const OFFSET_SHARPNESS := 20.0
# --- damped spring on Body squash (s>0 = squash wide/short, s<0 = stretch tall) ---
const SPRING_K := 420.0
const SPRING_DAMP := 18.0
const SQUASH_MAX := 0.32
const LAND_SQUASH := 0.26            # impulse scaled by impact
const TAKEOFF_STRETCH := -0.16
const SLASH_LUNGE_SQUASH := 0.10
const SLASH_LUNGE_PX := 7.0
const HURT_SQUASH := 0.18
const HURT_RECOIL_PX := 16.0
const HURT_TILT := -0.22
const SPRING_IMPULSE_SPEED := 20.0   # ~sqrt(SPRING_K): an impulse of X peaks near X squash
# --- air / dash / wall poses -------------------------------------------------------
const AIR_TILT_PER_VY := 0.00018     # rad per px/s vertical speed
const AIR_TILT_MAX := 0.12
const DASH_LEAN := 0.30
const DASH_STOP_HOLD := 0.12        # braking-skid pose after a grounded dash
var _dash_stop_t := 0.0
const DASH_STRETCH := -0.08
const WALL_LEAN := -0.05
const THROW_LEAN := 0.12
# --- slash trail -------------------------------------------------------------------
const TRAIL_POINTS := 14
const TRAIL_RADIUS := 58.0
const TRAIL_CENTRE := Vector2(10, -6)       # Animator space (feet at y = 28)
const AIR_TRAIL_CENTRE := Vector2(12, -2)
const TRAIL_ARC_FROM := -1.9         # rad (limb-rig fallback only)
const TRAIL_ARC_TO := 1.0
const TRAIL_WIDTH := 16.0
const TRAIL_FADE := 0.18
const TRAIL_COLOR := Color(0.78, 0.92, 1.0, 0.95)
# --- emotes ------------------------------------------------------------------------
const EMOTE_KINDS := ["wave", "victory", "taunt", "bow"]
const BOW_TILT := 0.32
const WAVE_SWAY := 0.07
const WAVE_HZ := 2.6
const VICTORY_HOP_PX := 14.0
const VICTORY_HZ := 2.0
const TAUNT_LEAN := -0.12
const TAUNT_HZ := 4.0
# --- death -------------------------------------------------------------------------
const DEAD_TILT := 1.35
const DEAD_SINK_PX := 6.0
const DEAD_FADE := 0.45
# --- layout ------------------------------------------------------------------------
const FEET_Y := 28.0                 # collision bottom in Player space; Body pivots here
const FRAME_PAD := 3.0               # transparent px under the feet in every painted frame

@export var textures: Dictionary = {}   # pose key -> Texture2D (set by Player.gd)

var state: int = State.IDLE
var facing: int = 1
var emote_kind: String = ""

var _body: Node2D
var _sprite: Sprite2D
var _limbs: Dictionary = {}         # name -> Node2D
var _weapon: Node2D
var _trail: Line2D
var _timer := 0.0
var _t := 0.0
var _run_t := 0.0
var _squash := 0.0
var _squash_v := 0.0
var _lean := 0.0
var _off := Vector2.ZERO
var _was_floor := true
var _last_vy := 0.0
var _trail_alpha := 0.0
var _dead_t := 0.0
var combo_step := 1                  # 1..3, current ground-combo hit
var air_slash := false               # current SLASH is the aerial variant
var frame_key := "idle"              # painted frame shown this tick (read by tests)
var _air_t := 0.0
var _jumped := false
var _land_t := 0.0
var _spin_t := 0.0
var _seq_t := 0.0

func _ready() -> void:
	_body = get_node_or_null("Body") as Node2D
	if _body == null:
		push_warning("PlayerAnimator: no Body node; animator disabled")
		return
	_body.position = Vector2(0, FEET_Y)
	_sprite = _body.get_node_or_null("Sprite2D") as Sprite2D
	if _sprite == null:
		push_warning("PlayerAnimator: Body has no painted Sprite2D; pose textures skipped")
	var missing: Array = []
	for n in ["LegBack", "LegFront", "ArmBack", "ArmFront"]:
		var l = _body.get_node_or_null(n)
		if l is Node2D: _limbs[n] = l
		else: missing.append(n)
	if _limbs.has("ArmFront"):
		_weapon = _limbs["ArmFront"].get_node_or_null("Weapon") as Node2D
	if missing.size() > 0:
		push_warning("PlayerAnimator: limb nodes %s missing; painted body is driven as one piece" % [missing])
	_trail = get_node_or_null("SlashTrail") as Line2D
	if _trail == null:
		push_warning("PlayerAnimator: no SlashTrail Line2D; slash trail skipped")
	else:
		_trail.width = TRAIL_WIDTH
		_trail.default_color = TRAIL_COLOR
		_trail.joint_mode = Line2D.LINE_JOINT_ROUND
		_trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
		_trail.end_cap_mode = Line2D.LINE_CAP_ROUND
		var wc := Curve.new(); wc.add_point(Vector2(0, 0.1)); wc.add_point(Vector2(1, 1)); _trail.width_curve = wc
		_trail.clear_points()

# ---------------------------------------------------------------- public API ----
func update_motion(vel: Vector2, on_floor: bool, on_wall: bool, dashing: bool, delta: float) -> void:
	if _body == null: return
	_t += delta
	scale.x = float(facing)   # facing is owned by the caller (set_facing)
	# landing / takeoff
	if on_floor and not _was_floor and _last_vy > LAND_IMPACT_MIN:
		play_land(clampf(_last_vy / LAND_IMPACT_FULL, 0.0, 1.0))
		_land_t = LAND_HOLD if absf(vel.x) < RUN_SPEED_MIN else LAND_HOLD_RUN
	elif not on_floor and _was_floor:
		_air_t = 0.0
		_jumped = vel.y < 0.0
		if _jumped: _kick(TAKEOFF_STRETCH)
	if on_floor: _jumped = false
	else: _air_t += delta
	_land_t = maxf(_land_t - delta, 0.0)
	_dash_stop_t = maxf(_dash_stop_t - delta, 0.0)
	if on_floor and state == State.SLASH and air_slash:
		_timer = 0.0     # an air slash ends on landing
	if on_floor and state == State.DOUBLE_JUMP:
		_timer = 0.0
	# combo cancel window: once the cut has landed, a dash or jump takes over at once
	if state == State.SLASH and can_cancel() and (dashing or (vel.y < -200.0 and not on_floor and _air_t < 0.05)):
		_timer = 0.0
	_was_floor = on_floor
	_last_vy = vel.y
	# timed states run to the end; EMOTE is cancelled by movement; DEAD is sticky
	if state == State.DEAD:
		pass
	elif state == State.EMOTE:
		# movement cancels an emote; otherwise it runs until _emote_left expires (in _pose)
		if absf(vel.x) > RUN_SPEED_MIN or not on_floor or dashing:
			_set_state(_locomotion(vel, on_floor, on_wall, dashing))
	elif _timer > 0.0:
		_timer -= delta
		if _timer <= 0.0: _set_state(_locomotion(vel, on_floor, on_wall, dashing))
	else:
		_set_state(_locomotion(vel, on_floor, on_wall, dashing))
	_pose(vel, delta)

func set_facing(dir: int) -> void:
	if dir != 0: facing = 1 if dir > 0 else -1
	scale.x = float(facing)

func play_slash(step: int = 1) -> void:
	if state == State.DEAD: return
	air_slash = not _was_floor
	combo_step = clampi(step, 1, 3)
	_seq_t = 0.0
	var dur := AIR_SLASH_TIME
	if not air_slash:
		dur = 0.0
		for d in COMBO_SEQ[combo_step - 1]: dur += d
	var prev := state
	_start_timed(State.SLASH, dur)
	if prev == State.SLASH: state_changed.emit(State.SLASH, State.SLASH)   # each combo hit is a fresh entry
	var heavy := 1.6 if combo_step == 3 and not air_slash else 1.0
	_kick(SLASH_LUNGE_SQUASH * heavy)
	_off.x += SLASH_LUNGE_PX * heavy
	if _trail:
		_trail.clear_points(); _trail_alpha = 1.0; _trail.modulate.a = 1.0
		var ci := 0 if air_slash else combo_step - 1
		_trail.width = COMBO_TRAIL_W[ci]; _trail.default_color = COMBO_TRAIL_COL[ci]

func can_cancel() -> bool:
	## true once the active cut is over (follow-through / recover cells)
	if state != State.SLASH: return true
	if air_slash: return _seq_t >= 0.15
	var seq: Array = COMBO_SEQ[combo_step - 1]
	var t := 0.0
	for i in range(CANCEL_FRAME): t += seq[i]
	return _seq_t >= t

func play_domain_cast() -> void:
	if state == State.DEAD: return
	_start_timed(State.DOMAIN_CAST, DOMAIN_CAST_TIME)
	_kick(TAKEOFF_STRETCH)
	_pose(Vector2.ZERO, 0.0)   # show the rite pose now: the DOMAIN cut-in pauses the tree right after

func play_victory() -> void:
	if state == State.DEAD: return
	_start_timed(State.VICTORY, VICTORY_TIME)

func play_throw() -> void:
	if state == State.DEAD or (state == State.SLASH and not can_cancel()): return
	_start_timed(State.THROW, THROW_TIME)

func play_hurt() -> void:
	if state == State.DEAD: return
	_start_timed(State.HURT, HURT_TIME)
	_kick(HURT_SQUASH)
	_off.x -= HURT_RECOIL_PX
	_lean = HURT_TILT

func play_land(impact: float) -> void:
	_kick(LAND_SQUASH * clampf(impact, 0.0, 1.0))
	if impact >= 1.0: _land_t = LAND_HOLD

func play_double_jump() -> void:
	## distinct beat for the second jump: a forward somersault on the tuck frame
	if state == State.DEAD: return
	_spin_t = 0.0 if _reduced_motion() else DOUBLE_JUMP_SPIN_T   # reduced motion: tuck frame, no somersault
	_air_t = JUMP_LAUNCH_T
	_kick(TAKEOFF_STRETCH)
	if state != State.SLASH and state != State.HURT:
		_start_timed(State.DOUBLE_JUMP, DOUBLE_JUMP_SPIN_T)

func _reduced_motion() -> bool:
	var ml := Engine.get_main_loop() as SceneTree
	var gm = ml.root.get_node_or_null("GameManager") if ml else null
	return gm != null and gm.reduced_motion

func play_emote(kind: String) -> void:
	if state == State.DEAD or _timer > 0.0: return
	if kind == "victory": play_victory(); return
	if not EMOTE_KINDS.has(kind):
		push_warning("PlayerAnimator: unknown emote '%s'" % kind); return
	emote_kind = kind
	_set_state(State.EMOTE)
	_timer = 0.0
	_emote_left = EMOTE_TIME

func play_dead() -> void:
	_dead_t = 0.0
	_timer = 0.0
	_set_state(State.DEAD)

func revive() -> void:
	## Back to normal after a checkpoint respawn.
	_dead_t = 0.0
	if _body: _body.modulate.a = 1.0
	_set_state(State.IDLE)

# ---------------------------------------------------------------- internals -----
var _emote_left := 0.0

func _start_timed(s: int, dur: float) -> void:
	_timer = dur
	_set_state(s)

func _set_state(s: int) -> void:
	if s == state: return
	var old := state
	state = s
	if old == State.DASH and (s == State.IDLE or s == State.RUN): _dash_stop_t = DASH_STOP_HOLD
	state_changed.emit(s, old)

func _locomotion(vel: Vector2, on_floor: bool, on_wall: bool, dashing: bool) -> int:
	if dashing: return State.DASH
	if not on_floor:
		if on_wall and vel.y > 0.0: return State.WALL_SLIDE
		return State.FALL if vel.y > FALL_SPEED_MIN else State.JUMP
	if absf(vel.x) > RUN_SPEED_MIN: return State.RUN
	return State.IDLE

func _kick(amount: float) -> void:
	_squash_v += amount * SPRING_IMPULSE_SPEED

func _smooth(cur: float, target: float, sharp: float, delta: float) -> float:
	return lerpf(cur, target, 1.0 - exp(-sharp * delta))

func _pose(vel: Vector2, delta: float) -> void:
	var tex_key := "idle"
	var lean_t := 0.0
	var bob := 0.0
	var squash_t := 0.0          # spring rest point
	var breath := 0.0
	match state:
		State.IDLE:
			# 6-cell breathing sheet at the old breath rate, plus a faint procedural sway
			tex_key = "idle_%d" % (int(_t * BREATH_HZ * IDLE_FRAMES) % IDLE_FRAMES)
			if not textures.has(tex_key): tex_key = "idle"; breath = sin(_t * TAU * BREATH_HZ) * BREATH_AMT
			if _land_t > 0.0: tex_key = "j_land"; breath = 0.0
			if _dash_stop_t > 0.0: tex_key = "dash_stop"; breath = 0.0
		State.RUN:
			_run_t += delta * RUN_FPS
			tex_key = "run_%d" % (int(_run_t) % RUN_SHEET_FRAMES)
			if not textures.has(tex_key): tex_key = RUN_FRAMES[int(_run_t * 0.5) % RUN_FRAMES.size()]
			bob = -absf(sin(_run_t * PI * 0.25)) * RUN_BOB_PX
			lean_t = RUN_LEAN
			if _land_t > 0.0: tex_key = "j_land"
			if _dash_stop_t > 0.0: tex_key = "dash_stop"
		State.JUMP, State.FALL:
			tex_key = _jump_frame(vel.y)
			lean_t = clampf(vel.y * AIR_TILT_PER_VY, -AIR_TILT_MAX, AIR_TILT_MAX)
		State.DOUBLE_JUMP:
			tex_key = "j_tuck"; lean_t = 0.0
		State.DOMAIN_CAST:
			# rite pose: blade raised, body rises a touch while the moon ring opens
			tex_key = "s_high"; bob = -6.0; squash_t = -0.05
		State.VICTORY:
			var vp := VICTORY_TIME - _timer
			bob = -absf(sin(vp * TAU * VICTORY_HZ * 0.5)) * VICTORY_HOP_PX if vp < 0.9 else 0.0
			tex_key = "j_rise" if bob < -VICTORY_HOP_PX * 0.5 else ("s_recover" if vp >= 0.9 else "idle_0")
		State.WALL_SLIDE:
			tex_key = "wall"; lean_t = WALL_LEAN
		State.DASH:
			tex_key = "dash"; lean_t = DASH_LEAN * 0.4; squash_t = DASH_STRETCH   # own painted pose (already leaning)
		State.SLASH:
			_seq_t += delta
			var seq: Array = AIR_SLASH_SEQ if air_slash else SLASH_SEQ
			var blades: Array = AIR_BLADE if air_slash else SLASH_BLADE
			if not air_slash and textures.has("c0_0"):
				var r := combo_step - 1
				seq = []
				for i in range(5): seq.append(["c%d_%d" % [r, i], COMBO_SEQ[r][i]])
				blades = COMBO_BLADE[r]
			var acc_t := 0.0
			var idx := seq.size() - 1
			for i in range(seq.size()):
				if _seq_t < acc_t + seq[i][1]: idx = i; break
				acc_t += seq[i][1]
			tex_key = seq[idx][0]
			var f := clampf((_seq_t - acc_t) / seq[idx][1], 0.0, 1.0)
			var a0: float = blades[idx]
			var a1: float = blades[mini(idx + 1, blades.size() - 1)]
			if idx >= 1 and idx <= seq.size() - 2:   # trail follows the blade from the first swing frame
				_record_trail_angle(lerpf(a0, a1, f), AIR_TRAIL_CENTRE if air_slash else TRAIL_CENTRE)
		State.THROW:
			tex_key = "run1"; lean_t = THROW_LEAN
		State.HURT:
			tex_key = "hurt"; lean_t = HURT_TILT
		State.EMOTE:
			_emote_left -= delta
			var p := _t
			match emote_kind:
				"wave": lean_t = sin(p * TAU * WAVE_HZ) * WAVE_SWAY
				"victory": bob = -absf(sin(p * TAU * VICTORY_HZ * 0.5)) * VICTORY_HOP_PX; tex_key = "j_rise" if bob < -VICTORY_HOP_PX * 0.5 else "idle"
				"taunt": lean_t = TAUNT_LEAN + sin(p * TAU * TAUNT_HZ) * 0.03
				"bow": lean_t = BOW_TILT * clampf((EMOTE_TIME - _emote_left) * 4.0, 0.0, 1.0) * clampf(_emote_left * 4.0, 0.0, 1.0)
			if _emote_left <= 0.0: _set_state(State.IDLE)
		State.DEAD:
			_dead_t += delta
			var k := clampf(_dead_t / DEAD_FADE, 0.0, 1.0)
			tex_key = "hurt"; lean_t = -DEAD_TILT * k; bob = DEAD_SINK_PX * k
			_body.modulate.a = 1.0 - 0.6 * k
	# textures (the painted sprite stays on screen; only its pose image changes)
	frame_key = tex_key
	if _sprite and textures.has(tex_key) and _sprite.texture != textures[tex_key]:
		_sprite.texture = textures[tex_key]
		# frames have their own sizes: keep the feet on the collision bottom
		var sy0 := _sprite.scale.y if _sprite.scale.y != 0.0 else 1.0
		_sprite.offset = Vector2(0, -_sprite.position.y / sy0 - (_sprite.texture.get_height() / 2.0 - FRAME_PAD))
	# damped spring for squash / stretch
	var acc := -SPRING_K * (_squash - squash_t) - SPRING_DAMP * _squash_v
	_squash_v += acc * delta
	_squash = clampf(_squash + _squash_v * delta, -SQUASH_MAX, SQUASH_MAX)
	var sy := 1.0 - _squash + breath
	var sx := 1.0 + _squash * 0.8 - breath * 0.5
	_body.scale = Vector2(sx, sy)
	# lean and offsets chase their targets
	_lean = _smooth(_lean, lean_t, LEAN_SHARPNESS, delta)
	var spin := 0.0
	if _spin_t > 0.0:
		_spin_t -= delta
		spin = TAU * (1.0 - clampf(_spin_t / DOUBLE_JUMP_SPIN_T, 0.0, 1.0))
		if state == State.JUMP or state == State.FALL or state == State.DOUBLE_JUMP:
			frame_key = "j_tuck"
			if _sprite and textures.has("j_tuck") and _sprite.texture != textures["j_tuck"]:
				_sprite.texture = textures["j_tuck"]
				_sprite.offset = Vector2(0, -_sprite.position.y / _sprite.scale.y - (_sprite.texture.get_height() / 2.0 - FRAME_PAD))
		else:
			spin = 0.0; _spin_t = 0.0
	_body.rotation = _lean + spin
	_off = Vector2(_smooth(_off.x, 0.0, OFFSET_SHARPNESS, delta), _smooth(_off.y, bob, OFFSET_SHARPNESS, delta))
	var pivot := Vector2(0, BODY_CENTRE_Y)
	_body.position = Vector2(0, FEET_Y) + _off + (pivot - pivot.rotated(spin) if spin != 0.0 else Vector2.ZERO)
	# optional limbs chase simple targets (only when the rig provides them)
	if not _limbs.is_empty():
		var swing := sin(_run_t * PI * 0.5) * (0.6 if state == State.RUN else 0.0)
		var targets := {"LegBack": -swing, "LegFront": swing, "ArmBack": swing * 0.7, "ArmFront": -swing * 0.7}
		if state == State.SLASH: targets["ArmFront"] = lerpf(TRAIL_ARC_FROM, TRAIL_ARC_TO, 1.0 - _timer / SLASH_TIME)
		for n in _limbs:
			_limbs[n].rotation = _smooth(_limbs[n].rotation, targets[n], LIMB_SHARPNESS, delta)
	# trail fade after the slash
	if _trail and state != State.SLASH and _trail.get_point_count() > 0:
		_trail_alpha -= delta / TRAIL_FADE
		_trail.modulate.a = maxf(_trail_alpha, 0.0)
		if _trail_alpha <= 0.0: _trail.clear_points()

func _jump_frame(vy: float) -> String:
	if _jumped and _air_t < JUMP_CROUCH_T: return "j_crouch"
	if _jumped and _air_t < JUMP_LAUNCH_T: return "j_launch"
	if vy < JUMP_VY_RISE: return "j_rise"
	if vy < JUMP_VY_TUCK: return "j_tuck"
	if vy < JUMP_VY_APEX: return "j_apex"
	if vy < JUMP_VY_FALL0: return "j_fall0"
	if vy < JUMP_VY_FALL: return "j_fall"
	return "j_preland"

func _record_trail_angle(a: float, centre: Vector2) -> void:
	if _trail == null: return
	if _weapon:
		_record_trail(0.0); return
	_trail.add_point(centre + Vector2(cos(a), sin(a)) * TRAIL_RADIUS)
	while _trail.get_point_count() > TRAIL_POINTS:
		_trail.remove_point(0)

func _record_trail(progress: float) -> void:
	if _trail == null: return
	var tip: Vector2
	if _weapon:
		tip = to_local(_weapon.global_position)
	else:
		var a := lerpf(TRAIL_ARC_FROM, TRAIL_ARC_TO, clampf(progress, 0.0, 1.0))
		tip = TRAIL_CENTRE + Vector2(cos(a), sin(a)) * TRAIL_RADIUS
	_trail.add_point(tip)
	while _trail.get_point_count() > TRAIL_POINTS:
		_trail.remove_point(0)
