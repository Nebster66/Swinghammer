@warning_ignore("missing_tool")
extends SwingObject2D

@export var steel_tile_scene: PackedScene
@export var tile_count: int = 8

var tiles = []  # Store references to tiles
var comulative_width = 0

@onready var collider: CollisionShape2D = $CollisionShape2D

func _ready():
	# Create tile instances
	for i in range(tile_count):
		var tile_instance = steel_tile_scene.instantiate()
		
		# Set location based on prior tiles' widths
		tile_instance.position = Vector2(comulative_width, 0)
		comulative_width += tile_instance.initial_width
		add_child(tile_instance)
		tiles.append(tile_instance)
	
	# Adjust the CollisionShape2D size and position
	if collider and collider.shape is RectangleShape2D:
		# Ensure each instance has a unique shape
		var new_shape = RectangleShape2D.new()
		new_shape.size = Vector2(comulative_width, 2)
		collider.shape = new_shape  # Assign a unique shape
		collider.position.x = (comulative_width / 2) - 1

# Handle hammer collision
func _on_body_entered(body):
	if body.is_in_group("hammer"):
		#print("hammer detected")
		# Ensure we are checking for the correct collider
		for child in body.get_children():
			if child is CollisionPolygon2D and child.name == "Head":
				#print("Head detected")
				
				var hammer_head = child  # Reference the "Head" collider
				var hit_position = _get_polygon_center(hammer_head, body)  # Get actual collision position

				#print("Hit position:", hit_position)  # Debugging

				var closest_tile = _get_closest_tile(hit_position)  # Find the closest tile
				if closest_tile:
					closest_tile.deform()
					_realign_tiles()
				break  # Stop looping once we find "Head"

# Get the global position of the average point of the CollisionPolygon2D
func _get_polygon_center(polygon: CollisionPolygon2D, parent: Node2D) -> Vector2:
	var global_points = []
	for point in polygon.polygon:
		global_points.append(parent.to_global(point))  # Convert local points to global coordinates

	# Find the centroid (average position of all points)
	var center = Vector2.ZERO
	for p in global_points:
		center += p
	center /= global_points.size()  # Average of all points

	return center  # Return the computed global position

# Find the closest tile to the hit position
func _get_closest_tile(hit_position: Vector2) -> StaticBody2D:
	var closest : StaticBody2D = null
	var shortest_distance : float = INF  # Start with a very large distance

	for tile in tiles:
		var current_distance = hit_position.distance_squared_to(tile.global_position)  # Use squared distance for efficiency
		if current_distance < shortest_distance:
			shortest_distance = current_distance
			closest = tile

	return closest

func _realign_tiles():
	var next_x = 0

	for tile in tiles:
		tile.position.x = next_x  # Explicitly position each tile
		next_x += tile.current_width  # Accumulate width in a fixed manner

	# Adjust collider size
	if collider and collider.shape is RectangleShape2D:
		collider.shape.size = Vector2(next_x, 2)
		collider.position.x = (next_x / 2) - 1
