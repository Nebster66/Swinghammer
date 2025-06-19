extends Control

@onready var money: Label = $Money
@onready var negative: Label = $Money/Negative
@onready var positive: Label = $Money/Positive

# Assuming your buttons are children of this Control node,
# or adjust paths as needed for your scene structure.
@onready var sell_button: Button = $"../../Inside/BuySellUI/Confirm_Sell"
@onready var buy_button: Button = $"../../Inside/BuySellUI/Confirm"
@onready var day_summary: Control = $"../../Menu/DaySummary" #day_summary.daily_income day_summary.daily_costs day_summary.aily_net day_summary.total_money

# IMPORTANT: This will now be the controlled variable.
# Any external script updating money should call ui.set_money_total_cents(new_value)
# or directly assign ui.money_total_cents = new_value, which will trigger the setter.
var money_total_cents: int = 1400:
	set(value):
		_update_money_with_tween(money_total_cents, value) # Initiate the tween
		money_total_cents = value # Update the actual stored value
		_update_daily_summary_labels() # Update daily summary after actual total changes

var daily_pence_spent: int = 0 # New variable to track total pence spent
var daily_pence_earned: int = 0 # New variable to track total pence earned

var _rolling_display_cents: int = 1400:
	set(value):
		_rolling_display_cents = value
		update_money_display()

var _positive_display_cents: int = 0:
	set(value):
		_positive_display_cents = value
		update_positive_display()

var _negative_display_cents: int = 0:
	set(value):
		_negative_display_cents = value
		update_negative_display()

var _is_tweening_money: bool = false # Flag to prevent concurrent tweens

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	modulate.a = 0.0
	negative.hide()
	positive.hide()
	update_money_display()
	update_positive_display()
	update_negative_display()
	
	# Ensure buttons are enabled initially
	_set_transaction_buttons_enabled(true)

func update_money_display() -> void:
	money.text = "$%.2f" % (float(_rolling_display_cents) / 100.0)
	# _update_daily_summary_labels() # Removed from here, called in money_total_cents setter

func update_positive_display() -> void:
	if positive.visible:
		positive.text = "+$%.2f" % (float(_positive_display_cents) / 100.0)

func update_negative_display() -> void:
	if negative.visible:
		negative.text = "-$%.2f" % (float(_negative_display_cents) / 100.0)

# Helper function to enable/disable buttons
func _set_transaction_buttons_enabled(enabled: bool) -> void:
	if sell_button:
		sell_button.disabled = not enabled
	if buy_button:
		buy_button.disabled = not enabled

func _on_main_menu_start_game() -> void:
	await get_tree().create_timer(2.0).timeout
	visible = true

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

func _on_menu_button_menu_return() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	visible = false

# New helper function to handle money updates with tweening
func _update_money_with_tween(start_cents: int, end_cents: int) -> void:
	if _is_tweening_money:
		print("Already tweening money, preventing new tween for total.")
		return # Prevent starting a new tween if one is active

	_is_tweening_money = true
	_set_transaction_buttons_enabled(false) # Disable buttons during tween

	var tween_duration: float = 0.7
	
	var tween_roll := create_tween()
	tween_roll.set_parallel(true)
	
	# Tween the _rolling_display_cents from the current display value to the target end_cents
	# This ensures a smooth transition from the currently displayed number.
	tween_roll.tween_property(self, "_rolling_display_cents", end_cents, tween_duration)
	
	tween_roll.set_ease(Tween.EASE_OUT)
	tween_roll.set_trans(Tween.TRANS_QUAD)

	await tween_roll.finished
	
	_is_tweening_money = false
	_set_transaction_buttons_enabled(true) # Re-enable buttons
	update_money_display() # Ensure final display is correct

func _on_sell_area_sell(value: float) -> void:
	if value == 0.0:
		return

	# If you want to prevent selling while a previous money tween is active, keep this check
	if _is_tweening_money:
		print("Already tweening money, ignoring sell request.")
		return
	
	var value_cents: int = int(value * 100.0 + 0.5)
	
	_positive_display_cents = value_cents
	positive.show()

	daily_pence_earned += value_cents # Update total pence earned

	# Now, instead of directly manipulating money_total_cents and then starting a tween,
	# we simply update money_total_cents, and its setter will handle the tween.
	money_total_cents += value_cents # This will trigger the setter for money_total_cents

	# Tween the positive display to disappear
	var tween_duration: float = 0.7 # This can be the same as your money tween duration
	var tween_positive_fade := create_tween()
	tween_positive_fade.tween_property(self, "_positive_display_cents", 0, tween_duration)
	tween_positive_fade.set_ease(Tween.EASE_OUT)
	tween_positive_fade.set_trans(Tween.TRANS_QUAD)
	await tween_positive_fade.finished
	positive.hide()

	print("Final Money Total (Sell): $%.2f" % (float(money_total_cents) / 100.0))
	print("Total Pence Earned: $%.2f" % (float(daily_pence_earned) / 100.0)) # Print updated total
	# _update_daily_summary_labels() is called by the money_total_cents setter

func _on_storage_purchase(price: float) -> void:
	if price == 0.0:
		return

	# If you want to prevent purchasing while a previous money tween is active, keep this check
	if _is_tweening_money:
		print("Already tweening money, ignoring purchase request.")
		return
		
	var price_cents: int = int(price * 100.0 + 0.5)

	_negative_display_cents = price_cents
	negative.show()
	
	daily_pence_spent += price_cents # Update total pence spent

	# Now, instead of directly manipulating money_total_cents and then starting a tween,
	# we simply update money_total_cents, and its setter will handle the tween.
	money_total_cents -= price_cents # This will trigger the setter for money_total_cents

	# Tween the negative display to disappear
	var tween_duration: float = 0.7
	var tween_negative_fade := create_tween()
	tween_negative_fade.tween_property(self, "_negative_display_cents", 0, tween_duration)
	tween_negative_fade.set_ease(Tween.EASE_OUT)
	tween_negative_fade.set_trans(Tween.TRANS_QUAD)
	await tween_negative_fade.finished
	negative.hide()
	update_negative_display() # Ensure it's hidden and text is correct

	print("Final Money Total (Purchase): $%.2f" % (float(money_total_cents) / 100.0))
	print("Total Pence Spent: $%.2f" % (float(daily_pence_spent) / 100.0)) # Print updated total
	# _update_daily_summary_labels() is called by the money_total_cents setter

# New function to update the daily summary labels
func _update_daily_summary_labels() -> void:
	if day_summary and is_instance_valid(day_summary):
		var daily_income_label: Label = day_summary.find_child("DailyIncome")
		var daily_costs_label: Label = day_summary.find_child("DailyCosts")
		var daily_net_label: Label = day_summary.find_child("DailyNet")
		var total_money_label: Label = day_summary.find_child("TotalMoney")

		if daily_income_label:
			daily_income_label.text = "$%.2f" % (float(daily_pence_earned) / 100.0)
		if daily_costs_label:
			daily_costs_label.text = "$%.2f" % (float(daily_pence_spent) / 100.0)
		if daily_net_label:
			var net_pence = daily_pence_earned - daily_pence_spent
			daily_net_label.text = "$%.2f" % (float(net_pence) / 100.0)
		if total_money_label:
			total_money_label.text = "$%.2f" % (float(money_total_cents) / 100.0)
	else:
		print("Warning: day_summary node not found or not valid.")


func _on_day_summary_start_game() -> void:
	await get_tree().create_timer(2.0).timeout
	visible = true

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	daily_pence_earned = 0
	daily_pence_spent = 0
