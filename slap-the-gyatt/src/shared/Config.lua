--[[
	SlapShared/Config  (ModuleScript)

	ALLE Spielwerte von "Slap the Blob" an einem Ort.
	Keine Roblox-APIs hier drin -> funktioniert auf Server und Client gleich.
	Farben sind { R, G, B } Tabellen (0-255).
]]

local Config = {}

Config.GameName = "Slap the Blob"
Config.Version = "4.0"

--------------------------------------------------------------------------
-- Speichern
--------------------------------------------------------------------------
Config.DataStoreName = "SlapTheGyatt_Data_v2"
Config.LeaderboardSlapsStore = "SlapTheGyatt_TopEarned_v2"
Config.LeaderboardRebirthStore = "SlapTheGyatt_TopRebirths_v2"
Config.AutosaveInterval = 120 -- Sekunden
Config.LeaderboardRefresh = 90 -- Sekunden

--------------------------------------------------------------------------
-- Kampf
--------------------------------------------------------------------------
Config.CritMultiplier = 3
Config.MegaCritChance = 0.02 -- Chance, dass ein Krit ein MEGA-Krit wird
Config.MegaCritMultiplier = 10
Config.ComboWindow = 1.6 -- Sekunden, bis die Combo abbricht
Config.ComboBonusPerStack = 0.01 -- +1% Slaps pro Combo-Stufe
Config.GyattRespawnTime = 4
Config.AutoSlapSlowdown = 1.35 -- Auto-Slap ist etwas langsamer als Klicken

--------------------------------------------------------------------------
-- Rebirth
--------------------------------------------------------------------------
Config.RebirthBaseCost = 250000
Config.RebirthCostGrowth = 3.5
Config.RebirthSlapBonus = 0.5 -- +50% Slaps pro Rebirth
Config.RebirthDamageBonus = 0.25 -- +25% Schaden pro Rebirth
Config.RebirthGems = 25 -- Gems pro Rebirth (mal Rebirth-Nummer)

--------------------------------------------------------------------------
-- Upgrades (mit Slaps kaufen, werden bei Rebirth zurueckgesetzt)
-- Alle 10 Level kommt ein TIER-UP: teuer (Slaps + Gems), aber jede neue
-- Stufe gibt einen viel groesseren Multiplikator als die letzte.
--------------------------------------------------------------------------
Config.UpgradeOrder = { "Power", "Speed", "Reach", "Luck", "Greed", "Combo" }

Config.TierSize = 10 -- Level pro Tier
Config.TierCostGrowth = 4 -- jede Tier macht alle Level 4x teurer
Config.TierUpCostMultiplier = 12 -- der Tier-Up-Kauf selbst kostet 12x
Config.TierUpGems = 15 -- Gems fuer Tier-Up = 15 * Tier^2
Config.Tiers = {
	{ Name = "Bronze", Color = { 205, 127, 50 }, Multiplier = 1 },
	{ Name = "Silver", Color = { 200, 205, 215 }, Multiplier = 1.6 },
	{ Name = "Gold", Color = { 255, 200, 40 }, Multiplier = 2.8 },
	{ Name = "Platinum", Color = { 160, 230, 230 }, Multiplier = 5 },
	{ Name = "Diamond", Color = { 120, 220, 255 }, Multiplier = 9 },
	{ Name = "Ruby", Color = { 255, 60, 90 }, Multiplier = 16 },
	{ Name = "Mythic", Color = { 255, 60, 180 }, Multiplier = 30 },
	{ Name = "Celestial", Color = { 180, 150, 255 }, Multiplier = 55 },
	{ Name = "Cosmic", Color = { 120, 80, 255 }, Multiplier = 100 },
	{ Name = "Infinite", Color = { 255, 255, 255 }, Multiplier = 200 },
	{ Name = "Infinite+", Color = { 255, 255, 255 }, Multiplier = 400 },
}

Config.Upgrades = {
	Power = { DisplayName = "Hand Power", Icon = "💪", Description = "More damage per slap - and your hand grows!", MaxLevel = 100, BaseCost = 15, CostGrowth = 1.28 },
	Speed = { DisplayName = "Slap Speed", Icon = "⚡", Description = "Shorter wait between slaps.", MaxLevel = 40, BaseCost = 40, CostGrowth = 1.42 },
	Reach = { DisplayName = "Reach", Icon = "📏", Description = "Hit targets from farther away.", MaxLevel = 30, BaseCost = 60, CostGrowth = 1.5 },
	Luck = { DisplayName = "Crit Luck", Icon = "🍀", Description = "Higher chance for critical slaps (x3 damage).", MaxLevel = 50, BaseCost = 100, CostGrowth = 1.38 },
	Greed = { DisplayName = "Slap Greed", Icon = "💰", Description = "More Slaps for every hit.", MaxLevel = 100, BaseCost = 150, CostGrowth = 1.3 },
	Combo = { DisplayName = "Combo Master", Icon = "🔥", Description = "Higher max combo = more bonus Slaps.", MaxLevel = 40, BaseCost = 500, CostGrowth = 1.5 },
}

--------------------------------------------------------------------------
-- Handschuhe / Haende (permanent, bleiben nach Rebirth)
--   Effect: none, sparkles, fire, smoke, rainbow, aura, electric, shadow,
--           orbit, dragon, thanos, ultragod, omni
--------------------------------------------------------------------------
Config.Hands = {}

