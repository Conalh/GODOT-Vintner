class_name EconomySystem
extends Node

## Economy and currency management system for Hemovintner
## Handles bar income, expenses, and the income banking system during hunts

signal currency_changed(old_amount: int, new_amount: int)
signal income_earned(amount: int, source: String)
signal expense_paid(amount: int, reason: String)
signal bar_income_banked(amount: int)
signal bar_income_delivered(amount: int)
signal daily_expenses_charged(amount: int)

## Currency and financial state
var current_currency: int = GameConstants.STARTING_CURRENCY
var total_earnings: int = 0
var total_expenses: int = 0
var net_profit: int = 0

## Bar income system
var bar_income_pending: int = 0
var bar_income_banked: int = 0
var bar_income_delivered: int = 0
var current_day_earnings: int = 0

## Financial tracking
var daily_expenses: int = GameConstants.DAILY_EXPENSES
var tax_rate: float = GameConstants.TAX_RATE
var insurance_cost: int = GameConstants.INSURANCE_COST
var last_expense_date: int = 0

## Hunt mode banking
var is_hunt_mode: bool = false
var hunt_start_currency: int = 0
var hunt_start_pending_income: int = 0

## Transaction history
var transaction_history: Array[Dictionary] = []
var max_transaction_history: int = 100

func _ready() -> void:
	_initialize_economy()
	_connect_signals()
	_start_daily_expense_timer()

## Core economy methods

func add_currency(amount: int, source: String = "unknown") -> void:
	"""Add currency to the player's account"""
	if amount <= 0:
		return
	
	var old_amount: int = current_currency
	current_currency += amount
	total_earnings += amount
	net_profit = total_earnings - total_expenses
	
	_record_transaction(amount, "income", source)
	currency_changed.emit(old_amount, current_currency)
	income_earned.emit(amount, source)

func spend_currency(amount: int, reason: String = "unknown") -> bool:
	"""Spend currency from the player's account"""
	if amount <= 0:
		return false
	
	if current_currency < amount:
		push_warning("Insufficient currency: %d < %d" % [current_currency, amount])
		return false
	
	var old_amount: int = current_currency
	current_currency -= amount
	total_expenses += amount
	net_profit = total_earnings - total_expenses
	
	_record_transaction(-amount, "expense", reason)
	currency_changed.emit(old_amount, current_currency)
	expense_paid.emit(amount, reason)
	
	return true

func earn_bar_income(amount: int, patron_satisfaction: float = 1.0) -> void:
	"""Earn income from bar operations (patron satisfaction affects amount)"""
	if amount <= 0:
		return
	
	var adjusted_amount: int = int(amount * patron_satisfaction)
	var reputation_bonus: float = PlayerData.bar_reputation * GameConstants.REPUTATION_BONUS
	var final_amount: int = int(adjusted_amount * (1.0 + reputation_bonus))
	
	current_day_earnings += final_amount
	
	if is_hunt_mode:
		# During hunt mode, bank the income
		bar_income_pending += final_amount
		bar_income_banked.emit(final_amount)
	else:
		# During bar mode, add directly to currency
		add_currency(final_amount, "bar_income")

func start_hunt_mode() -> void:
	"""Begin hunt mode and bank current bar income"""
	if is_hunt_mode:
		push_warning("Hunt mode already active")
		return
	
	is_hunt_mode = true
	hunt_start_currency = current_currency
	hunt_start_pending_income = bar_income_pending
	
	# Bank any pending bar income
	if bar_income_pending > 0:
		bar_income_banked += bar_income_pending
		bar_income_pending = 0
	
	# Save current state
	DataManager.save_game()

func end_hunt_mode() -> void:
	"""End hunt mode and deliver banked income"""
	if not is_hunt_mode:
		push_warning("Hunt mode not active")
		return
	
	is_hunt_mode = false
	
	# Deliver banked income
	if bar_income_banked > 0:
		add_currency(bar_income_banked, "hunt_completion_bonus")
		bar_income_delivered.emit(bar_income_banked)
		bar_income_banked = 0
	
	# Reset hunt tracking
	hunt_start_currency = 0
	hunt_start_pending_income = 0
	
	# Save state after hunt
	DataManager.save_game()

