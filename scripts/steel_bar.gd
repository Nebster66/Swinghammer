@warning_ignore("missing_tool")
extends SwingObject2D

@export var steel_tile_scene: PackedScene
@export var tile_count: int = 8

var tiles = []
var comulative_width = 0

@onready var collider: CollisionShape2D = $CollisionShape2D

var value: int = 0
var quality_modifier: float

func _ready():
	for i in range(tile_count):
		var tile_instance = steel_tile_scene.instantiate()
		tile_instance.position = Vector2(comulative_width, 0)
		comulative_width += tile_instance.initial_width
		add_child(tile_instance)
		tiles.append(tile_instance)

	if collider and collider.shape is RectangleShape2D:
		var new_shape = RectangleShape2D.new()
		new_shape.size = Vector2(comulative_width, 2)
		collider.shape = new_shape
		collider.position.x = (comulative_width / 2) - 1

# NOTE: Now only called externally (e.g. from sell area)
func update_value_and_quality():
	value = tiles.size()

	# Size quality
	var width_values = []
	for tile in tiles:
		width_values.append(tile.current_width)

	var min_w = width_values.min()
	var max_w = width_values.max()
	var size_variance = max_w - min_w

	var size_quality: float
	if size_variance <= 0.1:
		size_quality = 1.0
	elif size_variance <= 0.4:
		size_quality = 1.0
	else:
		size_quality = 0.5

	# Quenching quality - based on quench stage
	var stage3_quenched = 0
	var stage2_quenched = 0

	for tile in tiles:
		if tile.was_quenched_when_hot:
			if tile.quench_stage == 3:
				stage3_quenched += 1
			elif tile.quench_stage == 2:
				stage2_quenched += 1

	var total_quenched = stage2_quenched + stage3_quenched
	var quenching_quality: float

	if total_quenched == tiles.size():
		# Fully quenched, scale based on heat quality
		var stage3_ratio = float(stage3_quenched) / tiles.size()
		quenching_quality = lerp(1.5, 2.0, stage3_ratio)
	elif total_quenched == 0:
		quenching_quality = 1.0
	else:
		# Partial quench, lower value
		var stage3_ratio = float(stage3_quenched) / tiles.size()
		quenching_quality = lerp(1.0, 1.5, stage3_ratio)


	# Sharpness quality
	var total_sharpness = 0.0
	var sharpness_values = []

	for tile in tiles:
		total_sharpness += tile.sharpness
		sharpness_values.append(tile.sharpness)

	var avg_sharpness = total_sharpness / tiles.size()
	var sharpness_variance = sharpness_values.max() - sharpness_values.min()

	var sharpening_quality: float
	if avg_sharpness >= 0.9 and sharpness_variance <= 0.1:
		sharpening_quality = 2.0
	elif avg_sharpness >= 0.5:
		sharpening_quality = 1.5
	else:
		sharpening_quality = 1.0

	# Final quality modifier
	quality_modifier = (size_quality + quenching_quality + sharpening_quality) / 3.0

	print("Size Quality:", size_quality)
	print("Quenching Quality:", quenching_quality)
	print("Sharpening Quality:", sharpening_quality)
	print("Quality Modifier:", quality_modifier)

func _on_body_entered(body):
	if body.is_in_group("hammer"):
		for child in body.get_children():
			if child is CollisionPolygon2D and child.name == "Head":
				var hammer_head = child
				var hit_position = _get_polygon_center(hammer_head, body)

				var closest_tile = _get_closest_tile(hit_position)
				if closest_tile:
					closest_tile.deform()
					_realign_tiles()
				break

func _get_polygon_center(polygon: CollisionPolygon2D, parent: Node2D) -> Vector2:
	var global_points = []
	for point in polygon.polygon:
		global_points.append(parent.to_global(point))

	var center = Vector2.ZERO
	for p in global_points:
		center += p
	center /= global_points.size()
	return center

func _get_closest_tile(hit_position: Vector2) -> StaticBody2D:
	var closest : StaticBody2D = null
	var shortest_distance : float = INF

	for tile in tiles:
		var current_distance = hit_position.distance_squared_to(tile.global_position)
		if current_distance < shortest_distance:
			shortest_distance = current_distance
			closest = tile

	return closest

func _realign_tiles():
	var next_x = 0
	for tile in tiles:
		tile.position.x = next_x
		next_x += tile.current_width

	if collider and collider.shape is RectangleShape2D:
		collider.shape.size = Vector2(next_x, 2)
		collider.position.x = (next_x / 2) - 1
