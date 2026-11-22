--[[
	SlapShared/Config  (ModuleScript)

	ALLE Spielwerte von "Slap the Gyatt" an einem Ort.
	Keine Roblox-APIs hier drin -> funktioniert auf Server und Client gleich.
	Farben sind { R, G, B } Tabellen (0-255).
]]

local Config = {}

Config.GameName = "Slap the Gyatt"
Config.Version = "2.0"

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
--------------------------------------------------------------------------
Config.UpgradeOrder = { "Power", "Speed", "Reach", "Luck", "Greed", "Combo" }

Config.Upgrades = {
	Power = {
		DisplayName = "Hand-Staerke",
		Icon = "💪",
		Description = "Mehr Schaden pro Slap - und deine Hand waechst!",
		MaxLevel = 60,
		BaseCost = 15,
		CostGrowth = 1.33,
	},
	Speed = {
		DisplayName = "Slap-Tempo",
		Icon = "⚡",
		Description = "Kuerzere Wartezeit zwischen zwei Slaps.",
		MaxLevel = 30,
		BaseCost = 40,
		CostGrowth = 1.55,
	},
	Reach = {
		DisplayName = "Reichweite",
		Icon = "📏",
		Description = "Triff den Gyatt aus groesserer Entfernung.",
		MaxLevel = 20,
		BaseCost = 60,
		CostGrowth = 1.6,
	},
	Luck = {
		DisplayName = "Krit-Glueck",
		Icon = "🍀",
		Description = "Mehr Chance auf kritische Slaps (x3 Schaden).",
		MaxLevel = 30,
		BaseCost = 100,
		CostGrowth = 1.5,
	},
	Greed = {
		DisplayName = "Slap-Gier",
		Icon = "💰",
		Description = "Mehr Slaps fuer jeden Treffer.",
		MaxLevel = 50,
		BaseCost = 150,
		CostGrowth = 1.42,
	},
	Combo = {
		DisplayName = "Combo-Meister",
		Icon = "🔥",
		Description = "Hoehere maximale Combo = mehr Bonus-Slaps.",
		MaxLevel = 20,
		BaseCost = 500,
		CostGrowth = 1.7,
	},
}

--------------------------------------------------------------------------
-- Haende (permanent, bleiben nach Rebirth)
--   Effect: "none" | "sparkles" | "fire" | "smoke" | "rainbow"
--------------------------------------------------------------------------
Config.Hands = {
	{ Id = "Wood", DisplayName = "Holz-Hand", Damage = 1, Price = 0, Currency = "Slaps", Color = { 165, 115, 70 }, Material = "Wood", Effect = "none" },
	{ Id = "Stone", DisplayName = "Stein-Hand", Damage = 1.5, Price = 500, Currency = "Slaps", Color = { 125, 125, 130 }, Material = "Slate", Effect = "none" },
	{ Id = "Iron", DisplayName = "Eisen-Hand", Damage = 2.2, Price = 7500, Currency = "Slaps", Color = { 195, 200, 210 }, Material = "DiamondPlate", Effect = "none" },
	{ Id = "Gold", DisplayName = "Gold-Hand", Damage = 3.5, Price = 60000, Currency = "Slaps", Color = { 255, 200, 40 }, Material = "Foil", Effect = "sparkles" },
	{ Id = "Emerald", DisplayName = "Smaragd-Hand", Damage = 5, Price = 600000, Currency = "Slaps", Color = { 40, 220, 110 }, Material = "Glass", Effect = "sparkles" },
	{ Id = "Diamond", DisplayName = "Diamant-Hand", Damage = 8, Price = 8000000, Currency = "Slaps", Color = { 120, 230, 255 }, Material = "Glass", Effect = "sparkles" },
	{ Id = "Ice", DisplayName = "Frost-Hand", Damage = 12, Price = 90000000, Currency = "Slaps", Color = { 190, 235, 255 }, Material = "Ice", Effect = "smoke" },
	{ Id = "Lava", DisplayName = "Lava-Hand", Damage = 18, Price = 1200000000, Currency = "Slaps", Color = { 255, 110, 20 }, Material = "Neon", Effect = "fire" },
	{ Id = "Cloud", DisplayName = "Wolken-Hand", Damage = 27, Price = 20000000000, Currency = "Slaps", Color = { 250, 250, 255 }, Material = "SmoothPlastic", Effect = "sparkles" },
	{ Id = "Galaxy", DisplayName = "Galaxie-Hand", Damage = 40, Price = 400000000000, Currency = "Slaps", Color = { 120, 50, 220 }, Material = "Neon", Effect = "sparkles" },
	{ Id = "Rainbow", DisplayName = "Regenbogen-Hand", Damage = 60, Price = 8000000000000, Currency = "Slaps", Color = { 255, 80, 200 }, Material = "Neon", Effect = "rainbow" },
	{ Id = "GyattGod", DisplayName = "Gyatt-Gott-Hand", Damage = 100, Price = 2500, Currency = "Gems", Color = { 255, 235, 120 }, Material = "Neon", Effect = "fire" },
}

