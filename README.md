# Distortionz Weapons Market

> Premium underground weapons market for Qbox/FiveM — roaming dealer with tiered weapon unlocks via reputation, mixed cash/dirty money payments, glassy NUI shop, and configurable police alerts.

![FiveM](https://img.shields.io/badge/FiveM-cerulean-yellow?style=flat-square&labelColor=181b20)
![Qbox](https://img.shields.io/badge/Qbox-required-red?style=flat-square&labelColor=dfb317)
![License](https://img.shields.io/badge/License-MIT-brightgreen?style=flat-square)
![Version](https://img.shields.io/github/v/release/Distortionzz/Distortionz_WeaponsMarket?style=flat-square&color=d4aa62&label=version)

---

## Overview

A roaming black-market arms dealer. The dealer ped relocates between configured spawn points on a timer; players who find them can browse a glassy NUI shop with tiered inventory unlocked by reputation. Pay with mixed cash + dirty money, configurable police alert chance per purchase.

## Features

- **Roaming dealer** — ped relocates between spawn points on a configurable interval
- **Reputation tiers** — higher rep unlocks better weapons
- **Mixed payment** — cash + dirty money split per item
- **Glassy NUI shop** — distortionz dark + gold theme
- **Police alert** chance on purchase, escalates with high-tier weapons
- **Protected dealer ped** — flagged so distortionz_robped skips it

## Dependencies

| Resource | Required | Purpose |
|---|---|---|
| `qbx_core` | yes | Player data, money |
| `ox_lib` | yes | Callbacks, notify fallback |
| `ox_target` | yes | Dealer ped interaction |
| `ox_inventory` | yes | Weapon delivery, dirty money |
| `distortionz_notify` | optional | Branded notifications |

## Installation

```cfg
ensure distortionz_weaponsmarket
```

## Configuration

See [`config.lua`](config.lua) for spawn point pool, relocation interval, weapon tiers + reputation requirements, payment splits, and police alert thresholds.

## Credits

- **Author:** Distortionz
- **Framework:** [Qbox Project](https://github.com/Qbox-project)

## License

MIT — see [LICENSE](LICENSE).
