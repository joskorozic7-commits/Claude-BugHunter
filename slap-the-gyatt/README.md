# 👋 Slap the Blob 6.0

A complete, family-friendly Roblox simulator game: slap the Blobs, collect **Slaps** and **Gems**,
upgrade your hand, hatch pets, collect items, unlock 37 worlds in 7 dimensions and become the strongest!

## 🚀 How to start

1. Download **`SlapTheBlob.rbxlx`**.
2. Open it in Roblox Studio (double-click, or *File → Open*).
3. Press **▶ Play**. Done!

The whole world (about 2100 parts), all Blobs, eggs, menus and effects are built by
the scripts when the game starts. You don't need to build anything yourself.

**Saving in Studio:** publish the game and turn on
*Game Settings → Security → Enable Studio Access to API Services*.
Without that everything works, only progress isn't saved.

With Rojo: `rojo serve` (the `default.project.json` is in this folder).

## 🆕 New in 6.0

- **Clean screen:** a slim Slaps/Gems bar at the top and one narrow, collapsible menu column on the left (◀ / ☰). On phones it starts collapsed. During duels only the duel bar and Dash button are shown, and pets of duelling players are hidden.
- **Shop kiosks in the hub:** walk up to the stalls (Upgrades, Gloves, Egg Shop, Item Crates, Gem Shop, Forge) and press E. Smaller kiosks also stand at every dimension landing. The 🛒 Shop button opens all shops from anywhere.
- **Better PvP:** flat arenas without posts or orbs (clear view), combo counter, **⚡ Dash Strikes** (slap within 0.6 s after a dash for ×1.5 damage and extra knockback), glove trails on every swing.
- **Bigger map:** zones are now 160 × 200 studs (were 120 × 130), so targets have space. Every zone gets a 5th target, the **🪅 Piñata**, which drops lots of items.
- **New dimension "The Beyond" (zones 31–37):** Gravity Garden (low gravity), Glacier Slide (ice), Bounce Castle (bounce pads), Hyper Highway (turbo pads), Eclipse Valley (darkness), Titan's Core (heavy gravity), Tempest Peak (wind gusts).
- **75 items in 3 categories (25 each):** hats, wings/backs and auras. They show on your character and give Damage, Slaps, Walk Speed, Crit Luck or Gems. Rarities from Common to **Ultra Master**. They drop from targets (each kind has its own drop rate), come from crates (Slaps, Gems or R$100–R$10,000) and from rebirths. **Merge** 3 identical items in the Forge for +1 star (up to 5 ★).
- **306 pets, 8 rarities** (new: Ultra and Ultra Master), more pet slots (4 base, up to 10), gem eggs (Diamond, Mythic), **Robux eggs R$100–R$1000** and a **weekly event egg** with 6 exclusive pets that changes every week.
- **New hatch animation:** light rays, glow, flash, card flip, bounce and confetti.
- **Deeper upgrades:** 🦵 Legs (walk speed) and 🦘 Jump. Rebirth now needs Zone 3, costs more, and gives bigger bonuses plus a bonus item.
- **Top 3 podium** with the players' avatars next to the leaderboards.
- **Developer products to create** (see the list in the delivery message): 4 Robux eggs and 7 Robux crates. While their `ProductId` is `0` they are free in Studio only.

## 🆕 New in 5.0

- **30 worlds in 6 dimensions:** Overworld (1-6), The Rift (7-10), Elemental Realm (11-15), Mythic Realm (16-20), Cosmic Realm (21-25) and The Infinite (26-30). Each dimension ends with a portal to the next one, and every new world has its own targets, a treasure chest, an egg and 6 pets (192 pets in total).
- **Much harder progression:** zone prices grow x25 per zone and target HP x4 per zone (zones 2-10 got 3x more expensive and 2x tougher). From zone 11 on, every unlocked zone gives x3 damage, so the late game stays possible but takes real time.
- **Phone-friendly duels:** during a duel the Slaps panel, menu buttons, boosts and banners are hidden. Only the duel bar and the Dash button stay. The whole HUD scales down on small screens.
- **Performance:** fewer decorations in the far worlds, and outlines only on nearby targets.

## 🆕 New in 4.0

