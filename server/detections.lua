-- Anticheat Detection Systems
local AnticheataDetections = {}

-- Noclip Detection
function AnticheataDetections.CheckNoclip(playerId, position, velocity, inVehicle, onGround, speed)
    if not Config.Detection.Noclip.enabled then
        return
    end
    
    local playerData = AnticheataCore.GetPlayerData(playerId)
    if not playerData then
        return
    end
    
    local currentTime = GetGameTimer()
    local timeDelta = currentTime - playerData.lastUpdate
    
    -- Skip if time delta is too small or too large (lag)
    if timeDelta < 100 or timeDelta > 5000 then
        return
    end
    
    local lastPos = playerData.lastPosition
    local distance = Utils.GetDistance(position, lastPos)
    local timeInSeconds = timeDelta / 1000.0
    local calculatedSpeed = distance / timeInSeconds
    
    -- Detection 1: Speed check
    if not inVehicle and calculatedSpeed > Config.Detection.Noclip.speedThreshold then
        local reason = ("Suspicious speed: %.2f m/s (threshold: %.2f m/s)"):format(calculatedSpeed, Config.Detection.Noclip.speedThreshold)
        AnticheataDetections.HandleNoclipDetection(playerId, reason, "speed")
    end
    
    -- Detection 2: Teleportation check
    if distance > Config.Detection.Noclip.teleportDistance and timeInSeconds < 1.0 then
        local reason = ("Teleportation detected: %.2f meters in %.2f seconds"):format(distance, timeInSeconds)
        AnticheataDetections.HandleNoclipDetection(playerId, reason, "teleport")
    end
    
    -- Detection 3: Height check (floating without support)
    if not inVehicle and not onGround then
        local heightAboveGround = position.z - playerData.lastGroundZ
        if heightAboveGround > Config.Detection.Noclip.heightThreshold then
            -- Check if player has been floating for too long
            local floatingTime = currentTime - (playerData.lastGroundTime or currentTime)
            if floatingTime > 3000 then -- 3 seconds
                local reason = ("Floating %.2f meters above ground for %.2f seconds"):format(heightAboveGround, floatingTime / 1000.0)
                AnticheataDetections.HandleNoclipDetection(playerId, reason, "floating")
            end
        end
    else
        -- Update last ground time and position
        AnticheataCore.UpdatePlayerData(playerId, {
            lastGroundTime = currentTime,
            lastGroundZ = position.z
        })
    end
    
    -- Detection 4: Collision bypass check (moving through walls)
    if not inVehicle then
        AnticheataDetections.CheckCollisionBypass(playerId, lastPos, position)
    end
    
    -- Detection 5: Unnatural movement patterns
    if not inVehicle and distance > 1.0 then
        local velocityChange = math.abs(speed - (playerData.lastSpeed or 0))
        if velocityChange > 20.0 and timeInSeconds < 0.5 then
            local reason = ("Unnatural velocity change: %.2f m/s in %.2f seconds"):format(velocityChange, timeInSeconds)
            AnticheataDetections.HandleNoclipDetection(playerId, reason, "velocity")
        end
    end
    
    -- Update last speed
    AnticheataCore.UpdatePlayerData(playerId, {lastSpeed = speed})
end

-- Check for collision bypass
function AnticheataDetections.CheckCollisionBypass(playerId, startPos, endPos)
    -- This is a simplified collision check
    -- In a real implementation, you might want to use raycasting
    local distance = Utils.GetDistance(startPos, endPos)
    
    if distance > 5.0 then
        -- Check if the path between positions goes through solid objects
        -- This is a basic implementation - you could enhance with proper collision detection
        local steps = math.ceil(distance / 0.5)
        for i = 1, steps do
            local t = i / steps
            local checkPos = {
                x = startPos.x + (endPos.x - startPos.x) * t,
                y = startPos.y + (endPos.y - startPos.y) * t,
                z = startPos.z + (endPos.z - startPos.z) * t
            }
            
            -- Request collision check from client
            TriggerClientEvent('anticheat:checkCollision', playerId, checkPos, i)
        end
    end
end