-- 60 Handschuhe fuer Slaps: 20 Materialien x 3 Stufen (normal, Reinforced, Mega).
-- Jeder ist etwa 16% staerker und etwa doppelt so teuer wie der davor.
local GLOVE_MATERIALS = {
	{ "Wood", { 165, 115, 70 }, "Wood" },
	{ "Stone", { 125, 125, 130 }, "Slate" },
	{ "Copper", { 200, 120, 70 }, "Metal" },
	{ "Iron", { 195, 200, 210 }, "DiamondPlate" },
	{ "Bronze", { 205, 140, 60 }, "Foil" },
	{ "Silver", { 220, 225, 235 }, "Foil" },
	{ "Gold", { 255, 200, 40 }, "Foil" },
	{ "Jade", { 60, 190, 120 }, "Marble" },
	{ "Ruby", { 230, 40, 70 }, "Glass" },
	{ "Sapphire", { 40, 100, 230 }, "Glass" },
	{ "Emerald", { 40, 220, 110 }, "Glass" },
	{ "Amethyst", { 160, 80, 230 }, "Glass" },
	{ "Diamond", { 120, 230, 255 }, "Glass" },
	{ "Obsidian", { 45, 30, 60 }, "Glass" },
	{ "Frost", { 190, 235, 255 }, "Ice" },
	{ "Lava", { 255, 110, 20 }, "Neon" },
	{ "Thunder", { 255, 240, 90 }, "Neon" },
	{ "Shadow", { 70, 25, 110 }, "Neon" },
	{ "Galaxy", { 120, 50, 220 }, "Neon" },
	{ "Rainbow", { 255, 80, 200 }, "Neon" },
}
local GLOVE_GRADES = { "", "Reinforced ", "Mega " }
local SPECIAL_BASE_EFFECT = { Frost = "smoke", Lava = "fire", Thunder = "electric", Shadow = "shadow", Rainbow = "rainbow" }
do
	local index = 0
	for _, mat in ipairs(GLOVE_MATERIALS) do
		for grade = 1, 3 do
			index = index + 1
			local effect = SPECIAL_BASE_EFFECT[mat[1]] or "none"
			if grade == 2 and effect == "none" then
				effect = "sparkles"
			elseif grade == 3 then
				effect = (mat[1] == "Rainbow") and "rainbow" or "aura"
			end
			local rarity = "Common"
			if index > 48 then
				rarity = "Mythic"
			elseif index > 36 then
				rarity = "Legendary"
			elseif index > 24 then
				rarity = "Epic"
			elseif index > 12 then
				rarity = "Rare"
			end
			local damage = math.floor((1.165 ^ (index - 1)) * 100 + 0.5) / 100
			local price = 0
			if index > 1 then
				price = math.floor(300 * (2.05 ^ (index - 2)))
			end
			table.insert(Config.Hands, {
				Id = string.format("G%02d", index),
				Number = index,
				DisplayName = GLOVE_GRADES[grade] .. mat[1] .. " Glove",
				Rarity = rarity,
				Damage = damage,
				Price = price,
				Currency = "Slaps",
				Color = mat[2],
				Material = mat[3],
				Effect = effect,
			})
		end
	end
end

-- Gem-Handschuhe
local GEM_GLOVES = {
	{ Id = "GyattGod", DisplayName = "Blob God Hand", Rarity = "Legendary", Damage = 120, Price = 2500, Currency = "Gems", Color = { 255, 235, 120 }, Material = "Neon", Effect = "fire",
		SlapMultiplier = 1.25 },
	{ Id = "DragonClaw", DisplayName = "Dragon Claw", Rarity = "Mythic", Damage = 400, Price = 6000, Currency = "Gems", Color = { 200, 30, 40 }, Material = "Neon", Effect = "dragon",
		SlapMultiplier = 1.5, CritBonus = 0.05 },
	{ Id = "PhoenixTalon", DisplayName = "Phoenix Talon", Rarity = "Mythic", Damage = 1500, Price = 15000, Currency = "Gems", Color = { 255, 140, 30 }, Material = "Neon", Effect = "aura",
		SlapMultiplier = 2, CritBonus = 0.05 },
	{ Id = "StarForge", DisplayName = "Star Forge Gauntlet", Rarity = "Mythic", Damage = 5000, Price = 40000, Currency = "Gems", Color = { 90, 200, 255 }, Material = "Neon", Effect = "orbit",
		SlapMultiplier = 3, CritBonus = 0.08, ReachBonus = 4 },
}
for _, glove in ipairs(GEM_GLOVES) do
	table.insert(Config.Hands, glove)
end

