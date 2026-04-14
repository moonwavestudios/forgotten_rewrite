extends CharacterBody3D

@export var hitboxes: PackedScene

const WALK_SPEED = 5.0
const SPRINT_SPEED = 9.0
const MOUSE_SENSITIVITY = 0.003

var ritual_node: Node3D = null
var malice = 1
var is_Killer = false

var exp = 0

var current_speed = WALK_SPEED

@onready var camera: Camera3D = $Camera3D
@onready var first_person_cam: Camera3D = $FirstPersonCam
@onready var Ability_Component = $Ability_Component
@onready var Effect_Component = $EffectComponent

var usingAbility = false
var equipped_survivor = "nyx"
var equipped_killer = "yixi"

var crouching = false

var stunned = false

var equipped_attack = {}
var equipped_ability1 = {}
var equipped_ability2 = {}
var equipped_ability3 = {}
var equipped_ability4 = {}

var coins = 0

var pitch: float = 0.0
var cam = false

var health = 100
var maxhealth = 100

var MAX_STAMINA = 100.0
const STAMINA_DRAIN = 25.0   
const STAMINA_RECOVER = 15.0 
const STAMINA_RECOVER_EXHAUSTED = 5 

var ability_uses := {}

var stamina: float = MAX_STAMINA
var is_sprinting: bool = false

var exhausted: bool = false       
var sprint_needs_reset: bool = false 

var blocking = false

@onready var raycast = $RayCast3D

var weakness = 0
var tokens = 0

var interact_handlers := {
	"generator": _interact_generator,
	"arcade": _interact_arcade,
}

const COOLDOWN_ABILITY1 = 15.0
const COOLDOWN_ABILITY2 = 5.0
const COOLDOWN_ABILITY3 = 5.0
const COOLDOWN_ABILITY4 = 5.0
const COOLDOWN_ATTACK   = 2.0

var cooldowns := {
	"Ability1": 0.0,
	"Ability2": 0.0,
	"Ability3": 0.0,
	"Ability4": 0.0,
	"Attack":   0.0,
}

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_refresh_abilities()

func _process(delta: float) -> void:
	for key in cooldowns:
		if cooldowns[key] > 0.0:
			cooldowns[key] = max(0.0, cooldowns[key] - delta)

func _is_on_cooldown(action: String) -> bool:
	return cooldowns.get(action, 0.0) > 0.0

func _start_cooldown(action: String, duration: float) -> void:
	cooldowns[action] = duration

