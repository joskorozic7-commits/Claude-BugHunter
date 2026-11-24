--[[
	WorldFx: alles, was der Client in der Welt animiert.
	  * Gyatts huepfen, schauen dich an, wackeln und erschrecken bei Treffern
	  * Eier drehen sich, Regenbogen-Haende leuchten
	  * Tore freigeschalteter Zonen werden durchlaessig
	  * Licht & Stimmung je nach Zone
	  * Tutorial-Pfeil zum ersten Gyatt
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local WorldFx = {}
local ctx, Config, Calc

local player = Players.LocalPlayer
local gyattCache = {} -- [Model] = Animationsdaten
local hitsByKey = {} -- [Key] = { Time, From }
local currentZone = -1

--------------------------------------------------------------------------
-- Gyatts
--------------------------------------------------------------------------
local function getCache(model)
	local cache = gyattCache[model]
	if cache then
		return cache
	end
	local smiles = {}
	for _, child in ipairs(model:GetChildren()) do
		if child.Name == "MouthSmile" then
			table.insert(smiles, child)
		end
	end
	cache = {
		Phase = math.random() * 10,
		Yaw = 0,
		MouthO = model:FindFirstChild("MouthO"),
		Smiles = smiles,
		Highlight = model:FindFirstChild("Outline"),
		Shocked = false,
	}
	gyattCache[model] = cache
	return cache
end

local function setShocked(cache, shocked)
	if cache.Shocked == shocked then
		return
	end
	cache.Shocked = shocked
	if cache.MouthO then
		cache.MouthO.Transparency = shocked and 0 or 1
	end
	for _, part in ipairs(cache.Smiles) do
		part.Transparency = shocked and 1 or 0
	end
end

local function angleLerp(a, b, t)
	local diff = (b - a + math.pi) % (math.pi * 2) - math.pi
	return a + diff * t
end

local function animateGyatts(dt)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local camera = workspace.CurrentCamera
	local cameraPos = camera and camera.CFrame.Position or Vector3.new()
	local now = os.clock()

	for _, model in ipairs(CollectionService:GetTagged("SlapGyatt")) do
		local base = model:GetAttribute("BaseCFrame")
		local size = model:GetAttribute("Size") or 6
		if model.Parent and typeof(base) == "CFrame" and model.PrimaryPart then
			local position = base.Position
			if (position - cameraPos).Magnitude < 260 then
				local cache = getCache(model)

				-- zum Spieler drehen
				local targetYaw = cache.Yaw
				if root then
					local d = root.Position - position
					if d.X * d.X + d.Z * d.Z > 1 then
						targetYaw = math.atan2(-d.X, -d.Z)
					end
				end
				cache.Yaw = angleLerp(cache.Yaw, targetYaw, math.min(1, dt * 4))

				-- Treffer-Reaktion
				local hit = hitsByKey[model:GetAttribute("Key")]
				local k = 0
				if hit then
					local age = now - hit.Time
					if age < 0.35 then
						k = 1 - age / 0.35
					end
				end
				setShocked(cache, k > 0.15)
				if cache.Highlight then
					cache.Highlight.FillTransparency = 1 - 0.55 * k
				end

				local bounce = math.abs(math.sin(now * 2.2 + cache.Phase)) * size * 0.05
				local wobble = math.sin(now * 40) * k * 0.12
				local pivot = CFrame.new(position + Vector3.new(0, bounce - k * size * 0.04, 0))
					* CFrame.Angles(0, cache.Yaw, 0)
					* CFrame.Angles(k * 0.32, 0, wobble)
				model:PivotTo(pivot)
			end
		end
	end

	-- alte Eintraege aufraeumen
	for model in pairs(gyattCache) do
		if not model.Parent then
			gyattCache[model] = nil
		end
	end
end

function WorldFx.OnSlap(info)
	if info.Kind == "Gyatt" and type(info.Key) == "string" then
		hitsByKey[info.Key] = { Time = os.clock() }
	end
end

--------------------------------------------------------------------------
-- Eier & Regenbogen
--------------------------------------------------------------------------
local function animateEggs()
	local t = os.clock()
	for _, egg in ipairs(CollectionService:GetTagged("SlapEgg")) do
		local baseY = egg:GetAttribute("BaseY")
		if type(baseY) == "number" then
			local p = egg.Position
			egg.CFrame = CFrame.new(p.X, baseY + math.sin(t * 2 + p.Z) * 0.4, p.Z) * CFrame.Angles(0, t * 0.8, math.sin(t * 3) * 0.08)
		end
	end
	local rainbow = Color3.fromHSV((t * 0.25) % 1, 0.75, 1)
	for _, part in ipairs(CollectionService:GetTagged("RainbowHand")) do
		part.Color = rainbow
	end
end

--------------------------------------------------------------------------
-- Tore
--------------------------------------------------------------------------
local function refreshGates()
	local unlocked = (ctx.State and ctx.State.Zones) or 1
	for _, gate in ipairs(CollectionService:GetTagged("SlapGate")) do
		local index = gate:GetAttribute("ZoneIndex") or 99
		local open = index <= unlocked
		gate.CanCollide = not open
		gate.Transparency = open and 0.9 or 0.3
		for _, gui in ipairs(gate:GetChildren()) do
			if gui:IsA("SurfaceGui") then
				gui.Enabled = not open
			end
		end
	end
	-- Prompts zum Freischalten bereits offener Zonen verstecken
	local world = workspace:FindFirstChild("SlapWorld")
	if world then
		for index = 2, #Config.Zones do
			local zoneFolder = world:FindFirstChild("Zone" .. index)
			local promptPart = zoneFolder and zoneFolder:FindFirstChild("GatePrompt")
			local prompt = promptPart and promptPart:FindFirstChild("UnlockPrompt")
			if prompt then
				prompt.Enabled = index > unlocked
			end
		end
	end
end

--------------------------------------------------------------------------
-- Stimmung pro Zone
--------------------------------------------------------------------------
local MOODS = {
	[0] = { Clock = 14.5, Color = { 255, 220, 235 }, Decay = { 150, 110, 160 }, Density = 0.28, Tint = { 255, 255, 255 }, Cloud = 0.55, CloudColor = { 255, 245, 250 } },
	[1] = { Clock = 14.5, Color = { 255, 225, 235 }, Decay = { 140, 160, 120 }, Density = 0.28, Tint = { 255, 255, 255 }, Cloud = 0.55, CloudColor = { 255, 255, 255 } },
	[2] = { Clock = 15.8, Color = { 255, 225, 180 }, Decay = { 200, 140, 90 }, Density = 0.33, Tint = { 255, 242, 220 }, Cloud = 0.3, CloudColor = { 255, 235, 210 } },
	[3] = { Clock = 13, Color = { 220, 240, 255 }, Decay = { 140, 180, 220 }, Density = 0.36, Tint = { 232, 242, 255 }, Cloud = 0.75, CloudColor = { 240, 245, 255 } },
	[4] = { Clock = 18.1, Color = { 255, 150, 110 }, Decay = { 140, 40, 30 }, Density = 0.42, Tint = { 255, 222, 210 }, Cloud = 0.8, CloudColor = { 90, 70, 70 } },
	[5] = { Clock = 12, Color = { 255, 255, 255 }, Decay = { 255, 230, 200 }, Density = 0.3, Tint = { 255, 250, 240 }, Cloud = 0.7, CloudColor = { 255, 250, 235 } },
	[6] = { Clock = 0.5, Color = { 120, 90, 200 }, Decay = { 40, 20, 90 }, Density = 0.22, Tint = { 222, 212, 255 }, Cloud = 0, CloudColor = { 255, 255, 255 } },
}

local function applyMood(zoneIndex)
	local mood = MOODS[zoneIndex] or MOODS[0]
	local info = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	TweenService:Create(Lighting, info, { ClockTime = mood.Clock }):Play()
	local atmosphere = Lighting:FindFirstChild("SlapAtmosphere")
	if atmosphere then
		TweenService:Create(atmosphere, info, {
			Color = ctx.UI.rgb(mood.Color),
			Decay = ctx.UI.rgb(mood.Decay),
			Density = mood.Density,
		}):Play()
	end
	local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
	if clouds then
		TweenService:Create(clouds, info, { Cover = mood.Cloud, Color = ctx.UI.rgb(mood.CloudColor) }):Play()
	end
	local color = Lighting:FindFirstChild("SlapColor")
	if color then
		TweenService:Create(color, info, { TintColor = ctx.UI.rgb(mood.Tint) }):Play()
	end
end

local function checkZone()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local zone = Calc.GetZoneAtZ(root.Position.Z)
	if zone ~= currentZone then
		currentZone = zone
		ctx.Hud.SetZone(zone)
		applyMood(zone)
	end
end

--------------------------------------------------------------------------
-- Tutorial-Pfeil
--------------------------------------------------------------------------
local tutorial = { Beam = nil, A0 = nil, A1 = nil }

local function clearTutorial()
	for _, key in ipairs({ "Beam", "A0", "A1" }) do
		if tutorial[key] then
			tutorial[key]:Destroy()
			tutorial[key] = nil
		end
	end
end

local function updateTutorial()
	local state = ctx.State
	if not state or state.TutorialDone then
		clearTutorial()
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local target = nil
	for _, model in ipairs(CollectionService:GetTagged("SlapGyatt")) do
		if model:GetAttribute("Key") == "Z1_1" and model.Parent then
			target = model.PrimaryPart
		end
	end
	if not root or not target then
		clearTutorial()
		return
	end
	if tutorial.A0 and tutorial.A0.Parent == root and tutorial.A1 and tutorial.A1.Parent == target then
		return
	end
	clearTutorial()
	tutorial.A0 = Instance.new("Attachment")
	tutorial.A0.Parent = root
	tutorial.A1 = Instance.new("Attachment")
	tutorial.A1.Parent = target
	local beam = Instance.new("Beam")
	beam.Attachment0 = tutorial.A0
	beam.Attachment1 = tutorial.A1
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 120, 200), Color3.fromRGB(255, 230, 120))
	beam.Width0 = 0.6
	beam.Width1 = 0.6
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.Transparency = NumberSequence.new(0.2)
	beam.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	beam.TextureMode = Enum.TextureMode.Wrap
	beam.TextureLength = 2
	beam.TextureSpeed = 2
	beam.Parent = tutorial.A0
	tutorial.Beam = beam
end

--------------------------------------------------------------------------
function WorldFx.Init(context)
	ctx = context
	Config = ctx.Config
	Calc = ctx.Calc

	RunService.RenderStepped:Connect(function(dt)
		animateGyatts(dt)
		animateEggs()
	end)

	ctx.OnState(function(_, full)
		if full then
			refreshGates()
			updateTutorial()
		end
	end)

	task.spawn(function()
		while true do
			task.wait(0.5)
			checkZone()
			refreshGates()
			updateTutorial()
		end
	end)
end

return WorldFx
