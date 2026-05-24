extends Node

var intermission_started = false

var in_round = false
var lms_started = false

var _assigned_spawns: Dictionary = {}

var exit = preload("res://scenes/exit.tscn")

var items = {
	"Medkit" = [
		preload("res://assets/items/medkit.tscn")
	],
	"Cola" = [
		preload("res://assets/items/cola.tscn")
	]
}

var tasks = {
	"Generator" = [
		preload('res://scenes/other/generator.tscn')
	]
}

var maps = [
	preload("res://assets/maps/map_1.tscn")
]

@export var player_scene: PackedScene

var _spawned_players: Dictionary = {}

@export var intermission_time = 30

var sentinel_nerf_active: bool = false

var tasks_to_complete = 5
var tasks_completed = 0

var round_time = 258

func _ready() -> void:
	AchievementData.unlock("gen_001")
	
	$MultiplayerSpawner.spawn_function = _spawn_player
	
	LobbyManager.player_joined.connect(_on_player_joined)
	LobbyManager.player_left.connect(_on_player_left)
	LobbyManager.lobby_ready.connect(_on_lobby_ready)
	LobbyManager.connection_succeeded.connect(_on_connection_succeeded)

func _on_connection_succeeded() -> void:
	pass

func _on_player_left(id: int) -> void:
	if _spawned_players.has(id):
		_spawned_players[id].queue_free()
		_spawned_players.erase(id)

func _on_lobby_ready() -> void:
	if multiplayer.is_server():
		_assigned_spawns.clear()
		var points = get_tree().get_nodes_in_group("spawn_points")
		points.shuffle()
		var i = 0
		for id in LobbyManager.players:
			if i < points.size():
				_assigned_spawns[id] = points[i].global_position
				i += 1
			$MultiplayerSpawner.spawn([id, LobbyManager.players[id]])

func _on_player_joined(id: int, player_name: String) -> void:
	if multiplayer.is_server():
		var points = get_tree().get_nodes_in_group("spawn_points")
		var used = _assigned_spawns.values()
		for point in points:
			if not used.has(point.global_position):
				_assigned_spawns[id] = point.global_position
				break
		$MultiplayerSpawner.spawn([id, player_name])

func _spawn_player(data: Array) -> Node:
	var id: int = data[0]
	var player_name: String = data[1]
	if _spawned_players.has(id):
		return _spawned_players[id]
	var player = player_scene.instantiate()
	player.name = player_name
	player.player_name = player_name
	player.set_multiplayer_authority(id)
	player.add_to_group("players")
	_spawned_players[id] = player
	if id == multiplayer.get_unique_id():
		player.is_ready = true

	if _assigned_spawns.has(id):
		player.position = _assigned_spawns[id]
	
	return player

func get_sentinel_count() -> int:
	var count = 0
	for player in get_players():
		if not player.is_Killer and player.in_round:
			var survivor_data = CharData.get_survivor(player.equipped_survivor)
			if survivor_data.get("class", "") == "sentinel":
				count += 1
	return count

func get_modified_stun_duration(base_duration: float) -> float:
	var sentinels = get_sentinel_count()
	if sentinels >= 3:
		var reduction_stacks = sentinels - 2
		var multiplier = pow(0.8, reduction_stacks)
		return base_duration * multiplier
	return base_duration

func add_hitbox(hitbox, pos, hit_flag: Array, damage, Hittarget: String, size: Vector3, hitsfx, blockable = true, source_player = null) -> Node:
	var instance = hitbox.instantiate()
	instance.hit_flag = hit_flag
	
	if Hittarget == 'survivor':
		instance.hit_killer = false
	else:
		instance.hit_killer = true
		
	instance.damage = damage
	instance.hitsfx = hitsfx
	instance.scale = size
	instance.blockable = blockable
	
	$Hitboxes.add_child(instance)
	instance.global_position = pos
	
	if source_player:
		instance.global_rotation = source_player.global_rotation
		instance.og_plr = source_player
	
	await get_tree().create_timer(0.5).timeout
	
	if source_player and source_player.is_Killer:
		for player in get_players():
			if not player.is_Killer and player.health <= 0:
				if hit_flag.is_empty():
					hit_flag.append(true)
					source_player.on_killed_survivor()
					if has_node("RoundTimer") and $RoundTimer.time_left > 0:
						$RoundTimer.start($RoundTimer.time_left + 30.0)
	
	instance.queue_free()
	return instance

