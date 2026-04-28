extends StaticBody3D

func _ready() -> void:
	$ProximityPrompt.prompt_triggered.connect(_on_interacted)

func _on_interacted(interactor: Node) -> void:
	var snake = interactor.get_node("snake")
	snake.show()
	interactor.get_node("snake/TetrisTheme").play()
	interactor.current_speed = 0
	snake.visibility_changed.connect(_on_visibility_changed.bind(snake), CONNECT_ONE_SHOT)

func _on_visibility_changed(snake: Node) -> void:
	if not snake.visible:
		$ProximityPrompt.reset_activations()
