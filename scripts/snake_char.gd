extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@export var screen_width: float = 1152.0
@export var screen_height: float = 648.0
@export var wrap_around: bool = false  # false = die on wall hit

signal wall_hit

var current_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	get_parent().spawn_food()
	
	if $"..".visible:
		velocity = current_direction * SPEED

func _input(event: InputEvent) -> void:
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
	move_and_slide()
	_handle_wall_collision()

func _handle_wall_collision() -> void:
	var pos = global_position

	if wrap_around:
		if pos.x < 0:
			global_position.x = screen_width
		elif pos.x > screen_width:
			global_position.x = 0

		if pos.y < 0:
			global_position.y = screen_height
		elif pos.y > screen_height:
			global_position.y = 0
	else:
		if pos.x < 0 or pos.x > screen_width or pos.y < 0 or pos.y > screen_height:
			emit_signal("wall_hit")
			_on_death()

func _on_death() -> void:
	velocity = Vector2.ZERO
	set_physics_process(false)
	
func _on_food_eaten() -> void:
	$"..".score += 100
	get_parent().spawn_food()
