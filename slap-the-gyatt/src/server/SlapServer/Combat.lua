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
	local best, bestDistance = nil, math.huge
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			local otherRoot = getAliveRoot(other)
			if otherRoot and ctx.World.IsInArena(otherRoot.Position) and not ctx.Duel.IsInDuel(other) then
				local distance = (otherRoot.Position - root.Position).Magnitude - 1.5
				if distance <= reach and distance < bestDistance then
					best, bestDistance = other, distance
				end
			end
		end
	end
	if best then
		ctx.Duel.Start(player, best)
	end
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

	-- Duell laeuft: eigene Kampf-Regeln
	if profile.Duel then
		return ctx.Duel.Slap(player, profile, root)
	end
	-- In der Duell-Zone: einen anderen Spieler slappen startet ein Duell
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
	-- Slaps werden aus dem normalen Schaden berechnet (SNAP toetet nur sofort,
	-- sonst wuerde ein SNAP auf ein Ziel mit riesigen Leben die Wirtschaft sprengen)
	local rewardDamage = damage
	if hand.Snap and not target.IsGolden and math.random() < hand.Snap then
		special = "Snap"
		damage = math.max(damage, math.ceil(target.Health))
	end

	local slapMultiplier = Calc.GetSlapMultiplier(data, unixNow) * Calc.GetComboMultiplier(profile.Combo)
	local reward = rewardDamage * target.RewardMultiplier * slapMultiplier
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
