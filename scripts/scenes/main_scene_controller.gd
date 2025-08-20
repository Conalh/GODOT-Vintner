class_name MainSceneController
extends Node2D

## Main scene controller that manages the player and UI integration

@onready var player: Player = $Player
@onready var status_panel: Panel = $UI/InteractionPrompts/StatusPanel
@onready var interaction_info: Label = $UI/InteractionPrompts/StatusPanel/VBoxContainer/InteractionInfo

func _ready() -> void:
	"""Initialize the main scene controller"""
	_setup_player_connections()
	_setup_ui_display()

func _setup_player_connections() -> void:
	"""Connect player signals to UI updates"""
	if player:
		player.interaction_started.connect(_on_player_interaction_started)
		player.interaction_ended.connect(_on_player_interaction_ended)
		player.interaction_completed.connect(_on_player_interaction_completed)

func _setup_ui_display() -> void:
	"""Initialize the UI display"""
	if interaction_info:
		interaction_info.text = "No interaction available"

func _on_player_interaction_started(interactable: Node) -> void:
	"""Handle when the player starts an interaction"""
	if interaction_info:
		var prompt_text: String = "Interacting with: Test Object"
		if interactable.has_method("get_interaction_prompt"):
			prompt_text = "Interacting with: " + interactable.get_interaction_prompt()
		interaction_info.text = prompt_text

func _on_player_interaction_ended(interactable: Node) -> void:
	"""Handle when the player ends an interaction"""
	if interaction_info:
		interaction_info.text = "No interaction available"

func _on_player_interaction_completed(interactable: Node) -> void:
	"""Handle when the player completes an interaction"""
	if interaction_info:
		interaction_info.text = "Interaction completed"

func _process(_delta: float) -> void:
	"""Update UI based on current player state"""
	_update_interaction_display()

func _update_interaction_display() -> void:
	"""Update the interaction display based on current state"""
	if not player or not interaction_info:
		return
	
	var current_interactable: Node = player.get_current_interactable()
	if current_interactable:
		var prompt_text: String = "Press E to interact with: Test Object"
		if current_interactable.has_method("get_interaction_prompt"):
			prompt_text = "Press E to interact with: " + current_interactable.get_interaction_prompt()
		interaction_info.text = prompt_text
	else:
		interaction_info.text = "No interaction available"
