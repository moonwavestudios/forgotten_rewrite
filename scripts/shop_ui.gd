extends Panel

func _on_killers_button_pressed() -> void:
	$Killers.visible = true
	$Survivors.visible = false
	$Emotes.visible = false
