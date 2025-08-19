class_name InventorySystem
extends Node

## Inventory and item management system for Hemovintner
## Handles item storage, organization, and item-related operations

signal item_added(item_id: String, quantity: int, slot: int)
signal item_removed(item_id: String, quantity: int, slot: int)
signal item_moved(from_slot: int, to_slot: int)
signal inventory_full
signal inventory_updated

## Inventory structure
var inventory_slots: Array[Dictionary] = []
var max_slots: int = GameConstants.MAX_INVENTORY_SLOTS

## Specialized storage
var wine_storage: Array[Dictionary] = []
var blood_source_storage: Array[Dictionary] = []
var relic_storage: Array[Dictionary] = []

## Storage limits
var max_wine_storage: int = GameConstants.MAX_WINE_STORAGE
var max_blood_sources: int = GameConstants.MAX_BLOOD_SOURCES
var max_relics: int = GameConstants.MAX_RELICS

## Item registry
var item_registry: Dictionary = {}
var item_templates: Dictionary = {}

func _ready() -> void:
	_initialize_inventory()
	_load_item_templates()
	_connect_signals()

## Core inventory methods

func add_item(item_id: String, quantity: int = 1, item_data: Dictionary = {}) -> bool:
	"""Add an item to the inventory"""
	if quantity <= 0:
		return false
	
	var item_template: Dictionary = _get_item_template(item_id)
	if item_template.is_empty():
		push_error("Unknown item ID: %s" % item_id)
		return false
	
	var item_type: GameEnums.ItemType = item_template.get("type", GameEnums.ItemType.CONSUMABLE)
	
	# Route to appropriate storage based on item type
	match item_type:
		GameEnums.ItemType.WINE:
			return _add_to_wine_storage(item_id, quantity, item_data)
		GameEnums.ItemType.BLOOD_SOURCE:
			return _add_to_blood_storage(item_id, quantity, item_data)
		GameEnums.ItemType.RELIC:
			return _add_to_relic_storage(item_id, quantity, item_data)
		_:
			return _add_to_general_inventory(item_id, quantity, item_data)

func remove_item(item_id: String, quantity: int = 1, slot: int = -1) -> bool:
	"""Remove an item from the inventory"""
	if quantity <= 0:
		return false
	
	var item_template: Dictionary = _get_item_template(item_id)
	if item_template.is_empty():
		return false
	
	var item_type: GameEnums.ItemType = item_template.get("type", GameEnums.ItemType.CONSUMABLE)
	
	# Route to appropriate storage based on item type
	match item_type:
		GameEnums.ItemType.WINE:
			return _remove_from_wine_storage(item_id, quantity)
		GameEnums.ItemType.BLOOD_SOURCE:
			return _remove_from_blood_storage(item_id, quantity)
		GameEnums.ItemType.RELIC:
			return _remove_from_relic_storage(item_id, quantity)
		_:
			return _remove_from_general_inventory(item_id, quantity, slot)

func get_item_quantity(item_id: String) -> int:
	"""Get the total quantity of an item across all storage"""
	var total_quantity: int = 0
	
	# Check general inventory
	for slot in inventory_slots:
		if slot.get("item_id") == item_id:
			total_quantity += slot.get("quantity", 0)
	
	# Check specialized storage
	total_quantity += _get_wine_quantity(item_id)
	total_quantity += _get_blood_source_quantity(item_id)
	total_quantity += _get_relic_quantity(item_id)
	
	return total_quantity

func has_item(item_id: String, quantity: int = 1) -> bool:
	"""Check if the inventory contains the specified quantity of an item"""
	return get_item_quantity(item_id) >= quantity

func find_item_slot(item_id: String) -> int:
	"""Find the first slot containing the specified item"""
	for i in range(inventory_slots.size()):
		if inventory_slots[i].get("item_id") == item_id:
			return i
	return -1

