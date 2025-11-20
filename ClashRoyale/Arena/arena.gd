extends Node2D

# Arena - Main game scene for Clash Royale clone
# Manages game loop, troop spawning, and synchronization

class_name Arena

##################################################################################################
# Manager references (initialized in _ready)
##################################################################################################

var network_manager: NetworkManager = null
var clock_sync: ClockSync = null
var game_state_manager: GameStateManager = null

##################################################################################################
# Game objects
##################################################################################################

var local_troops := {}  # Dictionary of troop_id -> troop node
var enemy_troops := {}  # Dictionary of troop_id -> troop node
var local_towers := {}  # Dictionary of tower_id -> tower node
var enemy_towers := {}  # Dictionary of tower_id -> tower node

##################################################################################################
# Player data
##################################################################################################

var local_player_id: int = 0
var elixir: int = 5
var max_elixir: int = 10
var elixir_regen_rate: float = 1.0  # Elixir per second

##################################################################################################
# Nodes
##################################################################################################

@onready var game_hud: Control = null
@onready var spawn_area: Control = null

##################################################################################################
# Initialization
##################################################################################################

func _ready() -> void:
	# Initialize managers
	_setup_managers()
	
	# Setup arena
	_setup_arena()
	
	# Connect signals
	_connect_signals()
	
	# Start elixir generation
	var elixir_timer = Timer.new()
	elixir_timer.name = "ElixirTimer"
	elixir_timer.wait_time = 1.0 / elixir_regen_rate
	elixir_timer.timeout.connect(_on_elixir_timer_timeout)
	add_child(elixir_timer)
	elixir_timer.start()

func _setup_managers() -> void:
	# Get managers from /root (they should already exist from previous scenes)
	# This ensures consistent RPC paths without using autoloads
	if get_tree().root.has_node("NetworkManager"):
		network_manager = get_tree().root.get_node("NetworkManager")
		clock_sync = get_tree().root.get_node("ClockSync")
		game_state_manager = get_tree().root.get_node("GameStateManager")
	else:
		# Fallback: create if they don't exist (shouldn't happen in normal flow)
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
	
	# Get local player ID
	local_player_id = network_manager.local_player_id
	
	# Mark game as ready
	if network_manager.is_host or network_manager.is_server:
		game_state_manager.server_game_ready()

func _setup_arena() -> void:
	# Create arena floor/background
	var arena_bg = ColorRect.new()
	arena_bg.name = "ArenaBackground"
	arena_bg.color = Color(0.2, 0.6, 0.3)  # Green for grass
	arena_bg.size = Vector2(600, 800)
	arena_bg.position = Vector2(-300, -400)
	arena_bg.z_index = -10
	add_child(arena_bg)
	
	# Create river/bridge in the middle
	var river = ColorRect.new()
	river.name = "River"
	river.color = Color(0.2, 0.4, 0.8)  # Blue for water
	river.size = Vector2(600, 50)
	river.position = Vector2(-300, -25)
	river.z_index = -5
	add_child(river)
	
	# Create spawn areas (visual indicators)
	_create_spawn_areas()
	
	# Create towers
	_create_towers()
	
	# Create HUD
	_create_hud()
	
	# Create camera
	var camera = Camera2D.new()
	camera.name = "Camera"
	add_child(camera)
	camera.make_current()

func _create_spawn_areas() -> void:
	# Player spawn area (always bottom half from their perspective)
	var player_area = ColorRect.new()
	player_area.name = "PlayerSpawnArea"
	player_area.color = Color(0.3, 0.7, 0.3, 0.3)  # Semi-transparent green
	player_area.size = Vector2(600, 350)
	player_area.position = Vector2(-300, 25)
	player_area.z_index = -8
	add_child(player_area)
	
	# Enemy area (always top half from player perspective)
	var enemy_area = ColorRect.new()
	enemy_area.name = "EnemySpawnArea"
	enemy_area.color = Color(0.7, 0.3, 0.3, 0.3)  # Semi-transparent red
	enemy_area.size = Vector2(600, 350)
	enemy_area.position = Vector2(-300, -375)
	enemy_area.z_index = -8
	add_child(enemy_area)

