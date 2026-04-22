extends Node

const SAVE_PATH = "user://save.json"

func _load_all() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		push_warning("Couldn't open save file")
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		return parsed
	return {}

func _save_all(data: Dictionary) -> void:
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Couldn't write save file")
		return
	f.store_string(JSON.stringify(data, "\t"))

func get_owned_skins() -> Dictionary:
	var data = _load_all()
	return data.get("owned_skins", {})

func own_skin(character_id: String, skin_id: String) -> void:
	var data = _load_all()
	if not data.has("owned_skins"):
		data["owned_skins"] = {}
	if not data["owned_skins"].has(character_id):
		data["owned_skins"][character_id] = []
	if skin_id not in data["owned_skins"][character_id]:
		data["owned_skins"][character_id].append(skin_id)
	_save_all(data)

func get_owned_characters() -> Array:
	var data = _load_all()
	return data.get("owned_characters", [])

func own_character(character_id: String) -> void:
	var data = _load_all()
	if not data.has("owned_characters"):
		data["owned_characters"] = []
	if character_id not in data["owned_characters"]:
		data["owned_characters"].append(character_id)
	_save_all(data)

func has_character(character_id: String) -> bool:
	var data = _load_all()
	return character_id in data.get("owned_characters", [])

func has_skin(character_id: String, skin_id: String) -> bool:
	if skin_id == "default":
		return true  
	var owned = get_owned_skins()
	return owned.get(character_id, []).has(skin_id)

func get_equipped_skin(character_id: String) -> String:
	var data = _load_all()
	return data.get("equipped_skins", {}).get(character_id, "default")

func set_equipped_skin(character_id: String, skin_id: String) -> void:
	var data = _load_all()
	if not data.has("equipped_skins"):
		data["equipped_skins"] = {}
	data["equipped_skins"][character_id] = skin_id
	_save_all(data)
