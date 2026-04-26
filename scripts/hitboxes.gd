extends Area3D

var hit_flag: Array = []
var hit_killer = false
var damage = 25
var hitsfx = null
var og_plr = null

func _on_body_entered(body: Node3D) -> void:
	if hit_flag.size() > 0:
		return

	if "is_Killer" in body and not body.is_Killer and not hit_killer:
		if body.health > 0:
			hit_flag.append(true)
			var actual_damage = damage
			if body.weakness > 0:
				actual_damage = damage * body.weakness
			if body.blocking:
				actual_damage = actual_damage * 0.5  
				body.grant(15, 25, "Successful block")
				body.current_speed = body.WALK_SPEED
				body.blocking = false
				body.usingAbility = false
				
			body.health -= actual_damage
			_turn_green()
			if og_plr:
				og_plr.get_node("SFX").stream = hitsfx
				og_plr.get_node("SFX").play()
				if PlayerSettings.enabled_hitsound:
					og_plr.get_node("Hitsound").stream = PlayerSettings.hitsound
					og_plr.play_hitsound()
					
				if PlayerSettings.enabled_killsound:
					if body.health >= 0:
						og_plr.get_node("Killsound").stream = PlayerSettings.killsound
						og_plr.play_killsound()

	#killer stunning
	elif "is_Killer" in body and body.is_Killer and hit_killer:
		hit_flag.append(true)
		body.apply_stun(3)
		if og_plr:
			og_plr.grant(45, 35, "Stunned the killer")

		_turn_green()

func _turn_green() -> void:
	var mesh = $CollisionShape3D/MeshInstance3D
	if mesh:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color.GREEN
		mesh.material_override = mat
