extends Control

@onready var money: Label = $Money

var money_total: float = 14.00

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	modulate.a = 0.0

func _on_main_menu_start_game() -> void:
	await get_tree().create_timer(2.0).timeout
	visible = true

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5) # Fade in over 0.5 seconds


func _on_menu_button_menu_return() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5) # Fade out over 0.5 seconds
	await tween.finished
	visible = false # Only hide after fade-out completes


func _on_sell_area_sell(value,) -> void:
	money_total += snapped(value, 0.01)
	print(money_total)
	money.set_text(str(money_total))


func _on_storage_purchase(price) -> void:
	money_total -= price
	money.set_text(str(money_total))
