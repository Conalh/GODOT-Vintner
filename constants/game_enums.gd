class_name GameEnums
extends Resource

## Game-wide enums for Hemovintner

## Blood source types for crafting
enum BloodType {
	HUMAN,          # Human blood
	VAMPIRE,        # Vampire blood
	ANIMAL,         # Animal blood
	MYTHICAL,       # Mythical creature blood
	SYNTHETIC       # Artificial blood substitute
}

## Emotional notes that affect wine quality
enum EmotionalNote {
	JOY,            # Happiness and celebration
	SORROW,         # Sadness and melancholy
	RAGE,           # Anger and passion
	FEAR,           # Anxiety and tension
	LOVE,           # Romance and affection
	LUST,           # Desire and sensuality
	PRIDE,          # Confidence and arrogance
	ENVY,           # Jealousy and covetousness
	WRATH,          # Vengeance and hatred
	SLOTH           # Lethargy and apathy
}

## Virtues that provide stat bonuses
enum Virtue {
	STRENGTH,       # Physical power
	AGILITY,        # Speed and dexterity
	INTELLIGENCE,   # Mental acuity
	WISDOM,         # Knowledge and insight
	CHARISMA,       # Social influence
	CONSTITUTION,   # Health and endurance
	LUCK,           # Fortune and chance
	MAGIC,          # Supernatural power
	STEALTH,        # Concealment and subtlety
	RESISTANCE      # Defense against effects
}

## Game zones for progression
enum GameZone {
	DESERT_DIVE,    # Starting zone - desert dive bar
	NIGHTCLUB,      # Mid-game zone - nightclub
	VAMPIRE_COURT   # End-game zone - vampire court
}

## Scene types for management
enum SceneType {
	HUB,            # Bar management scenes
	HUNT,           # Action-platformer scenes
	MENU,           # UI menu scenes
	TRANSITION      # Scene transition scenes
}

## Patron personality types
enum PatronPersonality {
	ARISTOCRATIC,   # High-class, demanding
	BOHEMIAN,       # Artistic, unpredictable
	BUSINESS,       # Professional, consistent
	CRIMINAL,       # Dangerous, lucrative
	MYSTIC,         # Supernatural, mysterious
	PARTY_GOER,     # Social, easy-going
	LONER,          # Solitary, particular
	REGULAR         # Familiar, reliable
}

## Patron needs that drive behavior
enum PatronNeed {
	BLOOD_WINE,     # Primary drink requirement
	COMPANIONSHIP,  # Social interaction
	ENTERTAINMENT,  # Amusement and distraction
	PRIVACY,        # Seclusion and discretion
	STATUS,         # Recognition and respect
	EXCITEMENT,     # Thrills and danger
	COMFORT,        # Relaxation and security
	INSPIRATION     # Creative stimulation
}

## Wine quality ratings
enum WineQuality {
	ABYSMAL,        # Terrible quality
	POOR,           # Low quality
	AVERAGE,        # Standard quality
	GOOD,           # Above average
	EXCELLENT,      # High quality
	MASTERPIECE,    # Exceptional quality
	LEGENDARY       # Perfect quality
}

## Game states for management
enum GameState {
	MENU,           # Main menu
	HUB,            # Bar management
	HUNT,           # Action gameplay
	PAUSED,         # Game paused
	TRANSITIONING,  # Between scenes
	SAVING,         # Save operation
	LOADING         # Load operation
}

## Inventory item types
enum ItemType {
	BLOOD_SOURCE,   # Blood ingredients
	WINE,           # Crafted wines
	RELIC,          # Special items
	TOOL,           # Crafting tools
	CURRENCY,       # Money and valuables
	CONSUMABLE      # Temporary items
}

## Crafting station types
enum CraftingStation {
	BLOOD_EXTRACTOR, # Extract blood from sources
	WINE_PRESS,      # Press and ferment
	AGING_BARREL,    # Age and mature wines
	BLENDING_VAT,    # Mix and blend
	BOTTLING_STATION # Package final product
}

## Interactable object types
enum InteractableType {
	DOOR,           # Scene transitions
	COUNTER,        # Bar serving
	BENCH,          # Crafting stations
	STORAGE,        # Inventory access
	NPC,            # Character interaction
	DECORATION      # Environmental objects
}
