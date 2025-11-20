extends Control

# ClientMenu - Simplified entry point for clients
# Only has "Quick Play" button to connect to server and find match

@onready var quick_play_button: Button = null
@onready var status_label: Label = null
@onready var server_ip_input: LineEdit = null
@onready var username_input: LineEdit = null

var network_manager: NetworkManager = null
var game_state_manager: GameStateManager = null
var clock_sync: ClockSync = null

var is_searching: bool = false

##################################################################################################
# Initialization
##################################################################################################

func _ready() -> void:
	_setup_managers()
	_create_ui()

func _setup_managers() -> void:
	# Check if managers already exist in /root (from previous scene)
	if get_tree().root.has_node("NetworkManager"):
		network_manager = get_tree().root.get_node("NetworkManager")
		clock_sync = get_tree().root.get_node("ClockSync")
		game_state_manager = get_tree().root.get_node("GameStateManager")
	else:
		# Create manager nodes and add to /root for persistence and consistent RPC paths
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
	network_manager.matchmaking_status_updated.connect(_on_status_updated)
	network_manager.game_started.connect(_on_game_started)

func _create_ui() -> void:
	# Background
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.1, 0.1, 0.15)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Center container
	var center_container = VBoxContainer.new()
	center_container.name = "CenterContainer"
	center_container.position = Vector2(300, 150)
	center_container.size = Vector2(400, 400)
	center_container.add_theme_constant_override("separation", 20)
	add_child(center_container)
	
	# Title
	var title = Label.new()
	title.name = "Title"
	title.text = "CLASH ROYALE CLONE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	center_container.add_child(title)
	
	# Subtitle
	var subtitle = Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "Multiplayer Tower Defense"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	center_container.add_child(subtitle)
	
	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 30)
	center_container.add_child(spacer1)
	
	# Username input
	var username_container = VBoxContainer.new()
	username_container.add_theme_constant_override("separation", 5)
	center_container.add_child(username_container)
	
	var username_label = Label.new()
	username_label.text = "Username:"
	username_label.add_theme_font_size_override("font_size", 16)
	username_container.add_child(username_label)
	
	username_input = LineEdit.new()
	username_input.name = "UsernameInput"
	username_input.placeholder_text = "Enter your name"
	username_input.text = "Player"
	username_input.custom_minimum_size = Vector2(400, 40)
	username_input.add_theme_font_size_override("font_size", 18)
	username_container.add_child(username_input)
	
	# Server IP input
	var ip_container = VBoxContainer.new()
	ip_container.add_theme_constant_override("separation", 5)
	center_container.add_child(ip_container)
	
	var ip_label = Label.new()
	ip_label.text = "Server IP:"
	ip_label.add_theme_font_size_override("font_size", 16)
	ip_container.add_child(ip_label)
	
	server_ip_input = LineEdit.new()
	server_ip_input.name = "ServerIPInput"
	server_ip_input.placeholder_text = "127.0.0.1"
	server_ip_input.text = "127.0.0.1"
	server_ip_input.custom_minimum_size = Vector2(400, 40)
	server_ip_input.add_theme_font_size_override("font_size", 18)
	ip_container.add_child(server_ip_input)
	
	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	center_container.add_child(spacer2)
	
	# Quick Play button (large and prominent)
	quick_play_button = Button.new()
	quick_play_button.name = "QuickPlayButton"
	quick_play_button.text = "QUICK PLAY"
	quick_play_button.custom_minimum_size = Vector2(400, 80)
	quick_play_button.add_theme_font_size_override("font_size", 28)
	quick_play_button.add_theme_color_override("font_color", Color(1, 1, 1))
	quick_play_button.pressed.connect(_on_quick_play_pressed)
	center_container.add_child(quick_play_button)
	
	# Status label
	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "Click Quick Play to find a match"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	center_container.add_child(status_label)
	
	# Instructions at bottom
	var instructions = Label.new()
	instructions.name = "Instructions"
	instructions.text = "Make sure the server is running before clicking Quick Play.\nYou will be matched with another player automatically."
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.position = Vector2(200, 520)
	instructions.add_theme_font_size_override("font_size", 14)
	instructions.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	add_child(instructions)

##################################################################################################
# Button handlers
##################################################################################################

func _on_quick_play_pressed() -> void:
	if is_searching:
		return
	
	var username = username_input.text.strip_edges()
	if username == "":
		username = "Player" + str(randi() % 1000)
		username_input.text = username
	
	var server_ip = server_ip_input.text.strip_edges()
	if server_ip == "":
		server_ip = "127.0.0.1"
		server_ip_input.text = server_ip
	
	is_searching = true
	quick_play_button.disabled = true
	quick_play_button.text = "SEARCHING..."
	status_label.text = "Connecting to server..."
	
	# Connect to server for matchmaking
	if game_state_manager != null:
		game_state_manager.join_matchmaking(server_ip, username)

##################################################################################################
# Signal handlers
##################################################################################################

func _on_status_updated(status: String) -> void:
	status_label.text = status
	
	# If connection failed, reset button
	if "Failed" in status or "Error" in status:
		is_searching = false
		quick_play_button.disabled = false
		quick_play_button.text = "QUICK PLAY"

func _on_game_started() -> void:
	status_label.text = "Match starting! Loading arena..."
	# Scene change will be handled by game_state_manager
