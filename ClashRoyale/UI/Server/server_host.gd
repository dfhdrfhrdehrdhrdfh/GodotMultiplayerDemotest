extends Node

# ServerHost - Dedicated server scene
# Runs headless server that hosts matches for clients
# Automatically matches 2 clients and starts their game

var network_manager: NetworkManager = null
var game_state_manager: GameStateManager = null
var clock_sync: ClockSync = null

var connected_clients := {}  # player_id -> {username, ready, matched}
var active_matches := []  # Array of match data

##################################################################################################
# Initialization
##################################################################################################

func _ready() -> void:
	print("=== CLASH ROYALE CLONE - DEDICATED SERVER ===")
	print("Starting server on port 6969...")
	
	_setup_managers()
	_start_server()
	
	print("Server ready and waiting for clients...")
	print("Clients can connect and will be automatically matched.")

func _setup_managers() -> void:
	# Check if managers already exist in /root (from previous scene)
	if get_tree().root.has_node("NetworkManager"):
		network_manager = get_tree().root.get_node("NetworkManager")
		clock_sync = get_tree().root.get_node("ClockSync")
		game_state_manager = get_tree().root.get_node("GameStateManager")
	else:
		# Create manager nodes and add to /root for persistence and consistent RPC paths
		# This is NOT autoload - manually created, but at root level for consistent paths
		network_manager = NetworkManager.new()
		network_manager.name = "NetworkManager"
		get_tree().root.add_child(network_manager)
		
		clock_sync = ClockSync.new()
		clock_sync.name = "ClockSync"
		get_tree().root.add_child(clock_sync)
		
		game_state_manager = GameStateManager.new()
		game_state_manager.name = "GameStateManager"
		get_tree().root.add_child(game_state_manager)
		
		# Link references
		network_manager.clock_sync = clock_sync
		network_manager.game_state_manager = game_state_manager
		clock_sync.network_manager = network_manager
		game_state_manager.network_manager = network_manager
	
	# Connect signals
	network_manager.player_connected_to_matchmaking.connect(_on_player_connected)
	network_manager.player_disconnected_from_matchmaking.connect(_on_player_disconnected)
	network_manager.match_ready.connect(_on_match_ready)

func _start_server() -> void:
	# Wait for next frame to ensure all nodes are ready in the tree
	await get_tree().process_frame
	
	# Start dedicated server - directly setup without scene change
	# Server host scene is already the server, no need to change scenes
	game_state_manager.current_state = game_state_manager.GameState.SERVER_MATCHMAKING
	network_manager.setup_server_matchmaking()
	
	# Set as dedicated server
	network_manager.is_server = true
	network_manager.is_host = true

##################################################################################################
# Matchmaking logic
##################################################################################################

func _on_player_connected(player_id: int, player_name: String) -> void:
	print("Player connected: ", player_name, " (ID: ", player_id, ")")
	
	connected_clients[player_id] = {
		"username": player_name,
		"ready": true,
		"matched": false
	}
	
	print("Total players waiting: ", _count_unmatched_players())
	
	# Try to create a match
	_try_create_match()

func _on_player_disconnected(player_id: int) -> void:
	if player_id in connected_clients:
		print("Player disconnected: ", connected_clients[player_id]["username"])
		connected_clients.erase(player_id)
	
	print("Total players waiting: ", _count_unmatched_players())

func _count_unmatched_players() -> int:
	var count = 0
	for player_id in connected_clients.keys():
		if not connected_clients[player_id]["matched"]:
			count += 1
	return count

func _try_create_match() -> void:
	# Check if we have at least 2 unmatched players
	var unmatched_players = []
	for player_id in connected_clients.keys():
		if not connected_clients[player_id]["matched"]:
			unmatched_players.append(player_id)
	
	if unmatched_players.size() >= 2:
		# Create a match with first 2 players
		var player1_id = unmatched_players[0]
		var player2_id = unmatched_players[1]
		
		_create_match(player1_id, player2_id)

func _create_match(player1_id: int, player2_id: int) -> void:
	print("\n=== CREATING MATCH ===")
	print("Player 1: ", connected_clients[player1_id]["username"], " (ID: ", player1_id, ")")
	print("Player 2: ", connected_clients[player2_id]["username"], " (ID: ", player2_id, ")")
	
	# Mark players as matched
	connected_clients[player1_id]["matched"] = true
	connected_clients[player2_id]["matched"] = true
	
	# Store match data
	var match_data = {
		"player1_id": player1_id,
		"player2_id": player2_id,
		"start_time": Time.get_ticks_msec()
	}
	active_matches.append(match_data)
	
	# Notify both players about the match
	network_manager.client_matchmaking_success.rpc_id(player1_id, player1_id, player2_id)
	network_manager.client_matchmaking_success.rpc_id(player2_id, player2_id, player1_id)
	
	print("Match created! Starting game in 2 seconds...")
	
	# Start the match after a short delay
	await get_tree().create_timer(2.0).timeout
	_start_match_for_players(player1_id, player2_id)

func _start_match_for_players(player1_id: int, player2_id: int) -> void:
	print("Starting match for players ", player1_id, " and ", player2_id)
	
	# Tell both clients to start loading
	network_manager.client_start_loading.rpc_id(player1_id)
	network_manager.client_start_loading.rpc_id(player2_id)
	
	# Give clients time to sync clocks
	await get_tree().create_timer(3.0).timeout
	
	# Tell both clients to start the game
	network_manager.client_game_started.rpc_id(player1_id)
	network_manager.client_game_started.rpc_id(player2_id)
	
	print("Match started!")
	print("======================\n")

func _on_match_ready() -> void:
	# This signal is emitted when a match is ready to start
	print("Match ready signal received")

##################################################################################################
# Server stats (optional monitoring)
##################################################################################################

func _process(_delta: float) -> void:
	# Optional: Print server stats every 10 seconds
	pass

# For debugging - print server status
func _print_server_status() -> void:
	print("\n=== SERVER STATUS ===")
	print("Connected clients: ", connected_clients.size())
	print("Active matches: ", active_matches.size())
	print("Unmatched players: ", _count_unmatched_players())
	print("====================\n")
