class_name AbilityComponent

extends Node

@onready var player = $".."

@onready var main = $"../.."

var _dash_active := false

func get_skin_ability_sfx(ability_slot: String) -> AudioStream:
	if ability_slot == "" or not player:
		return null
	
	var char_type = "killer" if player.is_Killer else "survivor"
	var char_id = player.equipped_killer if player.is_Killer else player.equipped_survivor
	var skin_id = player.equipped_skin_id
	var skin_data = CharData.get_skin(char_id, char_type, skin_id)
	var sfx_data = skin_data.get("sfx", {})
	var sfx_entry = sfx_data.get(ability_slot, "")
	
	if sfx_entry is Array:
		var candidates: Array = []
		for path in sfx_entry:
			if path != "" and ResourceLoader.exists(path):
				var stream = load(path)
				if stream:
					candidates.append(stream)
		if candidates.size() > 0:
			return candidates[randi() % candidates.size()]
		return null
	
	if typeof(sfx_entry) == TYPE_STRING and sfx_entry != "" and ResourceLoader.exists(sfx_entry):
		return load(sfx_entry)
	
	return null

func get_skin_ability_sfx_array(ability_slot: String) -> Array:
	if ability_slot == "" or not player:
		return []
	
	var char_type = "killer" if player.is_Killer else "survivor"
	var char_id = player.equipped_killer if player.is_Killer else player.equipped_survivor
	var skin_id = player.equipped_skin_id
	var skin_data = CharData.get_skin(char_id, char_type, skin_id)
	var sfx_data = skin_data.get("sfx", {})
	var sfx_entry = sfx_data.get(ability_slot, "")
	
	if sfx_entry is Array:
		var streams: Array = []
		for path in sfx_entry:
			if path != "" and ResourceLoader.exists(path):
				var stream = load(path)
				if stream:
					streams.append(stream)
		return streams
	
	return []