func _refresh_abilities() -> void:
	if is_Killer:
		equipped_attack = Ability_Component.get_killer_ability("primary", equipped_killer)
		equipped_ability1 = Ability_Component.get_killer_ability("ability1", equipped_killer)
		equipped_ability2 = Ability_Component.get_killer_ability("ability2", equipped_killer)
		if Ability_Component.has_ability("ability3", equipped_killer):
			equipped_ability3 = Ability_Component.get_killer_ability("ability3", equipped_killer)
		if Ability_Component.has_ability("ability4", equipped_killer):
			equipped_ability4 = Ability_Component.get_killer_ability("ability4", equipped_killer)
			
		ability_uses.clear()
		for ab in [equipped_ability1, equipped_ability2, equipped_ability3, equipped_ability4]:
			if ab.has("uses") and ab.has("name"):
				ability_uses[ab.get("name")] = ab.get("uses")
	else:
		equipped_ability1 = Ability_Component.get_ability_survivor("ability1", equipped_survivor)
		equipped_ability2 = Ability_Component.get_ability_survivor("ability2", equipped_survivor)
		if Ability_Component.has_ability("ability3", equipped_survivor):
			equipped_ability3 = Ability_Component.get_ability_survivor("ability3", equipped_survivor)
		if Ability_Component.has_ability("ability4", equipped_survivor):
			equipped_ability4 = Ability_Component.get_ability_survivor("ability4", equipped_survivor)
		ability_uses.clear()
		for ab in [equipped_ability1, equipped_ability2, equipped_ability3, equipped_ability4]:
			if ab.has("uses") and ab.has("name"):
				ability_uses[ab.get("name")] = ab.get("uses")
			
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if Input.is_action_pressed("Sprint") and not exhausted and not sprint_needs_reset:
		is_sprinting = true
	else:
		is_sprinting = false
		
	if weakness > 0:
		$player_ui/GameStuff/VBoxContainer/Label.visible = true
		$player_ui/GameStuff/VBoxContainer/Label.text = "Weakness: " + str(weakness)
		
	$player_ui/GameStuff/Health.value = health
	$player_ui/GameStuff/Stamina.value = stamina
	
	if Input.is_action_just_pressed("Ability1") and not usingAbility and not _is_on_cooldown(equipped_ability1.get("name", "Ability1")):
		var ability_type = equipped_ability1.get("type", "")
		var ability_name = equipped_ability1.get("name", "Ability1")
		var cooldown_duration = equipped_ability1.get("cooldown", COOLDOWN_ABILITY1)
		Ability_Component._activate_ability(ability_type)
		_start_cooldown(ability_name, cooldown_duration)
		usingAbility = true
		await get_tree().create_timer(0.5).timeout
		abilityTimer_timeout()

	if Input.is_action_just_pressed("Ability2") and not usingAbility and not _is_on_cooldown(equipped_ability2.get("name", "Ability2")):
		if not _has_uses(equipped_ability2):
			return
			
		if equipped_ability2.get("type", "") == "chicken" and health >= maxhealth:
			return
			
		_consume_use(equipped_ability2)
		var ability_type = equipped_ability2.get("type", "")
		var ability_name = equipped_ability2.get("name", "Ability2")
		var cooldown_duration = equipped_ability2.get("cooldown", COOLDOWN_ABILITY2)
		_start_cooldown(ability_name, cooldown_duration)
		usingAbility = true
		Ability_Component._activate_ability(ability_type)
		
	if Input.is_action_just_pressed("Ability3") and not usingAbility and not equipped_ability3.is_empty() and not _is_on_cooldown(equipped_ability1.get("name", "Ability3")):
		var ability_type = equipped_ability3.get("type", "")
		var ability_name = equipped_ability3.get("name", "Ability3")
		var cooldown_duration = equipped_ability3.get("cooldown", COOLDOWN_ABILITY3)
		Ability_Component._activate_ability(ability_type)
		_start_cooldown(ability_name, cooldown_duration)
		usingAbility = true
		await get_tree().create_timer(0.5).timeout
		abilityTimer_timeout()
		
	if Input.is_action_just_pressed("Ability4") and not usingAbility and not equipped_ability4.is_empty() and not _is_on_cooldown(equipped_ability1.get("name", "Ability4")):
		var ability_type = equipped_ability4.get("type", "")
		var ability_name = equipped_ability4.get("name", "Ability4")
		var cooldown_duration = equipped_ability4.get("cooldown", COOLDOWN_ABILITY4)
		Ability_Component._activate_ability(ability_type)
		_start_cooldown(ability_name, cooldown_duration)
		usingAbility = true
		await get_tree().create_timer(0.5).timeout
		abilityTimer_timeout()

	if Input.is_action_just_pressed("interact") and not usingAbility:
		var collider = raycast.get_collider()
		if collider is Area3D:
			try_interact(collider)
			
	if Input.is_action_just_pressed("ChangeCam"):
		cam = not cam
		if cam:
			$FirstPersonCam.current = true
		else:
			camera.current = true

	if Input.is_action_just_pressed("Attack") and not usingAbility and not _is_on_cooldown(equipped_attack.get("name", "Attack")) and is_Killer:
		var ability_type = equipped_attack.get("type", "")
		var ability_name = equipped_attack.get("name", "Attack")
		var cooldown_duration = equipped_attack.get("cooldown", COOLDOWN_ATTACK)
		Ability_Component._activate_ability(ability_type)
		_start_cooldown(ability_name, cooldown_duration)
		usingAbility = true
		await get_tree().create_timer(0.5).timeout
		abilityTimer_timeout()
	
	if is_sprinting:
		current_speed = SPRINT_SPEED
		stamina = max(stamina - STAMINA_DRAIN * delta, 0.0)
	else:
		current_speed = WALK_SPEED
		if exhausted:
			stamina = min(stamina + STAMINA_RECOVER_EXHAUSTED * delta, MAX_STAMINA)
			if stamina >= MAX_STAMINA * 0.25:
				exhausted = false
		else:
			stamina = min(stamina + STAMINA_RECOVER * delta, MAX_STAMINA)

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, WALK_SPEED)
		velocity.z = move_toward(velocity.z, 0, WALK_SPEED)
	move_and_slide()

func try_interact(collider: Area3D):
	if not is_multiplayer_authority():
		return
	for group in interact_handlers.keys():
		if collider.is_in_group(group):
			interact_handlers[group].call(collider)
			return

func _has_uses(ability_data: Dictionary) -> bool:
	if not ability_data.has("uses"):
		return true 
	var namer = ability_data.get("name", "")
	return ability_uses.get(namer, 0) > 0

func _consume_use(ability_data: Dictionary) -> void:
	if not ability_data.has("uses"):
		return
	var namer = ability_data.get("name", "")
	if ability_uses.has(namer):
		ability_uses[namer] = max(0, ability_uses[namer] - 1)

func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		pitch -= event.relative.y * MOUSE_SENSITIVITY
		pitch = clamp(pitch, deg_to_rad(-80), deg_to_rad(80))
		camera.rotation.x = pitch
		first_person_cam.rotation.x = pitch

func apply_effect(effect, level):
	Effect_Component.activate_effect(effect, level)

func disable_effect(effect):
	Effect_Component.deactivate_effect(effect)

func _interact_generator(_collider) -> void:
	print("gen")
	
func grant(amountXP : int, amountCoins : int, text : String):
	var notificationsText = preload("res://scenes/other/notifications_text.tscn")
	var notifications = notificationsText.instantiate()
	
	exp += amountXP
	coins += amountCoins
	
	notifications.text = text + ": +" + str(amountXP) + " Coins +" + str(amountXP) + " EXP"
	
	$player_ui/GameStuff/Notifications.add_child(notifications)
	
	await get_tree().create_timer(2).timeout
	
	notifications.queue_free()
	
func _interact_arcade(_collider) -> void:
	print("arcade")

func abilityTimer_timeout():
	usingAbility = false
