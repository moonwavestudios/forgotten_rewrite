extends Node
const SUPABASE_URL = "https://wdfhltbmlruyeirbyiku.supabase.co"
const FAKE_DOMAIN = "@fuckyou.com"
var anon_key: String = ""
var access_token: String = ""
var current_user: Dictionary = {}
signal auth_success(user: Dictionary)
signal auth_error(message: String)

func _ready():
	var file = FileAccess.open("res://key.txt", FileAccess.READ)
	if file:
		anon_key = file.get_as_text().strip_edges()
		file.close()
	else:
		push_error("Could not load key.txt")
	_try_auto_login()

func _get_http() -> HTTPRequest:
	var http = HTTPRequest.new()
	add_child(http)
	return http

func _get_headers() -> Array:
	return [
		"Content-Type: application/json",
		"apikey: " + anon_key
	]

func _save_credentials(username: String, password: String) -> void:
	var data = save_data._load_all()
	data["saved_username"] = username
	data["saved_password"] = password
	save_data._save_all(data)

func _load_credentials() -> Dictionary:
	var data = save_data._load_all()
	return {
		"username": data.get("saved_username", ""),
		"password": data.get("saved_password", "")
	}

func _clear_credentials() -> void:
	var data = save_data._load_all()
	data.erase("saved_username")
	data.erase("saved_password")
	save_data._save_all(data)

func _try_auto_login() -> void:
	var creds = _load_credentials()
	if creds["username"] != "" and creds["password"] != "":
		login(creds["username"], creds["password"])

func sign_up(username: String, password: String):
	var http = _get_http()
	var email = username.to_lower() + FAKE_DOMAIN
	var body = JSON.stringify({"email": email, "password": password})
	http.request_completed.connect(_on_sign_up_completed.bind(http, username, password))
	http.request(SUPABASE_URL + "/auth/v1/signup", _get_headers(), HTTPClient.METHOD_POST, body)

func login(username: String, password: String):
	var http = _get_http()
	var email = username.to_lower() + FAKE_DOMAIN
	var body = JSON.stringify({"email": email, "password": password})
	http.request_completed.connect(_on_login_completed.bind(http, username, password))
	http.request(SUPABASE_URL + "/auth/v1/token?grant_type=password", _get_headers(), HTTPClient.METHOD_POST, body)

func logout():
	access_token = ""
	current_user = {}
	_clear_credentials()

func is_logged_in() -> bool:
	return access_token != ""

func _on_sign_up_completed(result, response_code, headers, body, http: HTTPRequest, username: String, password: String):
	http.queue_free()
	var json = JSON.parse_string(body.get_string_from_utf8())
	if response_code == 200:
		access_token = json.get("access_token", "")
		current_user = json.get("user", {})
		_save_credentials(username, password)
		auth_success.emit(current_user)
	else:
		var msg = json.get("msg", json.get("message", "Sign up failed"))
		auth_error.emit(msg)
	
func _on_login_completed(result, response_code, headers, body, http: HTTPRequest, username: String, password: String):
	http.queue_free()
	var json = JSON.parse_string(body.get_string_from_utf8())
	if response_code == 200:
		access_token = json.get("access_token", "")
		current_user = json.get("user", {})
		_save_credentials(username, password)
		auth_success.emit(current_user)
	else:
		_clear_credentials()
		var msg = json.get("msg", json.get("message", "Login failed"))
		auth_error.emit(msg)
