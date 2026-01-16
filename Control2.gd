extends Control

onready var address_input = $VBoxContainer/AddressInput
onready var user_label    = $VBoxContainer/UserStats
onready var pool_label    = $VBoxContainer/PoolStats

func _ready():
	$VBoxContainer/LoadButton.connect("pressed", self, "_on_load_pressed")
	$HttpUser.connect("request_completed", self, "_on_user_response")
	$HttpPool.connect("request_completed", self, "_on_pool_response")

	user_label.text = "Enter your Bitcoin Address..."
	pool_label.text = ""


func _on_load_pressed():
	var address = address_input.text.strip_edges()
	if address == "":
		user_label.text = "Please enter your Address"
		return

	user_label.text = "Loading User-Stats..."
	pool_label.text = "Loading Pool-Stats..."

	var user_url = "https://eusolo.ckpool.org/users/" + address
	var pool_url = "https://eusolo.ckpool.org/pool/pool.status"

	$HttpUser.request(user_url)
	$HttpPool.request(pool_url)


func _on_user_response(result, response_code, headers, body):
	if response_code != 200:
		user_label.text = "User HTTP-Error: %s" % response_code
		return

	var text = body.get_string_from_utf8()
	var json = JSON.parse(text)
	if json.error != OK:
		user_label.text = "JSON Error"
		print("DEBUG User JSON:", text)
		return

	var d = json.result

	
	var total_workers = d.get("workers", 0)
	var total_hashrate = d.get("hashrate1m", "?")
	var total_shares = d.get("shares", 0)
	var bestshare = d.get("bestshare", 0)

	
	var worker_list = d.get("worker", [])
	var worker_text = ""
	for w in worker_list:
		worker_text += "%s: %s H/s, %d Shares\n" % [w.get("workername","?"), w.get("hashrate1m","?"), w.get("shares",0)]

	if total_workers == 0:
		user_label.text = "No stats found yet..."
	else:
		user_label.text = (
			"Worker-Count: %s\n" +
			"Total-Hashrate: %s\n" +
			"Total-Shares: %s\n" +
			"Best Share: %s\n\n" +
			"Individual-Workers:\n%s"
		) % [total_workers, total_hashrate, total_shares, bestshare, worker_text]


func _on_pool_response(result, response_code, headers, body):
	if response_code != 200:
		pool_label.text = "Pool HTTP-Error: %s" % response_code
		return

	var text = body.get_string_from_utf8()
	var lines = text.split("\n", false)

	var pool_info = {}
	var hashrate_info = {}
	var share_info = {}

	for line in lines:
		line = line.strip_edges()
		if line == "":
			continue

		var json = JSON.parse(line)
		if json.error != OK:
			continue

		var d = json.result

		if d.has("Users"):
			pool_info = d
		elif d.has("hashrate1m"):
			hashrate_info = d
		elif d.has("accepted"):
			share_info = d

	pool_label.text = (
		"Pool Users: %s\n" +
		"Workers: %s\n" +
		"Hashrate 1m: %s\n" +
		"Hashrate 1h: %s\n" +
		"Difficulty: %s\n" +
		"Best Share: %s"
	) % [
		pool_info.get("Users", "?"),
		pool_info.get("Workers", "?"),
		hashrate_info.get("hashrate1m", "?"),
		hashrate_info.get("hashrate1hr", "?"),
		share_info.get("diff", "?"),
		share_info.get("bestshare", "?")
	]


func _on_HttpPool_request_completed(result, response_code, headers, body):
	pass 


func _on_HttpUser_request_completed(result, response_code, headers, body):
	pass 
