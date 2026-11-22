--[[
	Effects: Schadenszahlen, Partikel, Kamera-Wackeln, Konfetti, Rueckstoss.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Effects = {}
local ctx, UI, Calc

local player = Players.LocalPlayer
local shakeUntil = 0
local shakeStrength = 0

local function makeAttachment(position)
	local attachment = Instance.new("Attachment")
	attachment.Parent = workspace.Terrain
	attachment.WorldPosition = position
	return attachment
end

local function burst(position, colors, count, speed, size)
	local attachment = makeAttachment(position)
	local keypoints = {}
	for i, color in ipairs(colors) do
		table.insert(keypoints, ColorSequenceKeypoint.new((i - 1) / math.max(1, #colors - 1), color))
	end
	if #keypoints == 1 then
		table.insert(keypoints, ColorSequenceKeypoint.new(1, colors[1]))
	end
	local emitter = Instance.new("ParticleEmitter")
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(0.4, 0.9)
	emitter.Speed = NumberRange.new(speed * 0.6, speed)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Acceleration = Vector3.new(0, -30, 0)
	emitter.Drag = 2
	emitter.LightEmission = 0.6
	emitter.Color = ColorSequence.new(keypoints)
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.6) })
	emitter.Parent = attachment
	emitter:Emit(count)
	Debris:AddItem(attachment, 1.5)
end

local function floatingText(position, text, color, size, transparency)
	local attachment = makeAttachment(position)
	local billboard = UI.Create("BillboardGui", {
		Adornee = attachment,
		Size = UDim2.new(size * 1.8, 0, size, 0),
		AlwaysOnTop = true,
		LightInfluence = 0,
		MaxDistance = 200,
		Parent = attachment,
	})
	local label = UI.Create("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = UI.Font,
		TextScaled = true,
		TextColor3 = color,
		TextStrokeTransparency = 0,
		TextTransparency = transparency or 0,
		Text = text,
		Parent = billboard,
	})
	local scale = UI.Create("UIScale", { Scale = 0.4, Parent = label })
	TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	TweenService:Create(billboard, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { StudsOffset = Vector3.new(0, 3.5, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(0.45, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0.55), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	Debris:AddItem(attachment, 1.1)
end

local function shake(strength, duration)
	if not ctx.Setting("Shake") then
		return
	end
	shakeStrength = math.max(shakeStrength, strength)
	shakeUntil = math.max(shakeUntil, os.clock() + duration)
end

local function fovPunch(amount)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local base = 70
	camera.FieldOfView = base + amount
	TweenService:Create(camera, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = base }):Play()
end

function Effects.OnSlap(info)
	local position = info.Position
	if typeof(position) ~= "Vector3" then
		return
	end
	local isMine = info.UserId == player.UserId

	if info.Kind == "Pvp" then
		burst(position, { Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 80, 160) }, 18, 25, 0.8)
		if isMine then
			shake(0.25, 0.15)
			fovPunch(3)
		end
		return
	end

	local radius = tonumber(info.Radius) or 3
	local damage = tonumber(info.Damage) or 0
	local crit = tonumber(info.Crit) or 0

	-- Trefferpunkt: Seite des Gyatts, die zum Schlaeger zeigt
	local hitPoint = position
	if typeof(info.From) == "Vector3" then
		local dir = info.From - position
		if dir.Magnitude > 0.01 then
			hitPoint = position + dir.Unit * radius * 0.95
		end
	end

	local colors = { Color3.fromRGB(255, 200, 230), Color3.fromRGB(255, 90, 170) }
	if crit == 1 then
		colors = { Color3.fromRGB(255, 240, 120), Color3.fromRGB(255, 140, 30) }
	elseif crit == 2 then
		colors = { Color3.fromRGB(255, 80, 80), Color3.fromRGB(255, 230, 80), Color3.fromRGB(80, 255, 120), Color3.fromRGB(80, 160, 255), Color3.fromRGB(200, 90, 255) }
	end
	burst(hitPoint, colors, isMine and (crit > 0 and 30 or 14) or 6, 22 + crit * 10, 0.7 + crit * 0.3)

	if ctx.Setting("DamageNumbers") and (isMine or math.random() < 0.5) then
		local text = "-" .. Calc.FormatNumber(damage)
		local color = Color3.fromRGB(255, 255, 255)
		local size = isMine and 4.5 or 2.8
		if crit == 1 then
			text = "💥 KRIT! " .. text
			color = Color3.fromRGB(255, 220, 60)
			size = size * 1.3
		elseif crit == 2 then
			text = "🌈 MEGA KRIT!! " .. text
			color = Color3.fromRGB(255, 90, 200)
			size = size * 1.7
		end
		if isMine and info.Reward then
			text = text .. "\n+" .. Calc.FormatNumber(info.Reward) .. " 👋"
		end
		local offset = Vector3.new((math.random() - 0.5) * radius * 1.4, radius * 0.5 + math.random() * radius * 0.6, 0)
		floatingText(position + offset, text, color, size, isMine and 0 or 0.35)
	end

	if isMine then
		fovPunch(crit > 0 and 4 or 1.5)
		if crit > 0 then
			shake(crit == 2 and 0.9 or 0.4, crit == 2 and 0.45 or 0.2)
			ctx.PlaySound("Crit", crit == 2 and 0.8 or 1.1)
		end
	end
end

function Effects.OnDefeat(key, position, radius, isGolden)
	if typeof(position) ~= "Vector3" then
		return
	end
	radius = tonumber(radius) or 4
	local confetti = {
		Color3.fromRGB(255, 80, 160), Color3.fromRGB(255, 220, 60), Color3.fromRGB(90, 220, 255),
		Color3.fromRGB(120, 255, 120), Color3.fromRGB(200, 120, 255),
	}
	burst(position, confetti, isGolden and 120 or 60, 40, 1.4)
	burst(position + Vector3.new(0, radius, 0), { Color3.fromRGB(255, 255, 255) }, 30, 25, 2)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root and (root.Position - position).Magnitude < 80 then
		shake(0.6, 0.35)
		floatingText(position + Vector3.new(0, radius + 2, 0), isGolden and "⭐ GOLDEN BESIEGT! ⭐" or "💥 BESIEGT!", Color3.fromRGB(255, 230, 90), 7, 0)
	end
end

function Effects.OnKnockback(velocity, attackerName)
	if typeof(velocity) ~= "Vector3" then
		return
	end
	-- Schutz: unrealistisch starke Werte begrenzen
	if velocity.Magnitude > 250 then
		velocity = velocity.Unit * 250
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return
	end
	humanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
	root.AssemblyLinearVelocity = velocity
	shake(0.7, 0.3)
	ctx.PlaySound("Whoosh")
	ctx.Hud.Notify("💥 " .. tostring(attackerName) .. " hat dich weggeslappt!", { 255, 150, 150 })
	task.delay(0.8, function()
		if humanoid.Parent and humanoid.Health > 0 then
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end)
end

function Effects.Init(context)
	ctx = context
	UI = ctx.UI
	Calc = ctx.Calc

	-- Kamera-Wackeln ueber CameraOffset des Humanoids
	RunService.RenderStepped:Connect(function()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end
		local now = os.clock()
		if now < shakeUntil then
			local s = shakeStrength
			humanoid.CameraOffset = Vector3.new((math.random() - 0.5) * s, (math.random() - 0.5) * s, (math.random() - 0.5) * s)
		elseif shakeStrength > 0 then
			shakeStrength = 0
			humanoid.CameraOffset = Vector3.new(0, 0, 0)
		end
	end)
end

return Effects
