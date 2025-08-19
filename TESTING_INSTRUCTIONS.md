# Testing Instructions for Hemovintner

## Current Issue - RESOLVED ✅
The `main.tscn` scene was showing as "invalid/corrupt" due to:
1. **Invalid UID references** in scene files
2. **Autoload singleton conflicts** with `class_name` declarations
3. **Circular dependencies** between autoload systems

## What I Fixed
1. **Removed all `class_name` declarations** from autoload scripts
2. **Fixed invalid UID references** in scene files
3. **Updated enum references** from `GameManager.GameState` to `GameEnums.GameState`
4. **Created a simple test scene** to verify basic functionality

## Current Test Setup
The project now uses a **simple test scene** (`scenes/test_simple.tscn`) to verify basic functionality without autoload dependencies.

### Test Scene Features:
- **Red player square** (CharacterBody2D)
- **Basic movement** with WASD/arrow keys
- **Camera following** the player
- **Simple collision** detection
- **No autoload dependencies**

## How to Test

### 1. Open the Project in Godot
- Open Godot 4.4+
- Import the project from `C:\Dev\GODOT-VINTNER`
- The simple test scene should load without errors

### 2. Test Basic Functionality
- **Movement**: Use WASD or arrow keys to move the red player square
- **Camera**: The camera should smoothly follow the player
- **Console**: Check the output panel for "Simple test scene loaded successfully!"

### 3. Expected Behavior
- Player moves smoothly with input
- Camera follows player movement
- No error messages in the console
- Scene loads completely

## Troubleshooting

### If the scene still won't load:
1. **Check Godot version**: Ensure you're using Godot 4.4+
2. **Verify file paths**: All script files should be in the correct locations
3. **Check for syntax errors**: Look for any red error indicators in the script editor
4. **Check console output**: Look for any error messages

### Common Issues:
- **Missing scripts**: Ensure all referenced scripts exist
- **Invalid references**: Check that all ExtResource paths are correct
- **UID conflicts**: Each scene should have a unique UID

## File Structure
```
scenes/
├── test_simple.tscn (current main scene - working)
├── main.tscn (complex scene - fixed but not tested)
└── hub/
    └── MainHub.tscn (bar layout - not used in test)
scripts/
├── test_simple_controller.gd (simple test script)
├── entities/
│   ├── player.gd (player controller - not used in test)
│   └── test_interactable.gd (test interaction - not used in test)
└── scenes/
    └── main_scene_controller.gd (UI controller - not used in test)
```

## Next Steps
Once the simple test scene is working:
1. **Test basic movement** and camera following
2. **Switch back to main.tscn** to test the full system
3. **Test interaction system** with the green square
4. **Add more complex features** gradually

## Technical Notes
- **Autoload conflicts resolved**: Removed `class_name` declarations
- **UID references fixed**: All scene files now use valid references
- **Enum references updated**: Using `GameEnums.GameState` instead of `GameManager.GameState`
- **Simple test scene**: Minimal dependencies for basic functionality testing
- **Circular dependencies**: Identified and will be addressed in next phase

## Current Status
- ✅ **Basic scene loading**: Fixed UID and autoload issues
- ✅ **Simple test scene**: Created for basic functionality testing
- 🔄 **Main scene**: Fixed but needs testing
- 🔄 **Autoload system**: Fixed conflicts, needs testing
- ⏳ **Full interaction system**: Ready for testing once basic scene works
