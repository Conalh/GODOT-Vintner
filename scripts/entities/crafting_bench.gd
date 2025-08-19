class_name CraftingBench
extends IInteractable

## Wine creation station that integrates with CraftingSystem and uses BloodSource/WineRecipe Resources
## Provides the core crafting interface for creating wines from blood sources

# Crafting properties
@export var crafting_speed_multiplier: float = 1.0
@export var quality_bonus: float = 0.0
@export var max_ingredients: int = 5
@export var crafting_time_base: float = 10.0

# Crafting state
var is_crafting: bool = false
var current_recipe: WineRecipe = null
var crafting_progress: float = 0.0
var crafting_timer: float = 0.0
var selected_ingredients: Array[BloodSource] = []
var crafting_result: WineRecipe = null

# UI references
@onready var crafting_ui: Control = $CraftingUI
@onready var progress_bar: ProgressBar = $CraftingUI/ProgressBar
@onready var ingredient_slots: Array[Control] = []
@onready var result_display: Control = $CraftingUI/ResultDisplay
@onready var craft_button: Button = $CraftingUI/CraftButton
@onready var cancel_button: Button = $CraftingUI/CancelButton

# Visual feedback
@onready var bench_sprite: Sprite2D = $BenchSprite
@onready var crafting_particles: GPUParticles2D = $CraftingParticles
@onready var success_effect: AnimationPlayer = $SuccessEffect
@onready var failure_effect: AnimationPlayer = $FailureEffect

# Audio
@onready var crafting_sound: AudioStreamPlayer = $CraftingSound
@onready var success_sound: AudioStreamPlayer = $SuccessSound
@onready var failure_sound: AudioStreamPlayer = $FailureSound

func _ready() -> void:
	super._ready()
	_setup_crafting_bench()
	_setup_ui()
	_connect_signals()

func _setup_crafting_bench() -> void:
	"""Initialize the crafting bench setup"""
	interaction_prompt = "Press E to access crafting bench"
	interaction_range = 80.0
	requires_line_of_sight = false
	
	# Set up visual elements
	if bench_sprite:
		bench_sprite.texture = preload("res://assets/sprites/crafting_bench.png")
	
	if crafting_particles:
		crafting_particles.emitting = false

func _setup_ui() -> void:
	"""Initialize the crafting UI elements"""
	if not crafting_ui:
		return
	
	# Hide UI initially
	crafting_ui.visible = false
	
	# Set up progress bar
	if progress_bar:
		progress_bar.max_value = 100.0
		progress_bar.value = 0.0
	
	# Set up ingredient slots
	_setup_ingredient_slots()
	
	# Set up buttons
	if craft_button:
		craft_button.text = "Craft Wine"
		craft_button.disabled = true
	
	if cancel_button:
		cancel_button.text = "Cancel"

func _setup_ingredient_slots() -> void:
	"""Set up the ingredient slot containers"""
	var slots_container: Control = crafting_ui.get_node_or_null("IngredientSlots")
	if not slots_container:
		return
	
	for i in range(max_ingredients):
		var slot: Control = slots_container.get_node_or_null("Slot" + str(i + 1))
		if slot:
			ingredient_slots.append(slot)
			slot.gui_input.connect(_on_ingredient_slot_input.bind(i))

func _connect_signals() -> void:
	"""Connect to necessary signals"""
	if CraftingSystem:
		CraftingSystem.crafting_started.connect(_on_crafting_started)
		CraftingSystem.crafting_completed.connect(_on_crafting_completed)
		CraftingSystem.crafting_failed.connect(_on_crafting_failed)

func _process(delta: float) -> void:
	"""Update crafting bench logic"""
	super._process(delta)
	_update_crafting(delta)

func _update_crafting(delta: float) -> void:
	"""Update crafting progress and timing"""
	if not is_crafting or not current_recipe:
		return
	
	crafting_timer += delta * crafting_speed_multiplier
	crafting_progress = (crafting_timer / crafting_time_base) * 100.0
	
	# Update progress bar
	if progress_bar:
		progress_bar.value = crafting_progress
	
	# Check if crafting is complete
	if crafting_progress >= 100.0:
		_complete_crafting()

