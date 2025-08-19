extends Node

## Core game management system for Hemovintner
## Coordinates all other systems and manages overall game state

signal game_state_changed(old_state: GameEnums.GameState, new_state: GameEnums.GameState)
signal game_paused
signal game_resumed
signal game_saved
signal game_loaded
signal day_cycle_completed
signal hunt_mode_started(zone: GameEnums.GameZone)
signal hunt_mode_ended(success: bool)

## Game state management
var current_game_state: GameEnums.GameState = GameEnums.GameState.MENU
var previous_game_state: GameEnums.GameState = GameEnums.GameState.MENU
var is_paused: bool = false
var is_initialized: bool = false

## Game flow management
var day_cycle_timer: Timer
var current_day: int = 1
var day_progress: float = 0.0
var is_day_cycle_active: bool = false

## Hunt mode management
var current_hunt_zone: GameEnums.GameZone = GameEnums.GameZone.DESERT_DIVE
var hunt_start_time: float = 0.0
var hunt_duration: float = 0.0

## System coordination
var systems_initialized: Dictionary = {}
var initialization_order: Array[String] = [
	"DataManager",
	"PlayerData", 
	"InventorySystem",
	"EconomySystem",
	"CraftingSystem",
	"PatronManager",
	"SceneManager"
]

## Debug and development
var debug_mode: bool = false
var cheat_mode: bool = false
var god_mode: bool = false

func _ready() -> void:
	_initialize_game_manager()
	_connect_system_signals()

## Core game management methods

func initialize_game() -> bool:
	"""Initialize the game and all systems"""
	if is_initialized:
		push_warning("Game already initialized")
		return true
	
	# Initialize systems in order
	for system_name in initialization_order:
		if not _initialize_system(system_name):
			push_error("Failed to initialize system: %s" % system_name)
			return false
	
	is_initialized = true
	change_game_state(GameEnums.GameState.MENU)
	
	return true

func start_new_game() -> bool:
	"""Start a new game session"""
	if not is_initialized:
		if not initialize_game():
			return false
	
	# Reset all systems to initial state
	_reset_all_systems()
	
	# Start day cycle
	_start_day_cycle()
	
	change_game_state(GameEnums.GameState.HUB)
	return true

func load_game(save_slot: int = 0) -> bool:
	"""Load a saved game"""
	if not is_initialized:
		if not initialize_game():
			return false
	
	# Load game data
	var data_manager = get_node_or_null("/root/DataManager")
	if not data_manager or not data_manager.load_game(save_slot):
		push_error("Failed to load game from slot %d" % save_slot)
		return false
	
	# Start day cycle
	_start_day_cycle()
	
	# Determine appropriate game state
	var target_state: GameEnums.GameState = _determine_game_state_from_data()
	change_game_state(target_state)
	
	game_loaded.emit()
	return true

func save_game(save_slot: int = 0) -> bool:
	"""Save the current game"""
	if not is_initialized:
		push_error("Cannot save game before initialization")
		return false
	
	var data_manager = get_node_or_null("/root/DataManager")
	if not data_manager or not data_manager.save_game(save_slot):
		push_error("Failed to save game to slot %d" % save_slot)
		return false
	
	game_saved.emit()
	return true

func pause_game() -> void:
	"""Pause the game"""
	if is_paused:
		return
	
	is_paused = true
	get_tree().paused = true
	game_paused.emit()

func resume_game() -> void:
	"""Resume the game"""
	if not is_paused:
		return
	
	is_paused = false
	get_tree().paused = false
	game_resumed.emit()

func quit_game() -> void:
	"""Quit the game"""
	# Save game before quitting
	save_game()
	
	# Clean up
	_cleanup_game()
	
	# Quit
	get_tree().quit()

## Game state management

func change_game_state(new_state: GameEnums.GameState) -> void:
	"""Change the current game state"""
	if new_state == current_game_state:
		return
	
	previous_game_state = current_game_state
	current_game_state = new_state
	
	_handle_state_change(previous_game_state, new_state)
	game_state_changed.emit(previous_game_state, new_state)

func get_current_game_state() -> GameEnums.GameState:
	"""Get the current game state"""
	return current_game_state

