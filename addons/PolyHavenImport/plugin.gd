@tool
extends EditorPlugin

var _instance

func _enter_tree():
	if not Engine.is_editor_hint():
		return
	
	## Project Menu settings
	for setting in [
		["poly_haven_import/hdris_path", "res://assets/HDRIs", PROPERTY_HINT_DIR],
		["poly_haven_import/textures_path", "res://assets/textures", PROPERTY_HINT_DIR],
		["poly_haven_import/models_path", "res://assets/models", PROPERTY_HINT_DIR],
		
		["poly_haven_import/make_materials_triplanar", false, PROPERTY_HINT_NONE],
	]:
		if not ProjectSettings.has_setting(setting[0]):
			ProjectSettings.set_setting(setting[0], setting[1])
			ProjectSettings.set_initial_value(setting[0], setting[1])
			ProjectSettings.add_property_info({
				"name": setting[0],
				"type": typeof(setting[1]),
				"hint": setting[2],
			})
	
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
