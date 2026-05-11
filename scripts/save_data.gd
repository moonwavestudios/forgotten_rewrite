extends Node

const SAVE_PATH = "user://save.mwdat"
const DEFAULT_OWNED_CHARACTERS = ["eli", "swordman", "yixi"]

func _load_all() -> Dictionary:
	#if not FileAccess.file_exists(SAVE_PATH):
		#return {}
	#var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	#if f == null:
		#push_warning("Couldn't open save file")
		#return {}
	var parsed = MWDat.load(SAVE_PATH)
	if parsed is Dictionary:
		return parsed
	return {}

func _save_all(data: Dictionary) -> void:
	#var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	#if f == null:
		#push_warning("Couldn't write save file")
		#return
	#f.store_string(JSON.stringify(data, "\t"))
	MWDat.save(SAVE_PATH, data)

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
	var owned = data.get("owned_characters", [])
	for default_id in DEFAULT_OWNED_CHARACTERS:
		if default_id not in owned:
			owned.append(default_id)
	return owned

func get_coins() -> int:
	var data = _load_all()
	return data.get("coins", 0)

func set_coins(amount: int) -> void:
	var data = _load_all()
	data["coins"] = amount
	_save_all(data)

func get_malice() -> int:
	var data = _load_all()
	return data.get("malice", -100)

func set_malice(amount: int) -> void:
	var data = _load_all()
	data["malice"] = amount
	_save_all(data)

func get_settings() -> Dictionary:
	var data = _load_all()
	return data.get("player_settings", {})

func set_settings(settings: Dictionary) -> void:
	var data = _load_all()
	data["player_settings"] = settings
	_save_all(data)

func get_character_xp(character_id: String) -> int:
	var data = _load_all()
	return data.get("character_xp", {}).get(character_id, 0)

func add_character_xp(character_id: String, amount: int) -> void:
	var data = _load_all()
	if not data.has("character_xp"):
		data["character_xp"] = {}
	data["character_xp"][character_id] = data["character_xp"].get(character_id, 0) + amount
	_save_all(data)

func own_character(character_id: String) -> void:
	var data = _load_all()
	if not data.has("owned_characters"):
		data["owned_characters"] = []
	if character_id not in data["owned_characters"]:
		data["owned_characters"].append(character_id)
	_save_all(data)

func has_character(character_id: String) -> bool:
	var data = _load_all()
	if character_id in data.get("owned_characters", []):
		return true
	return character_id in DEFAULT_OWNED_CHARACTERS

func has_skin(character_id: String, skin_id: String) -> bool:
	if skin_id == "default":
		return true  
	var owned = get_owned_skins()
	return owned.get(character_id, []).has(skin_id)

func get_playtime(character_id: String) -> float:
	var data = _load_all()
	return data.get("character_playtime", {}).get(character_id, 0.0)

func add_playtime(character_id: String, seconds: float) -> void:
	var data = _load_all()
	if not data.has("character_playtime"):
		data["character_playtime"] = {}
	data["character_playtime"][character_id] = data["character_playtime"].get(character_id, 0.0) + seconds
	_save_all(data)

func get_equipped_skin(character_id: String) -> String:
	var data = _load_all()
	return data.get("equipped_skins", {}).get(character_id, "default")

func get_equipped_character(type: String) -> String:
	var data = _load_all()
	return data.get("equipped_characters", {}).get(type, "")

func set_equipped_character(type: String, character_id: String) -> void:
	var data = _load_all()
	if not data.has("equipped_characters"):
		data["equipped_characters"] = {}
	data["equipped_characters"][type] = character_id
	_save_all(data)

func set_equipped_skin(character_id: String, skin_id: String) -> void:
	var data = _load_all()
	if not data.has("equipped_skins"):
		data["equipped_skins"] = {}
	data["equipped_skins"][character_id] = skin_id
	_save_all(data)
