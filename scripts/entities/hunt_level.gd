class_name HuntLevel
extends Node2D

## Basic procedural room structure for hunt areas
## Provides room generation, enemy spawning, and hunt completion logic

# Level properties
@export var level_width: int = 800
@export var level_height: int = 600
@export var room_count: int = 5
@export var max_enemies: int = 12
@export var hunt_duration: float = 300.0  # 5 minutes
@export var difficulty_multiplier: float = 1.0

# Hunt state
var is_hunt_active: bool = false
var hunt_timer: float = 0.0
var enemies_remaining: int = 0
var blood_sources_found: int = 0
var relics_found: int = 0
var current_rumor: RumorData = null
var hunt_completed: bool = false

# Room generation
var rooms: Array[Dictionary] = []
var current_room: int = 0
var room_connections: Dictionary = {}
var spawn_points: Array[Vector2] = []
var exit_points: Array[Vector2] = []

# Enemy management
var active_enemies: Array[Node2D] = []
var enemy_spawn_timer: float = 0.0
var enemy_spawn_interval: float = 10.0
var max_concurrent_enemies: int = 6

# Visual elements
@onready var level_background: Sprite2D = $LevelBackground
@onready var room_container: Node2D = $RoomContainer
@onready var enemy_container: Node2D = $EnemyContainer
@onready var item_container: Node2D = $ItemContainer
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var exit_portal: Area2D = $ExitPortal

# UI elements
@onready var hunt_ui: Control = $HuntUI
@onready var timer_label: Label = $HuntUI/TimerLabel
@onready var enemy_count_label: Label = $HuntUI/EnemyCountLabel
@onready var progress_bar: ProgressBar = $HuntUI/ProgressBar
@onready var objective_label: Label = $HuntUI/ObjectiveLabel
@onready var completion_ui: Control = $HuntUI/CompletionUI

# Audio
@onready var ambient_music: AudioStreamPlayer = $AmbientMusic
@onready var battle_music: AudioStreamPlayer = $BattleMusic
@onready var victory_fanfare: AudioStreamPlayer = $VictoryFanfare
@onready var enemy_spawn_sound: AudioStreamPlayer = $EnemySpawnSound

func _ready() -> void:
	_setup_hunt_level()
	_generate_level()
	_setup_ui()
	_connect_signals()

func _setup_hunt_level() -> void:
	"""Initialize the hunt level setup"""
	# Set up level background
	if level_background:
		level_background.texture = preload("res://assets/sprites/hunt_background.png")
		level_background.modulate = Color.DARK_GRAY
	
	# Set up exit portal
	if exit_portal:
		exit_portal.body_entered.connect(_on_exit_portal_entered)

func _generate_level() -> void:
	"""Generate the procedural level structure"""
	_generate_rooms()
	_connect_rooms()
	_place_spawn_points()
	_place_exit_points()
	_spawn_initial_items()

func _generate_rooms() -> void:
	"""Generate individual rooms for the level"""
	rooms.clear()
	
	for i in range(room_count):
		var room: Dictionary = _create_room(i)
		rooms.append(room)
		
		# Create room visual representation
		_create_room_visual(room)

func _create_room(room_index: int) -> Dictionary:
	"""Create a single room with procedural properties"""
	var room: Dictionary = {}
	
	# Room dimensions
	room["width"] = randi_range(120, 200)
	room["height"] = randi_range(120, 200)
	
	# Room position (avoid overlap)
	var attempts: int = 0
	var valid_position: bool = false
	var position: Vector2
	
	while not valid_position and attempts < 50:
		position = Vector2(
			randi_range(50, level_width - 250),
			randi_range(50, level_height - 250)
		)
		
		valid_position = _is_position_valid(position, room["width"], room["height"])
		attempts += 1
	
	room["position"] = position
	room["center"] = position + Vector2(room["width"] / 2, room["height"] / 2)
	room["index"] = room_index
	
	# Room properties
	room["enemy_count"] = randi_range(1, 3)
	room["item_count"] = randi_range(0, 2)
	room["difficulty"] = randi_range(1, 5)
	room["is_cleared"] = false
	
	return room

