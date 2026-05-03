extends StaticBody3D

func _ready() -> void:
	$ProximityPrompt.prompt_triggered.connect(_on_interacted)

func _on_interacted(interactor: Node) -> void:
	interactor.get_node("player_ui/GameStuff/GeneratorPuzzle").visible = true
	interactor.get_node("player_ui/GameStuff/GeneratorPuzzle/HitCircleLayer").start()
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
