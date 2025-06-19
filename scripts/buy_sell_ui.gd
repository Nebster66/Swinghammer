extends Control

@onready var camera: Camera2D = $"../../Util/Camera2D"
@onready var slide: AudioStreamPlayer2D = $AccessUI/AudioStreamPlayer2D
@onready var access_ui: Button = $AccessUI
@onready var buy_area: StaticBody2D = $"../Storage"

var offset: int = 32

func _on_access_ui_toggled(toggled_on: bool) -> void:
	if toggled_on:
		camera.min_x -= offset
		camera.position.x -= offset
		slide.play()
		
	else:
		camera.min_x += offset
		camera.position.x += offset
		slide.play()
		
