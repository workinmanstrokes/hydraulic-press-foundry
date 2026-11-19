class_name Economy
extends RefCounted
## Economy logic: costs, sell prices, timers, coins, upgrades.
## Data is the locked v1 list in res://data/content.csv (14 rows).
## Times are the level-1 base times; upgrades scale them.

const CONTENT_PATH := "res://data/content.csv"
const START_COINS := 100
const PRESS_UPGRADE_COSTS := {2: 75, 3: 150, 4: 300}
const FURNACE_UPGRADE_COSTS := {2: 100, 3: 200, 4: 400}
const PRESS_TIME_FACTOR := 0.85  # per press level above 1
const FURNACE_SELL_BONUS := 0.10  # +10% sell price per furnace level above 1

var coins: int = START_COINS
var press_level: int = 1
var furnace_level: int = 1
# material name -> {cost, press_time_s, foundry_time_s, product, sell_price}
var content: Dictionary = {}
# Starter five for the greybox prototype.
var starter_materials: Array[String] = [
	"Scrap Iron", "Scrap Copper", "Scrap Aluminum", "Scrap Steel", "Scrap Brass",
]


func _init() -> void:
	load_content()


func load_content() -> void:
	var file := FileAccess.open(CONTENT_PATH, FileAccess.READ)
	if file == null:
		push_error("Economy: could not open " + CONTENT_PATH)
		return
	file.get_line()  # header
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts := line.split(",")
		if parts.size() < 6:
			continue
		content[parts[0]] = {
			"cost": int(parts[1]),
			"press_time_s": float(parts[2]),
			"foundry_time_s": float(parts[3]),
			"product": parts[4],
			"sell_price": int(parts[5]),
		}


func material_cost(material: String) -> int:
	if not content.has(material):
		return -1
	return int(content[material]["cost"])


func product_for(material: String) -> String:
	if not content.has(material):
		return ""
	return String(content[material]["product"])


func sell_price_for(product: String) -> int:
	for key in content:
		if String(content[key]["product"]) == product:
			var base := int(content[key]["sell_price"])
			var bonus := 1.0 + FURNACE_SELL_BONUS * float(furnace_level - 1)
			return int(round(base * bonus))
	return -1


func press_time_for(material: String) -> float:
	if not content.has(material):
		return -1.0
	var base := float(content[material]["press_time_s"])
	return base * pow(PRESS_TIME_FACTOR, float(press_level - 1))


func foundry_time_for(material: String) -> float:
	if not content.has(material):
		return -1.0
	return float(content[material]["foundry_time_s"])


func can_afford(amount: int) -> bool:
	return coins >= amount


func spend(amount: int) -> bool:
	if amount < 0 or not can_afford(amount):
		return false
	coins -= amount
	return true


func earn(amount: int) -> void:
	if amount > 0:
		coins += amount


func press_upgrade_cost() -> int:
	return int(PRESS_UPGRADE_COSTS.get(press_level + 1, -1))


func furnace_upgrade_cost() -> int:
	return int(FURNACE_UPGRADE_COSTS.get(furnace_level + 1, -1))


func upgrade_press() -> bool:
	var cost := press_upgrade_cost()
	if cost < 0 or not spend(cost):
		return false
	press_level += 1
	return true


func upgrade_furnace() -> bool:
	var cost := furnace_upgrade_cost()
	if cost < 0 or not spend(cost):
		return false
	furnace_level += 1
	return true
