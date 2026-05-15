extends Area3D

var owner_player
var hitboxes_scene
var effect = "slowness"
var effect_level = 1
var effect_duration = 1.0

var health = 10

var triggered := false

func _ready():
	add_to_group("beartraps")
	body_entered.connect(_on_body_entered)
	
func _process(delta: float) -> void:
	if health <= 0:
		queue_free()

func _on_body_entered(body):
	if triggered:
		return

	if body == owner_player:
		return

	if not ("is_Killer" in body):
		return

	if not body.is_Killer:
		return

	triggered = true
	
	var effect_comp = body.get_node_or_null("EffectComponent")
	if effect_comp:
		effect_comp.activate_effect(effect, effect_level, effect_duration)

	queue_free()
