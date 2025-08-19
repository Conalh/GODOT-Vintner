class_name CellarShelf
extends IInteractable

## Wine storage and inventory management station
## Displays stored wines and allows access to inventory management

# Shelf properties
@export var max_wine_display: int = 12
@export var shelf_capacity: int = 50
@export var aging_bonus_multiplier: float = 1.2
@export var quality_preservation: float = 0.95

# Storage state
var stored_wines: Array[WineRecipe] = []
var displayed_wines: Array[WineRecipe] = []
var current_page: int = 0
var total_pages: int = 1

# UI references
@onready var storage_ui: Control = $StorageUI
@onready var wine_grid: GridContainer = $StorageUI/WineGrid
@onready var page_navigation: Control = $StorageUI/PageNavigation
@onready var prev_button: Button = $StorageUI/PageNavigation/PrevButton
@onready var next_button: Button = $StorageUI/PageNavigation/NextButton
@onready var page_label: Label = $StorageUI/PageNavigation/PageLabel
@onready var storage_info: Control = $StorageUI/StorageInfo
@onready var capacity_bar: ProgressBar = $StorageUI/StorageInfo/CapacityBar
@onready var total_wines_label: Label = $StorageUI/StorageInfo/TotalWinesLabel

# Visual elements
@onready var shelf_sprite: Sprite2D = $ShelfSprite
@onready var wine_bottles: Array[Sprite2D] = []
@onready var aging_effects: GPUParticles2D = $AgingEffects
@onready var quality_glow: Sprite2D = $QualityGlow

# Audio
@onready var bottle_clink: AudioStreamPlayer = $BottleClink
@onready var shelf_open: AudioStreamPlayer = $ShelfOpen
@onready var shelf_close: AudioStreamPlayer = $ShelfClose

func _ready() -> void:
	super._ready()
	_setup_cellar_shelf()
	_setup_ui()
	_connect_signals()
	_update_storage_display()

func _setup_cellar_shelf() -> void:
	"""Initialize the cellar shelf setup"""
	interaction_prompt = "Press E to access wine storage"
	interaction_range = 60.0
	requires_line_of_sight = false
	
	# Set up visual elements
	if shelf_sprite:
		shelf_sprite.texture = preload("res://assets/sprites/cellar_shelf.png")
	
	if quality_glow:
		quality_glow.visible = false

func _setup_ui() -> void:
	"""Initialize the storage UI elements"""
	if not storage_ui:
		return
	
	# Hide UI initially
	storage_ui.visible = false
	
	# Set up capacity bar
	if capacity_bar:
		capacity_bar.max_value = shelf_capacity
		capacity_bar.value = 0
	
	# Set up page navigation
	if prev_button:
		prev_button.text = "←"
		prev_button.disabled = true
	
	if next_button:
		next_button.text = "→"
		next_button.disabled = true
	
	if page_label:
		page_label.text = "Page 1 of 1"
	
	# Set up wine grid
	_setup_wine_grid()

func _setup_wine_grid() -> void:
	"""Set up the wine display grid"""
	if not wine_grid:
		return
	
	# Create wine slot containers
	for i in range(max_wine_display):
		var wine_slot: Control = _create_wine_slot(i)
		wine_grid.add_child(wine_slot)

func _create_wine_slot(index: int) -> Control:
	"""Create a wine slot container"""
	var slot: PanelContainer = PanelContainer.new()
	slot.custom_minimum_size = Vector2(80, 100)
	
	# Add wine icon
	var icon: TextureRect = TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(60, 60)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot.add_child(icon)
	
	# Add wine name label
	var name_label: Label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = ""
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	slot.add_child(name_label)
	
	# Add quality indicator
	var quality_indicator: ColorRect = ColorRect.new()
	quality_indicator.name = "QualityIndicator"
	quality_indicator.custom_minimum_size = Vector2(20, 4)
	quality_indicator.color = Color.GRAY
	slot.add_child(quality_indicator)
	
	# Connect input
	slot.gui_input.connect(_on_wine_slot_input.bind(index))
	
	return slot

func _connect_signals() -> void:
	"""Connect to necessary signals"""
	if InventorySystem:
		InventorySystem.wine_added.connect(_on_wine_added)
		InventorySystem.wine_removed.connect(_on_wine_removed)
		InventorySystem.inventory_updated.connect(_on_inventory_updated)

func _process(delta: float) -> void:
	"""Update cellar shelf logic"""
	super._process(delta)
	_update_aging_effects(delta)

