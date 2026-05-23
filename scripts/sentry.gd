extends Node3D

var owner_player: Node = null
var hitboxes_scene = null
var health := 60
var _lifetime := 20.0
var _attack_interval := 0.8
var _range := 8.0
var _damage := 15
var _elapsed := 0.0
var _attack_timer := 0.0

func _physics_process(delta: float) -> void:
	if not is_instance_valid(owner_player):
		queue_free()
		return

	_elapsed += delta
	if _elapsed >= _lifetime:
		queue_free()
		return

	_attack_timer += delta
	if _attack_timer < _attack_interval:
		return
	_attack_timer = 0.0

	var space = get_world_3d().direct_space_state
	var shape = SphereShape3D.new()
	shape.radius = _range

	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = global_transform
	query.exclude = [owner_player.get_rid()]

	var results = space.intersect_shape(query)
	var closest: Node = null
	var closest_dist := INF

	for r in results:
		var body = r.collider
		if "is_Killer" in body and body.is_Killer and body.health > 0:
			var d = global_position.distance_to(body.global_position)
			if d < closest_dist:
				closest_dist = d
				closest = body

	if closest != null:
		var hit_flag: Array = []
		var main = get_parent()
		main.add_hitbox(
			hitboxes_scene,
			closest.global_position,
			hit_flag,
			_damage,
			"killer",
			Vector3(1.0, 1.0, 1.0),
			null,
			false,
			owner_player
		)

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		queue_free()
