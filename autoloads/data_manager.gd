class_name DataManager
extends Node

## Data persistence and loading system for Hemovintner
## Handles save/load operations, configuration, and data validation

signal data_saved(save_slot: int)
signal data_loaded(save_slot: int)
signal data_deleted(save_slot: int)
signal auto_save_completed
signal save_error(error_message: String)

## Save data structure
var current_save_data: Dictionary = {}
var auto_save_timer: Timer
var is_auto_saving: bool = false

## Configuration data
var game_config: Dictionary = {}
var user_preferences: Dictionary = {}

func _ready() -> void:
	_setup_auto_save()
	_load_user_preferences()
	_validate_save_directory()

## Save system methods

func save_game(save_slot: int = 0) -> bool:
	"""Save the current game state to the specified slot"""
	if is_auto_saving:
		push_warning("Cannot save while auto-save is in progress")
		return false
	
	var save_data: Dictionary = _collect_save_data()
	var file_path: String = _get_save_file_path(save_slot)
	
	var result: bool = _write_save_file(file_path, save_data)
	if result:
		current_save_data = save_data
		data_saved.emit(save_slot)
		_save_metadata(save_slot, save_data)
	
	return result

func load_game(save_slot: int = 0) -> bool:
	"""Load game state from the specified slot"""
	var file_path: String = _get_save_file_path(save_slot)
	
	if not FileAccess.file_exists(file_path):
		push_error("Save file not found: %s" % file_path)
		save_error.emit("Save file not found")
		return false
	
	var save_data: Dictionary = _read_save_file(file_path)
	if save_data.is_empty():
		push_error("Failed to read save file: %s" % file_path)
		save_error.emit("Failed to read save file")
		return false
	
	var result: bool = _apply_save_data(save_data)
	if result:
		current_save_data = save_data
		data_loaded.emit(save_slot)
	
	return result

func delete_save(save_slot: int) -> bool:
	"""Delete the save file from the specified slot"""
	var file_path: String = _get_save_file_path(save_slot)
	var metadata_path: String = _get_metadata_file_path(save_slot)
	
	var result: bool = true
	
	if FileAccess.file_exists(file_path):
		result = result and DirAccess.remove_absolute(file_path) == OK
	
	if FileAccess.file_exists(metadata_path):
		result = result and DirAccess.remove_absolute(metadata_path) == OK
	
	if result:
		data_deleted.emit(save_slot)
	else:
		push_error("Failed to delete save file: %s" % file_path)
	
	return result

func auto_save() -> void:
	"""Perform automatic save operation"""
	if is_auto_saving:
		return
	
	is_auto_saving = true
	var result: bool = save_game(0)  # Auto-save to slot 0
	is_auto_saving = false
	
	if result:
		auto_save_completed.emit()

func get_save_metadata(save_slot: int) -> Dictionary:
	"""Get metadata for a save slot (timestamp, player level, etc.)"""
	var metadata_path: String = _get_metadata_file_path(save_slot)
	
	if not FileAccess.file_exists(metadata_path):
		return {}
	
	var file: FileAccess = FileAccess.open(metadata_path, FileAccess.READ)
	if not file:
		return {}
	
	var metadata: Dictionary = {}
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_result: JSONParseResult = json.parse(json_string)
	
	if parse_result.error == OK:
		metadata = parse_result.data
	else:
		push_error("Failed to parse save metadata: %s" % parse_result.error_string)
	
	return metadata

func get_available_save_slots() -> Array[int]:
	"""Get list of save slots that contain valid save data"""
	var available_slots: Array[int] = []
	
	for slot in range(GameConstants.MAX_SAVE_SLOTS):
		var file_path: String = _get_save_file_path(slot)
		if FileAccess.file_exists(file_path):
			available_slots.append(slot)
	
	return available_slots

## Configuration methods

func save_user_preferences() -> bool:
	"""Save user preferences to disk"""
	var file_path: String = "user://hemovintner_preferences.dat"
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	
	if not file:
		push_error("Failed to open preferences file for writing: %s" % file_path)
		return false
	
	var json_string: String = JSON.stringify(user_preferences)
	file.store_string(json_string)
	file.close()
	
	return true

func load_user_preferences() -> bool:
	"""Load user preferences from disk"""
	var file_path: String = "user://hemovintner_preferences.dat"
	
	if not FileAccess.file_exists(file_path):
		_create_default_preferences()
		return true
	
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Failed to open preferences file for reading: %s" % file_path)
		return false
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_result: JSONParseResult = json.parse(json_string)
	
	if parse_result.error == OK:
		user_preferences = parse_result.data
	else:
		push_error("Failed to parse preferences file: %s" % parse_result.error_string)
		_create_default_preferences()
	
	return true

## Private helper methods

func _setup_auto_save() -> void:
	"""Initialize the auto-save timer"""
	auto_save_timer = Timer.new()
	auto_save_timer.wait_time = GameConstants.AUTO_SAVE_INTERVAL
	auto_save_timer.timeout.connect(auto_save)
	add_child(auto_save_timer)
	auto_save_timer.start()

