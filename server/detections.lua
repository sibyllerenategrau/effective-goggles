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
    
    -- Initialize violation counters if not exist
    if not playerData.violations then
        playerData.violations = {
            noclip = {count = 0, consecutive = 0, lastViolation = 0},
            teleport = {count = 0, consecutive = 0, lastViolation = 0},
            speed = {count = 0, consecutive = 0, lastViolation = 0}
        }
    end
    
    -- Detection 1: Enhanced speed check
    if not inVehicle and calculatedSpeed > Config.Detection.Noclip.speedThreshold then
        playerData.violations.speed.count = playerData.violations.speed.count + 1
        playerData.violations.speed.consecutive = playerData.violations.speed.consecutive + 1
        playerData.violations.speed.lastViolation = currentTime
        
        local reason = ("Suspicious speed: %.2f m/s (threshold: %.2f m/s) - Violation #%d"):format(
            calculatedSpeed, Config.Detection.Noclip.speedThreshold, playerData.violations.speed.count)
        AnticheataDetections.HandleNoclipDetection(playerId, reason, "speed")
    else
        -- Reset consecutive counter if no violation
        if currentTime - playerData.violations.speed.lastViolation > 5000 then
            playerData.violations.speed.consecutive = 0
        end
    end
    
    -- Detection 2: Enhanced teleportation check with velocity validation
    if distance > Config.Detection.Noclip.teleportDistance and timeInSeconds < 1.0 then
        -- Additional validation: check if velocity supports this movement
        local velocityDistance = #velocity * timeInSeconds
        if math.abs(distance - velocityDistance) > distance * 0.5 then -- 50% tolerance for velocity mismatch
            playerData.violations.teleport.count = playerData.violations.teleport.count + 1
            playerData.violations.teleport.consecutive = playerData.violations.teleport.consecutive + 1
            playerData.violations.teleport.lastViolation = currentTime
            
            local reason = ("Teleportation detected: %.2f meters in %.2f seconds (velocity mismatch: %.2f vs %.2f) - Violation #%d"):format(
                distance, timeInSeconds, distance, velocityDistance, playerData.violations.teleport.count)
            AnticheataDetections.HandleNoclipDetection(playerId, reason, "teleport")
        end
    else
        if currentTime - playerData.violations.teleport.lastViolation > 5000 then
            playerData.violations.teleport.consecutive = 0
        end
    end
    
    -- Detection 3: Improved height check with better ground detection
    if not inVehicle and not onGround then
        local heightAboveGround = position.z - playerData.lastGroundZ
        if heightAboveGround > Config.Detection.Noclip.heightThreshold then
            -- Check if player has been floating for too long
            local floatingTime = currentTime - (playerData.lastGroundTime or currentTime)
            if floatingTime > 1500 then -- Reduced from 2 seconds to 1.5 seconds
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
    
    -- Detection 4: Enhanced collision bypass check
    if not inVehicle then
        AnticheataDetections.CheckCollisionBypass(playerId, lastPos, position)
    end
    
    -- Detection 5: Enhanced unnatural movement patterns
    if not inVehicle and distance > 1.0 then
        local velocityChange = math.abs(speed - (playerData.lastSpeed or 0))
        -- Tightened velocity change threshold
        if velocityChange > Config.Detection.Noclip.velocityChangeThreshold and timeInSeconds < 0.5 then
            local reason = ("Unnatural velocity change: %.2f m/s in %.2f seconds"):format(velocityChange, timeInSeconds)
            AnticheataDetections.HandleNoclipDetection(playerId, reason, "velocity")
        end
        
        -- Detection for rapid movement patterns
        if calculatedSpeed > Config.Detection.Noclip.rapidMovementThreshold then
            playerData.violations.noclip.count = playerData.violations.noclip.count + 1
            playerData.violations.noclip.consecutive = playerData.violations.noclip.consecutive + 1
            playerData.violations.noclip.lastViolation = currentTime
            
            local reason = ("Rapid movement pattern: %.2f m/s over %.2f seconds - Violation #%d"):format(
                calculatedSpeed, timeInSeconds, playerData.violations.noclip.count)
            AnticheataDetections.HandleNoclipDetection(playerId, reason, "rapid_movement")
        else
            if currentTime - playerData.violations.noclip.lastViolation > 5000 then
                playerData.violations.noclip.consecutive = 0
            end
        end
    end
    
    -- Update last speed and violation tracking
    AnticheataCore.UpdatePlayerData(playerId, {
        lastSpeed = speed,
        violations = playerData.violations
    })
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

