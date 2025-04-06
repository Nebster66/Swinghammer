extends Node2D

@onready var groove_joint_2d: GrooveJoint2D = $GrooveJoint2D
@onready var bellows: AnimatedSprite2D = $Bellows
@onready var bellow_pin: RigidBody2D = $BellowPin
@onready var furnace: Node2D = get_parent()
@onready var bellow_fill_playlist: AudioStreamPlayer2D = $BellowFillPlaylist
@onready var bellow_pump_playlist: AudioStreamPlayer2D = $BellowPumpPlaylist

# Bellows movement
var min_y: float
var max_y: float
@export var total_frames: int = 5

# Volume controls
@export var pump_boost_db: float = 10.0  # Instant spike when pumped
@export var pump_fade_rate: float = 6.0  # How quickly the boost fades

var previous_frame: int = 0
var pump_volume_boost: float = 0.0  # Current boost amount

func _ready():
	max_y = bellow_pin.position.y
	min_y = max_y - 5

func _physics_process(delta):
	var progress = (bellow_pin.position.y - min_y) / (max_y - min_y)
	progress = clamp(progress, 0.0, 1.0)
	progress = 1.0 - progress

	var frame_index = round(progress * total_frames)

	# Detect direction of movement
	if frame_index > previous_frame:
		# Furnace is pumped → Apply an instant volume spike
		furnace.increase_temperature(5)
		pump_volume_boost = pump_boost_db  # Instant volume spike

		# Play pump sound when moving forward (compressing)
		if not bellow_pump_playlist.playing:
			bellow_pump_playlist.play()

	elif frame_index < previous_frame:
		# Play fill sound when moving backward (expanding)
		if not bellow_fill_playlist.playing:
			bellow_fill_playlist.play()

	# Store the current frame for the next comparison
	previous_frame = frame_index

	# Update the bellows animation
	bellows.frame = frame_index

	# Gradually reduce the pump boost over time
	pump_volume_boost = max(pump_volume_boost - pump_fade_rate * delta, 0.0)

	# Apply the volume adjustment with the current boost
	furnace.update_furnace_volume(pump_volume_boost)
