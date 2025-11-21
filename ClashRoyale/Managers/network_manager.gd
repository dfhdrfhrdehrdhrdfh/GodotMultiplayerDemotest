extends Node

# NetworkManager - Adapted from GodotMultiplayerDemo's multiplayer_manager.gd
# Handles all networking for Clash Royale clone without autoload
# Manages client-server communication, troop synchronization, and matchmaking

class_name NetworkManager

# Preload resources
const PORT = 6969
const MAX_CLIENTS = 2  # 1v1 game
const clock_sync_delay := 3.0
const player_connection_wait := 0.5

var is_host := false
var is_server := false

##################################################################################################
# Server variables
##################################################################################################

var connected_players := {}  # Dictionary of player_id -> player_data
var troops_dict := {}  # Dictionary of player_id -> {troop_id -> troop}
var towers_dict := {}  # Dictionary of player_id -> {tower_id -> tower}

const hard_reset_distance = 100
const soft_correction_distance = 1
const soft_correction_rate = 0.01
var server_tick_rate := 1.0 / Engine.physics_ticks_per_second

signal player_connected_to_matchmaking(player_id: int, player_name: String)
signal player_disconnected_from_matchmaking(player_id: int)
signal match_ready()  # Both players connected
signal troop_spawned_server(troop_data: Dictionary)
signal tower_destroyed(tower_id: int, player_id: int)

##################################################################################################
# Client variables
##################################################################################################

var local_player_id: int
var opponent_player_id: int
var username: String
var server_tick: int
var ping_in_ms := 0

signal matchmaking_status_updated(status: String)
signal game_started()
signal troop_spawned_client(troop_data: Dictionary)
signal troop_position_updated(troop_id: int, position: Vector2)
signal troop_health_updated(troop_id: int, health: int)
signal tower_health_updated(tower_id: int, player_id: int, health: int)
signal elixir_updated(elixir: int)
signal ping_calculated(ping: int)

# References to managers (set by main scene)
var clock_sync: Node = null
var game_state_manager: Node = null

##################################################################################################
# Shared functions
##################################################################################################

func reset() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	username = ""
	connected_players = {}
	troops_dict = {}
	towers_dict = {}
	is_host = false
	is_server = false

##################################################################################################
# Client functions
##################################################################################################

func join_matchmaking(ip_address: String, username_: String) -> void:
	var peer := ENetMultiplayerPeer.new()
	var error = peer.create_client(ip_address, PORT)
	if error != OK:
		matchmaking_status_updated.emit("Failed to connect to server")
		return
	multiplayer.multiplayer_peer = peer
	username = username_
	matchmaking_status_updated.emit("Connecting to server...")
	
@rpc("authority", "call_local", "reliable")
func client_matchmaking_success(player_id: int, opponent_id: int) -> void:
	local_player_id = player_id
	opponent_player_id = opponent_id
	matchmaking_status_updated.emit("Match found! Preparing game...")
	
@rpc("authority", "call_local", "reliable")
func client_start_loading() -> void:
	if clock_sync != null:
		clock_sync.start_sync()
	if game_state_manager != null:
		game_state_manager.client_start_loading()

@rpc("authority", "call_local", "reliable")
func client_game_started() -> void:
	game_started.emit()
	if game_state_manager != null:
		game_state_manager.client_game_started()

# Client sends troop spawn request to server
func request_spawn_troop(card_id: int, spawn_position: Vector2) -> void:
	if is_host:
		# Host directly spawns
		_spawn_troop_on_server(local_player_id, card_id, spawn_position)
	else:
		# Client requests spawn from server
		server_spawn_troop.rpc_id(1, card_id, spawn_position)

@rpc("any_peer", "call_remote", "reliable")
func server_spawn_troop(card_id: int, spawn_position: Vector2) -> void:
	if not is_host:
		return
	var player_id = multiplayer.get_remote_sender_id()
	_spawn_troop_on_server(player_id, card_id, spawn_position)

func _spawn_troop_on_server(player_id: int, card_id: int, spawn_position: Vector2) -> void:
	# Server-side troop spawn logic
	var troop_data = {
		"player_id": player_id,
		"card_id": card_id,
		"position": spawn_position,
		"troop_id": Time.get_ticks_msec() + player_id * 100000  # Unique ID
	}
	
	if player_id not in troops_dict:
		troops_dict[player_id] = {}
	
	troop_spawned_server.emit(troop_data)
	
	# Notify all clients about the new troop
	client_receive_troop_spawn.rpc(troop_data)

@rpc("authority", "call_local", "reliable")
func client_receive_troop_spawn(troop_data: Dictionary) -> void:
	troop_spawned_client.emit(troop_data)

# Receive game state from server (troops, towers, elixir)
@rpc("authority", "call_local", "unreliable")
func receive_game_state(game_state_data: Dictionary) -> void:
	if is_host:
		return
	
	server_tick = game_state_data.get("tick", 0)
	
	# Update troops
	if game_state_data.has("troops"):
		for troop_info in game_state_data["troops"]:
			troop_position_updated.emit(troop_info["id"], Vector2(troop_info["x"], troop_info["y"]))
			troop_health_updated.emit(troop_info["id"], troop_info["health"])
	
	# Update towers
	if game_state_data.has("towers"):
		for tower_info in game_state_data["towers"]:
			tower_health_updated.emit(tower_info["id"], tower_info["player_id"], tower_info["health"])
	
	# Update elixir for local player
	if game_state_data.has("elixir"):
		var elixir_data = game_state_data["elixir"]
		if elixir_data.has(str(local_player_id)):
			elixir_updated.emit(elixir_data[str(local_player_id)])
	
	ping_calculated.emit(ping_in_ms)

