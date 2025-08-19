class_name Elevator
extends IInteractable

## Scene transition trigger that transports players from the bar to hunt areas
## Integrates with SceneManager for seamless transitions

# Elevator properties
@export var destination_scene: String = "res://scenes/hunt/hunt_level.tscn"
@export var transition_duration: float = 2.0
@export var requires_hunt_mode: bool = true
@export var elevator_level: int = 1
@export var max_passengers: int = 1

# Transition state
var is_transitioning: bool = false
var transition_timer: float = 0.0
var current_passengers: Array[Node2D] = []
var destination_rumor: RumorData = null

# Visual elements
@onready var elevator_sprite: Sprite2D = $ElevatorSprite
@onready var door_sprite: Sprite2D = $DoorSprite
@onready var level_indicator: Label = $LevelIndicator
@onready var transition_effect: AnimationPlayer = $TransitionEffect
@onready var elevator_glow: Sprite2D = $ElevatorGlow
@onready var status_light: Sprite2D = $StatusLight

# Audio
@onready var elevator_music: AudioStreamPlayer = $ElevatorMusic
@onready var door_open: AudioStreamPlayer = $DoorOpen
@onready var door_close: AudioStreamPlayer = $DoorClose
@onready var elevator_moving: AudioStreamPlayer = $ElevatorMoving
@onready var arrival_bell: AudioStreamPlayer = $ArrivalBell

# UI elements
@onready var transition_ui: Control = $TransitionUI
@onready var destination_label: Label = $TransitionUI/DestinationLabel
@onready var progress_bar: ProgressBar = $TransitionUI/ProgressBar
@onready var status_label: Label = $TransitionUI/StatusLabel

func _ready() -> void:
	super._ready()
	_setup_elevator()
	_setup_ui()
	_connect_signals()

func _setup_elevator() -> void:
	"""Initialize the elevator setup"""
	interaction_prompt = "Press E to enter elevator"
	interaction_range = 50.0
	requires_line_of_sight = false
	
	# Set up visual elements
	if elevator_sprite:
		elevator_sprite.texture = preload("res://assets/sprites/elevator.png")
	
	if door_sprite:
		door_sprite.texture = preload("res://assets/sprites/elevator_door.png")
	
	if level_indicator:
		level_indicator.text = "B" + str(elevator_level)
	
	if status_light:
		status_light.modulate = Color.GREEN  # Available

func _setup_ui() -> void:
	"""Initialize the transition UI elements"""
	if not transition_ui:
		return
	
	# Hide UI initially
	transition_ui.visible = false
	
	# Set up progress bar
	if progress_bar:
		progress_bar.max_value = 100.0
		progress_bar.value = 0.0
	
	# Set up status label
	if status_label:
		status_label.text = "Preparing for departure..."

func _connect_signals() -> void:
	"""Connect to necessary signals"""
	if SceneManager:
		SceneManager.scene_changed.connect(_on_scene_changed)

func _process(delta: float) -> void:
	"""Update elevator logic"""
	super._process(delta)
	_update_transition(delta)
	_update_visual_state()

func _update_transition(delta: float) -> void:
	"""Update transition progress and timing"""
	if not is_transitioning:
		return
	
	transition_timer += delta
	var progress: float = (transition_timer / transition_duration) * 100.0
	
	# Update progress bar
	if progress_bar:
		progress_bar.value = progress
	
	# Check if transition is complete
	if progress >= 100.0:
		_complete_transition()

func _update_visual_state() -> void:
	"""Update elevator visual state based on current status"""
	if not status_light:
		return
	
	if is_transitioning:
		status_light.modulate = Color.YELLOW  # In transit
	elif current_passengers.size() > 0:
		status_light.modulate = Color.RED  # Occupied
	else:
		status_light.modulate = Color.GREEN  # Available

# IInteractable implementation
func can_interact(interactor: Node2D) -> bool:
	"""Check if the elevator can be interacted with"""
	if not super.can_interact(interactor):
		return false
	
	# Check if elevator is available
	if is_transitioning:
		return false
	
	if current_passengers.size() >= max_passengers:
		return false
	
	# Check if hunt mode is required
	if requires_hunt_mode and GameManager:
		if GameManager.current_game_state != GameEnums.GameState.HUNT_MODE:
			return false
	
	return true

func start_interaction(interactor: Node2D) -> void:
	"""Start interaction with the elevator"""
	if not super.start_interaction(interactor):
		return
	
	# Add passenger
	_add_passenger(interactor)
	
	// Check if we should start transition
	if current_passengers.size() >= max_passengers:
		_start_transition()

func _add_passenger(passenger: Node2D) -> void:
	"""Add a passenger to the elevator"""
	if current_passengers.has(passenger):
		return
	
	current_passengers.append(passenger)
	
	// Update interaction prompt
	interaction_prompt = "Elevator occupied"
	
	// Update visual state
	_update_visual_state()

func _remove_passenger(passenger: Node2D) -> void:
	"""Remove a passenger from the elevator"""
	if not current_passengers.has(passenger):
		return
	
	current_passengers.erase(passenger)
	
	// Update interaction prompt
	if current_passengers.size() == 0:
		interaction_prompt = "Press E to enter elevator"
	
	// Update visual state
	_update_visual_state()

func _start_transition() -> void:
	"""Start the elevator transition"""
	if is_transitioning:
		return
	
	is_transitioning = true
	transition_timer = 0.0
	
	// Close doors
	_close_elevator_doors()
	
	// Start transition effects
	_start_transition_effects()
	
	// Show transition UI
	_show_transition_ui()
	
	// Play elevator music
	if elevator_music:
		elevator_music.play()
	
	// Emit interaction signal
	interaction_started.emit(self, get_current_interactor())

