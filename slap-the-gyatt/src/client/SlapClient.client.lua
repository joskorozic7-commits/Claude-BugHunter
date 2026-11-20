--[[
	SlapClient (LocalScript in StarterPlayer > StarterPlayerScripts)

	Die komplette Benutzeroberflaeche:
	  * Anzeige von Slaps, Schaden und Rebirths
	  * Upgrade-Shop fuer die Hand
	  * Rebirth-Fenster
	  * Schadenszahlen und Nachrichten
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Config = require(ReplicatedStorage:WaitForChild("SlapConfig"))
local remotes = ReplicatedStorage:WaitForChild("SlapRemotes")
local StateUpdate = remotes:WaitForChild("StateUpdate")
local RequestState = remotes:WaitForChild("RequestState")
local BuyUpgrade = remotes:WaitForChild("BuyUpgrade")
local DoRebirth = remotes:WaitForChild("DoRebirth")
local SlapFx = remotes:WaitForChild("SlapFx")
local Notify = remotes:WaitForChild("Notify")

local state = nil -- letzter Spielstand vom Server

--------------------------------------------------------------------------
-- UI-Hilfen
--------------------------------------------------------------------------
local function create(className, props, children)
	local instance = Instance.new(className)
	local parent = nil
	for key, value in pairs(props or {}) do
		if key == "Parent" then
			parent = value
		else
			instance[key] = value
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = instance
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

local function corner(radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius or 12) })
end

