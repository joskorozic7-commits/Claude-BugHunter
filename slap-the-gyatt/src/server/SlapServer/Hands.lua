--[[
	Hands: baut das Slap-Hand-Tool (Aussehen je nach Hand + Staerke-Level)
	und gibt es dem Spieler.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SlapShared")
local Calc = require(Shared:WaitForChild("Calc"))

local Hands = {}
Hands.ToolName = "Slap Hand"

local ctx

local function rgb(t)
	return Color3.fromRGB(t[1], t[2], t[3])
end

local function material(name)
	local ok, result = pcall(function()
		return Enum.Material[name]
	end)
	if ok and result then
		return result
	end
	return Enum.Material.SmoothPlastic
end

local function handPart(name, size, color, mat, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = mat
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	p.Anchored = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	return p
end

function Hands.Build(data)
	local powerLevel = data.Upgrades.Power
	local hand = Calc.GetHand(data.Hand)
	local scale = Calc.GetHandScale(powerLevel)
	if hand.Effect == "thanos" then
		scale = scale * 1.25
	elseif hand.Effect == "ultragod" then
		scale = scale * 1.5
	end
	local color = rgb(hand.Color)
	local mat = material(hand.Material)

	local tool = Instance.new("Tool")
	tool.Name = Hands.ToolName
	tool.ToolTip = hand.DisplayName .. " (x" .. hand.Damage .. " Damage) - click to slap!"
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool:SetAttribute("HandId", hand.Id)
	tool:SetAttribute("PowerLevel", powerLevel)

	local palm = handPart("Handle", Vector3.new(1.4, 1.5, 0.55) * scale, color, mat)
	palm.CFrame = CFrame.new()
	palm.Parent = tool

	local parts = { palm }
	local function attach(p, offset)
		p.CFrame = palm.CFrame * offset
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = palm
		weld.Part1 = p
		weld.Parent = p
		p.Parent = tool
		table.insert(parts, p)
		return p
	end

	-- Finger mit Fingerkuppen
	local fingerXs = { -0.51, -0.17, 0.17, 0.51 }
	local fingerLengths = { 0.8, 1.0, 0.95, 0.75 }
	for i, x in ipairs(fingerXs) do
		local length = fingerLengths[i] * scale
		attach(handPart("Finger" .. i, Vector3.new(0.3 * scale, length, 0.45 * scale), color, mat),
			CFrame.new(x * scale, 0.75 * scale + length / 2, 0))
		attach(handPart("Tip" .. i, Vector3.new(0.3 * scale, 0.3 * scale, 0.3 * scale), color, mat, Enum.PartType.Ball),
			CFrame.new(x * scale, 0.75 * scale + length, 0))
	end
	-- Daumen
	attach(handPart("Thumb", Vector3.new(0.35 * scale, 0.75 * scale, 0.45 * scale), color, mat),
		CFrame.new(0.85 * scale, 0.05 * scale, 0) * CFrame.Angles(0, 0, math.rad(-35)))
	-- Armband in Kontrastfarbe
	attach(handPart("Cuff", Vector3.new(1.55 * scale, 0.35 * scale, 0.7 * scale), Color3.fromRGB(255, 110, 180), Enum.Material.Neon),
		CFrame.new(0, -0.8 * scale, 0))

	-- Effekte
	if hand.Effect == "sparkles" then
		local s = Instance.new("Sparkles")
		s.SparkleColor = color
		s.Parent = palm
	elseif hand.Effect == "fire" then
		local f = Instance.new("Fire")
		f.Size = 3 * scale
		f.Heat = 4
		f.Color = color
		f.SecondaryColor = Color3.fromRGB(255, 240, 120)
		f.Parent = palm
	elseif hand.Effect == "smoke" then
		local s = Instance.new("Smoke")
		s.Size = 1.5 * scale
		s.Opacity = 0.12
		s.RiseVelocity = 1
		s.Color = Color3.fromRGB(220, 240, 255)
		s.Parent = palm
	elseif hand.Effect == "rainbow" then
		for _, p in ipairs(parts) do
			if p.Name ~= "Cuff" then
				CollectionService:AddTag(p, "RainbowHand")
			end
		end
		local s = Instance.new("Sparkles")
		s.Parent = palm
	end
	if hand.Effect == "dragon" then
		-- schwarze Krallen an den Fingerspitzen
		for i, x in ipairs(fingerXs) do
			local length = fingerLengths[i] * scale
			attach(handPart("Claw" .. i, Vector3.new(0.18 * scale, 0.45 * scale, 0.18 * scale), Color3.fromRGB(20, 15, 15), Enum.Material.SmoothPlastic),
				CFrame.new(x * scale, 0.75 * scale + length + 0.3 * scale, -0.08 * scale) * CFrame.Angles(math.rad(-25), 0, 0))
		end
		local f = Instance.new("Fire")
		f.Size = 4 * scale
		f.Heat = 6
		f.Color = Color3.fromRGB(255, 60, 20)
		f.SecondaryColor = Color3.fromRGB(120, 0, 0)
		f.Parent = palm
	elseif hand.Effect == "thanos" then
		-- Die sechs Infinity-Steine
		local stones = {
			{ 160, 60, 255 }, -- Power
			{ 60, 140, 255 }, -- Space
			{ 255, 40, 40 }, -- Reality
			{ 255, 150, 30 }, -- Soul
			{ 40, 230, 90 }, -- Time
			{ 255, 230, 40 }, -- Mind
		}
		for i = 1, 4 do
			local x = fingerXs[i]
			local c = stones[i]
			local stone = attach(handPart("Stone" .. i, Vector3.new(0.24 * scale, 0.24 * scale, 0.24 * scale), Color3.fromRGB(c[1], c[2], c[3]), Enum.Material.Neon, Enum.PartType.Ball),
				CFrame.new(x * scale, 0.6 * scale, -0.3 * scale))
			stone.Name = "InfinityStone" .. i
		end
		local thumbStone = stones[5]
		attach(handPart("InfinityStone5", Vector3.new(0.24 * scale, 0.24 * scale, 0.24 * scale), Color3.fromRGB(thumbStone[1], thumbStone[2], thumbStone[3]), Enum.Material.Neon, Enum.PartType.Ball),
			CFrame.new(0.95 * scale, 0.2 * scale, -0.25 * scale))
		local mindStone = stones[6]
		attach(handPart("InfinityStone6", Vector3.new(0.42 * scale, 0.42 * scale, 0.42 * scale), Color3.fromRGB(mindStone[1], mindStone[2], mindStone[3]), Enum.Material.Neon, Enum.PartType.Ball),
			CFrame.new(0, -0.05 * scale, -0.3 * scale))
		local f = Instance.new("Fire")
		f.Size = 4 * scale
		f.Heat = 5
		f.Color = Color3.fromRGB(150, 60, 255)
		f.SecondaryColor = Color3.fromRGB(255, 200, 60)
		f.Parent = palm
		local s = Instance.new("Sparkles")
		s.SparkleColor = Color3.fromRGB(200, 120, 255)
		s.Parent = palm
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(170, 90, 255)
		light.Range = 14
		light.Brightness = 2
		light.Parent = palm
	elseif hand.Effect == "ultragod" then
		-- Regenbogen-Heiligenschein ums Handgelenk
		for i = 0, 9 do
			local angle = (i / 10) * math.pi * 2
			local orb = attach(handPart("HaloOrb" .. i, Vector3.new(0.28 * scale, 0.28 * scale, 0.28 * scale), Color3.fromRGB(255, 255, 255), Enum.Material.Neon, Enum.PartType.Ball),
				CFrame.new(math.cos(angle) * 1.15 * scale, -0.8 * scale, math.sin(angle) * 1.15 * scale))
			CollectionService:AddTag(orb, "RainbowHand")
		end
		-- goldene Kristalle auf den Knoecheln
		for i, x in ipairs(fingerXs) do
			attach(handPart("GodGem" .. i, Vector3.new(0.2 * scale, 0.32 * scale, 0.2 * scale), Color3.fromRGB(255, 215, 60), Enum.Material.Neon),
				CFrame.new(x * scale, 0.6 * scale, -0.32 * scale) * CFrame.Angles(0, math.rad(45), 0))
		end
		local f = Instance.new("Fire")
		f.Size = 6 * scale
		f.Heat = 9
		f.Color = Color3.fromRGB(255, 240, 160)
		f.SecondaryColor = Color3.fromRGB(255, 160, 255)
		f.Parent = palm
		local s = Instance.new("Sparkles")
		s.SparkleColor = Color3.fromRGB(255, 255, 200)
		s.Parent = palm
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 245, 200)
		light.Range = 22
		light.Brightness = 4
		light.Parent = palm
	end
	if hand.Effect == "aura" or hand.Effect == "omni" then
		local f = Instance.new("Fire")
		f.Size = 3 * scale
		f.Heat = 5
		f.Color = color
		f.SecondaryColor = Color3.fromRGB(255, 255, 255)
		f.Parent = palm
		local glowLight = Instance.new("PointLight")
		glowLight.Color = color
		glowLight.Range = 12
		glowLight.Brightness = 2
		glowLight.Parent = palm
	end
	if hand.Effect == "electric" then
		local s = Instance.new("Sparkles")
		s.SparkleColor = Color3.fromRGB(255, 255, 150)
		s.Parent = palm
		for i, x in ipairs(fingerXs) do
			attach(handPart("Bolt" .. i, Vector3.new(0.08 * scale, 0.5 * scale, 0.08 * scale), Color3.fromRGB(255, 255, 200), Enum.Material.Neon),
				CFrame.new(x * scale, 0.75 * scale + fingerLengths[i] * scale + 0.35 * scale, 0) * CFrame.Angles(0, 0, math.rad((i % 2 == 0) and 25 or -25)))
		end
	elseif hand.Effect == "shadow" then
		local smoke = Instance.new("Smoke")
		smoke.Size = 2 * scale
		smoke.Opacity = 0.25
		smoke.RiseVelocity = 2
		smoke.Color = Color3.fromRGB(80, 30, 120)
		smoke.Parent = palm
	elseif hand.Effect == "orbit" or hand.Effect == "omni" then
		for i = 0, 7 do
			local angle = (i / 8) * math.pi * 2
			local orb = attach(handPart("Orb" .. i, Vector3.new(0.26 * scale, 0.26 * scale, 0.26 * scale), color, Enum.Material.Neon, Enum.PartType.Ball),
				CFrame.new(math.cos(angle) * 1.1 * scale, 0.2 * scale, math.sin(angle) * 1.1 * scale))
			if hand.Effect == "omni" then
				CollectionService:AddTag(orb, "RainbowHand")
			end
		end
		if hand.Effect == "omni" then
			for _, p in ipairs(parts) do
				if p.Name ~= "Cuff" then
					CollectionService:AddTag(p, "RainbowHand")
				end
			end
		end
	end
	-- Schweif beim Schlagen (in der Farbe der Hand)
	local trailTop = Instance.new("Attachment")
	trailTop.Name = "TrailTop"
	trailTop.Position = Vector3.new(0, 0.9 * scale, 0)
	trailTop.Parent = palm
	local trailBottom = Instance.new("Attachment")
	trailBottom.Name = "TrailBottom"
	trailBottom.Position = Vector3.new(0, -0.6 * scale, 0)
	trailBottom.Parent = palm
	local trail = Instance.new("Trail")
	trail.Name = "SlapTrail"
	trail.Attachment0 = trailTop
	trail.Attachment1 = trailBottom
	trail.Lifetime = 0.18
	trail.MinLength = 0.1
	trail.FaceCamera = true
	trail.LightEmission = 0.6
	trail.Color = ColorSequence.new(color, Color3.fromRGB(255, 255, 255))
	trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 1) })
	trail.Parent = palm

	if hand.Material == "Neon" then
		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = 8
		light.Brightness = 1
		light.Parent = palm
	end

	-- Griff: Handflaeche nach vorne, Finger nach oben
	local baseGrip = CFrame.new(0, 0, -0.45 * scale) * CFrame.Angles(math.rad(-90), 0, 0)
	tool.Grip = baseGrip
	tool:SetAttribute("BaseGrip", baseGrip)

	tool.Activated:Connect(function()
		local player = ctx.Players:GetPlayerFromCharacter(tool.Parent)
		if not player then
			return
		end
		if ctx.Combat.TrySlap(player) then
			Hands.SwingTool(tool)
		end
	end)

	return tool
