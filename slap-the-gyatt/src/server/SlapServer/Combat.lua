--[[
	Combat: jeder Slap wird hier auf dem Server geprueft und berechnet.
	  * Cooldown, Reichweite, freigeschaltete Zone
	  * Krit / Mega-Krit, Combo
	  * PvP in der Arena (Rueckstoss)
	  * Auto-Slap
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SlapShared")
local Config = require(Shared:WaitForChild("Config"))
local Calc = require(Shared:WaitForChild("Calc"))

local Combat = {}
local ctx

local PVP_MAX_REACH = 12

local function getAliveRoot(player)
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or humanoid.Health <= 0 then
		return nil
	end
	return root, humanoid
end

local function pvpSlap(player, profile, root)
	local reach = math.min(Calc.GetTotalReach(profile.Data), PVP_MAX_REACH)
	local best, bestDistance, bestRoot = nil, math.huge, nil
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			local otherRoot = getAliveRoot(other)
			if otherRoot and ctx.World.IsInArena(otherRoot.Position) then
				local distance = (otherRoot.Position - root.Position).Magnitude - 1.5
				if distance <= reach and distance < bestDistance then
					best, bestDistance, bestRoot = other, distance, otherRoot
				end
			end
		end
	end
	if not best then
		return
	end

	local arena = Config.Arena
	local flat = bestRoot.Position - root.Position
	flat = Vector3.new(flat.X, 0, flat.Z)
	if flat.Magnitude < 0.01 then
		flat = root.CFrame.LookVector
		flat = Vector3.new(flat.X, 0, flat.Z)
	end
	if flat.Magnitude < 0.01 then
		flat = Vector3.new(0, 0, 1)
	end
	local strength = math.min(arena.BaseKnockback + profile.Data.Upgrades.Power * arena.KnockbackPerPower, arena.MaxKnockback)
	local velocity = flat.Unit * strength + Vector3.new(0, arena.UpForce, 0)

	ctx.Remotes.Fire("Knockback", best, velocity, player.DisplayName)
	ctx.Remotes.FireAll("SlapFx", {
		Kind = "Pvp",
		Position = bestRoot.Position,
		Radius = 1.5,
		UserId = player.UserId,
		TargetId = best.UserId,
	})
	ctx.Data.AddStat(profile, "PvpSlaps", 1)
	ctx.Data.Push(player, false)
end

-- Gibt true zurueck, wenn geslappt wurde (fuer die Schwung-Animation)
function Combat.TrySlap(player, isAuto)
	local profile = ctx.Data.Get(player)
	if not profile then
		return false
	end
	local root = getAliveRoot(player)
	if not root then
		return false
	end

	local data = profile.Data
	local now = os.clock()
	local cooldown = Calc.GetTotalCooldown(data)
	if isAuto then
		cooldown = cooldown * Config.AutoSlapSlowdown
	end
	if now - profile.LastSlap < cooldown - 0.04 then
		return false
	end
	profile.LastSlap = now

	if ctx.World.IsInArena(root.Position) then
		pvpSlap(player, profile, root)
		return true
	end

	local target = ctx.Gyatts.FindTarget(root.Position, Calc.GetTotalReach(data), data.Zones)
	if not target then
		return true -- Luft-Slap
	end

	-- Combo
	if now - profile.LastHit <= Config.ComboWindow then
		profile.Combo = math.min(profile.Combo + 1, Calc.GetMaxCombo(data.Upgrades.Combo))
	else
		profile.Combo = 1
	end
	profile.LastHit = now

	local unixNow = os.time()
	local damage = Calc.GetDamage(data, unixNow)
	local critLevel = 0
	if math.random() < Calc.GetTotalCritChance(data) then
		critLevel = 1
		damage = damage * Config.CritMultiplier
		if math.random() < Config.MegaCritChance then
			critLevel = 2
			damage = damage * Config.MegaCritMultiplier
		end
	end

	-- Legendaere Hand-Kraefte
	local hand = Calc.GetHand(data.Hand)
	local special = nil
	if hand.Smite then
		profile.SmiteCount = (profile.SmiteCount or 0) + 1
		if profile.SmiteCount >= hand.Smite.Every then
			profile.SmiteCount = 0
			special = "Smite"
			damage = damage * hand.Smite.Multiplier
		end
	end
	if hand.Snap and not target.IsGolden and math.random() < hand.Snap then
		special = "Snap"
		damage = math.max(damage, math.ceil(target.Health))
	end

	local slapMultiplier = Calc.GetSlapMultiplier(data, unixNow) * Calc.GetComboMultiplier(profile.Combo)
	local reward = damage * target.RewardMultiplier * slapMultiplier
	reward = ctx.Data.AddSlaps(profile, math.max(1, reward))

	data.TotalSlaps = data.TotalSlaps + 1
	if profile.Combo > data.BestCombo then
		data.BestCombo = profile.Combo
	end
	ctx.Data.AddStat(profile, "Slaps", 1)
	ctx.Data.AddStat(profile, "BestCombo", profile.Combo)
	if critLevel > 0 then
		ctx.Data.AddStat(profile, "Crits", 1)
	end

	ctx.Remotes.FireAll("SlapFx", {
		Kind = "Gyatt",
		Key = target.Key,
		Position = target.Position,
		Radius = target.Radius,
		Damage = damage,
		Crit = critLevel,
		Reward = reward,
		Combo = profile.Combo,
		UserId = player.UserId,
		From = root.Position,
		Special = special,
	})

	-- Blitz trifft auch alle Gyatts in der Naehe
	local splashTargets = {}
	if special == "Smite" then
		for _, other in ipairs(ctx.Gyatts.List) do
			if other ~= target and other.Alive and other.ZoneIndex <= data.Zones
				and (other.Position - target.Position).Magnitude <= hand.Smite.Radius then
				table.insert(splashTargets, other)
			end
		end
	end

	ctx.Gyatts.Damage(target, player, damage)

	for _, other in ipairs(splashTargets) do
		if other.Alive then
			local splashReward = ctx.Data.AddSlaps(profile, math.max(1, damage * other.RewardMultiplier * slapMultiplier))
			ctx.Remotes.FireAll("SlapFx", {
				Kind = "Gyatt",
				Key = other.Key,
				Position = other.Position,
				Radius = other.Radius,
				Damage = damage,
				Crit = critLevel,
				Reward = splashReward,
				Combo = profile.Combo,
				UserId = player.UserId,
				From = target.Position,
				Special = "Smite",
			})
			ctx.Gyatts.Damage(other, player, damage)
		end
	end

	if not data.TutorialDone and data.TotalSlaps >= 10 then
		data.TutorialDone = true
		ctx.Remotes.Popup(player, "SUPER SLAP!", "Now buy upgrades in the 🛒 Shop!", { 255, 170, 220 })
		ctx.Data.Push(player, true)
	else
		ctx.Data.Push(player, false)
	end
	return true
end

local function startAutoSlap()
	task.spawn(function()
		while true do
			task.wait(0.1)
			for player, profile in pairs(ctx.Data.Profiles) do
				if profile.Loaded and profile.Data.AutoSlapOn and profile.Data.GemShop.AutoSlap >= 1 and ctx.Hands.IsEquipped(player) then
					local data = profile.Data
					local cooldown = Calc.GetTotalCooldown(data) * Config.AutoSlapSlowdown
					if os.clock() - profile.LastSlap >= cooldown then
						local root = getAliveRoot(player)
						if root and not ctx.World.IsInArena(root.Position)
							and ctx.Gyatts.FindTarget(root.Position, Calc.GetTotalReach(data), data.Zones) then
							if Combat.TrySlap(player, true) then
								ctx.Hands.Swing(player)
							end
						end
					end
				end
			end
		end
	end)
end

function Combat.Init(context)
	ctx = context
end

function Combat.Start()
	startAutoSlap()
end

return Combat
