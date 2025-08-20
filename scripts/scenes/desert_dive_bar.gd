class_name DesertDiveBar
extends Node2D

## Main Desert Dive Bar scene controller
## Manages tile-based layout and component integration

@onready var map_tiles: Node2D = $MapTiles
@onready var interactive_stations: Node2D = $InteractiveStations
@onready var patron_spawns: Node2D = $PatronSpawns
@onready var lighting: Node2D = $Lighting

func _ready() -> void:
	_setup_bar_atmosphere()
	_initialize_stations()

func _setup_bar_atmosphere() -> void:
	## Configure desert dive bar lighting and ambience
	pass

func _initialize_stations() -> void:
	## Setup interactive stations from tile markers
	_find_and_setup_tile_components()

func _find_and_setup_tile_components() -> void:
	## Scan MapTiles for BarArea and SeatingArea instances
	## Call their setup_area() methods to spawn components
	for child in map_tiles.get_children():
		if child.has_method("setup_area"):
			child.setup_area()
