extends Panel

func _ready() -> void:
	for item in $Items/Killers/GridContainer.get_children():
		item.get_node('Button').pressed.connect(select_item.bind(item))

func select_item(item):
	$InfoPanel.visible = true
	$InfoPanel/CharName.text = item.get_node("ItemName").text
