extends Control

signal start_game

@onready var start_audio: AudioStreamPlayer2D = $CenterContainer/VBoxContainer/StartButton/AudioStreamPlayer2D
@onready var roof_tile_layer: TileMapLayer = $"../../Roof/RoofTileLayer"
@onready var upgrade_walls_button: Button = $CenterContainer/VBoxContainer/HBoxContainer/MenuButtons2/UpgradeWalls # costs $30
@onready var walls_tile_layer: TileMapLayer = $"../../Inside/TilemapLayers/WallTileLayer"
@onready var upgrade_roof_button: Button = $CenterContainer/VBoxContainer/HBoxContainer/MenuButtons2/UpgradeRoof # costs $20
@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var saw_audio: AudioStreamPlayer2D = $CenterContainer/VBoxContainer/StartButton/SawAudioStreamPlayer2D

# money stuff
@onready var daily_income: Label = $CenterContainer/VBoxContainer/HBoxContainer/MenuButtons/HBoxContainer/DailyIncome
@onready var daily_costs: Label = $CenterContainer/VBoxContainer/HBoxContainer/MenuButtons/HBoxContainer2/DailyCosts
@onready var daily_net: Label = $CenterContainer/VBoxContainer/HBoxContainer/MenuButtons/HBoxContainer3/DailyNet
@onready var total_money: Label = $CenterContainer/VBoxContainer/HBoxContainer/MenuButtons/HBoxContainer4/TotalMoney
@onready var ui: Control = $"../../UI/UI" # This node holds money_total_cents
@onready var money: Label = $"../../UI/UI/Money" # This is the specific label to update in the UI

# Store the current upgrade level for walls and roof
# 0 = base, 1 = upgraded, 2 = further upgraded (for roof)
var walls_current_level: int = 0
var roof_current_level: int = 0

# Define source IDs for base and upgraded states
# IMPORTANT: Adjust these based on your TileSet configuration.
# Ensure these match the source_ids in your TileSet asset.
const WALLS_SOURCE_IDS: Array[int] = [0, 1] # Level 0 -> source_id 0, Level 1 -> source_id 1
const ROOF_SOURCE_IDS: Array[int] = [0, 1, 2] # Level 0 -> source_id 0, Level 1 -> source_id 1, Level 2 -> source_id 2

# Define upgrade costs in cents (integers to avoid float inaccuracies)
const WALLS_UPGRADE_COST_CENTS: int = 3000 # $30.00
const ROOF_UPGRADE_COST_CENTS: int = 2000 # $20.00

# --- NEW: Internal variable for tweening money labels ---
# Only need this for total money now
var _current_display_total_money_cents: int = 0:
	set(value):
		_current_display_total_money_cents = value
		total_money.text = "$%.2f" % (_current_display_total_money_cents / 100.0)
		money.text = "$%.2f" % (_current_display_total_money_cents / 100.0) # Update main UI money label

# Keep track of active tweens for the total money label to prevent conflicts
var _total_money_tween: Tween = null


func _ready() -> void:
	# Initialize button states based on current upgrade levels
	upgrade_walls_button.button_pressed = (walls_current_level == 1)
	upgrade_roof_button.button_pressed = (roof_current_level == 2) # Roof button pressed if at highest level

	# Roof upgrade button is only enabled if walls are upgraded
	upgrade_roof_button.disabled = (walls_current_level < 1) or (roof_current_level == 2) # Also disable if already maxed out

	# Also disable walls button if already maxed out
	upgrade_walls_button.disabled = (walls_current_level == 1)

	# Set initial values directly without tweening on ready for all labels
	# Daily summary labels are no longer tweened on ready
	daily_income.text = "$%.2f" % (0.00) # Set to appropriate initial value
	daily_costs.text = "$%.2f" % (0.00)  # Set to appropriate initial value
	daily_net.text = "$%.2f" % (0.00)    # Set to appropriate initial value
	
	# This will set the total money immediately
	_current_display_total_money_cents = ui.money_total_cents


