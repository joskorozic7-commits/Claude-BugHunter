--[[
	Shop: alle Kaeufe mit Slaps und Gems.
	  Upgrades, Haende, Zonen, Teleport, Rebirth, Gem-Shop, Auto-Slap, Einstellungen
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("SlapShared")
local Config = require(Shared:WaitForChild("Config"))
local Calc = require(Shared:WaitForChild("Calc"))

local Shop = {}
local ctx
local rebirthRng = Random.new()

local RED = { 255, 120, 120 }
local GREEN = { 120, 255, 140 }

local function notEnough(player, amount, currency)
	local icon = currency == "Gems" and "💎" or "👋"
	ctx.Remotes.Notify(player, "Not enough " .. currency .. "! You need " .. icon .. " " .. Calc.FormatNumber(amount), RED)
	ctx.Remotes.Fire("Event", player, "Denied")
end

--------------------------------------------------------------------------
-- Upgrades
--------------------------------------------------------------------------
-- Kauft ein Level. Gibt zurueck: ok, fehlendeWaehrung ("Slaps"/"Gems"/nil), Betrag, warTierUp
local function buyOneUpgrade(profile, id, allowTierUp)
	local data = profile.Data
	local level = data.Upgrades[id]
	local cost, gems = Calc.GetUpgradeCost(id, level)
	if not cost then
		return false, nil, nil, false
	end
	local tierUp = gems > 0
	if tierUp and not allowTierUp then
		return false, "TierUp", cost, true
	end
	if data.Slaps < cost then
		return false, "Slaps", cost, tierUp
	end
	if data.Gems < gems then
		return false, "Gems", gems, tierUp
	end
	data.Slaps = data.Slaps - cost
	data.Gems = data.Gems - gems
	data.Upgrades[id] = level + 1
	ctx.Data.AddStat(profile, "Upgrades", 1)
	return true, nil, cost, tierUp
end

local function afterUpgrade(player, profile, id, bought, tierUp)
	local upgrade = Config.Upgrades[id]
	local level = profile.Data.Upgrades[id]
	if tierUp then
		local tierInfo = Calc.GetTierInfo(Calc.GetTier(level))
		ctx.Remotes.Popup(player, "TIER UP!", upgrade.Icon .. " " .. upgrade.DisplayName .. " is now " .. string.upper(tierInfo.Name) .. "  (" .. Calc.DescribeUpgrade(id, level) .. ")", tierInfo.Color)
	else
		ctx.Remotes.Notify(player, upgrade.Icon .. " " .. upgrade.DisplayName .. " is now level " .. level
			.. (bought > 1 and ("  (+" .. bought .. ")") or "") .. "!", GREEN)
	end
	ctx.Remotes.Fire("Event", player, "Purchased")
	if id == "Power" then
		ctx.Hands.Give(player, false) -- Hand waechst
	end
	if id == "Legs" or id == "Jump" then
		ctx.Items.ApplyStats(player) -- schneller laufen / hoeher springen
	end
	ctx.Data.Push(player, true)
end

function Shop.BuyUpgrade(player, id)
	local profile = ctx.Data.Get(player)
	if not profile or type(id) ~= "string" or not Config.Upgrades[id] then
		return
	end
	local ok, missing, amount, tierUp = buyOneUpgrade(profile, id, true)
	if ok then
		afterUpgrade(player, profile, id, 1, tierUp)
	elseif missing == nil then
		ctx.Remotes.Notify(player, "Already at max level!", { 255, 220, 120 })
	else
		notEnough(player, amount, missing)
	end
end

-- Kauft so viele Level wie moeglich, aber nie automatisch einen Tier-Up (der kostet Gems)
function Shop.BuyUpgradeMax(player, id)
	local profile = ctx.Data.Get(player)
	if not profile or type(id) ~= "string" or not Config.Upgrades[id] then
		return
	end
	local bought = 0
	local lastMissing, lastAmount = nil, nil
	for _ = 1, Config.Upgrades[id].MaxLevel do
		local ok, missing, amount = buyOneUpgrade(profile, id, false)
		lastMissing, lastAmount = missing, amount
		if not ok then
			break
		end
		bought = bought + 1
	end
	if bought > 0 then
		afterUpgrade(player, profile, id, bought, false)
	elseif lastMissing == "TierUp" then
		ctx.Remotes.Notify(player, "⚡ Time for a TIER UP! Press the Tier Up button.", { 255, 220, 120 })
	elseif lastMissing == nil then
		ctx.Remotes.Notify(player, "Already at max level!", { 255, 220, 120 })
	else
		notEnough(player, lastAmount, lastMissing)
	end
end

--------------------------------------------------------------------------
-- Haende
--------------------------------------------------------------------------
local function ownsHand(profile, handId)
	return profile.Data.OwnedHands[handId] == true or profile.RobuxHands[handId] == true
end
Shop.OwnsHand = ownsHand

-- Robux-Hand freischalten (nach Kauf oder zum Testen in Studio)
local function grantRobuxHand(player, profile, hand, isTest)
	profile.RobuxHands[hand.Id] = true
	profile.Data.Hand = hand.Id
	ctx.Hands.Give(player, true)
	local subtitle = hand.DisplayName .. "  (x" .. Calc.FormatNumber(hand.Damage) .. " Damage)"
	if isTest then
		subtitle = subtitle .. "  - Studio test, free"
	else
		ctx.Remotes.NotifyAll("👑 " .. player.DisplayName .. " got the " .. hand.DisplayName .. "!", hand.Color)
	end
	ctx.Remotes.Popup(player, "ULTRA HAND UNLOCKED!", subtitle, hand.Color)
	ctx.Remotes.Fire("Event", player, "Purchased")
	ctx.Data.Push(player, true)
end

-- Beim Betreten pruefen, welche Robux-Haende der Spieler besitzt
function Shop.CheckRobuxHands(player, profile)
	for _, hand in ipairs(Config.Hands) do
		local passId = tonumber(hand.GamePassId) or 0
		if hand.Currency == "Robux" and passId > 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
			end)
			if ok and owns then
				profile.RobuxHands[hand.Id] = true
			end
		end
	end
	if Calc.IsRobuxHand(profile.Data.Hand) and not profile.RobuxHands[profile.Data.Hand] then
		profile.Data.Hand = Config.Hands[1].Id
	end
end

function Shop.BuyHand(player, handId)
	local profile = ctx.Data.Get(player)
	if not profile or type(handId) ~= "string" or not Calc.IsHand(handId) then
		return
	end
	local data = profile.Data
	local hand = Calc.GetHand(handId)
	if ownsHand(profile, handId) then
		Shop.EquipHand(player, handId)
		return
	end
	if hand.Currency == "Robux" then
		local passId = tonumber(hand.GamePassId) or 0
		if passId <= 0 then
			if RunService:IsStudio() then
				grantRobuxHand(player, profile, hand, true)
			else
				ctx.Remotes.Notify(player, "👑 " .. hand.DisplayName .. " is coming soon!", { 255, 220, 120 })
			end
			return
		end
		local ok, err = pcall(function()
			MarketplaceService:PromptGamePassPurchase(player, passId)
		end)
		if not ok then
			warn("[SlapTheBlob] Game pass prompt failed: " .. tostring(err))
		end
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
	ctx.Remotes.Popup(player, "NEW HAND!", hand.DisplayName .. "  (x" .. hand.Damage .. " Damage)", hand.Color)
	ctx.Remotes.Fire("Event", player, "Purchased")
	ctx.Data.Push(player, true)
end

function Shop.EquipHand(player, handId)
	local profile = ctx.Data.Get(player)
	if not profile or type(handId) ~= "string" or not ownsHand(profile, handId) then
		return
	end
	profile.Data.Hand = handId
	ctx.Hands.Give(player, true)
	ctx.Remotes.Notify(player, "✋ " .. Calc.GetHand(handId).DisplayName .. " equipped!", GREEN)
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
		ctx.Remotes.Notify(player, "You already own this zone!", { 255, 220, 120 })
		return
	end
	if zoneIndex > data.Zones + 1 then
		ctx.Remotes.Notify(player, "Unlock Zone " .. (data.Zones + 1) .. " first!", RED)
		return
	end
	if data.Slaps < zone.Price then
		notEnough(player, zone.Price, "Slaps")
		return
	end
	data.Slaps = data.Slaps - zone.Price
	data.Zones = zoneIndex
	ctx.Remotes.Popup(player, "NEW ZONE!", "Zone " .. zoneIndex .. ": " .. zone.Name, zone.Accent)
	ctx.Remotes.NotifyAll("🗺️ " .. player.DisplayName .. " unlocked Zone " .. zoneIndex .. " (" .. zone.Name .. ")!", zone.Accent)
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
	if profile.Duel then
		ctx.Remotes.Notify(player, "⚔️ You can't teleport during a duel!", RED)
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
		ctx.Remotes.Notify(player, "This zone is still locked!", RED)
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
	if data.Zones < Config.RebirthMinZone then
		ctx.Remotes.Notify(player, "♻️ Unlock Zone " .. Config.RebirthMinZone .. " before you can rebirth!", RED)
		ctx.Remotes.Fire("Event", player, "Denied")
		return
	end
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
	-- Bonus-Item: je mehr Rebirths, desto seltener
	local r = data.Rebirths
	local weights = { Rare = 60, Epic = 25 + r * 2, Legendary = 6 + r, Mythic = 0.5 + r * 0.4, Ultra = r >= 10 and (r * 0.1) or 0 }
	local bonusId = Calc.PickItem(Calc.RollRarity(weights, function()
		return rebirthRng:NextNumber()
	end), function()
		return rebirthRng:NextNumber()
	end)
	if bonusId then
		ctx.Items.Give(profile, bonusId, 1)
		local bonusCfg = Config.Items[bonusId]
		ctx.Remotes.Notify(player, "🎁 Rebirth bonus: " .. bonusCfg.DisplayName .. " (" .. Config.Rarities[bonusCfg.Rarity].DisplayName .. ")!", Config.Rarities[bonusCfg.Rarity].Color)
	end

	ctx.Remotes.Popup(player, "REBIRTH " .. data.Rebirths .. "!", "Forever " .. Calc.FormatMultiplier(Calc.GetRebirthSlapMultiplier(data.Rebirths))
		.. " Slaps & " .. Calc.FormatMultiplier(Calc.GetRebirthDamageMultiplier(data.Rebirths)) .. " Damage  (+" .. gems .. " 💎)", { 200, 150, 255 })
	ctx.Remotes.NotifyAll("♻️ " .. player.DisplayName .. " did Rebirth " .. data.Rebirths .. "!", { 200, 150, 255 })

	-- zurueck zum Start, weil die Zonen wieder gesperrt sind
	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		character:PivotTo(ctx.World.Spawn.CFrame * CFrame.new(0, 4, 0))
	end
	ctx.Hands.Give(player, false)
	ctx.Items.ApplyCharacter(player)
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
		ctx.Remotes.Notify(player, "You already bought all of this!", { 255, 220, 120 })
		return
	end
	if data.Gems < price then
		notEnough(player, price, "Gems")
		return
	end
	data.Gems = data.Gems - price
	if item.Boost then
		ctx.Data.AddBoost(profile, item.Boost, item.Duration)
		ctx.Remotes.Notify(player, item.Icon .. " " .. item.DisplayName .. " activated!", GREEN)
	else
		data.GemShop[itemId] = owned + 1
		if itemId == "AutoSlap" then
			data.AutoSlapOn = true
			ctx.Remotes.Popup(player, "AUTO-SLAP!", "Hold your hand and stand next to a Blob.", { 120, 220, 255 })
		else
			ctx.Remotes.Notify(player, item.Icon .. " " .. item.DisplayName .. " bought!", GREEN)
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
		ctx.Remotes.Notify(player, "Buy Auto-Slap in the 💎 Gem Shop!", RED)
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

--------------------------------------------------------------------------
-- Dimensionen
--------------------------------------------------------------------------
function Shop.EnterDimension(player, dimIndex)
	local profile = ctx.Data.Get(player)
	local dim = Config.Dimensions[dimIndex]
	if not profile or not dim or not ctx.World.Dimensions[dimIndex] then
		return
	end
	if profile.Duel then
		return
	end
	-- man muss die letzte Zone der vorherigen Dimension haben
	if profile.Data.Zones < dim.FirstZone - 1 then
		ctx.Remotes.Notify(player, "🌀 Unlock Zone " .. (dim.FirstZone - 1) .. " first!", RED)
		return
	end
	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		character:PivotTo(ctx.World.Dimensions[dimIndex].LandingCFrame)
		ctx.Remotes.Popup(player, string.upper(dim.Name), "A new dimension! Unlock its zones at the gates.", { 200, 140, 255 })
	end
end

function Shop.ReturnToOverworld(player)
	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		character:PivotTo(ctx.World.Dimensions[1].LandingCFrame)
	end
end

--------------------------------------------------------------------------
-- Gems fuer Robux (Developer Products)
--------------------------------------------------------------------------
local function findPack(packId)
	for _, pack in ipairs(Config.GemPacks) do
		if pack.Id == packId then
			return pack
		end
	end
	return nil
end

local function grantGemPack(player, profile, pack, isTest)
	ctx.Data.AddGems(profile, pack.Gems)
	local subtitle = "+" .. Calc.FormatNumber(pack.Gems) .. " Gems"
	if isTest then
		subtitle = subtitle .. "  (Studio test)"
	end
	ctx.Remotes.Popup(player, "💎 GEMS ADDED!", subtitle, { 120, 220, 255 })
	ctx.Remotes.Fire("Event", player, "Purchased")
	ctx.Data.Push(player, true)
end

function Shop.BuyGemPack(player, packId)
	local profile = ctx.Data.Get(player)
	local pack = type(packId) == "string" and findPack(packId)
	if not profile or not pack then
		return
	end
	if (tonumber(pack.ProductId) or 0) <= 0 then
		if RunService:IsStudio() then
			grantGemPack(player, profile, pack, true)
		else
			ctx.Remotes.Notify(player, "💎 Gem packs are coming soon!", { 255, 220, 120 })
		end
		return
	end
	local ok, err = pcall(function()
		MarketplaceService:PromptProductPurchase(player, pack.ProductId)
	end)
	if not ok then
		warn("[SlapTheBlob] Product prompt failed: " .. tostring(err))
	end
end

-- Alle Developer Products: Gem-Pakete, Robux-Eier und Robux-Kisten
local function findProduct(productId)
	if not productId or productId == 0 then
		return nil
	end
	for _, pack in ipairs(Config.GemPacks) do
		if tonumber(pack.ProductId) == productId then
			return "Gems", pack
		end
	end
	for _, egg in ipairs(Config.RobuxEggs) do
		if tonumber(egg.ProductId) == productId then
			return "Egg", egg
		end
	end
	for _, crate in ipairs(Config.ItemCrates) do
		if crate.Currency == "Robux" and tonumber(crate.ProductId) == productId then
			return "Crate", crate
		end
	end
	return nil
end

local function grantProduct(player, profile, kind, def, isTest)
	if kind == "Gems" then
		grantGemPack(player, profile, def, isTest)
	elseif kind == "Egg" then
		ctx.Pets.GrantEgg(player, profile, def.Id, 1)
		if isTest then
			ctx.Remotes.Notify(player, "🥚 " .. def.Name .. " (Studio test)", { 255, 220, 120 })
		end
	elseif kind == "Crate" then
		ctx.Items.GrantCrate(player, profile, def)
		if isTest then
			ctx.Remotes.Notify(player, "🎁 " .. def.Name .. " (Studio test)", { 255, 220, 120 })
		end
	end
end

-- Kauf starten (ID 0 = in Studio gratis testen)
local function promptProduct(player, kind, def)
	local profile = ctx.Data.Get(player)
	if not profile then
		return
	end
	if (tonumber(def.ProductId) or 0) <= 0 then
		if RunService:IsStudio() then
			grantProduct(player, profile, kind, def, true)
		else
			ctx.Remotes.Notify(player, "🛒 This item is coming soon!", { 255, 220, 120 })
		end
		return
	end
	local ok, err = pcall(function()
		MarketplaceService:PromptProductPurchase(player, def.ProductId)
	end)
	if not ok then
		warn("[SlapTheBlob] Product prompt failed: " .. tostring(err))
	end
end

function Shop.BuyRobuxEgg(player, eggId)
	for _, egg in ipairs(Config.RobuxEggs) do
		if egg.Id == eggId then
			promptProduct(player, "Egg", egg)
			return
		end
	end
end

function Shop.BuyCrate(player, crateId)
	local crate = type(crateId) == "string" and ctx.Items.CrateById(crateId)
	if not crate then
		return
	end
	if crate.Currency == "Robux" then
		promptProduct(player, "Crate", crate)
	else
		ctx.Items.OpenCrate(player, crateId)
	end
end

-- Roblox ruft das fuer jeden Robux-Kauf auf (auch nach einem Absturz erneut,
-- bis wir PurchaseGranted zurueckgeben). Jeder Kauf wird genau einmal gutgeschrieben.
local function processReceipt(info)
	local kind, def = findProduct(info.ProductId)
	if not kind then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local player = Players:GetPlayerByUserId(info.PlayerId)
	local profile = player and ctx.Data.Get(player)
	if not profile or not profile.Loaded then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if ctx.Data.HasStore() and not profile.CanSave then
		-- Spielstand nicht sicher geladen: spaeter nochmal versuchen
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local data = profile.Data
	local purchaseId = tostring(info.PurchaseId)
	if data.Receipts[purchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	-- Zustand merken, um bei einem Speicherfehler alles zurueckzunehmen
	local before = { Gems = data.Gems, Pets = #data.Pets, Items = #data.Items, NextPetUid = data.NextPetUid, NextItemUid = data.NextItemUid }
	data.Receipts[purchaseId] = os.time()
	local ok, err = pcall(grantProduct, player, profile, kind, def, false)
	if ok and ctx.Data.HasStore() then
		ok = ctx.Data.Save(profile)
		err = "save failed"
	end
	if not ok then
		warn("[SlapTheBlob] Purchase " .. purchaseId .. " not granted: " .. tostring(err))
		data.Receipts[purchaseId] = nil
		data.Gems = before.Gems
		for i = #data.Pets, before.Pets + 1, -1 do
			table.remove(data.Pets, i)
		end
		for i = #data.Items, before.Items + 1, -1 do
			table.remove(data.Items, i)
		end
		data.NextPetUid = before.NextPetUid
		data.NextItemUid = before.NextItemUid
		ctx.Pets.UpdateAttribute(player)
		ctx.Items.ApplyCharacter(player)
		ctx.Data.Push(player, true)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end
Shop.ProcessReceipt = processReceipt

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
	ctx.RegisterAction("BuyGemPack", Shop.BuyGemPack)
	ctx.RegisterAction("BuyRobuxEgg", Shop.BuyRobuxEgg)
	ctx.RegisterAction("BuyCrate", Shop.BuyCrate)
end

function Shop.Start()
	MarketplaceService.ProcessReceipt = processReceipt
	for dimIndex, dimInfo in pairs(ctx.World.Dimensions) do
		if dimInfo.ReturnPrompt then
			dimInfo.ReturnPrompt.Triggered:Connect(function(player)
				Shop.ReturnToOverworld(player)
			end)
		end
	end
	for _, zoneInfo in ipairs(ctx.World.Zones) do
		if zoneInfo.PortalPrompt then
			local dimIndex = zoneInfo.PortalPrompt:GetAttribute("Dimension")
			zoneInfo.PortalPrompt.Triggered:Connect(function(player)
				Shop.EnterDimension(player, dimIndex)
			end)
		end
	end
	-- Robux-Kauf abgeschlossen
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		local profile = ctx.Data.Get(player)
		if not profile then
			return
		end
		for _, hand in ipairs(Config.Hands) do
			if hand.Currency == "Robux" and tonumber(hand.GamePassId) == passId then
				grantRobuxHand(player, profile, hand, false)
			end
		end
	end)

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
