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
        checkInterval = 500, -- milliseconds
        speedThreshold = 15.0, -- m/s (normal running speed ~7m/s)
        heightThreshold = 5.0, -- meters above ground without support
        teleportDistance = 50.0, -- instant movement distance threshold
        collisionCheckDistance = 2.0, -- distance to check for collisions
        maxWarnings = 3, -- warnings before action
        punishment = "kick" -- "kick", "ban", "warn"
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