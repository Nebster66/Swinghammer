extends Camera2D

signal transition_complete

@onready var game_target: Marker2D = $"../GameMarker"
@onready var menu_target: Marker2D = $"../MainMenuMarker"
@onready var access_ui: Button = $"../../Inside/BuySellUI/AccessUI"
@onready var main_menu: Control = $"../../Menu/MainMenu"
@onready var day_summary: Control = $"../../Menu/DaySummary"

# --- State Variables ---
var zoomed_in_position_y_offset: float = 30.0
var default_zoomed_out_position: Vector2

var zoomed_out_level := Vector2(4, 4)
var zoomed_in_level := Vector2(8, 8)

var vertical_offset_tolerance := 0.20	# <- 5 % wiggle room

var is_mobile := false
var is_pc := false
var is_zoomed_in := false
var is_transitioning := false
var is_in_game_view := false

# --- Auto vertical zoom tracking ---
var auto_vertical_zoom_applied := false
var auto_vertical_zoom_offset := Vector2(0, zoomed_in_position_y_offset)

# --- Edge Scrolling Variables ---
var edge_scroll_speed := 200.0
var edge_margin := 100
var min_x := -160.0
var max_x := 160.0
var min_y := 96
var max_y := -432

var previous_viewport_size := Vector2.ZERO

func _ready() -> void:
	zoom = zoomed_out_level
	default_zoomed_out_position = game_target.position
	previous_viewport_size = get_viewport().get_visible_rect().size

	if OS.has_feature("windows") or OS.has_feature("web_windows"):
		is_pc = true
	elif OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("android"):
		is_mobile = true

func get_safe_zoom(viewport_size := get_viewport().get_visible_rect().size) -> Vector2:
	var world_width = max_x - min_x
	var world_height = min_y - max_y

	var max_zoom_x = viewport_size.x / world_width
	var max_zoom_y = viewport_size.y / world_height
	var required_zoom = max(max_zoom_x, max_zoom_y)

	return Vector2(
		max(zoomed_out_level.x, required_zoom),
		max(zoomed_out_level.y, required_zoom)
	)

func _unhandled_input(event: InputEvent) -> void:
	if not is_pc or get_tree().paused or is_transitioning or auto_vertical_zoom_applied:
		return

	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and not is_zoomed_in:
			is_zoomed_in = true
			is_transitioning = true

			var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.connect("finished", Callable(self, "_on_camera_transition_complete"))

			var mouse_screen_pos = get_viewport().get_mouse_position()
			var mouse_world_pos = get_canvas_transform().affine_inverse() * mouse_screen_pos

			var target_y_pos = game_target.position.y + zoomed_in_position_y_offset

			var viewport_size = get_viewport().get_visible_rect().size
			var half_visible_width_zoomed_in = (viewport_size.x / zoomed_in_level.x) / 2.0

			var left_limit_zoomed_in = min_x + half_visible_width_zoomed_in
			var right_limit_zoomed_in = max_x - half_visible_width_zoomed_in

			var target_x_pos = clamp(mouse_world_pos.x, left_limit_zoomed_in, right_limit_zoomed_in)
			var target_camera_pos = Vector2(target_x_pos, target_y_pos)

			tween.tween_property(self, "zoom", zoomed_in_level, 1.0)
			tween.parallel().tween_property(self, "position", target_camera_pos, 0.5)

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and is_zoomed_in:
			is_zoomed_in = false
			is_transitioning = true

			var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.connect("finished", Callable(self, "_on_camera_transition_complete"))

			var target_zoom = get_safe_zoom()
			tween.tween_property(self, "zoom", target_zoom, 1.0)
			tween.parallel().tween_property(self, "position", default_zoomed_out_position, 0.5)
			access_ui.button_pressed = false

