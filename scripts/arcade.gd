extends StaticBody3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ProximityPrompt.prompt_triggered.connect(_on_interacted)

func _on_interacted(interactor: Node) -> void:
	interactor.get_node("player_ui/SpectatorStuff/tetris").visible = true
