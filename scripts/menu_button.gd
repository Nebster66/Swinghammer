extends Button

signal menu_return

# The camera reference is no longer needed here
# @onready var camera_2d: Camera2D = $"../../../Util/Camera2D"

func _on_pressed() -> void:
	menu_return.emit()
	# The game pause logic can remain if that's your desired behavior.
	get_tree().paused = true
	
	# The tweening logic has been removed from here.
	# The camera will listen for the 'menu_return' signal
	# and handle its own zoom reset.
