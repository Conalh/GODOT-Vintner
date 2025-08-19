extends Node

## Patron AI and behavior management system for Hemovintner
## Handles patron spawning, behavior, needs, and satisfaction

signal patron_spawned(patron_data: Dictionary)
signal patron_left(patron_id: String, reason: String)
signal patron_satisfied(patron_id: String, satisfaction: float)
signal patron_dissatisfied(patron_id: String, reason: String)
signal patron_order_taken(patron_id: String, order: Dictionary)

## Patron management
var active_patrons: Dictionary = {}
var patron_spawn_timer: Timer
var max_patrons: int = GameConstants.MAX_PATRONS_PER_SCENE

## Patron templates and behavior
var patron_templates: Dictionary = {}
var personality_weights: Dictionary = {}
var need_priorities: Dictionary = {}

## Spawning and timing
var spawn_interval: float = GameConstants.PATRON_SPAWN_INTERVAL
var last_spawn_time: float = 0.0
var day_cycle_progress: float = 0.0

## Satisfaction tracking
var total_patrons_served: int = 0
var average_satisfaction: float = 0.0
var satisfaction_history: Array[float] = []

func _ready() -> void:
	_initialize_patron_system()
	_load_patron_templates()
	_setup_spawn_timer()
	_connect_signals()

## Core patron management methods

func spawn_patron() -> Dictionary:
	"""Spawn a new patron with randomized personality and needs"""
	if active_patrons.size() >= max_patrons:
		push_warning("Maximum patrons reached, cannot spawn new patron")
		return {}
	
	var patron_id: String = _generate_patron_id()
	var personality: GameEnums.PatronPersonality = _select_random_personality()
	var needs: Array[GameEnums.PatronNeed] = _generate_patron_needs(personality)
	
	var patron_data: Dictionary = {
		"id": patron_id,
		"personality": personality,
		"needs": needs,
		"spawn_time": Time.get_time_dict_from_system().get("unix", 0.0),
		"patience_time": GameConstants.PATRON_PATIENCE_TIME,
		"satisfaction": 1.0,
		"current_need": needs[0] if needs.size() > 0 else GameEnums.PatronNeed.BLOOD_WINE,
		"order_taken": false,
		"order_fulfilled": false,
		"tip_amount": 0,
		"status": "waiting"
	}
	
	active_patrons[patron_id] = patron_data
	patron_spawned.emit(patron_data)
	
	return patron_data

func remove_patron(patron_id: String, reason: String = "left") -> bool:
	"""Remove a patron from the scene"""
	if not patron_id in active_patrons:
		return false
	
	var patron_data: Dictionary = active_patrons[patron_id]
	active_patrons.erase(patron_id)
	
	patron_left.emit(patron_id, reason)
	
	# Update satisfaction tracking
	_update_satisfaction_tracking(patron_data.satisfaction)
	
	return true

func take_patron_order(patron_id: String) -> Dictionary:
	"""Take an order from a specific patron"""
	if not patron_id in active_patrons:
		push_error("Patron not found: %s" % patron_id)
		return {}
	
	var patron_data: Dictionary = active_patrons[patron_id]
	if patron_data.order_taken:
		push_warning("Order already taken for patron: %s" % patron_id)
		return {}
	
	# Generate order based on patron needs and personality
	var order: Dictionary = _generate_patron_order(patron_data)
	
	patron_data.order_taken = true
	patron_data.status = "ordering"
	patron_data.current_order = order
	
	patron_order_taken.emit(patron_id, order)
	return order