func _is_position_valid(position: Vector2, width: int, height: int) -> bool:
	"""Check if a room position is valid (no overlap)"""
	for existing_room in rooms:
		var existing_pos: Vector2 = existing_room["position"]
		var existing_width: int = existing_room["width"]
		var existing_height: int = existing_room["height"]
		
		# Check for overlap
		if position.x < existing_pos.x + existing_width and \
		   position.x + width > existing_pos.x and \
		   position.y < existing_pos.y + existing_height and \
		   position.y + height > existing_pos.y:
			return false
	
	return true

func _create_room_visual(room: Dictionary) -> void:
	"""Create visual representation of a room"""
	if not room_container:
		return
	
	var room_node: Node2D = Node2D.new()
	room_node.name = "Room" + str(room["index"])
	room_node.position = room["position"]
	
	# Room background
	var room_bg: ColorRect = ColorRect.new()
	room_bg.custom_minimum_size = Vector2(room["width"], room["height"])
	room_bg.color = _get_room_color(room["difficulty"])
	room_bg.modulate.a = 0.3
	room_node.add_child(room_bg)
	
	# Room border
	var room_border: ColorRect = ColorRect.new()
	room_border.custom_minimum_size = Vector2(room["width"], 2)
	room_border.color = Color.WHITE
	room_border.modulate.a = 0.5
	room_node.add_child(room_border)
	
	# Room label
	var room_label: Label = Label.new()
	room_label.text = "Room " + str(room["index"] + 1)
	room_label.position = Vector2(5, 5)
	room_label.modulate = Color.WHITE
	room_node.add_child(room_label)
	
	room_container.add_child(room_node)

func _get_room_color(difficulty: int) -> Color:
	"""Get room color based on difficulty"""
	match difficulty:
		1: return Color.GREEN
		2: return Color.YELLOW
		3: return Color.ORANGE
		4: return Color.RED
		5: return Color.PURPLE
		_: return Color.GRAY

func _connect_rooms() -> void:
	"""Create connections between rooms"""
	room_connections.clear()
	
	for i in range(rooms.size() - 1):
		var current_room: Dictionary = rooms[i]
		var next_room: Dictionary = rooms[i + 1]
		
		# Create connection path
		var connection: Dictionary = _create_room_connection(current_room, next_room)
		room_connections[i] = connection
		
		# Visualize connection
		_create_connection_visual(connection)

func _create_room_connection(room1: Dictionary, room2: Dictionary) -> Dictionary:
	"""Create a connection between two rooms"""
	var connection: Dictionary = {}
	
	connection["start"] = room1["center"]
	connection["end"] = room2["center"]
	connection["width"] = 20
	connection["is_cleared"] = false
	
	return connection

func _create_connection_visual(connection: Dictionary) -> void:
	"""Create visual representation of room connection"""
	if not room_container:
		return
	
	var connection_node: Node2D = Node2D.new()
	connection_node.name = "Connection"
	
	# Connection line
	var connection_line: Line2D = Line2D.new()
	connection_line.points = [connection["start"], connection["end"]]
	connection_line.width = connection["width"]
	connection_line.default_color = Color.WHITE
	connection_line.modulate.a = 0.4
	connection_node.add_child(connection_line)
	
	room_container.add_child(connection_node)

func _place_spawn_points() -> void:
	"""Place enemy and item spawn points throughout the level"""
	spawn_points.clear()
	
	for room in rooms:
		var room_spawns: int = room["enemy_count"] + room["item_count"]
		
		for i in range(room_spawns):
			var spawn_pos: Vector2 = _get_random_position_in_room(room)
			spawn_points.append(spawn_pos)

func _get_random_position_in_room(room: Dictionary) -> Vector2:
	"""Get a random position within a room"""
	var margin: int = 20
	var x: float = room["position"].x + margin + randf_range(0, room["width"] - 2 * margin)
	var y: float = room["position"].y + margin + randf_range(0, room["height"] - 2 * margin)
	
	return Vector2(x, y)