func _create_towers() -> void:
	# Load tower scene/script
	var TowerScene = preload("res://ClashRoyale/Towers/tower_base.tscn")
	
	# Each player always sees their own towers at bottom and enemy towers at top
	# Local player towers (bottom - friendly)
	var local_left_tower = TowerScene.instantiate()
	local_left_tower.name = "LocalLeftTower"
	local_left_tower.initialize(1 + (local_player_id - 1) * 3, local_player_id, Vector2(-150, 300), "princess", network_manager)
	add_child(local_left_tower)
	
	var local_right_tower = TowerScene.instantiate()
	local_right_tower.name = "LocalRightTower"
	local_right_tower.initialize(2 + (local_player_id - 1) * 3, local_player_id, Vector2(150, 300), "princess", network_manager)
	add_child(local_right_tower)
	
	var local_king_tower = TowerScene.instantiate()
	local_king_tower.name = "LocalKingTower"
	local_king_tower.initialize(3 + (local_player_id - 1) * 3, local_player_id, Vector2(0, 350), "king", network_manager)
	add_child(local_king_tower)
	
	# Store local towers
	local_towers[1 + (local_player_id - 1) * 3] = local_left_tower
	local_towers[2 + (local_player_id - 1) * 3] = local_right_tower
	local_towers[3 + (local_player_id - 1) * 3] = local_king_tower
	
	# Enemy towers (top - hostile)
	var enemy_player_id = network_manager.opponent_player_id if network_manager.opponent_player_id != 0 else (3 - local_player_id)
	
	var enemy_left_tower = TowerScene.instantiate()
	enemy_left_tower.name = "EnemyLeftTower"
	enemy_left_tower.initialize(1 + (enemy_player_id - 1) * 3, enemy_player_id, Vector2(-150, -300), "princess", network_manager)
	add_child(enemy_left_tower)
	
	var enemy_right_tower = TowerScene.instantiate()
	enemy_right_tower.name = "EnemyRightTower"
	enemy_right_tower.initialize(2 + (enemy_player_id - 1) * 3, enemy_player_id, Vector2(150, -300), "princess", network_manager)
	add_child(enemy_right_tower)
	
	var enemy_king_tower = TowerScene.instantiate()
	enemy_king_tower.name = "EnemyKingTower"
	enemy_king_tower.initialize(3 + (enemy_player_id - 1) * 3, enemy_player_id, Vector2(0, -350), "king", network_manager)
	add_child(enemy_king_tower)
	
	# Store enemy towers
	enemy_towers[1 + (enemy_player_id - 1) * 3] = enemy_left_tower
	enemy_towers[2 + (enemy_player_id - 1) * 3] = enemy_right_tower
	enemy_towers[3 + (enemy_player_id - 1) * 3] = enemy_king_tower

func _create_hud() -> void:
	# Create canvas layer for HUD
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "HUDLayer"
	add_child(canvas_layer)
	
	# Create HUD control
	game_hud = Control.new()
	game_hud.name = "GameHUD"
	canvas_layer.add_child(game_hud)
	
	# Elixir display
	var elixir_label = Label.new()
	elixir_label.name = "ElixirLabel"
	elixir_label.text = "Elixir: " + str(elixir)
	elixir_label.position = Vector2(10, 10)
	elixir_label.add_theme_font_size_override("font_size", 20)
	game_hud.add_child(elixir_label)
	
	# Ping display
	var ping_label = Label.new()
	ping_label.name = "PingLabel"
	ping_label.text = "Ping: 0 ms"
	ping_label.position = Vector2(10, 40)
	ping_label.add_theme_font_size_override("font_size", 16)
	game_hud.add_child(ping_label)
	
	# Card hand at bottom
	_create_card_hand()

func _create_card_hand() -> void:
	var card_container = HBoxContainer.new()
	card_container.name = "CardHand"
	card_container.position = Vector2(150, 500)
	card_container.add_theme_constant_override("separation", 10)
	game_hud.add_child(card_container)
	
	# Create 4 sample cards
	for i in range(4):
		var card = CardUI.new()
		card.name = "Card" + str(i)
		
		# Create sample card data
		var card_data = CardData.new()
		card_data.card_id = i
		card_data.card_name = "Troop " + str(i + 1)
		card_data.elixir_cost = 3 + i
		card_data.max_health = 100 + (i * 50)
		card_data.damage = 10 + (i * 5)
		
		card.set_card_data(card_data)
		card.card_played.connect(_on_card_played)
		card_container.add_child(card)

func _connect_signals() -> void:
	if network_manager != null:
		network_manager.troop_spawned_client.connect(_on_troop_spawned_client)
		network_manager.troop_spawned_server.connect(_on_troop_spawned_server)
		network_manager.troop_position_updated.connect(_on_troop_position_updated)
		network_manager.troop_health_updated.connect(_on_troop_health_updated)
		network_manager.tower_health_updated.connect(_on_tower_health_updated)
		network_manager.elixir_updated.connect(_on_elixir_updated)
		network_manager.ping_calculated.connect(_on_ping_calculated)

##################################################################################################
# Input handling
##################################################################################################

