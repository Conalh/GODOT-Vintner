class_name PatronBehavior
extends IPatronComponent

## PatronBehavior Component - Movement, seating, and animations
## Manages patron movement, seating behavior, and visual animations
## Integrates with PatronPersonality for behavior patterns

## Movement and positioning
@export var movement_speed: float = 100.0  # Pixels per second
@export var rotation_speed: float = 180.0  # Degrees per second
@export var interaction_range: float = 50.0  # Range for interactions

## Current state and targets
var current_target: Vector2 = Vector2.ZERO
var is_moving: bool = false
var is_seated: bool = false
var current_seat: Node = null
var movement_path: Array[Vector2] = []
var path_index: int = 0

## Animation states
var current_animation: String = "idle"
var animation_blend_time: float = 0.2
var last_animation_change: float = 0.0

## Behavior patterns
var behavior_state: String = "wandering"  # wandering, seeking_seat, seated, leaving
var state_timer: float = 0.0
var state_duration: float = 5.0

## Seating preferences
var seating_preferences: Dictionary = {
	"preferred_seat_types": ["bar_stool", "booth", "table"],
	"avoid_crowded_areas": true,
	"prefer_window_seats": false,
	"group_size": 1
}

## Component initialization
func _on_initialize() -> void:
	component_id = "patron_behavior"
	component_name = "PatronBehavior"
	component_type = "behavior"
	
	# Initialize behavior from patron data
	var patron_data = get_patron_data()
	if patron_data:
		_initialize_from_patron_data(patron_data)
	
	log_component_message("Initialized with movement speed: " + str(movement_speed))

## Update logic
func _on_update(delta: float) -> void:
	# Update state timer
	state_timer += delta
	
	# Update behavior based on current state
	match behavior_state:
		"wandering":
			_update_wandering(delta)
		"seeking_seat":
			_update_seeking_seat(delta)
		"seated":
			_update_seated(delta)
		"leaving":
			_update_leaving(delta)
	
	# Update movement
	_update_movement(delta)
	
	# Update animations
	_update_animations(delta)

## Initialize component from PatronData Resource
func _initialize_from_patron_data(patron_data: PatronData) -> void:
	# Get behavior patterns from personality component
	var personality_component = _get_personality_component()
	if personality_component:
		var behavior_pattern = personality_component.get_current_behavior()
		movement_speed *= behavior_pattern.get("movement_speed", 1.0)
		interaction_range = behavior_pattern.get("interaction_range", 50.0)
	
	# Set seating preferences based on archetype
	match patron_data.archetype:
		"aristocrat":
			seating_preferences["preferred_seat_types"] = ["booth", "table"]
			seating_preferences["avoid_crowded_areas"] = true
			seating_preferences["prefer_window_seats"] = true
		"rogue":
			seating_preferences["preferred_seat_types"] = ["bar_stool", "corner_table"]
			seating_preferences["avoid_crowded_areas"] = false
			seating_preferences["prefer_window_seats"] = false
		"mystic":
			seating_preferences["preferred_seat_types"] = ["corner_table", "booth"]
			seating_preferences["avoid_crowded_areas"] = true
			seating_preferences["prefer_window_seats"] = false
	
	log_component_message("Initialized behavior from patron data: " + patron_data.name)

## Behavior state management
func set_behavior_state(new_state: String, duration: float = -1.0) -> void:
	"""Set the current behavior state"""
	var old_state = behavior_state
	behavior_state = new_state
	state_timer = 0.0
	
	if duration > 0:
		state_duration = duration
	else:
		state_duration = 5.0  # Default duration
	
	log_component_message("Behavior state changed: " + old_state + " -> " + new_state)
	
	# Initialize state-specific behavior
	match new_state:
		"wandering":
			_start_wandering()
		"seeking_seat":
			_start_seeking_seat()
		"seated":
			_start_seated()
		"leaving":
			_start_leaving()

