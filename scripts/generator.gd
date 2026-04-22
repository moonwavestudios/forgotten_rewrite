extends StaticBody3D

func _ready() -> void:
	$ProximityPrompt.prompt_triggered.connect(_on_interacted)

func _on_interacted(_interactor: Node) -> void:
	print("gen")
