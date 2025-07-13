-- Client-side Monitoring and Additional Checks
local AnticheataMonitoring = {}

-- Additional monitoring data
local monitoringData = {
    lastHealth = 0,
    lastArmor = 0,
    godModeChecks = 0,
    speedHackChecks = 0,
    lastVehicleCheck = 0,
    lastVehicleSpeed = 0,
    suspiciousEvents = {},
    environmentChecks = {},
    spawnedVehicles = {}, -- Track vehicles spawned by player
    lastVehicleSpawnTime = 0,
    vehicleSpawnCount = 0,
    entityTracking = {}, -- Track entities around player
    lastAlphaCheck = 0,
    playerModelTracking = { -- Track player model changes
        lastModel = 0,
        modelChanges = {},
        lastModelChangeTime = 0
    }
}

-- Advanced noclip detection patterns
local noclipPatterns = {
    consecutiveCollisionFails = 0,
    rapidPositionChanges = {},
    abnormalMovementCount = 0,
    lastCollisionTime = 0
}

-- Monitor for additional cheat indicators
function AnticheataMonitoring.StartAdvancedMonitoring()
    CreateThread(function()
        while true do
            Wait(500) -- Check every 0.5 seconds instead of 1 second for better detection
            
            local playerPed = PlayerPedId()
            if DoesEntityExist(playerPed) then
                -- Check for god mode
                AnticheataMonitoring.CheckGodMode(playerPed)
                
                -- Check for speed hacks in vehicles
                AnticheataMonitoring.CheckVehicleSpeedHack(playerPed)
                
                -- Check for environment manipulation
                AnticheataMonitoring.CheckEnvironmentManipulation()
                
                -- Advanced noclip pattern detection
                AnticheataMonitoring.CheckNoclipPatterns(playerPed)
                
                -- NEW: Check for invisibility
                AnticheataMonitoring.CheckInvisibility(playerPed)
                
                -- NEW: Check for vehicle spawning
                AnticheataMonitoring.CheckVehicleSpawning(playerPed)
                
                -- NEW: Check for entity manipulation
                AnticheataMonitoring.CheckEntityManipulation(playerPed)
                
                -- NEW: Check for player model manipulation
                AnticheataMonitoring.CheckPlayerModelManipulation(playerPed)
            end
        end
    end)
end

-- Check for god mode
function AnticheataMonitoring.CheckGodMode(playerPed)
    local currentHealth = GetEntityHealth(playerPed)
    local currentArmor = GetPedArmour(playerPed)
    
    -- More frequent god mode detection
    if monitoringData.lastHealth > 0 then
        -- Check for impossible health values
        if currentHealth > 200 or currentArmor > 100 then
            TriggerServerEvent('anticheat:suspiciousActivity', 'godmode', 
                ('Impossible health/armor values: HP=%d, Armor=%d'):format(currentHealth, currentArmor))
        end
        
        -- Check for rapid regeneration
        local healthDiff = currentHealth - monitoringData.lastHealth
        local armorDiff = currentArmor - monitoringData.lastArmor
        
        if healthDiff > 50 then -- Regenerated more than 50 HP in 1 second
            TriggerServerEvent('anticheat:suspiciousActivity', 'godmode', 
                ('Rapid health regeneration: +%d HP in 1 second'):format(healthDiff))
        end
        
        if armorDiff > 25 then -- Regenerated more than 25 armor in 1 second
            TriggerServerEvent('anticheat:suspiciousActivity', 'godmode', 
                ('Rapid armor regeneration: +%d armor in 1 second'):format(armorDiff))
        end
        
        -- Enhanced damage test with higher frequency
        if math.random(1, 100) <= 15 then -- 15% chance instead of 5%
            local testHealth = currentHealth - 1
            SetEntityHealth(playerPed, testHealth)
            
            Wait(150) -- Shorter wait time
            
            local newHealth = GetEntityHealth(playerPed)
            if newHealth >= currentHealth then
                monitoringData.godModeChecks = monitoringData.godModeChecks + 1
                
                if monitoringData.godModeChecks >= 2 then -- Reduced threshold
                    TriggerServerEvent('anticheat:suspiciousActivity', 'godmode', 
                        ('God mode detected: health restored from %d to %d'):format(testHealth, newHealth))
                    monitoringData.godModeChecks = 0
                end
            else
                -- Restore health if test was legitimate
                SetEntityHealth(playerPed, currentHealth)
                monitoringData.godModeChecks = math.max(0, monitoringData.godModeChecks - 1)
            end
        end
    end
    
    monitoringData.lastHealth = currentHealth
    monitoringData.lastArmor = currentArmor