func complete_day() -> void:
	"""Complete a game day and process daily expenses"""
	var current_date: int = Time.get_unix_time_from_system()
	
	# Only charge expenses once per day
	if current_date - last_expense_date >= 86400:  # 24 hours in seconds
		_charge_daily_expenses()
		last_expense_date = current_date
	
	# Reset daily earnings
	current_day_earnings = 0

## Financial calculation methods

func calculate_wine_price(base_price: int, quality: float, rarity: float = 1.0) -> int:
	"""Calculate the selling price of a wine based on quality and rarity"""
	var quality_multiplier: float = 1.0 + (quality - 0.5) * GameConstants.QUALITY_MULTIPLIER
	var rarity_multiplier: float = 1.0 + (rarity - 1.0) * 0.5
	var final_price: int = int(base_price * quality_multiplier * rarity_multiplier)
	
	return max(final_price, 1)  # Minimum price of 1

func calculate_patron_tip(base_amount: int, satisfaction: float) -> int:
	"""Calculate tip amount based on patron satisfaction"""
	if satisfaction < GameConstants.PATRON_SATISFACTION_THRESHOLD:
		return 0
	
	var tip_chance: float = GameConstants.PATRON_TIP_CHANCE
	if randf() <= tip_chance:
		var tip_multiplier: float = 0.1 + (satisfaction - 0.7) * 0.3
		return int(base_amount * tip_multiplier)
	
	return 0

func calculate_taxes() -> int:
	"""Calculate taxes based on current earnings"""
	return int(total_earnings * tax_rate)

func get_financial_summary() -> Dictionary:
	"""Get a comprehensive financial summary"""
	return {
		"current_currency": current_currency,
		"total_earnings": total_earnings,
		"total_expenses": total_expenses,
		"net_profit": net_profit,
		"bar_income_pending": bar_income_pending,
		"bar_income_banked": bar_income_banked,
		"bar_income_delivered": bar_income_delivered,
		"current_day_earnings": current_day_earnings,
		"daily_expenses": daily_expenses,
		"tax_rate": tax_rate,
		"insurance_cost": insurance_cost,
		"is_hunt_mode": is_hunt_mode
	}

## Transaction and history methods

func get_transaction_history(limit: int = -1) -> Array[Dictionary]:
	"""Get transaction history, optionally limited to recent entries"""
	if limit <= 0 or limit > transaction_history.size():
		return transaction_history.duplicate()
	
	var start_index: int = max(0, transaction_history.size() - limit)
	return transaction_history.slice(start_index)

func clear_transaction_history() -> void:
	"""Clear the transaction history"""
	transaction_history.clear()

## Save/load methods

func get_save_data() -> Dictionary:
	"""Get economy data for saving"""
	return {
		"current_currency": current_currency,
		"total_earnings": total_earnings,
		"total_expenses": total_expenses,
		"net_profit": net_profit,
		"bar_income_pending": bar_income_pending,
		"bar_income_banked": bar_income_banked,
		"bar_income_delivered": bar_income_delivered,
		"current_day_earnings": current_day_earnings,
		"daily_expenses": daily_expenses,
		"tax_rate": tax_rate,
		"insurance_cost": insurance_cost,
		"last_expense_date": last_expense_date,
		"is_hunt_mode": is_hunt_mode,
		"hunt_start_currency": hunt_start_currency,
		"hunt_start_pending_income": hunt_start_pending_income,
		"transaction_history": transaction_history
	}

func load_save_data(save_data: Dictionary) -> void:
	"""Load economy data from save"""
	if not _validate_save_data(save_data):
		push_error("Invalid save data format for EconomySystem")
		return
	
	current_currency = save_data.get("current_currency", GameConstants.STARTING_CURRENCY)
	total_earnings = save_data.get("total_earnings", 0)
	total_expenses = save_data.get("total_expenses", 0)
	net_profit = save_data.get("net_profit", 0)
	bar_income_pending = save_data.get("bar_income_pending", 0)
	bar_income_banked = save_data.get("bar_income_banked", 0)
	bar_income_delivered = save_data.get("bar_income_delivered", 0)
	current_day_earnings = save_data.get("current_day_earnings", 0)
	daily_expenses = save_data.get("daily_expenses", GameConstants.DAILY_EXPENSES)
	tax_rate = save_data.get("tax_rate", GameConstants.TAX_RATE)
	insurance_cost = save_data.get("insurance_cost", GameConstants.INSURANCE_COST)
	last_expense_date = save_data.get("last_expense_date", 0)
	is_hunt_mode = save_data.get("is_hunt_mode", false)
	hunt_start_currency = save_data.get("hunt_start_currency", 0)
	hunt_start_pending_income = save_data.get("hunt_start_pending_income", 0)
	transaction_history = save_data.get("transaction_history", [])

