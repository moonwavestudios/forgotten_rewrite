class_name PassiveComponent
extends Node

@onready var player = $".."

var _active_passives: Dictionary = {}

func _ready() -> void:
	await get_tree().physics_frame
	_load_passives()

func _load_passives() -> void:
	var passive_data: Dictionary = {}

	if player.is_Killer:
		passive_data = _get_killer_passive(player.equipped_killer)
	else:
		passive_data = _get_survivor_passive(player.equipped_survivor)

	if passive_data.is_empty():
		return

	_apply_passive(passive_data)

func _apply_passive(data: Dictionary) -> void:
	var ptype: String = data.get("type", "")
	if ptype == "":
		return

	_active_passives[ptype] = data

	match ptype:
		"regen":
			var interval: float = data.get("interval", 5.0)
			var amount: int = data.get("amount", 5)
			_start_regen_loop(interval, amount)

		"speed_boost":
			var multiplier: float = data.get("multiplier", 1.1)
			player.WALK_SPEED *= multiplier
			player.SPRINT_SPEED *= multiplier
			player.current_speed = player.WALK_SPEED

		"damage_reduce":
			pass  

		"token_start":
			var amount: int = data.get("amount", 1)
			player.tokens = min(player.tokens + amount, 3)

		"extra_health":
			var bonus: int = data.get("bonus", 20)
			player.maxhealth += bonus
			player.health = min(player.health + bonus, player.maxhealth)

		"block_regen":
			var interval: float = data.get("interval", 10.0)
			var max_blocks: int = data.get("max_blocks", 3)
			_start_block_regen_loop(interval, max_blocks)

		"stun_immune":
			player.stun_resistant = true
			player.stun_resistance_time = INF

		_:
			push_warning("[PassiveComponent] Unknown passive type: '%s' >_<" % ptype)

func _start_regen_loop(interval: float, amount: int) -> void:
	while is_instance_valid(player):
		await get_tree().create_timer(interval).timeout
		if not is_instance_valid(player):
			break
		if player.health > 0 and player.health < player.maxhealth:
			player.health = min(player.health + amount, player.maxhealth)

func _start_block_regen_loop(interval: float, max_blocks: int) -> void:
	while is_instance_valid(player):
		await get_tree().create_timer(interval).timeout
		if not is_instance_valid(player):
			break
		if player.blocks < max_blocks:
			player.blocks += 1

func apply_damage_reduction(raw_damage: int) -> int:
	if _active_passives.has("damage_reduce"):
		var reduction: float = _active_passives["damage_reduce"].get("reduction", 0.1)
		return max(1, int(raw_damage * (1.0 - reduction)))
	return raw_damage

func has_passive(ptype: String) -> bool:
	return _active_passives.has(ptype)

func get_passive(ptype: String) -> Dictionary:
	return _active_passives.get(ptype, {})

func _get_survivor_passive(survivor: String) -> Dictionary:
	var survivor_data = CharData.get_survivor(survivor)
	var abilities: Array = survivor_data.get("abilities", [])
	for ab in abilities:
		if ab.get("id") == "passive":
			return ab
	return {}

func _get_killer_passive(killer: String) -> Dictionary:
	var killer_data = CharData.get_killer(killer)
	var abilities: Array = killer_data.get("abilities", [])
	for ab in abilities:
		if ab.get("id") == "passive":
			return ab
	return {}
