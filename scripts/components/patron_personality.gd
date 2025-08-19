class_name PatronPersonality
extends IPatronComponent

## PatronPersonality Component - Dialogue and behavior patterns
## Manages patron dialogue, personality traits, and behavioral responses
## Integrates with PatronData Resources for dynamic personality expression

## Personality state and mood
@export var current_mood: String = "neutral"  # happy, satisfied, neutral, dissatisfied, angry
@export var mood_intensity: float = 0.5  # 0.0 = subtle, 1.0 = intense
@export var mood_stability: float = 0.7  # 0.0 = very volatile, 1.0 = very stable

## Dialogue and communication
var current_dialogue_state: String = "idle"
var dialogue_cooldown: float = 0.0
var last_dialogue_time: float = 0.0
var dialogue_history: Array[Dictionary] = []

## Personality expression
var personality_expression_timer: float = 0.0
var expression_interval: float = 5.0  # How often to express personality
var current_expression: String = ""

## Behavioral patterns
var behavior_patterns: Dictionary = {}
var current_behavior: String = "default"
var behavior_weights: Dictionary = {}

## Component initialization
func _on_initialize() -> void:
	component_id = "patron_personality"
	component_name = "PatronPersonality"
	component_type = "personality"
	
	# Initialize personality from patron data
	var patron_data = get_patron_data()
	if patron_data:
		_initialize_from_patron_data(patron_data)
	
	log_component_message("Initialized with mood: " + current_mood)

## Update logic
func _on_update(delta: float) -> void:
	# Update dialogue cooldown
	if dialogue_cooldown > 0:
		dialogue_cooldown -= delta
	
	# Update personality expression timer
	personality_expression_timer += delta
	if personality_expression_timer >= expression_interval:
		personality_expression_timer = 0.0
		_express_personality()
	
	# Update mood based on external factors
	_update_mood(delta)

## Initialize component from PatronData Resource
func _initialize_from_patron_data(patron_data: PatronData) -> void:
	# Set mood stability based on personality traits
	if patron_data.personality_traits.has("volatile"):
		mood_stability = 0.2
	elif patron_data.personality_traits.has("stable"):
		mood_stability = 0.9
	else:
		mood_stability = 0.7
	
	# Set expression interval based on personality
	if patron_data.personality_traits.has("talkative"):
		expression_interval = 2.0
	elif patron_data.personality_traits.has("quiet"):
		expression_interval = 10.0
	else:
		expression_interval = 5.0
	
	# Initialize behavior patterns
	_initialize_behavior_patterns(patron_data)
	
	log_component_message("Initialized personality from patron data: " + patron_data.name)

## Dialogue management
func get_dialogue_response(context: String, satisfaction: float = 0.5) -> String:
	"""Get an appropriate dialogue response based on context and satisfaction"""
	if dialogue_cooldown > 0:
		return ""
	
	var patron_data = get_patron_data()
	if not patron_data:
		return ""
	
	var response: String = ""
	
	match context:
		"wine_served":
			response = _get_wine_response(satisfaction, patron_data)
		"wine_rejected":
			response = _get_rejection_response(patron_data)
		"greeting":
			response = _get_greeting_response(patron_data)
		"farewell":
			response = _get_farewell_response(patron_data)
		"complaint":
			response = _get_complaint_response(patron_data)
		"praise":
			response = _get_praise_response(patron_data)
		"idle":
			response = _get_idle_response(patron_data)
		_:
			response = _get_default_response(patron_data)
	
	# Set dialogue cooldown
	dialogue_cooldown = 3.0  # 3 second cooldown between dialogue
	
	# Log dialogue
	_log_dialogue(context, response, satisfaction)
	
	return response

func can_speak() -> bool:
	"""Check if the patron can speak (not on cooldown)"""
	return dialogue_cooldown <= 0

## Mood management
func update_mood(satisfaction: float, context: String = "") -> void:
	"""Update the patron's mood based on satisfaction and context"""
	var old_mood = current_mood
	
	# Determine new mood based on satisfaction
	var new_mood: String
	if satisfaction >= 0.8:
		new_mood = "happy"
	elif satisfaction >= 0.6:
		new_mood = "satisfied"
	elif satisfaction >= 0.4:
		new_mood = "neutral"
	elif satisfaction >= 0.2:
		new_mood = "dissatisfied"
	else:
		new_mood = "angry"
	
	# Apply mood stability
	if mood_stability > 0.5:
		# Stable personality - gradual mood changes
		if new_mood != current_mood:
			mood_intensity = 0.3  # Subtle mood change
	else:
		# Volatile personality - immediate mood changes
		current_mood = new_mood
		mood_intensity = 1.0  # Intense mood change
	
	# Log significant mood changes
	if old_mood != current_mood:
		log_component_message("Mood changed: " + old_mood + " -> " + current_mood)
	
	# Emit signal for other components
	emit_signal("component_data_changed", self, {"mood": current_mood, "intensity": mood_intensity})

## Personality expression
func _express_personality() -> void:
	"""Express personality traits through random behaviors or dialogue"""
	var patron_data = get_patron_data()
	if not patron_data:
		return
	
	# Choose a personality expression based on traits
	var expression_chance = randf()
	var trait_index = 0
	
	for trait in patron_data.personality_traits:
		var trait_weight = 1.0 / patron_data.personality_traits.size()
		if expression_chance <= trait_weight + (trait_index * trait_weight):
			_express_trait(trait, patron_data)
			break
		trait_index += 1

func _express_trait(trait: String, patron_data: PatronData) -> void:
	"""Express a specific personality trait"""
	match trait:
		"elegant":
			current_expression = "adjusts_collar"
		"demanding":
			current_expression = "taps_fingers"
		"appreciative":
			current_expression = "nods_approvingly"
		"mysterious":
			current_expression = "glances_around"
		"aristocratic":
			current_expression = "straightens_posture"
		_:
			current_expression = "idle_gesture"
	
	log_component_message("Expressing trait: " + trait + " -> " + current_expression)