--------------------------------------------------------------------------
-- Seltenheiten
--------------------------------------------------------------------------
Config.RarityOrder = { "Common", "Rare", "Epic", "Legendary", "Mythic" }
Config.Rarities = {
	Common = { DisplayName = "Gewoehnlich", Color = { 200, 200, 200 }, Order = 1 },
	Rare = { DisplayName = "Selten", Color = { 80, 170, 255 }, Order = 2 },
	Epic = { DisplayName = "Episch", Color = { 190, 90, 255 }, Order = 3 },
	Legendary = { DisplayName = "Legendaer", Color = { 255, 190, 40 }, Order = 4 },
	Mythic = { DisplayName = "Mythisch", Color = { 255, 60, 120 }, Order = 5 },
}

--------------------------------------------------------------------------
-- Pets. Boost = Bonus auf Slaps (+Boost, also 0.5 = +50%)
--   Style: Aussehen ("dog","cat","bunny","bear","slime","bird","dragon","ghost","robot","alien","whale","unicorn")
--------------------------------------------------------------------------
Config.Pets = {
	-- Wiese
	Dog = { DisplayName = "Hund", Rarity = "Common", Boost = 0.1, Color = { 200, 150, 100 }, Style = "dog" },
	Cat = { DisplayName = "Katze", Rarity = "Common", Boost = 0.15, Color = { 255, 170, 80 }, Style = "cat" },
	Bunny = { DisplayName = "Hase", Rarity = "Rare", Boost = 0.3, Color = { 255, 255, 255 }, Style = "bunny" },
	Bear = { DisplayName = "Baer", Rarity = "Epic", Boost = 0.6, Color = { 140, 90, 60 }, Style = "bear" },
	-- Wueste
	Camel = { DisplayName = "Kamel", Rarity = "Common", Boost = 0.5, Color = { 210, 170, 110 }, Style = "bear" },
	Scorpion = { DisplayName = "Skorpion", Rarity = "Rare", Boost = 0.8, Color = { 120, 60, 40 }, Style = "slime" },
	Fennec = { DisplayName = "Wuestenfuchs", Rarity = "Epic", Boost = 1.2, Color = { 240, 200, 140 }, Style = "cat" },
	Sphinx = { DisplayName = "Sphinx", Rarity = "Legendary", Boost = 2.5, Color = { 230, 190, 80 }, Style = "cat" },
	-- Eis
	Penguin = { DisplayName = "Pinguin", Rarity = "Common", Boost = 1.5, Color = { 40, 40, 60 }, Style = "bird" },
	PolarBear = { DisplayName = "Eisbaer", Rarity = "Rare", Boost = 2.2, Color = { 240, 245, 255 }, Style = "bear" },
	Yeti = { DisplayName = "Yeti", Rarity = "Epic", Boost = 4, Color = { 200, 230, 255 }, Style = "bear" },
	FrostDragon = { DisplayName = "Frost-Drache", Rarity = "Legendary", Boost = 8, Color = { 120, 200, 255 }, Style = "dragon" },
	-- Lava
	FireSlime = { DisplayName = "Feuer-Slime", Rarity = "Common", Boost = 5, Color = { 255, 120, 30 }, Style = "slime" },
	MagmaDog = { DisplayName = "Magma-Hund", Rarity = "Rare", Boost = 7, Color = { 200, 50, 20 }, Style = "dog" },
	Phoenix = { DisplayName = "Phoenix", Rarity = "Epic", Boost = 13, Color = { 255, 170, 30 }, Style = "bird" },
	LavaDragon = { DisplayName = "Lava-Drache", Rarity = "Legendary", Boost = 24, Color = { 255, 60, 0 }, Style = "dragon" },
	-- Wolken
	CloudSheep = { DisplayName = "Wolken-Schaf", Rarity = "Common", Boost = 14, Color = { 250, 250, 255 }, Style = "slime" },
	AngelCat = { DisplayName = "Engel-Katze", Rarity = "Rare", Boost = 21, Color = { 255, 240, 200 }, Style = "cat" },
	Unicorn = { DisplayName = "Einhorn", Rarity = "Epic", Boost = 39, Color = { 255, 200, 240 }, Style = "unicorn" },
	SkyDragon = { DisplayName = "Himmels-Drache", Rarity = "Legendary", Boost = 74, Color = { 150, 220, 255 }, Style = "dragon" },
	-- Galaxie
	Alien = { DisplayName = "Alien", Rarity = "Common", Boost = 49, Color = { 120, 255, 120 }, Style = "alien" },
	RoboDog = { DisplayName = "Robo-Hund", Rarity = "Rare", Boost = 69, Color = { 170, 180, 200 }, Style = "robot" },
	StarWhale = { DisplayName = "Sternen-Wal", Rarity = "Epic", Boost = 119, Color = { 60, 80, 200 }, Style = "whale" },
	GyattGodPet = { DisplayName = "Gyatt-Gott", Rarity = "Mythic", Boost = 299, Color = { 255, 220, 90 }, Style = "ghost" },
	-- Gem-Ei
	GoldenDog = { DisplayName = "Goldener Hund", Rarity = "Rare", Boost = 3, Color = { 255, 210, 50 }, Style = "dog" },
	GoldenCat = { DisplayName = "Goldene Katze", Rarity = "Epic", Boost = 9, Color = { 255, 200, 30 }, Style = "cat" },
	GoldenDragon = { DisplayName = "Goldener Drache", Rarity = "Legendary", Boost = 35, Color = { 255, 215, 0 }, Style = "dragon" },
	Ghost = { DisplayName = "Slap-Geist", Rarity = "Mythic", Boost = 150, Color = { 230, 230, 255 }, Style = "ghost" },
}

