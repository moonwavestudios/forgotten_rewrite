extends Node2D

var grid_x = 3
var grid_y = 4
const CELL_SIZE = 30
var fall_timer: float = 0.0
const FALL_SPEED: float = 0.5 

var active_shape_name = ""
var current_shape_instance = null

var shapes = [
	preload("res://UI/stuff/tetris/square.tscn"),
]

func _ready():
	spawn_random_shape()

func spawn_random_shape():
	if current_shape_instance:
		current_shape_instance.queue_free()

	var chosen_scene = shapes[randi() % shapes.size()]
	current_shape_instance = chosen_scene.instantiate()
	add_child(current_shape_instance)

	update_shape_position()

func update_shape_position():
	if current_shape_instance:
		current_shape_instance.global_position = Vector2(
			grid_x * CELL_SIZE,
			grid_y * CELL_SIZE
		)

func _process(delta):
	fall_timer += delta
	if fall_timer >= FALL_SPEED and visible:
		fall_timer = 0.0
		if current_shape_instance != null:
			move_down()

func move_down():
	grid_y += 1
	update_shape_position()

func move_left():
	grid_x -= 1
	update_shape_position()

func move_right():
	grid_x += 1
	update_shape_position()
