-- Client-side Monitoring and Additional Checks
local AnticheataMonitoring = {}

-- Additional monitoring data
local monitoringData = {
    lastHealth = 0,
    lastArmor = 0,
    godModeChecks = 0,
    speedHackChecks = 0,
    lastVehicleCheck = 0,
    suspiciousEvents = {},
    environmentChecks = {}
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
    
    -- Keep only last 8 positions (reduced from 10)
    if #noclipPatterns.rapidPositionChanges > 8 then
        table.remove(noclipPatterns.rapidPositionChanges, 1)
    end
    
    -- Analyze movement patterns with stricter detection
    if #noclipPatterns.rapidPositionChanges >= 4 then
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
            if distance > 15.0 and timeDelta < 200 then
                TriggerServerEvent('anticheat:suspiciousActivity', 'noclip_pattern', 
                    ('Instant movement detected: %.2f meters in %d ms'):format(distance, timeDelta))
            end
        end
        
        local avgSpeed = totalDistance / (totalTime / 1000.0)
        
        -- Lowered speed threshold for stricter detection
        if avgSpeed > 20.0 and not IsPedInAnyVehicle(playerPed, false) then
            noclipPatterns.abnormalMovementCount = noclipPatterns.abnormalMovementCount + 1
            
            if noclipPatterns.abnormalMovementCount >= 2 then -- Reduced threshold
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
    if insideObjectCount >= 5 then -- Reduced from 4 to be more sensitive
        noclipPatterns.consecutiveCollisionFails = noclipPatterns.consecutiveCollisionFails + 1
        
        if noclipPatterns.consecutiveCollisionFails >= 3 then -- Reduced threshold
            TriggerServerEvent('anticheat:suspiciousActivity', 'collision_bypass', 
                ('Player inside solid objects: %d/%d collision rays hit'):format(insideObjectCount, #directions))
            noclipPatterns.consecutiveCollisionFails = 0
        end
    else
        noclipPatterns.consecutiveCollisionFails = math.max(0, noclipPatterns.consecutiveCollisionFails - 1)
    end
    
    -- Additional check for underground/inside building detection
    local groundZ = GetGroundZFor_3dCoord(position.x, position.y, position.z, false)
    if position.z < groundZ - 3.0 then -- Player is significantly underground
        TriggerServerEvent('anticheat:suspiciousActivity', 'collision_bypass', 
            ('Player underground: Z=%.2f, Ground=%.2f'):format(position.z, groundZ))
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