## State update methods
func _update_wandering(delta: float) -> void:
	"""Update wandering behavior"""
	# Check if we should seek a seat
	if state_timer > state_duration and not is_seated:
		set_behavior_state("seeking_seat")
		return
	
	# Random movement if no target
	if not is_moving:
		_generate_random_target()

func _update_seeking_seat(delta: float) -> void:
	"""Update seat-seeking behavior"""
	# Look for available seats
	var available_seat = _find_available_seat()
	if available_seat:
		_move_to_seat(available_seat)
		return
	
	# If no seats found, continue wandering
	if state_timer > state_duration:
		set_behavior_state("wandering")

func _update_seated(delta: float) -> void:
	"""Update seated behavior"""
	# Check if we should leave
	if state_timer > state_duration:
		set_behavior_state("leaving")
		return
	
	# Idle seated behavior
	_play_seated_animation()

func _update_leaving(delta: float) -> void:
	"""Update leaving behavior"""
	# Move towards exit
	if not is_moving:
		_generate_exit_target()
	
	# Check if we've reached the exit
	if _has_reached_target():
		_leave_bar()

## Movement management
func _update_movement(delta: float) -> void:
	"""Update movement logic"""
	if not is_moving or not _has_target():
		return
	
	var current_pos = get_patron_position()
	var direction = (current_target - current_pos).normalized()
	var distance = current_pos.distance_to(current_target)
	
	# Check if we've reached the target
	if distance < 5.0:
		_reached_target()
		return
	
	# Move towards target
	var movement = direction * movement_speed * delta
	var new_pos = current_pos + movement
	
	# Update patron position (this would call the patron entity's set_position method)
	if patron_entity and patron_entity.has_method("set_position"):
		patron_entity.set_position(new_pos)
	
	# Update animation based on movement
	if movement.length() > 0.1:
		_set_animation("walking")
	else:
		_set_animation("idle")

func _has_target() -> bool:
	"""Check if we have a valid target"""
	return current_target != Vector2.ZERO

func _has_reached_target() -> bool:
	"""Check if we've reached the current target"""
	if not _has_target():
		return false
	
	var current_pos = get_patron_position()
	return current_pos.distance_to(current_target) < 5.0

func _reached_target() -> void:
	"""Called when we reach the current target"""
	is_moving = false
	current_target = Vector2.ZERO
	
	# Handle target-specific behavior
	if behavior_state == "seeking_seat" and current_seat:
		_sit_down()
	elif behavior_state == "leaving":
		_leave_bar()

## Target generation
func _generate_random_target() -> void:
	"""Generate a random wandering target"""
	var bar_bounds = _get_bar_bounds()
	if bar_bounds.size == Vector2.ZERO:
		return
	
	var random_x = randf_range(bar_bounds.position.x, bar_bounds.position.x + bar_bounds.size.x)
	var random_y = randf_range(bar_bounds.position.y, bar_bounds.position.y + bar_bounds.size.y)
	
	current_target = Vector2(random_x, random_y)
	is_moving = true
	
	log_component_message("Generated random target: " + str(current_target))

func _generate_exit_target() -> void:
	"""Generate a target for leaving the bar"""
	var exit_position = _get_exit_position()
	if exit_position != Vector2.ZERO:
		current_target = exit_position
		is_moving = true
		log_component_message("Moving to exit: " + str(current_target))

## Seating management
func _start_seeking_seat() -> void:
	"""Start looking for a seat"""
	log_component_message("Looking for a seat")
	# This would trigger seat-finding logic

func _find_available_seat() -> Node:
	"""Find an available seat matching preferences"""
	# This would query the bar's seating system
	# For now, return null to indicate no seats found
	return null

func _move_to_seat(seat: Node) -> void:
	"""Move towards a specific seat"""
	if not seat:
		return
	
	var seat_position = seat.get_position()
	current_target = seat_position
	current_seat = seat
	is_moving = true
	
	log_component_message("Moving to seat: " + str(seat_position))