-- ROBUX-HANDSCHUHE (Game Passes, R$10 bis R$5000). So richtest du sie ein:
--   1. create.roblox.com -> dein Spiel -> Monetization -> Passes -> "Create a Pass"
--   2. Preis einstellen (siehe Price) und "Item for Sale" anschalten
--   3. Die Pass-ID hier bei GamePassId eintragen
-- Solange GamePassId = 0 ist, kann man die Hand nur in Studio zum Testen kostenlos benutzen.
local ROBUX_GLOVES = {
	{ Id = "Starter", DisplayName = "Starter Slapper", Damage = 4, Price = 10, GamePassId = 0, Color = { 120, 200, 255 }, Material = "SmoothPlastic", Effect = "sparkles",
		SlapMultiplier = 1.2 },
	{ Id = "Bubblegum", DisplayName = "Bubblegum Glove", Damage = 12, Price = 25, GamePassId = 0, Color = { 255, 140, 210 }, Material = "SmoothPlastic", Effect = "sparkles",
		SlapMultiplier = 1.3 },
	{ Id = "Clover", DisplayName = "Lucky Clover Glove", Damage = 30, Price = 49, GamePassId = 0, Color = { 60, 210, 90 }, Material = "Neon", Effect = "aura",
		SlapMultiplier = 1.5, CritBonus = 0.05 },
	{ Id = "ThunderFist", DisplayName = "Thunder Fist", Damage = 80, Price = 99, GamePassId = 0, Color = { 255, 235, 80 }, Material = "Neon", Effect = "electric",
		SlapMultiplier = 2, SpeedMultiplier = 0.9 },
	{ Id = "ShadowClaw", DisplayName = "Shadow Claw", Damage = 200, Price = 199, GamePassId = 0, Color = { 80, 20, 130 }, Material = "Neon", Effect = "shadow",
		SlapMultiplier = 2.5, CritBonus = 0.08 },
	{ Id = "Thanos", DisplayName = "Titan Gauntlet", Damage = 500, Price = 299, GamePassId = 0, Color = { 220, 170, 40 }, Material = "Foil", Effect = "thanos",
		SlapMultiplier = 3, CritBonus = 0.1, ReachBonus = 5, SpeedMultiplier = 0.8, Snap = 0.05,
		Perk = "🫰 SNAP: 5% chance to erase a target instantly" },
	{ Id = "Phantom", DisplayName = "Phantom Glove", Damage = 900, Price = 499, GamePassId = 0, Color = { 170, 120, 255 }, Material = "Neon", Effect = "orbit",
		SlapMultiplier = 4, CritBonus = 0.1, ReachBonus = 8, Snap = 0.03,
		Perk = "👻 Phantom reach + 3% SNAP" },
	{ Id = "DragonEmperor", DisplayName = "Dragon Emperor", Damage = 1600, Price = 999, GamePassId = 0, Color = { 220, 30, 30 }, Material = "Neon", Effect = "dragon",
		SlapMultiplier = 6, CritBonus = 0.15, ReachBonus = 8, SpeedMultiplier = 0.75,
		Smite = { Every = 8, Multiplier = 10, Radius = 30 },
		Perk = "🐉 DRAGON BREATH: every 8th slap burns all targets nearby (x10)" },
	{ Id = "UltraGod", DisplayName = "ULTRA GOD HAND", Damage = 3000, Price = 1999, GamePassId = 0, Color = { 255, 250, 220 }, Material = "Neon", Effect = "ultragod",
		SlapMultiplier = 10, CritBonus = 0.25, ReachBonus = 15, SpeedMultiplier = 0.5, Snap = 0.1,
		Smite = { Every = 5, Multiplier = 25, Radius = 45 },
		Perk = "⚡ DIVINE SMITE: every 5th slap strikes lightning (x25, area) + 10% SNAP" },
	{ Id = "CosmicOverlord", DisplayName = "Cosmic Overlord", Damage = 5000, Price = 2999, GamePassId = 0, Color = { 90, 60, 255 }, Material = "Neon", Effect = "orbit",
		SlapMultiplier = 15, CritBonus = 0.3, ReachBonus = 18, SpeedMultiplier = 0.45, Snap = 0.1,
		Smite = { Every = 5, Multiplier = 30, Radius = 50 },
		Perk = "🌌 COSMIC STORM: every 5th slap (x30, area) + 10% SNAP" },
	{ Id = "Omni", DisplayName = "OMNI GLOVE", Damage = 10000, Price = 5000, GamePassId = 0, Color = { 255, 255, 255 }, Material = "Neon", Effect = "omni",
		SlapMultiplier = 25, CritBonus = 0.35, ReachBonus = 20, SpeedMultiplier = 0.4, Snap = 0.12,
		Smite = { Every = 4, Multiplier = 40, Radius = 60 },
		Perk = "♾️ OMNI POWER: every 4th slap (x40, huge area) + 12% SNAP" },
}
for _, glove in ipairs(ROBUX_GLOVES) do
	glove.Currency = "Robux"
	glove.Rarity = "Ultra"
	table.insert(Config.Hands, glove)
end

--------------------------------------------------------------------------
-- Seltenheiten
--------------------------------------------------------------------------
Config.RarityOrder = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Secret" }
Config.Rarities = {
	Common = { DisplayName = "Common", Color = { 200, 200, 200 }, Order = 1 },
	Rare = { DisplayName = "Rare", Color = { 80, 170, 255 }, Order = 2 },
	Epic = { DisplayName = "Epic", Color = { 190, 90, 255 }, Order = 3 },
	Legendary = { DisplayName = "Legendary", Color = { 255, 190, 40 }, Order = 4 },
	Mythic = { DisplayName = "Mythic", Color = { 255, 60, 120 }, Order = 5 },
	Ultra = { DisplayName = "ULTRA", Color = { 255, 240, 120 }, Order = 6 },
	Secret = { DisplayName = "SECRET", Color = { 255, 255, 255 }, Order = 7 },
}

--------------------------------------------------------------------------
-- Eier und Pets
-- Jedes Ei hat 6 Pets. Boost = Bonus auf Slaps (+Boost, 0.5 = +50%).
-- Style bestimmt Aussehen und Animation des Pets.
--------------------------------------------------------------------------
Config.Pets = {}
Config.Eggs = {}

-- Gewichte der 6 Plaetze in einem normalen Zonen-Ei (Summe = 100)
local ZONE_EGG_SLOTS = {
	{ Rarity = "Common", Weight = 62, Factor = 1 },
	{ Rarity = "Common", Weight = 28, Factor = 1.4 },
	{ Rarity = "Rare", Weight = 8, Factor = 3 },
	{ Rarity = "Epic", Weight = 1.6, Factor = 7 },
	{ Rarity = "Legendary", Weight = 0.35, Factor = 18 },
	{ Rarity = "Mythic", Weight = 0.05, Factor = 50 },
}
local GOLDEN_EGG_SLOTS = {
	{ Rarity = "Rare", Weight = 62, Factor = 3 },
	{ Rarity = "Rare", Weight = 28, Factor = 4 },
	{ Rarity = "Epic", Weight = 8, Factor = 9 },
	{ Rarity = "Legendary", Weight = 1.75, Factor = 24 },
	{ Rarity = "Mythic", Weight = 0.248, Factor = 70 },
	{ Rarity = "Secret", Weight = 0.002, Factor = 1000 },
}
local CELESTIAL_EGG_SLOTS = {
	{ Rarity = "Epic", Weight = 60, Factor = 7 },
	{ Rarity = "Epic", Weight = 30, Factor = 9 },
	{ Rarity = "Legendary", Weight = 8, Factor = 20 },
	{ Rarity = "Mythic", Weight = 1.7, Factor = 55 },
	{ Rarity = "Mythic", Weight = 0.29, Factor = 80 },
	{ Rarity = "Secret", Weight = 0.01, Factor = 1000 },
}