func add_hitbox_instant(hitbox, pos, hit_flag: Array, damage, Hittarget: String, size: Vector3, hitsfx, source_player = null) -> Node:
	var instance = hitbox.instantiate()
	instance.hit_flag = hit_flag
	instance.hit_killer = Hittarget != 'survivor'
	instance.damage = damage
	instance.hitsfx = hitsfx
	instance.scale = size

	$Hitboxes.add_child(instance)
	instance.global_position = pos

	if source_player:
		instance.global_rotation = source_player.global_rotation
		instance.og_plr = source_player

	get_tree().create_timer(0.5).timeout.connect(instance.queue_free)
	return instance

func _process(_delta: float) -> void:
	if get_player_count() > 1 and not intermission_started:
		intermission_started = true
		start_intermission()
	else:
		for player in get_human_players():
			player.get_node("player_ui/SpectatorStuff/Label").text = \
				"Waiting for players"
		
	if $Intermission.time_left > 0:
		for player in get_human_players():
			player.get_node("player_ui/SpectatorStuff/Label").text = \
				"Intermission: " + str(int($Intermission.time_left))
				
	if tasks_completed == tasks_to_complete and $RoundTimer.is_stopped() and in_round and ServerSettings.exits:
		print("exit open")
		
	for plr in get_human_players():
		plr.get_node("player_ui/GameStuff/Objectives/Objective").text = "Completed generators: " + str(tasks_completed) + "/" + str(tasks_to_complete)
	
	if in_round and not lms_started:
		if get_alive_survivor_count() == 1:
			for player in get_players():
				if player.is_Killer and not player.is_npc:
					lms_started = true
					var survivor = get_surviving_player()
					start_lms(player.equipped_killer, survivor)
			
func get_player_count() -> int:
	return get_tree().get_nodes_in_group("players").size()

func get_human_players() -> Array:
	return get_players().filter(func(p): return not p.is_npc)

func get_alive_survivor_count() -> int:
	var count = 0
	for player in get_players():
		if not player.is_Killer and player.in_round and player.health > 0:
			count += 1
	return count

func get_players():
	return get_tree().get_nodes_in_group("players")

func start_intermission() -> void:
	$Intermission.start(intermission_time)

func _on_idle_voiceline_timer_timeout() -> void:
	for player in get_players():
		if player.is_Killer and player.in_round:
			player.get_node("Voiceline_Component").play_idle()

func start_round():
	var highest_malice = -INF
	var most_malicious_player = null
	
	in_round = true

	var random_map = maps[randi() % maps.size()]
	var map_instance = random_map.instantiate()
	$game.add_child(map_instance)
	
	if ServerSettings.exits:
		for exitSpawns in map_instance.get_children():
			if exitSpawns.name.contains("ExitSpawn"):
				var ExitScene = exit.instantiate()
				map_instance.add_child(ExitScene)
				ExitScene.global_position = exitSpawns.global_position
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	for player in get_human_players():
		if not player.is_ready:
			return
		var malice = player.malice if player.malice != null else 0
		if malice > highest_malice:
			highest_malice = malice
			most_malicious_player = player

	_ensure_unique_survivors()

	for player in get_players():
		player.in_round = true
		player.apply_character_stats()
		player._refresh_abilities()
		player._refresh_ability_ui()
		if player.has_node("snake"):
			player.get_node("snake").hide()
			player.get_node("snake").end_game()
		player.current_speed = player.WALK_SPEED

	for player in get_human_players():
		player.get_node('player_ui').get_node('SpectatorStuff').visible = false
		player.get_node('player_ui').get_node('GameStuff').visible = true
		
	for plr_num in get_player_count():
		if plr_num == 1:
			start_outro()
		
	if most_malicious_player != null:
		most_malicious_player.is_Killer = true
		most_malicious_player.get_node("Voiceline_Component").play_intro()