func move_item(from_slot: int, to_slot: int) -> bool:
	"""Move an item from one slot to another"""
	if not _is_valid_slot(from_slot) or not _is_valid_slot(to_slot):
		return false
	
	if from_slot == to_slot:
		return true
	
	var from_item: Dictionary = inventory_slots[from_slot]
	if from_item.is_empty():
		return false
	
	var to_item: Dictionary = inventory_slots[to_slot]
	
	# If destination slot is empty, move the item
	if to_item.is_empty():
		inventory_slots[to_slot] = from_item.duplicate()
		inventory_slots[from_slot] = {}
		item_moved.emit(from_slot, to_slot)
		inventory_updated.emit()
		return true
	
	# If destination slot has the same item, stack them
	if to_item.get("item_id") == from_item.get("item_id"):
		var max_stack: int = _get_item_template(from_item.get("item_id")).get("max_stack", 99)
		var space_in_stack: int = max_stack - to_item.get("quantity", 0)
		
		if space_in_stack > 0:
			var transfer_amount: int = min(space_in_stack, from_item.get("quantity", 0))
			to_item["quantity"] += transfer_amount
			from_item["quantity"] -= transfer_amount
			
			if from_item.get("quantity", 0) <= 0:
				inventory_slots[from_slot] = {}
			
			item_moved.emit(from_slot, to_slot)
			inventory_updated.emit()
			return true
	
	# If items are different, swap them
	var temp_item: Dictionary = to_item.duplicate()
	inventory_slots[to_slot] = from_item.duplicate()
	inventory_slots[from_slot] = temp_item
	
	item_moved.emit(from_slot, to_slot)
	inventory_updated.emit()
	return true

## Specialized storage methods

func add_wine(wine_id: String, wine_data: Dictionary) -> bool:
	"""Add a crafted wine to wine storage"""
	if wine_storage.size() >= max_wine_storage:
		push_warning("Wine storage is full")
		return false
	
	var wine_item: Dictionary = {
		"item_id": wine_id,
		"wine_data": wine_data,
		"craft_date": Time.get_unix_time_from_system(),
		"quality": wine_data.get("quality", 0.5),
		"aging_time": 0.0
	}
	
	wine_storage.append(wine_item)
	item_added.emit(wine_id, 1, wine_storage.size() - 1)
	inventory_updated.emit()
	return true

func add_blood_source(blood_id: String, blood_data: Dictionary) -> bool:
	"""Add a blood source to blood storage"""
	if blood_source_storage.size() >= max_blood_sources:
		push_warning("Blood source storage is full")
		return false
	
	var blood_item: Dictionary = {
		"item_id": blood_id,
		"blood_data": blood_data,
		"harvest_date": Time.get_unix_time_from_system(),
		"freshness": 1.0,
		"purity": blood_data.get("purity", 0.8)
	}
	
	blood_source_storage.append(blood_item)
	item_added.emit(blood_id, 1, blood_source_storage.size() - 1)
	inventory_updated.emit()
	return true

func add_relic(relic_id: String, relic_data: Dictionary) -> bool:
	"""Add a relic to relic storage"""
	if relic_storage.size() >= max_relics:
		push_warning("Relic storage is full")
		return false
	
	var relic_item: Dictionary = {
		"item_id": relic_id,
		"relic_data": relic_data,
		"discovery_date": Time.get_unix_time_from_system(),
		"power_level": relic_data.get("power_level", 1),
		"charges": relic_data.get("charges", 1)
	}
	
	relic_storage.append(relic_item)
	item_added.emit(relic_id, 1, relic_storage.size() - 1)
	inventory_updated.emit()
	return true

## Query methods

func get_all_wines() -> Array[Dictionary]:
	"""Get all wines in storage"""
	return wine_storage.duplicate()

func get_all_blood_sources() -> Array[Dictionary]:
	"""Get all blood sources in storage"""
	return blood_source_storage.duplicate()

func get_all_relics() -> Array[Dictionary]:
	"""Get all relics in storage"""
	return relic_storage.duplicate()

func get_wines_by_quality(min_quality: float = 0.0) -> Array[Dictionary]:
	"""Get wines above a certain quality threshold"""
	var filtered_wines: Array[Dictionary] = []
	
	for wine in wine_storage:
		if wine.get("quality", 0.0) >= min_quality:
			filtered_wines.append(wine)
	
	return filtered_wines

func get_blood_sources_by_type(blood_type: GameEnums.BloodType) -> Array[Dictionary]:
	"""Get blood sources of a specific type"""
	var filtered_sources: Array[Dictionary] = []
	
	for source in blood_source_storage:
		var source_data: Dictionary = source.get("blood_data", {})
		if source_data.get("blood_type") == blood_type:
			filtered_sources.append(source)
	
	return filtered_sources

func get_inventory_summary() -> Dictionary:
	"""Get a summary of all inventory contents"""
	var summary: Dictionary = {
		"general_items": {},
		"wine_count": wine_storage.size(),
		"blood_source_count": blood_source_storage.size(),
		"relic_count": relic_storage.size(),
		"total_items": 0
	}
	
	# Count general inventory items
	for slot in inventory_slots:
		if not slot.is_empty():
			var item_id: String = slot.get("item_id", "")
			var quantity: int = slot.get("quantity", 0)
			
			if item_id in summary.general_items:
				summary.general_items[item_id] += quantity
			else:
				summary.general_items[item_id] = quantity
			
			summary.total_items += quantity
	
	# Add specialized storage counts
	summary.total_items += wine_storage.size()
	summary.total_items += blood_source_storage.size()
	summary.total_items += relic_storage.size()
	
	return summary

