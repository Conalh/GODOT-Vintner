class_name BarCounter
extends IInteractable

## Main serving station for the bar that manages patron seating and service
## Integrates with PatronManager to spawn and route patrons

# Bar counter properties
@export var max_seats: int = 6
@export var seat_spacing: float = 80.0
@export var counter_length: float = 400.0
@export var seat_offset_from_counter: float = 30.0

# Seating management
var available_seats: Array[Vector2] = []
var occupied_seats: Dictionary = {}  # seat_position -> patron_entity
var seat_queue: Array[PatronEntity] = []

# Patron management
var current_patrons: Array[PatronEntity] = []
var max_patrons: int = 8
var spawn_timer: float = 0.0
var spawn_interval: float = 15.0

# Service state
var is_serving: bool = false
var current_order: Dictionary = {}
var service_timer: float = 0.0
var service_duration: float = 3.0

# Visual feedback
@onready var counter_sprite: Sprite2D = $CounterSprite
@onready var seat_markers: Node2D = $SeatMarkers
@onready var service_indicator: Sprite2D = $ServiceIndicator
@onready var patron_spawn_point: Marker2D = $PatronSpawnPoint

func _ready() -> void:
	super._ready()
	_setup_bar_counter()
	_setup_seats()
	_connect_signals()

func _setup_bar_counter() -> void:
	"""Initialize the bar counter setup"""
	interaction_prompt = "Press E to serve patrons"
	interaction_range = 100.0
	requires_line_of_sight = false
	
	# Set up visual elements
	if counter_sprite:
		counter_sprite.texture = preload("res://assets/sprites/bar_counter.png")
	
	if service_indicator:
		service_indicator.visible = false

func _setup_seats() -> void:
	"""Initialize seating positions along the counter"""
	var start_x: float = -counter_length / 2
	var center_y: float = 0.0
	
	for i in range(max_seats):
		var seat_x: float = start_x + (i * seat_spacing) + (seat_spacing / 2)
		var seat_position: Vector2 = Vector2(seat_x, center_y + seat_offset_from_counter)
		available_seats.append(seat_position)
		
		# Create visual seat marker
		var marker: Sprite2D = Sprite2D.new()
		marker.texture = preload("res://assets/sprites/seat_marker.png")
		marker.position = seat_position
		marker.modulate = Color.GREEN  # Available seat
		seat_markers.add_child(marker)

func _connect_signals() -> void:
	"""Connect to necessary signals"""
	if PatronManager:
		PatronManager.patron_spawned.connect(_on_patron_spawned)
		PatronManager.patron_removed.connect(_on_patron_removed)

func _process(delta: float) -> void:
	"""Update bar counter logic"""
	super._process(delta)
	_update_patron_spawning(delta)
	_update_service(delta)
	_update_seat_management()

func _update_patron_spawning(delta: float) -> void:
	"""Handle automatic patron spawning"""
	if current_patrons.size() >= max_patrons:
		return
	
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		_spawn_patron()

func _update_service(delta: float) -> void:
	"""Update service state and timing"""
	if is_serving:
		service_timer += delta
		if service_timer >= service_duration:
			_complete_service()

func _update_seat_management() -> void:
	"""Manage seat availability and patron routing"""
	# Route queued patrons to available seats
	while seat_queue.size() > 0 and available_seats.size() > 0:
		var patron: PatronEntity = seat_queue.pop_front()
		var seat_position: Vector2 = available_seats.pop_front()
		_assign_patron_to_seat(patron, seat_position)

func _spawn_patron() -> void:
	"""Spawn a new patron at the spawn point"""
	if not patron_spawn_point:
		return
	
	var patron_data: PatronData = PatronManager.get_random_patron_template()
	if not patron_data:
		return
	
	var patron_scene: PackedScene = preload("res://scenes/entities/patron_entity.tscn")
	var patron_instance: PatronEntity = patron_scene.instantiate()
	
	# Add to current scene
	get_parent().add_child(patron_instance)
	patron_instance.position = patron_spawn_point.global_position
	
	# Initialize with patron data
	patron_instance.initialize_patron(patron_data)
	
	# Add to current patrons
	current_patrons.append(patron_instance)
	
	# Queue for seating
	seat_queue.append(patron_instance)
	
	# Connect patron signals
	patron_instance.patron_state_changed.connect(_on_patron_state_changed)

func _assign_patron_to_seat(patron: PatronEntity, seat_position: Vector2) -> void:
	"""Assign a patron to a specific seat"""
	occupied_seats[seat_position] = patron
	
	# Update seat marker visual
	var marker: Sprite2D = _get_seat_marker_at_position(seat_position)
	if marker:
		marker.modulate = Color.RED  # Occupied seat
	
	# Tell patron to move to seat
	patron.move_to(seat_position)
	
	# Update patron behavior component
	var behavior_component: PatronBehavior = patron.get_component("PatronBehavior")
	if behavior_component:
		behavior_component.set_behavior_state(PatronBehavior.BehaviorState.SEEKING_SEAT)

func _get_seat_marker_at_position(position: Vector2) -> Sprite2D:
	"""Get the seat marker sprite at a specific position"""
	for marker in seat_markers.get_children():
		if marker.position == position:
			return marker
	return null

