extends Node2D

## Simple test controller for basic functionality testing

@onready var player: Player = $Player

func _ready() -> void:
	"""Initialize the test scene"""
	print("=== TEST SCENE DEBUG INFO ===")
	print("Simple test scene loaded successfully!")
	print("Player node found: ", player != null)
	if player:
		print("Player position: ", player.global_position)
		print("Player velocity: ", player.velocity)
	
	# Test basic autoload functionality
	print("=== AUTOLOAD TEST ===")
	# Wait a frame to ensure autoloads are ready
	await get_tree().process_frame
	
	if has_node("/root/GameManager"):
		print("GameManager autoload found")
		var game_manager = get_node("/root/GameManager")
		if game_manager.has_method("get_current_game_state"):
			print("Game state: ", game_manager.get_current_game_state())
	else:
		print("GameManager autoload NOT found")
	
	if has_node("/root/DataManager"):
		print("DataManager autoload found")
	else:
		print("DataManager autoload NOT found")
	
	print("=== END DEBUG INFO ===")

func _physics_process(_delta: float) -> void:
	"""Handle basic player movement for testing"""
	if not player:
		print("Player node not found!")
		return
	
	# Try to get input using the defined actions
	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Fallback to direct key checking if input actions don't work
	if input_vector == Vector2.ZERO:
		input_vector = Vector2.ZERO
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			input_vector.x -= 1
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			input_vector.x += 1
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			input_vector.y -= 1
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			input_vector.y += 1
	
	if input_vector != Vector2.ZERO:
		player.velocity = input_vector * 200.0
		print("Moving player: ", input_vector)
	else:
		player.velocity = Vector2.ZERO
	
	player.move_and_slide()
	
	# Debug output every few frames
	if Engine.get_process_frames() % 60 == 0:
		print("Player position: ", player.global_position, " Velocity: ", player.velocity)
