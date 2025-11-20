extends Node

# GameStateManager - Adapted from GodotMultiplayerDemo's game_manager.gd
# Manages game state transitions and scene changes without autoload

class_name GameStateManager

enum GameState {
	MAIN_MENU,
	SERVER_MATCHMAKING,
	HOST_MATCHMAKING,
	CLIENT_MATCHMAKING,
	SERVER_SETUP,
	HOST_SETUP,
	CLIENT_LOADING,
	GAME_SERVER,
	GAME_HOST,
	GAME_CLIENT,
}

var current_state := GameState.MAIN_MENU

# References to managers (set by main scene)
var network_manager: NetworkManager = null

##################################################################################################
# Menu functions
##################################################################################################

# NOTE: The following functions reference old UI/Matchmaking scenes which are not used
# in the current Client/Server architecture. The launcher.tscn loads either:
# - ClashRoyale/UI/Client/client_menu.tscn (for clients)
# - ClashRoyale/UI/Server/server_host.tscn (for server)
# These functions are kept for reference but should not be called.

# DEPRECATED: Use launcher.tscn -> server_host.tscn instead
#func start_server_matchmaking() -> void:
#	if current_state != GameState.MAIN_MENU:
#		return
#	get_tree().change_scene_to_file("res://ClashRoyale/UI/Matchmaking/matchmaking_lobby.tscn")
#	current_state = GameState.SERVER_MATCHMAKING
#	if network_manager != null:
#		network_manager.setup_server_matchmaking()

# DEPRECATED: Use launcher.tscn -> client_menu.tscn instead
#func start_host_matchmaking(username: String) -> void:
#	if current_state != GameState.MAIN_MENU:
#		return
#	get_tree().change_scene_to_file("res://ClashRoyale/UI/Matchmaking/matchmaking_lobby.tscn")
#	current_state = GameState.HOST_MATCHMAKING
#	if network_manager != null:
#		network_manager.setup_host_matchmaking(username)

# Used by client_menu.gd - connects to server
func join_matchmaking(ip_address: String, username: String) -> void:
	if current_state != GameState.MAIN_MENU:
		return
	# Client menu handles its own UI, just update state and call network manager
	current_state = GameState.CLIENT_MATCHMAKING
	if network_manager != null:
		network_manager.join_matchmaking(ip_address, username)

# DEPRECATED: Not used in current architecture
#func quit_to_menu() -> void:
#	if current_state not in [GameState.SERVER_MATCHMAKING, GameState.CLIENT_MATCHMAKING, GameState.HOST_MATCHMAKING]:
#		return
#	get_tree().change_scene_to_file("res://ClashRoyale/UI/Matchmaking/main_menu.tscn")
#	current_state = GameState.MAIN_MENU
#	if network_manager != null:
#		network_manager.reset()

##################################################################################################
# Game setup functions
##################################################################################################

func start_game_server() -> void:
	if current_state != GameState.SERVER_MATCHMAKING:
		return
	get_tree().change_scene_to_file("res://ClashRoyale/Arena/arena.tscn")
	current_state = GameState.SERVER_SETUP
	
func start_game_host() -> void:
	if current_state != GameState.HOST_MATCHMAKING:
		return
	get_tree().change_scene_to_file("res://ClashRoyale/Arena/arena.tscn")
	current_state = GameState.HOST_SETUP

func client_start_loading() -> void:
	if current_state != GameState.CLIENT_MATCHMAKING:
		return
	# Could add a loading screen here if needed
	current_state = GameState.CLIENT_LOADING
	
func client_game_started() -> void:
	if current_state != GameState.CLIENT_LOADING:
		return
	get_tree().change_scene_to_file("res://ClashRoyale/Arena/arena.tscn")
	current_state = GameState.GAME_CLIENT

func server_game_ready() -> void:
	if current_state == GameState.SERVER_SETUP:
		current_state = GameState.GAME_SERVER
	elif current_state == GameState.HOST_SETUP:
		current_state = GameState.GAME_HOST

##################################################################################################
# Utility functions
##################################################################################################

func is_game_active() -> bool:
	return current_state in [GameState.GAME_SERVER, GameState.GAME_HOST, GameState.GAME_CLIENT]

func is_server_or_host() -> bool:
	return current_state in [GameState.GAME_SERVER, GameState.GAME_HOST, GameState.SERVER_SETUP, GameState.HOST_SETUP]

func is_client() -> bool:
	return current_state in [GameState.GAME_CLIENT, GameState.CLIENT_LOADING]
