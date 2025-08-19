class_name SceneManager
extends Node

## Scene management system for Hemovintner
## Handles scene transitions, loading, and the hub-and-spoke architecture

signal scene_transition_started(from_scene: String, to_scene: String)
signal scene_transition_completed(scene_name: String)
signal scene_loading_started(scene_path: String)
signal scene_loading_completed(scene_name: String)
signal scene_error(error_message: String)

## Scene management state
var current_scene: Node
var current_scene_path: String = ""
var current_scene_type: GameEnums.SceneType = GameEnums.SceneType.MENU
var is_transitioning: bool = false
var transition_fade_duration: float = GameConstants.SCREEN_FADE_DURATION

## Scene paths and configuration
var scene_paths: Dictionary = {
	"main_menu": GameConstants.MAIN_MENU_SCENE,
	"main_hub": GameConstants.MAIN_HUB_SCENE,
	"desert_level": GameConstants.DESERT_LEVEL_SCENE,
	"nightclub_level": GameConstants.NIGHTCLUB_LEVEL_SCENE,
	"vampire_court": GameConstants.VAMPIRE_COURT_SCENE
}

var scene_types: Dictionary = {
	"main_menu": GameEnums.SceneType.MENU,
	"main_hub": GameEnums.SceneType.HUB,
	"desert_level": GameEnums.SceneType.HUNT,
	"nightclub_level": GameEnums.SceneType.HUNT,
	"vampire_court": GameEnums.SceneType.HUNT
}

## Transition management
var transition_scene: Node
var fade_animation_player: AnimationPlayer
var loading_screen: Control

## Scene history and navigation
var scene_history: Array[String] = []
var max_scene_history: int = 10

func _ready() -> void:
	_initialize_scene_manager()
	_connect_signals()

## Core scene management methods

func change_scene(scene_name: String, transition_type: String = "fade") -> bool:
	"""Change to a different scene with optional transition effect"""
	if is_transitioning:
		push_warning("Scene transition already in progress")
		return false
	
	if not scene_name in scene_paths:
		push_error("Unknown scene: %s" % scene_name)
		return false
	
	var target_scene_path: String = scene_paths[scene_name]
	var target_scene_type: GameEnums.SceneType = scene_types[scene_name]
	
	# Start transition
	is_transitioning = true
	scene_transition_started.emit(current_scene_path, target_scene_path)
	
	# Handle different transition types
	match transition_type:
		"fade":
			_start_fade_transition(target_scene_path, scene_name, target_scene_type)
		"instant":
			_start_instant_transition(target_scene_path, scene_name, target_scene_type)
		"slide":
			_start_slide_transition(target_scene_path, scene_name, target_scene_type)
		_:
			_start_fade_transition(target_scene_path, scene_name, target_scene_type)
	
	return true

func return_to_hub() -> bool:
	"""Return to the main hub scene from any hunt scene"""
	if current_scene_type == GameEnums.SceneType.HUB:
		push_warning("Already in hub scene")
		return false
	
	return change_scene("main_hub", "fade")

func start_hunt(zone: GameEnums.GameZone) -> bool:
	"""Start a hunt in the specified zone"""
	if current_scene_type != GameEnums.SceneType.HUB:
		push_error("Must be in hub scene to start hunt")
		return false
	
	var scene_name: String = _get_zone_scene_name(zone)
	if scene_name.is_empty():
		push_error("Invalid zone for hunt: %s" % zone)
		return false
	
	# Prepare hunt mode
	_prepare_hunt_mode(zone)
	
	return change_scene(scene_name, "fade")

func return_from_hunt() -> bool:
	"""Return from hunt to hub scene"""
	if current_scene_type != GameEnums.SceneType.HUNT:
		push_warning("Not in hunt scene")
		return false
	
	# Complete hunt mode
	_complete_hunt_mode()
	
	return change_scene("main_hub", "fade")

func reload_current_scene() -> bool:
	"""Reload the current scene"""
	if current_scene_path.is_empty():
		return false
	
	var scene_name: String = _get_scene_name_from_path(current_scene_path)
	if scene_name.is_empty():
		return false
	
	return change_scene(scene_name, "instant")

## Scene information methods

func get_current_scene_name() -> String:
	"""Get the name of the current scene"""
	return _get_scene_name_from_path(current_scene_path)

