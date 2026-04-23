extends Panel

var _selected_char_data: Dictionary = {}
var _selected_skin_data: Dictionary = {}
var _selected_type: String = ""

func _ready() -> void:
	if CharData.killers.is_empty() and CharData.survivors.is_empty():
		await CharData.data_loaded

	_populate_killers()
	_populate_survivors()
	_populate_emotes()

func _populate_killers() -> void:
	var grid = $Items/Killers/GridContainer
	_clear_grid(grid)

	var owned: Array = save_data.get_owned_characters()

	for killer_id in CharData.killers:
		var killer = CharData.killers[killer_id]
		var price  = killer.get("stats", {}).get("price", 0)
		if price == 0 or killer_id in owned:
			var item = _create_char_item(killer)
			grid.add_child(item)
			item.get_node("Button").pressed.connect(_on_char_selected.bind(item))

func _populate_survivors() -> void:
	var grid = $Items/Survivors/GridContainer
	_clear_grid(grid)

	var owned: Array = save_data.get_owned_characters()

	for survivor_id in CharData.survivors:
		var survivor = CharData.survivors[survivor_id]
		var price    = survivor.get("stats", {}).get("price", 0)
		if price == 0 or survivor_id in owned:
			var item = _create_char_item(survivor)
			grid.add_child(item)
			item.get_node("Button").pressed.connect(_on_char_selected.bind(item))

func _populate_emotes() -> void:
	var grid = $Items/Emotes/GridContainer
	_clear_grid(grid)

	var player = get_tree().get_first_node_in_group("players")
	var equipped_emotes: Array = player.equipped_emotes if player != null else []

	for emote_name in EmoteData.Emotes:
		var emote = EmoteData.Emotes[emote_name]
		if not EmoteData.is_unlocked(emote_name, equipped_emotes):
			continue
		var item = _create_emote_item(emote_name, emote)
		grid.add_child(item)
		item.get_node("Button").pressed.connect(_on_emote_selected.bind(item))

func _populate_skins_panel(char_data: Dictionary) -> void:
	var grid = $SkinsPanel/ScrollContainer/GridContainer
	_clear_grid(grid)

	var char_id       = char_data.get("id", "")
	var equipped_skin = save_data.get_equipped_skin(char_id)
	var skins: Array  = char_data.get("skins", [])

	for skin in skins:
		var skin_id = skin.get("id", "")
		if not save_data.has_skin(char_id, skin_id):
			continue

		var item_scene = preload("res://UI/stuff/ShopButton.tscn")
		var item = item_scene.instantiate()

		item.get_node("ItemName").text = skin.get("display_name", skin.get("id", "???"))
		item.get_node("Price").text    = "✓ Equipped" if skin_id == equipped_skin else "Equip"

		var thumb_path = skin.get("thumbnail", "")
		if thumb_path != "" and ResourceLoader.exists(thumb_path):
			item.get_node("Render").texture = load(thumb_path)

		item.set_meta("skin_data", skin)
		item.get_node("Button").pressed.connect(_on_skin_selected.bind(item))

		grid.add_child(item)

func _create_char_item(char_data: Dictionary) -> Control:
	var item_scene = preload("res://UI/stuff/ShopButton.tscn")
	var item = item_scene.instantiate()

	var char_id       = char_data.get("id", "")
	var equipped_skin = save_data.get_equipped_skin(char_id)

	item.get_node("ItemName").text = char_data.get("display_name", char_data.get("id", "???"))
	item.get_node("Price").text    = "Skin: " + equipped_skin

	var skins: Array = char_data.get("skins", [])
	if not skins.is_empty():
		var thumb_path = skins[0].get("thumbnail", "")
		if thumb_path != "" and ResourceLoader.exists(thumb_path):
			item.get_node("Render").texture = load(thumb_path)

	item.set_meta("char_data", char_data)
	return item

func _create_emote_item(emote_name: String, emote_data: Dictionary) -> Control:
	var item_scene = preload("res://UI/stuff/ShopButton.tscn")
	var item = item_scene.instantiate()

	item.get_node("ItemName").text = emote_name
	item.get_node("Price").text    = "Owned"

	item.set_meta("emote_name", emote_name)
	return item

func _on_char_selected(item) -> void:
	_selected_char_data = item.get_meta("char_data", {})
	_selected_skin_data = {}
	_selected_type      = "char"

	$InfoPanel.visible        = true
	$InfoPanel/CharName.text  = item.get_node("ItemName").text
	$InfoPanel/Price.text     = item.get_node("Price").text
	$InfoPanel/Render.texture = item.get_node("Render").texture

	_refresh_equip_button()

func _on_skin_selected(item) -> void:
	_selected_skin_data = item.get_meta("skin_data", {})
	_selected_type      = "skin"

	$InfoPanel/CharName.text  = item.get_node("ItemName").text
	$InfoPanel/Price.text     = item.get_node("Price").text
	$InfoPanel/Render.texture = item.get_node("Render").texture

	_refresh_equip_button()

func _on_emote_selected(item) -> void:
	_selected_type = "emote"

	$InfoPanel.visible        = true
	$InfoPanel/CharName.text  = item.get_node("ItemName").text
	$InfoPanel/Price.text     = "Owned"
	$InfoPanel/Render.texture = null

	_refresh_equip_button()

func _refresh_equip_button() -> void:
	var equip_btn = $InfoPanel/EquipButton
	if equip_btn == null:
		return

	match _selected_type:
		"char":
			equip_btn.disabled = true
			equip_btn.text     = "Choose a skin"
		"skin":
			var char_id        = _selected_char_data.get("id", "")
			var skin_id        = _selected_skin_data.get("id", "")
			var currently      = save_data.get_equipped_skin(char_id)
			equip_btn.disabled = (skin_id == currently)
			equip_btn.text     = "Equipped" if skin_id == currently else "Equip"
		"emote":
			# TODO: equippable emote slots
			equip_btn.disabled = true
			equip_btn.text     = "Owned"
		_:
			equip_btn.disabled = true
			equip_btn.text     = "Equip"

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
	_populate_killers()
	_populate_survivors()

func _on_skins_button_pressed() -> void:
	if _selected_char_data.is_empty():
		return
	_populate_skins_panel(_selected_char_data)
	$SkinsPanel.visible = not $SkinsPanel.visible
	$Items.visible      = not $Items.visible

func _clear_grid(grid: Node) -> void:
	for child in grid.get_children():
		child.queue_free()
