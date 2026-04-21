extends Panel

func _on_killers_button_pressed() -> void:
	$Killers.visible = true
	$Survivors.visible = false
	$Emotes.visible = false


func _on_survivors_button_pressed() -> void:
	$Killers.visible = false
	$Survivors.visible = true
	$Emotes.visible = false


func _on_emotes_button_pressed() -> void:
	$Killers.visible = false
	$Survivors.visible = false
	$Emotes.visible = true
