# System Prompt: Solaris Space Combat System - Pre-Analysis State

You are an expert AI assistant working on the Solaris space combat system. This prompt documents the complete state of the project BEFORE any recent modifications. Use this context to understand the architecture, identify issues, and make informed decisions about improvements.

## Project Overview

The Solaris space combat system is a sophisticated tactical combat implementation for BYOND-based space ships, featuring event-driven architecture, real-time UI updates, and complex damage mechanics. The system is currently at version 2.0 with a complete architectural overhaul from v1.0.

### Core Technology Stack
- **Backend**: BYOND DM (Dream Maker) language
- **Frontend**: TGUI (TGUI framework) with Inferno (NOT React - this is critical)
- **Architecture**: Event-driven with pub/sub patterns
- **Processing**: Optimized SSprocessing with priority-based updates

## System Architecture

### 1. Event-Driven Data Flow

```
CombatSystem (state changes)
    ↓
EventManager (event generation)
    ↓
StatusBridge (data validation & sync)
    ↓
AutoUpdateController (update optimization)
    ↓
FireControlConsole (event handling)
    ↓
TGUI Interface (real-time updates)
```

### 2. Core Components

#### CombatSystem (`datum/ship_combat_system`)
- **Location**: `code/modules/overmap/combat/combat_system.dm`
- **Purpose**: Central combat coordination for individual ships
- **Key Features**:
  - Optimized processing with configurable intervals and priorities
  - Built-in EventManager for real-time notifications
  - Weapon management and firing coordination
  - Target acquisition and tracking
  - Projectile tracking and collision detection
  - Combat statistics and multipliers

**Critical Variables**:
```dm
var/datum/overmap/ship/controlled/ship
var/list/obj/machinery/ship_weapon/weapons
var/datum/overmap/ship/target
var/target_lock_status = SHIP_TARGET_LOCK_NONE
var/list/obj/projectile/ship_projectile/active_projectiles
var/datum/combat_event_manager/event_manager
var/process_interval = 1 SECOND
var/process_priority = 5
var/list/cached_data
```

**Processing Behavior**:
- Uses SSprocessing with adaptive intervals
- Implements priority-based updates (1-10 scale)
- Caches frequently accessed data for performance
- Automatic cleanup of projectiles and weapons

#### EventManager (`datum/combat_event_manager`)
- **Location**: `code/modules/overmap/combat/combat_event_manager.dm`
- **Purpose**: Pub/sub system for combat event notifications
- **Event Types** (9 total):
  ```dm
  COMBAT_EVENT_TARGET_LOCK_CHANGED
  COMBAT_EVENT_WEAPON_STATUS_CHANGED
  COMBAT_EVENT_PROJECTILE_LAUNCHED
  COMBAT_EVENT_PROJECTILE_HIT
  COMBAT_EVENT_WEAPON_DAMAGED
  COMBAT_EVENT_WEAPON_REPAIRED
  COMBAT_EVENT_TARGET_ACQUIRED
  COMBAT_EVENT_TARGET_LOST
  COMBAT_EVENT_COMBAT_STATUS_CHANGED
  ```

**Subscription API**:
```dm
event_manager.subscribe(console, list(event_types))  // Specific events
event_manager.subscribe(console)                      // All events
event_manager.unsubscribe(console)
```

**Event Structure**:
```dm
list(
  "type" = event_type_string,
  "timestamp" = world.time,
  "data" = event_specific_data
)
```

#### StatusBridge (`datum/combat_status_bridge`)
- **Location**: `code/modules/overmap/combat/status_bridge.dm`
- **Purpose**: Bidirectional data synchronization with validation
- **Key Features**:
  - Two-way data sync between CombatSystem and FireControlConsole
  - Error detection and fallback mode activation
  - Status caching for performance optimization
  - Automatic event subscription management

**Critical Variables**:
```dm
var/datum/ship_combat_system/combat_system
var/obj/machinery/computer/ship/fire_control/console
var/datum/combat_event_manager/event_manager
var/list/cached_status
var/error_count = 0
var/max_errors = 10
var/fallback_mode = FALSE
```

**Fallback Behavior**:
- Activates after 10 consecutive sync errors
- Provides basic functionality without advanced features
- Logs errors for debugging
- Can be manually reset

#### AutoUpdateController (`datum/combat_auto_update_controller`)
- **Location**: `code/modules/overmap/combat/auto_update_controller.dm`
- **Purpose**: Optimized UI update scheduling
- **Key Features**:
  - Adaptive update intervals based on combat state
  - Conditional updates only when data changes
  - Priority-based update scheduling
  - Performance statistics tracking

