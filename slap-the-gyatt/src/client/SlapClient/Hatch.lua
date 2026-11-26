--[[
	Hatch: Ei- und Kisten-Animation.
	  Ei wackelt immer schneller, leuchtet auf und platzt.
	  Dahinter drehen sich Lichtstrahlen in der Farbe der besten Seltenheit,
	  die Karten drehen sich um (Flip), springen und es regnet Konfetti.
]]

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Hatch = {}
local ctx, UI, Config, Calc, Create

local overlay, stage, eggLabel, eggScale, eggGlow, rays, raysScale, resultHolder, hintLabel, flash, confettiHolder, bestLabel
local playing = false
local queue = {}

local CATEGORY_ICON = { Hat = "🎩", Back = "🪽", Aura = "✨" }

local function build()
	overlay = Create("TextButton", {
		Name = "HatchOverlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(10, 0, 20),
		BackgroundTransparency = 0.3,
		AutoButtonColor = false,
		Text = "",
		Visible = false,
		ZIndex = 50,
		Parent = ctx.Screen,
	})
	stage = Create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 50, Parent = overlay })
	-- Lichtstrahlen (12 schmale Balken, die sich drehen)
	rays = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.new(0, 520, 0, 520),
		Rotation = 0,
		BackgroundTransparency = 1,
		ZIndex = 50,
		Parent = stage,
	})
	raysScale = Create("UIScale", { Scale = 1, Parent = rays })
	for i = 0, 11 do
		Create("Frame", {
			Name = "Ray",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(0, 34, 1, 0),
			Rotation = i * 15,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.82,
			BorderSizePixel = 0,
			ZIndex = 50,
			Parent = rays,
		}, {
			Create("UIGradient", {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.5, 0),
					NumberSequenceKeypoint.new(1, 1),
				}),
				Rotation = 90,
			}),
		})
	end
	eggGlow = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.new(0, 200, 0, 200),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.6,
		ZIndex = 51,
		Parent = stage,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	eggLabel = UI.Label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.new(0, 200, 0, 200),
		Text = "🥚",
		ZIndex = 52,
		Parent = stage,
	})
	eggScale = Create("UIScale", { Scale = 1, Parent = eggLabel })
	resultHolder = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.new(0.94, 0, 0, 230),
		BackgroundTransparency = 1,
		ZIndex = 52,
		Parent = stage,
	}, {
		Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 14),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	bestLabel = UI.Label({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0.45, -125),
		Size = UDim2.new(0.8, 0, 0, 48),
		Text = "",
		ZIndex = 55,
		Parent = stage,
	})
	UI.TextStroke(3).Parent = bestLabel
	hintLabel = UI.Label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.45, 130),
		Size = UDim2.new(0.6, 0, 0, 26),
		Font = UI.BodyFont,
		TextColor3 = UI.Colors.SubText,
		Text = "Tap to close",
		ZIndex = 55,
		Parent = stage,
	})
	confettiHolder = Create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 56, Parent = overlay })
	flash = Create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 1, ZIndex = 57, Parent = overlay })
	-- auf kleinen Bildschirmen alles kleiner
	local stageScale = Create("UIScale", { Scale = 1, Parent = resultHolder })
	local function fit()
		local camera = workspace.CurrentCamera
		local h = camera and camera.ViewportSize.Y or 720
		local s = math.clamp(h / 700, 0.55, 1)
		stageScale.Scale = s
		raysScale.Scale = s
	end
	fit()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	end
end

local function confetti(color, amount)
	local colors = { color, Color3.fromRGB(255, 220, 80), Color3.fromRGB(255, 110, 180), Color3.fromRGB(90, 200, 255), Color3.fromRGB(120, 255, 140) }
	for i = 1, amount do
		local startX = math.random()
		local startRotation = math.random(0, 360)
		local piece = Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(startX, 0, -0.05, 0),
			Size = UDim2.new(0, math.random(6, 12), 0, math.random(10, 18)),
			Rotation = startRotation,
			BackgroundColor3 = colors[(i % #colors) + 1],
			BorderSizePixel = 0,
			ZIndex = 56,
			Parent = confettiHolder,
		})
		local duration = 1.6 + math.random() * 1.4
		TweenService:Create(piece, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(startX + (math.random() - 0.5) * 0.3, 0, 1.08, 0),
			Rotation = startRotation + math.random(-540, 540),
		}):Play()
		task.delay(duration + 0.05, function()
			piece:Destroy()
		end)
	end
end

