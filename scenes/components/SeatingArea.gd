extends StaticBody2D

## Seating area for Desert Dive Bar (64x64, 2x2 tiles)

@onready var patron_spawn_1: Node2D = $PatronSpawn1
@onready var patron_spawn_2: Node2D = $PatronSpawn2

func setup_area() -> void:
	# Instantiate patron AI at marker positions
	for marker in [patron_spawn_1, patron_spawn_2]:
		var patron = preload("res://scripts/entities/patron_entity.gd").new()
		patron.position = marker.global_position
		get_parent().add_child(patron)
