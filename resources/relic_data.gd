class_name RelicData
extends Resource

## RelicData Resource - Hunt rewards that modify crafting or combat abilities
## Provides permanent upgrades and modifications to player capabilities
## Integrates with PlayerData for progression and CraftingSystem for crafting bonuses

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var rarity: String = "Common"  # Common, Uncommon, Rare, Epic, Legendary
@export var relic_type: String = "crafting"  # crafting, combat, utility, prestige

## Effect system - what the relic does
@export var effect_type: String = "modifier"  # modifier, ability, passive, active
@export var effect_target: String = ""  # What system/stat this affects
@export var effect_value: float = 0.0  # Magnitude of the effect
@export var effect_operator: String = "add"  # add, multiply, set, conditional

## Crafting-specific effects
@export var crafting_bonuses: Dictionary = {}  # e.g., {"wine_quality": 0.2, "aging_speed": 1.5}
@export var recipe_unlocks: PackedStringArray = []  # Recipe IDs this relic unlocks
@export var ingredient_bonuses: Dictionary = {}  # e.g., {"blood_efficiency": 0.1, "note_intensity": 1.2}

## Combat and ability effects
@export var power_modifiers: Dictionary = {}  # e.g., {"Mist": {"radius": 1.5, "duration": 2.0}}
@export var stat_bonuses: Dictionary = {}  # e.g., {"health": 25, "stamina": 50}
@export var ability_unlocks: PackedStringArray = []  # New abilities this relic provides

## Utility and prestige effects
@export var bar_effects: Dictionary = {}  # e.g., {"patron_satisfaction": 0.15, "tip_multiplier": 1.2}
@export var hunt_effects: Dictionary = {}  # e.g., {"blood_drop_rate": 0.25, "relic_chance": 0.1}
@export var prestige_multipliers: Dictionary = {}  # e.g., {"serve_prestige": 1.3, "drink_prestige": 1.2}

## Requirements and restrictions
@export var unlock_requirements: Dictionary = {}  # What's needed to use this relic
@export var level_requirement: int = 0  # Minimum player level required
@export var prestige_requirement: int = 0  # Minimum prestige required
@export var is_consumable: bool = false  # Whether the relic is consumed on use

## Visual and thematic elements
@export var icon_path: String = ""  # Path to the relic's icon
@export var visual_effects: PackedStringArray = []  # Visual effects when equipped
@export var theme_tags: PackedStringArray = []  # Thematic tags for categorization

## Validation and utility methods
func is_valid() -> bool:
	"""Validate the relic data"""
	if id.is_empty() or name.is_empty():
		return false
	
	# Validate rarity
	var valid_rarities = ["Common", "Uncommon", " Rare", "Epic", "Legendary"]
	if not valid_rarities.has(rarity):
		return false
	
	# Validate relic type
	var valid_types = ["crafting", "combat", "utility", "prestige"]
	if not valid_types.has(relic_type):
		return false
	
	# Validate effect type
	var valid_effect_types = ["modifier", "ability", "passive", "active"]
	if not valid_effect_types.has(effect_type):
		return false
	
	return true

func can_be_equipped_by_player(player_data: PlayerData) -> bool:
	"""Check if the player can equip this relic"""
	if player_data.level < level_requirement:
		return false
	
	if player_data.reputation < prestige_requirement:
		return false
	
	# Check other unlock requirements
	for requirement_key in unlock_requirements.keys():
		var requirement_value = unlock_requirements[requirement_key]
		var player_value = player_data.get(requirement_key, 0)
		
		if player_value < requirement_value:
			return false
	
	return true

func get_crafting_bonus(bonus_type: String) -> float:
	"""Get a specific crafting bonus value"""
	return crafting_bonuses.get(bonus_type, 0.0)

func get_power_modifier(power_name: String, modifier_type: String) -> float:
	"""Get a specific power modifier value"""
	if power_modifiers.has(power_name):
		var power_mods = power_modifiers[power_name]
		return power_mods.get(modifier_type, 1.0)
	return 1.0

func get_stat_bonus(stat_name: String) -> float:
	"""Get a specific stat bonus value"""
	return stat_bonuses.get(stat_name, 0.0)

func get_bar_effect(effect_name: String) -> float:
	"""Get a specific bar effect value"""
	return bar_effects.get(effect_name, 0.0)

func get_hunt_effect(effect_name: String) -> float:
	"""Get a specific hunt effect value"""
	return hunt_effects.get(effect_name, 0.0)

func get_prestige_multiplier(prestige_type: String) -> float:
	"""Get a specific prestige multiplier value"""
	return prestige_multipliers.get(prestige_type, 1.0)

