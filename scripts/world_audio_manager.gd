extends Node

@onready var background_audio_player: AudioStreamPlayer = $BackgroundAudioPlayer

var music_volume
var background_volume
var sfx_volume

func _on_main_menu_start_game() -> void:
	background_audio_player.play()
