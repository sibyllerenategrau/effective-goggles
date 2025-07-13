-- Installation and Configuration Verification Script
-- Run this to verify your anticheat installation

print("^2=== Effective-Goggles Anticheat Installation Check ===^7")

-- Check if all required files exist
local requiredFiles = {
    "fxmanifest.lua",
    "config.lua",
    "shared/utils.lua",
    "server/core.lua",
    "server/detections.lua",
    "server/logging.lua",
    "client/core.lua",
    "client/monitoring.lua"
}

local allFilesExist = true
print("^3Checking required files:^7")

for _, file in ipairs(requiredFiles) do
    local f = io.open(file, "r")
    if f then
        f:close()
        print("  ^2✓^7 " .. file)
    else
        print("  ^1✗^7 " .. file .. " (MISSING)")
        allFilesExist = false
    end
end

if allFilesExist then
    print("^2✓ All required files found^7")
else
    print("^1✗ Some files are missing. Please check your installation.^7")
    return
end

-- Check configuration
print("\n^3Checking configuration:^7")

if Config then
    print("  ^2✓^7 Config loaded")
    
    if Config.Detection and Config.Detection.Noclip and Config.Detection.Noclip.enabled then
        print("  ^2✓^7 Noclip detection enabled")
    else
        print("  ^1✗^7 Noclip detection not enabled")
    end
    
    if Config.Logging and Config.Logging.logFile then
        print("  ^2✓^7 Logging configured")
    else
        print("  ^3!^7 Logging not configured")
    end
    
    if Config.Admin and Config.Admin.notifyAdmins then
        print("  ^2✓^7 Admin notifications enabled")
    else
        print("  ^3!^7 Admin notifications disabled")
    end
    
    -- Check spawn immunity configuration (NEW)
    if Config.Detection and Config.Detection.Position and Config.Detection.Position.spawnImmunity then
        if Config.Detection.Position.spawnImmunity.enabled then
            print("  ^2✓^7 Spawn immunity enabled (" .. (Config.Detection.Position.spawnImmunity.duration/1000) .. "s duration)")
        else
            print("  ^3!^7 Spawn immunity disabled")
        end
    else
        print("  ^1✗^7 Spawn immunity not configured")
    end
else
    print("  ^1✗^7 Config not loaded")
end

-- Create logs directory
os.execute("mkdir -p logs")
print("  ^2✓^7 Logs directory created")

print("\n^2=== Installation Check Complete ===^7")
print("^3To start the anticheat, add 'start " .. GetCurrentResourceName() .. "' to your server.cfg^7")
print("^3For support, check the README.md file^7")