func _ensure_unique_survivors() -> void:
	var used: Array = []
	var class_counts := {
		"sentinel": 0,
		"survivalist": 0,
		"support": 0,
	}
	var class_limits := {
		"sentinel": 3,
		"survivalist": 3,
		"support": 2,
	}

	for player in get_players():
		if player.is_Killer:
			continue

		var chosen = player.equipped_survivor
		var sdata = CharData.get_survivor(chosen)
		var cls = sdata.get("class", "")

		if not used.has(chosen) and (cls == "" or not class_limits.has(cls) or class_counts[cls] < class_limits[cls]):
			used.append(chosen)
			if cls != "" and class_counts.has(cls):
				class_counts[cls] += 1
			continue

		var replacement := ""
		for survivor_id in CharData.survivors.keys():
			if used.has(survivor_id):
				continue
			var candidate_cls = CharData.get_survivor(survivor_id).get("class", "")
			if candidate_cls != "" and class_limits.has(candidate_cls) and class_counts.get(candidate_cls, 0) >= class_limits[candidate_cls]:
				continue
			replacement = survivor_id
			break

		if replacement != "":
			player.equipped_survivor = replacement
			if player.has_method("apply_skin"):
				player.equipped_skin_id = save_data.get_equipped_skin(replacement)
			used.append(replacement)
			var newcls = CharData.get_survivor(replacement).get("class", "")
			if newcls != "" and class_counts.has(newcls):
				class_counts[newcls] += 1
			print("[Round] Assigned unique survivor '%s' to %s" % [replacement, player.player_name])
		else:
			push_warning("No unique survivor available for player: " + str(player.player_name))

func get_lms_duration(killer: String, survivor: String = "") -> float:
	var default_duration = 90.0
	var music_data = {}

	for player in get_players():
		if player.is_Killer and player.equipped_killer == killer:
			music_data = player.active_music
			break

	if music_data.is_empty():
		var killer_data = CharData.get_killer(killer)
		music_data = killer_data.get("music", {})

	if survivor != "":
		for entry in music_data.get("lms_special", []):
			if entry.get("survivor", "") == survivor:
				return entry.get("lms_duration", music_data.get("lms_duration", default_duration))

	return music_data.get("lms_duration", default_duration)

func get_surviving_player() -> String:
	for player in get_players():
		if not player.is_Killer:
			return player.equipped_survivor
	return ""

func start_lms(killer: String, survivor: String = "") -> void:
	var stream_path = get_lms(killer, survivor)
	if stream_path == "" or not ResourceLoader.exists(stream_path):
		push_warning("No LMS music found for killer: " + killer)
		return

	var duration = get_lms_duration(killer, survivor)
	ResourceLoader.load_threaded_request(stream_path)
	_await_lms_load(stream_path, duration)

func start_intro():
	#$Cutscenes/IntroCam.current = true
	pass
	
func start_outro():
	#$Cutscenes/IntroCam.current = true
	pass

func _await_lms_load(stream_path: String, duration: float) -> void:
	while true:
		var status = ResourceLoader.load_threaded_get_status(stream_path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var stream = ResourceLoader.load_threaded_get(stream_path)
			$LMS.stream = stream
			AudioServer.set_bus_volume_db(1, -100)
			$LMS.play()
			print("LMS playing: ", $LMS.playing, " | Duration: ", duration)
			
			$LMSTimer.wait_time = duration
			$LMSTimer.start()
			return
		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			push_warning("Failed to load LMS music: " + stream_path)
			return
		await get_tree().process_frame

func get_lms(killer: String, survivor: String = "") -> String:
	var music_data = {}

	for player in get_players():
		if player.is_Killer and player.equipped_killer == killer:
			music_data = player.active_music
			break

	if music_data.is_empty():
		var killer_data = CharData.get_killer(killer)
		music_data = killer_data.get("music", {})

	if survivor != "":
		for entry in music_data.get("lms_special", []):
			if entry.get("survivor", "") == survivor:
				return entry.get("track", music_data.get("lms", ""))

	return music_data.get("lms", "")

func get_chase_theme(killer: String):
	for player in get_players():
		if player.is_Killer and player.equipped_killer == killer:
			var theme = player.active_music.get("chase", "")
			if theme != "":  
				return theme
	
	var killer_data = CharData.get_killer(killer)
	return killer_data.get("music", {}).get("chase", "")

func _on_intermission_timeout() -> void:
	start_round()
	start_intro()

func _on_round_timer_timeout() -> void:
	in_round = false
	lms_started = false
	$LMS.stop()
	_cleanup_round()

func _cleanup_round() -> void:
	for player in get_players():
		if not player.is_Killer and player.animation_manager != null:
			for killer_player in get_players():
				if killer_player.is_Killer:
					player.animation_manager.unload_kill_animation(killer_player.equipped_killer)
