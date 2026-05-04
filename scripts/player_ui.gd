extends Control
var player_label = preload("res://UI/stuff/player_list_players.tscn")
var selected_player = ""
@onready var player_profile = $SpectatorStuff/PlayerProfile
@onready var player_list = $SpectatorStuff/PlayerList

var listening_action: String = ""
var listening_button: Button = null

var is_list_visible = true

var listening_just_started: bool = false
var tween: Tween

func _ready() -> void:
	PlayerSettings._load()
	set_process_unhandled_input(false)
	player_list.visible = true
	$SpectatorStuff/Settings_Panel/ScrollContainer/VBoxContainer/Hitboxes/Enable_Hitbox.button_pressed = PlayerSettings.show_hitboxes
	$SpectatorStuff/Settings_Panel/ScrollContainer/VBoxContainer/Killsound/EnableKillsound.button_pressed = PlayerSettings.enabled_killsound
	$SpectatorStuff/Settings_Panel/ScrollContainer/VBoxContainer/Hitsounds/HitsoundsEnable.button_pressed = PlayerSettings.enabled_hitsound
	
	$SpectatorStuff/Settings_Panel/ScrollContainer/VBoxContainer/Slash/SlashKeybind.text = PlayerSettings.get_keybind_label("Attack")
	$SpectatorStuff/Settings_Panel/ScrollContainer/VBoxContainer/Ability1/Ability1Keybind.text = PlayerSettings.get_keybind_label("Ability1")
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("PlayerList"):
		toggle_player_list()
	
	if listening_action == "":
		return
	
	var label: String = ""
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			label = PlayerSettings.get_keybind_label(listening_action)
		else:
			label = OS.get_keycode_string(event.keycode)
			PlayerSettings.set_keybind(listening_action, label)
	elif event is InputEventMouseButton and event.pressed:
		
		if not listening_just_started:
			match event.button_index:
				MOUSE_BUTTON_LEFT:       label = "LMB"
				MOUSE_BUTTON_RIGHT:      label = "RMB"
				MOUSE_BUTTON_MIDDLE:     label = "MMB"
				MOUSE_BUTTON_WHEEL_UP:   label = "WheelUp"
				MOUSE_BUTTON_WHEEL_DOWN: label = "WheelDown"
				_: label = "Mouse%d" % event.button_index
			PlayerSettings.set_keybind(listening_action, label)
		else:
			listening_just_started = false
			return
	else:
		return
	
	listening_button.text = label
	listening_action = ""
	listening_button = null
	get_viewport().set_input_as_handled()

func toggle_player_list() -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

	var hidden_x = player_list.position.x + player_list.size.x
	var visible_x = 838.0

	if is_list_visible:
		tween.tween_property(player_list, "position:x", hidden_x, 0.3)
		tween.tween_callback(func(): player_list.visible = false)
	else:
		player_list.position.x = hidden_x
		player_list.visible = true
		tween.tween_property(player_list, "position:x", visible_x, 0.3)

	is_list_visible = not is_list_visible

func _process(_delta: float) -> void:
	var human_players = $"../..".get_players().filter(
		func(p): return not p.is_in_group("AI")
	)

	var container = $SpectatorStuff/PlayerList/ScrollContainer/VBoxContainer

	for plr in human_players:
		var entry

		if container.has_node(NodePath(plr.name)):
			entry = container.get_node(NodePath(plr.name))
		else:
			entry = player_label.instantiate()
			entry.name = plr.name
			entry.text = plr.name
			container.add_child(entry)
			entry.get_node("Button").pressed.connect(
				player_lists_button_pressed.bind(plr.name)
			)

		entry.get_node("Malice").text = str(plr.malice)

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

func _on_settings_pressed() -> void:
	$SpectatorStuff/Settings_Panel.visible = not $SpectatorStuff/Settings_Panel.visible

func _on_enable_hitbox_toggled(toggled_on: bool) -> void:
	PlayerSettings.show_hitboxes = toggled_on
	PlayerSettings.save()


func _on_enable_killsound_toggled(toggled_on: bool) -> void:
	PlayerSettings.enabled_killsound = toggled_on
	PlayerSettings.save()


func _on_hitsounds_enable_toggled(toggled_on: bool) -> void:
	PlayerSettings.enabled_hitsound = toggled_on
	PlayerSettings.save()

func start_listening(action: String, btn: Button) -> void:
	if listening_button != null:
		listening_button.text = PlayerSettings.get_keybind_label(listening_action)
	listening_action = action
	listening_button = btn
	listening_just_started = true
	btn.text = "..."

func _unhandled_input(event: InputEvent) -> void:
	if listening_action == "":
		return
	
	var label: String = ""
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			label = PlayerSettings.get_keybind_label(listening_action)
		else:
			label = OS.get_keycode_string(event.keycode)
			PlayerSettings.set_keybind(listening_action, label)
	elif event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:   label = "LMB"
			MOUSE_BUTTON_RIGHT:  label = "RMB"
			MOUSE_BUTTON_MIDDLE: label = "MMB"
			MOUSE_BUTTON_WHEEL_UP:   label = "WheelUp"
			MOUSE_BUTTON_WHEEL_DOWN: label = "WheelDown"
			_: label = "Mouse%d" % event.button_index
		PlayerSettings.set_keybind(listening_action, label)
	else:
		return
	
	listening_button.text = label
	listening_action = ""
	listening_button = null
	get_viewport().set_input_as_handled()

func _on_slash_keybind_pressed() -> void:
	start_listening("Attack", $SpectatorStuff/Settings_Panel/ScrollContainer/VBoxContainer/Slash/SlashKeybind)

func _on_ability_1_keybind_pressed() -> void:
	start_listening("Ability1", $SpectatorStuff/Settings_Panel/ScrollContainer/VBoxContainer/Ability1/Ability1Keybind)

func _on_shop_button_pressed() -> void:
	$SpectatorStuff/Shop.visible = not $SpectatorStuff/Shop.visible

func _on_inventory_button_pressed() -> void:
	$SpectatorStuff/Inventory.visible = not $SpectatorStuff/Inventory.visible
