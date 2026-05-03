Config = {}

Config.Script = {
    name    = 'Distortionz Weapons Market',
    version = '1.0.4',
}

Config.Debug = false

-- ─── Notify integration ─────────────────────────────────────────────
Config.Notify = {
    resource      = 'distortionz_notify',
    title         = 'Black Market',
    defaultLength = 5000,
}

-- ─── Version checker ────────────────────────────────────────────────
Config.VersionCheck = {
    enabled     = true,
    checkOnStart = true,
    url         = 'https://raw.githubusercontent.com/Distortionzz/Distortionz_WeaponsMarket/main/version.json',
}
Config.CurrentVersion = '1.0.4'

-- ─── Dealer rotation ────────────────────────────────────────────────
-- The dealer ped relocates every X hours to one of these spots.
-- A blip is NOT shown — players have to hear about the location through
-- RP channels (or use /findarms_admin to debug).
Config.Dealer = {
    model        = 's_m_y_dealer_01',
    scenario     = 'WORLD_HUMAN_SMOKING',
    targetLabel  = 'Talk to Dealer',
    targetIcon   = 'fa-solid fa-gun',

    -- How often the dealer relocates (in real-time minutes)
    rotationMinutes = 90,

    -- Pool of possible locations. Server picks a random one each rotation.
    -- All are tucked-away spots with cover and roleplay vibes.
    -- Each location has an `area` field used by the rumor system to hint
    -- at the rough neighborhood without giving the exact spot.
    locations = {
        -- Industrial / warehouse zones
        { label = 'Cypress Flats yard',     area = 'Cypress Flats',  coords = vec4(819.74, -2156.07, 29.65, 178.0) },
        { label = 'El Burro container lot', area = 'El Burro Heights', coords = vec4(1135.16, -1838.76, 33.15, 175.0) },
        { label = 'Cypress trainyard',      area = 'Cypress Flats',  coords = vec4(728.60, -1875.60, 29.20, 270.0) },

        -- Alleys + back streets (Mission Row / South LS)
        { label = 'Strawberry alley',       area = 'Strawberry',     coords = vec4(125.50, -1717.50, 29.30, 138.0) },
        { label = 'Davis backlot',          area = 'Davis',          coords = vec4(82.30, -1957.40, 21.10, 318.0) },
        { label = 'Vespucci side street',   area = 'Vespucci Beach', coords = vec4(-1156.20, -1521.80, 4.40, 35.0) },

        -- Grove / Forum drive
        { label = 'Forum Drive corner',     area = 'Davis',          coords = vec4(95.40, -1955.60, 21.10, 215.0) },

        -- Sandy Shores (rural option)
        { label = 'Sandy gas station',      area = 'Sandy Shores',   coords = vec4(1689.40, 3585.40, 35.60, 28.0) },
        { label = 'Stab City trailer',      area = 'Stab City',      coords = vec4(193.20, 3637.10, 31.40, 240.0) },

        -- Paleto / countryside
        { label = 'Paleto auto shop alley', area = 'Paleto Bay',     coords = vec4(105.80, 6620.00, 31.80, 270.0) },
    },
}

-- ─── Proximity blip ─────────────────────────────────────────────────
-- Reveals a red circle on the map when the player gets close to the
-- current dealer. Rewards exploration without spoiling the location
-- across the whole map.
Config.ProximityBlip = {
    enabled         = true,

    -- Reveal the blip when player is within X meters of the dealer
    revealRadius    = 150.0,

    -- Visual radius of the red circle (meters on the map)
    circleRadius    = 60.0,

    -- How often the proximity check ticks (ms). 1000 is plenty.
    checkIntervalMs = 1000,

    -- Sprite + colors. Default is a deep red pulsing alert.
    color           = 1,    -- 1 = red
    alpha           = 96,   -- 0-255 transparency for the radius circle
}

