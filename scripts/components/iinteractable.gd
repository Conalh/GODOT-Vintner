class_name IInteractable
extends Area2D

## IInteractable - Base interface for all interactive bar stations
## Defines the contract that all interactable objects must implement
## Enables consistent interaction system across the bar

## Interaction properties
@export var interaction_prompt: String = "Interact"
@export var interaction_range: float = 50.0
@export var is_interactable: bool = true
@export var requires_line_of_sight: bool = true
@export var interaction_cooldown: float = 0.5

## Interaction state
var is_being_interacted_with: bool = false
var current_interactor: Node = null
var last_interaction_time: float = 0.0
var interaction_count: int = 0

## Visual feedback
@export var highlight_material: Material = null
@export var interaction_indicator: Node = null
@export var show_prompt: bool = true

## Signals for interaction events
signal interaction_started(interactor: Node, interactable: IInteractable)
signal interaction_completed(interactor: Node, interactable: IInteractable)
signal interaction_failed(interactor: Node, interactable: IInteractable, reason: String)
signal interaction_cancelled(interactor: Node, interactable: IInteractable)
signal interactor_entered_range(interactor: Node, interactable: IInteractable)
signal interactor_exited_range(interactor: Node, interactable: IInteractable)

## Virtual methods that must be implemented by derived classes
func can_interact(interactor: Node) -> bool:
	"""Check if the interactor can interact with this object"""
	if not is_interactable:
		return false
	
	if not interactor:
		return false
	
	# Check cooldown
	if Time.get_time_dict_from_system()["second"] - last_interaction_time < interaction_cooldown:
		return false
	
	# Check if already being interacted with
	if is_being_interacted_with and current_interactor != interactor:
		return false
	
	# Check line of sight if required
	if requires_line_of_sight and not _has_line_of_sight(interactor):
		return false
	
	# Call derived class validation
	return _validate_interaction(interactor)

func start_interaction(interactor: Node) -> bool:
	"""Start an interaction with the specified interactor"""
	if not can_interact(interactor):
		return false
	
	is_being_interacted_with = true
	current_interactor = interactor
	last_interaction_time = Time.get_time_dict_from_system()["second"]
	interaction_count += 1
	
	# Call derived class interaction logic
	var success = _on_interaction_started(interactor)
	
	if success:
		emit_signal("interaction_started", interactor, self)
		_show_interaction_feedback(true)
	else:
		_cancel_interaction(interactor)
		emit_signal("interaction_failed", interactor, self, "Interaction failed to start")
	
	return success

func complete_interaction(interactor: Node) -> bool:
	"""Complete the current interaction"""
	if not is_being_interacted_with or current_interactor != interactor:
		return false
	
	# Call derived class completion logic
	var success = _on_interaction_completed(interactor)
	
	if success:
		emit_signal("interaction_completed", interactor, self)
		_show_interaction_feedback(false)
		_end_interaction()
	else:
		emit_signal("interaction_failed", interactor, self, "Interaction failed to complete")
	
	return success

func cancel_interaction(interactor: Node) -> void:
	"""Cancel the current interaction"""
	_cancel_interaction(interactor)

## Virtual methods that can be overridden by derived classes
func _validate_interaction(interactor: Node) -> bool:
	"""Validate if interaction is possible - override in derived classes"""
	return true

func _on_interaction_started(interactor: Node) -> bool:
	"""Called when interaction starts - override in derived classes"""
	return true

func _on_interaction_completed(interactor: Node) -> bool:
	"""Called when interaction completes - override in derived classes"""
	return true

func _on_interaction_cancelled(interactor: Node) -> void:
	"""Called when interaction is cancelled - override in derived classes"""
	pass

## Interaction lifecycle management
func _end_interaction() -> void:
	"""End the current interaction"""
	is_being_interacted_with = false
	current_interactor = null

func _cancel_interaction(interactor: Node) -> void:
	"""Cancel the current interaction"""
	_on_interaction_cancelled(interactor)
	emit_signal("interaction_cancelled", interactor, self)
	_show_interaction_feedback(false)
	_end_interaction()