end

-- Check for vehicle speed hacks
function AnticheataMonitoring.CheckVehicleSpeedHack(playerPed)
    if IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        local speed = GetEntitySpeed(vehicle)
        local maxSpeed = GetVehicleModelMaxSpeed(GetEntityModel(vehicle))
        
        -- More strict detection: 1.2x instead of 2.0x
        if speed > maxSpeed * 1.2 then
            monitoringData.speedHackChecks = monitoringData.speedHackChecks + 1
            
            if monitoringData.speedHackChecks >= 2 then -- Reduced threshold
                TriggerServerEvent('anticheat:suspiciousActivity', 'speedhack', 
                    ('Vehicle speed hack detected: %.2f m/s (max: %.2f m/s, ratio: %.2fx)'):format(speed, maxSpeed, speed/maxSpeed))
                monitoringData.speedHackChecks = 0
            end
        else
            monitoringData.speedHackChecks = math.max(0, monitoringData.speedHackChecks - 1)
        end
        
        -- Additional check for impossible speeds
        if speed > 200.0 then -- No vehicle should go over 200 m/s
            TriggerServerEvent('anticheat:suspiciousActivity', 'speedhack', 
                ('Impossible vehicle speed: %.2f m/s'):format(speed))
        end
        
        -- Check for instant acceleration
        local currentTime = GetGameTimer()
        if monitoringData.lastVehicleCheck > 0 then
            local timeDelta = (currentTime - monitoringData.lastVehicleCheck) / 1000.0
            local lastSpeed = monitoringData.lastVehicleSpeed or 0
            local acceleration = math.abs(speed - lastSpeed) / timeDelta
            
            -- Unrealistic acceleration (0-100 km/h in less than 0.5 seconds)
            if acceleration > 55.0 and timeDelta < 0.5 then
                TriggerServerEvent('anticheat:suspiciousActivity', 'speedhack', 
                    ('Unrealistic acceleration: %.2f m/s² in %.2f seconds'):format(acceleration, timeDelta))
            end
        end
        
        monitoringData.lastVehicleCheck = currentTime
        monitoringData.lastVehicleSpeed = speed
    end
end

-- Check for environment manipulation
function AnticheataMonitoring.CheckEnvironmentManipulation()
    local playerPed = PlayerPedId()
    local position = GetEntityCoords(playerPed)
    
    -- Check time manipulation
    local gameHour = GetClockHours()
    local gameMinute = GetClockMinutes()
    
    if monitoringData.environmentChecks.lastHour then
        local timeDiff = (gameHour - monitoringData.environmentChecks.lastHour) * 60 + 
                        (gameMinute - monitoringData.environmentChecks.lastMinute)
        
        if math.abs(timeDiff) > 10 and GetGameTimer() - monitoringData.environmentChecks.lastCheck < 2000 then
            TriggerServerEvent('anticheat:suspiciousActivity', 'timehack', 
                ('Time manipulation detected: time jumped %d minutes'):format(timeDiff))
        end
    end
    
    monitoringData.environmentChecks.lastHour = gameHour
    monitoringData.environmentChecks.lastMinute = gameMinute
    monitoringData.environmentChecks.lastCheck = GetGameTimer()
    
    -- Check weather manipulation
    local weather = GetPrevWeatherTypeHashName()
    if monitoringData.environmentChecks.lastWeather and 
       weather ~= monitoringData.environmentChecks.lastWeather and
       GetGameTimer() - monitoringData.environmentChecks.lastWeatherChange < 5000 then
        TriggerServerEvent('anticheat:suspiciousActivity', 'weatherhack', 'Rapid weather changes detected')
    end
    
    monitoringData.environmentChecks.lastWeather = weather
    monitoringData.environmentChecks.lastWeatherChange = GetGameTimer()
end

