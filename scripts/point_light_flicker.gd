extends Light2D

# Parameters to control the flicker effect
var flicker_speed : float = 0.1 # How fast the flicker changes
var flicker_strength : float = 0.2 # How much the light flickers

# Timer to control the flicker
var flicker_timer : float = 0.0

func _ready():
	randomize() # Ensures randomisation when the scene starts

func _process(delta):
	# Update the flicker timer
	flicker_timer += delta
	
	# If the timer has reached the flicker speed, change the light energy
	if flicker_timer >= flicker_speed:
		# Set the energy to a random value within the base range +/- the strength
		self.energy = 1.0 + randf_range(-flicker_strength, flicker_strength)
		
		# Reset the timer
		flicker_timer = 0.0