##################################################################################################
# Server functions
##################################################################################################

func setup_multiplayer_server() -> void:
	is_host = true
	var peer := ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CLIENTS)
	if error != OK:
		print("Failed to create server")
		return
	peer.peer_connected.connect(_on_peer_connected_to_matchmaking)
	peer.peer_disconnected.connect(_on_peer_disconnected_from_matchmaking)
	multiplayer.multiplayer_peer = peer
	print("Server started on port ", PORT)

func setup_server_matchmaking() -> void:
	setup_multiplayer_server()
	is_server = true
	
func setup_host_matchmaking(username_: String) -> void:
	setup_multiplayer_server()
	username = username_
	local_player_id = 1
	connected_players[1] = {
		"username": username_,
		"ready": false
	}
	player_connected_to_matchmaking.emit(1, username_)
	
func _on_peer_connected_to_matchmaking(id: int) -> void:
	print("Peer connected: ", id)
	connected_players[id] = {
		"username": "Player_" + str(id),
		"ready": false
	}
	
	# Wait a bit for connection to stabilize
	await get_tree().create_timer(player_connection_wait).timeout
	
	# Request username
	request_client_username.rpc_id(id)
	
	# Check if we have 2 players for matchmaking
	if len(connected_players) == 2:
		_start_match()

@rpc("authority", "call_local", "reliable")
func request_client_username() -> void:
	send_username_to_server.rpc_id(1, username)

@rpc("any_peer", "call_remote", "reliable")
func send_username_to_server(client_username: String) -> void:
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id in connected_players:
		connected_players[sender_id]["username"] = client_username
		player_connected_to_matchmaking.emit(sender_id, client_username)

func _on_peer_disconnected_from_matchmaking(id: int) -> void:
	print("Peer disconnected: ", id)
	player_disconnected_from_matchmaking.emit(id)
	connected_players.erase(id)

func _start_match() -> void:
	print("Match starting with 2 players!")
	var player_ids = connected_players.keys()
	
	# Notify both players about the match
	for pid in player_ids:
		var opponent_id = player_ids[1] if player_ids[0] == pid else player_ids[0]
		if pid == 1:
			# Host
			client_matchmaking_success(pid, opponent_id)
		else:
			# Client
			client_matchmaking_success.rpc_id(pid, pid, opponent_id)
	
	match_ready.emit()
	
	# Start game after a delay
	await get_tree().create_timer(1.0).timeout
	start_game()

func start_game() -> void:
	client_start_loading.rpc()
	if not is_server:
		client_start_loading()
	
	# Give clients time to sync clocks
	await get_tree().create_timer(clock_sync_delay).timeout
	
	client_game_started.rpc()
	if not is_server:
		client_game_started()

func _physics_process(_delta: float) -> void:
	if not is_host:
		return
	
	if game_state_manager == null:
		return
		
	if not game_state_manager.is_game_active():
		return
	
	# Build and send game state to all clients
	var game_state = _build_game_state()
	receive_game_state.rpc(game_state)

func _build_game_state() -> Dictionary:
	var state = {
		"tick": clock_sync.tick if clock_sync != null else 0,
		"troops": [],
		"towers": [],
		"elixir": {}
	}
	
	# Add troop data
	for player_id in troops_dict.keys():
		for troop_id in troops_dict[player_id].keys():
			var troop = troops_dict[player_id][troop_id]
			if troop != null and is_instance_valid(troop):
				state["troops"].append({
					"id": troop.troop_id,
					"player_id": player_id,
					"x": troop.position.x,
					"y": troop.position.y,
					"health": troop.health
				})
	
	# Add tower data
	for player_id in towers_dict.keys():
		for tower_id in towers_dict[player_id].keys():
			var tower = towers_dict[player_id][tower_id]
			if tower != null and is_instance_valid(tower):
				state["towers"].append({
					"id": tower.tower_id,
					"player_id": player_id,
					"health": tower.health
				})
	
	return state

func register_troop(troop: Node, player_id: int, troop_id: int) -> void:
	if player_id not in troops_dict:
		troops_dict[player_id] = {}
	troops_dict[player_id][troop_id] = troop

func unregister_troop(player_id: int, troop_id: int) -> void:
	if player_id in troops_dict:
		troops_dict[player_id].erase(troop_id)

func register_tower(tower: Node, player_id: int, tower_id: int) -> void:
	if player_id not in towers_dict:
		towers_dict[player_id] = {}
	towers_dict[player_id][tower_id] = tower

func unregister_tower(player_id: int, tower_id: int) -> void:
	if player_id in towers_dict:
		towers_dict[player_id].erase(tower_id)
	tower_destroyed.emit(tower_id, player_id)
