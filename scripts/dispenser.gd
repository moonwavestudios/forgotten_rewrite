extends Node3D

var owner_player: Node = null
var health := 80
var _lifetime := 30.0
var _heal_interval := 2.0
var _range := 6.0
var _heal_amount := 10
var _elapsed := 0.0
var _heal_timer := 0.0

func _physics_process(delta: float) -> void:
	if not is_instance_valid(owner_player):
		queue_free()
		return

	_elapsed += delta
	if _elapsed >= _lifetime:
		queue_free()
		return

	_heal_timer += delta
	if _heal_timer < _heal_interval:
		return
	_heal_timer = 0.0

	var space = get_world_3d().direct_space_state
	var shape = SphereShape3D.new()
	shape.radius = _range

	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = global_transform

	var results = space.intersect_shape(query)
	for r in results:
		var body = r.collider
		if "is_Killer" in body and not body.is_Killer and body.health > 0:
			body.health = min(body.health + _heal_amount, body.maxhealth)

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		queue_free()