func _update_aging_effects(delta: float) -> void:
	"""Update visual aging effects for stored wines"""
	if not aging_effects:
		return
	
	# Check if any wines are aging
	var has_aging_wines: bool = false
	for wine in stored_wines:
		if wine.can_age() and wine.current_age_days > 0:
			has_aging_wines = true
			break
	
	aging_effects.emitting = has_aging_wines

# IInteractable implementation
func can_interact(interactor: Node2D) -> bool:
	"""Check if the cellar shelf can be interacted with"""
	return super.can_interact(interactor)

func start_interaction(interactor: Node2D) -> bool:
	"""Start interaction with the cellar shelf"""
	if not super.start_interaction(interactor):
		return false
	
	# Open storage UI
	_open_storage_ui()
	return true

func _open_storage_ui() -> void:
	"""Open the wine storage interface"""
	if storage_ui:
		storage_ui.visible = true
	
	if shelf_open:
		shelf_open.play()
	
	# Update display
	_update_storage_display()
	_update_page_navigation()

func _close_storage_ui() -> void:
	"""Close the wine storage interface"""
	if storage_ui:
		storage_ui.visible = false
	
	if shelf_close:
		shelf_close.play()

func _update_storage_display() -> void:
	"""Update the wine storage display"""
	if not InventorySystem:
		return
	
	# Get stored wines
	stored_wines = InventorySystem.get_wines()
	
	# Calculate total pages
	total_pages = max(1, ceili(float(stored_wines.size()) / float(max_wine_display)))
	current_page = clamp(current_page, 0, total_pages - 1)
	
	# Update displayed wines
	_update_displayed_wines()
	
	# Update storage info
	_update_storage_info()
	
	# Update visual wine bottles
	_update_wine_bottles()

func _update_displayed_wines() -> void:
	"""Update the wines displayed on the current page"""
	var start_index: int = current_page * max_wine_display
	var end_index: int = min(start_index + max_wine_display, stored_wines.size())
	
	displayed_wines.clear()
	for i in range(start_index, end_index):
		displayed_wines.append(stored_wines[i])
	
	# Update wine grid
	_update_wine_grid()

func _update_wine_grid() -> void:
	"""Update the wine grid display"""
	if not wine_grid:
		return
	
	var grid_children: Array = wine_grid.get_children()
	
	for i in range(grid_children.size()):
		var slot: Control = grid_children[i]
		if i < displayed_wines.size():
			_display_wine_in_slot(slot, displayed_wines[i])
		else:
			_clear_wine_slot(slot)

func _display_wine_in_slot(slot: Control, wine: WineRecipe) -> void:
	"""Display a wine in a slot"""
	if not slot:
		return
	
	# Set wine icon
	var icon: TextureRect = slot.get_node_or_null("Icon")
	if icon:
		if wine.icon_path:
			icon.texture = load(wine.icon_path)
		else:
			icon.texture = preload("res://assets/sprites/default_wine_bottle.png")
	
	# Set wine name
	var name_label: Label = slot.get_node_or_null("NameLabel")
	if name_label:
		name_label.text = wine.name
	
	# Set quality indicator
	var quality_indicator: ColorRect = slot.get_node_or_null("QualityIndicator")
	if quality_indicator:
		quality_indicator.color = _get_quality_color(wine.quality_score)

func _clear_wine_slot(slot: Control) -> void:
	"""Clear a wine slot"""
	if not slot:
		return
	
	var icon: TextureRect = slot.get_node_or_null("Icon")
	if icon:
		icon.texture = null
	
	var name_label: Label = slot.get_node_or_null("NameLabel")
	if name_label:
		name_label.text = ""
	
	var quality_indicator: ColorRect = slot.get_node_or_null("QualityIndicator")
	if quality_indicator:
		quality_indicator.color = Color.GRAY

func _get_quality_color(quality_score: float) -> Color:
	"""Get color based on wine quality score"""
	if quality_score >= 90:
		return Color.GOLD
	elif quality_score >= 80:
		return Color.ORANGE
	elif quality_score >= 70:
		return Color.YELLOW
	elif quality_score >= 60:
		return Color.GREEN
	else:
		return Color.RED

func _update_storage_info() -> void:
	"""Update storage information display"""
	if not storage_info:
		return
	
	# Update capacity bar
	if capacity_bar:
		capacity_bar.value = stored_wines.size()
		capacity_bar.max_value = shelf_capacity
	
	# Update total wines label
	if total_wines_label:
		total_wines_label.text = "Wines: " + str(stored_wines.size()) + "/" + str(shelf_capacity)

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

