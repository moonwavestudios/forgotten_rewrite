extends Node

const XP_THRESHOLDS: Array[int] = [
	0,        # 0 (unused)
	0,        # 1
	500,      # 2
	1100,     # 3
	1800,     # 4
	2600,     # 5
	3500,     # 6
	4500,     # 7
	5600,     # 8
	6800,     # 9
	8100,     # 10
	9600,     # 11
	11200,    # 12
	12900,    # 13
	14700,    # 14
	16600,    # 15
	18600,    # 16
	20700,    # 17
	22900,    # 18
	25200,    # 19
	27600,    # 20
	30200,    # 21
	32900,    # 22
	35700,    # 23
	38600,    # 24
	41600,    # 25
	44700,    # 26
	47900,    # 27
	51200,    # 28
	54600,    # 29
	58100,    # 30
	62000,    # 31
	66100,    # 32
	70400,    # 33
	74900,    # 34
	79600,    # 35
	84500,    # 36
	89600,    # 37
	94900,    # 38
	100400,   # 39
	106100,   # 40
	112500,   # 41
	119200,   # 42
	126200,   # 43
	133500,   # 44
	141100,   # 45
	149000,   # 46
	157200,   # 47
	165700,   # 48
	174500,   # 49
	183600,   # 50
	193500,   # 51
	203800,   # 52
	214500,   # 53
	225600,   # 54
	237100,   # 55
	249000,   # 56
	261300,   # 57
	274000,   # 58
	287100,   # 59
	300600,   # 60
	315000,   # 61
	329900,   # 62
	345300,   # 63
	361200,   # 64
	377600,   # 65
	394500,   # 66
	411900,   # 67
	429800,   # 68
	448200,   # 69
	467100,   # 70
	487000,   # 71
	507400,   # 72
	528300,   # 73
	549700,   # 74
	571600,   # 75
	594500,   # 76
	617900,   # 77
	641800,   # 78
	666200,   # 79
	691100,   # 80
	717500,   # 81
	744900,   # 82
	772800,   # 83
	801200,   # 84
	830100,   # 85
	860500,   # 86
	891900,   # 87
	923800,   # 88
	956200,   # 89
	989100,   # 90
	1023500,  # 91
	1059400,  # 92
	1096800,  # 93
	1135700,  # 94
	1176100,  # 95
	1218000,  # 96
	1261400,  # 97
	1306300,  # 98
	1352700,  # 99
	1400600,  # 100
]

const MAX_LEVEL: int = 100

func get_level(total_xp: int) -> int:
	var level := 1
	for i in range(2, XP_THRESHOLDS.size()):
		if total_xp >= XP_THRESHOLDS[i]:
			level = i
		else:
			break
	return min(level, MAX_LEVEL)

func get_xp_in_level(total_xp: int) -> int:
	var level := get_level(total_xp)
	if level >= MAX_LEVEL:
		return 0
	return total_xp - XP_THRESHOLDS[level]

func get_xp_to_next_level(total_xp: int) -> int:
	var level := get_level(total_xp)
	if level >= MAX_LEVEL:
		return 0
	return XP_THRESHOLDS[level + 1] - XP_THRESHOLDS[level]

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
