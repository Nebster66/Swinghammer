extends Camera2D

@onready var game_target = $"../GameMarker"
@onready var menu_target: Marker2D = $"../MainMenuMarker"

var mobile = false

# Adjustable values
var edge_scroll_speed := 200.0  # Pixels per second
var edge_margin := 50           # Distance from screen edge to start scrolling
var min_x = -175
var max_x = 175

func _process(delta: float) -> void:
	if mobile:
		var viewport_size = get_viewport().get_visible_rect().size
		var half_visible_width = (viewport_size.x / zoom.x) / 2.0  # Divide by zoom, not multiply!
		var left_limit = min_x + half_visible_width
		var right_limit = max_x - half_visible_width

		var mouse_pos = get_viewport().get_mouse_position()

		# Scroll Left
		if mouse_pos.x <= edge_margin:
			position.x -= edge_scroll_speed * delta

		# Scroll Right
		elif mouse_pos.x >= viewport_size.x - edge_margin:
			position.x += edge_scroll_speed * delta

		# Clamp the camera to stop its edges from going past min/max
		position.x = clamp(position.x, left_limit, right_limit)



func _on_main_menu_start_game() -> void:
	var target_position = game_target.position

	var tween = create_tween()

	if OS.has_feature("web_android") or OS.has_feature("web_ios"):
		target_position.y += 30
		mobile = true
		print("Running on Web Mobile")

		# First move
		tween.tween_property(self, "position", target_position, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		# Then zoom in
		tween.tween_property(self, "zoom", zoom * 2, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	elif OS.has_feature("windows"):
		print("Running on Windows")
		
		# Just move, no zoom
		tween.tween_property(self, "position", target_position, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	elif OS.has_feature("web_windows"):
		print("Running on Web Windows")
		
		# Optionally allow zoom for web browser, if testing mobile-like view
		#target_position.y += 30
		#mobile = true
		tween.tween_property(self, "position", target_position, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		#tween.tween_property(self, "zoom", zoom * 2, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	else:
		print("Not using mobile")

		# Default fallback
		tween.tween_property(self, "position", target_position, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)



func _on_menu_button_menu_return() -> void:
	var tween = create_tween()
	
	# Return to main menu marker
	tween.tween_property(self, "position", menu_target.position, 1.5)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
