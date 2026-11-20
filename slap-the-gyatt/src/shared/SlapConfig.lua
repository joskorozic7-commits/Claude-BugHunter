--[[
	SlapConfig (ModuleScript in ReplicatedStorage)

	Alle Spielwerte von "Slap the Gyatt" an einem Ort.
	Dieses Modul benutzt absichtlich KEINE Roblox-APIs, damit es auf
	Server und Client identisch funktioniert (und auch ausserhalb von
	Roblox getestet werden kann).
]]

local Config = {}

-- Name des DataStores. Wenn du den Spielstand aller Spieler zuruecksetzen
-- willst, aendere einfach die Versionsnummer am Ende.
Config.DataStoreName = "SlapTheGyatt_Data_v1"
Config.AutosaveInterval = 120 -- Sekunden

Config.CritMultiplier = 3
Config.GyattRespawnTime = 5 -- Sekunden bis ein besiegter Gyatt wieder erscheint

-- Rebirth: setzt Slaps und Upgrades zurueck, gibt dafuer einen dauerhaften Bonus.
Config.RebirthBaseCost = 100000
Config.RebirthCostGrowth = 3
Config.RebirthBonusPerRebirth = 0.5 -- +50% Slaps pro Rebirth

--------------------------------------------------------------------------
-- Upgrades fuer die Hand
--------------------------------------------------------------------------
-- order bestimmt die Reihenfolge im Shop.
Config.UpgradeOrder = { "Power", "Speed", "Reach", "Luck", "Greed" }

Config.Upgrades = {
	Power = {
		DisplayName = "Hand-Staerke",
		Icon = "💪",
		Description = "Mehr Schaden pro Slap. Deine Hand wird groesser!",
		MaxLevel = 50,
		BaseCost = 15,
		CostGrowth = 1.3,
	},
	Speed = {
		DisplayName = "Slap-Tempo",
		Icon = "⚡",
		Description = "Du kannst schneller hintereinander slappen.",
		MaxLevel = 25,
		BaseCost = 40,
		CostGrowth = 1.45,
	},
	Reach = {
		DisplayName = "Reichweite",
		Icon = "📏",
		Description = "Du triffst den Gyatt aus groesserer Entfernung.",
		MaxLevel = 20,
		BaseCost = 60,
		CostGrowth = 1.5,
	},
	Luck = {
		DisplayName = "Krit-Glueck",
		Icon = "🍀",
		Description = "Hoehere Chance auf einen kritischen Slap (x3 Schaden).",
		MaxLevel = 25,
		BaseCost = 100,
		CostGrowth = 1.42,
	},
	Greed = {
		DisplayName = "Slap-Gier",
		Icon = "💰",
		Description = "Du bekommst mehr Slaps fuer jeden Treffer.",
		MaxLevel = 40,
		BaseCost = 150,
		CostGrowth = 1.45,
	},
}

--------------------------------------------------------------------------
-- Formeln
--------------------------------------------------------------------------
local function clampLevel(id, level)
	local upgrade = Config.Upgrades[id]
	level = tonumber(level) or 0
	level = math.floor(level)
	if level < 0 then
		level = 0
	end
	if upgrade and level > upgrade.MaxLevel then
		level = upgrade.MaxLevel
	end
	return level
end
Config.ClampLevel = clampLevel

-- Preis fuer das NAECHSTE Level (aktuelles Level -> Level + 1).
-- Gibt nil zurueck, wenn das Maximum erreicht ist.
function Config.GetUpgradeCost(id, currentLevel)
	local upgrade = Config.Upgrades[id]
	if not upgrade then
		return nil
	end
	currentLevel = clampLevel(id, currentLevel)
	if currentLevel >= upgrade.MaxLevel then
		return nil
	end
	return math.floor(upgrade.BaseCost * (upgrade.CostGrowth ^ currentLevel))
end

-- Schaden pro Slap
function Config.GetDamage(powerLevel)
	powerLevel = clampLevel("Power", powerLevel)
	return math.floor((1 + powerLevel) * (1.15 ^ powerLevel))
end

-- Wartezeit zwischen zwei Slaps (Sekunden)
function Config.GetCooldown(speedLevel)
	speedLevel = clampLevel("Speed", speedLevel)
	local cooldown = 0.8 * (0.93 ^ speedLevel)
	if cooldown < 0.15 then
		cooldown = 0.15
	end
	return cooldown
end

-- Reichweite in Studs (Abstand zur Oberflaeche des Gyatts)
function Config.GetReach(reachLevel)
	reachLevel = clampLevel("Reach", reachLevel)
	return 6 + reachLevel * 1.5
end

-- Chance auf kritischen Treffer (0 bis 1)
function Config.GetCritChance(luckLevel)
	luckLevel = clampLevel("Luck", luckLevel)
	return 0.02 + luckLevel * 0.02
end

-- Multiplikator aus dem Gier-Upgrade
function Config.GetGreedMultiplier(greedLevel)
	greedLevel = clampLevel("Greed", greedLevel)
	return 1 + greedLevel * 0.25
end

-- Multiplikator aus Rebirths
function Config.GetRebirthMultiplier(rebirths)
	rebirths = math.max(0, math.floor(tonumber(rebirths) or 0))
	return 1 + rebirths * Config.RebirthBonusPerRebirth
