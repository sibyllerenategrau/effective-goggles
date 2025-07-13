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
        checkInterval = 250, -- Reduced from 300ms for more frequent checks
        speedThreshold = 8.0, -- Reduced from 10.0 m/s (normal running speed ~7m/s)
        heightThreshold = 2.5, -- Reduced from 3.0 meters above ground without support
        teleportDistance = 20.0, -- Reduced from 25.0 instant movement distance threshold
        collisionCheckDistance = 2.0, -- distance to check for collisions
        maxWarnings = 1, -- Reduced from 2 warnings before action
        punishment = "kick", -- "kick", "ban", "warn"
        velocityChangeThreshold = 12.0, -- Reduced from 15.0 maximum velocity change per second
        rapidMovementThreshold = 15.0, -- Reduced from 20.0 threshold for rapid position changes
        consecutiveViolationLimit = 1 -- Reduced from 2 consecutive violations before escalation
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
        punishment = "kick",
        -- Spawn immunity settings
        spawnImmunity = {
            enabled = true,
            duration = 15000, -- 15 seconds of immunity after spawn/respawn
            undergroundOnly = true -- If true: only apply to Underground zone. If false: apply to ALL blacklisted zones
        }
    },
    
    -- God Mode Detection
    GodMode = {
        enabled = true,
        checkInterval = 1500, -- Reduced from 2000ms - Check every 1.5 seconds
        damageTestChance = 25, -- Increased from 20% chance to test
        maxHealthRegenerationRate = 8.0, -- Reduced from 10.0 max health regen per second
        maxArmorRegenerationRate = 4.0, -- Reduced from 5.0 max armor regen per second
        consecutiveFailLimit = 1, -- Reduced from 2 consecutive test failures before warning
        punishment = "ban"
    },
    
    -- Vehicle Speed Detection  
    VehicleSpeed = {
        enabled = true,
        checkInterval = 1000,
        speedMultiplierThreshold = 1.3, -- 1.3x max speed instead of 2.0x
        consecutiveViolationLimit = 2,
        punishment = "kick"
    },
    
    -- Vehicle Spawning Detection (NEW)
    VehicleSpawning = {
        enabled = true,
        checkInterval = 2000,
        maxVehiclesPerPlayer = 3, -- Max vehicles a player can have spawned at once
        spawnRateLimit = 1, -- Max vehicles per minute
        detectionRadius = 50.0, -- Radius around player to check for new vehicles
        punishment = "ban",
        whitelistedVehicles = { -- Admin vehicles that are allowed
            -- Add vehicle model hashes here if needed
        }
    },
    
    -- Invisibility Detection (NEW)
    Invisibility = {
        enabled = true,
        checkInterval = 1500,
        minAlphaThreshold = 50, -- Minimum alpha value (0-255, 255 = fully visible)
        consecutiveViolationLimit = 2,
        punishment = "kick"
    },
    
    -- Entity Manipulation Detection (NEW)
    EntityManipulation = {
        enabled = true,
        checkInterval = 3000,
        maxEntitiesPerPlayer = 5, -- Max entities a player can have around them
        detectionRadius = 30.0, -- Radius around player to check for spawned entities
        punishment = "ban"
    },
    
    -- Player Model Manipulation Detection (NEW)
    PlayerModel = {
        enabled = true,
        checkInterval = 5000,
        punishment = "ban",
        allowedModels = { -- Only allow these ped models (empty = allow all default)
            -- Add specific model hashes here if you want to restrict models
        },
        detectModelChanges = true, -- Detect rapid model switching
        maxModelChangesPerMinute = 2
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