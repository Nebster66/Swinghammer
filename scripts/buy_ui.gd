extends StaticBody2D

signal purchase

@onready var label: Label = $"../BuySellUI/Length"
@onready var ui: Control = $"../../UI/UI"

@export var steel_bar_scene: PackedScene
@export var steel_bar_parent: NodePath # Path to where you want to instance the bar, e.g., "../Bars"

var tiles: int = 1

func _on_h_slider_value_changed(value: int) -> void:
	tiles = value
	label.set_text(str(value))

func _on_confirm_pressed() -> void:
	# Assuming 'tiles' represents a price in whole dollars,
	# convert it to cents for comparison.
	var tiles_in_cents = int(tiles * 100.0 + 0.5)

	if steel_bar_scene and ui.money_total_cents >= tiles_in_cents: # <--- CHANGED HERE
		purchase.emit(tiles)
		var steel_bar_instance = steel_bar_scene.instantiate()
		steel_bar_instance.tile_count = tiles

		var parent_node = get_node(steel_bar_parent)
		if parent_node:
			parent_node.add_child(steel_bar_instance)

			var local_spawn_offset = Vector2(-9, -10)
			steel_bar_instance.global_position = global_position + local_spawn_offset
			steel_bar_instance.z_index = -1
		else:
			push_error("Invalid steel_bar_parent path")
	else:
		if not steel_bar_scene:
			push_error("SteelBar scene is not assigned")
		elif ui.money_total_cents < tiles_in_cents: # <--- AND HERE
			push_error("Not enough money to purchase steel bar")
