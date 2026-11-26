--[[
	SlapShared/Config  (ModuleScript)

	ALLE Spielwerte von "Slap the Blob" an einem Ort.
	Keine Roblox-APIs hier drin -> funktioniert auf Server und Client gleich.
	Farben sind { R, G, B } Tabellen (0-255).
]]

local Config = {}

Config.GameName = "Slap the Blob"
Config.Version = "6.0"

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
Config.RebirthBaseCost = 2500000
Config.RebirthCostGrowth = 6
Config.RebirthMinZone = 3 -- man muss mindestens Zone 3 haben
Config.RebirthSlapBonus = 1 -- +100% Slaps pro Rebirth
Config.RebirthDamageBonus = 0.5 -- +50% Schaden pro Rebirth
Config.RebirthGems = 50 -- Gems pro Rebirth (mal Rebirth-Nummer)

--------------------------------------------------------------------------
-- Upgrades (mit Slaps kaufen, werden bei Rebirth zurueckgesetzt)
-- Alle 10 Level kommt ein TIER-UP: teuer (Slaps + Gems), aber jede neue
-- Stufe gibt einen viel groesseren Multiplikator als die letzte.
--------------------------------------------------------------------------
Config.UpgradeOrder = { "Power", "Speed", "Reach", "Luck", "Greed", "Combo", "Legs", "Jump" }

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
	Legs = { DisplayName = "Leg Power", Icon = "🦵", Description = "Run faster through the worlds.", MaxLevel = 40, BaseCost = 200, CostGrowth = 1.45 },
	Jump = { DisplayName = "Jump Power", Icon = "🦘", Description = "Jump higher.", MaxLevel = 30, BaseCost = 250, CostGrowth = 1.5 },
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
	{ "Plasma", { 255, 60, 255 }, "Neon" },
	{ "Nebula", { 150, 60, 255 }, "Neon" },
	{ "Solar", { 255, 190, 30 }, "Neon" },
	{ "Lunar", { 210, 220, 255 }, "Neon" },
	{ "Celestial", { 255, 240, 200 }, "Neon" },
	{ "Void", { 30, 10, 60 }, "Neon" },
	{ "Chrono", { 80, 255, 220 }, "Neon" },
	{ "Quantum", { 0, 180, 255 }, "Neon" },
	{ "Dragon", { 220, 20, 40 }, "Neon" },
	{ "Titan", { 255, 150, 40 }, "Neon" },
	{ "Divine", { 255, 255, 220 }, "Neon" },
	{ "Eternal", { 255, 80, 120 }, "Neon" },
	{ "Infinity", { 255, 255, 255 }, "Neon" },
}
local GLOVE_GRADES = { "", "Reinforced ", "Mega " }
local SPECIAL_BASE_EFFECT = { Frost = "smoke", Lava = "fire", Thunder = "electric", Shadow = "shadow", Rainbow = "rainbow",
	Plasma = "electric", Nebula = "orbit", Solar = "fire", Void = "shadow", Chrono = "orbit", Quantum = "electric", Dragon = "dragon",
	Divine = "aura", Eternal = "orbit", Infinity = "rainbow" }
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
			if index > 84 then
				rarity = "Ultra"
			elseif index > 48 then
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
	{ Id = "FrostPhoenix", DisplayName = "Frost Phoenix Claw", Rarity = "Mythic", Damage = 15000, Price = 80000, Currency = "Gems", Color = { 150, 230, 255 }, Material = "Neon", Effect = "smoke",
		SlapMultiplier = 4, CritBonus = 0.1, ReachBonus = 5 },
	{ Id = "CelestialGauntlet", DisplayName = "Celestial Gauntlet", Rarity = "Ultra", Damage = 50000, Price = 150000, Currency = "Gems", Color = { 255, 240, 180 }, Material = "Neon", Effect = "aura",
		SlapMultiplier = 6, CritBonus = 0.12, ReachBonus = 6 },
	{ Id = "VoidReaper", DisplayName = "Void Reaper", Rarity = "Ultra", Damage = 150000, Price = 300000, Currency = "Gems", Color = { 60, 20, 100 }, Material = "Neon", Effect = "shadow",
		SlapMultiplier = 8, CritBonus = 0.15, ReachBonus = 8, Snap = 0.02 },
	{ Id = "EternalFist", DisplayName = "Eternal Fist", Rarity = "Ultra", Damage = 500000, Price = 600000, Currency = "Gems", Color = { 255, 90, 140 }, Material = "Neon", Effect = "omni",
		SlapMultiplier = 12, CritBonus = 0.2, ReachBonus = 10, Snap = 0.04 },
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
	{ Id = "Starter", DisplayName = "Starter Slapper", Damage = 4, Price = 10, GamePassId = 2100348402, Color = { 120, 200, 255 }, Material = "SmoothPlastic", Effect = "sparkles",
		SlapMultiplier = 1.2 },
	{ Id = "Bubblegum", DisplayName = "Bubblegum Glove", Damage = 12, Price = 25, GamePassId = 2101997778, Color = { 255, 140, 210 }, Material = "SmoothPlastic", Effect = "sparkles",
		SlapMultiplier = 1.3 },
	{ Id = "Clover", DisplayName = "Lucky Clover Glove", Damage = 30, Price = 49, GamePassId = 2101847683, Color = { 60, 210, 90 }, Material = "Neon", Effect = "aura",
		SlapMultiplier = 1.5, CritBonus = 0.05 },
	{ Id = "ThunderFist", DisplayName = "Thunder Fist", Damage = 80, Price = 99, GamePassId = 2099214485, Color = { 255, 235, 80 }, Material = "Neon", Effect = "electric",
		SlapMultiplier = 2, SpeedMultiplier = 0.9 },
	{ Id = "ShadowClaw", DisplayName = "Shadow Claw", Damage = 200, Price = 199, GamePassId = 2098626510, Color = { 80, 20, 130 }, Material = "Neon", Effect = "shadow",
		SlapMultiplier = 2.5, CritBonus = 0.08 },
	{ Id = "Thanos", DisplayName = "Titan Gauntlet", Damage = 500, Price = 299, GamePassId = 2100414554, Color = { 220, 170, 40 }, Material = "Foil", Effect = "thanos",
		SlapMultiplier = 3, CritBonus = 0.1, ReachBonus = 5, SpeedMultiplier = 0.8, Snap = 0.05,
		Perk = "🫰 SNAP: 5% chance to erase a target instantly" },
	{ Id = "Phantom", DisplayName = "Phantom Glove", Damage = 900, Price = 499, GamePassId = 2099196443, Color = { 170, 120, 255 }, Material = "Neon", Effect = "orbit",
		SlapMultiplier = 4, CritBonus = 0.1, ReachBonus = 8, Snap = 0.03,
		Perk = "👻 Phantom reach + 3% SNAP" },
	{ Id = "DragonEmperor", DisplayName = "Dragon Emperor", Damage = 1600, Price = 999, GamePassId = 2100318437, Color = { 220, 30, 30 }, Material = "Neon", Effect = "dragon",
		SlapMultiplier = 6, CritBonus = 0.15, ReachBonus = 8, SpeedMultiplier = 0.75,
		Smite = { Every = 8, Multiplier = 10, Radius = 30 },
		Perk = "🐉 DRAGON BREATH: every 8th slap burns all targets nearby (x10)" },
	{ Id = "UltraGod", DisplayName = "ULTRA GOD HAND", Damage = 3000, Price = 1999, GamePassId = 2098302580, Color = { 255, 250, 220 }, Material = "Neon", Effect = "ultragod",
		SlapMultiplier = 10, CritBonus = 0.25, ReachBonus = 15, SpeedMultiplier = 0.5, Snap = 0.1,
		Smite = { Every = 5, Multiplier = 25, Radius = 45 },
		Perk = "⚡ DIVINE SMITE: every 5th slap strikes lightning (x25, area) + 10% SNAP" },
	{ Id = "CosmicOverlord", DisplayName = "Cosmic Overlord", Damage = 5000, Price = 2999, GamePassId = 2098818487, Color = { 90, 60, 255 }, Material = "Neon", Effect = "orbit",
		SlapMultiplier = 15, CritBonus = 0.3, ReachBonus = 18, SpeedMultiplier = 0.45, Snap = 0.1,
		Smite = { Every = 5, Multiplier = 30, Radius = 50 },
		Perk = "🌌 COSMIC STORM: every 5th slap (x30, area) + 10% SNAP" },
	{ Id = "Omni", DisplayName = "OMNI GLOVE", Damage = 10000, Price = 5000, GamePassId = 2099982495, Color = { 255, 255, 255 }, Material = "Neon", Effect = "omni",
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
Config.RarityOrder = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Ultra", "Secret", "UltraMaster" }
Config.Rarities = {
	Common = { DisplayName = "Common", Color = { 200, 200, 200 }, Order = 1 },
	Rare = { DisplayName = "Rare", Color = { 80, 170, 255 }, Order = 2 },
	Epic = { DisplayName = "Epic", Color = { 190, 90, 255 }, Order = 3 },
	Legendary = { DisplayName = "Legendary", Color = { 255, 190, 40 }, Order = 4 },
	Mythic = { DisplayName = "Mythic", Color = { 255, 60, 120 }, Order = 5 },
	Ultra = { DisplayName = "ULTRA", Color = { 255, 240, 120 }, Order = 6 },
	Secret = { DisplayName = "SECRET", Color = { 255, 255, 255 }, Order = 7 },
	UltraMaster = { DisplayName = "ULTRA MASTER", Color = { 255, 90, 255 }, Order = 8 },
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

Config.BasePetSlots = 4
Config.BaseInventory = 60
Config.LuckyBoostFactor = 2.5 -- Gewicht seltener Pets mit Glueck-Boost

--------------------------------------------------------------------------
-- Zonen. Jede Zone hat mehrere Ziele zum Slappen und ein Ei.
--   Kind: "blob" (Standard), "cube", "dummy", "robot", "ghost", "golem", "chest"
--   Decor: meadow, desert, ice, lava, cloud, space, candy, cyber, shadow, void
--   Accessories (nur Blobs): bow, glasses, cowboy, scarf, horns, halo, antenna, crown
--------------------------------------------------------------------------
Config.ZoneLength = 200
Config.ZoneWidth = 160

-- Dimensionen: am Ende der Oberwelt fuehrt ein Portal in die Rift-Dimension.
Config.Dimensions = {
	{ Name = "Overworld", FirstZone = 1, LastZone = 6, StartZ = 0 },
	{ Name = "The Rift", FirstZone = 7, LastZone = 10, StartZ = 1500 },
	{ Name = "Elemental Realm", FirstZone = 11, LastZone = 15, StartZ = 2700 },
	{ Name = "Mythic Realm", FirstZone = 16, LastZone = 20, StartZ = 4050 },
	{ Name = "Cosmic Realm", FirstZone = 21, LastZone = 25, StartZ = 5400 },
	{ Name = "The Infinite", FirstZone = 26, LastZone = 30, StartZ = 6750 },
	{ Name = "The Beyond", FirstZone = 31, LastZone = 37, StartZ = 8100 },
}

-- Ab Zone 11 gibt jede freigeschaltete Zone x3 Schaden (sonst waeren die
-- hohen Zonen unmoeglich). Die Leben der Ziele wachsen aber x4 pro Zone,
-- die Preise x25 - es wird also mit jeder Zone deutlich schwerer.
Config.ZonePowerStart = 10
Config.ZonePowerBase = 3
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

--------------------------------------------------------------------------
-- Schwieriger: Zonen 2-10 kosten 3x so viel, Ziele haben doppelte Leben
--------------------------------------------------------------------------
for index = 2, #Config.Zones do
	local zone = Config.Zones[index]
	zone.Price = zone.Price * 3
	for _, target in ipairs(zone.Gyatts) do
		target.MaxHealth = target.MaxHealth * 2
	end
end

--------------------------------------------------------------------------
-- 20 weitere Welten (Zone 11-30) in 4 neuen Dimensionen
--   { Name, Decor, Boden, Bodenmaterial, Akzent, Weg, Wort, {Art1, Art2}, Boss-Titel, {Boss-Accessoires} }
--------------------------------------------------------------------------
local EXTRA_ZONES = {
	-- Elemental Realm
	{ "Inferno Peaks", "lava", { 90, 35, 25 }, "Basalt", { 255, 120, 0 }, { 140, 60, 30 }, "Inferno", { "golem", "robot" }, "Inferno Titan Blob", { "horns", "crown" } },
	{ "Frozen Abyss", "ice", { 200, 225, 245 }, "Ice", { 90, 160, 255 }, { 150, 190, 230 }, "Glacier", { "ghost", "golem" }, "Glacier Emperor Blob", { "scarf", "crown" } },
	{ "Storm Plains", "cloud", { 150, 160, 180 }, "SmoothPlastic", { 255, 240, 80 }, { 110, 120, 140 }, "Storm", { "ghost", "cube" }, "Thunder Lord Blob", { "halo", "crown" } },
	{ "Toxic Swamp", "meadow", { 70, 110, 50 }, "Grass", { 150, 255, 60 }, { 90, 80, 50 }, "Toxic", { "cube", "dummy" }, "Swamp King Blob", { "horns", "glasses" } },
	{ "Crystal Caverns", "space", { 40, 30, 70 }, "Slate", { 120, 230, 255 }, { 70, 60, 110 }, "Crystal", { "golem", "ghost" }, "Crystal Queen Blob", { "crown", "bow" } },
	-- Mythic Realm
	{ "Enchanted Forest", "meadow", { 60, 140, 90 }, "Grass", { 255, 150, 255 }, { 120, 100, 160 }, "Fairy", { "ghost", "dummy" }, "Forest Spirit Blob", { "halo", "bow" } },
	{ "Dragon Desert", "desert", { 230, 170, 100 }, "Sand", { 255, 60, 40 }, { 200, 120, 80 }, "Dragon", { "golem", "robot" }, "Dragon Lord Blob", { "horns", "crown" } },
	{ "Candy Kingdom", "candy", { 255, 220, 240 }, "SmoothPlastic", { 255, 60, 140 }, { 255, 255, 220 }, "Sugar", { "cube", "dummy" }, "Candy Emperor Blob", { "crown", "bow" } },
	{ "Neon Metropolis", "cyber", { 25, 15, 45 }, "SmoothPlastic", { 255, 0, 200 }, { 60, 30, 90 }, "Neon", { "robot", "cube" }, "Mega Mecha Blob", { "antenna", "glasses" } },
	{ "Haunted Graveyard", "shadow", { 45, 40, 50 }, "Slate", { 120, 255, 160 }, { 80, 70, 80 }, "Haunted", { "ghost", "golem" }, "Phantom King Blob", { "horns", "halo" } },
	-- Cosmic Realm
	{ "Moon Base", "space", { 170, 170, 180 }, "Slate", { 120, 200, 255 }, { 120, 120, 135 }, "Lunar", { "robot", "cube" }, "Moon Emperor Blob", { "antenna", "crown" } },
	{ "Nebula Fields", "void", { 60, 20, 90 }, "Glass", { 255, 120, 220 }, { 90, 40, 120 }, "Nebula", { "ghost", "cube" }, "Nebula Queen Blob", { "halo", "bow" } },
	{ "Solar Flare", "lava", { 120, 60, 10 }, "Basalt", { 255, 220, 40 }, { 170, 90, 20 }, "Solar", { "golem", "ghost" }, "Sun God Blob", { "halo", "crown" } },
	{ "Starlight Heaven", "cloud", { 230, 235, 255 }, "SmoothPlastic", { 180, 160, 255 }, { 210, 210, 250 }, "Starlight", { "ghost", "dummy" }, "Star King Blob", { "halo", "crown", "glasses" } },
	{ "Black Hole", "void", { 5, 5, 10 }, "Glass", { 180, 80, 255 }, { 25, 15, 40 }, "Singularity", { "golem", "ghost" }, "Event Horizon Blob", { "horns", "halo" } },
	-- The Infinite
	{ "Glitch World", "cyber", { 10, 30, 20 }, "SmoothPlastic", { 0, 255, 90 }, { 30, 60, 40 }, "Glitch", { "cube", "robot" }, "ERROR Blob", { "antenna", "glasses" } },
	{ "Shadow Throne", "shadow", { 20, 10, 30 }, "Slate", { 255, 40, 80 }, { 50, 20, 60 }, "Throne", { "ghost", "golem" }, "Shadow Monarch Blob", { "horns", "crown" } },
	{ "Rainbow Road", "candy", { 255, 255, 255 }, "SmoothPlastic", { 255, 100, 200 }, { 200, 220, 255 }, "Rainbow", { "cube", "ghost" }, "Rainbow Overlord Blob", { "halo", "crown", "bow" } },
	{ "Golden Paradise", "desert", { 255, 220, 120 }, "Sand", { 255, 200, 40 }, { 240, 190, 90 }, "Golden", { "golem", "robot" }, "Golden God Blob", { "crown", "glasses" } },
	{ "INFINITY", "void", { 255, 255, 255 }, "Glass", { 0, 0, 0 }, { 200, 200, 210 }, "Infinity", { "ghost", "golem" }, "THE INFINITE BLOB", { "halo", "crown", "glasses" } },
	-- The Beyond: 7 Welten mit eigener Spielmechanik
	{ "Gravity Garden", "meadow", { 120, 220, 160 }, "Grass", { 120, 255, 220 }, { 200, 240, 220 }, "Gravity", { "ghost", "cube" }, "Zero-G Blob", { "halo", "bow" }, "lowgrav" },
	{ "Glacier Slide", "ice", { 210, 240, 255 }, "Ice", { 60, 180, 255 }, { 170, 210, 240 }, "Slide", { "golem", "cube" }, "Glacier Titan Blob", { "scarf", "crown" }, "ice" },
	{ "Bounce Castle", "candy", { 255, 210, 250 }, "SmoothPlastic", { 255, 120, 220 }, { 255, 240, 250 }, "Bounce", { "cube", "dummy" }, "Bouncy King Blob", { "crown", "bow" }, "bounce" },
	{ "Hyper Highway", "cyber", { 15, 20, 40 }, "SmoothPlastic", { 255, 230, 0 }, { 50, 60, 90 }, "Hyper", { "robot", "cube" }, "Turbo Blob", { "antenna", "glasses" }, "boost" },
	{ "Eclipse Valley", "shadow", { 15, 10, 20 }, "Slate", { 255, 140, 40 }, { 40, 30, 45 }, "Eclipse", { "ghost", "golem" }, "Eclipse Blob", { "horns", "halo" }, "dark" },
	{ "Titan's Core", "lava", { 70, 20, 10 }, "Basalt", { 255, 70, 0 }, { 110, 40, 20 }, "Core", { "golem", "robot" }, "Core Titan Blob", { "horns", "crown" }, "heavy" },
	{ "Tempest Peak", "cloud", { 120, 130, 160 }, "SmoothPlastic", { 120, 220, 255 }, { 100, 110, 140 }, "Tempest", { "ghost", "dummy" }, "TEMPEST GOD BLOB", { "halo", "crown", "glasses" }, "storm" },
}

local KIND_NAMES = { ghost = "Ghost", cube = "Cube", robot = "Bot", golem = "Golem", dummy = "Dummy" }
local PET_STYLES = { { "dog", "Pup" }, { "cat", "Cat" }, { "fox", "Fox" }, { "owl", "Owl" }, { "dragon", "Dragon" }, { "unicorn", "Unicorn" },
	{ "bunny", "Bunny" }, { "bat", "Bat" }, { "shark", "Shark" }, { "octopus", "Kraken" }, { "golem", "Golem" }, { "jelly", "Jelly" },
	{ "panda", "Panda" }, { "turtle", "Turtle" }, { "bee", "Bee" }, { "dino", "Dino" }, { "whale", "Whale" }, { "ghost", "Spirit" } }

local base = Config.Zones[10] -- Void Rift (schon 3x / 2x schwerer)
local basePrice = base.Price
local baseHealth = { base.Gyatts[1].MaxHealth, base.Gyatts[2].MaxHealth, base.Gyatts[3].MaxHealth, base.Gyatts[4].MaxHealth }
local baseReward = { base.Gyatts[1].RewardMultiplier, base.Gyatts[2].RewardMultiplier, base.Gyatts[3].RewardMultiplier }
local basePetBoost = 4200

for k, def in ipairs(EXTRA_ZONES) do
	local zoneIndex = 10 + k
	local name, decorName, floor, floorMat, accent, path, word, kinds, bossName, bossAcc =
		def[1], def[2], def[3], def[4], def[5], def[6], def[7], def[8], def[9], def[10]
	local hp = 5 ^ k
	local reward = 3.2 ^ k
	local eggId = "Z" .. zoneIndex
	local function shade(c, f)
		return { math.floor(math.clamp and math.clamp(c[1] * f, 0, 255) or math.min(255, c[1] * f)),
			math.floor(math.min(255, c[2] * f)), math.floor(math.min(255, c[3] * f)) }
	end
	table.insert(Config.Zones, {
		Name = name, Price = math.floor(basePrice * (40 ^ k)), Decor = decorName, Mechanic = def[11],
		Floor = floor, FloorMaterial = floorMat, Accent = accent, Path = path,
		Egg = eggId,
		Gyatts = {
			{ Id = word .. "A", Kind = kinds[1], DisplayName = word .. " " .. KIND_NAMES[kinds[1]], MaxHealth = baseHealth[1] * hp, Size = 13,
				Color = shade(accent, 0.8), RewardMultiplier = math.floor(baseReward[1] * reward), Gems = 15 + k },
			{ Id = word .. "Boss", DisplayName = bossName, MaxHealth = baseHealth[2] * hp, Size = math.min(34, 22 + math.floor(k / 2)),
				Color = shade(accent, 0.6), RewardMultiplier = math.floor(baseReward[2] * reward), Gems = 50 + k * 3, Accessories = bossAcc },
			{ Id = word .. "B", Kind = kinds[2], DisplayName = word .. " " .. KIND_NAMES[kinds[2]], MaxHealth = baseHealth[3] * hp, Size = 15,
				Color = shade(accent, 0.5), RewardMultiplier = math.floor(baseReward[3] * reward), Gems = 20 + k },
			{ Id = "Chest", Kind = "chest", DisplayName = word .. " Chest", MaxHealth = baseHealth[4] * hp, Size = 5, Color = shade(floor, 0.7),
				RewardMultiplier = 1, Gems = 60 + k * 4, Respawn = 60 },
		},
	})

	-- Ei mit 6 Pets fuer diese Zone
	local petBase = basePetBoost * (3.2 ^ k)
	local entries = {}
	for slotIndex, slot in ipairs(ZONE_EGG_SLOTS) do
		local style = PET_STYLES[((k * 5 + slotIndex * 3) % #PET_STYLES) + 1]
		local petId = eggId .. "_" .. slotIndex
		local tint = (slotIndex % 2 == 0) and accent or floor
		Config.Pets[petId] = {
			DisplayName = word .. " " .. style[2],
			Rarity = slot.Rarity,
			Boost = math.floor(petBase * slot.Factor),
			Color = tint,
			Style = style[1],
			Egg = eggId,
		}
		table.insert(entries, { petId, slot.Weight })
	end
	Config.Eggs[eggId] = { DisplayName = word .. " Egg", Price = math.floor(basePrice * (40 ^ k) * 5), Currency = "Slaps", Color = accent, Zone = zoneIndex, Pets = entries }
	table.insert(Config.EggOrder, eggId)
end

--------------------------------------------------------------------------
-- Dimensionen automatisch hintereinander legen (700 Studs Luecke dazwischen)
--------------------------------------------------------------------------
do
	local z = 0
	for _, dim in ipairs(Config.Dimensions) do
		dim.StartZ = z
		z = z + (dim.LastZone - dim.FirstZone + 1) * Config.ZoneLength + 700
	end
end

--------------------------------------------------------------------------
-- Zonen-Mechaniken (Standard je Thema, einzelne Zonen koennen eine eigene haben)
--   lowgrav  = wenig Schwerkraft      heavy = starke Schwerkraft
--   floaty   = leicht schwebend       ice   = rutschiger Boden
--   bounce   = Sprungpolster          boost = Turbo-Felder
--   dark     = Dunkelheit             storm = Windboeen
--------------------------------------------------------------------------
Config.DecorMechanic = { space = "lowgrav", void = "lowgrav", ice = "ice", candy = "bounce", cyber = "boost", shadow = "dark", cloud = "floaty", desert = "storm" }
Config.MechanicInfo = {
	lowgrav = { Name = "Low Gravity", Icon = "🪐" },
	heavy = { Name = "Heavy Gravity", Icon = "🪨" },
	floaty = { Name = "Floaty Air", Icon = "☁️" },
	ice = { Name = "Slippery Ice", Icon = "🧊" },
	bounce = { Name = "Bounce Pads", Icon = "🟣" },
	boost = { Name = "Turbo Pads", Icon = "⚡" },
	dark = { Name = "Darkness", Icon = "🌑" },
	storm = { Name = "Wind Gusts", Icon = "💨" },
}
for _, zone in ipairs(Config.Zones) do
	if zone.Mechanic == nil then
		zone.Mechanic = Config.DecorMechanic[zone.Decor]
	end
end

--------------------------------------------------------------------------
-- Pinata in jeder Zone: wenig Slaps, aber hohe Chance auf Items
--------------------------------------------------------------------------
for _, zone in ipairs(Config.Zones) do
	local boss = zone.Gyatts[2]
	table.insert(zone.Gyatts, {
		Id = "Pinata", Kind = "pinata", DisplayName = "Lucky Pinata", MaxHealth = math.floor(boss.MaxHealth * 0.15) + 30, Size = 7,
		Color = zone.Accent, RewardMultiplier = math.max(1, math.floor(boss.RewardMultiplier * 0.3)), Gems = 2, Respawn = 30,
	})
end

-- Item-Dropchance pro Zieltyp (beim Besiegen, pro Spieler der geholfen hat)
Config.KindDrops = { blob = 0.012, cube = 0.018, dummy = 0.01, robot = 0.022, ghost = 0.022, golem = 0.03, chest = 0.25, pinata = 0.15 }
Config.BossDropBonus = 2 -- der Boss jeder Zone (2. Ziel) hat doppelte Chance
-- Seltenheit von gefundenen Items. Je weiter die Zone, desto besser.
Config.DropRarityWeights = { Common = 60, Rare = 26, Epic = 10, Legendary = 3.5, Mythic = 0.5 }

--------------------------------------------------------------------------
-- Weitere Eier: Gem-Eier, Robux-Eier, Wochen-Event-Eier
--------------------------------------------------------------------------
local function addEgg(eggId, eggName, price, currency, color, zone, baseBoost, slots, petDefs, extra)
	local entries = {}
	for i, slot in ipairs(slots) do
		local petDef = petDefs[i]
		local petId = eggId .. "_" .. i
		local boost = baseBoost * slot.Factor
		boost = boost >= 10 and math.floor(boost) or math.floor(boost * 100 + 0.5) / 100
		Config.Pets[petId] = { DisplayName = petDef[1], Rarity = slot.Rarity, Boost = boost, Color = petDef[3], Style = petDef[2], Egg = eggId }
		table.insert(entries, { petId, slot.Weight })
	end
	local egg = { DisplayName = eggName, Price = price, Currency = currency, Color = color, Zone = zone, Pets = entries }
	for k, v in pairs(extra or {}) do
		egg[k] = v
	end
	Config.Eggs[eggId] = egg
	table.insert(Config.EggOrder, eggId)
	return egg
end

-- Gem-Eier (Diamanten)
addEgg("Diamond", "Diamond Egg", 1500, "Gems", { 120, 230, 255 }, 1, 60, {
	{ Rarity = "Epic", Weight = 60, Factor = 7 }, { Rarity = "Epic", Weight = 28, Factor = 9 }, { Rarity = "Legendary", Weight = 9, Factor = 20 },
	{ Rarity = "Legendary", Weight = 2.5, Factor = 26 }, { Rarity = "Mythic", Weight = 0.48, Factor = 60 }, { Rarity = "Ultra", Weight = 0.02, Factor = 150 },
}, { { "Diamond Pup", "dog", { 150, 230, 255 } }, { "Diamond Cat", "cat", { 170, 240, 255 } }, { "Gem Fox", "fox", { 90, 210, 255 } },
	{ "Crystal Owl", "owl", { 200, 250, 255 } }, { "Diamond Dragon", "dragon", { 120, 230, 255 } }, { "Prism Unicorn", "unicorn", { 230, 250, 255 } } }, { Shop = true })
addEgg("Mythic", "Mythic Egg", 5000, "Gems", { 255, 80, 160 }, 1, 200, {
	{ Rarity = "Legendary", Weight = 60, Factor = 20 }, { Rarity = "Legendary", Weight = 28, Factor = 26 }, { Rarity = "Mythic", Weight = 9, Factor = 55 },
	{ Rarity = "Mythic", Weight = 2.5, Factor = 70 }, { Rarity = "Ultra", Weight = 0.49, Factor = 150 }, { Rarity = "Secret", Weight = 0.01, Factor = 1000 },
}, { { "Mythic Wolf", "dog", { 255, 90, 160 } }, { "Mythic Phoenix", "bird", { 255, 120, 60 } }, { "Mythic Kraken", "octopus", { 200, 60, 255 } },
	{ "Mythic Dragon", "dragon", { 255, 60, 140 } }, { "Mythic Whale", "whale", { 255, 140, 220 } }, { "The Mythic One", "ghost", { 255, 200, 255 } } }, { Shop = true })

-- ROBUX-EIER (Developer Products, R$100 bis R$1000). ProductId eintragen wie bei den Gems.
Config.RobuxEggs = {
	{ Id = "RobuxEgg1", Name = "Robux Egg", Robux = 100, ProductId = 0, Color = { 120, 255, 140 }, Base = 50,
		Slots = { { Rarity = "Rare", Weight = 50, Factor = 3 }, { Rarity = "Epic", Weight = 25, Factor = 7 }, { Rarity = "Epic", Weight = 10, Factor = 9 },
			{ Rarity = "Legendary", Weight = 9, Factor = 20 }, { Rarity = "Legendary", Weight = 3, Factor = 26 }, { Rarity = "Mythic", Weight = 3, Factor = 60 } },
		Pets = { { "Lucky Pup", "dog", { 120, 255, 140 } }, { "Clover Cat", "cat", { 90, 220, 110 } }, { "Emerald Fox", "fox", { 60, 200, 120 } },
			{ "Jade Dragon", "dragon", { 80, 220, 140 } }, { "Fortune Owl", "owl", { 255, 220, 90 } }, { "Lucky Unicorn", "unicorn", { 180, 255, 190 } } } },
	{ Id = "RobuxEgg2", Name = "Super Egg", Robux = 250, ProductId = 3736656587, Color = { 90, 180, 255 }, Base = 200,
		Slots = { { Rarity = "Epic", Weight = 50, Factor = 7 }, { Rarity = "Legendary", Weight = 25, Factor = 20 }, { Rarity = "Legendary", Weight = 10, Factor = 26 },
			{ Rarity = "Mythic", Weight = 9, Factor = 60 }, { Rarity = "Mythic", Weight = 4, Factor = 75 }, { Rarity = "Ultra", Weight = 2, Factor = 150 } },
		Pets = { { "Super Shark", "shark", { 90, 180, 255 } }, { "Super Bee", "bee", { 255, 230, 90 } }, { "Storm Bat", "bat", { 120, 140, 255 } },
			{ "Super Dino", "dino", { 90, 200, 255 } }, { "Sky Whale", "whale", { 150, 210, 255 } }, { "Super Dragon", "dragon", { 60, 140, 255 } } } },
	{ Id = "RobuxEgg3", Name = "Mega Egg", Robux = 500, ProductId = 3736656733, Color = { 200, 90, 255 }, Base = 800,
		Slots = { { Rarity = "Legendary", Weight = 50, Factor = 20 }, { Rarity = "Mythic", Weight = 25, Factor = 60 }, { Rarity = "Mythic", Weight = 13, Factor = 75 },
			{ Rarity = "Ultra", Weight = 8, Factor = 150 }, { Rarity = "Ultra", Weight = 3, Factor = 180 }, { Rarity = "UltraMaster", Weight = 1, Factor = 400 } },
		Pets = { { "Mega Golem", "golem", { 200, 90, 255 } }, { "Mega Panda", "panda", { 230, 200, 255 } }, { "Mega Kraken", "octopus", { 170, 60, 255 } },
			{ "Mega Phoenix", "bird", { 255, 90, 220 } }, { "Mega Unicorn", "unicorn", { 220, 160, 255 } }, { "Mega Overlord", "dragon", { 150, 40, 255 } } } },
	{ Id = "RobuxEgg4", Name = "Ultra Master Egg", Robux = 999, ProductId = 3736656838, Color = { 255, 90, 255 }, Base = 3000,
		Slots = { { Rarity = "Mythic", Weight = 45, Factor = 60 }, { Rarity = "Ultra", Weight = 25, Factor = 150 }, { Rarity = "Ultra", Weight = 20, Factor = 180 },
			{ Rarity = "UltraMaster", Weight = 6, Factor = 400 }, { Rarity = "UltraMaster", Weight = 3, Factor = 500 }, { Rarity = "UltraMaster", Weight = 1, Factor = 800 } },
		Pets = { { "Master Wolf", "dog", { 255, 120, 255 } }, { "Master Dragon", "dragon", { 255, 60, 220 } }, { "Master Whale", "whale", { 255, 150, 255 } },
			{ "Ultra Master Phoenix", "bird", { 255, 200, 90 } }, { "Ultra Master Kraken", "octopus", { 255, 80, 200 } }, { "THE ULTRA MASTER", "ghost", { 255, 255, 255 } } } },
}
for _, robuxEgg in ipairs(Config.RobuxEggs) do
	addEgg(robuxEgg.Id, robuxEgg.Name, robuxEgg.Robux, "Robux", robuxEgg.Color, 1, robuxEgg.Base, robuxEgg.Slots, robuxEgg.Pets, { Robux = true })
end

-- WOCHEN-EVENTS: jede Woche ein anderes Event-Ei mit exklusiven Pets (nur in dieser Woche!)
local EVENT_SLOTS = {
	{ Rarity = "Legendary", Weight = 60, Factor = 20 }, { Rarity = "Legendary", Weight = 28, Factor = 26 }, { Rarity = "Mythic", Weight = 9, Factor = 60 },
	{ Rarity = "Mythic", Weight = 2.5, Factor = 75 }, { Rarity = "Ultra", Weight = 0.48, Factor = 160 }, { Rarity = "Secret", Weight = 0.02, Factor = 1200 },
}
Config.WeeklyEvents = {
	{ Id = "Spooky", Name = "Spooky Week", Color = { 255, 120, 30 }, Pets = { { "Pumpkin Pup", "dog", { 255, 140, 30 } }, { "Witch Cat", "cat", { 90, 40, 120 } },
		{ "Spooky Bat", "bat", { 60, 30, 70 } }, { "Ghost Owl", "owl", { 230, 230, 255 } }, { "Headless Dragon", "dragon", { 255, 100, 20 } }, { "Phantom King", "ghost", { 200, 255, 200 } } } },
	{ Id = "Winter", Name = "Winter Wonderland", Color = { 170, 220, 255 }, Pets = { { "Snow Pup", "dog", { 240, 250, 255 } }, { "Reindeer", "unicorn", { 170, 110, 70 } },
		{ "Ice Penguin", "bird", { 60, 70, 100 } }, { "Frost Panda", "panda", { 200, 230, 255 } }, { "Gift Golem", "golem", { 220, 40, 60 } }, { "Santa Blob", "ghost", { 255, 60, 60 } } } },
	{ Id = "Spring", Name = "Spring Bloom", Color = { 255, 170, 220 }, Pets = { { "Easter Bunny", "bunny", { 255, 220, 240 } }, { "Flower Bee", "bee", { 255, 230, 120 } },
		{ "Petal Fox", "fox", { 255, 160, 200 } }, { "Garden Frog", "frog", { 120, 220, 120 } }, { "Blossom Dragon", "dragon", { 255, 180, 230 } }, { "Spring Spirit", "ghost", { 230, 255, 220 } } } },
	{ Id = "Summer", Name = "Summer Splash", Color = { 80, 200, 255 }, Pets = { { "Beach Crab", "octopus", { 255, 110, 80 } }, { "Surf Shark", "shark", { 90, 160, 220 } },
		{ "Sunny Turtle", "turtle", { 90, 200, 120 } }, { "Coconut Cat", "cat", { 200, 150, 90 } }, { "Tidal Whale", "whale", { 40, 140, 255 } }, { "Sun God", "ghost", { 255, 220, 80 } } } },
	{ Id = "Space", Name = "Space Week", Color = { 140, 90, 255 }, Pets = { { "Astro Pup", "dog", { 220, 220, 240 } }, { "UFO Alien", "alien", { 120, 255, 160 } },
		{ "Comet Jelly", "jelly", { 120, 200, 255 } }, { "Rocket Robot", "robot", { 200, 200, 220 } }, { "Nebula Dragon", "dragon", { 160, 80, 255 } }, { "Black Hole", "ghost", { 40, 0, 80 } } } },
	{ Id = "Dragon", Name = "Dragon Festival", Color = { 255, 60, 60 }, Pets = { { "Lantern Pup", "dog", { 255, 80, 60 } }, { "Lucky Cat", "cat", { 255, 220, 120 } },
		{ "Fire Dino", "dino", { 255, 100, 30 } }, { "Jade Turtle", "turtle", { 60, 200, 130 } }, { "Golden Dragon King", "dragon", { 255, 200, 40 } }, { "Dragon Spirit", "ghost", { 255, 90, 90 } } } },
}
Config.EventEggPrice = 500 -- Gems
for _, event in ipairs(Config.WeeklyEvents) do
	event.EggId = "Event_" .. event.Id
	addEgg(event.EggId, event.Name .. " Egg", Config.EventEggPrice, "Gems", event.Color, 1, 300, EVENT_SLOTS, event.Pets, { Event = event.Id })
end

--------------------------------------------------------------------------
-- ITEMS / ACCESSOIRES: 3 Kategorien x 25. Veraendern das Aussehen und
-- geben Werte. 3 gleiche Items (gleiche Stufe) = 1 Item mit +1 Stern (max 5).
--------------------------------------------------------------------------
Config.ItemCategories = { "Hat", "Back", "Aura" }
Config.ItemCategoryInfo = {
	Hat = { Name = "Hats", Icon = "🎩", Stat = "Damage" },
	Back = { Name = "Wings & Backs", Icon = "🪽", Stat = "Speed" },
	Aura = { Name = "Auras", Icon = "✨", Stat = "Slaps" },
}
Config.StatInfo = {
	Damage = { Name = "Damage", Icon = "💪" },
	Slaps = { Name = "Slaps", Icon = "💰" },
	Speed = { Name = "Walk Speed", Icon = "🦵" },
	Luck = { Name = "Crit Luck", Icon = "🍀" },
	Gems = { Name = "Gem Find", Icon = "💎" },
}
Config.ItemRarityValue = { Common = 0.05, Rare = 0.12, Epic = 0.25, Legendary = 0.5, Mythic = 1, Ultra = 2.5, UltraMaster = 6 }
Config.ItemLevelMultiplier = { 1, 1.6, 2.5, 4, 6.5 }
Config.ItemMaxLevel = 5
Config.ItemInventory = 120
Config.Items = {}
Config.ItemOrder = {}

local ITEM_RARITY_BY_INDEX = { "Common", "Common", "Common", "Common", "Common", "Rare", "Rare", "Rare", "Rare", "Rare",
	"Epic", "Epic", "Epic", "Epic", "Legendary", "Legendary", "Legendary", "Legendary", "Mythic", "Mythic", "Mythic", "Ultra", "Ultra", "UltraMaster", "UltraMaster" }
-- { Name, Form, Farbe, Material, Effekt }
local ITEM_DEFS = {
	Hat = {
		{ "Party Hat", "cone", { 255, 90, 160 } }, { "Baseball Cap", "cap", { 60, 120, 255 } }, { "Beanie", "beanie", { 230, 60, 60 } },
		{ "Top Hat", "tophat", { 30, 30, 35 } }, { "Cowboy Hat", "brim", { 150, 100, 60 } }, { "Chef Hat", "chef", { 255, 255, 255 } },
		{ "Bunny Ears", "ears_long", { 255, 220, 235 } }, { "Cat Ears", "ears_cat", { 255, 170, 90 } }, { "Viking Helmet", "horns", { 180, 180, 190 } },
		{ "Ninja Band", "band", { 30, 30, 40 } }, { "Wizard Hat", "wizard", { 90, 60, 200 } }, { "Flower Crown", "ring", { 255, 150, 200 } },
		{ "Knight Helmet", "helm", { 200, 205, 215 }, "Metal" }, { "Space Helmet", "dome", { 200, 230, 255 }, "Glass" }, { "Golden Crown", "crown", { 255, 200, 40 }, "Foil" },
		{ "Angel Halo", "halo", { 255, 240, 120 }, "Neon" }, { "Demon Horns", "horns", { 200, 20, 30 }, "Neon" }, { "Antlers", "antlers", { 140, 100, 70 } },
		{ "Ice Crown", "crown", { 160, 220, 255 }, "Ice" }, { "Flame Crown", "crown", { 255, 110, 20 }, "Neon", "fire" }, { "Samurai Kabuto", "helm", { 180, 30, 40 }, "Metal" },
		{ "Galaxy Crown", "crown", { 120, 60, 255 }, "Neon", "sparkles" }, { "Cosmic Halo", "halo", { 160, 120, 255 }, "Neon", "sparkles" },
		{ "Ultra Master Crown", "crown", { 255, 90, 255 }, "Neon", "rainbow" }, { "Infinity Halo", "halo", { 255, 255, 255 }, "Neon", "rainbow" },
	},
	Back = {
		{ "Small Backpack", "backpack", { 230, 90, 60 } }, { "Cape", "cape", { 200, 30, 50 } }, { "Fairy Wings", "wings_round", { 200, 255, 240 }, "Glass" },
		{ "Bee Wings", "wings_round", { 230, 240, 255 }, "Glass" }, { "Leaf Wings", "wings_feather", { 90, 200, 90 } }, { "Butterfly Wings", "wings_round", { 255, 150, 60 } },
		{ "Bat Wings", "wings_bat", { 50, 30, 60 } }, { "Jetpack", "jetpack", { 180, 180, 190 }, "Metal" }, { "Royal Cape", "cape", { 120, 40, 200 } },
		{ "Feather Cape", "cape", { 240, 240, 255 } }, { "Angel Wings", "wings_feather", { 255, 255, 255 } }, { "Rocket Pack", "jetpack", { 255, 80, 60 }, "Metal", "fire" },
		{ "Dragon Wings", "wings_bat", { 200, 30, 30 } }, { "Ice Wings", "wings_feather", { 170, 225, 255 }, "Ice" }, { "Phoenix Wings", "wings_feather", { 255, 140, 30 }, "Neon", "fire" },
		{ "Shadow Wings", "wings_bat", { 40, 10, 60 }, "Neon", "smoke" }, { "Crystal Wings", "wings_round", { 150, 230, 255 }, "Glass", "sparkles" }, { "Mecha Wings", "wings_feather", { 120, 130, 150 }, "Metal" },
		{ "Golden Wings", "wings_feather", { 255, 200, 40 }, "Foil", "sparkles" }, { "Thunder Wings", "wings_feather", { 255, 240, 80 }, "Neon" }, { "Lava Wings", "wings_bat", { 255, 90, 20 }, "Neon", "fire" },
		{ "Galaxy Wings", "wings_round", { 120, 60, 255 }, "Neon", "sparkles" }, { "Void Wings", "wings_bat", { 20, 0, 40 }, "Neon", "smoke" },
		{ "Celestial Wings", "wings_feather", { 255, 240, 200 }, "Neon", "rainbow" }, { "Ultra Master Wings", "wings_feather", { 255, 90, 255 }, "Neon", "rainbow" },
	},
	Aura = {
		{ "Sparkle Aura", "aura", { 255, 255, 200 } }, { "Bubble Aura", "aura", { 150, 220, 255 } }, { "Leaf Aura", "aura", { 100, 220, 100 } },
		{ "Heart Aura", "aura", { 255, 90, 150 } }, { "Snow Aura", "aura", { 240, 250, 255 } }, { "Smoke Aura", "aura", { 150, 150, 160 }, nil, "smoke" },
		{ "Star Aura", "aura", { 255, 230, 90 } }, { "Music Aura", "aura", { 200, 120, 255 } }, { "Toxic Aura", "aura", { 140, 255, 60 } },
		{ "Ice Aura", "aura", { 160, 230, 255 } }, { "Fire Aura", "aura", { 255, 110, 20 }, nil, "fire" }, { "Lightning Aura", "aura", { 255, 250, 120 } },
		{ "Pixel Aura", "aura", { 60, 255, 200 } }, { "Ghost Aura", "aura", { 220, 230, 255 }, nil, "smoke" }, { "Gold Aura", "aura", { 255, 200, 40 }, nil, "sparkles" },
		{ "Crystal Aura", "aura", { 150, 240, 255 }, nil, "sparkles" }, { "Lava Aura", "aura", { 255, 70, 0 }, nil, "fire" }, { "Shadow Aura", "aura", { 60, 0, 90 }, nil, "smoke" },
		{ "Rainbow Aura", "aura", { 255, 120, 220 }, nil, "rainbow" }, { "Angel Aura", "aura", { 255, 250, 220 }, nil, "sparkles" }, { "Demon Aura", "aura", { 255, 30, 60 }, nil, "fire" },
		{ "Cosmic Aura", "aura", { 140, 90, 255 }, nil, "sparkles" }, { "Galaxy Aura", "aura", { 100, 60, 255 }, nil, "rainbow" },
		{ "Ultra Master Aura", "aura", { 255, 90, 255 }, nil, "rainbow" }, { "Infinity Aura", "aura", { 255, 255, 255 }, nil, "rainbow" },
	},
}
for _, category in ipairs(Config.ItemCategories) do
	for i, def in ipairs(ITEM_DEFS[category]) do
		local itemId = category .. "_" .. i
		local stat = Config.ItemCategoryInfo[category].Stat
		if category == "Aura" then
			stat = ({ "Slaps", "Luck", "Gems" })[(i % 3) + 1]
		elseif category == "Back" and i % 4 == 0 then
			stat = "Slaps"
		end
		Config.Items[itemId] = {
			Id = itemId, Category = category, DisplayName = def[1], Form = def[2], Color = def[3], Material = def[4] or "SmoothPlastic",
			Effect = def[5], Rarity = ITEM_RARITY_BY_INDEX[i], Stat = stat,
		}
		table.insert(Config.ItemOrder, itemId)
	end
end

-- Kisten mit zufaelligen Items. Gewichte nach Seltenheit.
Config.ItemCrates = {
	{ Id = "StarterCrate", Name = "Starter Crate", Price = 5000, Currency = "Slaps", Count = 1, Weights = { Common = 80, Rare = 18, Epic = 2 } },
	{ Id = "BasicCrate", Name = "Basic Crate", Price = 60, Currency = "Gems", Count = 1, Weights = { Common = 55, Rare = 32, Epic = 12, Legendary = 1 } },
	{ Id = "RoyalCrate", Name = "Royal Crate", Price = 400, Currency = "Gems", Count = 1, Weights = { Rare = 40, Epic = 40, Legendary = 17, Mythic = 3 } },
	{ Id = "MythicCrate", Name = "Mythic Crate", Price = 2500, Currency = "Gems", Count = 1, Weights = { Epic = 40, Legendary = 45, Mythic = 15 } },
	-- ROBUX-KISTEN (Developer Products, R$100 bis R$10000). ProductId eintragen.
	{ Id = "RobuxCrate1", Name = "Bronze Robux Crate", Robux = 100, ProductId = 3736657221, Currency = "Robux", Count = 1, Weights = { Epic = 70, Legendary = 28, Mythic = 2 } },
	{ Id = "RobuxCrate2", Name = "Silver Robux Crate", Robux = 250, ProductId = 3736657390, Currency = "Robux", Count = 1, Weights = { Legendary = 70, Mythic = 28, Ultra = 2 } },
	{ Id = "RobuxCrate3", Name = "Gold Robux Crate", Robux = 500, ProductId = 3736657548, Currency = "Robux", Count = 1, Weights = { Legendary = 40, Mythic = 50, Ultra = 10 } },
	{ Id = "RobuxCrate4", Name = "Diamond Robux Crate", Robux = 1000, ProductId = 3736657678, Currency = "Robux", Count = 2, Weights = { Mythic = 60, Ultra = 38, UltraMaster = 2 } },
	{ Id = "RobuxCrate5", Name = "Ultra Crate", Robux = 2499, ProductId = 3736657829, Currency = "Robux", Count = 2, Weights = { Mythic = 30, Ultra = 60, UltraMaster = 10 } },
	{ Id = "RobuxCrate6", Name = "Master Crate", Robux = 4999, ProductId = 3736657928, Currency = "Robux", Count = 3, Weights = { Ultra = 70, UltraMaster = 30 } },
	{ Id = "RobuxCrate7", Name = "Ultra Master Crate", Robux = 9999, ProductId = 3736658082, Currency = "Robux", Count = 3, Weights = { UltraMaster = 100 } },
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
	{ Id = "PetSlot", DisplayName = "+1 Pet Slot", Icon = "🐾", Description = "Equip one more pet at the same time (up to 10).", Prices = { 150, 400, 900, 2000, 4500, 9000 } },
	{ Id = "Inventory", DisplayName = "+20 Pet Storage", Icon = "🎒", Description = "More room for your pets.", Prices = { 80, 200, 450, 1000, 2200 } },
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
	CenterX = -45,
	CenterZ = -90,
	Radius = 22,
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
	DashStrikeWindow = 0.6, -- Schlag kurz nach dem Dash = Dash-Schlag
	DashStrikeMultiplier = 1.5,
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
	{ Id = "Pack1", Gems = 150, Robux = 49, ProductId = 3736545082 },
	{ Id = "Pack2", Gems = 400, Robux = 99, ProductId = 3736545191 },
	{ Id = "Pack3", Gems = 1000, Robux = 199, ProductId = 3736545308 },
	{ Id = "Pack4", Gems = 2500, Robux = 449, ProductId = 3736545421, Tag = "POPULAR" },
	{ Id = "Pack5", Gems = 6500, Robux = 999, ProductId = 3736545488 },
	{ Id = "Pack6", Gems = 22000, Robux = 3000, ProductId = 3736545603, Tag = "BEST VALUE" },
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
Config.HubLength = 120
Config.SpawnPosition = { 0, -55 }

return Config
