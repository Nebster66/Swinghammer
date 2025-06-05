extends Area2D
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var sparks: GPUParticles2D = $SparkParticle
@onready var smoke: GPUParticles2D = $PointSmoke

var on = false

func _ready() -> void:
	sparks.emitting = true
	smoke.emitting = true
		# Let them run for at least 0.2s
	await get_tree().create_timer(0.2).timeout
	sparks.emitting = false
	smoke.emitting = false
	animation.pause()
	
	input_pickable = true
	#test input signal connection
	if not is_connected("input_event", _on_input_event):
		#connect input signal if no connection is present
		connect("input_event", Callable(self, "_on_input_event"))

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed() and not animation.is_playing():
			animation.play()
			on = true
		elif event.is_pressed() and animation.is_playing():
			animation.pause()
			on = false
			sparks.emitting = false
			smoke.emitting = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("steel") and on:
		sparks.emitting = true
		smoke.emitting = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("steel") and on:
		sparks.emitting = false
		smoke.emitting = false
