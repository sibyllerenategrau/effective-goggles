-- Test Example for FiveM Anticheat
-- This file demonstrates how to use the Effective-Goggles anticheat system

-- Example server.cfg entry:
-- start effective-goggles

-- Example usage in other resources:

-- Check if a player is whitelisted
function IsPlayerWhitelistedExample(playerId)
    return Utils.IsPlayerWhitelisted(playerId)
end

-- Example of adding custom detection
RegisterServerEvent('custom:noclipDetection')
AddEventHandler('custom:noclipDetection', function(playerData)
    local playerId = source
    
    -- Custom logic here
    local reason = "Custom noclip detection triggered"
    
    -- Use the anticheat system to handle the detection
    AnticheataCore.AddWarning(playerId, "noclip", reason)
end)

-- Example of integrating with existing ban system
function IntegrateWithBanSystem()
    -- Override the punishment system
    local originalPunishPlayer = AnticheataCore.PunishPlayer
    
    AnticheataCore.PunishPlayer = function(playerId, detectionType, reason, punishmentType)
        if punishmentType == "ban" then
            -- Call your existing ban system
            -- YourBanSystem.BanPlayer(playerId, reason)
            DropPlayer(playerId, "Banned by anticheat: " .. reason)
        else
            -- Use original punishment
            originalPunishPlayer(playerId, detectionType, reason, punishmentType)
        end
    end
end

-- Example configuration for different server types

-- Strict RP Server Configuration
local StrictRPConfig = {
    speedThreshold = 10.0,
    heightThreshold = 3.0,
    maxWarnings = 2,
    punishment = "ban"
}

-- Casual Server Configuration  
local CasualConfig = {
    speedThreshold = 20.0,
    heightThreshold = 8.0,
    maxWarnings = 5,
    punishment = "kick"
}

-- Racing Server Configuration
local RacingConfig = {
    speedThreshold = 50.0, -- Higher threshold for racing
    heightThreshold = 10.0,
    maxWarnings = 3,
    punishment = "kick"
}

print("Effective-Goggles Anticheat examples loaded")