extends Control

# MatchmakingLobby - Waiting room for players to connect before match starts

@onready var status_label: Label = null
@onready var player_list: VBoxContainer = null
@onready var back_button: Button = null

var network_manager: NetworkManager = null
var game_state_manager: GameStateManager = null

##################################################################################################
# Initialization
##################################################################################################

func _ready() -> void:
	_setup_managers()
	_create_ui()
	_connect_signals()

func _setup_managers() -> void:
	# Get manager references from root or create new ones
	# Check if managers exist in tree
	if has_node("/root/NetworkManager"):
		network_manager = get_node("/root/NetworkManager")
	else:
		# Managers should be passed from previous scene, but create if missing
		network_manager = NetworkManager.new()
		network_manager.name = "NetworkManager"
		add_child(network_manager)
	
	if has_node("/root/ClockSync"):
		var clock_sync = get_node("/root/ClockSync")
	else:
		var clock_sync = ClockSync.new()
		clock_sync.name = "ClockSync"
		add_child(clock_sync)
		if network_manager != null:
			network_manager.clock_sync = clock_sync
			clock_sync.network_manager = network_manager
	
	if has_node("/root/GameStateManager"):
		game_state_manager = get_node("/root/GameStateManager")
	else:
		game_state_manager = GameStateManager.new()
		game_state_manager.name = "GameStateManager"
		add_child(game_state_manager)
		if network_manager != null:
			game_state_manager.network_manager = network_manager
			network_manager.game_state_manager = game_state_manager

func _create_ui() -> void:
	# Title
	var title = Label.new()
	title.name = "Title"
	title.text = "Matchmaking Lobby"
	title.position = Vector2(250, 50)
	title.add_theme_font_size_override("font_size", 28)
	add_child(title)
	
	# Status label
	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "Waiting for players..."
	status_label.position = Vector2(250, 120)
	status_label.add_theme_font_size_override("font_size", 18)
	add_child(status_label)
	
	# Player list container
	var list_label = Label.new()
	list_label.text = "Connected Players:"
	list_label.position = Vector2(250, 180)
	list_label.add_theme_font_size_override("font_size", 16)
	add_child(list_label)
	
	player_list = VBoxContainer.new()
	player_list.name = "PlayerList"
	player_list.position = Vector2(250, 210)
	add_child(player_list)
	
	# Back button
	back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = "Back to Menu"
	back_button.position = Vector2(250, 450)
	back_button.size = Vector2(200, 50)
	back_button.pressed.connect(_on_back_pressed)
	add_child(back_button)

func _connect_signals() -> void:
	if network_manager != null:
		network_manager.player_connected_to_matchmaking.connect(_on_player_connected)
		network_manager.player_disconnected_from_matchmaking.connect(_on_player_disconnected)
		network_manager.matchmaking_status_updated.connect(_on_status_updated)
		network_manager.match_ready.connect(_on_match_ready)

##################################################################################################
# Signal handlers
##################################################################################################

func _on_player_connected(player_id: int, player_name: String) -> void:
	var player_label = Label.new()
	player_label.name = "Player_" + str(player_id)
	player_label.text = player_name + " (ID: " + str(player_id) + ")"
	player_label.add_theme_font_size_override("font_size", 16)
	player_list.add_child(player_label)
	
	status_label.text = "Players connected: " + str(player_list.get_child_count())

func _on_player_disconnected(player_id: int) -> void:
	var player_node = player_list.get_node_or_null("Player_" + str(player_id))
	if player_node != null:
		player_list.remove_child(player_node)
		player_node.queue_free()
	
	status_label.text = "Players connected: " + str(player_list.get_child_count())

func _on_status_updated(status: String) -> void:
	status_label.text = status

func _on_match_ready() -> void:
	status_label.text = "Match starting!"
	back_button.disabled = true

func _on_back_pressed() -> void:
	if game_state_manager != null:
		game_state_manager.quit_to_menu()
