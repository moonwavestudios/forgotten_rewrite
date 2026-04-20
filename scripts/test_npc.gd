extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var current_speed = 5.0

var blocking = false

var in_round = false

@export var malice = 0

var active_music = {}

@export var is_Killer = true
var equipped_killer = "yixi"
var equipped_survivor = "nyx"
var equipped_skin_id: String = "default"
var _skin_instance: Node3D = null

var health = 100
var weakness = 0
var stunned = false

func _ready() -> void:
	var char_id = equipped_killer if is_Killer else equipped_survivor
	equipped_skin_id = save_data.get_equipped_skin(char_id)
	apply_skin(equipped_skin_id)

func apply_skin(skin_id: String) -> void:
	var char_type = "killer" if is_Killer else "survivor"
	var char_id = equipped_killer if is_Killer else equipped_survivor

	var skin_data = CharData.get_skin(char_id, char_type, skin_id)
	if skin_data.is_empty():
		push_warning("Skin '%s' not found!" % skin_id)
		return

	if is_instance_valid(_skin_instance):
		_skin_instance.queue_free()

	var skin_scene = load(skin_data.get("model", ""))
	if skin_scene:
		_skin_instance = skin_scene.instantiate()
		add_child(_skin_instance)
		equipped_skin_id = skin_id

	var char_data = CharData.get_killer(char_id) if is_Killer else CharData.get_survivor(char_id)
	var base_music = char_data.get("music", {})
	var skin_music = skin_data.get("music", {})

	active_music = {
		"lms": skin_music.get("lms", base_music.get("lms", "")),
		"chase": skin_music.get("chase", base_music.get("chase", ""))
	}

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Drain horizontal velocity based on current_speed uwu~
	# When current_speed is 0 (grabbed!), it stops vewy quickly (≧◡≦)
	velocity.x = move_toward(velocity.x, 0, (SPEED - current_speed + SPEED) * delta * 10.0)
	velocity.z = move_toward(velocity.z, 0, (SPEED - current_speed + SPEED) * delta * 10.0)
	
	move_and_slide()