func fulfill_patron_order(patron_id: String, wine_quality: float) -> bool:
	"""Fulfill a patron's order and calculate satisfaction"""
	if not patron_id in active_patrons:
		return false
	
	var patron_data: Dictionary = active_patrons[patron_id]
	if not patron_data.order_taken:
		push_error("No order to fulfill for patron: %s" % patron_id)
		return false
	
	# Calculate satisfaction based on wine quality and personality
	var satisfaction: float = _calculate_patron_satisfaction(patron_data, wine_quality)
	patron_data.satisfaction = satisfaction
	patron_data.order_fulfilled = true
	patron_data.status = "satisfied"
	
	# Calculate tip and earnings
	var tip_amount: int = _calculate_patron_tip(patron_data, satisfaction)
	patron_data.tip_amount = tip_amount
	
	# Award experience and reputation
	_award_patron_rewards(patron_data, satisfaction)
	
	if satisfaction >= GameConstants.PATRON_SATISFACTION_THRESHOLD:
		patron_satisfied.emit(patron_id, satisfaction)
	else:
		patron_dissatisfied.emit(patron_id, "Low satisfaction: %.2f" % satisfaction)
	
	return true

## Patron behavior and AI methods

func update_patron_behavior(delta: float) -> void:
	"""Update patron behavior and satisfaction over time"""
	var current_time: float = Time.get_time_dict_from_system().get("unix", 0.0)
	
	for patron_id in active_patrons.keys():
		var patron_data: Dictionary = active_patrons[patron_id]
		var time_in_scene: float = current_time - patron_data.spawn_time
		
		# Check if patron should leave due to impatience
		if time_in_scene >= patron_data.patience_time:
			_handle_patron_impatience(patron_id)
			continue
		
		# Update satisfaction based on time and service
		_update_patron_satisfaction(patron_id, delta)
		
		# Handle patron behavior changes
		_handle_patron_behavior_changes(patron_id, delta)

func get_patron_status(patron_id: String) -> String:
	"""Get the current status of a patron"""
	if not patron_id in active_patrons:
		return "not_found"
	
	return active_patrons[patron_id].get("status", "unknown")

func get_patron_satisfaction(patron_id: String) -> float:
	"""Get the current satisfaction level of a patron"""
	if not patron_id in active_patrons:
		return 0.0
	
	return active_patrons[patron_id].get("satisfaction", 0.0)

## Spawning and timing methods

func set_spawn_interval(new_interval: float) -> void:
	"""Change the patron spawn interval"""
	spawn_interval = new_interval
	if patron_spawn_timer:
		patron_spawn_timer.wait_time = spawn_interval

func pause_spawning() -> void:
	"""Pause patron spawning"""
	if patron_spawn_timer:
		patron_spawn_timer.paused = true

func resume_spawning() -> void:
	"""Resume patron spawning"""
	if patron_spawn_timer:
		patron_spawn_timer.paused = false

func update_day_cycle(progress: float) -> void:
	"""Update the day cycle progress (affects patron spawning)"""
	day_cycle_progress = progress
	
	# Adjust spawn rate based on time of day
	var time_multiplier: float = _calculate_time_multiplier(progress)
	patron_spawn_timer.wait_time = spawn_interval * time_multiplier

## Statistics and tracking methods

func get_patron_statistics() -> Dictionary:
	"""Get comprehensive patron statistics"""
	return {
		"active_patrons": active_patrons.size(),
		"max_patrons": max_patrons,
		"total_patrons_served": total_patrons_served,
		"average_satisfaction": average_satisfaction,
		"current_satisfaction": _calculate_current_satisfaction(),
		"spawn_interval": spawn_interval,
		"day_cycle_progress": day_cycle_progress
	}

func get_satisfaction_history() -> Array[float]:
	"""Get the satisfaction history for analysis"""
	return satisfaction_history.duplicate()

## Save/load methods

func get_save_data() -> Dictionary:
	"""Get patron manager data for saving"""
	return {
		"active_patrons": active_patrons,
		"patron_templates": patron_templates,
		"personality_weights": personality_weights,
		"need_priorities": need_priorities,
		"total_patrons_served": total_patrons_served,
		"average_satisfaction": average_satisfaction,
		"satisfaction_history": satisfaction_history,
		"spawn_interval": spawn_interval,
		"day_cycle_progress": day_cycle_progress
	}

