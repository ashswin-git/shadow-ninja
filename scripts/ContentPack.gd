extends Node

var active_pack_id: String = "original"
var pack_data: Dictionary = {}

func _ready() -> void:
	load_pack(active_pack_id)

func load_pack(pack_id: String) -> void:
	active_pack_id = pack_id
	var path = "res://content/" + pack_id + "/pack.json"
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK:
				var data = json.get_data()
				if data is Dictionary:
					pack_data = data

func get_title() -> String:
	return pack_data.get("title", "Aether Shinobi: Spirit Blade")

func get_font(bold: bool = false) -> Font:
	var font_path = pack_data.get("font_bold" if bold else "font", "res://content/original/fonts/OpenSauceSans-Regular.ttf")
	if ResourceLoader.exists(font_path):
		return load(font_path)
	return null

func get_color(color_name: String) -> Color:
	var palette = pack_data.get("palette", {})
	var hex = palette.get(color_name, "#ffffff")
	return Color(hex)
