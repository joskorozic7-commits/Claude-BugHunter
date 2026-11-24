--[[
	Hatch: Ei-Oeffnen-Animation (Ei wackelt, knackt, Pets erscheinen).
]]

local TweenService = game:GetService("TweenService")

local Hatch = {}
local ctx, UI, Config, Calc, Create

local overlay, eggLabel, eggScale, resultHolder, hintLabel
local playing = false
local queue = {}

local function build()
	overlay = Create("TextButton", {
		Name = "HatchOverlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(10, 0, 20),
		BackgroundTransparency = 0.35,
		AutoButtonColor = false,
		Text = "",
		Visible = false,
		ZIndex = 50,
		Parent = ctx.Screen,
	})
	eggLabel = UI.Label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.new(0, 220, 0, 220),
		Text = "🥚",
		ZIndex = 51,
		Parent = overlay,
	})
	eggScale = Create("UIScale", { Scale = 1, Parent = eggLabel })
	resultHolder = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.new(0.9, 0, 0, 230),
		BackgroundTransparency = 1,
		ZIndex = 51,
		Parent = overlay,
	}, {
		Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 14),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	hintLabel = UI.Label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.72, 0),
		Size = UDim2.new(0.6, 0, 0, 28),
		Font = UI.BodyFont,
		TextColor3 = UI.Colors.SubText,
		Text = "Click to close",
		ZIndex = 51,
		Parent = overlay,
	})
end

local function card(petId, order)
	local cfg = Config.Pets[petId]
	local rarity = Config.Rarities[cfg.Rarity]
	local color = UI.rgb(rarity.Color)
	local frame = Create("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(0, 160, 0, 210),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		ZIndex = 52,
		Parent = resultHolder,
	}, {
		UI.Corner(18),
		UI.Stroke(4, color),
		UI.Gradient(UI.Colors.Panel, UI.Colors.Darker),
	})
	local scale = Create("UIScale", { Scale = 0.2, Parent = frame })
	local face = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 14),
		Size = UDim2.new(0, 86, 0, 86),
		BackgroundColor3 = UI.rgb(cfg.Color),
		ZIndex = 53,
		Parent = frame,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }), UI.Stroke(3) })
	UI.Label({ Size = UDim2.fromScale(1, 1), Text = "😊", ZIndex = 54, Parent = face })
	local name = UI.Label({ Position = UDim2.new(0, 6, 0, 108), Size = UDim2.new(1, -12, 0, 30), Text = cfg.DisplayName, ZIndex = 53, Parent = frame })
	UI.TextStroke(1.5).Parent = name
	local rarityLabel = UI.Label({ Position = UDim2.new(0, 6, 0, 140), Size = UDim2.new(1, -12, 0, 24), Text = rarity.DisplayName, TextColor3 = color, ZIndex = 53, Parent = frame })
	UI.TextStroke(1.5).Parent = rarityLabel
	UI.Label({ Position = UDim2.new(0, 6, 0, 168), Size = UDim2.new(1, -12, 0, 22), Font = UI.BodyFont, Text = "+" .. Calc.FormatNumber(math.floor(cfg.Boost * 100)) .. "% Slaps", TextColor3 = UI.Colors.Gold, ZIndex = 53, Parent = frame })
	TweenService:Create(scale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	return frame
end

local function playOne(result)
	playing = true
	for _, child in ipairs(resultHolder:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	overlay.Visible = true
	hintLabel.Visible = false
	eggLabel.Visible = true
	eggLabel.Rotation = 0
	eggScale.Scale = 0.5
	TweenService:Create(eggScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

	-- Wackeln, immer schneller
	local shakes = { 0.16, 0.14, 0.12, 0.1, 0.08, 0.07, 0.06, 0.05 }
	for i, duration in ipairs(shakes) do
		local angle = (i % 2 == 0) and 18 or -18
		TweenService:Create(eggLabel, TweenInfo.new(duration), { Rotation = angle }):Play()
		task.wait(duration)
	end
	ctx.PlaySound("Hatch")
	TweenService:Create(eggScale, TweenInfo.new(0.15), { Scale = 1.6 }):Play()
	task.wait(0.15)
	eggLabel.Visible = false

	local best = "Common"
	for i, pet in ipairs(result.Pets or {}) do
		if Config.Pets[pet.Id] then
			card(pet.Id, i)
			local rarity = Config.Pets[pet.Id].Rarity
			if Config.Rarities[rarity].Order > Config.Rarities[best].Order then
				best = rarity
			end
		end
	end
	ctx.PlaySound("Popup", (best == "Legendary" or best == "Mythic") and 1.4 or 1)
	if best == "Legendary" or best == "Mythic" then
		ctx.Hud.Popup(string.upper(Config.Rarities[best].DisplayName) .. "!!!", "What luck!", Config.Rarities[best].Color)
	end
	hintLabel.Visible = true

	-- automatisch schliessen
	local closeAt = os.clock() + 3
	while overlay.Visible and os.clock() < closeAt do
		task.wait(0.1)
	end
	overlay.Visible = false
	playing = false
	if #queue > 0 then
		local nextResult = table.remove(queue, 1)
		task.spawn(playOne, nextResult)
	end
end

function Hatch.Play(result)
	if type(result) ~= "table" or type(result.Pets) ~= "table" then
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