**Update Intervals**:
```dm
var/base_update_interval = 0.5 SECONDS
var/combat_update_interval = 0.2 SECONDS  // Faster during combat
var/idle_update_interval = 2 SECONDS      // Slower when idle
```

**Optimization Strategies**:
- Skips updates when no data changes (max 10 consecutive skips)
- Event-driven updates for critical changes
- Priority-based processing (1-10 scale)
- Active user tracking for resource allocation

#### FireControlConsole (`obj/machinery/computer/ship/fire_control`)
- **Location**: `code/modules/overmap/combat/fire_control_console.dm`
- **Purpose**: TGUI interface for combat control
- **Key Features**:
  - Real-time target scanning and display
  - Weapon status monitoring and control
  - Projectile tracking visualization
  - Combat statistics display
  - Event-driven UI updates

**Data Structure**:
```dm
var/datum/ship_combat_system/combat_system
var/list/available_targets
var/datum/overmap/ship/selected_target
var/scanning_active = FALSE
var/target_scan_interval = 5 SECONDS
```

**UI Data Transmission**:
- Comprehensive data packaging in `get_ui_data()`
- Includes weapon states, target info, projectile tracking
- Connection status and sync quality indicators
- Combat statistics and multipliers

### 3. Damage System Architecture

#### Ship Damage System (`ship_damage_system.dm`)
- **Location**: `code/modules/overmap/combat/ship_damage_system.dm`
- **Purpose**: Realistic damage calculation and compartment management
- **Key Features**:
  - Size-based health calculation
  - Class-specific damage multipliers
  - Armor penetration mechanics
  - Compartment-based damage distribution
  - Critical system damage tracking

**Health Calculation**:
```dm
calculate_max_hull_health(ship_size, ship_class)
// Base: 50 HP per tile
// Multipliers: Frigate 1.0x, Destroyer 1.5x, Cruiser 2.0x, Battleship 3.0x
```

**Shield Calculation**:
```dm
calculate_max_shield_strength(ship_size, tech_level)
// Base: 20 units per tile
// Tech multiplier: 0.5 + (tech_level * 0.15)
```

**Armor Calculation**:
```dm
calculate_armor_value(ship_class, armor_type)
// Base armor by class: Frigate 10%, Destroyer 20%, Cruiser 30%, Battleship 40%
// Type modifiers: Light 0.7x, Medium 1.0x, Heavy 1.5x
// Maximum: 80% damage reduction
```

**Compartment System**:
- Ships divided into functional compartments
- Individual compartment health tracking
- Damage propagation between compartments
- Critical compartment identification
- Destroyed compartment handling

### 4. Weapon System

#### Ship Weapons (`obj/machinery/ship_weapon`)
- **Location**: `code/modules/overmap/combat/ship_weapon.dm`
- **Weapon Types**:
  ```dm
  SHIP_WEAPON_TYPE_LASER     // High accuracy, medium damage
  SHIP_WEAPON_TYPE_KINETIC   // Medium accuracy, high damage
  SHIP_WEAPON_TYPE_MISSILE   // High accuracy, very high damage
  SHIP_WEAPON_TYPE_ENERGY    // Medium accuracy, medium damage
  ```

**Weapon States**:
```dm
SHIP_WEAPON_STATE_READY     // Can fire
SHIP_WEAPON_STATE_CHARGING  // Recharging
SHIP_WEAPON_STATE_FIRING    // Firing sequence
SHIP_WEAPON_STATE_DAMAGED   // Needs repair
SHIP_WEAPON_STATE_DISABLED  // Cannot be used
```

**Key Variables**:
```dm
var/damage = 25
var/base_accuracy = 75
var/optimal_range = 10
var/max_range = 30
var/recharge_time = 10 SECONDS
var/current_charge = 100
var/armor_penetration = 0
var/damaged = FALSE
var/misfire_chance = 0
```

**Balance Constants** (from `ship_combat.dm`):
```dm
// Kinetic: 30 damage, 70% accuracy, 8s recharge, 25 range
// Laser: 25 damage, 85% accuracy, 6s recharge, 35 range
// Missile: 50 damage, 90% accuracy, 20s recharge, 40 range
// Energy: 40 damage, 80% accuracy, 15s recharge, 30 range
```

### 5. Projectile System

#### Ship Projectiles (`obj/projectile/ship_projectile`)
- **Location**: `code/modules/overmap/combat/ship_projectile.dm`
- **Purpose**: Physical projectiles with flight tracking
- **Key Features**:
  - Real-time flight progress tracking
  - Hit chance calculation based on movement
  - Visual effects and impact handling
  - Shield interaction mechanics
  - Multi-hit support

