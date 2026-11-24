--[[
	Hud: alles, was immer auf dem Bildschirm ist.
	  Geld-Anzeige, Combo, Boosts, Event-Banner, Menue-Knoepfe,
	  Auto-Slap-Schalter, Zonen-Anzeige, Nachrichten, Popups.
]]

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Hud = {}
local ctx, UI, Config, Calc, Create

local slapsLabel, gemsLabel, multiLabel, hintLabel
local comboFrame, comboLabel, comboFill
local boostRow
local eventBanner, eventLabel
local notifyHolder
local popupFrame, popupTitle, popupSub, popupScale
local zoneLabel
local autoButton
local badges = {}

local comboValue = 0
local comboExpires = 0
local golden = { ZoneIndex = nil, EndsAt = 0 }
local notifyCounter = 0
local popupId = 0

--------------------------------------------------------------------------
-- Aufbau
--------------------------------------------------------------------------
local function buildTop(screen)
	local top = Create("Frame", {
		Name = "TopPanel",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		Size = UDim2.new(0, 360, 0, 86),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Parent = screen,
	}, {
		UI.Corner(18),
		UI.Stroke(3, UI.Colors.Pink),
		UI.Gradient(UI.Colors.Dark, UI.Colors.Darker),
	})

	slapsLabel = UI.Label({
		Name = "Slaps",
		Position = UDim2.new(0, 10, 0, 4),
		Size = UDim2.new(1, -20, 0, 40),
		Text = "👋 Loading...",
		Parent = top,
	})
	UI.TextStroke(2).Parent = slapsLabel

	gemsLabel = UI.Label({
		Name = "Gems",
		Position = UDim2.new(0, 10, 0, 44),
		Size = UDim2.new(0.45, -10, 0, 22),
		TextColor3 = Color3.fromRGB(140, 220, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "💎 0",
		Parent = top,
	})
	UI.TextStroke(1.5).Parent = gemsLabel

	multiLabel = UI.Label({
		Name = "Multi",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 44),
		Size = UDim2.new(0.55, -10, 0, 22),
		Font = UI.BodyFont,
		TextColor3 = UI.Colors.SubText,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = "",
		Parent = top,
	})

	hintLabel = UI.Label({
		Name = "Hint",
		Position = UDim2.new(0, 10, 0, 66),
		Size = UDim2.new(1, -20, 0, 16),
		Font = UI.BodyFont,
		TextColor3 = Color3.fromRGB(170, 140, 190),
		Text = "",
		Parent = top,
	})

	-- Combo
	comboFrame = Create("Frame", {
		Name = "Combo",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 98),
		Size = UDim2.new(0, 220, 0, 46),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = screen,
	})
	comboLabel = UI.Label({
		Size = UDim2.new(1, 0, 0, 32),
		TextColor3 = Color3.fromRGB(255, 160, 60),
		Text = "",
		Parent = comboFrame,
	})
	UI.TextStroke(2.5).Parent = comboLabel
	local _, fill = UI.ProgressBar({ Position = UDim2.new(0.1, 0, 0, 34), Size = UDim2.new(0.8, 0, 0, 8), Color = Color3.fromRGB(255, 140, 40), Parent = comboFrame })
	comboFill = fill

	-- Boosts
	boostRow = Create("Frame", {
		Name = "Boosts",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 148),
		Size = UDim2.new(0, 420, 0, 28),
		BackgroundTransparency = 1,
		Parent = screen,
	}, { UI.List(6, true, Enum.HorizontalAlignment.Center) })

	-- Event-Banner
	eventBanner = Create("Frame", {
		Name = "EventBanner",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 182),
		Size = UDim2.new(0, 420, 0, 40),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Visible = false,
		Parent = screen,
	}, {
		UI.Corner(12),
		UI.Stroke(3, Color3.fromRGB(255, 240, 150)),
		UI.Gradient(Color3.fromRGB(255, 210, 60), Color3.fromRGB(230, 150, 20)),
		Create("UISizeConstraint", { MaxSize = Vector2.new(420, 40) }),
	})
	eventLabel = UI.Label({ Size = UDim2.fromScale(1, 1), Text = "", Parent = eventBanner }, nil)
	UI.Padding(6, 4).Parent = eventLabel
	UI.TextStroke(2).Parent = eventLabel
