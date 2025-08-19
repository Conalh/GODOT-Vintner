class_name RumorData
extends Resource

## RumorData Resource - Hunt mission definitions with expected rewards and difficulty
## Defines hunt objectives, expected blood sources, and reward structures
## Integrates with SceneManager for hunt transitions and PatronManager for mission generation

@export var id: String = ""
@export var title: String = ""
@export var description: String = ""
@export var hook: String = ""  # One-line hook for the mission
@export var biome: String = "Desert"  # Primary biome for the hunt

## Mission requirements and expectations
@export var expected_notes: PackedStringArray = []  # Emotional notes expected to find
@export var expected_virtues: PackedStringArray = []  # Virtues expected to find
@export var required_blood_sources: int = 1  # Minimum blood sources needed
@export var optional_blood_sources: int = 2  # Additional sources that can be found

## Difficulty and risk assessment
@export var risk_level: String = "Low"  # Low, Medium, High, Extreme
@export var difficulty_rating: int = 1  # 1-10 scale
@export var estimated_duration: float = 15.0  # Estimated time in minutes
@export var recommended_level: int = 1  # Recommended player level

## Reward structure
@export var blood_source_rewards: Dictionary = {}  # Specific blood sources guaranteed
@export var relic_chance: float = 0.0  # Probability of finding a relic (0.0-1.0)
@export var prestige_reward: int = 10  # Base prestige gained
@export var currency_reward: int = 25  # Base currency gained
@export var experience_reward: int = 50  # Base experience gained

## Hunt mechanics and challenges
@export var hunt_type: String = "gathering"  # gathering, assassination, exploration, boss
@export var special_mechanics: PackedStringArray = []  # Unique hunt mechanics
@export var environmental_hazards: PackedStringArray = []  # Hazards to avoid
@export var time_pressure: bool = false  # Whether there's a time limit
@export var stealth_required: bool = false  # Whether stealth is mandatory

## Unlock requirements and progression
@export var unlock_requirements: Dictionary = {}  # What's needed to unlock this rumor
@export var reputation_requirement: int = 0  # Minimum reputation needed
@export var previous_rumor_required: String = ""  # ID of rumor that must be completed first
@export var is_repeatable: bool = true  # Whether this hunt can be repeated

## Visual and thematic elements
@export var rumor_card_art: String = ""  # Path to rumor card artwork
@export var hunt_scene_path: String = ""  # Path to the hunt scene
@export var theme_tags: PackedStringArray = []  # Thematic tags for categorization
@export var mood_description: String = ""  # Atmospheric description

## Validation and utility methods
func is_valid() -> bool:
	"""Validate the rumor data"""
	if id.is_empty() or title.is_empty() or hook.is_empty():
		return false
	
	if required_blood_sources < 1:
		return false
	
	if relic_chance < 0.0 or relic_chance > 1.0:
		return false
	
	# Validate risk level
	var valid_risk_levels = ["Low", "Medium", "High", "Extreme"]
	if not valid_risk_levels.has(risk_level):
		return false
	
	# Validate difficulty rating
	if difficulty_rating < 1 or difficulty_rating > 10:
		return false
	
	return true

func can_be_accessed_by_player(player_data: PlayerData) -> bool:
	"""Check if the player can access this rumor"""
	if player_data.reputation < reputation_requirement:
		return false
	
	# Check other unlock requirements
	for requirement_key in unlock_requirements.keys():
		var requirement_value = unlock_requirements[requirement_key]
		var player_value = player_data.get(requirement_key, 0)
		
		if player_value < requirement_value:
			return false
	
	# Check if previous rumor is required
	if not previous_rumor_required.is_empty():
		if not player_data.completed_rumors.has(previous_rumor_required):
			return false
	
	return true

func get_expected_reward_summary() -> String:
	"""Get a human-readable summary of expected rewards"""
	var summary: String = "Expected Rewards:\n"
	
	# Blood sources
	summary += "• " + str(required_blood_sources) + " blood sources"
	if optional_blood_sources > 0:
		summary += " (+" + str(optional_blood_sources) + " optional)"
	summary += "\n"
	
	# Notes and virtues
	if not expected_notes.is_empty():
		summary += "• Notes: " + ", ".join(expected_notes) + "\n"
	
	if not expected_virtues.is_empty():
		summary += "• Virtues: " + ", ".join(expected_virtues) + "\n"
	
	# Relic chance
	if relic_chance > 0.0:
		summary += "• " + str(int(relic_chance * 100)) + "% chance of relic\n"
	
	# Other rewards
	summary += "• " + str(prestige_reward) + " prestige\n"
	summary += "• " + str(currency_reward) + " currency\n"
	summary += "• " + str(experience_reward) + " experience"
	
	return summary

func get_difficulty_description() -> String:
	"""Get a human-readable difficulty description"""
	var difficulty_text: String = ""
	
	match difficulty_rating:
		1, 2:
			difficulty_text = "Very Easy"
		3, 4:
			difficulty_text = "Easy"
		5, 6:
			difficulty_text = "Moderate"
		7, 8:
			difficulty_text = "Hard"
		9, 10:
			difficulty_text = "Very Hard"
	
	return difficulty_text + " (" + risk_level + " Risk)"

