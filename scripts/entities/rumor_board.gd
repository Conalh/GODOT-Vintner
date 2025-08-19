class_name RumorBoard
extends IInteractable

## Hunt selection interface that displays available rumors and allows hunt initiation
## Uses RumorData Resources to define hunt missions and rewards

# Board properties
@export var max_rumors_display: int = 6
@export var rumor_refresh_interval: float = 3600.0  # 1 hour
@export var max_active_rumors: int = 8
@export var rumor_unlock_level: int = 1

# Rumor state
var available_rumors: Array[RumorData] = []
var displayed_rumors: Array[RumorData] = []
var current_page: int = 0
var total_pages: int = 1
var last_refresh_time: float = 0.0
var selected_rumor: RumorData = null

# UI references
@onready var rumor_ui: Control = $RumorUI
@onready var rumor_grid: GridContainer = $RumorUI/RumorGrid
@onready var page_navigation: Control = $RumorUI/PageNavigation
@onready var prev_button: Button = $RumorUI/PageNavigation/PrevButton
@onready var next_button: Button = $RumorUI/PageNavigation/NextButton
@onready var page_label: Label = $RumorUI/PageNavigation/PageLabel
@onready var board_info: Control = $RumorUI/BoardInfo
@onready var refresh_timer: Label = $RumorUI/BoardInfo/RefreshTimer
@onready var hunt_button: Button = $RumorUI/HuntButton
@onready var rumor_details: Control = $RumorUI/RumorDetails

# Visual elements
@onready var board_sprite: Sprite2D = $BoardSprite
@onready var rumor_papers: Array[Sprite2D] = []
@onready var new_rumor_indicator: Sprite2D = $NewRumorIndicator
@onready var difficulty_glow: Sprite2D = $DifficultyGlow

# Audio
@onready var paper_rustle: AudioStreamPlayer = $PaperRustle
@onready var board_open: AudioStreamPlayer = $BoardOpen
@onready var board_close: AudioStreamPlayer = $BoardClose
@onready var rumor_select: AudioStreamPlayer = $RumorSelect

func _ready() -> void:
	super._ready()
	_setup_rumor_board()
	_setup_ui()
	_connect_signals()
	_refresh_available_rumors()

func _setup_rumor_board() -> void:
	"""Initialize the rumor board setup"""
	interaction_prompt = "Press E to view hunt rumors"
	interaction_range = 70.0
	requires_line_of_sight = false
	
	# Set up visual elements
	if board_sprite:
		board_sprite.texture = preload("res://assets/sprites/rumor_board.png")
	
	if new_rumor_indicator:
		new_rumor_indicator.visible = false

func _setup_ui() -> void:
	"""Initialize the rumor board UI elements"""
	if not rumor_ui:
		return
	
	# Hide UI initially
	rumor_ui.visible = false
	
	# Set up page navigation
	if prev_button:
		prev_button.text = "←"
		prev_button.disabled = true
	
	if next_button:
		next_button.text = "→"
		next_button.disabled = true
	
	if page_label:
		page_label.text = "Page 1 of 1"
	
	# Set up hunt button
	if hunt_button:
		hunt_button.text = "Start Hunt"
		hunt_button.disabled = true
	
	# Set up rumor grid
	_setup_rumor_grid()

func _setup_rumor_grid() -> void:
	"""Set up the rumor display grid"""
	if not rumor_grid:
		return
	
	# Create rumor slot containers
	for i in range(max_rumors_display):
		var rumor_slot: Control = _create_rumor_slot(i)
		rumor_grid.add_child(rumor_slot)

func _create_rumor_slot(index: int) -> Control:
	"""Create a rumor slot container"""
	var slot: PanelContainer = PanelContainer.new()
	slot.custom_minimum_size = Vector2(120, 150)
	
	# Add rumor title
	var title_label: Label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = ""
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	slot.add_child(title_label)
	
	# Add difficulty indicator
	var difficulty_indicator: ColorRect = ColorRect.new()
	difficulty_indicator.name = "DifficultyIndicator"
	difficulty_indicator.custom_minimum_size = Vector2(30, 6)
	difficulty_indicator.color = Color.GRAY
	slot.add_child(difficulty_indicator)
	
	# Add reward preview
	var reward_label: Label = Label.new()
	reward_label.name = "RewardLabel"
	reward_label.text = ""
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	slot.add_child(reward_label)
	
	# Add biome indicator
	var biome_label: Label = Label.new()
	biome_label.name = "BiomeLabel"
	biome_label.text = ""
	biome_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	biome_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	slot.add_child(biome_label)
	
	# Connect input
	slot.gui_input.connect(_on_rumor_slot_input.bind(index))
	
	return slot