-- Advanced noclip pattern detection
function AnticheataMonitoring.CheckNoclipPatterns(playerPed)
    local position = GetEntityCoords(playerPed)
    local currentTime = GetGameTimer()
    
    -- Check for rapid position changes
    table.insert(noclipPatterns.rapidPositionChanges, {pos = position, time = currentTime})
    
    -- Keep only last 6 positions (reduced from 8)
    if #noclipPatterns.rapidPositionChanges > 6 then
        table.remove(noclipPatterns.rapidPositionChanges, 1)
    end
    
    -- Analyze movement patterns with stricter detection
    if #noclipPatterns.rapidPositionChanges >= 3 then -- Reduced from 4
        local totalDistance = 0
        local totalTime = 0
        local maxInstantDistance = 0
        
        for i = 2, #noclipPatterns.rapidPositionChanges do
            local prev = noclipPatterns.rapidPositionChanges[i-1]
            local curr = noclipPatterns.rapidPositionChanges[i]
            
            local distance = #(vector3(curr.pos.x, curr.pos.y, curr.pos.z) - vector3(prev.pos.x, prev.pos.y, prev.pos.z))
            local timeDelta = curr.time - prev.time
            
            totalDistance = totalDistance + distance
            totalTime = totalTime + timeDelta
            
            -- Track maximum instant distance
            if distance > maxInstantDistance then
                maxInstantDistance = distance
            end
            
            -- Check for instant teleportation (reduced threshold)
            if distance > 12.0 and timeDelta < 200 then -- Reduced from 15.0 meters
                TriggerServerEvent('anticheat:suspiciousActivity', 'noclip_pattern', 
                    ('Instant movement detected: %.2f meters in %d ms'):format(distance, timeDelta))
            end
        end
        
        local avgSpeed = totalDistance / (totalTime / 1000.0)
        
        -- Lowered speed threshold for stricter detection
        if avgSpeed > 15.0 and not IsPedInAnyVehicle(playerPed, false) then -- Reduced from 20.0
            noclipPatterns.abnormalMovementCount = noclipPatterns.abnormalMovementCount + 1
            
            if noclipPatterns.abnormalMovementCount >= 1 then -- Reduced from 2 threshold
                TriggerServerEvent('anticheat:suspiciousActivity', 'noclip_pattern', 
                    ('Noclip movement pattern: avg speed %.2f m/s, max instant: %.2f m'):format(avgSpeed, maxInstantDistance))
                noclipPatterns.abnormalMovementCount = 0
            end
        else
            noclipPatterns.abnormalMovementCount = math.max(0, noclipPatterns.abnormalMovementCount - 1)
        end
    end
    
    -- Enhanced collision detection bypass
    AnticheataMonitoring.CheckCollisionBypass(playerPed, position)
end

