Config = {}

-- ===========================
-- TACTICAL LEAN SETTINGS
-- ===========================
Config.Lean = {
    TPV = {
        lateralOffsetClose = 0.50,
        lateralOffsetMedium = 0.65,
        lateralOffsetFar = 0.75,
        extraRightOffset = 0.45,
        verticalOffset = 0.55,
        cameraRoll = 10.0,
    },
    -- Animation Dictionaries
    Anims = {
        LEFT = {
            high = { dict = "anim@tactical_highlow_high_leftlean", clip = "high_leftlean_clip" },
            low = { dict = "anim@tactical_highlow_low_leftlean", clip = "low_leftlean_clip" }
        },
        RIGHT = {
            high = { dict = "anim@highlow_high_lean", clip = "high_lean_clip" },
            low = { dict = "anim@highlow_low_lean", clip = "low_lean_clip" }
        }
    },

    LKey = 'Q',
    RKey = 'E',
}

-- ===========================
-- QUICK THROW SETTINGS
-- ===========================
Config.QuickThrow = {
    Enabled = true,
    Cooldown = 1500, -- ms
    Key = 'G',
    Throwables = {
        { item = 'WEAPON_GRENADE',      hash = `WEAPON_GRENADE`,      speed = 35.0, label = "Grenade" },
        { item = 'WEAPON_MOLOTOV',      hash = `WEAPON_MOLOTOV`,      speed = 30.0, label = "Molotov" },
        { item = 'WEAPON_SMOKEGRENADE', hash = `WEAPON_SMOKEGRENADE`, speed = 35.0, label = "Smoke Grenade" },
        { item = 'WEAPON_BZGAS',        hash = `WEAPON_BZGAS`,        speed = 35.0, label = "BZ Gas" },
        { item = 'WEAPON_STICKYBOMB',   hash = `WEAPON_STICKYBOMB`,   speed = 25.0, label = "Sticky Bomb" },
        { item = 'WEAPON_PIPEBOMB',     hash = `WEAPON_PIPEBOMB`,     speed = 25.0, label = "Pipe Bomb" },
        { item = 'WEAPON_FLARE',        hash = `WEAPON_FLARE`,        speed = 40.0, label = "Flare" },
    }
}

