extends Control

var player_label = preload("res://UI/stuff/player_list_players.tscn")
var selected_player = ""

@onready var player_profile = $SpectatorStuff/PlayerProfile
@onready var player_list = $SpectatorStuff/PlayerList
@onready var player = $".."
@onready var audio_player = $"../Hitsound"
@onready var killsound_player = $"../Killsound"
@onready var file_dialog = $"../../FileDialog"

@onready var settings: Node = $"../PlayerSettings"

const NOTIFICATION_SCENE := preload("res://UI/achievement_notification.tscn")
const STACK_SPACING = 8
const NOTIFICATION_HEIGHT = 80

var listening_action: String = ""
var listening_button: Button = null
var is_list_visible = true
var listening_just_started: bool = false
var tween: Tween
var file_dialog_mode: String = ""
var _active_notifications: Array = []

func _ready() -> void:
	file_dialog.filters = ["*.wav,*.ogg,*.mp3 ; Audio Files"]
	file_dialog.file_selected.connect(_on_file_selected)
	settings._load()
	set_process_unhandled_input(false)
	player_list.visible = true
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	
	var saved_vol = settings.music_volume
	$SpectatorStuff/Settings_Panel/ScrollContainer/VBoxContainer/MusicVolume/Music_Slider.value = saved_vol
	$SpectatorStuff/Settings_Panel/ScrollContainer/VBoxContainer/MusicVolume/Music_LineEdit.text = str(int(saved_vol))
	AudioServer.set_bus_volume_db(1, linear_to_db(saved_vol / 100.0))

	$SpectatorStuff/Settings_Panel/ScrollContainer/VBoxContainer/Hitboxes/Enable_Hitbox.button_pressed       = settings.show_hitboxes
	$SpectatorStuff/Settings_Panel/ScrollContainer/VBoxContainer/Killsound/EnableKillsound.button_pressed    = settings.enabled_killsound
	$SpectatorStuff/Settings_Panel/ScrollContainer/VBoxContainer/Hitsounds/HitsoundsEnable.button_pressed    = settings.enabled_hitsound
	$SpectatorStuff/Settings_Panel/ScrollContainer/VBoxContainer/Stamina/Center_Stam.button_pressed          = settings.center_stamina

	_restore_hitsound()
	_restore_killsound()

	$SpectatorStuff/Settings_Panel/ScrollContainer/VBoxContainer/Slash/SlashKeybind.text    = settings.get_keybind_label("Attack")
	$SpectatorStuff/Settings_Panel/ScrollContainer/VBoxContainer/Ability1/Ability1Keybind.text = settings.get_keybind_label("Ability1")
	
	$Both/Ping_Label.visible = settings.show_ping
	$Both/FPS_Label.visible = settings.show_fps
	
	$SpectatorStuff/Settings_Panel/ScrollContainer/VBoxContainer/Show_FPS/ShowFPS.button_pressed = settings.show_fps
	$SpectatorStuff/Settings_Panel/ScrollContainer/VBoxContainer/Show_Ping/ShowPing.button_pressed = settings.show_ping

	AchievementData.achievement_unlocked.connect(_on_achievement_unlocked)
		
	await get_tree().process_frame
	_update_owner_ui()

func _update_owner_ui() -> void:
	$SpectatorStuff/Code.visible = (
		multiplayer.get_unique_id() == ServerSettings.server_owner_id
	)
	
	if not Admins.admins.has(player.player_name):
		$Both/ServerOwnerButton.visible = true

	if LobbyManager.lobby_code != "":
		$SpectatorStuff/Code.text = LobbyManager.lobby_code

func _on_achievement_unlocked(achievement) -> void:
	if _active_notifications.size() >= 3:
		return
	var notif = NOTIFICATION_SCENE.instantiate()
	add_child(notif)
	var slot := _active_notifications.size()
	notif.position.y = 16 + slot * (NOTIFICATION_HEIGHT + STACK_SPACING)
	_active_notifications.append(notif)
	notif.show_achievement(achievement)
	get_tree().create_timer(0.4 + 3.0 + 0.4 + 0.1).timeout.connect(func():
		_active_notifications.erase(notif)
	)

func _restore_hitsound() -> void:
	var path = settings.hitsound
	if path == "":
		return
	audio_player = get_node_or_null("../Hitsound")
	if audio_player == null:
		return
	var stream = settings.load_audio_from_path(path)
	if stream:
		audio_player.stream = stream
		settings.hitsound_stream = stream

