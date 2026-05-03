extends CharacterBody3D

@export var hitboxes: PackedScene

var WALK_SPEED = 5.0
var SPRINT_SPEED = 9.0
const MOUSE_SENSITIVITY = 0.003

var mouse_unlocked = false

var playtime_seconds: float = 0.0
var _playtime_save_timer: float = 0.0
const PLAYTIME_SAVE_INTERVAL: float = 60.0

var stun_resistant: bool = false
var stun_resistance_time: float = 0.0

const CHASE_RANGE = 15.0
const CHASE_SCAN_INTERVAL = 0.2

var _in_chase: bool = false
var _chase_scan_timer: float = 0.0

var equipped_emotes: Array = []
var is_emoting: bool = false
var current_emote: String = ""

var malice: int = -100
var is_Killer = false

var xp = 0
var blocks = 0

var current_speed = WALK_SPEED

@onready var camera: Camera3D = $Camera3D
@onready var first_person_cam: Camera3D = $FirstPersonCam
@onready var Ability_Component = $Ability_Component
@onready var Effect_Component = $EffectComponent
@onready var Voiceline_Component = $Voiceline_Component
@onready var Passive_Component = $PassiveComponent

@onready var AbilitiesStuff = $player_ui/GameStuff/AbilitiesStuff 
@onready var Items = $player_ui/GameStuff/Items 
@onready var AdminButton = $player_ui/Both/Admin

@onready var main = $".."

var usingAbility = false
var equipped_survivor = "nyx"
var equipped_killer = "yixi"
var equipped_skin_id: String = "default"
var _skin_instance: Node3D = null

var in_round = false

var crouching = false

var stun_time = 4
var stunned = false

var active_music = {}

var equipped_attack = {}
var equipped_ability1 = {}
var equipped_ability2 = {}
var equipped_ability3 = {}
var equipped_ability4 = {}

var has_items = [] # 2 item slots
var selected_item = ""

var coins = 0

var pitch: float = 0.0
var cam = false

var health = 100
var maxhealth = 100

var MAX_STAMINA = 100.0
const STAMINA_DRAIN = 25.0   
const STAMINA_RECOVER = 15.0 
const STAMINA_RECOVER_EXHAUSTED = 5 

@onready var anim_player: AnimationPlayer = $AnimationPlayer

var ability_uses := {}

var stamina: float = MAX_STAMINA
var is_sprinting: bool = false

var exhausted: bool = false       
var sprint_needs_reset: bool = false 

var blocking = false

@onready var raycast = $RayCast3D

var weakness = 0
var tokens = 0

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

	var saved_survivor = save_data.get_equipped_character("survivor")
	var saved_killer   = save_data.get_equipped_character("killer")

	if saved_survivor != "":
		equipped_survivor = saved_survivor
	if saved_killer != "":
		equipped_killer = saved_killer

	var char_id = equipped_killer if is_Killer else equipped_survivor
	equipped_skin_id = save_data.get_equipped_skin(char_id)
	apply_skin(equipped_skin_id)

	coins  = save_data.get_coins()
	malice = save_data.get_malice()

	var xp_char_id = equipped_killer if is_Killer else equipped_survivor
	xp = save_data.get_character_xp(xp_char_id)
	
	var pt_char_id = equipped_killer if is_Killer else equipped_survivor
	playtime_seconds = save_data.get_playtime(pt_char_id)
	
	AdminButton.pressed.connect(_on_admin_button_pressed)

func _process(delta: float) -> void:
	for key in cooldowns:
		if cooldowns[key] > 0.0:
			cooldowns[key] = max(0.0, cooldowns[key] - delta)
			
	playtime_seconds += delta
	_playtime_save_timer += delta
	if _playtime_save_timer >= PLAYTIME_SAVE_INTERVAL:
		_playtime_save_timer = 0.0
		var pt_char_id = equipped_killer if is_Killer else equipped_survivor
		save_data.add_playtime(pt_char_id, PLAYTIME_SAVE_INTERVAL) 
		
func _save_playtime() -> void:
	var unflushed = fmod(playtime_seconds, PLAYTIME_SAVE_INTERVAL)
	if unflushed > 0.0:
		var pt_char_id = equipped_killer if is_Killer else equipped_survivor
		save_data.add_playtime(pt_char_id, unflushed)

func play_hitsound():
	if is_multiplayer_authority():
		$Hitsound.play()
		
