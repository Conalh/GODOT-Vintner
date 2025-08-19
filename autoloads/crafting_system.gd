extends Node

## Wine crafting system for Hemovintner
## Handles recipe management, crafting logic, and quality calculations

signal recipe_unlocked(recipe_id: String)
signal crafting_started(recipe_id: String, ingredients: Array)
signal crafting_completed(recipe_id: String, result: Dictionary)
signal crafting_failed(recipe_id: String, reason: String)
signal quality_improved(recipe_id: String, old_quality: float, new_quality: float)

## Recipe management
var available_recipes: Array[String] = []
var unlocked_recipes: Array[String] = []
var recipe_templates: Dictionary = {}

## Crafting state
var current_craft: Dictionary = {}
var is_crafting: bool = false
var craft_progress: float = 0.0
var craft_timer: Timer

## Quality and success rates
var base_crafting_success_rate: float = 0.95
var quality_modifiers: Dictionary = {}
var skill_bonuses: Dictionary = {}

func _ready() -> void:
	_initialize_crafting_system()
	_load_recipe_templates()
	_connect_signals()

## Core crafting methods

func start_crafting(recipe_id: String, ingredients: Array[Dictionary]) -> bool:
	"""Begin crafting a wine with the specified ingredients"""
	if is_crafting:
		push_warning("Crafting already in progress")
		return false
	
	if not _can_craft_recipe(recipe_id, ingredients):
		return false
	
	# Validate and consume ingredients
	if not _consume_ingredients(ingredients):
		push_error("Failed to consume ingredients for crafting")
		return false
	
	# Start crafting process
	current_craft = {
		"recipe_id": recipe_id,
		"ingredients": ingredients,
		"start_time": Time.get_time_dict_from_system().get("unix", 0.0),
		"crafting_station": _get_crafting_station(recipe_id)
	}
	
	is_crafting = true
	craft_progress = 0.0
	
	# Start crafting timer
	_start_craft_timer(recipe_id)
	
	crafting_started.emit(recipe_id, ingredients)
	return true

func cancel_crafting() -> bool:
	"""Cancel the current crafting operation and refund ingredients"""
	if not is_crafting:
		return false
	
	# Refund ingredients
	_refund_ingredients(current_craft.ingredients)
	
	# Reset crafting state
	_reset_crafting_state()
	
	return true

func get_crafting_progress() -> float:
	"""Get the current crafting progress (0.0 to 1.0)"""
	return craft_progress

func get_crafting_time_remaining() -> float:
	"""Get the remaining time for the current craft"""
	if not is_crafting or not craft_timer:
		return 0.0
	
	return craft_timer.time_left

## Recipe management methods

func unlock_recipe(recipe_id: String) -> bool:
	"""Unlock a new wine recipe"""
	if recipe_id in unlocked_recipes:
		return false
	
	if not recipe_id in available_recipes:
		push_error("Recipe not available: %s" % recipe_id)
		return false
	
	unlocked_recipes.append(recipe_id)
	recipe_unlocked.emit(recipe_id)
	
	return true

func get_available_recipes() -> Array[String]:
	"""Get all available recipes"""
	return available_recipes.duplicate()

func get_unlocked_recipes() -> Array[String]:
	"""Get all unlocked recipes"""
	return unlocked_recipes.duplicate()

func get_recipe_template(recipe_id: String) -> Dictionary:
	"""Get the template for a specific recipe"""
	return recipe_templates.get(recipe_id, {})

func can_craft_recipe(recipe_id: String) -> bool:
	"""Check if a recipe can be crafted with current ingredients"""
	var recipe: Dictionary = get_recipe_template(recipe_id)
	if recipe.is_empty():
		return false
	
	var required_ingredients: Array = recipe.get("ingredients", [])
	
	for ingredient in required_ingredients:
		var item_id: String = ingredient.get("item_id", "")
		var quantity: int = ingredient.get("quantity", 1)
		
		if not InventorySystem.has_item(item_id, quantity):
			return false
	
	return true

## Quality and calculation methods

