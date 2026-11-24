--[[
	Gyatts: baut die Gyatt-Modelle, verwaltet Leben, Besiegen, Respawn,
	Belohnungen und das "Goldener Blob"-Event.

	Animationen (Wackeln, Hinschauen, Gesicht) macht der Client.
]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SlapShared")
local Config = require(Shared:WaitForChild("Config"))
local Calc = require(Shared:WaitForChild("Calc"))

local Gyatts = {}
Gyatts.List = {} -- alle aktiven Gyatt-Objekte (auch tote, die gleich respawnen)
Gyatts.Golden = nil

local ctx -- Init
local storage -- Ablage fuer besiegte Gyatts

local function rgb(t)
	return Color3.fromRGB(t[1], t[2], t[3])
end

--------------------------------------------------------------------------
-- Modell bauen
--------------------------------------------------------------------------
local function detail(model, name, size, cframe, color, mat, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	p.Parent = model
	return p
end


local function unit(x, y, z)
	return Vector3.new(x, y, z).Unit
end

local function buildModel(spec)
	local S = spec.Size
	local r = S / 2
	local base = spec.BaseCFrame -- Mitte des Koerpers, Vorderseite = -Z
	local model = Instance.new("Model")
	model.Name = "Gyatt_" .. spec.Key

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(S, S, S)
	body.CFrame = base
	body.Anchored = true
	body.CanCollide = true
	body.Color = rgb(spec.Color)
	body.Material = spec.Material or Enum.Material.SmoothPlastic
	body.TopSurface = Enum.SurfaceType.Smooth
	body.BottomSurface = Enum.SurfaceType.Smooth
	body.Parent = model

	local function onSurface(direction, extra)
		return base * CFrame.new(direction * (r + (extra or 0)))
	end
	local function facing(position, outward)
		-- Teil, das von der Kugel nach aussen schaut
		local worldPos = (base * CFrame.new(position)).Position
		local worldOut = base:VectorToWorldSpace(outward)
		return CFrame.lookAt(worldPos, worldPos + worldOut)
	end

	local black = Color3.fromRGB(25, 15, 25)
	local white = Color3.fromRGB(255, 255, 255)

	-- kleine Fuesse
	for _, side in ipairs({ -1, 1 }) do
		local foot = detail(model, "Foot", Vector3.new(S * 0.3, S * 0.15, S * 0.38),
			base * CFrame.new(side * S * 0.22, -r * 0.97, -S * 0.05),
			Color3.new(math.clamp(body.Color.R - 0.18, 0, 1), math.clamp(body.Color.G - 0.18, 0, 1), math.clamp(body.Color.B - 0.18, 0, 1)), body.Material)
		local footMesh = Instance.new("SpecialMesh")
		footMesh.MeshType = Enum.MeshType.Sphere
		footMesh.Parent = foot
	end

	-- Augen
	for _, side in ipairs({ -1, 1 }) do
		local dir = unit(side * 0.34, 0.24, -0.91)
		detail(model, "EyeWhite", Vector3.new(S * 0.3, S * 0.3, S * 0.3), onSurface(dir, -S * 0.08), white, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		detail(model, "Pupil", Vector3.new(S * 0.15, S * 0.15, S * 0.15), onSurface(dir, S * 0.02), black, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		detail(model, "Shine", Vector3.new(S * 0.05, S * 0.05, S * 0.05), onSurface(unit(side * 0.34 + 0.05, 0.3, -0.9), S * 0.07), white, Enum.Material.Neon, Enum.PartType.Ball)
		-- Augenbraue
		local browDir = unit(side * 0.33, 0.5, -0.8)
		detail(model, "Brow", Vector3.new(S * 0.22, S * 0.045, S * 0.05),
			facing(browDir * (r + S * 0.01), browDir) * CFrame.Angles(0, 0, math.rad(side * -12)), black)
		-- Baeckchen
		local blush = detail(model, "Blush", Vector3.new(S * 0.13, S * 0.13, S * 0.13), onSurface(unit(side * 0.55, -0.05, -0.83), -S * 0.045),
			Color3.fromRGB(255, 110, 150), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		blush.Transparency = 0.25
	end

	-- Mund: Laecheln (3 Teile) und "O" (versteckt, Client zeigt es beim Treffer)
	for i = -1, 1 do
		local dir = unit(i * 0.13, -0.27 + math.abs(i) * 0.05, -0.95)
		detail(model, "MouthSmile", Vector3.new(S * 0.11, S * 0.045, S * 0.05),
			facing(dir * (r + S * 0.005), dir) * CFrame.Angles(0, 0, math.rad(i * 25)), black)
	end
	local mouthO = detail(model, "MouthO", Vector3.new(S * 0.16, S * 0.16, S * 0.16), onSurface(unit(0, -0.28, -0.96), -S * 0.06),
		Color3.fromRGB(120, 20, 50), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	mouthO.Transparency = 1

	-- Accessoires
	local accessories = {}
	for _, a in ipairs(spec.Accessories or {}) do
		accessories[a] = true
	end

	if accessories.bow then
		local pink = Color3.fromRGB(255, 80, 150)
		local c = onSurface(unit(0.45, 0.85, 0), -S * 0.02)
		detail(model, "BowCenter", Vector3.new(S * 0.1, S * 0.1, S * 0.1), c, pink, nil, Enum.PartType.Ball)
		detail(model, "BowLeft", Vector3.new(S * 0.16, S * 0.16, S * 0.16), c * CFrame.new(-S * 0.1, S * 0.03, 0), pink, nil, Enum.PartType.Ball)
		detail(model, "BowRight", Vector3.new(S * 0.16, S * 0.16, S * 0.16), c * CFrame.new(S * 0.1, -S * 0.03, 0), pink, nil, Enum.PartType.Ball)
	end

	if accessories.glasses then
		for _, side in ipairs({ -1, 1 }) do
			local dir = unit(side * 0.34, 0.24, -0.91)
			local lens = detail(model, "Lens", Vector3.new(S * 0.3, S * 0.2, S * 0.04), facing(dir * (r + S * 0.09), dir), Color3.fromRGB(20, 20, 30), Enum.Material.Glass)
			lens.Transparency = 0.1
		end
		local bridgeDir = unit(0, 0.26, -0.96)
		detail(model, "Bridge", Vector3.new(S * 0.14, S * 0.03, S * 0.03), facing(bridgeDir * (r + S * 0.06), bridgeDir), Color3.fromRGB(20, 20, 30))
	end

	if accessories.cowboy then
		local brown = Color3.fromRGB(140, 90, 50)
		local top = base * CFrame.new(0, r * 0.92, 0)
		detail(model, "HatBrim", Vector3.new(S * 0.04, S * 0.95, S * 0.95), top * CFrame.Angles(0, 0, math.rad(90)), brown, Enum.Material.Fabric, Enum.PartType.Cylinder)
		detail(model, "HatTop", Vector3.new(S * 0.3, S * 0.5, S * 0.5), top * CFrame.new(0, S * 0.15, 0) * CFrame.Angles(0, 0, math.rad(90)), brown, Enum.Material.Fabric, Enum.PartType.Cylinder)
		detail(model, "HatBand", Vector3.new(S * 0.06, S * 0.52, S * 0.52), top * CFrame.new(0, S * 0.04, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(200, 40, 40), Enum.Material.Fabric, Enum.PartType.Cylinder)
	end

	if accessories.scarf then
		local red = Color3.fromRGB(220, 40, 60)
		for i = 0, 15 do
			local angle = (i / 16) * math.pi * 2
			local dir = Vector3.new(math.cos(angle) * 0.86, -0.5, math.sin(angle) * 0.86)
			detail(model, "Scarf", Vector3.new(S * 0.17, S * 0.17, S * 0.17), base * CFrame.new(dir * r), (i % 2 == 0) and red or Color3.fromRGB(255, 255, 255), Enum.Material.Fabric, Enum.PartType.Ball)
		end
	end

	if accessories.horns then
		for _, side in ipairs({ -1, 1 }) do
			local hornBase = onSurface(unit(side * 0.5, 0.82, 0), -S * 0.05)
			detail(model, "Horn", Vector3.new(S * 0.12, S * 0.32, S * 0.12), hornBase * CFrame.Angles(0, 0, math.rad(side * -25)) * CFrame.new(0, S * 0.12, 0), Color3.fromRGB(60, 20, 20), Enum.Material.Basalt)
			detail(model, "HornTip", Vector3.new(S * 0.08, S * 0.12, S * 0.08), hornBase * CFrame.Angles(0, 0, math.rad(side * -25)) * CFrame.new(0, S * 0.32, 0), Color3.fromRGB(255, 120, 20), Enum.Material.Neon)
		end
	end

	if accessories.halo then
		local gold = Color3.fromRGB(255, 230, 100)
		for i = 0, 17 do
			local angle = (i / 18) * math.pi * 2
			detail(model, "Halo", Vector3.new(S * 0.08, S * 0.08, S * 0.08), base * CFrame.new(math.cos(angle) * r * 0.55, r * 1.3, math.sin(angle) * r * 0.55), gold, Enum.Material.Neon, Enum.PartType.Ball)
		end
	end

	if accessories.antenna then
		for _, side in ipairs({ -1, 1 }) do
			local start = base * CFrame.new(side * r * 0.35, r * 0.88, 0)
			detail(model, "AntennaStick", Vector3.new(S * 0.04, S * 0.4, S * 0.04), start * CFrame.Angles(0, 0, math.rad(side * -20)) * CFrame.new(0, S * 0.18, 0), Color3.fromRGB(60, 60, 70), Enum.Material.Metal)
			detail(model, "AntennaBall", Vector3.new(S * 0.12, S * 0.12, S * 0.12), start * CFrame.Angles(0, 0, math.rad(side * -20)) * CFrame.new(0, S * 0.4, 0), Color3.fromRGB(120, 255, 120), Enum.Material.Neon, Enum.PartType.Ball)
		end
	end

	if accessories.crown then
		local gold = Color3.fromRGB(255, 200, 40)
		local top = base * CFrame.new(0, r * (accessories.cowboy and 1.25 or 0.9), 0)
		detail(model, "CrownBase", Vector3.new(S * 0.14, S * 0.45, S * 0.45), top * CFrame.Angles(0, 0, math.rad(90)), gold, Enum.Material.Foil, Enum.PartType.Cylinder)
		for i = 0, 4 do
			local angle = (i / 5) * math.pi * 2
			local spikePos = top * CFrame.new(math.cos(angle) * S * 0.19, S * 0.13, math.sin(angle) * S * 0.19)
			detail(model, "CrownSpike", Vector3.new(S * 0.07, S * 0.16, S * 0.07), spikePos, gold, Enum.Material.Foil)
			detail(model, "CrownGem", Vector3.new(S * 0.06, S * 0.06, S * 0.06), spikePos * CFrame.new(0, S * 0.1, 0),
				(i % 2 == 0) and Color3.fromRGB(255, 40, 80) or Color3.fromRGB(60, 160, 255), Enum.Material.Neon, Enum.PartType.Ball)
		end
	end

	-- Umriss
	local highlight = Instance.new("Highlight")
	highlight.Name = "Outline"
	highlight.FillTransparency = 1
	highlight.FillColor = Color3.fromRGB(255, 255, 255)
	highlight.OutlineColor = Color3.fromRGB(40, 15, 40)
	highlight.OutlineTransparency = 0.1
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Adornee = model
	highlight.Parent = model

	-- Sound
	local sound = Instance.new("Sound")
	sound.Name = "SlapSound"
	sound.SoundId = "rbxasset://sounds/swordslash.wav"
	sound.Volume = 0.7
	sound.RollOffMaxDistance = 120
	sound.Parent = body

	-- Name + Lebensbalken
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "InfoGui"
	billboard.Adornee = body
	billboard.Size = UDim2.new(math.max(12, S * 1.3), 0, 4, 0)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, r + 3.5, 0)
	billboard.MaxDistance = 220
	billboard.LightInfluence = 0
	billboard.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.fromScale(1, 0.5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = spec.NameColor or Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Text = spec.DisplayName
	nameLabel.Parent = billboard

	local barBack = Instance.new("Frame")
	barBack.Name = "HealthBack"
	barBack.Position = UDim2.fromScale(0, 0.55)
	barBack.Size = UDim2.fromScale(1, 0.42)
	barBack.BackgroundColor3 = Color3.fromRGB(40, 0, 20)
	barBack.BorderSizePixel = 0
	barBack.Parent = billboard
	local backCorner = Instance.new("UICorner")
	backCorner.CornerRadius = UDim.new(0.5, 0)
	backCorner.Parent = barBack
	local backStroke = Instance.new("UIStroke")
	backStroke.Thickness = 2
	backStroke.Color = Color3.fromRGB(20, 0, 10)
	backStroke.Parent = barBack

	local barFill = Instance.new("Frame")
	barFill.Name = "HealthFill"
	barFill.Size = UDim2.fromScale(1, 1)
	barFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	barFill.BorderSizePixel = 0
	barFill.Parent = barBack
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0.5, 0)
	fillCorner.Parent = barFill
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(Color3.fromRGB(255, 60, 140), Color3.fromRGB(255, 160, 80))
	gradient.Parent = barFill

	local hpText = Instance.new("TextLabel")
	hpText.Name = "HealthText"
	hpText.Size = UDim2.fromScale(1, 1)
	hpText.BackgroundTransparency = 1
	hpText.Font = Enum.Font.GothamBold
	hpText.TextScaled = true
	hpText.TextColor3 = Color3.fromRGB(255, 255, 255)
	hpText.TextStrokeTransparency = 0.2
	hpText.ZIndex = 2
	hpText.Parent = barBack

	model.PrimaryPart = body
	model:SetAttribute("Key", spec.Key)
	model:SetAttribute("BaseCFrame", base)
	model:SetAttribute("Size", S)
	model:SetAttribute("ZoneIndex", spec.ZoneIndex)
	CollectionService:AddTag(model, "SlapGyatt")

	return model, body, barFill, hpText, sound
end

--------------------------------------------------------------------------
-- Gyatt-Objekte
--------------------------------------------------------------------------
local function updateGui(g)
	local ratio = math.clamp(g.Health / g.MaxHealth, 0, 1)
	g.HealthFill.Size = UDim2.fromScale(ratio, 1)
	g.HealthText.Text = Calc.FormatNumber(math.ceil(g.Health)) .. " / " .. Calc.FormatNumber(g.MaxHealth)
end

local function createGyatt(spec)
	local model, body, fill, text, sound = buildModel(spec)
	local g = {
		Key = spec.Key,
		DisplayName = spec.DisplayName,
		ZoneIndex = spec.ZoneIndex,
		MaxHealth = spec.MaxHealth,
		Health = spec.MaxHealth,
		RewardMultiplier = spec.RewardMultiplier,
		DefeatBonus = spec.DefeatBonus,
		Gems = spec.Gems,
		Radius = spec.Size / 2,
		Position = spec.BaseCFrame.Position,
		Model = model,
		Body = body,
		HealthFill = fill,
		HealthText = text,
		Sound = sound,
		Alive = true,
		Contributors = {},
		IsGolden = spec.IsGolden == true,
	}
	updateGui(g)
	model.Parent = ctx.World.GyattFolder
	table.insert(Gyatts.List, g)
	return g
end

local function removeFromList(g)
	for i, other in ipairs(Gyatts.List) do
		if other == g then
			table.remove(Gyatts.List, i)
			return
		end
	end
end

function Gyatts.BuildAll()
	storage = Instance.new("Folder")
	storage.Name = "SlapDefeatedGyatts"
	storage.Parent = ServerStorage

	for zoneIndex, zone in ipairs(Config.Zones) do
		local zoneInfo = ctx.World.Zones[zoneIndex]
		for gyattIndex, cfg in ipairs(zone.Gyatts) do
			local spot = zoneInfo.GyattSpots[gyattIndex]
			createGyatt({
				Key = Calc.GetGyattKey(zoneIndex, gyattIndex),
				DisplayName = cfg.DisplayName,
				ZoneIndex = zoneIndex,
				MaxHealth = cfg.MaxHealth,
				Size = cfg.Size,
				Color = cfg.Color,
				Accessories = cfg.Accessories,
				RewardMultiplier = cfg.RewardMultiplier,
				DefeatBonus = math.floor(cfg.MaxHealth * cfg.RewardMultiplier * 0.25),
				Gems = cfg.Gems,
				BaseCFrame = CFrame.new(spot.Position + Vector3.new(0, 0.4 + cfg.Size * 0.56, 0)),
			})
		end
	end
end

-- Naechster lebender Gyatt in Reichweite, den der Spieler schlagen darf
function Gyatts.FindTarget(position, reach, unlockedZones)
	local best, bestDistance = nil, math.huge
	for _, g in ipairs(Gyatts.List) do
		if g.Alive and g.ZoneIndex <= unlockedZones then
			local distance = (g.Position - position).Magnitude - g.Radius
			if distance <= reach and distance < bestDistance then
				best = g
				bestDistance = distance
			end
		end
	end
	return best
end

local function rewardContributors(g, killer)
	for userId in pairs(g.Contributors) do
		local player = Players:GetPlayerByUserId(userId)
		local profile = player and ctx.Data.Get(player)
		if profile then
			local multiplier = Calc.GetSlapMultiplier(profile.Data, os.time())
			local bonus = ctx.Data.AddSlaps(profile, g.DefeatBonus * multiplier)
			local gems = ctx.Data.AddGems(profile, g.Gems)
			profile.Data.TotalDefeats = profile.Data.TotalDefeats + 1
			ctx.Data.AddStat(profile, "Defeats", 1)
			local text = "🎉 " .. g.DisplayName .. " defeated!  +" .. Calc.FormatNumber(bonus) .. " Slaps"
			if gems > 0 then
				text = text .. "  +" .. gems .. " 💎"
			end
			ctx.Remotes.Notify(player, text, { 120, 255, 140 })
			ctx.Data.Push(player, false)
		end
	end
	g.Contributors = {}
	if g.IsGolden and killer then
		ctx.Remotes.NotifyAll("⭐ " .. killer.DisplayName .. " defeated the GOLDEN BLOB! ⭐", { 255, 215, 0 })
	end
end

local function defeat(g, killer)
	g.Alive = false
	g.Health = 0
	updateGui(g)

	local explosion = Instance.new("Explosion")
	explosion.BlastPressure = 0
	explosion.BlastRadius = 0
	explosion.DestroyJointRadiusPercent = 0
	explosion.Position = g.Position
	explosion.Parent = workspace

	ctx.Remotes.FireAll("Defeat", g.Key, g.Position, g.Radius, g.IsGolden)
	rewardContributors(g, killer)

	if g.IsGolden then
		Gyatts.EndGolden(true)
		return
	end

	g.Model.Parent = storage
	task.delay(Config.GyattRespawnTime, function()
		g.Health = g.MaxHealth
		g.Alive = true
		g.Contributors = {}
		updateGui(g)
		g.Model.Parent = ctx.World.GyattFolder
	end)
end

-- Schaden zufuegen. Gibt true zurueck, wenn der Gyatt dadurch besiegt wurde.
function Gyatts.Damage(g, player, damage)
	if not g.Alive then
		return false
	end
	g.Contributors[player.UserId] = true
	g.Health = g.Health - damage
	g.Sound.PlaybackSpeed = 0.9 + math.random() * 0.3
	g.Sound:Play()
	if g.Health <= 0 then
		defeat(g, player)
		return true
	end
	updateGui(g)
	return false
end

--------------------------------------------------------------------------
-- Goldener Gyatt
--------------------------------------------------------------------------
Gyatts.GoldenState = { Active = false, ZoneIndex = 0, EndsAt = 0 }

function Gyatts.SendEventState(player)
	local state = Gyatts.GoldenState
	if state.Active then
		ctx.Remotes.Fire("Event", player, "GoldenStart", state.ZoneIndex, state.EndsAt)
	end
end

function Gyatts.EndGolden(defeated)
	local g = Gyatts.Golden
	if not g then
		return
	end
	Gyatts.Golden = nil
	Gyatts.GoldenState.Active = false
	g.Alive = false
	removeFromList(g)
	g.Model:Destroy()
	ctx.Remotes.FireAll("Event", "GoldenEnd", defeated == true)
	if not defeated then
		ctx.Remotes.NotifyAll("⭐ The Golden Blob escaped... next time!", { 255, 200, 120 })
	end
end

function Gyatts.SpawnGolden(zoneIndex)
	if Gyatts.Golden then
		return
	end
	local zone = Config.Zones[zoneIndex]
	local zoneInfo = ctx.World.Zones[zoneIndex]
	if not zone or not zoneInfo then
		return
	end
	local golden = Config.GoldenGyatt
	local bigGyatt = zone.Gyatts[#zone.Gyatts]
	local maxHealth = math.floor(bigGyatt.MaxHealth * golden.HealthFactor)
	local g = createGyatt({
		Key = "Golden",
		DisplayName = golden.DisplayName,
		ZoneIndex = zoneIndex,
		MaxHealth = maxHealth,
		Size = golden.Size,
		Color = golden.Color,
		Material = Enum.Material.Foil,
		NameColor = Color3.fromRGB(255, 220, 60),
		Accessories = { "crown", "glasses" },
		RewardMultiplier = bigGyatt.RewardMultiplier * golden.RewardFactor,
		DefeatBonus = math.floor(maxHealth * bigGyatt.RewardMultiplier * golden.RewardFactor * 0.25),
		Gems = golden.Gems,
		IsGolden = true,
		BaseCFrame = CFrame.new(zoneInfo.GoldenSpot.Position + Vector3.new(0, 0.4 + golden.Size * 0.56, 0)),
	})
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = Color3.fromRGB(255, 230, 120)
	sparkles.Parent = g.Body
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 220, 100)
	light.Range = 30
	light.Brightness = 3
	light.Parent = g.Body

	Gyatts.Golden = g
	local endsAt = os.time() + golden.Duration
	Gyatts.GoldenState = { Active = true, ZoneIndex = zoneIndex, EndsAt = endsAt }
	ctx.Remotes.FireAll("Event", "GoldenStart", zoneIndex, endsAt)
	ctx.Remotes.NotifyAll("⭐ A GOLDEN BLOB appeared in Zone " .. zoneIndex .. " (" .. zone.Name .. ")! ⭐", { 255, 215, 0 })

	task.delay(golden.Duration, function()
		if Gyatts.Golden == g then
			Gyatts.EndGolden(false)
		end
	end)
end

local function startGoldenLoop()
	task.spawn(function()
		local rng = Random.new()
		while true do
			task.wait(rng:NextInteger(Config.GoldenGyatt.MinInterval, Config.GoldenGyatt.MaxInterval))
			-- Zone: zufaellig bis zur hoechsten Zone, die ein Spieler hier hat
			local highest = 0
			for _, player in ipairs(Players:GetPlayers()) do
				local profile = ctx.Data.Get(player)
				if profile and profile.Data.Zones > highest then
					highest = profile.Data.Zones
				end
			end
			if highest > 0 and not Gyatts.Golden then
				Gyatts.SpawnGolden(rng:NextInteger(1, highest))
			end
		end
	end)
end

function Gyatts.Init(context)
	ctx = context
end

function Gyatts.Start()
	Gyatts.BuildAll()
	startGoldenLoop()
end

return Gyatts