func _connect_signals() -> void:
	"""Connect to necessary signals"""
	if SceneManager:
		SceneManager.scene_changed.connect(_on_scene_changed)

func _process(delta: float) -> void:
	"""Update rumor board logic"""
	super._process(delta)
	_update_refresh_timer(delta)
	_update_visual_indicators()

func _update_refresh_timer(delta: float) -> void:
	"""Update the rumor refresh timer"""
	if not refresh_timer:
		return
	
	var time_until_refresh: float = rumor_refresh_interval - (Time.get_time_dict_from_system()["unix"] - last_refresh_time)
	if time_until_refresh <= 0:
		_refresh_available_rumors()
		time_until_refresh = rumor_refresh_interval
	
	# Update timer display
	var minutes: int = int(time_until_refresh / 60.0)
	var seconds: int = int(time_until_refresh) % 60
	refresh_timer.text = "Refresh in: %02d:%02d" % [minutes, seconds]

func _update_visual_indicators() -> void:
	"""Update visual indicators for new rumors and difficulty"""
	if new_rumor_indicator:
		var has_new_rumors: bool = _check_for_new_rumors()
		new_rumor_indicator.visible = has_new_rumors
	
	if difficulty_glow:
		var has_high_difficulty: bool = _check_for_high_difficulty_rumors()
		difficulty_glow.visible = has_high_difficulty

func _check_for_new_rumors() -> bool:
	"""Check if there are any new rumors available"""
	for rumor in available_rumors:
		if rumor.can_be_accessed_by_player(PlayerData):
			return true
	return false

func _check_for_high_difficulty_rumors() -> bool:
	"""Check if there are any high difficulty rumors"""
	for rumor in available_rumors:
		if rumor.difficulty_rating >= 8:
			return true
	return false

# IInteractable implementation
func can_interact(interactor: Node2D) -> bool:
	"""Check if the rumor board can be interacted with"""
	return super.can_interact(interactor)

func start_interaction(interactor: Node2D) -> bool:
	"""Start interaction with the rumor board"""
	if not super.start_interaction(interactor):
		return false
	
	# Open rumor UI
	_open_rumor_ui()
	return true

func _open_rumor_ui() -> void:
	"""Open the rumor board interface"""
	if rumor_ui:
		rumor_ui.visible = true
	
	if board_open:
		board_open.play()
	
	# Update display
	_update_rumor_display()
	_update_page_navigation()

func _close_rumor_ui() -> void:
	"""Close the rumor board interface"""
	if rumor_ui:
		rumor_ui.visible = false
	
	if board_close:
		board_close.play()

func _refresh_available_rumors() -> void:
	"""Refresh the list of available rumors"""
	available_rumors.clear()
	
	# Get rumors from the game data or generate new ones
	_generate_available_rumors()
	
	# Filter based on player level and requirements
	_filter_rumors_by_player_requirements()
	
	# Update display
	_update_rumor_display()
	
	# Update last refresh time
	last_refresh_time = Time.get_time_dict_from_system()["unix"]

func _generate_available_rumors() -> void:
	"""Generate or load available rumors"""
	# This would typically load from a database or generate procedurally
	# For now, we'll create some sample rumors
	
	var sample_rumors: Array[RumorData] = [
		_create_sample_rumor("Whispers in the Desert", "Ancient blood sources hidden in the dunes", 3, "Desert"),
		_create_sample_rumor("Mountain Secrets", "Rare ingredients in the high peaks", 5, "Mountain"),
		_create_sample_rumor("Forest Shadows", "Mysterious creatures with unique blood", 7, "Forest"),
		_create_sample_rumor("Underground Tunnels", "Forgotten chambers with powerful relics", 9, "Underground")
	]
	
	available_rumors.append_array(sample_rumors)

func _create_sample_rumor(title: String, description: String, difficulty: int, biome: String) -> RumorData:
	"""Create a sample rumor for testing"""
	var rumor: RumorData = RumorData.new()
	rumor.id = "rumor_" + str(randi())
	rumor.title = title
	rumor.description = description
	rumor.hook = "A mysterious tale speaks of..."
	rumor.biome = biome
	rumor.difficulty_rating = difficulty
	rumor.risk_level = difficulty
	rumor.estimated_duration = difficulty * 10
	rumor.recommended_level = max(1, difficulty - 2)
	rumor.blood_source_rewards = ["blood_source_" + str(randi() % 5)]
	rumor.relic_chance = 0.1 + (difficulty * 0.05)
	rumor.prestige_reward = difficulty * 10
	rumor.currency_reward = difficulty * 25
	rumor.experience_reward = difficulty * 15
	rumor.hunt_type = "exploration"
	rumor.is_repeatable = false
	rumor.unlock_requirements = {"level": rumor.recommended_level}
	
	return rumor

