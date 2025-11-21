# Clash Royale Clone - Godot 4.5 Multiplayer

Een complete Clash Royale clone gebouwd in Godot 4.5 met multiplayer functionaliteit, gebaseerd op de networking van GodotMultiplayerDemo.

## Overzicht

Dit project is een 1v1 tower defense spel geïnspireerd door Clash Royale, met:
- Server-autoritatieve architectuur
- Client-side prediction en server reconciliatie
- Lag compensatie
- Real-time troop synchronisatie
- Matchmaking systeem

## Project Structuur

```
ClashRoyale/
├── Managers/
│   ├── network_manager.gd         # Netwerk communicatie (aangepast van multiplayer_manager.gd)
│   ├── clock_sync.gd               # Tijd synchronisatie (aangepast van clock.gd)
│   └── game_state_manager.gd       # Game state machine (aangepast van game_manager.gd)
├── Arena/
│   ├── arena.gd                    # Hoofd game scene
│   └── arena.tscn                  # Arena scene bestand
├── Units/
│   ├── troop_base.gd               # Basis klasse voor alle troops
│   └── troop_base.tscn             # Troop scene template
├── Towers/
│   ├── tower_base.gd               # Basis klasse voor torens
│   └── tower_base.tscn             # Tower scene template
├── Cards/
│   ├── card_data.gd                # Card eigenschappen resource
│   └── card_ui.gd                  # Card UI met drag-and-drop
├── UI/
│   ├── Matchmaking/
│   │   ├── main_menu.gd            # Hoofd menu
│   │   ├── main_menu.tscn
│   │   ├── matchmaking_lobby.gd    # Wachtkamer
│   │   └── matchmaking_lobby.tscn
│   └── GameHUD/                    # Game interface
└── Resources/                      # Sprites en assets

```

## Scene Structuur

### Main Menu Scene (main_menu.tscn)
```
MainMenu (Control)
├── NetworkManager (Node)
├── ClockSync (Node)
├── GameStateManager (Node)
├── Title (Label)
├── UsernameInput (LineEdit)
├── IPInput (LineEdit)
├── HostButton (Button)
├── JoinButton (Button)
└── ServerButton (Button)
```

### Arena Scene (arena.tscn)
```
Arena (Node2D)
├── NetworkManager (Node)
├── ClockSync (Node)
├── GameStateManager (Node)
├── ArenaBackground (ColorRect)
├── River (ColorRect)
├── PlayerSpawnArea (ColorRect)
├── P1_LeftTower (TowerBase)
├── P1_RightTower (TowerBase)
├── P1_KingTower (TowerBase)
├── P2_LeftTower (TowerBase)
├── P2_RightTower (TowerBase)
├── P2_KingTower (TowerBase)
├── Camera (Camera2D)
├── ElixirTimer (Timer)
└── HUDLayer (CanvasLayer)
    └── GameHUD (Control)
        ├── ElixirLabel (Label)
        ├── PingLabel (Label)
        └── CardHand (HBoxContainer)
            ├── Card0 (CardUI)
            ├── Card1 (CardUI)
            ├── Card2 (CardUI)
            └── Card3 (CardUI)
```

### Troop Scene (troop_base.tscn)
```
TroopBase (CharacterBody2D)
├── Sprite2D
├── CollisionShape2D (RectangleShape2D 30x30)
├── HealthBar (ProgressBar)
└── AttackTimer (Timer) - dynamisch toegevoegd
```

### Tower Scene (tower_base.tscn)
```
TowerBase (StaticBody2D)
├── Sprite2D
├── CollisionShape2D (RectangleShape2D 50x60)
├── HealthBar (ProgressBar)
├── AttackTimer (Timer) - dynamisch toegevoegd
└── DetectionArea (Area2D) - dynamisch toegevoegd
    └── CollisionShape2D (CircleShape2D)
```

## Belangrijke Aanpassingen t.o.v. GodotMultiplayerDemo

