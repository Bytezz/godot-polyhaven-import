tool
extends EditorPlugin

var _instance

func _enter_tree():
	self.connect("main_screen_changed", self, "_main_screen_changed")
	
	make_visible(false)


func _exit_tree():
	if _instance:
		_instance.queue_free()


func has_main_screen():
	return true


func make_visible(visible: bool):
	if _instance:
		_instance.visible = visible


func get_plugin_name():
	return "Poly Haven"


func get_plugin_icon():
	return load("res://addons/PolyHavenImport/icon.png")


func _main_screen_changed(screen_name: String):
	if screen_name == get_plugin_name():
		if _instance == null:
			_on_scene_change_requested("res://addons/PolyHavenImport/browse.tscn")
		else:
			get_editor_interface().get_editor_viewport().add_child(_instance)
	else:
		get_editor_interface().get_editor_viewport().remove_child(_instance)


func _on_scene_change_requested(scene: String):
	if _instance:
		get_editor_interface().get_editor_viewport().remove_child(_instance)
		_instance.queue_free()
	
	_instance = load(scene).instance()
	_instance.connect("scene_change_requested", self, "_on_scene_change_requested")
	get_editor_interface().get_editor_viewport().add_child(_instance)
