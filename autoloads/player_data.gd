extends Node

## Player progression and data management system for Hemovintner
## Handles player stats, experience, unlocks, and progression tracking

signal level_up(new_level: int, total_xp: int)
signal stat_changed(stat_name: String, old_value: float, new_value: float)
signal unlock_gained(unlock_id: String, unlock_name: String)
signal progression_updated

## Player basic information
var player_name: String = "Vintner"
var player_level: int = 1
var total_experience: int = 0
var experience_to_next_level: int = 100

## Player stats (base + bonuses)
var base_stats: Dictionary = {
	"strength": 10.0,
	"agility": 10.0,
	"intelligence": 10.0,
	"wisdom": 10.0,
	"charisma": 10.0,
	"constitution": 10.0,
	"luck": 10.0,
	"magic": 10.0,
	"stealth": 10.0,
	"resistance": 10.0
}

var stat_bonuses: Dictionary = {}
var current_stats: Dictionary = {}

## Progression tracking
var bar_reputation: float = 0.0
var total_patrons_served: int = 0
var total_wines_crafted: int = 0
var successful_hunts: int = 0
var total_play_time: float = 0.0
var days_completed: int = 0

## Unlocks and achievements
var unlocked_recipes: Array[String] = []
var unlocked_zones: Array[String] = []
var unlocked_crafting_stations: Array[String] = []
var achievements: Array[String] = []

## Game state tracking
var current_zone: GameEnums.GameZone = GameEnums.GameZone.DESERT_DIVE
var highest_zone_unlocked: GameEnums.GameZone = GameEnums.GameZone.DESERT_DIVE
var is_in_hunt_mode: bool = false
var hunt_start_time: float = 0.0

## Development and debug
var debug_mode: bool = false
var god_mode: bool = false
var unlimited_resources: bool = false

func _ready() -> void:
	_initialize_stats()
	_connect_signals()
	_load_default_unlocks()

## Core progression methods

func add_experience(amount: int) -> void:
	"""Add experience points and check for level up"""
	if amount <= 0:
		return
	
	var old_level: int = player_level
	total_experience += amount
	
	_check_level_up()
	
	if player_level > old_level:
		level_up.emit(player_level, total_experience)
		_unlock_level_based_content()

func gain_reputation(amount: float) -> void:
	"""Increase bar reputation"""
	if amount <= 0.0:
		return
	
	var old_reputation: float = bar_reputation
	bar_reputation = min(bar_reputation + amount, 100.0)
	
	if bar_reputation != old_reputation:
		stat_changed.emit("reputation", old_reputation, bar_reputation)
		_check_reputation_based_unlocks()

func unlock_recipe(recipe_id: String) -> bool:
	"""Unlock a new wine recipe"""
	if recipe_id in unlocked_recipes:
		return false
	
	unlocked_recipes.append(recipe_id)
	unlock_gained.emit(recipe_id, "Recipe: " + recipe_id)
	progression_updated.emit()
	
	return true

func unlock_zone(zone: GameEnums.GameZone) -> bool:
	"""Unlock a new game zone"""
	if zone in unlocked_zones:
		return false
	
	unlocked_zones.append(zone)
	unlock_gained.emit(str(zone), "Zone: " + str(zone))
	
	if zone > highest_zone_unlocked:
		highest_zone_unlocked = zone
	
	progression_updated.emit()
	return true

func unlock_crafting_station(station_id: String) -> bool:
	"""Unlock a new crafting station"""
	if station_id in unlocked_crafting_stations:
		return false
	
	unlocked_crafting_stations.append(station_id)
	unlock_gained.emit(station_id, "Station: " + station_id)
	progression_updated.emit()
	
	return true

## Stat management methods

func get_stat(stat_name: String) -> float:
	"""Get the current value of a stat (base + bonuses)"""
	if not stat_name in current_stats:
		return 0.0
	
	return current_stats[stat_name]

func modify_stat_bonus(stat_name: String, bonus_amount: float) -> void:
	"""Modify the bonus for a specific stat"""
	if not stat_name in base_stats:
		push_warning("Invalid stat name: %s" % stat_name)
		return
	
	var old_value: float = get_stat(stat_name)
	
	if stat_name in stat_bonuses:
		stat_bonuses[stat_name] += bonus_amount
	else:
		stat_bonuses[stat_name] = bonus_amount
	
	_update_stat(stat_name)
	
	var new_value: float = get_stat(stat_name)
	if new_value != old_value:
		stat_changed.emit(stat_name, old_value, new_value)