func _on_patron_state_changed(patron: PatronEntity, new_state: String) -> void:
	"""Handle patron state changes"""
	match new_state:
		"seated":
			_on_patron_seated(patron)
		"leaving":
			_on_patron_leaving(patron)

func _on_patron_seated(patron: PatronEntity) -> void:
	"""Handle patron being seated"""
	# Patron is now seated and ready to order
	patron.set_entity_state("ready_to_order")

func _on_patron_leaving(patron: PatronEntity) -> void:
	"""Handle patron leaving the bar"""
	# Free up the seat
	var seat_position: Vector2 = _get_patron_seat_position(patron)
	if seat_position != Vector2.ZERO:
		_free_seat(seat_position)
	
	# Remove from current patrons
	current_patrons.erase(patron)
	
	# Disconnect signals
	patron.patron_state_changed.disconnect(_on_patron_state_changed)

func _get_patron_seat_position(patron: PatronEntity) -> Vector2:
	"""Get the seat position for a specific patron"""
	for seat_pos in occupied_seats:
		if occupied_seats[seat_pos] == patron:
			return seat_pos
	return Vector2.ZERO

func _free_seat(seat_position: Vector2) -> void:
	"""Free up a seat for new patrons"""
	occupied_seats.erase(seat_position)
	available_seats.append(seat_position)
	
	# Update seat marker visual
	var marker: Sprite2D = _get_seat_marker_at_position(seat_position)
	if marker:
		marker.modulate = Color.GREEN  # Available seat

# IInteractable implementation
func can_interact(interactor: Node2D) -> bool:
	"""Check if the bar counter can be interacted with"""
	return super.can_interact(interactor) and not is_serving

func start_interaction(interactor: Node2D) -> bool:
	"""Start interaction with the bar counter"""
	if not super.start_interaction(interactor):
		return false
	
	# Start serving patrons
	_start_serving()
	return true

func _start_serving() -> void:
	"""Begin serving patrons at the counter"""
	is_serving = true
	service_timer = 0.0
	
	# Show service indicator
	if service_indicator:
		service_indicator.visible = true
	
	# Find next patron to serve
	var next_patron: PatronEntity = _get_next_patron_to_serve()
	if next_patron:
		_start_patron_order(next_patron)

func _get_next_patron_to_serve() -> PatronEntity:
	"""Get the next patron that needs service"""
	for patron in current_patrons:
		if patron.get_entity_state() == "ready_to_order":
			return patron
	return null

func _start_patron_order(patron: PatronEntity) -> void:
	"""Start taking an order from a patron"""
	current_order = {
		"patron": patron,
		"start_time": Time.get_time_dict_from_system(),
		"order_type": "wine_request"
	}
	
	# Update patron state
	patron.set_entity_state("ordering")
	
	# Emit interaction signal
	interaction_started.emit(self, patron)

func _complete_service() -> void:
	"""Complete the current service interaction"""
	is_serving = false
	service_timer = 0.0
	
	# Hide service indicator
	if service_indicator:
		service_indicator.visible = false
	
	# Complete the order
	if current_order.has("patron"):
		var patron: PatronEntity = current_order.patron
		_complete_patron_order(patron)
	
	# Clear current order
	current_order.clear()
	
	# Emit completion signal
	interaction_completed.emit(self, get_current_interactor())

func _complete_patron_order(patron: PatronEntity) -> void:
	"""Complete a patron's order"""
	# Update patron state
	patron.set_entity_state("served")
	
	# Add some delay before patron leaves
	var timer: Timer = Timer.new()
	timer.wait_time = 5.0
	timer.one_shot = true
	timer.timeout.connect(func(): _on_patron_order_completed(patron))
	add_child(timer)
	timer.start()

func _on_patron_order_completed(patron: PatronEntity) -> void:
	"""Handle patron order completion"""
	# Patron is satisfied and will leave
	patron.set_entity_state("leaving")

# Signal handlers
func _on_patron_spawned(patron: PatronEntity) -> void:
	"""Handle new patron spawning"""
	# This is handled in _spawn_patron now
	pass

func _on_patron_removed(patron: PatronEntity) -> void:
	"""Handle patron removal"""
	# This is handled in _on_patron_leaving now
	pass

# Utility methods
func get_available_seat_count() -> int:
	"""Get the number of available seats"""
	return available_seats.size()

func get_occupied_seat_count() -> int:
	"""Get the number of occupied seats"""
	return occupied_seats.size()

func get_total_seat_count() -> int:
	"""Get the total number of seats"""
	return max_seats

func is_seat_available() -> bool:
	"""Check if any seats are available"""
	return available_seats.size() > 0

func get_patron_at_seat(seat_position: Vector2) -> PatronEntity:
	"""Get the patron at a specific seat position"""
	return occupied_seats.get(seat_position, null)

func get_bar_status() -> Dictionary:
	"""Get the current status of the bar counter"""
	return {
		"available_seats": available_seats.size(),
		"occupied_seats": occupied_seats.size(),
		"current_patrons": current_patrons.size(),
		"is_serving": is_serving,
		"has_current_order": not current_order.is_empty()
	}
