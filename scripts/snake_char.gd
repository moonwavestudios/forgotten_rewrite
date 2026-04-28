extends CharacterBody2D

const SPEED = 300.0
@export var screen_width: float = 1152.0
@export var screen_height: float = 648.0
@export var wrap_around: bool = false

@export var segment_size: float = 64.0
@export var segment_spacing: float = 64.0 
@export var collision_radius: float = 8.0

var tail_segment_scene = preload("res://scenes/other/tail.tscn")
var tail_segments: Array[Node2D] = []

var position_history: Array[Vector2] = []
var history_length: int = 1

signal wall_hit

var current_direction: Vector2 = Vector2.RIGHT
var is_dead: bool = false

func _ready() -> void:
	get_parent().spawn_food()
	if $"..".visible:
		velocity = current_direction * SPEED

func _input(event: InputEvent) -> void:
	if is_dead:
		return
	if event.is_action_pressed("ui_left") and current_direction != Vector2.RIGHT:
		current_direction = Vector2.LEFT
	elif event.is_action_pressed("ui_right") and current_direction != Vector2.LEFT:
		current_direction = Vector2.RIGHT
	elif event.is_action_pressed("ui_up") and current_direction != Vector2.DOWN:
		current_direction = Vector2.UP
	elif event.is_action_pressed("ui_down") and current_direction != Vector2.UP:
		current_direction = Vector2.DOWN
	if $"..".visible:
		velocity = current_direction * SPEED

func _physics_process(_delta: float) -> void:
	if is_dead:
		return
	move_and_slide()
	_record_position()
	_update_tail_positions()
	_check_self_collision()
	_handle_wall_collision()

func _record_position() -> void:
	position_history.push_front(global_position)
	var max_needed = (tail_segments.size() + 1) * _samples_per_segment() + 10
	while position_history.size() > max_needed:
		position_history.pop_back()

func _samples_per_segment() -> int:
	var px_per_frame = SPEED / 60.0
	return max(1, int(segment_spacing / px_per_frame))

func _update_tail_positions() -> void:
	var spp = _samples_per_segment()
	for i in range(tail_segments.size()):
		var history_index = (i + 1) * spp
		if history_index < position_history.size():
			tail_segments[i].global_position = position_history[history_index]

func grow() -> void:
	var seg = tail_segment_scene.instantiate()
	get_parent().add_child(seg)
	seg.setup(segment_size, Color(0.2, 0.75, 0.3))
	
	if tail_segments.size() > 0:
		seg.global_position = tail_segments[-1].global_position
	elif position_history.size() > 0:
		seg.global_position = position_history[-1]
	else:
		seg.global_position = global_position
	tail_segments.append(seg)

func _check_self_collision() -> bool:
	var grace_segments = 4
	for i in range(grace_segments, tail_segments.size()):
		if global_position.distance_to(tail_segments[i].global_position) < collision_radius:
			_on_death()
			return true
	return false

func get_all_positions() -> Array:
	var positions: Array = [global_position]
	for seg in tail_segments:
		positions.append(seg.global_position)
	return positions

func _handle_wall_collision() -> void:
	var pos = global_position
	if wrap_around:
		if pos.x < 0: global_position.x = screen_width
		elif pos.x > screen_width: global_position.x = 0
		if pos.y < 0: global_position.y = screen_height
		elif pos.y > screen_height: global_position.y = 0
	else:
		if pos.x < 0 or pos.x > screen_width or pos.y < 0 or pos.y > screen_height:
			emit_signal("wall_hit")
			_on_death()

func _on_death() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	for seg in tail_segments:
		seg.queue_free()
	tail_segments.clear()
	position_history.clear()
	get_parent().end_game()

func _on_food_eaten() -> void:
	$"..".score += 100
	grow()
	get_parent().spawn_food(get_all_positions())
