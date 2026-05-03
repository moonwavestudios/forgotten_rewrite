class_name EffectComponent
extends Node

@onready var player = $".."

var burn_timer: Timer = null

func activate_effect(effect: String, level: int) -> void:
	if effect == "invisibility":
		var mesh_instance = player.get_node('CollisionShape3D/MeshInstance3D')
		var material = mesh_instance.get_active_material(0)

		if material:
			var unique_mat = material.duplicate()
			unique_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			unique_mat.albedo_color.a = 0.5 if level == 1 else 0.75
			mesh_instance.set_surface_override_material(0, unique_mat)
		else:
			push_error("No material found on MeshInstance3D!")

	elif effect == "burning":
		deactivate_effect("burning")

		burn_timer = Timer.new()
		burn_timer.wait_time = 1.0
		burn_timer.autostart = true
		burn_timer.timeout.connect(func(): player.health -= level)
		add_child(burn_timer)

	else:
		print(effect)

func deactivate_effect(effect: String) -> void:
	if effect == "invisibility":
		var mesh_instance = player.get_node('CollisionShape3D/MeshInstance3D')
		var material = mesh_instance.get_active_material(0)

		if material:
			var unique_mat = material.duplicate()
			unique_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			unique_mat.albedo_color.a = 1.0
			mesh_instance.set_surface_override_material(0, unique_mat)
		else:
			push_error("No material found on MeshInstance3D!")

	elif effect == "burning":
		if burn_timer != null:
			burn_timer.stop()
			burn_timer.queue_free()
			burn_timer = null
