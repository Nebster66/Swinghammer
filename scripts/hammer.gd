extends RigidBody2D

var pin: PinJoint2D
var mouse_anchor: Node2D
var held: bool = false

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed() and !held:
			pick_up_hammer()

func _physics_process(delta: float) -> void:
	if held:
		mouse_anchor.global_position = get_global_mouse_position()
		
		# Check if the mouse button is no longer pressed
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			release_hammer()

func pick_up_hammer() -> void:
	held = true
	
	# Create and attach the PinJoint2D
	pin = PinJoint2D.new()
	pin.softness = 0.5
	add_child(pin)

	# Create the mouse anchor
	var mouse_anchor_res = load("res://scenes/mouse_anchor.tscn")
	mouse_anchor = mouse_anchor_res.instantiate()
	add_child(mouse_anchor)

	# Set initial positions
	mouse_anchor.global_position = get_global_mouse_position()
	pin.global_position = get_global_mouse_position()
	pin.set_node_a(mouse_anchor.get_path())
	pin.set_node_b(self.get_path())

func release_hammer() -> void:
	held = false
	
	if pin:
		pin.queue_free()
		pin = null
	if mouse_anchor:
		mouse_anchor.queue_free()
		mouse_anchor = null
