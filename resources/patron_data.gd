class_name PatronData
extends Resource

## PatronData Resource - Vampire patron archetypes with personality and preferences
## Defines patron behavior, taste preferences, and dialogue styles for the bar system
## Integrates with PatronManager for AI behavior and CraftingSystem for wine preferences

@export var id: String = ""
@export var name: String = ""
@export var title: String = ""  # e.g., "The Count", "Lady Nightshade"
@export var description: String = ""

## Personality and behavior traits
@export var archetype: String = "aristocrat"  # aristocrat, rogue, scholar, warrior, mystic
@export var personality_traits: PackedStringArray = []  # e.g., ["elegant", "demanding", "appreciative"]
@export var mood_swings: float = 0.0  # 0.0 = stable, 1.0 = very volatile
@export var patience_level: float = 0.5  # 0.0 = impatient, 1.0 = very patient

## Taste preferences for wine selection
@export var preferred_notes: PackedStringArray = []  # Emotional notes they prefer
@export var preferred_virtues: PackedStringArray = []  # Virtues they value
@export var preferred_rarity: String = "Select"  # Minimum rarity they'll accept
@export var wine_preferences: Dictionary = {}  # Specific wine IDs they love/hate

## Economic behavior
@export var base_tip_amount: int = 5  # Base tip when satisfied
@export var tip_multiplier: float = 1.0  # Multiplier based on wine quality
@export var max_tip_amount: int = 50  # Maximum tip they'll give
@export var is_generous: bool = false  # Whether they tip above average

## Dialogue and interaction
@export var dialogue_style: String = "formal"  # formal, casual, cutting, poetic, mysterious
@export var one_liners: PackedStringArray = []  # Signature phrases
@export var complaint_phrases: PackedStringArray = []  # What they say when unhappy
@export var praise_phrases: PackedStringArray = []  # What they say when happy

## Visit patterns and timing
@export var visit_frequency: float = 1.0  # How often they visit (1.0 = normal)
@export var preferred_hours: PackedIntArray = []  # Preferred hours (0-23)
@export var stay_duration: float = 1.0  # How long they stay (1.0 = normal)
@export var is_regular: bool = false  # Whether they're a regular customer

## Special requirements and quirks
@export var special_requirements: PackedStringArray = []  # e.g., ["wax_seal", "bat_filigree"]
@export var deal_breakers: PackedStringArray = []  # What will make them leave immediately
@export var loyalty_level: int = 0  # How loyal they are to the bar
@export var unlock_requirements: Dictionary = {}  # What's needed to unlock this patron

## Validation and utility methods
func is_valid() -> bool:
	"""Validate the patron data"""
	if id.is_empty() or name.is_empty():
		return false
	
	if personality_traits.is_empty():
		return false
	
	if preferred_notes.is_empty() and preferred_virtues.is_empty():
		return false
	
	# Validate rarity preference
	var valid_rarities = ["House", "Select", "Reserve", "GrandReserve", "Mythic"]
	if not valid_rarities.has(preferred_rarity):
		return false
	
	return true

func will_accept_wine(wine: WineRecipe) -> bool:
	"""Check if this patron will accept a specific wine"""
	# Check rarity requirement
	var rarity_order = ["House", "Select", "Reserve", "GrandReserve", "Mythic"]
	var wine_rarity_index = rarity_order.find(wine.rarity)
	var preferred_rarity_index = rarity_order.find(preferred_rarity)
	
	if wine_rarity_index < preferred_rarity_index:
		return false
	
	# Check if they have specific preferences
	if wine_preferences.has(wine.id):
		var preference = wine_preferences[wine.id]
		if preference == "love":
			return true
		elif preference == "hate":
			return false
	
	# Check notes and virtues preferences
	var has_preferred_notes = false
	var has_preferred_virtues = false
	
	if preferred_notes.is_empty():
		has_preferred_notes = true
	else:
		for note in preferred_notes:
			if wine.has_note(note):
				has_preferred_notes = true
				break
	
	if preferred_virtues.is_empty():
		has_preferred_virtues = true
	else:
		for virtue in preferred_virtues:
			if wine.has_virtue(virtue):
				has_preferred_virtues = true
				break
	
	return has_preferred_notes and has_preferred_virtues

