extends CanvasLayer
var food = preload("res://scenes/food.tscn")
signal game_ended(final_score: int)
@export var screen_width: float = 1152.0
@export var screen_height: float = 648.0
@export var food_size: float = 20.0
var score = 0
var current_food: Node = null

@onready var player = get_parent()

func _ready() -> void:
	if not player.is_multiplayer_authority():
		process_mode = Node.PROCESS_MODE_DISABLED
		visible = false

func _process(_delta: float) -> void:
	$Label.text = "Score: " + str(score)

func spawn_food(snake_positions: Array = []) -> void:
	if current_food:
		current_food.queue_free()
	var pos: Vector2 = _find_valid_position(snake_positions)
	current_food = food.instantiate()
	add_child.call_deferred(current_food)
	await current_food.ready
	current_food.position = pos

func _find_valid_position(snake_positions: Array) -> Vector2:
	var margin := food_size
	var max_attempts := 50
	for _i in range(max_attempts):
		var candidate := Vector2(
			randf_range(margin, screen_width - margin),
			randf_range(margin, screen_height - margin)
		)
		if _is_clear(candidate, snake_positions):
			return candidate
	return Vector2(
		randf_range(margin, screen_width - margin),
		randf_range(margin, screen_height - margin)
	)

func _is_clear(candidate: Vector2, snake_positions: Array) -> bool:
	for seg_pos in snake_positions:
		if candidate.distance_to(seg_pos) < food_size * 2:
			return false
	return true

func end_game() -> void:
	if current_food:
		current_food.queue_free()
		current_food = null
	emit_signal("game_ended", score)

func _input(event: InputEvent) -> void:
	if not player.is_multiplayer_authority():
		return
	if event.is_action_pressed("ui_cancel") and visible:
		$TetrisTheme.stop()
		end_game()
		hide()
		player.current_speed = player.WALK_SPEED
