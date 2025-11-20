# Clash Royale Clone - Complete Project Overview

## 📋 Projectbeschrijving

Een volledig werkende Clash Royale clone in Godot 4.5 met:
- **1v1 Multiplayer matchmaking**
- **Server-autoritatieve architectuur** (gebaseerd op GodotMultiplayerDemo)
- **Geen autoload** - alle managers als reguliere nodes
- **Automatische matchmaking** - 2 clients worden automatisch gematched
- **Mirrored perspective** - beide spelers zien zichzelf onderaan

---

## 🏗️ Volledige Mappenstructuur

```
GodotMultiplayerDemotest/
├── project.godot                    # Main scene: res://ClashRoyale/launcher.tscn
├── ClashRoyale/
│   ├── launcher.gd                  # Entry point - detecteert --server argument
│   ├── launcher.tscn                # Scene voor launcher
│   │
│   ├── README.md                    # Project documentatie (Dutch)
│   ├── SETUP_GUIDE.md              # Gedetailleerde setup instructies
│   │
│   ├── Managers/                    # Core game managers (NO AUTOLOAD!)
│   │   ├── network_manager.gd      # Netwerk sync (van multiplayer_manager.gd)
│   │   ├── clock_sync.gd           # Tijd sync (van clock.gd)
│   │   └── game_state_manager.gd   # State machine (van game_manager.gd)
│   │
│   ├── Arena/                       # Main game scene
│   │   ├── arena.gd                # Game loop, spawning, perspective handling
│   │   └── arena.tscn              # Arena scene met Node2D root
│   │
│   ├── Units/                       # Troops/Units
│   │   ├── troop_base.gd           # CharacterBody2D met combat/movement
│   │   └── troop_base.tscn         # Scene: CharacterBody2D
│   │       ├── Sprite2D
│   │       ├── CollisionShape2D (30x30 rectangle)
│   │       └── HealthBar (ProgressBar)
│   │
│   ├── Towers/                      # Defensive structures
│   │   ├── tower_base.gd           # StaticBody2D met auto-targeting
│   │   └── tower_base.tscn         # Scene: StaticBody2D
│   │       ├── Sprite2D
│   │       ├── CollisionShape2D (50x60 rectangle)
│   │       └── HealthBar (ProgressBar)
│   │
│   ├── Cards/                       # Card system
│   │   ├── card_data.gd            # Resource voor card properties
│   │   └── card_ui.gd              # Control voor drag-and-drop
│   │
│   ├── UI/
│   │   ├── Client/                 # Client entry point
│   │   │   ├── client_menu.gd      # Quick Play menu
│   │   │   └── client_menu.tscn    # Scene: Control
│   │   │       ├── NetworkManager (Node)
│   │   │       ├── ClockSync (Node)
│   │   │       ├── GameStateManager (Node)
│   │   │       ├── Background (ColorRect)
│   │   │       ├── CenterContainer (VBoxContainer)
│   │   │       │   ├── Title (Label)
│   │   │       │   ├── UsernameInput (LineEdit)
│   │   │       │   ├── ServerIPInput (LineEdit)
│   │   │       │   ├── QuickPlayButton (Button)
│   │   │       │   └── StatusLabel (Label)
│   │   │       └── Instructions (Label)
│   │   │
│   │   ├── Server/                 # Server host
│   │   │   ├── server_host.gd      # Dedicated server logic
│   │   │   └── server_host.tscn    # Scene: Node
│   │   │       ├── NetworkManager (Node)
│   │   │       ├── ClockSync (Node)
│   │   │       └── GameStateManager (Node)
│   │   │
│   │   ├── Matchmaking/            # (Original demo UI - not used)
│   │   │   ├── main_menu.gd/tscn
│   │   │   └── matchmaking_lobby.gd/tscn
│   │   │
│   │   └── GameHUD/                # (Future: in-game UI)
│   │
│   └── Resources/                   # Assets (sprites, sounds, etc.)
│
├── Game/                            # Original GodotMultiplayerDemo files
├── Singletons/                      # Original autoload managers (not used)
├── UI/                              # Original demo UI
└── Textures/                        # Original demo textures
```

