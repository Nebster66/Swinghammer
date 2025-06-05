extends StaticBody2D

@onready var bubbles: GPUParticles2D = $Bubbles
@onready var steam: GPUParticles2D = $Steam
@onready var boiling_audio: AudioStreamPlayer2D = $BoilingAudio

func _ready() -> void:
	bubbles.emitting = true
	steam.emitting = true
	# Let them run for at least 0.2s
	await get_tree().create_timer(0.2).timeout
	bubbles.emitting = false
	steam.emitting = false
	boiling_audio.stop()  # Ensure audio is stopped initially


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("steel"):
		bubbles.emitting = true
		steam.emitting = true
		boiling_audio.play()  # Play the boiling audio

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("steel"):
		bubbles.emitting = false
		steam.emitting = false
		#boiling_audio.stop()  # Stop the boiling audio when body exits
