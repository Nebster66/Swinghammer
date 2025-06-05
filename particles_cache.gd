extends CanvasLayer

var mats_folder := "res://scenes/FX/Process_Materials/"

func _ready() -> void:
	# Load the directory
	var dir := DirAccess.open(mats_folder)
	if dir == null:
		push_error("Failed to open materials folder: %s" % mats_folder)
		return

	# Scan the folder for resources
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var full_path := mats_folder + file_name
			var mat_res := ResourceLoader.load(full_path)
			if mat_res:
				# Force a dummy processing of the resource (useful if it's a ShaderMaterial)
				if mat_res is ShaderMaterial:
					var dummy := ShaderMaterial.new()
					dummy.shader = mat_res.shader
					# Optionally force rendering to warm up shader
				elif mat_res is ParticleProcessMaterial:
					# You could log it or assign it temporarily to a dummy node
					var dummy_particle := GPUParticles2D.new()
					dummy_particle.process_material = mat_res
					# Not adding to scene tree avoids visual output, but may still warm up
					dummy_particle.preprocess = 1.0
				# You could also queue_free() or ignore the dummy nodes
		file_name = dir.get_next()

	dir.list_dir_end()
