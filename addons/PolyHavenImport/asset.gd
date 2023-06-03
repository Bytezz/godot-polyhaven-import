tool
extends HBoxContainer

var asset_id: String
var asset_name: String
var image_path: String
var publisher: String
var slug: String
var service: Service

func _ready():
	$ButtonContainer/InstallButton.visible = service._is_asset_downloaded(asset_id)
	$ButtonContainer/RemoveButton.visible = $ButtonContainer/InstallButton.visible
	$Padding/Content/Name.bbcode_text = str("[url]", asset_name, "[/url]");
	$Padding/Content/Publisher.text = publisher
	
	_load_image()


func _load_image():
	var image = yield(service.load_image_from_url(image_path), "completed")
	
	if image == null:
		return
		
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	
	$Image.texture = texture


func _on_DownloadButton_pressed():
	$ButtonContainer/DownloadButton.disabled = true
	$ButtonContainer/InstallButton.disabled = true
	$ButtonContainer/RemoveButton.disabled = true
	
	var result = yield(service.download_asset(asset_id, asset_name), "completed")
	
	$ButtonContainer/DownloadButton.disabled = false
	$ButtonContainer/InstallButton.disabled = false
	$ButtonContainer/RemoveButton.disabled = false
	$ButtonContainer/InstallButton.visible = result != null
	$ButtonContainer/RemoveButton.visible = $ButtonContainer/InstallButton.visible 


func _on_FileDialog_dir_selected(dir: String):
	$ButtonContainer/InstallButton.disabled = false
	$ButtonContainer/DownloadButton.disabled = false
	
	service.install_asset(asset_id, dir)

func _on_InstallButton_pressed():
	$FileDialog.popup_centered(Vector2(720,480))


func _on_Name_meta_clicked(meta: String):
	OS.shell_open(str("https://www.godotassets.com/asset/", slug))


func _on_RemoveButton_pressed():
	service.remove_asset(asset_id)
	
	$ButtonContainer/InstallButton.visible = false
	$ButtonContainer/RemoveButton.visible = false

