tool
extends Page

var entry = preload("res://addons/PolyHavenImport/entry.tscn")
onready var api = load("res://addons/PolyHavenImport/api.gd").new()

onready var ContentPanel = get_node("MarginContainer/VBoxContainer/ContentPanel")
onready var SearchInput = get_node("MarginContainer/VBoxContainer/SearchContainer/SearchInput")
onready var TypesDropDown = get_node("MarginContainer/VBoxContainer/FilterContainer/HBoxContainer/TypesDropDown")
onready var CategoriesDropDown = get_node("MarginContainer/VBoxContainer/FilterContainer/HBoxContainer2/CategoriesDropDown")
onready var AssetsGrid = get_node("MarginContainer/VBoxContainer/ContentPanel/Assets/MarginContainer/GridContainer")

var perpagenum:int = 20 # number of elements per page

func _ready():
	add_child(api)
	init()

func init():
	if not yield(api.check(), "completed"):
		ContentPanel.get_node("Assets").hide()
		ContentPanel.get_node("Error").show()
	else:
		ContentPanel.get_node("Assets").show()
		ContentPanel.get_node("Error").hide()
		
		populate_types_drop_down()
		populate_categories_drop_down()
		list_assets()

func _on_ErrorRetryBtn_pressed():
	self.init()

func populate_types_drop_down():
	var types = yield(api.types(), "completed")
	if not types:
		return
	
	TypesDropDown.clear()
	TypesDropDown.add_item("All")
	for type in types:
		TypesDropDown.add_item(type.capitalize())

func populate_categories_drop_down():
	if TypesDropDown.selected == -1:
		TypesDropDown.select(0)
	var type = TypesDropDown.get_item_text(TypesDropDown.selected).to_lower()
	
	CategoriesDropDown.clear()
	
	var categories = yield(api.categories(type), "completed")
	if not categories:
		CategoriesDropDown.add_item("All")
		return
	
	if type == "all":
		CategoriesDropDown.add_item("All")
	else:
		for category in categories:
			CategoriesDropDown.add_item(category.capitalize())

func list_assets():
	var type = TypesDropDown.get_item_text(TypesDropDown.selected).to_lower()
	var category = CategoriesDropDown.get_item_text(CategoriesDropDown.selected).to_lower()
	var search = SearchInput.text # TODO: search
	
	for child in AssetsGrid.get_children():
		child.queue_free()
	
	var assets = yield(api.assets(type, category), "completed") # TODO: sort by date
	if assets:
		for asset in assets.keys().slice(0, perpagenum-1): # TODO: pages
			var instance = entry.instance()
			
			instance.id = asset
			instance.asset_name = assets[asset]["name"]
			instance.authors = assets[asset]["authors"].keys()
			instance.categories = assets[asset]["categories"]
			instance.tags = assets[asset]["tags"]
			instance.api = api
			
			AssetsGrid.add_child(instance)

func _on_TypesDropDown_item_selected(index):
	populate_categories_drop_down()
	list_assets()

func _on_CategoriesDropDown_item_selected(index):
	list_assets()

func _on_SupportBtn_pressed():
	OS.shell_open("https://www.patreon.com/polyhaven/overview")
