extends Node3D

@export var max_health: float              = 2.0   # how many hits to break (set to 1 for one-shot)
@export var vault_duration: float          = 0.8
@export var vault_move_distance: float     = 2.2
@export var survivor_vault_speed_boost: float = 1.4

enum State { STANDING, DROPPED, BROKEN }
var state: State = State.STANDING
var health: float

signal pallet_dropped(pallet: Node)
signal pallet_broken(pallet: Node)
signal survivor_vaulted(pallet: Node, survivor: Node)

@onready var _blocker:         StaticBody3D    = $Blocker
@onready var _anim:            AnimationPlayer = $Anim
@onready var _mesh:            MeshInstance3D  = $Mesh
@onready var _prompt_survivor: Area3D          = $PromptSurvivor

var _vaulting_nodes: Dictionary = {}

func _ready() -> void:
	health = max_health
	_disable_blocker()
	_prompt_survivor.connect("prompt_triggered", _on_survivor_prompt_triggered)
	_refresh_prompt()

func _on_survivor_prompt_triggered(interactor: Node) -> void:
	match state:
		State.STANDING: _drop_pallet(interactor)
		State.DROPPED:  _vault(interactor)

func take_damage(amount: float) -> void:
	if state != State.DROPPED:
		return
	health -= amount
	if health <= 0.0:
		_break_pallet()

func _drop_pallet(_dropper: Node) -> void:
	if state != State.STANDING:
		return
	state = State.DROPPED

	if _anim.has_animation("drop"):
		_anim.play("drop")
		await _anim.animation_finished

	_enable_blocker()
	emit_signal("pallet_dropped", self)
	_refresh_prompt()

func _vault(vaulter: Node) -> void:
	if vaulter in _vaulting_nodes:
		return
	_vaulting_nodes[vaulter] = true
	_set_actor_frozen(vaulter, true)

	if _anim.has_animation("vault_survivor"):
		_anim.play("vault_survivor")

	var forward: Vector3 = (vaulter.global_position - global_position).normalized()
	forward.y = 0.0
	var target_pos: Vector3 = vaulter.global_position + forward * vault_move_distance

	var tween := create_tween()
	tween.tween_property(vaulter, "global_position", target_pos, vault_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	_set_actor_frozen(vaulter, false)
	_apply_speed_boost(vaulter, survivor_vault_speed_boost)
	emit_signal("survivor_vaulted", self, vaulter)
	_vaulting_nodes.erase(vaulter)

func _break_pallet() -> void:
	if state != State.DROPPED:
		return
	state = State.BROKEN
	_prompt_survivor.set_enabled(false)

	if _anim.has_animation("break"):
		_anim.play("break")
		await _anim.animation_finished

	_disable_blocker()
	_mesh.visible = false
	emit_signal("pallet_broken", self)
	# queue_free()

func _enable_blocker() -> void:
	_blocker.set_collision_layer_value(1, true)
	_blocker.set_collision_mask_value(1, true)

func _disable_blocker() -> void:
	_blocker.set_collision_layer_value(1, false)
	_blocker.set_collision_mask_value(1, false)

func _refresh_prompt() -> void:
	match state:
		State.STANDING:
			_prompt_survivor.set_enabled(true)
			_prompt_survivor.set_prompt_text("Press [F] to drop pallet")
		State.DROPPED:
			_prompt_survivor.set_enabled(true)
			_prompt_survivor.set_prompt_text("Press [F] to vault")
		State.BROKEN:
			_prompt_survivor.set_enabled(false)

func _set_actor_frozen(actor: Node, frozen: bool) -> void:
	if "movement_locked" in actor:
		actor.movement_locked = frozen

func _apply_speed_boost(actor: Node, multiplier: float) -> void:
	if actor.has_method("apply_speed_boost"):
		actor.apply_speed_boost(multiplier, 2.5)
	elif "speed_multiplier" in actor:
		actor.speed_multiplier = multiplier
		await get_tree().create_timer(2.5).timeout
		actor.speed_multiplier = 1.0
