extends Node2D

var grid_x = 6.52
var grid_y = 6.52
const CELL_SIZE = 32
const GRID_ORIGIN = Vector2(350, 67)
const GRID_WIDTH = 16
const GRID_HEIGHT = 18

var fall_timer: float = 0.0
const FALL_SPEED: float = 0.5

var current_shape_instance = null
var locked_cells: Dictionary = {}
var next_piece = ""

var shape_definitions = {
	"square": [
		[Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)],
		[Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)],
		[Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)],
		[Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)],
	],
	"I": [
		[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0)],
		[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(0,3)],
		[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0)],
		[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(0,3)],
	],
	"T": [
		[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1)],
		[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(-1,1)],
		[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,-1)],
		[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(1,1)],
	],
	"L": [
		[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(1,2)],
		[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1)],
		[Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(1,2)],
		[Vector2i(0,1), Vector2i(1,1), Vector2i(2,0), Vector2i(2,1)],
	],
	"S": [
		[Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1)],
		[Vector2i(0,0), Vector2i(0,1), Vector2i(1,1), Vector2i(1,2)],
		[Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1)],
		[Vector2i(0,0), Vector2i(0,1), Vector2i(1,1), Vector2i(1,2)],
	],
}

var current_shape_key: String = "square"
var current_rotation: int = 0  # 0–3

var shapes = [
	preload("res://UI/stuff/tetris/square.tscn"),
]

func _ready():
	spawn_random_shape()

func spawn_random_shape():
	# Pick a random shape key
	var keys = shape_definitions.keys()
	current_shape_key = keys[randi() % keys.size()]
	current_rotation = 0

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

func lock_shape():
	for cell in get_shape_cells(grid_x, grid_y):
		locked_cells[cell] = true
	queue_redraw()
	current_shape_instance = null
	spawn_random_shape()

func get_shape_cells(ox: int, oy: int) -> Array:
	return get_shape_cells_for(ox, oy, current_shape_key, current_rotation)

func get_shape_cells_for(ox: int, oy: int, shape_key: String, rotationd: int) -> Array:
	var offsets = shape_definitions[shape_key][rotationd]
	var cells = []
	for offset in offsets:
		cells.append(Vector2i(ox + offset.x, oy + offset.y))
	return cells

func can_move(new_x: int, new_y: int) -> bool:
	return can_move_with_rotation(new_x, new_y, current_rotation)

func can_move_with_rotation(new_x: int, new_y: int, rotationd: int) -> bool:
	for cell in get_shape_cells_for(new_x, new_y, current_shape_key, rotationd):
		if cell.x < 0 or cell.x >= GRID_WIDTH:
			return false
		if cell.y >= GRID_HEIGHT:
			return false
		if locked_cells.has(cell):
			return false
	return true

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_left"):
		move_left()
	if Input.is_action_just_pressed("ui_right"):
		move_right()
	if Input.is_action_just_pressed("RotateTetris"):
		rotate_shape()

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

func rotate_shape():
	var next_rotation = (current_rotation + 1) % 4

	if can_move_with_rotation(grid_x, grid_y, next_rotation):
		current_rotation = next_rotation
		current_shape_instance.rotation_degrees = next_rotation * 90
		return

	for kick in [1, -1, 2, -2]:
		if can_move_with_rotation(grid_x + kick, grid_y, next_rotation):
			grid_x += kick
			current_rotation = next_rotation
			current_shape_instance.rotation_degrees = next_rotation * 90
			update_shape_position()
			return
