extends Panel

func _ready() -> void:
	#for item in $Items/Killers/GridContainer.get_children():
		#item.get_node('Button').pressed.connect(select_item.bind(item))
	if CharData.killers.is_empty():
		await CharData.data_loaded
	
	_populate_killers()

func _populate_killers() -> void:
	var grid = $Items/Killers/GridContainer
	
	for child in grid.get_children():
		child.queue_free()
	
	for killer_id in CharData.killers:
		var killer = CharData.killers[killer_id]
		var item = _create_killer_item(killer)
		grid.add_child(item)
		item.get_node("Button").pressed.connect(select_item.bind(item))

func _create_killer_item(killer: Dictionary) -> Control:
	var item_scene = preload("res://UI/stuff/ShopButton.tscn")
	var item = item_scene.instantiate()
	
	item.get_node("ItemName").text = killer.get("display_name", killer["id"])
	item.get_node("Price").text = "$ %d" % killer.get("stats", {}).get("price", 0)
	
	var skins = killer.get("skins", [])
	if not skins.is_empty():
		var thumb_path = skins[0].get("thumbnail", "")
		if thumb_path != "" and ResourceLoader.exists(thumb_path):
			item.get_node("Render").texture = load(thumb_path)
	
	return item

func select_item(item):
	$InfoPanel.visible = true
	$InfoPanel/CharName.text = item.get_node("ItemName").text
	$InfoPanel/Price.text = item.get_node("Price").text
	$InfoPanel/Render.texture = item.get_node("Render").texture
