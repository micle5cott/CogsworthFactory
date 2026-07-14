# Cogsworth Factory — Complete Game Design Document
**Milestone 1: Game Design**
*Version 1.0 — 2026-07-13*

---

## Table of Contents

1. [Vision & Identity](#1-vision--identity)
2. [Core Gameplay Loop](#2-core-gameplay-loop)
3. [Economy — Items Are Everything](#3-economy--items-are-everything)
4. [Production Chains](#4-production-chains)
5. [Research & Progression](#5-research--progression)
6. [Machines & Specializations](#6-machines--specializations)
7. [Power Grid](#7-power-grid)
8. [Biomes & The Living World](#8-biomes--the-living-world)
9. [The Ascension System](#9-the-ascension-system)
10. [Blueprint System](#10-blueprint-system)
11. [Multiplayer Co-op](#11-multiplayer-co-op)
12. [Tutorial & Onboarding](#12-tutorial--onboarding)
13. [Achievements & Daily Rewards](#13-achievements--daily-rewards)
14. [Monetization](#14-monetization)
15. [Live Operations Plan](#15-live-operations-plan)
16. [Long-term Roadmap](#16-long-term-roadmap)
17. [Design Constraints & Engineering Notes](#17-design-constraints--engineering-notes)
18. [Rare Discoveries](#18-rare-discoveries)
19. [Clockwork Drone Network](#19-clockwork-drone-network)

---

## 1. Vision & Identity

### Elevator Pitch
A Clockpunk Cozy factory automation game on Roblox. Warm aesthetic, uncompromising depth. A ten-year-old can place their first Lumber Mill in 30 seconds. A Factorio veteran will still be optimizing throughput ratios after 200 hours.

### Working Title
**Cogsworth Factory**

### Tagline
*"Build it. Automate it. Optimize it."*

### Tone & Aesthetic — "Clockpunk Cozy"
Industrial/Steampunk warmth merged with a cozy, inviting visual language. Think Howl's Moving Castle meets Factory Town:
- Warm wood, copper, iron, and brass dominate the palette
- Steam puffs with soft amber glows
- Machines have personality — they clunk, whirr, and breathe
- Conveyor belts are wooden slats on brass rollers
- The factory feels alive, not cold

As players ascend, the aesthetic shifts through four visual planes:
- **Earthen Realm** (Ascensions 0–1): Wood, iron, copper. Cozy village-factory.
- **Steam Realm** (Ascensions 2–3): Brass and bronze, amber pipes, rolling fog.
- **Aether Realm** (Ascensions 4–5): Crystal machinery, glowing conveyor lines.
- **Celestial Realm** (Ascension 6+): Pure clockwork geometry. Machines made of light.

### Inspirations (Not Clones)
- Factorio — production ratios, research packs, complexity depth
- Satisfactory — no selling, items unlock items, beautiful world exploration
- Factory Town — cozy aesthetic, whimsical machines
- Shapez — elegance over bloat

### Target Audience: Dual Track
- **New players (8–14):** Guided by contextual hints, complexity reveals gradually, early game is immediately tactile and satisfying
- **Factory veterans (14–25):** Encounter ratio math, power grids, and routing puzzles within the first session; immediately feel at home

---

## 2. Core Gameplay Loop

### The Four Pillars of Depth

**1. Production Ratios**
Every machine has fixed input and output rates. A Smelter consumes 2 Iron Ore/sec and produces 1 Iron Ingot/sec. A Gear Press consumes 2 Iron Ingots/sec and produces 1 Iron Gear/sec. To run a Gear Press at 100% efficiency requires exactly 2 Smelters feeding it. Mismatched ratios create starvation (machine idles) or backpressure (conveyor jams). Every machine displays an efficiency percentage. A factory running at 100% across the board is a genuine achievement.

**2. Power Grid**
Machines consume Power Units (PU). Players must build and maintain a power grid. Tier 1 machines run on mechanical energy (no power required). From Tier 2 onward, power is mandatory. Running the factory into a blackout because new machines were added without checking the power budget is a real failure state — and a satisfying lesson. Power scales with every expansion and is never permanently solved.

**3. Research Packs as Unlock Gate**
New tiers and machines are unlocked by delivering Research Packs — specific manufactured items — to a Research Station. Unlocking Tier 2 requires producing 10 Iron Gears + 10 Copper Wire and routing them to the Research Station. This forces players to build for progress, not just production. A factory optimized only for bulk output will stall at early tiers. The Research Station consumes packs continuously — research ticks while the player is offline if the production line is correctly routed.

**4. Conveyor Throughput & Logistics Puzzles**
Conveyors have speed tiers. Mk1: 30 items/min. Mk2: 60/min. Mk3: 120/min. Mk4: 240/min. Mk5: 480/min. A production line outputting 120 items/min fed by a Mk1 belt will jam. Belts, splitters, mergers, and junctions all have tier equivalents. The grid imposes real spatial constraints.

### Failure States

| Problem | Cause | Solution |
|---|---|---|
| Machine starvation | Insufficient input rate | Add upstream machines or upgrade belts |
| Conveyor jam | Output blocked or belt too slow | Reroute, add splitter, upgrade belt tier |
| Power blackout | Demand exceeds supply | Add generators or reduce machine count |
| Research stall | No research pack production line | Build dedicated research line |
| Storage overflow | No output path | Add storage or reroute |

### The Loop at Every Scale

**Minute-to-minute:** Place a machine → identify its ratio requirements → route inputs and outputs correctly → watch efficiency climb toward 100%.

**Session-to-session (30–60 min):** Diagnose a bottleneck → trace it upstream → fix the root cause → efficiency of the whole line improves → research unlocks faster → new tier becomes available.

**Day-to-day (idle loop):** Log in → find research has advanced (if factory was correctly routed before logging off) → check what Research Pack is next → spend session building that production line → log off with research ticking.

**Week-to-week:** Unlock a new biome → new resources open new production chains → redesign parts of the factory → eventually hit the Ascension goal → choose permanent unlock → reset → play differently.

### Player Journey by Stage

| Stage | Player Feels Like... | Primary Activity |
|---|---|---|
| First 5 minutes | A kid turning on a toy | Placing first machines, watching items move |
| First hour | A tinkerer fighting for Tier 2 | Hand-crafting, routing ore to slow processors |
| Hours 2–10 | An engineer | Connecting production chains, managing power |
| First week | An architect | Optimizing throughput, routing efficiently |
| First month | A director | Multi-biome factory, blueprints, specializations |
| Long-term | A legend | Ascending, rebuilding faster, teaching others |

---

## 3. Economy — Items Are Everything

**There is no currency. Nothing is sold. Items ARE the economy.**

Every item produced is either:
- **Spent** to build the next machine (construction cost)
- **Consumed** by the Research Station to unlock the next tier
- **Buffered** in Storage to keep production flowing

### Hand-Crafting Phase
The game begins with hand-crafting. The player interacts with resource nodes to receive raw materials and uses a crafting menu to build the first few machines by hand. This phase lasts approximately 5–10 minutes and naturally teaches the core loop without a tutorial screen.

Once the first automated production line is running, hand-crafting is effectively retired — the player should never need to manually gather again (though they can always choose to).

### Machine Construction
Building a machine spends items from connected Storage Chests or the player's inventory. Removing a machine returns 100% of its construction materials. Redesigning the factory is always free — the cost was already paid.

### Idle Research Progress
The Research Station consumes Research Packs continuously. As long as:
1. The correct items are being produced
2. They are routed to the Research Station via conveyor
3. The Research Station has power (Tier 2+)

...research ticks whether the player is online or offline. This is the idle loop — not passive income, but **passive progress earned by building the factory correctly before logging off.** A sloppily routed factory stalls overnight. A well-designed one wakes up with a new tier unlocked.

### Monetization Compatibility
Without a currency, all Robux purchases are purely cosmetic or quality-of-life (extra Blueprint slots, plot expansion, machine skins). No "buy materials," no "skip research." Every gameplay milestone is earned through factory design.

---

## 4. Production Chains

Six tiers deep. Each tier unlocks via Research. This is the spine of the entire game.

```
TIER 1 — Raw Harvest & Basic Processing
  Wood                    → Lumber (Lumber Mill)
  Stone                   → Crushed Stone (Stone Crusher)
  Iron Ore                → Iron Ingot (Clay Furnace, 0.5/sec)
  Copper Ore              → Copper Ingot (Clay Furnace, 0.5/sec)
  Iron Ingot × 2          → Iron Gear (Gear Stamp, 0.5/sec)
  Copper Ingot            → Copper Wire (Wire Braider, 1/sec)

TIER 2 — Iron & Copper  [Research Pack: 10 Iron Gears + 10 Copper Wire]
  Iron Ore × 2            → Iron Ingot (Smelter, 1/sec) [2× Clay Furnace]
  Copper Ore × 2          → Copper Ingot (Copper Refinery, 1/sec)
  Iron Ingot × 2          → Iron Gear (Gear Press, 1/sec) [2× Gear Stamp]
  Iron Ingot              → Iron Plate (Roller Press, 1/sec)
  Copper Ingot            → Copper Wire (Wire Refinery, 1/sec) [2× Wire Braider]
  Iron Plate × 2          → Reinforced Panel (Panel Bender, 1/sec)

TIER 3 — Steel & Steam  [Research Pack: 20 Clockwork Modules + 10 Steam Capsules + 5 Glass Lenses]
  Iron Ingot × 3 + Coal   → Steel Ingot (Forge, 1/sec)
  Iron Gear + Copper Wire → Clockwork Module (Assembler Mk1, 1/sec) [2× Clockwork Bench]
  Crushed Stone × 2       → Glass Lens (Glass Kiln, 1/sec)
  Iron Plate + Coal       → Steam Capsule (Assembler Mk1, 1/sec)
  Steel Ingot             → Steel Plate (Roller Press Mk2, 1/sec)
  Steel Ingot × 2         → Reinforced Frame (Forge Press, 1/sec)

TIER 4 — Precision Engineering  [Research Pack: 15 Optical Assemblies + 20 Conductor Coils + 10 Reinforced Frames]
  Steel Ingot × 2         → Precision Gear (Precision Lathe, 1/sec)
  Copper Wire × 2         → Conductor Coil (Coil Winder, 1/sec)
  Glass Lens × 2 + Copper Wire → Optical Assembly (Optical Refinery, 1/sec)
  Clockwork Module + Reinforced Frame → Advanced Frame (Advanced Assembler, 1.5/sec)
  Obsidian (Biome 3)      → Obsidian Shard (Obsidian Cutter, 1/sec)
  Sulphur (Biome 3) + Copper Wire → Conductor Coil variant (1/sec)

TIER 5 — Clockwork Mastery  [Research Pack: 10 Automaton Cores + 5 Resonance Cores + 20 Precision Gears]
  Advanced Frame + Conductor Coil × 2 → Automaton Core (Advanced Assembler, 1/sec)
  Crystal Shard × 2 (Biome 4)  → Resonance Core (Crystal Refinery, 1/sec)
  Steel Plate + Clockwork Module × 2 → Steam Chassis (Forge Press, 1/sec)
  Resonance Core + Conductor Coil → Conductor Array (Resonance Forge, 1/sec)
  Automaton Core + Steam Chassis → Clockwork Automaton (Automaton Workshop, 0.5/sec)

TIER 6 — Ascension  [Research Pack: 20 Clockwork Automatons + 10 Aether Crystals + 5 Resonance Cores]
  Aether Crystal × 3 (Biome 5) → Pure Aether (Aether Refinery, 1/sec)
  Conductor Array + Resonance Core → Resonance Amplifier component (1/sec)
  [All of the above]             → Clockwork Ascendant (requires Blueprint + 10,000 PU)
```

---

## 5. Research & Progression

### Structure
Six main tiers on a linear track. Optional side branches within each tier. Side branches provide machine specializations, biome unlocks, logistics upgrades, and efficiency boosts. They are not required to advance but are strongly incentivized — skipping them makes later tiers harder.

### Research Pack Requirements

| Tier | Research Pack Contents | Notes |
|---|---|---|
| → Tier 2 | 10 Iron Gears + 10 Copper Wire | ~1 hour of optimized Tier 1 production |
| → Tier 3 | 20 Clockwork Modules + 10 Steam Capsules + 5 Glass Lenses | Several sessions |
| → Tier 4 | 15 Optical Assemblies + 20 Conductor Coils + 10 Reinforced Frames | Multi-biome production required |
| → Tier 5 | 10 Automaton Cores + 5 Resonance Cores + 20 Precision Gears | Crystal Caverns required |
| → Tier 6 | 20 Clockwork Automatons + 10 Aether Crystals + 5 Resonance Cores | Aether Rift required |

### Side Branch Research (Per Tier)

**Tier 2 Side Branches:**
- Biome 2 Unlock *(10 Iron Plates + 5 Copper Wire)* → Highlands
- Smelter Specialization *(15 Iron Gears)* → Blast Furnace or Precision Forge
- Storage Mk2 *(10 Iron Plates)*
- Roller Press *(15 Iron Ingots)* → enables Iron Plate production

**Tier 3 Side Branches:**
- Biome 3 Unlock *(15 Steel Plates + 10 Glass Lenses)* → Volcanic Depths
- Assembler Mk1 Specialization *(20 Clockwork Modules)* → High-Volume or Quality
- Miner Mk2 *(10 Steel Plates + 5 Clockwork Modules)*
- Conveyor Mk3 *(10 Steel Plates)*
- Pressure Accumulator *(20 Iron Gears + 10 Copper Wire)*

**Tier 4 Side Branches:**
- Biome 4 Unlock *(20 Optical Assemblies + 15 Conductor Coils)* → Crystal Caverns
- Precision Lathe Specialization *(25 Precision Gears)* → Mass Lathe or Artisan Lathe
- Logistics Mk2 *(20 Conductor Coils)* → Overflow valves, item filters, priority routing
- Conveyor Mk4 *(15 Steel Plates + 10 Conductor Coils)*
- Smart Splitter *(10 Conductor Coils + 5 Optical Assemblies)*
- Clockwork Dynamo *(25 Conductor Coils + 20 Precision Gears)*
- **Drone Network** *(20 Optical Assemblies + 10 Conductor Coils + 10 Precision Gears)* → Drone Dock, Logistic Drones, Construction Drones, Logistic Chests (see Section 19)

**Tier 5 Side Branches:**
- Biome 5 Unlock *(20 Resonance Cores + 10 Automaton Cores)* → Aether Rift
- Automaton Workshop Specialization *(20 Automaton Cores)* → Foreman or Courier
- Miner Mk3 *(15 Automaton Cores)*
- Conveyor Mk5 *(20 Automaton Cores + 10 Resonance Cores)*
- **Scout Drones** *(10 Automaton Cores + 5 Resonance Cores)* → Scout Drone units that reveal rare nodes before mining (see Section 19)

**Tier 6: No side branches. This is the finish line.**

### Idle Research Mechanics
The Research Station has two input slots (expandable to two simultaneous tracks via Robux purchase). It pulls from any Storage Chest reachable by conveyor. Research progress = packs delivered × station speed (modified by VIP bonus if applicable). If packs stop arriving (production line broken, belt jammed, power outage), research pauses. Players who log off with a clean, running research line wake up to unlocked tiers.

---

## 6. Machines & Specializations

### Universal Machine Rules
- Fixed input rate, output rate, and power draw — never randomized
- Efficiency % displayed at all times (100% = perfectly balanced, never starved or blocked)
- 10-item input buffer, 10-item output buffer
- Rotatable in 90° increments on placement
- Returns 100% of build materials when removed

---

### Tier 1 Machines *(No Power Required)*

| Machine | Input | Output | Rate | Build Cost |
|---|---|---|---|---|
| Lumber Mill | Wood node | Lumber | 2/sec | Hand-crafted (5 Wood) |
| Stone Crusher | Stone node | Crushed Stone | 2/sec | 10 Lumber |
| Clay Furnace | Iron or Copper Ore | Ingot | 0.5/sec | 10 Lumber + 5 Crushed Stone |
| Gear Stamp | 2 Iron Ingots | 1 Iron Gear | 0.5/sec | 10 Iron Ingots + 5 Lumber |
| Wire Braider | 1 Copper Ingot | 1 Copper Wire | 1/sec | 5 Copper Ingots + 5 Lumber |
| Clockwork Bench | 1 Iron Gear + 1 Copper Wire | 1 Clockwork Module | 0.5/sec | 15 Iron Gears + 10 Copper Wire |
| Miner Mk1 | Placed on ore node | Raw Ore | 1/sec | 15 Lumber + 5 Crushed Stone |
| Storage Chest | Any item | Any item | Holds 200 | 10 Lumber |
| Research Station | Research Packs | Research Progress | 1 pack/30 sec | 20 Lumber + 10 Crushed Stone |

*Conveyor Mk1: 30 items/min. Hand-crafted from 5 Lumber + 2 Iron Ingots.*

---

### Tier 2 Machines *(Steam Power Required)*

| Machine | Input | Output | Rate | Power | Build Cost |
|---|---|---|---|---|---|
| Smelter | 2 Iron/Copper Ore/sec | 1 Ingot/sec | 1/sec | 25 PU | 20 Iron Ingots + 10 Lumber |
| Gear Press | 2 Iron Ingots/sec | 1 Iron Gear/sec | 1/sec | 30 PU | 15 Iron Ingots + 5 Crushed Stone |
| Copper Refinery | 2 Copper Ore/sec | 1 Copper Ingot/sec | 1/sec | 20 PU | 15 Copper Ingots + 10 Iron Ingots |
| Wire Refinery | 2 Copper Ingots/sec | 1 Copper Wire/sec | 1/sec | 20 PU | 10 Copper Ingots + 10 Iron Gears |
| Roller Press | 2 Iron Ingots/sec | 1 Iron Plate/sec | 1/sec | 25 PU | 15 Iron Ingots + 10 Iron Gears |
| Panel Bender | 2 Iron Plates/sec | 1 Reinforced Panel/sec | 1/sec | 30 PU | 20 Iron Plates + 10 Iron Gears |
| Steam Boiler | Coal | Steam | 5 Steam/sec | — | 20 Iron Ingots + 10 Crushed Stone |
| Steam Engine | Steam | Power | 50 PU | — | 15 Iron Gears + 10 Iron Ingots |
| Storage Mk2 | Any item | Any item | Holds 500 | 10 PU | 20 Iron Plates + 10 Iron Gears |

**Smelter Specializations** *(choose one per machine, permanent)*
- **Blast Furnace** — 2 Ingots/sec output, 3× Coal fuel cost. Best for volume iron/copper lines.
- **Precision Forge** — 1 Ingot/sec, outputs Quality Ingots (required for Tier 5–6 recipes). Best for research and late-game prep.

---

### Tier 3 Machines *(Pressurized Steam)*

| Machine | Input | Output | Rate | Power | Build Cost |
|---|---|---|---|---|---|
| Forge | 3 Iron Ingots + 1 Coal/sec | 1 Steel Ingot/sec | 1/sec | 50 PU | 30 Iron Gears + 15 Clockwork Modules |
| Glass Kiln | 2 Crushed Stone/sec | 1 Glass Lens/sec | 1/sec | 40 PU | 20 Iron Plates + 10 Clockwork Modules |
| Assembler Mk1 | 2 components/sec | 1 assembly/sec | 1/sec | 60 PU | 25 Clockwork Modules + 15 Iron Gears |
| Roller Press Mk2 | 2 Steel Ingots/sec | 1 Steel Plate/sec | 1/sec | 55 PU | 20 Steel Ingots + 15 Iron Plates |
| Forge Press | 2 Steel Ingots/sec | 1 Reinforced Frame/sec | 1/sec | 65 PU | 25 Steel Plates + 15 Clockwork Modules |
| Pressure Engine | Steam + Capsule/sec | 150 PU | — | — | 20 Steel Plates + 15 Iron Gears |
| Pressure Accumulator | Excess power | 500 PU stored | — | — | 20 Steel Ingots + 10 Copper Wire |

**Assembler Mk1 Specializations** *(choose one per machine, permanent)*
- **High-Volume Assembler** — 3× output speed, 2× power draw. Best for bulk mid-tier components.
- **Quality Assembler** — 1× speed, outputs refined assembly variants used in Tier 5–6 recipes.

---

### Tier 4 Machines *(Clockwork Power)*

| Machine | Input | Output | Rate | Power | Build Cost |
|---|---|---|---|---|---|
| Precision Lathe | 2 Steel Ingots/sec | 1 Precision Gear/sec | 1/sec | 80 PU | 30 Steel Plates + 20 Conductor Coils |
| Coil Winder | 2 Copper Wire/sec | 1 Conductor Coil/sec | 1/sec | 60 PU | 20 Copper Wire + 15 Iron Plates |
| Optical Refinery | 2 Glass Lenses + 1 Copper Wire/sec | 1 Optical Assembly/sec | 1/sec | 70 PU | 25 Optical Assemblies + 15 Steel Plates |
| Advanced Assembler | 3 components/sec | 1 assembly/sec | 1.5/sec | 100 PU | 30 Optical Assemblies + 20 Reinforced Frames |
| Obsidian Cutter | 1 Obsidian/sec | 1 Obsidian Shard/sec | 1/sec | 90 PU | 25 Steel Plates + 15 Precision Gears |
| Clockwork Dynamo | Conductor Coil | 400 PU | — | — | 25 Conductor Coils + 20 Precision Gears |
| Smart Splitter | Any item input | Filtered outputs (3 lanes) | 60/min per lane | 15 PU | 10 Conductor Coils + 5 Optical Assemblies |

**Precision Lathe Specializations** *(choose one per machine, permanent)*
- **Mass Lathe** — 3 Precision Gears/sec, standard quality. Raw throughput for bulk late-game production.
- **Artisan Lathe** — 0.5/sec, outputs Master Gears (rare variant required for Clockwork Automaton in Tier 6).

---

### Tier 5 Machines *(Crystal Power)*

| Machine | Input | Output | Rate | Power | Build Cost |
|---|---|---|---|---|---|
| Automaton Workshop | 2 Automaton Cores + 1 Steam Chassis/sec | 1 Clockwork Automaton/sec | 0.5/sec | 200 PU | 40 Automaton Cores + 20 Resonance Cores |
| Crystal Refinery | 2 Crystal Shards/sec | 1 Resonance Core/sec | 1/sec | 150 PU | 30 Resonance Cores + 20 Automaton Cores + 10 Quartz |
| Resonance Forge | 2 Steel Ingots + 1 Resonance Core/sec | 1 Conductor Array/sec | 1/sec | 180 PU | 25 Resonance Cores + 15 Automaton Cores |
| Crystal Resonator | Nothing (self-sustaining) | 2,000 PU | — | — | 50 Crystal Shards + 30 Resonance Cores + 20 Automaton Cores |
| Automaton Loader | Items from conveyors | Smart-routed output | 120/min | 80 PU | 20 Automaton Cores + 10 Conductor Coils |

**Automaton Workshop Specializations** *(choose one per machine, permanent)*
- **Automaton Foreman** — Deployed near machines, boosts adjacent machine efficiency by 25%. Build cost: 2 Clockwork Automatons.
- **Automaton Courier** — Replaces conveyors in a small radius with dynamic item routing. High flexibility, moderate throughput.

---

### Tier 6 Machines *(Aether Power)*

| Machine | Input | Output | Rate | Power | Build Cost |
|---|---|---|---|---|---|
| Aether Refinery | 3 Aether Crystals/sec | 1 Pure Aether/sec | 1/sec | 500 PU | 30 Aether Crystals + 20 Resonance Cores |
| Resonance Amplifier | — | +50% output to adjacent machines | — | 300 PU | 20 Pure Aether + 15 Conductor Arrays |
| **Clockwork Ascendant** | *(Activation: 500 Automatons + 200 Pure Aether + 100 Resonance Cores)* | **Ascension** | — | **10,000 PU sustained for 60 sec** | 50 Pure Aether + 30 Conductor Arrays + 20 Void Stone |

### Machine Count Summary

| Tier | Machines | Specialization Paths |
|---|---|---|
| 1 | 9 | 0 |
| 2 | 9 | 2 (Smelter) |
| 3 | 7 | 2 (Assembler Mk1) |
| 4 | 7 | 2 (Precision Lathe) |
| 5 | 5 | 2 (Automaton Workshop) |
| 6 | 3 | 0 |
| **Total** | **40** | **8 paths** |

---

## 7. Power Grid

Power is mandatory from Tier 2 onward. Blackouts halt all powered machines simultaneously.

| Tier | Generator | Output | Fuel |
|---|---|---|---|
| 2 | Steam Engine | 50 PU | Coal |
| 3 | Pressure Engine | 150 PU | Coal + Steam Capsule |
| 4 | Clockwork Dynamo | 400 PU | Conductor Coil |
| 5 | Crystal Resonator | 2,000 PU | None (self-sustaining) |

**Clockwork Ascendant** requires **10,000 PU sustained** — meaning the player needs at minimum 5 Crystal Resonators running simultaneously before activation. Each Resonator costs 50 Crystal Shards + 30 Resonance Cores + 20 Automaton Cores. Five Resonators demands a substantial Crystal Shards production line. Power becomes the final engineering challenge before Ascension.

**Pressure Accumulator** (Tier 3): Stores 500 PU, discharges during demand spikes. Critical for factories that run burst-heavy production cycles. Required for any serious Tier 4+ factory.

---

## 8. Biomes & The Living World

### How Biomes Work
The player's plot sits at the center of a persistent world. Biomes unlock outward through Research side branches, expanding the buildable area. The world grows as the factory does. Geography creates permanent routing constraints — rivers, slopes, lava channels, and rifts are never "solved," only planned around. Resource nodes have fixed richness ratings (Rich, Standard, Sparse) — never depleted, always worth mining, but incentivizing exploration for better nodes.

---

### Biome 1 — Verdant Hollow *(Starting Biome)*

> *Mossy stone walls, warm lantern light, old oaks, a brook cutting through the center.*

| Resource | Richness | Notes |
|---|---|---|
| Wood | Rich | Abundant — no concern |
| Stone | Standard | Common |
| Iron Ore | Sparse | Few nodes — **intentionally scarce** |
| Copper Ore | Sparse | Few nodes — **intentionally scarce** |
| Coal | Sparse | Just enough to start Tier 2 power |

**Geographic features:**
- River bisects the plot — Conveyor Bridge required (5 Iron Plates, hand-craftable)
- Dense forest patches block building until cleared by Lumber Mill (clear mode)
- Gentle terrain — no slope challenge

**Design intent:** The scarcity of Iron and Copper is the first-hour gating mechanism. Players must build miners, route conveyors, and manage limited node counts to produce the 10 Iron Gears + 10 Copper Wire needed for Tier 2. This friction is intentional. Getting through it is the first meaningful achievement.

---

### Biome 2 — Highland Reach *(Tier 2 side branch: 10 Iron Plates + 5 Copper Wire)*

> *Rugged cliffsides, exposed ore veins, mountain fog, rickety mine scaffolding.*

| Resource | Richness | Notes |
|---|---|---|
| Iron Ore | Rich | Production opens up dramatically |
| Copper Ore | Rich | Same |
| Coal | Standard | Consistent fuel supply |
| Granite | Standard | Used in Conveyor Ramp construction (5 Iron Plates + 5 Granite each) |

**Geographic features:**
- Elevation changes require Conveyor Ramps (5 Iron Plates each) to route up/down slopes
- Rocky outcroppings force non-linear conveyor paths
- Mine shaft deposits: Miner Mk2+ placed here yields 2× output

**Design intent:** Biome 2 is the reward for surviving Hour 1. Iron and Copper abundance here lets production scale rapidly. The factory shifts from a small workshop to a real operation.

---

### Biome 3 — Volcanic Depths *(Tier 3 side branch: 15 Steel Plates + 10 Glass Lenses)*

> *Glowing lava channels, black rock, heat shimmer, distant low rumbling.*

| Resource | Richness | Notes |
|---|---|---|
| Coal | Rich | Power scaling made easy |
| Obsidian | Standard | Required for Tier 4 Obsidian Shard production |
| Sulphur | Sparse | Conductor Coil variant production |
| Iron Ore | Standard | Secondary source |

**Geographic features:**
- Lava channels: permanent, map-wide unbuildable terrain — must route around them
- Heat Vents: special tiles that boost adjacent machine output by 15% (limited, valuable in co-op)
- Unstable ground: only lightweight machines (Storage, Splitters) can be placed

**Design intent:** Lava channels force players who built in straight lines to rethink their entire layout. The first truly spatial routing challenge.

---

### Biome 4 — Crystal Caverns *(Tier 4 side branch: 20 Optical Assemblies + 15 Conductor Coils)*

> *Underground expanse, glowing crystal formations, bioluminescent moss, eerie quiet.*

| Resource | Richness | Notes |
|---|---|---|
| Crystal Shards | Standard | Essential for Crystal Resonator (Tier 5 power) |
| Resonance Stone | Sparse | Refined into Resonance Core |
| Quartz | Standard | Used in Crystal Refinery build cost |
| Copper Ore | Rich | Deep vein — secondary copper source |

**Geographic features:**
- Stalactite fields block overhead conveyor paths
- Crystal formations: aesthetically prominent, unbuildable
- Resonance Zones: areas that boost Research Station consumption speed by 20% if placed within range
- Dim ambient lighting (cosmetic, atmospheric)

**Design intent:** Crystal Caverns introduce underground tight-corridor routing. Blueprint system proves valuable here — compact production line designs can be deployed in constrained space.

---

### Biome 5 — Aether Rift *(Tier 5 side branch: 20 Resonance Cores + 10 Automaton Cores)*

> *Reality fractures here. Floating islands drift. Glowing rifts tear the terrain. The clockwork of the universe is exposed.*

| Resource | Richness | Notes |
|---|---|---|
| Aether Crystal | Sparse | Required for Ascension — rarest resource |
| Pure Aether | — | Refined from Aether Crystals |
| Void Stone | Sparse | Resonance Amplifier construction only |

**Geographic features:**
- Floating islands: reached via Aether Bridge (expensive, Automaton Core cost). Best Aether nodes are island-only.
- Rift zones: unbuildable, shift slowly over time (small, infrequent — requires monitoring, not panic)
- Gravitational anomalies: conveyors in affected areas run at 50% speed unless fitted with Aether Dampeners (crafted from Void Stone)

**Design intent:** The Aether Rift breaks every assumption the player has built. Solving it cleanly is the final factory design challenge before the Clockwork Ascendant.

### Geographic Constraint Summary

| Feature | Biome | Effect | Counter |
|---|---|---|---|
| River | 1 | Blocks conveyor path | Conveyor Bridge |
| Dense Forest | 1 | Blocks building | Lumber Mill clear mode |
| Slope | 2 | Conveyors can't run flat | Conveyor Ramp |
| Lava Channel | 3 | Permanently unbuildable | Route around |
| Stalactites | 4 | Overhead blockage | Lower routing |
| Rift Zone | 5 | Shifting unbuildable area | Monitor + reroute |
| Gravity Anomaly | 5 | 50% conveyor speed | Aether Dampener |

---

## 9. The Ascension System

### The End Goal: The Clockwork Ascendant

After unlocking Tier 6 Research and producing items across all five biomes, the player can construct the **Clockwork Ascendant**. This is not a grind wall — it is a factory stress test. A well-optimized factory produces the required items naturally through a properly designed production chain. A poorly optimized factory hits these requirements and discovers it needs to redesign.

**Build Cost** (to place the machine):
- 50× Pure Aether
- 30× Conductor Array
- 20× Void Stone

**Activation Requirements** (consumed when triggered):
- 500× Clockwork Automaton
- 200× Pure Aether
- 100× Resonance Core
- 10,000 PU sustained for 60 seconds
- All 5 biomes unlocked and actively producing

**Activation Sequence:**
Every machine in the factory illuminates simultaneously. Steam vents across the entire plot. The Ascendant winds up. The ground rises. The factory ascends.

### What Ascension Does

The factory **resets to zero**. All machines, research, and biomes return to day one.

The player permanently carries forward **one chosen unlock**, selected before the reset:

| Ascension | Option A | Option B |
|---|---|---|
| 1st | Start with Miner Mk2 | Start with Conveyor Mk2 |
| 2nd | Start with Forge pre-unlocked | Start with Auto-Assembler available from Tier 1 |
| 3rd | Skip hand-crafting phase (starters connected) | Start with second Research Station slot |
| 4th | Start with one Blueprint pre-loaded | Start with Pressure Accumulator already built |
| 5th | Start in Aether Realm (exclusive bonus resource) | Start with Clockwork Dynamo unlocked from Tier 2 |
| 6th+ | Compound bonuses: research speed, output rate, biome unlock cost reductions |

Each ascension changes **how** you play, not just how fast. A player who unlocks Miner Mk2 immediately plays differently from one who skips hand-crafting. Build identity carries across rebirths.

### The Visual Planes

| Plane | Ascensions | Aesthetic |
|---|---|---|
| Earthen Realm | 0–1 | Warm wood, iron, copper, cozy village-factory |
| Steam Realm | 2–3 | Brass and bronze, amber pipes, rolling fog |
| Aether Realm | 4–5 | Crystal machinery, glowing conveyor lines |
| Celestial Realm | 6+ | Pure clockwork geometry, machines of light |

Players who have ascended further are visually identifiable. Their factory looks different to visitors. Progression is displayed, not just numbered.

---

## 10. Blueprint System

**Available from:** Tier 3 Research (after Research Pack B)

### Saving a Blueprint
Player enters Blueprint Mode via toolbar. Drag-selects any area of the factory. The system captures:
- Machine types, positions, and rotations
- Conveyor connections and belt tier
- Junction and splitter configurations

The Blueprint saves as a named entry with an auto-generated thumbnail and a full material cost list.

### Placing a Blueprint
Select a saved Blueprint → ghost overlay appears showing exact footprint → green if materials in Storage are sufficient, red if not → confirm → materials deducted, machines appear instantly.

Specialization choices must be made per-machine after placement. Power connects automatically within grid range.

### Blueprint Slots
- Default: 5 slots
- Expandable via Blueprint Expansion (Robux purchase, +5 per purchase)
- Blueprint Ink (achievement/daily reward): temporary +1 slot for 24 hours

### Sharing
Blueprints generate a shareable code string (like Factorio's blueprint strings). Paste in-game to load any community design. An in-game curated gallery surfaces top-rated community Blueprints.

---

## 11. Multiplayer Co-op

### World Structure
Each player has their own private plot. Plots exist within a shared server but are fully independent. Players can visit any plot as a Visitor. Owners control co-op permissions.

### Permission System

| Role | Build | Research | Invite | Ascend |
|---|---|---|---|---|
| Visitor | No | No | No | No |
| Builder | Yes | No | No | No |
| Co-Owner | Yes | Yes | No | No |
| Owner | Yes | Yes | Yes | Yes |

Maximum 3 co-builders active simultaneously on a plot.

### Griefing Protection
- Owner can revoke any permission at any time
- 24-hour build/removal log viewable by owner
- Research progress and Ascension are owner-only actions
- Materials removed by a Builder are logged

### Co-op Social Layer
A Contribution Score tracks how much each co-builder has added to the factory (machines placed, research contributed, materials routed). Displayed on a plot leaderboard visible to all visitors.

---

## 12. Tutorial & Onboarding

**No tutorial screen. No forced walkthrough. Contextual onboarding only.**

### First 5 Minutes (Scripted Contextual Flow)
1. Player spawns on empty plot. Starter Chest contains: 20 Lumber, 10 Crushed Stone.
2. Automaton Companion appears: *"Try interacting with that tree over there."*
3. Player interacts with tree → receives Wood → Companion: *"You can hand-craft a Lumber Mill. Check your crafting menu."*
4. Player places Lumber Mill → Companion: *"Connect it to your Research Station with a Conveyor Segment."*
5. Conveyor placed → Research Station begins receiving Lumber → first research tick → Companion goes quiet.

From this point, the Companion only reappears if the player is idle for 3 consecutive minutes. Hints are contextual:

| Situation | Companion Says |
|---|---|
| Machine idle | *"That machine looks hungry — check its input line."* |
| Conveyor jam | *"Something's blocked downstream. Trace the output path."* |
| Power blackout | *"Power demand exceeds supply. You need more generators."* |
| Research stalled | *"The Research Station has stopped. Is it receiving the right items?"* |

Hints can be disabled in Settings.

### The Real Tutorial: The First Hour
The player discovers they need Iron Gears and Copper Wire for Tier 2. Iron and Copper nodes exist in Biome 1 but are Sparse. They must:
- Hand-craft a Clay Furnace to smelt ore into ingots
- Build Gear Stamps and Wire Braiders to process ingots
- Deploy Miner Mk1 machines on ore nodes
- Route everything via Mk1 conveyors
- Slowly accumulate 10 Iron Gears + 10 Copper Wire

When Tier 2 unlocks and machine output rates double, that moment teaches more than any tutorial screen ever could.

### UI Principles
- Machine efficiency % always visible on machine face
- Conveyor throughput shown on hover
- Research progress bar persistent in screen corner
- All notifications queue during active play — shown only when player is idle
- No pop-ups during conveyor placement or machine routing

---

## 13. Achievements & Daily Rewards

### Achievement Categories

| Category | Example Achievements |
|---|---|
| Factory Milestones | First machine placed, Tier 2 unlocked, all 5 biomes open, Clockwork Ascendant built |
| Efficiency | Run any machine at 100% for 60 minutes, run entire factory at 95%+ efficiency |
| Production Records | Produce 1,000 Iron Gears, produce first Clockwork Automaton |
| Exploration | Unlock each biome, place a machine on a floating Aether island |
| Social | Co-build with a friend, share a Blueprint, use a community Blueprint |
| Ascension | First ascension, 3rd ascension, reach Celestial Realm (6th ascension) |
| Speedrun | Reach Tier 2 in under 45 minutes |
| Perfectionist | Run entire factory at 95%+ efficiency for one full session |
| Rare Discoveries | Find your first Rare Node, fill a Trophy Case, find a Legendary node, craft a Masterwork Machine, own all 3 Legendary items simultaneously |
| Drone Network | Deploy first Drone Dock, have 10 drones active simultaneously, auto-build a Blueprint entirely via Construction Drones |

**Rewards:** Cosmetic items, machine skins, Research Boosters, Blueprint slots, titles.

### 7-Day Login Streak

| Day | Reward |
|---|---|
| 1 | Research Booster (1 hour, +50% research consumption speed) |
| 2 | Cosmetic plot decoration |
| 3 | Blueprint Ink (temporary +1 Blueprint slot, 24 hours) |
| 4 | Research Booster (2 hours) |
| 5 | Rare cosmetic machine skin (rotates weekly) |
| 6 | Research Booster (1 hour) |
| 7 | Cogsworth's Weekly Exclusive cosmetic + Research Booster (3 hours) |

Streaks reset on a missed day. No make-up mechanics.

---

## 14. Monetization

**Design principle:** Zero pay-to-win. Every gameplay milestone earned through factory design. All purchases are cosmetic or quality-of-life.

### Game Passes (One-Time Purchases)

| Pass | Price | Contents |
|---|---|---|
| Clockwork Skins Mk1 | 100 R$ | Cosmetic skins for all Tier 1–3 machines |
| Clockwork Skins Mk2 | 200 R$ | Cosmetic skins for all Tier 4–6 machines |
| Plot Theme: Steam Realm | 150 R$ | Full visual overhaul to Steam Realm aesthetic |
| Plot Theme: Aether Realm | 200 R$ | Full visual overhaul to Aether aesthetic |
| VIP Pass | 400 R$ | Exclusive badge, Brass Elite skin set, 10% research speed bonus, VIP starting kit (2× starting materials — irrelevant by Tier 2), VIP lounge server access |

### Developer Products (Repeatable)

| Product | Price | Effect |
|---|---|---|
| Blueprint Expansion | 250 R$ | +5 permanent Blueprint slots |
| Plot Expansion | 150 R$ | +20% buildable plot area |
| Second Research Slot | 400 R$ | Run two Research Tracks simultaneously |

### What Cannot Be Purchased
- Materials or items of any kind
- Research progress or speed beyond the VIP 10% (non-stacking)
- Access to biomes
- Ascension or tier unlocks
- Any gameplay advantage unavailable to free players

---

## 15. Live Operations Plan

### Launch Month
- Stability hotfixes
- Community Blueprint Gallery goes live
- First balance pass from production data (machine ratios, biome unlock pacing)

### Month 2–3: First Content Drop
- 2 new machine variants per tier as side-branch research
- Biome 1 sub-area: The Sunken Workshop (flooded section, wet-stone resources)
- Harvest Festival seasonal event (pumpkin decorations, amber conveyor skins)

### Month 4–6: Competitive Layer
- Global Leaderboards: efficiency score × sustained output rate
- Weekly Challenge Factory: pre-built broken factory on a shared server, first to restore full efficiency earns a cosmetic reward
- 30-day Ascension Leaderboard

### Month 7–12: Major Expansion
- Tier 7 Research Track (post-Ascension 3+ only)
- Biome 6: The Frozen Expanse (ice terrain, rare mineral deposits, conveyors slow unless insulated with Thermal Wrap items)
- Trading Post machine: leave items for other server players to collect
- Blueprint Marketplace: in-game browse, rate, and download community Blueprints

### Seasonal Events (Recurring Annually)

| Season | Event Content |
|---|---|
| Halloween | Ghost conveyor items, haunted machine skins, Phantom Automaton cosmetic |
| Winter Solstice | Snow biome overlay, snowflake conveyor particles, Frost Crystal one-time resource |
| Spring | Floral machine growth cosmetics, butterfly conveyor particles |
| Summer | Beach plot theme, sun-powered aesthetic for Crystal Resonators |

---

## 16. Long-Term Roadmap

**Year 1:** Core game complete (Milestones 1–14) → launch → monthly live ops content.

**Year 2:** Competitive mode (factory efficiency tournaments), Blueprint Marketplace, inter-plot Trading system, mobile performance pass.

**Year 3:** Major world expansion (Tiers 7–8), second Ascension plane with an entirely new resource tree, Guild system for cooperative factory networks across multiple plots.

**Long-term vision:** The Blueprint community becomes a content engine. The game provides the systems; players invent the designs. Cogsworth Factory becomes a Roblox platform for factory creativity, not just a game you complete.

---

## 17. Design Constraints & Engineering Notes

*For the engineering team. These are design-level constraints that must be respected in implementation.*

**Performance:**
- Assume factories may reach 200+ machines and thousands of conveyor segments per plot
- Item movement must be server-authoritative; client shows visual interpolation only
- Research progress is server-side; no client trust for any progression state
- Conveyor throughput calculations must batch-update (not per-item per-frame)

**Save Data:**
- Full factory state must serialize: machine positions, types, specializations, conveyor connections, research progress, ascension count and unlocks, biome unlock status
- Version migration required from day one — every save format change needs a migration path
- Research progress saves every 60 seconds server-side to prevent loss on crash

**Multiplayer:**
- Never trust client for item counts, machine placement validity, or research delivery
- Co-op permission system checked server-side on every build action
- Plot state is server-owned; co-builders operate on a replicated view

**Exploits to Design Against:**
- Infinite item duplication via belt manipulation
- Research station spoofing (client-side false delivery)
- AFK farming via Automaton Courier infinite routing loops
- Blueprint injection (malformed code strings crashing the server)

**Scalability:**
- Machine specialization choices stored per-machine-instance, not per-type
- Blueprint code strings must be validated and sandboxed server-side before any placement

---

## 18. Rare Discoveries

### The Shiny System
Resource nodes are infinite and predictable — but rare discovery events break routine with server-wide excitement and permanent bragging rights.

### How Rare Nodes Spawn
When a Miner is placed on a resource node, there is a small biome-specific chance the node resolves as a **Rare Node** instead. Rare Nodes:
- Glow with unique particle effects distinct from their biome's palette
- Trigger an immediate discovery chime and screen flash for the owner
- Broadcast a **server-wide announcement**: *"[PlayerName] has struck [Rare Node Name] in [Biome Name]!"*
- Produce rare variant items at the same rate as their standard counterpart

### Rarity Tiers

| Rarity | Spawn Chance | Announcement | Visual |
|---|---|---|---|
| Uncommon | ~3% | Private notification only | Soft shimmer |
| Rare | ~1% | Server-wide broadcast | Bright glow + rising particles |
| Legendary | ~0.1% | Server-wide broadcast + fanfare sound | Animated light beam visible across the entire plot |

### Rare Resources by Biome

| Biome | Rare Node | Rarity | Rare Item | Use |
|---|---|---|---|---|
| Verdant Hollow | Starfire Iron | Rare | Starfire Ingot | Trophy display; Masterwork Smelter recipe |
| Verdant Hollow | Mooncopper | Rare | Mooncopper Ingot | Trophy display; Masterwork Wire Refinery recipe |
| Highland Reach | Gilded Vein | Rare | Gilded Alloy | Trophy display; Masterwork Gear Press recipe |
| Highland Reach | Embercoal | Uncommon | Embercoal | Feed to any Forge for +50% output for 60 sec |
| Volcanic Depths | Obsidian Heart | Legendary | Heart of Obsidian | Trophy display only — no recipe, pure prestige |
| Volcanic Depths | Sulphur Crown | Rare | Pure Sulphur | Masterwork Conductor Coil recipe |
| Crystal Caverns | Prismatic Crystal | Legendary | Prismatic Shard | Trophy display; unlocks cosmetic Crystal Resonator skin |
| Crystal Caverns | Resonance Geode | Rare | Resonance Gem | Counts as 5 Resonance Cores in any Tier 5 recipe |
| Aether Rift | Void Shard | Legendary | Void Fragment | Trophy display; required for secret Masterwork Blueprint |
| Aether Rift | Aether Bloom | Rare | Pure Aether Bloom | Counts as 10 Pure Aether in Ascension activation |

### The Trophy Case
A dedicated display machine available from Tier 1 (build cost: 5 Lumber + 3 Iron Ingots).

- 9 display slots — items float, rotate, and glow inside a glass-fronted case
- All visitors to the plot can see Trophy Case contents in 3D with a tooltip showing what the item is
- Trophy Case contents save with factory state and persist across ascensions (the case itself survives the reset)
- A full case of Legendary items is the highest non-numerical status signal in the game

### Masterwork Machines
Rare items can be combined with standard materials to produce **Masterwork Machines** — identical in function to their standard counterparts but with a unique visual skin, a persistent glow, and an ownership plaque showing the builder's name.

Masterwork recipes are hidden in the crafting menu until the player holds a qualifying rare item. Examples:

| Masterwork Machine | Recipe |
|---|---|
| Masterwork Smelter | 1 Starfire Ingot + 20 Iron Ingots + 10 Lumber |
| Masterwork Gear Press | 1 Gilded Alloy + 15 Iron Ingots + 5 Crushed Stone |
| Masterwork Wire Refinery | 1 Mooncopper Ingot + 10 Copper Ingots + 10 Iron Gears |
| Masterwork Forge Press | 1 Pure Sulphur + 25 Steel Plates + 15 Clockwork Modules |
| Masterwork Crystal Resonator | 1 Prismatic Shard + 50 Crystal Shards + 30 Resonance Cores |
| The Void Ascendant | 1 Void Fragment + 50 Pure Aether + 30 Conductor Arrays + 20 Void Stone |

*The Void Ascendant is an alternate skin for the Clockwork Ascendant with dramatically different visual effects during the activation sequence. Functionally identical.*

---

## 19. Clockwork Drone Network

### Overview
The Drone Network is the late-game logistics upgrade — an alternative to conveyor systems using autonomous Clockwork Drones that fly items and execute builds. Unlocked at Tier 4 via a dedicated side-branch research.

Directly inspired by Factorio's bot network. A well-designed Drone Network supplements conveyors for hard-to-reach areas, handles Blueprint auto-construction, and provides flexible item logistics that scales with factory complexity.

### Core Principle
Drones do not replace conveyors. They **complement** them. Belts are faster at sustained throughput. Drones are flexible — point-to-point routing without laying belt, they fly over terrain obstacles, and they auto-build Blueprint ghosts while you're offline. A hybrid factory (belts for main production lines, drones for logistics and construction) is the intended endgame.

### Unlock
**Tier 4 Side Branch Research: "Drone Network"** *(20 Optical Assemblies + 10 Conductor Coils + 10 Precision Gears)*

### New Machines

#### Drone Dock *(Tier 4)*
The hub of the drone network. Drones charge, park, and launch from Drone Docks. Multiple Docks extend coverage area.

| Stat | Value |
|---|---|
| Build cost | 25 Precision Gears + 20 Conductor Coils + 10 Optical Assemblies |
| Power draw | 120 PU idle; +30 PU per active drone |
| Coverage radius | 50 studs |
| Default drone capacity | 5 drones |
| Max drone capacity | 10 (via "Drone Expansion" side-branch research) |
| Supported drone types | Logistic, Construction (Tier 4); Scout (Tier 5) |

Adjacent Drone Docks overlap their radii and form a single unified Drone Network. The network is aware of all Provider/Requester Chests and Blueprint ghosts within any connected Dock's range.

#### Logistic Chests
Standard Storage Chests upgraded for drone logistics. Must be within a Drone Dock's radius to participate.

| Variant | Function | Build Cost |
|---|---|---|
| Provider Chest | Drones pull items from this chest to fill requests | Storage Mk2 + 5 Conductor Coils |
| Requester Chest | Set item type + quantity; drones deliver from Providers | Storage Mk2 + 5 Conductor Coils |
| Buffer Chest | Acts as both Provider and Requester | Storage Mk2 + 10 Conductor Coils |

#### Logistic Drone *(assigned to Drone Dock)*
Moves items between Provider and Requester Chests autonomously.

| Stat | Value |
|---|---|
| Carry capacity | 20 items per trip |
| Speed | Moderate — roughly Mk2 conveyor throughput per active drone |
| Behavior | Continuously services Requester Chests; idles at Dock when no requests are pending |
| Best use | Off-grid storage connections, biome-to-biome transfers, bypassing lava channels or rifts |

#### Construction Drone *(assigned to Drone Dock)*
Fetches materials and builds Blueprint ghost placements automatically.

| Stat | Value |
|---|---|
| Carry capacity | 1 machine component per trip |
| Speed | Deliberate — ~8 seconds per machine placed |
| Behavior | Detects Blueprint ghosts in Dock radius → fetches required materials from Provider Chests → flies to ghost → places machine |
| Best use | Auto-building large Blueprint layouts, expanding the factory while offline |

**Construction Flow:**
1. Player places a Blueprint as a ghost overlay (no materials deducted yet)
2. Construction Drones detect pending ghosts within Dock radius
3. Drones fetch required materials from Provider Chests in the network
4. Drones fly to each ghost and place the machine — materials deducted on placement
5. The entire Blueprint builds automatically; the player can watch or log off

Deconstruction works in reverse: player marks machines for deconstruction → Drones remove them → materials returned to a Buffer Chest in the network.

#### Scout Drone *(Tier 5 side branch)*
Explores unmapped areas of unlocked biomes and highlights rare node locations before a Miner is placed.

| Stat | Value |
|---|---|
| Unlock | Tier 5 side branch: "Scout Drones" *(10 Automaton Cores + 5 Resonance Cores)* |
| Build cost per drone | 5 Automaton Cores + 3 Resonance Cores + 3 Conductor Coils |
| Behavior | Autonomously patrols uncovered biome tiles, marks undiscovered nodes on the minimap |
| Rare node detection | Notifies the player when a potential Rare Node is detected — letting them choose whether to mine it before committing a Miner |

### Network Scaling
Each Drone Dock supports up to 10 drones split across any mix of Logistic, Construction, and Scout types. A full late-game factory might have 10–15 Docks and 80–100 drones active. Performance is server-managed — drone tasks are batched and calculated server-side, not simulated per-drone per-frame (see Section 17).

### Drones vs. Conveyors

| | Conveyor Network | Drone Network |
|---|---|---|
| Throughput | High (Mk5: 480/min) | Moderate (scales with drone count) |
| Flexibility | Low (fixed paths, terrain-sensitive) | High (fly over anything) |
| Setup cost | Low | High (Dock + chest infrastructure) |
| Blueprint auto-build | No | Yes |
| Off-grid routing | No | Yes |
| Best for | Main production lines | Logistics, construction, terrain bypass |

---

*End of Milestone 1 Design Document — v1.1 (added Sections 18–19)*
*Next: Milestone 2 — Repository Setup & Project Structure*