--------------------------------------------------------------------------
-- Eier. Pets = { {PetId, Gewicht}, ... }
--------------------------------------------------------------------------
Config.Eggs = {
	Basic = { DisplayName = "Wiesen-Ei", Price = 250, Currency = "Slaps", Color = { 255, 240, 200 }, Zone = 1,
		Pets = { { "Dog", 55 }, { "Cat", 32 }, { "Bunny", 11 }, { "Bear", 2 } } },
	Desert = { DisplayName = "Wuesten-Ei", Price = 15000, Currency = "Slaps", Color = { 240, 200, 120 }, Zone = 2,
		Pets = { { "Camel", 55 }, { "Scorpion", 30 }, { "Fennec", 13 }, { "Sphinx", 2 } } },
	Ice = { DisplayName = "Eis-Ei", Price = 1000000, Currency = "Slaps", Color = { 190, 230, 255 }, Zone = 3,
		Pets = { { "Penguin", 55 }, { "PolarBear", 30 }, { "Yeti", 13 }, { "FrostDragon", 2 } } },
	Lava = { DisplayName = "Lava-Ei", Price = 60000000, Currency = "Slaps", Color = { 255, 100, 40 }, Zone = 4,
		Pets = { { "FireSlime", 55 }, { "MagmaDog", 30 }, { "Phoenix", 13 }, { "LavaDragon", 2 } } },
	Cloud = { DisplayName = "Wolken-Ei", Price = 5000000000, Currency = "Slaps", Color = { 250, 250, 255 }, Zone = 5,
		Pets = { { "CloudSheep", 55 }, { "AngelCat", 30 }, { "Unicorn", 13 }, { "SkyDragon", 2 } } },
	Galaxy = { DisplayName = "Galaxie-Ei", Price = 400000000000, Currency = "Slaps", Color = { 110, 60, 200 }, Zone = 6,
		Pets = { { "Alien", 55 }, { "RoboDog", 30 }, { "StarWhale", 14.9 }, { "GyattGodPet", 0.1 } } },
	Golden = { DisplayName = "Gold-Ei", Price = 75, Currency = "Gems", Color = { 255, 210, 40 }, Zone = 1,
		Pets = { { "GoldenDog", 60 }, { "GoldenCat", 30 }, { "GoldenDragon", 9.5 }, { "Ghost", 0.5 } } },
}
Config.EggOrder = { "Basic", "Golden", "Desert", "Ice", "Lava", "Cloud", "Galaxy" }

Config.BasePetSlots = 3
Config.BaseInventory = 40
Config.LuckyBoostFactor = 2.5 -- Gewicht seltener Pets mit Glueck-Boost

--------------------------------------------------------------------------
-- Zonen. Jede Zone hat 2 Gyatts und ein Ei.
--   Decor: "meadow" | "desert" | "ice" | "lava" | "cloud" | "space"
--   Accessories: "bow" "glasses" "cowboy" "scarf" "horns" "halo" "antenna" "crown"
--------------------------------------------------------------------------
Config.ZoneLength = 130
Config.ZoneWidth = 120

