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
	if not DataManager.load_game(save_slot):
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
	
	if not DataManager.save_game(save_slot):
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
	hunt_start_time = Time.get_time_dict_from_system()
	
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
	hunt_duration = Time.get_time_dict_from_system() - hunt_start_time
	
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
		"player_level": PlayerData.player_level if PlayerData else 0,
		"bar_reputation": PlayerData.bar_reputation if PlayerData else 0.0,
		"currency": EconomySystem.current_currency if EconomySystem else 0
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
	if PlayerData:
		PlayerData.reset_progression()
	
	# Reset economy
	if EconomySystem:
		EconomySystem.reset_economy()
	
	# Reset inventory
	if InventorySystem:
		# Clear all items
		pass
	
	# Reset crafting
	if CraftingSystem:
		# Reset crafting state
		pass
	
	# Reset patron manager
	if PatronManager:
		# Clear active patrons
		pass
	
	# Reset scene manager
	if SceneManager:
		# Reset scene history
		pass

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
	if PatronManager:
		PatronManager.pause_spawning()

func _handle_hub_state() -> void:
	"""Handle entering hub state"""
	resume_day_cycle()
	
	# Resume all game systems
	if PatronManager:
		PatronManager.resume_spawning()

func _handle_hunt_state() -> void:
	"""Handle entering hunt state"""
	pause_day_cycle()
	
	# Pause patron spawning
	if PatronManager:
		PatronManager.pause_spawning()

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
	if PlayerData and PlayerData.is_in_hunt_mode:
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
	if SceneManager:
		SceneManager.scene_transition_started.connect(_on_scene_transition_started)
		SceneManager.scene_transition_completed.connect(_on_scene_transition_completed)
	
	# Connect to player data signals
	if PlayerData:
		PlayerData.level_up.connect(_on_player_level_up)
		PlayerData.progression_updated.connect(_on_progression_updated)
	
	# Connect to economy signals
	if EconomySystem:
		EconomySystem.currency_changed.connect(_on_currency_changed)
		EconomySystem.bar_income_banked.connect(_on_bar_income_banked)
	
	# Connect to crafting signals
	if CraftingSystem:
		CraftingSystem.crafting_completed.connect(_on_crafting_completed)
		CraftingSystem.recipe_unlocked.connect(_on_recipe_unlocked)
	
	# Connect to patron manager signals
	if PatronManager:
		PatronManager.patron_satisfied.connect(_on_patron_satisfied)
		PatronManager.patron_dissatisfied.connect(_on_patron_dissatisfied)

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
	if PlayerData:
		PlayerData.complete_day()
	
	# Complete day in economy
	if EconomySystem:
		EconomySystem.complete_day()
	
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
	var scene_type: GameEnums.SceneType = SceneManager.get_current_scene_type()
	
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
	DataManager.auto_save()

func _on_currency_changed(old_amount: int, new_amount: int) -> void:
	"""Handle currency changes"""
	# Auto-save on significant currency changes
	if abs(new_amount - old_amount) > 100:
		DataManager.auto_save()

func _on_bar_income_banked(amount: int) -> void:
	"""Handle bar income being banked"""
	# Update hunt mode state
	pass

func _on_crafting_completed(recipe_id: String, result: Dictionary) -> void:
	"""Handle crafting completion"""
	# Auto-save on crafting completion
	DataManager.auto_save()

func _on_recipe_unlocked(recipe_id: String) -> void:
	"""Handle recipe unlock"""
	# Auto-save on recipe unlock
	DataManager.auto_save()

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
	if PlayerData:
		PlayerData.enable_debug_mode()
	
	if EconomySystem:
		EconomySystem.enable_debug_mode()

func disable_debug_mode() -> void:
	"""Disable debug features"""
	debug_mode = false
	cheat_mode = false
	god_mode = false
	
	# Disable debug in other systems
	if PlayerData:
		PlayerData.disable_debug_mode()
	
	if EconomySystem:
		EconomySystem.disable_debug_mode()

func _check_level_based_unlocks(level: int) -> void:
	"""Check for new unlocks based on player level"""
	# This would check various unlock conditions
	pass
