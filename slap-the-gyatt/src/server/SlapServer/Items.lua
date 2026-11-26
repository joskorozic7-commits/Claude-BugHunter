--[[
	Items: Accessoires (Huete, Fluegel/Ruecken, Auren).
	  * Inventar, Ausruesten (eins pro Kategorie), Loeschen
	  * Verschmelzen: 3 gleiche Items mit gleicher Stufe -> 1 Item mit +1 Stern
	  * Drops beim Besiegen von Zielen (jede Art hat ihre eigene Chance)
	  * Kisten fuer Slaps, Gems oder Robux
	  * Aussehen am Charakter + Werte (Laufgeschwindigkeit, Sprungkraft)
]]

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SlapShared")
local Config = require(Shared:WaitForChild("Config"))
local Calc = require(Shared:WaitForChild("Calc"))

local Items = {}
local ctx
local rng = Random.new()

local RED = { 255, 120, 120 }
local GREEN = { 120, 255, 140 }

local function random01()
	return rng:NextNumber()
end

local function findItem(data, uid)
	for i, item in ipairs(data.Items) do
		if item.Uid == uid then
			return item, i
		end
	end
	return nil
end

-- Item geben (auch ueber dem Limit, damit gekaufte Items nie verloren gehen)
function Items.Give(profile, itemId, level)
	if not Config.Items[itemId] then
		return nil
	end
	local item = { Uid = profile.Data.NextItemUid, Id = itemId, Level = level or 1, Equipped = false }
	profile.Data.NextItemUid = profile.Data.NextItemUid + 1
	table.insert(profile.Data.Items, item)
	return item
end

--------------------------------------------------------------------------
-- Aussehen am Charakter
--------------------------------------------------------------------------
local function newPart(model, name, size, color, mat, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = mat
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.Anchored = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape == "Oval" then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
	elseif shape then
		p.Shape = shape
	end
	p.Parent = model
	return p
end

local function rgb(t)
	return Color3.fromRGB(t[1], t[2], t[3])
end

local function material(name)
	local ok, result = pcall(function()
		return Enum.Material[name]
	end)
	return (ok and result) or Enum.Material.SmoothPlastic
end

local BALL, CYL = Enum.PartType.Ball, Enum.PartType.Cylinder
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90)) -- Zylinder aufrecht stellen

