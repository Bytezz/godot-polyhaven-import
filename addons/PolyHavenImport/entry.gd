@tool
extends HBoxContainer

var info : Dictionary
var id : String
var asset_name : String
var authors : Array
var categories : Array
var tags : Array
var files : Dictionary

var api

@onready var Title = get_node("VBoxContainer/Title")
@onready var Authors = get_node("VBoxContainer/Authors")
@onready var Categories = get_node("VBoxContainer/Categories")
@onready var Tags = get_node("VBoxContainer/Tags")
@onready var Thumb = get_node("Thumb")
@onready var ImportContainer = get_node("VBoxContainer/ImportContainer")
@onready var ImportBtn = get_node("VBoxContainer/ImportContainer/ImportBtn")
@onready var QualityDropDown = get_node("VBoxContainer/ImportContainer/QualityDropDown")
@onready var DownloadContainer = get_node("VBoxContainer/DownloadContainer")
@onready var DownloadProgressBar = get_node("VBoxContainer/DownloadContainer/DownloadProgressBar")
@onready var DownloadValueLabel = get_node("VBoxContainer/DownloadContainer/DownloadValueLabel")

@onready var download = load("res://addons/PolyHavenImport/download.gd").new()

func _ready() -> void:
	Title.text = asset_name
	Authors.text = beautify_list(authors, false)
	Categories.text = beautify_list(categories)
	Tags.text = beautify_list(tags)
	
	load_thumb()
	files = await api.asset_files(id)
	populate_quality_drop_down()
	
	add_child(download)
	download.connect("downloading", Callable(self, "download_progress"))
	download.connect("downloaded", Callable(self, "download_completed"))

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
	var thumb = await api.thumb(id, 150)
	if thumb == null:
		return
	
	Thumb.texture = ImageTexture.create_from_image(thumb)

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
	qualities.sort_custom(Callable(self, "sort_qualities"))
	
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
		
	elif info["type"] == 1: # Texture2D
		if "Diffuse" in files:
			fileurls.append(files["Diffuse"][quality]["png"]["url"]) # TODO: Using png directly without checking availability can be dangerous
		if "Metal" in files:
			fileurls.append(files["Metal"][quality]["png"]["url"])
		if "Rough" in files:
			fileurls.append(files["Rough"][quality]["png"]["url"])
		if "AO" in files:
			fileurls.append(files["AO"][quality]["png"]["url"])
		if "Displacement" in files:
			fileurls.append(files["Displacement"][quality]["png"]["url"])
		if "nor_gl" in files:
			fileurls.append(files["nor_gl"][quality]["png"]["url"])
		
		download.download(fileurls)
		
		ImportContainer.hide()
		DownloadContainer.show()
		
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
	var f:FileAccess
	
	if info["type"] == 0: # HDRI
		resourcepath = ProjectSettings.get_setting("poly_haven_import/hdris_path").path_join(asset_name).path_join(quality)
		DirAccess.make_dir_recursive_absolute(resourcepath)
		
		filen = asset_name+"."+results[0].url.split(".")[-1]
		f = FileAccess.open(resourcepath.path_join(filen), FileAccess.WRITE)
		f.store_buffer(results[0].result)
		f.close()
		await api._rescan_files()
		
		var resource = Sky.new()
		var panorama = PanoramaSkyMaterial.new()
		panorama.set_panorama(load(resourcepath.path_join(filen)))
		resource.set_material(panorama)
		ResourceSaver.save(resource, resourcepath.path_join(asset_name+".tres"), ResourceSaver.FLAG_CHANGE_PATH)
		api._rescan_files()
		
	elif info["type"] == 1: # Texture2D
		resourcepath = ProjectSettings.get_setting("poly_haven_import/textures_path").path_join(asset_name).path_join(quality)
		DirAccess.make_dir_recursive_absolute(resourcepath.path_join("textures"))
		
		var textures = {
			"albedo":"",
			"metallic":"",
			"rough":"",
			"ao":"",
			"depth":"",
			"normal":"",
		}
		
		for result in results:
			filen = result.url.split("/")[-1]
			var filen_path:String = resourcepath.path_join("textures").path_join(filen)
			
			if "_diff_" in filen.to_lower():
				textures["albedo"] = filen_path
			if "_metal_" in filen.to_lower():
				textures["metallic"] = filen_path
			if "_rough_" in filen.to_lower():
				textures["rough"] = filen_path
			if "_ao_" in filen.to_lower() or "_bump_" in filen.to_lower():
				textures["ao"] = filen_path
			if "_disp_" in filen.to_lower():
				textures["depth"] = filen_path
			if "_nor_gl_" in filen.to_lower():
				textures["normal"] = filen_path
			
			f = FileAccess.open(filen_path, FileAccess.WRITE)
			f.store_buffer(result.result)
			f.close()
		await api._rescan_files()
		
		var resource = StandardMaterial3D.new()
		if textures.albedo != "":
			resource.albedo_texture = load(textures.albedo)
		if textures.metallic != "":
			resource.metallic = .5
			resource.metallic_texture = load(textures.metallic)
		if textures.rough != "":
			resource.roughness_texture = load(textures.rough)
		if textures.ao != "":
			resource.ao_enabled = true
			resource.ao_texture = load(textures.ao)
		if textures.depth != "":
			resource.depth_enabled = true
			resource.depth_texture = load(textures.depth)
		if textures.normal != "":
			resource.normal_enabled = true
			resource.normal_texture = load(textures.normal)
		
		resource.uv1_triplanar = ProjectSettings.get_setting("poly_haven_import/make_materials_triplanar", false)
		
		ResourceSaver.save(resource, resourcepath.path_join(asset_name+".tres"), ResourceSaver.FLAG_CHANGE_PATH)
		api._rescan_files()
		
	elif info["type"] == 2: # Model
		resourcepath = ProjectSettings.get_setting("poly_haven_import/models_path").path_join(asset_name).path_join(quality)
		DirAccess.make_dir_recursive_absolute(resourcepath.path_join("textures"))
		
		for result in results:
			filen = result.url.split("/")[-1]
			if filen.ends_with(".jpg") or filen.ends_with(".jpeg") or filen.ends_with(".png") or filen.ends_with(".exr"):
				filen = "textures/"+filen
			f = FileAccess.open(resourcepath.path_join(filen), FileAccess.WRITE)
			f.store_buffer(result.result)
			f.close()
		api._rescan_files()

func download_progress(loaded, total, loadingfilenum, totalfilenum):
	var units:Array = ["B","KiB","MiB","GiB"]
	var sunit:int = 0
	var unit:String
	
	DownloadProgressBar.max_value = total
	DownloadProgressBar.value = loaded
	
	while total>1024 and sunit < units.size():
		total/=1024
		loaded/=1024
		sunit+=1
	unit = units[sunit]
	
	DownloadValueLabel.text = str(loaded)+unit+" / "+str(total)+unit+" ("+str(loadingfilenum)+"/"+str(totalfilenum)+")"

func download_completed(results:Array):
	DownloadContainer.hide()
	ImportContainer.show()
	
	ImportBtn.text = "Importing..."
	import(results)
	ImportBtn.text = "Re-import"
