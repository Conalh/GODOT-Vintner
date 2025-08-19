class_name IPatronComponent
extends Node

## IPatronComponent - Base component contract for all patron components
## Defines the interface that all patron components must implement
## Enables dynamic component composition for different vampire archetypes

## Component identification
@export var component_id: String = ""
@export var component_name: String = ""
@export var component_type: String = ""

## Component state and lifecycle
var is_active: bool = true
var is_initialized: bool = false
var component_data: Dictionary = {}

## Reference to the parent patron entity
var patron_entity: Node = null

## Signals for component communication
signal component_initialized(component: IPatronComponent)
signal component_activated(component: IPatronComponent)
signal component_deactivated(component: IPatronComponent)
signal component_data_changed(component: IPatronComponent, data: Dictionary)

## Virtual methods that must be implemented by derived components
func initialize(patron: Node, data: Dictionary = {}) -> void:
	"""Initialize the component with patron reference and data"""
	patron_entity = patron
	component_data = data
	_on_initialize()
	is_initialized = true
	emit_signal("component_initialized", self)

func activate() -> void:
	"""Activate the component"""
	is_active = true
	_on_activate()
	emit_signal("component_activated", self)

func deactivate() -> void:
	"""Deactivate the component"""
	is_active = false
	_on_deactivate()
	emit_signal("component_deactivated", self)

func update_component(delta: float) -> void:
	"""Update the component logic (called every frame when active)"""
	if is_active and is_initialized:
		_on_update(delta)

func get_component_data() -> Dictionary:
	"""Get the component's current data"""
	return component_data.duplicate()

func set_component_data(data: Dictionary) -> void:
	"""Set the component's data"""
	component_data = data.duplicate()
	_on_data_changed(data)
	emit_signal("component_data_changed", self, data)

func reset_component() -> void:
	"""Reset the component to its initial state"""
	_on_reset()
	is_initialized = false
	is_active = false

## Virtual methods that can be overridden by derived components
func _on_initialize() -> void:
	"""Called when the component is initialized - override in derived classes"""
	pass

func _on_activate() -> void:
	"""Called when the component is activated - override in derived classes"""
	pass

func _on_deactivate() -> void:
	"""Called when the component is deactivated - override in derived classes"""
	pass

func _on_update(delta: float) -> void:
	"""Called every frame when the component is active - override in derived classes"""
	pass

func _on_data_changed(data: Dictionary) -> void:
	"""Called when component data changes - override in derived classes"""
	pass

func _on_reset() -> void:
	"""Called when the component is reset - override in derived classes"""
	pass

## Utility methods
func is_component_ready() -> bool:
	"""Check if the component is ready to function"""
	return is_initialized and is_active and patron_entity != null

func get_patron_data() -> PatronData:
	"""Get the patron data from the patron entity"""
	if patron_entity and patron_entity.has_method("get_patron_data"):
		return patron_entity.get_patron_data()
	return null

func get_patron_position() -> Vector2:
	"""Get the patron's current position"""
	if patron_entity and patron_entity.has_method("get_position"):
		return patron_entity.get_position()
	return Vector2.ZERO

func log_component_message(message: String) -> void:
	"""Log a message from this component for debugging"""
	if patron_entity and patron_entity.has_method("log_component_message"):
		patron_entity.log_component_message(component_name + ": " + message)
	else:
		print(component_name + ": " + message)

## Component validation
func validate_component() -> bool:
	"""Validate that the component is properly configured"""
	if component_id.is_empty():
		log_component_message("ERROR: Component ID is empty")
		return false
	
	if component_name.is_empty():
		log_component_message("ERROR: Component name is empty")
		return false
	
	if component_type.is_empty():
		log_component_message("ERROR: Component type is empty")
		return false
	
	return true

## Save/Load support for component state
func get_save_data() -> Dictionary:
	"""Get component data for saving to persistent storage"""
	return {
		"component_id": component_id,
		"component_name": component_name,
		"component_type": component_type,
		"is_active": is_active,
		"is_initialized": is_initialized,
		"component_data": component_data
	}

func load_save_data(data: Dictionary) -> void:
	"""Load component data from persistent storage"""
	component_id = data.get("component_id", "")
	component_name = data.get("component_name", "")
	component_type = data.get("component_type", "")
	is_active = data.get("is_active", true)
	is_initialized = data.get("is_initialized", false)
	component_data = data.get("component_data", {})