func is_in_game_state(state: GameEnums.GameState) -> bool:
	"""Check if the game is in a specific state"""
	return current_game_state == state

## Day cycle management

func start_day_cycle() -> void:
	"""Start the day cycle timer"""
	if is_day_cycle_active:
		return
	
	is_day_cycle_active = true
	day_progress = 0.0
	
	if day_cycle_timer:
		day_cycle_timer.start()

func pause_day_cycle() -> void:
	"""Pause the day cycle"""
	if not is_day_cycle_active:
		return
	
	is_day_cycle_active = false
	
	if day_cycle_timer:
		day_cycle_timer.paused = true

func resume_day_cycle() -> void:
	"""Resume the day cycle"""
	if is_day_cycle_active:
		return
	
	is_day_cycle_active = true
	
	if day_cycle_timer:
		day_cycle_timer.paused = false

func get_day_progress() -> float:
	"""Get the current day progress (0.0 to 1.0)"""
	return day_progress

func get_current_day() -> int:
	"""Get the current day number"""
	return current_day

## Hunt mode management

func start_hunt_mode(zone: GameEnums.GameZone) -> bool:
	"""Start hunt mode in the specified zone"""
	if not is_in_game_state(GameEnums.GameState.HUB):
		push_error("Must be in hub state to start hunt")
		return false
	
	current_hunt_zone = zone
	var start_time_dict = Time.get_time_dict_from_system()
	hunt_start_time = start_time_dict.get("unix", 0.0)
	
	# Pause day cycle during hunt
	pause_day_cycle()
	
	# Change to hunt state
	change_game_state(GameEnums.GameState.HUNT)
	
	hunt_mode_started.emit(zone)
	return true

func end_hunt_mode(success: bool = true) -> bool:
	"""End hunt mode and return to hub"""
	if not is_in_game_state(GameEnums.GameState.HUNT):
		push_error("Must be in hunt state to end hunt")
		return false
	
	# Calculate hunt duration
	var current_time_dict = Time.get_time_dict_from_system()
	var current_time_float = current_time_dict.get("unix", 0.0)
	hunt_duration = current_time_float - hunt_start_time
	
	# Resume day cycle
	resume_day_cycle()
	
	# Change back to hub state
	change_game_state(GameEnums.GameState.HUB)
	
	hunt_mode_ended.emit(success)
	return true

## System coordination methods

func get_system_status() -> Dictionary:
	"""Get the status of all systems"""
	var status: Dictionary = {}
	
	for system_name in initialization_order:
		status[system_name] = systems_initialized.get(system_name, false)
	
	return status

func is_system_ready(system_name: String) -> bool:
	"""Check if a specific system is ready"""
	return systems_initialized.get(system_name, false)

func get_game_summary() -> Dictionary:
	"""Get a comprehensive summary of the current game state"""
	return {
		"game_state": current_game_state,
		"is_paused": is_paused,
		"is_initialized": is_initialized,
		"current_day": current_day,
		"day_progress": day_progress,
		"is_day_cycle_active": is_day_cycle_active,
		"current_hunt_zone": current_hunt_zone,
		"hunt_duration": hunt_duration,
		"systems_status": get_system_status(),
		"player_level": _get_player_level(),
		"bar_reputation": _get_player_reputation(),
		"currency": _get_economy_currency()
	}

## Save/load methods

func get_save_data() -> Dictionary:
	"""Get game manager data for saving"""
	return {
		"current_game_state": current_game_state,
		"previous_game_state": previous_game_state,
		"is_paused": is_paused,
		"is_initialized": is_initialized,
		"current_day": current_day,
		"day_progress": day_progress,
		"is_day_cycle_active": is_day_cycle_active,
		"current_hunt_zone": current_hunt_zone,
		"hunt_start_time": hunt_start_time,
		"hunt_duration": hunt_duration,
		"debug_mode": debug_mode,
		"cheat_mode": cheat_mode,
		"god_mode": god_mode
	}