func _activate_ability(ability_data: Dictionary) -> void:
	var ability = ability_data.get("type", "")
	var wind_up = ability_data.get("wind_up", 0.3)  # Default to 0.3 seconds if not specified
	
	# ==================== SLASHES ==============================
	if ability == "slash":
		var hit_flag: Array = []
		$"../SFX".stream = get_skin_ability_sfx("primary")
		$"../SFX".play()
		await get_tree().create_timer(wind_up).timeout
		for i in range(5):
			var spawn_pos = $"..".global_position + -$"..".transform.basis.z * 1.0
			spawn_pos.y -= 0.9
			$"../..".add_hitbox(
				$"..".hitboxes, spawn_pos, hit_flag, 25, "survivor", Vector3(1.0,1.0,1.0), get_skin_ability_sfx("slash_hit"), $".."
			)
			await get_tree().create_timer(0.05).timeout
			
	# ==============================================================================
			
	# shoot
	elif ability == "gun_shot":
		
		var sfx_array = get_skin_ability_sfx_array("ability1")
			
		$"..".current_speed = 0
				
		await get_tree().create_timer(0.8).timeout

		var hit_flag: Array = []
		var spawn_pos = $"..".global_position
		spawn_pos -= $"..".transform.basis.z * 4.0
		$"../..".add_hitbox(
			$"..".hitboxes, spawn_pos, hit_flag, 25, "killer", Vector3(0.5,0.25,5.558), null, $".."
		)
		$"../SFX".stream = sfx_array[1]
		$"../SFX".play()
		await get_tree().create_timer(0.05).timeout
			
		$"..".current_speed = $"..".WALK_SPEED
		$"..".usingAbility = false
		
	# mouse attack
	elif ability == "mouse_attack":
		var camera = get_viewport().get_camera_3d()
		if not camera:
			return

		var mouse_pos = get_viewport().get_mouse_position()
		var ray_origin = camera.project_ray_origin(mouse_pos)
		var ray_dir = camera.project_ray_normal(mouse_pos)

		var space = $"..".get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(
			ray_origin,
			ray_origin + ray_dir * 100.0
		)
		query.exclude = [$"..".get_rid()]  

		var result = space.intersect_ray(query)

		var target_pos: Vector3
		if result:
			target_pos = result.position
		else:
			target_pos = ray_origin + ray_dir * 50.0
			
		$"..".current_speed = 0
			
		
		await get_tree().create_timer(0.8).timeout

		_launch_mouse_projectile(target_pos)
		
		$"..".current_speed = $"..".WALK_SPEED
		
	elif ability == "void_dash":
		if _dash_active:
			return

		var dash_speed: float = ability_data.get("speed", 30.0)
		var dash_damage: int = ability_data.get("damage", 40)
		const MAX_DASH_TIME := 3.0
		var elapsed := 0.0

		_dash_active = true
		$"..".current_speed = 0

		var hit_flag: Array = []  

		while Input.is_action_pressed("Ability2") and elapsed < MAX_DASH_TIME:
			var delta = get_physics_process_delta_time()
			elapsed += delta

			var forward = -$"..".transform.basis.z
			forward.y = 0
			forward = forward.normalized()
			
			var spawn_pos = $"..".global_position + -$"..".transform.basis.z * 1.0
			spawn_pos.y -= 0.9

			$"..".velocity.x = forward.x * dash_speed
			$"..".velocity.z = forward.z * dash_speed
			$"..".move_and_slide()
			  
			$"../..".add_hitbox(
				$"..".hitboxes,
				spawn_pos,
				hit_flag,          
				dash_damage,
				"survivor",
				Vector3(1.2, 1.2, 1.2),
				$".."
			)

			await get_tree().physics_frame

		_dash_active = false
		$"..".current_speed = $"..".WALK_SPEED
		$"..".usingAbility = false
		
	elif ability == "sword":
		var hit_flag: Array = []
		$"..".current_speed = $"..".WALK_SPEED / 2
		for i in range(5):
			var spawn_pos = $"..".global_position + -$"..".transform.basis.z * 1.0
			spawn_pos.y -= 0.9
			$"../..".add_hitbox(
				$"..".hitboxes, spawn_pos, hit_flag, 25, "killer", Vector3(1.0,1.0,1.0), $".."
			)
			await get_tree().create_timer(0.05).timeout
			
		$"..".current_speed = $"..".WALK_SPEED
			
	elif ability == "chicken":
		if $"..".health < $"..".maxhealth:
			$"..".health = min($"..".health + 50, $"..".maxhealth)
			print("used chicken")
		else:
			print("Full HP")
		$"..".usingAbility = false 
		
	elif ability == "behead":
		var hit_flag: Array = []
		
		var forward = -$"..".transform.basis.z
		forward.y = 0
		forward = forward.normalized()
		var dash_speed := 18.0
		var dash_duration := 0.15
		var elapsed := 0.0
		
		$"../SFX".stream = get_skin_ability_sfx("ability1")
		$"../SFX".play()
		
		await get_tree().create_timer(0.3).timeout
		
		while elapsed < dash_duration:
			var delta = get_physics_process_delta_time()
			elapsed += delta
			$"..".velocity.x = forward.x * dash_speed
			$"..".velocity.z = forward.z * dash_speed
			$"..".move_and_slide()
			await get_tree().physics_frame
		
		for i in range(5):
			var spawn_pos = $"..".global_position + -$"..".transform.basis.z * 1.0
			spawn_pos.y -= 0.9
			$"../..".add_hitbox(
				$"..".hitboxes, spawn_pos, hit_flag, 25, "survivor", Vector3(1.0,1.0,1.0), get_skin_ability_sfx("slash_hit"), $".."
			)
			await get_tree().create_timer(0.05).timeout
		
	elif ability == "yixi_grab":
		$"..".current_speed = 0
		
		var grabbed_ref: Array = []
		var hit_flag: Array = []
		
		var spawn_pos = $"..".global_position
		spawn_pos.y -= 0.9
		
		await get_tree().create_timer(0.3).timeout
		
		var instance = $"..".hitboxes.instantiate()
		instance.hit_flag = hit_flag
		instance.hit_killer = false
		instance.damage = 10
		instance.hitsfx = get_skin_ability_sfx("slash_hit")
		instance.scale = Vector3(2.0, 1.0, 2.0)
		instance.og_plr = $".."
		
		instance.body_entered.connect(func(body):
			if grabbed_ref.is_empty() and "is_Killer" in body and not body.is_Killer:
				grabbed_ref.append(body)
		)
		
		$"../..".get_node("Hitboxes").add_child(instance)
		instance.global_position = spawn_pos
		instance.global_rotation = $"..".global_rotation
		
		await get_tree().physics_frame
		await get_tree().physics_frame
		await get_tree().physics_frame
		instance.queue_free()
		
		if not grabbed_ref.is_empty():
			var grabbed_player = grabbed_ref[0]
			
			if grabbed_player.health > 0:
				var original_speed = grabbed_player.current_speed
				grabbed_player.current_speed = 0
				
				$"..".grant(25, 35, 0, "Hit the grab")
				
				for i in range(6):
					if not is_instance_valid(grabbed_player) or grabbed_player.health <= 0:
						break
					var tick_flag: Array = []
					var tick_pos = grabbed_player.global_position
					tick_pos.y -= 0.9
					$"../..".add_hitbox(
						$"..".hitboxes, tick_pos, tick_flag, 5, "survivor",
						Vector3(1.0, 1.0, 1.0), get_skin_ability_sfx("slash_hit"), $".."
					)
					await get_tree().create_timer(0.3).timeout
				
				if is_instance_valid(grabbed_player):
					grabbed_player.current_speed = original_speed
					var throw_dir = -$"..".transform.basis.z
					throw_dir.y = 0.4
					throw_dir = throw_dir.normalized()
					grabbed_player.velocity = throw_dir * 18.0
					
		
		await get_tree().create_timer(2.5).timeout
		$"..".current_speed = $"..".WALK_SPEED
		$"..".usingAbility = false
	
	elif ability == "mark_killer":
		var plrs = $"../..".get_players()
		for plr in plrs:
			if plr.is_Killer:
				print(str(plr) + " is Killer")
				_highlight_killer(plr)
				
	elif ability == "beartrap":
		#var ability_data = get_killer_ability("ability3", $"..".equipped_killer)
		var trap_damage: int = ability_data.get("damage", 15)
		var trap_limit: int = ability_data.get("limit", 3)

		var active_traps = get_tree().get_nodes_in_group("beartraps").filter(
			func(t): return is_instance_valid(t) and t.owner_player == $".."
		)
		if active_traps.size() >= trap_limit:
			print("Beartrap limit reached (%d/%d)" % [active_traps.size(), trap_limit])
			$"..".usingAbility = false
			return

		var trap_scene = preload("res://scenes/other/bear_trap.tscn")
		var trap = trap_scene.instantiate()
		trap.owner_player = $".."
		trap.damage = trap_damage
		trap.hitboxes_scene = $"..".hitboxes
		main.add_child(trap)

		var place_pos = $"..".global_position
		place_pos.y -= 0.9
		trap.global_position = place_pos

		$"..".usingAbility = false
				
	elif ability == "block":
		$"..".blocking = true
		$"..".current_speed = 0.25
		await get_tree().create_timer(2).timeout
		$"..".current_speed = $"..".WALK_SPEED
		$"..".blocking = false
		$"..".usingAbility = false
		
	elif ability == "punch":
		if $"..".blocks >= 1:
			var hit_flag: Array = []
		
			var forward = -$"..".transform.basis.z
			forward.y = 0
			forward = forward.normalized()
			var dash_speed := 18.0
			var dash_duration := 0.15
			var elapsed := 0.0
			
			$"..".blocks = 0
			
			await get_tree().create_timer(0.3).timeout
			
			while elapsed < dash_duration:
				var delta = get_physics_process_delta_time()
				elapsed += delta
				$"..".velocity.x = forward.x * dash_speed
				$"..".velocity.z = forward.z * dash_speed
				$"..".move_and_slide()
				await get_tree().physics_frame
			
			for i in range(5):
				var spawn_pos = $"..".global_position + -$"..".transform.basis.z * 1.0
				spawn_pos.y -= 0.9
				$"../..".add_hitbox(
					$"..".hitboxes, spawn_pos, hit_flag, 25, "killer", Vector3(1.0,1.0,1.0), get_skin_ability_sfx("punch_hit"), $".."
				)
				await get_tree().create_timer(0.05).timeout
		
	elif ability == "anti_lock":
		#var ability_data = get_ability_survivor("ability3", $"..".equipped_survivor)
		var ability_range: float = ability_data.get("range", 10.0)
		var effect_duration: float = ability_data.get("effect_duration", 3.0)
		
		var plrs = $"../..".get_players()
		var nearest_killer = null
		var nearest_dist = INF
		
		for plr in plrs:
			if plr.is_Killer:
				var dist = $"..".global_position.distance_to(plr.global_position)
				if dist <= ability_range and dist < nearest_dist:
					nearest_dist = dist
					nearest_killer = plr
		
				if nearest_killer != null:
					if "current_target" in nearest_killer:
						nearest_killer.current_target = null
					if "locked_target" in nearest_killer:
						nearest_killer.locked_target = null
					if "target" in nearest_killer:
						nearest_killer.target = null
						
					_highlight_killer(nearest_killer, 1.0)
					
					if "current_speed" in nearest_killer and "WALK_SPEED" in nearest_killer:
						var original_speed = nearest_killer.WALK_SPEED
						nearest_killer.current_speed = nearest_killer.current_speed * 0.5
						await get_tree().create_timer(effect_duration).timeout
						if is_instance_valid(nearest_killer):
							nearest_killer.current_speed = original_speed
					else:
						await get_tree().create_timer(effect_duration).timeout

					print("anti_lock applied to: ", nearest_killer)
				else:
					print("no killer in range for anti_lock")

				$"..".usingAbility = false
				
	elif ability == "ally_link":
		#var ability_data = get_ability_survivor("ability4", $"..".equipped_survivor)
		var duration: float = ability_data.get("duration", 8.0)
		var redirect_ratio: float = ability_data.get("redirect_ratio", 0.35)
		var perfect_window: float = ability_data.get("perfect_release_window", 0.5)
		
		var plrs = $"../..".get_players()
		var nearest_ally = null
		var nearest_dist = INF

		for plr in plrs:
			if plr == $".." or plr.is_Killer:
				continue
			var dist = $"..".global_position.distance_to(plr.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest_ally = plr

		if nearest_ally == null:
			print("no ally found for ally_link")
			$"..".usingAbility = false
			return

		print("Oath Anchor linked to: ", nearest_ally)

		var elapsed := 0.0
		var last_redirected_damage := 0          
		var total_time := duration
		var in_perfect_window := false

		var ally_prev_health: int = nearest_ally.health

		while elapsed < total_time:
			var delta = get_physics_process_delta_time()
			elapsed += delta

			if elapsed >= (total_time - perfect_window):
				in_perfect_window = true

			if is_instance_valid(nearest_ally) and nearest_ally.health < ally_prev_health:
				var raw_hit = ally_prev_health - nearest_ally.health
				var redirected = int(raw_hit * redirect_ratio)

				nearest_ally.health = min(nearest_ally.health + redirected, nearest_ally.maxhealth)

				var nyx_damage = redirected
				if $"..".weakness > 0:
					nyx_damage = int(redirected * $"..".weakness)
				$"..".health -= nyx_damage

				last_redirected_damage = redirected
				print("Oath Anchor redirected %d damage from ally to Nyx" % redirected)

			ally_prev_health = nearest_ally.health if is_instance_valid(nearest_ally) else ally_prev_health

			if $"..".health <= 0 or not is_instance_valid(nearest_ally):
				break

			await get_tree().physics_frame

		if in_perfect_window and last_redirected_damage > 0:
			$"..".health = min($"..".health + last_redirected_damage, $"..".maxhealth)
			print("Perfect release! Negated last redirected instance: +%d HP" % last_redirected_damage)

		$"..".usingAbility = false
		
	elif ability == "bonespike":
		#var ability_data = get_killer_ability("ability1", $"..".equipped_killer)
		var spike_damage: int = ability_data.get("damage", 40)
		var effect_duration: float = ability_data.get("effect_duration", 2.0)

		await get_tree().create_timer(0.2).timeout

		var forward = -$"..".transform.basis.z
		forward.y = 0
		forward = forward.normalized()

		var start_pos = $"..".global_position + forward * 1.2

		var projectile = preload("res://assets/models/slash.tscn").instantiate()
		main.add_child(projectile)
		projectile.global_position = start_pos
		projectile.look_at(start_pos + forward, Vector3.UP)
		projectile.rotate_object_local(Vector3.UP, deg_to_rad(-90))

		var speed := 22.0
		var max_distance := 30.0
		var projectile_pos = start_pos
		var travelled := 0.0
		var hit_flag: Array = []
		var already_hit := false

		while travelled < max_distance:
			var step = speed * get_physics_process_delta_time()
			var next_pos = projectile_pos + forward * step

			var space = $"..".get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.create(projectile_pos, next_pos)
			query.exclude = [$"..".get_rid()]
			var result = space.intersect_ray(query)

			if result and travelled > 0.5:
				var body = result.collider
				if not already_hit and "is_Killer" in body and not body.is_Killer and body.health > 0:
					already_hit = true
					body.take_damage(spike_damage)

					var effect_comp = body.get_node_or_null("EffectComponent")
					if effect_comp:
						effect_comp.activate_effect("root", 1, effect_duration)
					else:
						var original_speed = body.current_speed
						body.current_speed = 0
						if is_instance_valid(body):
							body.current_speed = original_speed

					$"../..".add_hitbox(
						$"..".hitboxes,
						result.position,
						hit_flag,
						0,
						"survivor",
						Vector3(1.0, 1.0, 1.0),
						null,
						$".."
					)
					
					player.grant(25, 15, 0,"Hit Survivor with Bonespike")

				if is_instance_valid(projectile):
					projectile.queue_free()
				break

			projectile_pos = next_pos
			if is_instance_valid(projectile):
				projectile.global_position = projectile_pos

			travelled += step
			var travel_flag: Array = []
			main.add_hitbox(
				player.hitboxes, projectile_pos, travel_flag, spike_damage, "survivor",
				Vector3(2, 0.6, 0.6), null, player
			)
			
			await get_tree().physics_frame

		$"..".usingAbility = false

	elif ability == "adrenaline":
		var effect_comp = $"..".get_node_or_null("EffectComponent")
		if effect_comp:
			effect_comp.activate_effect("speed_boost", 2, 5.0)
		$"..".usingAbility = false
	
	elif ability == "entanglement":
		#var ability_data = get_killer_ability("ability2", $"..".equipped_killer)
		var spike_damage: int = ability_data.get("damage", 15)
		var effect_duration: float = ability_data.get("effect_duration", 2.0)

		await get_tree().create_timer(0.2).timeout

		var forward = -$"..".transform.basis.z
		forward.y = 0
		forward = forward.normalized()

		var start_pos = $"..".global_position + forward * 1.2

		var projectile = preload("res://assets/models/slash.tscn").instantiate()
		main.add_child(projectile)
		projectile.global_position = start_pos
		projectile.look_at(start_pos + forward, Vector3.UP)
		projectile.rotate_object_local(Vector3.UP, deg_to_rad(-90))

		var speed := 22.0
		var max_distance := 30.0
		var projectile_pos = start_pos
		var travelled := 0.0
		var hit_flag: Array = []
		var already_hit := false

		while travelled < max_distance:
			var step = speed * get_physics_process_delta_time()
			var next_pos = projectile_pos + forward * step

			var space = $"..".get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.create(projectile_pos, next_pos)
			query.exclude = [$"..".get_rid()]
			var result = space.intersect_ray(query)

			if result and travelled > 0.5:
				var body = result.collider
				if not already_hit and "is_Killer" in body and not body.is_Killer and body.health > 0:
					already_hit = true
					body.take_damage(spike_damage)

					var effect_comp = body.get_node_or_null("EffectComponent")
					if effect_comp:
						effect_comp.activate_effect("drain", 1, effect_duration)
					else:
						var original_speed = body.current_speed
						body.current_speed = 0
						if is_instance_valid(body):
							body.current_speed = original_speed

					$"../..".add_hitbox(
						$"..".hitboxes,
						result.position,
						hit_flag,
						0,
						"survivor",
						Vector3(1.0, 1.0, 1.0),
						null,
						$".."
					)
					
					player.grant(15, 15, 0,"Hit Survivor with Cursed Chain")

				if is_instance_valid(projectile):
					projectile.queue_free()
				break

			projectile_pos = next_pos
			if is_instance_valid(projectile):
				projectile.global_position = projectile_pos

			travelled += step
			var travel_flag: Array = []
			main.add_hitbox(
				player.hitboxes, projectile_pos, travel_flag, spike_damage, "survivor",
				Vector3(1, 0.3, 0.3), null, player
			)
			
			await get_tree().physics_frame

		$"..".usingAbility = false
		
	elif ability == "reveal":
		var plrs = $"../..".get_players()
		for plr in plrs:
			if not plr.is_Killer:
				_highlight_killer(plr, 5.0)
		$"..".usingAbility = false
		
	else:
		print(ability)
	
func _highlight_killer(killer_node: Node, duration: float = 3.0) -> void:
	var highlight_mat := StandardMaterial3D.new()
	highlight_mat.albedo_color = Color(1.0, 0.1, 0.1, 1.0)  
	highlight_mat.emission_enabled = true
	highlight_mat.emission = Color(1.0, 0.0, 0.0)
	highlight_mat.emission_energy_multiplier = 2.0
	highlight_mat.no_depth_test = true       
	highlight_mat.render_priority = 1        
 
	var meshes: Array[MeshInstance3D] = []
	var original_materials: Array = []
 
	for child in killer_node.find_children("*", "MeshInstance3D", true, false):
		var mesh_inst := child as MeshInstance3D
		meshes.append(mesh_inst)
		
		var surfs: Array = []
		for s in range(mesh_inst.get_surface_override_material_count()):
			surfs.append(mesh_inst.get_surface_override_material(s))
		original_materials.append(surfs)
		
		for s in range(mesh_inst.get_surface_override_material_count()):
			mesh_inst.set_surface_override_material(s, highlight_mat)
		
		if mesh_inst.get_surface_override_material_count() == 0:
			mesh_inst.material_override = highlight_mat
 
	await get_tree().create_timer(duration).timeout
 
	for idx in range(meshes.size()):
		if not is_instance_valid(meshes[idx]):
			continue
		var mesh_inst := meshes[idx]
		var surfs: Array = original_materials[idx]
		for s in range(surfs.size()):
			mesh_inst.set_surface_override_material(s, surfs[s])
		if mesh_inst.get_surface_override_material_count() == 0:
			mesh_inst.material_override = null

func _launch_mouse_projectile(target_pos: Vector3) -> void:
	var start_pos = $"..".global_position
	start_pos.y -= 0.9  

	var direction = (target_pos - start_pos).normalized()
	var speed = 20.0         
	var max_distance = 40.0
	var min_distance = 1.5  
	var projectile_pos = start_pos
	var travelled = 0.0

	while travelled < max_distance:
		var step = speed * get_physics_process_delta_time()
		var next_pos = projectile_pos + direction * step

		var space = $"..".get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(projectile_pos, next_pos)
		query.exclude = [$"..".get_rid()]
		var result = space.intersect_ray(query)

		if result and travelled >= min_distance: 
			_spawn_explosion(result.position)
			return

		projectile_pos = next_pos
		travelled += step
		await get_tree().physics_frame

	_spawn_explosion(projectile_pos)

func _spawn_explosion(pos: Vector3) -> void:
	var hit_flag: Array = []
	$"../..".add_hitbox(
		$"..".hitboxes,
		pos,
		hit_flag,
		35,         
		"survivor",
		Vector3(3.0, 3.0, 3.0),  
		$".."
	)

func has_ability(ability_slot: String, char_id: String) -> bool:
	var char_data = CharData.get_killer(char_id) if player.is_Killer else CharData.get_survivor(char_id)
	var abilities: Array = char_data.get("abilities", [])
	for ab in abilities:
		if ab.get("id") == ability_slot:
			return true
	return false

func get_ability_survivor(ability_slot: String, survivor: String) -> Dictionary:
	var survivor_data = CharData.get_survivor(survivor)
	var abilities: Array = survivor_data.get("abilities", [])
	for ab in abilities:
		if ab.get("id") == ability_slot:
			return ab
	push_warning("[AbilityComponent] Ability slot '%s' not found for survivor '%s'" % [ability_slot, survivor])
	return {}

func get_killer_ability(ability_slot: String, killer: String):
	var killer_data = CharData.get_killer(killer)
	var abilities: Array = killer_data.get("abilities", [])
	for ab in abilities:
		if ab.get("id") == ability_slot:
			return ab
	push_warning("[AbilityComponent] Ability slot '%s' not found for killer '%s'" % [ability_slot, killer])
	return {}