func _sit_down() -> void:
	"""Sit down at the current seat"""
	if not current_seat:
		return
	
	is_seated = true
	is_moving = false
	current_target = Vector2.ZERO
	
	# Set position to seat position
	if patron_entity and patron_entity.has_method("set_position"):
		patron_entity.set_position(current_seat.get_position())
	
	# Change to seated state
	set_behavior_state("seated", 30.0)  # Stay seated for 30 seconds
	
	log_component_message("Sat down at seat")

func _start_seated() -> void:
	"""Initialize seated behavior"""
	log_component_message("Now seated and comfortable")

func _play_seated_animation() -> void:
	"""Play seated idle animation"""
	_set_animation("seated_idle")

## Leaving behavior
func _start_leaving() -> void:
	"""Initialize leaving behavior"""
	if is_seated:
		_stand_up()
	
	log_component_message("Preparing to leave")

func _stand_up() -> void:
	"""Stand up from the current seat"""
	is_seated = false
	current_seat = null
	
	log_component_message("Stood up from seat")

func _leave_bar() -> void:
	"""Leave the bar completely"""
	log_component_message("Leaving the bar")
	
	# Signal to patron manager that this patron is leaving
	if patron_entity and patron_entity.has_method("leave_bar"):
		patron_entity.leave_bar()

## Animation management
func _update_animations(delta: float) -> void:
	"""Update animation states"""
	# Animation blending and transitions would go here
	pass

func _set_animation(animation_name: String) -> void:
	"""Set the current animation"""
	if current_animation == animation_name:
		return
	
	current_animation = animation_name
	last_animation_change = Time.get_time_dict_from_system()["second"]
	
	# This would trigger the actual animation change in the patron entity
	if patron_entity and patron_entity.has_method("play_animation"):
		patron_entity.play_animation(animation_name)
	
	log_component_message("Animation changed to: " + animation_name)

## Utility methods
func _get_personality_component() -> PatronPersonality:
	"""Get the personality component from the patron entity"""
	if patron_entity and patron_entity.has_method("get_component"):
		return patron_entity.get_component("PatronPersonality")
	return null

func _get_bar_bounds() -> Rect2:
	"""Get the bounds of the bar area"""
	# This would query the bar scene for its boundaries
	# For now, return a default area
	return Rect2(Vector2(0, 0), Vector2(800, 600))

func _get_exit_position() -> Vector2:
	"""Get the position of the bar exit"""
	# This would query the bar scene for exit positions
	# For now, return a default exit position
	return Vector2(400, 0)

## Component reset
func _on_reset() -> void:
	current_target = Vector2.ZERO
	is_moving = false
	is_seated = false
	current_seat = null
	movement_path.clear()
	path_index = 0
	current_animation = "idle"
	behavior_state = "wandering"
	state_timer = 0.0
	state_duration = 5.0

## Save/Load support
func get_save_data() -> Dictionary:
	var base_data = super.get_save_data()
	base_data.merge({
		"movement_speed": movement_speed,
		"interaction_range": interaction_range,
		"current_target": current_target,
		"is_moving": is_moving,
		"is_seated": is_seated,
		"current_seat_id": current_seat.get_name() if current_seat else "",
		"behavior_state": behavior_state,
		"state_timer": state_timer,
		"current_animation": current_animation,
		"seating_preferences": seating_preferences
	})
	return base_data

func load_save_data(data: Dictionary) -> void:
	super.load_save_data(data)
	movement_speed = data.get("movement_speed", 100.0)
	interaction_range = data.get("interaction_range", 50.0)
	current_target = data.get("current_target", Vector2.ZERO)
	is_moving = data.get("is_moving", false)
	is_seated = data.get("is_seated", false)
	# Note: Seat reference would need to be restored from ID in a full implementation
	behavior_state = data.get("behavior_state", "wandering")
	state_timer = data.get("state_timer", 0.0)
	current_animation = data.get("current_animation", "idle")
	seating_preferences = data.get("seating_preferences", {})
