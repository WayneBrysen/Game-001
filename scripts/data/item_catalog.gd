class_name ItemCatalog
extends RefCounted
## Factory catalog of cyberpunk shop items inspired by gritty station pawnshops.

static func create_default_items() -> Dictionary[String, ItemData]:
	var specs: Array[Dictionary] = [
		{
			"id": "water_cartridge",
			"name": "Purified Water Cartridge",
			"cat": ItemData.Category.SURVIVAL,
			"value": 65,
			"risk": 4,
			"color": Color(0.22, 0.86, 0.96),
			"shape": "cylinder",
			"prefix": "H2O-19",
			"desc": "Sealed life-support filter. Always in steady demand on Deck 9.",
			"clue": "Siphoned from Sector 4 Hydroponics reserve tank.",
		},
		{
			"id": "scrap_servo",
			"name": "Scrap Servo Arm",
			"cat": ItemData.Category.CYBERWARE,
			"value": 120,
			"risk": 14,
			"color": Color(0.95, 0.62, 0.18),
			"shape": "box",
			"prefix": "CYB-88",
			"desc": "Refurbished loader actuator with intact hydraulic couplers.",
			"clue": "Bio-lock ID scraped off with an angle grinder.",
		},
		{
			"id": "data_shard",
			"name": "Pre-Collapse Data Shard",
			"cat": ItemData.Category.TECH,
			"value": 155,
			"risk": 18,
			"color": Color(0.32, 0.95, 0.62),
			"shape": "chip",
			"prefix": "NET-77",
			"desc": "Encrypted optical storage wafer; netrunners pay extra for clean shards.",
			"clue": "CorpSec asset watermark hidden under UV layer.",
		},
		{
			"id": "dream_dust",
			"name": "Dream Dust Vial",
			"cat": ItemData.Category.CHEMS,
			"value": 190,
			"risk": 26,
			"color": Color(0.98, 0.24, 0.66),
			"shape": "vial",
			"prefix": "SYN-09",
			"desc": "Unlicensed neural stimulant brewed in pressurized under-deck labs.",
			"clue": "Red Syndicate batch stamp glows under UV spectrum.",
		},
		{
			"id": "milspec_optics",
			"name": "Mil-Spec Optics Rig",
			"cat": ItemData.Category.CYBERWARE,
			"value": 240,
			"risk": 22,
			"color": Color(0.45, 0.72, 1.0),
			"shape": "box",
			"prefix": "MIL-31",
			"desc": "Thermal-overlay ocular module. High margin if cleared quietly.",
			"clue": "Active CorpSec beacon pulsing on pin 4!",
		},
		{
			"id": "forged_pass",
			"name": "Forged Transit Pass",
			"cat": ItemData.Category.CONTRABAND,
			"value": 210,
			"risk": 28,
			"color": Color(0.96, 0.85, 0.26),
			"shape": "chip",
			"prefix": "PAS-00",
			"desc": "Cloned elevator clearance keycard for upper orbital rings.",
			"clue": "Micro-etched duplicate hologram mismatch.",
		},
		{
			"id": "plasma_core",
			"name": "Plasma Cutter Core",
			"cat": ItemData.Category.TECH,
			"value": 175,
			"risk": 15,
			"color": Color(1.0, 0.42, 0.25),
			"shape": "cylinder",
			"prefix": "IND-52",
			"desc": "Industrial docking-bay torch cell. Useful for salvage crews.",
			"clue": "Dockyard Guild inventory tag partially melted.",
		},
		{
			"id": "ai_dampener",
			"name": "AI Neural Dampener",
			"cat": ItemData.Category.CONTRABAND,
			"value": 310,
			"risk": 34,
			"color": Color(0.76, 0.35, 1.0),
			"shape": "chip",
			"prefix": "RGE-X1",
			"desc": "Experimental signal jammer shielding implants from rogue AI pings.",
			"clue": "High-priority CorpSec seizure serial embedded inside!",
		},
	]

	var catalog: Dictionary[String, ItemData] = {}
	for spec in specs:
		var item := ItemData.new()
		item.id = spec["id"]
		item.display_name = spec["name"]
		item.category = spec["cat"]
		item.base_value = spec["value"]
		item.illegal_risk = spec["risk"]
		item.visual_color = spec["color"]
		item.shape_type = spec["shape"]
		item.serial_prefix = spec["prefix"]
		item.description = spec["desc"]
		item.contraband_clue = spec["clue"]
		catalog[item.id] = item
	return catalog
