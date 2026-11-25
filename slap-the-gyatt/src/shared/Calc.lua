--[[
	SlapShared/Calc  (ModuleScript)

	Alle Formeln. Wird von Server UND Client benutzt, damit die Anzeige
	immer genau zu dem passt, was der Server rechnet.
	Benutzt keine Roblox-APIs.
]]

local Config = require(script.Parent:WaitForChild("Config"))

local Calc = {}

--------------------------------------------------------------------------
-- Zahlen & Zeit
--------------------------------------------------------------------------
local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc", "Ud", "Dd", "Td" }

function Calc.FormatNumber(n)
	n = tonumber(n) or 0
	if n ~= n then
		return "0"
	end
	if n == math.huge then
		return "∞"
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
		text = tostring(math.floor(n)) .. SUFFIXES[index]
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

function Calc.FormatTime(seconds)
	seconds = math.max(0, math.floor(tonumber(seconds) or 0))
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60
	if hours > 0 then
		return string.format("%dh %02dm", hours, minutes)
	end
	return string.format("%02d:%02d", minutes, secs)
end

function Calc.FormatMultiplier(m)
	if m >= 1000 then
		return "x" .. Calc.FormatNumber(m)
	elseif m >= 100 then
		return string.format("x%d", math.floor(m))
	end
	return string.format("x%.2f", m)
end

--------------------------------------------------------------------------
-- Upgrades
--------------------------------------------------------------------------
function Calc.ClampLevel(id, level)
	local upgrade = Config.Upgrades[id]
	level = math.floor(tonumber(level) or 0)
	if level ~= level or level < 0 then
		level = 0
	end
	if upgrade and level > upgrade.MaxLevel then
		level = upgrade.MaxLevel
	end
	return level
end

-- Tier eines Upgrade-Levels (0 = Bronze, 1 = Silver, ...)
function Calc.GetTier(level)
	level = math.max(0, math.floor(tonumber(level) or 0))
	return math.floor(level / Config.TierSize)
end

