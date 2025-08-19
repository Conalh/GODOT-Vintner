class_name MainHub
extends Node2D

## Main hub scene for the Desert Dive Bar
## Manages bar layout, patron spawning, and overall bar atmosphere

# Bar layout properties
@export var bar_width: int = 1200
@export var bar_height: int = 800
@export var max_patrons: int = 12
@export var patron_spawn_interval: float = 20.0
@export var day_cycle_duration: float = 300.0  # 5 minutes per day cycle

# Bar state
var is_bar_open: bool = true
var current_day_cycle: float = 0.0
var current_patron_count: int = 0
var active_patrons: Array[PatronEntity] = []
var bar_atmosphere: float = 0.5  # 0.0 = empty, 1.0 = packed

# Station references
@onready var bar_counter: BarCounter = $Stations/BarCounter
@onready var crafting_bench: CraftingBench = $Stations/CraftingBench
@onready var cellar_shelf: CellarShelf = $Stations/CellarShelf
@onready var rumor_board: RumorBoard = $Stations/RumorBoard
@onready var elevator: Elevator = $Stations/Elevator

# Patron management
@onready var patron_spawn_points: Array[Marker2D] = []
@onready var patron_container: Node2D = $PatronContainer
@onready var spawn_timer: Timer = $PatronSpawnTimer

# Visual elements
@onready var bar_background: Sprite2D = $BarBackground
@onready var lighting_system: Node2D = $LightingSystem
@onready var atmosphere_particles: GPUParticles2D = $AtmosphereParticles
@onready var day_night_cycle: AnimationPlayer = $DayNightCycle

# Audio
@onready var ambient_music: AudioStreamPlayer = $AmbientMusic
@onready var bar_ambience: AudioStreamPlayer = $BarAmbience
@onready var patron_chatter: AudioStreamPlayer = $PatronChatter

# UI elements
@onready var bar_ui: Control = $BarUI
@onready var status_panel: Control = $BarUI/StatusPanel
@onready var patron_count_label: Label = $BarUI/StatusPanel/PatronCountLabel
@onready var atmosphere_label: Label = $BarUI/StatusPanel/AtmosphereLabel
@onready var day_cycle_label: Label = $BarUI/StatusPanel/DayCycleLabel
@onready var income_display: Control = $BarUI/IncomeDisplay
@onready var current_income_label: Label = $BarUI/IncomeDisplay/CurrentIncomeLabel
@onready var total_income_label: Label = $BarUI/IncomeDisplay/TotalIncomeLabel

func _ready() -> void:
	_setup_main_hub()
	_setup_bar_layout()
	_setup_patron_spawning()
	_setup_ui()
	_connect_signals()
	_start_bar_operations()

func _setup_main_hub() -> void:
	"""Initialize the main hub setup"""
	# Set up bar background
	if bar_background:
		bar_background.texture = preload("res://assets/sprites/desert_dive_bar.png")
		bar_background.modulate = Color.WHITE
	
	# Set up lighting system
	if lighting_system:
		_setup_lighting()
	
	# Set up atmosphere particles
	if atmosphere_particles:
		atmosphere_particles.emitting = true
	
	# Start ambient audio
	if ambient_music:
		ambient_music.play()
	
	if bar_ambience:
		bar_ambience.play()

func _setup_lighting() -> void:
	"""Set up the bar lighting system"""
	# Create main bar light
	var main_light: PointLight2D = PointLight2D.new()
	main_light.texture = preload("res://assets/sprites/light_glow.png")
	main_light.energy = 1.0
	main_light.color = Color.WARM_WHITE
	main_light.position = Vector2(bar_width / 2, bar_height / 2)
	lighting_system.add_child(main_light)
	
	# Create station lights
	_create_station_lights()
	
	# Create mood lighting
	_create_mood_lighting()