## Save/load methods

func get_save_data() -> Dictionary:
	"""Get inventory data for saving"""
	return {
		"inventory_slots": inventory_slots,
		"wine_storage": wine_storage,
		"blood_source_storage": blood_source_storage,
		"relic_storage": relic_storage,
		"max_slots": max_slots,
		"max_wine_storage": max_wine_storage,
		"max_blood_sources": max_blood_sources,
		"max_relics": max_relics
	}

func load_save_data(save_data: Dictionary) -> void:
	"""Load inventory data from save"""
	if not _validate_save_data(save_data):
		push_error("Invalid save data format for InventorySystem")
		return
	
	inventory_slots = save_data.get("inventory_slots", [])
	wine_storage = save_data.get("wine_storage", [])
	blood_source_storage = save_data.get("blood_source_storage", [])
	relic_storage = save_data.get("relic_storage", [])
	max_slots = save_data.get("max_slots", GameConstants.MAX_INVENTORY_SLOTS)
	max_wine_storage = save_data.get("max_wine_storage", GameConstants.MAX_WINE_STORAGE)
	max_blood_sources = save_data.get("max_blood_sources", GameConstants.MAX_BLOOD_SOURCES)
	max_relics = save_data.get("max_relics", GameConstants.MAX_RELICS)
	
	inventory_updated.emit()

## Private helper methods

func _initialize_inventory() -> void:
	"""Initialize the inventory with empty slots"""
	inventory_slots.clear()
	
	for i in range(max_slots):
		inventory_slots.append({})

func _load_item_templates() -> void:
	"""Load item templates from resources"""
	# This would typically load from resource files
	# For now, we'll create some basic templates
	item_templates = {
		"basic_blood_wine": {
			"name": "Basic Blood Wine",
			"type": GameEnums.ItemType.WINE,
			"max_stack": 99,
			"description": "A simple blood wine"
		},
		"human_blood": {
			"name": "Human Blood",
			"type": GameEnums.ItemType.BLOOD_SOURCE,
			"max_stack": 50,
			"description": "Fresh human blood"
		},
		"vampire_blood": {
			"name": "Vampire Blood",
			"type": GameEnums.ItemType.BLOOD_SOURCE,
			"max_stack": 25,
			"description": "Potent vampire blood"
		}
	}

func _get_item_template(item_id: String) -> Dictionary:
	"""Get the template for an item"""
	return item_templates.get(item_id, {})

func _add_to_general_inventory(item_id: String, quantity: int, item_data: Dictionary) -> bool:
	"""Add an item to the general inventory"""
	var max_stack: int = _get_item_template(item_id).get("max_stack", 99)
	
	# First, try to stack with existing items
	for i in range(inventory_slots.size()):
		var slot: Dictionary = inventory_slots[i]
		if slot.get("item_id") == item_id:
			var space_in_stack: int = max_stack - slot.get("quantity", 0)
			if space_in_stack > 0:
				var transfer_amount: int = min(space_in_stack, quantity)
				slot["quantity"] += transfer_amount
				quantity -= transfer_amount
				
				item_added.emit(item_id, transfer_amount, i)
				
				if quantity <= 0:
					inventory_updated.emit()
					return true
	
	# If there's still quantity to add, find empty slots
	for i in range(inventory_slots.size()):
		if inventory_slots[i].is_empty():
			var add_amount: int = min(quantity, max_stack)
			inventory_slots[i] = {
				"item_id": item_id,
				"quantity": add_amount,
				"item_data": item_data
			}
			
			quantity -= add_amount
			item_added.emit(item_id, add_amount, i)
			
			if quantity <= 0:
				inventory_updated.emit()
				return true
	
	if quantity > 0:
		inventory_full.emit()
		return false
	
	return true

func _add_to_wine_storage(item_id: String, quantity: int, item_data: Dictionary) -> bool:
	"""Add a wine to wine storage"""
	return add_wine(item_id, item_data)

func _add_to_blood_storage(item_id: String, quantity: int, item_data: Dictionary) -> bool:
	"""Add a blood source to blood storage"""
	return add_blood_source(item_id, item_data)

