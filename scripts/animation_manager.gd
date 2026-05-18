class_name AnimationManager
extends Node

@onready var anim_player: AnimationPlayer = get_parent().find_child("AnimationPlayer") if is_node_ready() else null
@onready var char_data: Node = get_tree().get_first_node_in_group("GameData") if get_tree() else null

var character_id: String = ""
var character_type: String = ""
var skin_id: String = "default"

var _resolved_cache: Dictionary = {}

func _ready() -> void:
	if not anim_player and is_node_ready():
		anim_player = get_parent().find_child("AnimationPlayer")
	if not char_data and get_tree():
		char_data = get_tree().get_first_node_in_group("GameData")

func initialize(char_id: String, type: String, skin: String = "default") -> void:
	character_id = char_id
	character_type = type
	skin_id = skin
	_resolved_cache.clear()
	_load_animation_library(char_id, type, skin)

func _load_animation_library(char_id: String, type: String, skin: String) -> void:
	if not anim_player:
		push_warning("[AnimationManager] No AnimationPlayer")
		return

	var skin_data := CharData.get_skin(char_id, type, skin)
	var lib_path: String = skin_data.get("animation_library", "")

	if lib_path == "" and skin != "default":
		var default_skin := CharData.get_skin(char_id, type, "default")
		lib_path = default_skin.get("animation_library", "")

	if lib_path == "" or not ResourceLoader.exists(lib_path):
		push_warning("[AnimationManager] No animation library found for %s / %s" % [char_id, skin])
		return

	var lib := load(lib_path) as AnimationLibrary
	if lib == null:
		push_warning("[AnimationManager] Failed to load AnimationLibrary: %s" % lib_path)
		return

	if anim_player.has_animation_library("skin"):
		anim_player.remove_animation_library("skin")

	anim_player.add_animation_library("skin", lib)

func get_animation_name(action: String) -> String:
	if _resolved_cache.has(action):
		return _resolved_cache[action]

	var skin_data := CharData.get_skin(character_id, character_type, skin_id)
	var supported: Array = skin_data.get("animations", [])

	var qualified := "skin/" + action
	if (supported.is_empty() or action in supported) and anim_player and anim_player.has_animation(qualified):
		_resolved_cache[action] = qualified
		return qualified

	var default_qualified := "default_skin/" + action
	if anim_player and anim_player.has_animation(default_qualified):
		_resolved_cache[action] = default_qualified
		return default_qualified

	if anim_player and anim_player.has_animation(action):
		_resolved_cache[action] = action
		return action

	return ""

func load_kill_animation(killer_id: String) -> bool:
	var skin_data := CharData.get_skin(character_id, character_type, skin_id)
	var kill_anims: Dictionary = skin_data.get("kill_animations", {})
	var lib_path: String = kill_anims.get(killer_id, "")

	if lib_path == "" or not ResourceLoader.exists(lib_path):
		return false

	var lib_name := "kill_" + killer_id

	if anim_player.has_animation_library(lib_name):
		return true

	var lib := load(lib_path) as AnimationLibrary
	if lib == null:
		return false

	anim_player.add_animation_library(lib_name, lib)
	return true

func play_kill_animation(killer_id: String) -> void:
	if not anim_player:
		return

	if not load_kill_animation(killer_id):
		play_action_safe("death", "idle")
		return

	var anim_name := "kill_" + killer_id + "/death"
	if anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
	else:
		play_action_safe("death", "idle")

func unload_kill_animation(killer_id: String) -> void:
	var lib_name := "kill_" + killer_id
	if anim_player and anim_player.has_animation_library(lib_name):
		anim_player.remove_animation_library(lib_name)

func play_action(action: String, blend_time: float = 0.1, speed: float = 1.0) -> void:
	if not anim_player:
		push_warning("[AnimationManager] AnimationPlayer not found")
		return

	var anim_name := get_animation_name(action)

	if anim_name.is_empty() or not anim_player.has_animation(anim_name):
		push_warning("[AnimationManager] Animation '%s' not found for action '%s' (skin: %s)" % [anim_name, action, skin_id])
		return

	anim_player.play(anim_name, blend_time, speed)

func play_action_safe(action: String, fallback_action: String = "idle", blend_time: float = 0.1, speed: float = 1.0) -> void:
	if not anim_player:
		push_warning("[AnimationManager] AnimationPlayer not found")
		return

	var anim_name := get_animation_name(action)

	if anim_name.is_empty() or not anim_player.has_animation(anim_name):
		anim_name = get_animation_name(fallback_action)

	if anim_name.is_empty() or not anim_player.has_animation(anim_name):
		push_warning("[AnimationManager] No usable animation for action '%s' or fallback '%s'" % [action, fallback_action])
		return

	anim_player.play(anim_name, blend_time, speed)

func get_available_animations() -> Dictionary:
	if not char_data or not anim_player:
		return {}

	var all: Dictionary = char_data.get_skin_animations(character_id, character_type, skin_id)
	var available: Dictionary = {}

	for action in all:
		var anim_name: String = all[action]
		if not anim_name.is_empty() and anim_player.has_animation(anim_name):
			available[action] = anim_name

	return available

func get_all_animations() -> Dictionary:
	if not char_data:
		push_warning("[AnimationManager] GameData not found")
		return {}
	return char_data.get_skin_animations(character_id, character_type, skin_id)

func has_animation(action: String) -> bool:
	if not anim_player:
		return false
	var anim_name := get_animation_name(action)
	return not anim_name.is_empty() and anim_player.has_animation(anim_name)

func set_animation_player(player: AnimationPlayer) -> void:
	anim_player = player
	_resolved_cache.clear()

func set_char_data(data: Node) -> void:
	char_data = data
	_resolved_cache.clear()

func set_skin(skin: String) -> void:
	skin_id = skin
	_resolved_cache.clear()
