# tail_segment.gd
extends Node2D

func setup(seg_size: float, color: Color) -> void:
	var rect = ColorRect.new()
	rect.size = Vector2(seg_size, seg_size)
	rect.position = Vector2(-seg_size / 2, -seg_size / 2)  # center it
	rect.color = color
	add_child(rect)
