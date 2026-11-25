--[[
	World: baut die komplette Karte per Skript.
	  * Hub mit Spawn, Brunnen, Schildern, Bestenlisten und PvP-Arena
	  * 6 Themen-Zonen mit Deko, Eingangsbogen, Tor, Ei-Stand und Gyatt-Plaetzen
	  * Licht & Atmosphaere
]]

local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SlapShared")
local Config = require(Shared:WaitForChild("Config"))
local Calc = require(Shared:WaitForChild("Calc"))

local World = {}
World.FloorTop = 1
World.Zones = {}

local FLOOR = World.FloorTop
local HALF_WIDTH = Config.ZoneWidth / 2

--------------------------------------------------------------------------
-- Bau-Helfer
--------------------------------------------------------------------------
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

local function part(props)
	local p = Instance.new(props.ClassName or "Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for key, value in pairs(props) do
		if key ~= "ClassName" and key ~= "Parent" then
			p[key] = value
		end
	end
	p.Parent = props.Parent
	return p
end

-- Ball
local function ball(parent, position, diameter, color, mat)
	return part({
		Name = "Ball",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(diameter, diameter, diameter),
		CFrame = CFrame.new(position),
		Color = color,
		Material = mat or Enum.Material.SmoothPlastic,
		Parent = parent,
	})
end

-- Aufrechter Zylinder (Roblox-Zylinder liegen standardmaessig auf der X-Achse)
local function pillar(parent, bottomPosition, height, diameter, color, mat)
	return part({
		Name = "Pillar",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, diameter, diameter),
		CFrame = CFrame.new(bottomPosition + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = color,
		Material = mat or Enum.Material.SmoothPlastic,
		Parent = parent,
	})
end

-- Flache Scheibe (liegender Zylinder)
local function disc(parent, centerPosition, thickness, diameter, color, mat)
	return part({
		Name = "Disc",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(thickness, diameter, diameter),
		CFrame = CFrame.new(centerPosition) * CFrame.Angles(0, 0, math.rad(90)),
		Color = color,
		Material = mat or Enum.Material.SmoothPlastic,
		Parent = parent,
	})
end

local function addLight(target, color, range, brightness)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range or 12
	light.Brightness = brightness or 1.5
	light.Parent = target
	return light
end

-- Schild mit Text. face = Seite, auf der der Text steht.
local function sign(parent, cframe, size, text, textColor, backColor, face)
	local board = part({
		Name = "Sign",
		Size = size,
		CFrame = cframe,
		Color = backColor or Color3.fromRGB(45, 25, 55),
		Parent = parent,
	})
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextWrapped = true
	label.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.4
	label.Text = text
	label.Parent = gui
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.04, 0)
	padding.PaddingRight = UDim.new(0.04, 0)
	padding.PaddingTop = UDim.new(0.06, 0)
	padding.PaddingBottom = UDim.new(0.06, 0)
	padding.Parent = label
	return board, label
end

local function folder(name, parent)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

--------------------------------------------------------------------------
-- Deko pro Thema
--------------------------------------------------------------------------
local decor = {}

function decor.tree(parent, pos, rng)
	local height = rng:NextNumber(7, 12)
	pillar(parent, pos, height, rng:NextNumber(1.4, 2.2), Color3.fromRGB(110, 70, 40), Enum.Material.Wood)
	local leafColor = Color3.fromRGB(rng:NextInteger(50, 90), rng:NextInteger(150, 200), rng:NextInteger(60, 90))
	local top = pos + Vector3.new(0, height, 0)
	ball(parent, top, rng:NextNumber(6, 8), leafColor, Enum.Material.Grass)
	ball(parent, top + Vector3.new(1.8, -1.2, 0.5), rng:NextNumber(4, 5), leafColor, Enum.Material.Grass)
	ball(parent, top + Vector3.new(-1.6, -1, -0.8), rng:NextNumber(4, 5), leafColor, Enum.Material.Grass)
end

function decor.flower(parent, pos, rng)
	local colors = { { 255, 90, 140 }, { 255, 220, 60 }, { 160, 120, 255 }, { 255, 255, 255 }, { 255, 140, 60 } }
	local c = colors[rng:NextInteger(1, #colors)]
	pillar(parent, pos, 1.6, 0.25, Color3.fromRGB(60, 160, 60))
	ball(parent, pos + Vector3.new(0, 1.8, 0), 0.9, rgb(c))
	ball(parent, pos + Vector3.new(0, 1.8, 0), 0.45, Color3.fromRGB(255, 230, 90))
end

function decor.bush(parent, pos, rng)
	local color = Color3.fromRGB(60, rng:NextInteger(140, 180), 70)
	ball(parent, pos + Vector3.new(0, 1.2, 0), 3, color, Enum.Material.Grass)
	ball(parent, pos + Vector3.new(1.3, 0.9, 0.4), 2.2, color, Enum.Material.Grass)
	ball(parent, pos + Vector3.new(-1.2, 0.9, -0.3), 2.2, color, Enum.Material.Grass)
end

function decor.rock(parent, pos, rng, color, mat)
	local s = rng:NextNumber(1.5, 4)
	part({
		Name = "Rock",
		Size = Vector3.new(s * rng:NextNumber(1, 1.6), s * rng:NextNumber(0.6, 1), s),
		CFrame = CFrame.new(pos + Vector3.new(0, s * 0.3, 0)) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 6.28), rng:NextNumber(-0.3, 0.3)),
		Color = color or Color3.fromRGB(130, 130, 135),
		Material = mat or Enum.Material.Slate,
		Parent = parent,
	})
end

function decor.cactus(parent, pos, rng)
	local green = Color3.fromRGB(70, 160, 70)
	local h = rng:NextNumber(5, 9)
	pillar(parent, pos, h, 1.6, green, Enum.Material.Grass)
	ball(parent, pos + Vector3.new(0, h, 0), 1.6, green, Enum.Material.Grass)
	local armH = h * 0.5
	part({ Name = "Arm", Size = Vector3.new(1.6, 1.1, 1.1), CFrame = CFrame.new(pos + Vector3.new(1.3, armH, 0)), Color = green, Material = Enum.Material.Grass, Parent = parent })
	pillar(parent, pos + Vector3.new(2, armH - 0.5, 0), 2.6, 1.1, green, Enum.Material.Grass)
	part({ Name = "Arm", Size = Vector3.new(1.6, 1.1, 1.1), CFrame = CFrame.new(pos + Vector3.new(-1.3, armH + 1, 0)), Color = green, Material = Enum.Material.Grass, Parent = parent })
	pillar(parent, pos + Vector3.new(-2, armH + 0.5, 0), 2, 1.1, green, Enum.Material.Grass)
	ball(parent, pos + Vector3.new(0.3, h + 0.6, 0.3), 0.7, Color3.fromRGB(255, 100, 160))
end

function decor.pyramid(parent, pos, rng)
	local base = rng:NextNumber(14, 22)
	local steps = 6
	for i = 0, steps - 1 do
		local s = base * (1 - i / steps)
		part({
			Name = "PyramidStep",
			Size = Vector3.new(s, base / steps * 0.8, s),
			CFrame = CFrame.new(pos + Vector3.new(0, (i + 0.5) * base / steps * 0.8, 0)),
			Color = Color3.fromRGB(225, 190, 120),
			Material = Enum.Material.Sandstone,
			Parent = parent,
		})
	end
end

function decor.palm(parent, pos, rng)
	local h = rng:NextNumber(9, 13)
	pillar(parent, pos, h, 1.3, Color3.fromRGB(150, 110, 60), Enum.Material.Wood)
	for i = 1, 5 do
		local angle = (i / 5) * math.pi * 2
		part({
			Name = "Leaf",
			Size = Vector3.new(7, 0.3, 1.8),
			CFrame = CFrame.new(pos + Vector3.new(0, h, 0)) * CFrame.Angles(0, angle, math.rad(-20)) * CFrame.new(3.2, 0, 0),
			Color = Color3.fromRGB(70, 170, 70),
			Material = Enum.Material.Grass,
			Parent = parent,
		})
	end
	ball(parent, pos + Vector3.new(0.6, h - 0.5, 0), 1, Color3.fromRGB(120, 80, 40))
end

function decor.iceSpike(parent, pos, rng)
	local h = rng:NextNumber(5, 12)
	part({
		Name = "IceSpike",
		Size = Vector3.new(h * 0.25, h, h * 0.25),
		CFrame = CFrame.new(pos + Vector3.new(0, h / 2 - 0.5, 0)) * CFrame.Angles(rng:NextNumber(-0.25, 0.25), rng:NextNumber(0, 6.28), rng:NextNumber(-0.25, 0.25)),
		Color = Color3.fromRGB(170, 220, 255),
		Material = Enum.Material.Ice,
		Transparency = 0.15,
		Parent = parent,
	})
end