func _restore_killsound() -> void:
	var path = settings.killsound
	if path == "":
		return
	killsound_player = get_node_or_null("../Killsound")
	if killsound_player == null:
		return
	var stream = settings.load_audio_from_path(path)
	if stream:
		killsound_player.stream = stream
		settings.killsound_stream = stream

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("PlayerList"):
		toggle_player_list()

	if listening_action == "":
		return

	var label: String = ""

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			label = settings.get_keybind_label(listening_action)
		else:
			label = OS.get_keycode_string(event.keycode)
			settings.set_keybind(listening_action, label)
	elif event is InputEventMouseButton and event.pressed:
		if not listening_just_started:
			match event.button_index:
				MOUSE_BUTTON_LEFT:       label = "LMB"
				MOUSE_BUTTON_RIGHT:      label = "RMB"
				MOUSE_BUTTON_MIDDLE:     label = "MMB"
				MOUSE_BUTTON_WHEEL_UP:   label = "WheelUp"
				MOUSE_BUTTON_WHEEL_DOWN: label = "WheelDown"
				_: label = "Mouse%d" % event.button_index
			settings.set_keybind(listening_action, label)
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

	var current_names = human_players.map(func(p): return p.name)
	
	var ability_slots = []
	for child in $"../player_ui/GameStuff/AbilitiesStuff".get_children():
		if child.name.begins_with("Ability"):
			ability_slots.append(child)

	var ability_map = []
	if player.is_Killer:
		ability_map = [
			player.equipped_attack,
			player.equipped_ability1,
			player.equipped_ability2,
			player.equipped_ability3,
			player.equipped_ability4,
		]
	else:
		ability_map = [
			player.equipped_ability1,
			player.equipped_ability2,
			player.equipped_ability3,
			player.equipped_ability4,
		]

	for i in range(ability_slots.size()):
		var slot = ability_slots[i]
		var ab = ability_map[i] if i < ability_map.size() else {}
		var ab_name = ab.get("name", "")
		var cooldown_max = ab.get("cooldown", 0.0)
		var cooldown_cur = player.cooldowns.get(ab_name, 0.0)

		var overlay = slot.get_node_or_null("CooldownOverlay")
		var label = slot.get_node_or_null("CooldownLabel")

		if overlay:
			overlay.visible = cooldown_cur > 0.0
			if cooldown_max > 0.0:
				overlay.material.set_shader_parameter("progress", cooldown_cur / cooldown_max)

		if label:
			if cooldown_cur > 0.0:
				label.visible = true
				label.text = str(ceil(int(cooldown_cur)))
			else:
				label.visible = false

	for child in container.get_children():
		if child.name not in current_names:
			child.queue_free()

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
		
	if Admins.admins.has(player.name):
		$Both/Admin.visible = true

func _on_spin_box_value_changed(value: float) -> void:
	for plr in $"../..".get_players():
		if plr.name == $Both/Admin_Panel/ScrollContainer/VBoxContainer/GiveCoins/LineEdit.text:
			plr.give_coins(value)

func _on_give_killer_pressed() -> void:
	$click.play()
	for plr in $"../..".get_players():
		if plr.name == $Both/Admin_Panel/ScrollContainer/VBoxContainer/MakeKiller/LineEdit.text:
			plr.apply_character_stats()
			plr.apply_skin(plr.equipped_skin_id)
			plr._refresh_abilities()
			plr.is_Killer = true

func _on_kick_player_pressed() -> void:
	$click.play()
	var target_name = $Both/Admin_Panel/ScrollContainer/VBoxContainer/KickPlayer/LineEdit.text
	for plr in $"../..".get_players():
		if plr.get("is_npc"):
			continue
		if plr.player_name == target_name:
			var peer_id = plr.get_multiplayer_authority()
			if peer_id == 1:
				print("Cannot kick the server owner.")
				return
			multiplayer.multiplayer_peer.disconnect_peer(peer_id)
			return

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
	$SpectatorStuff/Shop.visible = false
	$SpectatorStuff/Inventory.visible = false
	$click.play()

func _on_enable_hitbox_toggled(toggled_on: bool) -> void:
	settings.set_show_hitboxes(toggled_on)
	$click.play()

func _on_enable_killsound_toggled(toggled_on: bool) -> void:
	settings.set_enabled_killsound(toggled_on)
	$click.play()

func _on_hitsounds_enable_toggled(toggled_on: bool) -> void:
	settings.set_enabled_hitsound(toggled_on)
	$click.play()