func load_save_data(save_data: Dictionary) -> void:
	"""Load patron manager data from save"""
	if not _validate_save_data(save_data):
		push_error("Invalid save data format for PatronManager")
		return
	
	active_patrons = save_data.get("active_patrons", {})
	patron_templates = save_data.get("patron_templates", {})
	personality_weights = save_data.get("personality_weights", {})
	need_priorities = save_data.get("need_priorities", {})
	total_patrons_served = save_data.get("total_patrons_served", 0)
	average_satisfaction = save_data.get("average_satisfaction", 0.0)
	satisfaction_history = save_data.get("satisfaction_history", [])
	spawn_interval = save_data.get("spawn_interval", GameConstants.PATRON_SPAWN_INTERVAL)
	day_cycle_progress = save_data.get("day_cycle_progress", 0.0)

## Private helper methods

func _initialize_patron_system() -> void:
	"""Initialize the patron management system"""
	# Initialize personality weights
	personality_weights = {
		GameEnums.PatronPersonality.ARISTOCRATIC: 0.15,
		GameEnums.PatronPersonality.BOHEMIAN: 0.12,
		GameEnums.PatronPersonality.BUSINESS: 0.20,
		GameEnums.PatronPersonality.CRIMINAL: 0.08,
		GameEnums.PatronPersonality.MYSTIC: 0.10,
		GameEnums.PatronPersonality.PARTY_GOER: 0.18,
		GameEnums.PatronPersonality.LONER: 0.07,
		GameEnums.PatronPersonality.REGULAR: 0.10
	}
	
	# Initialize need priorities
	need_priorities = {
		GameEnums.PatronNeed.BLOOD_WINE: 1.0,
		GameEnums.PatronNeed.COMPANIONSHIP: 0.7,
		GameEnums.PatronNeed.ENTERTAINMENT: 0.6,
		GameEnums.PatronNeed.PRIVACY: 0.5,
		GameEnums.PatronNeed.STATUS: 0.8,
		GameEnums.PatronNeed.EXCITEMENT: 0.4,
		GameEnums.PatronNeed.COMFORT: 0.6,
		GameEnums.PatronNeed.INSPIRATION: 0.3
	}

func _load_patron_templates() -> void:
	"""Load patron templates from resources"""
	# This would typically load from resource files
	# For now, we'll create some basic templates
	patron_templates = {
		"aristocratic": {
			"name": "Aristocratic Patron",
			"description": "High-class vampire with refined tastes",
			"base_satisfaction": 0.8,
			"tip_multiplier": 2.0,
			"patience": 0.7,
			"preferred_wines": ["vampire_essence_wine", "emotion_blend_wine"]
		},
		"bohemian": {
			"name": "Bohemian Patron",
			"description": "Artistic vampire seeking inspiration",
			"base_satisfaction": 0.6,
			"tip_multiplier": 1.5,
			"patience": 1.2,
			"preferred_wines": ["emotion_blend_wine", "basic_blood_wine"]
		},
		"business": {
			"name": "Business Patron",
			"description": "Professional vampire with consistent preferences",
			"base_satisfaction": 0.9,
			"tip_multiplier": 1.8,
			"patience": 1.0,
			"preferred_wines": ["vampire_essence_wine", "basic_blood_wine"]
		}
	}

func _setup_spawn_timer() -> void:
	"""Set up the patron spawn timer"""
	patron_spawn_timer = Timer.new()
	patron_spawn_timer.wait_time = spawn_interval
	patron_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(patron_spawn_timer)
	patron_spawn_timer.start()

func _generate_patron_id() -> String:
	"""Generate a unique patron ID"""
	var timestamp: int = int(Time.get_time_dict_from_system().get("unix", 0.0))
	var random_suffix: String = str(randi() % 10000).pad_zeros(4)
	return "patron_%d_%s" % [timestamp, random_suffix]

