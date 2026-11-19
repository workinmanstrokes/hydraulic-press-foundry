extends Control
## Workshop controller: order -> buy scrap -> press -> melt -> cast -> sell.
## One press, one furnace, five starter materials, one active order.
## Greybox only: every station is a labelled panel with a large button
## and a progress bar. No extra machines, modes, or automation.

const SAVE_PATH := "user://save.json"

var economy: Economy
var inventory: Dictionary = {}  # item name -> count
var active_order: Dictionary = {}  # {product, payout}
var order_index: int = 0
var press_material: String = ""
var press_progress: float = 0.0
var press_running: bool = false
var melt_material: String = ""
var melt_progress: float = 0.0
var melt_running: bool = false
var molten_material: String = ""
var status_text: String = "Welcome! Check the order, then buy scrap."

@onready var coins_label: Label = $TopBar/CoinsLabel
@onready var order_label: Label = $OrdersPanel/OrderLabel
@onready var status_label: Label = $StatusLabel
@onready var press_bar: ProgressBar = $WorkshopPanel/PressBar
@onready var melt_bar: ProgressBar = $WorkshopPanel/MeltBar
@onready var inventory_label: Label = $WorkshopPanel/InventoryLabel
@onready var market_list: ItemList = $MarketPanel/MarketList
@onready var press_button: Button = $WorkshopPanel/PressButton
@onready var melt_button: Button = $WorkshopPanel/MeltButton
@onready var cast_button: Button = $WorkshopPanel/CastButton
@onready var sell_button: Button = $WorkshopPanel/SellButton


func _ready() -> void:
	economy = Economy.new()
	load_save()
	if active_order.is_empty():
		next_order()
	build_market()
	refresh_ui()
	market_list.item_selected.connect(_on_market_selected)
	press_button.pressed.connect(_on_press_pressed)
	melt_button.pressed.connect(_on_melt_pressed)
	cast_button.pressed.connect(_on_cast_pressed)
	sell_button.pressed.connect(_on_sell_pressed)
	$UpgradesPanel/PressUpgradeButton.pressed.connect(_on_press_upgrade_pressed)
	$UpgradesPanel/FurnaceUpgradeButton.pressed.connect(_on_furnace_upgrade_pressed)


func _process(delta: float) -> void:
	if press_running:
		press_progress += delta / economy.press_time_for(press_material)
		press_bar.value = press_progress * 100.0
		if press_progress >= 1.0:
			press_running = false
			add_item("Crushed " + press_material, 1)
			status_text = "Pressed! Crushed %s is ready for the furnace." % press_material
			press_material = ""
			save_game()
			refresh_ui()
	if melt_running:
		melt_progress += delta / economy.foundry_time_for(melt_material)
		melt_bar.value = melt_progress * 100.0
		if melt_progress >= 1.0:
			melt_running = false
			molten_material = melt_material
			status_text = "Melted! Molten %s is ready to cast." % melt_material
			melt_material = ""
			save_game()
			refresh_ui()


func build_market() -> void:
	market_list.clear()
	for material in economy.starter_materials:
		var cost := economy.material_cost(material)
		market_list.add_item("%s — %d coins" % [material, cost])


func next_order() -> void:
	# Orders cycle through the starter products so the first 10 minutes
	# match the README timeline: iron, copper, aluminum, steel, brass...
	var products: Array[String] = [
		"Iron Ingot", "Copper Ingot", "Aluminum Ingot", "Steel Beam", "Brass Gear",
	]
	var product: String = products[order_index % products.size()]
	order_index += 1
	active_order = {"product": product, "payout": economy.sell_price_for(product)}


func add_item(item: String, amount: int) -> void:
	inventory[item] = int(inventory.get(item, 0)) + amount


func take_item(item: String, amount: int) -> bool:
	if int(inventory.get(item, 0)) < amount:
		return false
	inventory[item] = int(inventory[item]) - amount
	if int(inventory[item]) <= 0:
		inventory.erase(item)
	return true


func _on_market_selected(index: int) -> void:
	var material: String = economy.starter_materials[index]
	var cost := economy.material_cost(material)
	if not economy.spend(cost):
		status_text = "Not enough coins for %s (%d coins)." % [material, cost]
		refresh_ui()
		return
	add_item(material, 1)
	status_text = "Bought 1x %s. Load it into the press." % material
	save_game()
	refresh_ui()