## Private helper methods

func _initialize_economy() -> void:
	"""Initialize the economy system"""
	_charge_daily_expenses()
	last_expense_date = Time.get_unix_time_from_system()

func _start_daily_expense_timer() -> void:
	"""Start the timer for daily expenses"""
	var daily_timer: Timer = Timer.new()
	daily_timer.wait_time = GameConstants.DAY_CYCLE_DURATION
	daily_timer.timeout.connect(_on_daily_timer_timeout)
	add_child(daily_timer)
	daily_timer.start()

func _charge_daily_expenses() -> void:
	"""Charge daily expenses"""
	var total_daily_expenses: int = daily_expenses + insurance_cost
	
	if spend_currency(total_daily_expenses, "daily_expenses"):
		daily_expenses_charged.emit(total_daily_expenses)

func _record_transaction(amount: int, transaction_type: String, description: String) -> void:
	"""Record a financial transaction"""
	var transaction: Dictionary = {
		"timestamp": Time.get_unix_time_from_system(),
		"amount": amount,
		"type": transaction_type,
		"description": description,
		"balance_after": current_currency
	}
	
	transaction_history.append(transaction)
	
	# Limit transaction history size
	if transaction_history.size() > max_transaction_history:
		transaction_history.remove_at(0)

func _connect_signals() -> void:
	"""Connect to other system signals"""
	if DataManager:
		DataManager.data_saved.connect(_on_data_saved)
	
	if PlayerData:
		PlayerData.progression_updated.connect(_on_progression_updated)

func _validate_save_data(save_data: Dictionary) -> bool:
	"""Validate save data structure"""
	var required_keys: Array[String] = [
		"current_currency", "total_earnings", "total_expenses"
	]
	
	for key in required_keys:
		if not key in save_data:
			return false
	
	return true

func _on_daily_timer_timeout() -> void:
	"""Handle daily timer timeout"""
	complete_day()

func _on_data_saved(save_slot: int) -> void:
	"""Handle data save events"""
	# Economy data is automatically saved as part of the main save data
	pass

func _on_progression_updated() -> void:
	"""Handle player progression updates"""
	# Update reputation-based bonuses
	var reputation: float = PlayerData.bar_reputation
	var new_tax_rate: float = GameConstants.TAX_RATE * (1.0 - reputation * 0.001)
	tax_rate = max(new_tax_rate, 0.01)  # Minimum 1% tax rate

## Debug and development methods

func enable_debug_mode() -> void:
	"""Enable debug features for economy system"""
	if PlayerData and PlayerData.debug_mode:
		# Add debug currency
		add_currency(10000, "debug_currency")
		# Disable daily expenses
		daily_expenses = 0
		insurance_cost = 0

func disable_debug_mode() -> void:
	"""Disable debug features for economy system"""
	if PlayerData and not PlayerData.debug_mode:
		# Restore normal expenses
		daily_expenses = GameConstants.DAILY_EXPENSES
		insurance_cost = GameConstants.INSURANCE_COST

func reset_economy() -> void:
	"""Reset economy to starting state (debug only)"""
	if PlayerData and not PlayerData.debug_mode:
		push_warning("Cannot reset economy outside debug mode")
		return
	
	current_currency = GameConstants.STARTING_CURRENCY
	total_earnings = 0
	total_expenses = 0
	net_profit = 0
	bar_income_pending = 0
	bar_income_banked = 0
	bar_income_delivered = 0
	current_day_earnings = 0
	transaction_history.clear()
	
	currency_changed.emit(0, current_currency)
