class_name PatronNeeds
extends IPatronComponent

## PatronNeeds Component - Handles wine preferences and satisfaction
## Manages patron wine preferences, satisfaction levels, and need fulfillment
## Integrates with PatronData Resources for dynamic behavior

## Need states and satisfaction
@export var current_satisfaction: float = 0.5  # 0.0 = very unsatisfied, 1.0 = very satisfied
@export var satisfaction_decay_rate: float = 0.1  # Rate at which satisfaction decreases over time
@export var max_satisfaction: float = 1.0
@export var min_satisfaction: float = 0.0

## Wine preference tracking
var current_wine: WineRecipe = null
var wine_satisfaction: float = 0.0
var preferred_wines: Array[WineRecipe] = []
var rejected_wines: Array[WineRecipe] = []

## Need priorities and weights
var need_priorities: Dictionary = {
	"wine_quality": 0.4,
	"wine_preferences": 0.3,
	"service_quality": 0.2,
	"atmosphere": 0.1
}

## Satisfaction thresholds
var satisfaction_thresholds: Dictionary = {
	"very_satisfied": 0.8,
	"satisfied": 0.6,
	"neutral": 0.4,
	"dissatisfied": 0.2,
	"very_dissatisfied": 0.0
}

## Component initialization
func _on_initialize() -> void:
	component_id = "patron_needs"
	component_name = "PatronNeeds"
	component_type = "needs"
	
	# Initialize satisfaction based on patron data
	var patron_data = get_patron_data()
	if patron_data:
		_initialize_from_patron_data(patron_data)
	
	log_component_message("Initialized with satisfaction: " + str(current_satisfaction))

## Update logic
func _on_update(delta: float) -> void:
	# Decay satisfaction over time
	_decay_satisfaction(delta)
	
	# Update wine satisfaction if we have a current wine
	if current_wine:
		_update_wine_satisfaction(delta)

## Initialize component from PatronData Resource
func _initialize_from_patron_data(patron_data: PatronData) -> void:
	# Set initial satisfaction based on personality
	if patron_data.personality_traits.has("demanding"):
		current_satisfaction = 0.3
	elif patron_data.personality_traits.has("appreciative"):
		current_satisfaction = 0.7
	else:
		current_satisfaction = 0.5
	
	# Adjust satisfaction decay based on patience
	satisfaction_decay_rate *= (1.0 - patron_data.patience_level)
	
	log_component_message("Initialized from patron data: " + patron_data.name)

## Wine satisfaction management
func evaluate_wine(wine: WineRecipe, service_quality: float = 1.0) -> float:
	"""Evaluate how well a wine satisfies the patron's needs"""
	if not is_component_ready():
		return 0.0
	
	var patron_data = get_patron_data()
	if not patron_data:
		return 0.0
	
	var total_satisfaction: float = 0.0
	var total_weight: float = 0.0
	
	# Evaluate wine quality satisfaction
	var quality_satisfaction = _evaluate_wine_quality(wine, patron_data)
	total_satisfaction += quality_satisfaction * need_priorities["wine_quality"]
	total_weight += need_priorities["wine_quality"]
	
	# Evaluate preference satisfaction
	var preference_satisfaction = _evaluate_wine_preferences(wine, patron_data)
	total_satisfaction += preference_satisfaction * need_priorities["wine_preferences"]
	total_weight += need_priorities["wine_preferences"]
	
	# Evaluate service quality
	var service_satisfaction = service_quality
	total_satisfaction += service_satisfaction * need_priorities["service_quality"]
	total_weight += need_priorities["service_quality"]
	
	# Normalize satisfaction
	if total_weight > 0:
		wine_satisfaction = total_satisfaction / total_weight
	else:
		wine_satisfaction = 0.0
	
	return wine_satisfaction

func serve_wine(wine: WineRecipe, service_quality: float = 1.0) -> float:
	"""Serve a wine to the patron and update satisfaction"""
	var satisfaction = evaluate_wine(wine, service_quality)
	
	current_wine = wine
	wine_satisfaction = satisfaction
	
	# Update overall satisfaction
	_update_satisfaction_from_wine(satisfaction)
	
	# Track wine preferences
	if satisfaction > 0.7:
		if not preferred_wines.has(wine):
			preferred_wines.append(wine)
	elif satisfaction < 0.3:
		if not rejected_wines.has(wine):
			rejected_wines.append(wine)
	
	log_component_message("Served wine: " + wine.name + " (satisfaction: " + str(satisfaction) + ")")
	
	# Emit signal for other components
	emit_signal("component_data_changed", self, {"wine_served": wine.id, "satisfaction": satisfaction})
	
	return satisfaction

func remove_wine() -> void:
	"""Remove the current wine from the patron"""
	if current_wine:
		log_component_message("Removed wine: " + current_wine.name)
		current_wine = null
		wine_satisfaction = 0.0

## Satisfaction evaluation methods
func _evaluate_wine_quality(wine: WineRecipe, patron_data: PatronData) -> float:
	"""Evaluate wine quality satisfaction"""
	var quality_score = wine.calculate_quality_score()
	var max_quality = 20.0  # Maximum possible quality score
	
	# Normalize quality score
	var normalized_quality = quality_score / max_quality
	
	# Check if wine meets minimum rarity requirement
	var rarity_order = ["House", "Select", "Reserve", "GrandReserve", "Mythic"]
	var wine_rarity_index = rarity_order.find(wine.rarity)
	var preferred_rarity_index = rarity_order.find(patron_data.preferred_rarity)
	
	if wine_rarity_index < preferred_rarity_index:
		return 0.0  # Wine doesn't meet minimum requirements
	
	return normalized_quality

