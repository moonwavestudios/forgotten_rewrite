class_name AnimationManager
extends Node

@onready var anim_player: AnimationPlayer = get_parent().find_child("AnimationPlayer") if is_node_ready() else null
@onready var char_data: Node = get_tree().get_first_node_in_group("GameData") if get_tree() else null

var character_id: String = ""
var character_type: String = ""
var skin_id: String = "default"

func _ready() -> void:
	if not anim_player and is_node_ready():
		anim_player = get_parent().find_child("AnimationPlayer")
	
	if not char_data and get_tree():
		char_data = get_tree().get_first_node_in_group("GameData")

func initialize(char_id: String, type: String, skin: String = "default") -> void:
	character_id = char_id
	character_type = type
	skin_id = skin

func get_animation_name(action: String) -> String:
	if not char_data:
		push_warning("[AnimationManager] GameData not found")
		return action
	
	return char_data.get_animation(character_id, character_type, skin_id, action)

func play_action(action: String, blend_time: float = 0.1, speed: float = 1.0) -> void:
	if not anim_player:
		push_warning("[AnimationManager] AnimationPlayer not found")
		return
	
	var anim_name = get_animation_name(action)
	
	if anim_name.is_empty():
		push_warning("[AnimationManager] No animation found for action: %s" % action)
		return
	
	if not anim_player.has_animation(anim_name):
		push_warning("[AnimationManager] Animation not found: %s (for action: %s)" % [anim_name, action])
		return
	
	anim_player.play(anim_name, blend_time, speed)

func play_action_safe(action: String, fallback_action: String = "idle", blend_time: float = 0.1, speed: float = 1.0) -> void:
	if not anim_player:
		push_warning("[AnimationManager] AnimationPlayer not found")
		return
	
	var anim_name = get_animation_name(action)
	
	if anim_name.is_empty() or not anim_player.has_animation(anim_name):
		anim_name = get_animation_name(fallback_action)
	
	if anim_name.is_empty():
		push_warning("[AnimationManager] No animation found for action: %s (fallback: %s)" % [action, fallback_action])
		return
	
	if not anim_player.has_animation(anim_name):
		push_warning("[AnimationManager] Animation not found: %s" % anim_name)
		return
	
	anim_player.play(anim_name, blend_time, speed)

func get_all_animations() -> Dictionary:
	if not char_data:
		push_warning("[AnimationManager] GameData not found")
		return {}
	
	return char_data.get_skin_animations(character_id, character_type, skin_id)

func has_animation(action: String) -> bool:
	var anim_name = get_animation_name(action)
	if not anim_player:
		return false
	return anim_player.has_animation(anim_name)

func set_animation_player(player: AnimationPlayer) -> void:
	anim_player = player

func set_char_data(data: Node) -> void:
	char_data = data