-- Baut ein Accessoire. anchor = CFrame am Charakter, add(name, size, offset, shape, colorOverride)
local function buildForm(item, add)
	local form = item.Form
	if form == "cone" or form == "wizard" then
		for i = 0, 3 do
			add("Cone" .. i, Vector3.new(0.5, 1.5 - i * 0.35, 1.5 - i * 0.35), CFrame.new(0, 0.25 + i * 0.45, 0) * UPRIGHT, CYL)
		end
		add("Tip", Vector3.new(0.4, 0.4, 0.4), CFrame.new(0, 2.1, 0), BALL, form == "cone" and Color3.fromRGB(255, 255, 255) or nil)
		if form == "wizard" then
			add("Brim", Vector3.new(0.12, 2.6, 2.6), CFrame.new(0, 0.05, 0) * UPRIGHT, CYL)
		end
	elseif form == "cap" then
		add("Dome", Vector3.new(1.35, 0.7, 1.35), CFrame.new(0, 0.15, 0), "Oval")
		add("Visor", Vector3.new(1.2, 0.1, 0.8), CFrame.new(0, 0.05, -0.75), nil)
	elseif form == "beanie" then
		add("Dome", Vector3.new(1.4, 0.9, 1.4), CFrame.new(0, 0.2, 0), "Oval")
		add("Pom", Vector3.new(0.45, 0.45, 0.45), CFrame.new(0, 0.7, 0), BALL, Color3.fromRGB(255, 255, 255))
	elseif form == "tophat" then
		add("Brim", Vector3.new(0.12, 2, 2), CFrame.new(0, 0.05, 0) * UPRIGHT, CYL)
		add("Tube", Vector3.new(1.4, 1.2, 1.2), CFrame.new(0, 0.75, 0) * UPRIGHT, CYL)
		add("Band", Vector3.new(0.25, 1.24, 1.24), CFrame.new(0, 0.3, 0) * UPRIGHT, CYL, Color3.fromRGB(200, 30, 50))
	elseif form == "brim" then
		add("Brim", Vector3.new(0.12, 2.6, 2.6), CFrame.new(0, 0.05, 0) * UPRIGHT, CYL)
		add("Crown", Vector3.new(0.8, 1.3, 1.3), CFrame.new(0, 0.45, 0) * UPRIGHT, CYL)
	elseif form == "chef" then
		add("Base", Vector3.new(0.8, 1.3, 1.3), CFrame.new(0, 0.4, 0) * UPRIGHT, CYL)
		add("Puff", Vector3.new(1.7, 1.1, 1.7), CFrame.new(0, 1.05, 0), "Oval")
	elseif form == "ears_long" then
		for _, side in ipairs({ -1, 1 }) do
			add("Ear", Vector3.new(0.35, 1.5, 0.2), CFrame.new(side * 0.35, 0.8, 0) * CFrame.Angles(0, 0, side * -0.15), "Oval")
		end
	elseif form == "ears_cat" then
		for _, side in ipairs({ -1, 1 }) do
			add("Ear", Vector3.new(0.45, 0.55, 0.2), CFrame.new(side * 0.42, 0.3, 0) * CFrame.Angles(0, 0, side * -0.4), nil)
		end
	elseif form == "horns" then
		for _, side in ipairs({ -1, 1 }) do
			add("Horn", Vector3.new(0.9, 0.3, 0.3), CFrame.new(side * 0.7, 0.2, 0) * CFrame.Angles(0, 0, side * 0.9) * UPRIGHT, CYL)
		end
		add("Helmet", Vector3.new(1.3, 0.6, 1.3), CFrame.new(0, 0, 0), "Oval")
	elseif form == "antlers" then
		for _, side in ipairs({ -1, 1 }) do
			add("Antler", Vector3.new(1, 0.15, 0.15), CFrame.new(side * 0.45, 0.45, 0) * CFrame.Angles(0, 0, side * -1) * UPRIGHT, CYL)
			add("Branch", Vector3.new(0.5, 0.12, 0.12), CFrame.new(side * 0.75, 0.75, 0) * CFrame.Angles(0, 0, side * 0.3) * UPRIGHT, CYL)
		end
	elseif form == "band" then
		add("Band", Vector3.new(0.25, 1.32, 1.32), CFrame.new(0, -0.35, 0) * UPRIGHT, CYL)
		add("Knot", Vector3.new(0.3, 0.3, 0.6), CFrame.new(0, -0.35, 0.75), nil)
	elseif form == "ring" then
		for i = 0, 9 do
			local a = (i / 10) * math.pi * 2
			add("Flower", Vector3.new(0.35, 0.35, 0.35), CFrame.new(math.cos(a) * 0.62, -0.05, math.sin(a) * 0.62), BALL,
				(i % 2 == 0) and nil or Color3.fromRGB(255, 255, 140))
		end
	elseif form == "helm" then
		add("Helm", Vector3.new(1.45, 1.35, 1.45), CFrame.new(0, -0.35, 0), "Oval")
		add("Visor", Vector3.new(1, 0.15, 0.1), CFrame.new(0, -0.4, -0.72), nil, Color3.fromRGB(30, 30, 35))
	elseif form == "dome" then
		local dome = add("Dome", Vector3.new(1.9, 1.9, 1.9), CFrame.new(0, -0.55, 0), BALL)
		dome.Transparency = 0.55
	elseif form == "crown" then
		add("Ring", Vector3.new(0.35, 1.25, 1.25), CFrame.new(0, 0.1, 0) * UPRIGHT, CYL)
		for i = 0, 4 do
			local a = (i / 5) * math.pi * 2
			add("Spike", Vector3.new(0.18, 0.45, 0.18), CFrame.new(math.cos(a) * 0.5, 0.45, math.sin(a) * 0.5), nil)
			add("Gem", Vector3.new(0.16, 0.16, 0.16), CFrame.new(math.cos(a) * 0.5, 0.72, math.sin(a) * 0.5), BALL, Color3.fromRGB(255, 60, 120))
		end
	elseif form == "halo" then
		for i = 0, 13 do
			local a = (i / 14) * math.pi * 2
			add("Halo", Vector3.new(0.22, 0.22, 0.22), CFrame.new(math.cos(a) * 0.7, 0.7, math.sin(a) * 0.7), BALL)
		end
	-- Ruecken
	elseif form == "backpack" then
		add("Pack", Vector3.new(1.3, 1.4, 0.7), CFrame.new(0, 0, 0.35), nil)
		add("Flap", Vector3.new(1.32, 0.45, 0.72), CFrame.new(0, 0.55, 0.36), nil, Color3.fromRGB(255, 220, 80))
	elseif form == "cape" then
		add("Cape", Vector3.new(1.8, 2.6, 0.12), CFrame.new(0, -0.6, 0.25) * CFrame.Angles(math.rad(10), 0, 0), nil)
	elseif form == "jetpack" then
		for _, side in ipairs({ -1, 1 }) do
			add("Tank", Vector3.new(1.4, 0.55, 0.55), CFrame.new(side * 0.35, 0, 0.45) * UPRIGHT, CYL)
			add("Nozzle", Vector3.new(0.3, 0.4, 0.4), CFrame.new(side * 0.35, -0.8, 0.45) * UPRIGHT, CYL, Color3.fromRGB(60, 60, 70))
		end
	elseif form == "wings_round" or form == "wings_feather" or form == "wings_bat" then
		for _, side in ipairs({ -1, 1 }) do
			if form == "wings_round" then
				add("WingTop", Vector3.new(1.8, 1.4, 0.1), CFrame.new(side * 1.1, 0.5, 0.35) * CFrame.Angles(0, side * -0.3, side * -0.3), "Oval")
				add("WingLow", Vector3.new(1.2, 1, 0.1), CFrame.new(side * 0.9, -0.5, 0.35) * CFrame.Angles(0, side * -0.3, side * 0.3), "Oval")
			elseif form == "wings_feather" then
				for f = 0, 2 do
					add("Feather" .. f, Vector3.new(2.2 - f * 0.4, 0.45, 0.12), CFrame.new(side * (1.1 + f * 0.05), 0.6 - f * 0.45, 0.35) * CFrame.Angles(0, side * -0.25, side * (0.35 - f * 0.25)), "Oval")
				end
			else
				add("Wing", Vector3.new(2.2, 1.3, 0.1), CFrame.new(side * 1.2, 0.3, 0.35) * CFrame.Angles(0, side * -0.3, side * -0.35), nil)
				add("Tip", Vector3.new(0.6, 0.6, 0.12), CFrame.new(side * 2.2, 0.75, 0.35) * CFrame.Angles(0, 0, side * 0.8), nil)
			end
		end
	end