func _evaluate_wine_preferences(wine: WineRecipe, patron_data: PatronData) -> float:
	"""Evaluate how well the wine matches patron preferences"""
	var preference_score: float = 0.0
	var max_score: float = 0.0
	
	# Check notes preferences
	if not patron_data.preferred_notes.is_empty():
		var note_matches = 0
		for note in patron_data.preferred_notes:
			if wine.has_note(note):
				note_matches += 1
		preference_score += float(note_matches) / patron_data.preferred_notes.size()
		max_score += 1.0
	
	# Check virtues preferences
	if not patron_data.preferred_virtues.is_empty():
		var virtue_matches = 0
		for virtue in patron_data.preferred_virtues:
			if wine.has_virtue(virtue):
				virtue_matches += 1
		preference_score += float(virtue_matches) / patron_data.preferred_virtues.size()
		max_score += 1.0
	
	# Check specific wine preferences
	if patron_data.wine_preferences.has(wine.id):
		var preference = patron_data.wine_preferences[wine.id]
		if preference == "love":
			preference_score += 2.0
		elif preference == "hate":
			preference_score = 0.0
	
	if max_score > 0:
		return preference_score / max_score
	else:
		return 0.5  # Neutral if no preferences specified

func _update_satisfaction_from_wine(wine_satisfaction: float) -> void:
	"""Update overall satisfaction based on wine satisfaction"""
	var old_satisfaction = current_satisfaction
	
	# Blend wine satisfaction with current satisfaction
	var blend_factor = 0.7  # How much wine satisfaction affects overall
	current_satisfaction = (current_satisfaction * (1.0 - blend_factor)) + (wine_satisfaction * blend_factor)
	
	# Clamp satisfaction to valid range
	current_satisfaction = clamp(current_satisfaction, min_satisfaction, max_satisfaction)
	
	# Log significant changes
	if abs(current_satisfaction - old_satisfaction) > 0.1:
		log_component_message("Satisfaction changed: " + str(old_satisfaction) + " -> " + str(current_satisfaction))

## Satisfaction decay
func _decay_satisfaction(delta: float) -> void:
	"""Gradually decrease satisfaction over time"""
	var decay_amount = satisfaction_decay_rate * delta
	current_satisfaction = max(current_satisfaction - decay_amount, min_satisfaction)

## Utility methods
func get_satisfaction_level() -> String:
	"""Get a human-readable satisfaction level"""
	for level in satisfaction_thresholds.keys():
		if current_satisfaction >= satisfaction_thresholds[level]:
			return level
	return "very_dissatisfied"

func is_satisfied() -> bool:
	"""Check if the patron is generally satisfied"""
	return current_satisfaction >= satisfaction_thresholds["satisfied"]

func get_wine_recommendation() -> Array[String]:
	"""Get wine recommendations based on preferences"""
	var recommendations: Array[String] = []
	var patron_data = get_patron_data()
	
	if not patron_data:
		return recommendations
	
	# Recommend based on preferred notes
	for note in patron_data.preferred_notes:
		recommendations.append("wine_with_note_" + note.to_lower())
	
	# Recommend based on preferred virtues
	for virtue in patron_data.preferred_virtues:
		recommendations.append("wine_with_virtue_" + virtue.to_lower())
	
	# Recommend based on preferred rarity
	recommendations.append("wine_rarity_" + patron_data.preferred_rarity.to_lower())
	
	return recommendations

func get_tip_multiplier() -> float:
	"""Get tip multiplier based on satisfaction"""
	if current_satisfaction >= 0.8:
		return 1.5  # Very satisfied
	elif current_satisfaction >= 0.6:
		return 1.2  # Satisfied
	elif current_satisfaction >= 0.4:
		return 1.0  # Neutral
	elif current_satisfaction >= 0.2:
		return 0.8  # Dissatisfied
	else:
		return 0.5  # Very dissatisfied

## Component reset
func _on_reset() -> void:
	current_satisfaction = 0.5
	wine_satisfaction = 0.0
	current_wine = null
	preferred_wines.clear()
	rejected_wines.clear()

## Save/Load support
func get_save_data() -> Dictionary:
	var base_data = super.get_save_data()
	base_data.merge({
		"current_satisfaction": current_satisfaction,
		"wine_satisfaction": wine_satisfaction,
		"current_wine_id": current_wine.id if current_wine else "",
		"preferred_wine_ids": _get_wine_id_array(preferred_wines),
		"rejected_wine_ids": _get_wine_id_array(rejected_wines)
	})
	return base_data

func load_save_data(data: Dictionary) -> void:
	super.load_save_data(data)
	current_satisfaction = data.get("current_satisfaction", 0.5)
	wine_satisfaction = data.get("wine_satisfaction", 0.0)
	# Note: Wine references would need to be restored from IDs in a full implementation

func _get_wine_id_array(wines: Array[WineRecipe]) -> Array[String]:
	var ids: Array[String] = []
	for wine in wines:
		ids.append(wine.id)
	return ids