func _create_station_lights() -> void:
	"""Create lighting for each bar station"""
	var station_positions: Array[Vector2] = [
		Vector2(200, 300),   # Bar Counter
		Vector2(400, 200),   # Crafting Bench
		Vector2(600, 400),   # Cellar Shelf
		Vector2(800, 150),   # Rumor Board
		Vector2(1000, 500)   # Elevator
	]
	
	for i in range(station_positions.size()):
		var station_light: PointLight2D = PointLight2D.new()
		station_light.texture = preload("res://assets/sprites/station_light.png")
		station_light.energy = 0.8
		station_light.color = Color.YELLOW
		station_light.position = station_positions[i]
		lighting_system.add_child(station_light)

func _create_mood_lighting() -> void:
	"""Create atmospheric mood lighting"""
	var mood_light: PointLight2D = PointLight2D.new()
	mood_light.texture = preload("res://assets/sprites/mood_light.png")
	mood_light.energy = 0.6
	mood_light.color = Color.BLUE
	mood_light.position = Vector2(bar_width / 2, 100)
	lighting_system.add_child(mood_light)

func _setup_bar_layout() -> void:
	"""Set up the bar layout and station positioning"""
	# Position bar counter (main serving area)
	if bar_counter:
		bar_counter.position = Vector2(200, 300)
		bar_counter.max_seats = 6
		bar_counter.counter_length = 300
	
	# Position crafting bench
	if crafting_bench:
		crafting_bench.position = Vector2(400, 200)
	
	# Position cellar shelf
	if cellar_shelf:
		cellar_shelf.position = Vector2(600, 400)
	
	# Position rumor board
	if rumor_board:
		rumor_board.position = Vector2(800, 150)
	
	# Position elevator
	if elevator:
		elevator.position = Vector2(1000, 500)
		elevator.destination_scene = "res://scenes/hunt/hunt_level.tscn"

func _setup_patron_spawning() -> void:
	"""Set up patron spawning system"""
	# Create patron spawn points around the bar
	_create_patron_spawn_points()
	
	# Set up spawn timer
	if spawn_timer:
		spawn_timer.wait_time = patron_spawn_interval
		spawn_timer.timeout.connect(_spawn_patron)
		spawn_timer.start()

func _create_patron_spawn_points() -> void:
	"""Create patron spawn points around the bar perimeter"""
	var spawn_positions: Array[Vector2] = [
		Vector2(50, 100),    # Top left
		Vector2(bar_width - 50, 100),  # Top right
		Vector2(50, bar_height - 100), # Bottom left
		Vector2(bar_width - 50, bar_height - 100), # Bottom right
		Vector2(100, 50),    # Left middle
		Vector2(bar_width - 100, 50)   # Right middle
	]
	
	for i in range(spawn_positions.size()):
		var spawn_point: Marker2D = Marker2D.new()
		spawn_point.name = "PatronSpawn" + str(i + 1)
		spawn_point.position = spawn_positions[i]
		patron_spawn_points.append(spawn_point)
		add_child(spawn_point)

func _setup_ui() -> void:
	"""Initialize the bar UI elements"""
	if not bar_ui:
		return
	
	# Set up status panel
	_setup_status_panel()
	
	# Set up income display
	_setup_income_display()
	
	# Update initial values
	_update_ui_display()

func _setup_status_panel() -> void:
	"""Set up the status panel UI"""
	if not status_panel:
		return
	
	# Set up patron count label
	if patron_count_label:
		patron_count_label.text = "Patrons: 0/" + str(max_patrons)
	
	# Set up atmosphere label
	if atmosphere_label:
		atmosphere_label.text = "Atmosphere: Quiet"
	
	# Set up day cycle label
	if day_cycle_label:
		day_cycle_label.text = "Day Cycle: Morning"

func _setup_income_display() -> void:
	"""Set up the income display UI"""
	if not income_display:
		return
	
	# Set up current income label
	if current_income_label:
		current_income_label.text = "Current Income: $0"
	
	# Set up total income label
	if total_income_label:
		total_income_label.text = "Total Income: $0"