-- { EggId, Name, Preis, Waehrung, Farbe, Zone, Basis-Boost, Slots, { {PetName, Style, Farbe}, ... x6 } }
local EGG_DEFS = {
	{ "Basic", "Meadow Egg", 250, "Slaps", { 255, 240, 200 }, 1, 0.12, ZONE_EGG_SLOTS, {
		{ "Puppy", "dog", { 200, 150, 100 } }, { "Kitty", "cat", { 255, 170, 80 } }, { "Bunny", "bunny", { 255, 255, 255 } },
		{ "Fox", "fox", { 255, 130, 40 } }, { "Wise Owl", "owl", { 150, 110, 80 } }, { "Rainbow Unicorn", "unicorn", { 255, 200, 240 } } } },
	{ "Desert", "Desert Egg", 15000, "Slaps", { 240, 200, 120 }, 2, 0.38, ZONE_EGG_SLOTS, {
		{ "Camel", "bear", { 210, 170, 110 } }, { "Desert Frog", "frog", { 200, 180, 90 } }, { "Fennec", "fox", { 240, 200, 140 } },
		{ "Scarab", "bee", { 60, 160, 120 } }, { "Sphinx", "cat", { 230, 190, 80 } }, { "Pharaoh Dragon", "dragon", { 240, 200, 60 } } } },
	{ "Ice", "Ice Egg", 1000000, "Slaps", { 190, 230, 255 }, 3, 1.2, ZONE_EGG_SLOTS, {
		{ "Penguin", "bird", { 40, 40, 60 } }, { "Seal", "slime", { 200, 210, 220 } }, { "Polar Bear", "bear", { 240, 245, 255 } },
		{ "Ice Panda", "panda", { 230, 245, 255 } }, { "Yeti", "golem", { 200, 230, 255 } }, { "Frost Dragon", "dragon", { 120, 200, 255 } } } },
	{ "Lava", "Lava Egg", 60000000, "Slaps", { 255, 100, 40 }, 4, 3.9, ZONE_EGG_SLOTS, {
		{ "Fire Slime", "slime", { 255, 120, 30 } }, { "Magma Dog", "dog", { 200, 50, 20 } }, { "Lava Turtle", "turtle", { 120, 60, 40 } },
		{ "Ember Bat", "bat", { 255, 90, 40 } }, { "Phoenix", "bird", { 255, 170, 30 } }, { "Inferno Dino", "dino", { 220, 40, 20 } } } },
	{ "Cloud", "Cloud Egg", 5000000000, "Slaps", { 250, 250, 255 }, 5, 12.5, ZONE_EGG_SLOTS, {
		{ "Cloud Sheep", "slime", { 250, 250, 255 } }, { "Sky Bunny", "bunny", { 200, 230, 255 } }, { "Angel Cat", "cat", { 255, 240, 200 } },
		{ "Storm Owl", "owl", { 150, 160, 200 } }, { "Pegasus", "unicorn", { 240, 245, 255 } }, { "Sky Dragon", "dragon", { 150, 220, 255 } } } },
	{ "Galaxy", "Galaxy Egg", 400000000000, "Slaps", { 110, 60, 200 }, 6, 40, ZONE_EGG_SLOTS, {
		{ "Alien", "alien", { 120, 255, 120 } }, { "Moon Frog", "frog", { 180, 180, 220 } }, { "Robo Dog", "robot", { 170, 180, 200 } },
		{ "Star Jelly", "jelly", { 120, 160, 255 } }, { "Star Whale", "whale", { 60, 80, 200 } }, { "Galaxy Kraken", "octopus", { 150, 60, 220 } } } },
	{ "Candy", "Candy Egg", 30000000000000, "Slaps", { 255, 160, 210 }, 7, 128, ZONE_EGG_SLOTS, {
		{ "Gummy Bear", "bear", { 255, 90, 120 } }, { "Candy Bunny", "bunny", { 255, 190, 230 } }, { "Lollipop Slime", "slime", { 255, 120, 200 } },
		{ "Cupcake Cat", "cat", { 255, 220, 170 } }, { "Candy Dragon", "dragon", { 255, 110, 190 } }, { "Sugar Unicorn", "unicorn", { 255, 230, 250 } } } },
	{ "Cyber", "Cyber Egg", 2000000000000000, "Slaps", { 60, 255, 230 }, 8, 410, ZONE_EGG_SLOTS, {
		{ "Robo Cat", "robot", { 120, 200, 255 } }, { "Pixel Frog", "frog", { 60, 255, 120 } }, { "Cyber Fox", "fox", { 0, 230, 255 } },
		{ "Mecha Shark", "shark", { 120, 130, 160 } }, { "Neon Dino", "dino", { 255, 0, 200 } }, { "Cyber Golem", "golem", { 40, 255, 220 } } } },
	{ "Shadow", "Shadow Egg", 150000000000000000, "Slaps", { 90, 40, 140 }, 9, 1300, ZONE_EGG_SLOTS, {
		{ "Shadow Bat", "bat", { 60, 30, 90 } }, { "Gloom Slime", "slime", { 90, 50, 130 } }, { "Phantom Cat", "ghost", { 170, 140, 220 } },
		{ "Void Wolf", "dog", { 50, 40, 80 } }, { "Nightmare Owl", "owl", { 80, 40, 120 } }, { "Shadow Dragon", "dragon", { 70, 20, 110 } } } },
	{ "Void", "Void Egg", 12000000000000000000, "Slaps", { 30, 10, 50 }, 10, 4200, ZONE_EGG_SLOTS, {
		{ "Void Jelly", "jelly", { 140, 60, 255 } }, { "Rift Turtle", "turtle", { 60, 30, 100 } }, { "Abyss Shark", "shark", { 30, 20, 60 } },
		{ "Void Octopus", "octopus", { 100, 30, 180 } }, { "Void Golem", "golem", { 50, 20, 90 } }, { "Void Emperor", "dragon", { 20, 10, 40 } } } },
	{ "Golden", "Golden Egg", 75, "Gems", { 255, 210, 40 }, 1, 1, GOLDEN_EGG_SLOTS, {
		{ "Golden Dog", "dog", { 255, 210, 50 } }, { "Golden Cat", "cat", { 255, 200, 30 } }, { "Golden Panda", "panda", { 255, 220, 90 } },
		{ "Golden Dragon", "dragon", { 255, 215, 0 } }, { "Golden Unicorn", "unicorn", { 255, 230, 120 } }, { "Blob God", "ghost", { 255, 220, 90 } } } },
	{ "Celestial", "Celestial Egg", 600, "Gems", { 160, 140, 255 }, 1, 20, CELESTIAL_EGG_SLOTS, {
		{ "Comet Bee", "bee", { 255, 230, 120 } }, { "Nebula Fox", "fox", { 200, 100, 255 } }, { "Celestial Whale", "whale", { 120, 140, 255 } },
		{ "Astral Phoenix", "bird", { 255, 120, 220 } }, { "Cosmic Kraken", "octopus", { 90, 60, 255 } }, { "The Creator", "ghost", { 255, 255, 255 } } } },
}

