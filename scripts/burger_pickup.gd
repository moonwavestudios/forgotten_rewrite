extends Area3D

var heal_amount: int = 25
var owner_player: Node = null

func _on_body_entered(body):
	if "is_Killer" in body and not body.is_Killer:
		body.health = min(body.health + heal_amount, body.maxhealth)
		var ability_comp = owner_player.get_node_or_null("AbilityComponent")
		if ability_comp:
			ability_comp._activate_ability({"type": "rush_hour"})
		queue_free()
