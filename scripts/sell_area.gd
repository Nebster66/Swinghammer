extends StaticBody2D

signal sell

@onready var sell_zone: Area2D = $Area2D

var total_value: float = 0.00

func _on_confirm_sell_pressed() -> void:
	for item in sell_zone.get_overlapping_bodies():
		if item.is_in_group("steel"):
			if "update_value_and_quality" in item:
				item.update_value_and_quality()
			total_value += (item.value * item.quality_modifier)
			item.queue_free()
	sell.emit(snapped(total_value, 0.01))
	total_value = 0.00
