--[[
	Shop: alle Kaeufe mit Slaps und Gems.
	  Upgrades, Haende, Zonen, Teleport, Rebirth, Gem-Shop, Auto-Slap, Einstellungen
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SlapShared")
local Config = require(Shared:WaitForChild("Config"))
local Calc = require(Shared:WaitForChild("Calc"))

local Shop = {}
local ctx

local RED = { 255, 120, 120 }
local GREEN = { 120, 255, 140 }

local function notEnough(player, amount, currency)
	local icon = currency == "Gems" and "💎" or "👋"
	ctx.Remotes.Notify(player, "Nicht genug " .. currency .. "! Du brauchst " .. icon .. " " .. Calc.FormatNumber(amount), RED)
	ctx.Remotes.Fire("Event", player, "Denied")
end

--------------------------------------------------------------------------
-- Upgrades
--------------------------------------------------------------------------
local function buyOneUpgrade(profile, id)
	local data = profile.Data
	local level = data.Upgrades[id]
	local cost = Calc.GetUpgradeCost(id, level)
	if not cost or data.Slaps < cost then
		return false, cost
	end
	data.Slaps = data.Slaps - cost
	data.Upgrades[id] = level + 1
	ctx.Data.AddStat(profile, "Upgrades", 1)
	return true, cost
end

local function afterUpgrade(player, profile, id, bought)
	local upgrade = Config.Upgrades[id]
	ctx.Remotes.Notify(player, upgrade.Icon .. " " .. upgrade.DisplayName .. " ist jetzt Level " .. profile.Data.Upgrades[id]
		.. (bought > 1 and ("  (+" .. bought .. ")") or "") .. "!", GREEN)
	ctx.Remotes.Fire("Event", player, "Purchased")
	if id == "Power" then
		ctx.Hands.Give(player, false) -- Hand waechst
	end
	ctx.Data.Push(player, true)
end

function Shop.BuyUpgrade(player, id)
	local profile = ctx.Data.Get(player)
	if not profile or type(id) ~= "string" or not Config.Upgrades[id] then
		return
	end
	local ok, cost = buyOneUpgrade(profile, id)
	if ok then
		afterUpgrade(player, profile, id, 1)
	elseif cost == nil then
		ctx.Remotes.Notify(player, "Schon auf Max-Level!", { 255, 220, 120 })
	else
		notEnough(player, cost, "Slaps")
	end
end

function Shop.BuyUpgradeMax(player, id)
	local profile = ctx.Data.Get(player)
	if not profile or type(id) ~= "string" or not Config.Upgrades[id] then
		return
	end
	local bought = 0
	local lastCost = nil
	for _ = 1, Config.Upgrades[id].MaxLevel do
		local ok, cost = buyOneUpgrade(profile, id)
		lastCost = cost
		if not ok then
			break
		end
		bought = bought + 1
	end
	if bought > 0 then
		afterUpgrade(player, profile, id, bought)
	elseif lastCost == nil then
		ctx.Remotes.Notify(player, "Schon auf Max-Level!", { 255, 220, 120 })
	else
		notEnough(player, lastCost, "Slaps")
	end
end

--------------------------------------------------------------------------
-- Haende
--------------------------------------------------------------------------
function Shop.BuyHand(player, handId)
	local profile = ctx.Data.Get(player)
	if not profile or type(handId) ~= "string" or not Calc.IsHand(handId) then
		return
	end
	local data = profile.Data
	local hand = Calc.GetHand(handId)
	if data.OwnedHands[handId] then
		Shop.EquipHand(player, handId)
		return
	end
	local balanceKey = hand.Currency == "Gems" and "Gems" or "Slaps"
	if data[balanceKey] < hand.Price then
		notEnough(player, hand.Price, balanceKey)
		return
	end
	data[balanceKey] = data[balanceKey] - hand.Price
	data.OwnedHands[handId] = true
	data.Hand = handId
	ctx.Hands.Give(player, true)
	ctx.Remotes.Popup(player, "NEUE HAND!", hand.DisplayName .. "  (x" .. hand.Damage .. " Schaden)", hand.Color)
	ctx.Remotes.Fire("Event", player, "Purchased")
	ctx.Data.Push(player, true)
end

function Shop.EquipHand(player, handId)
	local profile = ctx.Data.Get(player)
	if not profile or type(handId) ~= "string" or not profile.Data.OwnedHands[handId] then
		return
	end
	profile.Data.Hand = handId
	ctx.Hands.Give(player, true)
	ctx.Remotes.Notify(player, "✋ " .. Calc.GetHand(handId).DisplayName .. " ausgeruestet!", GREEN)
	ctx.Data.Push(player, true)
end

--------------------------------------------------------------------------
-- Zonen & Teleport
--------------------------------------------------------------------------
function Shop.UnlockZone(player, zoneIndex)
	local profile = ctx.Data.Get(player)
	if not profile or type(zoneIndex) ~= "number" then
		return
	end
	local data = profile.Data
	zoneIndex = math.floor(zoneIndex)
	local zone = Config.Zones[zoneIndex]
	if not zone then
		return
	end
	if zoneIndex <= data.Zones then
		ctx.Remotes.Notify(player, "Diese Zone hast du schon!", { 255, 220, 120 })
		return
	end
	if zoneIndex > data.Zones + 1 then
		ctx.Remotes.Notify(player, "Schalte zuerst Zone " .. (data.Zones + 1) .. " frei!", RED)
		return
	end
	if data.Slaps < zone.Price then
		notEnough(player, zone.Price, "Slaps")
		return
	end
	data.Slaps = data.Slaps - zone.Price
	data.Zones = zoneIndex
	ctx.Remotes.Popup(player, "NEUE ZONE!", "Zone " .. zoneIndex .. ": " .. zone.Name, zone.Accent)
	ctx.Remotes.NotifyAll("🗺️ " .. player.DisplayName .. " hat Zone " .. zoneIndex .. " (" .. zone.Name .. ") freigeschaltet!", zone.Accent)
	ctx.Remotes.Fire("Event", player, "Purchased")
	ctx.Data.Push(player, true)
end

function Shop.Teleport(player, zoneIndex)
	local profile = ctx.Data.Get(player)
	if not profile or type(zoneIndex) ~= "number" then
		return
	end
	zoneIndex = math.floor(zoneIndex)
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return
	end
	local now = os.clock()
	if profile.LastTeleport and now - profile.LastTeleport < 2 then
		return
	end
	if zoneIndex == 0 then
		profile.LastTeleport = now
		local spawn = ctx.World.Spawn
		character:PivotTo(spawn.CFrame * CFrame.new(0, 4, 0))
		return
	end
	if zoneIndex < 1 or zoneIndex > profile.Data.Zones then
		ctx.Remotes.Notify(player, "Diese Zone ist noch gesperrt!", RED)
		return
	end
	profile.LastTeleport = now
	character:PivotTo(ctx.World.Zones[zoneIndex].TeleportCFrame)
end

--------------------------------------------------------------------------
-- Rebirth
--------------------------------------------------------------------------
function Shop.Rebirth(player)
	local profile = ctx.Data.Get(player)
	if not profile then
		return
	end
	local data = profile.Data
	local cost = Calc.GetRebirthCost(data.Rebirths)
	if data.Slaps < cost then
		notEnough(player, cost, "Slaps")
		return
	end
	data.Rebirths = data.Rebirths + 1
	data.Slaps = 0
	for _, id in ipairs(Config.UpgradeOrder) do
		data.Upgrades[id] = 0
	end
	data.Zones = 1
	local gems = ctx.Data.AddGems(profile, Calc.GetRebirthGems(data.Rebirths))
	profile.Combo = 0

	ctx.Remotes.Popup(player, "REBIRTH " .. data.Rebirths .. "!", "Fuer immer " .. Calc.FormatMultiplier(Calc.GetRebirthSlapMultiplier(data.Rebirths))
		.. " Slaps & " .. Calc.FormatMultiplier(Calc.GetRebirthDamageMultiplier(data.Rebirths)) .. " Schaden  (+" .. gems .. " 💎)", { 200, 150, 255 })
	ctx.Remotes.NotifyAll("♻️ " .. player.DisplayName .. " hat Rebirth " .. data.Rebirths .. " gemacht!", { 200, 150, 255 })

	-- zurueck zum Start, weil die Zonen wieder gesperrt sind
	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		character:PivotTo(ctx.World.Spawn.CFrame * CFrame.new(0, 4, 0))
	end
	ctx.Hands.Give(player, false)
	ctx.Data.Push(player, true)
	task.spawn(ctx.Data.Save, profile)
end

--------------------------------------------------------------------------
-- Gem-Shop
--------------------------------------------------------------------------
function Shop.BuyGemItem(player, itemId)
	local profile = ctx.Data.Get(player)
	if not profile or type(itemId) ~= "string" then
		return
	end
	local item = Calc.GetGemItem(itemId)
	if not item then
		return
	end
	local data = profile.Data
	local owned = data.GemShop[itemId] or 0
	local price = Calc.GetGemItemPrice(itemId, owned)
	if not price then
		ctx.Remotes.Notify(player, "Das hast du schon komplett gekauft!", { 255, 220, 120 })
		return
	end
	if data.Gems < price then
		notEnough(player, price, "Gems")
		return
	end
	data.Gems = data.Gems - price
	if item.Boost then
		ctx.Data.AddBoost(profile, item.Boost, item.Duration)
		ctx.Remotes.Notify(player, item.Icon .. " " .. item.DisplayName .. " aktiviert!", GREEN)
	else
		data.GemShop[itemId] = owned + 1
		if itemId == "AutoSlap" then
			data.AutoSlapOn = true
			ctx.Remotes.Popup(player, "AUTO-SLAP!", "Halte deine Hand und stell dich zu einem Gyatt.", { 120, 220, 255 })
		else
			ctx.Remotes.Notify(player, item.Icon .. " " .. item.DisplayName .. " gekauft!", GREEN)
		end
	end
	ctx.Remotes.Fire("Event", player, "Purchased")
	ctx.Data.Push(player, true)
end

function Shop.ToggleAutoSlap(player)
	local profile = ctx.Data.Get(player)
	if not profile then
		return
	end
	if profile.Data.GemShop.AutoSlap < 1 then
		ctx.Remotes.Notify(player, "Kauf Auto-Slap im 💎 Gem-Shop!", RED)
		return
	end
	profile.Data.AutoSlapOn = not profile.Data.AutoSlapOn
	ctx.Remotes.Notify(player, "🤖 Auto-Slap " .. (profile.Data.AutoSlapOn and "AN" or "AUS"), GREEN)
	ctx.Data.Push(player, true)
end

function Shop.SetSetting(player, name, value)
	local profile = ctx.Data.Get(player)
	if not profile or type(name) ~= "string" or type(value) ~= "boolean" then
		return
	end
	if profile.Data.Settings[name] == nil then
		return
	end
	profile.Data.Settings[name] = value
	ctx.Data.Push(player, true)
end

function Shop.Init(context)
	ctx = context
	ctx.RegisterAction("BuyUpgrade", Shop.BuyUpgrade)
	ctx.RegisterAction("BuyUpgradeMax", Shop.BuyUpgradeMax)
	ctx.RegisterAction("BuyHand", Shop.BuyHand)
	ctx.RegisterAction("EquipHand", Shop.EquipHand)
	ctx.RegisterAction("UnlockZone", Shop.UnlockZone)
	ctx.RegisterAction("Teleport", Shop.Teleport)
	ctx.RegisterAction("Rebirth", Shop.Rebirth)
	ctx.RegisterAction("BuyGemItem", Shop.BuyGemItem)
	ctx.RegisterAction("ToggleAutoSlap", Shop.ToggleAutoSlap)
	ctx.RegisterAction("SetSetting", Shop.SetSetting)
end

function Shop.Start()
	-- Tor-Prompts
	for _, zoneInfo in ipairs(ctx.World.Zones) do
		if zoneInfo.GatePrompt then
			local index = zoneInfo.Index
			zoneInfo.GatePrompt.Triggered:Connect(function(player)
				Shop.UnlockZone(player, index)
			end)
		end
	end
end

return Shop