## Behavior pattern management
func _initialize_behavior_patterns(patron_data: PatronData) -> void:
	"""Initialize behavior patterns based on patron data"""
	behavior_patterns = {
		"default": {
			"movement_speed": 1.0,
			"interaction_range": 50.0,
			"patience": patron_data.patience_level
		},
		"elegant": {
			"movement_speed": 0.8,
			"interaction_range": 60.0,
			"patience": 0.8
		},
		"impatient": {
			"movement_speed": 1.3,
			"interaction_range": 40.0,
			"patience": 0.2
		},
		"mysterious": {
			"movement_speed": 0.9,
			"interaction_range": 70.0,
			"patience": 0.6
		}
	}
	
	# Set behavior weights based on personality traits
	for trait in patron_data.personality_traits:
		match trait:
			"elegant":
				behavior_weights["elegant"] = 0.7
			"impatient":
				behavior_weights["impatient"] = 0.6
			"mysterious":
				behavior_weights["mysterious"] = 0.5
			_:
				behavior_weights["default"] = 0.3

func get_behavior_pattern(pattern_name: String) -> Dictionary:
	"""Get a specific behavior pattern"""
	return behavior_patterns.get(pattern_name, behavior_patterns["default"])

func get_current_behavior() -> Dictionary:
	"""Get the current behavior pattern"""
	return get_behavior_pattern(current_behavior)

## Dialogue response methods
func _get_wine_response(satisfaction: float, patron_data: PatronData) -> String:
	"""Get response when wine is served"""
	if satisfaction >= 0.8:
		return patron_data.get_random_praise()
	elif satisfaction >= 0.6:
		return "Acceptable."
	elif satisfaction >= 0.4:
		return "Hmm..."
	else:
		return patron_data.get_random_complaint()

func _get_rejection_response(patron_data: PatronData) -> String:
	"""Get response when wine is rejected"""
	return patron_data.get_random_complaint()

func _get_greeting_response(patron_data: PatronData) -> String:
	"""Get greeting response"""
	return patron_data.get_random_one_liner()

func _get_farewell_response(patron_data: PatronData) -> String:
	"""Get farewell response"""
	if current_mood == "happy" or current_mood == "satisfied":
		return "Until next time."
	else:
		return "Good evening."

func _get_complaint_response(patron_data: PatronData) -> String:
	"""Get complaint response"""
	return patron_data.get_random_complaint()

func _get_praise_response(patron_data: PatronData) -> String:
	"""Get praise response"""
	return patron_data.get_random_praise()

func _get_idle_response(patron_data: PatronData) -> String:
	"""Get idle response"""
	var responses = patron_data.one_liners
	if responses.size() > 0:
		return responses[randi() % responses.size()]
	return ""

func _get_default_response(patron_data: PatronData) -> String:
	"""Get default response for unknown contexts"""
	return patron_data.get_random_one_liner()

## Utility methods
func get_mood_description() -> String:
	"""Get a human-readable mood description"""
	var descriptions = {
		"happy": "cheerful and pleased",
		"satisfied": "content and satisfied",
		"neutral": "neutral and composed",
		"dissatisfied": "slightly displeased",
		"angry": "visibly upset"
	}
	return descriptions.get(current_mood, "neutral")

func is_in_good_mood() -> bool:
	"""Check if the patron is in a good mood"""
	return current_mood == "happy" or current_mood == "satisfied"

func get_personality_summary() -> String:
	"""Get a summary of the patron's personality"""
	var patron_data = get_patron_data()
	if not patron_data:
		return "Unknown personality"
	
	var summary = patron_data.archetype + " with "
	summary += ", ".join(patron_data.personality_traits.slice(0, 3))
	summary += " traits. Currently " + get_mood_description() + "."
	
	return summary

## Dialogue logging
func _log_dialogue(context: String, response: String, satisfaction: float) -> void:
	"""Log dialogue for debugging and analysis"""
	var dialogue_entry = {
		"time": Time.get_time_dict_from_system(),
		"context": context,
		"response": response,
		"satisfaction": satisfaction,
		"mood": current_mood
	}
	
	dialogue_history.append(dialogue_entry)
	
	# Keep only last 20 dialogue entries
	if dialogue_history.size() > 20:
		dialogue_history.pop_front()

## Component reset
func _on_reset() -> void:
	current_mood = "neutral"
	mood_intensity = 0.5
	current_dialogue_state = "idle"
	dialogue_cooldown = 0.0
	personality_expression_timer = 0.0
	current_expression = ""
	dialogue_history.clear()
	behavior_patterns.clear()
	behavior_weights.clear()

## Save/Load support
func get_save_data() -> Dictionary:
	var base_data = super.get_save_data()
	base_data.merge({
		"current_mood": current_mood,
		"mood_intensity": mood_intensity,
		"mood_stability": mood_stability,
		"current_dialogue_state": current_dialogue_state,
		"dialogue_history": dialogue_history,
		"behavior_patterns": behavior_patterns,
		"behavior_weights": behavior_weights
	})
	return base_data

func load_save_data(data: Dictionary) -> void:
	super.load_save_data(data)
	current_mood = data.get("current_mood", "neutral")
	mood_intensity = data.get("mood_intensity", 0.5)
	mood_stability = data.get("mood_stability", 0.7)
	current_dialogue_state = data.get("current_dialogue_state", "idle")
	dialogue_history = data.get("dialogue_history", [])
	behavior_patterns = data.get("behavior_patterns", {})
	behavior_weights = data.get("behavior_weights", {})