func load_save_data(save_data: Dictionary) -> void:
	"""Load game manager data from save"""
	if not _validate_save_data(save_data):
		push_error("Invalid save data format for GameManager")
		return
	
	current_game_state = save_data.get("current_game_state", GameEnums.GameState.MENU)
	previous_game_state = save_data.get("previous_game_state", GameEnums.GameState.MENU)
	is_paused = save_data.get("is_paused", false)
	is_initialized = save_data.get("is_initialized", false)
	current_day = save_data.get("current_day", 1)
	day_progress = save_data.get("day_progress", 0.0)
	is_day_cycle_active = save_data.get("is_day_cycle_active", false)
	current_hunt_zone = save_data.get("current_hunt_zone", GameEnums.GameZone.DESERT_DIVE)
	hunt_start_time = save_data.get("hunt_start_time", 0.0)
	hunt_duration = save_data.get("hunt_duration", 0.0)
	debug_mode = save_data.get("debug_mode", false)
	cheat_mode = save_data.get("cheat_mode", false)
	god_mode = save_data.get("god_mode", false)

## Private helper methods

func _initialize_game_manager() -> void:
	"""Initialize the game manager system"""
	_setup_day_cycle_timer()
	_initialize_systems_dictionary()

func _setup_day_cycle_timer() -> void:
	"""Set up the day cycle timer"""
	day_cycle_timer = Timer.new()
	day_cycle_timer.wait_time = GameConstants.DAY_CYCLE_DURATION
	day_cycle_timer.timeout.connect(_on_day_cycle_timeout)
	add_child(day_cycle_timer)

func _initialize_systems_dictionary() -> void:
	"""Initialize the systems status dictionary"""
	for system_name in initialization_order:
		systems_initialized[system_name] = false

func _initialize_system(system_name: String) -> bool:
	"""Initialize a specific system"""
	# Check if system exists
	var system_node: Node = get_node_or_null("/root/" + system_name)
	if not system_node:
		push_error("System not found: %s" % system_name)
		return false
	
	# Mark system as initialized
	systems_initialized[system_name] = true
	
	return true

func _reset_all_systems() -> void:
	"""Reset all systems to initial state"""
	# Reset player data
	_call_autoload_method_safe("PlayerData", "reset_progression")
	
	# Reset economy
	_call_autoload_method_safe("EconomySystem", "reset_economy")
	
	# Reset inventory
	# InventorySystem reset would go here
	# _call_autoload_method_safe("InventorySystem", "reset_inventory")
	
	# Reset crafting
	# CraftingSystem reset would go here
	# _call_autoload_method_safe("CraftingSystem", "reset_crafting")
	
	# Reset patron manager
	# PatronManager reset would go here
	# _call_autoload_method_safe("PatronManager", "reset_patrons")
	
	# Reset scene manager
	# SceneManager reset would go here
	# _call_autoload_method_safe("SceneManager", "reset_scenes")

func _start_day_cycle() -> void:
	"""Start the day cycle"""
	day_progress = 0.0
	is_day_cycle_active = true
	
	if day_cycle_timer:
		day_cycle_timer.start()

func _handle_state_change(old_state: GameEnums.GameState, new_state: GameEnums.GameState) -> void:
	"""Handle changes in game state"""
	match new_state:
		GameEnums.GameState.MENU:
			_handle_menu_state()
		GameEnums.GameState.HUB:
			_handle_hub_state()
		GameEnums.GameState.HUNT:
			_handle_hunt_state()
		GameEnums.GameState.PAUSED:
			_handle_paused_state()
		GameEnums.GameState.TRANSITIONING:
			_handle_transitioning_state()

func _handle_menu_state() -> void:
	"""Handle entering menu state"""
	pause_day_cycle()
	
	# Pause all game systems
	_call_autoload_method_safe("PatronManager", "pause_spawning")

func _handle_hub_state() -> void:
	"""Handle entering hub state"""
	resume_day_cycle()
	
	# Resume all game systems
	_call_autoload_method_safe("PatronManager", "resume_spawning")

func _handle_hunt_state() -> void:
	"""Handle entering hunt state"""
	pause_day_cycle()
	
	# Pause patron spawning
	_call_autoload_method_safe("PatronManager", "pause_spawning")

