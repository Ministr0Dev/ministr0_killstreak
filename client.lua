-- Ministr0 Dev — Killstreak System (Client) | discord.gg/4eh8
-- © 2026 Ministr0 Dev. All rights reserved.

local ESX, PlayerData = nil, {}
local currentStreak = 0
local bestStreak = 0
local hudHidden = false
local killfeedEntries = {}
local streakHistory = {}

CreateThread(function()
    while not ESX do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Wait(100)
    end
    PlayerData = ESX.GetPlayerData()
    while not Config do Wait(0) end

    if Config.Misc.debug then
        print('[Ministr0 Dev] Killstreak System v' .. Config.Developer.version .. ' loaded.')
    end

    if Config.Sounds.enabled and Config.Sounds.custom_audio_bank then
        RequestSound(Config.Sounds.audio_bank_name)
    end
end)

local function Notify(msg, nType, duration)
    nType = nType or 'info'
    duration = duration or Config.Notifications.timeout
    local system = Config.Notifications.system

    if system == 'auto' then
        if ESX and ESX.ShowNotification then
            system = 'esx'
        elseif exports['okokNotify'] then
            system = 'okok'
        elseif exports['mythic_notify'] then
            system = 'mythic'
        elseif exports['pNotify'] then
            system = 'pnotify'
        else
            system = 'chat'
        end
    end

    if system == 'esx' then
        ESX.ShowNotification(msg)
    elseif system == 'okok' then
        exports['okokNotify']:Alert(Lang('notification_title'), msg, duration, nType)
    elseif system == 'mythic' then
        exports['mythic_notify']:SendAlert(nType, msg, duration)
    elseif system == 'pnotify' then
        exports['pNotify']:SendNotification({ text = msg, type = nType, timeout = duration, layout = Config.Notifications.position })
    elseif system == 'chat' then
        TriggerEvent('chat:addMessage', { args = { Lang('notification_title'), msg }, color = { 114, 204, 255 } })
    end
end

local function PlayStreakSound(tier)
    if not Config.Sounds.enabled then return end
    if not tier.effects or not tier.effects.sound then return end
    PlaySoundFrontend(-1, tier.effects.sound, tier.effects.sound_set or 'STREAK_SOUNDS', true)
end

local function ApplyScreenEffects(tier)
    if not Config.ScreenEffects.enabled then return end
    local ef = tier.effects

    if ef.screen_flash then
        DoScreenFadeOut(Config.ScreenEffects.flash_duration)
        Wait(Config.ScreenEffects.flash_duration / 2)
        DoScreenFadeIn(Config.ScreenEffects.flash_duration)
    end

    if ef.screen_shake then
        ShakeGameplayCam('DEATH_FAIL_IN_EFFECT_SHAKE', ef.shake_intensity or 0.25)
        Wait(Config.ScreenEffects.shake_duration)
        StopGameplayCamShaking(true)
    end

    if Config.ScreenEffects.cinematic_border_on_godlike and tier.kills >= 30 then
        SetCinematicModeActive(true)
        Wait(Config.ScreenEffects.cinematic_border_duration)
        SetCinematicModeActive(false)
    end
end

local function SpawnParticles(tier)
    if not Config.Particles.enabled then return end
    local cfg = Config.Particles['streak_' .. tier.kills]
    if not cfg then return end

    local coords = GetEntityCoords(PlayerPedId())
    RequestNamedPtfxAsset(cfg.ptfx)
    while not HasNamedPtfxAssetLoaded(cfg.ptfx) do Wait(0) end

    UseParticleFxAssetNextCall(cfg.ptfx)
    StartParticleFxNonLoopedAtCoord(cfg.fx, coords.x, coords.y, coords.z + 1.0, 0.0, 0.0, 0.0, cfg.scale or 1.0, false, false, false)
end

local function GetStreakColor(streak)
    for _, tier in ipairs(Config.KillstreakTiers) do
        if streak >= tier.kills then
            return tier.color
        end
    end
    return { r = 255, g = 255, b = 255 }
end

local function GetNextStreakTier()
    for _, tier in ipairs(Config.KillstreakTiers) do
        if tier.kills > currentStreak then return tier end
    end
    return nil
end