Config.Zones = {
	{
		Name = "Gyatt-Wiese", Price = 0, Decor = "meadow",
		Floor = { 105, 200, 105 }, FloorMaterial = "Grass", Accent = { 255, 120, 180 }, Path = { 230, 210, 160 },
		Egg = "Basic",
		Gyatts = {
			{ Id = "Baby", DisplayName = "Baby Gyatt", MaxHealth = 40, Size = 7, Color = { 255, 175, 205 }, RewardMultiplier = 1, Gems = 1, Accessories = { "bow" } },
			{ Id = "Big", DisplayName = "Big Gyatt", MaxHealth = 400, Size = 11, Color = { 255, 125, 165 }, RewardMultiplier = 2, Gems = 2, Accessories = { "bow", "glasses" } },
		},
	},
	{
		Name = "Wuesten-Gyatt", Price = 2500, Decor = "desert",
		Floor = { 235, 205, 140 }, FloorMaterial = "Sand", Accent = { 255, 170, 60 }, Path = { 200, 160, 100 },
		Egg = "Desert",
		Gyatts = {
			{ Id = "Cactus", DisplayName = "Kaktus Gyatt", MaxHealth = 4000, Size = 9, Color = { 120, 200, 90 }, RewardMultiplier = 4, Gems = 2, Accessories = { "cowboy" } },
			{ Id = "Pharao", DisplayName = "Pharao Gyatt", MaxHealth = 20000, Size = 13, Color = { 240, 190, 70 }, RewardMultiplier = 8, Gems = 4, Accessories = { "crown", "glasses" } },
		},
	},
	{
		Name = "Eis-Gyatt-Land", Price = 150000, Decor = "ice",
		Floor = { 225, 240, 255 }, FloorMaterial = "Snow", Accent = { 120, 200, 255 }, Path = { 170, 215, 245 },
		Egg = "Ice",
		Gyatts = {
			{ Id = "Snow", DisplayName = "Schnee Gyatt", MaxHealth = 150000, Size = 10, Color = { 240, 248, 255 }, RewardMultiplier = 15, Gems = 3, Accessories = { "scarf" } },
			{ Id = "Frost", DisplayName = "Frost Gyatt", MaxHealth = 750000, Size = 15, Color = { 140, 210, 255 }, RewardMultiplier = 30, Gems = 6, Accessories = { "scarf", "crown" } },
		},
	},
	{
		Name = "Lava-Gyatt-Vulkan", Price = 10000000, Decor = "lava",
		Floor = { 70, 45, 40 }, FloorMaterial = "Basalt", Accent = { 255, 90, 20 }, Path = { 120, 60, 40 },
		Egg = "Lava",
		Gyatts = {
			{ Id = "Magma", DisplayName = "Magma Gyatt", MaxHealth = 5000000, Size = 11, Color = { 255, 100, 40 }, RewardMultiplier = 60, Gems = 4, Accessories = { "horns" } },
			{ Id = "Inferno", DisplayName = "Inferno Gyatt", MaxHealth = 25000000, Size = 17, Color = { 200, 30, 20 }, RewardMultiplier = 120, Gems = 8, Accessories = { "horns", "crown" } },
		},
	},
	{
		Name = "Wolken-Gyatt-Himmel", Price = 750000000, Decor = "cloud",
		Floor = { 245, 245, 255 }, FloorMaterial = "SmoothPlastic", Accent = { 255, 220, 120 }, Path = { 255, 235, 170 },
		Egg = "Cloud",
		Gyatts = {
			{ Id = "Angel", DisplayName = "Engel Gyatt", MaxHealth = 150000000, Size = 12, Color = { 255, 250, 235 }, RewardMultiplier = 250, Gems = 5, Accessories = { "halo" } },
			{ Id = "Heaven", DisplayName = "Himmels Gyatt", MaxHealth = 750000000, Size = 18, Color = { 255, 225, 150 }, RewardMultiplier = 500, Gems = 10, Accessories = { "halo", "crown" } },
		},
	},
	{
		Name = "Galaxie-Gyatt-Weltall", Price = 50000000000, Decor = "space",
		Floor = { 35, 25, 70 }, FloorMaterial = "SmoothPlastic", Accent = { 160, 90, 255 }, Path = { 80, 60, 140 },
		Egg = "Galaxy",
		Gyatts = {
			{ Id = "Alien", DisplayName = "Alien Gyatt", MaxHealth = 5000000000, Size = 14, Color = { 130, 255, 140 }, RewardMultiplier = 1000, Gems = 6, Accessories = { "antenna" } },
			{ Id = "God", DisplayName = "GYATT GOTT", MaxHealth = 25000000000, Size = 24, Color = { 90, 230, 255 }, RewardMultiplier = 2000, Gems = 15, Accessories = { "halo", "crown", "glasses" } },
		},
	},
}