## Line of sight checking
func _has_line_of_sight(interactor: Node) -> bool:
	"""Check if there's a clear line of sight between interactor and this object"""
	if not interactor:
		return false
	
	var interactor_pos = interactor.get_position()
	var self_pos = get_position()
	
	# Simple distance check for now
	# In a full implementation, this would use raycasting
	var distance = interactor_pos.distance_to(self_pos)
	return distance <= interaction_range

## Visual feedback
func _show_interaction_feedback(is_active: bool) -> void:
	"""Show visual feedback for interaction state"""
	if interaction_indicator:
		interaction_indicator.visible = is_active
	
	if highlight_material:
		# Apply or remove highlight material
		pass

func show_interaction_prompt(interactor: Node) -> void:
	"""Show the interaction prompt for the specified interactor"""
	if not show_prompt or not can_interact(interactor):
		return
	
	# This would show a UI prompt
	# Implementation depends on the UI system
	pass

func hide_interaction_prompt() -> void:
	"""Hide the interaction prompt"""
	# This would hide the UI prompt
	# Implementation depends on the UI system
	pass

## Utility methods
func get_interaction_prompt() -> String:
	"""Get the current interaction prompt"""
	return interaction_prompt

func set_interaction_prompt(new_prompt: String) -> void:
	"""Set a new interaction prompt"""
	interaction_prompt = new_prompt

func is_in_interaction_range(interactor: Node) -> bool:
	"""Check if an interactor is within interaction range"""
	if not interactor:
		return false
	
	var distance = interactor.get_position().distance_to(get_position())
	return distance <= interaction_range

func get_interaction_progress() -> float:
	"""Get the current interaction progress (0.0 to 1.0)"""
	# This would return progress for long interactions
	# Default implementation returns 0.0
	return 0.0

func get_interaction_duration() -> float:
	"""Get the expected duration of the interaction"""
	# This would return the time needed to complete the interaction
	# Default implementation returns 0.0 (instant)
	return 0.0

## Area2D signal handlers
func _on_area_entered(area: Area2D) -> void:
	"""Called when an interactor enters the interaction area"""
	var interactor = _get_interactor_from_area(area)
	if interactor:
		emit_signal("interactor_entered_range", interactor, self)
		show_interaction_prompt(interactor)

func _on_area_exited(area: Area2D) -> void:
	"""Called when an interactor exits the interaction area"""
	var interactor = _get_interactor_from_area(area)
	if interactor:
		emit_signal("interactor_exited_range", interactor, self)
		hide_interaction_prompt()
		
		# Cancel interaction if interactor leaves range
		if current_interactor == interactor:
			cancel_interaction(interactor)

func _get_interactor_from_area(area: Area2D) -> Node:
	"""Extract the interactor node from an area"""
	# This would traverse up the scene tree to find the actual interactor
	# For now, return the area's parent
	return area.get_parent()

## Component validation
func validate_interactable() -> bool:
	"""Validate that the interactable is properly configured"""
	if interaction_prompt.is_empty():
		print("ERROR: Interaction prompt is empty")
		return false
	
	if interaction_range <= 0:
		print("ERROR: Interaction range must be positive")
		return false
	
	return true

## Save/Load support for interaction state
func get_save_data() -> Dictionary:
	"""Get interaction data for saving to persistent storage"""
	return {
		"interaction_prompt": interaction_prompt,
		"interaction_range": interaction_range,
		"is_interactable": is_interactable,
		"requires_line_of_sight": requires_line_of_sight,
		"interaction_cooldown": interaction_cooldown,
		"interaction_count": interaction_count,
		"last_interaction_time": last_interaction_time
	}

func load_save_data(data: Dictionary) -> void:
	"""Load interaction data from persistent storage"""
	interaction_prompt = data.get("interaction_prompt", "Interact")
	interaction_range = data.get("interaction_range", 50.0)
	is_interactable = data.get("is_interactable", true)
	requires_line_of_sight = data.get("requires_line_of_sight", true)
	interaction_cooldown = data.get("interaction_cooldown", 0.5)
	interaction_count = data.get("interaction_count", 0)
	last_interaction_time = data.get("last_interaction_time", 0.0)
