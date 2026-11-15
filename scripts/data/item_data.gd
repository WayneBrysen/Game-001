class_name ItemData
extends Resource
## Archetype definition for tradeable cyberpunk shop merchandise.

enum Category {
	TECH,
	CHEMS,
	CYBERWARE,
	SURVIVAL,
	CONTRABAND,
}

@export var id: String = "item_generic"
@export var display_name: String = "Scrap Module"
@export var category: Category = Category.TECH
@export var base_value: int = 100
@export var illegal_risk: int = 10 ## Base heat/suspicion added if proven stolen/contraband.
@export var visual_color: Color = Color(0.2, 0.85, 1.0)
@export var shape_type: String = "box" ## "box", "vial", "chip", "cylinder"
@export var serial_prefix: String = "NS-404"
@export var description: String = "Salvaged station hardware."
@export var contraband_clue: String = "Filed-off Syndicate serial stamp."


func get_category_label() -> String:
	match category:
		Category.TECH:
			return "TECH"
		Category.CHEMS:
			return "CHEMS"
		Category.CYBERWARE:
			return "CYBER"
		Category.SURVIVAL:
			return "SUPPLY"
		Category.CONTRABAND:
			return "BLACK"
	return "MISC"
