extends Node2D

var grid_x = 3
var grid_y = 4
const CELL_SIZE = 30
var fall_timer: float = 0.0
const FALL_SPEED: float = 0.5 

func _process(delta):
	fall_timer += delta
	if fall_timer >= FALL_SPEED and $".".visible:
		fall_timer = 0.0
		move_down()
	
	position.x = grid_x * CELL_SIZE
	position.y = grid_y * CELL_SIZE

func move_left():
	grid_x -= 1   

func move_down():
	grid_y += 1  