### 1. Geen Autoload
Alle managers (NetworkManager, ClockSync, GameStateManager) worden **niet** als autoload gebruikt. In plaats daarvan:
- Worden ze als Node children toegevoegd aan scenes
- Worden referenties handmatig doorgegeven tussen objecten
- Elke scene initialiseert zijn eigen manager instances indien nodig

### 2. Networking Aanpassingen
**Van multiplayer_manager.gd naar network_manager.gd:**
- Ondersteunt troops in plaats van players als hoofdobjecten
- Toegevoegd: tower synchronisatie
- Toegevoegd: troop spawn requests
- Aangepast: MAX_CLIENTS = 2 voor 1v1 matches
- Toegevoegd: elixir synchronisatie
- Toegevoegd: matchmaking signalen

### 3. Game State Management
**Van game_manager.gd naar game_state_manager.gd:**
- Aangepaste states voor matchmaking
- Toegevoegd: is_game_active() helper functie
- Scene paths aangepast naar ClashRoyale folders

### 4. Troop vs Player
In het originele demo waren "players" de hoofdobjecten. Nu:
- **Troops** zijn de bewegende eenheden
- **Players** zijn alleen controllers die troops spawnen
- Elke troop heeft `owner_player_id` in plaats van zelf een player te zijn

## Hoe Te Gebruiken

### Setup in Godot Editor

1. **Open het project:**
   - Open Godot 4.5
   - Importeer dit project
   - Wacht tot assets geïmporteerd zijn

2. **Instellen project configuratie:**
   - `project.godot` is al geconfigureerd
   - Main scene: `res://ClashRoyale/UI/Matchmaking/main_menu.tscn`
   - Geen autoloads vereist

3. **Test de game:**

   **Optie A: Host + Client op dezelfde PC**
   - Start Godot Editor en druk op Play (F5)
   - Kies "Host Game"
   - Open een tweede instantie van het project in terminal:
     ```bash
     godot --path /path/to/project
     ```
   - Kies "Join Game" met IP: 127.0.0.1

   **Optie B: Dedicated Server**
   - Start server instantie:
     ```bash
     godot --path /path/to/project --headless
     ```
   - Kies "Start Dedicated Server" in menu
   - Start twee client instanties en join beide

### Troop Spawning

**Methode 1: Mouse Click (Standaard actief)**
- Klik met linkermuisknop in je helft van de arena
- Een basic troop wordt automatisch gespawned (kost 3 elixir)

**Methode 2: Card Drag-and-Drop (Geïmplementeerd maar vereist verdere integratie)**
- Sleep een card van de hand naar de arena
- Drop in je territorium om te spawnen
- Elixir wordt automatisch afgetrokken

### Controls
- **Linkermuisknop**: Spawn troop in arena
- **ESC**: Terug naar menu (indien in lobby)

## Code Uitleg

### NetworkManager Key Functions

```gdscript
# Client spawnt een troop
func request_spawn_troop(card_id: int, spawn_position: Vector2)
    # Client stuurt spawn request naar server
    # Server valideert en spawnt troop
    # Server notificeert alle clients

# Server synchroniseert game state
func _build_game_state() -> Dictionary
    # Verzamelt posities en health van alle troops
    # Verzamelt tower health
    # Verzamelt elixir data
    # Stuurt naar alle clients

# Client ontvangt updates
func receive_game_state(game_state_data: Dictionary)
    # Update troop posities
    # Update troop health
    # Update tower health
    # Update elixir
```

### TroopBase Key Functions

```gdscript
# Server simuleert troop gedrag
func _physics_process(delta: float)
    # Zoek nearest enemy (troop of tower)
    # Beweeg naar enemy of bridge
    # Aanval als in range
    # Update wordt automatisch gesynchroniseerd door NetworkManager

# Damage handling
func take_damage(amount: int)
    # Alleen server verwerkt damage
    # Health update wordt gesynchroniseerd
    # Bij dood: troop wordt verwijderd en gederegistreerd
```

### Arena Key Functions