function decor.snowman(parent, pos, rng)
	local white = Color3.fromRGB(250, 250, 255)
	ball(parent, pos + Vector3.new(0, 1.8, 0), 4, white, Enum.Material.Snow)
	ball(parent, pos + Vector3.new(0, 4.6, 0), 3, white, Enum.Material.Snow)
	ball(parent, pos + Vector3.new(0, 6.7, 0), 2.1, white, Enum.Material.Snow)
	ball(parent, pos + Vector3.new(-0.4, 7, -0.95), 0.35, Color3.fromRGB(20, 20, 20))
	ball(parent, pos + Vector3.new(0.4, 7, -0.95), 0.35, Color3.fromRGB(20, 20, 20))
	part({ Name = "Carrot", Size = Vector3.new(0.3, 0.3, 1.2), CFrame = CFrame.new(pos + Vector3.new(0, 6.7, -1.4)), Color = Color3.fromRGB(255, 140, 30), Parent = parent })
	part({ Name = "Hat", Size = Vector3.new(1.6, 1.4, 1.6), CFrame = CFrame.new(pos + Vector3.new(0, 8.3, 0)), Color = Color3.fromRGB(30, 30, 35), Parent = parent })
	part({ Name = "HatRim", Size = Vector3.new(2.4, 0.2, 2.4), CFrame = CFrame.new(pos + Vector3.new(0, 7.6, 0)), Color = Color3.fromRGB(30, 30, 35), Parent = parent })
end

function decor.pine(parent, pos, rng)
	pillar(parent, pos, 3, 1.2, Color3.fromRGB(100, 70, 40), Enum.Material.Wood)
	local green = Color3.fromRGB(40, 110, 70)
	for i = 0, 3 do
		local s = 7 - i * 1.6
		part({
			Name = "PineLayer",
			Size = Vector3.new(s, 2, s),
			CFrame = CFrame.new(pos + Vector3.new(0, 3.5 + i * 2, 0)) * CFrame.Angles(0, math.rad(45 * i), 0),
			Color = green,
			Material = Enum.Material.Grass,
			Parent = parent,
		})
		part({
			Name = "Snow",
			Size = Vector3.new(s * 0.8, 0.3, s * 0.8),
			CFrame = CFrame.new(pos + Vector3.new(0, 4.6 + i * 2, 0)) * CFrame.Angles(0, math.rad(45 * i), 0),
			Color = Color3.fromRGB(250, 250, 255),
			Material = Enum.Material.Snow,
			Parent = parent,
		})
	end
end

function decor.lavaPool(parent, pos, rng)
	local d = rng:NextNumber(6, 12)
	local pool = disc(parent, pos + Vector3.new(0, 0.12, 0), 0.25, d, Color3.fromRGB(255, 100, 20), Enum.Material.Neon)
	pool.CanCollide = false
	disc(parent, pos + Vector3.new(0, 0.05, 0), 0.2, d + 1.5, Color3.fromRGB(40, 30, 30), Enum.Material.Basalt)
	addLight(pool, Color3.fromRGB(255, 120, 40), d + 6, 2)
end

function decor.volcano(parent, pos, rng)
	local rock = Color3.fromRGB(60, 40, 38)
	for i = 0, 4 do
		local d = 34 - i * 6
		pillar(parent, pos + Vector3.new(0, i * 5, 0), 5, d, rock, Enum.Material.Basalt)
	end
	local top = disc(parent, pos + Vector3.new(0, 25.2, 0), 0.4, 8, Color3.fromRGB(255, 90, 10), Enum.Material.Neon)
	local fire = Instance.new("Fire")
	fire.Size = 25
	fire.Heat = 20
	fire.Parent = top
	local smoke = Instance.new("Smoke")
	smoke.Size = 20
	smoke.RiseVelocity = 8
	smoke.Opacity = 0.15
	smoke.Color = Color3.fromRGB(70, 60, 60)
	smoke.Parent = top
	addLight(top, Color3.fromRGB(255, 100, 30), 40, 3)
end

function decor.cloud(parent, pos, rng)
	local white = Color3.fromRGB(255, 255, 255)
	local lift = rng:NextNumber(0, 6)
	for i = 1, rng:NextInteger(3, 5) do
		local p = ball(parent, pos + Vector3.new(rng:NextNumber(-4, 4), 2 + lift + rng:NextNumber(0, 2), rng:NextNumber(-3, 3)), rng:NextNumber(3.5, 6), white, Enum.Material.SmoothPlastic)
		p.CanCollide = false
	end
end

function decor.goldPillar(parent, pos, rng)
	local h = rng:NextNumber(8, 14)
	pillar(parent, pos, 1, 4, Color3.fromRGB(255, 215, 120), Enum.Material.Foil)
	pillar(parent, pos + Vector3.new(0, 1, 0), h, 2.4, Color3.fromRGB(250, 245, 235), Enum.Material.Marble)
	pillar(parent, pos + Vector3.new(0, h + 1, 0), 1, 4, Color3.fromRGB(255, 215, 120), Enum.Material.Foil)
end

function decor.rainbow(parent, pos)
	local colors = { { 255, 60, 60 }, { 255, 150, 40 }, { 255, 230, 60 }, { 80, 220, 90 }, { 70, 160, 255 }, { 160, 90, 255 } }
	for band, c in ipairs(colors) do
		local radius = 26 - band * 1.6
		for step = 0, 12 do
			local angle = math.pi * step / 12
			local p = part({
				Name = "Rainbow",
				Size = Vector3.new(1.6, 1.6, 7.5),
				CFrame = CFrame.new(pos + Vector3.new(math.cos(angle) * radius, math.sin(angle) * radius, 0)) * CFrame.Angles(0, 0, angle) * CFrame.Angles(0, math.rad(90), 0),
				Color = rgb(c),
				Material = Enum.Material.Neon,
				CanCollide = false,
				Parent = parent,
			})
			p.CastShadow = false
		end
	end
end

