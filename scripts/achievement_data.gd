extends Node

class Achievement:
	var id: String
	var title: String
	var description: String
	var category: String
	var difficulty: String
	var hidden: bool
	var conditions: Dictionary
	var reward: Dictionary
	var is_unlocked: bool = false

	func _init(data: Dictionary) -> void:
		id          = data.get("id", "")
		title       = data.get("title", "")
		description = data.get("description", "")
		category    = data.get("category", "")
		difficulty  = data.get("difficulty", "")
		hidden      = data.get("hidden", false)
		conditions  = data.get("conditions", {})
		reward      = data.get("reward", {})

	func get_info() -> String:
		return "[%s] %s (%s/%s) - Unlocked: %s" % [id, title, category, difficulty, is_unlocked]


signal achievement_unlocked(achievement: Achievement)
signal achievements_loaded(count: int)


const ACHIEVEMENTS_PATH := "res://achievements.json"
const SAVE_PATH         := "user://achievements_save.json"

var _achievements: Dictionary = {}


func _ready() -> void:
	load_achievements()
	load_progress()


func get_all(category: String = "") -> Array[Achievement]:
	var result: Array[Achievement] = []
	for ach in _achievements.values():
		if category == "" or ach.category == category:
			result.append(ach)
	return result


func get_by_id(id: String) -> Achievement:
	return _achievements.get(id, null)


func unlock(id: String) -> bool:
	var ach: Achievement = get_by_id(id)
	if ach == null:
		push_warning("AchievementManager: unknown id '%s'" % id)
		return false
	if ach.is_unlocked:
		return false

	ach.is_unlocked = true
	save_progress()
	achievement_unlocked.emit(ach)
	print("🏆 Achievement unlocked: ", ach.title)
	return true

func notify_event(type: String, amount: int = 1) -> void:
	for ach in _achievements.values():
		if ach.is_unlocked:
			continue
		var cond: Dictionary = ach.conditions
		if cond.get("type", "") == type:
			var required: int = cond.get("count", 1)
			if amount >= required:
				unlock(ach.id)

func load_achievements() -> void:
	var file := FileAccess.open(ACHIEVEMENTS_PATH, FileAccess.READ)
	if file == null:
		push_error("AchievementManager: cannot open '%s'" % ACHIEVEMENTS_PATH)
		return

	var json  := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()

	if error != OK:
		push_error("AchievementManager: JSON parse error – %s" % json.get_error_message())
		return

	var root: Variant = json.data
	if typeof(root) != TYPE_DICTIONARY:
		push_error("AchievementManager: unexpected JSON root type")
		return

	var list: Array = (
		root
		.get("achievement_system", {})
		.get("achievements", [])
	)

	_achievements.clear()
	for entry in list:
		var ach := Achievement.new(entry)
		_achievements[ach.id] = ach

	achievements_loaded.emit(_achievements.size())
	print("AchievementManager: loaded %d achievement(s)" % _achievements.size())


func save_progress() -> void:
	var unlocked_ids: Array[String] = []
	for ach in _achievements.values():
		if ach.is_unlocked:
			unlocked_ids.append(ach.id)

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("AchievementManager: cannot write save file")
		return

	file.store_string(JSON.stringify({"unlocked": unlocked_ids}))
	file.close()


func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return

	var json  := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()

	if error != OK:
		push_warning("AchievementManager: could not parse save – progress reset")
		return

	var unlocked: Array = json.data.get("unlocked", [])
	for id in unlocked:
		var ach: Achievement = get_by_id(id)
		if ach:
			ach.is_unlocked = true

	print("AchievementManager: restored %d unlocked achievement(s)" % unlocked.size())