func apply_effect_to_wine(wine: WineRecipe) -> void:
	"""Apply relic effects to a wine recipe during crafting"""
	if relic_type != "crafting":
		return
	
	# Apply quality bonuses
	var quality_bonus = get_crafting_bonus("wine_quality")
	if quality_bonus > 0.0:
		wine.quality_score += quality_bonus
		wine.rarity = wine.determine_rarity()
	
	# Apply aging bonuses
	var aging_bonus = get_crafting_bonus("aging_speed")
	if aging_bonus > 0.0:
		wine.aging_potential *= aging_bonus
	
	# Apply ingredient efficiency bonuses
	var ingredient_bonus = get_crafting_bonus("ingredient_efficiency")
	if ingredient_bonus > 0.0:
		# This would affect how much of the blood source is consumed
		pass

func get_effect_summary() -> String:
	"""Get a human-readable summary of all relic effects"""
	var summary: String = ""
	
	# Crafting effects
	if not crafting_bonuses.is_empty():
		summary += "Crafting: "
		for bonus_type in crafting_bonuses.keys():
			var value = crafting_bonuses[bonus_type]
			if value > 0:
				summary += "+" + str(value * 100) + "% " + bonus_type.replace("_", " ") + ", "
		summary = summary.trim_suffix(", ") + "\n"
	
	# Combat effects
	if not power_modifiers.is_empty():
		summary += "Powers: "
		for power_name in power_modifiers.keys():
			var mods = power_modifiers[power_name]
			for mod_type in mods.keys():
				var value = mods[mod_type]
				if value > 1.0:
					summary += "+" + str(int((value - 1.0) * 100)) + "% " + power_name + " " + mod_type + ", "
		summary = summary.trim_suffix(", ") + "\n"
	
	# Stat effects
	if not stat_bonuses.is_empty():
		summary += "Stats: "
		for stat_name in stat_bonuses.keys():
			var value = stat_bonuses[stat_name]
			if value > 0:
				summary += "+" + str(value) + " " + stat_name + ", "
		summary = summary.trim_suffix(", ") + "\n"
	
	# Bar effects
	if not bar_effects.is_empty():
		summary += "Bar: "
		for effect_name in bar_effects.keys():
			var value = bar_effects[effect_name]
			if value > 0:
				summary += "+" + str(int(value * 100)) + "% " + effect_name.replace("_", " ") + ", "
		summary = summary.trim_suffix(", ")
	
	return summary

## Save/Load support
func get_save_data() -> Dictionary:
	"""Get data for saving to persistent storage"""
	return {
		"id": id,
		"name": name,
		"description": description,
		"rarity": rarity,
		"relic_type": relic_type,
		"effect_type": effect_type,
		"effect_target": effect_target,
		"effect_value": effect_value,
		"effect_operator": effect_operator,
		"crafting_bonuses": crafting_bonuses,
		"recipe_unlocks": recipe_unlocks,
		"ingredient_bonuses": ingredient_bonuses,
		"power_modifiers": power_modifiers,
		"stat_bonuses": stat_bonuses,
		"ability_unlocks": ability_unlocks,
		"bar_effects": bar_effects,
		"hunt_effects": hunt_effects,
		"prestige_multipliers": prestige_multipliers,
		"unlock_requirements": unlock_requirements,
		"level_requirement": level_requirement,
		"prestige_requirement": prestige_requirement,
		"is_consumable": is_consumable,
		"icon_path": icon_path,
		"visual_effects": visual_effects,
		"theme_tags": theme_tags
	}

func load_save_data(data: Dictionary) -> void:
	"""Load data from persistent storage"""
	id = data.get("id", "")
	name = data.get("name", "")
	description = data.get("description", "")
	rarity = data.get("rarity", "Common")
	relic_type = data.get("relic_type", "crafting")
	effect_type = data.get("effect_type", "modifier")
	effect_target = data.get("effect_target", "")
	effect_value = data.get("effect_value", 0.0)
	effect_operator = data.get("effect_operator", "add")
	crafting_bonuses = data.get("crafting_bonuses", {})
	recipe_unlocks = data.get("recipe_unlocks", PackedStringArray())
	ingredient_bonuses = data.get("ingredient_bonuses", {})
	power_modifiers = data.get("power_modifiers", {})
	stat_bonuses = data.get("stat_bonuses", {})
	ability_unlocks = data.get("ability_unlocks", PackedStringArray())
	bar_effects = data.get("bar_effects", {})
	hunt_effects = data.get("hunt_effects", {})
	prestige_multipliers = data.get("prestige_multipliers", {})
	unlock_requirements = data.get("unlock_requirements", {})
	level_requirement = data.get("level_requirement", 0)
	prestige_requirement = data.get("prestige_requirement", 0)
	is_consumable = data.get("is_consumable", false)
	icon_path = data.get("icon_path", "")
	visual_effects = data.get("visual_effects", PackedStringArray())
	theme_tags = data.get("theme_tags", PackedStringArray())
