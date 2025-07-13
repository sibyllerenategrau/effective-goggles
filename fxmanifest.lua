fx_version 'cerulean'
game 'gta5'

name 'Effective-Goggles Anticheat'
description 'Comprehensive FiveM anticheat system with noclip detection'
author 'Effective-Goggles'
version '1.0.0'

-- Server scripts
server_scripts {
    'config.lua',
    'server/core.lua',
    'server/detections.lua',
    'server/logging.lua'
}

-- Client scripts
client_scripts {
    'config.lua',
    'client/core.lua',
    'client/monitoring.lua'
}

-- Shared scripts
shared_scripts {
    'shared/utils.lua'
}