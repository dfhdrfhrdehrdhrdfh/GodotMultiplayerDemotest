extends Control

# CardUI - Visual representation of a card in the player's hand
# Handles drag and drop for spawning troops

class_name CardUI

var card_data: CardData = null
var can_be_played: bool = false

@onready var card_icon: TextureRect = null
@onready var elixir_label: Label = null
@onready var name_label: Label = null

signal card_played(card_id: int, position: Vector2)

##################################################################################################
# Initialization
##################################################################################################

func _ready() -> void:
	# Create card icon
	if not has_node("CardIcon"):
		card_icon = TextureRect.new()
		card_icon.name = "CardIcon"
		card_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		card_icon.size = Vector2(80, 100)
		add_child(card_icon)
	else:
		card_icon = get_node("CardIcon")
	
	# Create elixir label
	if not has_node("ElixirLabel"):
		elixir_label = Label.new()
		elixir_label.name = "ElixirLabel"
		elixir_label.position = Vector2(5, 5)
		elixir_label.add_theme_font_size_override("font_size", 16)
		add_child(elixir_label)
	else:
		elixir_label = get_node("ElixirLabel")
	
	# Create name label
	if not has_node("NameLabel"):
		name_label = Label.new()
		name_label.name = "NameLabel"
		name_label.position = Vector2(5, 85)
		name_label.add_theme_font_size_override("font_size", 12)
		add_child(name_label)
	else:
		name_label = get_node("NameLabel")
	
	custom_minimum_size = Vector2(90, 110)

func set_card_data(data: CardData) -> void:
	card_data = data
	update_visuals()

func update_visuals() -> void:
	if card_data == null:
		return
	
	if card_icon != null and card_data.icon != null:
		card_icon.texture = card_data.icon
	
	if elixir_label != null:
		elixir_label.text = str(card_data.elixir_cost)
	
	if name_label != null:
		name_label.text = card_data.card_name

func set_playable(playable: bool) -> void:
	can_be_played = playable
	
	# Visual feedback
	if playable:
		modulate = Color(1, 1, 1)
	else:
		modulate = Color(0.5, 0.5, 0.5)

##################################################################################################
# Input handling
##################################################################################################

func _gui_input(event: InputEvent) -> void:
	if not can_be_played:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Start dragging
			get_viewport().set_input_as_handled()

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not can_be_played or card_data == null:
		return null
	
	# Create drag preview
	var preview = Control.new()
	var preview_icon = TextureRect.new()
	if card_data.icon != null:
		preview_icon.texture = card_data.icon
	preview_icon.size = Vector2(60, 75)
	preview_icon.modulate = Color(1, 1, 1, 0.7)
	preview.add_child(preview_icon)
	
	set_drag_preview(preview)
	
	return card_data

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		# Card was dropped
		var drop_position = get_viewport().get_mouse_position()
		if card_data != null:
			card_played.emit(card_data.card_id, drop_position)
