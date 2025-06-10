extends StaticBody2D

signal sell

@onready var sell_zone: Area2D = $Area2D

func _on_button_pressed() -> void:
	for item in sell_zone.get_overlapping_bodies():
		if item.is_in_group("steel"):
			if "update_value_and_quality" in item:
				item.update_value_and_quality()
			sell.emit(item.value * item.quality_modifier)
			item.queue_free()
