extends Node

const SAVE_PATH = "user://shadow_ninja_save.json"

var current_level: int = 1
var unlocked_level: int = 1
var level_stars: Dictionary = {} # level_num -> int (0-3)
var total_coins: int = 0

var audio_pool: Array[AudioStreamPlayer] = []
var pool_index: int = 0
const POOL_SIZE = 8

func _ready() -> void:
	load_game()
	for i in range(POOL_SIZE):
		var p = AudioStreamPlayer.new()
		add_child(p)
		audio_pool.append(p)

func save_game() -> void:
	var data = {
		"unlocked_level": unlocked_level,
		"level_stars": level_stars,
		"total_coins": total_coins
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_game() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK:
				var data = json.get_data()
				if data is Dictionary:
					unlocked_level = data.get("unlocked_level", 1)
					level_stars = data.get("level_stars", {})
					total_coins = data.get("total_coins", 0)

func complete_level(lvl: int, stars: int, coins: int) -> void:
	if lvl >= unlocked_level and lvl <= 12:
		unlocked_level = lvl + 1
	var prev_stars = level_stars.get(str(lvl), 0)
	if stars > prev_stars:
		level_stars[str(lvl)] = stars
	total_coins += coins
	save_game()

func play_sfx(name: String) -> void:
	var path = "res://assets/audio/" + name + ".wav"
	if ResourceLoader.exists(path):
		var player = audio_pool[pool_index]
		pool_index = (pool_index + 1) % POOL_SIZE
		player.stream = load(path)
		player.play()
