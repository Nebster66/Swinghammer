extends Control

@onready var money: Label = $Money
@onready var negative: Label = $Money/Negative
@onready var positive: Label = $Money/Positive

@onready var sell_button: Button = $"../../Inside/BuySellUI/Confirm_Sell"
@onready var buy_button: Button = $"../../Inside/BuySellUI/Confirm"
@onready var day_summary: Control = $"../../Menu/DaySummary"

var money_total_cents: int = 1400:
	set(value):
		_update_money_with_tween(money_total_cents, value)
		money_total_cents = value
		_update_daily_summary_labels()

var daily_pence_spent: int = 0
var daily_pence_earned: int = 0

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

var _is_tweening_money: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	modulate.a = 0.0
	negative.hide()
	positive.hide()
	update_money_display()
	update_positive_display()
	update_negative_display()
	_set_transaction_buttons_enabled(true)

func update_money_display() -> void:
	money.text = "$%.2f" % (float(_rolling_display_cents) / 100.0)

func update_positive_display() -> void:
	if positive.visible:
		positive.text = "+$%.2f" % (float(_positive_display_cents) / 100.0)

func update_negative_display() -> void:
	if negative.visible:
		negative.text = "-$%.2f" % (float(_negative_display_cents) / 100.0)

func _set_transaction_buttons_enabled(enabled: bool) -> void:
	if sell_button:
		sell_button.disabled = not enabled
	if buy_button:
		buy_button.disabled = not enabled

func _on_main_menu_start_game() -> void:
	await get_tree().create_timer(2.0).timeout
	visible = true
	create_tween().tween_property(self, "modulate:a", 1.0, 0.5)

func _on_menu_button_menu_return() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	visible = false

func _update_money_with_tween(start_cents: int, end_cents: int) -> void:
	if _is_tweening_money:
		print("Already tweening money, preventing new tween for total.")
		return

	_is_tweening_money = true
	_set_transaction_buttons_enabled(false)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "_rolling_display_cents", end_cents, 0.7)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)

	await tween.finished
	_is_tweening_money = false
	_set_transaction_buttons_enabled(true)
	update_money_display()

func _on_sell_area_sell(value: float) -> void:
	if value == 0.0 or _is_tweening_money:
		print("Ignoring sell request.")
		return

	var value_cents: int = int(value * 100.0 + 0.5)
	_positive_display_cents = value_cents
	positive.show()
	daily_pence_earned += value_cents
	money_total_cents += value_cents

	await _fade_out_display(positive, "_positive_display_cents")
	print("Final Money Total (Sell): $%.2f" % (float(money_total_cents) / 100.0))
	print("Total Pence Earned: $%.2f" % (float(daily_pence_earned) / 100.0))

func _on_storage_purchase(price: float) -> void:
	if price == 0.0 or _is_tweening_money:
		print("Ignoring purchase request.")
		return

	var price_cents: int = int(price * 100.0 + 0.5)
	_negative_display_cents = price_cents
	negative.show()
	daily_pence_spent += price_cents
	money_total_cents -= price_cents

	await _fade_out_display(negative, "_negative_display_cents")
	update_negative_display()
	print("Final Money Total (Purchase): $%.2f" % (float(money_total_cents) / 100.0))
	print("Total Pence Spent: $%.2f" % (float(daily_pence_spent) / 100.0))

func _fade_out_display(label: Label, property_name: String) -> void:
	var tween := create_tween()
	tween.tween_property(self, property_name, 0, 0.7)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	await tween.finished
	label.hide()

func _get_insurance_cost(level: int) -> int:
	match level:
		0: return 1500
		1: return 1000
		2: return 500
		_: return 1500

func _update_daily_summary_labels() -> void:
	if not day_summary or not is_instance_valid(day_summary):
		return

	var income_label: Label = day_summary.find_child("DailyIncome")
	var cost_label: Label = day_summary.find_child("DailyCosts")
	var net_label: Label = day_summary.find_child("DailyNet")
	var total_label: Label = day_summary.find_child("TotalMoney")
	var roof_level: int = day_summary.get("roof_current_level")
	var insurance_cents: int = _get_insurance_cost(roof_level)
	var net_pence: int = daily_pence_earned - daily_pence_spent - insurance_cents

	if income_label:
		income_label.text = "$%.2f" % (float(daily_pence_earned) / 100.0)
	if cost_label:
		cost_label.text = "$%.2f" % (float(daily_pence_spent) / 100.0)
	if net_label:
		net_label.text = "$%.2f" % (float(net_pence) / 100.0)
		net_label.add_theme_color_override("font_color", Color(1, 0, 0) if net_pence < 0 else Color(0, 1, 0))
	if total_label:
		total_label.text = "$%.2f" % (float(money_total_cents) / 100.0)

func _on_day_summary_start_game() -> void:
	await get_tree().create_timer(2.0).timeout
	visible = true
	create_tween().tween_property(self, "modulate:a", 1.0, 0.5)
	daily_pence_earned = 0
	daily_pence_spent = 0

	var insurance_label: Label = day_summary.find_child("DailyInsurance")
	if insurance_label:
		var cost = _get_insurance_cost(day_summary.get("roof_current_level"))
		insurance_label.text = "$%.2f" % (float(cost) / 100.0)

	_update_daily_summary_labels()

func _on_end_day_button_menu_return() -> void:
	var level: int = day_summary.get("roof_current_level")
	var cost: int = _get_insurance_cost(level)
	money_total_cents -= cost

	var insurance_label: Label = day_summary.find_child("DailyInsurance")
	if insurance_label:
		insurance_label.text = "$%.2f" % (float(cost) / 100.0)
	else:
		print("Warning: DailyInsurance label not found")
