extends CharacterBody3D

const SPEED = 5.0
var WALK_SPEED = 5.0
const JUMP_VELOCITY = 4.5
var current_speed = 5.0

var equipped_emotes: Array = []

var coins = 0

var xp = 0

var blocking = false

var in_round = false

@onready var main = $".."

var stun_resistant: bool = false
var stun_resistance_time: float = 0.0

var hit_flag: Array = []

var is_ready = true

var chase_layer_players: Array = []

var hitbox_timer := 0.0
const HITBOX_INTERVAL := 0.5

@export var malice = 0

var active_music = {}

@export var hitboxes: PackedScene

@onready var Passive_Component = $PassiveComponent
@onready var Voiceline_Component = $Voiceline_Component

const CHASE_FAR = 20.0
const CHASE_MEDIUM = 15.0
const CHASE_CLOSE = 10.0
const CHASE_CLOSEST = 5.0
const CHASE_SCAN_INTERVAL = 0.2

var current_intensity: int = 0
var _chase_scan_timer: float = 0.0
 
@export var is_Killer = true
@export var equipped_killer = "yixi"
var equipped_survivor = "nyx"
@export var equipped_skin_id: String = "default"
var _skin_instance: Node3D = null

@export var hitbox_attack = "killer"

var health = 100
var weakness = 0

var stun_time = 4
var stunned = false

func _ready() -> void:
	hit_flag = []
	var char_id = equipped_killer if is_Killer else equipped_survivor
	equipped_skin_id = save_data.get_equipped_skin(char_id)
	apply_skin(equipped_skin_id)
	
	chase_layer_players = []
	for i in range(3):
		var player = AudioStreamPlayer.new()
		add_child(player)
		player.bus = "Ambience"
		chase_layer_players.append(player)

func _refresh_ability_ui():
	pass

func apply_stun(duration: float) -> void:
	if Passive_Component.has_passive("stun_immune"):
		return
	if stunned or stun_resistant:
		return

	var actual_duration = duration
	if is_instance_valid(main) and main.has_method("get_modified_stun_duration"):
		actual_duration = main.get_modified_stun_duration(duration)

	stunned = true
	stun_time = actual_duration

func apply_skin(skin_id: String) -> void:
	var char_type = "killer" if is_Killer else "survivor"
	var char_id = equipped_killer if is_Killer else equipped_survivor

	var char_data = CharData.get_killer(char_id) if is_Killer else CharData.get_survivor(char_id)
	var base_music = char_data.get("music", {})
	var base_voicelines = char_data.get("voicelines", {})
	
	var skins: Array = char_data.get("skins", [])
	if skins.is_empty():
		active_music = {
			"lms":   base_music.get("lms", ""),
			"chase": base_music.get("chase", "")
		}
		Voiceline_Component.apply_voicelines(base_voicelines) 
		return

	var skin_data = CharData.get_skin(char_id, char_type, skin_id)
	
	if skin_data.is_empty():
		push_warning("Skin '%s' not found, using base music instead~" % skin_id)
		active_music = {
			"lms": base_music.get("lms", ""),
			"chase": base_music.get("chase", "")
		}
		return

	if is_instance_valid(_skin_instance):
		_skin_instance.queue_free()

	var model_path = skin_data.get("model", "")
	if model_path != "" and ResourceLoader.exists(model_path):
		var skin_scene = load(model_path)
		if skin_scene:
			_skin_instance = skin_scene.instantiate()
			add_child(_skin_instance)
			$CollisionShape3D/MeshInstance3D.visible = false
	
	equipped_skin_id = skin_id

	var skin_music = skin_data.get("music", {})
	var base_chase = base_music.get("chase", "")
	var skin_chase = skin_music.get("chase", base_chase)
	var chase_layers = skin_music.get("chase_layers", [])
	var chase_value
	if chase_layers is Array and chase_layers.size() >= 3:
		chase_value = [chase_layers[0], chase_layers[1], chase_layers[2], skin_chase]
	else:
		chase_value = skin_chase
	active_music = {
		"lms": skin_music.get("lms", base_music.get("lms", "")),
		"chase": chase_value
	}
	
	var merged_voicelines: Dictionary = base_voicelines.duplicate()
	var skin_voicelines = skin_data.get("voicelines", {})            
	for key in skin_voicelines:                                       
		merged_voicelines[key] = skin_voicelines[key]                
	Voiceline_Component.apply_voicelines(merged_voicelines)  