end

local MENU_BUTTONS = {
	{ "Shop", "🛒", "Shop", { 255, 105, 180 } },
	{ "Hands", "✋", "Hands", { 255, 160, 60 } },
	{ "Pets", "🐾", "Pets", { 90, 200, 120 } },
	{ "Zones", "🗺️", "Zones", { 70, 170, 255 } },
	{ "Gems", "💎", "Gems", { 90, 210, 255 } },
	{ "Rebirth", "♻️", "Rebirth", { 160, 100, 255 } },
	{ "Quests", "📜", "Quests", { 255, 200, 60 } },
	{ "Daily", "🎁", "Daily", { 255, 90, 120 } },
	{ "Codes", "🎟️", "Codes", { 120, 120, 255 } },
	{ "Settings", "⚙️", "Settings", { 130, 130, 150 } },
}

local function buildMenuButtons(screen)
	local holder = Create("Frame", {
		Name = "MenuButtons",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 8, 0.5, 0),
		Size = UDim2.new(0, 132, 0, 330),
		BackgroundTransparency = 1,
		Parent = screen,
	}, {
		Create("UIGridLayout", {
			CellSize = UDim2.new(0, 62, 0, 60),
			CellPadding = UDim2.new(0, 6, 0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	for order, info in ipairs(MENU_BUTTONS) do
		local name, icon, label, color = info[1], info[2], info[3], info[4]
		local button = UI.Button({
			Name = name,
			LayoutOrder = order,
			Color = UI.rgb(color),
			Text = "",
			Padding = 2,
			PaddingY = 2,
			Parent = holder,
		}, function()
			UI.Toggle(name)
		end)
		UI.Label({ Size = UDim2.new(1, 0, 0.62, 0), Text = icon, Parent = button })
		local text = UI.Label({ Position = UDim2.new(0, 0, 0.62, 0), Size = UDim2.new(1, 0, 0.38, 0), Text = label, Parent = button })
		UI.TextStroke(1.5).Parent = text

		local badge = Create("TextLabel", {
			Name = "Badge",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(1, -4, 0, 4),
			Size = UDim2.new(0, 22, 0, 22),
			BackgroundColor3 = UI.Colors.Red,
			Font = UI.Font,
			TextScaled = true,
			TextColor3 = UI.Colors.White,
			Text = "!",
			Visible = false,
			ZIndex = 3,
			Parent = button,
		}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }), UI.Stroke(2, UI.Colors.White) })
		badges[name] = badge
	end
end

local function buildRightSide(screen)
	autoButton = UI.Button({
		Name = "AutoSlap",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, -40),
		Size = UDim2.new(0, 120, 0, 50),
		Color = UI.Colors.Gray,
		Text = "🤖 Auto: OFF",
		Parent = screen,
	}, function()
		ctx.Request("ToggleAutoSlap")
	end)
	autoButton.Visible = false
end

local function buildBottom(screen)
	zoneLabel = UI.Label({
		Name = "Zone",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.new(0, 360, 0, 26),
		TextColor3 = UI.Colors.White,
		Text = "📍 Hub",
		Parent = screen,
	})
	UI.TextStroke(2).Parent = zoneLabel

	notifyHolder = Create("Frame", {
		Name = "Notifications",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -40),
		Size = UDim2.new(0.8, 0, 0, 170),
		BackgroundTransparency = 1,
		Parent = screen,
	}, {
		Create("UIListLayout", {
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),
		Create("UISizeConstraint", { MaxSize = Vector2.new(620, 170) }),
	})

	popupFrame = Create("Frame", {
		Name = "Popup",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.36),
		Size = UDim2.new(0.8, 0, 0, 110),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 20,
		Parent = screen,
	}, { Create("UISizeConstraint", { MaxSize = Vector2.new(640, 110) }) })
	popupScale = Create("UIScale", { Scale = 1, Parent = popupFrame })
	popupTitle = UI.Label({ Size = UDim2.new(1, 0, 0, 64), Text = "", ZIndex = 20, Parent = popupFrame })
	UI.TextStroke(3.5).Parent = popupTitle
	popupSub = UI.Label({ Position = UDim2.new(0, 0, 0, 66), Size = UDim2.new(1, 0, 0, 34), TextColor3 = UI.Colors.White, Text = "", ZIndex = 20, Parent = popupFrame })
	UI.TextStroke(2.5).Parent = popupSub