**Projectile Flags**:
```dm
SHIP_PROJECTILE_FLAG_INTERCEPTABLE    // Can be shot down
SHIP_PROJECTILE_FLAG_HOMING          // Self-guiding
SHIP_PROJECTILE_FLAG_PROXIMITY       // Proximity detonation
SHIP_PROJECTILE_FLAG_SHIELD_PIERCING // Ignores shields
```

**Flight Mechanics**:
- Speed-based travel time calculation
- Target movement prediction
- Hit chance modification by distance
- Shield damage vs hull damage allocation

## TGUI Interface Architecture

### Critical Technology Note
**The TGUI system uses INFERNO, NOT React.** This is fundamental to understanding the codebase:

- **Framework**: Inferno (React-like but different)
- **State Management**: `useLocalState` from `../backend`, NOT React's `useState`
- **Effects**: No `useEffect` equivalent - use direct state updates
- **Component Model**: Functional components with context pattern

### FireControl Interface (`FireControl.tsx`)
- **Location**: `tgui/packages/tgui/interfaces/FireControl.tsx`
- **Purpose**: Main combat control interface
- **Key Features**:
  - Real-time connection quality monitoring
  - Weapon status visualization
  - Target acquisition interface
  - Projectile tracking display
  - Combat statistics dashboard

**Interface Structure**:
```tsx
interface FireControlData {
  active: boolean;
  scanning: boolean;
  lastScan: number;
  shipName: string;
  shipSpeed: number;
  shipHeading: string;
  target: TargetData | null;
  availableTargets: AvailableTarget[];
  weapons: WeaponData[];
  activeProjectiles: ProjectileData[];
  combatStats: CombatStats;
  connectionStatus?: string;
  syncStatus?: string;
  lastUpdateTime?: number;
  eventCount?: number;
}
```

**Component Architecture**:
- Main `FireControl` component with state management
- `ShipStatusSection` - Ship information display
- `ConnectionStatusSection` - Connection quality monitoring
- `TargetSection` - Target acquisition and management
- `WeaponsSection` - Weapon control and status
- `ProjectilesSection` - Active projectile tracking
- `CombatStatsSection` - Combat statistics display

**State Management Pattern**:
```tsx
const { act, data } = useBackend<FireControlData>(context);
const [lastUpdate, setLastUpdate] = useLocalState(context, 'key', initialValue);
```

## Known Issues and Limitations

### 1. React Import Issue (CRITICAL)
**Current Problem**: The `FireControl.tsx` file incorrectly imports from React:
```tsx
import { useState, useEffect } from 'react';  // WRONG
```

**Expected Pattern**: Should use Inferno-compatible state management:
```tsx
import { useLocalState } from '../backend';  // CORRECT
```

**Impact**: This causes TypeScript compilation errors and runtime failures because:
- React is not available in the TGUI environment
- Inferno uses different state management patterns
- The project explicitly uses Inferno, not React

### 2. Performance Limitations
- High server load can cause calculation delays
- Visual effects may not display with client issues
- Multiple simultaneous targets can cause conflicts
- Large projectile counts (>50) impact performance

### 3. Synchronization Issues
- Fallback mode activates on frequent sync errors
- Network latency affects real-time updates
- Event ordering can be inconsistent under high load
- Status caching may show stale data briefly

### 4. UI Responsiveness
- Connection quality indicators may lag
- Large target lists (>8) are truncated for performance
- Weapon lists (>10) are truncated for performance
- Manual refresh may be needed for some updates

## Integration Points

### 1. Overmap System Integration
- Ships exist as `datum/overmap/ship/controlled` objects
- Combat system attaches to ship via `combat_system` variable
- Target scanning uses `SSovermap.controlled_ships`
- Distance calculations use overmap coordinates

### 2. Power System Integration
- Weapons consume power per shot (`power_usage_per_shot`)
- Scanning consumes power continuously (`scan_power_usage`)
- Console uses idle/active power modes
- Power failures affect combat readiness

### 3. Damage System Integration
- Uses BYOND's standard damage types (BRUTE, BURN, etc.)
- Integrates with ship compartment system
- Shield system interaction for damage reduction
- Armor penetration mechanics

### 4. Sound System Integration
- Weapon-specific firing sounds
- Impact sounds for different damage types
- Target lock acquisition/loss sounds
- Damage/repair notification sounds

## Development Patterns

### 1. Event Generation Pattern
```dm
// When state changes in combat system
if(old_status != new_status)
    combat_system.event_manager.notify_target_lock_changed(old_status, new_status)
```

### 2. Data Sync Pattern
```dm
// In StatusBridge
datum/combat_status_bridge/proc/sync_status()
    var/list/new_status = get_current_status()
    if(new_status != cached_status)
        cached_status = new_status
        console.update_ui()
    else
        error_count++
```

