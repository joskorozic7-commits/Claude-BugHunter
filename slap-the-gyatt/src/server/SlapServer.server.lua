--[[
	SlapServer (Script in ServerScriptService)

	Kompletter Server fuer "Slap the Gyatt":
	  * baut die Arena und die Gyatts
	  * gibt jedem Spieler seine Slap-Hand (Tool)
	  * prueft jeden Slap auf dem Server (Cooldown, Reichweite) -> kein Cheaten
	  * verwaltet Slaps (Waehrung), Upgrades und Rebirths
	  * speichert alles im DataStore
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("SlapConfig"))

--------------------------------------------------------------------------
-- Remotes
--------------------------------------------------------------------------
local remotes = ReplicatedStorage:FindFirstChild("SlapRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "SlapRemotes"
	remotes.Parent = ReplicatedStorage
end

local function getRemote(name)
	local remote = remotes:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remotes
	end
	return remote
end

local StateUpdate = getRemote("StateUpdate") -- Server -> Client: Spielstand
local RequestState = getRemote("RequestState") -- Client -> Server: "schick mir meinen Stand"
local BuyUpgrade = getRemote("BuyUpgrade") -- Client -> Server: Upgrade kaufen
local DoRebirth = getRemote("DoRebirth") -- Client -> Server: Rebirth
local SlapFx = getRemote("SlapFx") -- Server -> alle: Schadenszahl anzeigen
local Notify = getRemote("Notify") -- Server -> Client: Nachricht

--------------------------------------------------------------------------
-- Hilfsfunktionen
--------------------------------------------------------------------------
local function rgb(t)
	return Color3.fromRGB(t[1], t[2], t[3])
end

local function notify(player, text, color)
	if player and player.Parent then
		Notify:FireClient(player, text, color or { 255, 255, 255 })
	end
end

local function notifyAll(text, color)
	Notify:FireAllClients(text, color or { 255, 255, 255 })
end

--------------------------------------------------------------------------
-- Arena bauen
--------------------------------------------------------------------------
local arena = workspace:FindFirstChild("SlapArena")
if arena then
	arena:Destroy()
end
arena = Instance.new("Folder")
arena.Name = "SlapArena"
arena.Parent = workspace

local FLOOR_TOP = 1

local floor = Instance.new("Part")
floor.Name = "Floor"
floor.Anchored = true
floor.Size = Vector3.new(160, 2, 420)
floor.Position = Vector3.new(0, FLOOR_TOP - 1, 140)
floor.Color = Color3.fromRGB(110, 200, 120)
floor.Material = Enum.Material.Grass
floor.TopSurface = Enum.SurfaceType.Smooth
floor.BottomSurface = Enum.SurfaceType.Smooth
floor.Parent = arena

-- Weg in der Mitte
local path = Instance.new("Part")
path.Name = "Path"
path.Anchored = true
path.CanCollide = false
path.Size = Vector3.new(14, 0.2, 400)
path.Position = Vector3.new(0, FLOOR_TOP + 0.1, 150)
path.Color = Color3.fromRGB(230, 210, 160)
path.Material = Enum.Material.Sand
path.TopSurface = Enum.SurfaceType.Smooth
path.Parent = arena

local spawnPad = Instance.new("SpawnLocation")
spawnPad.Name = "SlapSpawn"
spawnPad.Anchored = true
spawnPad.Size = Vector3.new(12, 1, 12)
-- um 180 Grad gedreht, damit Spieler Richtung Gyatts (+Z) schauen
spawnPad.CFrame = CFrame.new(0, FLOOR_TOP + 0.5, 0) * CFrame.Angles(0, math.pi, 0)
spawnPad.Color = Color3.fromRGB(255, 120, 180)
spawnPad.Material = Enum.Material.SmoothPlastic
spawnPad.Neutral = true
spawnPad.Duration = 0 -- kein ForceField
spawnPad.Parent = arena

-- Andere SpawnLocations (z.B. aus der Baseplate-Vorlage) deaktivieren,
-- damit alle Spieler bei der Arena starten.
for _, descendant in ipairs(workspace:GetDescendants()) do
	if descendant:IsA("SpawnLocation") and descendant ~= spawnPad then
		descendant.Enabled = false
	end
end

-- Begruessungsschild
do
	local sign = Instance.new("Part")
	sign.Name = "WelcomeSign"
	sign.Anchored = true
	sign.Size = Vector3.new(1, 6, 16)
	sign.Position = Vector3.new(14, FLOOR_TOP + 7, 14)
	sign.Color = Color3.fromRGB(40, 40, 60)
	sign.Material = Enum.Material.SmoothPlastic
	sign.Parent = arena

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Left -- zeigt Richtung Weg (-X)
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = sign

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 170, 220)
	label.Text = "👋 SLAP THE GYATT 👋\nKlicke mit deiner Hand auf den Gyatt!"
	label.Parent = gui

	local pole = Instance.new("Part")
	pole.Name = "SignPole"
	pole.Anchored = true
	pole.Size = Vector3.new(1, 4, 1)
	pole.Position = Vector3.new(14, FLOOR_TOP + 2, 14)
	pole.Color = Color3.fromRGB(90, 60, 40)
	pole.Material = Enum.Material.Wood
	pole.Parent = arena
end

--------------------------------------------------------------------------
-- Gyatts bauen
--------------------------------------------------------------------------
local gyatts = {} -- Liste von Gyatt-Objekten

local function updateGyattGui(g)
	local ratio = math.clamp(g.Health / g.Config.MaxHealth, 0, 1)
	g.HealthFill.Size = UDim2.fromScale(ratio, 1)
	g.HealthText.Text = Config.FormatNumber(math.ceil(g.Health)) .. " / " .. Config.FormatNumber(g.Config.MaxHealth)
end

local function setGyattVisible(g, visible)
	g.Body.Transparency = visible and 0 or 1
	g.Body.CanCollide = visible
	g.Face.Transparency = visible and 0 or 1
	g.Billboard.Enabled = visible
	g.Highlight.Enabled = visible
end

local function createGyatt(cfg)
	local model = Instance.new("Model")
	model.Name = cfg.Id .. "Gyatt"

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(cfg.Size, cfg.Size, cfg.Size)
	-- Vorderseite (-Z) schaut zum Spawn
	body.CFrame = CFrame.new(cfg.PositionX, FLOOR_TOP + cfg.Size / 2, cfg.PositionZ)
	body.Anchored = true
	body.CanCollide = true
	body.Color = rgb(cfg.Color)
	body.Material = Enum.Material.SmoothPlastic
	body.TopSurface = Enum.SurfaceType.Smooth
	body.BottomSurface = Enum.SurfaceType.Smooth
	body.Parent = model

	local face = Instance.new("Decal")
	face.Name = "Face"
	face.Texture = "rbxasset://textures/face.png"
	face.Face = Enum.NormalId.Front
	face.Parent = body

	local highlight = Instance.new("Highlight")
	highlight.FillTransparency = 1
	highlight.OutlineColor = Color3.fromRGB(40, 20, 40)
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Adornee = model
	highlight.Parent = model

	local slapSound = Instance.new("Sound")
	slapSound.Name = "SlapSound"
	slapSound.SoundId = "rbxasset://sounds/swordslash.wav"
	slapSound.Volume = 0.8
	slapSound.RollOffMaxDistance = 150
	slapSound.Parent = body

	-- Name + Lebensbalken
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "InfoGui"
	billboard.Adornee = body
	billboard.Size = UDim2.new(math.max(10, cfg.Size * 1.2), 0, 3.5, 0)
	billboard.StudsOffset = Vector3.new(0, cfg.Size / 2 + 2.5, 0)
	billboard.MaxDistance = 250
	billboard.LightInfluence = 0
	billboard.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.fromScale(1, 0.5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0
	local requirement = ""
	if cfg.RequiredPower > 0 then
		requirement = "  (💪 Lv " .. cfg.RequiredPower .. ")"
	end
	nameLabel.Text = cfg.DisplayName .. requirement
	nameLabel.Parent = billboard

	local barBack = Instance.new("Frame")
	barBack.Name = "HealthBack"
	barBack.Position = UDim2.fromScale(0, 0.55)
	barBack.Size = UDim2.fromScale(1, 0.45)
	barBack.BackgroundColor3 = Color3.fromRGB(40, 0, 20)
	barBack.BorderSizePixel = 0
	barBack.Parent = billboard
	local backCorner = Instance.new("UICorner")
	backCorner.CornerRadius = UDim.new(0.4, 0)
	backCorner.Parent = barBack

	local barFill = Instance.new("Frame")
	barFill.Name = "HealthFill"
	barFill.Size = UDim2.fromScale(1, 1)
	barFill.BackgroundColor3 = Color3.fromRGB(255, 70, 140)
	barFill.BorderSizePixel = 0
	barFill.Parent = barBack
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0.4, 0)
	fillCorner.Parent = barFill

	local hpText = Instance.new("TextLabel")
	hpText.Name = "HealthText"
	hpText.Size = UDim2.fromScale(1, 1)
	hpText.BackgroundTransparency = 1
	hpText.Font = Enum.Font.GothamBold
	hpText.TextScaled = true
	hpText.TextColor3 = Color3.fromRGB(255, 255, 255)
	hpText.TextStrokeTransparency = 0.3
	hpText.ZIndex = 2
	hpText.Parent = barBack

	model.PrimaryPart = body
	model.Parent = arena

	local g = {
		Config = cfg,
		Model = model,
		Body = body,
		Face = face,
		Highlight = highlight,
		Sound = slapSound,
		Billboard = billboard,
		HealthFill = barFill,
		HealthText = hpText,
		Health = cfg.MaxHealth,
		Alive = true,
		BaseSize = body.Size,
		BaseColor = body.Color,
		Contributors = {},
		CurrentTween = nil,
	}
	updateGyattGui(g)
	table.insert(gyatts, g)
	return g
end

for _, cfg in ipairs(Config.Gyatts) do
	createGyatt(cfg)
end

local function wobbleGyatt(g)
	if g.CurrentTween then
		g.CurrentTween:Cancel()
	end
	g.Body.Size = g.BaseSize
	g.Body.Color = g.BaseColor
	local tween = TweenService:Create(
		g.Body,
		TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true),
		{ Size = g.BaseSize * 1.12, Color = Color3.fromRGB(255, 255, 255) }
	)
	g.CurrentTween = tween
	tween.Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed and g.CurrentTween == tween then
			g.Body.Size = g.BaseSize
			g.Body.Color = g.BaseColor
			g.CurrentTween = nil
		end
	end)
	tween:Play()