func play_killsound():
	if is_multiplayer_authority():
		$Killsound.play()

func _is_on_cooldown(action: String) -> bool:
	return cooldowns.get(action, 0.0) > 0.0

func _start_cooldown(action: String, duration: float) -> void:
	cooldowns[action] = duration

func apply_character_stats():
	var char_id = equipped_killer if is_Killer else equipped_survivor
	var char_data = CharData.get_killer(char_id) if is_Killer else CharData.get_survivor(char_id)

	var stats: Dictionary = char_data.get("stats", {})

	maxhealth = int(stats.get("health", 100))
	health = int(maxhealth)

	WALK_SPEED = stats.get("walk_speed", 5.1)
	SPRINT_SPEED = stats.get("sprint_speed", 9.1)

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
	
	equipped_skin_id = skin_id

	var skin_music = skin_data.get("music", {})
	active_music = {
		"lms": skin_music.get("lms", base_music.get("lms", "")),
		"chase": skin_music.get("chase", base_music.get("chase", ""))
	}
	
	var merged_voicelines: Dictionary = base_voicelines.duplicate()
	var skin_voicelines = skin_data.get("voicelines", {})            
	for key in skin_voicelines:                                       
		merged_voicelines[key] = skin_voicelines[key]                
	Voiceline_Component.apply_voicelines(merged_voicelines)  

func refresh_item_ui() -> void:
	var slots = []
	for child in Items.get_children():
		if child.name.begins_with("Item"):
			slots.append(child)

	for i in range(slots.size()):
		var ability = has_items[i] if i < has_items.size() else {}
		slots[i].visible = not ability.is_empty()

		## THIS IS FOR LATER WHEN EVERYTHING IS ADDED
		#if not ability.is_empty():
		#	var tex_rect = slots[i].get_node_or_null("TextureRect")
		#	if tex_rect and ability.has("icon"):
		#		tex_rect.texture = load(ability.get("icon", ""))

func _refresh_ability_ui() -> void:
	var abilities = [
		equipped_attack,
		equipped_ability1,
		equipped_ability2,
		equipped_ability3,
		equipped_ability4,
	]
	
	var action_names = [
		"Attack",
		"Ability1",
		"Ability2",
		"Ability3",
		"Ability4",
	]

	var slots = []
	for child in AbilitiesStuff.get_children():
		if child.name.begins_with("Ability"):
			slots.append(child)

	for i in range(slots.size()):
		var ability = abilities[i] if i < abilities.size() else {}
		slots[i].visible = not ability.is_empty()

		## THIS IS FOR LATER WHEN EVERYTHING IS ADDED
		if not ability.is_empty():
		#	var tex_rect = slots[i].get_node_or_null("TextureRect")
		#	if tex_rect and ability.has("icon"):
		#		tex_rect.texture = load(ability.get("icon", ""))

			var keybind_node = slots[i].get_node_or_null("Keybind")
			if keybind_node:
				var action = action_names[i] if i < action_names.size() else ""
				keybind_node.text = PlayerSettings.get_keybind_label(action)