function decor.star(parent, pos, rng)
	local colors = { { 255, 255, 200 }, { 200, 220, 255 }, { 255, 200, 255 } }
	local p = ball(parent, pos + Vector3.new(0, rng:NextNumber(8, 30), 0), rng:NextNumber(0.6, 1.6), rgb(colors[rng:NextInteger(1, #colors)]), Enum.Material.Neon)
	p.CanCollide = false
	p.CastShadow = false
end

function decor.planet(parent, pos, rng)
	local colors = { { 255, 140, 90 }, { 120, 200, 255 }, { 200, 120, 255 }, { 120, 255, 180 } }
	local d = rng:NextNumber(10, 18)
	local center = pos + Vector3.new(0, rng:NextNumber(25, 40), 0)
	local p = ball(parent, center, d, rgb(colors[rng:NextInteger(1, #colors)]), Enum.Material.SmoothPlastic)
	p.CanCollide = false
	local ring = part({
		Name = "PlanetRing",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, d * 1.7, d * 1.7),
		CFrame = CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(math.rad(20), 0, 0),
		Color = Color3.fromRGB(240, 220, 255),
		Material = Enum.Material.Neon,
		Transparency = 0.5,
		CanCollide = false,
		Parent = parent,
	})
	ring.CastShadow = false
end

function decor.crystal(parent, pos, rng)
	local colors = { { 180, 90, 255 }, { 90, 220, 255 }, { 255, 90, 200 } }
	local c = rgb(colors[rng:NextInteger(1, #colors)])
	for i = 1, 3 do
		local h = rng:NextNumber(3, 8)
		local p = part({
			Name = "Crystal",
			Size = Vector3.new(h * 0.3, h, h * 0.3),
			CFrame = CFrame.new(pos + Vector3.new(rng:NextNumber(-1.5, 1.5), h / 2 - 0.3, rng:NextNumber(-1.5, 1.5))) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 6.28), rng:NextNumber(-0.4, 0.4)),
			Color = c,
			Material = Enum.Material.Neon,
			Transparency = 0.2,
			Parent = parent,
		})
		if i == 1 then
			addLight(p, c, 10, 1)
		end
	end
end

-- ===== Candy =====
local CANDY_COLORS = { { 255, 90, 160 }, { 120, 220, 255 }, { 255, 230, 90 }, { 160, 255, 140 }, { 200, 130, 255 } }

function decor.lollipop(parent, pos, rng)
	local h = rng:NextNumber(6, 11)
	pillar(parent, pos, h, 0.6, Color3.fromRGB(255, 255, 255))
	local c = CANDY_COLORS[rng:NextInteger(1, #CANDY_COLORS)]
	local candy = part({
		Name = "Lollipop",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.8, 5, 5),
		CFrame = CFrame.new(pos + Vector3.new(0, h + 2, 0)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0),
		Color = rgb(c),
		Material = Enum.Material.Glass,
		Parent = parent,
	})
	part({
		Name = "Swirl",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.9, 2.4, 2.4),
		CFrame = candy.CFrame,
		Color = Color3.fromRGB(255, 255, 255),
		Parent = parent,
	})
end

function decor.candyCane(parent, pos, rng)
	local h = rng:NextNumber(7, 12)
	local segments = math.floor(h / 1.2)
	for i = 0, segments - 1 do
		pillar(parent, pos + Vector3.new(0, i * 1.2, 0), 1.2, 1.2, (i % 2 == 0) and Color3.fromRGB(230, 30, 50) or Color3.fromRGB(255, 255, 255))
	end
	local top = pos + Vector3.new(0, segments * 1.2, 0)
	for i = 1, 4 do
		local angle = (i / 4) * math.pi
		ball(parent, top + Vector3.new(math.sin(angle) * 1.5 - 0, math.cos(angle) * 1.2, 0) + Vector3.new(1.5 - math.cos(angle) * 1.5 - 1.5, 0, 0), 1.3,
			(i % 2 == 0) and Color3.fromRGB(230, 30, 50) or Color3.fromRGB(255, 255, 255))
	end
end

function decor.gumdrop(parent, pos, rng)
	local c = CANDY_COLORS[rng:NextInteger(1, #CANDY_COLORS)]
	local d = rng:NextNumber(2.5, 4.5)
	local drop = ball(parent, pos + Vector3.new(0, d * 0.2, 0), d, rgb(c), Enum.Material.Glass)
	drop.Transparency = 0.15
end

function decor.cupcake(parent, pos, rng)
	local c = CANDY_COLORS[rng:NextInteger(1, #CANDY_COLORS)]
	pillar(parent, pos, 2.5, 4, Color3.fromRGB(200, 140, 90))
	ball(parent, pos + Vector3.new(0, 3.3, 0), 4.4, rgb(c))
	ball(parent, pos + Vector3.new(0, 5.4, 0), 1.2, Color3.fromRGB(220, 20, 40))
end

-- ===== Cyber =====
function decor.neonPillar(parent, pos, rng)
	local h = rng:NextNumber(8, 18)
	part({ Name = "CyberPillar", Size = Vector3.new(2.5, h, 2.5), CFrame = CFrame.new(pos + Vector3.new(0, h / 2, 0)), Color = Color3.fromRGB(25, 30, 50), Parent = parent })
	local stripe = part({ Name = "CyberStripe", Size = Vector3.new(2.7, h * 0.9, 0.4), CFrame = CFrame.new(pos + Vector3.new(0, h / 2, -1.2)),
		Color = Color3.fromRGB(0, 255, 230), Material = Enum.Material.Neon, Parent = parent })
	addLight(stripe, Color3.fromRGB(0, 255, 230), 10, 1)
end

function decor.holoCube(parent, pos, rng)
	local s = rng:NextNumber(1.5, 3.5)
	local cube = part({
		Name = "HoloCube",
		Size = Vector3.new(s, s, s),
		CFrame = CFrame.new(pos + Vector3.new(0, rng:NextNumber(3, 9), 0)) * CFrame.Angles(rng:NextNumber(0, 3), rng:NextNumber(0, 3), rng:NextNumber(0, 3)),
		Color = (rng:NextNumber() < 0.5) and Color3.fromRGB(255, 0, 200) or Color3.fromRGB(0, 200, 255),
		Material = Enum.Material.Neon,
		Transparency = 0.35,
		CanCollide = false,
		Parent = parent,
	})
	cube.CastShadow = false
end

function decor.serverTower(parent, pos, rng)
	local h = rng:NextNumber(6, 10)
	part({ Name = "Server", Size = Vector3.new(4, h, 3), CFrame = CFrame.new(pos + Vector3.new(0, h / 2, 0)), Color = Color3.fromRGB(35, 40, 55), Material = Enum.Material.Metal, Parent = parent })
	for y = 1, math.floor(h) - 1 do
		local light = part({ Name = "ServerLight", Size = Vector3.new(0.4, 0.3, 0.2), CFrame = CFrame.new(pos + Vector3.new(rng:NextNumber(-1.4, 1.4), y, -1.55)),
			Color = (rng:NextNumber() < 0.7) and Color3.fromRGB(60, 255, 120) or Color3.fromRGB(255, 60, 60), Material = Enum.Material.Neon, Parent = parent })
		light.CastShadow = false
	end
end

function decor.gridLine(parent, pos, rng)
	local line = part({ Name = "GridLine", Size = Vector3.new(0.3, 0.1, rng:NextNumber(15, 40)), CFrame = CFrame.new(pos + Vector3.new(0, 0.05, 0)),
		Color = Color3.fromRGB(0, 255, 230), Material = Enum.Material.Neon, CanCollide = false, Parent = parent })
	line.CastShadow = false
end

-- ===== Shadow =====
function decor.deadTree(parent, pos, rng)
	local h = rng:NextNumber(7, 12)
	local dark = Color3.fromRGB(35, 25, 40)
	pillar(parent, pos, h, 1.2, dark, Enum.Material.Wood)
	for i = 1, 4 do
		local y = h * (0.45 + i * 0.12)
		local angle = rng:NextNumber(0, 6.28)
		part({ Name = "Branch", Size = Vector3.new(0.5, 0.5, rng:NextNumber(3, 5)),
			CFrame = CFrame.new(pos + Vector3.new(0, y, 0)) * CFrame.Angles(0, angle, 0) * CFrame.Angles(math.rad(-30), 0, 0) * CFrame.new(0, 0, -2),
			Color = dark, Material = Enum.Material.Wood, Parent = parent })
	end
end

function decor.purpleLamp(parent, pos, rng)
	pillar(parent, pos, 7, 0.6, Color3.fromRGB(30, 20, 40), Enum.Material.Metal)
	local orb = ball(parent, pos + Vector3.new(0, 7.6, 0), 1.6, Color3.fromRGB(170, 60, 255), Enum.Material.Neon)
	addLight(orb, Color3.fromRGB(170, 60, 255), 18, 2)
end

-- ===== Void =====
function decor.floatingShard(parent, pos, rng)
	local h = rng:NextNumber(2, 7)
	local shard = part({
		Name = "VoidShard",
		Size = Vector3.new(h * 0.35, h, h * 0.35),
		CFrame = CFrame.new(pos + Vector3.new(0, rng:NextNumber(3, 16), 0)) * CFrame.Angles(rng:NextNumber(-0.6, 0.6), rng:NextNumber(0, 6), rng:NextNumber(-0.6, 0.6)),
		Color = Color3.fromRGB(15, 10, 25),
		Material = Enum.Material.Glass,
		CanCollide = false,
		Parent = parent,
	})
	shard.CastShadow = false
	local edge = part({ Name = "ShardGlow", Size = Vector3.new(h * 0.12, h * 1.02, h * 0.12), CFrame = shard.CFrame,
		Color = Color3.fromRGB(200, 150, 255), Material = Enum.Material.Neon, CanCollide = false, Parent = parent })
	edge.CastShadow = false
end

function decor.voidRing(parent, pos, rng)
	local r = rng:NextNumber(4, 7)
	local center = pos + Vector3.new(0, r + 2, 0)
	local yaw = rng:NextNumber(0, 3)
	for i = 0, 15 do
		local angle = (i / 16) * math.pi * 2
		local p = ball(parent, center + CFrame.Angles(0, yaw, 0):VectorToWorldSpace(Vector3.new(math.cos(angle) * r, math.sin(angle) * r, 0)), 0.9,
			Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
		p.CanCollide = false
		p.CastShadow = false
	end
end

function decor.blackHole(parent, pos, rng)
	local center = pos + Vector3.new(0, 30, 0)
	local hole = ball(parent, center, 14, Color3.fromRGB(0, 0, 0), Enum.Material.SmoothPlastic)
	hole.CanCollide = false
	hole.CastShadow = false
	local ring = part({ Name = "AccretionDisk", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 30, 30),
		CFrame = CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(math.rad(15), 0, 0),
		Color = Color3.fromRGB(190, 110, 255), Material = Enum.Material.Neon, Transparency = 0.4, CanCollide = false, Parent = parent })
	ring.CastShadow = false
	addLight(ring, Color3.fromRGB(190, 110, 255), 60, 2)
end

-- Welche Deko-Objekte pro Thema, mit Anzahl
local THEMES = {
	meadow = { { "tree", 22 }, { "flower", 60 }, { "bush", 18 }, { "rock", 10 } },
	desert = { { "cactus", 22 }, { "palm", 8 }, { "rock", 16, { 200, 160, 110 }, "Sandstone" }, { "pyramid", 2, nil, nil, true } },
	ice = { { "iceSpike", 35 }, { "pine", 16 }, { "snowman", 5 }, { "rock", 8, { 200, 220, 240 }, "Glacier" } },
	lava = { { "lavaPool", 14 }, { "rock", 30, { 50, 35, 35 }, "Basalt" }, { "volcano", 2, nil, nil, true } },
	cloud = { { "cloud", 26 }, { "goldPillar", 14 }, { "rainbow", 1, nil, nil, true } },
	space = { { "star", 70 }, { "crystal", 22 }, { "planet", 4, nil, nil, true }, { "rock", 10, { 70, 60, 90 }, "Slate" } },
	candy = { { "lollipop", 18 }, { "candyCane", 16 }, { "gumdrop", 30 }, { "cupcake", 10 } },
	cyber = { { "neonPillar", 16 }, { "holoCube", 20 }, { "serverTower", 10 }, { "gridLine", 12 } },
	shadow = { { "deadTree", 18 }, { "crystal", 14 }, { "purpleLamp", 10 }, { "rock", 16, { 40, 30, 55 }, "Slate" } },
	void = { { "floatingShard", 30 }, { "voidRing", 6 }, { "star", 50 }, { "blackHole", 2, nil, nil, true } },
}

--------------------------------------------------------------------------
-- Haupt-Bau
--------------------------------------------------------------------------
local root

local function buildLighting()
	Lighting.ClockTime = 14.5
	Lighting.Brightness = 2.2
	Lighting.GlobalShadows = true
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 140, 160)
	Lighting.Ambient = Color3.fromRGB(80, 70, 90)
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.EnvironmentSpecularScale = 0.5

	local function ensure(className, name)
		local existing = Lighting:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
		local effect = Instance.new(className)
		effect.Name = name
		effect.Parent = Lighting
		return effect
	end

	local atmosphere = ensure("Atmosphere", "SlapAtmosphere")
	atmosphere.Density = 0.28
	atmosphere.Offset = 0.1
	atmosphere.Color = Color3.fromRGB(255, 220, 235)
	atmosphere.Decay = Color3.fromRGB(150, 110, 160)
	atmosphere.Glare = 0.3
	atmosphere.Haze = 1.2

	local bloom = ensure("BloomEffect", "SlapBloom")
	bloom.Intensity = 0.7
	bloom.Size = 26
	bloom.Threshold = 1.4

	local color = ensure("ColorCorrectionEffect", "SlapColor")
	color.Saturation = 0.18
	color.Contrast = 0.06
	color.Brightness = 0.02

	local rays = ensure("SunRaysEffect", "SlapSunRays")
	rays.Intensity = 0.06
	rays.Spread = 0.8
end

local function buildHub()
	local hub = folder("Hub", root)
	local length = Config.HubLength

	part({
		Name = "HubFloor",
		Size = Vector3.new(Config.ZoneWidth, 2, length),
		CFrame = CFrame.new(0, FLOOR - 1, -length / 2),
		Color = Color3.fromRGB(240, 200, 220),
		Material = Enum.Material.Pebble,
		Parent = hub,
	})
	-- Muster-Fliesen
	for x = -2, 2 do
		for z = 1, 3 do
			if (x + z) % 2 == 0 then
				part({
					Name = "Tile",
					Size = Vector3.new(10, 0.1, 10),
					CFrame = CFrame.new(x * 10, FLOOR + 0.05, -z * 10 - 20),
					Color = Color3.fromRGB(255, 160, 200),
					Material = Enum.Material.Marble,
					CanCollide = false,
					Parent = hub,
				})
			end
		end
	end

	local spawnPos = Config.SpawnPosition
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SlapSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.CFrame = CFrame.new(spawnPos[1], FLOOR + 0.5, spawnPos[2]) * CFrame.Angles(0, math.pi, 0)
	spawn.Color = Color3.fromRGB(255, 110, 180)
	spawn.Material = Enum.Material.Neon
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = hub
	World.Spawn = spawn

	-- Brunnen
	local fx, fz = 10, -22
	pillar(hub, Vector3.new(fx, FLOOR, fz), 1.5, 16, Color3.fromRGB(230, 230, 240), Enum.Material.Marble)
	local water = disc(hub, Vector3.new(fx, FLOOR + 1.45, fz), 0.2, 14, Color3.fromRGB(110, 200, 255), Enum.Material.Glass)
	water.Transparency = 0.25
	water.CanCollide = false
	pillar(hub, Vector3.new(fx, FLOOR, fz), 5, 2, Color3.fromRGB(230, 230, 240), Enum.Material.Marble)
	-- Mini-Blob-Statue mit Gesicht
	local statue = ball(hub, Vector3.new(fx, FLOOR + 7.5, fz), 5, Color3.fromRGB(255, 170, 205), Enum.Material.Marble)
	local face = Instance.new("Decal")
	face.Texture = "rbxasset://textures/face.png"
	face.Face = Enum.NormalId.Front
	face.Parent = statue
	local sparkle = Instance.new("Sparkles")
	sparkle.SparkleColor = Color3.fromRGB(255, 200, 230)
	sparkle.Parent = statue

	-- Laternen
	for _, pos in ipairs({ { -20, -8 }, { 20, -8 }, { -20, -60 }, { 30, -60 }, { 50, -8 }, { -50, -8 } }) do
		local base = Vector3.new(pos[1], FLOOR, pos[2])
		pillar(hub, base, 9, 0.6, Color3.fromRGB(50, 40, 60), Enum.Material.Metal)
		local lamp = ball(hub, base + Vector3.new(0, 9.5, 0), 1.6, Color3.fromRGB(255, 230, 180), Enum.Material.Neon)
		addLight(lamp, Color3.fromRGB(255, 220, 170), 22, 1.6)
	end

	-- Schilder
	sign(hub, CFrame.new(-8, FLOOR + 8, -12) * CFrame.Angles(0, math.rad(-20), 0), Vector3.new(16, 7, 0.8),
		"👋 SLAP THE BLOB 👋\nClick the Blobs with your hand!", Color3.fromRGB(255, 170, 220), nil, Enum.NormalId.Front)
	pillar(hub, Vector3.new(-8, FLOOR, -12), 4.5, 0.8, Color3.fromRGB(90, 60, 40), Enum.Material.Wood)

	sign(hub, CFrame.new(28, FLOOR + 7, -12) * CFrame.Angles(0, math.rad(20), 0), Vector3.new(16, 9, 0.8),
		"📖 HOW TO PLAY\n1. Slap Blobs = Slaps\n2. Upgrade your hand in the Shop\n3. New zones & eggs\n4. Rebirth for a mega bonus!",
		Color3.fromRGB(255, 255, 255), Color3.fromRGB(70, 40, 90), Enum.NormalId.Front)
	pillar(hub, Vector3.new(28, FLOOR, -12), 2.6, 0.8, Color3.fromRGB(90, 60, 40), Enum.Material.Wood)

	-- Bestenlisten
	World.Leaderboards = {}
	local function leaderboard(id, title, cframe, color)
		local board = part({
			Name = "Leaderboard_" .. id,
			Size = Vector3.new(14, 18, 1),
			CFrame = cframe,
			Color = Color3.fromRGB(35, 20, 45),
			Parent = hub,
		})
		part({ Name = "Frame", Size = Vector3.new(15, 19, 0.8), CFrame = cframe * CFrame.new(0, 0, 0.3), Color = color, Material = Enum.Material.Neon, Parent = hub })
		for _, offsetX in ipairs({ -5, 5 }) do
			local bottom = (cframe * CFrame.new(offsetX, -9, 0)).Position
			pillar(hub, Vector3.new(bottom.X, FLOOR, bottom.Z), bottom.Y - FLOOR, 1, Color3.fromRGB(60, 50, 70), Enum.Material.Metal)
		end

		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 35
		gui.LightInfluence = 0
		gui.Parent = board

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "Title"
		titleLabel.Size = UDim2.fromScale(1, 0.12)
		titleLabel.BackgroundColor3 = color
		titleLabel.Font = Enum.Font.FredokaOne
		titleLabel.TextScaled = true
		titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		titleLabel.TextStrokeTransparency = 0.3
		titleLabel.Text = title
		titleLabel.Parent = gui

		local rows = {}
		for i = 1, 10 do
			local row = Instance.new("TextLabel")
			row.Name = "Row" .. i
			row.Position = UDim2.fromScale(0.03, 0.13 + (i - 1) * 0.087)
			row.Size = UDim2.fromScale(0.94, 0.08)
			row.BackgroundColor3 = Color3.fromRGB(60, 35, 75)
			row.BackgroundTransparency = (i % 2 == 0) and 0.4 or 0.75
			row.Font = Enum.Font.GothamBold
			row.TextScaled = true
			row.TextXAlignment = Enum.TextXAlignment.Left
			row.TextColor3 = i == 1 and Color3.fromRGB(255, 215, 0) or (i == 2 and Color3.fromRGB(220, 220, 230) or (i == 3 and Color3.fromRGB(230, 150, 80) or Color3.fromRGB(240, 230, 250)))
			row.Text = "  " .. i .. ".  ..."
			row.Parent = gui
			rows[i] = row
		end
		World.Leaderboards[id] = rows
	end
	-- stehen rechts und schauen zur Mitte (-X)
	leaderboard("Earned", "🏆 MOST SLAPS", CFrame.new(50, FLOOR + 14, -32) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(255, 110, 180))
	leaderboard("Rebirths", "♻️ MOST REBIRTHS", CFrame.new(50, FLOOR + 14, -56) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(150, 90, 255))

	-- PvP-Arena
	local arena = Config.Arena
	local center = Vector3.new(arena.CenterX, FLOOR, arena.CenterZ)
	disc(hub, center + Vector3.new(0, 0.4, 0), 0.8, arena.Radius * 2 + 2, Color3.fromRGB(255, 60, 140), Enum.Material.Neon)
	local platform = disc(hub, center + Vector3.new(0, 0.6, 0), 1, arena.Radius * 2, Color3.fromRGB(60, 40, 80), Enum.Material.DiamondPlate)
	platform.Name = "ArenaFloor"
	for i = 1, 8 do
		local angle = (i / 8) * math.pi * 2
		local postPos = center + Vector3.new(math.cos(angle) * (arena.Radius + 0.5), 0, math.sin(angle) * (arena.Radius + 0.5))
		pillar(hub, postPos, 5, 1, Color3.fromRGB(255, 255, 255), Enum.Material.Metal)
		local top = ball(hub, postPos + Vector3.new(0, 5.4, 0), 1.3, Color3.fromRGB(255, 60, 140), Enum.Material.Neon)
		addLight(top, Color3.fromRGB(255, 80, 160), 10, 1)
	end
	-- Schild auf der Seite zum Spawn (+X), Text zeigt nach +X
	sign(hub, CFrame.new(center + Vector3.new(arena.Radius + 3, 9, 0)) * CFrame.Angles(0, math.rad(-90), 0), Vector3.new(20, 5, 0.8),
		"⚔️ DUEL ZONE ⚔️\nSlap a player here to start a duel!", Color3.fromRGB(255, 220, 240), Color3.fromRGB(120, 20, 60), Enum.NormalId.Front)
	World.Arena = { Center = center, Radius = arena.Radius }
end

local function buildZone(index, zone)
	local zFolder = folder("Zone" .. index, root)
	local decorFolder = folder("Decor", zFolder)
	local startZ = Calc.GetZoneStartZ(index)
	local length = Config.ZoneLength
	local centerZ = startZ + length / 2
	local accent = rgb(zone.Accent)
	local info = { Index = index, StartZ = startZ, Folder = zFolder }

	part({
		Name = "Floor",
		Size = Vector3.new(Config.ZoneWidth, 2, length),
		CFrame = CFrame.new(0, FLOOR - 1, centerZ),
		Color = rgb(zone.Floor),
		Material = material(zone.FloorMaterial),
		Parent = zFolder,
	})
	part({
		Name = "Path",
		Size = Vector3.new(12, 0.2, length),
		CFrame = CFrame.new(0, FLOOR + 0.1, centerZ),
		Color = rgb(zone.Path),
		Material = Enum.Material.Pebble,
		CanCollide = false,
		Parent = zFolder,
	})

	-- Gyatt-Plaetze (Podeste)
	info.GyattSpots = {
		CFrame.new(-22, FLOOR + 0.6, startZ + 48),
		CFrame.new(20, FLOOR + 0.6, startZ + 92),
		CFrame.new(24, FLOOR + 0.6, startZ + 42),
		CFrame.new(-40, FLOOR + 0.6, startZ + 82),
	}
	for i, spot in ipairs(info.GyattSpots) do
		local size = (zone.Gyatts[i] or zone.Gyatts[1]).Size
		disc(zFolder, spot.Position, 0.6, size + 6, accent, Enum.Material.Neon).Name = "GyattPad"
		disc(zFolder, spot.Position + Vector3.new(0, 0.1, 0), 0.6, size + 4, Color3.fromRGB(255, 255, 255), Enum.Material.Marble).Name = "GyattPadTop"
	end
	info.GoldenSpot = CFrame.new(-28, FLOOR + 0.6, startZ + 108)

	-- Eingangsbogen
	local archZ = startZ + 6
	pillar(zFolder, Vector3.new(-14, FLOOR, archZ), 16, 2.5, accent, Enum.Material.Neon)
	pillar(zFolder, Vector3.new(14, FLOOR, archZ), 16, 2.5, accent, Enum.Material.Neon)
	sign(zFolder, CFrame.new(0, FLOOR + 17.5, archZ), Vector3.new(32, 4, 1), "Zone " .. index .. ": " .. zone.Name,
		Color3.fromRGB(255, 255, 255), Color3.fromRGB(40, 25, 55), Enum.NormalId.Front)

	-- Tor (ab Zone 2)
	if index > 1 then
		local gate = part({
			Name = "Gate",
			Size = Vector3.new(Config.ZoneWidth, 30, 1.5),
			CFrame = CFrame.new(0, FLOOR + 15, startZ),
			Color = accent,
			Material = Enum.Material.ForceField,
			Transparency = 0.3,
			Parent = zFolder,
		})
		gate:SetAttribute("ZoneIndex", index)
		CollectionService:AddTag(gate, "SlapGate")
		local priceText = "🔒 Zone " .. index .. ": " .. zone.Name .. "\n👋 " .. Calc.FormatNumber(zone.Price) .. " Slaps"
		for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
			local gui = Instance.new("SurfaceGui")
			gui.Name = "GateGui"
			gui.Face = face
			gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			gui.PixelsPerStud = 12
			gui.LightInfluence = 0
			gui.Parent = gate
			local label = Instance.new("TextLabel")
			label.Name = "Text"
			label.AnchorPoint = Vector2.new(0.5, 0.5)
			label.Position = UDim2.fromScale(0.5, 0.45)
			label.Size = UDim2.fromScale(0.4, 0.35)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.FredokaOne
			label.TextScaled = true
			label.TextColor3 = Color3.fromRGB(255, 255, 255)
			label.TextStrokeTransparency = 0
			label.Text = priceText
			label.Parent = gui
		end

		local promptPart = part({
			Name = "GatePrompt",
			Size = Vector3.new(1, 1, 1),
			CFrame = CFrame.new(0, FLOOR + 3, startZ - 3),
			Transparency = 1,
			CanCollide = false,
			Parent = zFolder,
		})
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "UnlockPrompt"
		prompt.ActionText = "Unlock (" .. Calc.FormatNumber(zone.Price) .. " Slaps)"
		prompt.ObjectText = "Zone " .. index .. ": " .. zone.Name
		prompt.HoldDuration = 0.4
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt:SetAttribute("ZoneIndex", index)
		prompt.Parent = promptPart
		info.Gate = gate
		info.GatePrompt = prompt
	end

	-- Ei-Stand
	local egg = Config.Eggs[zone.Egg]
	info.EggStands = {}
	local function eggStand(eggId, position)
		local eggCfg = Config.Eggs[eggId]
		local standFolder = folder("EggStand_" .. eggId, zFolder)
		local base = pillar(standFolder, position, 2.5, 9, Color3.fromRGB(60, 40, 75), Enum.Material.Marble)
		base.Name = "EggBase"
		disc(standFolder, position + Vector3.new(0, 2.55, 0), 0.3, 9.6, accent, Enum.Material.Neon)
		local eggPart = part({
			Name = "Egg",
			Size = Vector3.new(5, 6.5, 5),
			CFrame = CFrame.new(position + Vector3.new(0, 6, 0)),
			Color = rgb(eggCfg.Color),
			Material = eggCfg.Currency == "Gems" and Enum.Material.Foil or Enum.Material.SmoothPlastic,
			Parent = standFolder,
		})
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = eggPart
		eggPart:SetAttribute("BaseY", position.Y + 6)
		CollectionService:AddTag(eggPart, "SlapEgg")
		local glow = Instance.new("PointLight")
		glow.Color = rgb(eggCfg.Color)
		glow.Range = 12
		glow.Brightness = 1.2
		glow.Parent = eggPart
		if eggCfg.Currency == "Gems" then
			local s = Instance.new("Sparkles")
			s.SparkleColor = Color3.fromRGB(255, 230, 120)
			s.Parent = eggPart
		end

		-- Info-Anzeige ueber dem Ei
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "EggInfo"
		billboard.Size = UDim2.new(12, 0, 9, 0)
		billboard.StudsOffsetWorldSpace = Vector3.new(0, 10.5, 0)
		billboard.MaxDistance = 70
		billboard.LightInfluence = 0
		billboard.Adornee = base
		billboard.Parent = base
		local title = Instance.new("TextLabel")
		title.Size = UDim2.fromScale(1, 0.2)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.FredokaOne
		title.TextScaled = true
		title.TextColor3 = rgb(eggCfg.Color)
		title.TextStrokeTransparency = 0
		local currencyIcon = eggCfg.Currency == "Gems" and "💎" or "👋"
		title.Text = "🥚 " .. eggCfg.DisplayName .. "  " .. currencyIcon .. " " .. Calc.FormatNumber(eggCfg.Price)
		title.Parent = billboard
		local chances = Calc.GetEggChances(eggId, false)
		for i, entry in ipairs(chances) do
			local pet = Config.Pets[entry.PetId]
			local rarity = Config.Rarities[pet.Rarity]
			local row = Instance.new("TextLabel")
			row.Position = UDim2.fromScale(0, 0.2 + (i - 1) * 0.19)
			row.Size = UDim2.fromScale(1, 0.18)
			row.BackgroundTransparency = 1
			row.Font = Enum.Font.GothamBold
			row.TextScaled = true
			row.TextColor3 = rgb(rarity.Color)
			row.TextStrokeTransparency = 0.2
			row.Text = pet.DisplayName .. "  +" .. Calc.FormatNumber(math.floor(pet.Boost * 100)) .. "%  (" .. Calc.FormatChance(entry.Chance) .. ")"
			row.Parent = billboard
		end

		local prompts = {}
		for _, amount in ipairs({ 1, 3 }) do
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "Hatch" .. amount
			prompt.ActionText = amount == 1 and "Hatch" or "Hatch x3"
			prompt.ObjectText = eggCfg.DisplayName .. " (" .. currencyIcon .. " " .. Calc.FormatNumber(eggCfg.Price * amount) .. ")"
			prompt.KeyboardKeyCode = amount == 1 and Enum.KeyCode.E or Enum.KeyCode.R
			prompt.HoldDuration = 0.25
			prompt.MaxActivationDistance = 12
			prompt.RequiresLineOfSight = false
			prompt.UIOffset = Vector2.new(0, amount == 1 and 0 or 80)
			prompt:SetAttribute("EggId", eggId)
			prompt:SetAttribute("Amount", amount)
			prompt.Parent = base
			table.insert(prompts, prompt)
		end
		table.insert(info.EggStands, { EggId = eggId, Prompts = prompts })
	end
	eggStand(zone.Egg, Vector3.new(42, FLOOR, startZ + 24))
	if zone.ExtraEgg then
		eggStand(zone.ExtraEgg, Vector3.new(42, FLOOR, startZ + 62))
	end
	if zone.ExtraEgg2 then
		eggStand(zone.ExtraEgg2, Vector3.new(-44, FLOOR, startZ + 20))
	end
	if egg == nil then
		warn("[SlapTheBlob] Zone " .. index .. " has no valid egg")
	end

	-- Deko
	local rng = Random.new(1000 + index * 77)
	local blocked = {
		{ X = -22, Z = startZ + 48, R = zone.Gyatts[1].Size + 8 },
		{ X = 20, Z = startZ + 92, R = zone.Gyatts[2].Size + 8 },
		{ X = 42, Z = startZ + 24, R = 9 },
		{ X = 42, Z = startZ + 62, R = 9 },
		{ X = -44, Z = startZ + 20, R = 9 },
		{ X = 24, Z = startZ + 42, R = 14 },
		{ X = -40, Z = startZ + 82, R = 9 },
		{ X = -28, Z = startZ + 108, R = 14 },
		{ X = 0, Z = startZ + 6, R = 16 },
		{ X = 0, Z = startZ + length - 14, R = 22 },
	}
	local function isFree(x, z, radius)
		if math.abs(x) < 9 + radius then
			return false -- Weg frei lassen
		end
		for _, b in ipairs(blocked) do
			local dx, dz = x - b.X, z - b.Z
			if math.sqrt(dx * dx + dz * dz) < b.R + radius then
				return false
			end
		end
		return true
	end
	for _, entry in ipairs(THEMES[zone.Decor] or {}) do
		local kind, count, color, mat, big = entry[1], entry[2], entry[3], entry[4], entry[5]
		local builder = decor[kind]
		if builder then
			for n = 1, count do
				local x, z
				if big then
					-- grosse Objekte an den Rand
					local side = (n % 2 == 0) and 1 or -1
					x = side * (HALF_WIDTH - 14)
					z = startZ + length * (0.3 + 0.4 * ((n - 1) / math.max(1, count - 1)))
					if kind == "rainbow" then
						x = 0
						z = startZ + length - 12
					end
				else
					local tries = 0
					repeat
						x = rng:NextNumber(-HALF_WIDTH + 3, HALF_WIDTH - 3)
						z = rng:NextNumber(startZ + 10, startZ + length - 4)
						tries = tries + 1
					until isFree(x, z, 2) or tries > 25
				end
				local pos = Vector3.new(x, FLOOR, z)
				if kind == "rock" then
					builder(decorFolder, pos, rng, color and rgb(color) or nil, mat and material(mat) or nil)
				else
					builder(decorFolder, pos, rng)
				end
			end
		end
	end

	-- Zaun an den Seiten
	for _, side in ipairs({ -1, 1 }) do
		part({
			Name = "Fence",
			Size = Vector3.new(1, 3, length),
			CFrame = CFrame.new(side * (HALF_WIDTH - 0.5), FLOOR + 1.5, centerZ),
			Color = accent,
			Material = Enum.Material.Neon,
			Transparency = 0.2,
			Parent = zFolder,
		})
	end

	-- Portal in die naechste Dimension am Ende der letzten Zone einer Dimension
	local dim, dimIndex = Calc.GetDimension(index)
	local nextDim = Config.Dimensions[dimIndex + 1]
	if index == dim.LastZone and nextDim then
		local portalZ = startZ + length - 14
		local portal = folder("RiftPortal", zFolder)
		local purple = Color3.fromRGB(170, 70, 255)
		for i = 0, 23 do
			local angle = (i / 24) * math.pi * 2
			local orb = ball(portal, Vector3.new(math.cos(angle) * 11, FLOOR + 13 + math.sin(angle) * 11, portalZ), 3, purple, Enum.Material.Neon)
			orb.CanCollide = false
		end
		local swirl = disc(portal, Vector3.new(0, FLOOR + 13, portalZ), 0.4, 20, Color3.fromRGB(60, 0, 120), Enum.Material.Neon)
		swirl.CFrame = CFrame.new(0, FLOOR + 13, portalZ) * CFrame.Angles(0, math.rad(90), 0)
		swirl.Transparency = 0.25
		swirl.CanCollide = false
		swirl.Name = "PortalSwirl"
		CollectionService:AddTag(swirl, "SlapPortal")
		addLight(swirl, purple, 40, 3)
		local sparkle = Instance.new("Sparkles")
		sparkle.SparkleColor = purple
		sparkle.Parent = swirl
		sign(portal, CFrame.new(0, FLOOR + 28, portalZ), Vector3.new(30, 4, 1), "🌀 PORTAL TO " .. string.upper(nextDim.Name) .. " 🌀",
			Color3.fromRGB(230, 200, 255), Color3.fromRGB(40, 10, 70), Enum.NormalId.Front)
		local promptPart = part({ Name = "PortalPrompt", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(0, FLOOR + 3, portalZ - 4), Transparency = 1, CanCollide = false, Parent = portal })
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "EnterPrompt"
		prompt.ActionText = "Enter " .. nextDim.Name
		prompt.ObjectText = "Dimension Portal"
		prompt.HoldDuration = 0.5
		prompt.MaxActivationDistance = 16
		prompt.RequiresLineOfSight = false
		prompt:SetAttribute("Dimension", dimIndex + 1)
		prompt.Parent = promptPart
		info.PortalPrompt = prompt
	end

	info.TeleportCFrame = CFrame.new(0, FLOOR + 4, startZ + 14)
	World.Zones[index] = info
	return info
end

local function buildBounds()
	local bounds = folder("Bounds", root)
	local function wall(size, position)
		part({ Name = "InvisibleWall", Size = size, CFrame = CFrame.new(position), Transparency = 1, Parent = bounds })
	end
	for dimIndex, dim in ipairs(Config.Dimensions) do
		local frontZ = (dimIndex == 1) and -Config.HubLength or (dim.StartZ - Config.DimensionLandingLength)
		local endZ = Calc.GetZoneStartZ(dim.LastZone) + Config.ZoneLength
		local length = endZ - frontZ
		local centerZ = (endZ + frontZ) / 2
		wall(Vector3.new(2, 120, length), Vector3.new(-HALF_WIDTH - 1, 60, centerZ))
		wall(Vector3.new(2, 120, length), Vector3.new(HALF_WIDTH + 1, 60, centerZ))
		wall(Vector3.new(Config.ZoneWidth, 120, 2), Vector3.new(0, 60, frontZ - 1))
		wall(Vector3.new(Config.ZoneWidth, 120, 2), Vector3.new(0, 60, endZ + 1))
	end
	-- Hub-Zaun
	for _, side in ipairs({ -1, 1 }) do
		part({
			Name = "HubFence",
			Size = Vector3.new(1, 3, Config.HubLength),
			CFrame = CFrame.new(side * (HALF_WIDTH - 0.5), FLOOR + 1.5, -Config.HubLength / 2),
			Color = Color3.fromRGB(255, 110, 180),
			Material = Enum.Material.Neon,
			Transparency = 0.2,
			Parent = bounds,
		})
	end
end

-- Landeplattform am Anfang jeder weiteren Dimension (mit Rueck-Portal)
World.Dimensions = {}
local function buildLandings()
	for dimIndex, dim in ipairs(Config.Dimensions) do
		if dimIndex > 1 then
			local landing = folder("Landing_" .. dim.Name, root)
			local length = Config.DimensionLandingLength
			local frontZ = dim.StartZ - length
			local firstZone = Config.Zones[dim.FirstZone]
			part({
				Name = "LandingFloor",
				Size = Vector3.new(Config.ZoneWidth, 2, length),
				CFrame = CFrame.new(0, FLOOR - 1, frontZ + length / 2),
				Color = Color3.fromRGB(45, 25, 70),
				Material = Enum.Material.Marble,
				Parent = landing,
			})
			for x = -2, 2 do
				part({ Name = "Rune", Size = Vector3.new(6, 0.1, 6), CFrame = CFrame.new(x * 14, FLOOR + 0.05, frontZ + length / 2) * CFrame.Angles(0, math.rad(45), 0),
					Color = rgb(firstZone.Accent), Material = Enum.Material.Neon, CanCollide = false, Parent = landing })
			end
			sign(landing, CFrame.new(0, FLOOR + 14, frontZ + 8) * CFrame.Angles(0, math.pi, 0), Vector3.new(36, 7, 1),
				"🌀 WELCOME TO " .. string.upper(dim.Name) .. " 🌀\nStronger targets, rarer pets!", Color3.fromRGB(240, 220, 255), Color3.fromRGB(40, 10, 70), Enum.NormalId.Front)
			-- Rueck-Portal
			local returnPart = part({ Name = "ReturnPortal", Size = Vector3.new(10, 14, 1), CFrame = CFrame.new(-40, FLOOR + 7, frontZ + 6),
				Color = Color3.fromRGB(120, 255, 180), Material = Enum.Material.Neon, Transparency = 0.3, CanCollide = false, Parent = landing })
			addLight(returnPart, Color3.fromRGB(120, 255, 180), 20, 2)
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "ReturnPrompt"
			prompt.ActionText = "Return to Overworld"
			prompt.ObjectText = "Portal"
			prompt.HoldDuration = 0.3
			prompt.MaxActivationDistance = 14
			prompt.RequiresLineOfSight = false
			prompt.Parent = returnPart
			World.Dimensions[dimIndex] = {
				LandingCFrame = CFrame.new(0, FLOOR + 4, frontZ + 20),
				ReturnPrompt = prompt,
			}
		else
			World.Dimensions[dimIndex] = { LandingCFrame = CFrame.new(0, FLOOR + 4, Calc.GetZoneStartZ(dim.LastZone) + Config.ZoneLength - 30) }
		end
	end
end

-- Schwebende Duell-Arenen hoch ueber der Karte
World.DuelArenas = {}
local function buildDuelArenas()
	local duel = Config.Duel
	local arenaFolder = folder("DuelArenas", root)
	for i = 1, duel.ArenaCount do
		local center = Vector3.new(-450 + (i - 1) * 150, FLOOR + duel.ArenaHeight, -350)
		local r = duel.ArenaRadius
		disc(arenaFolder, center + Vector3.new(0, -1.5, 0), 3, r * 2 + 3, Color3.fromRGB(255, 50, 120), Enum.Material.Neon)
		local floorPart = disc(arenaFolder, center + Vector3.new(0, -0.5, 0), 1.2, r * 2, Color3.fromRGB(45, 30, 70), Enum.Material.DiamondPlate)
		floorPart.Name = "DuelFloor"
		for k = 1, 10 do
			local angle = (k / 10) * math.pi * 2
			local p = center + Vector3.new(math.cos(angle) * (r - 1), 0, math.sin(angle) * (r - 1))
			local orb = ball(arenaFolder, p + Vector3.new(0, 0.6, 0), 1.5, Color3.fromRGB(255, 200, 80), Enum.Material.Neon)
			orb.CanCollide = false
		end
		sign(arenaFolder, CFrame.new(center + Vector3.new(0, 18, -r - 4)), Vector3.new(26, 5, 1), "⚔️ DUEL ARENA " .. i .. " ⚔️",
			Color3.fromRGB(255, 230, 240), Color3.fromRGB(120, 20, 60), Enum.NormalId.Back)
		World.DuelArenas[i] = {
			Center = center,
			Spawns = {
				CFrame.lookAt(center + Vector3.new(-r * 0.55, 3, 0), center + Vector3.new(0, 3, 0)),
				CFrame.lookAt(center + Vector3.new(r * 0.55, 3, 0), center + Vector3.new(0, 3, 0)),
			},
		}
	end
end

--------------------------------------------------------------------------
-- Hintergrund: Himmel, Wolken, Boden und Berge rund um die Karte
--------------------------------------------------------------------------
local BACKDROPS = {
	meadow = { Ground = { 90, 170, 90 }, Mountain = { 80, 140, 90 }, Cap = { 250, 250, 255 }, Kind = "mountain" },
	desert = { Ground = { 220, 185, 120 }, Mountain = { 210, 130, 70 }, Cap = { 235, 170, 100 }, Kind = "mesa" },
	ice = { Ground = { 230, 240, 255 }, Mountain = { 160, 190, 220 }, Cap = { 255, 255, 255 }, Kind = "mountain" },
	lava = { Ground = { 50, 35, 32 }, Mountain = { 60, 40, 38 }, Cap = { 255, 90, 20 }, Kind = "volcano" },
	cloud = { Ground = { 240, 245, 255 }, Mountain = { 255, 255, 255 }, Cap = { 255, 220, 120 }, Kind = "cloud" },
	space = { Ground = { 25, 15, 50 }, Mountain = { 70, 55, 100 }, Cap = { 170, 120, 255 }, Kind = "asteroid" },
	candy = { Ground = { 255, 190, 225 }, Mountain = { 255, 150, 200 }, Cap = { 255, 255, 255 }, Kind = "mountain" },
	cyber = { Ground = { 15, 20, 35 }, Mountain = { 30, 40, 60 }, Cap = { 0, 255, 230 }, Kind = "tower" },
	shadow = { Ground = { 30, 20, 40 }, Mountain = { 45, 30, 60 }, Cap = { 170, 60, 255 }, Kind = "mountain" },
	void = { Ground = { 10, 5, 20 }, Mountain = { 40, 20, 70 }, Cap = { 255, 255, 255 }, Kind = "asteroid" },
}

local function backdropMountain(parent, kind, position, rng, theme)
	local color = rgb(theme.Mountain)
	local cap = rgb(theme.Cap)
	if kind == "mountain" or kind == "volcano" then
		local baseD = rng:NextNumber(70, 120)
		local layers = 6
		local layerH = baseD * 0.16
		for i = 0, layers - 1 do
			local d = baseD * (1 - i / layers)
			local isTop = i >= layers - 2
			local layer = pillar(parent, position + Vector3.new(0, i * layerH, 0), layerH, d,
				(isTop and kind == "mountain") and cap or color, kind == "volcano" and Enum.Material.Basalt or Enum.Material.Rock)
			layer.CastShadow = false
		end
		if kind == "volcano" then
			local top = disc(parent, position + Vector3.new(0, layers * layerH + 0.2, 0), 0.5, baseD / layers, cap, Enum.Material.Neon)
			top.CastShadow = false
			local fire = Instance.new("Fire")
			fire.Size = 30
			fire.Heat = 25
			fire.Parent = top
			addLight(top, Color3.fromRGB(255, 100, 30), 60, 3)
		end
	elseif kind == "mesa" then
		local w = rng:NextNumber(40, 80)
		local h = rng:NextNumber(25, 45)
		for i = 0, 2 do
			local layer = part({
				Name = "Mesa",
				Size = Vector3.new(w * (1 - i * 0.12), h / 3, w * 0.7 * (1 - i * 0.12)),
				CFrame = CFrame.new(position + Vector3.new(0, h / 6 + i * h / 3, 0)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0),
				Color = (i % 2 == 0) and color or cap,
				Material = Enum.Material.Sandstone,
				Parent = parent,
			})
			layer.CastShadow = false
		end
		local dune = ball(parent, position + Vector3.new(rng:NextNumber(-40, 40), -10, rng:NextNumber(-30, 30)), rng:NextNumber(40, 60), rgb(theme.Ground), Enum.Material.Sand)
		dune.CastShadow = false
	elseif kind == "cloud" then
		local lift = rng:NextNumber(10, 40)
		for i = 1, 6 do
			local puff = ball(parent, position + Vector3.new(rng:NextNumber(-25, 25), lift + rng:NextNumber(-5, 8), rng:NextNumber(-20, 20)), rng:NextNumber(18, 32), color, Enum.Material.SmoothPlastic)
			puff.CastShadow = false
			puff.CanCollide = false
		end
		-- kleiner goldener Tempel auf der Wolke
		for _, ox in ipairs({ -6, 6 }) do
			local col = pillar(parent, position + Vector3.new(ox, lift + 10, 0), 12, 2.5, cap, Enum.Material.Foil)
			col.CastShadow = false
		end
		local roof = part({ Name = "TempleRoof", Size = Vector3.new(18, 2, 8), CFrame = CFrame.new(position + Vector3.new(0, lift + 23, 0)), Color = cap, Material = Enum.Material.Foil, Parent = parent })
		roof.CastShadow = false
	elseif kind == "tower" then
		for i = 1, 3 do
			local w = rng:NextNumber(14, 26)
			local h = rng:NextNumber(60, 160)
			local offset = Vector3.new(rng:NextNumber(-30, 30), 0, rng:NextNumber(-30, 30))
			local tower = part({ Name = "Tower", Size = Vector3.new(w, h, w), CFrame = CFrame.new(position + offset + Vector3.new(0, h / 2, 0)),
				Color = color, Material = Enum.Material.SmoothPlastic, Parent = parent })
			tower.CastShadow = false
			for y = 10, h - 6, 14 do
				local stripe = part({ Name = "TowerStripe", Size = Vector3.new(w + 0.4, 0.8, w + 0.4), CFrame = CFrame.new(position + offset + Vector3.new(0, y, 0)),
					Color = cap, Material = Enum.Material.Neon, CanCollide = false, Parent = parent })
				stripe.CastShadow = false
			end
			if i == 1 then
				addLight(tower, cap, 40, 2)
			end
		end
	elseif kind == "asteroid" then
		for i = 1, 4 do
			local s = rng:NextNumber(8, 22)
			local rock = part({
				Name = "Asteroid",
				Size = Vector3.new(s, s * 0.8, s * 1.1),
				CFrame = CFrame.new(position + Vector3.new(rng:NextNumber(-30, 30), rng:NextNumber(15, 70), rng:NextNumber(-30, 30))) * CFrame.Angles(rng:NextNumber(0, 3), rng:NextNumber(0, 3), rng:NextNumber(0, 3)),
				Color = color,
				Material = Enum.Material.Slate,
				CanCollide = false,
				Parent = parent,
			})
			rock.CastShadow = false
			if i == 1 then
				local glow = ball(parent, rock.Position + Vector3.new(0, s * 0.5, 0), s * 0.3, cap, Enum.Material.Neon)
				glow.CanCollide = false
				glow.CastShadow = false
			end
		end
	end
end

local function buildBackground()
	local bg = folder("Background", root)
	local rng = Random.new(4242)

	-- Himmel (nur eingebaute Roblox-Werte, keine Bilder noetig)
	local oldSky = Lighting:FindFirstChildOfClass("Sky")
	if oldSky then
		oldSky:Destroy()
	end
	local sky = Instance.new("Sky")
	sky.Name = "SlapSky"
	sky.StarCount = 3000
	sky.CelestialBodiesShown = true
	sky.SunAngularSize = 16
	sky.MoonAngularSize = 9
	sky.Parent = Lighting

	-- Echte Wolken am Himmel
	local terrain = workspace.Terrain
	local clouds = terrain:FindFirstChildOfClass("Clouds")
	if not clouds then
		clouds = Instance.new("Clouds")
		clouds.Parent = terrain
	end
	clouds.Cover = 0.55
	clouds.Density = 0.55
	clouds.Color = Color3.fromRGB(255, 245, 250)

	local outer = 360 -- wie weit der Boden ausserhalb der Karte reicht
	local function ground(name, size, position, color, mat)
		local g = part({ Name = name, Size = size, CFrame = CFrame.new(position), Color = color, Material = mat, Parent = bg })
		g.CastShadow = false
		return g
	end

	-- Boden neben dem Hub und dahinter
	local hubColor = Color3.fromRGB(110, 190, 110)
	for _, side in ipairs({ -1, 1 }) do
		ground("HubGround", Vector3.new(outer, 2, Config.HubLength), Vector3.new(side * (HALF_WIDTH + outer / 2), FLOOR - 1.2, -Config.HubLength / 2), hubColor, Enum.Material.Grass)
	end
	ground("BackGround", Vector3.new(Config.ZoneWidth + outer * 2, 2, outer), Vector3.new(0, FLOOR - 1.2, -Config.HubLength - outer / 2), hubColor, Enum.Material.Grass)

	-- Riesige Blob-Statue hinter dem Hub ("Mount Blob"), schaut zum Spawn (+Z)
	local mx, mz = 0, -Config.HubLength - 120
	local pink = Color3.fromRGB(255, 160, 200)
	local my = FLOOR + 42
	local giant = ball(bg, Vector3.new(mx, my, mz), 84, pink, Enum.Material.Marble)
	giant.CastShadow = false
	local white = Color3.fromRGB(255, 255, 255)
	local black = Color3.fromRGB(30, 20, 35)
	for _, side in ipairs({ -1, 1 }) do
		local eye = ball(bg, Vector3.new(mx + side * 14, my + 10, mz + 36), 22, white, Enum.Material.SmoothPlastic)
		eye.CastShadow = false
		local pupil = ball(bg, Vector3.new(mx + side * 14, my + 10, mz + 45), 11, black, Enum.Material.SmoothPlastic)
		pupil.CastShadow = false
		local blush = ball(bg, Vector3.new(mx + side * 25, my - 4, mz + 33), 12, Color3.fromRGB(255, 110, 150), Enum.Material.SmoothPlastic)
		blush.CastShadow = false
		local foot = ball(bg, Vector3.new(mx + side * 20, FLOOR + 3, mz + 8), 26, Color3.fromRGB(220, 120, 160), Enum.Material.Marble)
		foot.CastShadow = false
	end
	local mouth = part({ Name = "MountBlobMouth", Size = Vector3.new(18, 3, 2), CFrame = CFrame.new(mx, my - 8, mz + 41), Color = black, Parent = bg })
	mouth.CastShadow = false
	local crownBase = pillar(bg, Vector3.new(mx, my + 38, mz), 6, 30, Color3.fromRGB(255, 200, 40), Enum.Material.Foil)
	crownBase.CastShadow = false
	local monumentSign = sign(bg, CFrame.new(mx, FLOOR + 92, mz + 2), Vector3.new(60, 10, 1), "MOUNT BLOB", Color3.fromRGB(255, 80, 160), Color3.fromRGB(255, 255, 255), Enum.NormalId.Back)
	monumentSign.CastShadow = false
	for _ = 1, 8 do
		backdropMountain(bg, "mountain", Vector3.new(rng:NextNumber(-260, 260), FLOOR - 1, -Config.HubLength - rng:NextNumber(170, 320)), rng, BACKDROPS.meadow)
	end

	-- Pro Zone: Boden und Berge links und rechts
	for index, zone in ipairs(Config.Zones) do
		local theme = BACKDROPS[zone.Decor] or BACKDROPS.meadow
		local startZ = Calc.GetZoneStartZ(index)
		local centerZ = startZ + Config.ZoneLength / 2
		for _, side in ipairs({ -1, 1 }) do
			ground("ZoneGround", Vector3.new(outer, 2, Config.ZoneLength), Vector3.new(side * (HALF_WIDTH + outer / 2), FLOOR - 1.2, centerZ), rgb(theme.Ground),
				zone.Decor == "desert" and Enum.Material.Sand or (zone.Decor == "ice" and Enum.Material.Snow or (zone.Decor == "lava" and Enum.Material.Basalt or (zone.Decor == "meadow" and Enum.Material.Grass or Enum.Material.SmoothPlastic))))
			for n = 1, 3 do
				local x = side * rng:NextNumber(HALF_WIDTH + 60, HALF_WIDTH + 280)
				local z = startZ + (n - 0.5) * Config.ZoneLength / 3 + rng:NextNumber(-15, 15)
				backdropMountain(bg, theme.Kind, Vector3.new(x, FLOOR - 1, z), rng, theme)
			end
		end
	end

	-- Ende der Welt: Boden und Berge hinter der letzten Zone
	for dimIndex, dim in ipairs(Config.Dimensions) do
		local endZ = Calc.GetZoneStartZ(dim.LastZone) + Config.ZoneLength
		local lastTheme = BACKDROPS[Config.Zones[dim.LastZone].Decor] or BACKDROPS.space
		ground("EndGround", Vector3.new(Config.ZoneWidth + outer * 2, 2, outer * 0.5), Vector3.new(0, FLOOR - 1.2, endZ + outer * 0.25), rgb(lastTheme.Ground), Enum.Material.SmoothPlastic)
		for _ = 1, 6 do
			backdropMountain(bg, lastTheme.Kind, Vector3.new(rng:NextNumber(-260, 260), FLOOR - 1, endZ + rng:NextNumber(50, 170)), rng, lastTheme)
		end
		if dimIndex > 1 then
			local frontZ = dim.StartZ - Config.DimensionLandingLength
			local firstTheme = BACKDROPS[Config.Zones[dim.FirstZone].Decor] or BACKDROPS.space
			for _, side in ipairs({ -1, 1 }) do
				ground("LandingGround", Vector3.new(outer, 2, Config.DimensionLandingLength), Vector3.new(side * (HALF_WIDTH + outer / 2), FLOOR - 1.2, frontZ + Config.DimensionLandingLength / 2), rgb(firstTheme.Ground), Enum.Material.SmoothPlastic)
			end
			ground("RiftBackGround", Vector3.new(Config.ZoneWidth + outer * 2, 2, outer * 0.5), Vector3.new(0, FLOOR - 1.3, frontZ - outer * 0.25), rgb(firstTheme.Ground), Enum.Material.SmoothPlastic)
			for _ = 1, 6 do
				backdropMountain(bg, firstTheme.Kind, Vector3.new(rng:NextNumber(-260, 260), FLOOR - 1, frontZ - rng:NextNumber(50, 170)), rng, firstTheme)
			end
		end
	end
end

function World.Build()
	local old = workspace:FindFirstChild("SlapWorld")
	if old then
		old:Destroy()
	end
	root = folder("SlapWorld", workspace)
	World.Root = root

	-- Andere Spawns (z.B. aus der Baseplate-Vorlage) ausschalten
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("SpawnLocation") then
			d.Enabled = false
		end
	end

	buildLighting()
	buildHub()
	for index, zone in ipairs(Config.Zones) do
		buildZone(index, zone)
	end
	buildBounds()
	buildLandings()
	buildDuelArenas()
	buildBackground()

	World.GyattFolder = folder("Gyatts", root)
	return World
end

-- Liegt eine Position in der PvP-Arena?
function World.IsInArena(position)
	if not World.Arena then
		return false
	end
	local offset = position - World.Arena.Center
	local flat = math.sqrt(offset.X * offset.X + offset.Z * offset.Z)
	return flat <= World.Arena.Radius and offset.Y > -2 and offset.Y < 25
end

return World
