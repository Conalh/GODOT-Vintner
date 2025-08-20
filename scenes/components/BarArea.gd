extends StaticBody2D

## Bar area for Desert Dive Bar (96x64, 3x2 tiles)

@onready var bar_counter_marker: Node2D = $BarCounterMarker

func setup_area() -> void:
	# Instantiate BarCounter at marker position
	var bar_counter = preload("res://scripts/entities/bar_counter.gd").new()
	bar_counter.position = bar_counter_marker.global_position
	get_parent().add_child(bar_counter)
