extends Light2D

var flicker_speed: float = 0.1
var flicker_strength: float = 0.2
var flicker_timer: float = 0.0
var flicker_enabled: bool = true

func _ready():
	randomize()
	add_to_group("flicker_lights")

func _process(delta):
	if flicker_enabled:
		flicker_timer += delta
		if flicker_timer >= flicker_speed:
			self.energy = 1.0 + randf_range(-flicker_strength, flicker_strength)
			flicker_timer = 0.0
	else:
		self.energy = 1.0


func set_flicker_enabled(enabled: bool) -> void:
	flicker_enabled = enabled