func _connect_signals() -> void:
	"""Connect to necessary signals"""
	if GameManager:
		GameManager.game_state_changed.connect(_on_game_state_changed)
	
	if EconomySystem:
		EconomySystem.bar_income_earned.connect(_on_bar_income_earned)
	
	if PatronManager:
		PatronManager.patron_spawned.connect(_on_patron_spawned)
		PatronManager.patron_removed.connect(_on_patron_removed)

func _start_bar_operations() -> void:
	"""Start the bar's daily operations"""
	is_bar_open = true
	
	# Start day cycle
	if day_night_cycle:
		day_night_cycle.play("day_cycle")
	
	# Start patron spawning
	_spawn_initial_patrons()

func _spawn_initial_patrons() -> void:
	"""Spawn initial patrons to populate the bar"""
	var initial_patron_count: int = randi_range(3, 6)
	
	for i in range(initial_patron_count):
		_spawn_patron()

func _spawn_patron() -> void:
	"""Spawn a new patron"""
	if current_patron_count >= max_patrons:
		return
	
	# Select random spawn point
	var spawn_index: int = randi() % patron_spawn_points.size()
	var spawn_point: Marker2D = patron_spawn_points[spawn_index]
	
	# Create patron entity
	var patron_scene: PackedScene = preload("res://scenes/entities/patron_entity.tscn")
	var patron_instance: PatronEntity = patron_scene.instantiate()
	
	# Add to patron container
	patron_container.add_child(patron_instance)
	patron_instance.position = spawn_point.global_position
	
	# Initialize with random patron data
	var patron_data: PatronData = PatronManager.get_random_patron_template()
	if patron_data:
		patron_instance.initialize_patron(patron_data)
	
	# Add to active patrons
	active_patrons.append(patron_instance)
	current_patron_count += 1
	
	# Connect patron signals
	patron_instance.patron_state_changed.connect(_on_patron_state_changed)
	
	# Update UI
	_update_ui_display()
	_update_bar_atmosphere()

func _on_patron_spawned(patron: PatronEntity) -> void:
	"""Handle patron spawning from PatronManager"""
	# This is handled locally in _spawn_patron
	pass

func _on_patron_removed(patron: PatronEntity) -> void:
	"""Handle patron removal from PatronManager"""
	# This is handled locally in _on_patron_state_changed
	pass

func _on_patron_state_changed(patron: PatronEntity, new_state: String) -> void:
	"""Handle patron state changes"""
	match new_state:
		"leaving":
			_on_patron_leaving(patron)
		"seated":
			_on_patron_seated(patron)

func _on_patron_leaving(patron: PatronEntity) -> void:
	"""Handle patron leaving the bar"""
	# Remove from active patrons
	if active_patrons.has(patron):
		active_patrons.erase(patron)
		current_patron_count -= 1
	
	# Update UI
	_update_ui_display()
	_update_bar_atmosphere()
	
	# Schedule patron removal
	var timer: Timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.timeout.connect(func(): _remove_patron(patron))
	add_child(timer)
	timer.start()

func _on_patron_seated(patron: PatronEntity) -> void:
	"""Handle patron being seated"""
	# Update bar atmosphere
	_update_bar_atmosphere()

func _remove_patron(patron: PatronEntity) -> void:
	"""Remove a patron from the scene"""
	if patron and is_instance_valid(patron):
		patron.queue_free()

func _update_bar_atmosphere() -> void:
	"""Update the bar's atmosphere based on patron count and activity"""
	var patron_ratio: float = float(current_patron_count) / float(max_patrons)
	var activity_level: float = _calculate_activity_level()
	
	bar_atmosphere = (patron_ratio + activity_level) / 2.0
	
	# Update visual effects
	_update_atmosphere_effects()
	
	// Update UI
	_update_atmosphere_display()

func _calculate_activity_level() -> float:
	"""Calculate the current activity level in the bar"""
	var activity: float = 0.0
	
	# Check if bar counter is serving
	if bar_counter and bar_counter.is_serving:
		activity += 0.3
	
	# Check if crafting bench is active
	if crafting_bench and crafting_bench.is_crafting:
		activity += 0.2
	
	# Check patron satisfaction
	for patron in active_patrons:
		var needs_component: PatronNeeds = patron.get_component("PatronNeeds")
		if needs_component and needs_component.is_satisfied():
			activity += 0.1
	
	return min(activity, 1.0)