---

## 🎮 Scene Structures in Detail

### 1. launcher.tscn
```
Launcher (Node)
└── Script: launcher.gd
    ├── Checks for --server argument
    └── Loads client_menu.tscn or server_host.tscn
```

### 2. client_menu.tscn (Client Entry Point)
```
ClientMenu (Control) - Full screen
├── NetworkManager (Node) - created dynamically
├── ClockSync (Node) - created dynamically
├── GameStateManager (Node) - created dynamically
├── Background (ColorRect) - Dark blue/gray
├── CenterContainer (VBoxContainer)
│   ├── Title (Label) - "CLASH ROYALE CLONE"
│   ├── Subtitle (Label) - "Multiplayer Tower Defense"
│   ├── UsernameInput (LineEdit) - Enter player name
│   ├── ServerIPInput (LineEdit) - Server address (default: 127.0.0.1)
│   ├── QuickPlayButton (Button) - Large, prominent button
│   └── StatusLabel (Label) - Connection status
└── Instructions (Label) - How to play info
```

### 3. server_host.tscn (Dedicated Server)
```
ServerHost (Node)
├── NetworkManager (Node) - created dynamically
├── ClockSync (Node) - created dynamically
└── GameStateManager (Node) - created dynamically

NO UI - runs headless
Prints to console:
- "=== CLASH ROYALE CLONE - DEDICATED SERVER ==="
- "Server ready and waiting for clients..."
- Player connections
- Match creation logs
```

### 4. arena.tscn (Main Game Scene)
```
Arena (Node2D)
├── NetworkManager (Node) - created in _ready()
├── ClockSync (Node) - created in _ready()
├── GameStateManager (Node) - created in _ready()
│
├── ArenaBackground (ColorRect) - Green grass, 600x800
├── River (ColorRect) - Blue water strip in middle, 600x50
├── PlayerSpawnArea (ColorRect) - Semi-transparent green, bottom half
├── EnemySpawnArea (ColorRect) - Semi-transparent red, top half
│
├── LocalLeftTower (TowerBase - StaticBody2D)
│   └── Position: Vector2(-150, 300)
├── LocalRightTower (TowerBase - StaticBody2D)
│   └── Position: Vector2(150, 300)
├── LocalKingTower (TowerBase - StaticBody2D)
│   └── Position: Vector2(0, 350)
│
├── EnemyLeftTower (TowerBase - StaticBody2D)
│   └── Position: Vector2(-150, -300)
├── EnemyRightTower (TowerBase - StaticBody2D)
│   └── Position: Vector2(150, -300)
├── EnemyKingTower (TowerBase - StaticBody2D)
│   └── Position: Vector2(0, -350)
│
├── Camera (Camera2D) - Centered on arena
├── ElixirTimer (Timer) - 1 second interval
│
└── HUDLayer (CanvasLayer)
    └── GameHUD (Control)
        ├── ElixirLabel (Label) - Position: (10, 10)
        ├── PingLabel (Label) - Position: (10, 40)
        └── CardHand (HBoxContainer) - Position: (150, 500)
            ├── Card0 (CardUI) - 3 elixir
            ├── Card1 (CardUI) - 4 elixir
            ├── Card2 (CardUI) - 5 elixir
            └── Card3 (CardUI) - 6 elixir

DYNAMICALLY SPAWNED:
├── TroopBase instances (CharacterBody2D)
└── More towers/projectiles as needed
```

### 5. troop_base.tscn
```
TroopBase (CharacterBody2D)
├── collision_layer = 4 (Troop)
├── collision_mask = 6 (Tower + Troop)
│
├── Sprite2D
│   └── modulate = Color(0.8, 0.2, 0.2, 1) - Red-ish
│
├── CollisionShape2D
│   └── shape = RectangleShape2D (30x30)
│
└── HealthBar (ProgressBar)
    ├── offset = (-20, -30) to (20, -25)
    ├── max_value = 100
    └── show_percentage = false

DYNAMICALLY ADDED IN CODE:
└── AttackTimer (Timer) - for attack cooldown
```