func calculate_wine_quality(ingredients: Array[Dictionary], player_skill: float = 1.0) -> float:
	"""Calculate the quality of a wine based on ingredients and player skill"""
	var base_quality: float = 0.5
	var ingredient_quality: float = 0.0
	var ingredient_count: int = ingredients.size()
	
	# Calculate ingredient quality contribution
	for ingredient in ingredients:
		var blood_data: Dictionary = ingredient.get("blood_data", {})
		var purity: float = blood_data.get("purity", 0.5)
		var freshness: float = blood_data.get("freshness", 0.5)
		var emotional_note: GameEnums.EmotionalNote = blood_data.get("emotional_note", GameEnums.EmotionalNote.JOY)
		var virtue: GameEnums.Virtue = blood_data.get("virtue", GameEnums.Virtue.STRENGTH)
		
		# Base ingredient quality
		var ingredient_quality_score: float = (purity + freshness) * 0.5
		
		# Emotional note bonus
		var emotional_bonus: float = _calculate_emotional_bonus(emotional_note)
		
		# Virtue bonus
		var virtue_bonus: float = _calculate_virtue_bonus(virtue)
		
		ingredient_quality += ingredient_quality_score + emotional_bonus + virtue_bonus
	
	# Average ingredient quality
	if ingredient_count > 0:
		ingredient_quality /= ingredient_count
	
	# Player skill bonus
	var skill_bonus: float = (player_skill - 1.0) * 0.2
	
	# Final quality calculation
	var final_quality: float = base_quality + ingredient_quality + skill_bonus
	
	# Clamp quality between 0.0 and 1.0
	return clamp(final_quality, GameConstants.MIN_WINE_QUALITY, GameConstants.MAX_WINE_QUALITY)

func calculate_crafting_success_rate(recipe_id: String, player_skill: float = 1.0) -> float:
	"""Calculate the chance of successful crafting"""
	var base_success: float = base_crafting_success_rate
	var recipe_difficulty: float = _get_recipe_difficulty(recipe_id)
	var skill_modifier: float = (player_skill - 1.0) * 0.1
	
	var final_success_rate: float = base_success - recipe_difficulty + skill_modifier
	
	return clamp(final_success_rate, 0.0, 1.0)

func calculate_crafting_time(recipe_id: String, player_skill: float = 1.0) -> float:
	"""Calculate the time required to craft a wine"""
	var base_time: float = _get_recipe_base_time(recipe_id)
	var skill_modifier: float = 1.0 - (player_skill - 1.0) * 0.2
	
	var final_time: float = base_time * skill_modifier
	
	return max(final_time, 1.0)  # Minimum 1 second

## Save/load methods

func get_save_data() -> Dictionary:
	"""Get crafting system data for saving"""
	return {
		"available_recipes": available_recipes,
		"unlocked_recipes": unlocked_recipes,
		"recipe_templates": recipe_templates,
		"base_crafting_success_rate": base_crafting_success_rate,
		"quality_modifiers": quality_modifiers,
		"skill_bonuses": skill_bonuses
	}

func load_save_data(save_data: Dictionary) -> void:
	"""Load crafting system data from save"""
	if not _validate_save_data(save_data):
		push_error("Invalid save data format for CraftingSystem")
		return
	
	available_recipes = save_data.get("available_recipes", [])
	unlocked_recipes = save_data.get("unlocked_recipes", [])
	recipe_templates = save_data.get("recipe_templates", {})
	base_crafting_success_rate = save_data.get("base_crafting_success_rate", 0.95)
	quality_modifiers = save_data.get("quality_modifiers", {})
	skill_bonuses = save_data.get("skill_bonuses", {})

## Private helper methods

func _initialize_crafting_system() -> void:
	"""Initialize the crafting system"""
	craft_timer = Timer.new()
	craft_timer.one_shot = true
	add_child(craft_timer)

func _load_recipe_templates() -> void:
	"""Load recipe templates from resources"""
	# This would typically load from resource files
	# For now, we'll create some basic templates
	recipe_templates = {
		"basic_blood_wine": {
			"name": "Basic Blood Wine",
			"description": "A simple blood wine for beginners",
			"ingredients": [
				{"item_id": "human_blood", "quantity": 1, "type": "blood_source"}
			],
			"crafting_time": 30.0,
			"difficulty": 0.1,
			"base_price": 100,
			"unlock_level": 1,
			"crafting_station": GameEnums.CraftingStation.BLOOD_EXTRACTOR
		},
		"vampire_essence_wine": {
			"name": "Vampire Essence Wine",
			"description": "A potent wine made with vampire blood",
			"ingredients": [
				{"item_id": "vampire_blood", "quantity": 1, "type": "blood_source"},
				{"item_id": "human_blood", "quantity": 2, "type": "blood_source"}
			],
			"crafting_time": 60.0,
			"difficulty": 0.3,
			"base_price": 250,
			"unlock_level": 3,
			"crafting_station": GameEnums.CraftingStation.WINE_PRESS
		},
		"emotion_blend_wine": {
			"name": "Emotion Blend Wine",
			"description": "A complex wine blending multiple emotional notes",
			"ingredients": [
				{"item_id": "human_blood", "quantity": 3, "type": "blood_source"},
				{"item_id": "vampire_blood", "quantity": 1, "type": "blood_source"}
			],
			"crafting_time": 90.0,
			"difficulty": 0.5,
			"base_price": 400,
			"unlock_level": 5,
			"crafting_station": GameEnums.CraftingStation.BLENDING_VAT
		}
	}
	
	# Set available recipes
	available_recipes = recipe_templates.keys()

