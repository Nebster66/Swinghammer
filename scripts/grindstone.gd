extends Area2D

@onready var animation: AnimatedSprite2D   = $AnimatedSprite2D
@onready var sparks:     GPUParticles2D    = $SparkParticle
@onready var smoke:      GPUParticles2D    = $PointSmoke
@onready var point_light: PointLight2D     = $PointLightFlicker
@onready var on_audio:   AudioStreamPlayer2D = $OnAudio
@onready var grind_audio: AudioStreamPlayer2D = $GrindAudio

var on: bool       = false            # Whether the wheel is currently spinning
var disabled: bool = false            # true when a “disable” signal has been received

func _ready() -> void:
	sparks.emitting = true
	smoke.emitting  = true
	await get_tree().create_timer(0.2).timeout   # Let them run briefly
	sparks.emitting = false
	smoke.emitting  = false
	point_light.enabled = false
	animation.pause()

	input_pickable = true
	# Ensure the Area2D’s input event is connected
	if not is_connected("input_event", _on_input_event):
		connect("input_event", Callable(self, "_on_input_event"))

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if disabled:						### NEW – ignore clicks while disabled
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if animation.is_playing():
			# Turn OFF
			animation.pause()
			on = false
			sparks.emitting = false
			smoke.emitting = false
			on_audio.stop()
		else:
			# Turn ON
			animation.play()
			on = true
			on_audio.play()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("steel") and on:
		sparks.emitting   = true
		smoke.emitting    = true
		point_light.enabled = true
		grind_audio.play()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("steel") and on:
		sparks.emitting   = false
		smoke.emitting    = false
		point_light.enabled = false
		grind_audio.stop()

func _on_day_night_manager_disable() -> void:
	disabled = true
	# Force the stone to stop if it was running
	if on:
		animation.pause()
		on = false
		sparks.emitting = false
		smoke.emitting  = false
		point_light.enabled = false
		on_audio.stop()
		grind_audio.stop()

func _on_day_night_manager_enable() -> void:
	disabled = false