### 6. tower_base.tscn
```
TowerBase (StaticBody2D)
├── collision_layer = 2 (Tower)
├── collision_mask = 4 (Troop)
│
├── Sprite2D
│   └── modulate = Color(0.5, 0.5, 0.8, 1) - Blue-ish
│
├── CollisionShape2D
│   └── shape = RectangleShape2D (50x60)
│
└── HealthBar (ProgressBar)
    ├── offset = (-30, -50) to (30, -42)
    ├── max_value = 500 (princess) or 800 (king)
    └── show_percentage = false

DYNAMICALLY ADDED IN CODE:
├── AttackTimer (Timer) - for attack cooldown
└── DetectionArea (Area2D) - for finding targets
    └── CollisionShape2D (CircleShape2D, radius = attack_range)
```

---

## 🔧 Code Files - Volledige Uitleg

### Core Managers (Adapted from GodotMultiplayerDemo)

#### network_manager.gd (1071 lines)
**Origineel:** `Singletons/multiplayer_manager.gd`  
**Aanpassingen:**
- Geen autoload - extends Node als class_name NetworkManager
- MAX_CLIENTS = 2 (voor 1v1)
- Troops in plaats van Players als main objects
- Tower synchronisatie toegevoegd
- Matchmaking signalen voor auto-match
- Elixir sync

**Belangrijkste functies:**
```gdscript
# CLIENT
func join_matchmaking(ip: String, username: String)
func request_spawn_troop(card_id: int, position: Vector2)
func receive_game_state(game_state_data: Dictionary)

# SERVER
func setup_multiplayer_server()
func _start_match() # Auto-match 2 clients
func _build_game_state() -> Dictionary
func register_troop(troop: Node, player_id: int, troop_id: int)
func register_tower(tower: Node, player_id: int, tower_id: int)
```

#### clock_sync.gd (114 lines)
**Origineel:** `Singletons/clock.gd`  
**Aanpassingen:**
- Geen autoload
- Reference naar network_manager (set by parent)

**Belangrijkste functies:**
```gdscript
var tick: int # Synchronized tick counter
func start_sync() # Client starts clock sync
func advance_tick() # Called every physics frame
```

#### game_state_manager.gd (95 lines)
**Origineel:** `Singletons/game_manager.gd`  
**Aanpassingen:**
- Geen autoload
- Scene paths naar ClashRoyale folders
- Simplified states voor matchmaking

**Belangrijkste functies:**
```gdscript
func join_matchmaking(ip: String, username: String)
func client_start_loading()
func client_game_started()
func is_game_active() -> bool
```

### Game Logic

#### arena.gd (420 lines)
**Doel:** Main game scene controller

**Belangrijkste functies:**
```gdscript
func _setup_managers()
    # Creates NetworkManager, ClockSync, GameStateManager
    # Links all references

func _setup_arena()
    # Creates background, river, spawn areas
    # Calls _create_towers() and _create_hud()

func _create_towers()
    # Creates 6 towers (3 local, 3 enemy)
    # Positions based on local_player_id
    # Each player sees self at bottom, enemy at top

func _spawn_troop(troop_data: Dictionary)
    # Server spawns actual troop
    # Client mirrors enemy position:
    if not is_local and not network_manager.is_host:
        spawn_position.y = -spawn_position.y

func _is_valid_spawn_position(pos: Vector2) -> bool
    # Always checks bottom half (player's side)
    return pos.y > 25 and pos.y < 375

func _input(event: InputEvent)
    # Mouse click to spawn troop
    # Only in valid spawn area
    # Costs elixir
```

#### troop_base.gd (234 lines)
**Doel:** Troop behavior, movement, combat

