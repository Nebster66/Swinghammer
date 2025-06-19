extends Camera2D

@onready var game_target: Marker2D = $"../GameMarker"
@onready var menu_target: Marker2D = $"../MainMenuMarker"
@onready var access_ui: Button = $"../../Inside/BuySellUI/AccessUI"
@onready var main_menu: Control = $"../../Menu/MainMenu"
@onready var day_summary: Control = $"../../Menu/DaySummary"

# --- State Variables ---
# NEW: Define explicit positions for each state. We'll set these in _ready().
var zoomed_in_position_y_offset: float = 30.0 # This is the Y offset for zoomed-in state
var default_zoomed_out_position: Vector2 # The default position when zoomed out (usually game_target.position)

var zoomed_out_level := Vector2(4, 4)
var zoomed_in_level := Vector2(8, 8) # Equivalent to original 'zoom * 2' for initial mobile zoom

var is_mobile := false
var is_pc := false
var is_zoomed_in := false

# --- Edge Scrolling Variables ---
var edge_scroll_speed := 200.0
var edge_margin := 50
var min_x := -160.0 # Ensure these are floats for calculations
var max_x := 160.0 # Ensure these are floats for calculations

func _ready() -> void:
	# Set initial camera properties
	zoom = zoomed_out_level
	
	# --- NEW: Calculate and store the default zoomed-out position once game_target is ready ---
	default_zoomed_out_position = game_target.position
	
	# Determine platform
	if OS.has_feature("windows") or OS.has_feature("web_windows"):
		is_pc = true
	elif OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("android"):
		is_mobile = true

func _unhandled_input(event: InputEvent) -> void:
	if not is_pc or get_tree().paused:
		return

	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and not is_zoomed_in:
			is_zoomed_in = true
			# Create a tween. Set the transition and ease for the entire tween sequence.
			var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			
			# Get mouse position in screen coordinates
			var mouse_screen_pos = get_viewport().get_mouse_position()
			# Convert mouse screen position to world coordinates.
			var mouse_world_pos = get_canvas_transform().affine_inverse() * mouse_screen_pos
			
			# Calculate the target Y position with the fixed offset for the zoomed-in state.
			var target_y_pos = game_target.position.y + zoomed_in_position_y_offset
			
			# --- Calculate clamping limits for the zoomed-in state ---
			var viewport_size = get_viewport().get_visible_rect().size
			# Calculate half_visible_width when zoomed in (using the target zoomed_in_level)
			var half_visible_width_zoomed_in = (viewport_size.x / zoomed_in_level.x) / 2.0
			
			var left_limit_zoomed_in = min_x + half_visible_width_zoomed_in
			var right_limit_zoomed_in = max_x - half_visible_width_zoomed_in
			
			# Clamp the target X position based on the mouse's world X and the zoomed-in limits.
			var target_x_pos = clamp(mouse_world_pos.x, left_limit_zoomed_in, right_limit_zoomed_in)
			
			# Combine to form the final target position for the camera.
			var target_camera_pos = Vector2(target_x_pos, target_y_pos)
			
			# Tween the zoom level.
			tween.tween_property(self, "zoom", zoomed_in_level, 1.0)
			# Tween the camera position to the calculated target. This will run in parallel with the zoom.
			tween.parallel().tween_property(self, "position", target_camera_pos, 0.5)

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and is_zoomed_in:
			is_zoomed_in = false
			# Create a tween for zooming out.
			var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			# Tween the zoom level back to the zoomed-out state.
			tween.tween_property(self, "zoom", zoomed_out_level, 1.0)
			# Move back to the default, centered position (game_target's position). This runs in parallel with the zoom.
			tween.parallel().tween_property(self, "position", default_zoomed_out_position, 0.5)
			access_ui.button_pressed = false

