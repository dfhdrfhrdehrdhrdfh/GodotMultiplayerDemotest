extends Control

# MainMenu - Entry point for the Clash Royale clone
# Allows player to host, join, or start a server

@onready var username_input: LineEdit = null
@onready var ip_input: LineEdit = null
@onready var host_button: Button = null
@onready var join_button: Button = null
@onready var server_button: Button = null

var network_manager: NetworkManager = null
var game_state_manager: GameStateManager = null

##################################################################################################
# Initialization
##################################################################################################

func _ready() -> void:
	_setup_managers()
	_create_ui()

func _setup_managers() -> void:
	# Create manager nodes
	network_manager = NetworkManager.new()
	network_manager.name = "NetworkManager"
	add_child(network_manager)
	
	var clock_sync = ClockSync.new()
	clock_sync.name = "ClockSync"
	add_child(clock_sync)
	
	game_state_manager = GameStateManager.new()
	game_state_manager.name = "GameStateManager"
	add_child(game_state_manager)
	
	# Link references
	network_manager.clock_sync = clock_sync
	network_manager.game_state_manager = game_state_manager
	clock_sync.network_manager = network_manager
	game_state_manager.network_manager = network_manager

func _create_ui() -> void:
	# Title
	var title = Label.new()
	title.name = "Title"
	title.text = "Clash Royale Clone - Multiplayer"
	title.position = Vector2(200, 50)
	title.add_theme_font_size_override("font_size", 32)
	add_child(title)
	
	# Username input
	var username_label = Label.new()
	username_label.text = "Username:"
	username_label.position = Vector2(250, 150)
	username_label.add_theme_font_size_override("font_size", 18)
	add_child(username_label)
	
	username_input = LineEdit.new()
	username_input.name = "UsernameInput"
	username_input.placeholder_text = "Enter your name"
	username_input.text = "Player1"
	username_input.position = Vector2(250, 180)
	username_input.size = Vector2(300, 40)
	add_child(username_input)
	
	# IP address input
	var ip_label = Label.new()
	ip_label.text = "Server IP:"
	ip_label.position = Vector2(250, 240)
	ip_label.add_theme_font_size_override("font_size", 18)
	add_child(ip_label)
	
	ip_input = LineEdit.new()
	ip_input.name = "IPInput"
	ip_input.placeholder_text = "127.0.0.1"
	ip_input.text = "127.0.0.1"
	ip_input.position = Vector2(250, 270)
	ip_input.size = Vector2(300, 40)
	add_child(ip_input)
	
	# Host button
	host_button = Button.new()
	host_button.name = "HostButton"
	host_button.text = "Host Game"
	host_button.position = Vector2(250, 340)
	host_button.size = Vector2(140, 50)
	host_button.pressed.connect(_on_host_pressed)
	add_child(host_button)
	
	# Join button
	join_button = Button.new()
	join_button.name = "JoinButton"
	join_button.text = "Join Game"
	join_button.position = Vector2(410, 340)
	join_button.size = Vector2(140, 50)
	join_button.pressed.connect(_on_join_pressed)
	add_child(join_button)
	
	# Server button
	server_button = Button.new()
	server_button.name = "ServerButton"
	server_button.text = "Start Dedicated Server"
	server_button.position = Vector2(250, 410)
	server_button.size = Vector2(300, 50)
	server_button.pressed.connect(_on_server_pressed)
	add_child(server_button)
	
	# Instructions
	var instructions = Label.new()
	instructions.text = "Host: Create a game and wait for opponent\nJoin: Connect to an existing game\nServer: Run headless server for hosting"
	instructions.position = Vector2(200, 480)
	instructions.add_theme_font_size_override("font_size", 14)
	add_child(instructions)

##################################################################################################
# Button handlers
##################################################################################################

func _on_host_pressed() -> void:
	var username = username_input.text if username_input.text != "" else "Host"
	if game_state_manager != null:
		game_state_manager.start_host_matchmaking(username)

func _on_join_pressed() -> void:
	var username = username_input.text if username_input.text != "" else "Client"
	var ip = ip_input.text if ip_input.text != "" else "127.0.0.1"
	if game_state_manager != null:
		game_state_manager.join_matchmaking(ip, username)

func _on_server_pressed() -> void:
	if game_state_manager != null:
		game_state_manager.start_server_matchmaking()
