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
            Wait(1000) -- Check every second
            
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
    
    -- Check if player took damage but health didn't decrease
    if monitoringData.lastHealth > 0 and currentHealth >= monitoringData.lastHealth then
        -- Simulate damage to test god mode
        if math.random(1, 100) <= 5 then -- 5% chance to test
            local testHealth = currentHealth - 1
            SetEntityHealth(playerPed, testHealth)
            
            Wait(100)
            
            local newHealth = GetEntityHealth(playerPed)
            if newHealth > testHealth then
                monitoringData.godModeChecks = monitoringData.godModeChecks + 1
                
                if monitoringData.godModeChecks >= 3 then
                    TriggerServerEvent('anticheat:suspiciousActivity', 'godmode', 'God mode detected through health manipulation test')
                    monitoringData.godModeChecks = 0
                end
            else
                -- Restore health if test was legitimate
                SetEntityHealth(playerPed, currentHealth)
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
        
        -- Check if speed exceeds realistic limits
        if speed > maxSpeed * 2.0 then -- Double the max speed
            monitoringData.speedHackChecks = monitoringData.speedHackChecks + 1
            
            if monitoringData.speedHackChecks >= 3 then
                TriggerServerEvent('anticheat:suspiciousActivity', 'speedhack', 
                    ('Vehicle speed hack detected: %.2f m/s (max: %.2f m/s)'):format(speed, maxSpeed))
                monitoringData.speedHackChecks = 0
            end
        else
            monitoringData.speedHackChecks = math.max(0, monitoringData.speedHackChecks - 1)
        end
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
    
    -- Keep only last 10 positions
    if #noclipPatterns.rapidPositionChanges > 10 then
        table.remove(noclipPatterns.rapidPositionChanges, 1)
    end
    
    -- Analyze movement patterns
    if #noclipPatterns.rapidPositionChanges >= 5 then
        local totalDistance = 0
        local totalTime = 0
        
        for i = 2, #noclipPatterns.rapidPositionChanges do
            local prev = noclipPatterns.rapidPositionChanges[i-1]
            local curr = noclipPatterns.rapidPositionChanges[i]
            
            local distance = #(vector3(curr.pos.x, curr.pos.y, curr.pos.z) - vector3(prev.pos.x, prev.pos.y, prev.pos.z))
            local timeDelta = curr.time - prev.time
            
            totalDistance = totalDistance + distance
            totalTime = totalTime + timeDelta
        end
        
        local avgSpeed = totalDistance / (totalTime / 1000.0)
        
        if avgSpeed > 30.0 and not IsPedInAnyVehicle(playerPed, false) then
            noclipPatterns.abnormalMovementCount = noclipPatterns.abnormalMovementCount + 1
            
            if noclipPatterns.abnormalMovementCount >= 3 then
                TriggerServerEvent('anticheat:suspiciousActivity', 'noclip_pattern', 
                    ('Noclip movement pattern detected: avg speed %.2f m/s'):format(avgSpeed))
                noclipPatterns.abnormalMovementCount = 0
            end
        end
    end
    
    -- Check collision detection bypass
    AnticheataMonitoring.CheckCollisionBypass(playerPed, position)
end

-- Enhanced collision bypass detection
function AnticheataMonitoring.CheckCollisionBypass(playerPed, position)
    if IsPedInAnyVehicle(playerPed, false) then
        return
    end
    
    -- Cast multiple rays around player to detect if inside objects
    local directions = {
        {x = 1, y = 0, z = 0},
        {x = -1, y = 0, z = 0},
        {x = 0, y = 1, z = 0},
        {x = 0, y = -1, z = 0},
        {x = 0, y = 0, z = 1},
        {x = 0, y = 0, z = -1}
    }
    
    local insideObjectCount = 0
    
    for _, direction in pairs(directions) do
        local startPos = vector3(position.x, position.y, position.z)
        local endPos = vector3(
            position.x + direction.x * 0.5,
            position.y + direction.y * 0.5,
            position.z + direction.z * 0.5
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
    
    -- If player is surrounded by objects, they might be noclipping
    if insideObjectCount >= 4 then
        noclipPatterns.consecutiveCollisionFails = noclipPatterns.consecutiveCollisionFails + 1
        
        if noclipPatterns.consecutiveCollisionFails >= 5 then
            TriggerServerEvent('anticheat:suspiciousActivity', 'collision_bypass', 
                ('Player inside solid objects: %d/6 collision rays hit'):format(insideObjectCount))
            noclipPatterns.consecutiveCollisionFails = 0
        end
    else
        noclipPatterns.consecutiveCollisionFails = math.max(0, noclipPatterns.consecutiveCollisionFails - 1)
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