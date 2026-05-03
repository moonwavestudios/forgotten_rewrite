extends Control

var player_label = preload("res://UI/stuff/player_list_players.tscn")

var selected_player = ""

@onready var player_profile = $SpectatorStuff/PlayerProfile

func _process(_delta: float) -> void:
	var human_players = $"../..".get_players().filter(func(p): return not p.is_in_group("AI"))
	for plr in human_players:
		if $SpectatorStuff/PlayerList/ScrollContainer/VBoxContainer.get_children().size() -1 < human_players.size():
			var scene = player_label.instantiate()
			$SpectatorStuff/PlayerList/ScrollContainer/VBoxContainer.add_child(scene)
			scene.text = plr.name
			scene.name = plr.name
			scene.get_node("Malice").text = str(plr.malice)
			scene.get_node("Button").pressed.connect(player_lists_button_pressed.bind(plr.name))

func _on_spin_box_value_changed(value: float) -> void:
	for plr in $"../..".get_players():
		if plr.name == $Both/Admin_Panel/ScrollContainer/VBoxContainer/GiveCoins/LineEdit.text:
			plr.give_coins(value)
	
func _on_give_killer_pressed() -> void:
	for plr in $"../..".get_players():
		if plr.name == $Both/Admin_Panel/ScrollContainer/VBoxContainer/MakeKiller/LineEdit.text:
			plr.apply_character_stats()
			plr.apply_skin(plr.equipped_skin_id)
			plr._refresh_abilities()
			plr.is_Killer = true

func player_lists_button_pressed(player_name: String):
	for plr in $"../..".get_players():
		if plr.name == player_name:
			if selected_player == player_name:
				player_profile.visible = not player_profile.visible
				selected_player = ""
			else:
				player_profile.visible = true
				selected_player = player_name
			player_profile.get_node("Label").text = plr.name + "'s Profile"
			_update_profile_playtime(plr)

func _update_profile_playtime(plr) -> void:
	var pt_total = int(plr.playtime_seconds)
	var pt_h = pt_total / 3600
	var pt_m = (pt_total % 3600) / 60
	var pt_s = pt_total % 60
	player_profile.get_node("Label2").text = "%02d:%02d:%02d" % [pt_h, pt_m, pt_s]