end

--------------------------------------------------------------------------
-- Spielerdaten
--------------------------------------------------------------------------
local dataStore = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if ok then
		dataStore = result
	else
		warn("[SlapTheGyatt] DataStore nicht verfuegbar, Fortschritt wird nicht gespeichert: " .. tostring(result))
	end
end

local profiles = {} -- [Player] = profile

local function defaultData()
	local upgrades = {}
	for _, id in ipairs(Config.UpgradeOrder) do
		upgrades[id] = 0
	end
	return {
		Slaps = 0,
		Rebirths = 0,
		TotalSlaps = 0,
		Upgrades = upgrades,
	}
end

-- Macht aus (eventuell kaputten/alten) gespeicherten Daten saubere Daten.
local function sanitizeData(raw)
	local data = defaultData()
	if type(raw) ~= "table" then
		return data
	end
	local function safeNumber(value)
		value = tonumber(value)
		if not value or value ~= value or value == math.huge or value < 0 then
			return 0
		end
		return math.floor(value)
	end
	data.Slaps = safeNumber(raw.Slaps)
	data.Rebirths = safeNumber(raw.Rebirths)
	data.TotalSlaps = safeNumber(raw.TotalSlaps)
	if type(raw.Upgrades) == "table" then
		for _, id in ipairs(Config.UpgradeOrder) do
			data.Upgrades[id] = Config.ClampLevel(id, raw.Upgrades[id])
		end
	end
	return data
