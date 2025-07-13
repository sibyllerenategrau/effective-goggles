-- Anticheat Logging System
local AnticheataLogging = {}

-- Initialize logging
function AnticheataLogging.Initialize()
    if Config.Logging.logFile then
        -- Create logs directory if it doesn't exist
        os.execute("mkdir -p logs")
        
        -- Log startup
        AnticheataLogging.WriteToFile("=== ANTICHEAT SYSTEM STARTED ===")
        print(("[%s] Anticheat logging system initialized"):format(Config.ResourceName))
    end
end

-- Write to log file
function AnticheataLogging.WriteToFile(message)
    if not Config.Logging.logFile then
        return
    end
    
    local timestamp = Utils.GetTimestamp()
    local logMessage = ("[%s] %s\n"):format(timestamp, message)
    
    local file = io.open(Config.Logging.logFile, "a")
    if file then
        file:write(logMessage)
        file:close()
        
        -- Check file size and rotate if necessary
        AnticheataLogging.CheckLogRotation()
    else
        print(("Failed to write to log file: %s"):format(Config.Logging.logFile))
    end
end

-- Check and rotate log file if too large
function AnticheataLogging.CheckLogRotation()
    local file = io.open(Config.Logging.logFile, "r")
    if not file then
        return
    end
    
    local size = file:seek("end")
    file:close()
    
    if size > Config.Logging.maxLogSize then
        -- Rotate log file
        local timestamp = os.date("%Y%m%d_%H%M%S")
        local backupName = Config.Logging.logFile .. "." .. timestamp
        os.rename(Config.Logging.logFile, backupName)
        
        -- Start new log file
        AnticheataLogging.WriteToFile("=== NEW LOG FILE STARTED (Previous rotated to " .. backupName .. ") ===")
    end
end

-- Log detection event
function AnticheataLogging.LogDetection(playerId, detectionType, reason, action, warningCount)
    if not Config.Logging.logDetections then
        return
    end
    
    local playerName = GetPlayerName(playerId)
    local identifier = Utils.GetPlayerIdentifier(playerId)
    local detectionId = Utils.GenerateDetectionId()
    
    local logMessage = ("DETECTION [%d] | Player: %s (%s) | Type: %s | Reason: %s | Action: %s | Warnings: %d"):format(
        detectionId, playerName, identifier or "unknown", detectionType, reason, action, warningCount
    )
    
    -- Log to file
    if Config.LogToFile then
        AnticheataLogging.WriteToFile(logMessage)
    end
    
    -- Log to console
    if Config.LogToConsole then
        print(("[%s] %s"):format(Config.ResourceName, logMessage))
    end
    
    -- Send to Discord webhook if configured
    if Config.Admin.notifyDiscord and Config.Admin.discordWebhook ~= "" then
        AnticheataLogging.SendToDiscord(detectionId, playerName, identifier, detectionType, reason, action, warningCount)
    end
end

-- Log warning
function AnticheataLogging.LogWarning(playerId, message)
    if not Config.Logging.logWarnings then
        return
    end
    
    local playerName = GetPlayerName(playerId)
    local identifier = Utils.GetPlayerIdentifier(playerId)
    
    local logMessage = ("WARNING | Player: %s (%s) | Message: %s"):format(
        playerName, identifier or "unknown", message
    )
    
    if Config.LogToFile then
        AnticheataLogging.WriteToFile(logMessage)
    end
    
    if Config.LogToConsole then
        print(("[%s] %s"):format(Config.ResourceName, logMessage))
    end
end

-- Log punishment
function AnticheataLogging.LogPunishment(playerId, punishmentType, reason)
    if not Config.Logging.logPunishments then
        return
    end
    
    local playerName = GetPlayerName(playerId)
    local identifier = Utils.GetPlayerIdentifier(playerId)
    
    local logMessage = ("PUNISHMENT | Player: %s (%s) | Type: %s | Reason: %s"):format(
        playerName, identifier or "unknown", punishmentType, reason
    )
    
    if Config.LogToFile then
        AnticheataLogging.WriteToFile(logMessage)
    end
    
    if Config.LogToConsole then
        print(("[%s] %s"):format(Config.ResourceName, logMessage))
    end
end

-- Send notification to Discord
function AnticheataLogging.SendToDiscord(detectionId, playerName, identifier, detectionType, reason, action, warningCount)
    local embed = {
        {
            ["color"] = action == "kick" and 16711680 or action == "ban" and 8388608 or 16776960, -- Red for kick, dark red for ban, yellow for warning
            ["title"] = "🚨 Anticheat Detection",
            ["description"] = "A player has been detected by the anticheat system",
            ["fields"] = {
                {
                    ["name"] = "Detection ID",
                    ["value"] = tostring(detectionId),
                    ["inline"] = true
                },
                {
                    ["name"] = "Player",
                    ["value"] = playerName,
                    ["inline"] = true
                },
                {
                    ["name"] = "Identifier",
                    ["value"] = identifier or "Unknown",
                    ["inline"] = true
                },
                {
                    ["name"] = "Detection Type",
                    ["value"] = detectionType,
                    ["inline"] = true
                },
                {
                    ["name"] = "Action Taken",
                    ["value"] = action,
                    ["inline"] = true
                },
                {
                    ["name"] = "Warning Count",
                    ["value"] = tostring(warningCount),
                    ["inline"] = true
                },
                {
                    ["name"] = "Reason",
                    ["value"] = reason,
                    ["inline"] = false
                }
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            ["footer"] = {
                ["text"] = "Effective-Goggles Anticheat"
            }
        }
    }
    
    PerformHttpRequest(Config.Admin.discordWebhook, function(err, text, headers) 
        if err ~= 200 then
            print(("Failed to send Discord notification: %d"):format(err))
        end
    end, 'POST', json.encode({username = "Anticheat", embeds = embed}), {['Content-Type'] = 'application/json'})
end

-- Log system events
function AnticheataLogging.LogSystemEvent(event, message)
    local logMessage = ("SYSTEM | Event: %s | Message: %s"):format(event, message)
    
    if Config.LogToFile then
        AnticheataLogging.WriteToFile(logMessage)
    end
    
    if Config.LogToConsole and Config.EnableDebug then
        print(("[%s] %s"):format(Config.ResourceName, logMessage))
    end
end

-- Initialize logging when resource starts
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        AnticheataLogging.Initialize()
        AnticheataLogging.LogSystemEvent("START", "Anticheat system started")
    end
end)

-- Log when resource stops
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        AnticheataLogging.LogSystemEvent("STOP", "Anticheat system stopped")
    end
end)

-- Export functions
_G.AnticheataLogging = AnticheataLogging