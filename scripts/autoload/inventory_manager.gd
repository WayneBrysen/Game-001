extends Node
## Holds the item catalog and player's current shelf inventory.

const MAX_SHELF_SLOTS: int = 8

var catalog: Dictionary[String, ItemData] = {}
var stock: Array[Dictionary] = []
var _next_uid: int = 1


func _ready() -> void:
	catalog = ItemCatalog.create_default_items()
	_seed_starting_stock()


func _seed_starting_stock() -> void:
	stock.clear()
	add_item_by_id("water_cartridge", 50, false, false)
	add_item_by_id("scrap_servo", 95, false, false)
	add_item_by_id("data_shard", 130, true, false)


func get_item_data(item_id: String) -> ItemData:
	return catalog.get(item_id, null)


func get_all_item_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in catalog.keys():
		ids.append(key)
	return ids


func add_item_by_id(item_id: String, paid_price: int, is_stolen: bool, has_beacon: bool) -> Dictionary:
	var data := get_item_data(item_id)
	if data == null:
		return {}
	var entry := {
		"uid": _next_uid,
		"item_id": item_id,
		"name": data.display_name,
		"category": data.get_category_label(),
		"base_value": data.base_value,
		"paid_price": paid_price,
		"is_stolen": is_stolen,
		"has_beacon": has_beacon,
		"color": data.visual_color,
		"shape": data.shape_type,
		"serial": "%s-%04d" % [data.serial_prefix, randi_range(1000, 9999)],
	}
	_next_uid += 1
	stock.append(entry)
	GameEvents.inventory_updated.emit()
	return entry


func remove_item_by_uid(uid: int) -> bool:
	for i in range(stock.size()):
		if stock[i]["uid"] == uid:
			stock.remove_at(i)
			GameEvents.inventory_updated.emit()
			return true
	return false


func has_capacity() -> bool:
	return stock.size() < MAX_SHELF_SLOTS


func get_sell_value(entry: Dictionary) -> int:
	var base := int(entry.get("base_value", 100))
	var rep_bonus := int(EconomyManager.factions.get("Scavengers", 0) * 0.4)
	return maxi(20, base + rep_bonus)
