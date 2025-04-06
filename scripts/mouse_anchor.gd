extends StaticBody2D

var mouse_position

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _physics_process(delta: float) -> void:
	global_position = get_global_mouse_position()
