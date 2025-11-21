# Clash Royale Clone - Setup & Usage Guide

## Hoe de Game Te Starten

Deze game gebruikt een **client-server architectuur**. Je hebt minimaal 3 instances nodig om een match te spelen:
- 1x Server instance (dedicated server)
- 2x Client instances (de spelers)

### Optie 1: Alles Lokaal Testen (Aanbevolen voor development)

#### Stap 1: Start de Server
Open een terminal en run:
```bash
godot --path /path/to/project -- --server
```

Of in Windows:
```bash
Godot_v4.x_win64.exe --path C:\path\to\project -- --server
```

Je zou dit moeten zien:
```
Starting in SERVER mode...
=== CLASH ROYALE CLONE - DEDICATED SERVER ===
Starting server on port 6969...
Server ready and waiting for clients...
```

#### Stap 2: Start Client 1
Open een nieuwe terminal:
```bash
godot --path /path/to/project
```

Dit opent het client menu. 
- Vul een username in (bijv. "Player1")
- Server IP blijft "127.0.0.1"
- **KLIK NOG NIET** op Quick Play!

#### Stap 3: Start Client 2
Open een derde terminal:
```bash
godot --path /path/to/project
```

Dit opent een tweede client menu.
- Vul een username in (bijv. "Player2")
- Server IP blijft "127.0.0.1"

#### Stap 4: Match Starten
Nu beide clients open zijn:
1. Klik op "Quick Play" in Client 1
2. Klik op "Quick Play" in Client 2

De server detecteert automatisch dat 2 spelers verbonden zijn en start de match!

**Output in Server Terminal:**
```
Player connected: Player1 (ID: 2)
Total players waiting: 1
Player connected: Player2 (ID: 3)
Total players waiting: 2

=== CREATING MATCH ===
Player 1: Player1 (ID: 2)
Player 2: Player2 (ID: 3)
Match created! Starting game in 2 seconds...
```

Beide clients laden nu de arena en de match begint!

---

## Hoe Te Spelen

### Controls
- **Linkermuisknop klikken** in het groene gebied (jouw helft) om een troop te spawnen
- Troepen kosten **Elixir** (zie linksboven)
- Elixir regenereert automatisch (1 per seconde)

### Doel
- Vernietig de vijandelijke torens (rood gebied bovenaan)
- Bescherm je eigen torens (groen gebied onderaan)
- Eerste speler die de King Tower (midden) vernietigt wint

### Game Mechanica

#### Arena Layout
```
╔═══════════════════════╗
║   ENEMY SIDE (RED)    ║  <- Vijandelijke torens en troops
║                       ║
║   🏰    🏰    🏰     ║  <- Enemy towers
║                       ║
║═══════ RIVER ════════║  <- Middengrens
║                       ║
║   🏰    🏰    🏰     ║  <- Jouw towers
║                       ║
║  YOUR SIDE (GREEN)    ║  <- Jouw spawn gebied
╚═══════════════════════╝
```

#### Troops
- **Spawnen**: Klik in groen gebied
- **Bewegen**: Automatisch naar vijandelijke kant
- **Aanvallen**: Automatisch als vijand in range
- **Health**: Rode balk boven elke troop

#### Towers
- **Princess Towers** (links/rechts): 500 HP, 50 damage
- **King Tower** (midden): 800 HP, 60 damage
- Towers vallen automatisch aan als vijand in range
- Range indicator: cirkel rondom tower

---

## Architectuur Details

### Scene Flow

#### Voor Clients:
```
launcher.tscn (detecteert --server argument)
    └─> client_menu.tscn (Quick Play menu)
         └─> arena.tscn (de game)
```

#### Voor Server:
```
launcher.tscn (detecteert --server argument)
    └─> server_host.tscn (dedicated server)
```

### Netwerk Synchronisatie

**Server (Authoritative)**
- Simuleert alle troop beweging en combat
- Valideert alle spawn requests
- Berekent alle damage
- Stuurt game state updates naar clients (60 fps)

**Clients**
- Tonen game state visueel
- Sturen input (spawn requests) naar server
- Ontvangen position/health updates
- Interpoleren movement voor smooth visuals

### Perspective System

Elk van de twee spelers ziet **zichzelf altijd onderaan** en de **vijand altijd bovenaan**:

**Server Perspectief (absolute positions)**
```
Player 2 Towers (top): Y = -300 tot -350
         River: Y = -25 tot 25
Player 1 Towers (bottom): Y = 300 tot 350
```