func _can_craft_recipe(recipe_id: String, ingredients: Array[Dictionary]) -> bool:
	"""Check if a recipe can be crafted with the given ingredients"""
	var recipe: Dictionary = get_recipe_template(recipe_id)
	if recipe.is_empty():
		return false
	
	if not recipe_id in unlocked_recipes:
		push_error("Recipe not unlocked: %s" % recipe_id)
		return false
	
	# Validate ingredients
	var required_ingredients: Array = recipe.get("ingredients", [])
	if ingredients.size() != required_ingredients.size():
		return false
	
	# Check if ingredients match requirements
	for i in range(ingredients.size()):
		var ingredient: Dictionary = ingredients[i]
		var required: Dictionary = required_ingredients[i]
		
		if ingredient.get("item_id") != required.get("item_id"):
			return false
		
		if ingredient.get("quantity", 1) < required.get("quantity", 1):
			return false
	
	return true

func _consume_ingredients(ingredients: Array[Dictionary]) -> bool:
	"""Consume ingredients from inventory"""
	for ingredient in ingredients:
		var item_id: String = ingredient.get("item_id", "")
		var quantity: int = ingredient.get("quantity", 1)
		
		if not InventorySystem.remove_item(item_id, quantity):
			return false
	
	return true

func _refund_ingredients(ingredients: Array[Dictionary]) -> void:
	"""Refund ingredients to inventory"""
	for ingredient in ingredients:
		var item_id: String = ingredient.get("item_id", "")
		var quantity: int = ingredient.get("quantity", 1)
		
		InventorySystem.add_item(item_id, quantity, ingredient)

func _start_craft_timer(recipe_id: String) -> void:
	"""Start the crafting timer for a recipe"""
	var crafting_time: float = calculate_crafting_time(recipe_id)
	
	craft_timer.wait_time = crafting_time
	craft_timer.timeout.connect(_on_craft_timer_timeout)
	craft_timer.start()

func _on_craft_timer_timeout() -> void:
	"""Handle crafting timer completion"""
	if not is_crafting:
		return
	
	var recipe_id: String = current_craft.get("recipe_id", "")
	var ingredients: Array[Dictionary] = current_craft.get("ingredients", [])
	
	# Calculate success chance
	var success_rate: float = calculate_crafting_success_rate(recipe_id)
	var success: bool = randf() <= success_rate
	
	if success:
		_complete_crafting(recipe_id, ingredients)
	else:
		_fail_crafting(recipe_id, "Crafting failed due to bad luck")
	
	# Reset crafting state
	_reset_crafting_state()

func _complete_crafting(recipe_id: String, ingredients: Array[Dictionary]) -> void:
	"""Complete a successful crafting operation"""
	var recipe: Dictionary = get_recipe_template(recipe_id)
	var player_skill: float = PlayerData.get_stat("intelligence") / 10.0
	
	# Calculate wine quality
	var wine_quality: float = calculate_wine_quality(ingredients, player_skill)
	
	# Create wine result
	var wine_result: Dictionary = {
		"recipe_id": recipe_id,
		"name": recipe.get("name", "Unknown Wine"),
		"description": recipe.get("description", ""),
		"quality": wine_quality,
		"base_price": recipe.get("base_price", 100),
		"crafting_date": Time.get_time_dict_from_system().get("unix", 0.0),
		"ingredients_used": ingredients,
		"crafting_station": current_craft.get("crafting_station", GameEnums.CraftingStation.BLOOD_EXTRACTOR)
	}
	
	# Add wine to inventory
	if InventorySystem.add_wine(recipe_id, wine_result):
		crafting_completed.emit(recipe_id, wine_result)
		
		# Award experience
		var xp_gain: int = int(wine_quality * GameConstants.XP_PER_QUALITY_WINE)
		PlayerData.add_experience(xp_gain)
		
		# Update player stats
		PlayerData.total_wines_crafted += 1
	else:
		crafting_failed.emit(recipe_id, "Failed to add wine to inventory")