end

function Config.GetRebirthCost(rebirths)
	rebirths = math.max(0, math.floor(tonumber(rebirths) or 0))
	return math.floor(Config.RebirthBaseCost * (Config.RebirthCostGrowth ^ rebirths))
end

-- Groesse der Hand (Skalierungsfaktor)
function Config.GetHandScale(powerLevel)
	powerLevel = clampLevel("Power", powerLevel)
	return 1 + powerLevel * 0.03
end

-- Beschreibung des aktuellen Werts eines Upgrades (fuer den Shop)
function Config.DescribeStat(id, level)
	if id == "Power" then
		return Config.FormatNumber(Config.GetDamage(level)) .. " Schaden"
	elseif id == "Speed" then
		return string.format("%.2f s Cooldown", Config.GetCooldown(level))
	elseif id == "Reach" then
		return string.format("%.1f Studs", Config.GetReach(level))
	elseif id == "Luck" then
		return string.format("%d%% Krit", math.floor(Config.GetCritChance(level) * 100 + 0.5))
	elseif id == "Greed" then
		return string.format("x%.2f Slaps", Config.GetGreedMultiplier(level))
	end
	return ""
end

--------------------------------------------------------------------------
-- Hand-Stufen (Aussehen der Hand je nach Staerke-Level)
--------------------------------------------------------------------------
Config.HandTiers = {
	{ MinLevel = 0, Name = "Holz-Hand", Color = { 160, 110, 70 }, Material = "Wood" },
	{ MinLevel = 5, Name = "Stein-Hand", Color = { 130, 130, 130 }, Material = "Slate" },
	{ MinLevel = 12, Name = "Eisen-Hand", Color = { 190, 195, 205 }, Material = "Metal" },
	{ MinLevel = 20, Name = "Gold-Hand", Color = { 255, 200, 40 }, Material = "Foil" },
	{ MinLevel = 30, Name = "Diamant-Hand", Color = { 90, 220, 255 }, Material = "Glass" },
	{ MinLevel = 40, Name = "Regenbogen-Hand", Color = { 255, 80, 200 }, Material = "Neon" },
}

function Config.GetHandTier(powerLevel)
	powerLevel = clampLevel("Power", powerLevel)
	local result = Config.HandTiers[1]
	for _, tier in ipairs(Config.HandTiers) do
		if powerLevel >= tier.MinLevel then
			result = tier
		end
	end
	return result
end

--------------------------------------------------------------------------
-- Die Gyatts (Gegner). Position Z = Abstand vom Spawn.
--------------------------------------------------------------------------
Config.Gyatts = {
	{
		Id = "Baby",
		DisplayName = "Baby Gyatt",
		MaxHealth = 50,
		Size = 6,
		Color = { 255, 170, 200 },
		PositionX = 0,
		PositionZ = 35,
		RewardMultiplier = 1,
		DefeatBonus = 25,
		RequiredPower = 0,
	},
	{
		Id = "Big",
		DisplayName = "Big Gyatt",
		MaxHealth = 1000,
		Size = 10,
		Color = { 255, 120, 160 },
		PositionX = 0,
		PositionZ = 75,
		RewardMultiplier = 3,
		DefeatBonus = 600,
		RequiredPower = 5,
	},
	{
		Id = "Mega",
		DisplayName = "Mega Gyatt",
		MaxHealth = 25000,
		Size = 14,
		Color = { 200, 90, 255 },
		PositionX = 0,
		PositionZ = 125,
		RewardMultiplier = 8,
		DefeatBonus = 15000,
		RequiredPower = 12,
	},
	{
		Id = "King",
		DisplayName = "King Gyatt",
		MaxHealth = 500000,
		Size = 20,
		Color = { 255, 210, 60 },
		PositionX = 0,
		PositionZ = 190,
		RewardMultiplier = 20,
		DefeatBonus = 300000,
		RequiredPower = 22,
	},
	{
		Id = "God",
		DisplayName = "Gyatt Gott",
		MaxHealth = 10000000,
		Size = 28,
		Color = { 90, 230, 255 },
		PositionX = 0,
		PositionZ = 275,
		RewardMultiplier = 50,
		DefeatBonus = 6000000,
		RequiredPower = 35,
	},
}

--------------------------------------------------------------------------
-- Zahlen huebsch formatieren: 1234 -> 1.23K, 5000000 -> 5M
--------------------------------------------------------------------------
local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

function Config.FormatNumber(n)
	n = tonumber(n) or 0
	if n ~= n then -- NaN
		return "0"
	end
	local negative = n < 0
	if negative then
		n = -n
	end
	local index = 1
	while n >= 1000 and index < #SUFFIXES do
		n = n / 1000
		index = index + 1
	end
	local text
	if index == 1 then
		text = tostring(math.floor(n))
	elseif n >= 100 then
		text = string.format("%d", math.floor(n)) .. SUFFIXES[index]
	elseif n >= 10 then
		text = string.format("%.1f", math.floor(n * 10) / 10) .. SUFFIXES[index]
	else
		text = string.format("%.2f", math.floor(n * 100) / 100) .. SUFFIXES[index]
	end
	if negative then
		text = "-" .. text
	end
	return text
end

return Config
