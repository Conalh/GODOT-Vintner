class_name GameConstants
extends Resource

## Game-wide constants for Hemovintner

## File paths and resources
const SAVE_FILE_PATH: String = "user://hemovintner_save.dat"
const CONFIG_FILE_PATH: String = "user://hemovintner_config.dat"
const DEFAULT_CONFIG_PATH: String = "res://resources/default_config.tres"

## Scene paths
const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
const MAIN_HUB_SCENE: String = "res://scenes/hub/main_hub.tscn"
const DESERT_LEVEL_SCENE: String = "res://scenes/hunt/desert_level.tscn"
const NIGHTCLUB_LEVEL_SCENE: String = "res://scenes/hunt/nightclub_level.tscn"
const VAMPIRE_COURT_SCENE: String = "res://scenes/hunt/vampire_court.tscn"

## Game balance constants
const BASE_WINE_PRICE: int = 100
const QUALITY_MULTIPLIER: float = 1.5
const REPUTATION_BONUS: float = 0.1
const PATRON_SATISFACTION_THRESHOLD: float = 0.7

## Time constants (in seconds)
const DAY_CYCLE_DURATION: float = 300.0  # 5 minutes per day
const NIGHT_CYCLE_DURATION: float = 180.0 # 3 minutes per night
const PATRON_SPAWN_INTERVAL: float = 30.0 # New patron every 30 seconds
const WINE_AGING_BASE_TIME: float = 60.0  # Base aging time in seconds

## Inventory limits
const MAX_INVENTORY_SLOTS: int = 50
const MAX_WINE_STORAGE: int = 100
const MAX_BLOOD_SOURCES: int = 200
const MAX_RELICS: int = 25

## Crafting constants
const MAX_RECIPE_INGREDIENTS: int = 5
const MIN_WINE_QUALITY: float = 0.1
const MAX_WINE_QUALITY: float = 1.0
const CRAFTING_FAILURE_CHANCE: float = 0.05

## Patron behavior constants
const MAX_PATRONS_PER_SCENE: int = 8
const PATRON_PATIENCE_TIME: float = 120.0  # 2 minutes before leaving
const PATRON_SATISFACTION_DECAY: float = 0.1
const PATRON_TIP_CHANCE: float = 0.3

## Player progression constants
const XP_PER_SATISFIED_PATRON: int = 10
const XP_PER_QUALITY_WINE: int = 25
const XP_PER_SUCCESSFUL_HUNT: int = 100
const LEVEL_UP_THRESHOLD_MULTIPLIER: float = 1.5

## Economy constants
const STARTING_CURRENCY: int = 500
const DAILY_EXPENSES: int = 50
const TAX_RATE: float = 0.1
const INSURANCE_COST: int = 25

## Hunt mode constants
const MAX_HUNT_DURATION: float = 600.0  # 10 minutes max
const INGREDIENT_SPAWN_RATE: float = 2.0  # Every 2 seconds
const ENEMY_SPAWN_RATE: float = 5.0      # Every 5 seconds
const BOSS_SPAWN_THRESHOLD: float = 0.8   # At 80% hunt completion

## Audio constants
const MASTER_VOLUME_DEFAULT: float = 0.8
const MUSIC_VOLUME_DEFAULT: float = 0.6
const SFX_VOLUME_DEFAULT: float = 0.7
const AMBIENT_VOLUME_DEFAULT: float = 0.5

## Visual constants
const SCREEN_FADE_DURATION: float = 0.5
const UI_ANIMATION_DURATION: float = 0.3
const PARTICLE_LIFETIME: float = 2.0
const LIGHT_FLICKER_RATE: float = 0.1

## Debug and development constants
const DEBUG_MODE: bool = true
const SHOW_FPS: bool = true
const SHOW_DEBUG_INFO: bool = true
const ENABLE_CHEATS: bool = true
const LOG_LEVEL: int = 2  # 0=Error, 1=Warning, 2=Info, 3=Debug

## Save system constants
const AUTO_SAVE_INTERVAL: float = 300.0  # Auto-save every 5 minutes
const MAX_SAVE_SLOTS: int = 5
const SAVE_VERSION: String = "1.0.0"

## Network constants (for future multiplayer features)
const MAX_PLAYERS: int = 4
const NETWORK_TICK_RATE: int = 60
const LATENCY_COMPENSATION: float = 0.1

## Localization constants
const DEFAULT_LANGUAGE: String = "en"
const SUPPORTED_LANGUAGES: Array[String] = ["en", "es", "fr", "de", "ja"]
const FALLBACK_LANGUAGE: String = "en"
