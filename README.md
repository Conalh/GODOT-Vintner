# Hemovintner

A Gothic modern vampire game combining bar management with action-platformer gameplay.

## Project Structure

```
GODOT-Vintner/
├── project.godot                 # Main project configuration
├── README.md                     # This file
├── WorkReadme.md                 # Development work log
├── autoloads/                    # Singleton autoload scripts
│   ├── game_manager.gd          # Core game state and transitions
│   ├── data_manager.gd          # Data persistence and loading
│   ├── inventory_system.gd      # Inventory and item management
│   ├── economy_system.gd        # Currency and bar income
│   ├── crafting_system.gd       # Wine crafting logic
│   ├── player_data.gd           # Player stats and progression
│   ├── scene_manager.gd         # Scene transitions and management
│   └── patron_manager.gd        # Patron AI and behavior
├── resources/                    # Custom Resource classes
│   ├── blood_source.gd          # Blood ingredient definitions
│   ├── wine_recipe.gd           # Wine crafting recipes
│   ├── patron_data.gd           # Patron personality and needs
│   ├── game_config.gd           # Game-wide configuration
│   └── save_data.gd             # Save/load data structures
├── scenes/                       # Game scenes
│   ├── hub/                     # Hub scenes (bar management)
│   │   ├── main_hub.tscn        # Main bar scene
│   │   ├── crafting_bench.tscn  # Wine crafting interface
│   │   └── bar_counter.tscn     # Bar serving interface
│   ├── hunt/                    # Hunt scenes (action-platformer)
│   │   ├── desert_level.tscn    # Desert dive bar zone
│   │   ├── nightclub_level.tscn # Nightclub zone
│   │   └── vampire_court.tscn   # Vampire court zone
│   ├── ui/                      # User interface scenes
│   │   ├── main_menu.tscn       # Main menu
│   │   ├── hud.tscn             # In-game HUD
│   │   └── pause_menu.tscn      # Pause menu
│   └── components/              # Reusable scene components
│       ├── patron.tscn          # Base patron scene
│       ├── interactable.tscn    # Base interactable object
│       └── door_transition.tscn # Scene transition doors
├── scripts/                      # GDScript files
│   ├── components/              # Component scripts
│   │   ├── patron_needs.gd      # Patron needs system
│   │   ├── patron_personality.gd # Patron personality traits
│   │   ├── patron_behavior.gd   # Patron AI behavior
│   │   └── interactable.gd      # Base interactable interface
│   ├── entities/                # Entity scripts
│   │   ├── player.gd            # Player character
│   │   ├── patron.gd            # Patron base class
│   │   └── npc.gd               # Non-patron NPCs
│   └── systems/                 # System scripts
│       ├── procedural_gen.gd    # Level generation
│       ├── audio_manager.gd     # Audio system
│       └── effects_manager.gd   # Visual effects
├── assets/                       # Game assets
│   ├── sprites/                 # 2D sprites and textures
│   ├── models/                  # 3D models (if applicable)
│   ├── audio/                   # Sound effects and music
│   ├── fonts/                   # Typography
│   └── icons/                   # UI icons
├── constants/                    # Game constants and enums
│   ├── game_enums.gd            # Game-wide enums
│   ├── game_constants.gd        # Game constants
│   └── input_mapping.gd         # Input configuration
└── tests/                       # Test scenes and scripts
    ├── unit_tests/              # Unit test scripts
    └── integration_tests/       # Integration test scenes
```

## Architecture Overview

### Autoload Hierarchy (Dependency Order)

1. **DataManager** - Base data persistence (no dependencies)
2. **PlayerData** - Player progression (depends on DataManager)
3. **InventorySystem** - Item management (depends on DataManager)
4. **EconomySystem** - Currency system (depends on DataManager, PlayerData)
5. **CraftingSystem** - Wine crafting (depends on InventorySystem, EconomySystem)
6. **PatronManager** - Patron AI (depends on DataManager, PlayerData)
7. **SceneManager** - Scene transitions (depends on DataManager)
8. **GameManager** - Core game state (depends on all other systems)

### Core Systems

- **Hub-and-Spoke Scene Architecture**: Separate hub (bar management) and hunt (action-platformer) scenes
- **Cross-Scene Data Persistence**: All game state maintained through autoload singletons
- **Bar Income Banking**: Earnings locked during hunts, delivered on return
- **Component-Based Patron System**: Modular patron behavior and needs

### Design Principles

- **SOLID Principles**: Single responsibility, open/closed, Liskov substitution, interface segregation, dependency inversion
- **Clean Code**: Readable naming, small functions, comprehensive error handling
- **Modern Godot 4**: Typed GDScript, custom resources, signal-based communication
- **Performance**: Memory efficiency, minimal per-frame operations, proper cleanup

## Development Guidelines

- All public methods must have XML documentation (`##` comments)
- Maximum function length: 20 lines
- Full static typing with `->` return types
- No magic numbers - use constants/enums
- Comprehensive error handling - never fail silently
- Component composition over inheritance
- Loose coupling through signals and dependency injection