# IInteractable implementation
func can_interact(interactor: Node2D) -> bool:
	"""Check if the crafting bench can be interacted with"""
	return super.can_interact(interactor) and not is_crafting

func start_interaction(interactor: Node2D) -> bool:
	"""Start interaction with the crafting bench"""
	if not super.start_interaction(interactor):
		return false
	
	# Open crafting UI
	_open_crafting_ui()
	return true

func _open_crafting_ui() -> void:
	"""Open the crafting interface"""
	if crafting_ui:
		crafting_ui.visible = true
	
	# Update ingredient slots with available blood sources
	_update_ingredient_slots()
	
	# Update craft button state
	_update_craft_button_state()

func _close_crafting_ui() -> void:
	"""Close the crafting interface"""
	if crafting_ui:
		crafting_ui.visible = false
	
	# Clear current selection
	selected_ingredients.clear()
	current_recipe = null

func _update_ingredient_slots() -> void:
	"""Update ingredient slots with available blood sources"""
	if not InventorySystem:
		return
	
	var available_sources: Array[BloodSource] = InventorySystem.get_blood_sources()
	
	for i in range(ingredient_slots.size()):
		var slot: Control = ingredient_slots[i]
		if i < available_sources.size():
			var source: BloodSource = available_sources[i]
			_display_blood_source_in_slot(slot, source)
		else:
			_clear_ingredient_slot(slot)

func _display_blood_source_in_slot(slot: Control, source: BloodSource) -> void:
	"""Display a blood source in an ingredient slot"""
	if not slot:
		return
	
	# Set slot icon
	var icon: TextureRect = slot.get_node_or_null("Icon")
	if icon and source.icon_path:
		icon.texture = load(source.icon_path)
	
	# Set slot label
	var label: Label = slot.get_node_or_null("Label")
	if label:
		label.text = source.source_name
	
	# Set slot tooltip
	var tooltip: String = _generate_blood_source_tooltip(source)
	slot.tooltip_text = tooltip

func _clear_ingredient_slot(slot: Control) -> void:
	"""Clear an ingredient slot"""
	if not slot:
		return
	
	var icon: TextureRect = slot.get_node_or_null("Icon")
	if icon:
		icon.texture = null
	
	var label: Label = slot.get_node_or_null("Label")
	if label:
		label.text = ""

func _generate_blood_source_tooltip(source: BloodSource) -> String:
	"""Generate a tooltip for a blood source"""
	var tooltip: String = source.source_name + "\n"
	tooltip += "Rarity: " + str(source.rarity_hint) + "\n"
	tooltip += "Type: " + str(source.source_type) + "\n"
	
	if source.notes.size() > 0:
		tooltip += "Notes: " + ", ".join(source.notes) + "\n"
	
	if source.virtues.size() > 0:
		tooltip += "Virtues: "
		for virtue in source.virtues:
			tooltip += str(virtue) + "(" + str(source.virtues[virtue]) + ") "
	
	return tooltip