end

local function dataKey(player)
	return "Player_" .. player.UserId
end

local function loadData(player)
	if not dataStore then
		return true, defaultData()
	end
	-- In Studio nur ein Versuch, damit man nicht lange warten muss
	local maxAttempts = RunService:IsStudio() and 1 or 3
	for attempt = 1, maxAttempts do
		local ok, result = pcall(function()
			return dataStore:GetAsync(dataKey(player))
		end)
		if ok then
			return true, sanitizeData(result)
		end
		warn("[SlapTheGyatt] Laden fehlgeschlagen (Versuch " .. attempt .. "): " .. tostring(result))
		if attempt < maxAttempts then
			task.wait(2)
		end
	end
	return false, defaultData()
end

local function saveProfile(player, profile)
	if not dataStore or not profile or not profile.CanSave then
		return
	end
	local snapshot = {
		Slaps = profile.Data.Slaps,
		Rebirths = profile.Data.Rebirths,
		TotalSlaps = profile.Data.TotalSlaps,
		Upgrades = {},
	}
	for _, id in ipairs(Config.UpgradeOrder) do
		snapshot.Upgrades[id] = profile.Data.Upgrades[id]
	end
	for attempt = 1, 3 do
		local ok, err = pcall(function()
			dataStore:SetAsync(dataKey(player), snapshot)
		end)
		if ok then
			return
		end
		warn("[SlapTheGyatt] Speichern fehlgeschlagen (Versuch " .. attempt .. "): " .. tostring(err))
		task.wait(1)
	end
