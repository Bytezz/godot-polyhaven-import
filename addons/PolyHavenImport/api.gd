@tool
extends EditorPlugin

var apiurl : String = "https://api.polyhaven.com/"

func _rescan_files(): # Make editor rescan for files
	var editor_file_system := get_editor_interface().get_resource_filesystem()
	editor_file_system.scan()
	await editor_file_system.sources_changed
	return 0

func _req(url:String, json=true):
	var req = HTTPRequest.new()
	add_child(req)
	
	var error = req.request(url)
	if error != OK:
		req.queue_free()
		return false
	
	var response = await req.request_completed
	if response[1] != 200:
		req.queue_free()
		return false
	
	req.queue_free()
	if json:
		var test_json_conv = JSON.new()
		test_json_conv.parse(response[3].get_string_from_utf8())
		return test_json_conv.data
	return response[3].get_string_from_utf8()


func check():
	if await _req(apiurl, false):
		return true
	else:
		return false

func types():
	return await _req(apiurl+"types")

func categories(type:String="all"):
	return await _req(apiurl+"categories/"+type)

func assets(type:String="all", category:String=""):
	if category == "all": category = ""
	return await _req(apiurl+"assets?type="+type.uri_encode()+"&categories="+category.uri_encode())

func asset_info(id:String):
	return await _req(apiurl+"info/"+id)

func asset_files(id:String):
	return await _req(apiurl+"files/"+id)

func author_info(id:String):
	return await _req(apiurl+"author/"+id)

func thumb(id:String, width:int=150):
	var cdnurl = "https://cdn.polyhaven.com/asset_img/thumbs/"
	var req = HTTPRequest.new()
	add_child(req)
	
	req.request(cdnurl+id+".png?width="+str(width))
	var response = await req.request_completed
	if response[1] != 200:
		return null
	
	var image = Image.new()
	image.load_png_from_buffer(response[3])
	
	remove_child(req)
	req.queue_free()
	
	return image