-- Handle noclip detection
function AnticheataDetections.HandleNoclipDetection(playerId, reason, detectionType)
    local warningCount = AnticheataCore.AddWarning(playerId, "noclip", reason)
    
    if warningCount >= Config.Detection.Noclip.maxWarnings then
        AnticheataCore.PunishPlayer(playerId, "noclip", reason, Config.Detection.Noclip.punishment)
    else
        -- Teleport player back to last safe position as a corrective measure
        local playerData = AnticheataCore.GetPlayerData(playerId)
        if playerData and playerData.lastPosition then
            TriggerClientEvent('anticheat:teleportToPosition', playerId, playerData.lastPosition)
        end
    end
end

-- Position validation
function AnticheataDetections.CheckPosition(playerId, position)
    if not Config.Detection.Position.enabled then
        return
    end
    
    -- Check if position is in blacklisted zone
    local inBlacklistedZone, zoneName = Utils.IsPositionInBlacklistedZone(position)
    if inBlacklistedZone then
        local reason = ("Player in blacklisted zone: %s"):format(zoneName)
        local warningCount = AnticheataCore.AddWarning(playerId, "position", reason)
        
        if warningCount >= 2 then
            AnticheataCore.PunishPlayer(playerId, "position", reason, Config.Detection.Position.punishment)
        else
            -- Teleport player to a safe location
            TriggerClientEvent('anticheat:teleportToSafeLocation', playerId)
        end
    end
    
    -- Check if position is too high
    if position.z > Config.Detection.Position.maxHeight then
        local reason = ("Player too high: %.2f (max: %.2f)"):format(position.z, Config.Detection.Position.maxHeight)
        local warningCount = AnticheataCore.AddWarning(playerId, "position", reason)
        
        if warningCount >= 2 then
            AnticheataCore.PunishPlayer(playerId, "position", reason, Config.Detection.Position.punishment)
        else
            -- Teleport player down
            local safePos = {x = position.x, y = position.y, z = 30.0}
            TriggerClientEvent('anticheat:teleportToPosition', playerId, safePos)
        end
    end
end

-- Handle collision check result from client
RegisterServerEvent('anticheat:collisionResult')
AddEventHandler('anticheat:collisionResult', function(position, hasCollision, stepId)
    local playerId = source
    
    if not hasCollision then
        -- Player moved through a solid object
        local reason = ("Collision bypass detected at position: %.2f, %.2f, %.2f"):format(position.x, position.y, position.z)
        AnticheataDetections.HandleNoclipDetection(playerId, reason, "collision")
    end
end)

-- Periodically check all players
CreateThread(function()
    while true do
        Wait(Config.Detection.Noclip.checkInterval)
        
        local players = GetPlayers()
        for _, playerId in pairs(players) do
            if not Utils.IsPlayerWhitelisted(playerId) then
                -- Request updated position from client
                TriggerClientEvent('anticheat:requestUpdate', playerId)
            end
        end
    end
end)

-- Handle suspicious activity reports from client
RegisterServerEvent('anticheat:suspiciousActivity')
AddEventHandler('anticheat:suspiciousActivity', function(activityType, reason)
    local playerId = source
    
    if Utils.IsPlayerWhitelisted(playerId) then
        return
    end
    
    local warningCount = AnticheataCore.AddWarning(playerId, activityType, reason)
    
    -- Different thresholds for different activity types
    local maxWarnings = 2
    local punishment = "kick"
    
    if activityType == "godmode" then
        maxWarnings = 2
        punishment = "ban"
    elseif activityType == "speedhack" then
        maxWarnings = 3
        punishment = "kick"
    elseif activityType == "menu_injection" then
        maxWarnings = 1
        punishment = "ban"
    elseif activityType == "collision_bypass" then
        maxWarnings = 2
        punishment = "kick"
    elseif activityType == "noclip_pattern" then
        maxWarnings = 2
        punishment = "kick"
    end
    
    if warningCount >= maxWarnings then
        AnticheataCore.PunishPlayer(playerId, activityType, reason, punishment)
    end
end)

-- Export functions
_G.AnticheataDetections = AnticheataDetections