local function stroke(thickness, color)
	return create("UIStroke", {
		Thickness = thickness or 3,
		Color = color or Color3.fromRGB(40, 20, 40),
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function rgb(t)
	return Color3.fromRGB(t[1], t[2], t[3])
end

local PINK = Color3.fromRGB(255, 110, 180)
local DARK = Color3.fromRGB(45, 25, 55)
local GREEN = Color3.fromRGB(70, 200, 100)
local GRAY = Color3.fromRGB(120, 120, 130)
local GOLD = Color3.fromRGB(255, 200, 60)

-- Alte UI entfernen (falls das Skript neu gestartet wurde)
local old = playerGui:FindFirstChild("SlapUI")
if old then
	old:Destroy()
end

local screen = create("ScreenGui", {
	Name = "SlapUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = playerGui,
})

--------------------------------------------------------------------------
-- Oben: Slaps-Anzeige
--------------------------------------------------------------------------
local topBar = create("Frame", {
	Name = "TopBar",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 8),
	Size = UDim2.new(0, 320, 0, 70),
	BackgroundColor3 = DARK,
	BackgroundTransparency = 0.1,
	Parent = screen,
}, { corner(16), stroke(3, PINK) })

local slapsLabel = create("TextLabel", {
	Name = "Slaps",
	Size = UDim2.new(1, -16, 0.6, 0),
	Position = UDim2.new(0, 8, 0, 2),
	BackgroundTransparency = 1,
	Font = Enum.Font.FredokaOne,
	TextScaled = true,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	Text = "👋 Laden...",
	Parent = topBar,
})

local statsLabel = create("TextLabel", {
	Name = "Stats",
	Size = UDim2.new(1, -16, 0.35, 0),
	Position = UDim2.new(0, 8, 0.6, 0),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextScaled = true,
	TextColor3 = Color3.fromRGB(255, 190, 225),
	Text = "",
	Parent = topBar,
})

--------------------------------------------------------------------------
-- Links: Knoepfe
--------------------------------------------------------------------------
local buttonColumn = create("Frame", {
	Name = "Buttons",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 10, 0.5, 0),
	Size = UDim2.new(0, 130, 0, 130),
	BackgroundTransparency = 1,
	Parent = screen,
}, {
	create("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

local function makeSideButton(text, color, order)
	return create("TextButton", {
		Size = UDim2.new(1, 0, 0, 55),
		LayoutOrder = order,
		BackgroundColor3 = color,
		Font = Enum.Font.FredokaOne,
		TextScaled = true,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Text = text,
		AutoButtonColor = true,
		Parent = buttonColumn,
	}, { corner(14), stroke(3), create("UIPadding", {
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
	}) })
end

local shopButton = makeSideButton("🛒 Shop", PINK, 1)
local rebirthButton = makeSideButton("♻️ Rebirth", Color3.fromRGB(150, 90, 255), 2)

--------------------------------------------------------------------------
-- Fenster-Vorlage
--------------------------------------------------------------------------
local openWindow = nil

local function makeWindow(name, title, height)
	local window = create("Frame", {
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.new(0.9, 0, 0, height),
		BackgroundColor3 = DARK,
		Visible = false,
		Parent = screen,
	}, {
		corner(18),
		stroke(4, PINK),
		create("UISizeConstraint", { MaxSize = Vector2.new(520, height) }),
	})

	create("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -70, 0, 44),
		Position = UDim2.new(0, 14, 0, 8),
		BackgroundTransparency = 1,
		Font = Enum.Font.FredokaOne,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Text = title,
		Parent = window,
	})

	local close = create("TextButton", {
		Name = "Close",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 10),
		Size = UDim2.new(0, 40, 0, 40),
		BackgroundColor3 = Color3.fromRGB(230, 70, 90),
		Font = Enum.Font.FredokaOne,
		TextScaled = true,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Text = "X",
		Parent = window,
	}, { corner(10), stroke(2) })

	close.Activated:Connect(function()
		window.Visible = false
		if openWindow == window then
			openWindow = nil
		end
	end)

	return window
end

local function toggleWindow(window)
	if openWindow and openWindow ~= window then
		openWindow.Visible = false
	end
	window.Visible = not window.Visible
	if window.Visible then
		openWindow = window
	else
		openWindow = nil
	end
end

--------------------------------------------------------------------------
-- Shop
--------------------------------------------------------------------------
local shopWindow = makeWindow("ShopWindow", "🛒 Hand-Upgrades", 430)

local handInfo = create("TextLabel", {
	Name = "HandInfo",
	Size = UDim2.new(1, -28, 0, 26),
	Position = UDim2.new(0, 14, 0, 54),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = GOLD,
	Text = "",
	Parent = shopWindow,
})

local list = create("ScrollingFrame", {
	Name = "List",
	Size = UDim2.new(1, -20, 1, -96),
	Position = UDim2.new(0, 10, 0, 86),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 8,
	ScrollBarImageColor3 = PINK,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	Parent = shopWindow,
}, {
	create("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
	create("UIPadding", {
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 2),
		PaddingBottom = UDim.new(0, 2),
		PaddingLeft = UDim.new(0, 2),
	}),
})

local rows = {} -- [upgradeId] = { Level=, Stat=, Buy= }

for order, id in ipairs(Config.UpgradeOrder) do
	local upgrade = Config.Upgrades[id]
	local row = create("Frame", {
		Name = id,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 78),
		BackgroundColor3 = Color3.fromRGB(70, 40, 85),
		Parent = list,
	}, { corner(12) })

	create("TextLabel", {
		Name = "Name",
		Size = UDim2.new(0.62, -10, 0, 28),
		Position = UDim2.new(0, 10, 0, 4),
		BackgroundTransparency = 1,
		Font = Enum.Font.FredokaOne,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Text = upgrade.Icon .. " " .. upgrade.DisplayName,
		Parent = row,
	})

	local levelLabel = create("TextLabel", {
		Name = "Level",
		Size = UDim2.new(0.62, -10, 0, 18),
		Position = UDim2.new(0, 10, 0, 32),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(255, 190, 225),
		Text = "",
		Parent = row,
	})

	local statLabel = create("TextLabel", {
		Name = "Stat",
		Size = UDim2.new(0.62, -10, 0, 18),
		Position = UDim2.new(0, 10, 0, 53),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(220, 220, 230),
		Text = upgrade.Description,
		Parent = row,
	})

	local buy = create("TextButton", {
		Name = "Buy",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0.36, 0, 0, 56),
		BackgroundColor3 = GRAY,
		Font = Enum.Font.FredokaOne,
		TextScaled = true,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Text = "...",
		Parent = row,
	}, { corner(10), stroke(2), create("UIPadding", {
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
	}) })

	buy.Activated:Connect(function()
		BuyUpgrade:FireServer(id)
	end)

	rows[id] = { Level = levelLabel, Stat = statLabel, Buy = buy }
end

