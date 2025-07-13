-- Server Core Anticheat System
local AnticheataCore = {}
local playerData = {}
local warnings = {}

-- Initialize player data
function AnticheataCore.InitializePlayer(playerId)
    local ped = GetPlayerPed(playerId)
    local coords = GetEntityCoords(ped)
    
    playerData[playerId] = {
        lastPosition = coords,
        lastGroundZ = coords.z,
        lastVelocity = vector3(0, 0, 0),
        lastUpdate = GetGameTimer(),
        inVehicle = false,
        isAdmin = false,
        connectionTime = GetGameTimer()
    }
    
    warnings[playerId] = {
        noclip = 0,
        position = 0,
        total = 0
    }
    
    if Config.EnableDebug then
        print(("[%s] Player %s initialized in anticheat system"):format(Config.ResourceName, GetPlayerName(playerId)))
    end
end

-- Clean up player data
function AnticheataCore.CleanupPlayer(playerId)
    playerData[playerId] = nil
    warnings[playerId] = nil
    
    if Config.EnableDebug then
        print(("[%s] Player %s removed from anticheat system"):format(Config.ResourceName, playerId))
    end
end

-- Check if player is admin
function AnticheataCore.IsPlayerAdmin(playerId)
    -- Check if player has admin permissions
    for _, permission in pairs(Config.Admin.adminPermissions) do
        if IsPlayerAceAllowed(playerId, permission) then
            return true
        end
    end
    return false
end

-- Add warning to player
function AnticheataCore.AddWarning(playerId, detectionType, reason)
    if not warnings[playerId] then
        warnings[playerId] = {noclip = 0, position = 0, total = 0}
    end
    
    warnings[playerId][detectionType] = warnings[playerId][detectionType] + 1
    warnings[playerId].total = warnings[playerId].total + 1
    
    local warningCount = warnings[playerId][detectionType]
    
    -- Log warning
    AnticheataLogging.LogDetection(playerId, detectionType, reason, "warning", warningCount)
    
    -- Notify admins
    if Config.Admin.notifyAdmins then
        AnticheataCore.NotifyAdmins(("^3[ANTICHEAT]^7 %s - %s (Warning %d)"):format(GetPlayerName(playerId), reason, warningCount))
    end
    
    return warningCount
end

-- Punish player
function AnticheataCore.PunishPlayer(playerId, detectionType, reason, punishmentType)
    local playerName = GetPlayerName(playerId)
    local identifier = Utils.GetPlayerIdentifier(playerId)
    
    -- Log punishment
    AnticheataLogging.LogDetection(playerId, detectionType, reason, punishmentType, warnings[playerId][detectionType])
    
    if punishmentType == "kick" then
        DropPlayer(playerId, ("🚫 ANTICHEAT: %s"):format(reason))
        AnticheataCore.NotifyAdmins(("^1[ANTICHEAT]^7 %s kicked for %s"):format(playerName, reason))
    elseif punishmentType == "ban" then
        -- Add to ban list (you might want to integrate with your ban system)
        DropPlayer(playerId, ("🚫 ANTICHEAT BAN: %s"):format(reason))
        AnticheataCore.NotifyAdmins(("^1[ANTICHEAT]^7 %s banned for %s"):format(playerName, reason))
    elseif punishmentType == "warn" then
        -- Just a warning message
        TriggerClientEvent('chat:addMessage', playerId, {
            color = {255, 0, 0},
            multiline = true,
            args = {"[ANTICHEAT]", reason}
        })
    end
end

-- Notify admins
function AnticheataCore.NotifyAdmins(message)
    local players = GetPlayers()
    for _, playerId in pairs(players) do
        if AnticheataCore.IsPlayerAdmin(playerId) then
            TriggerClientEvent('chat:addMessage', playerId, {
                color = {255, 165, 0},
                multiline = true,
                args = {"[ADMIN]", message}
            })
        end
    end
    
    if Config.LogToConsole then
        print(message)
    end
end

-- Get player data
function AnticheataCore.GetPlayerData(playerId)
    return playerData[playerId]
end

-- Update player data
function AnticheataCore.UpdatePlayerData(playerId, data)
    if playerData[playerId] then
        for key, value in pairs(data) do
            playerData[playerId][key] = value
        end
    end
end

-- Event handlers
RegisterServerEvent('anticheat:playerLoaded')
AddEventHandler('anticheat:playerLoaded', function()
    local playerId = source
    AnticheataCore.InitializePlayer(playerId)
end)

RegisterServerEvent('anticheat:updatePosition')
AddEventHandler('anticheat:updatePosition', function(position, velocity, inVehicle, onGround, speed, health, armor, vehicleData)
    local playerId = source
    
    if Utils.IsPlayerWhitelisted(playerId) then
        return
    end
    
    if not playerData[playerId] then
        AnticheataCore.InitializePlayer(playerId)
        return
    end
    
    local playerInfo = playerData[playerId]
    
    -- Trigger detection checks
    AnticheataDetections.CheckNoclip(playerId, position, velocity, inVehicle, onGround, speed)
    AnticheataDetections.CheckPosition(playerId, position)
    
    -- God mode detection (if health/armor provided)
    if health and armor then
        AnticheataDetections.CheckGodMode(playerId, health, armor, playerInfo.lastHealth or health, playerInfo.lastArmor or armor)
    end
    
    -- Vehicle speed detection (if in vehicle and vehicle data provided)
    if inVehicle and vehicleData then
        AnticheataDetections.CheckVehicleSpeed(playerId, vehicleData.entity, speed, vehicleData.maxSpeed)
    end
    
    -- Update player data
    AnticheataCore.UpdatePlayerData(playerId, {
        lastPosition = position,
        lastVelocity = velocity,
        lastUpdate = GetGameTimer(),
        inVehicle = inVehicle,
        lastHealth = health,
        lastArmor = armor
    })
end)

AddEventHandler('playerDropped', function(reason)
    local playerId = source
    AnticheataCore.CleanupPlayer(playerId)
end)

-- Export functions
_G.AnticheataCore = AnticheataCore