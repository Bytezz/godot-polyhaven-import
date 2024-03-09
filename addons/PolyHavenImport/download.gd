@tool
extends Node

var t = Thread.new()

signal downloading(bytes_loaded, bytes_total, loadingfilenum, totalfilenum)
signal downloaded(result)

func download(urls:Array):
	if(t.is_alive()):
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
	
	t.start(Callable(self, "_download").bind(formattedurls))

func _download(urls:Array):
	var err = 0
	var http = HTTPClient.new()
	var headers = ["User-Agent: Godot-Polyhaven-Import", "Accept: */*"]
	var results : Array = []
	var rb : PackedByteArray
	var chunk
	var url:Dictionary
	var i:int = 0
	
	while i < urls.size():
		url = urls[i]
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
						call_deferred("_send_downloading_signal", rb.size(), http.get_response_body_length(), i+1, urls.size())

		results.append({"url":url.url,"result":rb})
		http.close()
		i+=1
	call_deferred("_send_downloaded_signal")
	return results

func _send_downloading_signal(loaded, total, loadingfilenum, totalfilenum):
	emit_signal("downloading", loaded, total, loadingfilenum, totalfilenum)

func _send_downloaded_signal():
	var result = t.wait_to_finish()
	emit_signal("downloaded", result)
