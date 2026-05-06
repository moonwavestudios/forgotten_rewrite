extends Node

var hitsound = ""
var enabled_hitsound = false
var enabled_killsound = false
var killsound = ""
var show_hitboxes: bool = false

var center_stamina: bool = false

var hitsound_stream: AudioStream = null
var killsound_stream: AudioStream = null

var keybinds: Dictionary = {
	"Ability1": "Q",
	"Ability2": "E",
	"Ability3": "R",
	"Ability4": "F",
	"Attack":   "LMB",
}

func _load() -> void:
	var s: Dictionary = save_data.get_settings()
	if s.is_empty():
		return
	hitsound          = s.get("hitsound",          hitsound)
	killsound         = s.get("killsound",          killsound)
	enabled_hitsound  = s.get("enabled_hitsound",  enabled_hitsound)
	enabled_killsound = s.get("enabled_killsound", enabled_killsound)
	center_stamina = s.get("center_stamina", center_stamina)
	show_hitboxes     = s.get("show_hitboxes",      show_hitboxes)
	if s.has("keybinds"):
		keybinds.merge(s["keybinds"], true)

func save() -> void:
	save_data.set_settings({
		"hitsound":          hitsound,
		"killsound":         killsound,
		"enabled_hitsound":  enabled_hitsound,
		"enabled_killsound": enabled_killsound,
		"show_hitboxes":     show_hitboxes,
		"center_stamina":     center_stamina,
		"keybinds":          keybinds,
	})

func get_keybind_label(action: String) -> String:
	return keybinds.get(action, "?")

static func load_audio_from_path(path: String) -> AudioStream:
	if path == "" or not FileAccess.file_exists(path):
		return null
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return null
	
	var buffer = file.get_buffer(file.get_length())
	file.close()
	
	var ext = path.get_extension().to_lower()
	match ext:
		"mp3":
			var stream = AudioStreamMP3.new()
			stream.data = buffer
			return stream
		"wav":
			var stream = AudioStreamWAV.new()
			stream.data = buffer
			return stream
		"ogg":
			var stream = AudioStreamOggVorbis.load_from_buffer(buffer)
			return stream
		_:
			push_warning("Unsupported audio format: " + ext)
			return null

func set_keybind(action: String, label: String) -> void:
	keybinds[action] = label
	save()

func set_hitsound(value: String) -> void:
	hitsound = value
	save()

func set_killsound(value: String) -> void:
	killsound = value
	save()

func set_enabled_hitsound(value: bool) -> void:
	enabled_hitsound = value
	save()

func set_enabled_killsound(value: bool) -> void:
	enabled_killsound = value
	save()

func set_show_hitboxes(value: bool) -> void:
	show_hitboxes = value
	save()
