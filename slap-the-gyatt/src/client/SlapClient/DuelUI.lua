--[[
	DuelUI: Anzeige waehrend eines Duells.
	  Lebensbalken beider Spieler, Timer, grosser Countdown,
	  Dash-Knopf (Taste Q) und Ergebnis.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local DuelUI = {}
local ctx, UI, Config, Create

local player = Players.LocalPlayer
local frame, myBar, theirBar, myLabel, theirLabel, timerLabel, bigLabel, bigScale, dashButton
local active = false
local duelScale
local dashReadyAt = 0
local maxHealth = 100

local function build()
	frame = Create("Frame", {
		Name = "DuelHud",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.new(0, 520, 0, 74),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Visible = false,
		ZIndex = 10,
		Parent = ctx.Screen,
	}, {
		UI.Corner(16),
		UI.Stroke(3, Color3.fromRGB(255, 80, 140)),
		UI.Gradient(Color3.fromRGB(70, 20, 50), Color3.fromRGB(30, 10, 30)),
		Create("UISizeConstraint", { MaxSize = Vector2.new(520, 74) }),
	})
	duelScale = Create("UIScale", { Scale = 1, Parent = frame })
	myLabel = UI.Label({ Position = UDim2.new(0, 10, 0, 4), Size = UDim2.new(0.4, -10, 0, 22), TextXAlignment = Enum.TextXAlignment.Left, Text = "You", ZIndex = 11, Parent = frame })
	theirLabel = UI.Label({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 4), Size = UDim2.new(0.4, -10, 0, 22), TextXAlignment = Enum.TextXAlignment.Right, Text = "", ZIndex = 11, Parent = frame })
	timerLabel = UI.Label({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 2), Size = UDim2.new(0.2, 0, 0, 28), Text = "60", TextColor3 = UI.Colors.Gold, ZIndex = 11, Parent = frame })
	UI.TextStroke(2).Parent = timerLabel
	local _, a = UI.ProgressBar({ Position = UDim2.new(0, 10, 0, 34), Size = UDim2.new(0.5, -20, 0, 22), Color = Color3.fromRGB(80, 220, 120), Parent = frame })
	local _, b = UI.ProgressBar({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 34), Size = UDim2.new(0.5, -20, 0, 22), Color = Color3.fromRGB(255, 70, 90), Parent = frame })
	myBar, theirBar = a, b

	bigLabel = UI.Label({
		Name = "DuelBig",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.4),
		Size = UDim2.new(0.6, 0, 0.18, 0),
		Text = "",
		Visible = false,
		ZIndex = 30,
		Parent = ctx.Screen,
	})
	UI.TextStroke(4).Parent = bigLabel
	bigScale = Create("UIScale", { Scale = 1, Parent = bigLabel })

	dashButton = UI.Button({
		Name = "Dash",
		-- rechts in der Mitte, damit er nicht den Springen-Knopf am Handy verdeckt
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.45, 0),
		Size = UDim2.new(0, 110, 0, 60),
		Color = Color3.fromRGB(80, 160, 255),
		Text = "💨 DASH (Q)",
		Parent = ctx.Screen,
	}, function()
		DuelUI.Dash()
	end)
	dashButton.Visible = false
end

local function showBig(text, color, duration)
	bigLabel.Text = text
	bigLabel.TextColor3 = color or UI.Colors.White
	bigLabel.Visible = true
	bigScale.Scale = 0.3
	TweenService:Create(bigScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	local myText = text
	task.delay(duration or 0.9, function()
		if bigLabel.Text == myText then
			bigLabel.Visible = false
		end
	end)
end

function DuelUI.Dash()
	if not active then
		return
	end
	local now = os.clock()
	if now < dashReadyAt then
		return
	end
	dashReadyAt = now + Config.Duel.DashCooldown
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		local look = root.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		if flat.Magnitude > 0.01 then
			root.AssemblyLinearVelocity = flat.Unit * Config.Duel.DashSpeed + Vector3.new(0, 8, 0)
		end
	end
	ctx.PlaySound("Whoosh", 1.3)
	ctx.Request("DuelDash")
end

function DuelUI.OnEvent(info)
	if type(info) ~= "table" then
		return
	end
	if info.Kind == "Start" then
		active = true
		ctx.Hud.SetDuelMode(true)
		duelScale.Scale = ctx.Hud.GetScale()
		maxHealth = tonumber(info.MaxHealth) or 100
		frame.Visible = true
		dashButton.Visible = true
		theirLabel.Text = tostring(info.Opponent)
		myLabel.Text = player.DisplayName
		UI.SetProgress(myBar, 1)
		UI.SetProgress(theirBar, 1)
		timerLabel.Text = tostring(info.Duration or 60)
		ctx.UI.Close(ctx.UI.OpenWindow or "")
		task.spawn(function()
			local count = tonumber(info.Countdown) or 3
			for i = count, 1, -1 do
				showBig(tostring(i), UI.Colors.Gold, 0.8)
				ctx.PlaySound("Click", 1 + (count - i) * 0.2)
				task.wait(1)
			end
			showBig("⚔️ FIGHT! ⚔️", Color3.fromRGB(255, 90, 120), 1)
			ctx.PlaySound("Popup", 1.3)
		end)
	elseif info.Kind == "Update" then
		local myHealth = tonumber(info.MyHealth) or 0
		local theirHealth = tonumber(info.TheirHealth) or 0
		UI.SetProgress(myBar, myHealth / maxHealth)
		UI.SetProgress(theirBar, theirHealth / maxHealth)
		myLabel.Text = player.DisplayName .. "  " .. math.ceil(myHealth)
		theirLabel.Text = math.ceil(theirHealth) .. "  " .. tostring(info.Opponent or "")
		timerLabel.Text = tostring(math.ceil(tonumber(info.TimeLeft) or 0))
	elseif info.Kind == "DashOk" then
		dashReadyAt = math.max(dashReadyAt, os.clock() + (tonumber(info.Cooldown) or 2.5) - 0.2)
	elseif info.Kind == "End" then
		active = false
		dashButton.Visible = false
		local result = info.Result
		if result == "Win" then
			showBig("🏆 VICTORY!", UI.Colors.Gold, 2.5)
		elseif result == "Lose" then
			showBig("💀 DEFEAT", Color3.fromRGB(255, 90, 90), 2.5)
		else
			showBig("🤝 DRAW", UI.Colors.White, 2.5)
		end
		ctx.Hud.Notify("⚔️ Duel over (" .. tostring(info.Reason) .. ")  +" .. tostring(info.Gems) .. " 💎", { 255, 220, 120 })
		task.delay(2.5, function()
			if not active then
				frame.Visible = false
				ctx.Hud.SetDuelMode(false)
			end
		end)
	end
end

function DuelUI.IsActive()
	return active
end

function DuelUI.Init(context)
	ctx = context
	UI = ctx.UI
	Config = ctx.Config
	Create = UI.Create
	build()
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.Q then
			DuelUI.Dash()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.1)
			if active then
				local left = dashReadyAt - os.clock()
				if left > 0 then
					dashButton.Text = string.format("💨 %.1f", left)
					UI.SetButtonColor(dashButton, UI.Colors.Gray)
				else
					dashButton.Text = "💨 DASH (Q)"
					UI.SetButtonColor(dashButton, Color3.fromRGB(80, 160, 255))
				end
			end
		end
	end)
end

return DuelUI
