--!strict
-- Animation asset IDs and UI transition timings.
-- Replace placeholder IDs (0) with real Roblox asset IDs in Milestone 4/5.

local AnimationConfig = {}

AnimationConfig.ANIMATIONS = {
    machine_running  = { id = 0, looped = true  },
    machine_idle     = { id = 0, looped = true  },
    machine_offline  = { id = 0, looped = true  },
    conveyor_move    = { id = 0, looped = true  },
    drone_fly        = { id = 0, looped = true  },
    drone_carry      = { id = 0, looped = true  },
    rare_node_glow   = { id = 0, looped = true  },
    ascension_pulse  = { id = 0, looped = false },
    trophy_sparkle   = { id = 0, looped = false },
}

-- UI tween durations in seconds.
AnimationConfig.UI = {
    TOOLBAR_SLIDE          = 0.25,
    NOTIFICATION_FADE      = 0.40,
    PROGRESS_BAR_TWEEN     = 0.30,
    RESEARCH_COMPLETE_HOLD = 3.00,
    PANEL_OPEN             = 0.20,
    PANEL_CLOSE            = 0.15,
}

return AnimationConfig
