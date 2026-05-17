class_name VoicelineComponent
extends Node

@onready var player = $".."

const CATEGORY_COOLDOWN := {
	"intro":    0.0,
	"idle":    30.0,
	"kill":     4.0,
	"victory":  0.0,
	"stun":     6.0,
	
}

const ABILITY_COOLDOWN := 8.0

var _cooldowns: Dictionary = {}

@onready var _sfx: AudioStreamPlayer3D = _get_or_create_sfx()

var _lines: Dictionary = {}

func apply_voicelines(voiceline_data: Dictionary) -> void:
	_lines.clear()
	for category in voiceline_data:
		var paths: Array = voiceline_data[category]
		var streams: Array = []
		for path in paths:
			if path != "" and ResourceLoader.exists(path):
				var stream = load(path)
				if stream:
					streams.append(stream)
		if streams.size() > 0:
			_lines[category] = streams

func play(category: String) -> bool:
	if _sfx.playing:
		return false
	if _is_on_cooldown(category):
		return false
	var streams: Array = _lines.get(category, [])
	if streams.is_empty():
		return false
	var stream = streams[randi() % streams.size()]
	_sfx.stream = stream
	_sfx.play()
	_start_cooldown(category)
	return true

func play_idle() -> void:
	play("idle")

func play_intro() -> void:
	play("intro")

func play_kill() -> void:
	play("kill")

func play_victory() -> void:
	play("victory")

func play_stun() -> void:
	play("stun")

func play_ability(ability_type: String) -> void:
	play(ability_type)

func _get_or_create_sfx() -> AudioStreamPlayer3D:
	var existing = player.get_node_or_null("voicelines")
	if existing is AudioStreamPlayer3D:
		return existing
	var sfx := AudioStreamPlayer3D.new()
	sfx.name = "voicelines"
	
	sfx.bus = "Master"
	sfx.max_distance = 30.0
	player.add_child(sfx)
	return sfx

func _is_on_cooldown(category: String) -> bool:
	return _cooldowns.get(category, 0.0) > 0.0

func _start_cooldown(category: String) -> void:
	var cd: float
	if CATEGORY_COOLDOWN.has(category):
		cd = CATEGORY_COOLDOWN[category]
	else:
		cd = ABILITY_COOLDOWN
	_cooldowns[category] = cd

func play_forced(category: String) -> bool:
	if _is_on_cooldown(category):
		return false
	var streams: Array = _lines.get(category, [])
	if streams.is_empty():
		return false
	if _sfx.playing:
		_sfx.stop()
	var stream = streams[randi() % streams.size()]
	_sfx.stream = stream
	_sfx.play()
	_start_cooldown(category)
	return true

func _process(delta: float) -> void:
	for key in _cooldowns:
		if _cooldowns[key] > 0.0:
			_cooldowns[key] = max(0.0, _cooldowns[key] - delta)
