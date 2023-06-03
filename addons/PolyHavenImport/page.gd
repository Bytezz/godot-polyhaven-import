tool
class_name Page
extends Control

signal scene_change_requested(scene)

func navigate(scene: String):
	emit_signal("scene_change_requested", scene)