func _on_ingredient_slot_input(slot_index: int, event: InputEvent) -> void:
	"""Handle input on ingredient slots"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_ingredient(slot_index)

func _select_ingredient(slot_index: int) -> void:
	"""Select an ingredient from a slot"""
	if slot_index >= ingredient_slots.size():
		return
	
	var slot: Control = ingredient_slots[slot_index]
	if not slot:
		return
	
	# Check if slot has a blood source
	if InventorySystem:
		var available_sources: Array[BloodSource] = InventorySystem.get_blood_sources()
		if slot_index < available_sources.size():
			var source: BloodSource = available_sources[slot_index]
			_toggle_ingredient_selection(source, slot)
	
	# Update craft button state
	_update_craft_button_state()

func _toggle_ingredient_selection(source: BloodSource, slot: Control) -> void:
	"""Toggle selection of an ingredient"""
	if selected_ingredients.has(source):
		selected_ingredients.erase(source)
		_set_slot_selected(slot, false)
	else:
		if selected_ingredients.size() < max_ingredients:
			selected_ingredients.append(source)
			_set_slot_selected(slot, true)

func _set_slot_selected(slot: Control, selected: bool) -> void:
	"""Set the visual selection state of a slot"""
	if not slot:
		return
	
	# Change slot appearance based on selection
	var panel: Panel = slot.get_node_or_null("Panel")
	if panel:
		if selected:
			panel.modulate = Color.YELLOW
		else:
			panel.modulate = Color.WHITE

func _update_craft_button_state() -> void:
	"""Update the craft button enabled state"""
	if not craft_button:
		return
	
	# Enable if we have ingredients and a valid recipe
	var can_craft: bool = selected_ingredients.size() > 0 and _can_create_recipe()
	craft_button.disabled = not can_craft

func _can_create_recipe() -> bool:
	"""Check if we can create a wine recipe with selected ingredients"""
	return selected_ingredients.size() > 0

func _on_craft_button_pressed() -> void:
	"""Handle craft button press"""
	if not _can_create_recipe():
		return
	
	_start_crafting()

func _on_cancel_button_pressed() -> void:
	"""Handle cancel button press"""
	_close_crafting_ui()
	cancel_interaction()

func _start_crafting() -> void:
	"""Begin the crafting process"""
	if not CraftingSystem:
		return
	
	# Create recipe from selected ingredients
	current_recipe = _create_recipe_from_ingredients()
	if not current_recipe:
		return
	
	# Start crafting in the system
	var success: bool = CraftingSystem.start_crafting(current_recipe)
	if not success:
		return
	
	# Update local state
	is_crafting = true
	crafting_progress = 0.0
	crafting_timer = 0.0
	
	# Show crafting UI
	_show_crafting_progress()
	
	# Start visual effects
	if crafting_particles:
		crafting_particles.emitting = true
	
	if crafting_sound:
		crafting_sound.play()
	
	# Emit interaction signal
	interaction_started.emit(self, get_current_interactor())

func _create_recipe_from_ingredients() -> WineRecipe:
	"""Create a wine recipe from selected ingredients"""
	if selected_ingredients.size() == 0:
		return null
	
	var recipe: WineRecipe = WineRecipe.new()
	recipe.id = _generate_recipe_id()
	recipe.name = _generate_recipe_name()
	recipe.description = _generate_recipe_description()
	
	# Calculate recipe properties from ingredients
	_calculate_recipe_properties(recipe)
	
	return recipe

func _generate_recipe_id() -> String:
	"""Generate a unique recipe ID"""
	return "recipe_" + str(Time.get_time_dict_from_system().get("unix", 0.0))

func _generate_recipe_name() -> String:
	"""Generate a recipe name based on ingredients"""
	var names: Array[String] = []
	for source in selected_ingredients:
		names.append(source.source_name)
	
	return "Blend of " + ", ".join(names)

func _generate_recipe_description() -> String:
	"""Generate a recipe description based on ingredients"""
	return "A carefully crafted blend of blood sources with unique characteristics."

func _calculate_recipe_properties(recipe: WineRecipe) -> void:
	"""Calculate recipe properties from selected ingredients"""
	# Combine notes from all ingredients
	var combined_notes: Array[String] = []
	var combined_virtues: Dictionary = {}
	
	for source in selected_ingredients:
		# Add notes
		for note in source.notes:
			if not combined_notes.has(note):
				combined_notes.append(note)
		
		# Combine virtues
		for virtue in source.virtues:
			if combined_virtues.has(virtue):
				combined_virtues[virtue] += source.virtues[virtue]
			else:
				combined_virtues[virtue] = source.virtues[virtue]
	
	recipe.notes = combined_notes
	recipe.virtues = combined_virtues
	
	# Calculate quality and rarity
	recipe.calculate_quality_score()
	recipe.determine_rarity()
	
	# Set other properties
	recipe.crafting_date = Time.get_date_dict_from_system()
	recipe.aging_potential = _calculate_aging_potential()
	recipe.complexity_rating = selected_ingredients.size()

func _calculate_aging_potential() -> int:
	"""Calculate the aging potential based on ingredients"""
	var total_potential: int = 0
	for source in selected_ingredients:
		total_potential += source.rarity_hint
	
	return total_potential / selected_ingredients.size()

func _show_crafting_progress() -> void:
	"""Show the crafting progress UI"""
	if progress_bar:
		progress_bar.visible = true
	
	if craft_button:
		craft_button.visible = false
	
	if cancel_button:
		cancel_button.visible = true

func _complete_crafting() -> void:
	"""Complete the crafting process"""
	is_crafting = false
	
	# Stop visual effects
	if crafting_particles:
		crafting_particles.emitting = false
	
	if crafting_sound:
		crafting_sound.stop()
	
	# Create the final recipe
	crafting_result = current_recipe
	if crafting_result:
		# Add to inventory
		if InventorySystem:
			InventorySystem.add_wine(crafting_result)
		
		# Show success effect
		_show_success_effect()
		
		# Play success sound
		if success_sound:
			success_sound.play()
	
	# Update UI
	_show_crafting_result()
	
	# Emit completion signal
	interaction_completed.emit(self, get_current_interactor())

func _show_success_effect() -> void:
	"""Show the crafting success effect"""
	if success_effect:
		success_effect.play("success")
	
	# Add some sparkle particles or other visual feedback
	if crafting_particles:
		crafting_particles.emitting = true
		var timer: Timer = Timer.new()
		timer.wait_time = 2.0
		timer.one_shot = true
		timer.timeout.connect(func(): crafting_particles.emitting = false)
		add_child(timer)
		timer.start()

func _show_crafting_result() -> void:
	"""Show the crafting result display"""
	if result_display:
		result_display.visible = true
	
	# Display recipe information
	_display_recipe_result()

func _display_recipe_result() -> void:
	"""Display the crafted recipe result"""
	if not crafting_result or not result_display:
		return
	
	# Set result name
	var name_label: Label = result_display.get_node_or_null("NameLabel")
	if name_label:
		name_label.text = crafting_result.name
	
	# Set result description
	var desc_label: Label = result_display.get_node_or_null("DescriptionLabel")
	if desc_label:
		desc_label.text = crafting_result.description
	
	# Set quality indicator
	var quality_label: Label = result_display.get_node_or_null("QualityLabel")
	if quality_label:
		quality_label.text = "Quality: " + str(crafting_result.quality_score)

# Signal handlers
func _on_crafting_started(recipe: WineRecipe) -> void:
	"""Handle crafting started signal from CraftingSystem"""
	# This is handled locally now
	pass

func _on_crafting_completed(recipe: WineRecipe) -> void:
	"""Handle crafting completed signal from CraftingSystem"""
	# This is handled locally now
	pass

func _on_crafting_failed(recipe: WineRecipe, reason: String) -> void:
	"""Handle crafting failed signal from CraftingSystem"""
	# Show failure effect
	if failure_effect:
		failure_effect.play("failure")
	
	if failure_sound:
		failure_sound.play()
	
	# Reset crafting state
	is_crafting = false
	current_recipe = null
	crafting_progress = 0.0
	
	# Hide progress UI
	if progress_bar:
		progress_bar.visible = false
	
	# Show craft button again
	if craft_button:
		craft_button.visible = true

# Utility methods
func get_crafting_status() -> Dictionary:
	"""Get the current status of the crafting bench"""
	return {
		"is_crafting": is_crafting,
		"progress": crafting_progress,
		"selected_ingredients": selected_ingredients.size(),
		"current_recipe": current_recipe.name if current_recipe else "None"
	}

func get_available_ingredients() -> Array[BloodSource]:
	"""Get the currently available blood source ingredients"""
	if not InventorySystem:
		return []
	
	return InventorySystem.get_blood_sources()

func can_craft_wine() -> bool:
	"""Check if wine can be crafted with current ingredients"""
	return _can_create_recipe() and not is_crafting

func get_crafting_time_estimate() -> float:
	"""Get estimated crafting time for current ingredients"""
	return crafting_time_base / crafting_speed_multiplier