func get_hunt_duration_text() -> String:
	"""Get a human-readable duration description"""
	if estimated_duration < 1.0:
		return "Quick (< 1 minute)"
	elif estimated_duration < 5.0:
		return "Very Short (" + str(int(estimated_duration)) + " minutes)"
	elif estimated_duration < 15.0:
		return "Short (" + str(int(estimated_duration)) + " minutes)"
	elif estimated_duration < 30.0:
		return "Medium (" + str(int(estimated_duration)) + " minutes)"
	else:
		return "Long (" + str(int(estimated_duration)) + " minutes)"

func calculate_reward_multiplier(player_level: int) -> float:
	"""Calculate reward multiplier based on player level vs recommended level"""
	var level_difference = player_level - recommended_level
	
	if level_difference >= 3:
		return 0.7  # Over-leveled, reduced rewards
	elif level_difference >= 1:
		return 0.9  # Slightly over-leveled
	elif level_difference == 0:
		return 1.0  # Perfect level match
	elif level_difference >= -2:
		return 1.2  # Slightly under-leveled, bonus rewards
	else:
		return 1.5  # Significantly under-leveled, major bonus

func get_modified_rewards(player_level: int) -> Dictionary:
	"""Get rewards modified by player level and other factors"""
	var multiplier = calculate_reward_multiplier(player_level)
	
	return {
		"prestige": int(float(prestige_reward) * multiplier),
		"currency": int(float(currency_reward) * multiplier),
		"experience": int(float(experience_reward) * multiplier),
		"relic_chance": relic_chance,
		"blood_sources": required_blood_sources + optional_blood_sources
	}

## Save/Load support
func get_save_data() -> Dictionary:
	"""Get data for saving to persistent storage"""
	return {
		"id": id,
		"title": title,
		"description": description,
		"hook": hook,
		"biome": biome,
		"expected_notes": expected_notes,
		"expected_virtues": expected_virtues,
		"required_blood_sources": required_blood_sources,
		"optional_blood_sources": optional_blood_sources,
		"risk_level": risk_level,
		"difficulty_rating": difficulty_rating,
		"estimated_duration": estimated_duration,
		"recommended_level": recommended_level,
		"blood_source_rewards": blood_source_rewards,
		"relic_chance": relic_chance,
		"prestige_reward": prestige_reward,
		"currency_reward": currency_reward,
		"experience_reward": experience_reward,
		"hunt_type": hunt_type,
		"special_mechanics": special_mechanics,
		"environmental_hazards": environmental_hazards,
		"time_pressure": time_pressure,
		"stealth_required": stealth_required,
		"unlock_requirements": unlock_requirements,
		"reputation_requirement": reputation_requirement,
		"previous_rumor_required": previous_rumor_required,
		"is_repeatable": is_repeatable,
		"rumor_card_art": rumor_card_art,
		"hunt_scene_path": hunt_scene_path,
		"theme_tags": theme_tags,
		"mood_description": mood_description
	}

func load_save_data(data: Dictionary) -> void:
	"""Load data from persistent storage"""
	id = data.get("id", "")
	title = data.get("title", "")
	description = data.get("description", "")
	hook = data.get("hook", "")
	biome = data.get("biome", "Desert")
	expected_notes = data.get("expected_notes", PackedStringArray())
	expected_virtues = data.get("expected_virtues", PackedStringArray())
	required_blood_sources = data.get("required_blood_sources", 1)
	optional_blood_sources = data.get("optional_blood_sources", 2)
	risk_level = data.get("risk_level", "Low")
	difficulty_rating = data.get("difficulty_rating", 1)
	estimated_duration = data.get("estimated_duration", 15.0)
	recommended_level = data.get("recommended_level", 1)
	blood_source_rewards = data.get("blood_source_rewards", {})
	relic_chance = data.get("relic_chance", 0.0)
	prestige_reward = data.get("prestige_reward", 10)
	currency_reward = data.get("currency_reward", 25)
	experience_reward = data.get("experience_reward", 50)
	hunt_type = data.get("hunt_type", "gathering")
	special_mechanics = data.get("special_mechanics", PackedStringArray())
	environmental_hazards = data.get("environmental_hazards", PackedStringArray())
	time_pressure = data.get("time_pressure", false)
	stealth_required = data.get("stealth_required", false)
	unlock_requirements = data.get("unlock_requirements", {})
	reputation_requirement = data.get("reputation_requirement", 0)
	previous_rumor_required = data.get("previous_rumor_required", "")
	is_repeatable = data.get("is_repeatable", true)
	rumor_card_art = data.get("rumor_card_art", "")
	hunt_scene_path = data.get("hunt_scene_path", "")
	theme_tags = data.get("theme_tags", PackedStringArray())
	mood_description = data.get("mood_description", "")
