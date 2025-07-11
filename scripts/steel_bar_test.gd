extends Node2D	# originally SwingObject2D

@export var steel_tile_scene: PackedScene
@export var tile_count: int = 8

var tiles: Array = []
var cumulative_width := 0.0

# The former physics collider is kept only as an Area2D for hit‑detection
@onready var hitbox: Area2D = $hitbox				# (Hitbox/CollisionShape2D in the scene)

func _ready() -> void:
	# Build the bar from individual tiles
	for i in tile_count:
		var tile := steel_tile_scene.instantiate()
		tile.position.x = cumulative_width
		add_child(tile)
		tiles.append(tile)
		cumulative_width += tile.initial_width

		# Listen when the tile deforms so we can realign
		tile.connect("deformed", Callable(self, "_on_tile_deformed"))

	# Resize the monitoring hitbox to cover the whole bar (not physics active)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(cumulative_width, 2)
	hitbox.get_node("CollisionShape2D").shape = shape
	hitbox.position.x = cumulative_width * 0.5
	hitbox.monitoring = true
	hitbox.set_collision_layer_value(1, false)	# ensure it is NOT on any physics layer
	hitbox.set_collision_mask_value(1, false)

func _on_tile_deformed() -> void:
	_realign_tiles()

func _realign_tiles() -> void:
	var next_x := 0.0
	for tile in tiles:
		tile.position.x = next_x
		next_x += tile.current_width

	# Stretch the monitoring hitbox to new total width
	hitbox.position.x = next_x * 0.5
	hitbox.get_node("CollisionShape2D").shape.size.x = next_x

func update_value_and_quality() -> void:
	# (unchanged –– omitted for brevity, copy your existing implementation here)
	pass

var previous_tile: RigidBody2D = null

func link_tiles(new_tile: RigidBody2D) -> void:
	if previous_tile:
		var joint := PinJoint2D.new()
		joint.global_position = (new_tile.global_position + previous_tile.global_position) / 2
		add_child(joint)
		joint.node_a = previous_tile.get_path()
		joint.node_b = new_tile.get_path()
	previous_tile = new_tile
