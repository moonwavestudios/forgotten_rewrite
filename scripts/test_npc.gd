extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var current_speed = 5.0

var blocking = false

@export var is_Killer = true
var equipped_killer = "yixi"

var health = 100
var weakness = 0
var stunned = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Drain horizontal velocity based on current_speed uwu~
	# When current_speed is 0 (grabbed!), it stops vewy quickly (≧◡≦)
	velocity.x = move_toward(velocity.x, 0, (SPEED - current_speed + SPEED) * delta * 10.0)
	velocity.z = move_toward(velocity.z, 0, (SPEED - current_speed + SPEED) * delta * 10.0)
	
	move_and_slide()
