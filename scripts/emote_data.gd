extends Node

var Emotes = {
	"Wave" = {
		"Price" = 50,
		"Limited" = false,
		"animation" = "emote_wave",
		"duration" = 2.0
	},
}

func get_emote(emote_name: String) -> Dictionary:
	return Emotes.get(emote_name, {})

func is_unlocked(emote_name: String, player_emotes: Array) -> bool:
	return emote_name in player_emotes
