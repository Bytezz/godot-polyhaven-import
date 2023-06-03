tool
extends Page

const AssetResource = preload("res://addons/PolyHavenImport/asset.tscn")

onready var _service: Service = load("res://addons/PolyHavenImport/service.gd").new()

func _ready():
	add_child(_service)
	_refresh_list()


func _on_Logo_pressed():
	OS.shell_open("https://www.godotassets.com")


func _on_LogoutButton_pressed():
	_service.logout()
	navigate("res://addons/PolyHavenImport/login.tscn")


func _on_RefreshButton_pressed():
	var list = $Layout/Scroll/Content/List
	
	for n in list.get_children():
		list.remove_child(n)
		n.queue_free()
		
	_refresh_list()


func _refresh_list():
	$Layout/Padding/Header/RefreshButton.disabled = true
	
	var assets = yield(_service.get_list(), "completed")
	
	for asset in assets:
		var instance = AssetResource.instance()

		instance.asset_id = asset["asset"]["id"]
		instance.asset_name = asset["asset"]["name"]
		instance.image_path = asset["asset"]["imagePath"]
		instance.publisher = asset["asset"]["publisher"]
		instance.slug = asset["asset"]["slug"]
		instance.service = _service
		
		$Layout/Scroll/Content/List.add_child(instance)
	
	$Layout/Padding/Header/RefreshButton.disabled = false

