extends Panel

func _ready():
	Auth.auth_success.connect(_on_auth_success)
	Auth.auth_error.connect(_on_auth_error)

func _on_start_pressed() -> void:
	$Hosting.visible = true

func _on_auth_success(user):
	print("Logged in as ", user)

func _on_auth_error(message):
	$ErrorLabel.text = message

func _on_signin_but_pressed() -> void:
	Auth.sign_up($Signin/SigninUsername.text, $Signin/LineEdit2.text)

func _on_login_but_pressed() -> void:
	Auth.login($Login/LineEdit.text, $Login/LineEdit2.text)