**Client 1 Perspectief**
```
Enemy (Player 2) top: Y = -300
         River: Y = 0
   You (Player 1) bottom: Y = 300
```

**Client 2 Perspectief**
```
Enemy (Player 1) top: Y = -300  <- mirrored!
         River: Y = 0
   You (Player 2) bottom: Y = 300
```

De arena.gd code zorgt automatisch voor deze mirroring:
```gdscript
# Als enemy troop, mirror Y position
if not is_local and not network_manager.is_host:
    spawn_position = Vector2(spawn_position.x, -spawn_position.y)
```

---

## Troubleshooting

### "Server niet gevonden"
- Zorg dat server instance draait voordat clients connecten
- Check firewall settings (port 6969 moet open zijn)
- Voor lokaal testen: gebruik altijd 127.0.0.1

### "Match start niet"
- Je hebt **exact 2 clients** nodig
- Beide clients moeten "Quick Play" klikken
- Server console toont "Creating Match" als het werkt

### Troops spawnen niet
- Check elixir (linksboven) - je hebt minimaal 3 nodig
- Klik in het groene gebied (jouw helft)
- Server moet draaien

### Troops bewegen niet
- **Alleen server simuleert beweging**
- Clients zien alleen de resultaten
- Check server console voor errors

### Positie bugs (troops op verkeerde kant)
- Client moet `opponent_player_id` correct ontvangen
- Check NetworkManager.client_matchmaking_success RPC
- Arena mirroring gebeurt automatisch

---

## Development Tips

### Debuggen

**Server Console Output:**
```bash
# Kijk naar connected players
Total players waiting: 2

# Match creation
=== CREATING MATCH ===
Player 1: Player1 (ID: 2)
Player 2: Player2 (ID: 3)
```

**Client Console:**
```bash
# Connection status
Connecting to server...
Match found! Preparing game...
Match starting! Loading arena...
```

### Multiple Instances Runnen

**Linux/Mac:**
```bash
# Terminal 1: Server
godot --path $(pwd) -- --server

# Terminal 2: Client 1
godot --path $(pwd)

# Terminal 3: Client 2
godot --path $(pwd)
```

**Windows:**
```cmd
REM Terminal 1: Server
Godot_v4.x_win64.exe --path %CD% -- --server

REM Terminal 2: Client 1
Godot_v4.x_win64.exe --path %CD%

REM Terminal 3: Client 2
Godot_v4.x_win64.exe --path %CD%
```

### Export voor Deployment

1. **Server Executable:**
   - Export project als "Headless" voor server
   - Run met: `./GameServer -- --server`

2. **Client Executable:**
   - Export normaal met graphics
   - Run zonder arguments: `./GameClient`

---

## Code Locaties

### Belangrijkste Files

| File | Doel |
|------|------|
| `launcher.gd` | Detecteert --server argument en laadt juiste scene |
| `UI/Client/client_menu.gd` | Client entry point met Quick Play |
| `UI/Server/server_host.gd` | Dedicated server met auto-matchmaking |
| `Arena/arena.gd` | Main game scene, spawning, perspective |
| `Managers/network_manager.gd` | Netwerk communicatie & sync |
| `Units/troop_base.gd` | Troop behavior & combat |
| `Towers/tower_base.gd` | Tower defense & targeting |

### Manager Initialisatie (Zonder Autoload!)

Elke scene initialiseert zijn eigen managers:
```gdscript
func _setup_managers() -> void:
    network_manager = NetworkManager.new()
    add_child(network_manager)
    
    clock_sync = ClockSync.new()
    add_child(clock_sync)
    
    game_state_manager = GameStateManager.new()
    add_child(game_state_manager)
    
    # Link references
    network_manager.clock_sync = clock_sync
    # etc...
```

Dit betekent dat managers **niet global** zijn - elke scene heeft zijn eigen instances.

---

## Volgende Stappen

### Features Toevoegen

1. **Win/Loss Conditions**
   - Detect wanneer King Tower destroyed
   - Show victory screen
   - Return to menu

2. **Verschillende Troop Types**
   - Extend TroopBase voor nieuwe units
   - Geef elk type unique stats
   - Voeg toe aan card hand

3. **Visual Improvements**
   - Sprites voor troops en towers
   - Attack animations
   - Damage numbers
   - Particle effects

4. **UI Polish**
   - Better card visuals
   - Match timer
   - Tower health bars in HUD
   - Elixir bar animation

5. **Gameplay Tweaks**
   - Balance troop stats
   - Adjust elixir costs
   - Tower targeting priority
   - Spawn cooldowns

---

Veel succes met je Clash Royale clone! 🎮
