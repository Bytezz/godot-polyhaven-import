@tool
extends Node

var threads: Array[Thread]
var threads_loaded: Dictionary = {}
var threads_total: Dictionary = {}
var threads_loaded_files: Array[int]
var threads_results: Array[Dictionary] = []

signal downloading(bytes_loaded, bytes_total, loadingfilenum, totalfilenum)
signal downloaded(result)

func download(urls:Array):
	if(threads.size() > 0):
		return
	
	var url:String
	var domain:String
	var splittedurl:PackedStringArray
	var formattedurls:Array = [] # [{"domain":domain, "url":url}]
	var i:int = 0
	
	while i < urls.size():
		url = urls[i]
		url = url.trim_prefix("http://")
		url = url.trim_prefix("https://")
		splittedurl = url.split("/")
		domain = splittedurl[0]
		splittedurl.remove_at(0)
		url = "/"+"/".join(splittedurl)
		formattedurls.append({"domain":domain, "url":url})
		
		i+=1
	
	i = 0
	while i < formattedurls.size():
		var formattedurl:Dictionary = formattedurls[i]
		var thread = Thread.new()
		threads.append(thread)
		thread.start(Callable(self, "_download").bind(formattedurl, i, formattedurls.size()))
		i+=1

func _download(url:Dictionary, filenum:int, totalfilenum:int):
	var err = 0
	var http = HTTPClient.new()
	var headers = ["User-Agent: Godot-Polyhaven-Import", "Accept: */*"]
	var result : Dictionary
	var rb : PackedByteArray
	var chunk
	
	rb = PackedByteArray()
	err = http.connect_to_host("https://"+url.domain)
	
	while(http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING):
		http.poll()
		OS.delay_msec(5)
	
	err = http.request(HTTPClient.METHOD_GET, url.url, headers)
	
	while (http.get_status() == HTTPClient.STATUS_REQUESTING):
		http.poll()
		OS.delay_msec(5)
	
	if(http.has_response()):
		if http.get_response_code() != 200:
			push_error("Response code: %s" % http.get_response_code())
			assert(false)
		else:
			while(http.get_status() == HTTPClient.STATUS_BODY):
				http.poll()
				chunk = http.read_response_body_chunk()
				if(chunk.size() == 0):
					OS.delay_usec(5)
				else:
					rb = rb+chunk
					call_deferred("_send_downloading_signal", rb.size(), http.get_response_body_length(), filenum, totalfilenum)
	
	result = {"url":url.url,"result":rb}
	http.close()
	
	call_deferred("_send_downloaded_signal", filenum)
	return result

func _send_downloading_signal(loaded, total, loadingfilenum, totalfilenum):
	var all_loaded: int = 0
	var all_total: int = 0
	
	threads_loaded[loadingfilenum] = loaded
	threads_total[loadingfilenum] = total
	
	for file in threads_loaded:
		all_loaded += threads_loaded[file]
		all_total += threads_total[file]
	
	emit_signal("downloading", all_loaded, all_total, threads_loaded_files.size(), totalfilenum)

func _send_downloaded_signal(filenum:int):
	var result = threads[filenum].wait_to_finish()
	threads_loaded_files.append(filenum)
	threads_results.append(result)
	
	if threads_loaded_files.size() == threads.size():
		for thread:Thread in threads:
			if thread.is_alive():
				return
		threads = []
		emit_signal("downloaded", threads_results)