func _process(delta: float) -> void:
	var current_viewport_size = get_viewport().get_visible_rect().size
	if current_viewport_size != previous_viewport_size:
		previous_viewport_size = current_viewport_size
		if is_in_game_view and not is_zoomed_in and not is_transitioning:
			var new_zoom = get_safe_zoom()
			var needs_vertical_offset = new_zoom.y > zoomed_out_level.y * (1.0 + vertical_offset_tolerance)

			zoom = new_zoom

			if needs_vertical_offset and not auto_vertical_zoom_applied:
				position += auto_vertical_zoom_offset
				auto_vertical_zoom_applied = true
			elif not needs_vertical_offset and auto_vertical_zoom_applied:
				position -= auto_vertical_zoom_offset
				auto_vertical_zoom_applied = false

	# Edge scrolling
	if is_zoomed_in and not is_transitioning:
		var viewport_size = current_viewport_size
		var half_visible_width = (viewport_size.x / zoom.x) / 2.0

		var left_limit = min_x + half_visible_width
		var right_limit = max_x - half_visible_width

		var mouse_pos = get_viewport().get_mouse_position()

		if mouse_pos.x <= edge_margin:
			position.x -= edge_scroll_speed * delta
		elif mouse_pos.x >= viewport_size.x - edge_margin:
			position.x += edge_scroll_speed * delta

		position.x = clamp(position.x, left_limit, right_limit)

func _on_main_menu_start_game() -> void:
	is_transitioning = true
	is_in_game_view = true

	var viewport_size = get_viewport().get_visible_rect().size
	var target_zoom = get_safe_zoom(viewport_size)

	var needs_vertical_offset = is_mobile or (target_zoom.y > zoomed_out_level.y * (1.0 + vertical_offset_tolerance))

	print_debug("Start Game - viewport_size: ", viewport_size, " target_zoom: ", target_zoom, " needs_vertical_offset: ", needs_vertical_offset)

	var target_pos = default_zoomed_out_position

	if is_mobile:
		is_zoomed_in = true

		if needs_vertical_offset:
			target_pos += auto_vertical_zoom_offset
			auto_vertical_zoom_applied = true
		else:
			auto_vertical_zoom_applied = false

		var tween1 = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween1.tween_property(self, "zoom", target_zoom, 1.0)
		tween1.parallel().tween_property(self, "position", target_pos, 1.0)
		tween1.connect("finished", Callable(self, "_on_stage1_complete"))

	else:
		is_zoomed_in = false

		if needs_vertical_offset:
			target_pos += auto_vertical_zoom_offset
			auto_vertical_zoom_applied = true
		else:
			auto_vertical_zoom_applied = false

		var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "zoom", target_zoom, 1.5)
		tween.parallel().tween_property(self, "position", target_pos, 1.5)
		tween.connect("finished", Callable(self, "_on_camera_transition_complete"))

func _on_stage1_complete() -> void:
	var tween2 = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween2.tween_property(self, "zoom", zoomed_in_level, 1.5)
	tween2.connect("finished", Callable(self, "_on_camera_transition_complete"))

func _on_day_summary_start_game() -> void:
	# Connect once so it runs after transition is done
	if not is_connected("transition_complete", Callable(self, "_on_transition_complete_from_day_summary")):
		connect("transition_complete", Callable(self, "_on_transition_complete_from_day_summary"))
	_on_main_menu_start_game()

func _on_transition_complete_from_day_summary() -> void:
	main_menu.show()
	day_summary.hide()
	disconnect("transition_complete", Callable(self, "_on_transition_complete_from_day_summary"))

func _on_menu_button_menu_return() -> void:
	main_menu.show()
	day_summary.hide()
	is_transitioning = true
	is_in_game_view = false
	is_zoomed_in = false
	auto_vertical_zoom_applied = false

	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.connect("finished", Callable(self, "_on_camera_transition_complete"))
	access_ui.button_pressed = false

	tween.tween_property(self, "position", menu_target.position, 1.5)
	tween.parallel().tween_property(self, "zoom", zoomed_out_level, 1.5)

func _on_end_day_button_menu_return() -> void:
	_on_menu_button_menu_return()
	main_menu.hide()
	day_summary.show()

func _on_camera_transition_complete() -> void:
	is_transitioning = false
	emit_signal("transition_complete")
