class_name Player
extends CharacterBody2D

## Player controller for the vampire character
## Handles movement, interaction with bar stations, and animation states

signal interaction_started(interactable: Node)
signal interaction_ended(interactable: Node)
signal interaction_completed(interactable: Node)

# Movement properties
@export var max_speed: float = 200.0
@export var acceleration: float = 800.0
@export var friction: float = 600.0
@export var rotation_speed: float = 5.0

# Interaction properties
@export var interaction_range: float = 64.0
@export var interaction_cooldown: float = 0.2
@export var show_interaction_prompt: bool = true

# Animation properties
@export var animation_blend_time: float = 0.1
@export var idle_threshold: float = 10.0

# Node references
@onready var sprite: ColorRect = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_prompt: Label = $InteractionPrompt
@onready var interaction_timer: Timer = $InteractionTimer

# Internal state
var input_vector: Vector2 = Vector2.ZERO
var is_interacting: bool = false
var current_interactable: Node = null
var last_interaction_time: float = 0.0
var current_animation: String = "idle"
var is_moving: bool = false

func _ready() -> void:
	"""Initialize the player controller"""
	_setup_interaction_area()
	_setup_interaction_timer()
	_setup_animation_player()
	_setup_input_handling()
	
	# Connect interaction area signals
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)
	
	# Start with idle animation
	_play_animation("idle")

func _physics_process(delta: float) -> void:
	"""Handle physics updates for movement and interaction"""
	_handle_input()
	_handle_movement(delta)
	_handle_animation()
	_handle_interaction_prompt()

func _setup_interaction_area() -> void:
	"""Configure the interaction detection area"""
	if interaction_area:
		var collision_shape: CollisionShape2D = interaction_area.get_node_or_null("CollisionShape2D")
		if collision_shape and collision_shape.shape is RectangleShape2D:
			var rect_shape: RectangleShape2D = collision_shape.shape
			rect_shape.size = Vector2(interaction_range * 2, interaction_range * 2)
		else:
			# Create collision shape if it doesn't exist
			var new_collision_shape: CollisionShape2D = CollisionShape2D.new()
			var rect_shape: RectangleShape2D = RectangleShape2D.new()
			rect_shape.size = Vector2(interaction_range * 2, interaction_range * 2)
			new_collision_shape.shape = rect_shape
			interaction_area.add_child(new_collision_shape)

func _setup_interaction_timer() -> void:
	"""Configure the interaction cooldown timer"""
	if interaction_timer:
		interaction_timer.wait_time = interaction_cooldown
		interaction_timer.one_shot = true

func _setup_animation_player() -> void:
	"""Configure the animation player with default animations"""
	if animation_player:
		# Ensure we have basic animations
		if not animation_player.has_animation("idle"):
			push_warning("Missing 'idle' animation in AnimationPlayer!")
		if not animation_player.has_animation("walk"):
			push_warning("Missing 'walk' animation in AnimationPlayer!")

func _setup_input_handling() -> void:
	"""Set up input action mappings if they don't exist"""
	# This will be handled by the input mapping constants
	pass

func _handle_input() -> void:
	"""Process player input for movement and interaction"""
	# Get movement input
	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Handle interaction input
	if Input.is_action_just_pressed("interact") and _can_interact():
		_start_interaction()

func _handle_movement(delta: float) -> void:
	"""Handle player movement physics"""
	if is_interacting:
		# Stop movement during interaction
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	else:
		# Apply movement
		if input_vector != Vector2.ZERO:
			velocity = velocity.move_toward(input_vector * max_speed, acceleration * delta)
			is_moving = true
		else:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
			is_moving = false
	
	# Apply movement
	move_and_slide()
	
	# Handle rotation towards movement direction
	if input_vector != Vector2.ZERO:
		var target_rotation: float = input_vector.angle()
		rotation = lerp_angle(rotation, target_rotation, rotation_speed * delta)

func _handle_animation() -> void:
	"""Update player animations based on current state"""
	var target_animation: String = "idle"
	
	if is_interacting:
		target_animation = "idle"
	elif is_moving and velocity.length() > idle_threshold:
		target_animation = "walk"
	else:
		target_animation = "idle"
	
	if target_animation != current_animation:
		_play_animation(target_animation)
		current_animation = target_animation