func _filter_rumors_by_player_requirements() -> void:
	"""Filter rumors based on player level and requirements"""
	if not PlayerData:
		return
	
	var filtered_rumors: Array[RumorData] = []
	
	for rumor in available_rumors:
		if rumor.can_be_accessed_by_player(PlayerData):
			filtered_rumors.append(rumor)
	
	available_rumors = filtered_rumors

func _update_rumor_display() -> void:
	"""Update the rumor display"""
	# Calculate total pages
	total_pages = max(1, ceili(float(available_rumors.size()) / float(max_rumors_display)))
	current_page = clamp(current_page, 0, total_pages - 1)
	
	# Update displayed rumors
	_update_displayed_rumors()
	
	# Update board info
	_update_board_info()

func _update_displayed_rumors() -> void:
	"""Update the rumors displayed on the current page"""
	var start_index: int = current_page * max_rumors_display
	var end_index: int = min(start_index + max_rumors_display, available_rumors.size())
	
	displayed_rumors.clear()
	for i in range(start_index, end_index):
		displayed_rumors.append(available_rumors[i])
	
	# Update rumor grid
	_update_rumor_grid()

func _update_rumor_grid() -> void:
	"""Update the rumor grid display"""
	if not rumor_grid:
		return
	
	var grid_children: Array = rumor_grid.get_children()
	
	for i in range(grid_children.size()):
		var slot: Control = grid_children[i]
		if i < displayed_rumors.size():
			_display_rumor_in_slot(slot, displayed_rumors[i])
		else:
			_clear_rumor_slot(slot)

func _display_rumor_in_slot(slot: Control, rumor: RumorData) -> void:
	"""Display a rumor in a slot"""
	if not slot:
		return
	
	# Set rumor title
	var title_label: Label = slot.get_node_or_null("TitleLabel")
	if title_label:
		title_label.text = rumor.title
	
	# Set difficulty indicator
	var difficulty_indicator: ColorRect = slot.get_node_or_null("DifficultyIndicator")
	if difficulty_indicator:
		difficulty_indicator.color = _get_difficulty_color(rumor.difficulty_rating)
	
	# Set reward preview
	var reward_label: Label = slot.get_node_or_null("RewardLabel")
	if reward_label:
		reward_label.text = "Reward: " + str(rumor.currency_reward) + " coins"
	
	# Set biome indicator
	var biome_label: Label = slot.get_node_or_null("BiomeLabel")
	if biome_label:
		biome_label.text = rumor.biome

func _clear_rumor_slot(slot: Control) -> void:
	"""Clear a rumor slot"""
	if not slot:
		return
	
	var title_label: Label = slot.get_node_or_null("TitleLabel")
	if title_label:
		title_label.text = ""
	
	var difficulty_indicator: ColorRect = slot.get_node_or_null("DifficultyIndicator")
	if difficulty_indicator:
		difficulty_indicator.color = Color.GRAY
	
	var reward_label: Label = slot.get_node_or_null("RewardLabel")
	if reward_label:
		reward_label.text = ""
	
	var biome_label: Label = slot.get_node_or_null("BiomeLabel")
	if biome_label:
		biome_label.text = ""

func _get_difficulty_color(difficulty: int) -> Color:
	"""Get color based on rumor difficulty"""
	if difficulty >= 9:
		return Color.RED
	elif difficulty >= 7:
		return Color.ORANGE
	elif difficulty >= 5:
		return Color.YELLOW
	elif difficulty >= 3:
		return Color.GREEN
	else:
		return Color.BLUE

func _update_board_info() -> void:
	"""Update the board information display"""
	if not board_info:
		return
	
	# Update total rumors label
	var total_rumors_label: Label = board_info.get_node_or_null("TotalRumorsLabel")
	if total_rumors_label:
		total_rumors_label.text = "Available Hunts: " + str(available_rumors.size())

func _update_page_navigation() -> void:
	"""Update page navigation button states"""
	if not page_navigation:
		return
	
	# Update prev button
	if prev_button:
		prev_button.disabled = current_page <= 0
	
	# Update next button
	if next_button:
		next_button.disabled = current_page >= total_pages - 1
	
	# Update page label
	if page_label:
		page_label.text = "Page " + str(current_page + 1) + " of " + str(total_pages)