func add_item(item):
	if not has_items.has(item):
		has_items.append(item)
		refresh_item_ui()

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
				
	_refresh_ability_ui()
			
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if Input.is_action_pressed("Sprint") and not exhausted and not sprint_needs_reset:
		is_sprinting = true
	else:
		is_sprinting = false
		
	if is_Killer:
		_chase_scan_timer -= delta
		if _chase_scan_timer <= 0.0:
			_chase_scan_timer = CHASE_SCAN_INTERVAL
			_update_chase_music()
		
	if weakness > 0:
		$player_ui/GameStuff/VBoxContainer/Label.visible = true
		$player_ui/GameStuff/VBoxContainer/Label.text = "Weakness: " + str(weakness)
		
	$player_ui/GameStuff/Health.value = health
	$player_ui/GameStuff/Health.max_value = maxhealth
	$player_ui/GameStuff/Health/Label.text = str(int(health)) + "/" + str(maxhealth)
	$player_ui/GameStuff/Stamina.value = stamina
	$player_ui/GameStuff/Stamina/Label.text = str(int(stamina)) + "/" + str(int(MAX_STAMINA))
	
	if health < maxhealth*0.5:
		$player_ui/GameStuff/Vignette.visible = true
	else:
		$player_ui/GameStuff/Vignette.visible = false
		
	if health <= 0:
		in_round = false
		$player_ui/GameStuff.visible = false
		$player_ui/SpectatorStuff.visible = true
	
	if Input.is_action_just_pressed("Ability1") and in_round and not usingAbility and not _is_on_cooldown(equipped_ability1.get("name", "Ability1")):
		var ability_type = equipped_ability1.get("type", "")
		var ability_name = equipped_ability1.get("name", "Ability1")
		var cooldown_duration = equipped_ability1.get("cooldown", COOLDOWN_ABILITY1)
		Ability_Component._activate_ability(ability_type)
		Voiceline_Component.play_ability(ability_type)
		_start_cooldown(ability_name, cooldown_duration)
		usingAbility = true
		await get_tree().create_timer(0.5).timeout
		abilityTimer_timeout()

	if Input.is_action_just_pressed("Ability2") and in_round and not usingAbility and not _is_on_cooldown(equipped_ability2.get("name", "Ability2")):
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
		Voiceline_Component.play_ability(ability_type)
		await get_tree().create_timer(0.5).timeout
		abilityTimer_timeout()
		
	if Input.is_action_just_pressed("Ability3") and in_round and not usingAbility and not equipped_ability3.is_empty() and not _is_on_cooldown(equipped_ability3.get("name", "Ability3")):
		var ability_type = equipped_ability3.get("type", "")
		var ability_name = equipped_ability3.get("name", "Ability3")
		var cooldown_duration = equipped_ability3.get("cooldown", COOLDOWN_ABILITY3)
		Ability_Component._activate_ability(ability_type)
		Voiceline_Component.play_ability(ability_type)
		_start_cooldown(ability_name, cooldown_duration)
		usingAbility = true
		await get_tree().create_timer(0.5).timeout
		abilityTimer_timeout()
		
	if Input.is_action_just_pressed("Ability4") and in_round and not usingAbility and not equipped_ability4.is_empty() and not _is_on_cooldown(equipped_ability4.get("name", "Ability4")):
		var ability_type = equipped_ability4.get("type", "")
		var ability_name = equipped_ability4.get("name", "Ability4")
		var cooldown_duration = equipped_ability4.get("cooldown", COOLDOWN_ABILITY4)
		Ability_Component._activate_ability(ability_type)
		Voiceline_Component.play_ability(ability_type)
		_start_cooldown(ability_name, cooldown_duration)
		usingAbility = true
		if ability_type != "ally_link":
			await get_tree().create_timer(0.5).timeout
			abilityTimer_timeout()
			
	if not is_Killer and Input.is_action_just_pressed("ui_accept") and not is_emoting and not usingAbility:
		_try_emote("Wave")
		
	if Input.is_action_just_pressed("Item1") and has_items.size() > 0:
		var item = has_items[0]
		selected_item = item

	if Input.is_action_just_pressed("Item2") and has_items.size() > 1:
		var item = has_items[1]
		selected_item = item
	
	if Input.is_action_just_pressed("unlock_mouse"):
		if mouse_unlocked:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			mouse_unlocked = false
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
			mouse_unlocked = true
	
	if Input.is_action_just_pressed("ChangeCam"):
		cam = not cam
		if cam:
			$FirstPersonCam.current = true
		else:
			camera.current = true
			
	if Input.is_action_just_pressed("Shop") and not in_round:
		$player_ui/SpectatorStuff/Shop.visible = not $player_ui/SpectatorStuff/Shop.visible
			
	if Input.is_action_just_pressed("Inventory") and not in_round:
		$player_ui/SpectatorStuff/Inventory.visible = not $player_ui/SpectatorStuff/Inventory.visible

	if Input.is_action_just_pressed("Attack") and not usingAbility and not _is_on_cooldown(equipped_attack.get("name", "Attack")):
		if is_Killer:
			var ability_type = equipped_attack.get("type", "")
			var ability_name = equipped_attack.get("name", "Attack")
			var cooldown_duration = equipped_attack.get("cooldown", COOLDOWN_ATTACK)
			Ability_Component._activate_ability(ability_type)
			_start_cooldown(ability_name, cooldown_duration)
			usingAbility = true
			await get_tree().create_timer(0.5).timeout
			abilityTimer_timeout()
		else:
			if selected_item == "medkit":
				health = min(health + 80, maxhealth)
				has_items.erase("medkit")
				selected_item = ""
				refresh_item_ui()
			elif selected_item == "cola":
				has_items.erase("cola")
				selected_item = ""
				refresh_item_ui()
				var base_walk = WALK_SPEED
				var base_sprint = SPRINT_SPEED
				WALK_SPEED *= 2.0
				SPRINT_SPEED *= 2.0
				current_speed = WALK_SPEED
				await get_tree().create_timer(5.0).timeout
				WALK_SPEED = base_walk
				SPRINT_SPEED = base_sprint
				current_speed = WALK_SPEED
	
	if is_sprinting:
		current_speed = SPRINT_SPEED
		stamina = max(stamina - STAMINA_DRAIN * delta, 0.0)
	else:
		if exhausted:
			stamina = min(stamina + STAMINA_RECOVER_EXHAUSTED * delta, MAX_STAMINA)
			if stamina >= MAX_STAMINA * 0.25:
				exhausted = false
		else:
			stamina = min(stamina + STAMINA_RECOVER * delta, MAX_STAMINA)
			
	if not is_sprinting and current_speed == SPRINT_SPEED:
		current_speed = WALK_SPEED

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	if is_emoting:
		if input_dir.length() > 0.1:
			_stop_emote()
		return
		
	if stun_resistant:
		stun_resistance_time = max(0.0, stun_resistance_time - delta)
		if stun_resistance_time <= 0.0:
			stun_resistant = false
		
	if stunned:
		stun_time = max(0.0, stun_time - delta)
		if stun_time <= 0.0:
			stunned = false
			stun_resistant = true      
			stun_resistance_time = 3.0 
		velocity.x = move_toward(velocity.x, 0, WALK_SPEED)
		velocity.z = move_toward(velocity.z, 0, WALK_SPEED)
		move_and_slide()
		return
		
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, WALK_SPEED)
		velocity.z = move_toward(velocity.z, 0, WALK_SPEED)
		
	move_and_slide()

