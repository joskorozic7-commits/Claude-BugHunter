--[[
	PetsFx: baut kleine Pet-Modelle und laesst sie hinter ihren Besitzern
	herschweben. Laeuft nur lokal (fluessig und ohne Server-Last).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PetsFx = {}
local ctx, Config, UI

local folder
local owners = {} -- [Player] = { Signature, Pets = { {Model, Current} } }

local function newPart(model, name, size, color, shape, mat)
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
	if shape then
		p.Shape = shape
	end
	p.Parent = model
	return p
end

-- Pet-Modell bauen. Alles relativ zum Koerper (Vorderseite = -Z).
local function buildPet(petId)
	local cfg = Config.Pets[petId]
	local rarity = Config.Rarities[cfg.Rarity]
	local color = UI.rgb(cfg.Color)
	local style = cfg.Style
	local model = Instance.new("Model")
	model.Name = "Pet_" .. petId

	local bodySize = 1.9
	local body
	if style == "robot" then
		body = newPart(model, "Body", Vector3.new(1.8, 1.6, 1.8), color, nil, Enum.Material.DiamondPlate)
	elseif style == "whale" then
		body = newPart(model, "Body", Vector3.new(1.8, 1.6, 2.8), color, nil)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = body
	elseif style == "slime" then
		body = newPart(model, "Body", Vector3.new(2, 1.4, 2), color, nil, Enum.Material.Glass)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = body
		body.Transparency = 0.15
	else
		body = newPart(model, "Body", Vector3.new(bodySize, bodySize, bodySize), color, Enum.PartType.Ball)
	end
	if style == "ghost" then
		body.Transparency = 0.25
		body.Material = Enum.Material.Neon
	end
	model.PrimaryPart = body
	local base = body.CFrame

	local white = Color3.fromRGB(255, 255, 255)
	local black = Color3.fromRGB(20, 15, 25)
	local front = -body.Size.Z / 2

	-- Augen
	for _, side in ipairs({ -1, 1 }) do
		newPart(model, "Eye", Vector3.new(0.45, 0.45, 0.45), white, Enum.PartType.Ball).CFrame = base * CFrame.new(side * 0.38, 0.25, front + 0.12)
		newPart(model, "Pupil", Vector3.new(0.24, 0.24, 0.24), black, Enum.PartType.Ball).CFrame = base * CFrame.new(side * 0.38, 0.25, front - 0.04)
	end
	newPart(model, "Mouth", Vector3.new(0.35, 0.08, 0.08), black).CFrame = base * CFrame.new(0, -0.15, front + 0.02)

	local accent = UI.Lighten(color, 0.15)
	if style == "cat" or style == "dog" or style == "bear" or style == "bunny" then
		for _, side in ipairs({ -1, 1 }) do
			local ear
			if style == "bunny" then
				ear = newPart(model, "Ear", Vector3.new(0.3, 1.2, 0.2), accent)
				ear.CFrame = base * CFrame.new(side * 0.35, 1.3, 0) * CFrame.Angles(0, 0, side * -0.15)
			elseif style == "cat" then
				ear = newPart(model, "Ear", Vector3.new(0.45, 0.6, 0.2), accent)
				ear.CFrame = base * CFrame.new(side * 0.5, 0.9, 0) * CFrame.Angles(0, 0, side * -0.4)
			elseif style == "dog" then
				ear = newPart(model, "Ear", Vector3.new(0.35, 0.8, 0.2), UI.Lighten(color, -0.15))
				ear.CFrame = base * CFrame.new(side * 0.85, 0.25, 0) * CFrame.Angles(0, 0, side * 0.3)
			else
				ear = newPart(model, "Ear", Vector3.new(0.5, 0.5, 0.5), accent, Enum.PartType.Ball)
				ear.CFrame = base * CFrame.new(side * 0.65, 0.75, 0)
			end
		end
		if style == "dog" or style == "bear" then
			newPart(model, "Nose", Vector3.new(0.25, 0.2, 0.2), black, Enum.PartType.Ball).CFrame = base * CFrame.new(0, 0.02, front - 0.05)
		end
	elseif style == "dragon" or style == "bird" then
		for _, side in ipairs({ -1, 1 }) do
			local wing = newPart(model, "Wing", Vector3.new(1.4, 0.15, 0.9), accent, nil, Enum.Material.Neon)
			wing.CFrame = base * CFrame.new(side * 1.2, 0.3, 0.3) * CFrame.Angles(0, 0, side * 0.4)
			wing.Transparency = 0.2
		end
		if style == "dragon" then
			for _, side in ipairs({ -1, 1 }) do
				newPart(model, "Horn", Vector3.new(0.2, 0.6, 0.2), Color3.fromRGB(255, 240, 200)).CFrame = base * CFrame.new(side * 0.4, 1, 0.1) * CFrame.Angles(-0.3, 0, side * -0.2)
			end
		else
			newPart(model, "Beak", Vector3.new(0.3, 0.2, 0.4), Color3.fromRGB(255, 180, 40)).CFrame = base * CFrame.new(0, 0, front - 0.15)
		end
	elseif style == "unicorn" then
		newPart(model, "Horn", Vector3.new(0.22, 0.9, 0.22), Color3.fromRGB(255, 230, 120), nil, Enum.Material.Neon).CFrame = base * CFrame.new(0, 1.15, -0.35) * CFrame.Angles(-0.4, 0, 0)
		newPart(model, "Mane", Vector3.new(0.3, 0.9, 1.2), Color3.fromRGB(170, 120, 255)).CFrame = base * CFrame.new(0, 0.8, 0.4)
	elseif style == "alien" or style == "robot" then
		for _, side in ipairs({ -1, 1 }) do
			newPart(model, "Antenna", Vector3.new(0.1, 0.7, 0.1), Color3.fromRGB(80, 80, 90)).CFrame = base * CFrame.new(side * 0.35, 1.15, 0)
			newPart(model, "AntennaTip", Vector3.new(0.3, 0.3, 0.3), Color3.fromRGB(120, 255, 120), Enum.PartType.Ball, Enum.Material.Neon).CFrame = base * CFrame.new(side * 0.35, 1.55, 0)
		end
	elseif style == "whale" then
		newPart(model, "Tail", Vector3.new(1.4, 0.15, 0.6), accent).CFrame = base * CFrame.new(0, 0.3, 1.6)
		local spout = newPart(model, "Spout", Vector3.new(0.25, 0.25, 0.25), Color3.fromRGB(150, 220, 255), Enum.PartType.Ball, Enum.Material.Neon)
		spout.CFrame = base * CFrame.new(0, 1.05, 0.2)
	elseif style == "ghost" then
		local crown = newPart(model, "Halo", Vector3.new(0.1, 1.1, 1.1), Color3.fromRGB(255, 230, 100), Enum.PartType.Cylinder, Enum.Material.Neon)
		crown.CFrame = base * CFrame.new(0, 1.3, 0) * CFrame.Angles(0, 0, math.rad(90))
	end

	-- Glanz fuer seltene Pets
	if cfg.Rarity == "Legendary" or cfg.Rarity == "Mythic" then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = UI.rgb(rarity.Color)
		sparkles.Parent = body
	end
	if cfg.Rarity ~= "Common" then
		local light = Instance.new("PointLight")
		light.Color = UI.rgb(rarity.Color)
		light.Range = 6
		light.Brightness = 0.8
		light.Parent = body
	end

	local billboard = UI.Create("BillboardGui", {
		Adornee = body,
		Size = UDim2.new(4, 0, 0.8, 0),
		StudsOffsetWorldSpace = Vector3.new(0, 1.7, 0),
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
	return model
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
			table.insert(entry.Pets, { Model = buildPet(petId), Current = nil, Phase = math.random() * 6 })
		end
	end
end

local function animate(dt)
	local t = os.clock()
	local alpha = math.min(1, dt * 7)
	for owner, entry in pairs(owners) do
		local character = owner.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and owner.Parent then
			local count = #entry.Pets
			for i, pet in ipairs(entry.Pets) do
				local spread = (i - (count + 1) / 2) * 3.2
				local row = math.floor((i - 1) / 4)
				local offset = CFrame.new(spread, 0.6 + math.sin(t * 3 + pet.Phase) * 0.35, 4.5 + row * 3)
				local target = root.CFrame * offset
				local look = target.Position + root.CFrame.LookVector
				local targetCFrame = CFrame.lookAt(target.Position, look)
				if not pet.Current or (pet.Current.Position - targetCFrame.Position).Magnitude > 60 then
					pet.Current = targetCFrame
				else
					pet.Current = pet.Current:Lerp(targetCFrame, alpha)
				end
				if pet.Model.PrimaryPart then
					pet.Model:PivotTo(pet.Current)
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
