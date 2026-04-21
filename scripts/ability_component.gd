class_name AbilityComponent

extends Node

@onready var player = $".."

var coin_flip_sfx = preload("res://assets/sfx/coin_flip.mp3")
var shotSFX = preload("res://assets/sfx/shot.mp3")
var nothingSFX = preload("res://assets/sfx/do_nothing.mp3")
var explodeSFX = preload("res://assets/sfx/test.ogg")
var gunDestroyed = false

var slash_sfx = preload("res://assets/sfx/Slash_swing.ogg")
var envy_sfx = preload("res://assets/sfx/Noli_stab.mp3")

var slash_hit = preload("res://assets/sfx/Yixi_Hit.mp3")
var envy_hit = preload("res://assets/sfx/envy_hit.ogg")

var nyx_stab = preload("res://assets/sfx/Dagger_Success.mp3")

var _dash_active := false

func _activate_ability(ability: String) -> void:
	# ==================== SLASHES ==============================
	if ability == "slash":
		var hit_flag: Array = []
		$"../SFX".stream = slash_sfx
		$"../SFX".play()
		await get_tree().create_timer(0.3).timeout
		for i in range(5):
			var spawn_pos = $"..".global_position + -$"..".transform.basis.z * 1.0
			spawn_pos.y -= 0.9
			$"../..".add_hitbox(
				$"..".hitboxes, spawn_pos, hit_flag, 25, "survivor", Vector3(1.0,1.0,1.0), slash_hit, $".."
			)
			await get_tree().create_timer(0.05).timeout
			
	elif ability == "envy_slash":
		var hit_flag: Array = []
		$"../SFX".stream = envy_sfx
		$"../SFX".play()
		await get_tree().create_timer(0.3).timeout
		for i in range(5):
			var spawn_pos = $"..".global_position + -$"..".transform.basis.z * 1.0
			spawn_pos.y -= 0.9
			$"../..".add_hitbox(
				$"..".hitboxes, spawn_pos, hit_flag, 25, "survivor", Vector3(1.0,1.0,1.0), envy_hit, $".."
			)
			await get_tree().create_timer(0.05).timeout
			
	# ==============================================================================
			
	# coin flip
	elif ability == "luck_token":
		await get_tree().create_timer(0.5).timeout
		
		var sfx_player = $"../SFX"
		sfx_player.stream = coin_flip_sfx
		sfx_player.play()
		var random = randf()
		if random < 0.75 and $"..".tokens < 3:
			$"..".tokens += 1
		elif random > 0.75:
			$"..".weakness += 1
			
	# shoot
	elif ability == "gun_shot":
		if $"..".tokens > 0 and not gunDestroyed:
			var tokens_used = $"..".tokens
			$"..".tokens = 0
			
			var random = randf()
			var shoot_chance: float
			var explode_chance: float
			
			$"..".current_speed = 0
			
			if tokens_used == 1:
				shoot_chance = 0.15
				explode_chance = 0.25  
			elif tokens_used == 2:
				shoot_chance = 0.40
				explode_chance = 0.55  
			else: 
				shoot_chance = 0.70
				explode_chance = 0.78  
				
			
			await get_tree().create_timer(0.8).timeout
			
			if random < shoot_chance:
				var hit_flag: Array = []
				var spawn_pos = $"..".global_position + $"..".transform.basis.y * 1.0
				spawn_pos -= $"..".transform.basis.z * 4.0
				spawn_pos.y -= 0.9
				$"../..".add_hitbox(
					$"..".hitboxes, spawn_pos, hit_flag, 25 * tokens_used, "killer", Vector3(0.5,0.25,5.558), $".."
				)
				$"../SFX".stream = shotSFX
				$"../SFX".play()
				await get_tree().create_timer(0.05).timeout
			elif random < explode_chance:
				gunDestroyed = true
				var hit_flag: Array = []
				var spawn_pos = $"..".global_position + -$"..".transform.basis.z * 1.0
				spawn_pos.y -= 0.9
				$"../..".add_hitbox(
					$"..".hitboxes, spawn_pos, hit_flag, 15 * tokens_used, "killer", Vector3(1.0,1.0,1.0), $".."
				)
				if $"..".weakness < 1:
					$"..".health -= 25 
				else:
					$"..".health -= 25 * $"..".weakness
				$"../SFX".stream = explodeSFX
				$"../SFX".play()
				await get_tree().create_timer(0.05).timeout
			else:
				$"../SFX".stream = nothingSFX
				$"../SFX".play()
		else:
			print("not enough tokens or gun is broken")
			
		$"..".current_speed = $"..".WALK_SPEED
		$"..".usingAbility = false
			
	#reroll
	elif ability == "health_gamble":
		if $"..".tokens > 0:
			var ability_data = get_ability_survivor("ability3", $"..".equipped_survivor)
			var min_health = ability_data.get("min_health", 60)
			var max_health = ability_data.get("max_health", 130)
			
			if player.health == player.maxhealth:
				player.maxhealth = randi_range(min_health, max_health)
				player.health = player.maxhealth
				print(str(player.health))
			else:
				player.maxhealth = randi_range(min_health, max_health)
		$"..".usingAbility = false
	
	# hat fix
	elif ability == "reset" and player.tokens == 3:
		gunDestroyed = false
		player.weakness = 0
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

		var ability_data = get_killer_ability("ability2", $"..".equipped_killer)
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
		
		$"../SFX".stream = slash_sfx
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
				$"..".hitboxes, spawn_pos, hit_flag, 25, "survivor", Vector3(1.0,1.0,1.0), slash_hit, $".."
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
		instance.hitsfx = slash_hit
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
				
				$"..".grant(25, 35, "Hit the grab")
				
				for i in range(6):
					if not is_instance_valid(grabbed_player) or grabbed_player.health <= 0:
						break
					var tick_flag: Array = []
					var tick_pos = grabbed_player.global_position
					tick_pos.y -= 0.9
					$"../..".add_hitbox(
						$"..".hitboxes, tick_pos, tick_flag, 5, "survivor",
						Vector3(1.0, 1.0, 1.0), slash_hit, $".."
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
					$"..".hitboxes, spawn_pos, hit_flag, 25, "killer", Vector3(1.0,1.0,1.0), slash_hit, $".."
				)
				await get_tree().create_timer(0.05).timeout
		
	elif ability == "anti_lock":
		var ability_data = get_ability_survivor("ability3", $"..".equipped_survivor)
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

func has_ability(ability_slot: String, survivor: String) -> bool:
	var survivor_data = CharData.get_survivor(survivor)
	var abilities: Array = survivor_data.get("abilities", [])
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
