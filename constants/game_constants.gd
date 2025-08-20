class_name GameConstants
extends Node

# Input constants
const DEFAULT_MOUSE_SENSITIVITY: float = 1.0
const INTERACTION_RANGE: float = 64.0
const INTERACTION_COOLDOWN: float = 0.2

# Movement constants
const PLAYER_SPEED: float = 200.0
const PLAYER_ACCELERATION: float = 1000.0
const PLAYER_FRICTION: float = 800.0

# UI constants
const FADE_DURATION: float = 0.3
const UI_ANIMATION_SPEED: float = 0.2

# Economic constants
const BASE_TIP_AMOUNT: int = 5
const PRESTIGE_MULTIPLIER: float = 1.1

# Bar and Scene constants
const BAR_WIDTH: int = 1200
const BAR_HEIGHT: int = 800
const MAX_PATRONS: int = 12
const PATRON_SPAWN_INTERVAL: float = 20.0
const DAY_CYCLE_DURATION: float = 300.0  # 5 minutes per day cycle
const BAR_ATMOSPHERE_DEFAULT: float = 0.5  # 0.0 = empty, 1.0 = packed

# Lighting constants
const MAIN_LIGHT_ENERGY: float = 1.0
const STATION_LIGHT_ENERGY: float = 0.8
const MOOD_LIGHT_ENERGY: float = 0.6
const AMBIENT_LIGHT_BASE: float = 0.5
const AMBIENT_LIGHT_VARIANCE: float = 0.5

# Station positioning constants
const BAR_COUNTER_POSITION_X: int = 200
const BAR_COUNTER_POSITION_Y: int = 300
const CRAFTING_BENCH_POSITION_X: int = 400
const CRAFTING_BENCH_POSITION_Y: int = 200
const CELLAR_SHELF_POSITION_X: int = 600
const CELLAR_SHELF_POSITION_Y: int = 400
const RUMOR_BOARD_POSITION_X: int = 800
const RUMOR_BOARD_POSITION_Y: int = 150
const ELEVATOR_POSITION_X: int = 1000
const ELEVATOR_POSITION_Y: int = 500

# Bar counter constants
const MAX_SEATS: int = 6
const COUNTER_LENGTH: int = 300
const SEAT_SPACING: float = 80.0
const SEAT_OFFSET_FROM_COUNTER: float = 30.0

# Spawn position constants
const SPAWN_MARGIN: int = 50
const SPAWN_MIDDLE_MARGIN: int = 100

# Activity scoring constants
const PATRON_ACTIVITY_SCORE: float = 0.3
const SERVICE_ACTIVITY_SCORE: float = 0.2
const ATMOSPHERE_ACTIVITY_SCORE: float = 0.1

# Audio constants
const AMBIENT_MUSIC_DAY_PITCH: float = 0.8
const AMBIENT_MUSIC_NIGHT_PITCH: float = 1.0

# Timer constants
const ATMOSPHERE_UPDATE_INTERVAL: float = 2.0

# Player constants
const MAX_SPEED: float = 200.0
const ACCELERATION: float = 800.0
const FRICTION: float = 600.0
const ROTATION_SPEED: float = 5.0
const ANIMATION_BLEND_TIME: float = 0.1
const IDLE_THRESHOLD: float = 10.0

# Patron constants
const PATRON_MAX_SPEED: float = 150.0
const PATRON_ACCELERATION: float = 500.0
const PATRON_FRICTION: float = 0.8
const PATRON_SATISFACTION_THRESHOLD: float = 0.7
const PATRON_MAX_SATISFACTION: float = 1.0
const PATRON_MIN_SATISFACTION: float = 0.0
# Rate at which patron satisfaction decreases per second
const PATRON_SATISFACTION_DECAY_RATE: float = 0.1
const PATRON_WAIT_TOLERANCE: float = 30.0
const PATRON_TIP_BASE: int = 10
const PATRON_TIP_MULTIPLIER: float = 1.5

# Test interactable constants
const TEST_INTERACTION_RANGE: float = 64.0
const TEST_INTERACTION_COOLDOWN: float = 1.0

# Rumor board constants
const MAX_RUMORS_DISPLAY: int = 6
const RUMOR_REFRESH_INTERVAL: float = 3600.0  # 1 hour
const MAX_ACTIVE_RUMORS: int = 8
const RUMOR_UNLOCK_LEVEL: int = 1
const RUMOR_BOARD_INTERACTION_RANGE: float = 70.0
const DIFFICULTY_THRESHOLDS: Array = [3, 5, 7, 9]
const RELIC_CHANCE_BASE: float = 0.1
const RELIC_CHANCE_PER_DIFFICULTY: float = 0.05

