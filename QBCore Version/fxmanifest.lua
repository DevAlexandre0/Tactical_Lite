fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'GESUS'
description 'Standalone Tactical Lean & Quick Throw'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

files {
    'stream/**'
}

dependencies {
    'ox_lib',
    'qb-core',
    'qb-inventory'
}
