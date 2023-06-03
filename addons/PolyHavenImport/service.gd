tool
class_name Service
extends Node

const _path: String = "https://godot.azurewebsites.net%s"
const _file_folder = "user://%s"
const _asset_folder = _file_folder % "assets/%s"
const _file_path = _file_folder % "token"

var _expires: int = 0
var _id_token: String = ""
var _token_type: String = ""
var _refresh_token: String = ""

onready var _unzip = load("res://addons/PolyHavenImport/unzip.gd").new()

func _ready():
	_load_refresh_token()


func download_asset(asset_id: String, asset_name: String):
	var update = _update_id_token()
	
	if update is GDScriptFunctionState:
		yield(update, "completed")
		
	var req = HTTPRequest.new()
	add_child(req)
	
	var url = _path % "/api/purchase/download/%s" % asset_id
	var headers = ["Authorization: Bearer %s" % _id_token]
	
	req.request(url, headers, true, HTTPClient.METHOD_GET)
	
	var response = yield(req, "request_completed")
	var response_code = response[1]
	var body = response[3]
	
	if response_code != 200:
		_error("Unable to get download link for asset %s" % asset_id)
		return null

	url = body.get_string_from_utf8()
	
	var regex = RegEx.new()
	regex.compile("[^\\w\\s]");
	
	var filename = str(asset_id, "-", regex.sub(asset_name, "", true), ".zip")
	
	var dir = Directory.new()
	dir.make_dir_recursive(_asset_folder % "")
	req.download_file = _asset_folder % filename
	
	req.request(url, [], true, HTTPClient.METHOD_GET)
	
	response = yield(req, "request_completed")
	response_code = response[1]
	body = response[3]
	
	var result = null
	
	if response_code != 200:
		remove_asset(asset_id)
		_error("Unable to download asset %s" % asset_id)
	else:
		result = req.download_file
		
	remove_child(req)
	req.queue_free()
	
	return response


func install_asset(asset_id: String, directory: String):
	var asset_file = _find_asset_download_file(asset_id)
	
	_unzip.unzip(asset_file, str(directory, "/"))


func is_logged_in():
	return _refresh_token != ""


func get_list():
	var update = _update_id_token()
	
	if update is GDScriptFunctionState:
		yield(update, "completed")
	
	var req = HTTPRequest.new()
	add_child(req)
	
	var url = _path % "/api/purchase"
	var headers = ["Authorization: Bearer %s" % _id_token]
	
	req.request(url, headers, true, HTTPClient.METHOD_GET)
	
	var response = yield(req, "request_completed")
	var response_code = response[1]
	var body = response[3]
	
	var result = null

	if (response_code != 200):
		var msg = "PolyHavenImport received response_code of %s from server" % response_code
		_error(msg)
	else:		
		result = JSON.parse(body.get_string_from_utf8()).result
		
	remove_child(req)
	req.queue_free()
	
	return result


func login(access_token: String):
	_refresh_token = access_token
	_token_type = "custom"
	
	yield(_update_id_token(), "completed")
	
	return _id_token != ""


func logout():
	_clear_refresh_token()
	_refresh_token = ""
	_token_type = ""


func load_image_from_url(url: String):
	var req = HTTPRequest.new()
	add_child(req)
	
	req.request(url, [], true, HTTPClient.METHOD_GET)
	
	var result = yield(req, "request_completed")
	var response_code = result[1]
	var body = result[3]
	
	if response_code != 200:
		_error("Unable to load image %s" % url)
		return null
	
	var image = Image.new()
	image.load_jpg_from_buffer(body)
	
	remove_child(req)
	req.queue_free()
	
	return image


func remove_asset(asset_id: String):
	var path = _find_asset_download_file(asset_id)
	
	Directory.new().remove(path)


func _clear_refresh_token():
	Directory.new().remove(_file_path)


func _error(message: String):
	printerr(message)
	push_error(message)


func _find_asset_download_file(asset_id: String):
	var result = null
	var dir = Directory.new()
	var err = dir.open(_asset_folder % "")
	
	if err != OK:
		return result
	
	dir.list_dir_begin()
	
	while true:
		var file = dir.get_next()
		
		if (file == ""):
			break
		elif file.begins_with("%s-" % asset_id):
			result = _asset_folder % file
			break
	
	dir.list_dir_end()
	
	return result


func _is_asset_downloaded(asset_id: String):
	return _find_asset_download_file(asset_id ) != null


func _load_refresh_token():
	var file = File.new()
	var err = file.open_encrypted_with_pass(_file_path, File.READ, OS.get_unique_id())
	
	if (err == OK):
		_refresh_token = file.get_as_text()
		_token_type = "refresh"
		
		file.close()


func _update_id_token():
	if (OS.get_system_time_secs() < _expires):
		return 
	
	var url = _path % "/api/plugin/login"
	var headers = ["Content-Type: application/json"]
	var json = JSON.print({
		"type": _token_type,
		"token": _refresh_token
	})
	
	var req = HTTPRequest.new()
	add_child(req)
	
	req.request(url, headers, true, HTTPClient.METHOD_POST, json)
	
	var response = yield(req, "request_completed")
	var response_code = response[1]
	var body = response[3]
	
	if (response_code != 200):
		var msg = "PolyHavenImport received response_code of %s from server" % response_code
		_error(msg)
	else:
		var data = JSON.parse(body.get_string_from_utf8()).result
		
		_expires = OS.get_system_time_secs() + int(data["expiresIn"])
		_id_token = data["idToken"]
		_refresh_token = data["refreshToken"]
		_token_type = "refresh"
		
		_save_refresh_token()
		
	remove_child(req)
	req.queue_free()


func _save_refresh_token():
	var file = File.new()
	
	Directory.new().make_dir_recursive(_file_folder % "")
	
	var err = file.open_encrypted_with_pass(_file_path, File.WRITE, OS.get_unique_id())
	
	if (err == OK):
		file.store_string(_refresh_token)
		file.close()
	else:
		_error("Unable to store token")