func _handle_paused_state() -> void:
	"""Handle entering paused state"""
	# Pause day cycle
	pause_day_cycle()

func _handle_transitioning_state() -> void:
	"""Handle entering transitioning state"""
	# Pause day cycle during transitions
	pause_day_cycle()

func _determine_game_state_from_data() -> GameEnums.GameState:
	"""Determine appropriate game state from loaded data"""
	# Check if player is in hunt mode
	var player_data = _get_autoload_safe("PlayerData")
	if player_data and player_data.has_method("is_in_hunt_mode") and player_data.is_in_hunt_mode:
		return GameEnums.GameState.HUNT
	
	# Default to hub state
	return GameEnums.GameState.HUB

func _cleanup_game() -> void:
	"""Clean up game resources before quitting"""
	# Save game
	save_game()
	
	# Stop timers
	if day_cycle_timer:
		day_cycle_timer.stop()
	
	# Disconnect signals
	_disconnect_system_signals()

func _connect_system_signals() -> void:
	"""Connect to signals from other systems"""
	# Connect to scene manager signals
	var scene_manager = _get_autoload_safe("SceneManager")
	if scene_manager:
		if scene_manager.has_signal("scene_transition_started"):
			scene_manager.scene_transition_started.connect(_on_scene_transition_started)
		if scene_manager.has_signal("scene_transition_completed"):
			scene_manager.scene_transition_completed.connect(_on_scene_transition_completed)
	
	# Connect to player data signals
	var player_data = _get_autoload_safe("PlayerData")
	if player_data:
		if player_data.has_signal("level_up"):
			player_data.level_up.connect(_on_player_level_up)
		if player_data.has_signal("progression_updated"):
			player_data.progression_updated.connect(_on_progression_updated)
	
	# Connect to economy signals
	var economy_system = _get_autoload_safe("EconomySystem")
	if economy_system:
		if economy_system.has_signal("currency_changed"):
			economy_system.currency_changed.connect(_on_currency_changed)
		if economy_system.has_signal("bar_income_banked"):
			economy_system.bar_income_banked.connect(_on_bar_income_banked)
	
	# Connect to crafting signals
	var crafting_system = _get_autoload_safe("CraftingSystem")
	if crafting_system:
		if crafting_system.has_signal("crafting_completed"):
			crafting_system.crafting_completed.connect(_on_crafting_completed)
		if crafting_system.has_signal("recipe_unlocked"):
			crafting_system.recipe_unlocked.connect(_on_recipe_unlocked)
	
	# Connect to patron manager signals
	var patron_manager = _get_autoload_safe("PatronManager")
	if patron_manager:
		if patron_manager.has_signal("patron_satisfied"):
			patron_manager.patron_satisfied.connect(_on_patron_satisfied)
		if patron_manager.has_signal("patron_dissatisfied"):
			patron_manager.patron_dissatisfied.connect(_on_patron_dissatisfied)

func _disconnect_system_signals() -> void:
	"""Disconnect from system signals"""
	# This would disconnect all signal connections
	pass

func _validate_save_data(save_data: Dictionary) -> bool:
	"""Validate save data structure"""
	var required_keys: Array[String] = [
		"current_game_state", "is_initialized", "current_day"
	]
	
	for key in required_keys:
		if not key in save_data:
			return false
	
	return true

## Signal handlers

func _on_day_cycle_timeout() -> void:
	"""Handle day cycle completion"""
	current_day += 1
	day_progress = 0.0
	
	# Complete day in player data
	_call_autoload_method_safe("PlayerData", "complete_day")
	
	# Complete day in economy
	_call_autoload_method_safe("EconomySystem", "complete_day")
	
	day_cycle_completed.emit()
	
	# Restart timer for next day
	if day_cycle_timer:
		day_cycle_timer.start()

func _on_scene_transition_started(from_scene: String, to_scene: String) -> void:
	"""Handle scene transition start"""
	change_game_state(GameEnums.GameState.TRANSITIONING)