func _on_rumor_slot_input(slot_index: int, event: InputEvent) -> void:
	"""Handle input on rumor slots"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_rumor(slot_index)

func _select_rumor(slot_index: int) -> void:
	"""Select a rumor from a slot"""
	if slot_index >= displayed_rumors.size():
		return
	
	var rumor: RumorData = displayed_rumors[slot_index]
	if not rumor:
		return
	
	# Select the rumor
	selected_rumor = rumor
	
	# Show rumor details
	_show_rumor_details(rumor)
	
	// Enable hunt button
	if hunt_button:
		hunt_button.disabled = false
	
	if rumor_select:
		rumor_select.play()

func _show_rumor_details(rumor: RumorData) -> void:
	"""Show detailed information about a selected rumor"""
	if not rumor_details:
		return
	
	rumor_details.visible = true
	
	// Set rumor title
	var title_label: Label = rumor_details.get_node_or_null("TitleLabel")
	if title_label:
		title_label.text = rumor.title
	
	// Set rumor description
	var desc_label: Label = rumor_details.get_node_or_null("DescriptionLabel")
	if desc_label:
		desc_label.text = rumor.description
	
	// Set difficulty information
	var difficulty_label: Label = rumor_details.get_node_or_null("DifficultyLabel")
	if difficulty_label:
		difficulty_label.text = "Difficulty: " + rumor.get_difficulty_description()
	
	// Set reward information
	var reward_label: Label = rumor_details.get_node_or_null("RewardLabel")
	if reward_label:
		reward_label.text = "Expected Rewards: " + rumor.get_expected_reward_summary()
	
	// Set hunt duration
	var duration_label: Label = rumor_details.get_node_or_null("DurationLabel")
	if duration_label:
		duration_label.text = "Estimated Duration: " + rumor.get_hunt_duration_text()

func _on_hunt_button_pressed() -> void:
	"""Handle hunt button press"""
	if not selected_rumor:
		return
	
	_start_hunt(selected_rumor)

func _start_hunt(rumor: RumorData) -> void:
	"""Start a hunt based on the selected rumor"""
	if not SceneManager:
		return
	
	// Store hunt data
	if GameManager:
		GameManager.start_hunt_mode()
	
	// Change to hunt scene
	var hunt_scene_path: String = rumor.hunt_scene_path
	if hunt_scene_path.is_empty():
		hunt_scene_path = "res://scenes/hunt/hunt_level.tscn"
	
	SceneManager.start_hunt(hunt_scene_path, rumor)
	
	// Close rumor UI
	_close_rumor_ui()
	
	// Emit completion signal
	interaction_completed.emit(self, get_current_interactor())

# Page navigation
func _on_prev_button_pressed() -> void:
	"""Handle previous page button press"""
	if current_page > 0:
		current_page -= 1
		_update_displayed_rumors()
		_update_page_navigation()

func _on_next_button_pressed() -> void:
	"""Handle next page button press"""
	if current_page < total_pages - 1:
		current_page += 1
		_update_displayed_rumors()
		_update_page_navigation()

# Signal handlers
func _on_scene_changed(scene_path: String) -> void:
	"""Handle scene changes"""
	// Refresh rumors when returning to hub
	if scene_path.contains("hub"):
		_refresh_available_rumors()

# Utility methods
func get_board_status() -> Dictionary:
	"""Get the current status of the rumor board"""
	return {
		"total_rumors": available_rumors.size(),
		"current_page": current_page + 1,
		"total_pages": total_pages,
		"displayed_rumors": displayed_rumors.size(),
		"selected_rumor": selected_rumor.title if selected_rumor else "None"
	}

func get_rumors_by_difficulty(max_difficulty: int) -> Array[RumorData]:
	"""Get rumors below a certain difficulty threshold"""
	var filtered_rumors: Array[RumorData] = []
	for rumor in available_rumors:
		if rumor.difficulty_rating <= max_difficulty:
			filtered_rumors.append(rumor)
	return filtered_rumors

func get_rumors_by_biome(biome: String) -> Array[RumorData]:
	"""Get rumors for a specific biome"""
	var biome_rumors: Array[RumorData] = []
	for rumor in available_rumors:
		if rumor.biome == biome:
			biome_rumors.append(rumor)
	return biome_rumors

func can_start_hunt() -> bool:
	"""Check if a hunt can be started"""
	return selected_rumor != null

func get_selected_rumor() -> RumorData:
	"""Get the currently selected rumor"""
	return selected_rumor

func force_refresh_rumors() -> void:
	"""Force a refresh of available rumors"""
	_refresh_available_rumors()
