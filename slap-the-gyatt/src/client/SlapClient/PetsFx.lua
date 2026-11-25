--[[
	PetsFx: baut die Pets aus Teilen und animiert sie (nur lokal, fluessig).

	Jedes Pet besteht aus Teilen mit fester Position relativ zum Koerper.
	Pro Frame wird jedes Teil neu gesetzt: Koerper-Position * Teil-Versatz * Animation.
	  Bewegung: "hop" (huepft beim Laufen), "fly" (schwebt, Fluegel schlagen),
	            "float" (sanftes Schweben), "swim" (schwimmt hin und her)
	  Teil-Animationen: wingL/wingR (flattern), tail (wedeln), ear (zucken),
	            tentacle (wellen), spin (drehen)
	  Seltene Pets: Glitzer + Licht, Secret-Pets: Regenbogenfarben
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PetsFx = {}
local ctx, Config, UI

local folder
local owners = {} -- [Player] = { Signature, Pets = { pet, ... } }

local MOTION = {
	dog = "hop", cat = "hop", bunny = "hop", bear = "hop", fox = "hop", panda = "hop", frog = "hop",
	dino = "hop", turtle = "hop", golem = "hop",
	bird = "fly", dragon = "fly", bat = "fly", bee = "fly", owl = "fly", unicorn = "fly",
	slime = "float", robot = "float", alien = "float", ghost = "float", jelly = "float",
	whale = "swim", shark = "swim", octopus = "swim",
}

local WHITE = Color3.fromRGB(255, 255, 255)
local BLACK = Color3.fromRGB(20, 15, 25)

local function shade(c, amount)
	return Color3.new(math.clamp(c.R + amount, 0, 1), math.clamp(c.G + amount, 0, 1), math.clamp(c.B + amount, 0, 1))
end

-- Pet-Bauplan: fuegt Teile mit Versatz und Rolle hinzu
local function newBuilder(petModel)
	local builder = { Parts = {}, Model = petModel }
	function builder:add(name, size, offset, color, shape, mat, role, extra)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Size = size
		p.Color = color
		p.Material = mat or Enum.Material.SmoothPlastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		if shape == "Oval" then
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Parent = p
		elseif shape then
			p.Shape = shape
		end
		p.Parent = self.Model
		table.insert(self.Parts, { Part = p, Offset = offset, Role = role, Extra = extra or 0 })
		return p
	end
	return builder
end

local BALL = Enum.PartType.Ball
local CYL = Enum.PartType.Cylinder

local function addEyes(b, front, y, spread, size, big)
	size = size or 0.42
	for _, side in ipairs({ -1, 1 }) do
		b:add("Eye", Vector3.new(size, size, size), CFrame.new(side * spread, y, front + 0.1), WHITE, BALL)
		b:add("Pupil", Vector3.new(size * 0.55, size * 0.55, size * 0.55), CFrame.new(side * spread, y, front - 0.06 - (big and 0.06 or 0)), BLACK, BALL)
		b:add("Shine", Vector3.new(size * 0.2, size * 0.2, size * 0.2), CFrame.new(side * spread - 0.06, y + size * 0.15, front - 0.14), WHITE, BALL, Enum.Material.Neon)
	end
end

local function addBlush(b, front, spread)
	for _, side in ipairs({ -1, 1 }) do
		local p = b:add("Blush", Vector3.new(0.28, 0.16, 0.08), CFrame.new(side * spread, -0.1, front + 0.15), Color3.fromRGB(255, 120, 160), "Oval")
		p.Transparency = 0.3
	end
end

local function addWings(b, color, y, z, span, mat)
	for _, side in ipairs({ -1, 1 }) do
		local wing = b:add("Wing", Vector3.new(span, 0.12, span * 0.6), CFrame.new(side * 0.75, y, z), color, "Oval", mat or Enum.Material.SmoothPlastic,
			side < 0 and "wingL" or "wingR", span)
		wing.Transparency = 0.1
	end
end

local function addTail(b, color, size, offset, mat)
	b:add("Tail", size, offset, color, "Oval", mat, "tail")
end

-- Pet bauen
local function buildPet(petId)
	local cfg = Config.Pets[petId]
	local rarity = Config.Rarities[cfg.Rarity]
	local color = UI.rgb(cfg.Color)
	local light = shade(color, 0.15)
	local dark = shade(color, -0.15)
	local style = cfg.Style
	local model = Instance.new("Model")
	model.Name = "Pet_" .. petId
	local b = newBuilder(model)

	local body
	local front = -0.95
	if style == "robot" or style == "golem" then
		body = b:add("Body", Vector3.new(1.8, 1.6, 1.6), CFrame.new(), color, nil, style == "robot" and Enum.Material.DiamondPlate or Enum.Material.Slate)
		front = -0.8
	elseif style == "whale" or style == "shark" then
		body = b:add("Body", Vector3.new(1.7, 1.5, 2.8), CFrame.new(), color, "Oval")
		front = -1.3
	elseif style == "slime" or style == "jelly" then
		body = b:add("Body", Vector3.new(2, 1.5, 2), CFrame.new(), color, "Oval", Enum.Material.Glass)
		body.Transparency = 0.15
		front = -0.95
	else
		body = b:add("Body", Vector3.new(1.9, 1.9, 1.9), CFrame.new(), color, BALL, style == "ghost" and Enum.Material.Neon or Enum.Material.SmoothPlastic)
		if style == "ghost" then
			body.Transparency = 0.25
		end
	end
	model.PrimaryPart = body

	-- Gesicht
	if style == "owl" then
		addEyes(b, front, 0.2, 0.42, 0.62, true)
	elseif style == "frog" then
		for _, side in ipairs({ -1, 1 }) do
			b:add("EyeBump", Vector3.new(0.7, 0.7, 0.7), CFrame.new(side * 0.5, 0.85, -0.45), color, BALL)
		end
		addEyes(b, -0.75, 0.9, 0.5, 0.45)
	elseif style == "ghost" or style == "jelly" then
		for _, side in ipairs({ -1, 1 }) do
			b:add("Eye", Vector3.new(0.3, 0.46, 0.1), CFrame.new(side * 0.35, 0.15, front + 0.05), BLACK, "Oval")
		end
	elseif style == "robot" or style == "golem" then
		local eyeColor = style == "robot" and Color3.fromRGB(0, 255, 230) or Color3.fromRGB(255, 200, 80)
		for _, side in ipairs({ -1, 1 }) do
			b:add("Eye", Vector3.new(0.38, 0.22, 0.08), CFrame.new(side * 0.38, 0.2, front - 0.02), eyeColor, nil, Enum.Material.Neon)
		end
	else
		addEyes(b, front, 0.25, 0.38)
	end
	if style ~= "robot" and style ~= "golem" and style ~= "ghost" and style ~= "jelly" then
		addBlush(b, front, 0.62)
	end
	if style == "bird" or style == "owl" then
		b:add("Beak", Vector3.new(0.32, 0.22, 0.4), CFrame.new(0, -0.05, front - 0.1), Color3.fromRGB(255, 180, 40), "Oval")
	elseif style == "dog" or style == "bear" or style == "panda" or style == "fox" then
		b:add("Snout", Vector3.new(0.7, 0.5, 0.4), CFrame.new(0, -0.15, front + 0.05), light, "Oval")
		b:add("Nose", Vector3.new(0.24, 0.18, 0.18), CFrame.new(0, -0.05, front - 0.12), BLACK, BALL)
	elseif style ~= "robot" and style ~= "golem" then
		b:add("Mouth", Vector3.new(0.3, 0.06, 0.06), CFrame.new(0, -0.2, front + 0.02), BLACK)
	end

	-- Besonderheiten
	if style == "cat" then
		for _, side in ipairs({ -1, 1 }) do
			b:add("Ear", Vector3.new(0.45, 0.6, 0.2), CFrame.new(side * 0.5, 0.9, 0) * CFrame.Angles(0, 0, side * -0.4), light, nil, nil, "ear", side)
		end
		addTail(b, color, Vector3.new(0.25, 0.25, 1.2), CFrame.new(0, 0, 1.1) * CFrame.Angles(math.rad(-40), 0, 0))
	elseif style == "dog" then
		for _, side in ipairs({ -1, 1 }) do
			b:add("Ear", Vector3.new(0.35, 0.8, 0.2), CFrame.new(side * 0.85, 0.25, 0) * CFrame.Angles(0, 0, side * 0.3), dark, "Oval", nil, "ear", side)
		end
		addTail(b, color, Vector3.new(0.25, 0.25, 0.9), CFrame.new(0, 0.2, 1) * CFrame.Angles(math.rad(-50), 0, 0))
	elseif style == "bunny" then
		for _, side in ipairs({ -1, 1 }) do
			b:add("Ear", Vector3.new(0.3, 1.2, 0.2), CFrame.new(side * 0.35, 1.3, 0) * CFrame.Angles(0, 0, side * -0.15), light, "Oval", nil, "ear", side)
		end
		b:add("Tail", Vector3.new(0.5, 0.5, 0.5), CFrame.new(0, -0.3, 0.95), WHITE, BALL)
	elseif style == "bear" or style == "panda" then
		for _, side in ipairs({ -1, 1 }) do
			b:add("Ear", Vector3.new(0.5, 0.5, 0.5), CFrame.new(side * 0.65, 0.75, 0), style == "panda" and BLACK or dark, BALL)
			if style == "panda" then
				b:add("Patch", Vector3.new(0.5, 0.6, 0.1), CFrame.new(side * 0.38, 0.22, front + 0.12), BLACK, "Oval")
			end
		end
	elseif style == "fox" then
		for _, side in ipairs({ -1, 1 }) do
			b:add("Ear", Vector3.new(0.45, 0.75, 0.2), CFrame.new(side * 0.5, 0.95, 0) * CFrame.Angles(0, 0, side * -0.3), color, nil, nil, "ear", side)
			b:add("EarTip", Vector3.new(0.3, 0.2, 0.22), CFrame.new(side * 0.6, 1.25, 0) * CFrame.Angles(0, 0, side * -0.3), WHITE)
		end
		addTail(b, color, Vector3.new(0.6, 0.6, 1.5), CFrame.new(0, 0.1, 1.3) * CFrame.Angles(math.rad(-30), 0, 0))
	elseif style == "dragon" then
		addWings(b, light, 0.3, 0.3, 1.4, Enum.Material.Neon)
		for _, side in ipairs({ -1, 1 }) do
			b:add("Horn", Vector3.new(0.2, 0.6, 0.2), CFrame.new(side * 0.4, 1, 0.1) * CFrame.Angles(-0.3, 0, side * -0.2), Color3.fromRGB(255, 240, 200))
		end
		addTail(b, color, Vector3.new(0.35, 0.35, 1.4), CFrame.new(0, -0.2, 1.3))
		for i = 1, 3 do
			b:add("Spike", Vector3.new(0.18, 0.35, 0.3), CFrame.new(0, 0.75 - i * 0.15, 0.2 + i * 0.25), light)
		end
	elseif style == "bird" then
		addWings(b, light, 0.1, 0.2, 1.2)
		addTail(b, dark, Vector3.new(0.5, 0.1, 0.7), CFrame.new(0, 0, 1.1))
	elseif style == "owl" then
		addWings(b, dark, 0, 0.2, 1.1)
		for _, side in ipairs({ -1, 1 }) do
			b:add("Tuft", Vector3.new(0.25, 0.5, 0.2), CFrame.new(side * 0.55, 1, 0) * CFrame.Angles(0, 0, side * -0.4), dark)
		end
	elseif style == "bat" then
		addWings(b, dark, 0.2, 0.2, 1.5, Enum.Material.SmoothPlastic)
		for _, side in ipairs({ -1, 1 }) do
			b:add("Ear", Vector3.new(0.35, 0.6, 0.15), CFrame.new(side * 0.45, 0.95, 0) * CFrame.Angles(0, 0, side * -0.3), dark, nil, nil, "ear", side)
		end
	elseif style == "bee" then
		for i = -1, 1, 2 do
			b:add("Stripe", Vector3.new(1.95, 0.25, 1.95), CFrame.new(0, i * 0.3, 0), BLACK, "Oval")
		end
		addWings(b, Color3.fromRGB(220, 240, 255), 0.6, 0.3, 0.9, Enum.Material.Glass)
		b:add("Stinger", Vector3.new(0.15, 0.15, 0.5), CFrame.new(0, -0.1, 1.15), BLACK)
		for _, side in ipairs({ -1, 1 }) do
			b:add("Antenna", Vector3.new(0.08, 0.6, 0.08), CFrame.new(side * 0.3, 1.1, -0.3) * CFrame.Angles(-0.4, 0, side * -0.3), BLACK)
		end
	elseif style == "unicorn" then
		b:add("Horn", Vector3.new(0.22, 0.9, 0.22), CFrame.new(0, 1.15, -0.35) * CFrame.Angles(-0.4, 0, 0), Color3.fromRGB(255, 230, 120), nil, Enum.Material.Neon)
		b:add("Mane", Vector3.new(0.3, 0.9, 1.2), CFrame.new(0, 0.8, 0.4), Color3.fromRGB(170, 120, 255), "Oval")
		addWings(b, WHITE, 0.3, 0.3, 1.1)
	elseif style == "frog" then
		for _, side in ipairs({ -1, 1 }) do
			b:add("Leg", Vector3.new(0.5, 0.3, 0.7), CFrame.new(side * 0.7, -0.8, 0.2), dark, "Oval")
		end
	elseif style == "dino" then
		for i = 1, 4 do
			b:add("Spike", Vector3.new(0.2, 0.45, 0.3), CFrame.new(0, 0.95 - i * 0.12, -0.1 + i * 0.3), light)
		end
		addTail(b, color, Vector3.new(0.5, 0.5, 1.4), CFrame.new(0, -0.3, 1.2))
	elseif style == "turtle" then
		b:add("Shell", Vector3.new(2.2, 1.1, 2.2), CFrame.new(0, 0.55, 0.25), Color3.fromRGB(70, 140, 60), "Oval")
		for _, side in ipairs({ -1, 1 }) do
			b:add("Leg", Vector3.new(0.45, 0.35, 0.45), CFrame.new(side * 0.75, -0.8, -0.3), light, BALL)
			b:add("Leg", Vector3.new(0.45, 0.35, 0.45), CFrame.new(side * 0.75, -0.8, 0.6), light, BALL)
		end
	elseif style == "golem" then
		for i = 1, 3 do
			b:add("Crystal", Vector3.new(0.3, 0.7, 0.3), CFrame.new((i - 2) * 0.45, 0.95, 0.2) * CFrame.Angles(0, 0, (i - 2) * 0.3), Color3.fromRGB(120, 230, 255), nil, Enum.Material.Neon)
		end
		for _, side in ipairs({ -1, 1 }) do
			b:add("Fist", Vector3.new(0.55, 0.55, 0.55), CFrame.new(side * 1.15, -0.2, 0), dark, BALL, Enum.Material.Slate, "ear", side)
		end
	elseif style == "whale" or style == "shark" then
		addTail(b, light, Vector3.new(1.4, 0.15, 0.6), CFrame.new(0, 0.2, 1.6))
		if style == "shark" then
			b:add("Fin", Vector3.new(0.2, 0.8, 0.6), CFrame.new(0, 0.95, 0.2) * CFrame.Angles(-0.3, 0, 0), dark)
			b:add("Teeth", Vector3.new(0.6, 0.12, 0.08), CFrame.new(0, -0.3, front + 0.05), WHITE)
		else
			b:add("Spout", Vector3.new(0.25, 0.25, 0.25), CFrame.new(0, 1.05, 0.2), Color3.fromRGB(150, 220, 255), BALL, Enum.Material.Neon, "spin")
		end
	elseif style == "octopus" then
		for i = 0, 5 do
			local angle = (i / 6) * math.pi * 2
			b:add("Tentacle", Vector3.new(0.25, 0.25, 1.1), CFrame.new(math.cos(angle) * 0.6, -0.9, math.sin(angle) * 0.6) * CFrame.Angles(math.rad(70), angle, 0), light, "Oval", nil, "tentacle", i)
		end
	elseif style == "jelly" then
		for i = 0, 4 do
			local angle = (i / 5) * math.pi * 2
			local t = b:add("Tentacle", Vector3.new(0.1, 1.2, 0.1), CFrame.new(math.cos(angle) * 0.5, -1.2, math.sin(angle) * 0.5), light, nil, Enum.Material.Neon, "tentacle", i)
			t.Transparency = 0.2
		end
	elseif style == "alien" or style == "robot" then
		for _, side in ipairs({ -1, 1 }) do
			b:add("Antenna", Vector3.new(0.1, 0.7, 0.1), CFrame.new(side * 0.35, 1.15, 0), Color3.fromRGB(80, 80, 90))
			b:add("AntennaTip", Vector3.new(0.3, 0.3, 0.3), CFrame.new(side * 0.35, 1.55, 0), Color3.fromRGB(120, 255, 120), BALL, Enum.Material.Neon, "ear", side)
		end
	elseif style == "ghost" then
		for i = -1, 1 do
			local tail = b:add("Wisp", Vector3.new(0.6, 0.6, 0.6), CFrame.new(i * 0.5, -0.95, 0), color, BALL, Enum.Material.Neon, "tentacle", i + 1)
			tail.Transparency = 0.35
		end
		b:add("Halo", Vector3.new(0.1, 1.1, 1.1), CFrame.new(0, 1.3, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 230, 100), CYL, Enum.Material.Neon, "spin")
	elseif style == "slime" then
		b:add("Shine", Vector3.new(0.5, 0.3, 0.3), CFrame.new(-0.45, 0.4, -0.6), WHITE, "Oval", Enum.Material.Neon)
	end

	-- Seltenheit: Glanz, Licht, Regenbogen
	local order = rarity.Order
	if order >= 4 then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = UI.rgb(rarity.Color)
		sparkles.Parent = body
	end
	if order >= 2 then
		local pointLight = Instance.new("PointLight")
		pointLight.Color = UI.rgb(rarity.Color)
		pointLight.Range = 4 + order * 1.5
		pointLight.Brightness = 0.6 + order * 0.15
		pointLight.Parent = body
	end
	if order >= 5 then
		b:add("Aura", Vector3.new(0.1, 3, 3), CFrame.new(0, -1.1, 0) * CFrame.Angles(0, 0, math.rad(90)), UI.rgb(rarity.Color), CYL, Enum.Material.Neon, "spin").Transparency = 0.6
	end

	local billboard = UI.Create("BillboardGui", {
		Adornee = body,
		Size = UDim2.new(4, 0, 0.8, 0),
		StudsOffsetWorldSpace = Vector3.new(0, 1.8, 0),
		MaxDistance = 45,
		LightInfluence = 0,
		Parent = body,
	})
	UI.Create("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = UI.Font,
		TextScaled = true,
		TextColor3 = UI.rgb(rarity.Color),
		TextStrokeTransparency = 0,
		Text = cfg.DisplayName,
		Parent = billboard,
	})

	model.Parent = folder
	return {
		Model = model,
		Parts = b.Parts,
		Motion = MOTION[style] or "float",
		Secret = cfg.Rarity == "Secret",
		Phase = math.random() * 6,
		Current = nil,
	}
end

local function clearOwner(owner)
	local entry = owners[owner]
	if entry then
		for _, pet in ipairs(entry.Pets) do
			pet.Model:Destroy()
		end
		owners[owner] = nil
	end
end

local function syncOwner(owner)
	local signature = owner:GetAttribute("EquippedPets") or ""
	if owner ~= Players.LocalPlayer and not ctx.Setting("OtherPets") then
		signature = ""
	end
	local entry = owners[owner]
	if entry and entry.Signature == signature then
		return
	end
	clearOwner(owner)
	entry = { Signature = signature, Pets = {} }
	owners[owner] = entry
	for petId in string.gmatch(signature, "[^,]+") do
		if Config.Pets[petId] then
			table.insert(entry.Pets, buildPet(petId))
		end
	end
end

-- Animation eines Teils
local function partAnimation(role, extra, t, speedFactor)
	if role == "wingL" then
		-- Drehpunkt an der Schulter, Fluegel zeigt nach aussen
		return CFrame.Angles(0, 0, -math.sin(t * 14) * 0.6) * CFrame.new(-extra / 2, 0, 0)
	elseif role == "wingR" then
		return CFrame.Angles(0, 0, math.sin(t * 14) * 0.6) * CFrame.new(extra / 2, 0, 0)
	elseif role == "tail" then
		return CFrame.Angles(0, math.sin(t * (6 + speedFactor * 8)) * 0.5, 0)
	elseif role == "ear" then
		return CFrame.Angles(0, 0, math.sin(t * 3 + extra) * 0.12)
	elseif role == "tentacle" then
		return CFrame.Angles(math.sin(t * 4 + extra) * 0.35, 0, 0)
	elseif role == "spin" then
		return CFrame.Angles(t * 2, 0, 0)
	end
	return nil
end

local function animate(dt)
	local t = os.clock()
	local alpha = math.min(1, dt * 7)
	local rainbow = Color3.fromHSV((t * 0.3) % 1, 0.6, 1)
	for owner, entry in pairs(owners) do
		local character = owner.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and owner.Parent then
			local velocity = root.AssemblyLinearVelocity
			local moving = Vector3.new(velocity.X, 0, velocity.Z).Magnitude > 2
			local speedFactor = moving and 1 or 0
			local count = #entry.Pets
			for i, pet in ipairs(entry.Pets) do
				local spread = (i - (count + 1) / 2) * 3.2
				local row = math.floor((i - 1) / 4)
				local phaseT = t + pet.Phase
				local height, tilt, sway = 0.6, 0, 0
				if pet.Motion == "hop" then
					local hop = math.abs(math.sin(phaseT * (moving and 9 or 3)))
					height = 0.2 + hop * (moving and 1.1 or 0.25)
					tilt = moving and -0.15 or 0
				elseif pet.Motion == "fly" then
					height = 2 + math.sin(phaseT * 3) * 0.45
					tilt = math.sin(phaseT * 2) * 0.08
				elseif pet.Motion == "swim" then
					height = 1.6 + math.sin(phaseT * 2) * 0.3
					sway = math.sin(phaseT * 2.5) * 0.3
				else
					height = 1.2 + math.sin(phaseT * 2) * 0.3
					sway = math.sin(phaseT * 0.8) * 0.15
				end
				local offset = CFrame.new(spread, height, 4.5 + row * 3)
				local target = root.CFrame * offset
				local look = target.Position + root.CFrame.LookVector
				local targetCFrame = CFrame.lookAt(target.Position, look)
				if not pet.Current or (pet.Current.Position - targetCFrame.Position).Magnitude > 60 then
					pet.Current = targetCFrame
				else
					pet.Current = pet.Current:Lerp(targetCFrame, alpha)
				end
				local bodyCFrame = pet.Current * CFrame.Angles(tilt, sway, 0)
				for _, info in ipairs(pet.Parts) do
					local anim = info.Role and partAnimation(info.Role, info.Extra, phaseT, speedFactor)
					if anim then
						info.Part.CFrame = bodyCFrame * info.Offset * anim
					else
						info.Part.CFrame = bodyCFrame * info.Offset
					end
				end
				if pet.Secret and pet.Parts[1] then
					pet.Parts[1].Part.Color = rainbow
				end
			end
		end
	end
end

function PetsFx.Init(context)
	ctx = context
	Config = ctx.Config
	UI = ctx.UI

	folder = Instance.new("Folder")
	folder.Name = "SlapLocalPets"
	folder.Parent = workspace

	Players.PlayerRemoving:Connect(clearOwner)
	RunService.RenderStepped:Connect(animate)
	task.spawn(function()
		while true do
			for _, owner in ipairs(Players:GetPlayers()) do
				syncOwner(owner)
			end
			task.wait(0.5)
		end
	end)
end

return PetsFx
