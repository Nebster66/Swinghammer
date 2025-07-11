@warning_ignore("missing_tool")
extends SwingObject2D	# originally StaticBody2D

signal deformed	# <-- NEW: emitted when tile is deformed

@export var initial_width: float = 2.0  
@export var initial_height: float = 2.0  
@export var w_mult_arr: Array = [1, 1.05, 1.075, 1.1, 1, 1]  
@export var h_mult_arr: Array = [1, 0.95, 0.9, 0.85, 1, 1]  
@export var min_height: float = 1.0  
@export var max_width: float = 2.5  
@export var cooling_rate: float = 1  
@export var heating_rate: float = 5.0  

@onready var area_2d: Area2D = $Area2D  
@onready var sprite: AnimatedSprite2D = $SteelTileSprite  
@onready var shape: CollisionShape2D = $CollisionShape2D  

# Steel properties  
var current_width: float  
var current_height: float  
var heat: float = 0.0  
var max_heat: float = 100.0  
var in_furnace: bool = false  
var furnace: Node2D = null  
var is_hardened: bool = false  
var was_quenched_when_hot: bool = false  
var quench_stage: int = -1  

# Sharpening properties  
var sharpness: float = 0.0  
var is_sharpened: bool = false  
var touching_grindstone: bool = false  
var grindstone: Node2D = null  
const SHARPEN_RATE: float = 20.0  

# Status handling  
var status_array = ["temp_0", "temp_1", "temp_2", "temp_3", "quenched", "sharp"]  
var current_status: int = 0  

func _ready() -> void:
	current_width = initial_width
	current_height = initial_height

	if not area_2d.is_connected("area_entered", Callable(self, "_on_area_2d_area_entered")):
		area_2d.connect("area_entered", Callable(self, "_on_area_2d_area_entered"))
	if not area_2d.is_connected("area_exited", Callable(self, "_on_area_2d_area_exited")):
		area_2d.connect("area_exited", Callable(self, "_on_area_2d_area_exited"))
	if not area_2d.is_connected("body_entered", Callable(self, "_on_area_2d_body_entered")):
		area_2d.connect("body_entered", Callable(self, "_on_area_2d_body_entered"))
	if not area_2d.is_connected("body_exited", Callable(self, "_on_area_2d_body_exited")):
		area_2d.connect("body_exited", Callable(self, "_on_area_2d_body_exited"))

	sprite.play(status_array[current_status])
	set_process(true)
	
	# Try attaching to parent or neighbouring tile
	if get_parent() and get_parent().has_method("link_tiles"):
		get_parent().link_tiles(self)
		
	input_pickable = true  # this is necessary for _on_input_event to fire

func _physics_process(delta: float) -> void:
	if in_furnace and furnace:
		if heat < furnace.temperature:
			var furnace_heat_cap = (furnace.temperature / furnace.max_temperature) * max_heat
			heat = min(heat + (furnace.temperature / furnace.max_temperature) * heating_rate * delta, furnace_heat_cap)
		elif heat > furnace.temperature:
			heat = max(heat - cooling_rate * delta, furnace.temperature)
	else:
		heat = max(heat - cooling_rate * delta, 0)

	if not is_hardened:
		_update_temperature_stage()

	if is_hardened and touching_grindstone and grindstone.on and not is_sharpened:
		sharpness += SHARPEN_RATE * delta
		sharpness = clamp(sharpness, 0, 100)

		if sharpness >= 90:
			is_sharpened = true
			current_status = 5  # "sharp"
			sprite.play(status_array[current_status])

func _update_temperature_stage() -> void:
	var new_status = clamp(int(heat / 25), 0, 3)
	if new_status != current_status:
		current_status = new_status
		sprite.play(status_array[current_status])

func deform() -> void:
	current_width = clamp(current_width * w_mult_arr[current_status], initial_width, max_width)
	current_height = clamp(current_height * h_mult_arr[current_status], min_height, initial_height)

	var scale_x = current_width / initial_width
	var scale_y = current_height / initial_height
	sprite.scale = Vector2(scale_x, scale_y)

	if shape.shape is RectangleShape2D:
		var rect_shape := shape.shape as RectangleShape2D
		rect_shape.size = Vector2(current_width, current_height)
		shape.position = Vector2.ZERO  # ensure it's centred

	emit_signal("deformed")

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("furnace"):
		in_furnace = true
		furnace = area.get_parent()
	elif area.is_in_group("water") and not is_hardened:
		_quench_steel()

func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.is_in_group("furnace"):
		in_furnace = false
		furnace = null
		if is_hardened:
			is_hardened = false

func _quench_steel() -> void:
	if current_status >= 2 and current_status <= 3:
		is_hardened = true
		was_quenched_when_hot = true
		quench_stage = current_status
		current_status = 4  # "quenched"
	else:
		is_hardened = false
		was_quenched_when_hot = false
		quench_stage = -1
		_update_temperature_stage()

	heat = 0
	sprite.play(status_array[current_status])

	if get_parent().has_method("_update_value_and_quality"):
		get_parent()._update_value_and_quality()

func _on_area_2d_body_entered(body: Node) -> void:
	if body.is_in_group("hammer"):
		deform()
	elif body.is_in_group("grindstone"):
		touching_grindstone = true
		grindstone = body.get_parent()

func _on_area_2d_body_exited(body: Node) -> void:
	if body.is_in_group("grindstone"):
		touching_grindstone = false
		grindstone = null