func _collect_save_data() -> Dictionary:
	"""Collect all necessary data from other systems for saving"""
	var save_data: Dictionary = {
		"version": GameConstants.SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"player_data": {},
		"inventory_data": {},
		"economy_data": {},
		"crafting_data": {},
		"patron_data": {},
		"scene_data": {},
		"game_state": {}
	}
	
	# Collect data from other autoloads if they exist
	if PlayerData:
		save_data.player_data = PlayerData.get_save_data()
	
	if InventorySystem:
		save_data.inventory_data = InventorySystem.get_save_data()
	
	if EconomySystem:
		save_data.economy_data = EconomySystem.get_save_data()
	
	if CraftingSystem:
		save_data.crafting_data = CraftingSystem.get_save_data()
	
	if PatronManager:
		save_data.patron_data = PatronManager.get_save_data()
	
	if SceneManager:
		save_data.scene_data = SceneManager.get_save_data()
	
	if GameManager:
		save_data.game_state = GameManager.get_save_data()
	
	return save_data

func _apply_save_data(save_data: Dictionary) -> bool:
	"""Apply loaded save data to all systems"""
	if not _validate_save_data(save_data):
		push_error("Invalid save data format")
		return false
	
	# Apply data to other autoloads if they exist
	if PlayerData and "player_data" in save_data:
		PlayerData.load_save_data(save_data.player_data)
	
	if InventorySystem and "inventory_data" in save_data:
		InventorySystem.load_save_data(save_data.inventory_data)
	
	if EconomySystem and "economy_data" in save_data:
		EconomySystem.load_save_data(save_data.economy_data)
	
	if CraftingSystem and "crafting_data" in save_data:
		CraftingSystem.load_save_data(save_data.crafting_data)
	
	if PatronManager and "patron_data" in save_data:
		PatronManager.load_save_data(save_data.patron_data)
	
	if SceneManager and "scene_data" in save_data:
		SceneManager.load_save_data(save_data.scene_data)
	
	if GameManager and "game_state" in save_data:
		GameManager.load_save_data(save_data.game_state)
	
	return true

func _validate_save_data(save_data: Dictionary) -> bool:
	"""Validate that save data has the correct structure"""
	var required_keys: Array[String] = [
		"version", "timestamp", "player_data", "inventory_data",
		"economy_data", "crafting_data", "patron_data", "scene_data", "game_state"
	]
	
	for key in required_keys:
		if not key in save_data:
			push_error("Missing required save data key: %s" % key)
			return false
	
	return true

func _get_save_file_path(save_slot: int) -> String:
	"""Get the file path for a specific save slot"""
	return "user://hemovintner_save_%d.dat" % save_slot

func _get_metadata_file_path(save_slot: int) -> String:
	"""Get the metadata file path for a specific save slot"""
	return "user://hemovintner_metadata_%d.dat" % save_slot

func _write_save_file(file_path: String, save_data: Dictionary) -> bool:
	"""Write save data to a file"""
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	
	if not file:
		push_error("Failed to open save file for writing: %s" % file_path)
		return false
	
	var json_string: String = JSON.stringify(save_data)
	file.store_string(json_string)
	file.close()
	
	return true

func _read_save_file(file_path: String) -> Dictionary:
	"""Read save data from a file"""
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	
	if not file:
		push_error("Failed to open save file for reading: %s" % file_path)
		return {}
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_result: JSONParseResult = json.parse(json_string)
	
	if parse_result.error == OK:
		return parse_result.data
	else:
		push_error("Failed to parse save file: %s" % parse_result.error_string)
		return {}

func _save_metadata(save_slot: int, save_data: Dictionary) -> void:
	"""Save metadata for a save slot"""
	var metadata: Dictionary = {
		"slot": save_slot,
		"timestamp": save_data.timestamp,
		"player_level": save_data.player_data.get("level", 1),
		"player_name": save_data.player_data.get("name", "Unknown"),
		"game_time": save_data.game_state.get("total_play_time", 0),
		"bar_reputation": save_data.game_state.get("bar_reputation", 0.0)
	}
	
	var metadata_path: String = _get_metadata_file_path(save_slot)
	var file: FileAccess = FileAccess.open(metadata_path, FileAccess.WRITE)
	
	if file:
		var json_string: String = JSON.stringify(metadata)
		file.store_string(json_string)
		file.close()

func _validate_save_directory() -> void:
	"""Ensure the save directory exists"""
	var save_dir: DirAccess = DirAccess.open("user://")
	if not save_dir:
		push_error("Failed to access user directory")

func _create_default_preferences() -> void:
	"""Create default user preferences"""
	user_preferences = {
		"audio": {
			"master_volume": GameConstants.MASTER_VOLUME_DEFAULT,
			"music_volume": GameConstants.MUSIC_VOLUME_DEFAULT,
			"sfx_volume": GameConstants.SFX_VOLUME_DEFAULT,
			"ambient_volume": GameConstants.AMBIENT_VOLUME_DEFAULT
		},
		"graphics": {
			"fullscreen": false,
			"vsync": true,
			"max_fps": 60,
			"particle_quality": "high"
		},
		"input": {
			"mouse_sensitivity": GameConstants.DEFAULT_MOUSE_SENSITIVITY,
			"gamepad_sensitivity": GameConstants.DEFAULT_GAMEPAD_SENSITIVITY,
			"deadzone": GameConstants.DEFAULT_DEADZONE
		},
		"accessibility": {
			"high_contrast": false,
			"colorblind_mode": "none",
			"text_size": "normal",
			"subtitles": true
		}
	}
	
	save_user_preferences()

func _load_user_preferences() -> void:
	"""Load user preferences on startup"""
	load_user_preferences()
