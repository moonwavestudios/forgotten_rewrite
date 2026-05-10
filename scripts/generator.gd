extends StaticBody3D

@onready var main = $"../../.."

func _ready() -> void:
	$ProximityPrompt.prompt_triggered.connect(_on_interacted)

func _on_interacted(interactor: Node) -> void:
	var puzzle = interactor.get_node("player_ui/GameStuff/GeneratorPuzzle")
	var minigame = puzzle.get_node("HitCircleLayer")
	
	puzzle.visible = true
	minigame.start()
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	interactor.move_cam = false
	interactor.current_speed = 0
	
	if not minigame.minigame_completed.is_connected(_on_puzzle_completed):
		minigame.minigame_completed.connect(_on_puzzle_completed)

func _on_puzzle_completed() -> void:
	$ProximityPrompt.set_enabled(false)
