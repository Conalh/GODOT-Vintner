class_name WineRecipe
extends Resource

## WineRecipe Resource - Crafted wine data with quality calculations and buff effects
## Supports the quality progression: House → Select → Reserve → Grand Reserve → Mythic
## Integrates with CraftingSystem for wine creation and quality determination

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var rarity: String = "House"  # House, Select, Reserve, GrandReserve, Mythic

## Emotional Notes (1-3) - affects buff power selection and wine personality
@export var notes: PackedStringArray = []
## Stat Virtues - Dictionary mapping virtue names to intensity values
@export var virtues: Dictionary = {}

## Buff system - powers that augment vampire abilities
@export var buff_power: String = ""  # Mist, BatSwarm, Mesmerize, Shadowstep, Regen
@export var buff_effect: String = ""  # +radius, +distance, +duration, +damage, +efficiency
@export var buff_magnitude: int = 0  # Intensity of the buff effect
@export var buff_duration_sec: float = 0.0  # How long the buff lasts

## Economic values
@export var serve_value: int = 0  # Prestige gained when serving to patrons
@export var drink_value: int = 0  # Prestige gained when drinking personally

## Visual and thematic elements
@export var label_motifs: PackedStringArray = []  # Visual motifs for the wine label
@export var tagline: String = ""  # Elegant description of the wine

## Crafting metadata
@export var crafting_date: String = ""  # When the wine was crafted
@export var aging_potential: float = 0.0  # How much the wine can improve with age
@export var current_age_days: int = 0  # Current age of the wine
@export var is_aged: bool = false  # Whether the wine has been aged

## Quality calculation support
@export var quality_score: float = 0.0  # Calculated quality rating
@export var complexity_rating: int = 0  # How complex the wine is (1-10)

## Validation and utility methods
func is_valid() -> bool:
	"""Validate the wine recipe data"""
	if id.is_empty() or name.is_empty():
		return false
	
	if notes.size() < 1 or notes.size() > 3:
		return false
	
	if virtues.is_empty():
		return false
	
	# Validate rarity
	var valid_rarities = ["House", "Select", "Reserve", "GrandReserve", "Mythic"]
	if not valid_rarities.has(rarity):
		return false
	
	# Validate buff power
	var valid_powers = ["Mist", "BatSwarm", "Mesmerize", "Shadowstep", "Regen"]
	if not buff_power.is_empty() and not valid_powers.has(buff_power):
		return false
	
	return true

func get_total_virtue_score() -> int:
	"""Calculate total virtue score for quality calculations"""
	var total: int = 0
	for virtue_value in virtues.values():
		total += int(virtue_value)
	return total

func calculate_quality_score() -> float:
	"""Calculate the wine's quality score based on virtues and complexity"""
	var base_score: float = float(get_total_virtue_score())
	var complexity_bonus: float = float(complexity_rating) * 0.5
	var age_bonus: float = 0.0
	
	if is_aged and current_age_days > 0:
		age_bonus = min(float(current_age_days) * 0.1, 5.0)  # Max 5 points from aging
	
	quality_score = base_score + complexity_bonus + age_bonus
	return quality_score

func determine_rarity() -> String:
	"""Determine rarity based on quality score and virtue complexity"""
	var score: float = calculate_quality_score()
	var virtue_count: int = virtues.size()
	var note_count: int = notes.size()
	
	# Complex calculation considering multiple factors
	var rarity_score: float = score + (float(virtue_count) * 0.5) + (float(note_count) * 0.3)
	
	if rarity_score >= 15.0:
		return "Mythic"
	elif rarity_score >= 12.0:
		return "GrandReserve"
	elif rarity_score >= 8.0:
		return "Reserve"
	elif rarity_score >= 5.0:
		return "Select"
	else:
		return "House"

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

func has_note(note_name: String) -> bool:
	"""Check if this wine contains a specific emotional note"""
	return notes.has(note_name)

func has_virtue(virtue_name: String) -> bool:
	"""Check if this wine contains a specific virtue"""
	return virtues.has(virtue_name)

func can_age() -> bool:
	"""Check if this wine can be aged further"""
	return current_age_days < int(aging_potential)

func age_wine(days: int) -> void:
	"""Age the wine by the specified number of days"""
	if can_age():
		current_age_days += days
		if current_age_days >= int(aging_potential):
			is_aged = true
			# Recalculate quality after aging
			calculate_quality_score()

func get_buff_description() -> String:
	"""Get a human-readable description of the wine's buff effect"""
	if buff_power.is_empty() or buff_effect.is_empty():
		return "No buff effect"
	
	var effect_text: String = buff_effect
	if buff_magnitude > 0:
		effect_text += " +" + str(buff_magnitude)
	
	var duration_text: String = ""
	if buff_duration_sec > 0:
		duration_text = " for " + str(int(buff_duration_sec)) + " seconds"
	
	return buff_power + " " + effect_text + duration_text

## Save/Load support
func get_save_data() -> Dictionary:
	"""Get data for saving to persistent storage"""
	return {
		"id": id,
		"name": name,
		"description": description,
		"rarity": rarity,
		"notes": notes,
		"virtues": virtues,
		"buff_power": buff_power,
		"buff_effect": buff_effect,
		"buff_magnitude": buff_magnitude,
		"buff_duration_sec": buff_duration_sec,
		"serve_value": serve_value,
		"drink_value": drink_value,
		"label_motifs": label_motifs,
		"tagline": tagline,
		"crafting_date": crafting_date,
		"aging_potential": aging_potential,
		"current_age_days": current_age_days,
		"is_aged": is_aged,
		"quality_score": quality_score,
		"complexity_rating": complexity_rating
	}

func load_save_data(data: Dictionary) -> void:
	"""Load data from persistent storage"""
	id = data.get("id", "")
	name = data.get("name", "")
	description = data.get("description", "")
	rarity = data.get("rarity", "House")
	notes = data.get("notes", PackedStringArray())
	virtues = data.get("virtues", {})
	buff_power = data.get("buff_power", "")
	buff_effect = data.get("buff_effect", "")
	buff_magnitude = data.get("buff_magnitude", 0)
	buff_duration_sec = data.get("buff_duration_sec", 0.0)
	serve_value = data.get("serve_value", 0)
	drink_value = data.get("drink_value", 0)
	label_motifs = data.get("label_motifs", PackedStringArray())
	tagline = data.get("tagline", "")
	crafting_date = data.get("crafting_date", "")
	aging_potential = data.get("aging_potential", 0.0)
	current_age_days = data.get("current_age_days", 0)
	is_aged = data.get("is_aged", false)
	quality_score = data.get("quality_score", 0.0)
	complexity_rating = data.get("complexity_rating", 0)
