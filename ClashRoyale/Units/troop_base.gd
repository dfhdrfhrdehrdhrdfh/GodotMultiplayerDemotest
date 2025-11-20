extends CharacterBody2D

# TroopBase - Base class for all troops/units in Clash Royale clone
# Handles movement, combat, health synchronization

class_name TroopBase

##################################################################################################
# Troop properties
##################################################################################################

var troop_id: int = 0
var owner_player_id: int = 0
var troop_type: String = "basic"
var max_health: int = 100
var health: int = 100
var damage: int = 10
var move_speed: float = 50.0
var attack_range: float = 50.0
var attack_cooldown: float = 1.0
var is_local_player_troop: bool = false

##################################################################################################
# Movement and targeting
##################################################################################################

var target: Node2D = null
var target_position: Vector2 = Vector2.ZERO
var is_attacking: bool = false

##################################################################################################
# Timers and state
##################################################################################################

@onready var attack_timer: Timer = null
@onready var sprite: Sprite2D = null
@onready var health_bar: ProgressBar = null

# Reference to network manager (set by arena)
var network_manager: NetworkManager = null

##################################################################################################
# Signals
##################################################################################################

signal troop_died(troop_id: int, owner_id: int)
signal troop_attacked(target_id: int)

##################################################################################################
# Initialization
##################################################################################################

func _ready() -> void:
	# Create sprite if not exists
	if not has_node("Sprite2D"):
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
	else:
		sprite = get_node("Sprite2D")
	
	# Create attack timer
	attack_timer = Timer.new()
	attack_timer.name = "AttackTimer"
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)
	
	# Create health bar
	if not has_node("HealthBar"):
		health_bar = ProgressBar.new()
		health_bar.name = "HealthBar"
		health_bar.size = Vector2(40, 5)
		health_bar.position = Vector2(-20, -30)
		health_bar.max_value = max_health
		health_bar.value = health
		health_bar.show_percentage = false
		add_child(health_bar)
	else:
		health_bar = get_node("HealthBar")
		health_bar.max_value = max_health
		health_bar.value = health

func initialize(p_troop_id: int, p_owner_id: int, p_position: Vector2, p_network_manager: NetworkManager) -> void:
	troop_id = p_troop_id
	owner_player_id = p_owner_id
	position = p_position
	network_manager = p_network_manager
	
	# Register with network manager if server/host
	if network_manager != null and network_manager.is_host:
		network_manager.register_troop(self, owner_player_id, troop_id)

##################################################################################################
# Physics process
##################################################################################################

func _physics_process(delta: float) -> void:
	# Only server/host simulates troop behavior
	if network_manager == null or not network_manager.is_host:
		return
	
	# Find target if we don't have one
	if target == null or not is_instance_valid(target):
		find_target()
	
	# Move towards target or bridge
	if target != null and is_instance_valid(target):
		var distance_to_target = position.distance_to(target.global_position)
		
		if distance_to_target <= attack_range:
			# In attack range, stop and attack
			velocity = Vector2.ZERO
			attack_target()
		else:
			# Move towards target
			var direction = (target.global_position - position).normalized()
			velocity = direction * move_speed
	else:
		# No target, move towards enemy side
		move_towards_enemy_bridge()
	
	move_and_slide()
	
	# Update health bar
	if health_bar != null:
		health_bar.value = health

##################################################################################################
# Combat
##################################################################################################

func find_target() -> void:
	if network_manager == null:
		return
	
	# Find nearest enemy troop or tower
	var nearest_enemy = null
	var nearest_distance = INF
	
	# Check enemy troops
	for player_id in network_manager.troops_dict.keys():
		if player_id == owner_player_id:
			continue
		
		for enemy_troop_id in network_manager.troops_dict[player_id].keys():
			var enemy = network_manager.troops_dict[player_id][enemy_troop_id]
			if enemy != null and is_instance_valid(enemy):
				var dist = position.distance_to(enemy.position)
				if dist < nearest_distance:
					nearest_distance = dist
					nearest_enemy = enemy
	
	# Check enemy towers
	for player_id in network_manager.towers_dict.keys():
		if player_id == owner_player_id:
			continue
		
		for tower_id in network_manager.towers_dict[player_id].keys():
			var tower = network_manager.towers_dict[player_id][tower_id]
			if tower != null and is_instance_valid(tower):
				var dist = position.distance_to(tower.position)
				if dist < nearest_distance:
					nearest_distance = dist
					nearest_enemy = tower
	
	target = nearest_enemy

func attack_target() -> void:
	if is_attacking or attack_timer == null or not attack_timer.is_stopped():
		return
	
	if target == null or not is_instance_valid(target):
		return
	
	is_attacking = true
	
	# Deal damage to target
	if target.has_method("take_damage"):
		target.take_damage(damage)
		troop_attacked.emit(target.get("troop_id") if target.has("troop_id") else target.get("tower_id"))
	
	attack_timer.start()

func _on_attack_timer_timeout() -> void:
	is_attacking = false

func move_towards_enemy_bridge() -> void:
	# Determine which direction to move based on owner
	# Player 1 (bottom) moves up, Player 2 (top) moves down
	if owner_player_id == 1 or owner_player_id == network_manager.local_player_id:
		# Move up
		velocity = Vector2(0, -move_speed)
	else:
		# Move down
		velocity = Vector2(0, move_speed)

##################################################################################################
# Health management
##################################################################################################

func take_damage(amount: int) -> void:
	if network_manager == null or not network_manager.is_host:
		return  # Only server processes damage
	
	health -= amount
	
	if health_bar != null:
		health_bar.value = health
	
	if health <= 0:
		die()

func die() -> void:
	troop_died.emit(troop_id, owner_player_id)
	
	if network_manager != null and network_manager.is_host:
		network_manager.unregister_troop(owner_player_id, troop_id)
	
	queue_free()

##################################################################################################
# Network synchronization (for clients)
##################################################################################################

func update_from_server(new_position: Vector2, new_health: int) -> void:
	# Smooth position update for clients
	position = position.lerp(new_position, 0.3)
	health = new_health
	
	if health_bar != null:
		health_bar.value = health
