extends Node

const MAX_LEVEL: int = 100

func xp_threshold(level: int) -> int:
	if level <= 1:
		return 0
	var l := level - 1
	return int(50.0 * l * l + 450.0 * l)

func get_level(total_xp: int) -> int:
	if total_xp <= 0:
		return 1
	var l := int((-450.0 + sqrt(450.0 * 450.0 + 4.0 * 50.0 * float(total_xp))) / (2.0 * 50.0))
	return clampi(l + 1, 1, MAX_LEVEL)

func get_xp_in_level(total_xp: int) -> int:
	var level := get_level(total_xp)
	if level >= MAX_LEVEL:
		return 0
	return total_xp - xp_threshold(level)

func get_xp_to_next_level(total_xp: int) -> int:
	var level := get_level(total_xp)
	if level >= MAX_LEVEL:
		return 0
	return xp_threshold(level + 1) - xp_threshold(level)

func get_level_progress(total_xp: int) -> float:
	var level := get_level(total_xp)
	if level >= MAX_LEVEL:
		return 1.0
	var xp_in  := get_xp_in_level(total_xp)
	var xp_for := get_xp_to_next_level(total_xp)
	if xp_for <= 0:
		return 1.0
	return clampf(float(xp_in) / float(xp_for), 0.0, 1.0)

func get_level_info(total_xp: int) -> Dictionary:
	var level := get_level(total_xp)
	return {
		"level":       level,
		"xp_in_level": get_xp_in_level(total_xp),
		"xp_to_next":  get_xp_to_next_level(total_xp),
		"progress":    get_level_progress(total_xp),
		"is_max":      level >= MAX_LEVEL,
	}