func _place_exit_points() -> void:
	"""Place exit points for completing the hunt"""
	exit_points.clear()
	
	# Place exit in the last room
	var last_room: Dictionary = rooms[rooms.size() - 1]
	var exit_pos: Vector2 = last_room["center"]
	
	if exit_portal:
		exit_portal.position = exit_pos
	
	exit_points.append(exit_pos)

func _spawn_initial_items() -> void:
	"""Spawn initial blood sources and items in the level"""
	if not item_container:
		return
	
	for room in rooms:
		if room["item_count"] > 0:
			for i in range(room["item_count"]):
				var item_pos: Vector2 = _get_random_position_in_room(room)
				_spawn_item(item_pos)

func _spawn_item(position: Vector2) -> void:
	"""Spawn a blood source or relic item"""
	if not item_container:
		return
	
	# Random chance for blood source vs relic
	var is_blood_source: bool = randf() < 0.7
	
	if is_blood_source:
		_spawn_blood_source(position)
	else:
		_spawn_relic(position)

func _spawn_blood_source(position: Vector2) -> void:
	"""Spawn a blood source item"""
	var blood_source: Sprite2D = Sprite2D.new()
	blood_source.texture = preload("res://assets/sprites/blood_source.png")
	blood_source.position = position
	blood_source.name = "BloodSource"
	
	# Add interaction area
	var interaction_area: Area2D = Area2D.new()
	var collision_shape: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 15.0
	collision_shape.shape = shape
	interaction_area.add_child(collision_shape)
	
	blood_source.add_child(interaction_area)
	item_container.add_child(blood_source)

func _spawn_relic(position: Vector2) -> void:
	"""Spawn a relic item"""
	var relic: Sprite2D = Sprite2D.new()
	relic.texture = preload("res://assets/sprites/relic.png")
	relic.position = position
	relic.name = "Relic"
	
	# Add interaction area
	var interaction_area: Area2D = Area2D.new()
	var collision_shape: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 15.0
	collision_shape.shape = shape
	interaction_area.add_child(collision_shape)
	
	relic.add_child(interaction_area)
	item_container.add_child(relic)

func _setup_ui() -> void:
	"""Initialize the hunt UI elements"""
	if not hunt_ui:
		return
	
	# Set up progress bar
	if progress_bar:
		progress_bar.max_value = 100.0
		progress_bar.value = 0.0
	
	# Set up objective label
	if objective_label:
		objective_label.text = "Clear all enemies and find blood sources"
	
	# Hide completion UI initially
	if completion_ui:
		completion_ui.visible = false

func _connect_signals() -> void:
	"""Connect to necessary signals"""
	if GameManager:
		GameManager.game_state_changed.connect(_on_game_state_changed)

func _process(delta: float) -> void:
	"""Update hunt level logic"""
	if not is_hunt_active:
		return
	
	_update_hunt_timer(delta)
	_update_enemy_spawning(delta)
	_update_hunt_progress()
	_check_hunt_completion()

func _update_hunt_timer(delta: float) -> void:
	"""Update the hunt timer"""
	hunt_timer += delta
	
	# Update timer display
	if timer_label:
		var remaining_time: float = hunt_duration - hunt_timer
		var minutes: int = int(remaining_time / 60.0)
		var seconds: int = int(remaining_time) % 60
		timer_label.text = "Time: %02d:%02d" % [minutes, seconds]
	
	# Check for time limit
	if hunt_timer >= hunt_duration:
		_on_hunt_timeout()

func _update_enemy_spawning(delta: float) -> void:
	"""Update enemy spawning logic"""
	if active_enemies.size() >= max_concurrent_enemies:
		return
	
	enemy_spawn_timer += delta
	if enemy_spawn_timer >= enemy_spawn_interval:
		enemy_spawn_timer = 0.0
		_spawn_enemy()

