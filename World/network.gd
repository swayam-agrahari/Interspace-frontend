# Network.gd (Attach to the Network node)
extends Node

@onready var websocket_client = get_node("/root/Main/World/WebSocketClient") # RefeCrence to WebSocke4tClient node
var player_scene = preload("res://Player/player.tscn")
var network_player = preload("res://Player/networkplayer.tscn")
var pending_join_request = null
var userID
var players = {}  # Dictionary to store player instances
var local_player_id = null
var last_sent_position = Vector2.ZERO
@onready var player_list = $PlayerList




func _ready():
	# Connect to the WebSocket server

	
	websocket_client.connect_to_url("ws://4.240.40.227/ws/")	

	# Connect signals to methods
	websocket_client.connect("connected_to_server", Callable(self, "_on_connected_to_server"))
	websocket_client.connect("connection_closed", Callable(self, "_on_connection_closed"))
	websocket_client.connect("message_received", Callable(self, "_on_message_received"))

	print("Attempting to connect to WebSocket server...")
	


func _on_connected_to_server():
	print("Connected to WebSocket server!")
	if pending_join_request:
		var space_id = pending_join_request["space_id"]
		var token = pending_join_request["token"]
		_send_join_request(space_id, token)
		pending_join_request = null
	

func _on_connection_closed():
	print("Connection to WebSocket server closed.")



func send_message(message: String):
	websocket_client.send(message)

func close_connection():
	websocket_client.close(1000, "Normal closure")

var join_in_progress = false  # Add this line at the top of the script

func join_space(space_id: String, token: String):
	print("Join game requested with Space ID: %s, Token: %s" % [space_id, token])

	# If websocket is not connected yet, store the request
	
	print("WebSocket not connected yet, storing join request...")
	pending_join_request = {
		"space_id": space_id,
		"token": token
	}
	if websocket_client and websocket_client.has_method("get_ready_state"):
		if websocket_client.get_ready_state() == WebSocketPeer.STATE_OPEN:
			print("WebSocket is connected!")
			_send_join_request(space_id, token)
		else:
			print("WebSocket not connected yet, storing join request...")
	



func _send_join_request(space_id: String, token: String):
	var payload = {
		"type": "join",
		"payload": {
		"spaceId": space_id,
		"token": token
		}
	}
	websocket_client.send(JSON.stringify(payload))
	print("Join space payload sent: %s" % payload)



func spawn_player(x: float, y: float, user_id: String):
	print("Attempting to spawn player with ID: %s" % [user_id])
	var lp: CharacterBody2D = player_scene.instantiate()
	print("lp",lp)
	userID = user_id
	lp.set_name(user_id)
	lp.position = Vector2(x,y)
	player_list.add_child(lp)
	
	
func _spawn_network_player(x,y,user_id) -> void:
	var np: CharacterBody2D = network_player.instantiate()
	np.set_name(user_id)
	np.position = Vector2(x, y)
	player_list.add_child(np)

func handle_space_joined(data: Dictionary):
	var spawn_data = data["payload"]["spawn"]
	var user_id = data["payload"]["userId"]
	local_player_id = user_id  # Set local player ID
	print("Local player ID set to: %s" % local_player_id)

	# Only spawn the local player in the local instance
	if user_id == local_player_id:
		spawn_player(spawn_data.x, spawn_data.y, user_id)

	# Spawn other players (remote players)
	if data.has("users"):
		print("users in space-join", data["users"])
		for user in data["users"]:
			if user["id"] != local_player_id:  # Only spawn remote players
				_spawn_network_player(user.x, user.y, user["id"])


func handle_user_join(data: Dictionary):
	print("user-join got",data)
	var user_id = data["payload"]["userId"]
	var x = data["payload"]["x"]
	var y = data["payload"]["y"]
	print("localid",local_player_id)
	if user_id != local_player_id:
		_spawn_network_player(x, y, user_id)

func send_movement(x: float, y: float):
	if not local_player_id:
		print("Error: Local player ID not set")
		return
		
	var current_pos = Vector2(x, y)
	if current_pos == last_sent_position:
		return

	last_sent_position = current_pos
	
	var payload = {
		"type": "move",
		"payload": {
			"x": int(x),
			"y": int(y)
		}
	}
	websocket_client.send(JSON.stringify(payload))
	print("Sent move request for local player %s: %s" % [local_player_id, payload])

func handle_move(data: Dictionary):
	var user_id = data["payload"]["userId"]
	var new_x = data["payload"]["x"]
	var new_y = data["payload"]["y"]
	print("Received move for player %s to position (%s, %s)" % [user_id, new_x, new_y])

	# Only handle movement for other players (not our local player)
	print("handle move local id", local_player_id)
	if user_id != local_player_id:
		for player in player_list.get_children():
			if player.name == user_id:
			# Call update_network_position on the network player
					if player.has_method("update_network_position"):
						print("Updating network player position:", player.name)
						player.update_network_position(new_x, new_y)

func reject_player_position(data: Dictionary):
	if not local_player_id:
		print("Error: Local player ID not set during movement rejection")
		return
		
	if not players.has(local_player_id):
		print("Error: Local player not found in players dictionary during movement rejection")
		return
		
	var x = data["payload"]["x"]
	var y = data["payload"]["y"]
	
	var player_instance = players[local_player_id]
	player_instance.position = Vector2(x, y)  # Reset to server-provided position
	last_sent_position = Vector2(x, y)  # Update last sent position
	print("Movement rejected for local player %s. Position reset to: %s, %s" % [local_player_id, x, y])

func _on_message_received(message: Variant):
	if typeof(message) != TYPE_STRING:
		print("Error: Received non-string message")
		return
		
	var json = JSON.new()
	var json_result = json.parse(message)
	if json_result != OK:
		print("Error parsing JSON message")
		return
		
	var parsed_message = json.get_data()
	if typeof(parsed_message) != TYPE_DICTIONARY or not parsed_message.has("type"):
		print("Error: Invalid message format")
		return
		
	match parsed_message["type"]:
		"space-joined":
			handle_space_joined(parsed_message)
		"user-join":
			handle_user_join(parsed_message)
		"move":
			handle_move(parsed_message)
		"movement-rejected":
			reject_player_position(parsed_message)
		