func on_killed_survivor() -> void:
	$Voiceline_Component.play_kill()

func _update_chase_music() -> void:
	var target_dist = INF

	if is_Killer:

		for player in get_tree().get_nodes_in_group("players"):
			if not is_instance_valid(player):
				continue
			if player == self:
				continue
			if player.is_Killer:
				continue
			var dist = global_position.distance_to(player.global_position)
			if dist < target_dist:
				target_dist = dist
	else:

		for player in get_tree().get_nodes_in_group("players"):
			if not is_instance_valid(player):
				continue
			if not player.is_Killer:
				continue
			var dist = global_position.distance_to(player.global_position)
			if dist < target_dist:
				target_dist = dist

	var new_intensity = 0
	if target_dist <= CHASE_CLOSEST:
		new_intensity = 4
	elif target_dist <= CHASE_CLOSE:
		new_intensity = 3
	elif target_dist <= CHASE_MEDIUM:
		new_intensity = 2
	elif target_dist <= CHASE_FAR:
		new_intensity = 1

	if new_intensity != current_intensity:
		current_intensity = new_intensity
		_on_chase_state_changed(new_intensity)

func _refresh_abilities() -> void:
	pass

func play_hitsound():
	pass
		
func play_killsound():
	pass

func _on_chase_state_changed(intensity: int) -> void:
	var chase_data = active_music.get("chase", "")
	
	if not is_Killer:
		for player in get_tree().get_nodes_in_group("players"):
			if is_instance_valid(player) and player.is_Killer:
				chase_data = player.active_music.get("chase", "")
				break

	if intensity > 0:
		if chase_data is Array and chase_data.size() >= 4:
			for i in range(4):
				var path = ""
				var should_play = false
				if intensity == 4 and i == 3:
					path = chase_data[3]
					should_play = true
				elif not is_Killer and intensity == 1 and i == 0:
					path = chase_data[0]
					should_play = true
				elif not is_Killer and intensity == 2 and i == 1:
					path = chase_data[1]
					should_play = true
				elif not is_Killer and intensity == 3 and i == 2:
					path = chase_data[2]
					should_play = true

				if i < 3:
					if should_play and not chase_layer_players[i].playing and path != "" and ResourceLoader.exists(path):
						chase_layer_players[i].stream = load(path)
						chase_layer_players[i].play()
					elif not should_play and chase_layer_players[i].playing:
						chase_layer_players[i].stop()
				else:
					if should_play and not $Chase_Theme.playing and path != "" and ResourceLoader.exists(path):
						$Chase_Theme.stream = load(path)
						$Chase_Theme.play()
					elif not should_play and $Chase_Theme.playing:
						$Chase_Theme.stop()
		else:

			if not $Chase_Theme.playing and chase_data != "" and ResourceLoader.exists(chase_data):
				$Chase_Theme.stream = load(chase_data)
				$Chase_Theme.play()
	else:

		$Chase_Theme.stop()
		for player in chase_layer_players:
			player.stop()

func apply_character_stats():
	print("stuff")

func grant(_amountXP: int, _amountCoins: int, _maliceAmount: int, _text: String) -> void:
	pass

func take_damage(amount: int) -> void:
	if health <= 0:
		return
	var final_dmg = Passive_Component.apply_damage_reduction(amount)
	if weakness > 0:
		final_dmg = int(final_dmg * (1.0 + weakness * 0.25))
	health -= final_dmg

func _physics_process(delta: float) -> void:
	hitbox_attack = "killer" if not is_Killer else "survivor"
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if is_Killer or true:
		_chase_scan_timer -= delta
		if _chase_scan_timer <= 0.0:
			_chase_scan_timer = CHASE_SCAN_INTERVAL
			_update_chase_music()
	
	if health <= 0:
		in_round = false
	
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