func _spawn_enemy() -> void:
	"""Spawn a new enemy in the level"""
	if not enemy_container or spawn_points.size() == 0:
		return
	
	# Select random spawn point
	var spawn_index: int = randi() % spawn_points.size()
	var spawn_pos: Vector2 = spawn_points[spawn_index]
	
	# Create enemy
	var enemy: Node2D = _create_enemy(spawn_pos)
	if enemy:
		active_enemies.append(enemy)
		enemies_remaining += 1
		
		# Update enemy count display
		_update_enemy_count_display()
		
		// Play spawn sound
		if enemy_spawn_sound:
			enemy_spawn_sound.play()

func _create_enemy(spawn_position: Vector2) -> Node2D:
	"""Create an enemy entity"""
	var enemy: Node2D = Node2D.new()
	enemy.name = "Enemy"
	enemy.position = spawn_position
	
	# Enemy sprite
	var enemy_sprite: Sprite2D = Sprite2D.new()
	enemy_sprite.texture = preload("res://assets/sprites/enemy.png")
	enemy_sprite.modulate = Color.RED
	enemy.add_child(enemy_sprite)
	
	# Enemy collision
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 20.0
	collision.shape = shape
	enemy.add_child(collision)
	
	# Enemy health
	var health: int = randi_range(30, 80)
	enemy.set_meta("health", health)
	enemy.set_meta("max_health", health)
	
	# Connect enemy death signal
	enemy.tree_exited.connect(_on_enemy_died.bind(enemy))
	
	return enemy

func _on_enemy_died(enemy: Node2D) -> void:
	"""Handle enemy death"""
	if active_enemies.has(enemy):
		active_enemies.erase(enemy)
		enemies_remaining = max(0, enemies_remaining - 1)
		
		_update_enemy_count_display()
		
		# Check if all enemies are defeated
		if enemies_remaining <= 0:
			_on_all_enemies_defeated()

func _update_enemy_count_display() -> void:
	"""Update the enemy count display"""
	if enemy_count_label:
		enemy_count_label.text = "Enemies: " + str(enemies_remaining)

func _update_hunt_progress() -> void:
	"""Update the hunt progress display"""
	if not progress_bar:
		return
	
	var total_objectives: int = max_enemies + 5  # enemies + items
	var completed_objectives: int = (max_enemies - enemies_remaining) + blood_sources_found + relics_found
	var progress: float = (float(completed_objectives) / float(total_objectives)) * 100.0
	
	progress_bar.value = progress

func _check_hunt_completion() -> void:
	"""Check if the hunt objectives are complete"""
	if enemies_remaining <= 0 and not hunt_completed:
		_on_hunt_objectives_complete()

func _on_hunt_objectives_complete() -> void:
	"""Handle hunt objectives completion"""
	hunt_completed = true
	
	# Show completion UI
	if completion_ui:
		completion_ui.visible = true
	
	# Play victory fanfare
	if victory_fanfare:
		victory_fanfare.play()
	
	// Update objective label
	if objective_label:
		objective_label.text = "Hunt Complete! Return to the exit portal."

func _on_hunt_timeout() -> void:
	"""Handle hunt time limit reached"""
	# End hunt due to timeout
	_end_hunt(false, "Time limit reached")

func _on_all_enemies_defeated() -> void:
	"""Handle all enemies being defeated"""
	# Update objective
	if objective_label:
		objective_label.text = "All enemies defeated! Find the exit portal."

func _on_exit_portal_entered(body: Node2D) -> void:
	"""Handle player entering the exit portal"""
	if body.name == "Player" and hunt_completed:
		_complete_hunt()

func _complete_hunt() -> void:
	"""Complete the hunt and return to hub"""
	# Calculate rewards
	var rewards: Dictionary = _calculate_hunt_rewards()
	
	// Give rewards to player
	_give_hunt_rewards(rewards)
	
	// End hunt
	_end_hunt(true, "Hunt completed successfully")