func _handle_interaction_prompt() -> void:
	"""Show/hide interaction prompt based on available interactables"""
	if interaction_prompt:
		if current_interactable and show_interaction_prompt:
			var prompt_text: String = "Press E to Interact"
			if current_interactable.has_method("get_interaction_prompt"):
				prompt_text = current_interactable.get_interaction_prompt()
			interaction_prompt.text = prompt_text
			interaction_prompt.visible = true
		else:
			interaction_prompt.visible = false

func _play_animation(animation_name: String) -> void:
	"""Play the specified animation with blending"""
	if animation_player and animation_player.has_animation(animation_name):
		animation_player.play(animation_name)
		animation_player.speed_scale = 1.0

func _can_interact() -> bool:
	"""Check if the player can interact with the current interactable"""
	if not current_interactable:
		return false
	
	if is_interacting:
		return false
	
	var time_dict = Time.get_time_dict_from_system()
	var current_time: float = 0.0
	if "timestamp" in time_dict:
		current_time = time_dict["timestamp"]
	elif "unix" in time_dict:
		current_time = time_dict["unix"]
	else:
		push_error("Time dictionary missing 'timestamp' and 'unix' keys! Contents: %s" % str(time_dict))
	if current_time - last_interaction_time < interaction_cooldown:
		return false
	
	# Check if the interactable has the required methods
	if current_interactable.has_method("can_interact"):
		return current_interactable.can_interact(self)
	
	return true

func _start_interaction() -> void:
	"""Begin interaction with the current interactable"""
	if not current_interactable:
		return
	
	is_interacting = true
	var time_dict = Time.get_time_dict_from_system()
	if "unix" in time_dict:
		last_interaction_time = time_dict["unix"]
	elif "timestamp" in time_dict:
		last_interaction_time = time_dict["timestamp"]
	else:
		push_error("Time dictionary missing 'unix' and 'timestamp' keys! Contents: %s" % str(time_dict))
	
	# Start interaction timer
	if interaction_timer:
		interaction_timer.start()
	
	# Emit signal
	interaction_started.emit(current_interactable)
	
	# Start interaction on the interactable
	if current_interactable.has_method("start_interaction"):
		current_interactable.start_interaction(self)

func _end_interaction() -> void:
	"""End the current interaction"""
	if not is_interacting:
		return
	
	is_interacting = false
	
	if current_interactable:
		if current_interactable.has_method("end_interaction"):
			current_interactable.end_interaction(self)
		interaction_ended.emit(current_interactable)

func _on_interaction_area_entered(area: Area2D) -> void:
	"""Handle when an interactable enters the interaction area"""
	var interactable: Node = area
	if interactable and interactable.has_method("is_currently_interactable"):
		if interactable.is_currently_interactable():
			current_interactable = interactable
	elif interactable:
		# Fallback for basic Area2D nodes
		current_interactable = interactable

func _on_interaction_area_exited(area: Area2D) -> void:
	"""Handle when an interactable exits the interaction area"""
	var interactable: Node = area
	if interactable == current_interactable:
		if is_interacting:
			_end_interaction()
		current_interactable = null

func _on_interaction_timer_timeout() -> void:
	"""Handle interaction timer timeout"""
	if is_interacting:
		_end_interaction()

func get_interaction_range() -> float:
	"""Get the current interaction range"""
	return interaction_range

func set_interaction_range(new_range: float) -> void:
	"""Set a new interaction range"""
	interaction_range = new_range
	_setup_interaction_area()

func is_currently_interacting() -> bool:
	"""Check if the player is currently interacting"""
	return is_interacting

func get_current_interactable() -> Node:
	"""Get the current interactable in range"""
	return current_interactable

func force_end_interaction() -> void:
	"""Force end the current interaction (useful for scene transitions)"""
	_end_interaction()

func save_player_state() -> Dictionary:
	"""Save the current player state for persistence"""
	return {
		"position": global_position,
		"rotation": rotation,
		"current_animation": current_animation,
		"interaction_range": interaction_range,
		"max_speed": max_speed
	}

func load_player_state(state: Dictionary) -> void:
	"""Load player state from saved data"""
	if state.has("position"):
		global_position = state["position"]
	if state.has("rotation"):
		rotation = state["rotation"]
	if state.has("interaction_range"):
		set_interaction_range(state["interaction_range"])
	if state.has("max_speed"):
		max_speed = state["max_speed"]
