class_name TestInteractable
extends Area2D

## Simple test interactable for testing the interaction system

signal interaction_started(interactor: Node)
signal interaction_ended(interactor: Node)

@export var interaction_prompt: String = "Test Interaction"
@export var interaction_range: float = 64.0
@export var is_interactable: bool = true
@export var requires_line_of_sight: bool = false
@export var interaction_cooldown: float = 1.0
@export var is_being_interacted_with: bool = false
@export var current_interactor: Node = null
@export var last_interaction_time: float = 0.0
@export var interaction_count: int = 0

func _ready() -> void:
	"""Initialize the test interactable"""
	_setup_collision()
	_setup_visual_feedback()

func _setup_collision() -> void:
	"""Set up collision detection"""
	# The collision shape is already set up in the scene
	pass

func _setup_visual_feedback() -> void:
	"""Set up visual feedback for interaction"""
	# Change color when being interacted with
	pass

func can_interact(interactor: Node) -> bool:
	"""Check if the interactor can interact with this object"""
	if not is_interactable:
		return false
	
	if is_being_interacted_with:
		return false
	
	var current_time: float = Time.get_time_dict_from_system()["unix"]
	if current_time - last_interaction_time < interaction_cooldown:
		return false
	
	return true

func start_interaction(interactor: Node) -> void:
	"""Start interaction with the interactor"""
	if not can_interact(interactor):
		return
	
	is_being_interacted_with = true
	current_interactor = interactor
	last_interaction_time = Time.get_time_dict_from_system()["unix"]
	interaction_count += 1
	
	# Visual feedback
	var sprite: ColorRect = get_node_or_null("Sprite2D")
	if sprite:
		sprite.color = Color(0.8, 0.8, 0.2, 1)  # Yellow when interacting
	
	# Emit signal
	interaction_started.emit(interactor)
	
	print("Test interaction started! Count: ", interaction_count)

func end_interaction(interactor: Node) -> void:
	"""End interaction with the interactor"""
	if not is_being_interacted_with or current_interactor != interactor:
		return
	
	is_being_interacted_with = false
	current_interactor = null
	
	# Visual feedback
	var sprite: ColorRect = get_node_or_null("Sprite2D")
	if sprite:
		sprite.color = Color(0.2, 0.8, 0.2, 1)  # Green when not interacting
	
	# Emit signal
	interaction_ended.emit(interactor)
	
	print("Test interaction ended!")

func get_interaction_prompt() -> String:
	"""Get the interaction prompt text"""
	return interaction_prompt

func is_currently_interactable() -> bool:
	"""Check if currently interactable"""
	return is_interactable and not is_being_interacted_with