function Calc.GetTierInfo(tier)
	tier = math.max(0, math.floor(tonumber(tier) or 0))
	local info = Config.Tiers[tier + 1] or Config.Tiers[#Config.Tiers]
	return info, tier
end

function Calc.GetTierMultiplier(level)
	return (Calc.GetTierInfo(Calc.GetTier(level))).Multiplier
end

-- Ist der naechste Kauf (Level -> Level+1) ein Tier-Up?
function Calc.IsTierUp(id, currentLevel)
	currentLevel = Calc.ClampLevel(id, currentLevel)
	return (currentLevel + 1) % Config.TierSize == 0
end

-- Preis fuer das naechste Level. Gibt Slaps, Gems zurueck (nil wenn Max-Level).
function Calc.GetUpgradeCost(id, currentLevel)
	local upgrade = Config.Upgrades[id]
	if not upgrade then
		return nil
	end
	currentLevel = Calc.ClampLevel(id, currentLevel)
	if currentLevel >= upgrade.MaxLevel then
		return nil
	end
	local tier = Calc.GetTier(currentLevel)
	local cost = upgrade.BaseCost * (upgrade.CostGrowth ^ currentLevel) * (Config.TierCostGrowth ^ tier)
	local gems = 0
	if Calc.IsTierUp(id, currentLevel) then
		cost = cost * Config.TierUpCostMultiplier
		local newTier = tier + 1
		gems = Config.TierUpGems * newTier * newTier
	end
	return math.floor(cost), gems
end

function Calc.GetBaseDamage(powerLevel)
	powerLevel = Calc.ClampLevel("Power", powerLevel)
	return math.floor((1 + powerLevel) * (1.09 ^ powerLevel) * Calc.GetTierMultiplier(powerLevel))
end

function Calc.GetCooldown(speedLevel)
	speedLevel = Calc.ClampLevel("Speed", speedLevel)
	return math.max(0.1, 0.8 * (0.965 ^ speedLevel) / (1 + 0.15 * Calc.GetTier(speedLevel)))
end

function Calc.GetReach(reachLevel)
	reachLevel = Calc.ClampLevel("Reach", reachLevel)
	return 6 + reachLevel * 0.5 + Calc.GetTier(reachLevel) * 3
end

function Calc.GetCritChance(luckLevel)
	luckLevel = Calc.ClampLevel("Luck", luckLevel)
	return 0.03 + luckLevel * 0.005 + Calc.GetTier(luckLevel) * 0.025
end

function Calc.GetGreedMultiplier(greedLevel)
	greedLevel = Calc.ClampLevel("Greed", greedLevel)
	return (1 + greedLevel * 0.12) * Calc.GetTierMultiplier(greedLevel)
end

function Calc.GetMaxCombo(comboLevel)
	comboLevel = Calc.ClampLevel("Combo", comboLevel)
	return 25 + comboLevel * 4 + Calc.GetTier(comboLevel) * 20
end

function Calc.GetComboMultiplier(combo)
	combo = math.max(0, math.floor(tonumber(combo) or 0))
	return 1 + combo * Config.ComboBonusPerStack
end

function Calc.GetHandScale(powerLevel)
	powerLevel = Calc.ClampLevel("Power", powerLevel)
	return 1 + math.min(powerLevel, 60) * 0.025
end

function Calc.DescribeUpgrade(id, level)
	if id == "Power" then
		return Calc.FormatNumber(Calc.GetBaseDamage(level)) .. " base damage"
	elseif id == "Speed" then
		return string.format("%.2f s", Calc.GetCooldown(level))
	elseif id == "Reach" then
		return string.format("%.1f Studs", Calc.GetReach(level))
	elseif id == "Luck" then
		return string.format("%.1f%% crit", Calc.GetCritChance(level) * 100)
	elseif id == "Greed" then
		return Calc.FormatMultiplier(Calc.GetGreedMultiplier(level)) .. " Slaps"
	elseif id == "Combo" then
		return "Max Combo " .. Calc.GetMaxCombo(level)
	end
	return ""
end

--------------------------------------------------------------------------
-- Rebirth
--------------------------------------------------------------------------
local function cleanCount(n)
	n = math.floor(tonumber(n) or 0)
	if n ~= n or n < 0 then
		return 0
	end
	return n
end

function Calc.GetRebirthCost(rebirths)
	return math.floor(Config.RebirthBaseCost * (Config.RebirthCostGrowth ^ cleanCount(rebirths)))
end

function Calc.GetRebirthSlapMultiplier(rebirths)
	return 1 + cleanCount(rebirths) * Config.RebirthSlapBonus
end

function Calc.GetRebirthDamageMultiplier(rebirths)
	return 1 + cleanCount(rebirths) * Config.RebirthDamageBonus
end

function Calc.GetRebirthGems(newRebirthCount)
	return Config.RebirthGems * cleanCount(newRebirthCount)
end

--------------------------------------------------------------------------
-- Haende
--------------------------------------------------------------------------
local handIndex = {}
for i, hand in ipairs(Config.Hands) do
	handIndex[hand.Id] = i
end

function Calc.GetHand(handId)
	local index = handIndex[handId]
	if index then
		return Config.Hands[index], index
	end
	return Config.Hands[1], 1
end

function Calc.IsHand(handId)
	return handIndex[handId] ~= nil
end

function Calc.IsRobuxHand(handId)
	local index = handIndex[handId]
	return index ~= nil and Config.Hands[index].Currency == "Robux"
end

-- Besitzt der Spieler die Hand? (Robux-Haende stehen in RobuxHands)
function Calc.OwnsHand(data, handId)
	if type(data) ~= "table" then
		return false
	end
	if type(data.OwnedHands) == "table" and data.OwnedHands[handId] then
		return true
	end
	return type(data.RobuxHands) == "table" and data.RobuxHands[handId] == true
end

-- Kurzbeschreibung der Bonus-Werte einer Hand
function Calc.DescribeHandPerks(hand)
	local parts = { "x" .. Calc.FormatNumber(hand.Damage) .. " Damage" }
	if hand.SlapMultiplier then
		table.insert(parts, "x" .. hand.SlapMultiplier .. " Slaps")
	end
	if hand.CritBonus then
		table.insert(parts, "+" .. math.floor(hand.CritBonus * 100 + 0.5) .. "% Crit")
	end
	if hand.ReachBonus then
		table.insert(parts, "+" .. hand.ReachBonus .. " Reach")
	end
	if hand.SpeedMultiplier then
		table.insert(parts, "+" .. math.floor((1 / hand.SpeedMultiplier - 1) * 100 + 0.5) .. "% Speed")
	end
	return table.concat(parts, " • ")
end

--------------------------------------------------------------------------
-- Pets
--------------------------------------------------------------------------
function Calc.GetPetBoost(petIds)
	local total = 1
	for _, petId in ipairs(petIds or {}) do
		local pet = Config.Pets[petId]
		if pet then
			total = total + pet.Boost
		end
	end
	return total
end

-- Liste der Pet-IDs, die ein Spieler ausgeruestet hat
function Calc.GetEquippedPetIds(data)
	local result = {}
	if type(data) ~= "table" or type(data.Pets) ~= "table" then
		return result
	end
	for _, pet in ipairs(data.Pets) do
		if pet.Equipped and Config.Pets[pet.Id] then
			table.insert(result, pet.Id)
		end
	end
	return result
end

function Calc.GetPetSlots(data)
	local bought = (data and data.GemShop and tonumber(data.GemShop.PetSlot)) or 0
	return Config.BasePetSlots + cleanCount(bought)
end

function Calc.GetInventorySize(data)
	local bought = (data and data.GemShop and tonumber(data.GemShop.Inventory)) or 0
	return Config.BaseInventory + cleanCount(bought) * 20
end

-- Wahrscheinlichkeiten eines Eis (fuer Anzeige und Wuerfeln)
function Calc.GetEggChances(eggId, lucky)
	local egg = Config.Eggs[eggId]
	local result = {}
	if not egg then
		return result
	end
	local total = 0
	for _, entry in ipairs(egg.Pets) do
		local pet = Config.Pets[entry[1]]
		local weight = entry[2]
		if lucky and pet and #result >= 2 then
			weight = weight * Config.LuckyBoostFactor
		end
		total = total + weight
		table.insert(result, { PetId = entry[1], Weight = weight })
	end
	for _, entry in ipairs(result) do
		entry.Chance = entry.Weight / total
	end
	return result
end

-- randomFn() muss eine Zahl in [0, 1) liefern
function Calc.RollEgg(eggId, lucky, randomFn)
	local chances = Calc.GetEggChances(eggId, lucky)
	local roll = randomFn()
	local sum = 0
	for _, entry in ipairs(chances) do
		sum = sum + entry.Chance
		if roll < sum then
			return entry.PetId
		end
	end
	local last = chances[#chances]
	return last and last.PetId or nil
end

function Calc.FormatChance(chance)
	local percent = chance * 100
	if percent >= 10 then
		return string.format("%d%%", math.floor(percent + 0.5))
	elseif percent >= 1 then
		return string.format("%.1f%%", percent)
	end
	return string.format("%.2f%%", percent)
end

--------------------------------------------------------------------------
-- Boosts
--------------------------------------------------------------------------
function Calc.IsBoostActive(data, boostId, now)
	if type(data) ~= "table" or type(data.Boosts) ~= "table" then
		return false
	end
	local expires = tonumber(data.Boosts[boostId])
	return expires ~= nil and expires > now
end

--------------------------------------------------------------------------
-- Gesamtwerte eines Spielers
--------------------------------------------------------------------------
function Calc.GetDamage(data, now)
	local upgrades = data.Upgrades or {}
	local hand = Calc.GetHand(data.Hand)
	local damage = Calc.GetBaseDamage(upgrades.Power) * hand.Damage * Calc.GetRebirthDamageMultiplier(data.Rebirths)
	if Calc.IsBoostActive(data, "DoubleDamage", now) then
		damage = damage * 2
	end
	return math.max(1, math.floor(damage))
end

-- Multiplikator fuer verdiente Slaps (ohne Combo und ohne Gyatt-Multiplikator)
function Calc.GetSlapMultiplier(data, now)
	local upgrades = data.Upgrades or {}
	local hand = Calc.GetHand(data.Hand)
	local multiplier = Calc.GetGreedMultiplier(upgrades.Greed)
		* Calc.GetRebirthSlapMultiplier(data.Rebirths)
		* Calc.GetPetBoost(Calc.GetEquippedPetIds(data))
		* (hand.SlapMultiplier or 1)
	if Calc.IsBoostActive(data, "DoubleSlaps", now) then
		multiplier = multiplier * 2
	end
	return multiplier
end

-- Krit-Chance inklusive Hand-Bonus
function Calc.GetTotalCritChance(data)
	local hand = Calc.GetHand(data.Hand)
	return math.min(0.95, Calc.GetCritChance((data.Upgrades or {}).Luck) + (hand.CritBonus or 0))
end

-- Reichweite inklusive Hand-Bonus
function Calc.GetTotalReach(data)
	local hand = Calc.GetHand(data.Hand)
	return Calc.GetReach((data.Upgrades or {}).Reach) + (hand.ReachBonus or 0)
end

-- Wartezeit inklusive Hand-Bonus
function Calc.GetTotalCooldown(data)
	local hand = Calc.GetHand(data.Hand)
	return math.max(0.08, Calc.GetCooldown((data.Upgrades or {}).Speed) * (hand.SpeedMultiplier or 1))
end

--------------------------------------------------------------------------
-- Gem-Shop
--------------------------------------------------------------------------
local gemItems = {}
for _, item in ipairs(Config.GemShop) do
	gemItems[item.Id] = item
end

function Calc.GetGemItem(itemId)
	return gemItems[itemId]
end

-- Preis fuer den naechsten Kauf, nil wenn ausverkauft
function Calc.GetGemItemPrice(itemId, ownedCount)
	local item = gemItems[itemId]
	if not item then
		return nil
	end
	if item.Repeatable then
		return item.Prices[1]
	end
	return item.Prices[cleanCount(ownedCount) + 1]
end

--------------------------------------------------------------------------
-- Zonen
--------------------------------------------------------------------------
function Calc.GetDimension(zoneIndex)
	for index, dim in ipairs(Config.Dimensions) do
		if zoneIndex >= dim.FirstZone and zoneIndex <= dim.LastZone then
			return dim, index
		end
	end
	return Config.Dimensions[1], 1
end

function Calc.GetZoneStartZ(zoneIndex)
	local dim = Calc.GetDimension(zoneIndex)
	return dim.StartZ + (zoneIndex - dim.FirstZone) * Config.ZoneLength
end

-- Zone an einer Z-Position. 0 = Hub der Oberwelt.
function Calc.GetZoneAtZ(z)
	if z < 0 then
		return 0
	end
	local best = 1
	for _, dim in ipairs(Config.Dimensions) do
		local landingStart = dim.StartZ - Config.DimensionLandingLength - 40
		if z >= landingStart or dim.StartZ == 0 then
			local offset = math.floor((z - dim.StartZ) / Config.ZoneLength)
			best = math.max(dim.FirstZone, math.min(dim.LastZone, dim.FirstZone + offset))
		end
	end
	return best
end

function Calc.GetGyattKey(zoneIndex, gyattIndex)
	return "Z" .. zoneIndex .. "_" .. gyattIndex
end

--------------------------------------------------------------------------
-- Taegliche Belohnung
-- Gibt zurueck: kannAbholen, Serien-Tag, Sekunden bis zur naechsten
--------------------------------------------------------------------------
function Calc.GetDailyStatus(data, now)
	local daily = (type(data) == "table" and type(data.Daily) == "table") and data.Daily or { Last = 0, Streak = 0 }
	local last = tonumber(daily.Last) or 0
	local streak = tonumber(daily.Streak) or 0
	if last > 0 and now - last < Config.DailyCooldown then
		return false, streak, last + Config.DailyCooldown - now
	end
	if last == 0 or now - last > Config.DailyStreakReset or streak >= #Config.DailyRewards then
		return true, 1, 0
	end
	return true, streak + 1, 0
end

--------------------------------------------------------------------------
-- Quests
--------------------------------------------------------------------------
function Calc.GetDayNumber(unixTime)
	return math.floor((tonumber(unixTime) or 0) / 86400)
end

-- Gibt die Quests eines Tages fuer einen Spieler zurueck (immer gleich fuer
-- denselben Tag und Spieler, egal auf welchem Server).
function Calc.GetQuests(day, userId)
	local seed = (cleanCount(day) * 7919 + cleanCount(userId) * 104729) % 2147483647
	local function nextRandom()
		seed = (seed * 16807) % 2147483647
		return seed / 2147483647
	end
	nextRandom()
	local pool = {}
	for i = 1, #Config.QuestPool do
		pool[i] = i
	end
	local quests = {}
	for slot = 1, math.min(Config.QuestsPerDay, #pool) do
		local pick = math.floor(nextRandom() * #pool) + 1
		if pick > #pool then
			pick = #pool
		end
		local template = Config.QuestPool[pool[pick]]
		table.remove(pool, pick)
		local tier = slot -- Quest 1 leicht, 2 mittel, 3 schwer
		local amount = template.Amounts[tier] or template.Amounts[#template.Amounts]
		table.insert(quests, {
			Id = template.Id,
			Stat = template.Stat,
			Text = string.format(template.Text, Calc.FormatNumber(amount)),
			Amount = amount,
			Gems = template.Gems[tier] or template.Gems[#template.Gems],
		})
	end
	return quests
end

return Calc