- **10 worlds in 2 dimensions:** at the end of the Overworld a portal leads into **The Rift** (Candy, Cyber, Shadow and Void Rift), each with its own decor, background and lighting.
- **More than Blobs:** slap Training Dummies, Slime Cubes, Robots, Ghosts, Golems and **Treasure Chests** (lots of Gems).
- **Tiered upgrades:** every 10 levels you need a **⚡ TIER UP** (Slaps + Gems). Tiers: Bronze → Silver → Gold → Platinum → Diamond → Ruby → Mythic → Celestial → Cosmic → Infinite, each with a bigger multiplier.
- **75 gloves:** 60 gloves for Slaps (#60 takes real time), 4 Gem gloves and **11 Robux gloves from R$10 to R$5000**.
- **72 pets from 12 eggs** with lower drop rates (Legendary ~0.35%, Mythic 0.05%, **Secret** 0.002%), 24 body types and animations (wings flap, pets hop, swim, tentacles wave, auras).
- **Pet trading:** request → both pick pets → Ready → 3 s countdown → Confirm. Checked on the server.
- **Duels:** slap someone in the Duel Zone and you both get teleported to a floating arena: HP bars, countdown, crits, combos, dash (Q) with dodge, knockback & ring-outs, 60 s timer, Gem rewards.
- **Buy Gems with Robux:** 6 packs from R$49 to R$3000, with safe receipt handling (never lost, never granted twice).

### Robux setup (Game Passes & Developer Products)
All IDs go into `src/shared/Config.lua` (or the `Config` ModuleScript in Studio):
- **Gloves** (Game Passes, `GamePassId`): Starter Slapper R$10, Bubblegum R$25, Lucky Clover R$49, Thunder Fist R$99, Shadow Claw R$199, Titan Gauntlet R$299, Phantom R$499, Dragon Emperor R$999, Ultra God R$1999, Cosmic Overlord R$2999, OMNI R$5000.
- **Gem packs** (Developer Products, `ProductId`): 150 💎 R$49, 400 💎 R$99, 1000 💎 R$199, 2500 💎 R$449, 6500 💎 R$999, 22000 💎 R$3000.
While an ID is `0`, the item is free **in Studio only** (for testing).

## 🎮 What's inside

### The Blobs
Round cartoon blob monsters with big eyes, eyebrows, blushing cheeks and little feet.
They bounce, turn toward you, get a shocked "O" mouth and wobble when you slap them.
Accessories: bow, sunglasses, cowboy hat, scarf, devil horns, halo, alien antennas, crown.

### 6 worlds with 12 Blobs
| Zone | Blobs | Decor & background |
|---|---|---|
| 1 Blob Meadow | Baby Blob, Big Blob | trees, flowers, green mountains with snow caps |
| 2 Blob Desert | Cactus Blob, Pharaoh Blob | cacti, palms, pyramids, red mesas and dunes |
| 3 Blob Ice Land | Snow Blob, Frost Blob | ice spikes, pines, snowmen, icy mountains |
| 4 Blob Volcano | Magma Blob, Inferno Blob | lava pools, volcanoes with fire, dark smoky sky |
| 5 Blob Cloud Heaven | Angel Blob, Heaven Blob | clouds, gold pillars, rainbow, floating cloud temples |
| 6 Blob Galaxy | Alien Blob, BLOB GOD | stars, planets, crystals, floating asteroids, night sky |

### 🌄 Background
Sky with sun, moon and stars, real moving clouds, ground and mountains all around the map,
and a giant **Mount Blob** statue behind the spawn. Light, clouds and mood change per zone.

### ⭐ Golden Blob (event)
Every 4–7 minutes a Golden Blob appears with huge rewards and Gems, with a countdown banner.

### ✋ 12 hands, 🛒 6 upgrades
Wood → Stone → Iron → Gold → Emerald → Diamond → Frost → Lava → Cloud → Galaxy → Rainbow → **Blob God Hand**.
Upgrades: Hand Power, Slap Speed, Reach, Crit Luck, Slap Greed, Combo Master (with "Buy MAX").
Crits (x3), rare MEGA crits (x30) and a combo system up to +225 % Slaps.

### 👑 Legendary hands
| Hand | Price | Power |
|---|---|---|
| Blob God Hand | 💎 2,500 | x100 damage, x1.25 Slaps |
| Dragon Claw | 💎 6,000 | x180 damage, x1.5 Slaps, +5% crit, claws + dragon fire |
| **Titan Gauntlet** | **R$ 299** | x500 damage, x3 Slaps, +10% crit, +5 reach, +25% speed, **🫰 SNAP: 5% chance to erase a Blob instantly**, 6 cosmic stones |
| **ULTRA GOD HAND** | **R$ 1999** | x2500 damage, x10 Slaps, +25% crit, +15 reach, +100% speed, **⚡ DIVINE SMITE every 5th slap (x25, hits all Blobs nearby)** + 10% SNAP, rainbow halo |

#### Setting up the Robux hands (Game Passes)
Robux items must be created on the Roblox website, the code only needs their ID:
1. Publish the game, then go to **create.roblox.com → your game → Monetization → Passes → Create a Pass**.
2. Create "Titan Gauntlet", set **Item for Sale** to on and the price to **299**.
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
- Codes: `BLOB`, `SLAP`, `RELEASE`, `BIGHAND`, `LUCKY`
- Rebirth for permanent bonuses
- PvP slap arena, global leaderboards, teleport menu, tutorial arrow, settings and stats
- All purchases and slaps are checked on the server (no cheating)
- Works on PC, phone and tablet

## ✏️ Changing values

Everything is in `src/shared/Config.lua`. Then rebuild the place file:

```
python3 tools/build_place.py
```

## 🎨 Store art
`marketing/` contains the icon (512×512), two thumbnails (1920×1080) and the two game pass images.
Re-draw them with `python3 tools/make_art.py` (needs Pillow).
