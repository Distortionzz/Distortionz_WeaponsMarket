fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Distortionz'
description 'Distortionz Weapons Market — roaming black market dealer with tiered weapon unlocks via reputation, mixed cash/dirty money payments, glassy NUI shop, and configurable police alerts.'
version '1.0.7'
repository 'https://github.com/Distortionzz/Distortionz_WeaponsMarket'

ui_page 'html/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua',
    'version_check.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_target',
    'ox_inventory'
}