func _select_random_personality() -> GameEnums.PatronPersonality:
	"""Select a random personality based on weights"""
	var total_weight: float = 0.0
	for weight in personality_weights.values():
		total_weight += weight
	
	var random_value: float = randf() * total_weight
	var current_weight: float = 0.0
	
	for personality in personality_weights.keys():
		current_weight += personality_weights[personality]
		if random_value <= current_weight:
			return personality
	
	# Fallback to regular personality
	return GameEnums.PatronPersonality.REGULAR

func _generate_patron_needs(personality: GameEnums.PatronPersonality) -> Array[GameEnums.PatronNeed]:
	"""Generate needs for a patron based on personality"""
	var needs: Array[GameEnums.PatronNeed] = [GameEnums.PatronNeed.BLOOD_WINE]
	
	# Add personality-specific needs
	match personality:
		GameEnums.PatronPersonality.ARISTOCRATIC:
			needs.append_array([GameEnums.PatronNeed.STATUS, GameEnums.PatronNeed.PRIVACY])
		GameEnums.PatronPersonality.BOHEMIAN:
			needs.append_array([GameEnums.PatronNeed.INSPIRATION, GameEnums.PatronNeed.ENTERTAINMENT])
		GameEnums.PatronPersonality.BUSINESS:
			needs.append_array([GameEnums.PatronNeed.COMFORT, GameEnums.PatronNeed.STATUS])
		GameEnums.PatronPersonality.CRIMINAL:
			needs.append_array([GameEnums.PatronNeed.EXCITEMENT, GameEnums.PatronNeed.PRIVACY])
		GameEnums.PatronPersonality.MYSTIC:
			needs.append_array([GameEnums.PatronNeed.INSPIRATION, GameEnums.PatronNeed.PRIVACY])
		GameEnums.PatronPersonality.PARTY_GOER:
			needs.append_array([GameEnums.PatronNeed.COMPANIONSHIP, GameEnums.PatronNeed.ENTERTAINMENT])
		GameEnums.PatronPersonality.LONER:
			needs.append_array([GameEnums.PatronNeed.PRIVACY, GameEnums.PatronNeed.COMFORT])
		GameEnums.PatronPersonality.REGULAR:
			needs.append_array([GameEnums.PatronNeed.COMPANIONSHIP, GameEnums.PatronNeed.COMFORT])
	
	# Shuffle needs to add variety
	needs.shuffle()
	return needs

func _generate_patron_order(patron_data: Dictionary) -> Dictionary:
	"""Generate an order for a patron based on their preferences"""
	var personality: GameEnums.PatronPersonality = patron_data.personality
	var template: Dictionary = patron_templates.get(_get_personality_key(personality), {})
	var preferred_wines: Array = template.get("preferred_wines", ["basic_blood_wine"])
	
	var selected_wine: String = preferred_wines[randi() % preferred_wines.size()]
	var quantity: int = 1
	
	# Some personalities order more
	if personality == GameEnums.PatronPersonality.PARTY_GOER:
		quantity = randi_range(1, 3)
	elif personality == GameEnums.PatronPersonality.ARISTOCRATIC:
		quantity = randi_range(1, 2)
	
	return {
		"wine_id": selected_wine,
		"quantity": quantity,
		"special_requests": _generate_special_requests(personality),
		"urgency": _calculate_order_urgency(patron_data)
	}

func _calculate_patron_satisfaction(patron_data: Dictionary, wine_quality: float) -> float:
	"""Calculate patron satisfaction based on wine quality and personality"""
	var base_satisfaction: float = patron_data.get("satisfaction", 1.0)
	var personality: GameEnums.PatronPersonality = patron_data.personality
	var template: Dictionary = patron_templates.get(_get_personality_key(personality), {})
	
	# Base satisfaction from wine quality
	var quality_satisfaction: float = wine_quality
	
	# Personality modifier
	var personality_modifier: float = template.get("base_satisfaction", 0.8)
	
	# Service speed bonus
	var service_speed: float = _calculate_service_speed(patron_data)
	var speed_bonus: float = service_speed * 0.2
	
	# Final satisfaction calculation
	var final_satisfaction: float = (quality_satisfaction + personality_modifier + speed_bonus) / 3.0
	
	return clamp(final_satisfaction, 0.0, 1.0)

