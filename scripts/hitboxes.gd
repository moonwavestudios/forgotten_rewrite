extends Area3D

var hit_flag: Array = []
var hit_killer = false
var damage = 25
var hitsfx = null
var blockable = true
var og_plr = null
var has_hit := false

signal on_hit(body: Node3D)

static var _green_mat: StandardMaterial3D = null

func _get_settings() -> Node:
	return og_plr.get_node("PlayerSettings")

func init(source_player: Node) -> void:
	og_plr = source_player
	_apply_hitbox_visibility()

func _apply_hitbox_visibility() -> void:
	var mesh = $CollisionShape3D/MeshInstance3D
	if mesh and og_plr:
		var is_local = og_plr.is_multiplayer_authority()
		var is_npc = og_plr.get("is_npc") == true
		mesh.visible = (is_local or (is_npc and multiplayer.is_server())) and _get_settings().show_hitboxes

func _ready() -> void:
	if not _green_mat:
		_green_mat = StandardMaterial3D.new()
		_green_mat.albedo_color = Color.GREEN

func _on_body_entered(body: Node3D) -> void:
	if hit_flag.size() > 0:
		return

	if body.is_in_group("pallets"):
		hit_flag.append(true)
		body.take_damage(damage)
		_turn_green()
		return

	if "is_Killer" in body and not body.is_Killer and not hit_killer and body.in_round:
		if body.health > 0:
			hit_flag.append(true)
			has_hit = true
			emit_signal("on_hit", body)
			if body.blocking and blockable:
				body.grant(15, 25, 1, "Successful block")
				body.current_speed = body.WALK_SPEED
				body.blocking = false
				body.usingAbility = false
				body.take_damage(int(damage * 0.5))
			else:
				body.take_damage(damage)
			_turn_green()
			if og_plr:
				var s = _get_settings()
				og_plr.get_node("SFX").stream = hitsfx
				og_plr.get_node("SFX").play()
				if s.enabled_hitsound:
					og_plr.get_node("Hitsound").stream = s.hitsound_stream
					og_plr.play_hitsound()
				if s.enabled_killsound:
					if body.health <= 0:
						og_plr.get_node("Killsound").stream = s.killsound_stream
						og_plr.play_killsound()
	elif "is_Killer" in body and body.is_Killer and hit_killer and body.in_round:
		hit_flag.append(true)
		has_hit = true
		emit_signal("on_hit", body)
		body.apply_stun(3)
		if og_plr:
			og_plr.grant(45, 35, 5, "Stunned the killer")
		_turn_green()

func _turn_green() -> void:
	var mesh = $CollisionShape3D/MeshInstance3D
	if mesh:
		mesh.material_override = _green_mat