func _close_elevator_doors() -> void:
	"""Close the elevator doors"""
	if door_sprite:
		door_sprite.visible = false
	
	if door_close:
		door_close.play()

func _start_transition_effects() -> void:
	"""Start visual and audio transition effects"""
	if transition_effect:
		transition_effect.play("transition")
	
	if elevator_moving:
		elevator_moving.play()
	
	// Start elevator glow effect
	if elevator_glow:
		elevator_glow.visible = true

func _show_transition_ui() -> void:
	"""Show the transition UI"""
	if not transition_ui:
		return
	
	transition_ui.visible = true
	
	// Set destination label
	if destination_label:
		var destination_name: String = _get_destination_name()
		destination_label.text = "Destination: " + destination_name
	
	// Set status label
	if status_label:
		status_label.text = "Departing..."

func _get_destination_name() -> String:
	"""Get the human-readable destination name"""
	if destination_scene.contains("hunt_level"):
		return "Hunt Area"
	elif destination_scene.contains("hub"):
		return "Main Bar"
	else:
		return "Unknown Location"

func _complete_transition() -> void:
	"""Complete the elevator transition"""
	is_transitioning = false
	
	// Stop transition effects
	_stop_transition_effects()
	
	// Hide transition UI
	_hide_transition_ui()
	
	// Perform scene change
	_perform_scene_change()
	
	// Emit completion signal
	interaction_completed.emit(self, get_current_interactor())

func _stop_transition_effects() -> void:
	"""Stop all transition effects"""
	if transition_effect:
		transition_effect.stop()
	
	if elevator_moving:
		elevator_moving.stop()
	
	if elevator_music:
		elevator_music.stop()
	
	// Stop elevator glow
	if elevator_glow:
		elevator_glow.visible = false

func _hide_transition_ui() -> void:
	"""Hide the transition UI"""
	if transition_ui:
		transition_ui.visible = false

func _perform_scene_change() -> void:
	"""Perform the actual scene change"""
	if not SceneManager:
		return
	
	// Get destination rumor if available
	var rumor: RumorData = _get_destination_rumor()
	
	// Change scene
	if destination_scene.contains("hunt"):
		SceneManager.start_hunt(destination_scene, rumor)
	else:
		SceneManager.change_scene(destination_scene)

func _get_destination_rumor() -> RumorData:
	"""Get the destination rumor data if available"""
	// This would typically come from the RumorBoard or GameManager
	// For now, return null
	return null

func _open_elevator_doors() -> void:
	"""Open the elevator doors"""
	if door_sprite:
		door_sprite.visible = true
	
	if door_open:
		door_open.play()

func _play_arrival_bell() -> void:
	"""Play the arrival bell sound"""
	if arrival_bell:
		arrival_bell.play()

# Signal handlers
func _on_scene_changed(scene_path: String) -> void:
	"""Handle scene changes"""
	// Reset elevator state when returning to hub
	if scene_path.contains("hub"):
		_reset_elevator_state()

func _reset_elevator_state() -> void:
	"""Reset the elevator to its initial state"""
	is_transitioning = false
	transition_timer = 0.0
	current_passengers.clear()
	destination_rumor = null
	
	// Open doors
	_open_elevator_doors()
	
	// Reset visual state
	_update_visual_state()
	
	// Reset interaction prompt
	interaction_prompt = "Press E to enter elevator"

# Utility methods
func get_elevator_status() -> Dictionary:
	"""Get the current status of the elevator"""
	return {
		"is_transitioning": is_transiting,
		"current_passengers": current_passengers.size(),
		"max_passengers": max_passengers,
		"elevator_level": elevator_level,
		"destination": destination_scene,
		"can_interact": can_interact(null)
	}

func set_destination_scene(scene_path: String) -> void:
	"""Set the elevator destination scene"""
	destination_scene = scene_path

func set_destination_rumor(rumor: RumorData) -> void:
	"""Set the destination rumor data"""
	destination_rumor = rumor

func is_elevator_available() -> bool:
	"""Check if the elevator is available for use"""
	return not is_transitioning and current_passengers.size() < max_passengers

func get_transition_progress() -> float:
	"""Get the current transition progress (0.0 to 1.0)"""
	if not is_transitioning:
		return 0.0
	
	return transition_timer / transition_duration

func force_open_doors() -> void:
	"""Force open the elevator doors (for debugging)"""
	_open_elevator_doors()

func force_close_doors() -> void:
	"""Force close the elevator doors (for debugging)"""
	_close_elevator_doors()

func emergency_stop() -> void:
	"""Emergency stop the elevator"""
	if is_transitioning:
		is_transitioning = false
		transition_timer = 0.0
		_stop_transition_effects()
		_hide_transition_ui()
		_open_elevator_doors()
		_update_visual_state()

func get_passenger_count() -> int:
	"""Get the current number of passengers"""
	return current_passengers.size()

func has_passenger(passenger: Node2D) -> bool:
	"""Check if a specific passenger is in the elevator"""
	return current_passengers.has(passenger)

func get_elevator_level() -> int:
	"""Get the elevator level number"""
	return elevator_level

func set_elevator_level(level: int) -> void:
	"""Set the elevator level number"""
	elevator_level = level
	if level_indicator:
		level_indicator.text = "B" + str(elevator_level)
