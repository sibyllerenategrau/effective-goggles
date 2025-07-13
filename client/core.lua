-- Client Core Anticheat System
local isMonitoring = false
local lastPosition = vector3(0, 0, 0)
local lastUpdate = 0

-- Initialize client anticheat
function InitializeClientAnticheat()
    local playerPed = PlayerPedId()
    lastPosition = GetEntityCoords(playerPed)
    lastUpdate = GetGameTimer()
    isMonitoring = true
    
    if Config.EnableDebug then
        print(("[%s] Client anticheat initialized"):format(Config.ResourceName))
    end
    
    -- Notify server that player is loaded
    TriggerServerEvent('anticheat:playerLoaded')
    
    -- Start monitoring
    StartPositionMonitoring()
end

-- Start position monitoring
function StartPositionMonitoring()
    CreateThread(function()
        while isMonitoring do
            Wait(Config.Detection.Noclip.checkInterval)
            
            local playerPed = PlayerPedId()
            if DoesEntityExist(playerPed) then
                local position = GetEntityCoords(playerPed)
                local velocity = GetEntityVelocity(playerPed)
                local speed = GetEntitySpeed(playerPed)
                local inVehicle = IsPedInAnyVehicle(playerPed, false)
                local onGround = IsEntityOnGround(playerPed)
                local health = GetEntityHealth(playerPed)
                local armor = GetPedArmour(playerPed)
                
                -- Get vehicle data if in vehicle
                local vehicleData = nil
                if inVehicle then
                    local vehicle = GetVehiclePedIsIn(playerPed, false)
                    vehicleData = {
                        entity = vehicle,
                        maxSpeed = GetVehicleModelMaxSpeed(GetEntityModel(vehicle)),
                        model = GetEntityModel(vehicle)
                    }
                end
                
                -- Send enhanced position update to server
                TriggerServerEvent('anticheat:updatePosition', position, velocity, inVehicle, onGround, speed, health, armor, vehicleData)
                
                lastPosition = position
                lastUpdate = GetGameTimer()
            end
        end
    end)
end

-- Handle server requests for position updates
RegisterNetEvent('anticheat:requestUpdate')
AddEventHandler('anticheat:requestUpdate', function()
    local playerPed = PlayerPedId()
    if DoesEntityExist(playerPed) then
        local position = GetEntityCoords(playerPed)
        local velocity = GetEntityVelocity(playerPed)
        local speed = GetEntitySpeed(playerPed)
        local inVehicle = IsPedInAnyVehicle(playerPed, false)
        local onGround = IsEntityOnGround(playerPed)
        local health = GetEntityHealth(playerPed)
        local armor = GetPedArmour(playerPed)
        
        -- Get vehicle data if in vehicle
        local vehicleData = nil
        if inVehicle then
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            vehicleData = {
                entity = vehicle,
                maxSpeed = GetVehicleModelMaxSpeed(GetEntityModel(vehicle)),
                model = GetEntityModel(vehicle)
            }
        end
        
        TriggerServerEvent('anticheat:updatePosition', position, velocity, inVehicle, onGround, speed, health, armor, vehicleData)
    end
end)

-- Handle collision checks
RegisterNetEvent('anticheat:checkCollision')
AddEventHandler('anticheat:checkCollision', function(position, stepId)
    -- Perform raycast to check for collision
    local hasCollision = false
    
    -- Cast ray from above the position down to check for ground/objects
    local raycast = StartShapeTestRay(
        position.x, position.y, position.z + 1.0,
        position.x, position.y, position.z - 1.0,
        -1, PlayerPedId(), 0
    )
    
    local _, hit, _, _, _ = GetShapeTestResult(raycast)
    hasCollision = hit == 1
    
    -- Also check for props and buildings
    if not hasCollision then
        local raycast2 = StartShapeTestRay(
            position.x, position.y, position.z,
            position.x, position.y, position.z,
            1, PlayerPedId(), 0
        )
        local _, hit2, _, _, _ = GetShapeTestResult(raycast2)
        hasCollision = hit2 == 1
    end
    
    TriggerServerEvent('anticheat:collisionResult', position, hasCollision, stepId)
end)

-- Handle teleportation to position
RegisterNetEvent('anticheat:teleportToPosition')
AddEventHandler('anticheat:teleportToPosition', function(position)
    local playerPed = PlayerPedId()
    
    -- Ensure the position is safe
    RequestCollisionAtCoord(position.x, position.y, position.z)
    
    -- Wait for collision to load
    local timeout = 0
    while not HasCollisionLoadedAroundEntity(playerPed) and timeout < 1000 do
        Wait(10)
        timeout = timeout + 10
    end
    
    -- Teleport player
    SetEntityCoords(playerPed, position.x, position.y, position.z, false, false, false, true)
    
    -- Freeze player briefly to prevent immediate movement
    FreezeEntityPosition(playerPed, true)
    Wait(500)
    FreezeEntityPosition(playerPed, false)
    
    if Config.EnableDebug then
        print(("Teleported to safe position: %.2f, %.2f, %.2f"):format(position.x, position.y, position.z))
    end
end)

-- Handle teleportation to safe location
RegisterNetEvent('anticheat:teleportToSafeLocation')
AddEventHandler('anticheat:teleportToSafeLocation', function()
    local safeLocations = {
        {x = -1037.7, y = -2737.8, z = 20.2}, -- Airport
        {x = 215.9, y = -810.1, z = 30.7},    -- City center
        {x = -275.0, y = 6635.0, z = 7.5},    -- Paleto Bay
        {x = 1698.4, y = 4924.0, z = 42.1},   -- Grapeseed
        {x = -3244.5, y = 1008.6, z = 12.8}   -- Military base area
    }
    
    -- Choose random safe location
    local safePos = safeLocations[math.random(#safeLocations)]
    
    local playerPed = PlayerPedId()
    RequestCollisionAtCoord(safePos.x, safePos.y, safePos.z)
    
    local timeout = 0
    while not HasCollisionLoadedAroundEntity(playerPed) and timeout < 1000 do
        Wait(10)
        timeout = timeout + 10
    end
    
    SetEntityCoords(playerPed, safePos.x, safePos.y, safePos.z, false, false, false, true)
    
    FreezeEntityPosition(playerPed, true)
    Wait(500)
    FreezeEntityPosition(playerPed, false)
    
    -- Notify player
    ShowNotification("~r~Anticheat: ~w~You have been moved to a safe location")
end)

-- Show notification
function ShowNotification(message)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(message)
    DrawNotification(false, false)
end

-- Handle god mode testing
RegisterNetEvent('anticheat:performGodModeTest')
AddEventHandler('anticheat:performGodModeTest', function()
    local playerPed = PlayerPedId()
    if DoesEntityExist(playerPed) then
        local originalHealth = GetEntityHealth(playerPed)
        
        -- Temporarily reduce health by 1
        SetEntityHealth(playerPed, originalHealth - 1)
        
        Wait(200) -- Wait 200ms
        
        local newHealth = GetEntityHealth(playerPed)
        
        -- Check if health was restored (indicating possible god mode)
        if newHealth >= originalHealth then
            TriggerServerEvent('anticheat:godModeTestResult', false, newHealth, originalHealth)
        else
            -- Restore original health if test was legitimate
            SetEntityHealth(playerPed, originalHealth)
            TriggerServerEvent('anticheat:godModeTestResult', true, newHealth, originalHealth)
        end
    end
end)

-- Initialize when resource starts
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- Wait a bit for everything to load
        Wait(1000)
        InitializeClientAnticheat()
    end
end)

-- Cleanup when resource stops
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        isMonitoring = false
    end
end)