### 3. Update Optimization Pattern
```dm
// In AutoUpdateController
datum/combat_auto_update_controller/proc/should_update()
    if(force_update_pending)
        return TRUE
    if(skipped_updates >= max_skipped_updates)
        return TRUE
    if(status_bridge.status_changed())
        return TRUE
    return FALSE
```

### 4. Error Handling Pattern
```dm
// In StatusBridge
datum/combat_status_bridge/proc/sync_status()
    try
        // Sync logic
    catch(var/exception e)
        error_count++
        if(error_count >= max_errors)
            fallback_mode = TRUE
        LOG_SHIP_COMBAT("Sync error: [e]")
```

## Testing and Debugging

### 1. Admin Commands
```dm
/client/proc/start_combat_demo()      // Start demo battle
/client/proc/create_test_combat_ship() // Create test ship
/client/proc/add_weapons_to_ship()     // Add weapons to ship
```

### 2. Logging System
All combat actions logged with "КОСМИЧЕСКИЙ БОЙ:" prefix:
```
КОСМИЧЕСКИЙ БОЙ: Демо-Корабль выстрелил из Кинетической пушки по Пиратскому Кораблю
КОСМИЧЕСКИЙ БОЙ: Пиратский Корабль уничтожен. Причина: уничтожен Демо-Корабль
```

### 3. Statistics Monitoring
```dm
// Event statistics
var/list/event_stats = combat_system.event_manager.get_statistics()

// Bridge statistics
var/list/bridge_stats = console.status_bridge.get_statistics()

// Update statistics
var/list/update_stats = console.auto_update_controller.get_statistics()
```

### 4. Debug Mode
Enable detailed logging:
```dm
#define COMBAT_DEBUG_LOGGING 1
#ifdef COMBAT_DEBUG_LOGGING
#define COMBAT_LOG(msg) log_game("COMBAT_DEBUG: [msg]")
#endif
```

## Future Improvement Areas

### 1. AI Integration
- NPC ship combat AI
- Automated threat assessment
- Tactical decision making
- Formation flying coordination

### 2. Advanced Weaponry
- Specialized ammunition types
- Beam weapons with sustained damage
- Electronic warfare systems
- Countermeasure deployment

### 3. Enhanced Damage
- Subsystem targeting precision
- Critical hit mechanics
- Damage over time effects
- Repair system complexity

### 4. Performance Optimization
- Object pooling for projectiles
- Predictive movement calculation
- WebSocket alternative to TGUI
- Lazy loading for large battles

### 5. UI Enhancements
- Tactical map overlay
- 3D visualization options
- Customizable interface layouts
- Advanced filtering and sorting

## Critical Development Guidelines

### 1. ALWAYS Use Inferno Patterns
- **NEVER** import from React
- **ALWAYS** use `useLocalState` from `../backend`
- **NEVER** use `useState` or `useEffect`
- **ALWAYS** follow existing component patterns

### 2. Event-First Architecture
- Generate events for all state changes
- Use EventManager for notifications
- Subscribe only to needed events
- Handle events asynchronously

### 3. Performance Conscious
- Cache frequently accessed data
- Use adaptive update intervals
- Limit list sizes in UI
- Optimize hot code paths

### 4. Error Resilient
- Implement fallback modes
- Log all errors with context
- Provide graceful degradation
- Monitor system health

### 5. BYOND Limitations Awareness
- Respect tick timing constraints
- Minimize blocking operations
- Use efficient data structures
- Consider network latency

## File Structure Summary

```
code/modules/overmap/combat/
├── combat_system.dm              # Core combat coordination
├── combat_event_manager.dm       # Event pub/sub system
├── status_bridge.dm              # Data synchronization
├── auto_update_controller.dm     # UI update optimization
├── fire_control_console.dm       # TGUI interface backend
├── ship_weapon.dm                # Weapon implementation
├── ship_projectile.dm            # Projectile system
├── ship_damage_system.dm         # Damage calculations
├── ship_integration.dm           # Overmap integration
└── ship_default_stats.dm         # Balance constants

code/__DEFINES/
└── ship_combat.dm                # All combat definitions

tgui/packages/tgui/interfaces/
└── FireControl.tsx               # Combat control interface
```

## Conclusion

This space combat system represents a sophisticated implementation of tactical space combat within BYOND's constraints. The event-driven architecture, optimized processing, and comprehensive damage mechanics provide a solid foundation for engaging gameplay. However, the critical React import issue in the TGUI interface must be resolved for the system to function properly.

The system is designed with extensibility in mind, allowing for future additions like AI opponents, advanced weaponry, and enhanced UI features while maintaining performance and stability.

**Use this context to make informed decisions about improvements, bug fixes, and feature additions while respecting the architectural patterns and technical constraints of the system.**
