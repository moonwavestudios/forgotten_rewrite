extends Node2D

var grid_x = 3
var grid_y = 4
const CELL_SIZE = 32
const GRID_ORIGIN = Vector2(350, 67)
const GRID_WIDTH = 16   
const GRID_HEIGHT = 20 

var fall_timer: float = 0.0
const FALL_SPEED: float = 0.5
var current_shape_instance = null

var locked_cells: Dictionary = {}

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
	grid_x = 3
	grid_y = 0
	update_shape_position()

func update_shape_position():
	if current_shape_instance:
		current_shape_instance.position = Vector2(
			GRID_ORIGIN.x + grid_x * CELL_SIZE,
			GRID_ORIGIN.y + grid_y * CELL_SIZE
		)

func get_shape_cells(ox: int, oy: int) -> Array:
	return [
		Vector2i(ox,     oy),
		Vector2i(ox + 1, oy),
		Vector2i(ox,     oy + 1),
		Vector2i(ox + 1, oy + 1),
	]

func can_move(new_x: int, new_y: int) -> bool:
	for cell in get_shape_cells(new_x, new_y):
		
		if cell.x < 0 or cell.x >= GRID_WIDTH:
			return false
		
		if cell.y >= GRID_HEIGHT:
			return false
		
		if locked_cells.has(cell):
			return false
	return true

func lock_shape():
	
	for cell in get_shape_cells(grid_x, grid_y):
		locked_cells[cell] = true
	# TODO: check for completed rows here nyaa~
	spawn_random_shape()

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_left"):
		move_left()
	if Input.is_action_just_pressed("ui_right"):
		move_right()

func _process(delta):
	fall_timer += delta
	if fall_timer >= FALL_SPEED and visible:
		fall_timer = 0.0
		if current_shape_instance != null:
			move_down()

func move_down():
	if can_move(grid_x, grid_y + 1):
		grid_y += 1
		update_shape_position()
	else:
		lock_shape()

func move_left():
	if can_move(grid_x - 1, grid_y):
		grid_x -= 1
		update_shape_position()

func move_right():
	if can_move(grid_x + 1, grid_y):
		grid_x += 1
		update_shape_position()
