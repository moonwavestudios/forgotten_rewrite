extends Node

var intermission_started = false

var in_round = true
var lms_started = false

func add_hitbox(hitbox, pos, hit_flag: Array, damage, Hittarget: String, size: Vector3, hitsfx, source_player = null) -> void:
	var instance = hitbox.instantiate()
	instance.hit_flag = hit_flag
	
	if Hittarget == 'survivor':
		instance.hit_killer = false
	else:
		instance.hit_killer = true
		
	instance.damage = damage
	instance.hitsfx = hitsfx
	
	instance.scale = size
	
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
	
	instance.queue_free()
	
func _process(_delta: float) -> void:
	if get_player_count() > 1 and not intermission_started:
		intermission_started = true
		start_intermission()
	else:
		for player in get_players():
			player.get_node("player_ui/SpectatorStuff/Label").text = \
				"Waiting for players"
		
	if $Intermission.time_left > 0:
		for player in get_players():
			player.get_node("player_ui/SpectatorStuff/Label").text = \
				"Intermission: " + str(int($Intermission.time_left))
				
	if in_round and not lms_started:
		if get_player_count() == 2:
			for player in get_players():
				if player.is_Killer:
					lms_started = true
					var survivor = get_surviving_player()
					start_lms(player.equipped_killer, survivor)
			

func get_player_count() -> int:
	return get_tree().get_nodes_in_group("players").size()
	
func get_players():
	return get_tree().get_nodes_in_group("players")

func start_intermission() -> void:
	$Intermission.start(30)

func _on_idle_voiceline_timer_timeout() -> void:
	for player in get_players():
		if player.is_Killer and player.in_round:
			player.get_node("Voiceline_Component").play_idle()

func start_round():
	var highest_malice = -INF
	var most_malicious_player = null
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	for player in get_players():
		if player.malice > highest_malice:
			highest_malice = player.malice
			most_malicious_player = player
		
		player.get_node('player_ui').get_node('SpectatorStuff').visible = false
		player.get_node('player_ui').get_node('GameStuff').visible = true
		player.in_round = true
			
		
	if most_malicious_player != null:
		most_malicious_player.is_Killer = true
		most_malicious_player.get_node("Voiceline_Component").play_intro()
		start_chase(most_malicious_player.equipped_killer, most_malicious_player)
			
func assign_model(_player):
	pass

func start_chase(killer: String, player: Node) -> void:
	var stream_path = get_chase_theme(killer)
	if stream_path == "" or not ResourceLoader.exists(stream_path):
		push_warning("No chase music found for killer: " + killer)
		return
	ResourceLoader.load_threaded_request(stream_path)
	_await_chase_load(stream_path, player)

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
	pass
	## this is gonna be used to start the intro
	
func start_outro():
	pass
	## this is gonna be used to start the outro

func _await_chase_load(stream_path: String, player: Node) -> void:
	while true:
		var status = ResourceLoader.load_threaded_get_status(stream_path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var stream = ResourceLoader.load_threaded_get(stream_path)
			player.get_node('Chase_Theme').stream = stream 
			player.get_node('Chase_Theme').play()
			return
		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			push_warning("Failed to load chase music: " + stream_path)
			return
		await get_tree().process_frame

func _await_lms_load(stream_path: String, duration: float) -> void:
	while true:
		var status = ResourceLoader.load_threaded_get_status(stream_path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var stream = ResourceLoader.load_threaded_get(stream_path)
			$LMS.stream = stream
			AudioServer.set_bus_volume_db(1, 0)
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
