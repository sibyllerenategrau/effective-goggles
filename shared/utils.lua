-- Shared Utility Functions
Utils = {}

-- Get player identifier
function Utils.GetPlayerIdentifier(playerId)
    local identifiers = GetPlayerIdentifiers(playerId)
    
    -- Prefer steam ID, then license
    for _, identifier in pairs(identifiers) do
        if string.sub(identifier, 1, string.len("steam:")) == "steam:" then
            return identifier
        end
    end
    
    for _, identifier in pairs(identifiers) do
        if string.sub(identifier, 1, string.len("license:")) == "license:" then
            return identifier
        end
    end
    
    return nil
end

-- Check if player is whitelisted
function Utils.IsPlayerWhitelisted(playerId)
    if not Config.Whitelist.enabled then
        return false
    end
    
    local identifier = Utils.GetPlayerIdentifier(playerId)
    if not identifier then
        return false
    end
    
    for _, whitelistedId in pairs(Config.Whitelist.players) do
        if identifier == whitelistedId then
            return true
        end
    end
    
    return false
end

-- Calculate distance between two points
function Utils.GetDistance(pos1, pos2)
    return math.sqrt(
        (pos1.x - pos2.x)^2 + 
        (pos1.y - pos2.y)^2 + 
        (pos1.z - pos2.z)^2
    )
end

-- Check if position is in a blacklisted zone
function Utils.IsPositionInBlacklistedZone(position)
    for _, zone in pairs(Config.Detection.Position.blacklistedZones) do
        local distance = Utils.GetDistance(position, {x = zone.x, y = zone.y, z = zone.z})
        if distance <= zone.radius then
            return true, zone.name
        end
    end
    return false, nil
end

-- Format timestamp
function Utils.GetTimestamp()
    return os.date("%Y-%m-%d %H:%M:%S")
end

-- Generate detection ID
function Utils.GenerateDetectionId()
    return math.random(100000, 999999)
end