func start_listening(action: String, btn: Button) -> void:
	if listening_button != null:
		listening_button.text = settings.get_keybind_label(listening_action)
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
			label = settings.get_keybind_label(listening_action)
		else:
			label = OS.get_keycode_string(event.keycode)
			settings.set_keybind(listening_action, label)
	elif event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:       label = "LMB"
			MOUSE_BUTTON_RIGHT:      label = "RMB"
			MOUSE_BUTTON_MIDDLE:     label = "MMB"
			MOUSE_BUTTON_WHEEL_UP:   label = "WheelUp"
			MOUSE_BUTTON_WHEEL_DOWN: label = "WheelDown"
			_: label = "Mouse%d" % event.button_index
		settings.set_keybind(listening_action, label)
	else:
		return

	listening_button.text = label
	listening_action = ""
	listening_button = null
	get_viewport().set_input_as_handled()

func _on_file_selected(path: String) -> void:
	var stream = settings.load_audio_from_path(path)
	if not stream:
		print("Failed to load audio from: ", path)
		return

	if file_dialog_mode == "hitsound":
		audio_player = get_node_or_null("../Hitsound")
		if audio_player == null:
			print("Hitsound node not found!")
			return
		audio_player.stream = stream
		settings.hitsound_stream = stream
		settings.set_hitsound(path)

	elif file_dialog_mode == "killsound":
		killsound_player = get_node_or_null("../Killsound")
		if killsound_player == null:
			print("Killsound node not found!")
			return
		killsound_player.stream = stream
		settings.killsound_stream = stream
		settings.set_killsound(path)

	file_dialog_mode = ""

func _on_slash_keybind_pressed() -> void:
	$click.play()
	start_listening("Attack", $SpectatorStuff/Settings_Panel/ScrollContainer/VBoxContainer/Slash/SlashKeybind)

func _on_ability_1_keybind_pressed() -> void:
	$click.play()
	start_listening("Ability1", $SpectatorStuff/Settings_Panel/ScrollContainer/VBoxContainer/Ability1/Ability1Keybind)

func _on_shop_button_pressed() -> void:
	$SpectatorStuff/Shop.visible = not $SpectatorStuff/Shop.visible
	$SpectatorStuff/Inventory.visible = false
	$click.play()

func _on_inventory_button_pressed() -> void:
	$SpectatorStuff/Inventory.visible = not $SpectatorStuff/Inventory.visible
	$SpectatorStuff/Shop.visible = false
	$click.play()

func _on_hitsound_select_pressed() -> void:
	file_dialog_mode = "hitsound"
	file_dialog.popup_centered(Vector2(800, 600))

func _on_killsound_select_pressed() -> void:
	file_dialog_mode = "killsound"
	file_dialog.popup_centered(Vector2(800, 600))

func _on_center_stam_toggled(toggled_on: bool) -> void:
	settings.center_stamina = toggled_on
	settings.save()

func _on_music_slider_value_changed(value: float) -> void:
	var db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(1, db)
	$SpectatorStuff/Settings_Panel/ScrollContainer/VBoxContainer/MusicVolume/Music_LineEdit.text = str(int(value))
	settings.set_music_volume(value)

func _on_music_line_edit_text_changed(new_text: String) -> void:
	var db = linear_to_db(float(new_text) / 100.0)
	AudioServer.set_bus_volume_db(1, db)
	$SpectatorStuff/Settings_Panel/ScrollContainer/VBoxContainer/MusicVolume/Music_Slider.value = float(new_text)
	settings.set_music_volume(float(new_text))

func _on_show_fps_toggled(toggled_on: bool) -> void:
	$Both/FPS_Label.visible = toggled_on
	settings.show_fps = toggled_on
	settings.save()
	$click.play()

func _on_show_ping_toggled(toggled_on: bool) -> void:
	$Both/Ping_Label.visible = toggled_on
	settings.show_ping = toggled_on
	settings.save()
	$click.play()

func _on_spectate_pressed() -> void:
	pass # Replace with function body.

func _on_server_owner_button_pressed() -> void:
	$Both/SO_Panel.visible = not $Both/SO_Panel.visible

func _on_SO_kick_pressed() -> void:
	$click.play()
	var target_name = $Both/SO_Panel/ScrollContainer/VBoxContainer/KickPlayer/LineEdit.text
	for plr in $"../..".get_players():
		if plr.get("is_npc"):
			continue
		if plr.player_name == target_name:
			var peer_id = plr.get_multiplayer_authority()
			if peer_id == 1:
				print("Cannot kick the server owner.")
				return
			multiplayer.multiplayer_peer.disconnect_peer(peer_id)
			return
