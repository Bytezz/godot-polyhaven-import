tool
extends Node

var t = Thread.new()

signal downloading(bytes_loaded, bytes_total)
signal downloaded(result)

func download(urls:Array):
	if(t.is_active()):
		return
	
	var url:String
	var domain:String
	var splittedurl:PoolStringArray
	var formattedurls:Array = [] # [{"domain":domain, "url":url}]
	var i:int = 0
	
	while i < urls.size():
		url = urls[i]
		url = url.trim_prefix("http://")
		url = url.trim_prefix("https://")
		splittedurl = url.split("/")
		domain = splittedurl[0]
		splittedurl.remove(0)
		url = "/"+"/".join(splittedurl)
		formattedurls.append({"domain":domain, "url":url})
		
		i+=1
	
	t.start(self, "_download", formattedurls)

func _download(urls):
	var err = 0
	var http = HTTPClient.new()
	var headers = ["User-Agent: Godot-Polyhaven-Import", "Accept: */*"]
	var results : Array = []
	var rb : PoolByteArray
	var chunk
	
	for url in urls:
		rb = PoolByteArray()
		err = http.connect_to_host(url.domain, -1, true)

		while(http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING):
			http.poll()
			OS.delay_msec(100)

		err = http.request(HTTPClient.METHOD_GET, url.url, headers)

		while (http.get_status() == HTTPClient.STATUS_REQUESTING):
			http.poll()
			OS.delay_msec(500)
		
		if(http.has_response()):
			while(http.get_status() == HTTPClient.STATUS_BODY):
				http.poll()
				chunk = http.read_response_body_chunk()
				if(chunk.size() == 0):
					OS.delay_usec(100)
				else:
					rb = rb+chunk
					call_deferred("_send_downloading_signal", rb.size(), http.get_response_body_length())

		results.append({"url":url.url,"result":rb})
		http.close()
	call_deferred("_send_downloaded_signal")
	return results

func _send_downloading_signal(loaded, total):
	emit_signal("downloading", loaded, total)

func _send_downloaded_signal():
	var result = t.wait_to_finish()
	emit_signal("downloaded", result)
