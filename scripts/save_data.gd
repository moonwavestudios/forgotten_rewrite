extends Node

const SAVE_PATH = "user://save.mwdat"
const DEFAULT_OWNED_CHARACTERS = ["eli", "swordman", "yixi"]

var _cache: Dictionary = {}
var _cache_loaded: bool = false

func _load_all() -> Dictionary:
	if _cache_loaded:
		return _cache
	var parsed = MWDat.load(SAVE_PATH)
	_cache = parsed if parsed is Dictionary else {}
	_cache_loaded = true
	return _cache

func _save_all(data: Dictionary) -> void:
	_cache = data
	MWDat.save(SAVE_PATH, data)

func get_owned_skins() -> Dictionary:
	return _load_all().get("owned_skins", {})

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
	var owned: Array = _load_all().get("owned_characters", []).duplicate()
	for default_id in DEFAULT_OWNED_CHARACTERS:
		if default_id not in owned:
			owned.append(default_id)
	return owned

func get_coins() -> int:
	return _load_all().get("coins", 0)

func set_coins(amount: int) -> void:
	var data = _load_all()
	data["coins"] = amount
	_save_all(data)

func get_malice() -> int:
	return _load_all().get("malice", -100)

func set_malice(amount: int) -> void:
	var data = _load_all()
	data["malice"] = amount
	_save_all(data)

func get_settings() -> Dictionary:
	return _load_all().get("player_settings", {})

func set_settings(settings: Dictionary) -> void:
	var data = _load_all()
	data["player_settings"] = settings
	_save_all(data)

func get_character_xp(character_id: String) -> int:
	return _load_all().get("character_xp", {}).get(character_id, 0)

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
	if character_id in DEFAULT_OWNED_CHARACTERS:
		return true
	return character_id in _load_all().get("owned_characters", [])

func has_skin(character_id: String, skin_id: String) -> bool:
	if skin_id == "default":
		return true
	return get_owned_skins().get(character_id, []).has(skin_id)

func get_playtime(character_id: String) -> float:
	return _load_all().get("character_playtime", {}).get(character_id, 0.0)

func add_playtime(character_id: String, seconds: float) -> void:
	var data = _load_all()
	if not data.has("character_playtime"):
		data["character_playtime"] = {}
	data["character_playtime"][character_id] = data["character_playtime"].get(character_id, 0.0) + seconds
	_save_all(data)

func get_equipped_skin(character_id: String) -> String:
	return _load_all().get("equipped_skins", {}).get(character_id, "default")

func get_equipped_character(type: String) -> String:
	return _load_all().get("equipped_characters", {}).get(type, "")

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