-- Karte fuer ein Pet oder Item. Startet "umgedreht" (schmal) und dreht sich auf.
local function makeCard(order, info)
	local color = info.RarityColor
	local frame = Create("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(0, 160, 0, 214),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		ZIndex = 53,
		Parent = resultHolder,
	}, {
		UI.Corner(18),
		UI.Stroke(4, color),
		UI.Gradient(UI.Colors.Panel, UI.Colors.Darker),
	})
	local inner = Create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 53, Parent = frame })
	local scale = Create("UIScale", { Scale = 0.2, Parent = frame })
	-- Rueckseite (Fragezeichen) waehrend des Flips
	local back = Create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, ZIndex = 58, Parent = frame }, { UI.Corner(18) })
	UI.Label({ Size = UDim2.fromScale(1, 1), Text = "?", ZIndex = 59, Parent = back })

	local face = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 14),
		Size = UDim2.new(0, 86, 0, 86),
		BackgroundColor3 = info.Color,
		ZIndex = 54,
		Parent = inner,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }), UI.Stroke(3) })
	UI.Label({ Size = UDim2.fromScale(1, 1), Text = info.Icon, ZIndex = 55, Parent = face })
	local name = UI.Label({ Position = UDim2.new(0, 6, 0, 106), Size = UDim2.new(1, -12, 0, 30), TextWrapped = true, Text = info.Name, ZIndex = 54, Parent = inner })
	UI.TextStroke(1.5).Parent = name
	local rarityLabel = UI.Label({ Position = UDim2.new(0, 6, 0, 138), Size = UDim2.new(1, -12, 0, 24), Text = info.RarityName, TextColor3 = color, ZIndex = 54, Parent = inner })
	UI.TextStroke(1.5).Parent = rarityLabel
	UI.Label({ Position = UDim2.new(0, 6, 0, 166), Size = UDim2.new(1, -12, 0, 22), Font = UI.BodyFont, TextScaled = true, Text = info.Stat, TextColor3 = UI.Colors.Gold, ZIndex = 54, Parent = inner })
	if info.Order >= 5 then
		-- Glanz fuer sehr seltene Karten
		local shine = Create("UIGradient", {
			Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(0.5, color), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)) }),
			Rotation = 45,
			Parent = back,
		})
		shine.Offset = Vector2.new(-1, 0)
		TweenService:Create(shine, TweenInfo.new(0.5), { Offset = Vector2.new(1, 0) }):Play()
	end

	-- Auftauchen, dann Flip (Breite 0 -> voll), dann kleiner Huepfer
	local delayTime = 0.12 * (order - 1)
	task.delay(delayTime, function()
		TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		task.wait(0.35 + (info.Order >= 4 and 0.35 or 0))
		local half = TweenService:Create(frame, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = UDim2.new(0, 0, 0, 214) })
		half:Play()
		task.wait(0.12)
		back.Visible = false
		TweenService:Create(frame, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(0, 160, 0, 214) }):Play()
		task.wait(0.18)
		scale.Scale = 1.15
		TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end)
	return frame
end

local function petInfo(petId)
	local cfg = Config.Pets[petId]
	local rarity = Config.Rarities[cfg.Rarity]
	return {
		Name = cfg.DisplayName,
		Icon = "😊",
		Color = UI.rgb(cfg.Color),
		RarityName = rarity.DisplayName,
		RarityColor = UI.rgb(rarity.Color),
		Order = rarity.Order,
		Rarity = cfg.Rarity,
		Stat = "+" .. Calc.FormatNumber(math.floor(cfg.Boost * 100)) .. "% Slaps",
	}
end

local function itemInfo(itemId, level)
	local cfg = Config.Items[itemId]
	local rarity = Config.Rarities[cfg.Rarity]
	return {
		Name = cfg.DisplayName,
		Icon = CATEGORY_ICON[cfg.Category] or "🎁",
		Color = UI.rgb(cfg.Color),
		RarityName = rarity.DisplayName,
		RarityColor = UI.rgb(rarity.Color),
		Order = rarity.Order,
		Rarity = cfg.Rarity,
		Stat = Calc.DescribeItem(itemId, level or 1),
	}
end

