extends Node

# Launcher - Entry point that decides whether to load client or server scene
# Checks command line arguments to determine mode

func _ready() -> void:
	var args = OS.get_cmdline_args()
	var is_server_mode = false
	
	# Check for --server argument
	for arg in args:
		if arg == "--server" or arg == "-server":
			is_server_mode = true
			break
	
	# Load appropriate scene
	if is_server_mode:
		print("Starting in SERVER mode...")
		get_tree().change_scene_to_file("res://ClashRoyale/UI/Server/server_host.tscn")
	else:
		print("Starting in CLIENT mode...")
		get_tree().change_scene_to_file("res://ClashRoyale/UI/Client/client_menu.tscn")
