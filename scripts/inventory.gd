extends Panel

var _selected_char_data: Dictionary = {}
var _selected_skin_data: Dictionary = {}
var _selected_type: String = "" 

func _ready() -> void:
	if CharData.killers.is_empty() and CharData.survivors.is_empty():
		await CharData.data_loaded

	_populate_characters()

func _populate_characters() -> void:
	var grid = $Items/Characters/GridContainer
	_clear_grid(grid)

	var owned: Array = save_data.get_owned_characters()

	for char_id in CharData.killers:
		var char_data = CharData.killers[char_id]
		var price = char_data.get("stats", {}).get("price", 0)
		if price == 0 or char_id in owned:
			_add_char_item(grid, char_data)

	for char_id in CharData.survivors:
		var char_data = CharData.survivors[char_id]
		var price = char_data.get("stats", {}).get("price", 0)
		if price == 0 or char_id in owned:
			_add_char_item(grid, char_data)

func _add_char_item(grid: Node, char_data: Dictionary) -> void:
	var item = _create_char_item(char_data)
	grid.add_child(item)
	item.get_node("Button").pressed.connect(_on_char_selected.bind(item))

func _populate_skins_panel(char_data: Dictionary) -> void:
	var grid = $SkinsPanel/ScrollContainer/GridContainer
	_clear_grid(grid)

	var char_id   = char_data.get("id", "")
	var char_type = "killer" if CharData.killers.has(char_id) else "survivor"
	var skins: Array = char_data.get("skins", [])
	var equipped_skin = save_data.get_equipped_skin(char_id)

	for skin in skins:
		var skin_id = skin.get("id", "")
		var is_owned = save_data.has_skin(char_id, skin_id)
		if not is_owned:
			continue

		var item_scene = preload("res://UI/stuff/ShopButton.tscn")
		var item = item_scene.instantiate()

		item.get_node("ItemName").text = skin.get("display_name", skin.get("id", "???"))

		if skin_id == equipped_skin:
			item.get_node("Price").text = "✓ Equipped"
		else:
			item.get_node("Price").text = "Equip"

		var thumb_path = skin.get("thumbnail", "")
		if thumb_path != "" and ResourceLoader.exists(thumb_path):
			item.get_node("Render").texture = load(thumb_path)

		item.set_meta("skin_data", skin)
		item.set_meta("char_id", char_id)
		item.get_node("Button").pressed.connect(_on_skin_selected.bind(item))

		grid.add_child(item)

func _create_char_item(char_data: Dictionary) -> Control:
	var item_scene = preload("res://UI/stuff/ShopButton.tscn")
	var item = item_scene.instantiate()

	item.get_node("ItemName").text = char_data.get("display_name", char_data.get("id", "???"))

	var char_id      = char_data.get("id", "")
	var char_type    = "killer" if CharData.killers.has(char_id) else "survivor"
	var equipped_skin = save_data.get_equipped_skin(char_id)
	item.get_node("Price").text = "Skin: " + equipped_skin

	var skins: Array = char_data.get("skins", [])
	if not skins.is_empty():
		var thumb_path = skins[0].get("thumbnail", "")
		if thumb_path != "" and ResourceLoader.exists(thumb_path):
			item.get_node("Render").texture = load(thumb_path)

	item.set_meta("char_data", char_data)
	return item

func _on_char_selected(item) -> void:
	_selected_char_data = item.get_meta("char_data", {})
	_selected_type = "char"

	$InfoPanel.visible = true
	$InfoPanel/CharName.text = item.get_node("ItemName").text
	$InfoPanel/Price.text    = item.get_node("Price").text
	$InfoPanel/Render.texture = item.get_node("Render").texture

	_refresh_equip_button()

func _on_skin_selected(item) -> void:
	_selected_skin_data = item.get_meta("skin_data", {})
	_selected_type = "skin"

	$InfoPanel/CharName.text  = item.get_node("ItemName").text
	$InfoPanel/Price.text     = item.get_node("Price").text
	$InfoPanel/Render.texture = item.get_node("Render").texture

	_refresh_equip_button()

func _refresh_equip_button() -> void:
	var equip_btn = $InfoPanel/EquipButton
	if equip_btn == null:
		return

	match _selected_type:
		"char":
			equip_btn.disabled = true
			equip_btn.text = "Choose a skin"
		"skin":
			var char_id = _selected_char_data.get("id", "")
			var skin_id = _selected_skin_data.get("id", "")
			var currently_equipped = save_data.get_equipped_skin(char_id)
			var already = (skin_id == currently_equipped)
			equip_btn.disabled = already
			equip_btn.text = "Equipped" if already else "Equip"
		_:
			equip_btn.disabled = true
			equip_btn.text = "Equip"

func _on_equip_button_pressed() -> void:
	if _selected_type != "skin":
		return

	var char_id = _selected_char_data.get("id", "")
	var skin_id = _selected_skin_data.get("id", "")
	if char_id == "" or skin_id == "":
		return

	save_data.set_equipped_skin(char_id, skin_id)

	var player = get_tree().get_first_node_in_group("players")
	if player != null:
		var player_char = player.equipped_killer if player.is_Killer else player.equipped_survivor
		if player_char == char_id:
			player.apply_skin(skin_id)

	_populate_skins_panel(_selected_char_data)
	_refresh_equip_button()
	_populate_characters()   

func _on_skins_button_pressed() -> void:
	if _selected_char_data.is_empty():
		return
	_populate_skins_panel(_selected_char_data)
	$SkinsPanel.visible = not $SkinsPanel.visible
	$Items.visible      = not $Items.visible

func _clear_grid(grid: Node) -> void:
	for child in grid.get_children():
		child.queue_free()