func reset_stat_bonuses() -> void:
	"""Reset all stat bonuses to zero"""
	var old_stats: Dictionary = current_stats.duplicate()
	stat_bonuses.clear()
	
	for stat_name in base_stats.keys():
		_update_stat(stat_name)
		var new_value: float = get_stat(stat_name)
		if new_value != old_stats[stat_name]:
			stat_changed.emit(stat_name, old_stats[stat_name], new_value)

## Game state methods

func start_hunt() -> void:
	"""Mark the beginning of a hunt session"""
	if is_in_hunt_mode:
		push_warning("Hunt already in progress")
		return
	
	is_in_hunt_mode = true
	var start_time_dict = Time.get_time_dict_from_system()
	hunt_start_time = start_time_dict.get("unix", 0.0)
	var data_manager = get_node_or_null("/root/DataManager")
	if data_manager:
		data_manager.save_game()  # Save before hunt

func end_hunt(success: bool = true) -> void:
	"""Mark the end of a hunt session"""
	if not is_in_hunt_mode:
		push_warning("No hunt in progress")
		return
	
	is_in_hunt_mode = false
	var current_time_dict = Time.get_time_dict_from_system()
	var current_time_float = current_time_dict.get("unix", 0.0)
	var hunt_duration: float = current_time_float - hunt_start_time
	
	if success:
		successful_hunts += 1
		add_experience(GameConstants.XP_PER_SUCCESSFUL_HUNT)
	
	var data_manager = get_node_or_null("/root/DataManager")
	if data_manager:
		data_manager.save_game()  # Save after hunt

func complete_day() -> void:
	"""Mark the completion of a game day"""
	days_completed += 1
	total_play_time += GameConstants.DAY_CYCLE_DURATION
	progression_updated.emit()

## Save/load methods

func get_save_data() -> Dictionary:
	"""Get player data for saving"""
	return {
		"player_name": player_name,
		"player_level": player_level,
		"total_experience": total_experience,
		"experience_to_next_level": experience_to_next_level,
		"base_stats": base_stats,
		"stat_bonuses": stat_bonuses,
		"bar_reputation": bar_reputation,
		"total_patrons_served": total_patrons_served,
		"total_wines_crafted": total_wines_crafted,
		"successful_hunts": successful_hunts,
		"total_play_time": total_play_time,
		"days_completed": days_completed,
		"unlocked_recipes": unlocked_recipes,
		"unlocked_zones": unlocked_zones,
		"unlocked_crafting_stations": unlocked_crafting_stations,
		"achievements": achievements,
		"current_zone": current_zone,
		"highest_zone_unlocked": highest_zone_unlocked,
		"is_in_hunt_mode": is_in_hunt_mode,
		"hunt_start_time": hunt_start_time
	}

func load_save_data(save_data: Dictionary) -> void:
	"""Load player data from save"""
	if not _validate_save_data(save_data):
		push_error("Invalid save data format for PlayerData")
		return
	
	player_name = save_data.get("player_name", "Vintner")
	player_level = save_data.get("player_level", 1)
	total_experience = save_data.get("total_experience", 0)
	experience_to_next_level = save_data.get("experience_to_next_level", 100)
	base_stats = save_data.get("base_stats", base_stats)
	stat_bonuses = save_data.get("stat_bonuses", {})
	bar_reputation = save_data.get("bar_reputation", 0.0)
	total_patrons_served = save_data.get("total_patrons_served", 0)
	total_wines_crafted = save_data.get("total_wines_crafted", 0)
	successful_hunts = save_data.get("successful_hunts", 0)
	total_play_time = save_data.get("total_play_time", 0.0)
	days_completed = save_data.get("days_completed", 0)
	unlocked_recipes = save_data.get("unlocked_recipes", [])
	unlocked_zones = save_data.get("unlocked_zones", [])
	unlocked_crafting_stations = save_data.get("unlocked_crafting_stations", [])
	achievements = save_data.get("achievements", [])
	current_zone = save_data.get("current_zone", GameEnums.GameZone.DESERT_DIVE)
	highest_zone_unlocked = save_data.get("highest_zone_unlocked", GameEnums.GameZone.DESERT_DIVE)
	is_in_hunt_mode = save_data.get("is_in_hunt_mode", false)
	hunt_start_time = save_data.get("hunt_start_time", 0.0)
	
	_update_all_stats()
	progression_updated.emit()