func _on_start_button_pressed() -> void:
	# Apply the visuals of the currently selected upgrade levels
	apply_upgrade_visuals(walls_tile_layer, walls_current_level, WALLS_SOURCE_IDS)
	apply_upgrade_visuals(roof_tile_layer, roof_current_level, ROOF_SOURCE_IDS)

	# --- NEW LOGIC: Disable buttons for applied upgrades ---
	# If walls are upgraded, disable the walls upgrade button
	if walls_current_level == 1:
		upgrade_walls_button.disabled = true
		if roof_current_level == 2:
			upgrade_roof_button.disabled = true

	# If roof is upgraded to its final level, disable the roof upgrade button
	if roof_current_level == 2:
		upgrade_roof_button.disabled = true
	# --- END NEW LOGIC ---

	start_game.emit()
	get_tree().paused = false

	# --- NEW LOGIC: Play saw audio if any upgrade is applied ---
	if walls_current_level > 0 or roof_current_level > 0:
		saw_audio.play()
	else:
		start_audio.play()

func _on_upgrade_walls_toggled(toggled_on: bool) -> void:
	# Only allow toggling if the button is not already disabled (meaning, not already maxed out)
	if upgrade_walls_button.disabled and toggled_on: # Prevent enabling if already maxed
		upgrade_walls_button.button_pressed = false # Revert button state if illegally toggled
		return

	var current_total_money_cents: int = ui.money_total_cents # Get current money from ui.money_total_cents
	var cost_or_refund_cents: int = WALLS_UPGRADE_COST_CENTS

	if toggled_on:
		# Check if player has enough money for walls upgrade
		if current_total_money_cents >= cost_or_refund_cents:
			walls_current_level = 1 # Walls go to level 1
			# Deduct cost from total_money_cents
			current_total_money_cents -= cost_or_refund_cents
			ui.money_total_cents = current_total_money_cents # Apply cost to ui.money_total_cents
			# Tween total money label
			_total_money_tween = _tween_label_value(self, "_current_display_total_money_cents", current_total_money_cents, 0.7, _total_money_tween)

			# If walls are now level 1, and roof is at base level 0, set roof to level 1 (initial upgrade)
			if roof_current_level == 0:
				roof_current_level = 1
				upgrade_roof_button.button_pressed = (roof_current_level == 2) # Only press if it's the final level
			upgrade_roof_button.disabled = false # Enable roof button
			print("Walls upgraded! Cost: $%.2f. Remaining money: $%.2f" % [cost_or_refund_cents / 100.0, current_total_money_cents / 100.0])
		else:
			print("Not enough money to upgrade walls! Need $%.2f, have $%.2f" % [cost_or_refund_cents / 100.0, current_total_money_cents / 100.0])
			upgrade_walls_button.button_pressed = false # Revert button state if not enough money
	else:
		# If reverting, refund the money
		if walls_current_level == 1: # Only refund if it was actually upgraded
			current_total_money_cents += cost_or_refund_cents
			ui.money_total_cents = current_total_money_cents
			# Tween total money label
			_total_money_tween = _tween_label_value(self, "_current_display_total_money_cents", current_total_money_cents, 0.7, _total_money_tween)
			print("Walls upgrade reverted. Refunded $%.2f. New money: $%.2f" % [cost_or_refund_cents / 100.0, current_total_money_cents / 100.0])

		walls_current_level = 0 # Walls revert to base
		# If walls are reverted, roof upgrade should also be reverted and disabled
		roof_current_level = 0 # Roof reverts to base
		upgrade_roof_button.button_pressed = false # Untoggle roof button
		upgrade_roof_button.disabled = true # Disable roof button
		print("Walls reverted to base.")

	# total_money.text is updated by the setter of _current_display_total_money_cents, so no direct update here.


