extends Node

signal disable
signal enable

# Day/Night Cycle Settings
@export var day_length: float = 120.0 # Duration of the main DAY and NIGHT phases in seconds
@export var transition_duration: float = 10.0 # Duration of SUNSET and SUNRISE phases in seconds
@onready var confirm: Button = $"../../Inside/BuySellUI/Confirm"

# Color Settings
@export var sunset_colour: Color = Color(1.0, 0.5, 0.3)
@export var night_colour: Color = Color(0.2, 0.2, 0.3)
@export var sunrise_colour: Color = Color(1.0, 0.6, 0.4)

# Season Settings
@export var days_per_season: int = 4

# UI Reference
@onready var date_label: Label = $"../../UI/UI/Date" # Path to the label node (adjust if manager is in a different spot)
@onready var end_day_button: Button = $"../../UI/UI/EndDayButton"

# Reference to the CanvasModulate nodes
@export var canvas_modulates: Array[CanvasModulate] # Drag and drop your 3 CanvasModulate nodes here in the Inspector!

# --- Enums for State Management ---
enum TimeOfDay { DAY, SUNSET, NIGHT, SUNRISE, PAUSED_END_OF_DAY } # Added PAUSED_END_OF_DAY
enum Season { SPRING, SUMMER, AUTUMN, WINTER }

# --- Internal State Variables ---
var current_phase: TimeOfDay = TimeOfDay.DAY
var current_season: Season = Season.SPRING
var day_counter: int = 1 # Tracks the day within the current season

var default_color: Color # This will now be the color we apply when in DAY phase
var target_color: Color
var time_in_phase: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	# Ensure canvas_modulates array is populated
	if canvas_modulates.is_empty():
		push_warning("No CanvasModulate nodes assigned to the 'canvas_modulates' array in the Inspector!")
		return

	# Store the initial color of the first CanvasModulate as the default day color
	# Assuming all CanvasModulates should start with the same "day" color
	default_color = canvas_modulates[0].color
	
	# Set the timer for the first day phase
	time_in_phase = day_length
	# Initialize the target color and update the UI label
	set_target_color()
	update_date_label()
	
	# Hide the end day button initially
	end_day_button.hide()
	
	# Connect the button's pressed signal
	end_day_button.pressed.connect(Callable(self, "_on_end_day_button_pressed"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float):
	# Only process the cycle if not paused
	if current_phase == TimeOfDay.PAUSED_END_OF_DAY:
		return

	# Decrease the timer for the current phase
	time_in_phase -= delta

	# If the current phase has ended, advance to the next one
	if time_in_phase <= 0:
		advance_phase()

	# Smoothly interpolate the CanvasModulate color towards the target color
	# Apply the interpolated color to ALL referenced CanvasModulate nodes
	for canvas_modulate_node in canvas_modulates:
		canvas_modulate_node.color = canvas_modulate_node.color.lerp(target_color, delta / transition_duration)


# --- Core Logic Functions (remain the same) ---

func advance_phase():
	# Check if we are about to transition from NIGHT to DAY (i.e., end of the current day)
	if current_phase == TimeOfDay.NIGHT: # The end of SUNRISE signals the start of a new DAY
		# Pause the cycle and show the button
		current_phase = TimeOfDay.PAUSED_END_OF_DAY
		end_day_button.show()
		confirm.disabled = true # new and works
		emit_signal("disable")
		return # Exit early, don't advance to the next time of day yet

	current_phase = TimeOfDay.values()[(int(current_phase) + 1) % TimeOfDay.values().size()]

	# The `update_day_and_season()` logic only runs when we actually advance to a new DAY
	if current_phase == TimeOfDay.DAY:
		update_day_and_season()

	match current_phase:
		TimeOfDay.DAY, TimeOfDay.NIGHT:
			time_in_phase = day_length
		TimeOfDay.SUNSET, TimeOfDay.SUNRISE:
			time_in_phase = transition_duration

	set_target_color()
	update_date_label()

func set_target_color():
	match current_phase:
		TimeOfDay.DAY:
			target_color = default_color
		TimeOfDay.SUNSET:
			target_color = sunset_colour
		TimeOfDay.NIGHT:
			target_color = night_colour
		TimeOfDay.SUNRISE:
			target_color = sunrise_colour
		TimeOfDay.PAUSED_END_OF_DAY:
			# Maintain the sunrise color while paused
			target_color = sunrise_colour 


func update_day_and_season():
	day_counter += 1
	if day_counter > days_per_season:
		day_counter = 1
		current_season = Season.values()[(int(current_season) + 1) % Season.values().size()]

func update_date_label():
	if not is_instance_valid(date_label):
		print("Date label is not valid.")
		return
	
	var season_name = Season.find_key(current_season).capitalize()
	
	var day_period_name = "Day"
	if current_phase == TimeOfDay.NIGHT or current_phase == TimeOfDay.SUNRISE or current_phase == TimeOfDay.PAUSED_END_OF_DAY:
		day_period_name = "Night" # Display as "Night" when paused at the end of the day
	
	var new_date_text = "%s %s - %d" % [season_name, day_period_name, day_counter]
	date_label.text = new_date_text
	
	#date_updated.emit(new_date_text)

# --- New Function for Button Press ---
func _on_end_day_button_pressed():
	end_day_button.hide()
	# Manually advance the phase to DAY, which will also update the day counter
	current_phase = TimeOfDay.DAY
	time_in_phase = day_length # Reset the timer for the new day
	update_day_and_season() # Ensure day and season are updated
	set_target_color() # Set the target color for the new day
	update_date_label() # Update the label for the new day
	confirm.disabled = false
	emit_signal("enable")
	print("End Day button pressed! Advancing to the next day.")
