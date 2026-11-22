--[[
	UI: kleine UI-Bibliothek (Farben, Bausteine, animierte Buttons, Fenster).
]]

local TweenService = game:GetService("TweenService")

local UI = {}

UI.Colors = {
	Pink = Color3.fromRGB(255, 105, 180),
	PinkDark = Color3.fromRGB(200, 60, 140),
	Purple = Color3.fromRGB(150, 90, 255),
	Dark = Color3.fromRGB(38, 22, 50),
	Darker = Color3.fromRGB(26, 14, 36),
	Panel = Color3.fromRGB(62, 36, 82),
	PanelLight = Color3.fromRGB(85, 52, 110),
	Green = Color3.fromRGB(60, 200, 100),
	GreenDark = Color3.fromRGB(30, 140, 70),
	Gray = Color3.fromRGB(115, 110, 125),
	Gold = Color3.fromRGB(255, 200, 50),
	Blue = Color3.fromRGB(70, 170, 255),
	Red = Color3.fromRGB(230, 70, 90),
	White = Color3.fromRGB(255, 255, 255),
	Text = Color3.fromRGB(245, 235, 255),
	SubText = Color3.fromRGB(205, 180, 225),
}

UI.Font = Enum.Font.FredokaOne
UI.BodyFont = Enum.Font.GothamBold

function UI.rgb(t)
	return Color3.fromRGB(t[1], t[2], t[3])
end

function UI.Create(className, props, children)
	local instance = Instance.new(className)
	local parent = nil
	if props then
		for key, value in pairs(props) do
			if key == "Parent" then
				parent = value
			else
				instance[key] = value
			end
		end
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = instance
		end
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end
local Create = UI.Create

function UI.Corner(radius)
	return Create("UICorner", { CornerRadius = UDim.new(0, radius or 12) })
end

