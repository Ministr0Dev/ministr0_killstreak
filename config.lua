-- Ministr0 Dev — Killstreak System Configuration | discord.gg/4eh8
-- © 2026 Ministr0 Dev. All rights reserved.

Config = {}
Config.Locale = 'en'

Config.Developer = {
    name = 'Ministr0 Dev',
    discord = 'discord.gg/4eh8',
    version = '2.0.0',
    website = 'https://discord.gg/4eh8'
}

Config.KillstreakTiers = {
    { kills = 3, title = 'WARMING UP', subtitle = '~g~3-Kill Streak', color = { r = 0, g = 255, b = 0 },
      reward = { { type = 'money', amount = 1000 }, { type = 'item', name = 'bread', count = 2 } },
      effects = { screen_flash = true, screen_shake = false, sound = 'STREAK_3', sound_set = 'STREAK_SOUNDS' },
      announce_all = true, announce_color = '~g~' },
    { kills = 5, title = 'ON FIRE', subtitle = '~y~5-Kill Streak', color = { r = 255, g = 255, b = 0 },
      reward = { { type = 'money', amount = 2500 }, { type = 'weapon', name = 'WEAPON_SMG', ammo = 120 } },
      effects = { screen_flash = true, screen_shake = true, shake_intensity = 0.15, sound = 'STREAK_5', sound_set = 'STREAK_SOUNDS' },
      announce_all = true, announce_color = '~y~' },
    { kills = 10, title = 'UNSTOPPABLE', subtitle = '~o~10-Kill Streak', color = { r = 255, g = 165, b = 0 },
      reward = { { type = 'money', amount = 5000 }, { type = 'weapon', name = 'WEAPON_ASSAULTRIFLE', ammo = 240 } },
      effects = { screen_flash = true, screen_shake = true, shake_intensity = 0.25, sound = 'STREAK_10', sound_set = 'STREAK_SOUNDS' },
      announce_all = true, announce_color = '~o~' },
    { kills = 15, title = 'DOMINATING', subtitle = '~r~15-Kill Streak', color = { r = 255, g = 0, b = 0 },
      reward = { { type = 'money', amount = 10000 }, { type = 'black_money', amount = 2500 }, { type = 'weapon', name = 'WEAPON_HEAVYRIFLE', ammo = 300 } },
      effects = { screen_flash = true, screen_shake = true, shake_intensity = 0.35, sound = 'STREAK_15', sound_set = 'STREAK_SOUNDS' },
      announce_all = true, announce_color = '~r~' },
    { kills = 20, title = 'LEGENDARY', subtitle = '~p~20-Kill Streak — LEGENDARY', color = { r = 255, g = 0, b = 255 },
      reward = { { type = 'money', amount = 25000 }, { type = 'black_money', amount = 5000 }, { type = 'vehicle', name = 'adder', spawn_at = 'nearest' }, { type = 'weapon', name = 'WEAPON_RPG', ammo = 10 } },
      effects = { screen_flash = true, screen_shake = true, shake_intensity = 0.5, sound = 'STREAK_20', sound_set = 'STREAK_SOUNDS' },
      announce_all = true, announce_color = '~p~' },
    { kills = 30, title = 'GODLIKE', subtitle = '~b~30-Kill Streak — GODLIKE', color = { r = 0, g = 191, b = 255 },
      reward = { { type = 'money', amount = 50000 }, { type = 'black_money', amount = 10000 }, { type = 'item', name = 'gold_chain', count = 1 }, { type = 'weapon', name = 'WEAPON_MINIGUN', ammo = 500 } },
      effects = { screen_flash = true, screen_shake = true, shake_intensity = 0.65, sound = 'STREAK_30', sound_set = 'STREAK_SOUNDS' },
      announce_all = true, announce_color = '~b~' },
    { kills = 50, title = 'IMMORTAL', subtitle = '~y~50-Kill Streak — IMMORTAL', color = { r = 255, g = 215, b = 0 },
      reward = { { type = 'money', amount = 100000 }, { type = 'black_money', amount = 25000 }, { type = 'item', name = 'diamond', count = 5 }, { type = 'vehicle', name = 'nero', spawn_at = 'nearest' }, { type = 'weapon', name = 'WEAPON_RAILGUN', ammo = 20 } },
      effects = { screen_flash = true, screen_shake = true, shake_intensity = 1.0, sound = 'STREAK_50', sound_set = 'STREAK_SOUNDS' },
      announce_all = true, announce_color = '~y~' }
}

