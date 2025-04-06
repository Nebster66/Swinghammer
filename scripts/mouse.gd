extends Node2D

var open = preload("res://sprites/TongsOpen.png")
var closed = preload("res://sprites/TongsClosed.png")

var cursor_size = 128  # Change this to adjust the cursor size
var original_size = 32  # Original image size
var original_hotspot = Vector2(3, 3)  # Hotspot in the original 32x32 image

func _ready() -> void:
	set_cursor(open)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			set_cursor(closed)
		elif event.is_released():
			set_cursor(open)

# Function to set the cursor with correct scaling and hotspot
func set_cursor(texture: Texture2D) -> void:
	var scaled_texture = scale_texture(texture, cursor_size, cursor_size)
	var hotspot = original_hotspot * (cursor_size / float(original_size))  # Scale hotspot proportionally
	Input.set_custom_mouse_cursor(scaled_texture, Input.CURSOR_ARROW, hotspot)

# Function to scale the texture while preserving pixel art
func scale_texture(texture: Texture2D, new_width: int, new_height: int) -> ImageTexture:
	var image = texture.get_image()  # Extract image data
	image.convert(Image.FORMAT_RGBA8)  # Ensure format is compatible
	image.resize(new_width, new_height, Image.INTERPOLATE_NEAREST)  # Use nearest-neighbour scaling
	var new_texture = ImageTexture.create_from_image(image)
	return new_texture
