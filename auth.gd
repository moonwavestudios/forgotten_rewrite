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

func _get_http() -> HTTPRequest:
	var http = HTTPRequest.new()
	add_child(http)
	return http

func _get_headers() -> Array:
	return [
		"Content-Type: application/json",
		"apikey: " + anon_key
	]

func sign_up(username: String, password: String):
	var http = _get_http()
	var email = username.to_lower() + FAKE_DOMAIN
	var body = JSON.stringify({"email": email, "password": password})
	http.request_completed.connect(_on_sign_up_completed.bind(http))
	http.request(SUPABASE_URL + "/auth/v1/signup", _get_headers(), HTTPClient.METHOD_POST, body)

func login(username: String, password: String):
	var http = _get_http()
	var email = username.to_lower() + FAKE_DOMAIN
	var body = JSON.stringify({"email": email, "password": password})
	http.request_completed.connect(_on_login_completed.bind(http))
	http.request(SUPABASE_URL + "/auth/v1/token?grant_type=password", _get_headers(), HTTPClient.METHOD_POST, body)

func logout():
	access_token = ""
	current_user = {}

func is_logged_in() -> bool:
	return access_token != ""

func _on_sign_up_completed(result, response_code, headers, body, http: HTTPRequest):
	http.queue_free()
	var json = JSON.parse_string(body.get_string_from_utf8())
	if response_code == 200:
		access_token = json.get("access_token", "")
		current_user = json.get("user", {})
		auth_success.emit(current_user)
	else:
		var msg = json.get("msg", json.get("message", "Sign up failed"))
		auth_error.emit(msg)

func _on_login_completed(result, response_code, headers, body, http: HTTPRequest):
	http.queue_free()
	var json = JSON.parse_string(body.get_string_from_utf8())
	if response_code == 200:
		access_token = json.get("access_token", "")
		current_user = json.get("user", {})
		auth_success.emit(current_user)
	else:
		var msg = json.get("msg", json.get("message", "Login failed"))
		auth_error.emit(msg)
