extends StaticBody3D

func _ready() -> void:
	$ProximityPrompt.prompt_triggered.connect(_on_interacted)

func _on_interacted(interactor: Node) -> void:
	var snake = interactor.get_node("snake")
	snake.show()
	interactor.get_node("snake/TetrisTheme").play()
	interactor.current_speed = 0