```gdscript
# Setup managers zonder autoload
func _setup_managers()
    # Create NetworkManager node
    # Create ClockSync node
    # Create GameStateManager node
    # Link alle references handmatig
    
# Spawn troop voor beide client en server
func _spawn_troop(troop_data: Dictionary)
    # Instantiate troop scene
    # Initialize met network_manager reference
    # Voeg toe aan scene tree
    # Registreer in local of enemy dict
```

## Collision Layers

- **Layer 1**: Player (Reserved voor toekomstig gebruik)
- **Layer 2**: Tower (Statische verdedigingsstructuren)
- **Layer 3**: Troop (Bewegende eenheden)
- **Layer 4**: Projectile (Voor toekomstige projectiel attacks)

## Networking Flow

### Troop Spawn Flow
```
1. Client: Mouse click in arena
2. Client: request_spawn_troop() naar NetworkManager
3. Client: RPC naar server (server_spawn_troop)
4. Server: Valideert spawn position
5. Server: Spawnt troop lokaal
6. Server: Registreert in troops_dict
7. Server: RPC naar alle clients (client_receive_troop_spawn)
8. Clients: Spawnen troop lokaal voor visualisatie
```

### Game State Sync Flow (elke physics frame)
```
1. Server: _physics_process op NetworkManager
2. Server: _build_game_state() verzamelt data
3. Server: receive_game_state.rpc() stuurt naar clients
4. Clients: Ontvangen state update
5. Clients: Update troop posities (lerp voor smooth movement)
6. Clients: Update health bars
7. Clients: Update tower states
```

## Belangrijke Features

### ✅ Geïmplementeerd
- Basis networking zonder autoload
- 1v1 matchmaking
- Troop spawning via mouse click
- Server-side troop movement en combat
- Tower defense (3 towers per speler)
- Health synchronisatie
- Elixir systeem
- Ping display
- Position smoothing voor clients

### 🚧 Te Verbeteren
- Card drag-and-drop volledige integratie
- Verschillende troop types met unieke stats
- Visual feedback voor attacks
- Sound effects
- Winning/losing conditions
- Match timer
- Troop animations
- Better sprite graphics
- Particle effects
- UI polish

## Troubleshooting

### "Autoload doesn't work"
✅ **Opgelost**: Dit project gebruikt geen autoload. Alle managers zijn normale nodes in de scene tree.

### Troops bewegen niet
- Check of je de host/server bent (alleen server simuleert movement)
- Controleer of NetworkManager.is_host == true
- Kijk in de remote debugger of troops geregistreerd zijn

### Geen verbinding tussen client en server
- Controleer firewall instellingen
- Gebruik 127.0.0.1 voor lokale test
- Controleer of PORT (6969) beschikbaar is

### Troops verschijnen niet na spawn
- Check console voor errors
- Verifieer dat troop_base.tscn correct is
- Controleer of spawn position binnen arena grenzen is

## Verdere Uitbreiding

### Nieuwe Troop Type Toevoegen
1. Maak nieuwe scene: `new_troop.tscn`
2. Extend van TroopBase
3. Override stats in _ready():
   ```gdscript
   func _ready():
       super._ready()
       max_health = 200
       damage = 20
       move_speed = 30.0
   ```
4. Voeg toe aan card system

### Nieuwe Tower Type
1. Extend TowerBase
2. Pas attack_range en damage aan
3. Voeg visuele verschillen toe

### Custom Card
1. Maak CardData resource in Resources/
2. Stel properties in (elixir_cost, stats, etc.)
3. Link naar troop scene
4. Voeg toe aan hand in arena._create_card_hand()

## Credits

Gebaseerd op **GodotMultiplayerDemo** door @seaciety:
- Original repository: https://github.com/seaciety/GodotMultiplayerDemo
- Networking architectuur
- Clock synchronisatie
- Client-side prediction systeem

Aangepast voor Clash Royale clone met:
- No-autoload architectuur
- Troop-based gameplay
- Tower defense mechanics
- 1v1 matchmaking

## Licentie

Zie LICENSE in root directory.