function UI.Stroke(thickness, color, transparency)
	return Create("UIStroke", {
		Thickness = thickness or 2,
		Color = color or Color3.fromRGB(20, 8, 28),
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function UI.TextStroke(thickness)
	return Create("UIStroke", {
		Thickness = thickness or 2,
		Color = Color3.fromRGB(20, 8, 28),
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
	})
end

function UI.Padding(all, top)
	return Create("UIPadding", {
		PaddingLeft = UDim.new(0, all),
		PaddingRight = UDim.new(0, all),
		PaddingTop = UDim.new(0, top or all),
		PaddingBottom = UDim.new(0, top or all),
	})
end

function UI.Gradient(top, bottom)
	return Create("UIGradient", {
		Color = ColorSequence.new(top, bottom),
		Rotation = 90,
	})
end

function UI.List(padding, horizontal, align)
	return Create("UIListLayout", {
		Padding = UDim.new(0, padding or 6),
		FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})
end

function UI.Label(props)
	local defaults = {
		BackgroundTransparency = 1,
		Font = UI.Font,
		TextScaled = true,
		TextColor3 = UI.Colors.Text,
		Text = "",
	}
	for k, v in pairs(props) do
		defaults[k] = v
	end
	return Create("TextLabel", defaults)
end

local function lighten(color, amount)
	return Color3.new(
		math.clamp(color.R + amount, 0, 1),
		math.clamp(color.G + amount, 0, 1),
		math.clamp(color.B + amount, 0, 1)
	)
end
UI.Lighten = lighten

-- Setzt die Farbe eines mit UI.Button gebauten Knopfes
function UI.SetButtonColor(button, color)
	button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	local gradient = button:FindFirstChild("ButtonGradient")
	if gradient then
		gradient.Color = ColorSequence.new(lighten(color, 0.12), color)
	end
end

-- Animierter Knopf. onClick wird bei Klick/Tap aufgerufen.
function UI.Button(props, onClick)
	local color = props.Color or UI.Colors.Pink
	local button = Create("TextButton", {
		Name = props.Name or "Button",
		Size = props.Size or UDim2.new(0, 120, 0, 44),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.new(),
		LayoutOrder = props.LayoutOrder or 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		AutoButtonColor = false,
		Font = UI.Font,
		TextScaled = true,
		TextColor3 = UI.Colors.White,
		Text = props.Text or "",
		ZIndex = props.ZIndex or 1,
		Parent = props.Parent,
	}, {
		UI.Corner(props.Radius or 12),
		UI.Stroke(props.StrokeThickness or 2.5),
		Create("UIGradient", { Name = "ButtonGradient", Color = ColorSequence.new(lighten(color, 0.12), color), Rotation = 90 }),
		UI.Padding(props.Padding or 6, props.PaddingY or 4),
		UI.TextStroke(1.5),
	})
	local scale = Create("UIScale", { Scale = 1, Parent = button })

	local hoverInfo = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	button.MouseEnter:Connect(function()
		TweenService:Create(scale, hoverInfo, { Scale = 1.06 }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(scale, hoverInfo, { Scale = 1 }):Play()
	end)
	button.MouseButton1Down:Connect(function()
		TweenService:Create(scale, hoverInfo, { Scale = 0.93 }):Play()
	end)
	button.MouseButton1Up:Connect(function()
		TweenService:Create(scale, hoverInfo, { Scale = 1.03 }):Play()
	end)
	if onClick then
		button.Activated:Connect(function()
			onClick(button)
		end)
	end
	return button
end

-- Fortschrittsbalken. Gibt Hintergrund und Fuellung zurueck.
function UI.ProgressBar(props)
	local back = Create("Frame", {
		Name = props.Name or "Progress",
		Size = props.Size or UDim2.new(1, 0, 0, 12),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.new(),
		LayoutOrder = props.LayoutOrder or 0,
		BackgroundColor3 = UI.Colors.Darker,
		BorderSizePixel = 0,
		Parent = props.Parent,
	}, { UI.Corner(props.Radius or 6), UI.Stroke(1.5) })
	local fill = Create("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Parent = back,
	}, {
		UI.Corner(props.Radius or 6),
		UI.Gradient(lighten(props.Color or UI.Colors.Pink, 0.15), props.Color or UI.Colors.Pink),
	})
	return back, fill
end

function UI.SetProgress(fill, ratio)
	if ratio ~= ratio then
		ratio = 0
	end
	fill.Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1)
end

--------------------------------------------------------------------------
-- Fenster
--------------------------------------------------------------------------
UI.Windows = {}
UI.OpenWindow = nil
UI.OnWindowOpened = nil -- function(name)

function UI.CreateWindow(screen, name, title, icon, size)
	local width = size and size.X or 560
	local height = size and size.Y or 440
	local window = Create("Frame", {
		Name = name .. "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.53),
		Size = UDim2.new(0.94, 0, 0.8, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Visible = false,
		ZIndex = 5,
		Parent = screen,
	}, {
		UI.Corner(20),
		UI.Stroke(4, UI.Colors.Pink),
		UI.Gradient(UI.Colors.Dark, UI.Colors.Darker),
		Create("UISizeConstraint", { MaxSize = Vector2.new(width, height) }),
	})
	local scale = Create("UIScale", { Scale = 1, Parent = window })

	local titleBar = Create("Frame", {
		Name = "TitleBar",
		Size = UDim2.new(1, 0, 0, 54),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		ZIndex = 5,
		Parent = window,
	}, {
		UI.Corner(20),
		UI.Gradient(UI.Colors.Pink, UI.Colors.PinkDark),
	})
	-- untere Ecken der Titelleiste eckig machen
	Create("Frame", {
		Name = "Filler",
		Position = UDim2.new(0, 0, 1, -18),
		Size = UDim2.new(1, 0, 0, 18),
		BorderSizePixel = 0,
		BackgroundColor3 = UI.Colors.PinkDark,
		ZIndex = 5,
		Parent = titleBar,
	})
	local titleLabel = UI.Label({
		Name = "Title",
		Position = UDim2.new(0, 16, 0, 7),
		Size = UDim2.new(1, -80, 0, 40),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = icon .. "  " .. title,
		ZIndex = 6,
		Parent = titleBar,
	})
	UI.TextStroke(2).Parent = titleLabel

	local content = Create("Frame", {
		Name = "Content",
		Position = UDim2.new(0, 12, 0, 62),
		Size = UDim2.new(1, -24, 1, -72),
		BackgroundTransparency = 1,
		ZIndex = 5,
		Parent = window,
	})

	local entry = { Name = name, Frame = window, Content = content, Scale = scale, Refresh = nil }

	UI.Button({
		Name = "Close",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 8),
		Size = UDim2.new(0, 40, 0, 38),
		Color = UI.Colors.Red,
		Text = "X",
		ZIndex = 7,
		Parent = window,
	}, function()
		UI.Close(name)
	end)

	UI.Windows[name] = entry
	return entry
end

function UI.Close(name)
	local entry = UI.Windows[name]
	if entry and entry.Frame.Visible then
		entry.Frame.Visible = false
		if UI.OpenWindow == name then
			UI.OpenWindow = nil
		end
	end
end

function UI.Open(name)
	local entry = UI.Windows[name]
	if not entry then
		return
	end
	if UI.OpenWindow and UI.OpenWindow ~= name then
		UI.Close(UI.OpenWindow)
	end
	UI.OpenWindow = name
	entry.Frame.Visible = true
	entry.Scale.Scale = 0.85
	TweenService:Create(entry.Scale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	if entry.Refresh then
		entry.Refresh()
	end
	if UI.OnWindowOpened then
		UI.OnWindowOpened(name)
	end
end

function UI.Toggle(name)
	if UI.OpenWindow == name then
		UI.Close(name)
	else
		UI.Open(name)
	end
end

-- Scroll-Liste fuer Fenster-Inhalte
function UI.ScrollList(parent, props)
	props = props or {}
	local scroll = Create("ScrollingFrame", {
		Name = props.Name or "List",
		Position = props.Position or UDim2.new(),
		Size = props.Size or UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = UI.Colors.Pink,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ZIndex = 5,
		Parent = parent,
	}, {
		UI.Padding(4, 4),
	})
	if props.Grid then
		Create("UIGridLayout", {
			CellSize = props.Grid,
			CellPadding = UDim2.new(0, 8, 0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = scroll,
		})
	else
		Create("UIListLayout", {
			Padding = UDim.new(0, props.Padding or 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = scroll,
		})
	end
	return scroll
end

-- Zeile in einer Liste
function UI.Row(parent, height, order)
	return Create("Frame", {
		Name = "Row",
		Size = UDim2.new(1, -10, 0, height),
		LayoutOrder = order or 0,
		BackgroundColor3 = UI.Colors.Panel,
		ZIndex = 5,
		Parent = parent,
	}, { UI.Corner(14), UI.Stroke(2, UI.Colors.PanelLight) })
end

return UI
