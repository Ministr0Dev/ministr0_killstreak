-- Ministr0 Dev — Killstreak System | discord.gg/4eh8
-- © 2026 Ministr0 Dev. All rights reserved.

fx_version 'cerulean'
game 'gta5'

author 'Ministr0 Dev'
description 'Killstreak Reward System with HUD, sounds, effects, leaderboard & Discord integration'
version '2.0.0'
url 'https://discord.gg/4eh8'

shared_scripts {
    'locales/*.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

ui_page 'html/index.html'

dependencies {
    'es_extended',
    'oxmysql'
}

tags {
    'esx', 'killstreak', 'ministr0', 'reward', 'hud', 'rpg', 'fivem'
}

-- Developed by Ministr0 Dev | discord.gg/4eh8