-- Handle noclip detection with escalation based on consecutive violations
function AnticheataDetections.HandleNoclipDetection(playerId, reason, detectionType)
    local playerData = AnticheataCore.GetPlayerData(playerId)
    local violationData = playerData.violations and playerData.violations[detectionType] or {consecutive = 1}
    
    -- Escalate punishment based on consecutive violations
    local punishment = Config.Detection.Noclip.punishment
    if violationData.consecutive >= Config.Detection.Noclip.consecutiveViolationLimit then
        punishment = "ban" -- Escalate to ban for persistent violators
    end
    
    local warningCount = AnticheataCore.AddWarning(playerId, "noclip", reason)
    
    if warningCount >= Config.Detection.Noclip.maxWarnings then
        AnticheataCore.PunishPlayer(playerId, "noclip", reason, punishment)
    else
        -- Teleport player back to last safe position as a corrective measure
        if playerData and playerData.lastPosition then
            TriggerClientEvent('anticheat:teleportToPosition', playerId, playerData.lastPosition)
        end
    end
end

-- Position validation with enhanced checks
function AnticheataDetections.CheckPosition(playerId, position)
    if not Config.Detection.Position.enabled then
        return
    end
    
    local playerData = AnticheataCore.GetPlayerData(playerId)
    if not playerData then
        return
    end
    
    -- Check if position is in blacklisted zone
    local inBlacklistedZone, zoneName = Utils.IsPositionInBlacklistedZone(position)
    if inBlacklistedZone then
        -- Check for spawn immunity if this is an underground zone
        local isUndergroundZone = zoneName == "Underground"
        local hasSpawnImmunity = AnticheataCore.HasSpawnImmunity(playerId)
        
        if isUndergroundZone and hasSpawnImmunity and Config.Detection.Position.spawnImmunity.undergroundOnly then
            -- Player has spawn immunity for underground zones, skip detection
            if Config.EnableDebug then
                print(("[%s] Player %s in underground zone but has spawn immunity (%.1fs remaining)"):format(
                    Config.ResourceName, 
                    GetPlayerName(playerId),
                    (playerData.spawnImmunity.duration - (GetGameTimer() - playerData.spawnImmunity.startTime)) / 1000.0
                ))
            end
            return
        end
        
        local reason = ("Player in blacklisted zone: %s"):format(zoneName)
        local warningCount = AnticheataCore.AddWarning(playerId, "position", reason)
        
        if warningCount >= 2 then
            AnticheataCore.PunishPlayer(playerId, "position", reason, Config.Detection.Position.punishment)
        else
            -- Teleport player to a safe location
            TriggerClientEvent('anticheat:teleportToSafeLocation', playerId)
            -- Reset spawn immunity after teleporting to safe location
            AnticheataCore.ResetSpawnImmunity(playerId)
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
    
    -- Additional server-side validation
    local currentTime = GetGameTimer()
    local lastPos = playerData.lastPosition
    
    if lastPos then
        local distance = Utils.GetDistance(position, lastPos)
        local timeDelta = (currentTime - playerData.lastUpdate) / 1000.0
        
        -- Server-side teleportation validation (more strict on server)
        if distance > 20.0 and timeDelta < 1.0 then
            local calculatedSpeed = distance / timeDelta
            if calculatedSpeed > 50.0 then -- Extremely fast movement
                local reason = ("Server-side teleport validation failed: %.2f meters in %.2f seconds (%.2f m/s)"):format(
                    distance, timeDelta, calculatedSpeed)
                local warningCount = AnticheataCore.AddWarning(playerId, "position", reason)
                
                if warningCount >= 1 then -- Immediate action for extreme teleportation
                    AnticheataCore.PunishPlayer(playerId, "position", reason, "kick")
                else
                    TriggerClientEvent('anticheat:teleportToPosition', playerId, lastPos)
                end
            end
        end
        
        -- Check for impossible coordinate values
        if math.abs(position.x) > 10000 or math.abs(position.y) > 10000 or position.z > 5000 or position.z < -2000 then
            local reason = ("Impossible coordinates: %.2f, %.2f, %.2f"):format(position.x, position.y, position.z)
            AnticheataCore.PunishPlayer(playerId, "position", reason, "kick")
            return
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
    
    -- Stricter thresholds and punishments for different activity types
    local maxWarnings = 2
    local punishment = "kick"
    
    if activityType == "godmode" then
        maxWarnings = 1 -- Immediate action for god mode
        punishment = "ban"
    elseif activityType == "speedhack" then
        maxWarnings = 2 -- Reduced from 3
        punishment = "kick"
    elseif activityType == "menu_injection" then
        maxWarnings = 1
        punishment = "ban"
    elseif activityType == "collision_bypass" then
        maxWarnings = 2 -- Reduced from original
        punishment = "kick"
    elseif activityType == "noclip_pattern" then
        maxWarnings = 2
        punishment = "kick"
    elseif activityType == "timehack" or activityType == "weatherhack" then
        maxWarnings = 1 -- Immediate action for environment manipulation
        punishment = "ban"
    elseif activityType == "invisibility" then -- NEW
        maxWarnings = 1 -- Immediate action for invisibility
        punishment = "ban"
    elseif activityType == "vehicle_spawning" then -- NEW
        maxWarnings = 1 -- Immediate action for vehicle spawning
        punishment = "ban"
    elseif activityType == "entity_manipulation" then -- NEW
        maxWarnings = 1 -- Immediate action for entity spawning
        punishment = "ban"
    elseif activityType == "player_model" then -- NEW
        maxWarnings = 1 -- Immediate action for model manipulation
        punishment = "ban"
    end
    
    if warningCount >= maxWarnings then
        AnticheataCore.PunishPlayer(playerId, activityType, reason, punishment)
    end
