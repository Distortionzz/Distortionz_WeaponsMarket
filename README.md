# 🔫🟡 Distortionz Weapons Market

**Premium black market dealer for FiveM / Qbox.**
A polished, feature-rich underground arms script where a roaming dealer rotates between hidden locations across the map. Players hunt for the dealer using rumor hints and proximity scouting, then unlock heavier firepower as they earn the dealer's trust.

---

## ✨ Features

### 🚚 Roaming Dealer System
The dealer doesn't sit at a static spot — they rotate every **90 minutes** between **10 hidden locations** across Los Santos & Blaine County. No public map blip. Players have to learn the rhythm of the map and listen for street rumors.

| 📍 Location | 🗺️ Area |
|-------------|---------|
| Cypress Flats yard | Cypress Flats |
| El Burro container lot | El Burro Heights |
| Cypress trainyard | Cypress Flats |
| Strawberry alley | Strawberry |
| Davis backlot | Davis |
| Vespucci side street | Vespucci Beach |
| Forum Drive corner | Davis |
| Sandy gas station | Sandy Shores |
| Stab City trailer | Stab City |
| Paleto auto shop alley | Paleto Bay |

### 🏆 4-Tier Reputation System
Players earn dealer trust through purchases. Each tier unlocks heavier weapons:

| Tier | Label | Required Purchases | Color |
|------|-------|-------------------|-------|
| 🩶 1 | **WALK-IN** | 0 | Grey |
| 🟦 2 | **REGULAR** | 5 | Blue |
| 🟪 3 | **TRUSTED** | 15 | Purple |
| 🟡 4 | **MADE MAN** | 30 | Gold |

Reputation **persists across sessions** via `qbx_core` player metadata (`distortionz_weaponsmarket_rep`).

### 💰 Mixed Payment System
Different items demand different money:

- 🟢 **Tier 1 — Cash** (basics, sidearms, ammo)
- 🟡 **Tier 2 — Mixed** (pistols cash, SMGs/shotguns dirty money)
- 🟠 **Tier 3-4 — Dirty Money** (suppressed weapons, rifles, snipers)

Dirty money pulls from `qbx_core` player metadata (`dirtymoney`) — pair this script with `distortionz_moneylaundering` for the full underground economy loop.

### 💎 Glassy NUI Shop
Premium black-market vibes with full Distortionz brand styling:

- 🟡 Pulsing **BLACK MARKET** brand tag
- 🏷️ Live reputation badge (color shifts per tier)
- 📊 Progress bar showing purchases until next rank
- 📑 Tabs: **Weapons** / **Ammo**
- 🔒 Locked items shown with lock icon (no buy button)
- 🎨 Color-coded tier pills on every item card
- 💵 Cash / Dirty Money labels per item (green / orange)
- ✨ Glassy translucent panel matching all Distortionz scripts

### 📢 Rumor Broadcasting System
Every **30 minutes**, a "word on the street" message broadcasts to all players hinting at the dealer's rough area:

> *"Word on the street is the dealer is around Cypress Flats."*
> *"Whispers in the alleys say the dealer is around Sandy Shores."*
> *"They say if you're looking for hardware, check Strawberry."*

**8 randomized templates** keep it fresh. Delivered through both **chat** (yellow Distortionz tag) and **notify popup** (Whispers title).

### 🔴 Proximity Radar
Once players reach the rumored area, the hunt continues — a **red 60m radius circle** appears on their map when they get within **150m** of the dealer. Combine rumor + radar for a satisfying RP discovery loop:

1. ⏱️ Widget shows next rotation timer
2. 📢 Rumor: "Dealer is around Cypress Flats"
3. 🚗 Drive to Cypress Flats
4. 🔴 Red proximity circle pops on map
5. 🎯 Spot the smoking dealer ped tucked away
6. 🤝 ox_target → Talk to Dealer
7. 💎 Glassy shop opens

### ⏱️ Persistent Corner Widget
A small countdown widget locks to the **bottom-right corner** at all times:

```
🟡 BLACK MARKET
DEALER LIVE
01:23:45
until relocation
```

Color states: **white** (normal) → **amber** (under 5 min) → **red blinking** (under 1 min). Synced across all players using a server-side timestamp, so everyone's countdown agrees.

### 🚨 Police Alert System
Higher-tier purchases have a chance to alert police with a flashing red blip:

| Tier | Alert Chance |
|------|--------------|
| Tier 1 | 0% |
| Tier 2 | 5% |
| Tier 3 | 15% |
| Tier 4 | 30% |

Alert blip lasts **90 seconds**. Cops on duty (configurable jobs: `police`, `sheriff`, `sasp`) get a "Suspicious Activity" notification with the location.

