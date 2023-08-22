tool
extends HBoxContainer

var info : Dictionary
var id : String
var asset_name : String
var authors : Array
var categories : Array
var tags : Array
var files : Dictionary

var api

onready var Title = get_node("VBoxContainer/Title")
onready var Authors = get_node("VBoxContainer/Authors")
onready var Categories = get_node("VBoxContainer/Categories")
onready var Tags = get_node("VBoxContainer/Tags")
onready var Thumb = get_node("Thumb")
onready var ImportContainer = get_node("VBoxContainer/ImportContainer")
onready var ImportBtn = get_node("VBoxContainer/ImportContainer/ImportBtn")
onready var QualityDropDown = get_node("VBoxContainer/ImportContainer/QualityDropDown")
onready var DownloadContainer = get_node("VBoxContainer/DownloadContainer")
onready var DownloadProgressBar = get_node("VBoxContainer/DownloadContainer/DownloadProgressBar")
onready var DownloadValueLabel = get_node("VBoxContainer/DownloadContainer/DownloadValueLabel")

onready var download = load("res://addons/PolyHavenImport/download.gd").new()

func _ready():
	Title.text = asset_name
	Authors.text = beautify_list(authors, false)
	Categories.text = beautify_list(categories)
	Tags.text = beautify_list(tags)
	
	load_thumb()
	files = yield(api.asset_files(id), "completed")
	populate_quality_drop_down()
	
	add_child(download)
	download.connect("downloading", self, "download_progress")
	download.connect("downloaded", self, "download_completed")

func beautify_list(list:Array, cap:bool=true):
	var out:String
	var m:int = 3
	var i:int = 0
	
	for e in list:
		if i>0:
			out += ", "
		if i>=3:
			out += "..."
			break
		
		if cap:
			e = e.capitalize()
		out += e
		
		i+=1
	
	return out

func load_thumb():
	var thumb = yield(api.thumb(id, 150), "completed")
	if thumb == null:
		return
	
	var texture = ImageTexture.new()
	texture.create_from_image(thumb)
	
	Thumb.texture = texture

static func sort_qualities(a, b):
	if a.to_int() > b.to_int():
		return true
	return false

func populate_quality_drop_down():
	if not files:
		return
	
	var qualities:Array
	
	if info["type"] == 0:
		qualities = files["hdri"].keys()
	else:
		qualities = files[files.keys()[0]].keys()
	qualities.sort_custom(self, "sort_qualities")
	
	QualityDropDown.clear()
	for quality in qualities:
		QualityDropDown.add_item(quality)

func _on_Title_pressed():
	OS.shell_open("https://polyhaven.com/a/"+id)

func _on_ImportBtn_pressed():
	if not files:
		return
	
	var quality = QualityDropDown.get_item_text(QualityDropDown.selected)
	var fileurls:Array
	
	if info["type"] == 0: # HDRI
		if "exr" in files["hdri"][quality]:
			fileurls.append(files["hdri"][quality]["exr"]["url"])
		else:
			fileurls.append(files["hdri"][quality]["hdr"]["url"])
		
		download.download(fileurls)
		
		ImportContainer.hide()
		DownloadContainer.show()
	elif info["type"] == 1: # Texture
		pass
	elif info["type"] == 2: # Model
		if "gltf" in files:
			fileurls.append(files["gltf"][quality]["gltf"]["url"])
			for i in files["gltf"][quality]["gltf"]["include"]:
				fileurls.append(files["gltf"][quality]["gltf"]["include"][i]["url"])
		elif "blend" in files:
			fileurls.append(files["blend"][quality]["blend"]["url"])
			for i in files["blend"][quality]["blend"]["include"]:
				fileurls.append(files["blend"][quality]["blend"]["include"][i]["url"])
		else:
			fileurls.append(files["fbx"][quality]["fbx"]["url"])
			for i in files["fbx"][quality]["fbx"]["include"]:
				fileurls.append(files["fbx"][quality]["fbx"]["include"][i]["url"])
		
		download.download(fileurls)
		
		ImportContainer.hide()
		DownloadContainer.show()

func import(results:Array):
	var quality = QualityDropDown.get_item_text(QualityDropDown.selected)
	var resourcepath:String
	var filen:String # filename
	var dir = Directory.new()
	var f = File.new()
	
	if info["type"] == 0: # HDRI
		resourcepath = "res://assets/HDRIs/"+asset_name+"/"+quality
		dir.make_dir_recursive(resourcepath)
		
		filen = asset_name+"."+results[0].url.split(".")[-1]
		f.open(resourcepath+"/"+filen, File.WRITE)
		f.store_buffer(results[0].result)
		f.close()
		api._rescan_files()
		yield(get_tree().create_timer(.3), "timeout")
		
		var resource = PanoramaSky.new()
		resource.panorama = load(resourcepath+"/"+filen)
		ResourceSaver.save(resourcepath+"/"+asset_name+".tres", resource, ResourceSaver.FLAG_CHANGE_PATH)
		api._rescan_files()
	elif info["type"] == 1: # Texture
		#dir.make_dir_recursive("res://assets/textures/"+asset_name)
		
		#var resource = Material.new()
		#ResourceSaver.save("res://assets/textures/"+asset_name+"/"+asset_name+".tres", resource)
		pass
	elif info["type"] == 2: # Model
		resourcepath = "res://assets/models/"+asset_name+"/"+quality
		dir.make_dir_recursive(resourcepath+"/textures")
		
		for result in results:
			filen = result.url.split("/")[-1]
			if filen.ends_with(".jpg") or filen.ends_with(".jpeg") or filen.ends_with(".png") or filen.ends_with(".exr"):
				filen = "textures/"+filen
			f.open(resourcepath+"/"+filen, File.WRITE)
			f.store_buffer(result.result)
			f.close()
		api._rescan_files()

func download_progress(loaded, total):
	DownloadProgressBar.max_value = total
	DownloadProgressBar.value = loaded
	
	DownloadValueLabel.text = str(loaded/1024/1024)+"MiB / "+str(total/1024/1024)+"MiB"

func download_completed(results:Array):
	DownloadContainer.hide()
	ImportContainer.show()
	
	ImportBtn.text = "Importing..."
	import(results)
	ImportBtn.text = "Re-import"
