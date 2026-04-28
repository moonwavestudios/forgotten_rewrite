extends Area2D

func _on_body_entered(body: CharacterBody2D) -> void:
	body._on_food_eaten()
	queue_free()
