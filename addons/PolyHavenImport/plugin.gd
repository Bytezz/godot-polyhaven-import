@tool
extends EditorPlugin

var _instance

func _enter_tree():
	self.connect("main_screen_changed", Callable(self, "_main_screen_changed"))
	
	_make_visible(false)


func _exit_tree():
	if _instance:
		_instance.queue_free()


func _has_main_screen():
	return true


func _make_visible(visible: bool):
	if _instance:
		_instance.visible = visible


func _get_plugin_name():
	return "Poly Haven"


func _get_plugin_icon():
	return load("res://addons/PolyHavenImport/icon.png")


func _main_screen_changed(screen_name: String):
	if screen_name == _get_plugin_name():
		if _instance == null:
			_on_scene_change_requested("res://addons/PolyHavenImport/browse.tscn")
		else:
			get_editor_interface().get_editor_main_screen().add_child(_instance)
	else:
		get_editor_interface().get_editor_main_screen().remove_child(_instance)


func _on_scene_change_requested(scene: String):
	if _instance:
		get_editor_interface().get_editor_main_screen().remove_child(_instance)
		_instance.queue_free()
	
	_instance = load(scene).instantiate()
	_instance.connect("scene_change_requested", Callable(self, "_on_scene_change_requested"))
	get_editor_interface().get_editor_main_screen().add_child(_instance)
