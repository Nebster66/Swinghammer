extends Button

signal menu_return

func _on_pressed() -> void:
	menu_return.emit()
	get_tree().paused = true
