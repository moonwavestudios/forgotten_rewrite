class_name VoicelineComponent
extends Node

@onready var player = $".."

const IDLE_MIN_INTERVAL := 15.0
const IDLE_MAX_INTERVAL := 25.0

var _cooldowns: Dictionary = {}
var _idle_timer: float = 0.0

const CATEGORY_COOLDOWN := {
	"intro":    0.0,
	"idle":    20.0,
	"kill":     4.0,
	"victory":  0.0,
	"stun":     6.0,
	
}

const ABILITY_COOLDOWN := 8.0

@onready var _sfx: AudioStreamPlayer3D = _get_or_create_sfx()
@onready var _idle_sfx: AudioStreamPlayer3D = _get_or_create_idle_sfx()

var _lines: Dictionary = {}
var _current_idle_loops: bool = false

func _ready() -> void:
	_idle_timer = randf_range(IDLE_MIN_INTERVAL, IDLE_MAX_INTERVAL)

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
	_restart_idle_loop()

func _restart_idle_loop() -> void:
	var streams: Array = _lines.get("idle", [])
	if streams.is_empty():
		_idle_sfx.stop()
		_current_idle_loops = false
		return

	var stream = streams[randi() % streams.size()]
	_idle_sfx.stream = stream
	_idle_sfx.play()
	_current_idle_loops = true

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
	if _current_idle_loops:
		return
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
	player.add_child.call_deferred(sfx)
	return sfx

func _get_or_create_idle_sfx() -> AudioStreamPlayer3D:
	var existing = player.get_node_or_null("voicelines_idle")
	if existing is AudioStreamPlayer3D:
		return existing
	var sfx := AudioStreamPlayer3D.new()
	sfx.name = "voicelines_idle"
	sfx.bus = "Master"
	sfx.max_distance = 30.0
	player.add_child.call_deferred(sfx)
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

	if not player.in_round:
		return

	if _current_idle_loops:
		if not _idle_sfx.playing:
			_restart_idle_loop()
		return

	_idle_timer -= delta
	if _idle_timer <= 0.0:
		play_idle()
		_idle_timer = randf_range(IDLE_MIN_INTERVAL, IDLE_MAX_INTERVAL)