local function DrawHUD()
    if hudHidden or not Config.HUD.enabled or currentStreak < 1 then return end

    local screenX, screenY = GetScreenResolution(0, 0)
    local scale = Config.HUD.scale
    local pos = Config.HUD.position
    local boxX, boxY

    if pos == 'top-left' then
        boxX, boxY = 0.01, 0.01
    elseif pos == 'top-right' then
        boxX, boxY = screenX - 0.25, 0.01
    elseif pos == 'bottom-left' then
        boxX, boxY = 0.01, screenY - 0.08
    elseif pos == 'bottom-right' then
        boxX, boxY = screenX - 0.25, screenY - 0.08
    else
        boxX, boxY = (screenX / 2) - 0.12, screenY - 0.06
    end

    local bg = Config.HUD.bg_color
    DrawRect(boxX + 0.12, boxY + 0.025, 0.24, 0.05, bg.r / 255, bg.g / 255, bg.b / 255, bg.a / 255)

    local tc = Config.HUD.text_color
    SetTextFont(Config.HUD.font)
    SetTextScale(0.0, scale)
    SetTextColour(tc.r, tc.g, tc.b, tc.a)
    SetTextDropShadow(0, 0, 0, 0, 100)
    SetTextCentre(true)
    SetTextEntry('STRING')
    AddTextComponentString(Lang('hud_streak'):format(currentStreak))
    DrawText(boxX + 0.12, boxY + 0.008)

    if Config.HUD.show_best_streak and bestStreak > 0 then
        SetTextFont(Config.HUD.font)
        SetTextScale(0.0, scale - 0.1)
        SetTextColour(tc.r - 50, tc.g - 50, tc.b - 50, tc.a)
        SetTextCentre(true)
        SetTextEntry('STRING')
        AddTextComponentString(Lang('hud_best'):format(bestStreak))
        DrawText(boxX + 0.12, boxY + 0.028)
    end

    if Config.HUD.show_next_reward then
        local next = GetNextStreakTier()
        if next then
            SetTextFont(Config.HUD.font)
            SetTextScale(0.0, scale - 0.1)
            SetTextColour(255, 255, 0, tc.a)
            SetTextCentre(true)
            SetTextEntry('STRING')
            AddTextComponentString(Lang('hud_next'):format(next.kills))
            DrawText(boxX + 0.12, boxY + 0.048)
        end
    end
end

local function AddKillfeedEntry(killer, victim, streak, weapon)
    if not Config.Killfeed.enabled then return end
    table.insert(killfeedEntries, { killer = killer, victim = victim, streak = streak, weapon = weapon, time = GetGameTimer() })
    if #killfeedEntries > Config.Killfeed.max_entries then
        table.remove(killfeedEntries, 1)
    end
end

local function GetWeaponLabel(hash)
    local map = {
        [GetHashKey('GROUP_PISTOL')] = 'Pistol',
        [GetHashKey('GROUP_SMG')] = 'SMG',
        [GetHashKey('GROUP_RIFLE')] = 'Rifle',
        [GetHashKey('GROUP_SHOTGUN')] = 'Shotgun',
        [GetHashKey('GROUP_SNIPER')] = 'Sniper',
        [GetHashKey('GROUP_HEAVY')] = 'Heavy'
    }
    return map[GetWeapontypeGroup(hash)] or 'Unknown'
end

local function RenderKillfeed()
    if not Config.Killfeed.enabled or #killfeedEntries == 0 then return end

    local now = GetGameTimer()
    local xPos = Config.Killfeed.position == 'top-left' and 0.01 or 0.72
    local yOff = 0.0

    for i = #killfeedEntries, 1, -1 do
        local e = killfeedEntries[i]
        local elapsed = now - e.time

        if elapsed > Config.Killfeed.display_duration then
            table.remove(killfeedEntries, i)
        else
            local alpha = 255
            if elapsed > Config.Killfeed.display_duration - Config.Killfeed.fade_speed then
                alpha = math.floor(255 * (1 - (elapsed - (Config.Killfeed.display_duration - Config.Killfeed.fade_speed)) / Config.Killfeed.fade_speed))
            end

            local streakColor = GetStreakColor(e.streak)
            local weaponLabel = Config.Killfeed.show_weapon_icon and (' [' .. GetWeaponLabel(e.weapon) .. '] ') or ' '

            SetTextFont(0)
            SetTextScale(0.0, 0.35)
            SetTextColour(streakColor.r, streakColor.g, streakColor.b, alpha)
            SetTextEntry('STRING')
            AddTextComponentString(e.killer .. weaponLabel .. e.victim)
            DrawText(xPos, 0.1 + yOff)

            if Config.Killfeed.show_streak_count and e.streak > 2 then
                SetTextScale(0.0, 0.3)
                SetTextEntry('STRING')
                AddTextComponentString('⚡' .. e.streak)
                DrawText(xPos + 0.15, 0.1 + yOff)
            end

            yOff = yOff + 0.025
        end
    end