end

local function getMultiplier(profile)
	return Config.GetGreedMultiplier(profile.Data.Upgrades.Greed) * Config.GetRebirthMultiplier(profile.Data.Rebirths)
end

local function pushState(player)
	local profile = profiles[player]
	if not profile then
		return
	end
	local data = profile.Data
	if profile.Leaderstats then
		profile.Leaderstats.Slaps.Value = data.Slaps
		profile.Leaderstats.Rebirths.Value = data.Rebirths
	end
	local upgrades = {}
	for _, id in ipairs(Config.UpgradeOrder) do
		upgrades[id] = data.Upgrades[id]
	end
	StateUpdate:FireClient(player, {
		Slaps = data.Slaps,
		Rebirths = data.Rebirths,
		TotalSlaps = data.TotalSlaps,
		Upgrades = upgrades,
	})
end

--------------------------------------------------------------------------
-- Die Slap-Hand (Tool)
--------------------------------------------------------------------------
local HAND_TOOL_NAME = "Slap Hand"
local onSlap -- wird weiter unten definiert

local function makeHandPart(name, size, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.Anchored = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

local function buildHandTool(powerLevel)
	local scale = Config.GetHandScale(powerLevel)
	local tier = Config.GetHandTier(powerLevel)
	local color = rgb(tier.Color)
	local material = Enum.Material[tier.Material] or Enum.Material.SmoothPlastic

	local tool = Instance.new("Tool")
	tool.Name = HAND_TOOL_NAME
	tool.ToolTip = tier.Name .. " - klicken zum Slappen!"
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool:SetAttribute("PowerLevel", powerLevel)

	-- Handflaeche = Handle
	local palm = makeHandPart("Handle", Vector3.new(1.4, 1.5, 0.5) * scale, color, material)
	palm.CFrame = CFrame.new()
	palm.Parent = tool

	local function attach(part, offset)
		part.CFrame = palm.CFrame * offset
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = palm
		weld.Part1 = part
		weld.Parent = part
		part.Parent = tool
	end

	-- vier Finger
	local fingerXs = { -0.51, -0.17, 0.17, 0.51 }
	local fingerLengths = { 0.8, 1.0, 0.95, 0.75 }
	for i, x in ipairs(fingerXs) do
		local length = fingerLengths[i] * scale
		local finger = makeHandPart("Finger" .. i, Vector3.new(0.3 * scale, length, 0.45 * scale), color, material)
		attach(finger, CFrame.new(x * scale, 0.75 * scale + length / 2, 0))
	end

	-- Daumen
	local thumb = makeHandPart("Thumb", Vector3.new(0.35 * scale, 0.75 * scale, 0.45 * scale), color, material)
	attach(thumb, CFrame.new(0.85 * scale, 0.05 * scale, 0) * CFrame.Angles(0, 0, math.rad(-35)))

	-- Glitzer fuer starke Haende
	if powerLevel >= 20 then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = color
		sparkles.Parent = palm
	end

	-- Griff: Hand sitzt vor der Faust, Finger zeigen nach vorne
	local baseGrip = CFrame.new(0, 0, -0.4 * scale) * CFrame.Angles(math.rad(-90), 0, 0)
	tool.Grip = baseGrip

	local swingId = 0
	tool.Activated:Connect(function()
		local player = Players:GetPlayerFromCharacter(tool.Parent)
		if not player then
			return
		end
		if onSlap(player) then
			-- kleine Schwung-Animation ueber den Griff
			swingId = swingId + 1
			local myId = swingId
			tool.Grip = baseGrip * CFrame.Angles(math.rad(70), 0, 0)
			task.delay(0.12, function()
				if swingId == myId and tool.Parent then
					tool.Grip = baseGrip
				end
			end)
		end
	end)

	return tool
end

local function removeHandTools(player)
	local containers = { player:FindFirstChildOfClass("Backpack"), player.Character }
	for _, container in ipairs(containers) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Tool") and child.Name == HAND_TOOL_NAME then
					child:Destroy()
				end
			end
		end
	end
end

-- Gibt dem Spieler eine (neue) Hand passend zu seinem Staerke-Level.
-- Wenn er die alte Hand gerade in der Hand hatte, wird die neue ausgeruestet.
local function giveHand(player)
	local profile = profiles[player]
	if not profile then
		return
	end
	local character = player.Character
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not character or not backpack then
		return
	end

	local wasEquipped = false
	local equipped = character:FindFirstChildOfClass("Tool")
	if equipped and equipped.Name == HAND_TOOL_NAME then
		wasEquipped = true
	end

	removeHandTools(player)

	local tool = buildHandTool(profile.Data.Upgrades.Power)
	tool.Parent = backpack

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 and (wasEquipped or profile.AutoEquip) then
		profile.AutoEquip = false
		humanoid:EquipTool(tool)
	end
end

--------------------------------------------------------------------------
-- Slap-Logik (alles serverseitig geprueft)
--------------------------------------------------------------------------
local function findTarget(rootPosition, reach)
	local best, bestDistance = nil, math.huge
	for _, g in ipairs(gyatts) do
		if g.Alive then
			local surfaceDistance = (g.Body.Position - rootPosition).Magnitude - g.BaseSize.X / 2
			if surfaceDistance <= reach and surfaceDistance < bestDistance then
				best = g
				bestDistance = surfaceDistance
			end
		end
	end
	return best
end

local function defeatGyatt(g, killer)
	g.Alive = false
	g.Health = 0
	updateGyattGui(g)
	if g.CurrentTween then
		g.CurrentTween:Cancel()
		g.CurrentTween = nil
	end
	g.Body.Size = g.BaseSize
	g.Body.Color = g.BaseColor
	setGyattVisible(g, false)

	-- kleine Explosion (ohne Schaden)
	local explosion = Instance.new("Explosion")
	explosion.BlastPressure = 0
	explosion.BlastRadius = 0
	explosion.DestroyJointRadiusPercent = 0
	explosion.Position = g.Body.Position
	explosion.Parent = workspace

	notifyAll("💥 " .. killer.DisplayName .. " hat den " .. g.Config.DisplayName .. " besiegt!", { 255, 200, 80 })

	-- Bonus fuer alle, die mitgeslappt haben
	for userId in pairs(g.Contributors) do
		local player = Players:GetPlayerByUserId(userId)
		local profile = player and profiles[player]
		if profile and profile.Loaded then
			local bonus = math.floor(g.Config.DefeatBonus * getMultiplier(profile))
			profile.Data.Slaps = profile.Data.Slaps + bonus
			notify(player, "🎉 Besiegt-Bonus: +" .. Config.FormatNumber(bonus) .. " Slaps", { 120, 255, 140 })
			pushState(player)
		end
	end
	g.Contributors = {}

	task.delay(Config.GyattRespawnTime, function()
		g.Health = g.Config.MaxHealth
		g.Alive = true
		updateGyattGui(g)
		setGyattVisible(g, true)
	end)
end

-- Gibt true zurueck, wenn ein Slap ausgefuehrt wurde (fuer die Animation).
onSlap = function(player)
	local profile = profiles[player]
	if not profile or not profile.Loaded then
		return false
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or humanoid.Health <= 0 then
		return false
	end

	local upgrades = profile.Data.Upgrades
	local now = os.clock()
	-- kleine Toleranz (0.05 s) wegen Netzwerk-Schwankungen
	if now - profile.LastSlap < Config.GetCooldown(upgrades.Speed) - 0.05 then
		return false
	end
	profile.LastSlap = now

	local target = findTarget(root.Position, Config.GetReach(upgrades.Reach))
	if not target then
		return true -- Luft-Slap
	end

	if upgrades.Power < target.Config.RequiredPower then
		if now - profile.LastWarning > 2 then
			profile.LastWarning = now
			notify(
				player,
				"😤 Deine Hand ist zu schwach! " .. target.Config.DisplayName .. " braucht Hand-Staerke Lv " .. target.Config.RequiredPower,
				{ 255, 120, 120 }
			)
		end
		return true
	end

	local damage = Config.GetDamage(upgrades.Power)
	local isCrit = math.random() < Config.GetCritChance(upgrades.Luck)
	if isCrit then
		damage = damage * Config.CritMultiplier
	end

	local reward = math.max(1, math.floor(damage * target.Config.RewardMultiplier * getMultiplier(profile)))
	profile.Data.Slaps = profile.Data.Slaps + reward
	profile.Data.TotalSlaps = profile.Data.TotalSlaps + 1
	target.Contributors[player.UserId] = true

	target.Health = target.Health - damage
	target.Sound:Play()
	SlapFx:FireAllClients(target.Body.Position, target.BaseSize.X / 2, damage, isCrit, reward, player.UserId)

	if target.Health <= 0 then
		defeatGyatt(target, player)
	else
		updateGyattGui(target)
		wobbleGyatt(target)
	end

	pushState(player)
	return true
end

--------------------------------------------------------------------------
-- Shop: Upgrades & Rebirth
--------------------------------------------------------------------------
BuyUpgrade.OnServerEvent:Connect(function(player, upgradeId)
	local profile = profiles[player]
	if not profile or not profile.Loaded then
		return
	end
	if type(upgradeId) ~= "string" or not Config.Upgrades[upgradeId] then
		return
	end
	local level = profile.Data.Upgrades[upgradeId]
	local cost = Config.GetUpgradeCost(upgradeId, level)
	if not cost then
		notify(player, "Dieses Upgrade ist schon auf Max-Level!", { 255, 220, 120 })
		return
	end
	if profile.Data.Slaps < cost then
		notify(player, "Nicht genug Slaps! Du brauchst " .. Config.FormatNumber(cost), { 255, 120, 120 })
		return
	end

	profile.Data.Slaps = profile.Data.Slaps - cost
	profile.Data.Upgrades[upgradeId] = level + 1

	local upgrade = Config.Upgrades[upgradeId]
	notify(player, upgrade.Icon .. " " .. upgrade.DisplayName .. " ist jetzt Level " .. (level + 1) .. "!", { 120, 255, 140 })

	if upgradeId == "Power" then
		local oldTier = Config.GetHandTier(level)
		local newTier = Config.GetHandTier(level + 1)
		if oldTier ~= newTier then
			notify(player, "✨ Neue Hand freigeschaltet: " .. newTier.Name .. "!", newTier.Color)
		end
		giveHand(player) -- Hand waechst
	end
	pushState(player)
end)

DoRebirth.OnServerEvent:Connect(function(player)
	local profile = profiles[player]
	if not profile or not profile.Loaded then
		return
	end
	local cost = Config.GetRebirthCost(profile.Data.Rebirths)
	if profile.Data.Slaps < cost then
		notify(player, "Fuer einen Rebirth brauchst du " .. Config.FormatNumber(cost) .. " Slaps!", { 255, 120, 120 })
		return
	end
	profile.Data.Rebirths = profile.Data.Rebirths + 1
	profile.Data.Slaps = 0
	for _, id in ipairs(Config.UpgradeOrder) do
		profile.Data.Upgrades[id] = 0
	end
	notifyAll(
		"♻️ " .. player.DisplayName .. " hat Rebirth " .. profile.Data.Rebirths .. " gemacht!",
		{ 200, 150, 255 }
	)
	giveHand(player)
	pushState(player)
	task.spawn(saveProfile, player, profile)
end)

RequestState.OnServerEvent:Connect(function(player)
	local profile = profiles[player]
	if profile and profile.Loaded then
		pushState(player)
	end
end)

--------------------------------------------------------------------------
-- Spieler betreten / verlassen
--------------------------------------------------------------------------
local function onCharacterAdded(player, character)
	local profile = profiles[player]
	if not profile or not profile.Loaded then
		return
	end
	-- warten bis Backpack/Humanoid bereit sind
	character:WaitForChild("Humanoid", 10)
	player:WaitForChild("Backpack", 10)
	if player.Character ~= character or not player.Parent then
		return
	end
	profile.AutoEquip = true
	giveHand(player)
end

local function onPlayerAdded(player)
	local profile = {
		Data = defaultData(),
		Loaded = false,
		CanSave = false,
		LastSlap = 0,
		LastWarning = 0,
		AutoEquip = true,
		Leaderstats = nil,
	}
	profiles[player] = profile

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local slaps = Instance.new("NumberValue")
	slaps.Name = "Slaps"
	slaps.Parent = leaderstats
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Parent = leaderstats
	leaderstats.Parent = player
	profile.Leaderstats = { Slaps = slaps, Rebirths = rebirths }

	local ok, data = loadData(player)
	if not player.Parent then
		profiles[player] = nil
		return -- Spieler hat das Spiel waehrend des Ladens verlassen
	end
	profile.Data = data
	profile.Loaded = true
	-- Nur speichern, wenn das Laden geklappt hat (sonst wuerden wir alte Daten ueberschreiben)
	profile.CanSave = ok
	if not ok then
		if RunService:IsStudio() then
			notify(player, "⚠️ Speichern aus: In Studio 'Game Settings > Security > Enable Studio Access to API Services' anschalten.", { 255, 200, 120 })
		else
			notify(player, "⚠️ Dein Spielstand konnte nicht geladen werden. Fortschritt wird diese Runde nicht gespeichert.", { 255, 120, 120 })
		end
	end

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end

	pushState(player)
	notify(player, "👋 Willkommen bei Slap the Gyatt! Kauf Upgrades fuer deine Hand im Shop.", { 255, 170, 220 })
end

local function onPlayerRemoving(player)
	local profile = profiles[player]
	if profile then
		profiles[player] = nil
		saveProfile(player, profile)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- Automatisch speichern
task.spawn(function()
	while true do
		task.wait(Config.AutosaveInterval)
		for player, profile in pairs(profiles) do
			task.spawn(saveProfile, player, profile)
		end
	end
end)

-- Beim Herunterfahren des Servers alles speichern
game:BindToClose(function()
	if RunService:IsStudio() and not dataStore then
		return
	end
	local pending = 0
	for player, profile in pairs(profiles) do
		pending = pending + 1
		task.spawn(function()
			saveProfile(player, profile)
			pending = pending - 1
		end)
	end
	local started = os.clock()
	while pending > 0 and os.clock() - started < 25 do
		task.wait(0.1)
	end
end)

print("[SlapTheGyatt] Server gestartet - viel Spass beim Slappen!")