func _process(delta: float) -> void:
	# Only perform edge scrolling if currently zoomed in.
	if is_zoomed_in:
		# Recalculate half_visible_width based on the current zoom level.
		var viewport_size = get_viewport().get_visible_rect().size
		var half_visible_width = (viewport_size.x / zoom.x) / 2.0 # Use current zoom.x
		
		var left_limit = min_x + half_visible_width
		var right_limit = max_x - half_visible_width
		
		var mouse_pos = get_viewport().get_mouse_position()
		
		# Edge scrolling logic: move camera based on mouse position near screen edges.
		if mouse_pos.x <= edge_margin:
			position.x -= edge_scroll_speed * delta
		elif mouse_pos.x >= viewport_size.x - edge_margin:
			position.x += edge_scroll_speed * delta
		
		# Clamp the camera's x position to prevent it from going beyond the defined limits.
		position.x = clamp(position.x, left_limit, right_limit)

func _on_main_menu_start_game() -> void:
	# Create a tween. Set the transition and ease for the entire tween sequence.
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	if is_mobile:
		# For mobile, set the state to zoomed in.
		is_zoomed_in = true
		# Calculate the target position for mobile (game_target's X, plus Y offset).
		var mobile_zoomed_in_target = Vector2(game_target.position.x, game_target.position.y + zoomed_in_position_y_offset)
		
		# --- MOBILE START SEQUENCE: Lower first, THEN zoom in ---
		# First, tween the position to the target, lowering the camera.
		tween.tween_property(self, "position", mobile_zoomed_in_target, 1.5)
		# After the position tween completes, this tween will start, zooming the camera in.
		tween.tween_property(self, "zoom", zoomed_in_level, 1.5)
	else: # is_pc (or any other platform not explicitly mobile)
		# For PC, ensure the state is zoomed out.
		is_zoomed_in = false 
		# Tween the position to the default zoomed-out target (game_target's position).
		tween.tween_property(self, "position", default_zoomed_out_position, 1.5)
		# Tween the zoom level to the default zoomed-out level. This runs in parallel with the position tween.
		tween.parallel().tween_property(self, "zoom", zoomed_out_level, 1.5)

func _on_menu_button_menu_return() -> void:
	main_menu.show()
	day_summary.hide()
	
	# Create a tween for returning to the menu.
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	access_ui.button_pressed = false
	
	# Tween the camera position back to the main menu marker.
	tween.tween_property(self, "position", menu_target.position, 1.5)
	
	# If currently zoomed in, also tween the zoom level back to zoomed out.
	# This runs in parallel with the position tween.
	if is_zoomed_in:
		tween.parallel().tween_property(self, "zoom", zoomed_out_level, 1.5)
		is_zoomed_in = false # Update state after zooming out


func _on_day_summary_start_game() -> void:
	# Create a tween. Set the transition and ease for the entire tween sequence.
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	if is_mobile:
		# For mobile, set the state to zoomed in.
		is_zoomed_in = true
		# Calculate the target position for mobile (game_target's X, plus Y offset).
		var mobile_zoomed_in_target = Vector2(game_target.position.x, game_target.position.y + zoomed_in_position_y_offset)
		
		# --- MOBILE START SEQUENCE: Lower first, THEN zoom in ---
		# First, tween the position to the target, lowering the camera.
		tween.tween_property(self, "position", mobile_zoomed_in_target, 1.5)
		# After the position tween completes, this tween will start, zooming the camera in.
		tween.tween_property(self, "zoom", zoomed_in_level, 1.5)
	else: # is_pc (or any other platform not explicitly mobile)
		# For PC, ensure the state is zoomed out.
		is_zoomed_in = false 
		# Tween the position to the default zoomed-out target (game_target's position).
		tween.tween_property(self, "position", default_zoomed_out_position, 1.5)
		# Tween the zoom level to the default zoomed-out level. This runs in parallel with the position tween.
		tween.parallel().tween_property(self, "zoom", zoomed_out_level, 1.5)


func _on_end_day_button_menu_return() -> void:
	main_menu.hide()
	day_summary.show()
	
	# Create a tween for returning to the menu.
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	access_ui.button_pressed = false
	
	# Tween the camera position back to the main menu marker.
	tween.tween_property(self, "position", menu_target.position, 1.5)
	
	# If currently zoomed in, also tween the zoom level back to zoomed out.
	# This runs in parallel with the position tween.
	if is_zoomed_in:
		tween.parallel().tween_property(self, "zoom", zoomed_out_level, 1.5)
		is_zoomed_in = false # Update state after zooming out
