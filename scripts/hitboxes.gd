extends Area3D

var hit_flag: Array = []
var hit_killer = false
var damage = 25
var hitsfx = null
var og_plr = null
var is_back_attack = false

func _on_body_entered(body: Node3D) -> void:
	if hit_flag.size() > 0:
		return
		
	if "isKiller" in body and not body.isKiller and not hit_killer:
		if body.health > 0:
			hit_flag.append(true) 
			if body.weakness > 0:
				if not body.blocking:
					body.health -= damage * body.weakness
			else:
				if not body.blocking:
					body.health -= damage
				
			_turn_green()
			if og_plr:
				og_plr.get_node("SFX").stream = hitsfx
				og_plr.get_node("SFX").play()
	elif "isKiller" in body and body.isKiller and hit_killer:
		if body.health > 0:
			hit_flag.append(true) 
			body.health -= damage
			body.stunned = true
			_turn_green()

func _turn_green() -> void:
	var mesh = $CollisionShape3D/MeshInstance3D
	if mesh:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color.GREEN
		mesh.material_override = mat