func _update_wine_bottles() -> void:
	"""Update visual wine bottle representations"""
	# This would update the 3D or 2D wine bottle sprites on the shelf
	# For now, we'll just update the quality glow effect
	
	if quality_glow:
		var has_high_quality: bool = false
		for wine in stored_wines:
			if wine.quality_score >= 85:
				has_high_quality = true
				break
		
		quality_glow.visible = has_high_quality

func _on_wine_slot_input(slot_index: int, event: InputEvent) -> void:
	"""Handle input on wine slots"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_wine(slot_index)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_inspect_wine(slot_index)

func _select_wine(slot_index: int) -> void:
	"""Select a wine from a slot"""
	if slot_index >= displayed_wines.size():
		return
	
	var wine: WineRecipe = displayed_wines[slot_index]
	if not wine:
		return
	
	# Show wine details or allow wine selection
	_show_wine_details(wine)

func _inspect_wine(slot_index: int) -> void:
	"""Inspect a wine for detailed information"""
	if slot_index >= displayed_wines.size():
		return
	
	var wine: WineRecipe = displayed_wines[slot_index]
	if not wine:
		return
	
	# Show detailed wine inspection
	_show_wine_inspection(wine)

func _show_wine_details(wine: WineRecipe) -> void:
	"""Show basic wine details"""
	# This would open a wine details popup
	# For now, we'll just print to console
	print("Selected wine: " + wine.name)
	print("Quality: " + str(wine.quality_score))
	print("Rarity: " + str(wine.rarity))

func _show_wine_inspection(wine: WineRecipe) -> void:
	"""Show detailed wine inspection"""
	# This would open a detailed wine inspection window
	print("Inspecting wine: " + wine.name)
	print("Description: " + wine.description)
	print("Notes: " + ", ".join(wine.notes))
	print("Virtues: " + str(wine.virtues))
	print("Aging potential: " + str(wine.aging_potential))
	print("Current age: " + str(wine.current_age_days) + " days")

# Page navigation
func _on_prev_button_pressed() -> void:
	"""Handle previous page button press"""
	if current_page > 0:
		current_page -= 1
		_update_displayed_wines()
		_update_page_navigation()

func _on_next_button_pressed() -> void:
	"""Handle next page button press"""
	if current_page < total_pages - 1:
		current_page += 1
		_update_displayed_wines()
		_update_page_navigation()

# Signal handlers
func _on_wine_added(wine: WineRecipe) -> void:
	"""Handle wine being added to inventory"""
	_update_storage_display()

func _on_wine_removed(wine: WineRecipe) -> void:
	"""Handle wine being removed from inventory"""
	_update_storage_display()

func _on_inventory_updated() -> void:
	"""Handle general inventory updates"""
	_update_storage_display()

# Utility methods
func get_storage_status() -> Dictionary:
	"""Get the current status of the cellar shelf"""
	return {
		"total_wines": stored_wines.size(),
		"capacity": shelf_capacity,
		"current_page": current_page + 1,
		"total_pages": total_pages,
		"displayed_wines": displayed_wines.size()
	}

func get_wine_at_position(position: Vector2) -> WineRecipe:
	"""Get the wine at a specific position on the shelf"""
	# This would be used for 3D positioning
	# For now, return null
	return null

func can_store_wine() -> bool:
	"""Check if the shelf can store more wines"""
	return stored_wines.size() < shelf_capacity

func get_aging_bonus() -> float:
	"""Get the aging bonus multiplier for this shelf"""
	return aging_bonus_multiplier

func get_quality_preservation() -> float:
	"""Get the quality preservation rate for this shelf"""
	return quality_preservation

func get_wines_by_quality(min_quality: float) -> Array[WineRecipe]:
	"""Get wines above a certain quality threshold"""
	var high_quality_wines: Array[WineRecipe] = []
	for wine in stored_wines:
		if wine.quality_score >= min_quality:
			high_quality_wines.append(wine)
	return high_quality_wines

func get_wines_by_rarity(rarity: int) -> Array[WineRecipe]:
	"""Get wines of a specific rarity"""
	var rarity_wines: Array[WineRecipe] = []
	for wine in stored_wines:
		if wine.rarity == rarity:
			rarity_wines.append(wine)
	return rarity_wines
