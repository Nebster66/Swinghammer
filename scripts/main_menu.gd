extends Control

signal start_game

@onready var menu_buttons: VBoxContainer = $CenterContainer/MenuButtons
@onready var options_menu: VBoxContainer = $CenterContainer/OptionsMenu
@onready var display_menu: VBoxContainer = $CenterContainer/OptionsMenu/HBoxContainer/DisplayMenu
@onready var volume_menu: VBoxContainer = $CenterContainer/OptionsMenu/HBoxContainer/VolumeMenu
@onready var credits_menu: VBoxContainer = $CenterContainer/CreditsMenu
@onready var quit_button: Button = $CenterContainer/MenuButtons/QuitButton
@onready var start_button: Button = $CenterContainer/MenuButtons/StartButton
@onready var access_menu: VBoxContainer = $CenterContainer/OptionsMenu/HBoxContainer/AccessabilityMenu
@onready var start_audio: AudioStreamPlayer2D = $CenterContainer/MenuButtons/StartButton/AudioStreamPlayer2D

#volume sliders
@onready var main_volume_slider: HSlider = $CenterContainer/OptionsMenu/HBoxContainer/VolumeMenu/HBoxContainer/MainVolumeSlider
@onready var music_volume_slider: HSlider = $CenterContainer/OptionsMenu/HBoxContainer/VolumeMenu/HBoxContainer2/MusicVolumeSlider
@onready var sfx_volume_slider: HSlider = $CenterContainer/OptionsMenu/HBoxContainer/VolumeMenu/HBoxContainer3/SFXVolumeSlider

func _ready() -> void:
	menu_buttons.visible = true
	options_menu.visible = false
	credits_menu.visible = false
	
	# Set the initial slider values based on the current bus volumes
	main_volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	music_volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))
	sfx_volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))

	# Ensure sliders have the correct ranges (adjust based on your needs)
	main_volume_slider.min_value = 0.0
	main_volume_slider.max_value = 2.0
	music_volume_slider.min_value = 0.0
	music_volume_slider.max_value = 2.0
	sfx_volume_slider.min_value = 0.0
	sfx_volume_slider.max_value = 2.0

	# Set the step value to 10 (this means values will be rounded to the nearest multiple of 0.1)
	main_volume_slider.step = 0.2
	music_volume_slider.step = 0.2
	sfx_volume_slider.step = 0.2

func _on_start_button_pressed() -> void:
	start_game.emit()
	start_audio.play()
	start_button.text = "Resume"
	get_tree().paused = false
	#quit_button.disabled = true

func _on_quit_button_pressed() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	get_tree().quit()

func _on_options_button_pressed() -> void:
	menu_buttons.visible = false
	display_menu.visible = false
	volume_menu.visible = false
	options_menu.visible = true

func _on_back_button_pressed() -> void:
	credits_menu.visible = false
	options_menu.visible = false
	menu_buttons.visible = true

func _on_sound_button_pressed() -> void:
	display_menu.visible = false
	access_menu.visible = false
	volume_menu.visible = true

func _on_display_button_pressed() -> void:
	volume_menu.visible = false
	access_menu.visible = false
	display_menu.visible = true

func _on_credits_button_pressed() -> void:
	menu_buttons.visible = false
	credits_menu.visible = true

func _on_display_mode_toggled(toggled_on: bool) -> void:
	if toggled_on == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

# Volume control callbacks
func _on_main_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))

func _on_music_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))

func _on_sfx_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(value))


func _on_flip_hammer_toggled(toggled_on: bool) -> void:
	pass # send a message to "SwingHammer" scene that flips sprite 2d, disables head1 collider, enables head2 collider, adjusts COM


func _on_access_button_pressed() -> void:
	volume_menu.visible = false
	display_menu.visible = false
	access_menu.visible = true


func _on_flicker_toggled(toggled_on: bool) -> void:
	get_tree().call_group("flicker_lights", "set_flicker_enabled", toggled_on)