func _calculate_patron_tip(patron_data: Dictionary, satisfaction: float) -> float:
	"""Calculate tip amount based on satisfaction and personality"""
	var personality: GameEnums.PatronPersonality = patron_data.personality
	var template: Dictionary = patron_templates.get(_get_personality_key(personality), {})
	var base_tip_multiplier: float = template.get("tip_multiplier", 1.0)
	
	var satisfaction_multiplier: float = satisfaction * 2.0
	var final_tip: float = base_tip_multiplier * satisfaction_multiplier
	
	return final_tip

func _award_patron_rewards(patron_data: Dictionary, satisfaction: float) -> void:
	"""Award experience and reputation for serving a patron"""
	var base_xp: int = GameConstants.XP_PER_SATISFIED_PATRON
	var xp_multiplier: float = satisfaction
	
	PlayerData.add_experience(int(base_xp * xp_multiplier))
	
	# Award reputation based on satisfaction
	var reputation_gain: float = satisfaction * 0.1
	PlayerData.gain_reputation(reputation_gain)
	
	# Update patron statistics
	total_patrons_served += 1
	_update_satisfaction_tracking(satisfaction)

func _update_patron_satisfaction(patron_id: String, delta: float) -> void:
	"""Update patron satisfaction over time"""
	if not patron_id in active_patrons:
		return
	
	var patron_data: Dictionary = active_patrons[patron_id]
	var current_satisfaction: float = patron_data.satisfaction
	
	# Satisfaction decreases over time
	var satisfaction_decay: float = GameConstants.PATRON_SATISFACTION_DECAY * delta
	var new_satisfaction: float = current_satisfaction - satisfaction_decay
	
	patron_data.satisfaction = clamp(new_satisfaction, 0.0, 1.0)
	
	# Update status based on satisfaction
	if patron_data.satisfaction < 0.3:
		patron_data.status = "dissatisfied"
	elif patron_data.satisfaction < 0.6:
		patron_data.status = "neutral"
	else:
		patron_data.status = "satisfied"

func _handle_patron_impatience(patron_id: String) -> void:
	"""Handle a patron leaving due to impatience"""
	var patron_data: Dictionary = active_patrons[patron_id]
	
	# Reduce reputation for poor service
	var reputation_loss: float = 0.05
	PlayerData.gain_reputation(-reputation_loss)
	
	remove_patron(patron_id, "impatient")

func _handle_patron_behavior_changes(patron_id: String, delta: float) -> void:
	"""Handle changes in patron behavior over time"""
	if not patron_id in active_patrons:
		return
	
	var patron_data: Dictionary = active_patrons[patron_id]
	
	# Patrons may change their needs over time
	if randf() < 0.01:  # 1% chance per frame
		var new_needs: Array[GameEnums.PatronNeed] = _generate_patron_needs(patron_data.personality)
		patron_data.needs = new_needs
		patron_data.current_need = new_needs[0] if new_needs.size() > 0 else GameEnums.PatronNeed.BLOOD_WINE

func _update_satisfaction_tracking(satisfaction: float) -> void:
	"""Update satisfaction tracking statistics"""
	satisfaction_history.append(satisfaction)
	
	# Keep only recent history
	if satisfaction_history.size() > 100:
		satisfaction_history.remove_at(0)
	
	# Update average satisfaction
	var total_satisfaction: float = 0.0
	for sat in satisfaction_history:
		total_satisfaction += sat
	
	average_satisfaction = total_satisfaction / satisfaction_history.size()

func _calculate_current_satisfaction() -> float:
	"""Calculate current average satisfaction of active patrons"""
	if active_patrons.is_empty():
		return 0.0
	
	var total_satisfaction: float = 0.0
	for patron_data in active_patrons.values():
		total_satisfaction += patron_data.get("satisfaction", 0.0)
	
	return total_satisfaction / active_patrons.size()