end

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end
    if not args[6] or args[6] ~= 1 then return end
    if not IsEntityAPed(args[1]) or not IsPedAPlayer(args[1]) then return end

    local victim = args[1]
    local attacker = args[2]
    local ped = PlayerPedId()

    if attacker ~= ped or victim == attacker then return end
    if IsEntityDead(victim) or GetEntityHealth(victim) <= 0 then
        TriggerServerEvent('ministr0:onPlayerKill', GetCurrentWeapon())
    end
end)

RegisterNetEvent('ministr0:updateKillstreak')
AddEventHandler('ministr0:updateKillstreak', function(streak, best)
    currentStreak = streak
    if best and best > bestStreak then
        bestStreak = best
    end
end)

RegisterNetEvent('ministr0:announceKillstreak')
AddEventHandler('ministr0:announceKillstreak', function(msg, tierIndex)
    local tier = Config.KillstreakTiers[tierIndex]
    if not tier then
        Notify(msg, 'success')
        return
    end

    PlayStreakSound(tier)
    ApplyScreenEffects(tier)
    SpawnParticles(tier)

    if Config.HUD.enabled then
        SetTextFont(0)
        SetTextScale(0.0, 0.8)
        SetTextColour(tier.color.r, tier.color.g, tier.color.b, 255)
        SetTextCentre(true)
        SetTextEntry('STRING')
        AddTextComponentString(tier.title)
        DrawText(0.5, 0.35)

        SetTextScale(0.0, 0.5)
        SetTextEntry('STRING')
        AddTextComponentString(tier.subtitle)
        DrawText(0.5, 0.40)

        Wait(2000)
    end

    Notify(msg, 'success', Config.Notifications.timeout)
end)

RegisterNetEvent('ministr0:notifyClient')
AddEventHandler('ministr0:notifyClient', function(msg, nType)
    Notify(msg, nType or 'info')
end)

RegisterNetEvent('ministr0:playSound')
AddEventHandler('ministr0:playSound', function(sound, set)
    if Config.Sounds.enabled then
        PlaySoundFrontend(-1, sound, set or 'STREAK_SOUNDS', true)
    end
end)

RegisterNetEvent('ministr0:killfeedEntry')
AddEventHandler('ministr0:killfeedEntry', function(killer, victim, streak, weapon)
    AddKillfeedEntry(killer, victim, streak, weapon)
end)

RegisterNetEvent('ministr0:setHudState')
AddEventHandler('ministr0:setHudState', function(hidden)
    hudHidden = hidden
    Notify(hidden and Lang('hud_hidden') or Lang('hud_shown'), 'info')
end)

RegisterNetEvent('ministr0:showLeaderboard')
AddEventHandler('ministr0:showLeaderboard', function(data)
    local lines = { '<CENTER>' .. Lang('leaderboard_title'), '' }
    for i, entry in ipairs(data) do
        local icon = i == 1 and '🥇' or i == 2 and '🥈' or i == 3 and '🥉' or i .. '.'
        table.insert(lines, icon .. ' ' .. entry.name .. ' — ⚡ ' .. entry.streak .. ' kills')
    end
    table.insert(lines, '')
    table.insert(lines, '<CENTER>' .. Lang('developed_by'))
    TriggerEvent('chat:addMessage', { args = { Lang('leaderboard_title'), table.concat(lines, '\n') }, color = { 114, 204, 255 } })
end)

CreateThread(function()
    while true do
        Wait(0)
        if NetworkIsSessionStarted() then
            DrawHUD()
            RenderKillfeed()
        end
    end
end)

RegisterCommand(Config.Admin.commands.toggle_hud, function()
    hudHidden = not hudHidden
    Notify(hudHidden and Lang('hud_hidden') or Lang('hud_shown'), 'info')
end, false)

RegisterCommand(Config.Admin.commands.leaderboard, function()
    TriggerServerEvent('ministr0:requestLeaderboard')
end, false)

AddEventHandler('onClientResourceStop', function(name)
    if GetCurrentResourceName() == name then
        currentStreak = 0
        bestStreak = 0
        killfeedEntries = {}
    end
end)

-- Developed by Ministr0 Dev | discord.gg/4eh8