**Properties:**
```gdscript
var troop_id: int
var owner_player_id: int
var max_health: int = 100
var damage: int = 10
var move_speed: float = 50.0
var attack_range: float = 50.0
var attack_cooldown: float = 1.0
```

**Belangrijkste functies:**
```gdscript
func _physics_process(delta)
    # Only server simulates
    # find_target() -> nearest enemy
    # move_and_slide() towards target
    # attack_target() if in range

func find_target()
    # Searches network_manager.troops_dict
    # Searches network_manager.towers_dict
    # Sets nearest enemy as target

func take_damage(amount: int)
    # Only server processes
    # Updates health
    # Calls die() if health <= 0
```

#### tower_base.gd (257 lines)
**Doel:** Tower defense, auto-targeting

**Properties:**
```gdscript
var tower_type: String = "princess" # or "king"
var max_health: int = 500 # or 800 for king
var damage: int = 50 # or 60 for king
var attack_range: float = 150.0
var attack_cooldown: float = 0.8
```

**Belangrijkste functies:**
```gdscript
func _physics_process(delta)
    # Only server simulates
    # find_target() in range
    # attack_target() if valid

func find_target()
    # Checks all enemy troops
    # Within attack_range
    # Prioritizes closest

func update_from_server(new_health: int)
    # Client receives health update
    # Updates health bar
    # Shows destruction visual
```

### UI Controllers

#### client_menu.gd (141 lines)
**Doel:** Client entry with Quick Play

```gdscript
func _on_quick_play_pressed()
    # Get username and IP
    # Call game_state_manager.join_matchmaking()
    # Updates button to "SEARCHING..."

func _on_status_updated(status: String)
    # Updates StatusLabel
    # Shows connection progress

func _on_game_started()
    # Match found!
    # Scene changes to arena
```

#### server_host.gd (161 lines)
**Doel:** Dedicated server with auto-matchmaking

```gdscript
func _on_player_connected(player_id, name)
    # Adds to connected_clients
    # Calls _try_create_match()

func _try_create_match()
    # Checks if 2 unmatched players
    # Calls _create_match()

func _create_match(p1_id, p2_id)
    # Marks both as matched
    # Sends client_matchmaking_success RPC
    # Waits 2 seconds
    # Calls _start_match_for_players()

func _start_match_for_players(p1_id, p2_id)
    # Sends client_start_loading RPC
    # Waits 3 seconds (clock sync)
    # Sends client_game_started RPC
```

#### launcher.gd (18 lines)
**Doel:** Detect server vs client mode

```gdscript
func _ready():
    var args = OS.get_cmdline_args()
    
    if "--server" in args:
        change_scene_to_file("res://ClashRoyale/UI/Server/server_host.tscn")
    else:
        change_scene_to_file("res://ClashRoyale/UI/Client/client_menu.tscn")
```

---

## ⚙️ Collision Layers

```
Layer 1: Player (Reserved)
Layer 2: Tower
Layer 3: Troop
Layer 4: Projectile (Future)
```

**Tower:**
- collision_layer = 2
- collision_mask = 4 (can detect Troops)

**Troop:**
- collision_layer = 4
- collision_mask = 6 (can detect Towers + other Troops)

---

## 🌐 Network Flow

### Match Start Flow
```
1. Server starts: server_host.tscn
2. Client 1 clicks Quick Play
   → join_matchmaking("127.0.0.1", "Player1")
   → Connects to server
3. Server: _on_player_connected(2, "Player1")
4. Client 2 clicks Quick Play
5. Server: _on_player_connected(3, "Player2")
   → _try_create_match()
   → _create_match(2, 3)
6. Server → RPC to both: client_matchmaking_success
7. Wait 2 seconds
8. Server → RPC to both: client_start_loading
9. Both clients: change_scene to arena.tscn
10. Clock sync for 3 seconds
11. Server → RPC to both: client_game_started
12. Match begins!
```