Config.Mechanics = {
    reset_on_death = true,
    reset_on_disconnect = true,
    reset_on_respawn = true,
    reset_on_new_session = true,
    max_killstreak_per_session = false,
    max_killstreak_value = 100,
    cooldown_between_kills = 0.5,
    require_damage_from_weapon = true,
    track_by_weapon_category = false,
    assist_time_window = 5.0,
    assist_counts_as_kill = false,
    headshot_bonus = false,
    headshot_bonus_kills = 1,
    melee_bonus = false,
    melee_bonus_kills = 2,
    no_scoping_multiplier = 1.0
}

Config.HUD = {
    enabled = true,
    position = 'bottom-center',
    font = 0,
    scale = 0.4,
    text_color = { r = 255, g = 255, b = 255, a = 255 },
    bg_color = { r = 0, g = 0, b = 0, a = 120 },
    show_current_streak = true,
    show_best_streak = true,
    show_next_reward = true,
    display_mode = 'always',
    fade_out_time = 5.0,
    anim_slide = true,
    anim_pulse = true
}

Config.Notifications = {
    system = 'auto',
    custom_css = true,
    timeout = 5000,
    position = 'top-right',
    animation = 'slide'
}

Config.Sounds = {
    enabled = true,
    volume = 0.6,
    custom_audio_bank = true,
    audio_bank_name = 'STREAK_SOUNDS'
}

Config.ScreenEffects = {
    enabled = true,
    flash_duration = 200,
    shake_duration = 300,
    cinematic_border_on_godlike = true,
    cinematic_border_duration = 4000
}

Config.Killfeed = {
    enabled = true,
    max_entries = 10,
    position = 'top-right',
    display_duration = 6000,
    fade_speed = 500,
    show_weapon_icon = true,
    show_streak_count = true
}

Config.Particles = {
    enabled = true,
    streak_10 = { fx = 'scr_fbi_fire_plane', ptfx = 'core', scale = 1.0 },
    streak_20 = { fx = 'scr_apartment_ammo_helicopter', ptfx = 'core', scale = 1.5 },
    streak_30 = { fx = 'scr_indep_fireworks', ptfx = 'core', scale = 2.0 },
    streak_50 = { fx = 'scr_fbi_fire_plane', ptfx = 'core', scale = 3.0 }
}

Config.Discord = {
    enabled = false,
    webhook_url = '',
    embed_color = 5814783,
    footer_text = 'Ministr0 Dev Killstreak System',
    footer_icon = '',
    log_killstreak_milestone = true,
    log_leaderboard = true,
    log_admin_actions = true,
    bot_name = 'Ministr0 Killstreak',
    bot_avatar = ''
}

Config.Database = {
    enabled = true,
    table_name = 'ministr0_killstreaks',
    auto_cleanup_days = 30,
    save_interval_minutes = 5,
    save_on_disconnect = true,
    load_on_join = true
}

Config.Leaderboard = {
    enabled = true,
    max_entries = 10,
    command = 'killstreaks',
    refresh_interval = 30
}

Config.Admin = {
    ace_permission = 'ministr0.admin',
    commands = {
        reset_player = 'resetstreak',
        set_streak = 'setstreak',
        give_reward = 'giftreak',
        reload_config = 'reloadstreaks',
        toggle_hud = 'togglestreak',
        leaderboard = 'killstreaks'
    }
}

Config.AntiCheat = {
    enabled = true,
    max_kills_per_second = 5,
    max_kills_per_minute = 60,
    ban_on_trigger = true,
    ban_reason = 'Killstreak exploit detected | Ministr0 Dev',
    log_violations = true,
    notify_admin_on_violation = true
}

Config.Economy = {
    enable_money_multiplier = false,
    money_multiplier_per_streak = 0.1,
    max_money_multiplier = 5.0,
    tax_percentage = 0.0,
    tax_type = 'none'
}

Config.CustomEvents = {
    on_killstreak = 'ministr0:onKillstreak',
    on_reward = 'ministr0:onReward',
    on_loss = 'ministr0:onStreakLost',
    on_milestone = 'ministr0:onMilestone'
}

Config.Misc = {
    debug = false,
    developer_mode = false,
    enable_console_logging = true,
    console_prefix = '[Ministr0 Dev]',
    check_updates = true,
    update_url = 'https://discord.gg/4eh8'
}

-- Developed by Ministr0 Dev | discord.gg/4eh8