func _add_to_relic_storage(item_id: String, quantity: int, item_data: Dictionary) -> bool:
	"""Add a relic to relic storage"""
	return add_relic(item_id, item_data)

func _remove_from_general_inventory(item_id: String, quantity: int, slot: int = -1) -> bool:
	"""Remove an item from general inventory"""
	var remaining_quantity: int = quantity
	
	if slot >= 0 and slot < inventory_slots.size():
		var slot_item: Dictionary = inventory_slots[slot]
		if slot_item.get("item_id") == item_id:
			var slot_quantity: int = slot_item.get("quantity", 0)
			var remove_amount: int = min(remaining_quantity, slot_quantity)
			
			slot_item["quantity"] -= remove_amount
			remaining_quantity -= remove_amount
			
			if slot_item["quantity"] <= 0:
				inventory_slots[slot] = {}
			
			item_removed.emit(item_id, remove_amount, slot)
			
			if remaining_quantity <= 0:
				inventory_updated.emit()
				return true
	
	# If we still need to remove more, search other slots
	for i in range(inventory_slots.size()):
		if remaining_quantity <= 0:
			break
		
		var slot_item: Dictionary = inventory_slots[i]
		if slot_item.get("item_id") == item_id:
			var slot_quantity: int = slot_item.get("quantity", 0)
			var remove_amount: int = min(remaining_quantity, slot_quantity)
			
			slot_item["quantity"] -= remove_amount
			remaining_quantity -= remove_amount
			
			if slot_item["quantity"] <= 0:
				inventory_slots[i] = {}
			
			item_removed.emit(item_id, remove_amount, i)
	
	inventory_updated.emit()
	return remaining_quantity <= 0

func _remove_from_wine_storage(item_id: String, quantity: int) -> bool:
	"""Remove a wine from wine storage"""
	var removed_count: int = 0
	
	for i in range(wine_storage.size() - 1, -1, -1):
		if removed_count >= quantity:
			break
		
		if wine_storage[i].get("item_id") == item_id:
			wine_storage.remove_at(i)
			removed_count += 1
			item_removed.emit(item_id, 1, i)
	
	inventory_updated.emit()
	return removed_count >= quantity

func _remove_from_blood_storage(item_id: String, quantity: int) -> bool:
	"""Remove a blood source from blood storage"""
	var removed_count: int = 0
	
	for i in range(blood_source_storage.size() - 1, -1, -1):
		if removed_count >= quantity:
			break
		
		if blood_source_storage[i].get("item_id") == item_id:
			blood_source_storage.remove_at(i)
			removed_count += 1
			item_removed.emit(item_id, 1, i)
	
	inventory_updated.emit()
	return removed_count >= quantity

func _remove_from_relic_storage(item_id: String, quantity: int) -> bool:
	"""Remove a relic from relic storage"""
	var removed_count: int = 0
	
	for i in range(relic_storage.size() - 1, -1, -1):
		if removed_count >= quantity:
			break
		
		if relic_storage[i].get("item_id") == item_id:
			relic_storage.remove_at(i)
			removed_count += 1
			item_removed.emit(item_id, 1, i)
	
	inventory_updated.emit()
	return removed_count >= quantity

func _get_wine_quantity(item_id: String) -> int:
	"""Get the quantity of a specific wine"""
	var count: int = 0
	for wine in wine_storage:
		if wine.get("item_id") == item_id:
			count += 1
	return count

func _get_blood_source_quantity(item_id: String) -> int:
	"""Get the quantity of a specific blood source"""
	var count: int = 0
	for source in blood_source_storage:
		if source.get("item_id") == item_id:
			count += 1
	return count

func _get_relic_quantity(item_id: String) -> int:
	"""Get the quantity of a specific relic"""
	var count: int = 0
	for relic in relic_storage:
		if relic.get("item_id") == item_id:
			count += 1
	return count

func _is_valid_slot(slot_index: int) -> bool:
	"""Check if a slot index is valid"""
	return slot_index >= 0 and slot_index < inventory_slots.size()

func _connect_signals() -> void:
	"""Connect to other system signals"""
	if DataManager:
		DataManager.data_saved.connect(_on_data_saved)

func _validate_save_data(save_data: Dictionary) -> bool:
	"""Validate save data structure"""
	var required_keys: Array[String] = [
		"inventory_slots", "wine_storage", "blood_source_storage", "relic_storage"
	]
	
	for key in required_keys:
		if not key in save_data:
			return false
	
	return true

func _on_data_saved(save_slot: int) -> void:
	"""Handle data save events"""
	# Inventory is automatically saved as part of the main save data
	pass
