class_name CustomerGenerator
extends RefCounted
## Generates cyberpunk patrons with sell/buy intent and hidden contraband cues.

const ARCHETYPES: Array[Dictionary] = [
	{
		"role": "Deck Scavenger",
		"faction": "Scavengers",
		"coat_color": Color(0.24, 0.58, 0.48),
		"visor_color": Color(0.2, 0.95, 0.72),
		"skin_color": Color(0.76, 0.62, 0.54),
		"stolen_chance": 0.45,
		"sting_chance": 0.0,
		"greed": 0.92,
		"names": ["Riko", "Vex", "Tala", "Mink", "Korr"],
		"sell_lines": [
			"Pulled this from a cold bulkhead. No questions, fair credits.",
			"Need quick creds before air-tax hits. Take a look.",
		],
		"buy_lines": [
			"Word is you stock decent gear. Name a clean price.",
			"Got cash on hand if this unit actually powers on.",
		],
	},
	{
		"role": "Syndicate Runner",
		"faction": "Syndicate",
		"coat_color": Color(0.56, 0.16, 0.42),
		"visor_color": Color(1.0, 0.22, 0.65),
		"skin_color": Color(0.84, 0.72, 0.68),
		"stolen_chance": 0.80,
		"sting_chance": 0.0,
		"greed": 1.05,
		"names": ["Nyx", "Sable", "Jinx", "Kade", "Zero-9"],
		"sell_lines": [
			"Hot cargo off the freight lift. Move it fast.",
			"Syndicate surplus. Don't bother scanning the serial.",
		],
		"buy_lines": [
			"Crew needs hardware tonight. Don't waste my cycle.",
			"Price it sharp and nobody visits after curfew.",
		],
	},
	{
		"role": "Corp Logistics Clerk",
		"faction": "CorpSec",
		"coat_color": Color(0.22, 0.30, 0.52),
		"visor_color": Color(0.32, 0.76, 1.0),
		"skin_color": Color(0.86, 0.76, 0.70),
		"stolen_chance": 0.25,
		"sting_chance": 0.0,
		"greed": 1.12,
		"names": ["Vance", "Lin", "Mercer", "Sato", "Hollis"],
		"sell_lines": [
			"Manifest discrepancy. Consider this off-book liquidation.",
			"Surplus requisition unit. Keep receipts off the grid.",
		],
		"buy_lines": [
			"Looking for something discreet before inspection starts.",
			"Have credits authorized, provided quality passes scan.",
		],
	},
	{
		"role": "Suspicious Auditor",
		"faction": "CorpSec",
		"coat_color": Color(0.18, 0.22, 0.30),
		"visor_color": Color(1.0, 0.82, 0.24),
		"skin_color": Color(0.74, 0.66, 0.62),
		"stolen_chance": 0.90,
		"sting_chance": 0.65,
		"greed": 0.78,
		"names": ["Agent 4B", "Kestrel", "Dorn", "Pryce"],
		"sell_lines": [
			"Found this unattended near Sector 2. Cheap if you buy right now.",
			"Totally legitimate salvage... why are you reaching for the UV lamp?",
		],
		"buy_lines": [
			"Testing local compliance. Show me what you're selling.",
		],
	},
]


func generate_offer(current_day: int, suspicion: int) -> Dictionary:
	var arch_idx := randi_range(0, ARCHETYPES.size() - 1)
	if current_day == 1 and arch_idx == 3:
		arch_idx = randi_range(0, 2)
	elif suspicion >= 45 and randf() < 0.35:
		arch_idx = 3

	var arch := ARCHETYPES[arch_idx]
	var names: Array = arch["names"]
	var customer_name: String = names[randi_range(0, names.size() - 1)]

	var can_buy_from_player := InventoryManager.stock.size() > 0 and randf() < 0.42
	if can_buy_from_player:
		return _build_buy_from_player_offer(arch, customer_name)
	return _build_sell_to_player_offer(arch, customer_name)


func _build_sell_to_player_offer(arch: Dictionary, customer_name: String) -> Dictionary:
	var item_ids := InventoryManager.get_all_item_ids()
	var item_id: String = item_ids[randi_range(0, item_ids.size() - 1)]
	var data := InventoryManager.get_item_data(item_id)

	var is_stolen := randf() < float(arch["stolen_chance"])
	var is_sting := is_stolen and (randf() < float(arch["sting_chance"]))
	var has_beacon := is_stolen and (is_sting or randf() < 0.42)

	var discount := 0.68 if is_stolen else 0.84
	var ask_price := maxi(25, int(round(data.base_value * discount * float(arch["greed"]))))
	var lines: Array = arch["sell_lines"]

	return {
		"intent": "SELL_TO_PLAYER",
		"customer_name": customer_name,
		"role": arch["role"],
		"faction": arch["faction"],
		"coat_color": arch["coat_color"],
		"visor_color": arch["visor_color"],
		"skin_color": arch["skin_color"],
		"dialogue": lines[randi_range(0, lines.size() - 1)],
		"item_id": data.id,
		"item_name": data.display_name,
		"category": data.get_category_label(),
		"base_value": data.base_value,
		"initial_price": ask_price,
		"min_acceptable": maxi(15, int(round(ask_price * 0.72))),
		"max_acceptable": ask_price * 2,
		"illegal_risk": data.illegal_risk,
		"is_stolen": is_stolen,
		"has_beacon": has_beacon,
		"is_sting": is_sting,
		"uv_clue": data.contraband_clue if (is_stolen or has_beacon) else "Factory hologram intact. Clean registration.",
		"serial": "%s-%04d" % [data.serial_prefix, randi_range(1000, 9999)],
		"item_color": data.visual_color,
		"item_shape": data.shape_type,
		"description": data.description,
		"target_uid": -1,
	}


func _build_buy_from_player_offer(arch: Dictionary, customer_name: String) -> Dictionary:
	var stock_idx := randi_range(0, InventoryManager.stock.size() - 1)
	var stock_item := InventoryManager.stock[stock_idx]
	var data := InventoryManager.get_item_data(stock_item["item_id"])
	var fair_sell := InventoryManager.get_sell_value(stock_item)
	var bid_price := maxi(30, int(round(fair_sell * randf_range(0.92, 1.22))))
	var lines: Array = arch["buy_lines"]

	return {
		"intent": "BUY_FROM_PLAYER",
		"customer_name": customer_name,
		"role": arch["role"],
		"faction": arch["faction"],
		"coat_color": arch["coat_color"],
		"visor_color": arch["visor_color"],
		"skin_color": arch["skin_color"],
		"dialogue": lines[randi_range(0, lines.size() - 1)],
		"item_id": stock_item["item_id"],
		"item_name": stock_item["name"],
		"category": stock_item["category"],
		"base_value": stock_item["base_value"],
		"initial_price": bid_price,
		"min_acceptable": 10,
		"max_acceptable": int(round(bid_price * 1.28)),
		"illegal_risk": data.illegal_risk if data else 10,
		"is_stolen": stock_item["is_stolen"],
		"has_beacon": stock_item["has_beacon"],
		"is_sting": false,
		"uv_clue": data.contraband_clue if (data and stock_item["is_stolen"]) else "Clean unit on your shelf.",
		"serial": stock_item["serial"],
		"item_color": stock_item["color"],
		"item_shape": stock_item["shape"],
		"description": data.description if data else "Stocked item.",
		"target_uid": stock_item["uid"],
	}