func _input(event: InputEvent) -> void:
	# Handle mouse clicks for spawning troops (alternative to drag-drop)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var click_pos = get_global_mouse_position()
			
			# Check if click is in valid spawn area (player's half)
			if _is_valid_spawn_position(click_pos):
				# Spawn a basic troop for testing
				_request_spawn(0, click_pos)

func _is_valid_spawn_position(pos: Vector2) -> bool:
	# Check if position is in player's territory
	# Player spawns troops on their side of the arena
	# Both players see themselves at the bottom and enemy at top
	# So locally, spawn area is always bottom half
	return pos.y > 25 and pos.y < 375 and pos.x > -300 and pos.x < 300

##################################################################################################
# Card and troop spawning
##################################################################################################

func _on_card_played(card_id: int, drop_position: Vector2) -> void:
	# Convert screen position to world position
	var world_pos = get_global_mouse_position()
	
	if _is_valid_spawn_position(world_pos):
		_request_spawn(card_id, world_pos)

func _request_spawn(card_id: int, position: Vector2) -> void:
	# Check elixir cost
	var cost = 3 + card_id  # Simple cost calculation
	
	if elixir >= cost:
		elixir -= cost
		_update_elixir_display()
		
		if network_manager != null:
			network_manager.request_spawn_troop(card_id, position)

func _on_troop_spawned_server(troop_data: Dictionary) -> void:
	# Server spawns the actual troop
	_spawn_troop(troop_data)

func _on_troop_spawned_client(troop_data: Dictionary) -> void:
	# Client receives troop spawn notification
	_spawn_troop(troop_data)

func _spawn_troop(troop_data: Dictionary) -> void:
	var TroopScene = preload("res://ClashRoyale/Units/troop_base.tscn")
	var troop = TroopScene.instantiate()
	
	var spawn_position = troop_data["position"]
	var is_local = (troop_data["player_id"] == local_player_id)
	
	# If enemy troop, mirror position to opposite side
	# Each player sees themselves at bottom and enemy at top
	if not is_local and not network_manager.is_host:
		# Mirror Y position for enemy troops on client
		spawn_position = Vector2(spawn_position.x, -spawn_position.y)
	
	troop.initialize(
		troop_data["troop_id"],
		troop_data["player_id"],
		spawn_position,
		network_manager
	)
	
	troop.is_local_player_troop = is_local
	
	add_child(troop)
	
	if troop.is_local_player_troop:
		local_troops[troop_data["troop_id"]] = troop
	else:
		enemy_troops[troop_data["troop_id"]] = troop

##################################################################################################
# Network updates
##################################################################################################

func _on_troop_position_updated(troop_id: int, position: Vector2) -> void:
	# Update troop position from server
	var troop = null
	if troop_id in local_troops:
		troop = local_troops[troop_id]
	elif troop_id in enemy_troops:
		troop = enemy_troops[troop_id]
	
	if troop != null and is_instance_valid(troop):
		troop.position = position

func _on_troop_health_updated(troop_id: int, health: int) -> void:
	# Update troop health from server
	var troop = null
	if troop_id in local_troops:
		troop = local_troops[troop_id]
	elif troop_id in enemy_troops:
		troop = enemy_troops[troop_id]
	
	if troop != null and is_instance_valid(troop):
		troop.health = health
		if troop.health_bar != null:
			troop.health_bar.value = health

func _on_tower_health_updated(tower_id: int, player_id: int, health: int) -> void:
	# Update tower health from server
	var tower = null
	if tower_id in local_towers:
		tower = local_towers[tower_id]
	elif tower_id in enemy_towers:
		tower = enemy_towers[tower_id]
	
	if tower != null and is_instance_valid(tower):
		tower.update_from_server(health)

func _on_elixir_updated(new_elixir: int) -> void:
	elixir = new_elixir
	_update_elixir_display()

func _on_ping_calculated(ping: int) -> void:
	if game_hud != null and game_hud.has_node("PingLabel"):
		game_hud.get_node("PingLabel").text = "Ping: " + str(ping) + " ms"

##################################################################################################
# Game logic
##################################################################################################

func _on_elixir_timer_timeout() -> void:
	# Only local client manages their own elixir
	if elixir < max_elixir:
		elixir += 1
		_update_elixir_display()

func _update_elixir_display() -> void:
	if game_hud != null and game_hud.has_node("ElixirLabel"):
		game_hud.get_node("ElixirLabel").text = "Elixir: " + str(elixir)
	
	# Update card playability
	if game_hud != null and game_hud.has_node("CardHand"):
		var card_hand = game_hud.get_node("CardHand")
		for card in card_hand.get_children():
			if card is CardUI and card.card_data != null:
				card.set_playable(elixir >= card.card_data.elixir_cost)
