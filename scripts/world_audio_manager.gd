extends Node

@onready var background_audio_player: AudioStreamPlayer = $BackgroundAudioPlayer
@onready var button_sound: AudioStreamPlayer = $ButtonSound

var music_volume
var background_volume
var sfx_volume

func _ready() -> void:
	var buttons: Array = get_tree().get_nodes_in_group("button")
	for button in buttons:
		button.pressed.connect(self.on_button_pressed)

func _on_main_menu_start_game() -> void:
	background_audio_player.play()

func on_button_pressed()->void:
	button_sound.play()
