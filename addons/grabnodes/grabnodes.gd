@tool
extends EditorPlugin


func _enter_tree() -> void:
	# Add the custom node type to the editor
	add_custom_type("SwingObject2D", "RigidBody2D", preload("res://addons/swing_object_2d.gd"), preload("res://icon.svg"))


func _exit_tree() -> void:
	# Remove the custom node type when the plugin is disabled
	remove_custom_type("SwingObject2D")
