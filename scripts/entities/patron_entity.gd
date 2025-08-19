class_name PatronEntity
extends CharacterBody2D

## PatronEntity - Composite patron with component slots
## Manages all patron components and coordinates their behavior
## Integrates with PatronData Resources for dynamic patron creation

## Entity identification
@export var patron_id: String = ""
@export var patron_name: String = ""
@export var patron_title: String = ""

## Component management
var components: Dictionary = {}
var component_nodes: Dictionary = {}
var is_initialized: bool = false

## Patron data reference
var patron_data: PatronData = null

## Visual representation
@export var sprite: Sprite2D = null
@export var animation_player: AnimationPlayer = null
@export var collision_shape: CollisionShape2D = null

## Movement and physics
@export var max_speed: float = 150.0
@export var acceleration: float = 500.0
@export var friction: float = 0.8

## Component slots
@export var needs_component: PatronNeeds = null
@export var personality_component: PatronPersonality = null
@export var behavior_component: PatronBehavior = null

## Entity state
var current_state: String = "idle"
var state_timer: float = 0.0
var is_active: bool = true

## Signals for entity events
signal patron_initialized(patron: PatronEntity)
signal patron_activated(patron: PatronEntity)
signal patron_deactivated(patron: PatronEntity)
signal patron_state_changed(old_state: String, new_state: String)
signal patron_component_added(component: IPatronComponent)
signal patron_component_removed(component: IPatronComponent)

## Entity initialization
func _ready() -> void:
	# Initialize component references
	_initialize_component_references()
	
	# Set up collision detection
	_setup_collision()
	
	# Initialize if patron data is already set
	if patron_data:
		initialize_patron(patron_data)

func _initialize_component_references() -> void:
	"""Initialize references to component nodes"""
	if needs_component:
		component_nodes["needs"] = needs_component
		components["needs"] = needs_component
	
	if personality_component:
		component_nodes["personality"] = personality_component
		components["personality"] = personality_component
	
	if behavior_component:
		component_nodes["behavior"] = behavior_component
		components["behavior"] = behavior_component

func _setup_collision() -> void:
	"""Set up collision detection for the patron"""
	if not collision_shape:
		# Create a default collision shape if none exists
		var new_collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(32, 32)  # Default size
		new_collision.shape = shape
		add_child(new_collision)
		collision_shape = new_collision

## Patron initialization
func initialize_patron(data: PatronData) -> bool:
	"""Initialize the patron with PatronData Resource"""
	if is_initialized:
		log_component_message("Patron already initialized")
		return false
	
	if not data or not data.is_valid():
		log_component_message("ERROR: Invalid patron data provided")
		return false
	
	patron_data = data
	patron_id = data.id
	patron_name = data.name
	patron_title = data.title
	
	# Initialize all components
	_initialize_components()
	
	# Set up component communication
	_setup_component_signals()
	
	is_initialized = true
	emit_signal("patron_initialized", self)
	
	log_component_message("Patron initialized: " + patron_name)
	return true

func _initialize_components() -> void:
	"""Initialize all patron components"""
	for component_name in components.keys():
		var component = components[component_name]
		if component and component.has_method("initialize"):
			component.initialize(self)
			emit_signal("patron_component_added", component)

func _setup_component_signals() -> void:
	"""Set up signal connections between components"""
	# Connect needs component to personality component
	if components.has("needs") and components.has("personality"):
		var needs = components["needs"]
		var personality = components["personality"]
		
		needs.component_data_changed.connect(_on_needs_changed)
	
	# Connect personality component to behavior component
	if components.has("personality") and components.has("behavior"):
		var personality = components["personality"]
		var behavior = components["behavior"]
		
		personality.component_data_changed.connect(_on_personality_changed)

## Component management
func get_component(component_type: String) -> IPatronComponent:
	"""Get a component by type"""
	return components.get(component_type, null)

func add_component(component: IPatronComponent) -> bool:
	"""Add a new component to the patron"""
	if not component:
		return false
	
	var component_type = component.component_type
	if components.has(component_type):
		log_component_message("Component type already exists: " + component_type)
		return false
	
	components[component_type] = component
	component_nodes[component_type] = component
	
	# Initialize the component
	if component.has_method("initialize"):
		component.initialize(self)
	
	emit_signal("patron_component_added", component)
	log_component_message("Added component: " + component_type)
	
	return true

func remove_component(component_type: String) -> bool:
	"""Remove a component from the patron"""
	if not components.has(component_type):
		return false
	
	var component = components[component_type]
	components.erase(component_type)
	component_nodes.erase(component_type)
	
	# Deactivate the component
	if component.has_method("deactivate"):
		component.deactivate()
	
	emit_signal("patron_component_removed", component)
	log_component_message("Removed component: " + component_type)
	
	return true

## Entity update logic
func _process(delta: float) -> void:
	if not is_active or not is_initialized:
		return
	
	# Update all components
	_update_components(delta)
	
	# Update entity state
	_update_entity_state(delta)