func _update_atmosphere_effects() -> void:
	"""Update visual and audio atmosphere effects"""
	# Update particle density
	if atmosphere_particles:
		atmosphere_particles.amount = int(bar_atmosphere * 50)
	
	# Update lighting intensity
	if lighting_system:
		var lights: Array = lighting_system.get_children()
		for light in lights:
			if light is PointLight2D:
				light.energy = 0.5 + (bar_atmosphere * 0.5)
	
	# Update audio levels
	if patron_chatter:
		patron_chatter.volume_db = -20 + (bar_atmosphere * 20)

func _update_atmosphere_display() -> void:
	"""Update the atmosphere display in the UI"""
	if not atmosphere_label:
		return
	
	var atmosphere_text: String = "Atmosphere: "
	if bar_atmosphere < 0.2:
		atmosphere_text += "Empty"
	elif bar_atmosphere < 0.4:
		atmosphere_text += "Quiet"
	elif bar_atmosphere < 0.6:
		atmosphere_text += "Moderate"
	elif bar_atmosphere < 0.8:
		atmosphere_text += "Lively"
	else:
		atmosphere_text += "Packed"
	
	atmosphere_label.text = atmosphere_text

func _update_ui_display() -> void:
	"""Update all UI elements"""
	# Update patron count
	if patron_count_label:
		patron_count_label.text = "Patrons: " + str(current_patron_count) + "/" + str(max_patrons)
	
	# Update income display
	_update_income_display()
	
	# Update day cycle
	_update_day_cycle_display()

func _update_income_display() -> void:
	"""Update the income display"""
	if not income_display:
		return
	
	if current_income_label and EconomySystem:
		var current_income: int = EconomySystem.bar_income_pending
		current_income_label.text = "Current Income: $" + str(current_income)
	
	if total_income_label and EconomySystem:
		var total_income: int = EconomySystem.bar_income_banked
		total_income_label.text = "Total Income: $" + str(total_income)

func _update_day_cycle_display() -> void:
	"""Update the day cycle display"""
	if not day_cycle_label:
		return
	
	var cycle_progress: float = current_day_cycle / day_cycle_duration
	var cycle_text: String = "Day Cycle: "
	
	if cycle_progress < 0.25:
		cycle_text += "Morning"
	elif cycle_progress < 0.5:
		cycle_text += "Afternoon"
	elif cycle_progress < 0.75:
		cycle_text += "Evening"
	else:
		cycle_text += "Night"
	
	day_cycle_label.text = cycle_text

func _process(delta: float) -> void:
	"""Update main hub logic"""
	_update_day_cycle(delta)
	_update_patron_behavior(delta)
	_check_bar_conditions()

func _update_day_cycle(delta: float) -> void:
	"""Update the day cycle progression"""
	current_day_cycle += delta
	
	# Check if day cycle is complete
	if current_day_cycle >= day_cycle_duration:
		_complete_day_cycle()
	
	# Update day/night cycle animation
	if day_night_cycle:
		var cycle_progress: float = current_day_cycle / day_cycle_duration
		day_night_cycle.seek(cycle_progress * day_night_cycle.current_animation_length)

func _update_patron_behavior(delta: float) -> void:
	"""Update patron behavior and interactions"""
	for patron in active_patrons:
		if not is_instance_valid(patron):
			active_patrons.erase(patron)
			current_patron_count -= 1
			continue
		
		# Update patron components
		patron._update_components(delta)

func _check_bar_conditions() -> void:
	"""Check various bar conditions and respond accordingly"""
	# Check if bar should close
	if current_day_cycle >= day_cycle_duration * 0.9 and is_bar_open:
		_close_bar()
	
	# Check if bar should open
	if current_day_cycle >= day_cycle_duration and not is_bar_open:
		_open_bar()