func get_current_scene_type() -> GameEnums.SceneType:
	"""Get the type of the current scene"""
	return current_scene_type

func is_in_hub() -> bool:
	"""Check if currently in a hub scene"""
	return current_scene_type == GameEnums.SceneType.HUB

func is_in_hunt() -> bool:
	"""Check if currently in a hunt scene"""
	return current_scene_type == GameEnums.SceneType.HUNT

func is_in_menu() -> bool:
	"""Check if currently in a menu scene"""
	return current_scene_type == GameEnums.SceneType.MENU

func get_scene_history() -> Array[String]:
	"""Get the scene navigation history"""
	return scene_history.duplicate()

func can_return_to_previous_scene() -> bool:
	"""Check if there's a previous scene to return to"""
	return scene_history.size() > 1

func return_to_previous_scene() -> bool:
	"""Return to the previous scene in history"""
	if not can_return_to_previous_scene():
		return false
	
	# Remove current scene from history
	scene_history.pop_back()
	
	# Get previous scene
	var previous_scene: String = scene_history[scene_history.size() - 1]
	
	return change_scene(previous_scene, "fade")

## Transition effect methods

func set_transition_duration(duration: float) -> void:
	"""Set the duration for scene transitions"""
	transition_fade_duration = duration

func enable_loading_screen(enable: bool) -> void:
	"""Enable or disable the loading screen during transitions"""
	# This would show/hide a loading screen UI
	pass

## Save/load methods

func get_save_data() -> Dictionary:
	"""Get scene manager data for saving"""
	return {
		"current_scene_path": current_scene_path,
		"current_scene_type": current_scene_type,
		"scene_history": scene_history,
		"transition_fade_duration": transition_fade_duration
	}

func load_save_data(save_data: Dictionary) -> void:
	"""Load scene manager data from save"""
	if not _validate_save_data(save_data):
		push_error("Invalid save data format for SceneManager")
		return
	
	current_scene_path = save_data.get("current_scene_path", "")
	current_scene_type = save_data.get("current_scene_type", GameEnums.SceneType.MENU)
	scene_history = save_data.get("scene_history", [])
	transition_fade_duration = save_data.get("transition_fade_duration", GameConstants.SCREEN_FADE_DURATION)

## Private helper methods

func _initialize_scene_manager() -> void:
	"""Initialize the scene management system"""
	# Set initial scene
	current_scene = get_tree().current_scene
	if current_scene:
		current_scene_path = current_scene.scene_file_path
		current_scene_type = _get_scene_type_from_path(current_scene_path)
		scene_history.append(_get_scene_name_from_path(current_scene_path))

func _start_fade_transition(target_scene_path: String, scene_name: String, scene_type: GameEnums.SceneType) -> void:
	"""Start a fade transition to the target scene"""
	# Create fade overlay
	var fade_overlay: ColorRect = ColorRect.new()
	fade_overlay.color = Color.BLACK
	fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_overlay.modulate.a = 0.0
	
	# Add to current scene
	if current_scene:
		current_scene.add_child(fade_overlay)
	
	# Create fade animation
	var tween: Tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 1.0, transition_fade_duration / 2.0)
	tween.tween_callback(_load_target_scene.bind(target_scene_path, scene_name, scene_type))
	tween.tween_property(fade_overlay, "modulate:a", 0.0, transition_fade_duration / 2.0)
	tween.tween_callback(_complete_transition.bind(scene_name))

func _start_instant_transition(target_scene_path: String, scene_name: String, scene_type: GameEnums.SceneType) -> void:
	"""Start an instant transition to the target scene"""
	_load_target_scene(target_scene_path, scene_name, scene_type)
	_complete_transition(scene_name)

func _start_slide_transition(target_scene_path: String, scene_name: String, scene_type: GameEnums.SceneType) -> void:
	"""Start a slide transition to the target scene"""
	# For now, use fade transition as fallback
	_start_fade_transition(target_scene_path, scene_name, scene_type)

