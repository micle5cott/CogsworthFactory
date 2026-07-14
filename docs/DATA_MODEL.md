# Data Model

All player-specific persistent data is defined in `src/shared/DataModel.luau`.

## Schema Version

`DataModel.SCHEMA_VERSION = 1`

Increment this constant and add a migration entry whenever a breaking change is made (field renamed, type changed, field removed).

---

## PlayerData Structure

```
PlayerData
├── _version: number               Schema version for migration
├── currency
│   ├── coins: number
│   └── premiumCoins: number
├── inventory
│   └── [itemId]: number           Stack count per item
├── plot
│   ├── biomeId: string            Current active biome
│   ├── machines: MachineInstanceData[]
│   ├── conveyors: ConveyorSegmentData[]
│   └── powerBalance: number       PU surplus (+) or deficit (-)
├── research
│   ├── completed: string[]        Completed researchIds
│   ├── active: string?            Currently-researching researchId
│   └── progress: {[researchId]: number}  Packs delivered
├── unlocks
│   ├── tiers: number[]            Unlocked tier numbers
│   ├── biomes: string[]           Unlocked biome ids
│   ├── machines: string[]         Unlocked machine ids
│   └── specializations: string[]  Unlocked specialization ids
├── statistics
│   ├── playtimeSeconds: number
│   ├── totalItemsProduced: number
│   ├── totalResearchCompleted: number
│   ├── totalAscensions: number
│   └── rarityNodeStrikes
│       ├── uncommon: number
│       ├── rare: number
│       └── legendary: number
├── settings
│   ├── hintsEnabled: boolean
│   ├── musicVolume: number        0–1
│   ├── sfxVolume: number          0–1
│   └── efficiencyOverlay: boolean
├── achievements
│   └── [achievementId]: boolean
├── blueprints
│   └── [blueprintId]: BlueprintData
├── ascension
│   ├── count: number
│   ├── unlocks: string[]          Ascension upgrade ids
│   └── trophyCase: (string|nil)[] 9 slots; nil = empty
└── coop
    └── members: CoopMemberEntry[]  {playerId, role}
```

---

## New Player Defaults

A new player starts with:
- `coins = 0`, `premiumCoins = 0`
- `plot.biomeId = "verdant_hollow"`
- `unlocks.tiers = {1}`, `unlocks.biomes = {"verdant_hollow"}`
- All 9 Tier-1 machines unlocked
- `settings.hintsEnabled = true`, `musicVolume = 0.8`, `sfxVolume = 1.0`

---

## Migration System

`DataModel.migrate(raw)` reads `raw._version` and runs each migration function from `storedVersion + 1` to `SCHEMA_VERSION` in order.

`DataModel.applyDefaults(data)` backfills nil fields for returning players after migration. This handles additive changes (new fields) without requiring a full migration.

### Adding a field (non-breaking)
1. Add to the type and `DataModel.default()`
2. Add a fallback in `DataModel.applyDefaults()`
3. No version bump needed

### Renaming/removing a field (breaking)
1. Bump `SCHEMA_VERSION`
2. Add a migration function in the `migrations` table
3. Update the type and `DataModel.default()`

---

## DataStore Key Format

```
"player_" .. tostring(player.UserId)
```

Example: `"player_123456789"`

DataStore name: `"PlayerData_v1"` (from `GameConfig.DATASTORE_NAME`)