func _on_press_pressed() -> void:
	if press_running:
		return
	for material in economy.starter_materials:
		if int(inventory.get(material, 0)) > 0:
			take_item(material, 1)
			press_material = material
			press_progress = 0.0
			press_running = true
			status_text = "Pressing %s..." % material
			refresh_ui()
			return
	status_text = "No scrap in inventory. Buy scrap in the market first."
	refresh_ui()


func _on_melt_pressed() -> void:
	if melt_running or molten_material != "":
		return
	for material in economy.starter_materials:
		var crushed := "Crushed " + material
		if int(inventory.get(crushed, 0)) > 0:
			take_item(crushed, 1)
			melt_material = material
			melt_progress = 0.0
			melt_running = true
			status_text = "Melting crushed %s..." % material
			refresh_ui()
			return
	status_text = "No crushed scrap. Press scrap first."
	refresh_ui()


func _on_cast_pressed() -> void:
	if molten_material.is_empty():
		status_text = "Nothing molten. Melt crushed scrap first."
		refresh_ui()
		return
	var product := economy.product_for(molten_material)
	add_item(product, 1)
	status_text = "Cast 1x %s. Sell it in the shop!" % product
	molten_material = ""
	save_game()
	refresh_ui()


func _on_sell_pressed() -> void:
	if active_order.is_empty():
		return
	var product: String = active_order["product"]
	if not take_item(product, 1):
		status_text = "You don't have %s yet. Cast it first." % product
		refresh_ui()
		return
	var payout := int(active_order["payout"])
	economy.earn(payout)
	status_text = "Sold %s for %d coins! Order complete." % [product, payout]
	next_order()
	save_game()
	refresh_ui()


func _on_press_upgrade_pressed() -> void:
	if economy.upgrade_press():
		status_text = "Press upgraded to level %d. Press time reduced." % economy.press_level
	else:
		status_text = "Cannot upgrade press (cost %d coins)." % economy.press_upgrade_cost()
	save_game()
	refresh_ui()


func _on_furnace_upgrade_pressed() -> void:
	if economy.upgrade_furnace():
		status_text = "Furnace upgraded to level %d. Sell prices up 10%%." % economy.furnace_level
	else:
		status_text = "Cannot upgrade furnace (cost %d coins)." % economy.furnace_upgrade_cost()
	save_game()
	refresh_ui()


func refresh_ui() -> void:
	coins_label.text = "Coins: %d" % economy.coins
	if active_order.is_empty():
		order_label.text = "No order."
	else:
		order_label.text = "Order: 1x %s — pays %d coins" % [active_order["product"], active_order["payout"]]
	status_label.text = status_text
	press_bar.value = press_progress * 100.0
	melt_bar.value = melt_progress * 100.0
	var lines: Array[String] = []
	for item in inventory:
		lines.append("%s x%d" % [item, inventory[item]])
	if molten_material != "":
		lines.append("Molten %s (ready to cast)" % molten_material)
	inventory_label.text = "Inventory:\n" + ("\n".join(lines) if not lines.is_empty() else "empty")
	$UpgradesPanel/PressUpgradeButton.text = "Upgrade Press (Lv %d) — %d coins" % [economy.press_level, economy.press_upgrade_cost()]
	$UpgradesPanel/FurnaceUpgradeButton.text = "Upgrade Furnace (Lv %d) — %d coins" % [economy.furnace_level, economy.furnace_upgrade_cost()]


func save_game() -> void:
	var data := {
		"coins": economy.coins,
		"press_level": economy.press_level,
		"furnace_level": economy.furnace_level,
		"inventory": inventory,
		"active_order": active_order,
		"order_index": order_index,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data))


func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	if data.is_empty():
		return
	economy.coins = int(data.get("coins", Economy.START_COINS))
	economy.press_level = int(data.get("press_level", 1))
	economy.furnace_level = int(data.get("furnace_level", 1))
	inventory = data.get("inventory", {})
	active_order = data.get("active_order", {})
	order_index = int(data.get("order_index", 0))
