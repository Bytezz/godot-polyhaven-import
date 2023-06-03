tool

signal progress(file_name, total)

var storage_path: String
var zip_file: String

var _file_count: int

func unzip(source_file: String, destination: String):
	zip_file = source_file
	storage_path = destination
	
	var gdunzip = load('res://addons/PolyHavenImport/gdunzip.gd').new()
	
	if !gdunzip.load(zip_file):
		print('- Failed loading zip file')
		return false
		
	ProjectSettings.load_resource_pack(zip_file)
	
	_file_count = len(gdunzip.files)
	
	for f in gdunzip.files:
		unzip_file(f)
		
func unzip_file(file_name: String):
	var read_file = File.new()
	
	if read_file.file_exists("res://" + file_name):
		read_file.open(("res://" + file_name), File.READ)
		
		var content = read_file.get_buffer(read_file.get_len())
		read_file.close()
		
		var base_dir = storage_path + file_name.get_base_dir()
		
		var dir = Directory.new()
		dir.make_dir(base_dir)
		
		emit_signal("progress", file_name, _file_count)
		
		var isFolder = file_name.ends_with("/")

		if isFolder:
			dir.make_dir_recursive(storage_path + file_name)
		else:
			var writeFile = File.new()
			writeFile.open(storage_path + file_name, File.WRITE)
			writeFile.store_buffer(content)
			writeFile.close()