end)

-- Export functions
_G.AnticheataDetections = AnticheataDetections

-- God Mode Detection
function AnticheataDetections.CheckGodMode(playerId, health, armor, lastHealth, lastArmor)
    if not Config.Detection.GodMode.enabled then
        return
    end
    
    local playerData = AnticheataCore.GetPlayerData(playerId)
    if not playerData then
        return
    end
    
    local currentTime = GetGameTimer()
    local timeDelta = (currentTime - playerData.lastUpdate) / 1000.0 -- in seconds
    
    if timeDelta < 0.1 or timeDelta > 10.0 then
        return
    end
    
    -- Initialize god mode tracking
    if not playerData.godModeData then
        playerData.godModeData = {
            suspiciousRegenCount = 0,
            lastDamageTestTime = 0,
            testFailures = 0,
            lastTestHealth = health
        }
    end
    
    -- Check for suspicious health regeneration
    if health > lastHealth then
        local healthRegen = (health - lastHealth) / timeDelta
        if healthRegen > Config.Detection.GodMode.maxHealthRegenerationRate then
            playerData.godModeData.suspiciousRegenCount = playerData.godModeData.suspiciousRegenCount + 1
            local reason = ("Suspicious health regeneration: %.2f HP/sec (max: %.2f)"):format(
                healthRegen, Config.Detection.GodMode.maxHealthRegenerationRate)
            AnticheataDetections.HandleGodModeDetection(playerId, reason)
        end
    end
    
    -- Check for suspicious armor regeneration
    if armor > lastArmor then
        local armorRegen = (armor - lastArmor) / timeDelta
        if armorRegen > Config.Detection.GodMode.maxArmorRegenerationRate then
            playerData.godModeData.suspiciousRegenCount = playerData.godModeData.suspiciousRegenCount + 1
            local reason = ("Suspicious armor regeneration: %.2f armor/sec (max: %.2f)"):format(
                armorRegen, Config.Detection.GodMode.maxArmorRegenerationRate)
            AnticheataDetections.HandleGodModeDetection(playerId, reason)
        end
    end
    
    -- Periodic damage testing (increased frequency)
    if currentTime - playerData.godModeData.lastDamageTestTime > Config.Detection.GodMode.checkInterval then
        if math.random(1, 100) <= Config.Detection.GodMode.damageTestChance then
            TriggerClientEvent('anticheat:performGodModeTest', playerId)
            playerData.godModeData.lastDamageTestTime = currentTime
            playerData.godModeData.lastTestHealth = health
        end
    end
    
    AnticheataCore.UpdatePlayerData(playerId, {godModeData = playerData.godModeData})