-- Enhanced collision bypass detection
function AnticheataMonitoring.CheckCollisionBypass(playerPed, position)
    if IsPedInAnyVehicle(playerPed, false) then
        return
    end
    
    -- Cast multiple rays around player to detect if inside objects
    local directions = {
        {x = 1, y = 0, z = 0},   -- East
        {x = -1, y = 0, z = 0},  -- West
        {x = 0, y = 1, z = 0},   -- North
        {x = 0, y = -1, z = 0},  -- South
        {x = 0, y = 0, z = 1},   -- Up
        {x = 0, y = 0, z = -1},  -- Down
        {x = 1, y = 1, z = 0},   -- Northeast
        {x = -1, y = -1, z = 0}  -- Southwest
    }
    
    local insideObjectCount = 0
    local rayDistance = 0.8 -- Increased detection radius
    
    for _, direction in pairs(directions) do
        local startPos = vector3(position.x, position.y, position.z)
        local endPos = vector3(
            position.x + direction.x * rayDistance,
            position.y + direction.y * rayDistance,
            position.z + direction.z * rayDistance
        )
        
        local raycast = StartShapeTestRay(
            startPos.x, startPos.y, startPos.z,
            endPos.x, endPos.y, endPos.z,
            1, playerPed, 0
        )
        
        local _, hit, _, _, _ = GetShapeTestResult(raycast)
        
        if hit == 1 then
            insideObjectCount = insideObjectCount + 1
        end
    end
    
    -- More sensitive detection: if player is surrounded by objects
    if insideObjectCount >= 4 then -- Reduced from 5 to be more sensitive
        noclipPatterns.consecutiveCollisionFails = noclipPatterns.consecutiveCollisionFails + 1
        
        if noclipPatterns.consecutiveCollisionFails >= 2 then -- Reduced from 3 threshold
            TriggerServerEvent('anticheat:suspiciousActivity', 'collision_bypass', 
                ('Player inside solid objects: %d/%d collision rays hit'):format(insideObjectCount, #directions))
            noclipPatterns.consecutiveCollisionFails = 0
        end
    else
        noclipPatterns.consecutiveCollisionFails = math.max(0, noclipPatterns.consecutiveCollisionFails - 1)
    end
    
    -- Additional check for underground/inside building detection
    local found, groundZ = GetGroundZFor_3dCoord(position.x, position.y, position.z, false)
    if found and position.z < groundZ - 3.0 then -- Player is significantly underground
        TriggerServerEvent('anticheat:suspiciousActivity', 'collision_bypass', 
            ('Player underground: Z=%.2f, Ground=%.2f'):format(position.z, groundZ))
    end
end

-- NEW: Check for invisibility/alpha manipulation
function AnticheataMonitoring.CheckInvisibility(playerPed)
    local currentTime = GetGameTimer()
    
    -- Check every 1.5 seconds
    if currentTime - monitoringData.lastAlphaCheck < 1500 then
        return
    end
    
    monitoringData.lastAlphaCheck = currentTime
    
    -- Get player alpha (transparency)
    local alpha = GetEntityAlpha(playerPed)
    
    -- Check if player is too transparent (invisible)
    if alpha < Config.Detection.Invisibility.minAlphaThreshold then
        TriggerServerEvent('anticheat:suspiciousActivity', 'invisibility', 
            ('Player invisibility detected: alpha value %d (min: %d)'):format(alpha, Config.Detection.Invisibility.minAlphaThreshold))
    end
    
    -- Check if entity is set to not be visible
    if not IsEntityVisible(playerPed) then
        TriggerServerEvent('anticheat:suspiciousActivity', 'invisibility', 'Player entity set to invisible')
    end
    
    -- Check for collision disabled (often used with invisibility)
    if not DoesEntityHaveCollision(playerPed) then
        TriggerServerEvent('anticheat:suspiciousActivity', 'invisibility', 'Player collision disabled')
    end
end

-- NEW: Check for vehicle spawning near player
function AnticheataMonitoring.CheckVehicleSpawning(playerPed)
    local position = GetEntityCoords(playerPed)
    local currentTime = GetGameTimer()
    
    -- Get all vehicles in area
    local vehicles = {}
    local vehicleHandle, vehicle = FindFirstVehicle()
    local success
    
    repeat
        local vehiclePos = GetEntityCoords(vehicle)
        local distance = #(vector3(position.x, position.y, position.z) - vector3(vehiclePos.x, vehiclePos.y, vehiclePos.z))
        
        if distance <= Config.Detection.VehicleSpawning.detectionRadius then
            table.insert(vehicles, vehicle)
        end
        
        success, vehicle = FindNextVehicle(vehicleHandle)
    until not success
    
    EndFindVehicle(vehicleHandle)
    
    -- Check for new vehicles that weren't there before
    for _, vehicle in pairs(vehicles) do
        local found = false
        for _, trackedVehicle in pairs(monitoringData.spawnedVehicles) do
            if vehicle == trackedVehicle.entity then
                found = true
                break
            end
        end
        
        if not found then
            -- Check if vehicle was recently created
            local vehicleAge = GetGameTimer() - GetEntityHandle(vehicle)
            if vehicleAge < 5000 then -- Vehicle created within last 5 seconds
                -- Check if player is the driver or very close to the vehicle
                local vehiclePos = GetEntityCoords(vehicle)
                local distance = #(vector3(position.x, position.y, position.z) - vector3(vehiclePos.x, vehiclePos.y, vehiclePos.z))
                
                if distance < 10.0 or GetPedInVehicleSeat(vehicle, -1) == playerPed then
                    -- Track this vehicle spawn
                    table.insert(monitoringData.spawnedVehicles, {
                        entity = vehicle,
                        spawnTime = currentTime,
                        distance = distance
                    })
                    
                    monitoringData.vehicleSpawnCount = monitoringData.vehicleSpawnCount + 1
                    
                    -- Check spawn rate (per minute)
                    local oneMinuteAgo = currentTime - 60000
                    local recentSpawns = 0
                    for _, spawnedVehicle in pairs(monitoringData.spawnedVehicles) do
                        if spawnedVehicle.spawnTime > oneMinuteAgo then
                            recentSpawns = recentSpawns + 1
                        end
                    end
                    
                    if recentSpawns > Config.Detection.VehicleSpawning.spawnRateLimit then
                        TriggerServerEvent('anticheat:suspiciousActivity', 'vehicle_spawning', 
                            ('Excessive vehicle spawning: %d vehicles in 1 minute (limit: %d)'):format(recentSpawns, Config.Detection.VehicleSpawning.spawnRateLimit))
                    end
                    
                    -- Check total vehicles around player
                    if #vehicles > Config.Detection.VehicleSpawning.maxVehiclesPerPlayer then
                        TriggerServerEvent('anticheat:suspiciousActivity', 'vehicle_spawning', 
                            ('Too many vehicles around player: %d (max: %d)'):format(#vehicles, Config.Detection.VehicleSpawning.maxVehiclesPerPlayer))
                    end
                end
            end
        end
    end
    
    -- Clean up old tracked vehicles (older than 5 minutes)
    local fiveMinutesAgo = currentTime - 300000
    for i = #monitoringData.spawnedVehicles, 1, -1 do
        if monitoringData.spawnedVehicles[i].spawnTime < fiveMinutesAgo then
            table.remove(monitoringData.spawnedVehicles, i)
        end
    end
end

-- NEW: Check for entity manipulation (spawning objects, props, etc.)
function AnticheataMonitoring.CheckEntityManipulation(playerPed)
    local position = GetEntityCoords(playerPed)
    local currentTime = GetGameTimer()
    
    -- Get all objects/props in area
    local objects = {}
    local objectHandle, object = FindFirstObject()
    local success
    
    repeat
        local objectPos = GetEntityCoords(object)
        local distance = #(vector3(position.x, position.y, position.z) - vector3(objectPos.x, objectPos.y, objectPos.z))
        
        if distance <= Config.Detection.EntityManipulation.detectionRadius then
            table.insert(objects, object)
        end
        
        success, object = FindNextObject(objectHandle)
    until not success
    
    EndFindObject(objectHandle)
    
    -- Check for excessive entities around player
    if #objects > Config.Detection.EntityManipulation.maxEntitiesPerPlayer then
        TriggerServerEvent('anticheat:suspiciousActivity', 'entity_manipulation', 
            ('Excessive entities around player: %d (max: %d)'):format(#objects, Config.Detection.EntityManipulation.maxEntitiesPerPlayer))
    end
    
    -- Track new entities
    for _, object in pairs(objects) do
        local found = false
        for _, trackedEntity in pairs(monitoringData.entityTracking) do
            if object == trackedEntity.entity then
                found = true
                break
            end
        end
        
        if not found then
            -- Check if entity was recently created
            local entityAge = GetGameTimer() - GetEntityHandle(object)
            if entityAge < 3000 then -- Entity created within last 3 seconds
                table.insert(monitoringData.entityTracking, {
                    entity = object,
                    spawnTime = currentTime
                })
                
                -- Check for rapid entity spawning
                local thirtySecondsAgo = currentTime - 30000
                local recentSpawns = 0
                for _, trackedEntity in pairs(monitoringData.entityTracking) do
                    if trackedEntity.spawnTime > thirtySecondsAgo then
                        recentSpawns = recentSpawns + 1
                    end
                end
                
                if recentSpawns > 3 then -- More than 3 entities in 30 seconds
                    TriggerServerEvent('anticheat:suspiciousActivity', 'entity_manipulation', 
                        ('Rapid entity spawning: %d entities in 30 seconds'):format(recentSpawns))
                end
            end
        end
    end
    
    -- Clean up old tracked entities (older than 2 minutes)
    local twoMinutesAgo = currentTime - 120000
    for i = #monitoringData.entityTracking, 1, -1 do
        if monitoringData.entityTracking[i].spawnTime < twoMinutesAgo then
            table.remove(monitoringData.entityTracking, i)
        end
    end
end

-- Monitor for menu injection attempts
function AnticheataMonitoring.MonitorMenuInjection()
    CreateThread(function()
        while true do
            Wait(5000) -- Check every 5 seconds
            
            -- Check for suspicious UI elements that might indicate menus
            if IsControlPressed(0, 86) then -- VK_NUMPAD5 commonly used by menus
                TriggerServerEvent('anticheat:suspiciousActivity', 'menu_injection', 'Suspicious control input detected')
            end
            
            -- Check for rapid key combinations
            local suspiciousControls = {
                {288, 289, 170}, -- F1, F2, F3
                {311, 312, 313}, -- F12, Insert, Delete
            }
            
            for _, controls in pairs(suspiciousControls) do
                local allPressed = true
                for _, control in pairs(controls) do
                    if not IsControlPressed(0, control) then
                        allPressed = false
                        break
                    end
                end
                
                if allPressed then
                    TriggerServerEvent('anticheat:suspiciousActivity', 'menu_injection', 'Suspicious key combination detected')
                end
            end
        end
    end)
end

-- Handle server suspicious activity reports
RegisterServerEvent('anticheat:suspiciousActivity')

-- Start all monitoring when resource loads
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        Wait(2000) -- Wait for core to initialize
        
        AnticheataMonitoring.StartAdvancedMonitoring()
        AnticheataMonitoring.MonitorMenuInjection()
        
        if Config.EnableDebug then
            print(("[%s] Advanced monitoring started"):format(Config.ResourceName))
        end
    end
end)

-- Export monitoring functions
_G.AnticheataMonitoring = AnticheataMonitoring

-- NEW: Check for player model manipulation
function AnticheataMonitoring.CheckPlayerModelManipulation(playerPed)
    if not Config.Detection.PlayerModel.enabled then
        return
    end
    
    local currentTime = GetGameTimer()
    local currentModel = GetEntityModel(playerPed)
    
    -- Initialize tracking if not exists
    if monitoringData.playerModelTracking.lastModel == 0 then
        monitoringData.playerModelTracking.lastModel = currentModel
        return
    end
    
    -- Check if model changed
    if currentModel ~= monitoringData.playerModelTracking.lastModel then
        table.insert(monitoringData.playerModelTracking.modelChanges, {
            fromModel = monitoringData.playerModelTracking.lastModel,
            toModel = currentModel,
            changeTime = currentTime
        })
        
        monitoringData.playerModelTracking.lastModel = currentModel
        monitoringData.playerModelTracking.lastModelChangeTime = currentTime
        
        -- Check for allowed models (if configured)
        if #Config.Detection.PlayerModel.allowedModels > 0 then
            local modelAllowed = false
            for _, allowedModel in pairs(Config.Detection.PlayerModel.allowedModels) do
                if currentModel == allowedModel then
                    modelAllowed = true
                    break
                end
            end
            
            if not modelAllowed then
                TriggerServerEvent('anticheat:suspiciousActivity', 'player_model', 
                    ('Unauthorized player model: %d'):format(currentModel))
                return
            end
        end
        
        -- Check for rapid model switching
        if Config.Detection.PlayerModel.detectModelChanges then
            local oneMinuteAgo = currentTime - 60000
            local recentChanges = 0
            
            for _, change in pairs(monitoringData.playerModelTracking.modelChanges) do
                if change.changeTime > oneMinuteAgo then
                    recentChanges = recentChanges + 1
                end
            end
            
            if recentChanges > Config.Detection.PlayerModel.maxModelChangesPerMinute then
                TriggerServerEvent('anticheat:suspiciousActivity', 'player_model', 
                    ('Rapid model switching: %d changes in 1 minute (max: %d)'):format(recentChanges, Config.Detection.PlayerModel.maxModelChangesPerMinute))
            end
        end
        
        -- Clean up old model changes (older than 5 minutes)
        local fiveMinutesAgo = currentTime - 300000
        for i = #monitoringData.playerModelTracking.modelChanges, 1, -1 do
            if monitoringData.playerModelTracking.modelChanges[i].changeTime < fiveMinutesAgo then
                table.remove(monitoringData.playerModelTracking.modelChanges, i)
            end
        end
    end
end