## Private helper methods

func _initialize_stats() -> void:
	"""Initialize the current stats based on base stats and bonuses"""
	for stat_name in base_stats.keys():
		_update_stat(stat_name)

func _update_stat(stat_name: String) -> void:
	"""Update a specific stat's current value"""
	if not stat_name in base_stats:
		return
	
	var base_value: float = base_stats[stat_name]
	var bonus_value: float = stat_bonuses.get(stat_name, 0.0)
	current_stats[stat_name] = base_value + bonus_value

func _update_all_stats() -> void:
	"""Update all stats"""
	for stat_name in base_stats.keys():
		_update_stat(stat_name)

func _check_level_up() -> void:
	"""Check if the player should level up"""
	while total_experience >= experience_to_next_level:
		player_level += 1
		experience_to_next_level = _calculate_next_level_xp()

func _calculate_next_level_xp() -> int:
	"""Calculate experience required for the next level"""
	return int(100 * pow(GameConstants.LEVEL_UP_THRESHOLD_MULTIPLIER, player_level - 1))

func _unlock_level_based_content() -> void:
	"""Unlock content based on player level"""
	match player_level:
		2:
			unlock_crafting_station("wine_press")
		3:
			unlock_recipe("basic_red_wine")
		5:
			unlock_zone(GameEnums.GameZone.NIGHTCLUB)
		7:
			unlock_crafting_station("aging_barrel")
		10:
			unlock_zone(GameEnums.GameZone.VAMPIRE_COURT)

func _check_reputation_based_unlocks() -> void:
	"""Unlock content based on bar reputation"""
	if bar_reputation >= 25.0 and not "premium_ingredients" in unlocked_recipes:
		unlock_recipe("premium_ingredients")
	
	if bar_reputation >= 50.0 and not "exclusive_wines" in unlocked_recipes:
		unlock_recipe("exclusive_wines")
	
	if bar_reputation >= 75.0 and not "vip_service" in unlocked_recipes:
		unlock_recipe("vip_service")

func _load_default_unlocks() -> void:
	"""Load default unlocks for new players"""
	unlocked_recipes.append("basic_blood_wine")
	unlocked_crafting_stations.append("blood_extractor")
	unlocked_zones.append(str(GameEnums.GameZone.DESERT_DIVE)) # Ensure String type for TypedArray

func _connect_signals() -> void:
	"""Connect to other system signals"""
	var data_manager = get_node_or_null("/root/DataManager")
	if data_manager:
		data_manager.data_saved.connect(_on_data_saved)

func _validate_save_data(save_data: Dictionary) -> bool:
	"""Validate save data structure"""
	var required_keys: Array[String] = [
		"player_name", "player_level", "total_experience", "base_stats"
	]
	
	for key in required_keys:
		if not key in save_data:
			return false
	
	return true

func _on_data_saved(save_slot: int) -> void:
	"""Handle data save events"""
	progression_updated.emit()

## Getter methods for external access

func get_player_level() -> int:
	"""Get the current player level"""
	return player_level

func get_bar_reputation() -> float:
	"""Get the current bar reputation"""
	return bar_reputation

## Debug and development methods

func enable_debug_mode() -> void:
	"""Enable debug features"""
	debug_mode = true
	god_mode = true
	unlimited_resources = true

func disable_debug_mode() -> void:
	"""Disable debug features"""
	debug_mode = false
	god_mode = false
	unlimited_resources = false

func add_debug_experience(amount: int) -> void:
	"""Add experience for debugging purposes"""
	if debug_mode:
		add_experience(amount)

func reset_progression() -> void:
	"""Reset all player progression (debug only)"""
	if not debug_mode:
		push_warning("Cannot reset progression outside debug mode")
		return
	
	player_level = 1
	total_experience = 0
	experience_to_next_level = 100
	bar_reputation = 0.0
	total_patrons_served = 0
	total_wines_crafted = 0
	successful_hunts = 0
	total_play_time = 0.0
	days_completed = 0
	
	unlocked_recipes.clear()
	unlocked_zones.clear()
	unlocked_crafting_stations.clear()
	achievements.clear()
	
	current_zone = GameEnums.GameZone.DESERT_DIVE
	highest_zone_unlocked = GameEnums.GameZone.DESERT_DIVE
	
	_load_default_unlocks()
	_update_all_stats()
	progression_updated.emit()
