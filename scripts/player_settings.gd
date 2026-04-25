extends Node

var hitsound = ""
var enabled_hitsound = false
var enabled_killsound = false
var killsound = ""

var keybinds: Dictionary = {
	"Ability1": "Q",
	"Ability2": "E",
	"Ability3": "R",
	"Ability4": "F",
	"Attack":   "LMB",
}

func get_keybind_label(action: String) -> String:
	return keybinds.get(action, "?")

func set_keybind(action: String, label: String) -> void:
	keybinds[action] = label
