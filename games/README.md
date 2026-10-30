# Fuchsia X v3 — Code Documentation

Fuchsia X v3 is a Lua script designed for Roblox's *Breaking Point*. The script is organized into several modules responsible for configuration management, player interactions, combat features, automated movement, client-side modifications, and the user interface.

This document provides an overview of the codebase, explaining the purpose of each section and identifying where it can be found in `script.lua`.

---

## Table of Contents

1. [Initialization and Dependencies](#1-initialization-and-dependencies)
2. [Configuration Management](#2-configuration-management)
3. [Game Services and Player References](#3-game-services-and-player-references)
4. [Player and Character Management](#4-player-and-character-management)
5. [Knife Prediction System](#5-knife-prediction-system)
6. [Knife Equipping System](#6-knife-equipping-system)
7. [Kill Aura](#7-kill-aura)
8. [Auto-Throw](#8-auto-throw)
9. [Always Hit](#9-always-hit)
10. [Auto-Pilot](#10-auto-pilot)
11. [Fullbright](#11-fullbright)
12. [User Interface](#12-user-interface)
13. [Teleport Handling](#13-teleport-handling)

---

## 1. Initialization and Dependencies

**Lines 1–21**

This section initializes the script and loads its external dependencies.

| Lines | Description |
|---|---|
| 1–2 | Defines production and testing configuration variables. |
| 4–7 | Loads the Breaking Point API, pathfinding library, and utility functions. |
| 9–10 | Saves previously configured settings. |
| 12–13 | Disconnects the previous Fullbright connection. |
| 15–19 | Disconnects previously registered connections to prevent duplicates. |
| 21 | Defines the teleport queue function using executor compatibility alternatives. |

### External Dependencies

- **bpAPI:** Provides access to Breaking Point game logic and animations.
- **Pathfinder:** Provides pathfinding functionality for automated movement.
- **BPUtils:** Contains utility functions for player detection, knife detection, and character interactions.

---

## 2. Configuration Management

**Lines 23–109**

Responsible for storing, loading, and saving the script's configuration.

### Configuration Structure

**Lines 23–63**

Defines the global settings table (`getgenv().fx_settings`).

The configuration is divided into the following modules:

| Module | Purpose |
|---|---|
| Global | General configuration shared across features. |
| KillAura | Kill Aura settings and execution references. |
| AlwaysHit | Always Hit settings. |
| Fullbright | Fullbright settings and connection reference. |
| AntiAFK | Anti-AFK settings. |
| AutoThrow | Auto-Throw settings and keybind configuration. |
| AutoPlay | Auto-Pilot settings. |
| Connections | Stores active connections for cleanup. |

### Saving Settings

**Lines 64–79**

The `SaveSettings()` function:

1. Retrieves the current Auto-Throw keybind.
2. Iterates through the configuration modules.
3. Excludes runtime references such as connections, callbacks, and toggle objects.
4. Serializes the remaining configuration into JSON.
5. Writes the configuration to `FuchsiaX/fx_v3_bp.json`.

### Connection Management

**Lines 81–84**

Defines `addConnection()`, which registers connections in the global connection table.

### Loading Settings

**Lines 86–99**

The `TryLoadingSettings()` function:

1. Checks whether the configuration file exists.
2. Reads and decodes the JSON configuration.
3. Iterates through previously saved modules.
4. Restores values that still exist in the current configuration.

### Initialization and Compatibility

**Lines 101–109**

Loads saved settings and checks whether the executor supports teleport queuing. If unsupported, the corresponding option is disabled and saved.

---

## 3. Game Services and Player References

**Lines 112–170**

Initializes Roblox services, player references, and shared game variables.

### Roblox Services

**Lines 112–119**

Retrieves references to:

- VirtualUser
- Players
- Workspace
- RunService
- ReplicatedStorage
- Lighting
- RemoteEvent

Also defines the remote event key used by the script.

### Local Player References

**Lines 121–124**

Initializes references to the local player, backpack, character, and primary character part.

### Pathfinding Initialization

**Lines 126–139**

Creates the pathfinding agent and configures waypoint spacing.

A `CharacterAdded` connection updates the local character and recreates the pathfinding agent after respawning.

### Anti-AFK Event

**Lines 141–147**

Registers an idle event listener. When Anti-AFK or Auto-Pilot is enabled, it uses VirtualUser to simulate interaction and prevent idle disconnection.

---

## 4. Player and Character Management

**Lines 174–206**

Contains the functions responsible for managing the local knife's equipped state.

### EquipKnife()

**Lines 174–181**

Checks whether the knife exists in the backpack and moves it into the character.

### Action State Tracking

**Lines 183–187**

Defines two state variables:

- `AutoThrowing`: Indicates whether an automated throw is currently being performed.
- `Stabbing`: Indicates whether an automated stabbing operation is active.

`isGoodTimeToUnequip()` checks whether either operation is currently active.

### UnequipKnife()

**Lines 189–206**

Moves the knife back into the backpack when possible.

If an action is still running, it schedules the unequip operation to happen once the character becomes available.

---

## 5. Knife Prediction System

**Lines 149–170**

Defines the shared `fx_modules` table and its `PredictPosition()` function.

### PredictPosition()

**Lines 151–170**

Calculates an estimated future position for a moving target.

The calculation uses:

- The distance between the knife and target.
- The target's assembly velocity.
- The estimated knife velocity.
- The estimated time required for the knife to reach the target.

The function then calculates a predicted position offset based on target velocity.

Finally, it returns:

1. A `CFrame` representing the predicted target position and orientation.
2. An estimated travel time.

This function is shared by Auto-Throw and Auto-Pilot.

---

## 6. Kill Aura

**Lines 208–298**

Implements the Kill Aura functionality.

### Kill Aura Execution

**Lines 208–275**

Defines `getgenv().fx_settings.KillAura.Run()`.

The function:

1. Checks whether the local player has a knife and is not sitting.
2. Retrieves the local knife.
3. Iterates through the players in the server.
4. Filters out invalid targets.
5. Checks whether a target is eligible.
6. Identifies the closest character part.
7. Checks whether the target is within the configured range.
8. Executes the stabbing operation.

It also tracks currently targeted players to prevent duplicate operations.

### Action Cleanup

**Lines 245–275**

Handles the asynchronous stabbing operation, including target validation, termination conditions, and restoring the knife's equipped state.

### Kill Aura Loop

**Lines 279–298**

Defines the main Kill Aura loop.

While enabled, it repeatedly executes the feature. In production mode, errors are caught using `pcall()` and printed to the console.

---

## 7. Auto-Throw

**Lines 300–374**

Contains the automated knife-throwing functionality.

### Auto-Throw Execution

**Lines 300–359**

Defines `getgenv().fx_settings.AutoThrow.Run()`.

The function:

1. Checks whether Auto-Pilot is enabled.
2. Retrieves the local knife.
3. Verifies that the player can throw.
4. Identifies the closest eligible player to the mouse.
5. Validates the target's character and required references.
6. Randomly selects the head or primary character part according to the configured headshot probability.
7. Handles knife equipping and throwing animations.
8. Uses `PredictPosition()` to calculate the target's predicted position.
9. Executes the throw and handles the associated timing.
10. Restores the knife's equipped state when necessary.

### Auto-Throw Loop

**Lines 362–374**

Defines the continuous execution loop.

It repeatedly invokes the Auto-Throw function while the feature is enabled, with production error handling.

---

## 8. Always Hit

**Lines 376–406**

Implements the Always Hit functionality.

### Main Execution

**Lines 376–393**

Defines the internal `run()` function.

It:

1. Retrieves the closest eligible player to the mouse.
2. Checks whether the target has a valid character.
3. Randomly selects the head or primary character part.
4. Executes the corresponding remote event.

### Always Hit Loop

**Lines 395–406**

Continuously executes the internal function while Always Hit is enabled.

Production mode includes error handling through `pcall()`.

---

## 9. Auto-Pilot

**Lines 408–941**

The largest section of the script.

Auto-Pilot combines automated movement, pathfinding, combat actions, and randomized behavior.

### 9.1 Movement Validation

**Lines 409–431**

Contains helper functions:

- `ValidatePositions()`: Checks whether all supplied positions are inside the glass arena.
- `randominvert()`: Randomly changes a number's sign.
- `canMove()`: Determines whether movement is currently permitted.

### 9.2 Movement Functions

**Lines 433–485**

Defines two movement methods.

| Function | Description |
|---|---|
| MoveTo() | Moves the character directly toward a target position. |
| PathfindTo() | Uses the Pathfinder agent to navigate toward a destination. |

`PathfindTo()` also handles pathfinding errors, character removal, movement completion, and cancellation.

### 9.3 Random Position Generation

**Lines 487–506**

Contains functions for generating random movement destinations.

- `CreateRandomPositionAroundPlayer()`: Generates a random valid position around the local character.
- `randomrange()`: Generates a random decimal number within a specified range.

### 9.4 Movement Patterns

**Lines 508–716**

Defines the `Moves` table, containing the different movement patterns available to Auto-Pilot.

| Function | Lines | Description |
|---|---|---|
| adad | 509–543 | Alternates movement between two positions perpendicular to the target direction. |
| walkfakewalk | 544–584 | Performs a sequence of movements designed to create irregular walking patterns. |
| walkspinright | 585–641 | Performs a right-oriented circular movement pattern. |
| walkspinleft | 642–697 | Performs a left-oriented circular movement pattern. |
| jump | 698–709 | Makes the character jump and waits for landing. |
| wait | 710–716 | Waits for a randomized duration. |

### 9.5 Unstuck System

**Lines 718–739**

Defines `unstuck()`.

Generates a random valid destination and uses pathfinding to move the character away from its current position.

This is used when a movement operation fails.

### 9.6 Movement Selection

**Lines 741–760**

Prepares the movement selection system.

- `MovesKeys`: Stores available movement patterns.
- `Throw()`: Prints Auto-Pilot errors to the console.
- `shuffle()`: Randomizes the order of movement patterns.

The circular movement patterns are handled separately during movement selection.

### 9.7 Auto-Pilot Tasks

**Lines 762–910**

Defines the `Tasks` table, which contains the different operations executed by Auto-Pilot.

| Task | Lines | Description |
|---|---|---|
| AntiAFK | 763 | Placeholder task. |
| Movement | 764–806 | Selects and executes randomized movement patterns. |
| AutoThrow | 807–903 | Handles target selection, prediction, raycasting, and automated throwing. |
| KillAura | 904–910 | Invokes the existing Kill Aura execution function. |

### 9.8 Task Execution Manager

**Lines 912–941**

Iterates through the available tasks and executes each one in a separate spawned thread.

It also:

- Temporarily disables conflicting features.
- Updates their UI toggles when necessary.
- Handles execution errors.
- Restores previously enabled features after Auto-Pilot stops.

---

## 10. Fullbright

**Lines 943–970**

Implements the Fullbright client-side modification.

### doFullbright()

**Lines 943–951**

Changes Lighting properties when Fullbright is enabled:

- Brightness
- ClockTime
- FogEnd
- GlobalShadows
- OutdoorAmbient

### RegisterFullbright()

**Lines 953–959**

Disconnects an existing lighting connection, registers a new `Lighting.Changed` listener, and applies Fullbright immediately.

### UnregisterFullbright()

**Lines 961–970**

Disconnects the listener and restores the script's predefined lighting values.

---

## 11. User Interface

**Lines 972–1161**

Creates the graphical interface using the Rayfield UI library.

### Rayfield Initialization

**Lines 972–982**

Loads Rayfield and creates the main window.

The window is named `Fuchsia X v3 - Breaking Point` and uses the Amethyst theme.

### Combat Tab

**Lines 984–1023**

Contains combat-related settings.

| Element | Lines | Description |
|---|---|---|
| Kill Aura toggle | 987–1001 | Enables or disables Kill Aura. |
| Always Hit toggle | 1003–1012 | Enables or disables Always Hit. |
| Headshot Chance slider | 1014–1023 | Configures Always Hit's headshot probability. |

### Client Tab

**Lines 1026–1057**

Contains client-side settings.

| Element | Lines | Description |
|---|---|---|
| Fullbright toggle | 1029–1040 | Enables or disables Fullbright. |
| Anti-AFK toggle | 1042–1057 | Enables or disables Anti-AFK. |

The Anti-AFK toggle prevents activation while Auto-Pilot is running.

### Auto-Throw Tab

**Lines 1060–1100**

Contains Auto-Throw settings.

| Element | Lines | Description |
|---|---|---|
| Auto-Throw toggle | 1063–1077 | Enables or disables continuous Auto-Throw. |
| Throw Once keybind | 1079–1089 | Executes a single throw when activated. |
| Headshot Chance slider | 1091–1100 | Configures Auto-Throw's headshot probability. |

### Auto-Pilot Tab

**Lines 1103–1126**

Contains Auto-Pilot settings.

| Element | Lines | Description |
|---|---|---|
| Auto-Pilot toggle | 1106–1115 | Enables or disables Auto-Pilot. |
| Headshot Chance slider | 1117–1126 | Configures Auto-Pilot's headshot probability. |

### Settings Tab

**Lines 1129–1161**

Contains general configuration options.

| Element | Lines | Description |
|---|---|---|
| Save Settings button | 1130–1136 | Saves the current configuration. |
| Stab Legit toggle | 1139–1145 | Controls legitimate stabbing animations. |
| Throw Legit toggle | 1147–1153 | Controls legitimate throwing animations. |
| Anti Cheap Aimbot toggle | 1155–1161 | Controls the knife equipping behavior associated with this option. |

---

## 12. Teleport Handling

**Lines 1163–1179**

Handles configuration and script loading when the player teleports to another server.

### Load on Teleport Toggle

**Lines 1163–1171**

Creates the Load on Teleport setting when the executor supports teleport queuing.

### Teleport Event

**Lines 1173–1179**

Registers a `LocalPlayer.OnTeleport` listener.

When teleportation begins, the script checks whether automatic loading is enabled and queues the loader script.

A `TeleportCheck` variable prevents the loader from being queued multiple times.

---

## 13. Completion Notification

**Line 1181**

Displays a notification confirming that Fuchsia X v3 has finished loading.

---

## Codebase Overview

The script follows a modular organization in which individual systems are implemented separately but share configuration and utility functions.

| Section | Line Range | Responsibility |
|---|---:|---|
| Initialization | 1–21 | Dependencies and cleanup |
| Configuration | 23–109 | Settings persistence |
| Services | 112–147 | Roblox services and player initialization |
| Prediction | 149–170 | Target position prediction |
| Knife Management | 174–206 | Equipping and unequipping |
| Kill Aura | 208–298 | Automated stabbing |
| Auto-Throw | 300–374 | Automated throwing |
| Always Hit | 376–406 | Hit execution |
| Auto-Pilot | 408–941 | Movement and automated tasks |
| Fullbright | 943–970 | Lighting modifications |
| UI Initialization | 972–982 | Main interface |
| UI Tabs | 984–1161 | Feature controls |
| Teleport Handling | 1163–1179 | Automatic loading |
| Completion | 1181 | Loading notification |

**Total: 1,181 lines.**