func calculate_tip_amount(wine: WineRecipe, service_quality: float) -> int:
	"""Calculate the tip amount based on wine and service quality"""
	if not will_accept_wine(wine):
		return 0
	
	var base_tip: int = base_tip_amount
	var quality_bonus: float = 0.0
	
	# Add bonus for wine quality
	var rarity_order = ["House", "Select", "Reserve", "GrandReserve", "Mythic"]
	var wine_rarity_index = rarity_order.find(wine.rarity)
	var preferred_rarity_index = rarity_order.find(preferred_rarity)
	
	if wine_rarity_index > preferred_rarity_index:
		quality_bonus += 2.0
	
	# Add bonus for matching preferences
	if wine.has_note(get_primary_preferred_note()):
		quality_bonus += 1.0
	
	if wine.has_virtue(get_primary_preferred_virtue()):
		quality_bonus += 1.0
	
	# Apply service quality
	var final_tip: int = int(float(base_tip + quality_bonus) * tip_multiplier * service_quality)
	
	# Apply generosity modifier
	if is_generous:
		final_tip = int(float(final_tip) * 1.5)
	
	# Cap at maximum
	return min(final_tip, max_tip_amount)

func get_primary_preferred_note() -> String:
	"""Get the first/primary preferred emotional note"""
	if preferred_notes.size() > 0:
		return preferred_notes[0]
	return ""

func get_primary_preferred_virtue() -> String:
	"""Get the first/primary preferred virtue"""
	if preferred_virtues.size() > 0:
		return preferred_virtues[0]
	return ""

func get_random_one_liner() -> String:
	"""Get a random one-liner from the patron's collection"""
	if one_liners.size() > 0:
		var random_index = randi() % one_liners.size()
		return one_liners[random_index]
	return ""

func get_random_complaint() -> String:
	"""Get a random complaint phrase"""
	if complaint_phrases.size() > 0:
		var random_index = randi() % complaint_phrases.size()
		return complaint_phrases[random_index]
	return ""

func get_random_praise() -> String:
	"""Get a random praise phrase"""
	if praise_phrases.size() > 0:
		var random_index = randi() % praise_phrases.size()
		return praise_phrases[random_index]
	return ""

func is_available_at_hour(hour: int) -> bool:
	"""Check if this patron is available at a specific hour"""
	if preferred_hours.is_empty():
		return true  # Available all hours if no preference specified
	
	return preferred_hours.has(hour)

## Save/Load support
func get_save_data() -> Dictionary:
	"""Get data for saving to persistent storage"""
	return {
		"id": id,
		"name": name,
		"title": title,
		"description": description,
		"archetype": archetype,
		"personality_traits": personality_traits,
		"mood_swings": mood_swings,
		"patience_level": patience_level,
		"preferred_notes": preferred_notes,
		"preferred_virtues": preferred_virtues,
		"preferred_rarity": preferred_rarity,
		"wine_preferences": wine_preferences,
		"base_tip_amount": base_tip_amount,
		"tip_multiplier": tip_multiplier,
		"max_tip_amount": max_tip_amount,
		"is_generous": is_generous,
		"dialogue_style": dialogue_style,
		"one_liners": one_liners,
		"complaint_phrases": complaint_phrases,
		"praise_phrases": praise_phrases,
		"visit_frequency": visit_frequency,
		"preferred_hours": preferred_hours,
		"stay_duration": stay_duration,
		"is_regular": is_regular,
		"special_requirements": special_requirements,
		"deal_breakers": deal_breakers,
		"loyalty_level": loyalty_level,
		"unlock_requirements": unlock_requirements
	}

func load_save_data(data: Dictionary) -> void:
	"""Load data from persistent storage"""
	id = data.get("id", "")
	name = data.get("name", "")
	title = data.get("title", "")
	description = data.get("description", "")
	archetype = data.get("archetype", "aristocrat")
	personality_traits = data.get("personality_traits", PackedStringArray())
	mood_swings = data.get("mood_swings", 0.0)
	patience_level = data.get("patience_level", 0.5)
	preferred_notes = data.get("preferred_notes", PackedStringArray())
	preferred_virtues = data.get("preferred_virtues", PackedStringArray())
	preferred_rarity = data.get("preferred_rarity", "Select")
	wine_preferences = data.get("wine_preferences", {})
	base_tip_amount = data.get("base_tip_amount", 5)
	tip_multiplier = data.get("tip_multiplier", 1.0)
	max_tip_amount = data.get("max_tip_amount", 50)
	is_generous = data.get("is_generous", false)
	dialogue_style = data.get("dialogue_style", "formal")
	one_liners = data.get("one_liners", PackedStringArray())
	complaint_phrases = data.get("complaint_phrases", PackedStringArray())
	praise_phrases = data.get("praise_phrases", PackedStringArray())
	visit_frequency = data.get("visit_frequency", 1.0)
	preferred_hours = data.get("preferred_hours", PackedIntArray())
	stay_duration = data.get("stay_duration", 1.0)
	is_regular = data.get("is_regular", false)
	special_requirements = data.get("special_requirements", PackedStringArray())
	deal_breakers = data.get("deal_breakers", PackedStringArray())
	loyalty_level = data.get("loyalty_level", 0)
	unlock_requirements = data.get("unlock_requirements", {})
