# 👋 Slap the Gyatt 2.2

A complete Roblox simulator game: slap the Gyatts, collect **Slaps** and **Gems**,
upgrade your hand, hatch pets, unlock 6 worlds and become the strongest!

## 🚀 How to start

1. Download **`SlapTheGyatt.rbxlx`**.
2. Open it in Roblox Studio (double-click, or *File → Open*).
3. Press **▶ Play**. Done!

The whole world (about 2100 parts), all Gyatts, eggs, menus and effects are built by
the scripts when the game starts. You don't need to build anything yourself.

**Saving in Studio:** publish the game and turn on
*Game Settings → Security → Enable Studio Access to API Services*.
Without that everything works, only progress isn't saved.

With Rojo: `rojo serve` (the `default.project.json` is in this folder).

## 🎮 What's inside

### The Gyatts
Cartoon booty characters: two big round cheeks in colorful shorts, a waistband with a
"GYATT" tag, little legs and sneakers. They bounce, turn toward you and wobble when you
slap them. Accessories: bow, heart prints, cowboy hat, winter pompoms, devil horns and tail,
angel wings and halo, alien antennas, crown.

### 6 worlds with 12 Gyatts
| Zone | Gyatts | Decor & background |
|---|---|---|
| 1 Gyatt Meadow | Baby Gyatt, Big Gyatt | trees, flowers, green mountains with snow caps |
| 2 Gyatt Desert | Cactus Gyatt, Pharaoh Gyatt | cacti, palms, pyramids, red mesas and dunes |
| 3 Gyatt Ice Land | Snow Gyatt, Frost Gyatt | ice spikes, pines, snowmen, icy mountains |
| 4 Gyatt Volcano | Magma Gyatt, Inferno Gyatt | lava pools, volcanoes with fire, dark smoky sky |
| 5 Gyatt Cloud Heaven | Angel Gyatt, Heaven Gyatt | clouds, gold pillars, rainbow, floating cloud temples |
| 6 Gyatt Galaxy | Alien Gyatt, GYATT GOD | stars, planets, crystals, floating asteroids, night sky |

### 🌄 Background
Sky with sun, moon and stars, real moving clouds, ground and mountains all around the map,
and a giant **Mount Gyatt** statue behind the spawn. Light, clouds and mood change per zone.

### ⭐ Golden Gyatt (event)
Every 4–7 minutes a Golden Gyatt appears with huge rewards and Gems, with a countdown banner.

### ✋ 12 hands, 🛒 6 upgrades
Wood → Stone → Iron → Gold → Emerald → Diamond → Frost → Lava → Cloud → Galaxy → Rainbow → **Gyatt God Hand**.
Upgrades: Hand Power, Slap Speed, Reach, Crit Luck, Slap Greed, Combo Master (with "Buy MAX").
Crits (x3), rare MEGA crits (x30) and a combo system up to +225 % Slaps.

### 👑 Legendary hands
| Hand | Price | Power |
|---|---|---|
| Gyatt God Hand | 💎 2,500 | x100 damage, x1.25 Slaps |
| Dragon Claw | 💎 6,000 | x180 damage, x1.5 Slaps, +5% crit, claws + dragon fire |
| **Thanos Gauntlet** | **R$ 299** | x500 damage, x3 Slaps, +10% crit, +5 reach, +25% speed, **🫰 SNAP: 5% chance to erase a Gyatt instantly**, 6 Infinity Stones |
| **ULTRA GOD HAND** | **R$ 1999** | x2500 damage, x10 Slaps, +25% crit, +15 reach, +100% speed, **⚡ DIVINE SMITE every 5th slap (x25, hits all Gyatts nearby)** + 10% SNAP, rainbow halo |

#### Setting up the Robux hands (Game Passes)
Robux items must be created on the Roblox website, the code only needs their ID:
1. Publish the game, then go to **create.roblox.com → your game → Monetization → Passes → Create a Pass**.
2. Create "Thanos Gauntlet", set **Item for Sale** to on and the price to **299**.
3. Create "Ultra God Hand" with price **1999**.
4. Copy each pass ID (the number in the pass page address) into `src/shared/Config.lua`
   at `GamePassId = 0` of the matching hand, then run `python3 tools/build_place.py`
   (or paste the ID directly into the `Config` ModuleScript in Studio).

While `GamePassId` is `0`, the hand is **free in Studio only** (for testing, never saved).
In the real game it shows "coming soon" until you add the ID.

### 🐾 Pets
7 eggs, 28 pets in 5 rarities, hatch animation, pets follow you around.

### 💎 Gems, 🎁 rewards, ♻️ rebirth, ⚔️ PvP
- Gem Shop: Auto-Slap, pet slots, storage, 2x Slaps, 2x Damage, Egg Luck
- Daily reward with 7-day streak, 3 daily quests
- Codes: `GYATT`, `SLAP`, `RELEASE`, `BIGHAND`, `LUCKY`
- Rebirth for permanent bonuses
- PvP slap arena, global leaderboards, teleport menu, tutorial arrow, settings and stats
- All purchases and slaps are checked on the server (no cheating)
- Works on PC, phone and tablet

## ✏️ Changing values

Everything is in `src/shared/Config.lua`. Then rebuild the place file:

```
python3 tools/build_place.py
```