func _fail_crafting(recipe_id: String, reason: String) -> void:
	"""Handle a failed crafting operation"""
	crafting_failed.emit(recipe_id, reason)
	
	# Refund ingredients
	_refund_ingredients(current_craft.get("ingredients", []))

func _reset_crafting_state() -> void:
	"""Reset the crafting system state"""
	current_craft = {}
	is_crafting = false
	craft_progress = 0.0
	
	if craft_timer:
		craft_timer.stop()
		craft_timer.timeout.disconnect(_on_craft_timer_timeout)

func _get_crafting_station(recipe_id: String) -> GameEnums.CraftingStation:
	"""Get the required crafting station for a recipe"""
	var recipe: Dictionary = get_recipe_template(recipe_id)
	return recipe.get("crafting_station", GameEnums.CraftingStation.BLOOD_EXTRACTOR)

func _get_recipe_difficulty(recipe_id: String) -> float:
	"""Get the difficulty of a recipe"""
	var recipe: Dictionary = get_recipe_template(recipe_id)
	return recipe.get("difficulty", 0.5)

func _get_recipe_base_time(recipe_id: String) -> float:
	"""Get the base crafting time for a recipe"""
	var recipe: Dictionary = get_recipe_template(recipe_id)
	return recipe.get("crafting_time", 30.0)

func _calculate_emotional_bonus(emotional_note: GameEnums.EmotionalNote) -> float:
	"""Calculate quality bonus from emotional notes"""
	var emotional_bonuses: Dictionary = {
		GameEnums.EmotionalNote.JOY: 0.1,
		GameEnums.EmotionalNote.SORROW: 0.05,
		GameEnums.EmotionalNote.RAGE: 0.15,
		GameEnums.EmotionalNote.FEAR: 0.08,
		GameEnums.EmotionalNote.LOVE: 0.12,
		GameEnums.EmotionalNote.LUST: 0.18,
		GameEnums.EmotionalNote.PRIDE: 0.14,
		GameEnums.EmotionalNote.ENVY: 0.06,
		GameEnums.EmotionalNote.WRATH: 0.16,
		GameEnums.EmotionalNote.SLOTH: 0.02
	}
	
	return emotional_bonuses.get(emotional_note, 0.0)

func _calculate_virtue_bonus(virtue: GameEnums.Virtue) -> float:
	"""Calculate quality bonus from virtues"""
	var virtue_bonuses: Dictionary = {
		GameEnums.Virtue.STRENGTH: 0.08,
		GameEnums.Virtue.AGILITY: 0.06,
		GameEnums.Virtue.INTELLIGENCE: 0.12,
		GameEnums.Virtue.WISDOM: 0.10,
		GameEnums.Virtue.CHARISMA: 0.09,
		GameEnums.Virtue.CONSTITUTION: 0.07,
		GameEnums.Virtue.LUCK: 0.15,
		GameEnums.Virtue.MAGIC: 0.20,
		GameEnums.Virtue.STEALTH: 0.05,
		GameEnums.Virtue.RESISTANCE: 0.04
	}
	
	return virtue_bonuses.get(virtue, 0.0)

func _connect_signals() -> void:
	"""Connect to other system signals"""
	if DataManager:
		DataManager.data_saved.connect(_on_data_saved)
	
	if PlayerData:
		PlayerData.progression_updated.connect(_on_progression_updated)

func _validate_save_data(save_data: Dictionary) -> bool:
	"""Validate save data structure"""
	var required_keys: Array[String] = [
		"available_recipes", "unlocked_recipes", "recipe_templates"
	]
	
	for key in required_keys:
		if not key in save_data:
			return false
	
	return true

func _on_data_saved(save_slot: int) -> void:
	"""Handle data save events"""
	# Crafting data is automatically saved as part of the main save data
	pass

func _on_progression_updated() -> void:
	"""Handle player progression updates"""
	# Check for new recipe unlocks based on level
	var player_level: int = PlayerData.player_level
	
	for recipe_id in available_recipes:
		var recipe: Dictionary = get_recipe_template(recipe_id)
		var unlock_level: int = recipe.get("unlock_level", 1)
		
		if player_level >= unlock_level and not recipe_id in unlocked_recipes:
			unlock_recipe(recipe_id)