end

local AURA_TAG = "SlapItemVisual"

local function clearVisuals(character)
	for _, child in ipairs(character:GetDescendants()) do
		if CollectionService:HasTag(child, AURA_TAG) then
			child:Destroy()
		end
	end
end

local function addEffect(target, item, color)
	if item.Effect == "fire" then
		local f = Instance.new("Fire")
		f.Size = 2
		f.Heat = 3
		f.Color = color
		f.Parent = target
		CollectionService:AddTag(f, AURA_TAG)
	elseif item.Effect == "smoke" then
		local s = Instance.new("Smoke")
		s.Size = 1
		s.Opacity = 0.15
		s.Color = color
		s.Parent = target
		CollectionService:AddTag(s, AURA_TAG)
	elseif item.Effect == "sparkles" or item.Effect == "rainbow" then
		local s = Instance.new("Sparkles")
		s.SparkleColor = color
		s.Parent = target
		CollectionService:AddTag(s, AURA_TAG)
	end
end

local function attachItem(character, item)
	local color = rgb(item.Color)
	local mat = material(item.Material)
	if item.Category == "Aura" then
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end
		local attachment = Instance.new("Attachment")
		attachment.Name = "AuraAttachment"
		attachment.Parent = root
		CollectionService:AddTag(attachment, AURA_TAG)
		local emitter = Instance.new("ParticleEmitter")
		emitter.Rate = 12
		emitter.Lifetime = NumberRange.new(1, 1.8)
		emitter.Speed = NumberRange.new(1, 3)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.LightEmission = 0.7
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
		if item.Effect == "rainbow" then
			emitter.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 255, 120)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 120, 255)),
			})
		else
			emitter.Color = ColorSequence.new(color)
		end
		emitter.Parent = attachment
		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = 8
		light.Brightness = 1
		light.Parent = attachment
		addEffect(root, item, color)
		return
	end

	local anchorPart, anchorOffset
	if item.Category == "Hat" then
		anchorPart = character:FindFirstChild("Head")
		if anchorPart then
			anchorOffset = CFrame.new(0, anchorPart.Size.Y / 2, 0)
		end
	else
		anchorPart = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
		if anchorPart then
			anchorOffset = CFrame.new(0, 0.2, anchorPart.Size.Z / 2)
		end
	end
	if not anchorPart then
		return
	end
	local model = Instance.new("Model")
	model.Name = "SlapAccessory_" .. item.Category
	CollectionService:AddTag(model, AURA_TAG)
	local base = anchorPart.CFrame * anchorOffset
	local first = nil
	local function add(name, size, offset, shape, colorOverride)
		local p = newPart(model, name, size, colorOverride or color, mat, shape)
		p.CFrame = base * offset
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = anchorPart
		weld.Part1 = p
		weld.Parent = p
		if item.Effect == "rainbow" and not colorOverride then
			CollectionService:AddTag(p, "RainbowHand")
		end
		first = first or p
		return p
	end
	buildForm(item, add)
	model.Parent = character
	if first then
		addEffect(first, item, color)
	end
