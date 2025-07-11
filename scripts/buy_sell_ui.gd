extends Control

@onready var camera: Camera2D = $"../../Util/Camera2D"
@onready var slide: AudioStreamPlayer2D = $AccessUI/AudioStreamPlayer2D
@onready var access_ui: Button = $AccessUI
@onready var buy_area: StaticBody2D = $"../Storage"

var offset: int = 32

func _ready() -> void:
	# Connect to the window resize signal (Godot 4 syntax)
	get_tree().root.size_changed.connect(_on_window_size_changed)

func _on_access_ui_toggled(toggled_on: bool) -> void:
	if toggled_on:
		camera.min_x -= offset
		camera.position.x -= offset
		slide.play()
	else:
		camera.min_x += offset
		camera.position.x += offset
		slide.play()

func _on_window_size_changed() -> void:
	# Automatically close the Access UI if open when the window is resized
	if access_ui.button_pressed:
		access_ui.button_pressed = false  # Triggers toggled(false)
