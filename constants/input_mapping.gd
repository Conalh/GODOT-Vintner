class_name InputMapping
extends Resource

## Input mapping constants for Hemovintner

## Player movement actions
const MOVE_LEFT: String = "move_left"
const MOVE_RIGHT: String = "move_right"
const MOVE_UP: String = "move_up"
const MOVE_DOWN: String = "move_down"
const MOVE_FAST: String = "move_fast"
const MOVE_SLOW: String = "move_slow"

## Player interaction actions
const INTERACT: String = "interact"
const USE_ITEM: String = "use_item"
const DROP_ITEM: String = "drop_item"
const PICKUP_ITEM: String = "pickup_item"
const EXAMINE: String = "examine"

## Combat and action actions
const ATTACK: String = "attack"
const DEFEND: String = "defend"
const DODGE: String = "dodge"
const JUMP: String = "jump"
const CROUCH: String = "crouch"
const SPRINT: String = "sprint"

## Inventory and crafting actions
const OPEN_INVENTORY: String = "open_inventory"
const OPEN_CRAFTING: String = "open_crafting"
const CRAFT_ITEM: String = "craft_item"
const SELECT_RECIPE: String = "select_recipe"
const QUICK_ACCESS_1: String = "quick_access_1"
const QUICK_ACCESS_2: String = "quick_access_2"
const QUICK_ACCESS_3: String = "quick_access_3"
const QUICK_ACCESS_4: String = "quick_access_4"

## Bar management actions
const SERVE_PATRON: String = "serve_patron"
const TAKE_ORDER: String = "take_order"
const PREPARE_DRINK: String = "prepare_drink"
const CALL_PATRON: String = "call_patron"
const CLEAN_UP: String = "clean_up"

## UI and menu actions
const PAUSE: String = "pause"
const OPEN_MENU: String = "open_menu"
const CONFIRM: String = "confirm"
const CANCEL: String = "cancel"
const NEXT_TAB: String = "next_tab"
const PREVIOUS_TAB: String = "previous_tab"
const SCROLL_UP: String = "scroll_up"
const SCROLL_DOWN: String = "scroll_down"

## Camera and view actions
const ZOOM_IN: String = "zoom_in"
const ZOOM_OUT: String = "zoom_out"
const ROTATE_CAMERA: String = "rotate_camera"
const RESET_CAMERA: String = "reset_camera"
const TOGGLE_PERSPECTIVE: String = "toggle_perspective"

## Debug and development actions
const DEBUG_MENU: String = "debug_menu"
const TOGGLE_DEBUG_INFO: String = "toggle_debug_info"
const RELOAD_SCENE: String = "reload_scene"
const TOGGLE_GOD_MODE: String = "toggle_god_mode"
const SPAWN_ITEM: String = "spawn_item"
const TELEPORT_PLAYER: String = "teleport_player"

## Multiplayer actions (for future features)
const CHAT: String = "chat"
const TEAM_CHAT: String = "team_chat"
const EMOTE: String = "emote"
const VOTE: String = "vote"
const SPECTATE: String = "spectate"

## Accessibility actions
const TOGGLE_ACCESSIBILITY: String = "toggle_accessibility"
const INCREASE_TEXT_SIZE: String = "increase_text_size"
const DECREASE_TEXT_SIZE: String = "decrease_text_size"
const TOGGLE_HIGH_CONTRAST: String = "toggle_high_contrast"
const TOGGLE_COLORBLIND_MODE: String = "toggle_colorblind_mode"

## Default key bindings (can be customized by player)
const DEFAULT_BINDINGS: Dictionary = {
	MOVE_LEFT: [KEY_A, KEY_LEFT],
	MOVE_RIGHT: [KEY_D, KEY_RIGHT],
	MOVE_UP: [KEY_W, KEY_UP],
	MOVE_DOWN: [KEY_S, KEY_DOWN],
	MOVE_FAST: [KEY_SHIFT],
	MOVE_SLOW: [KEY_CTRL],
	INTERACT: [KEY_E, KEY_ENTER],
	USE_ITEM: [KEY_Q],
	ATTACK: [KEY_SPACE, KEY_MOUSE_LEFT],
	DEFEND: [KEY_MOUSE_RIGHT],
	JUMP: [KEY_SPACE],
	OPEN_INVENTORY: [KEY_I, KEY_TAB],
	OPEN_CRAFTING: [KEY_C],
	PAUSE: [KEY_ESCAPE, KEY_P],
	CONFIRM: [KEY_ENTER, KEY_SPACE],
	CANCEL: [KEY_ESCAPE, KEY_BACKSPACE],
	ZOOM_IN: [KEY_EQUAL, KEY_PLUS],
	ZOOM_OUT: [KEY_MINUS],
	DEBUG_MENU: [KEY_F1],
	RELOAD_SCENE: [KEY_F5]
}

## Gamepad bindings
const DEFAULT_GAMEPAD_BINDINGS: Dictionary = {
	MOVE_LEFT: [JOY_ANALOG_LX],
	MOVE_RIGHT: [JOY_ANALOG_LX],
	MOVE_UP: [JOY_ANALOG_LY],
	MOVE_DOWN: [JOY_ANALOG_LY],
	INTERACT: [JOY_BUTTON_A],
	ATTACK: [JOY_BUTTON_B],
	DEFEND: [JOY_BUTTON_X],
	JUMP: [JOY_BUTTON_A],
	OPEN_INVENTORY: [JOY_BUTTON_Y],
	PAUSE: [JOY_BUTTON_START],
	CONFIRM: [JOY_BUTTON_A],
	CANCEL: [JOY_BUTTON_B]
}

## Input sensitivity settings
const DEFAULT_MOUSE_SENSITIVITY: float = 1.0
const DEFAULT_GAMEPAD_SENSITIVITY: float = 1.0
const DEFAULT_DEADZONE: float = 0.1
const MAX_SENSITIVITY: float = 3.0
const MIN_SENSITIVITY: float = 0.1

## Input validation
static func is_valid_action(action_name: String) -> bool:
	return action_name in DEFAULT_BINDINGS or action_name in DEFAULT_GAMEPAD_BINDINGS

static func get_default_binding(action_name: String) -> Array:
	if action_name in DEFAULT_BINDINGS:
		return DEFAULT_BINDINGS[action_name]
	elif action_name in DEFAULT_GAMEPAD_BINDINGS:
		return DEFAULT_GAMEPAD_BINDINGS[action_name]
	return []

static func get_all_actions() -> Array[String]:
	var actions: Array[String] = []
	actions.append_array(DEFAULT_BINDINGS.keys())
	actions.append_array(DEFAULT_GAMEPAD_BINDINGS.keys())
	return actions