### Troop Spawn Flow
```
1. Client: Mouse click in spawn area
2. Client: _request_spawn(card_id, position)
3. Client → RPC to server: server_spawn_troop(card_id, position)
4. Server: _spawn_troop_on_server()
   → Creates troop_data dict
   → Spawns troop locally
   → Registers in troops_dict
5. Server → RPC to all: client_receive_troop_spawn(troop_data)
6. Both clients: _spawn_troop(troop_data)
   → Client spawns for visualization
   → Enemy troop position mirrored
```

### Game State Sync (every frame)
```
Server _physics_process:
1. Build game_state dict:
   - All troop positions/health
   - All tower health
   - Elixir for each player
2. receive_game_state.rpc(game_state)

Client receives:
1. Updates troop positions (lerp for smooth)
2. Updates troop health bars
3. Updates tower health
4. Updates local elixir display
```

---

## 🎯 Perspective System (Critical!)

### Server (Absolute Coordinates)
```
Player 2 Side: Y = -400 to 0
    Enemy Towers (for P1): Y = -300, -350
    River: Y = -25 to 25
    Local Towers (for P2): Y = 300, 350
Player 1 Side: Y = 0 to 400
```

### Client View (Relative to Local Player)
**BOTH clients see themselves at bottom:**

```
Enemy Side (RED): Y = -400 to 0
    Enemy Towers: Y = -300, -350
    Enemy Troops: mirrored positions

River: Y = -25 to 25

Your Side (GREEN): Y = 0 to 400
    Your Towers: Y = 300, 350
    Your Troops: actual positions
```

**Position Mirroring Code:**
```gdscript
# In arena.gd _spawn_troop():
if not is_local and not network_manager.is_host:
    # Mirror Y for enemy troops
    spawn_position = Vector2(spawn_position.x, -spawn_position.y)
```

**Why this works:**
- Server maintains absolute positions
- Player 1 troops: Y > 0 (move towards Y < 0)
- Player 2 troops: Y < 0 (move towards Y > 0)
- Client 1 sees: self at bottom, P2 mirrored to top
- Client 2 sees: self at bottom, P1 mirrored to top

---

## 🚀 How to Run

### Terminal Commands

**Start Server (Terminal 1):**
```bash
godot --path /path/to/GodotMultiplayerDemotest -- --server
```

**Start Client 1 (Terminal 2):**
```bash
godot --path /path/to/GodotMultiplayerDemotest
```
- Enter username: Player1
- Server IP: 127.0.0.1
- Click Quick Play

**Start Client 2 (Terminal 3):**
```bash
godot --path /path/to/GodotMultiplayerDemotest
```
- Enter username: Player2
- Server IP: 127.0.0.1
- Click Quick Play

**Result:**
```
Server console:
=== CREATING MATCH ===
Player 1: Player1 (ID: 2)
Player 2: Player2 (ID: 3)
Match created! Starting game in 2 seconds...
Match started!
```

Both clients load arena and can play!

---

## ✨ Features Overview

### ✅ Implemented
- [x] Dedicated server with auto-matchmaking
- [x] Client Quick Play menu
- [x] 1v1 automatic match creation
- [x] Troop spawning (mouse click)
- [x] Server-side movement & combat
- [x] Health synchronization
- [x] Tower defense system
- [x] Elixir generation
- [x] Ping display
- [x] Mirrored client perspectives
- [x] No autoload architecture

### 🚧 To Add
- [ ] Win/loss conditions
- [ ] Victory screen
- [ ] Multiple troop types
- [ ] Attack animations
- [ ] Better sprites
- [ ] Sound effects
- [ ] Match timer
- [ ] Reconnection logic

---

## 📚 Bronnen

**Gebaseerd op:**
- GodotMultiplayerDemo door @seaciety
- https://github.com/seaciety/GodotMultiplayerDemo

**Networking principes:**
- Client-side prediction
- Server reconciliation
- Lag compensation
- Clock synchronization

**Belangrijke aanpassingen:**
- No autoload
- Troop-based gameplay
- Tower defense mechanics
- Auto-matchmaking systeem
- Mirrored perspective

---

Succes met je Clash Royale clone! 🎮🏰
