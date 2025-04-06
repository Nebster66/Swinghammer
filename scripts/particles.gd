extends GPUParticles2D

# Set this flag when creating sparks dynamically
var is_dynamic_spawn := false

func _ready():
	if is_dynamic_spawn:
		return  # Skip reparenting if dynamically spawned

	var sub_viewport = get_tree().get_root().get_node("Game/Inside/SubViewportContainer/ParticlesViewport")
	var saved_global_position = global_position
	call_deferred("_move_to_subviewport", sub_viewport, saved_global_position)

func _move_to_subviewport(sub_viewport, saved_global_position):
	if get_parent():
		get_parent().remove_child(self)

	sub_viewport.add_child(self)

	var container_global_position = sub_viewport.get_parent().global_position
	var corrected_position = saved_global_position - container_global_position
	global_position = corrected_position