func _complete_day_cycle() -> void:
	"""Complete the current day cycle"""
	# Bank current income
	if EconomySystem:
		EconomySystem.complete_day()
	
	// Reset day cycle
	current_day_cycle = 0.0
	
	// Update UI
	_update_ui_display()

func _close_bar() -> void:
	"""Close the bar for the night"""
	is_bar_open = false
	
	// Stop patron spawning
	if spawn_timer:
		spawn_timer.stop()
	
	// Start closing sequence
	_start_bar_closing_sequence()

func _open_bar() -> void:
	"""Open the bar for the day"""
	is_bar_open = true
	
	// Resume patron spawning
	if spawn_timer:
		spawn_timer.start()
	
	// Start opening sequence
	_start_bar_opening_sequence()

func _start_bar_closing_sequence() -> void:
	"""Start the bar closing sequence"""
	// Dim lights
	if lighting_system:
		var lights: Array = lighting_system.get_children()
		for light in lights:
			if light is PointLight2D:
				var tween: Tween = create_tween()
				tween.tween_property(light, "energy", 0.2, 2.0)
	
	// Change music
	if ambient_music:
		ambient_music.pitch_scale = 0.8

func _start_bar_opening_sequence() -> void:
	"""Start the bar opening sequence"""
	// Brighten lights
	if lighting_system:
		var lights: Array = lighting_system.get_children()
		for light in lights:
			if light is PointLight2D:
				var tween: Tween = create_tween()
				tween.tween_property(light, "energy", 1.0, 2.0)
	
	// Reset music
	if ambient_music:
		ambient_music.pitch_scale = 1.0

# Signal handlers
func _on_game_state_changed(new_state: GameEnums.GameState) -> void:
	"""Handle game state changes"""
	match new_state:
		GameEnums.GameState.BAR_MODE:
			# Returned to bar mode
			pass
		GameEnums.GameState.HUNT_MODE:
			# Entered hunt mode
			pass

func _on_bar_income_earned(amount: int) -> void:
	"""Handle bar income being earned"""
	_update_income_display()

# Utility methods
func get_bar_status() -> Dictionary:
	"""Get the current status of the bar"""
	return {
		"is_open": is_bar_open,
		"current_patrons": current_patron_count,
		"max_patrons": max_patrons,
		"bar_atmosphere": bar_atmosphere,
		"day_cycle_progress": current_day_cycle / day_cycle_duration,
		"active_stations": _get_active_stations()
	}

func _get_active_stations() -> Array[String]:
	"""Get list of currently active stations"""
	var active_stations: Array[String] = []
	
	if bar_counter and bar_counter.is_serving:
		active_stations.append("BarCounter")
	
	if crafting_bench and crafting_bench.is_crafting:
		active_stations.append("CraftingBench")
	
	return active_stations

func get_patron_at_position(position: Vector2) -> PatronEntity:
	"""Get the patron at a specific position"""
	for patron in active_patrons:
		if patron.position.distance_to(position) < 50.0:
			return patron
	
	return null

func get_station_at_position(position: Vector2) -> Node2D:
	"""Get the station at a specific position"""
	var stations: Array[Node2D] = [bar_counter, crafting_bench, cellar_shelf, rumor_board, elevator]
	
	for station in stations:
		if station and station.position.distance_to(position) < 100.0:
			return station
	
	return null

func force_spawn_patron() -> void:
	"""Force spawn a patron (for debugging)"""
	_spawn_patron()

func force_close_bar() -> void:
	"""Force close the bar (for debugging)"""
	_close_bar()

func force_open_bar() -> void:
	"""Force open the bar (for debugging)"""
	_open_bar()

func get_bar_dimensions() -> Vector2:
	"""Get the bar dimensions"""
	return Vector2(bar_width, bar_height)

func is_position_in_bar(position: Vector2) -> bool:
	"""Check if a position is within the bar boundaries"""
	return position.x >= 0 and position.x <= bar_width and \
		   position.y >= 0 and position.y <= bar_height
