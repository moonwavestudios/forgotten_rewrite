extends Node

const SURVIVORS_DIR := "res://data/survivors/"
const KILLERS_DIR   := "res://data/killers/"

var survivors : Dictionary = {}   
var killers   : Dictionary = {}   
var skins     : Dictionary = {}  

signal data_loaded

func _ready() -> void:
	_load_all()
	emit_signal("data_loaded")

func get_survivor(id: String) -> Dictionary:
	return survivors.get(id, {})

func get_killer(id: String) -> Dictionary:
	return killers.get(id, {})

func get_skins(character_id: String, type: String) -> Array:
	var data = get_killer(character_id) if type == "killer" else get_survivor(character_id)
	return data.get("skins", [])

func get_skin(character_id: String, type: String, skin_id: String) -> Dictionary:
	for skin in get_skins(character_id, type):
		if skin.get("id") == skin_id:
			return skin
	return {}

func get_skin_animations(character_id: String, type: String, skin_id: String) -> Dictionary:
	var skin = get_skin(character_id, type, skin_id)
	return skin.get("animations", {})

func get_animation(character_id: String, type: String, skin_id: String, action: String) -> String:
	var animations = get_skin_animations(character_id, type, skin_id)
	return animations.get(action, "")

func has_skin_animations(character_id: String, type: String, skin_id: String) -> bool:
	return not get_skin_animations(character_id, type, skin_id).is_empty()

func get_animation_safe(character_id: String, type: String, skin_id: String, action: String, fallback: String = "") -> String:
	var anim = get_animation(character_id, type, skin_id, action)
	if anim.is_empty():
		return fallback if not fallback.is_empty() else action
	return anim

func _load_all() -> void:
	survivors = _load_directory(SURVIVORS_DIR)
	killers   = _load_directory(KILLERS_DIR)

	print("[GameData] Loaded %d survivor(s), %d killer(s)" % [
		survivors.size(), killers.size()
	])

func _load_directory(dir_path: String) -> Dictionary:
	var registry: Dictionary = {}
	var dir := DirAccess.open(dir_path)

	if dir == null:
		push_warning("[GameData] Directory not found: %s" % dir_path)
		return registry

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var full_path := dir_path + file_name
			var data := _parse_json_file(full_path)

			if data.is_empty():
				push_warning("[GameData] Skipping empty or invalid file: %s" % full_path)
			elif not data.has("id"):
				push_warning("[GameData] Missing 'id' field in: %s" % full_path)
			else:
				registry[data["id"]] = data

		file_name = dir.get_next()

	dir.list_dir_end()
	return registry

func _parse_json_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		push_error("[GameData] Could not open file: %s" % path)
		return {}

	var text    := file.get_as_text()
	var parsed  = JSON.parse_string(text)

	if parsed == null:
		push_error("[GameData] JSON parse error in: %s" % path)
		return {}

	if parsed is not Dictionary:
		push_error("[GameData] Expected a JSON object (Dictionary) in: %s" % path)
		return {}

	return parsed

func reload_file(path: String) -> void:
	var data := _parse_json_file(path)
	if data.is_empty() or not data.has("id"):
		push_error("[GameData] reload_file: invalid data in %s" % path)
		return

	match data.get("type", ""):
		"survivor": survivors[data["id"]] = data
		"killer":   killers[data["id"]]   = data
		"skin":     skins[data["id"]]     = data
		_:          push_warning("[GameData] reload_file: unknown type in %s" % path)

	print("[GameData] Reloaded: %s (%s)" % [data["id"], data.get("type", "?")])