--------------------------------------------------------------------------
-- Rebirth-Fenster
--------------------------------------------------------------------------
local rebirthWindow = makeWindow("RebirthWindow", "♻️ Rebirth", 290)

local rebirthText = create("TextLabel", {
	Name = "Info",
	Size = UDim2.new(1, -28, 0, 130),
	Position = UDim2.new(0, 14, 0, 58),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextScaled = true,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextColor3 = Color3.fromRGB(240, 230, 255),
	Text = "",
	Parent = rebirthWindow,
})

local rebirthConfirm = create("TextButton", {
	Name = "Confirm",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -14),
	Size = UDim2.new(0.8, 0, 0, 60),
	BackgroundColor3 = GRAY,
	Font = Enum.Font.FredokaOne,
	TextScaled = true,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	Text = "Rebirth!",
	Parent = rebirthWindow,
}, { corner(12), stroke(3), create("UIPadding", {
	PaddingTop = UDim.new(0, 6),
	PaddingBottom = UDim.new(0, 6),
}) })

rebirthConfirm.Activated:Connect(function()
	DoRebirth:FireServer()
end)

shopButton.Activated:Connect(function()
	toggleWindow(shopWindow)
end)
rebirthButton.Activated:Connect(function()
	toggleWindow(rebirthWindow)
end)

--------------------------------------------------------------------------
-- UI aktualisieren
--------------------------------------------------------------------------
local function refresh()
	if not state then
		return
	end
	local upgrades = state.Upgrades or {}
	local multiplier = Config.GetGreedMultiplier(upgrades.Greed) * Config.GetRebirthMultiplier(state.Rebirths)

	slapsLabel.Text = "👋 " .. Config.FormatNumber(state.Slaps) .. " Slaps"
	statsLabel.Text = "💪 " .. Config.FormatNumber(Config.GetDamage(upgrades.Power)) .. " Schaden   💰 x"
		.. string.format("%.2f", multiplier) .. "   ♻️ " .. tostring(state.Rebirths)

	local tier = Config.GetHandTier(upgrades.Power)
	handInfo.Text = "Deine Hand: " .. tier.Name
	handInfo.TextColor3 = rgb(tier.Color)

	for _, id in ipairs(Config.UpgradeOrder) do
		local row = rows[id]
		local upgrade = Config.Upgrades[id]
		local level = Config.ClampLevel(id, upgrades[id])
		local cost = Config.GetUpgradeCost(id, level)
		row.Level.Text = "Level " .. level .. " / " .. upgrade.MaxLevel
		if cost then
			row.Stat.Text = Config.DescribeStat(id, level) .. "  ➜  " .. Config.DescribeStat(id, level + 1)
			row.Buy.Text = "👋 " .. Config.FormatNumber(cost)
			if state.Slaps >= cost then
				row.Buy.BackgroundColor3 = GREEN
			else
				row.Buy.BackgroundColor3 = GRAY
			end
		else
			row.Stat.Text = Config.DescribeStat(id, level)
			row.Buy.Text = "MAX"
			row.Buy.BackgroundColor3 = GOLD
		end
	end

	local rebirthCost = Config.GetRebirthCost(state.Rebirths)
	local nextMultiplier = Config.GetRebirthMultiplier(state.Rebirths + 1)
	rebirthText.Text = "Setzt deine Slaps und alle Hand-Upgrades zurueck.\n\n"
		.. "Dafuer bekommst du fuer immer x" .. string.format("%.1f", nextMultiplier) .. " Slaps!\n\n"
		.. "Kosten: " .. Config.FormatNumber(rebirthCost) .. " Slaps"
	if state.Slaps >= rebirthCost then
		rebirthConfirm.BackgroundColor3 = GREEN
		rebirthConfirm.Text = "♻️ Rebirth machen!"
	else
		rebirthConfirm.BackgroundColor3 = GRAY
		rebirthConfirm.Text = "Noch " .. Config.FormatNumber(rebirthCost - state.Slaps) .. " Slaps"
	end
end

