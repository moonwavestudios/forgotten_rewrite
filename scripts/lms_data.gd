extends Node

var courses: Dictionary = {}

func _ready() -> void:
	_load_all_json()

func _load_all_json() -> void:
	var dir := DirAccess.open("res://assets/LMS_Data")
	if dir == null:
		push_error("LMSData: Could not open 'res://assets/LMS_Data'. Error: %s" % error_string(DirAccess.get_open_error()))
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			_load_json_file("res://assets/LMS_Data/" + file_name)
		file_name = dir.get_next()

	dir.list_dir_end()

func _load_json_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("LMSData: Could not open file '%s'. Error: %s" % [path, error_string(FileAccess.get_open_error())])
		return

	var raw := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(raw)
	if parsed == null:
		push_error("LMSData: Failed to parse JSON in '%s'." % path)
		return

	var key := path.get_file().get_basename().to_lower()
	courses[key] = parsed

func get_course(key: String) -> Dictionary:
	var k := key.to_lower()
	if not courses.has(k):
		push_warning("LMSData: No course found for key '%s'." % k)
		return {}
	return courses[k]

func get_title(key: String) -> String:
	return get_course(key).get("Title", "")

func get_author(key: String) -> String:
	return get_course(key).get("Author", "")

func get_all_courses() -> Array:
	return courses.values()

func get_all_keys() -> Array:
	return courses.keys()

func has_course(key: String) -> bool:
	return courses.has(key.to_lower())