Config.EggOrder = {}
for _, def in ipairs(EGG_DEFS) do
	local eggId, eggName, price, currency, color, zone, baseBoost, slots, pets = def[1], def[2], def[3], def[4], def[5], def[6], def[7], def[8], def[9]
	local entries = {}
	for i, slot in ipairs(slots) do
		local petDef = pets[i]
		local petId = eggId .. "_" .. i
		local boost = baseBoost * slot.Factor
		if boost >= 10 then
			boost = math.floor(boost)
		else
			boost = math.floor(boost * 100 + 0.5) / 100
		end
		Config.Pets[petId] = { DisplayName = petDef[1], Rarity = slot.Rarity, Boost = boost, Color = petDef[3], Style = petDef[2], Egg = eggId }
		table.insert(entries, { petId, slot.Weight })
	end
	Config.Eggs[eggId] = { DisplayName = eggName, Price = price, Currency = currency, Color = color, Zone = zone, Pets = entries }
	table.insert(Config.EggOrder, eggId)
end

Config.BasePetSlots = 3
Config.BaseInventory = 40
Config.LuckyBoostFactor = 2.5 -- Gewicht seltener Pets mit Glueck-Boost

--------------------------------------------------------------------------
-- Zonen. Jede Zone hat mehrere Ziele zum Slappen und ein Ei.
--   Kind: "blob" (Standard), "cube", "dummy", "robot", "ghost", "golem", "chest"
--   Decor: meadow, desert, ice, lava, cloud, space, candy, cyber, shadow, void
--   Accessories (nur Blobs): bow, glasses, cowboy, scarf, horns, halo, antenna, crown
--------------------------------------------------------------------------
Config.ZoneLength = 130
Config.ZoneWidth = 120

-- Dimensionen: am Ende der Oberwelt fuehrt ein Portal in die Rift-Dimension.
Config.Dimensions = {
	{ Name = "Overworld", FirstZone = 1, LastZone = 6, StartZ = 0 },
	{ Name = "The Rift", FirstZone = 7, LastZone = 10, StartZ = 1500 },
}
Config.DimensionLandingLength = 70 -- Plattform vor der ersten Zone einer Dimension

local function chest(health, gems, color)
	return { Id = "Chest", Kind = "chest", DisplayName = "Treasure Chest", MaxHealth = health, Size = 5, Color = color or { 150, 95, 50 },
		RewardMultiplier = 1, Gems = gems, Respawn = 60 }
end

