extends Panel

func _ready() -> void:
	if CharData.killers.is_empty() and CharData.survivors.is_empty():
		await CharData.data_loaded
	
	_populate_killers()
	_populate_survivors()
	_populate_emotes()

func _populate_killers() -> void:
	var grid = $Items/Killers/GridContainer
	_clear_grid(grid)
	
	for killer_id in CharData.killers:
		var killer = CharData.killers[killer_id]
		var item = _create_char_item(killer)
		grid.add_child(item)
		item.get_node("Button").pressed.connect(select_char_item.bind(item))

func _populate_survivors() -> void:
	var grid = $Items/Survivors/GridContainer
	_clear_grid(grid)
	
	for survivor_id in CharData.survivors:
		var survivor = CharData.survivors[survivor_id]
		var item = _create_char_item(survivor)
		grid.add_child(item)
		item.get_node("Button").pressed.connect(select_char_item.bind(item))

func _populate_emotes() -> void:
	var grid = $Items/Emotes/GridContainer
	_clear_grid(grid)
	
	for emote_name in EmoteData.Emotes:
		var emote = EmoteData.Emotes[emote_name]
		var item = _create_emote_item(emote_name, emote)
		grid.add_child(item)
		item.get_node("Button").pressed.connect(select_emote_item.bind(item))

func _create_char_item(char_data: Dictionary) -> Control:
	var item_scene = preload("res://UI/stuff/ShopButton.tscn")
	var item = item_scene.instantiate()
	
	item.get_node("ItemName").text = char_data.get("display_name", char_data.get("id", "???"))
	item.get_node("Price").text = "$ %d" % char_data.get("stats", {}).get("price", 0)
	
	var skins = char_data.get("skins", [])
	if not skins.is_empty():
		var thumb_path = skins[0].get("thumbnail", "")
		if thumb_path != "" and ResourceLoader.exists(thumb_path):
			item.get_node("Render").texture = load(thumb_path)
	
	return item

func _create_emote_item(emote_name: String, emote_data: Dictionary) -> Control:
	var item_scene = preload("res://UI/stuff/ShopButton.tscn")
	var item = item_scene.instantiate()
	
	item.get_node("ItemName").text = emote_name
	item.get_node("Price").text = "$ %d" % emote_data.get("Price", 0)
	
	if emote_data.get("Limited", false):
		item.get_node("LimitedBadge").visible = true
	
	return item

func select_char_item(item) -> void:
	$InfoPanel.visible = true
	$InfoPanel/CharName.text = item.get_node("ItemName").text
	$InfoPanel/Price.text = item.get_node("Price").text
	$InfoPanel/Render.texture = item.get_node("Render").texture

func select_emote_item(item) -> void:
	$InfoPanel.visible = true
	$InfoPanel/CharName.text = item.get_node("ItemName").text
	$InfoPanel/Price.text = item.get_node("Price").text
	$InfoPanel/Render.texture = null

func _clear_grid(grid: Node) -> void:
	for child in grid.get_children():
		child.queue_free()
