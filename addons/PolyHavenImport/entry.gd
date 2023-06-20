tool
extends HBoxContainer

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
onready var QualityDropDown = get_node("VBoxContainer/HBoxContainer/QualityDropDown")

func _ready():
	Title.text = asset_name
	Authors.text = beautify_list(authors, false)
	Categories.text = beautify_list(categories)
	Tags.text = beautify_list(tags)
	
	load_thumb()
	files = yield(api.asset_files(id), "completed")
	populate_quality_drop_down()

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

func populate_quality_drop_down():
	if not files:
		return
	
	QualityDropDown.clear()
	for quality in files[files.keys()[0]].keys():
		QualityDropDown.add_item(quality)

func _on_Title_pressed():
	OS.shell_open("https://polyhaven.com/a/"+id)