func _on_upgrade_roof_toggled(toggled_on: bool) -> void:
	# Only allow toggling if the button is not already disabled (meaning, not already maxed out)
	if upgrade_roof_button.disabled and toggled_on: # Prevent enabling if already maxed
		upgrade_roof_button.button_pressed = false # Revert button state if illegally toggled
		return

	var current_total_money_cents: int = ui.money_total_cents # Get current money from ui.money_total_cents
	var cost_or_refund_cents: int = ROOF_UPGRADE_COST_CENTS

	# Only allow roof upgrade if walls are already upgraded (level 1 or higher)
	if walls_current_level >= 1:
		if toggled_on:
			# Check if player has enough money for roof upgrade
			if current_total_money_cents >= cost_or_refund_cents:
				roof_current_level = 2 # Roof goes to its final (Level 2) upgrade
				# Deduct cost from total_money_cents
				current_total_money_cents -= cost_or_refund_cents
				ui.money_total_cents = current_total_money_cents # Apply cost to ui.money_total_cents
				# Tween total money label
				_total_money_tween = _tween_label_value(self, "_current_display_total_money_cents", current_total_money_cents, 0.7, _total_money_tween)
				print("Roof upgraded to level 2! Cost: $%.2f. Remaining money: $%.2f" % [cost_or_refund_cents / 100.0, current_total_money_cents / 100.0])
			else:
				print("Not enough money to upgrade roof! Need $%.2f, have $%.2f" % [cost_or_refund_cents / 100.0, current_total_money_cents / 100.0])
				upgrade_roof_button.button_pressed = false # Revert button state if not enough money
		else:
			# If reverting, refund the money
			if roof_current_level == 2: # Only refund if it was actually upgraded to level 2
				current_total_money_cents += cost_or_refund_cents
				ui.money_total_cents = current_total_money_cents
				# Tween total money label
				_total_money_tween = _tween_label_value(self, "_current_display_total_money_cents", current_total_money_cents, 0.7, _total_money_tween)
				print("Roof upgrade reverted. Refunded $%.2f. New money: $%.2f" % [cost_or_refund_cents / 100.0, current_total_money_cents / 100.0])
			roof_current_level = 1 # Roof reverts to its initial upgrade (Level 1)
			print("Roof reverted to level 1.")
	else:
		# If walls are not upgraded, force roof button off and print a message
		upgrade_roof_button.button_pressed = false
		roof_current_level = 0 # Ensure roof is base if walls aren't upgraded
		print("Cannot upgrade roof until walls are upgraded!")

	# total_money.text is updated by the setter of _current_display_total_money_cents, so no direct update here.


# This function applies the correct tile source_id based on the current level
# and an array of source IDs mapping to levels.
func apply_upgrade_visuals(tilemap_layer: TileMapLayer, current_level: int, source_ids_map: Array[int]) -> void:
	if not tilemap_layer or not tilemap_layer is TileMapLayer:
		print("Error: Provided node is not a TileMapLayer or is null!")
		return

	var target_source_id: int
	if current_level >= 0 && current_level < source_ids_map.size():
		target_source_id = source_ids_map[current_level]
	else:
		# Fallback to base or print error if level is out of bounds
		printerr("Error: Invalid upgrade level %d for TileMapLayer '%s'. Using base ID." % [current_level, tilemap_layer.name])
		target_source_id = source_ids_map[0] # Use base ID as fallback

	var used_cells = tilemap_layer.get_used_cells()

	for cell_coords in used_cells:
		var current_atlas_coords = tilemap_layer.get_cell_atlas_coords(cell_coords)
		var current_alternative_tile = tilemap_layer.get_cell_alternative_tile(cell_coords)

		# Only update if the current tile's source ID is different from the target
		if tilemap_layer.get_cell_source_id(cell_coords) != target_source_id:
			tilemap_layer.set_cell(cell_coords, target_source_id, current_atlas_coords, current_alternative_tile)

	print("Tileset visual update complete for TileMapLayer: %s to level %d (Source ID: %d)" % [tilemap_layer.name, current_level, target_source_id])

# --- Function to tween a label's value ---
func _tween_label_value(target_node: Object, property_name: String, final_value: int, duration: float, existing_tween: Tween) -> Tween:
	if existing_tween and existing_tween.is_running():
		existing_tween.kill() # Stop any previous tween on this property

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(target_node, property_name, final_value, duration)
	return tween
