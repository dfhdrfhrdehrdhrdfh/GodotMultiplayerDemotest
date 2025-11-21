extends StaticBody2D

# TowerBase - Base class for towers (King Tower and Princess Towers)
# Handles tower health, attacking nearby enemies

class_name TowerBase

##################################################################################################
# Tower properties
##################################################################################################

var tower_id: int = 0
var owner_player_id: int = 0
var tower_type: String = "princess"  # "princess" or "king"
var max_health: int = 500
var health: int = 500
var damage: int = 50
var attack_range: float = 150.0
var attack_cooldown: float = 0.8

##################################################################################################
# Combat
##################################################################################################

var target: Node2D = null
var is_attacking: bool = false

##################################################################################################
# Nodes
##################################################################################################

@onready var attack_timer: Timer = null
@onready var detection_area: Area2D = null
@onready var sprite: Sprite2D = null
@onready var health_bar: ProgressBar = null

# Reference to network manager (set by arena)
var network_manager: NetworkManager = null

##################################################################################################
# Signals
##################################################################################################

signal tower_destroyed(tower_id: int, owner_id: int)
signal tower_attacked(target_id: int)

##################################################################################################
# Initialization
##################################################################################################

func _ready() -> void:
	# Create sprite if not exists
	if not has_node("Sprite2D"):
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		sprite.modulate = Color(0.5, 0.5, 0.8)  # Blue-ish color for tower
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
	
	# Create detection area for finding targets
	if not has_node("DetectionArea"):
		detection_area = Area2D.new()
		detection_area.name = "DetectionArea"
		
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = attack_range
		collision.shape = shape
		detection_area.add_child(collision)
		
		detection_area.body_entered.connect(_on_body_entered_range)
		detection_area.body_exited.connect(_on_body_exited_range)
		add_child(detection_area)
	else:
		detection_area = get_node("DetectionArea")
	
	# Create health bar
	if not has_node("HealthBar"):
		health_bar = ProgressBar.new()
		health_bar.name = "HealthBar"
		health_bar.size = Vector2(60, 8)
		health_bar.position = Vector2(-30, -50)
		health_bar.max_value = max_health
		health_bar.value = health
		health_bar.show_percentage = false
		add_child(health_bar)
	else:
		health_bar = get_node("HealthBar")
		health_bar.max_value = max_health
		health_bar.value = health

func initialize(p_tower_id: int, p_owner_id: int, p_position: Vector2, p_tower_type: String, p_network_manager: NetworkManager) -> void:
	tower_id = p_tower_id
	owner_player_id = p_owner_id
	position = p_position
	tower_type = p_tower_type
	network_manager = p_network_manager
	
	# Set health based on tower type
	if tower_type == "king":
		max_health = 800
		health = 800
		damage = 60
	else:  # princess
		max_health = 500
		health = 500
		damage = 50
	
	if health_bar != null:
		health_bar.max_value = max_health
		health_bar.value = health
	
	# Register with network manager if server/host
	if network_manager != null and network_manager.is_host:
		network_manager.register_tower(self, owner_player_id, tower_id)

##################################################################################################
# Physics process
##################################################################################################

func _physics_process(_delta: float) -> void:
	# Only server/host simulates tower behavior
	if network_manager == null or not network_manager.is_host:
		return
	
	# Update health bar
	if health_bar != null:
		health_bar.value = health
	
	# Check if we have a valid target
	if target == null or not is_instance_valid(target):
		find_target()
	else:
		# Check if target is still in range
		if position.distance_to(target.global_position) > attack_range:
			target = null
			find_target()
		else:
			attack_target()

##################################################################################################
# Combat
##################################################################################################

func find_target() -> void:
	if network_manager == null:
		return
	
	# Find nearest enemy troop in range
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
				if dist <= attack_range and dist < nearest_distance:
					nearest_distance = dist
					nearest_enemy = enemy
	
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
		tower_attacked.emit(target.get("troop_id") if target.has("troop_id") else 0)
	
	attack_timer.start()

func _on_attack_timer_timeout() -> void:
	is_attacking = false

func _on_body_entered_range(body: Node2D) -> void:
	# When an enemy enters range, consider it as target
	if body.has("owner_player_id") and body.owner_player_id != owner_player_id:
		if target == null:
			target = body

func _on_body_exited_range(body: Node2D) -> void:
	# If our current target left range, clear it
	if target == body:
		target = null

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
		destroy()

func destroy() -> void:
	tower_destroyed.emit(tower_id, owner_player_id)
	
	if network_manager != null and network_manager.is_host:
		network_manager.unregister_tower(owner_player_id, tower_id)
	
	# Visual indication of destruction
	if sprite != null:
		sprite.modulate = Color(0.3, 0.3, 0.3)
	
	# Disable collision
	collision_layer = 0
	collision_mask = 0

##################################################################################################
# Network synchronization (for clients)
##################################################################################################

func update_from_server(new_health: int) -> void:
	health = new_health
	
	if health_bar != null:
		health_bar.value = health
	
	if health <= 0:
		# Visual indication of destruction for client
		if sprite != null:
			sprite.modulate = Color(0.3, 0.3, 0.3)
		collision_layer = 0
		collision_mask = 0
