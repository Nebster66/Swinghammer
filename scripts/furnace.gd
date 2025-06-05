extends StaticBody2D

# Nodes
@onready var smoke: GPUParticles2D = $FurnaceSmoke
@onready var flame: GPUParticles2D = $Flame
@onready var light: PointLight2D = $PointLight2D
@onready var fire_area_collider: CollisionShape2D = $FireArea/CollisionShape2D
@onready var bellow_system: Node2D = $BellowSystem
@onready var furnace_sound: AudioStreamPlayer2D = $FurnaceSound

# Temperature properties
var temperature: float = 20.0
var max_temperature: float = 100.0
var min_temperature: float = 20.0
var cooling_rate: float = 5.0

# Volume properties with export variables
@export var min_volume_db: float = -30.0  # Minimum furnace volume
@export var max_volume_db: float = 0.0    # Maximum furnace volume
@export var volume_fade_speed: float = 5.0  # Speed of volume transition

# Current volume
var current_volume: float = -30.0

func _ready() -> void:
	update_visuals()
	set_process(true)

func _process(delta: float) -> void:
	if temperature > min_temperature:
		temperature = max(min_temperature, temperature - cooling_rate * delta)
		update_visuals()

func increase_temperature(amount: float) -> void:
	temperature = min(temperature + amount, max_temperature)
	update_visuals()

func update_visuals() -> void:
	var temp_ratio := (temperature - min_temperature) / (max_temperature - min_temperature)

	smoke.emitting = true
	flame.emitting = true
	light.enabled = true

	smoke.amount_ratio = max(temp_ratio, 0.2)
	flame.amount_ratio = max(temp_ratio, 0.2)

	light.energy = lerp(0.4, 2.0, temp_ratio)

	var min_scale := 0.8
	var max_scale := 1.2
	light.scale = Vector2.ONE * lerp(min_scale, max_scale, temp_ratio)

func update_furnace_volume(pump_boost: float) -> void:
	# Base volume from temperature
	var temp_ratio := (temperature - min_temperature) / (max_temperature - min_temperature)
	var base_volume = lerp(min_volume_db, max_volume_db, temp_ratio)

	# Apply the pump boost immediately, but fade naturally afterward
	var target_volume = base_volume + pump_boost

	# Smoothly interpolate the current volume toward the target volume
	current_volume = lerp(current_volume, target_volume, volume_fade_speed * get_process_delta_time())
	
	# Apply the interpolated volume
	furnace_sound.volume_db = current_volume


func _on_main_menu_start_game() -> void:
	furnace_sound.play()
