-- Effective-Goggles Anticheat Configuration
Config = {}

-- General Settings
Config.ResourceName = "effective-goggles"
Config.EnableDebug = true
Config.LogToFile = true
Config.LogToConsole = true

-- Detection Settings
Config.Detection = {
    -- Noclip Detection
    Noclip = {
        enabled = true,
        checkInterval = 300, -- milliseconds (reduced from 500 for more frequent checks)
        speedThreshold = 10.0, -- m/s (normal running speed ~7m/s, lowered to catch more exploits)
        heightThreshold = 3.0, -- meters above ground without support (lowered)
        teleportDistance = 25.0, -- instant movement distance threshold (lowered from 50.0)
        collisionCheckDistance = 2.0, -- distance to check for collisions
        maxWarnings = 2, -- warnings before action (lowered from 3)
        punishment = "kick", -- "kick", "ban", "warn"
        velocityChangeThreshold = 15.0, -- maximum velocity change per second (new)
        rapidMovementThreshold = 20.0, -- threshold for rapid position changes (new)
        consecutiveViolationLimit = 2 -- consecutive violations before escalation (new)
    },
    
    -- Position Validation
    Position = {
        enabled = true,
        checkInterval = 1000,
        blacklistedZones = {
            -- Underground zones
            {x = 0, y = 0, z = -1000, radius = 8000, name = "Underground"},
            -- Add more zones as needed
        },
        maxHeight = 2000.0, -- Maximum allowed height
        punishment = "kick"
    },
    
    -- God Mode Detection
    GodMode = {
        enabled = true,
        checkInterval = 2000, -- Check every 2 seconds
        damageTestChance = 20, -- 20% chance to test (increased from 5%)
        maxHealthRegenerationRate = 10.0, -- max health regen per second
        maxArmorRegenerationRate = 5.0, -- max armor regen per second
        consecutiveFailLimit = 2, -- consecutive test failures before warning
        punishment = "ban"
    },
    
    -- Vehicle Speed Detection  
    VehicleSpeed = {
        enabled = true,
        checkInterval = 1000,
        speedMultiplierThreshold = 1.3, -- 1.3x max speed instead of 2.0x
        consecutiveViolationLimit = 2,
        punishment = "kick"
    }
}

-- Admin Settings
Config.Admin = {
    notifyAdmins = true,
    notifyDiscord = false, -- Set to true and configure webhook
    discordWebhook = "",
    adminPermissions = {
        "admin",
        "mod",
        "anticheat.admin"
    }
}

-- Whitelist (players immune to anticheat)
Config.Whitelist = {
    enabled = true,
    players = {
        -- Add steam IDs or license IDs here
        -- "steam:110000000000000",
        -- "license:abc123def456"
    }
}

-- Logging Settings
Config.Logging = {
    logFile = "logs/anticheat.log",
    logDetections = true,
    logWarnings = true,
    logPunishments = true,
    maxLogSize = 10485760 -- 10MB
}