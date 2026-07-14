--!strict
local JuiceConfig = {}

-- Camera shake amplitudes (studs of random offset)
JuiceConfig.SHAKE_TREE_HIT       = 0.08
JuiceConfig.SHAKE_TREE_FALL      = 0.35
JuiceConfig.SHAKE_MACHINE_PLACE  = 0.15
JuiceConfig.SHAKE_MACHINE_OUTPUT = 0.04

-- Camera shake durations (seconds)
JuiceConfig.SHAKE_DUR_TREE_HIT      = 0.12
JuiceConfig.SHAKE_DUR_TREE_FALL     = 0.45
JuiceConfig.SHAKE_DUR_MACHINE_PLACE = 0.20
JuiceConfig.SHAKE_DUR_OUTPUT        = 0.10

-- Particle burst counts
JuiceConfig.CHIPS_PER_HIT    = 8   -- wood chips on tree hit
JuiceConfig.LEAVES_ON_FALL   = 22  -- leaves when tree falls
JuiceConfig.DUST_ON_PLACE    = 12  -- dust when machine placed
JuiceConfig.SPARKS_ON_OUTPUT = 5   -- sparks when lumber mill outputs

-- Machine placement spring animation
JuiceConfig.PLACE_SCALE_TIME = 0.18  -- seconds for full spring cycle
JuiceConfig.PLACE_OVERSHOOT  = 1.12  -- peak scale factor before settling

-- Conveyor belt texture scroll
JuiceConfig.BELT_SCROLL_SPEED = 1.5  -- studs/second on OffsetStudsV

-- Lumber mill progress bar (BillboardGui above machine)
JuiceConfig.PROGRESS_BAR_WIDTH    = 80    -- pixels
JuiceConfig.PROGRESS_BAR_HEIGHT   = 10    -- pixels
JuiceConfig.PROGRESS_STUDS_OFFSET = 5.0   -- studs above Base CFrame
JuiceConfig.PROGRESS_CYCLE_SECS   = 3.0   -- LUMBER_MILL_PROCESS_TICKS / MACHINE_TICK_HZ

-- HUD floating text timing
JuiceConfig.POPUP_SCALE_TIME = 0.12
JuiceConfig.POPUP_HOLD_TIME  = 0.55
JuiceConfig.POPUP_FADE_TIME  = 0.35

-- Sound asset IDs (Roblox free audio catalog).
-- Test each ID in Studio by right-clicking a Sound and pressing Play.
-- Swap any silent ID with a free sound from the Creator Store.
-- All IDs are 0 (silent) until verified free audio assets are sourced.
-- To add a sound: find a free audio asset in the Creator Store, paste its ID here,
-- test with right-click → Play in a Sound object, then commit.
JuiceConfig.SFX = {
    TREE_HIT      = 0,
    TREE_CRACK    = 0,
    TREE_FALL     = 0,
    MACHINE_PLACE = 0,
    MACHINE_HUM   = 0,
    BELT_LOOP     = 0,
    STORAGE_FILL  = 0,
    ITEM_COLLECT  = 0,
    STEP_COMPLETE = 0,
}

-- Particle colors
JuiceConfig.COLOR_WOOD_CHIP   = Color3.fromRGB(139, 90,  43)
JuiceConfig.COLOR_LEAF        = Color3.fromRGB(85,  160, 60)
JuiceConfig.COLOR_DUST        = Color3.fromRGB(160, 140, 120)
JuiceConfig.COLOR_SPARK       = Color3.fromRGB(255, 200, 50)
JuiceConfig.COLOR_PROGRESS_BG = Color3.fromRGB(30,  30,  30)
JuiceConfig.COLOR_PROGRESS_FG = Color3.fromRGB(80,  200, 80)

-- Onboarding step labels (shown in objectives panel, Task 7)
JuiceConfig.STEP_LABELS = {
    "Place a Lumber Mill",
    "First Lumber Produced!",
    "Connect a Conveyor",
    "Build a Storage Chest",
    "Your factory runs!",
}

return JuiceConfig
