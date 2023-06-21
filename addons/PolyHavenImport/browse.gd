tool
extends Page

var entry = preload("res://addons/PolyHavenImport/entry.tscn")
onready var api = load("res://addons/PolyHavenImport/api.gd").new()

onready var ContentPanel = get_node("MarginContainer/VBoxContainer/ContentPanel")
onready var SearchInput = get_node("MarginContainer/VBoxContainer/SearchContainer/SearchInput")
onready var TypesDropDown = get_node("MarginContainer/VBoxContainer/FilterContainer/HBoxContainer/TypesDropDown")
onready var CategoriesDropDown = get_node("MarginContainer/VBoxContainer/FilterContainer/HBoxContainer2/CategoriesDropDown")
onready var AssetsGrid = get_node("MarginContainer/VBoxContainer/ContentPanel/Assets/MarginContainer/VBoxContainer/GridContainer")
onready var TopPagesContainer = get_node("MarginContainer/VBoxContainer/ContentPanel/Assets/MarginContainer/VBoxContainer/TopPagesScroll/TopPagesContainer")
onready var BottomPagesContainer = get_node("MarginContainer/VBoxContainer/ContentPanel/Assets/MarginContainer/VBoxContainer/BottomPagesScroll/BottomPagesContainer")

var perpagenum:int = 40 # number of elements per page
var pagenumber:int = 0  # current page number

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
	
	var assets:Dictionary = yield(api.assets(type, category), "completed") # TODO: sort by date
	if assets:
		for child in TopPagesContainer.get_children():
			child.queue_free()
		for child in BottomPagesContainer.get_children():
			child.queue_free()
		
		var pages:int = assets.size()/perpagenum
		for page in range(pages):
			var PageBtn = Button.new()
			PageBtn.text = str(page+1)
			if pagenumber == page:
				PageBtn.disabled = true
				PageBtn.focus_mode = PageBtn.FOCUS_NONE
			else:
				PageBtn.connect("pressed", self, "goto_page", [page], CONNECT_PERSIST)
			TopPagesContainer.add_child(PageBtn)
			BottomPagesContainer.add_child(PageBtn.duplicate())
		
		for asset in assets.keys().slice(pagenumber*perpagenum, pagenumber*perpagenum+perpagenum-1):
			var instance = entry.instance()
			
			instance.id = asset
			instance.asset_name = assets[asset]["name"]
			instance.authors = assets[asset]["authors"].keys()
			instance.categories = assets[asset]["categories"]
			instance.tags = assets[asset]["tags"]
			instance.api = api
			
			AssetsGrid.add_child(instance)

func goto_page(page:int):
	pagenumber = page
	list_assets()

func _on_TypesDropDown_item_selected(index):
	pagenumber = 0
	populate_categories_drop_down()
	list_assets()

func _on_CategoriesDropDown_item_selected(index):
	pagenumber = 0
	list_assets()

func _on_SupportBtn_pressed():
	OS.shell_open("https://www.patreon.com/polyhaven/overview")
