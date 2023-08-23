tool
extends EditorPlugin

var apiurl : String = "https://api.polyhaven.com/"

func _rescan_files(): # Make editor rescan for files
	var editor_file_system := get_editor_interface().get_resource_filesystem()
	editor_file_system.scan()
	yield(editor_file_system, "sources_changed")
	return 0

func _req(url:String, json=true):
	var req = HTTPRequest.new()
	add_child(req)
	
	var error = req.request(url)
	if error != OK:
		req.queue_free()
		return false
	
	var response = yield(req, "request_completed")
	if response[1] != 200:
		req.queue_free()
		return false
	
	req.queue_free()
	if json:
		return JSON.parse(response[3].get_string_from_utf8()).result
	return response[3].get_string_from_utf8()


func check():
	if yield(_req(apiurl, false), "completed"):
		return true
	else:
		return false

func types():
	return yield(_req(apiurl+"types"), "completed")

func categories(type:String="all"):
	return yield(_req(apiurl+"categories/"+type), "completed")

func assets(type:String="all", category:String=""):
	if category == "all": category = ""
	return yield(_req(apiurl+"assets?type="+type.percent_encode()+"&categories="+category.percent_encode()), "completed")

func asset_info(id:String):
	return yield(_req(apiurl+"info/"+id), "completed")

func asset_files(id:String):
	return yield(_req(apiurl+"files/"+id), "completed")

func author_info(id:String):
	return yield(_req(apiurl+"author/"+id), "completed")

func thumb(id:String, width:int=150):
	var cdnurl = "https://cdn.polyhaven.com/asset_img/thumbs/"
	var req = HTTPRequest.new()
	add_child(req)
	
	req.request(cdnurl+id+".png?width="+str(width))
	var response = yield(req, "request_completed")
	if response[1] != 200:
		return null
	
	var image = Image.new()
	image.load_png_from_buffer(response[3])
	
	remove_child(req)
	req.queue_free()
	
	return image
