extends SwingObject2D

@onready var spark: GPUParticles2D = $Spark
@onready var clang: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var spark_origin: Marker2D = $SparkOrigin

var touching = true

func _on_body_entered(body: Node) -> void:
	if held and body.is_in_group("steel"):
		var particles_viewport = get_tree().get_root().get_node("Game/Inside/SubViewportContainer/ParticlesViewport")

		var new_particle: GPUParticles2D = spark.duplicate()
		new_particle.is_dynamic_spawn = true

		# Get the SubViewportContainer’s global position (which defines the visual offset)
		var sub_viewport_container = particles_viewport.get_parent()
		var container_global_position = sub_viewport_container.global_position

		# Calculate the local position for the particle relative to the viewport
		var corrected_position = spark_origin.global_position - container_global_position
		new_particle.position = corrected_position  # Use position, NOT global_position


		# Add directly to the SubViewport
		particles_viewport.add_child(new_particle)

		new_particle.restart()
		new_particle.emitting = true

		new_particle.finished.connect(func():
			new_particle.queue_free()
		)

		clang.play()


# attempt to negate multiple triggers for one collision
func _on_body_exited(body: Node) -> void:
	if body.is_in_group("steel") and touching:
		touching = false