end

local function removeHands(player)
	local containers = { player:FindFirstChildOfClass("Backpack"), player.Character }
	for _, container in ipairs(containers) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Tool") and child.Name == Hands.ToolName then
					child:Destroy()
				end
			end
		end
	end
end

-- Gibt dem Spieler eine neue Hand. Ausgeruestet, wenn sie es vorher war
-- (oder forceEquip gesetzt ist).
function Hands.Give(player, forceEquip)
	local profile = ctx.Data.Get(player)
	if not profile then
		return
	end
	local character = player.Character
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not character or not backpack then
		return
	end
	local current = character:FindFirstChildOfClass("Tool")
	local wasEquipped = current ~= nil and current.Name == Hands.ToolName

	removeHands(player)
	local tool = Hands.Build(profile.Data)
	tool.Parent = backpack

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 and (wasEquipped or forceEquip) then
		humanoid:EquipTool(tool)
	end
end

-- Hat der Spieler die Hand gerade in der Hand?
function Hands.IsEquipped(player)
	local character = player.Character
	if not character then
		return false
	end
	local tool = character:FindFirstChildOfClass("Tool")
	return tool ~= nil and tool.Name == Hands.ToolName
end

-- Kurze Schwung-Animation ueber den Griff
function Hands.SwingTool(tool)
	local base = tool:GetAttribute("BaseGrip")
	if typeof(base) ~= "CFrame" then
		return
	end
	local swingId = (tool:GetAttribute("SwingId") or 0) + 1
	tool:SetAttribute("SwingId", swingId)
	tool.Grip = base * CFrame.Angles(math.rad(75), 0, 0)
	task.delay(0.1, function()
		if tool.Parent and tool:GetAttribute("SwingId") == swingId then
			tool.Grip = base
		end
	end)
end

-- Schwung fuer Auto-Slap
function Hands.Swing(player)
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	if tool and tool.Name == Hands.ToolName then
		Hands.SwingTool(tool)
	end
end

function Hands.Init(context)
	ctx = context
end

return Hands