-- ─── Rumor system ───────────────────────────────────────────────────
-- Periodically broadcasts a "word on the street" message hinting at the
-- rough AREA of the current dealer (not the exact spot). Adds RP flavor
-- and gives players a hunt target without spoiling the discovery.
Config.Rumors = {
    enabled = true,

    -- How often a rumor message broadcasts (in real-time minutes).
    -- 30 = every half hour, so within a 90-min rotation, players get ~3 hints.
    intervalMinutes = 30,

    -- Show the rumor as an in-game chat message
    showInChat = true,

    -- Also send as a notify popup
    showAsNotify = true,

    -- Pool of rumor message templates. {area} is replaced with the area name.
    -- The script picks one at random each broadcast for variety.
    templates = {
        'Word on the street is the dealer is around {area}.',
        'Heard a tip — the man with the goods is hiding out in {area}.',
        'Some folks say the black market dealer is somewhere in {area} right now.',
        'Rumor has it the dealer set up shop in {area}.',
        'A buddy of mine said the dealer is operating out of {area}.',
        'Word\'s going around that {area} is where the deals are happening.',
        'Whispers in the alleys say the dealer is around {area}.',
        'They say if you\'re looking for hardware, check {area}.',
    },
}

-- ─── Reputation tiers ───────────────────────────────────────────────
-- Players gain reputation by purchasing weapons. Higher tiers unlock
-- better weapons. Reputation persists across sessions in qbx_core
-- player metadata under 'distortionz_weaponsmarket_rep'.
Config.Reputation = {
    -- Each tier requires this many TOTAL successful purchases to unlock
    tiers = {
        { name = 'Tier 1 — Walk-in',  label = 'WALK-IN',   purchasesRequired = 0,  color = '#9ca3af' },
        { name = 'Tier 2 — Regular',  label = 'REGULAR',   purchasesRequired = 5,  color = '#5fa9ff' },
        { name = 'Tier 3 — Trusted',  label = 'TRUSTED',   purchasesRequired = 15, color = '#c590ff' },
        { name = 'Tier 4 — Made Man', label = 'MADE MAN',  purchasesRequired = 30, color = '#ffd76c' },
    },

    -- Notify the player when they unlock a new tier
    notifyOnTierUp = true,
}

-- ─── Weapon catalog ─────────────────────────────────────────────────
-- Each entry:
--   item        = ox_inventory item name
--   label       = display name in shop UI
--   description = short shop description
--   tier        = required reputation tier (1-4)
--   price       = numeric price
--   payAccount  = 'cash' | 'bank' | 'dirty'
--   stock       = -1 for unlimited, or numeric to limit
--
-- Purchasing always counts toward reputation regardless of tier.
Config.Catalog = {
    -- ─── Tier 1: Walk-in (cash, basic loadout) ─────────────────────
    {
        item = 'WEAPON_KNIFE',
        label = 'Combat Knife',
        description = 'Quiet. Reliable. No questions asked.',
        tier = 1, price = 350, payAccount = 'cash', stock = -1,
        category = 'Melee',
    },
    {
        item = 'WEAPON_BAT',
        label = 'Baseball Bat',
        description = 'Old reliable. Doesn\'t need ammo.',
        tier = 1, price = 200, payAccount = 'cash', stock = -1,
        category = 'Melee',
    },
    {
        item = 'WEAPON_PISTOL',
        label = 'Pistol .45',
        description = 'Standard sidearm. Easy concealment.',
        tier = 1, price = 4500, payAccount = 'cash', stock = -1,
        category = 'Sidearm',
    },
    {
        item = 'WEAPON_SNSPISTOL',
        label = 'SNS Pistol',
        description = 'Pocket-sized. Cheap. Disposable.',
        tier = 1, price = 3000, payAccount = 'cash', stock = -1,
        category = 'Sidearm',
    },

    -- ─── Tier 2: Regular (mixed cash + dirty) ──────────────────────
    {
        item = 'WEAPON_PISTOL50',
        label = 'Pistol .50',
        description = 'Stops anything you point it at.',
        tier = 2, price = 8500, payAccount = 'cash', stock = -1,
        category = 'Sidearm',
    },
    {
        item = 'WEAPON_MICROSMG',
        label = 'Micro SMG',
        description = 'Compact. Fast. Loud.',
        tier = 2, price = 12000, payAccount = 'dirty', stock = -1,
        category = 'SMG',
    },
    {
        item = 'WEAPON_SAWNOFFSHOTGUN',
        label = 'Sawed-Off Shotgun',
        description = 'Up close and personal.',
        tier = 2, price = 9500, payAccount = 'dirty', stock = -1,
        category = 'Shotgun',
    },

    -- ─── Tier 3: Trusted (dirty money primary) ─────────────────────
    {
        item = 'WEAPON_SMG',
        label = 'Standard SMG',
        description = 'Suppressed-ready. Professional grade.',
        tier = 3, price = 22000, payAccount = 'dirty', stock = -1,
        category = 'SMG',
    },
    {
        item = 'WEAPON_PUMPSHOTGUN',
        label = 'Pump Shotgun',
        description = 'Police-grade. Where\'d we get this? Don\'t ask.',
        tier = 3, price = 18000, payAccount = 'dirty', stock = -1,
        category = 'Shotgun',
    },
    {
        item = 'WEAPON_ASSAULTRIFLE',
        label = 'Assault Rifle',
        description = 'High capacity. High consequences.',
        tier = 3, price = 35000, payAccount = 'dirty', stock = -1,
        category = 'Rifle',
    },

    -- ─── Tier 4: Made Man (top shelf) ──────────────────────────────
    {
        item = 'WEAPON_CARBINERIFLE',
        label = 'Carbine Rifle',
        description = 'Military spec. Treat with respect.',
        tier = 4, price = 55000, payAccount = 'dirty', stock = -1,
        category = 'Rifle',
    },
    {
        item = 'WEAPON_SPECIALCARBINE',
        label = 'Special Carbine',
        description = 'Black ops favorite. Untraceable.',
        tier = 4, price = 75000, payAccount = 'dirty', stock = -1,
        category = 'Rifle',
    },
    {
        item = 'WEAPON_SNIPERRIFLE',
        label = 'Sniper Rifle',
        description = 'Long range. No witnesses.',
        tier = 4, price = 95000, payAccount = 'dirty', stock = -1,
        category = 'Sniper',
    },
}