local lastSlaps = nil
StateUpdate.OnClientEvent:Connect(function(newState)
	if type(newState) ~= "table" then
		return
	end
	state = newState
	refresh()

	-- Slaps-Zahl kurz "aufpoppen" lassen, wenn sie steigt
	if lastSlaps and state.Slaps > lastSlaps then
		slapsLabel.TextColor3 = Color3.fromRGB(150, 255, 160)
		TweenService:Create(slapsLabel, TweenInfo.new(0.35), { TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
	end
	lastSlaps = state.Slaps
end)

--------------------------------------------------------------------------
-- Nachrichten (unten in der Mitte)
--------------------------------------------------------------------------
local notifyHolder = create("Frame", {
	Name = "Notifications",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -100),
	Size = UDim2.new(0.8, 0, 0, 150),
	BackgroundTransparency = 1,
	Parent = screen,
}, {
	create("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}),
	create("UISizeConstraint", { MaxSize = Vector2.new(600, 150) }),
})

local notifyCounter = 0
Notify.OnClientEvent:Connect(function(text, color)
	if type(text) ~= "string" then
		return
	end
	local textColor = Color3.fromRGB(255, 255, 255)
	if type(color) == "table" and #color == 3 then
		textColor = rgb(color)
	end
	notifyCounter = notifyCounter + 1

	-- maximal 4 Nachrichten gleichzeitig
	local existing = {}
	for _, child in ipairs(notifyHolder:GetChildren()) do
		if child:IsA("TextLabel") then
			table.insert(existing, child)
		end
	end
	table.sort(existing, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	while #existing >= 4 do
		table.remove(existing, 1):Destroy()
	end

	local label = create("TextLabel", {
		LayoutOrder = notifyCounter,
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = DARK,
		BackgroundTransparency = 0.25,
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextColor3 = textColor,
		TextStrokeTransparency = 0.5,
		Text = text,
		Parent = notifyHolder,
	}, { corner(8), create("UIPadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
	}) })

	task.delay(3.5, function()
		if label.Parent then
			local fade = TweenService:Create(label, TweenInfo.new(0.5), {
				TextTransparency = 1,
				TextStrokeTransparency = 1,
				BackgroundTransparency = 1,
			})
			fade:Play()
			task.delay(0.55, function()
				label:Destroy()
			end)
		end
	end)
end)

--------------------------------------------------------------------------
-- Schadenszahlen ueber dem Gyatt
--------------------------------------------------------------------------
-- Attachments im Terrain dienen als unsichtbare Ankerpunkte (nur lokal)
local fxAnchor = workspace.Terrain

SlapFx.OnClientEvent:Connect(function(position, radius, damage, isCrit, reward, slapperId)
	if typeof(position) ~= "Vector3" or type(damage) ~= "number" then
		return
	end
	radius = type(radius) == "number" and radius or 3
	local isMine = slapperId == player.UserId

	-- Zahlen von anderen Spielern kleiner und blasser anzeigen
	local attachment = Instance.new("Attachment")
	local offset = Vector3.new((math.random() - 0.5) * radius, radius * 0.4 + math.random() * radius * 0.5, -radius - 0.5)
	attachment.Parent = fxAnchor
	attachment.WorldPosition = position + offset

	local text = "-" .. Config.FormatNumber(damage)
	if isCrit then
		text = "💥 KRIT " .. text
	end
	if isMine and type(reward) == "number" then
		text = text .. "\n+" .. Config.FormatNumber(reward) .. " 👋"
	end

	local size = isMine and 5 or 3
	if isCrit then
		size = size * 1.4
	end

	local billboard = create("BillboardGui", {
		Adornee = attachment,
		Size = UDim2.new(size * 1.6, 0, size, 0),
		AlwaysOnTop = true,
		LightInfluence = 0,
		MaxDistance = 200,
		Parent = attachment,
	})
	local label = create("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.FredokaOne,
		TextScaled = true,
		TextColor3 = isCrit and GOLD or Color3.fromRGB(255, 255, 255),
		TextStrokeTransparency = 0,
		TextTransparency = isMine and 0 or 0.4,
		Text = text,
		Parent = billboard,
	})

	local rise = TweenService:Create(billboard, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffset = Vector3.new(0, 3, 0),
	})
	local fade = TweenService:Create(label, TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0.4), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	rise:Play()
	fade:Play()
	task.delay(1, function()
		attachment:Destroy()
	end)
end)

--------------------------------------------------------------------------
-- Start
--------------------------------------------------------------------------
RequestState:FireServer()
