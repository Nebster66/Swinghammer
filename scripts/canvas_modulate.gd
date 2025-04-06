extends CanvasModulate

@export var day_length: float = 120.0  # Total length of a day-night cycle in seconds (Day and Night phases)
@export var transition_speed: float = 0.25  # Speed of transition between phases (sunset/sunrise)

@export var sunset_colour: Color
@export var night_colour: Color
@export var sunrise_colour: Color

enum TimeOfDay { DAY, SUNSET, NIGHT, SUNRISE }
var current_phase: TimeOfDay = TimeOfDay.DAY
var default_color: Color
var target_color: Color
var transition_timer: float = 0.0

func _ready():
	default_color = color  # Store the default modulate colour
	transition_timer = day_length  # Set timer for first day cycle
	set_target_color()

func _process(delta):
	transition_timer -= delta
	if transition_timer <= 0:
		advance_phase()
		if current_phase == TimeOfDay.DAY or current_phase == TimeOfDay.NIGHT:
			# Set the timer for day/night phases
			transition_timer = day_length
		else:
			# Set the timer for the transition phases (sunset/sunrise)
			transition_timer = transition_speed

	# Smoothly transition towards the target colour
	color = color.lerp(target_color, delta * transition_speed)

func advance_phase():
	match current_phase:
		TimeOfDay.DAY:
			current_phase = TimeOfDay.SUNSET
		TimeOfDay.SUNSET:
			current_phase = TimeOfDay.NIGHT
		TimeOfDay.NIGHT:
			current_phase = TimeOfDay.SUNRISE
		TimeOfDay.SUNRISE:
			current_phase = TimeOfDay.DAY
	
	set_target_color()

func set_target_color():
	match current_phase:
		TimeOfDay.DAY:
			target_color = default_color  # Default (day) colour
		TimeOfDay.SUNSET:
			target_color = Color(1.0, 0.5, 0.3, 1.0)  # Sunset: warm orange
		TimeOfDay.NIGHT:
			target_color = Color(0.2, 0.2, 0.3, 1.0)  # Night: dark blue
		TimeOfDay.SUNRISE:
			target_color = Color(1.0, 0.6, 0.4, 1.0)  # Sunrise: warm yellowish-orange