end

-- Aussehen + Werte am Charakter anwenden
function Items.ApplyCharacter(player)
	local profile = ctx.Data.Get(player)
	local character = player.Character
	if not profile or not character then
		return
	end
	clearVisuals(character)
	for _, owned in ipairs(profile.Data.Items) do
		if owned.Equipped and Config.Items[owned.Id] then
			attachItem(character, Config.Items[owned.Id])
		end
	end
	Items.ApplyStats(player)
end

function Items.ApplyStats(player)
	local profile = ctx.Data.Get(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not profile or not humanoid then
		return
	end
	humanoid.WalkSpeed = Calc.GetWalkSpeed(profile.Data)
	humanoid.UseJumpPower = true
	humanoid.JumpPower = Calc.GetJumpPower(profile.Data.Upgrades.Jump)
end

--------------------------------------------------------------------------
-- Aktionen
--------------------------------------------------------------------------
local function changed(player)
	Items.ApplyCharacter(player)
	ctx.Data.Push(player, true)
end

function Items.Equip(player, uid)
	local profile = ctx.Data.Get(player)
	if not profile or type(uid) ~= "number" then
		return
	end
	local item = findItem(profile.Data, uid)
	if not item then
		return
	end
	local category = Config.Items[item.Id].Category
	for _, other in ipairs(profile.Data.Items) do
		if other.Equipped and Config.Items[other.Id].Category == category then
			other.Equipped = false
		end
	end
	item.Equipped = true
	changed(player)
end

function Items.Unequip(player, uid)
	local profile = ctx.Data.Get(player)
	if not profile or type(uid) ~= "number" then
		return
	end
	local item = findItem(profile.Data, uid)
	if item then
		item.Equipped = false
		changed(player)
	end
end

function Items.Delete(player, uid)
	local profile = ctx.Data.Get(player)
	if not profile or type(uid) ~= "number" then
		return
	end
	local item, index = findItem(profile.Data, uid)
	if item then
		table.remove(profile.Data.Items, index)
		changed(player)
	end
end

-- 3 gleiche Items (gleiche Stufe) -> 1 Item mit +1 Stern
function Items.Merge(player, uid)
	local profile = ctx.Data.Get(player)
	if not profile or type(uid) ~= "number" then
		return
	end
	local data = profile.Data
	local base = findItem(data, uid)
	if not base then
		return
	end
	if base.Level >= Config.ItemMaxLevel then
		ctx.Remotes.Notify(player, "⭐ This item is already at max stars!", { 255, 220, 120 })
		return
	end
	local group = { base }
	for _, other in ipairs(data.Items) do
		if #group >= 3 then
			break
		end
		if other ~= base and other.Id == base.Id and other.Level == base.Level then
			table.insert(group, other)
		end
	end
	if #group < 3 then
		ctx.Remotes.Notify(player, "🔨 You need 3 of the same item with the same stars to merge.", RED)
		return
	end
	local wasEquipped = false
	for _, item in ipairs(group) do
		wasEquipped = wasEquipped or item.Equipped
		local _, index = findItem(data, item.Uid)
		table.remove(data.Items, index)
	end
	local result = Items.Give(profile, base.Id, base.Level + 1)
	result.Equipped = wasEquipped
	local cfg = Config.Items[base.Id]
	ctx.Remotes.Popup(player, "MERGED!", cfg.DisplayName .. " " .. string.rep("★", result.Level) .. "  " .. Calc.DescribeItem(base.Id, result.Level),
		Config.Rarities[cfg.Rarity].Color)
	ctx.Remotes.Fire("Event", player, "Purchased")
	changed(player)
end

local function crateById(crateId)
	for _, crate in ipairs(Config.ItemCrates) do
		if crate.Id == crateId then
			return crate
		end
	end
	return nil
end
Items.CrateById = crateById

-- Kiste oeffnen und Items geben (fuer Robux-Kaeufe ohne Preispruefung)
function Items.GrantCrate(player, profile, crate)
	local results = {}
	for _ = 1, crate.Count or 1 do
		local rarity = Calc.RollRarity(crate.Weights, random01)
		local itemId = Calc.PickItem(rarity, random01)
		if itemId then
			Items.Give(profile, itemId, 1)
			table.insert(results, { Id = itemId, Level = 1 })
			local cfg = Config.Items[itemId]
			if Config.Rarities[cfg.Rarity].Order >= 5 then
				ctx.Remotes.NotifyAll("🌟 " .. player.DisplayName .. " got " .. cfg.DisplayName .. " (" .. Config.Rarities[cfg.Rarity].DisplayName .. ")!", Config.Rarities[cfg.Rarity].Color)
			end
		end
	end
	ctx.Remotes.Fire("Hatch", player, { Crate = crate.Id, Items = results })
	changed(player)
	return results
end

function Items.OpenCrate(player, crateId)
	local profile = ctx.Data.Get(player)
	local crate = type(crateId) == "string" and crateById(crateId)
	if not profile or not crate or crate.Currency == "Robux" then
		return
	end
	local now = os.clock()
	if profile.LastCrate and now - profile.LastCrate < 1 then
		return
	end
	if #profile.Data.Items >= Config.ItemInventory then
		ctx.Remotes.Notify(player, "🎒 Your item storage is full! Merge or delete items.", RED)
		return
	end
	local key = crate.Currency == "Gems" and "Gems" or "Slaps"
	if profile.Data[key] < crate.Price then
		ctx.Remotes.Notify(player, "Not enough " .. key .. "! You need " .. Calc.FormatNumber(crate.Price), RED)
		ctx.Remotes.Fire("Event", player, "Denied")
		return
	end
	profile.LastCrate = now
	profile.Data[key] = profile.Data[key] - crate.Price
	Items.GrantCrate(player, profile, crate)
end

-- Drop beim Besiegen eines Ziels
function Items.RollDrop(player, profile, target)
	local chance = Config.KindDrops[target.Kind or "blob"] or 0.01
	if target.IsBoss then
		chance = chance * Config.BossDropBonus
	end
	chance = chance * (1 + Calc.GetItemBonuses(profile.Data).Luck * 0.2)
	if rng:NextNumber() >= chance or #profile.Data.Items >= Config.ItemInventory then
		return nil
	end
	-- hoehere Zonen: bessere Seltenheiten
	local weights = {}
	local zoneFactor = (target.ZoneIndex or 1) / #Config.Zones
	for rarity, weight in pairs(Config.DropRarityWeights) do
		local order = Config.Rarities[rarity].Order
		weights[rarity] = weight * (1 + zoneFactor * (order - 1) * 1.5)
	end
	local rarity = Calc.RollRarity(weights, random01)
	local itemId = Calc.PickItem(rarity, random01)
	if not itemId then
		return nil
	end
	Items.Give(profile, itemId, 1)
	local cfg = Config.Items[itemId]
	local rarityInfo = Config.Rarities[cfg.Rarity]
	if rarityInfo.Order >= 3 then
		ctx.Remotes.Popup(player, "ITEM DROP!", cfg.DisplayName .. " (" .. rarityInfo.DisplayName .. ")  " .. Calc.DescribeItem(itemId, 1), rarityInfo.Color)
	else
		ctx.Remotes.Notify(player, "🎁 You found " .. cfg.DisplayName .. " (" .. rarityInfo.DisplayName .. ")!", rarityInfo.Color)
	end
	ctx.Data.Push(player, true)
	return itemId
end

function Items.Init(context)
	ctx = context
	ctx.RegisterAction("EquipItem", Items.Equip)
	ctx.RegisterAction("UnequipItem", Items.Unequip)
	ctx.RegisterAction("DeleteItem", Items.Delete)
	ctx.RegisterAction("MergeItem", Items.Merge)
	ctx.RegisterAction("OpenCrate", Items.OpenCrate)
end

Items.Players = Players
return Items