func _calculate_time_multiplier(day_progress: float) -> float:
	"""Calculate spawn rate multiplier based on time of day"""
	# Peak hours (evening) have more patrons
	if day_progress >= 0.6 and day_progress <= 0.8:
		return 0.5  # Spawn twice as fast
	elif day_progress >= 0.2 and day_progress <= 0.4:
		return 2.0  # Spawn half as fast (early morning)
	else:
		return 1.0  # Normal spawn rate

func _get_personality_key(personality: GameEnums.PatronPersonality) -> String:
	"""Get the string key for a personality enum"""
	match personality:
		GameEnums.PatronPersonality.ARISTOCRATIC:
			return "aristocratic"
		GameEnums.PatronPersonality.BOHEMIAN:
			return "bohemian"
		GameEnums.PatronPersonality.BUSINESS:
			return "business"
		GameEnums.PatronPersonality.CRIMINAL:
			return "criminal"
		GameEnums.PatronPersonality.MYSTIC:
			return "mystic"
		GameEnums.PatronPersonality.PARTY_GOER:
			return "party_goer"
		GameEnums.PatronPersonality.LONER:
			return "loner"
		GameEnums.PatronPersonality.REGULAR:
			return "regular"
		_:
			return "regular"

func _generate_special_requests(personality: GameEnums.PatronPersonality) -> Array[String]:
	"""Generate special requests based on personality"""
	var requests: Array[String] = []
	
	match personality:
		GameEnums.PatronPersonality.ARISTOCRATIC:
			if randf() < 0.3:
				requests.append("aged_wine")
			if randf() < 0.2:
				requests.append("private_serving")
		GameEnums.PatronPersonality.BOHEMIAN:
			if randf() < 0.4:
				requests.append("experimental_blend")
			if randf() < 0.3:
				requests.append("artistic_presentation")
		GameEnums.PatronPersonality.CRIMINAL:
			if randf() < 0.5:
				requests.append("discrete_serving")
	
	return requests

func _calculate_order_urgency(patron_data: Dictionary) -> float:
	"""Calculate how urgent a patron's order is"""
	var personality: GameEnums.PatronPersonality = patron_data.personality
	var time_in_scene: float = Time.get_time_dict_from_system().get("unix", 0.0) - patron_data.spawn_time
	var patience_remaining: float = patron_data.patience_time - time_in_scene
	
	# More urgent if patience is running low
	var urgency: float = 1.0 - (patience_remaining / patron_data.patience_time)
	
	# Some personalities are more urgent
	if personality == GameEnums.PatronPersonality.ARISTOCRATIC:
		urgency *= 1.5
	elif personality == GameEnums.PatronPersonality.CRIMINAL:
		urgency *= 1.3
	
	return clamp(urgency, 0.0, 1.0)

func _calculate_service_speed(patron_data: Dictionary) -> float:
	"""Calculate service speed for satisfaction bonus"""
	var order_time: float = 0.0
	if patron_data.order_taken:
		order_time = Time.get_time_dict_from_system().get("unix", 0.0) - patron_data.spawn_time
	
	# Faster service = higher bonus
	var speed_score: float = 1.0 - (order_time / patron_data.patience_time)
	return clamp(speed_score, 0.0, 1.0)

func _on_spawn_timer_timeout() -> void:
	"""Handle spawn timer timeout"""
	if active_patrons.size() < max_patrons:
		spawn_patron()

func _connect_signals() -> void:
	"""Connect to other system signals"""
	if DataManager:
		DataManager.data_saved.connect(_on_data_saved)

func _validate_save_data(save_data: Dictionary) -> bool:
	"""Validate save data structure"""
	var required_keys: Array[String] = [
		"active_patrons", "patron_templates", "total_patrons_served"
	]
	
	for key in required_keys:
		if not key in save_data:
			return false
	
	return true

func _on_data_saved(save_slot: int) -> void:
	"""Handle data save events"""
	# Patron data is automatically saved as part of the main save data
	pass