func _calculate_hunt_rewards() -> Dictionary:
	"""Calculate hunt completion rewards"""
	var rewards: Dictionary = {}
	
	# Base rewards
	rewards["experience"] = 100 + (blood_sources_found * 25) + (relics_found * 50)
	rewards["currency"] = 50 + (blood_sources_found * 10) + (relics_found * 20)
	
	# Time bonus
	var time_bonus: float = 1.0 + (hunt_duration - hunt_timer) / hunt_duration
	rewards["time_bonus"] = time_bonus
	
	# Apply time bonus to rewards
	rewards["experience"] = int(rewards["experience"] * time_bonus)
	rewards["currency"] = int(rewards["currency"] * time_bonus)
	
	return rewards

func _give_hunt_rewards(rewards: Dictionary) -> void:
	"""Give hunt rewards to the player"""
	if PlayerData:
		PlayerData.add_experience(rewards["experience"])
	
	if EconomySystem:
		EconomySystem.add_currency(rewards["currency"])

func _end_hunt(success: bool, reason: String) -> void:
	"""End the hunt and return to hub"""
	is_hunt_active = false
	
	// Update game state
	if GameManager:
		GameManager.end_hunt_mode()
	
	// Return to hub
	if SceneManager:
		SceneManager.return_from_hunt()

func start_hunt(rumor: RumorData) -> void:
	"""Start the hunt with the given rumor"""
	current_rumor = rumor
	is_hunt_active = true
	hunt_timer = 0.0
	enemies_remaining = 0
	blood_sources_found = 0
	relics_found = 0
	hunt_completed = false
	
	// Start ambient music
	if ambient_music:
		ambient_music.play()
	
	// Spawn initial enemies
	for i in range(min(3, max_enemies)):
		_spawn_enemy()

# Signal handlers
func _on_game_state_changed(new_state: GameEnums.GameState) -> void:
	"""Handle game state changes"""
	if new_state == GameEnums.GameState.HUNT_MODE:
		# Hunt mode activated
		pass
	elif new_state == GameEnums.GameState.BAR_MODE:
		# Returned to bar mode
		pass

# Utility methods
func get_hunt_status() -> Dictionary:
	"""Get the current status of the hunt"""
	return {
		"is_active": is_hunt_active,
		"time_remaining": hunt_duration - hunt_timer,
		"enemies_remaining": enemies_remaining,
		"blood_sources_found": blood_sources_found,
		"relics_found": relics_found,
		"hunt_completed": hunt_completed,
		"current_room": current_room
	}

func get_room_at_position(position: Vector2) -> Dictionary:
	"""Get the room at a specific position"""
	for room in rooms:
		if position.x >= room["position"].x and \
		   position.x <= room["position"].x + room["width"] and \
		   position.y >= room["position"].y and \
		   position.y <= room["position"].y + room["height"]:
			return room
	
	return {}

func is_position_in_room(position: Vector2, room: Dictionary) -> bool:
	"""Check if a position is within a room"""
	return position.x >= room["position"].x and \
		   position.x <= room["position"].x + room["width"] and \
		   position.y >= room["position"].y and \
		   position.y <= room["position"].y + room["height"]

func get_connected_rooms(room_index: int) -> Array[int]:
	"""Get indices of rooms connected to the specified room"""
	var connected: Array[int] = []
	
	if room_connections.has(room_index):
		connected.append(room_index + 1)
	
	if room_connections.has(room_index - 1):
		connected.append(room_index - 1)
	
	return connected

func clear_room(room_index: int) -> void:
	"""Mark a room as cleared"""
	if room_index < rooms.size():
		rooms[room_index]["is_cleared"] = true
		
		// Update room visual
		_update_room_visual(room_index)

func _update_room_visual(room_index: int) -> void:
	"""Update the visual state of a room"""
	var room_node: Node2D = room_container.get_node_or_null("Room" + str(room_index))
	if not room_node:
		return
	
	// Change room color to indicate cleared state
	var room_bg: ColorRect = room_node.get_node_or_null("ColorRect")
	if room_bg:
		room_bg.color = Color.GREEN
		room_bg.modulate.a = 0.6