func _on_scene_transition_completed(scene_name: String) -> void:
	"""Handle scene transition completion"""
	# Determine appropriate game state based on scene
	var scene_manager = _get_autoload_safe("SceneManager")
	var scene_type: GameEnums.SceneType = GameEnums.SceneType.HUB  # Default
	
	if scene_manager and scene_manager.has_method("get_current_scene_type"):
		scene_type = scene_manager.get_current_scene_type()
	
	match scene_type:
		GameEnums.SceneType.HUB:
			change_game_state(GameEnums.GameState.HUB)
		GameEnums.SceneType.HUNT:
			change_game_state(GameEnums.GameState.HUNT)
		GameEnums.SceneType.MENU:
			change_game_state(GameEnums.GameState.MENU)

func _on_player_level_up(new_level: int, total_xp: int) -> void:
	"""Handle player level up"""
	# Save game on level up
	save_game()
	
	# Check for new unlocks
	_check_level_based_unlocks(new_level)

func _on_progression_updated() -> void:
	"""Handle player progression updates"""
	# Auto-save on progression updates
	_call_autoload_method_safe("DataManager", "auto_save")

func _on_currency_changed(old_amount: int, new_amount: int) -> void:
	"""Handle currency changes"""
	# Auto-save on significant currency changes
	if abs(new_amount - old_amount) > 100:
		_call_autoload_method_safe("DataManager", "auto_save")

func _on_bar_income_banked(amount: int) -> void:
	"""Handle bar income being banked"""
	# Update hunt mode state
	pass

func _on_crafting_completed(recipe_id: String, result: Dictionary) -> void:
	"""Handle crafting completion"""
	# Auto-save on crafting completion
	_call_autoload_method_safe("DataManager", "auto_save")

func _on_recipe_unlocked(recipe_id: String) -> void:
	"""Handle recipe unlock"""
	# Auto-save on recipe unlock
	_call_autoload_method_safe("DataManager", "auto_save")

func _on_patron_satisfied(patron_id: String, satisfaction: float) -> void:
	"""Handle patron satisfaction"""
	# Update reputation tracking
	pass

func _on_patron_dissatisfied(patron_id: String, reason: String) -> void:
	"""Handle patron dissatisfaction"""
	# Update reputation tracking
	pass

## Debug and development methods

func enable_debug_mode() -> void:
	"""Enable debug features"""
	debug_mode = true
	cheat_mode = true
	god_mode = true
	
	# Enable debug in other systems
	_call_autoload_method_safe("PlayerData", "enable_debug_mode")
	_call_autoload_method_safe("EconomySystem", "enable_debug_mode")

func disable_debug_mode() -> void:
	"""Disable debug features"""
	debug_mode = false
	cheat_mode = false
	god_mode = false
	
	# Disable debug in other systems
	_call_autoload_method_safe("PlayerData", "disable_debug_mode")
	_call_autoload_method_safe("EconomySystem", "disable_debug_mode")

func _check_level_based_unlocks(level: int) -> void:
	"""Check for new unlocks based on player level"""
	# This would check various unlock conditions
	pass

## Helper methods for safe autoload access

func _get_player_level() -> int:
	"""Safely get player level from autoload"""
	var player_data = get_node_or_null("/root/PlayerData")
	if player_data and player_data.has_method("get_player_level"):
		return player_data.get_player_level()
	return 1

func _get_player_reputation() -> float:
	"""Safely get player reputation from autoload"""
	var player_data = get_node_or_null("/root/PlayerData")
	if player_data and player_data.has_method("get_bar_reputation"):
		return player_data.get_bar_reputation()
	return 0.0

func _get_economy_currency() -> int:
	"""Safely get economy currency from autoload"""
	var economy_system = get_node_or_null("/root/EconomySystem")
	if economy_system and economy_system.has_method("get_current_currency"):
		return economy_system.get_current_currency()
	return 0

func _get_autoload_safe(autoload_name: String) -> Node:
	"""Safely get an autoload node by name"""
	return get_node_or_null("/root/" + autoload_name)

func _call_autoload_method_safe(autoload_name: String, method_name: String, default_return = null) -> Variant:
	"""Safely call a method on an autoload"""
	var autoload = _get_autoload_safe(autoload_name)
	if autoload and autoload.has_method(method_name):
		return autoload.call(method_name)
	return default_return