end

--------------------------------------------------------------------------
-- Oeffentliche Funktionen
--------------------------------------------------------------------------
function Hud.Notify(text, color)
	if type(text) ~= "string" then
		return
	end
	local textColor = UI.Colors.White
	if type(color) == "table" and #color == 3 then
		textColor = UI.rgb(color)
	end
	notifyCounter = notifyCounter + 1

	local existing = {}
	for _, child in ipairs(notifyHolder:GetChildren()) do
		if child:IsA("TextLabel") then
			table.insert(existing, child)
		end
	end
	table.sort(existing, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	while #existing >= 5 do
		table.remove(existing, 1):Destroy()
	end

	local label = Create("TextLabel", {
		LayoutOrder = notifyCounter,
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = UI.Colors.Darker,
		BackgroundTransparency = 0.2,
		Font = UI.BodyFont,
		TextScaled = true,
		TextColor3 = textColor,
		Text = text,
		Parent = notifyHolder,
	}, { UI.Corner(10), UI.Padding(10, 4), UI.TextStroke(1.5) })
	local scale = Create("UIScale", { Scale = 0.6, Parent = label })
	TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

	task.delay(4, function()
		if label.Parent then
			TweenService:Create(label, TweenInfo.new(0.5), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
			task.delay(0.55, function()
				label:Destroy()
			end)
		end
	end)
end

function Hud.Popup(title, subtitle, color)
	popupId = popupId + 1
	local myId = popupId
	popupTitle.Text = tostring(title)
	popupSub.Text = tostring(subtitle or "")
	popupTitle.TextColor3 = (type(color) == "table" and #color == 3) and UI.rgb(color) or UI.Colors.White
	popupTitle.TextTransparency = 0
	popupSub.TextTransparency = 0
	popupFrame.Visible = true
	popupScale.Scale = 0.3
	TweenService:Create(popupScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(2.6, function()
		if popupId ~= myId then
			return
		end
		TweenService:Create(popupTitle, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		TweenService:Create(popupSub, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		task.delay(0.45, function()
			if popupId == myId then
				popupFrame.Visible = false
			end
		end)
	end)
end

function Hud.SetCombo(combo)
	combo = tonumber(combo) or 0
	comboValue = combo
	comboExpires = os.clock() + Config.ComboWindow
	if combo >= 2 then
		comboFrame.Visible = true
		comboLabel.Text = "🔥 " .. combo .. "x COMBO  +" .. math.floor(combo * Config.ComboBonusPerStack * 100 + 0.5) .. "%"
		local hue = math.clamp(0.12 - combo / 1000, 0, 0.12)
		comboLabel.TextColor3 = Color3.fromHSV(hue, 0.85, 1)
	end
end

function Hud.SetGoldenEvent(zoneIndex, endsAt)
	if zoneIndex then
		golden.ZoneIndex = zoneIndex
		golden.EndsAt = tonumber(endsAt) or 0
		eventBanner.Visible = true
	else
		golden.ZoneIndex = nil
		eventBanner.Visible = false
	end
end

function Hud.SetZone(index)
	if index == 0 then
		zoneLabel.Text = "📍 Hub - Spawn Area"
	else
		local zone = Config.Zones[index]
		zoneLabel.Text = "📍 Zone " .. index .. ": " .. (zone and zone.Name or "?")
	end
end

local function refreshBoosts(state)
	for _, child in ipairs(boostRow:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	if not state or type(state.Boosts) ~= "table" then
		return
	end
	local now = ctx.Now()
	for order, id in ipairs(Config.BoostOrder) do
		local expires = tonumber(state.Boosts[id]) or 0
		if expires > now then
			local boost = Config.Boosts[id]
			Create("TextLabel", {
				Name = id,
				LayoutOrder = order,
				Size = UDim2.new(0, 130, 1, 0),
				BackgroundColor3 = UI.Colors.Darker,
				BackgroundTransparency = 0.15,
				Font = UI.Font,
				TextScaled = true,
				TextColor3 = UI.rgb(boost.Color),
				Text = boost.Icon .. " " .. boost.DisplayName .. " " .. Calc.FormatTime(expires - now),
				Parent = boostRow,
			}, { UI.Corner(8), UI.Padding(6, 3), UI.Stroke(2, UI.rgb(boost.Color)) })
		end
	end
end

local function refreshBadges(state)
	if not state then
		return
	end
	local questReady = false
	if state.Quests and state.Quests.Day then
		local quests = Calc.GetQuests(state.Quests.Day, ctx.Player.UserId)
		for i, quest in ipairs(quests) do
			local progress = state.Quests.Progress and state.Quests.Progress[i] or 0
			local claimed = state.Quests.Claimed and state.Quests.Claimed[i]
			if not claimed and progress >= quest.Amount then
				questReady = true
			end
		end
	end
	badges.Quests.Visible = questReady
	local dailyReady = Calc.GetDailyStatus(state, ctx.Now())
	badges.Daily.Visible = dailyReady == true
	badges.Rebirth.Visible = (state.Slaps or 0) >= Calc.GetRebirthCost(state.Rebirths)
end

function Hud.Refresh(state)
	if not state then
		return
	end
	slapsLabel.Text = "👋 " .. Calc.FormatNumber(state.Slaps) .. " Slaps"
	gemsLabel.Text = "💎 " .. Calc.FormatNumber(state.Gems)
	if state.Upgrades then
		local now = ctx.Now()
		multiLabel.Text = "💪 " .. Calc.FormatNumber(Calc.GetDamage(state, now)) .. "   💰 " .. Calc.FormatMultiplier(Calc.GetSlapMultiplier(state, now))
	end
	local owned = state.GemShop and (state.GemShop.AutoSlap or 0) >= 1
	autoButton.Visible = owned == true
	if owned then
		autoButton.Text = state.AutoSlapOn and "🤖 Auto: ON" or "🤖 Auto: OFF"
		UI.SetButtonColor(autoButton, state.AutoSlapOn and UI.Colors.Green or UI.Colors.Gray)
	end
	refreshBadges(state)
	refreshBoosts(state)

	-- naechstes Ziel
	local zones = state.Zones or 1
	local nextZone = Config.Zones[zones + 1]
	if nextZone then
		hintLabel.Text = "🎯 Next goal: Zone " .. (zones + 1) .. " for " .. Calc.FormatNumber(nextZone.Price) .. " Slaps"
	else
		hintLabel.Text = "🎯 Next goal: Rebirth for " .. Calc.FormatNumber(Calc.GetRebirthCost(state.Rebirths)) .. " Slaps"
	end
end

local lastSlaps = nil
function Hud.Init(context)
	ctx = context
	UI = ctx.UI
	Config = ctx.Config
	Calc = ctx.Calc
	Create = UI.Create

	buildTop(ctx.Screen)
	buildMenuButtons(ctx.Screen)
	buildRightSide(ctx.Screen)
	buildBottom(ctx.Screen)

	ctx.OnState(function(state)
		Hud.Refresh(state)
		if lastSlaps and state.Slaps > lastSlaps then
			slapsLabel.TextColor3 = Color3.fromRGB(150, 255, 160)
			TweenService:Create(slapsLabel, TweenInfo.new(0.35), { TextColor3 = UI.Colors.White }):Play()
		end
		lastSlaps = state.Slaps
	end)

	-- Combo-Balken laufend leeren
	RunService.RenderStepped:Connect(function()
		if comboFrame.Visible then
			local remaining = comboExpires - os.clock()
			if remaining <= 0 then
				comboFrame.Visible = false
				comboValue = 0
			else
				UI.SetProgress(comboFill, remaining / Config.ComboWindow)
			end
		end
	end)

	-- Timer jede halbe Sekunde
	task.spawn(function()
		while true do
			task.wait(0.5)
			if golden.ZoneIndex then
				local remaining = golden.EndsAt - ctx.Now()
				if remaining < 0 then
					remaining = 0
				end
				eventLabel.Text = "⭐ GOLDEN BLOB in Zone " .. golden.ZoneIndex .. "!  " .. Calc.FormatTime(remaining)
			end
			if ctx.State then
				refreshBoosts(ctx.State)
				refreshBadges(ctx.State)
			end
		end
	end)
end

return Hud