Config.Zones = {
	{
		Name = "Blob Meadow", Price = 0, Decor = "meadow",
		Floor = { 105, 200, 105 }, FloorMaterial = "Grass", Accent = { 255, 120, 180 }, Path = { 230, 210, 160 },
		Egg = "Basic", ExtraEgg = "Golden", ExtraEgg2 = "Celestial",
		Gyatts = {
			{ Id = "Baby", DisplayName = "Baby Blob", MaxHealth = 40, Size = 7, Color = { 255, 175, 205 }, RewardMultiplier = 1, Gems = 1, Accessories = { "bow" } },
			{ Id = "Big", DisplayName = "Big Blob", MaxHealth = 400, Size = 11, Color = { 255, 125, 165 }, RewardMultiplier = 2, Gems = 2, Accessories = { "bow", "glasses" } },
			{ Id = "Dummy", Kind = "dummy", DisplayName = "Training Dummy", MaxHealth = 150, Size = 7, Color = { 210, 170, 110 }, RewardMultiplier = 1.5, Gems = 1 },
			chest(120, 6),
		},
	},
	{
		Name = "Blob Desert", Price = 2500, Decor = "desert",
		Floor = { 235, 205, 140 }, FloorMaterial = "Sand", Accent = { 255, 170, 60 }, Path = { 200, 160, 100 },
		Egg = "Desert",
		Gyatts = {
			{ Id = "Cactus", DisplayName = "Cactus Blob", MaxHealth = 4000, Size = 9, Color = { 120, 200, 90 }, RewardMultiplier = 4, Gems = 2, Accessories = { "cowboy" } },
			{ Id = "Pharao", DisplayName = "Pharaoh Blob", MaxHealth = 20000, Size = 13, Color = { 240, 190, 70 }, RewardMultiplier = 8, Gems = 4, Accessories = { "crown", "glasses" } },
			{ Id = "SandCube", Kind = "cube", DisplayName = "Sand Cube", MaxHealth = 10000, Size = 9, Color = { 230, 190, 110 }, RewardMultiplier = 6, Gems = 3 },
			chest(8000, 10),
		},
	},
	{
		Name = "Blob Ice Land", Price = 150000, Decor = "ice",
		Floor = { 225, 240, 255 }, FloorMaterial = "Snow", Accent = { 120, 200, 255 }, Path = { 170, 215, 245 },
		Egg = "Ice",
		Gyatts = {
			{ Id = "Snow", DisplayName = "Snow Blob", MaxHealth = 150000, Size = 10, Color = { 240, 248, 255 }, RewardMultiplier = 15, Gems = 3, Accessories = { "scarf" } },
			{ Id = "Frost", DisplayName = "Frost Blob", MaxHealth = 750000, Size = 15, Color = { 140, 210, 255 }, RewardMultiplier = 30, Gems = 6, Accessories = { "scarf", "crown" } },
			{ Id = "IceGolem", Kind = "golem", DisplayName = "Ice Golem", MaxHealth = 400000, Size = 12, Color = { 150, 220, 255 }, RewardMultiplier = 22, Gems = 5 },
			chest(300000, 14, { 120, 170, 210 }),
		},
	},
	{
		Name = "Blob Volcano", Price = 10000000, Decor = "lava",
		Floor = { 70, 45, 40 }, FloorMaterial = "Basalt", Accent = { 255, 90, 20 }, Path = { 120, 60, 40 },
		Egg = "Lava",
		Gyatts = {
			{ Id = "Magma", DisplayName = "Magma Blob", MaxHealth = 5000000, Size = 11, Color = { 255, 100, 40 }, RewardMultiplier = 60, Gems = 4, Accessories = { "horns" } },
			{ Id = "Inferno", DisplayName = "Inferno Blob", MaxHealth = 25000000, Size = 17, Color = { 200, 30, 20 }, RewardMultiplier = 120, Gems = 8, Accessories = { "horns", "crown" } },
			{ Id = "LavaBot", Kind = "robot", DisplayName = "Lava Bot", MaxHealth = 12000000, Size = 12, Color = { 90, 70, 70 }, RewardMultiplier = 90, Gems = 6 },
			chest(9000000, 18, { 90, 40, 30 }),
		},
	},
	{
		Name = "Blob Cloud Heaven", Price = 750000000, Decor = "cloud",
		Floor = { 245, 245, 255 }, FloorMaterial = "SmoothPlastic", Accent = { 255, 220, 120 }, Path = { 255, 235, 170 },
		Egg = "Cloud",
		Gyatts = {
			{ Id = "Angel", DisplayName = "Angel Blob", MaxHealth = 150000000, Size = 12, Color = { 255, 250, 235 }, RewardMultiplier = 250, Gems = 5, Accessories = { "halo" } },
			{ Id = "Heaven", DisplayName = "Heaven Blob", MaxHealth = 750000000, Size = 18, Color = { 255, 225, 150 }, RewardMultiplier = 500, Gems = 10, Accessories = { "halo", "crown" } },
			{ Id = "CloudGhost", Kind = "ghost", DisplayName = "Cloud Ghost", MaxHealth = 400000000, Size = 11, Color = { 235, 240, 255 }, RewardMultiplier = 380, Gems = 8 },
			chest(300000000, 22, { 240, 230, 200 }),
		},
	},
	{
		Name = "Blob Galaxy", Price = 50000000000, Decor = "space",
		Floor = { 35, 25, 70 }, FloorMaterial = "SmoothPlastic", Accent = { 160, 90, 255 }, Path = { 80, 60, 140 },
		Egg = "Galaxy",
		Gyatts = {
			{ Id = "Alien", DisplayName = "Alien Blob", MaxHealth = 5000000000, Size = 14, Color = { 130, 255, 140 }, RewardMultiplier = 1000, Gems = 6, Accessories = { "antenna" } },
			{ Id = "God", DisplayName = "BLOB GOD", MaxHealth = 25000000000, Size = 24, Color = { 90, 230, 255 }, RewardMultiplier = 2000, Gems = 15, Accessories = { "halo", "crown", "glasses" } },
			{ Id = "SpaceBot", Kind = "robot", DisplayName = "Space Robot", MaxHealth = 12000000000, Size = 14, Color = { 200, 210, 230 }, RewardMultiplier = 1500, Gems = 10 },
			chest(9000000000, 28, { 70, 50, 120 }),
		},
	},
	-- ===================== THE RIFT (Dimension 2) =====================
	{
		Name = "Candy Rift", Price = 5000000000000, Decor = "candy",
		Floor = { 255, 200, 230 }, FloorMaterial = "SmoothPlastic", Accent = { 255, 90, 170 }, Path = { 255, 250, 250 },
		Egg = "Candy",
		Gyatts = {
			{ Id = "Gummy", DisplayName = "Gummy Blob", MaxHealth = 300000000000, Size = 12, Color = { 255, 90, 140 }, RewardMultiplier = 4000, Gems = 8, Accessories = { "bow" } },
			{ Id = "LollipopKing", DisplayName = "King Lollipop Blob", MaxHealth = 2000000000000, Size = 20, Color = { 255, 140, 220 }, RewardMultiplier = 12000, Gems = 18, Accessories = { "crown", "bow" } },
			{ Id = "CandyCube", Kind = "cube", DisplayName = "Candy Cube", MaxHealth = 900000000000, Size = 13, Color = { 120, 220, 255 }, RewardMultiplier = 7000, Gems = 10 },
			chest(700000000000, 35, { 255, 120, 180 }),
		},
	},
	{
		Name = "Cyber Rift", Price = 500000000000000, Decor = "cyber",
		Floor = { 20, 25, 40 }, FloorMaterial = "SmoothPlastic", Accent = { 0, 255, 230 }, Path = { 40, 60, 90 },
		Egg = "Cyber",
		Gyatts = {
			{ Id = "GlitchCube", Kind = "cube", DisplayName = "Glitch Cube", MaxHealth = 8000000000000, Size = 12, Color = { 0, 255, 200 }, RewardMultiplier = 25000, Gems = 10 },
			{ Id = "CyberGod", DisplayName = "Cyber Blob God", MaxHealth = 70000000000000, Size = 22, Color = { 60, 120, 255 }, RewardMultiplier = 80000, Gems = 22, Accessories = { "antenna", "crown", "glasses" } },
			{ Id = "MechaBot", Kind = "robot", DisplayName = "Mecha Bot", MaxHealth = 25000000000000, Size = 15, Color = { 60, 70, 90 }, RewardMultiplier = 45000, Gems = 14 },
			chest(20000000000000, 42, { 40, 60, 90 }),
		},
	},
	{
		Name = "Shadow Rift", Price = 50000000000000000, Decor = "shadow",
		Floor = { 40, 25, 55 }, FloorMaterial = "Slate", Accent = { 170, 60, 255 }, Path = { 70, 45, 90 },
		Egg = "Shadow",
		Gyatts = {
			{ Id = "ShadowGhost", Kind = "ghost", DisplayName = "Shadow Ghost", MaxHealth = 250000000000000, Size = 12, Color = { 90, 60, 140 }, RewardMultiplier = 160000, Gems = 12 },
			{ Id = "Nightmare", DisplayName = "Nightmare Blob", MaxHealth = 2500000000000000, Size = 22, Color = { 60, 20, 90 }, RewardMultiplier = 550000, Gems = 26, Accessories = { "horns", "crown" } },
			{ Id = "ShadowGolem", Kind = "golem", DisplayName = "Shadow Golem", MaxHealth = 800000000000000, Size = 15, Color = { 100, 40, 160 }, RewardMultiplier = 300000, Gems = 16 },
			chest(600000000000000, 50, { 60, 30, 80 }),
		},
	},
	{
		Name = "Void Rift", Price = 5000000000000000000, Decor = "void",
		Floor = { 15, 10, 25 }, FloorMaterial = "Glass", Accent = { 255, 255, 255 }, Path = { 40, 30, 60 },
		Egg = "Void",
		Gyatts = {
			{ Id = "VoidGhost", Kind = "ghost", DisplayName = "Void Ghost", MaxHealth = 9000000000000000, Size = 13, Color = { 30, 20, 50 }, RewardMultiplier = 1100000, Gems = 15 },
			{ Id = "VoidKing", DisplayName = "VOID KING", MaxHealth = 120000000000000000, Size = 30, Color = { 20, 10, 40 }, RewardMultiplier = 4000000, Gems = 50, Accessories = { "halo", "crown", "glasses" } },
			{ Id = "VoidGolem", Kind = "golem", DisplayName = "Void Golem", MaxHealth = 30000000000000000, Size = 16, Color = { 80, 40, 160 }, RewardMultiplier = 2000000, Gems = 20 },
			chest(20000000000000000, 60, { 30, 20, 50 }),
		},
	},
}

