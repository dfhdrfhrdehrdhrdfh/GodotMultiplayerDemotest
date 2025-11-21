extends Resource

# CardData - Defines properties for a single card/troop type

class_name CardData

@export var card_id: int = 0
@export var card_name: String = "Basic Troop"
@export var elixir_cost: int = 3
@export var troop_scene: PackedScene = null

# Troop stats
@export var max_health: int = 100
@export var damage: int = 10
@export var move_speed: float = 50.0
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 1.0

# Visual
@export var icon: Texture2D = null
@export var description: String = "A basic troop unit"
