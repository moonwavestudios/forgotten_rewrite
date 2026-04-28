extends Control

var player_label = preload("res://UI/stuff/player_list_players.tscn")

func _process(_delta: float) -> void:
	for plr in $"../..".get_players():
		if $SpectatorStuff/PlayerList/ScrollContainer/VBoxContainer.get_children().size() -1 < $"../..".get_player_count():
			var scene = player_label.instantiate()
			$SpectatorStuff/PlayerList/ScrollContainer/VBoxContainer.add_child(scene)
			scene.text = plr.name
			scene.get_node("Malice").text = str(plr.malice)

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