func _load_target_scene(scene_path: String, scene_name: String, scene_type: GameEnums.SceneType) -> void:
	"""Load the target scene"""
	scene_loading_started.emit(scene_path)
	
	# Save current scene to history
	if current_scene_path != scene_path:
		scene_history.append(scene_name)
		
		# Limit history size
		if scene_history.size() > max_scene_history:
			scene_history.remove_at(0)
	
	# Load the new scene
	var scene_resource: PackedScene = load(scene_path)
	if not scene_resource:
		scene_error.emit("Failed to load scene: %s" % scene_path)
		is_transitioning = false
		return
	
	# Instance the scene
	var new_scene: Node = scene_resource.instantiate()
	if not new_scene:
		scene_error.emit("Failed to instantiate scene: %s" % scene_path)
		is_transitioning = false
		return
	
	# Add to scene tree
	get_tree().root.add_child(new_scene)
	
	# Set as current scene
	get_tree().current_scene = new_scene
	
	# Remove old scene
	if current_scene and current_scene != new_scene:
		current_scene.queue_free()
	
	# Update current scene reference
	current_scene = new_scene
	current_scene_path = scene_path
	current_scene_type = scene_type
	
	scene_loading_completed.emit(scene_name)

func _complete_transition(scene_name: String) -> void:
	"""Complete the scene transition"""
	is_transitioning = false
	scene_transition_completed.emit(scene_name)

func _prepare_hunt_mode(zone: GameEnums.GameZone) -> void:
	"""Prepare the game for hunt mode"""
	# Update player state
	PlayerData.start_hunt()
	
	# Update economy state
	EconomySystem.start_hunt_mode()
	
	# Update patron manager
	PatronManager.pause_spawning()
	
	# Save game state
	DataManager.save_game()

func _complete_hunt_mode() -> void:
	"""Complete hunt mode and return to hub"""
	# Update player state
	PlayerData.end_hunt()
	
	# Update economy state
	EconomySystem.end_hunt_mode()
	
	# Update patron manager
	PatronManager.resume_spawning()
	
	# Save game state
	DataManager.save_game()

func _get_zone_scene_name(zone: GameEnums.GameZone) -> String:
	"""Get the scene name for a specific zone"""
	match zone:
		GameEnums.GameZone.DESERT_DIVE:
			return "desert_level"
		GameEnums.GameZone.NIGHTCLUB:
			return "nightclub_level"
		GameEnums.GameZone.VAMPIRE_COURT:
			return "vampire_court"
		_:
			return ""

func _get_scene_name_from_path(scene_path: String) -> String:
	"""Extract scene name from scene path"""
	if scene_path.is_empty():
		return ""
	
	var path_parts: PackedStringArray = scene_path.split("/")
	var filename: String = path_parts[path_parts.size() - 1]
	var name_parts: PackedStringArray = filename.split(".")
	
	return name_parts[0]

func _get_scene_type_from_path(scene_path: String) -> GameEnums.SceneType:
	"""Determine scene type from scene path"""
	var scene_name: String = _get_scene_name_from_path(scene_path)
	
	if scene_name in scene_types:
		return scene_types[scene_name]
	
	# Default to menu if unknown
	return GameEnums.SceneType.MENU

func _connect_signals() -> void:
	"""Connect to other system signals"""
	if DataManager:
		DataManager.data_saved.connect(_on_data_saved)

func _validate_save_data(save_data: Dictionary) -> bool:
	"""Validate save data structure"""
	var required_keys: Array[String] = [
		"current_scene_path", "current_scene_type"
	]
	
	for key in required_keys:
		if not key in save_data:
			return false
	
	return true

func _on_data_saved(save_slot: int) -> void:
	"""Handle data save events"""
	# Scene data is automatically saved as part of the main save data
	pass

## Debug and development methods

func enable_debug_mode() -> void:
	"""Enable debug features for scene management"""
	if PlayerData and PlayerData.debug_mode:
		# Enable debug logging
		pass

func disable_debug_mode() -> void:
	"""Disable debug features for scene management"""
	if PlayerData and not PlayerData.debug_mode:
		# Disable debug logging
		pass

func get_debug_info() -> Dictionary:
	"""Get debug information about the scene manager"""
	return {
		"current_scene_path": current_scene_path,
		"current_scene_type": current_scene_type,
		"is_transitioning": is_transitioning,
		"scene_history": scene_history,
		"transition_duration": transition_fade_duration,
		"available_scenes": scene_paths.keys()
	}