local function playOne(result)
	playing = true
	for _, child in ipairs(resultHolder:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local infos = {}
	for _, pet in ipairs(result.Pets or {}) do
		if Config.Pets[pet.Id] then
			table.insert(infos, petInfo(pet.Id))
		end
	end
	for _, item in ipairs(result.Items or {}) do
		if Config.Items[item.Id] then
			table.insert(infos, itemInfo(item.Id, item.Level))
		end
	end
	local best = infos[1]
	for _, info in ipairs(infos) do
		if info.Order > best.Order then
			best = info
		end
	end
	if not best then
		playing = false
		return
	end

	local isCrate = result.Crate ~= nil
	local eggCfg = result.EggId and Config.Eggs[result.EggId]
	local eggColor = eggCfg and UI.rgb(eggCfg.Color) or Color3.fromRGB(200, 150, 255)

	overlay.Visible = true
	hintLabel.Visible = false
	bestLabel.Text = ""
	eggLabel.Visible = true
	eggGlow.Visible = true
	eggLabel.Text = isCrate and "🎁" or "🥚"
	eggLabel.Rotation = 0
	eggGlow.BackgroundColor3 = eggColor
	eggGlow.BackgroundTransparency = 0.7
	eggScale.Scale = 0.4
	rays.Visible = true
	rays.Rotation = 0
	for _, ray in ipairs(rays:GetChildren()) do
		if ray:IsA("Frame") then
			ray.BackgroundColor3 = eggColor
			ray.BackgroundTransparency = 0.88
		end
	end
	TweenService:Create(eggScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

	-- Strahlen drehen sich die ganze Zeit
	local spin = RunService.RenderStepped:Connect(function(dt)
		rays.Rotation = (rays.Rotation + dt * 25) % 360
	end)

	-- Wackeln, immer schneller; das Leuchten wird staerker (seltener = laenger)
	local shakes = { 0.16, 0.14, 0.12, 0.1, 0.08, 0.07, 0.06, 0.05 }
	if best.Order >= 5 then
		table.insert(shakes, 0.05)
		table.insert(shakes, 0.04)
		table.insert(shakes, 0.04)
	end
	for i, duration in ipairs(shakes) do
		local angle = (i % 2 == 0) and 16 or -16
		TweenService:Create(eggLabel, TweenInfo.new(duration), { Rotation = angle }):Play()
		eggGlow.BackgroundTransparency = 0.7 - (i / #shakes) * 0.45
		task.wait(duration)
	end
	-- Aufblitzen in der Farbe der besten Seltenheit
	ctx.PlaySound("Hatch")
	flash.BackgroundColor3 = best.RarityColor
	flash.BackgroundTransparency = best.Order >= 4 and 0.1 or 0.5
	TweenService:Create(flash, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
	TweenService:Create(eggScale, TweenInfo.new(0.15), { Scale = 1.7 }):Play()
	task.wait(0.15)
	eggLabel.Visible = false
	eggGlow.Visible = false
	for _, ray in ipairs(rays:GetChildren()) do
		if ray:IsA("Frame") then
			ray.BackgroundColor3 = best.RarityColor
			ray.BackgroundTransparency = best.Order >= 4 and 0.55 or 0.78
		end
	end
	raysScale.Scale = raysScale.Scale * 0.6
	TweenService:Create(raysScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = raysScale.Scale / 0.6 }):Play()

	for i, info in ipairs(infos) do
		makeCard(i, info)
	end
	if best.Order >= 3 then
		bestLabel.Text = string.upper(best.RarityName) .. "!" .. (best.Order >= 5 and "!!" or "")
		bestLabel.TextColor3 = best.RarityColor
		local s = Create("UIScale", { Scale = 0.3, Parent = bestLabel })
		TweenService:Create(s, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		task.delay(3, function()
			s:Destroy()
		end)
	end
	confetti(best.RarityColor, best.Order >= 5 and 70 or (best.Order >= 3 and 40 or 18))
	ctx.PlaySound("Popup", best.Order >= 4 and 1.4 or 1)
	if best.Order >= 5 then
		ctx.Hud.Popup(string.upper(best.RarityName) .. "!!!", "Incredible luck!", Config.Rarities[best.Rarity].Color)
	end
	task.wait(0.6)
	hintLabel.Visible = true

	-- automatisch schliessen
	local closeAt = os.clock() + (best.Order >= 4 and 4 or 3)
	while overlay.Visible and os.clock() < closeAt do
		task.wait(0.1)
	end
	spin:Disconnect()
	overlay.Visible = false
	playing = false
	if #queue > 0 then
		local nextResult = table.remove(queue, 1)
		task.spawn(playOne, nextResult)
	end
end

function Hatch.Play(result)
	if type(result) ~= "table" or (type(result.Pets) ~= "table" and type(result.Items) ~= "table") then
		return
	end
	if playing then
		if #queue < 3 then
			table.insert(queue, result)
		end
		return
	end
	task.spawn(playOne, result)
end

function Hatch.Init(context)
	ctx = context
	UI = ctx.UI
	Config = ctx.Config
	Calc = ctx.Calc
	Create = UI.Create
	build()
	overlay.Activated:Connect(function()
		if hintLabel.Visible then
			overlay.Visible = false
		end
	end)
end

return Hatch