# Hunt level constants
const LEVEL_WIDTH: int = 800
const LEVEL_HEIGHT: int = 600
const ROOM_COUNT: int = 5
const MAX_ENEMIES: int = 12
const HUNT_DURATION: float = 300.0  # 5 minutes
const DIFFICULTY_MULTIPLIER: float = 1.0
const ENEMY_SPAWN_INTERVAL: float = 10.0
const MAX_CONCURRENT_ENEMIES: int = 6

# Hunt level visual constants
const ROOM_BACKGROUND_ALPHA: float = 0.3
const ROOM_BORDER_ALPHA: float = 0.5
const CONNECTION_WIDTH: int = 20
const CONNECTION_LINE_ALPHA: float = 0.4
const ROOM_MARGIN: int = 20
const ENEMY_COLLISION_RADIUS: float = 15.0
const BLOOD_SOURCE_COLLISION_RADIUS: float = 20.0
const PROGRESS_BAR_MAX_VALUE: float = 100.0
const PROGRESS_BAR_DEFAULT_VALUE: float = 0.0

# Hunt level reward constants
const BASE_EXPERIENCE_REWARD: int = 100
const EXPERIENCE_PER_BLOOD_SOURCE: int = 25
const EXPERIENCE_PER_RELIC: int = 50
const BASE_CURRENCY_REWARD: int = 50
const CURRENCY_PER_BLOOD_SOURCE: int = 10
const CURRENCY_PER_RELIC: int = 20
const TIME_BONUS_BASE: float = 1.0

# Hunt level room constants
const ROOM_BACKGROUND_ACTIVE_ALPHA: float = 0.6

# Crafting system constants
const BASE_CRAFTING_SUCCESS_RATE: float = 0.95
const BASE_WINE_QUALITY: float = 0.5
const SKILL_MODIFIER_BASE: float = 1.0
const SKILL_MODIFIER_MULTIPLIER: float = 0.2
const MIN_WINE_QUALITY: float = 0.1
const MAX_WINE_QUALITY: float = 1.0
const XP_PER_QUALITY_WINE: int = 25

# Economy system constants
const MAX_TRANSACTION_HISTORY: int = 100
const DAILY_CYCLE_SECONDS: int = 86400  # 24 hours in seconds
const QUALITY_MULTIPLIER: float = 1.0
const RARITY_MULTIPLIER_BASE: float = 1.0
const RARITY_MULTIPLIER_VARIANCE: float = 0.5
const TIP_MULTIPLIER_BASE: float = 0.1
const TIP_MULTIPLIER_VARIANCE: float = 0.3
const SATISFACTION_THRESHOLD: float = 0.7
const STARTING_CURRENCY: int = 500
const DAILY_EXPENSES: int = 50
const TAX_RATE: float = 0.1
const INSURANCE_COST: int = 25
const REPUTATION_BONUS: float = 0.1
const PATRON_TIP_CHANCE: float = 0.3

# Player data constants
const EXPERIENCE_TO_NEXT_LEVEL: int = 100
const BAR_REPUTATION_DEFAULT: float = 0.0
const TOTAL_PLAY_TIME_DEFAULT: float = 0.0
const HUNT_START_TIME_DEFAULT: float = 0.0
const REPUTATION_THRESHOLD_PREMIUM: float = 25.0
const REPUTATION_THRESHOLD_EXCLUSIVE: float = 50.0
const REPUTATION_THRESHOLD_VIP: float = 75.0
const XP_PER_SUCCESSFUL_HUNT: int = 100
const LEVEL_UP_THRESHOLD_MULTIPLIER: float = 1.5

# Inventory system constants
const INVENTORY_SLOT_DEFAULT: int = -1
const MAX_INVENTORY_SLOTS: int = 50
const MAX_WINE_STORAGE: int = 100
const MAX_BLOOD_SOURCES: int = 200
const MAX_RELICS: int = 25

# Patron manager constants
const DAY_PROGRESS_PEAK_START: float = 0.6
const DAY_PROGRESS_PEAK_END: float = 0.8
const DAY_PROGRESS_QUIET_START: float = 0.2
const DAY_PROGRESS_QUIET_END: float = 0.4
const URGENCY_MULTIPLIER_HIGH: float = 1.5
const URGENCY_MULTIPLIER_MEDIUM: float = 1.3
const REPUTATION_LOSS_PER_PATRON: float = 0.05
const MAX_PATRONS_PER_SCENE: int = 8
const PATRON_PATIENCE_TIME: float = 120.0  # 2 minutes before leaving
const XP_PER_SATISFIED_PATRON: int = 10

# Scene manager constants
const MAX_SCENE_HISTORY: int = 10
const FADE_OVERLAY_ALPHA: float = 0.0
const SCREEN_FADE_DURATION: float = 0.5

# Input mapping constants
const DEFAULT_GAMEPAD_SENSITIVITY: float = 1.0
const DEFAULT_DEADZONE: float = 0.1
const MAX_SENSITIVITY: float = 3.0
const MIN_SENSITIVITY: float = 0.1

