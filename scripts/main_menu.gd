extends Panel

func _ready():
	Auth.auth_success.connect(_on_auth_success)
	Auth.auth_error.connect(_on_auth_error)

func _on_start_pressed() -> void:
	$Hosting.visible = true

func _on_auth_success(user):
	var email = user.get("email", "player@fuckyou.com")
	$"../../..".name = email.replace("@fuckyou.com", "")
	$Username.text = email.replace("@fuckyou.com", "")
	$Login.visible = false
	$Signin.visible = false
	
	$SigninButton.visible = false
	$LoginButton.visible = false

func _on_auth_error(message):
	$Signin/Label.text = message

func _on_signin_but_pressed() -> void:
	Auth.sign_up($Signin/SigninUsername.text, $Signin/LineEdit2.text)
	$SigninButton.visible = false
	$LoginButton.visible = false

func _on_login_but_pressed() -> void:
	Auth.login($Login/LineEdit.text, $Login/LineEdit2.text)
	$LoginButton.visible = false
	$SigninButton.visible = false

func _on_host_pressed() -> void:
	$"../Hosting".visible = true
	$".".visible = false
