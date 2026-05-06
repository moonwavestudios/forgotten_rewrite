class_name EffectComponent
extends Node

@onready var player = $".."

var burn_timer: Timer = null
var slow_timer: Timer = null
var root_timer: Timer = null
var invisibility_timer: Timer = null
var drain_timer: Timer = null
var drain_tick_timer: Timer = null
var _original_speed: float = 0.0

func activate_effect(effect: String, level: int, duration: float = 1.0) -> void:
	if effect == "invisibility":
		deactivate_effect("invisibility")
		var mesh_instance = player.get_node('CollisionShape3D/MeshInstance3D')
		var material = mesh_instance.get_active_material(0)
		if material:
			var unique_mat = material.duplicate()
			unique_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			unique_mat.albedo_color.a = 0.5 if level == 1 else 0.75
			mesh_instance.set_surface_override_material(0, unique_mat)
		else:
			push_error("No material found on MeshInstance3D!")
			return
		invisibility_timer = Timer.new()
		invisibility_timer.wait_time = duration
		invisibility_timer.one_shot = true
		invisibility_timer.autostart = true
		invisibility_timer.timeout.connect(func(): deactivate_effect("invisibility"))
		add_child(invisibility_timer)
		
	elif effect == "burning":
		deactivate_effect("burning")
		burn_timer = Timer.new()
		burn_timer.wait_time = duration
		burn_timer.autostart = true
		burn_timer.timeout.connect(func(): player.health -= level)
		add_child(burn_timer)
		
	elif effect == "drain":
		deactivate_effect("drain")
		
		_original_speed = player.current_speed
		player.current_speed = player.current_speed * 0.7
		
		drain_tick_timer = Timer.new()
		drain_tick_timer.wait_time = 1.0
		drain_tick_timer.one_shot = false
		drain_tick_timer.autostart = true
		drain_tick_timer.timeout.connect(func(): player.health -= 10)
		add_child(drain_tick_timer)
		
		drain_timer = Timer.new()
		drain_timer.wait_time = 4.0
		drain_timer.one_shot = true
		drain_timer.autostart = true
		drain_timer.timeout.connect(func(): deactivate_effect("drain"))
		add_child(drain_timer)
		
	elif effect == "slow":
		deactivate_effect("slow")
		_original_speed = player.current_speed
		var slow_factor: float = 1.0 / float(level)
		player.current_speed = max(player.current_speed * slow_factor, 0.5)
		slow_timer = Timer.new()
		slow_timer.wait_time = duration
		slow_timer.one_shot = true
		slow_timer.autostart = true
		slow_timer.timeout.connect(func(): deactivate_effect("slow"))
		add_child(slow_timer)
		
	elif effect == "root":
		deactivate_effect("slow")
		_original_speed = player.current_speed
		player.current_speed = 0
		root_timer = Timer.new()
		root_timer.wait_time = duration
		root_timer.one_shot = true
		root_timer.autostart = true
		root_timer.timeout.connect(func(): deactivate_effect("slow"))
		add_child(root_timer)
		
	else:
		print(effect)

func deactivate_effect(effect: String) -> void:
	if effect == "invisibility":
		if invisibility_timer != null:
			invisibility_timer.stop()
			invisibility_timer.queue_free()
			invisibility_timer = null
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
			
	elif effect == "drain":
		if drain_tick_timer != null:
			drain_tick_timer.stop()
			drain_tick_timer.queue_free()
			drain_tick_timer = null
		if drain_timer != null:
			drain_timer.stop()
			drain_timer.queue_free()
			drain_timer = null
		if _original_speed > 0.0:
			player.current_speed = _original_speed
			_original_speed = 0.0
			
	elif effect == "slow":
		if slow_timer != null:
			slow_timer.stop()
			slow_timer.queue_free()
			slow_timer = null
		if _original_speed > 0.0:
			player.current_speed = _original_speed
			_original_speed = 0.0
			
	elif effect == "root":
		if root_timer != null:
			root_timer.stop()
			root_timer.queue_free()
			root_timer = null
		if _original_speed > 0.0:
			player.current_speed = _original_speed
			_original_speed = 0.0
