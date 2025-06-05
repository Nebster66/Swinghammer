extends Node

var resource_paths: Array[String] = [
	"res://scenes/FX/flame.tscn",
	"res://scenes/FX/furnace_smoke.tscn",
	"res://scenes/FX/point_smoke.tscn",
	"res://scenes/FX/Process_Materials/bubbles.tres",
	"res://scenes/FX/Process_Materials/flame.tres",
	"res://scenes/FX/Process_Materials/furnace_smoke.tres",
	"res://scenes/FX/Process_Materials/hammer_spark.tres",
	"res://scenes/FX/Process_Materials/point_smoke.tres",
	"res://scenes/FX/Process_Materials/sparks.tres",
	"res://scenes/FX/Process_Materials/steam.tres",
	"res://scenes/FX/Process_Materials/torch_flame.tres",
	"res://scenes/FX/Process_Materials/unshaded.tres",
	"res://scenes/FX/spark_particle.tscn"
]

var loaded_resources: Dictionary = {}
var loading_complete := false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("Collected paths to load: ", resource_paths)
	preload_all_particles()

func preload_all_particles() -> void:
	await get_tree().process_frame  # Give the browser a frame to breathe
	for path in resource_paths:
		print("Loading: ", path)
		var res = ResourceLoader.load(path)
		if res:
			loaded_resources[path] = res
			print("Preloaded: ", path)

			if res is PackedScene:
				var inst = res.instantiate()
				if inst:
					add_child(inst)
					inst.visible = false
					await warm_up_particles_in_node(inst)
					inst.queue_free()

		# Give control back to browser before loading next file
		await get_tree().process_frame

	loading_complete = true
	print("All particle resources preloaded.")
	for path in loaded_resources.keys():
		print("Preloaded: ", path)

func warm_up_particles_in_node(node: Node) -> void:
	for child in node.get_children():
		if child is GPUParticles2D or child is CPUParticles2D:
			await warm_up_particle_node(child)
		await warm_up_particles_in_node(child)

func warm_up_particle_node(particle: Node) -> void:
	var was_visible = particle.visible
	var was_emitting = particle.emitting

	# Position it on-screen in a hidden corner
	if particle is Node2D:
		particle.global_position = Vector2(10, 10)  # Must be inside viewport

	particle.visible = true  # Make visible so GPU draws it
	particle.emitting = true

	# Wait a couple of frames to allow draw and shader compile
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout

	particle.emitting = was_emitting
	particle.visible = was_visible