end

-- Handle god mode detection
function AnticheataDetections.HandleGodModeDetection(playerId, reason)
    local warningCount = AnticheataCore.AddWarning(playerId, "godmode", reason)
    
    if warningCount >= 1 then -- Immediate action for god mode
        AnticheataCore.PunishPlayer(playerId, "godmode", reason, Config.Detection.GodMode.punishment)
    end
end

-- Vehicle Speed Detection
function AnticheataDetections.CheckVehicleSpeed(playerId, vehicle, speed, maxSpeed)
    if not Config.Detection.VehicleSpeed.enabled then
        return
    end
    
    local playerData = AnticheataCore.GetPlayerData(playerId)
    if not playerData then
        return
    end
    
    -- Initialize vehicle speed tracking
    if not playerData.vehicleSpeedData then
        playerData.vehicleSpeedData = {
            violations = 0,
            consecutive = 0,
            lastViolation = 0
        }
    end
    
    local currentTime = GetGameTimer()
    local speedThreshold = maxSpeed * Config.Detection.VehicleSpeed.speedMultiplierThreshold
    
    if speed > speedThreshold then
        playerData.vehicleSpeedData.violations = playerData.vehicleSpeedData.violations + 1
        playerData.vehicleSpeedData.consecutive = playerData.vehicleSpeedData.consecutive + 1
        playerData.vehicleSpeedData.lastViolation = currentTime
        
        local reason = ("Vehicle speed hack: %.2f m/s (max: %.2f, threshold: %.2f) - Violation #%d"):format(
            speed, maxSpeed, speedThreshold, playerData.vehicleSpeedData.violations)
        
        if playerData.vehicleSpeedData.consecutive >= Config.Detection.VehicleSpeed.consecutiveViolationLimit then
            AnticheataCore.PunishPlayer(playerId, "speedhack", reason, Config.Detection.VehicleSpeed.punishment)
            playerData.vehicleSpeedData.consecutive = 0 -- Reset after punishment
        else
            AnticheataCore.AddWarning(playerId, "speedhack", reason)
        end
    else
        -- Reset consecutive counter if no violation for 5 seconds
        if currentTime - playerData.vehicleSpeedData.lastViolation > 5000 then
            playerData.vehicleSpeedData.consecutive = 0
        end
    end
    
    AnticheataCore.UpdatePlayerData(playerId, {vehicleSpeedData = playerData.vehicleSpeedData})
end

-- Handle god mode test results
RegisterServerEvent('anticheat:godModeTestResult')
AddEventHandler('anticheat:godModeTestResult', function(testPassed, finalHealth, originalHealth)
    local playerId = source
    
    if Utils.IsPlayerWhitelisted(playerId) then
        return
    end
    
    local playerData = AnticheataCore.GetPlayerData(playerId)
    if not playerData or not playerData.godModeData then
        return
    end
    
    if not testPassed then
        playerData.godModeData.testFailures = playerData.godModeData.testFailures + 1
        local reason = ("God mode test failed: health restored from %d to %d (failure #%d)"):format(
            originalHealth - 1, finalHealth, playerData.godModeData.testFailures)
        
        if playerData.godModeData.testFailures >= Config.Detection.GodMode.consecutiveFailLimit then
            AnticheataDetections.HandleGodModeDetection(playerId, reason)
            playerData.godModeData.testFailures = 0 -- Reset after action
        else
            AnticheataCore.AddWarning(playerId, "godmode", reason)
        end
    else
        -- Reset failure count on successful test
        playerData.godModeData.testFailures = math.max(0, playerData.godModeData.testFailures - 1)
    end
    
    AnticheataCore.UpdatePlayerData(playerId, {godModeData = playerData.godModeData})
end)