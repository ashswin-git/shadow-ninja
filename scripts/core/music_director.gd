class_name MusicDirector
extends Node
## Phase 5: music per act + boss theme on the "Music" bus, 0.8 s crossfade, ducking while paused.
## Volumes come from Settings (GameManager.apply_audio drives the Music / SFX buses).

## Rich art pass: 8 stereo arranged loops (tools/gen_music_rich.py), one theme per boss + a victory loop.
const TRACKS := {"menu": "res://assets/audio/music/menu.ogg", "act1": "res://assets/audio/music/act1.ogg",
	"act2": "res://assets/audio/music/act2.ogg", "act3": "res://assets/audio/music/act3.ogg",
	"boss": "res://assets/audio/music/boss_rin.ogg", "boss_rin": "res://assets/audio/music/boss_rin.ogg",
	"boss_gorrah": "res://assets/audio/music/boss_gorrah.ogg", "boss_vey": "res://assets/audio/music/boss_vey.ogg",
	"victory": "res://assets/audio/music/victory.ogg"}
const FADE := 0.8
const DUCK_DB := -10.0
var _a: AudioStreamPlayer
var _b: AudioStreamPlayer
var current := ""
var _duck := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var p := AudioStreamPlayer.new(); p.bus = &"Music"; p.volume_db = -80.0; add_child(p)
		if i == 0: _a = p
		else: _b = p

func _exit_tree() -> void:
	# stop + drop streams so the Ogg playback objects don't outlive the engine at quit (exit leak)
	for p in [_a, _b]:
		if p: p.stop(); p.stream = null

static func track_for_level(n: int) -> String:
	if n in [4, 8, 12]: return {4: "boss_rin", 8: "boss_gorrah", 12: "boss_vey"}[n]
	return "act1" if n <= 3 else ("act2" if n <= 7 else "act3")

func play(name: String) -> void:
	if name == current or not TRACKS.has(name): return
	current = name
	# headless (CI / tests) uses the Dummy audio driver, which never mixes, so started playbacks are
	# never released and show up as ObjectDB / resource leaks at exit. Nothing is audible there anyway.
	if DisplayServer.get_name() == "headless": return
	var st: AudioStreamOggVorbis = load(TRACKS[name])
	st.loop = true
	var old := _a; _a = _b; _b = old
	_a.stream = st; _a.volume_db = -40.0; _a.play()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_a, "volume_db", 0.0, FADE)
	tw.tween_property(_b, "volume_db", -60.0, FADE)
	tw.chain().tween_callback(_b.stop)

func _process(delta: float) -> void:
	# duck the Music bus while the game is paused (pause menu / results)
	var target := DUCK_DB if get_tree().paused else 0.0
	_duck = move_toward(_duck, target, delta * 30.0)
	var idx := AudioServer.get_bus_index(&"Music")
	if idx >= 0: AudioServer.set_bus_volume_db(idx, GameManager.music_bus_db() + _duck)