func _update_components(delta: float) -> void:
	"""Update all active components"""
	for component in components.values():
		if component and component.has_method("update_component"):
			component.update_component(delta)

func _update_entity_state(delta: float) -> void:
	"""Update the entity's current state"""
	state_timer += delta
	
	# State-specific logic would go here
	# For now, just maintain the timer

## Component signal handlers
func _on_needs_changed(component: IPatronComponent, data: Dictionary) -> void:
	"""Handle changes in the needs component"""
	if data.has("wine_served"):
		# Wine was served, update personality mood
		var personality = get_component("personality")
		if personality and data.has("satisfaction"):
			personality.update_mood(data["satisfaction"], "wine_served")

func _on_personality_changed(component: IPatronComponent, data: Dictionary) -> void:
	"""Handle changes in the personality component"""
	if data.has("mood"):
		# Mood changed, update behavior if needed
		var behavior = get_component("behavior")
		if behavior:
			# Adjust behavior based on mood
			pass

## Entity state management
func set_entity_state(new_state: String) -> void:
	"""Set the entity's current state"""
	var old_state = current_state
	current_state = new_state
	state_timer = 0.0
	
	emit_signal("patron_state_changed", old_state, new_state)
	log_component_message("State changed: " + old_state + " -> " + new_state)

func activate_patron() -> void:
	"""Activate the patron entity"""
	is_active = true
	
	# Activate all components
	for component in components.values():
		if component and component.has_method("activate"):
			component.activate()
	
	emit_signal("patron_activated", self)
	log_component_message("Patron activated")

func deactivate_patron() -> void:
	"""Deactivate the patron entity"""
	is_active = false
	
	# Deactivate all components
	for component in components.values():
		if component and component.has_method("deactivate"):
			component.deactivate()
	
	emit_signal("patron_deactivated", self)
	log_component_message("Patron deactivated")

## Patron data access
func get_patron_data() -> PatronData:
	"""Get the patron's data resource"""
	return patron_data

func get_patron_info() -> Dictionary:
	"""Get basic patron information"""
	return {
		"id": patron_id,
		"name": patron_name,
		"title": patron_title,
		"state": current_state,
		"is_active": is_active,
		"is_initialized": is_initialized
	}

## Movement and positioning
func set_position(new_position: Vector2) -> void:
	"""Set the patron's position"""
	position = new_position

func get_position() -> Vector2:
	"""Get the patron's current position"""
	return position

func move_to(target_position: Vector2) -> void:
	"""Move the patron to a target position"""
	# This would trigger movement in the behavior component
	var behavior = get_component("behavior")
	if behavior and behavior.has_method("set_behavior_state"):
		behavior.set_behavior_state("seeking_target")

## Animation management
func play_animation(animation_name: String) -> void:
	"""Play an animation on the patron"""
	if animation_player and animation_player.has_animation(animation_name):
		animation_player.play(animation_name)
		log_component_message("Playing animation: " + animation_name)
	else:
		log_component_message("Animation not found: " + animation_name)

## Bar interaction
func leave_bar() -> void:
	"""Signal that the patron is leaving the bar"""
	log_component_message("Leaving the bar")
	
	# Signal to patron manager
	# This would be handled by the PatronManager autoload
	pass

## Utility methods
func log_component_message(message: String) -> void:
	"""Log a message from this patron entity"""
	print("Patron[" + patron_name + "]: " + message)

func is_patron_ready() -> bool:
	"""Check if the patron is ready to function"""
	return is_initialized and is_active and patron_data != null

func get_component_summary() -> String:
	"""Get a summary of all components"""
	var summary = "Patron: " + patron_name + "\n"
	summary += "Components: " + str(components.keys()) + "\n"
	summary += "State: " + current_state + "\n"
	summary += "Active: " + str(is_active)
	
	return summary

## Save/Load support
func get_save_data() -> Dictionary:
	"""Get patron data for saving to persistent storage"""
	var component_data = {}
	for component_name in components.keys():
		var component = components[component_name]
		if component and component.has_method("get_save_data"):
			component_data[component_name] = component.get_save_data()
	
	return {
		"patron_id": patron_id,
		"patron_name": patron_name,
		"patron_title": patron_title,
		"current_state": current_state,
		"state_timer": state_timer,
		"is_active": is_active,
		"is_initialized": is_initialized,
		"position": position,
		"component_data": component_data
	}

func load_save_data(data: Dictionary) -> void:
	"""Load patron data from persistent storage"""
	patron_id = data.get("patron_id", "")
	patron_name = data.get("patron_name", "")
	patron_title = data.get("patron_title", "")
	current_state = data.get("current_state", "idle")
	state_timer = data.get("state_timer", 0.0)
	is_active = data.get("is_active", true)
	is_initialized = data.get("is_initialized", false)
	position = data.get("position", Vector2.ZERO)
	
	# Load component data
	var component_data = data.get("component_data", {})
	for component_name in component_data.keys():
		var component = components.get(component_name)
		if component and component.has_method("load_save_data"):
			component.load_save_data(component_data[component_name])