-- ─── Ammo catalog (always Tier 1, always cash) ──────────────────────
Config.Ammo = {
    {
        item = 'ammo-9',
        label = '9mm Ammo (50 rds)',
        description = 'Pistol rounds.',
        tier = 1, price = 75, payAccount = 'cash', count = 50,
        category = 'Ammo',
    },
    {
        item = 'ammo-45',
        label = '.45 Ammo (50 rds)',
        description = 'Heavy pistol rounds.',
        tier = 1, price = 95, payAccount = 'cash', count = 50,
        category = 'Ammo',
    },
    {
        item = 'ammo-rifle',
        label = 'Rifle Ammo (50 rds)',
        description = 'Standard rifle rounds.',
        tier = 2, price = 250, payAccount = 'cash', count = 50,
        category = 'Ammo',
    },
    {
        item = 'ammo-shotgun',
        label = 'Shotgun Shells (25 rds)',
        description = '12-gauge buckshot.',
        tier = 2, price = 180, payAccount = 'cash', count = 25,
        category = 'Ammo',
    },
    {
        item = 'ammo-sniper',
        label = 'Sniper Ammo (10 rds)',
        description = 'High-caliber rounds.',
        tier = 4, price = 450, payAccount = 'dirty', count = 10,
        category = 'Ammo',
    },
}

-- ─── Police alerts ──────────────────────────────────────────────────
Config.Police = {
    jobNames = { 'police', 'sheriff', 'sasp' },

    -- Chance % to alert police on each tier purchase
    alertChance = {
        [1] = 0,    -- Walk-in: never
        [2] = 5,    -- Regular: 5%
        [3] = 15,   -- Trusted: 15%
        [4] = 30,   -- Made Man: 30%
    },

    -- Alert blip sticks for X seconds
    alertDurationSec = 90,
}

-- ─── Misc ───────────────────────────────────────────────────────────
Config.Misc = {
    -- Server-side cooldown between purchases (per player) in seconds
    purchaseCooldownSec = 5,

    -- If true, save reputation across server restarts via qbx_core metadata
    persistReputation = true,
}
