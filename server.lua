-- Ministr0 Dev — Killstreak System (Server) | discord.gg/4eh8
-- © 2026 Ministr0 Dev. All rights reserved.

local ESX = nil
local playerKillstreaks = {}
local playerBestStreaks = {}
local playerLastKillTime = {}
local playerKillTimestamps = {}
local leaderboardCache = {}
local leaderboardCacheTime = 0

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local function Log(msg, level)
    level = level or 'info'
    if not Config.Misc.enable_console_logging then return end
    local p = Config.Misc.console_prefix or '[Ministr0 Dev]'
    if level == 'error' then
        print('^1' .. p .. ' [ERROR] ' .. msg .. '^0')
    elseif level == 'warn' then
        print('^3' .. p .. ' [WARN] ' .. msg .. '^0')
    elseif level == 'success' then
        print('^2' .. p .. ' [SUCCESS] ' .. msg .. '^0')
    else
        print('^5' .. p .. ' [INFO] ' .. msg .. '^0')
    end
end

local function EnsureTable()
    if not Config.Database.enabled then return end
    local t = Config.Database.table_name
    MySQL.ready(function()
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS `]] .. t .. [[` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `identifier` VARCHAR(60) NOT NULL UNIQUE,
                `name` VARCHAR(100) DEFAULT 'Unknown',
                `best_streak` INT DEFAULT 0,
                `total_kills` INT DEFAULT 0,
                `streaks_earned` INT DEFAULT 0,
                `last_streak_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]])
        Log('Database table [' .. t .. '] ready.', 'success')
    end)
end

local function LoadPlayer(id, src)
    if not Config.Database.enabled then return end
    local t = Config.Database.table_name
    MySQL.query('SELECT * FROM `' .. t .. '` WHERE `identifier` = ?', { id }, function(res)
        if res and #res > 0 then
            playerBestStreaks[src] = res[1].best_streak or 0
            playerKillstreaks[src] = playerKillstreaks[src] or 0
        else
            MySQL.query('INSERT INTO `' .. t .. '` (`identifier`, `name`) VALUES (?, ?)', { id, GetPlayerName(src) })
            playerBestStreaks[src] = 0
        end
    end)
end

local function SavePlayer(src, id)
    if not Config.Database.enabled then return end
    local t = Config.Database.table_name
    MySQL.query('INSERT INTO `' .. t .. '` (`identifier`, `name`, `best_streak`) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `best_streak` = GREATEST(`best_streak`, VALUES(`best_streak`)), `total_kills` = `total_kills` + ?', {
        id, GetPlayerName(src), playerBestStreaks[src] or 0, playerKillstreaks[src] or 0
    })
end

local function RefreshLB()
    if not Config.Database.enabled then return end
    local t = Config.Database.table_name
    MySQL.query('SELECT `name`, `best_streak` FROM `' .. t .. '` ORDER BY `best_streak` DESC LIMIT ' .. Config.Leaderboard.max_entries, function(res)
        if res then
            leaderboardCache = res
            leaderboardCacheTime = GetGameTimer()
        end
    end)
end

local function SendDiscord(msg, embed)
    if not Config.Discord.enabled or Config.Discord.webhook_url == '' then return end
    PerformHttpRequest(Config.Discord.webhook_url, function() end, 'POST', json.encode({
        username = Config.Discord.bot_name or 'Ministr0 Killstreak',
        avatar_url = Config.Discord.bot_avatar or '',
        embeds = { {
            color = embed and embed.color or Config.Discord.embed_color,
            title = embed and embed.title or 'Killstreak Event',
            description = msg,
            footer = { text = Config.Discord.footer_text or 'Ministr0 Dev Killstreak System', icon_url = Config.Discord.footer_icon or '' },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
        } }
    }), { ['Content-Type'] = 'application/json' })
end

local function GiveReward(xPlayer, r)
    if not xPlayer then return false end

    if r.type == 'money' then
        local amount = r.amount or 0
        if Config.Economy.enable_money_multiplier then
            amount = math.floor(amount * (1 + Config.Economy.money_multiplier_per_streak * (playerKillstreaks[xPlayer.source] or 1)))
            amount = math.min(amount, amount * Config.Economy.max_money_multiplier)
        end
        if Config.Economy.tax_percentage > 0 then
            amount = amount - math.floor(amount * Config.Economy.tax_percentage)
        end
        xPlayer.addMoney(amount)

    elseif r.type == 'black_money' then
        xPlayer.addAccountMoney('black_money', r.amount or 0)

    elseif r.type == 'item' then
        xPlayer.addInventoryItem(r.name, r.count or 1)

    elseif r.type == 'weapon' then
        xPlayer.addWeapon(r.name, r.ammo or 100)

    elseif r.type == 'vehicle' then
        local plate = 'KS' .. math.random(1000, 9999)
        MySQL.query('INSERT INTO `owned_vehicles` (`owner`, `plate`, `vehicle`) VALUES (?, ?, ?)', {
            xPlayer.identifier, plate, json.encode({ model = GetHashKey(r.name), plate = plate })
        }, function(affected)
            if affected and affected > 0 then
                TriggerClientEvent('ministr0:notifyClient', xPlayer.source, Lang('vehicle_received'):format(r.name))
            end
        end)
    end
    return true
end

local function AntiCheat(src)
    if not Config.AntiCheat.enabled then return true end

    local now = GetGameTimer()
    local timestamps = playerKillTimestamps[src] or {}
    local recent = 0
    for _, t in ipairs(timestamps) do
        if now - t < 60000 then recent = recent + 1 end
    end

    if recent > Config.AntiCheat.max_kills_per_minute then
        Log('ANTI-CHEAT: ' .. GetPlayerName(src) .. ' exceeded limit (' .. recent .. '/min)', 'warn')
        if Config.AntiCheat.notify_admin_on_violation then
            TriggerClientEvent('chat:addMessage', -1, { args = { 'Ministr0 Dev', Lang('anticheat_violation'):format(GetPlayerName(src)) }, color = { 255, 0, 0 } })
        end
        if Config.AntiCheat.ban_on_trigger then
            DropPlayer(src, Config.AntiCheat.ban_reason)
        end
        SendDiscord('**ANTI-CHEAT**\nPlayer: ' .. GetPlayerName(src) .. '\nKills/min: ' .. recent, { title = '⚠️ Anti-Cheat', color = 16711680 })
        return false
    end

    table.insert(timestamps, now)
    if #timestamps > 100 then table.remove(timestamps, 1) end
    playerKillTimestamps[src] = timestamps

    if Config.Mechanics.cooldown_between_kills > 0 then
        local last = playerLastKillTime[src] or 0
        if now - last < Config.Mechanics.cooldown_between_kills * 1000 then return false end
    end

    playerLastKillTime[src] = now
    return true
end

local function FormatRewards(rewards)
    local parts = {}
    for _, r in ipairs(rewards) do
        if r.type == 'money' then
            table.insert(parts, '$' .. (r.amount or 0))
        elseif r.type == 'black_money' then
            table.insert(parts, '🖤 $' .. (r.amount or 0))
        elseif r.type == 'weapon' then
            table.insert(parts, '🔫 ' .. (r.name or '?'))
        elseif r.type == 'item' then
            table.insert(parts, '📦 ' .. (r.count or 1) .. 'x ' .. (r.name or '?'))
        elseif r.type == 'vehicle' then
            table.insert(parts, '🚗 ' .. (r.name or '?'))
        end
    end
    return #parts > 0 and table.concat(parts, ', ') or 'None'
end

RegisterNetEvent('ministr0:onPlayerKill')
AddEventHandler('ministr0:onPlayerKill', function(weaponHash)
    local src = source
    if not src then return end
    if not AntiCheat(src) then return end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    playerKillstreaks[src] = (playerKillstreaks[src] or 0) + 1
    local streak = playerKillstreaks[src]

    if Config.Mechanics.max_killstreak_per_session and streak > Config.Mechanics.max_killstreak_value then return end
    if streak > (playerBestStreaks[src] or 0) then
        playerBestStreaks[src] = streak
    end

    TriggerClientEvent('ministr0:updateKillstreak', src, streak, playerBestStreaks[src])

    for i, tier in ipairs(Config.KillstreakTiers) do
        if streak == tier.kills then
            local name = GetPlayerName(src)
            for _, reward in ipairs(tier.reward) do
                GiveReward(xPlayer, reward)
            end
            if tier.announce_all then
                TriggerClientEvent('ministr0:announceKillstreak', -1, (tier.announce_color or '') .. name .. Lang('reached_streak'):format(streak), i)
            end
            if Config.Database.enabled then
                local t = Config.Database.table_name
                MySQL.query('UPDATE `' .. t .. '` SET `best_streak` = GREATEST(`best_streak`, ?), `total_kills` = `total_kills` + 1, `streaks_earned` = `streaks_earned` + 1 WHERE `identifier` = ?', { streak, xPlayer.identifier })
            end
            SendDiscord('**' .. name .. '** reached **' .. streak .. ' kills** (' .. tier.title .. ')\nRewards: ' .. FormatRewards(tier.reward), { title = '⚡ ' .. tier.title, color = Config.Discord.embed_color })
            if Config.CustomEvents.on_killstreak then TriggerEvent(Config.CustomEvents.on_killstreak, src, streak, tier) end
            if Config.CustomEvents.on_reward then TriggerEvent(Config.CustomEvents.on_reward, src, streak, tier.reward) end
            Log(name .. ' — ' .. streak .. '-kill streak! [' .. tier.title .. ']', 'success')
            break
        end
    end
end)

if Config.Mechanics.reset_on_death then
    AddEventHandler('esx:onPlayerDeath', function(playerId)
        if playerKillstreaks[playerId] and playerKillstreaks[playerId] > 0 then
            if Config.CustomEvents.on_loss then TriggerEvent(Config.CustomEvents.on_loss, playerId, playerKillstreaks[playerId]) end
            playerKillstreaks[playerId] = 0
            TriggerClientEvent('ministr0:updateKillstreak', playerId, 0, playerBestStreaks[playerId] or 0)
            TriggerClientEvent('ministr0:notifyClient', playerId, Lang('streak_lost'), 'error')
        end
    end)
end

AddEventHandler('playerDropped', function()
    local src = source
    if not src then return end
    if Config.Mechanics.reset_on_disconnect then playerKillstreaks[src] = nil end
    if Config.Database.save_on_disconnect and Config.Database.enabled then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then SavePlayer(src, xPlayer.identifier) end
    end
    playerLastKillTime[src] = nil
    playerKillTimestamps[src] = nil
end)

if Config.Database.enabled then
    CreateThread(function()
        while true do
            Wait(Config.Database.save_interval_minutes * 60000)
            for src, _ in pairs(playerKillstreaks) do
                local xPlayer = ESX.GetPlayerFromId(src)
                if xPlayer then SavePlayer(src, xPlayer.identifier) end
            end
        end
    end)

    CreateThread(function()
        Wait(5000)
        EnsureTable()
        if Config.Database.auto_cleanup_days > 0 then
            MySQL.query('DELETE FROM `' .. Config.Database.table_name .. '` WHERE `last_streak_date` < DATE_SUB(NOW(), INTERVAL ? DAY)', { Config.Database.auto_cleanup_days })
        end
    end)
end

RegisterNetEvent('ministr0:requestLeaderboard')
AddEventHandler('ministr0:requestLeaderboard', function()
    local src = source
    RefreshLB()
    if #leaderboardCache == 0 then
        TriggerClientEvent('ministr0:notifyClient', src, Lang('no_leaderboard_data'), 'error')
        return
    end
    TriggerClientEvent('ministr0:showLeaderboard', src, leaderboardCache)
end)

if Config.Leaderboard.enabled then
    CreateThread(function()
        while true do
            Wait(Config.Leaderboard.refresh_interval * 1000)
            RefreshLB()
        end
    end)
end

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    local src = source
    if Config.Database.load_on_join then LoadPlayer(xPlayer.identifier, src) end
    if Config.Mechanics.reset_on_new_session then playerKillstreaks[src] = 0 end
end)

RegisterCommand(Config.Admin.commands.reset_player, function(source, args)
    local src = source
    if not IsPlayerAceAllowed(src, Config.Admin.ace_permission) then
        TriggerClientEvent('ministr0:notifyClient', src, Lang('no_permission'), 'error')
        return
    end
    local target = tonumber(args[1])
    if not target then
        TriggerClientEvent('ministr0:notifyClient', src, Lang('usage_reset'), 'error')
        return
    end
    playerKillstreaks[target] = 0
    playerBestStreaks[target] = 0
    TriggerClientEvent('ministr0:updateKillstreak', target, 0, 0)
    TriggerClientEvent('ministr0:notifyClient', target, Lang('streak_reset_admin'), 'info')
    TriggerClientEvent('ministr0:notifyClient', src, Lang('streak_reset_success'):format(GetPlayerName(target)), 'success')
    SendDiscord('**Admin Reset**\n' .. GetPlayerName(src) .. ' → ' .. GetPlayerName(target), { title = '🔧 Admin', color = 16776960 })
end, true)

RegisterCommand(Config.Admin.commands.set_streak, function(source, args)
    local src = source
    if not IsPlayerAceAllowed(src, Config.Admin.ace_permission) then
        TriggerClientEvent('ministr0:notifyClient', src, Lang('no_permission'), 'error')
        return
    end
    local target, streak = tonumber(args[1]), tonumber(args[2])
    if not target or not streak then
        TriggerClientEvent('ministr0:notifyClient', src, Lang('usage_set'), 'error')
        return
    end
    playerKillstreaks[target] = streak
    if streak > (playerBestStreaks[target] or 0) then playerBestStreaks[target] = streak end
    TriggerClientEvent('ministr0:updateKillstreak', target, streak, playerBestStreaks[target])
    TriggerClientEvent('ministr0:notifyClient', target, Lang('streak_set_admin'):format(streak), 'info')
    TriggerClientEvent('ministr0:notifyClient', src, Lang('streak_set_success'):format(GetPlayerName(target), streak), 'success')
end, true)

RegisterCommand(Config.Admin.commands.give_reward, function(source, args)
    local src = source
    if not IsPlayerAceAllowed(src, Config.Admin.ace_permission) then
        TriggerClientEvent('ministr0:notifyClient', src, Lang('no_permission'), 'error')
        return
    end
    local target = tonumber(args[1])
    if not target then
        TriggerClientEvent('ministr0:notifyClient', src, Lang('usage_gift'), 'error')
        return
    end
    local xPlayer = ESX.GetPlayerFromId(target)
    if not xPlayer then
        TriggerClientEvent('ministr0:notifyClient', src, Lang('player_not_found'), 'error')
        return
    end
    GiveReward(xPlayer, { type = args[2] or 'money', amount = tonumber(args[3]) or 1000, name = args[4] })
    TriggerClientEvent('ministr0:notifyClient', src, Lang('reward_given'):format(GetPlayerName(target)), 'success')
end, true)

RegisterCommand(Config.Admin.commands.reload_config, function(source, args)
    local src = source
    if not IsPlayerAceAllowed(src, Config.Admin.ace_permission) then
        TriggerClientEvent('ministr0:notifyClient', src, Lang('no_permission'), 'error')
        return
    end
    ExecuteCommand('ensure ministr0_killstreak')
    TriggerClientEvent('ministr0:notifyClient', src, Lang('config_reloaded'), 'success')
end, true)

exports('GetPlayerStreak', function(id) return playerKillstreaks[id] or 0 end)
exports('GetPlayerBestStreak', function(id) return playerBestStreaks[id] or 0 end)
exports('SetPlayerStreak', function(id, streak)
    playerKillstreaks[id] = streak
    if streak > (playerBestStreaks[id] or 0) then playerBestStreaks[id] = streak end
    TriggerClientEvent('ministr0:updateKillstreak', id, streak, playerBestStreaks[id])
    return true
end)
exports('ResetPlayerStreak', function(id)
    playerKillstreaks[id] = 0
    TriggerClientEvent('ministr0:updateKillstreak', id, 0, playerBestStreaks[id] or 0)
    return true
end)
exports('GetLeaderboard', function() return leaderboardCache end)
exports('GiveCustomReward', function(id, rType, amount, name)
    local xPlayer = ESX.GetPlayerFromId(id)
    if not xPlayer then return false end
    return GiveReward(xPlayer, { type = rType, amount = amount, name = name })
end)

Log('╔═══════════════════════════════════════════════════╗', 'info')
Log('║      Ministr0 Dev — Killstreak System v' .. Config.Developer.version .. '       ║', 'info')
Log('║      Developed by ' .. Config.Developer.name .. '              ║', 'info')
Log('║      ' .. Config.Developer.discord .. '                    ║', 'info')
Log('╚═══════════════════════════════════════════════════╝', 'info')
Log(#Config.KillstreakTiers .. ' tiers | DB: ' .. tostring(Config.Database.enabled) .. ' | Discord: ' .. tostring(Config.Discord.enabled) .. ' | AntiCheat: ' .. tostring(Config.AntiCheat.enabled), 'info')

-- Developed by Ministr0 Dev | discord.gg/4eh8
