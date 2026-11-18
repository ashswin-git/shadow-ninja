class_name CreatureAnimator
extends Node2D
## Procedural motion for painted enemies and bosses (same rig pattern as PlayerAnimator:
## this node flips via scale.x, its Body child holds the painted Sprite2D). The enemy art is
## a painted frame strip (walk + attack frames), so limbs are not split: the owner script still picks the
## strip frame, and this node owns every transform (bob, hit squash, windup lean, recoil).

signal state_changed(new_state: int, old_state: int)

enum State { IDLE, WALK, WINDUP, ATTACK, HURT }

const SPRING_K := 380.0
const SPRING_DAMP := 16.0
const SQUASH_MAX := 0.3
const SPRING_IMPULSE_SPEED := 19.0   # ~sqrt(SPRING_K): an impulse of X peaks near X squash
const HIT_SQUASH := 0.22
const HIT_RECOIL_PX := 10.0
const HIT_TILT := -0.12
const HURT_TIME := 0.18
const WINDUP_LEAN := -0.14          # lean back while charging
const WINDUP_SQUASH := 0.08         # crouch while charging
const ATTACK_LEAN := 0.12           # lunge forward on release
const ATTACK_STRETCH := -0.12
const ATTACK_LUNGE_PX := 8.0
const LEAN_SHARPNESS := 12.0
const OFFSET_SHARPNESS := 16.0
const IDLE_BOB_HZ := 0.38
const WALK_BOB_HZ := 0.95

@export var feet_y := 28.0          # collision bottom; Body pivots here
@export var idle_bob_px := 1.2
@export var walk_bob_px := 1.8
@export var walk_rate := 6.0        # rad/s of the walk bob cycle

var state: int = State.IDLE
var facing: int = 1
var _body: Node2D
var _t := 0.0
var _timer := 0.0
var _squash := 0.0
var _squash_v := 0.0
var _lean := 0.0
var _off := Vector2.ZERO

func _ready() -> void:
	_body = get_node_or_null("Body") as Node2D
	if _body == null:
		push_warning("CreatureAnimator: no Body node; motion disabled")
		return
	_body.position = Vector2(0, feet_y)
	_t = randf() * 4.0

func set_facing(dir: int) -> void:
	if dir != 0: facing = 1 if dir > 0 else -1
	scale.x = float(facing)

func play_windup(dur: float) -> void:
	_timer = dur; _set_state(State.WINDUP)
	_kick(WINDUP_SQUASH)

func play_attack(dur: float, lunge_px := ATTACK_LUNGE_PX) -> void:
	_timer = dur; _set_state(State.ATTACK)
	_kick(ATTACK_STRETCH)
	_off.x += lunge_px

func play_hurt() -> void:
	_timer = HURT_TIME; _set_state(State.HURT)
	_kick(HIT_SQUASH)
	_off.x -= HIT_RECOIL_PX
	_lean = HIT_TILT

func update_motion(moving: bool, delta: float) -> void:
	if _body == null: return
	_t += delta
	scale.x = float(facing)
	if _timer > 0.0:
		_timer -= delta
		if _timer <= 0.0: _set_state(State.WALK if moving else State.IDLE)
	else:
		_set_state(State.WALK if moving else State.IDLE)
	var lean_t := 0.0
	var rest := 0.0
	var bob := 0.0
	match state:
		State.IDLE: bob = -absf(sin(_t * TAU * IDLE_BOB_HZ)) * idle_bob_px
		State.WALK: bob = -absf(sin(_t * walk_rate)) * walk_bob_px
		State.WINDUP: lean_t = WINDUP_LEAN; rest = WINDUP_SQUASH
		State.ATTACK: lean_t = ATTACK_LEAN; rest = ATTACK_STRETCH * 0.5
		State.HURT: lean_t = HIT_TILT
	var acc := -SPRING_K * (_squash - rest) - SPRING_DAMP * _squash_v
	_squash_v += acc * delta
	_squash = clampf(_squash + _squash_v * delta, -SQUASH_MAX, SQUASH_MAX)
	_body.scale = Vector2(1.0 + _squash * 0.8, 1.0 - _squash)
	_lean = lerpf(_lean, lean_t, 1.0 - exp(-LEAN_SHARPNESS * delta))
	_body.rotation = _lean
	var k := 1.0 - exp(-OFFSET_SHARPNESS * delta)
	_off = Vector2(lerpf(_off.x, 0.0, k), lerpf(_off.y, bob, k))
	_body.position = Vector2(0, feet_y) + _off

func _kick(amount: float) -> void:
	_squash_v += amount * SPRING_IMPULSE_SPEED

func _set_state(s: int) -> void:
	if s == state: return
	var old := state
	state = s
	state_changed.emit(s, old)
