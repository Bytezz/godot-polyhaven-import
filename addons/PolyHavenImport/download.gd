tool
extends Node

var t = Thread.new()

signal downloading(bytes_loaded, bytes_total)
signal downloaded(result)

func download(url:String):
	if(t.is_active()):
		return
	
	var domain:String
	var splittedurl:PoolStringArray
	
	url = url.trim_prefix("http://")
	url = url.trim_prefix("https://")
	splittedurl = url.split("/")
	domain = splittedurl[0]
	splittedurl.remove(0)
	url = "/"+"/".join(splittedurl)
	
	t.start(self, "_download", {"domain":domain, "url":url})

func _download(params):
	var err = 0
	var http = HTTPClient.new()
	var headers = ["User-Agent: Godot-Polyhaven-Import", "Accept: */*"]
	var rb : PoolByteArray
	var chunk
	
	err = http.connect_to_host(params.domain, -1, true)

	while(http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING):
		http.poll()
		OS.delay_msec(100)

	err = http.request(HTTPClient.METHOD_GET, params.url, headers)

	while (http.get_status() == HTTPClient.STATUS_REQUESTING):
		http.poll()
		OS.delay_msec(500)
# 
	if(http.has_response()):
		while(http.get_status() == HTTPClient.STATUS_BODY):
			http.poll()
			chunk = http.read_response_body_chunk()
			if(chunk.size() == 0):
				OS.delay_usec(100)
			else:
				rb = rb+chunk
				call_deferred("_send_downloading_signal", rb.size(), http.get_response_body_length())

	call_deferred("_send_downloaded_signal")
	http.close()
	return rb

func _send_downloading_signal(loaded, total):
	emit_signal("downloading", loaded, total)

func _send_downloaded_signal():
	var result = t.wait_to_finish()
	emit_signal("downloaded", result)
