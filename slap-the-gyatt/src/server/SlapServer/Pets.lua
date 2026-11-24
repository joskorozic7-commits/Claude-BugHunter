--[[
	Pets: Eier oeffnen, Pets ausruesten / ablegen / loeschen.
	Ausgeruestete Pets stehen als Attribut "EquippedPets" am Spieler,
	damit alle Clients sie anzeigen koennen.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SlapShared")
local Config = require(Shared:WaitForChild("Config"))
local Calc = require(Shared:WaitForChild("Calc"))

local Pets = {}
local ctx
local rng = Random.new()

local RED = { 255, 120, 120 }

local function countEquipped(data)
	local n = 0
	for _, pet in ipairs(data.Pets) do
		if pet.Equipped then
			n = n + 1
		end
	end
	return n
end

local function findPet(data, uid)
	for i, pet in ipairs(data.Pets) do
		if pet.Uid == uid then
			return pet, i
		end
	end
	return nil
end

function Pets.UpdateAttribute(player)
	local profile = ctx.Data.Get(player)
	if not profile then
		return
	end
	player:SetAttribute("EquippedPets", table.concat(Calc.GetEquippedPetIds(profile.Data), ","))
end

local function changed(player)
	Pets.UpdateAttribute(player)
	ctx.Data.Push(player, true)
end

function Pets.Hatch(player, eggId, amount)
	local profile = ctx.Data.Get(player)
	if not profile or type(eggId) ~= "string" then
		return
	end
	local egg = Config.Eggs[eggId]
	if not egg then
		return
	end
	amount = (amount == 3) and 3 or 1
	local data = profile.Data

	local now = os.clock()
	if profile.LastHatch and now - profile.LastHatch < 1.2 then
		return
	end
	if egg.Zone > data.Zones then
		ctx.Remotes.Notify(player, "Unlock Zone " .. egg.Zone .. " first!", RED)
		return
	end
	local space = Calc.GetInventorySize(data) - #data.Pets
	if space < amount then
		ctx.Remotes.Notify(player, "🎒 Your pet inventory is full! Delete pets or buy more space.", RED)
		ctx.Remotes.Fire("Event", player, "Denied")
		return
	end
	local balanceKey = egg.Currency == "Gems" and "Gems" or "Slaps"
	local price = egg.Price * amount
	if data[balanceKey] < price then
		local icon = balanceKey == "Gems" and "💎" or "👋"
		ctx.Remotes.Notify(player, "Not enough " .. balanceKey .. "! You need " .. icon .. " " .. Calc.FormatNumber(price), RED)
		ctx.Remotes.Fire("Event", player, "Denied")
		return
	end
	profile.LastHatch = now
	data[balanceKey] = data[balanceKey] - price

	local lucky = Calc.IsBoostActive(data, "LuckyEggs", os.time())
	local slots = Calc.GetPetSlots(data)
	local results = {}
	for _ = 1, amount do
		local petId = Calc.RollEgg(eggId, lucky, function()
			return rng:NextNumber()
		end)
		local pet = { Uid = data.NextPetUid, Id = petId, Equipped = false }
		data.NextPetUid = data.NextPetUid + 1
		if countEquipped(data) < slots then
			pet.Equipped = true
		end
		table.insert(data.Pets, pet)
		table.insert(results, { Id = petId, Uid = pet.Uid })

		local petCfg = Config.Pets[petId]
		if petCfg.Rarity == "Legendary" or petCfg.Rarity == "Mythic" then
			local rarity = Config.Rarities[petCfg.Rarity]
			ctx.Remotes.NotifyAll("🌟 " .. player.DisplayName .. " hatched " .. petCfg.DisplayName .. " (" .. rarity.DisplayName .. ")!", rarity.Color)
		end
	end
	ctx.Data.AddStat(profile, "Eggs", amount)
	ctx.Remotes.Fire("Hatch", player, { EggId = eggId, Pets = results })
	changed(player)
end

function Pets.Equip(player, uid)
	local profile = ctx.Data.Get(player)
	if not profile or type(uid) ~= "number" then
		return
	end
	local pet = findPet(profile.Data, uid)
	if not pet or pet.Equipped then
		return
	end
	if countEquipped(profile.Data) >= Calc.GetPetSlots(profile.Data) then
		ctx.Remotes.Notify(player, "All pet slots are full! Unequip a pet first.", RED)
		return
	end
	pet.Equipped = true
	changed(player)
end

function Pets.Unequip(player, uid)
	local profile = ctx.Data.Get(player)
	if not profile or type(uid) ~= "number" then
		return
	end
	local pet = findPet(profile.Data, uid)
	if not pet or not pet.Equipped then
		return
	end
	pet.Equipped = false
	changed(player)
end

function Pets.Delete(player, uid)
	local profile = ctx.Data.Get(player)
	if not profile or type(uid) ~= "number" then
		return
	end
	local pet, index = findPet(profile.Data, uid)
	if not pet then
		return
	end
	table.remove(profile.Data.Pets, index)
	changed(player)
end

-- Beste Pets automatisch ausruesten
function Pets.EquipBest(player)
	local profile = ctx.Data.Get(player)
	if not profile then
		return
	end
	local data = profile.Data
	local sorted = {}
	for _, pet in ipairs(data.Pets) do
		pet.Equipped = false
		table.insert(sorted, pet)
	end
	table.sort(sorted, function(a, b)
		local boostA, boostB = Config.Pets[a.Id].Boost, Config.Pets[b.Id].Boost
		if boostA == boostB then
			return a.Uid < b.Uid
		end
		return boostA > boostB
	end)
	for i = 1, math.min(Calc.GetPetSlots(data), #sorted) do
		sorted[i].Equipped = true
	end
	ctx.Remotes.Notify(player, "🐾 Best pets equipped!", { 120, 255, 140 })
	changed(player)
end

-- Alle nicht ausgeruesteten Pets einer Seltenheit loeschen
function Pets.DeleteRarity(player, rarity)
	local profile = ctx.Data.Get(player)
	if not profile or type(rarity) ~= "string" or not Config.Rarities[rarity] then
		return
	end
	local kept = {}
	local removed = 0
	for _, pet in ipairs(profile.Data.Pets) do
		if not pet.Equipped and Config.Pets[pet.Id].Rarity == rarity then
			removed = removed + 1
		else
			table.insert(kept, pet)
		end
	end
	profile.Data.Pets = kept
	ctx.Remotes.Notify(player, "🗑️ " .. removed .. " pets deleted.", { 255, 220, 120 })
	changed(player)
end

function Pets.Init(context)
	ctx = context
	ctx.RegisterAction("Hatch", Pets.Hatch)
	ctx.RegisterAction("EquipPet", Pets.Equip)
	ctx.RegisterAction("UnequipPet", Pets.Unequip)
	ctx.RegisterAction("DeletePet", Pets.Delete)
	ctx.RegisterAction("EquipBestPets", Pets.EquipBest)
	ctx.RegisterAction("DeleteRarity", Pets.DeleteRarity)
end

function Pets.Start()
	for _, zoneInfo in ipairs(ctx.World.Zones) do
		for _, stand in ipairs(zoneInfo.EggStands) do
			for _, prompt in ipairs(stand.Prompts) do
				local eggId = prompt:GetAttribute("EggId")
				local amount = prompt:GetAttribute("Amount")
				prompt.Triggered:Connect(function(player)
					Pets.Hatch(player, eggId, amount)
				end)
			end
		end
	end
end

return Pets