# Test scene constants
const PLAYER_MOVEMENT_SPEED: float = 200.0
const DEBUG_PRINT_INTERVAL: int = 60

# IInteractable constants
const DEFAULT_INTERACTION_RANGE: float = 50.0
const DEFAULT_INTERACTION_COOLDOWN: float = 0.5

# Save system constants
const MAX_SAVE_SLOTS: int = 5
const AUTO_SAVE_INTERVAL: float = 300.0  # Auto-save every 5 minutes
const SAVE_VERSION: String = "1.0.0"

# Audio volume constants
const MASTER_VOLUME_DEFAULT: float = 0.8
const MUSIC_VOLUME_DEFAULT: float = 0.6
const SFX_VOLUME_DEFAULT: float = 0.7
const AMBIENT_VOLUME_DEFAULT: float = 0.5

# Scene path constants
const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
const MAIN_HUB_SCENE: String = "res://scenes/hub/main_hub.tscn"
const DESERT_LEVEL_SCENE: String = "res://scenes/hunt/desert_level.tscn"
const NIGHTCLUB_LEVEL_SCENE: String = "res://scenes/hunt/nightclub_level.tscn"
const VAMPIRE_COURT_SCENE: String = "res://scenes/hunt/vampire_court.tscn"

# Resource default constants
const BLOOD_SOURCE_INTENSITY_MULTIPLIER: float = 1.0
const WINE_RECIPE_BUFF_MAGNITUDE: int = 0
const WINE_RECIPE_BUFF_DURATION: float = 0.0
const WINE_RECIPE_SERVE_VALUE: int = 0
const WINE_RECIPE_DRINK_VALUE: int = 0
const WINE_RECIPE_AGING_POTENTIAL: float = 0.0
const WINE_RECIPE_CURRENT_AGE: int = 0
const WINE_RECIPE_QUALITY_SCORE: float = 0.0
const WINE_RECIPE_COMPLEXITY_RATING: int = 0

# Wine quality thresholds
const WINE_RARITY_MYTHIC: float = 15.0
const WINE_RARITY_GRAND_RESERVE: float = 12.0
const WINE_RARITY_RESERVE: float = 8.0
const WINE_RARITY_SELECT: float = 5.0

# Rumor data constants
const RUMOR_REQUIRED_BLOOD_SOURCES: int = 1
const RUMOR_OPTIONAL_BLOOD_SOURCES: int = 2
const RUMOR_DIFFICULTY_MIN: int = 1
const RUMOR_DIFFICULTY_MAX: int = 10
const RUMOR_ESTIMATED_DURATION: float = 15.0
const RUMOR_RECOMMENDED_LEVEL: int = 1
const RUMOR_RELIC_CHANCE: float = 0.0
const RUMOR_PRESTIGE_REWARD: int = 10
const RUMOR_CURRENCY_REWARD: int = 25
const RUMOR_EXPERIENCE_REWARD: int = 50
const RUMOR_REPUTATION_REQUIREMENT: int = 0

# Level difference thresholds
const LEVEL_DIFFERENCE_HIGH: int = 3
const LEVEL_DIFFERENCE_MEDIUM: int = 1
const LEVEL_DIFFERENCE_NONE: int = 0

# Relic data constants
const RELIC_EFFECT_VALUE: float = 0.0
const RELIC_LEVEL_REQUIREMENT: int = 0
const RELIC_PRESTIGE_REQUIREMENT: int = 0

# Patron data constants
const PATRON_MOOD_SWINGS: float = 0.0
const PATRON_PATIENCE_LEVEL: float = 0.5
const PATRON_BASE_TIP_AMOUNT: int = 5
const PATRON_MAX_TIP_AMOUNT: int = 50
const PATRON_VISIT_FREQUENCY: float = 1.0
const PATRON_STAY_DURATION: float = 1.0
const PATRON_LOYALTY_LEVEL: int = 0

# Patron quality bonuses
const PATRON_QUALITY_BONUS_EXCELLENT: float = 2.0
const PATRON_QUALITY_BONUS_GOOD: float = 1.0
const PATRON_QUALITY_BONUS_ACCEPTABLE: float = 1.0
# Additional patron constants for enhanced functionality
# Note: PATRON_SATISFACTION_DECAY and PATRON_TIP_CHANCE are already defined above
# PATRON_SATISFACTION_DECAY is used as a base value for satisfaction loss per event, while PATRON_SATISFACTION_DECAY_RATE determines the rate of continuous satisfaction decrease over time.
# Note: If you add a new constant named PATRON_SATISFACTION_DECAY, clarify its purpose.
# For example:
# const PATRON_SATISFACTION_DECAY: float = 0.1  # Amount satisfaction decreases per event (not per second)
# If both are needed, document the difference clearly above each definition.
# Note: PATRON_TIP_CHANCE is already defined above
