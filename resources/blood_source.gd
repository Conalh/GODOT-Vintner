class_name BloodSource
extends Resource

## BloodSource Resource - Complex ingredient data for wine crafting
## Contains emotional Notes, stat Virtues, intensity values, and rarity hints
## Integrates with CraftingSystem for wine quality calculations

@export var id: String = ""
@export var source_name: String = ""
@export var description: String = ""
@export var rarity_hint: String = "House"  # House, Select, Reserve, GrandReserve, Mythic

## Emotional Notes (emotions) - 1-3 per source, affects wine buffs
@export var notes: PackedStringArray = []
## Stat Virtues - Dictionary mapping virtue names to intensity values
@export var virtues: Dictionary = {}
## Intensity multiplier for this blood source (affects final wine quality)
@export var intensity_multiplier: float = 1.0
## Source type for categorization and filtering
@export var source_type: String = "mortal"  # mortal, vampire, supernatural, relic

## Metadata for hunt integration
@export var biome_origin: String = "Desert"
@export var hunt_difficulty: String = "Low"  # Low, Medium, High
@export var is_rare_find: bool = false

## Validation and utility methods
func is_valid() -> bool:
	"""Validate the blood source data"""
	if id.is_empty() or source_name.is_empty():
		return false
	
	if notes.size() < 1 or notes.size() > 3:
		return false
	
	if virtues.is_empty():
		return false
	
	# Validate rarity hint
	var valid_rarities = ["House", "Select", "Reserve", "GrandReserve", "Mythic"]
	if not valid_rarities.has(rarity_hint):
		return false
	
	return true

func get_total_virtue_score() -> int:
	"""Calculate total virtue score for rarity calculations"""
	var total: int = 0
	for virtue_value in virtues.values():
		total += int(virtue_value)
	return total

func get_primary_note() -> String:
	"""Get the first/primary emotional note"""
	if notes.size() > 0:
		return notes[0]
	return ""

func get_primary_virtue() -> String:
	"""Get the virtue with highest intensity"""
	var highest_virtue: String = ""
	var highest_value: int = 0
	
	for virtue_name in virtues.keys():
		var value: int = int(virtues[virtue_name])
		if value > highest_value:
			highest_value = value
			highest_virtue = virtue_name
	
	return highest_virtue

func get_virtue_intensity(virtue_name: String) -> int:
	"""Get the intensity value for a specific virtue"""
	return int(virtues.get(virtue_name, 0))

func has_note(note_name: String) -> bool:
	"""Check if this blood source contains a specific emotional note"""
	return notes.has(note_name)

func has_virtue(virtue_name: String) -> bool:
	"""Check if this blood source contains a specific virtue"""
	return virtues.has(virtue_name)

## Save/Load support
func get_save_data() -> Dictionary:
	"""Get data for saving to persistent storage"""
	return {
		"id": id,
		"source_name": source_name,
		"description": description,
		"rarity_hint": rarity_hint,
		"notes": notes,
		"virtues": virtues,
		"intensity_multiplier": intensity_multiplier,
		"source_type": source_type,
		"biome_origin": biome_origin,
		"hunt_difficulty": hunt_difficulty,
		"is_rare_find": is_rare_find
	}

func load_save_data(data: Dictionary) -> void:
	"""Load data from persistent storage"""
	id = data.get("id", "")
	source_name = data.get("source_name", "")
	description = data.get("description", "")
	rarity_hint = data.get("rarity_hint", "House")
	notes = data.get("notes", PackedStringArray())
	virtues = data.get("virtues", {})
	intensity_multiplier = data.get("intensity_multiplier", 1.0)
	source_type = data.get("source_type", "mortal")
	biome_origin = data.get("biome_origin", "Desert")
	hunt_difficulty = data.get("hunt_difficulty", "Low")
	is_rare_find = data.get("is_rare_find", false)