func on_killed_survivor() -> void:
	Voiceline_Component.play_kill()

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
		var chase_path = active_music.get("chase", "")
		if chase_path == "":
			push_warning("No chase music path set for this killer.")
			return
		if not $Chase_Theme.playing:
			$Chase_Theme.stream = load(chase_path)
			$Chase_Theme.play()
	else:
		$Chase_Theme.stop()

func _try_emote(emote_name: String) -> void:
	if is_Killer:
		return

	var emote_data = EmoteData.get_emote(emote_name)
	if emote_data.is_empty():
		return

	if not EmoteData.is_unlocked(emote_name, equipped_emotes):
		return

	_play_emote(emote_name, emote_data)

func _play_emote(emote_name: String, emote_data: Dictionary) -> void:
	is_emoting = true
	current_emote = emote_name
	usingAbility = true  # blocks abilities + movement input

	var anim = emote_data.get("animation", "")
	var duration = emote_data.get("duration", 2.0)

	if anim != "" and anim_player.has_animation(anim):
		anim_player.play(anim)

	await get_tree().create_timer(duration).timeout
	_stop_emote()

func _stop_emote() -> void:
	is_emoting = false
	current_emote = ""
	usingAbility = false
	if anim_player.is_playing():
		anim_player.stop()

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

func give_coins(amount):
	coins += amount
	save_data.set_coins(coins)

func grant(amountXP: int, amountCoins: int, text: String) -> void:
	var notificationsText = preload("res://scenes/other/notifications_text.tscn")
	var notifications = notificationsText.instantiate()

	var char_id = equipped_killer if is_Killer else equipped_survivor

	xp += amountXP
	save_data.add_character_xp(char_id, amountXP)

	coins += amountCoins
	save_data.set_coins(coins)

	notifications.text = text + ": +" + str(amountCoins) + " Coins +" + str(amountXP) + " EXP"
	$player_ui/GameStuff/Notifications.add_child(notifications)

	await get_tree().create_timer(2).timeout
	notifications.queue_free()
	
func take_damage(amount: int) -> void:
	if health <= 0:
		return
	var final_dmg = Passive_Component.apply_damage_reduction(amount)
	if weakness > 0:
		final_dmg = int(final_dmg * weakness)
	health -= final_dmg

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
	if is_emoting:
		_stop_emote()
	usingAbility = false
	is_sprinting = false

func _on_admin_button_pressed() -> void:
	$"player_ui/Both/Admin_Panel".visible = not $"player_ui/Both/Admin_Panel".visible

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		_save_playtime()

func abilityTimer_timeout():
	usingAbility = false