-- Goldener Gyatt (Server-Event)
Config.GoldenGyatt = {
	DisplayName = "⭐ GOLDEN BLOB ⭐",
	MinInterval = 240,
	MaxInterval = 420,
	Duration = 90,
	HealthFactor = 6, -- mal Leben des grossen Gyatts der Zone
	RewardFactor = 5,
	Gems = 30,
	Size = 16,
	Color = { 255, 215, 0 },
}

--------------------------------------------------------------------------
-- Gem-Shop
--------------------------------------------------------------------------
Config.GemShop = {
	{ Id = "AutoSlap", DisplayName = "Auto-Slap", Icon = "🤖", Description = "Slaps automatically when you are close to a Blob.", Prices = { 200 } },
	{ Id = "PetSlot", DisplayName = "+1 Pet Slot", Icon = "🐾", Description = "Equip one more pet at the same time.", Prices = { 150, 400, 900 } },
	{ Id = "Inventory", DisplayName = "+20 Pet Storage", Icon = "🎒", Description = "More room for your pets.", Prices = { 80, 200, 450 } },
	{ Id = "DoubleSlaps", DisplayName = "2x Slaps (15 min)", Icon = "⏫", Description = "Double Slaps for 15 minutes.", Prices = { 60 }, Boost = "DoubleSlaps", Duration = 900, Repeatable = true },
	{ Id = "LuckyEggs", DisplayName = "Egg Luck (15 min)", Icon = "🌈", Description = "Rare pets show up much more often.", Prices = { 40 }, Boost = "LuckyEggs", Duration = 900, Repeatable = true },
	{ Id = "DoubleDamage", DisplayName = "2x Damage (15 min)", Icon = "🥊", Description = "Double damage for 15 minutes.", Prices = { 60 }, Boost = "DoubleDamage", Duration = 900, Repeatable = true },
}

Config.Boosts = {
	DoubleSlaps = { DisplayName = "2x Slaps", Icon = "⏫", Color = { 120, 255, 140 } },
	LuckyEggs = { DisplayName = "Egg Luck", Icon = "🌈", Color = { 255, 150, 255 } },
	DoubleDamage = { DisplayName = "2x Damage", Icon = "🥊", Color = { 255, 140, 120 } },
}
Config.BoostOrder = { "DoubleSlaps", "DoubleDamage", "LuckyEggs" }

