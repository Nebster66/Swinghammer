extends StaticBody2D

signal purchase

@onready var buy_button: Button = $BuyUI/BuyButton
@onready var confirm: Button = $BuyUI/Confirm
@onready var h_slider: HSlider = $BuyUI/HSlider
@onready var label: Label = $BuyUI/Label

@export var steel_bar_scene: PackedScene
@export var steel_bar_parent: NodePath # Path to where you want to instance the bar, e.g., "../Bars"

var tiles: int = 1
var vis: bool = false

func _ready() -> void:
	h_slider.visible = false
	confirm.visible = false
	label.visible = false

func _on_h_slider_value_changed(value: int) -> void:
	tiles = value
	label.set_text(str(value))

func _on_buy_button_pressed() -> void:
	vis = !vis
	h_slider.visible = vis
	confirm.visible = vis
	label.visible = vis

func _on_confirm_pressed() -> void:
	h_slider.visible = false
	confirm.visible = false
	label.visible = false
	vis = false

	purchase.emit(tiles)
	
	if steel_bar_scene:
		var steel_bar_instance = steel_bar_scene.instantiate()
		steel_bar_instance.tile_count = tiles

		var parent_node = get_node(steel_bar_parent)
		if parent_node:
			parent_node.add_child(steel_bar_instance)

			# Set position above this node (the Purchase node)
			var local_spawn_offset = Vector2(0, -10)  # Adjust vertical offset as needed
			steel_bar_instance.global_position = global_position + local_spawn_offset

			# Set correct Z index
			steel_bar_instance.z_index = -1
		else:
			push_error("Invalid steel_bar_parent path")
	else:
		push_error("SteelBar scene is not assigned")