### 🛡️ Anti-Exploit Layer
- 🔒 Server validates dealer distance (≤4m) on shop open AND purchase
- ⏱️ Per-player purchase cooldown (5s default)
- 💰 Server-side payment validation (cash, bank, dirtymoney metadata)
- 🎒 Auto-refund if `ox_inventory` rejects the item (e.g., full inventory)
- 🔑 Tier validation server-side (clients can't fake their reputation)

### 🌍 Ground-Snapped Ped Spawning
Three-layer ground detection prevents floating dealers:
1. `RequestAdditionalCollisionAtCoord` to load the area's collision mesh
2. `GetGroundZFor_3dCoord` with multi-height fallbacks
3. `PlaceObjectOnGroundProperly` as final safety

### 🛠️ Admin Commands

| Command | Permission | Effect |
|---------|------------|--------|
| `/findarms_admin` | `group.admin` | Print current dealer location to your console |
| `/rotatearms_admin` | `group.admin` | Force the dealer to rotate now |
| `/rumor_admin` | `group.admin` | Force-broadcast a rumor right now |

### 🧾 Standardized Version Checker
- 📡 GitHub `version.json` polling on resource start
- 🔍 HTML-response detection (catches misconfigured URLs)
- 🆔 Custom User-Agent (avoids GitHub rate limits)
- 🟢 Color-coded console output

---

## 📦 Resource Name

```
distortionz_weaponsmarket
```

## 🛠 Installation

1. 📥 Drop the folder into your `resources/` folder
2. ⚙️ Open `config.lua` and tune:
   - `Config.Dealer.locations` — add/remove rotation spots (each needs `area` for rumors)
   - `Config.Dealer.rotationMinutes` — how often the dealer relocates
   - `Config.Catalog` — your weapon list, prices, and tier requirements
   - `Config.Reputation.tiers` — purchase thresholds for each rank
   - `Config.Police.alertChance` — % chance per tier
   - `Config.Rumors.intervalMinutes` — how often rumors broadcast
   - `Config.ProximityBlip.revealRadius` / `circleRadius` — radar tuning
3. 📝 Add to your `server.cfg`:
   ```cfg
   ensure distortionz_weaponsmarket
   ```
4. 🔄 Restart your server

## 🧩 Dependencies

- 🟦 [`qbx_core`](https://github.com/Qbox-project/qbx_core)
- 🛠️ [`ox_lib`](https://github.com/overextended/ox_lib)
- 🎯 [`ox_target`](https://github.com/overextended/ox_target)
- 🎒 [`ox_inventory`](https://github.com/overextended/ox_inventory)
- 🔔 [`distortionz_notify`](https://github.com/Distortionzz/Distortionz_Notify) *(optional — falls back to ox_lib)*

## 🎮 Player Flow

1. ⏱️ Player sees corner widget — **DEALER LIVE 01:23:45**
2. 📢 Chat: *"Rumor: Word on the street is the dealer is around Cypress Flats."*
3. 🚗 Player heads to Cypress Flats, drives the alleys
4. 🔴 Red proximity circle appears on map within 150m
5. 👀 Spots smoking ped tucked in a yard
6. 🤝 Walks up, ox_target → "Talk to Dealer"
7. 💎 Glassy NUI shop opens, browses tier-locked weapons
8. 💰 Buys a pistol (cash) or an SMG (dirty money)
9. 📈 Reputation climbs, new tiers unlock with each purchase
10. 🚨 Higher tier purchases roll for police alert chance

## 🎭 Roleplay Scenarios

### The Walk-in
> Player hits Tier 1 stuff with cash — pistols, knives, basic ammo. Dealer keeps it polite, no alerts. Easy entry into the underground.

### The Regular Buyer
> 5 purchases later, the dealer trusts you with SMGs and sawed-offs. Now you're paying with dirty money you laundered through `distortionz_moneylaundering`.

### The Trusted Soldier
> 15 purchases in, you've got access to suppressed SMGs, pump shotguns, and assault rifles. Cops start whispering about a new player in town.

### The Made Man
> 30 purchases. Carbine rifles, special carbines, sniper rifles — the full toolkit. Every transaction is a 30% police alert roll. Welcome to the top.

## 📝 Changelog

### v1.0.4
- 🔴 Added **proximity radar** — red 60m circle reveals when player is within 150m of dealer

### v1.0.3
- 🌍 Fixed dealer ped spawning in mid-air (three-layer ground detection)

### v1.0.2
- 📢 Added rumor broadcasting system with 8 randomized templates
- 🛠️ New `/rumor_admin` command

### v1.0.1
- ⏱️ Added persistent bottom-right countdown widget with color states

### v1.0.0
- 🎉 Initial release
- 🚚 Roaming dealer with 10 rotation locations
- 🏆 4-tier reputation system with persistent metadata
- 💰 Mixed cash/dirty money payment per item
- 💎 Glassy NUI shop with weapons + ammo tabs
- 🚨 Police alerts with tier-based chance

---

## 📜 License

MIT — see `LICENSE`.

---

**Built with 🟡 by Distortionz** · Part of the [Distortionz RP](https://github.com/Distortionzz) script lineup