--------------------------------------------------------------------------
-- Taegliche Belohnung (7-Tage-Serie)
--------------------------------------------------------------------------
Config.DailyCooldown = 20 * 3600 -- frueheste naechste Abholung
Config.DailyStreakReset = 48 * 3600 -- danach beginnt die Serie neu
Config.DailyRewards = {
	{ Gems = 10 },
	{ Gems = 15 },
	{ Gems = 20, Boost = "DoubleSlaps", Duration = 300 },
	{ Gems = 30 },
	{ Gems = 40, Boost = "LuckyEggs", Duration = 600 },
	{ Gems = 60 },
	{ Gems = 120, Boost = "DoubleDamage", Duration = 900 },
}

--------------------------------------------------------------------------
-- Taegliche Quests
--   Stat: welcher Zaehler zaehlt
--------------------------------------------------------------------------
Config.QuestsPerDay = 3
Config.QuestPool = {
	{ Id = "Slap", Stat = "Slaps", Text = "Slap %s times", Amounts = { 150, 400, 800 }, Gems = { 10, 20, 35 } },
	{ Id = "Defeat", Stat = "Defeats", Text = "Defeat %s Blobs", Amounts = { 3, 8, 15 }, Gems = { 12, 25, 40 } },
	{ Id = "Combo", Stat = "BestCombo", Text = "Reach a %s combo", Amounts = { 20, 50, 100 }, Gems = { 10, 20, 40 } },
	{ Id = "Eggs", Stat = "Eggs", Text = "Hatch %s eggs", Amounts = { 2, 5, 10 }, Gems = { 10, 20, 35 } },
	{ Id = "Upgrades", Stat = "Upgrades", Text = "Buy %s upgrades", Amounts = { 3, 8, 15 }, Gems = { 8, 18, 30 } },
	{ Id = "Crits", Stat = "Crits", Text = "Land %s critical slaps", Amounts = { 15, 40, 80 }, Gems = { 10, 20, 35 } },
	{ Id = "Pvp", Stat = "PvpSlaps", Text = "Land %s hits in duels", Amounts = { 5, 15, 30 }, Gems = { 10, 20, 35 } },
	{ Id = "Chests", Stat = "Chests", Text = "Open %s treasure chests", Amounts = { 2, 5, 10 }, Gems = { 10, 20, 35 } },
}

--------------------------------------------------------------------------
-- Codes (Gross-/Kleinschreibung egal)
--------------------------------------------------------------------------
Config.Codes = {
	BLOB = { Gems = 50 },
	SLAP = { Gems = 25, Boost = "DoubleSlaps", Duration = 600 },
	RELEASE = { Gems = 100 },
	BIGHAND = { Boost = "DoubleDamage", Duration = 900 },
	LUCKY = { Boost = "LuckyEggs", Duration = 900 },
}

--------------------------------------------------------------------------
-- Duelle (PvP)
-- Wer in der Duell-Zone im Hub einen anderen Spieler slappt, startet ein
-- Duell: beide werden in eine eigene Arena teleportiert.
--------------------------------------------------------------------------
Config.Arena = { -- die Duell-Zone im Hub
	CenterX = -34,
	CenterZ = -38,
	Radius = 20,
}
Config.Duel = {
	Health = 150,
	Duration = 60, -- Sekunden
	Countdown = 3,
	AttackCooldown = 0.45,
	Reach = 11,
	BaseDamage = 7,
	DamagePerPower = 1.1, -- pro Zehnerpotenz Schaden der Hand
	MaxDamage = 16,
	CritChance = 0.15,
	CritMultiplier = 1.4,
	ComboWindow = 1.2,
	ComboBonus = 0.06, -- +6% Schaden pro Treffer in Folge
	MaxComboBonus = 0.3,
	Knockback = 45,
	KnockbackGrowth = 1.6, -- je weniger Leben, desto weiter fliegt man
	UpForce = 28,
	DashCooldown = 2.5,
	DashInvulnerable = 0.35,
	DashSpeed = 75,
	RingOutDepth = 25,
	WinGems = 10,
	LoseGems = 2,
	ArenaCount = 4,
	ArenaRadius = 30,
	ArenaHeight = 300, -- Hoehe ueber dem Boden
}

--------------------------------------------------------------------------
-- Gems fuer Robux (Developer Products). So richtest du sie ein:
--   create.roblox.com -> dein Spiel -> Monetization -> Developer Products ->
--   "Create a Developer Product", Preis einstellen, ID hier bei ProductId eintragen.
-- Solange ProductId = 0 ist, gibt es die Gems nur in Studio zum Testen.
--------------------------------------------------------------------------
Config.GemPacks = {
	{ Id = "Pack1", Gems = 150, Robux = 49, ProductId = 0 },
	{ Id = "Pack2", Gems = 400, Robux = 99, ProductId = 0 },
	{ Id = "Pack3", Gems = 1000, Robux = 199, ProductId = 0 },
	{ Id = "Pack4", Gems = 2500, Robux = 449, ProductId = 0, Tag = "POPULAR" },
	{ Id = "Pack5", Gems = 6500, Robux = 999, ProductId = 0 },
	{ Id = "Pack6", Gems = 22000, Robux = 3000, ProductId = 0, Tag = "BEST VALUE" },
}

--------------------------------------------------------------------------
-- Handel
--------------------------------------------------------------------------
Config.Trade = {
	MaxPets = 8, -- pro Seite
	RequestTimeout = 30,
	Countdown = 3, -- Sekunden nach "Bereit" bis man bestaetigen kann
}

-- Hub (Startbereich) liegt bei Z < 0
Config.HubLength = 80
Config.SpawnPosition = { 10, -52 }

return Config
