extends Camera2D

@onready var game_target = $"../GameMarker"  # The target location in your game scene
@onready var menu_target: Marker2D = $"../MainMenuMarker"

func _on_main_menu_start_game() -> void:
	# Create the tween
	var tween = create_tween()
	
	# Set the transition properties
	tween.tween_property(self, "position", game_target.position, 1.5)  # 1.5 seconds duration
	
	# Set the easing method (optional, makes it smoother)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)

func _on_menu_button_menu_return() -> void:
	var tween = create_tween()
	
	# Set the transition properties
	tween.tween_property(self, "position", menu_target.position, 1.5)  # 1.5 seconds duration
	
	# Set the easing method (optional, makes it smoother)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