-- Goldener Gyatt (Server-Event)
Config.GoldenGyatt = {
	DisplayName = "⭐ GOLDENER GYATT ⭐",
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
	{ Id = "AutoSlap", DisplayName = "Auto-Slap", Icon = "🤖", Description = "Slappt automatisch, wenn du nah an einem Gyatt bist.", Prices = { 200 } },
	{ Id = "PetSlot", DisplayName = "+1 Pet-Platz", Icon = "🐾", Description = "Ruest ein Pet mehr gleichzeitig aus.", Prices = { 150, 400, 900 } },
	{ Id = "Inventory", DisplayName = "+20 Pet-Inventar", Icon = "🎒", Description = "Mehr Platz fuer deine Pets.", Prices = { 80, 200, 450 } },
	{ Id = "DoubleSlaps", DisplayName = "2x Slaps (15 Min)", Icon = "⏫", Description = "Doppelte Slaps fuer 15 Minuten.", Prices = { 60 }, Boost = "DoubleSlaps", Duration = 900, Repeatable = true },
	{ Id = "LuckyEggs", DisplayName = "Ei-Glueck (15 Min)", Icon = "🌈", Description = "Seltene Pets kommen viel oefter.", Prices = { 40 }, Boost = "LuckyEggs", Duration = 900, Repeatable = true },
	{ Id = "DoubleDamage", DisplayName = "2x Schaden (15 Min)", Icon = "🥊", Description = "Doppelter Schaden fuer 15 Minuten.", Prices = { 60 }, Boost = "DoubleDamage", Duration = 900, Repeatable = true },
}

Config.Boosts = {
	DoubleSlaps = { DisplayName = "2x Slaps", Icon = "⏫", Color = { 120, 255, 140 } },
	LuckyEggs = { DisplayName = "Ei-Glueck", Icon = "🌈", Color = { 255, 150, 255 } },
	DoubleDamage = { DisplayName = "2x Schaden", Icon = "🥊", Color = { 255, 140, 120 } },
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
	{ Id = "Slap", Stat = "Slaps", Text = "Slappe %s mal", Amounts = { 150, 400, 800 }, Gems = { 10, 20, 35 } },
	{ Id = "Defeat", Stat = "Defeats", Text = "Besiege %s Gyatts", Amounts = { 3, 8, 15 }, Gems = { 12, 25, 40 } },
	{ Id = "Combo", Stat = "BestCombo", Text = "Erreiche eine %ser Combo", Amounts = { 20, 50, 100 }, Gems = { 10, 20, 40 } },
	{ Id = "Eggs", Stat = "Eggs", Text = "Oeffne %s Eier", Amounts = { 2, 5, 10 }, Gems = { 10, 20, 35 } },
	{ Id = "Upgrades", Stat = "Upgrades", Text = "Kaufe %s Upgrades", Amounts = { 3, 8, 15 }, Gems = { 8, 18, 30 } },
	{ Id = "Crits", Stat = "Crits", Text = "Lande %s kritische Slaps", Amounts = { 15, 40, 80 }, Gems = { 10, 20, 35 } },
	{ Id = "Pvp", Stat = "PvpSlaps", Text = "Slappe %s Spieler in der Arena", Amounts = { 3, 8, 15 }, Gems = { 10, 20, 35 } },
}

--------------------------------------------------------------------------
-- Codes (Gross-/Kleinschreibung egal)
--------------------------------------------------------------------------
Config.Codes = {
	GYATT = { Gems = 50 },
	SLAP = { Gems = 25, Boost = "DoubleSlaps", Duration = 600 },
	RELEASE = { Gems = 100 },
	BIGHAND = { Boost = "DoubleDamage", Duration = 900 },
	LUCKY = { Boost = "LuckyEggs", Duration = 900 },
}

--------------------------------------------------------------------------
-- PvP-Arena
--------------------------------------------------------------------------
Config.Arena = {
	CenterX = -34,
	CenterZ = -38,
	Radius = 20,
	BaseKnockback = 45,
	KnockbackPerPower = 1.2,
	MaxKnockback = 140,
	UpForce = 35,
}

-- Hub (Startbereich) liegt bei Z < 0
Config.HubLength = 80
Config.SpawnPosition = { 10, -52 }

return Config
