extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var current_speed = 5.0

var blocking = false

var in_round = false

var hit_flag: Array = []

var hitbox_timer := 0.0
const HITBOX_INTERVAL := 0.5

@export var malice = 0

var active_music = {}

@export var hitboxes: PackedScene

const CHASE_RANGE = 15.0
const CHASE_SCAN_INTERVAL = 0.2

var _in_chase: bool = false
var _chase_scan_timer: float = 0.0
 
@export var is_Killer = true
var equipped_killer = "yixi"
var equipped_survivor = "nyx"
var equipped_skin_id: String = "default"
var _skin_instance: Node3D = null

@export var hitbox_attack = "killer"

var health = 100
var weakness = 0

var stun_time = 4
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
		
	if health <= 0:
		in_round = false

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

func on_killed_survivor() -> void:
	$Voiceline_Component.play_kill()

func _update_chase_music() -> void:
	var survivor_nearby = false

	for player in get_tree().get_nodes_in_group("players"):
		if not is_instance_valid(player):
			continue
		if player == self:
			continue
		if player.is_Killer:
			continue
		var dist = global_position.distance_to(player.global_position)
		if dist <= CHASE_RANGE:
			survivor_nearby = true
			break

	if survivor_nearby and not _in_chase:
		_in_chase = true
		_on_chase_state_changed(true)
	elif not survivor_nearby and _in_chase:
		_in_chase = false
		_on_chase_state_changed(false)

func _on_chase_state_changed(chasing: bool) -> void:
	if chasing:
		if not $Chase_Theme.playing:
			$Chase_Theme.stream = load(active_music.get("chase", ""))
			$Chase_Theme.play()
	else:
		$Chase_Theme.stop()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if is_Killer:
		_chase_scan_timer -= delta
		if _chase_scan_timer <= 0.0:
			_chase_scan_timer = CHASE_SCAN_INTERVAL
			_update_chase_music()
	
	#if is_Killer:
	hitbox_timer += delta
		
	if hitbox_timer >= HITBOX_INTERVAL:
		hitbox_timer = 0.0
			
		hit_flag.clear()
			
		for i in range(5):
			var spawn_pos = global_position + -transform.basis.z * 1.0
			spawn_pos.y -= 0.9
				
			$"..".add_hitbox(
				hitboxes,
				spawn_pos,
				hit_flag,
				25,
				hitbox_attack,
				Vector3(1.0, 1.0, 1.0),
				null,
				self
			)
	
	velocity.x = move_toward(velocity.x, 0, (SPEED - current_speed + SPEED) * delta * 10.0)
	velocity.z = move_toward(velocity.z, 0, (SPEED - current_speed + SPEED) * delta * 10.0)
	
	move_and_slide()
