--[[
	Duel: 1-gegen-1-Kaempfe.

	Wer in der Duell-Zone im Hub einen anderen Spieler slappt, startet ein
	Duell. Beide werden in eine freie schwebende Arena teleportiert.
	  * Leben (eigene Duell-Leben, nicht die Roblox-Gesundheit)
	  * 3-2-1-Countdown, danach 60 Sekunden Kampf
	  * Schaden haengt (gedeckelt) von der Hand-Staerke ab, Krits, Combo-Bonus
	  * Dash mit kurzer Unverwundbarkeit
	  * Rueckstoss wird staerker, je weniger Leben man hat -> Ring-Out moeglich
	  * Sieg: Gems + Duell-Sieg; nach Ablauf gewinnt, wer mehr Leben hat
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SlapShared")
local Config = require(Shared:WaitForChild("Config"))
local Calc = require(Shared:WaitForChild("Calc"))

local Duel = {}
local ctx

local D = Config.Duel
local duels = {} -- aktive Duelle
local arenaInUse = {} -- [ArenaIndex] = Duel

local function getRoot(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or humanoid.Health <= 0 then
		return nil
	end
	return root
end

function Duel.IsInDuel(player)
	local profile = ctx.Data.Get(player)
	return profile ~= nil and profile.Duel ~= nil
end

local function other(duel, player)
	if duel.A == player then
		return duel.B
	end
	return duel.A
end

local function sendUpdate(duel)
	local now = os.clock()
	local timeLeft = 0
	if duel.FightStart then
		timeLeft = math.max(0, D.Duration - (now - duel.FightStart))
	end
	for _, player in ipairs({ duel.A, duel.B }) do
		local opponent = other(duel, player)
		local profile = ctx.Data.Get(player)
		ctx.Remotes.Fire("Duel", player, {
			Kind = "Update",
			MyHealth = duel.Health[player],
			TheirHealth = duel.Health[opponent],
			MaxHealth = D.Health,
			TimeLeft = timeLeft,
			Opponent = opponent.DisplayName,
			MyCombo = profile and profile.DuelCombo or 0,
		})
	end
end

-- Schaden eines Treffers aus der Hand-Staerke (log-skaliert und gedeckelt)
function Duel.GetHitDamage(data)
	local raw = Calc.GetDamage(data, os.time())
	local damage = D.BaseDamage + math.log10(math.max(1, raw)) * D.DamagePerPower
	return math.min(D.MaxDamage, damage)
end

local function teleportBack(player)
	local root = getRoot(player)
	if root and player.Character then
		local center = ctx.World.Arena.Center
		player.Character:PivotTo(CFrame.new(center + Vector3.new(ctx.World.Arena.Radius + 6, 4, 0)))
	end
end

local function finish(duel, winner, reason)
	if duel.Over then
		return
	end
	duel.Over = true
	for i, d in ipairs(duels) do
		if d == duel then
			table.remove(duels, i)
			break
		end
	end
	arenaInUse[duel.ArenaIndex] = nil

	for _, player in ipairs({ duel.A, duel.B }) do
		player:SetAttribute("InDuel", nil)
		local profile = ctx.Data.Get(player)
		if profile then
			profile.Duel = nil
			local result
			local gems
			if winner == nil then
				result = "Draw"
				gems = D.LoseGems
			elseif winner == player then
				result = "Win"
				gems = D.WinGems
				profile.Data.DuelWins = (profile.Data.DuelWins or 0) + 1
			else
				result = "Lose"
				gems = D.LoseGems
			end
			ctx.Data.AddGems(profile, gems)
			ctx.Remotes.Fire("Duel", player, { Kind = "End", Result = result, Gems = gems, Reason = reason })
			ctx.Data.Push(player, true)
			task.delay(2.5, function()
				if player.Parent and not (ctx.Data.Get(player) and ctx.Data.Get(player).Duel) then
					teleportBack(player)
				end
			end)
		end
	end
	if winner then
		ctx.Remotes.NotifyAll("⚔️ " .. winner.DisplayName .. " won a duel against " .. other(duel, winner).DisplayName .. "! (" .. reason .. ")", { 255, 200, 120 })
	end
end

function Duel.Start(a, b)
	local profileA, profileB = ctx.Data.Get(a), ctx.Data.Get(b)
	if not profileA or not profileB or profileA.Duel or profileB.Duel then
		return false
	end
	if ctx.Trade and (ctx.Trade.IsTrading(a) or ctx.Trade.IsTrading(b)) then
		return false
	end
	local arenaIndex = nil
	for i = 1, #ctx.World.DuelArenas do
		if not arenaInUse[i] then
			arenaIndex = i
			break
		end
	end
	if not arenaIndex then
		ctx.Remotes.Notify(a, "⚔️ All duel arenas are busy, try again in a moment!", { 255, 200, 120 })
		return false
	end
	local arena = ctx.World.DuelArenas[arenaIndex]
	local duel = {
		A = a,
		B = b,
		ArenaIndex = arenaIndex,
		Arena = arena,
		Health = { [a] = D.Health, [b] = D.Health },
		Started = os.clock(),
		FightStart = nil,
		Over = false,
	}
	arenaInUse[arenaIndex] = duel
	table.insert(duels, duel)
	profileA.Duel = duel
	profileB.Duel = duel
	profileA.DuelCombo, profileB.DuelCombo = 0, 0
	profileA.LastDuelHit, profileB.LastDuelHit = 0, 0
	profileA.DashUntil, profileB.DashUntil = 0, 0

	profileA.LastDash, profileB.LastDash = 0, 0
	for i, player in ipairs({ a, b }) do
		player:SetAttribute("InDuel", true)
		if player.Character then
			player.Character:PivotTo(arena.Spawns[i])
		end
		ctx.Remotes.Fire("Duel", player, {
			Kind = "Start",
			Opponent = other(duel, player).DisplayName,
			Countdown = D.Countdown,
			Duration = D.Duration,
			MaxHealth = D.Health,
		})
	end
	task.delay(D.Countdown, function()
		if not duel.Over then
			duel.FightStart = os.clock()
			sendUpdate(duel)
		end
	end)
	return true
end

-- Slap waehrend eines Duells. Gibt true zurueck, wenn ein Schlag ausgefuehrt wurde.
function Duel.Slap(player, profile, root)
	local duel = profile.Duel
	if not duel or duel.Over or not duel.FightStart then
		return false
	end
	local now = os.clock()
	if now - (profile.LastDuelSlap or 0) < D.AttackCooldown - 0.04 then
		return false
	end
	profile.LastDuelSlap = now

	local opponent = other(duel, player)
	local opponentProfile = ctx.Data.Get(opponent)
	local opponentRoot = getRoot(opponent)
	if not opponentProfile or not opponentRoot then
		return true
	end
	local distance = (opponentRoot.Position - root.Position).Magnitude
	if distance > D.Reach + 1.5 then
		return true -- daneben
	end
	if now < (opponentProfile.DashUntil or 0) then
		ctx.Remotes.FireAll("SlapFx", { Kind = "DuelDodge", Position = opponentRoot.Position, Radius = 2, UserId = player.UserId })
		return true -- ausgewichen
	end

	-- Combo
	if now - (profile.LastDuelHit or 0) <= D.ComboWindow then
		profile.DuelCombo = (profile.DuelCombo or 0) + 1
	else
		profile.DuelCombo = 0
	end
	profile.LastDuelHit = now

	local damage = Duel.GetHitDamage(profile.Data) * (1 + math.min(D.MaxComboBonus, profile.DuelCombo * D.ComboBonus))
	local crit = math.random() < D.CritChance
	if crit then
		damage = damage * D.CritMultiplier
	end
	-- Dash-Schlag: kurz nach einem Dash trifft man haerter
	local dashStrike = now - (profile.LastDash or 0) <= D.DashStrikeWindow
	if dashStrike then
		damage = damage * D.DashStrikeMultiplier
		profile.LastDash = profile.LastDash - D.DashStrikeWindow -- nur einmal pro Dash
	end
	damage = math.floor(damage * 10 + 0.5) / 10
	duel.Health[opponent] = math.max(0, duel.Health[opponent] - damage)

	-- Rueckstoss: staerker bei wenig Leben
	local missing = 1 - duel.Health[opponent] / D.Health
	local flat = opponentRoot.Position - root.Position
	flat = Vector3.new(flat.X, 0, flat.Z)
	if flat.Magnitude < 0.01 then
		flat = Vector3.new(0, 0, 1)
	end
	local strength = D.Knockback * (1 + missing * D.KnockbackGrowth) * (crit and 1.3 or 1) * (dashStrike and 1.4 or 1)
	ctx.Remotes.Fire("Knockback", opponent, flat.Unit * strength + Vector3.new(0, D.UpForce, 0), player.DisplayName)
	ctx.Remotes.FireAll("SlapFx", {
		Kind = "Duel",
		Position = opponentRoot.Position,
		Radius = 2,
		Damage = damage,
		Crit = crit and 1 or 0,
		UserId = player.UserId,
		TargetId = opponent.UserId,
		Combo = profile.DuelCombo,
		Special = dashStrike and "DashStrike" or nil,
	})
	ctx.Data.AddStat(profile, "PvpSlaps", 1)

	if duel.Health[opponent] <= 0 then
		finish(duel, player, "K.O.")
	else
		sendUpdate(duel)
	end
	return true
end

function Duel.Dash(player)
	local profile = ctx.Data.Get(player)
	if not profile or not profile.Duel or not profile.Duel.FightStart then
		return
	end
	local now = os.clock()
	if now - (profile.LastDash or 0) < D.DashCooldown - 0.1 then
		return
	end
	profile.LastDash = now
	profile.DashUntil = now + D.DashInvulnerable
	ctx.Remotes.Fire("Duel", player, { Kind = "DashOk", Cooldown = D.DashCooldown })
end

function Duel.OnLeave(player)
	local profile = ctx.Data.Profiles[player]
	local duel = profile and profile.Duel
	if duel and not duel.Over then
		finish(duel, other(duel, player), "opponent left")
	end
end

local function tick()
	local now = os.clock()
	for i = #duels, 1, -1 do
		local duel = duels[i]
		if duel and not duel.Over then
			local arenaY = duel.Arena.Center.Y
			local loser = nil
			local reason = nil
			for _, player in ipairs({ duel.A, duel.B }) do
				if not player.Parent then
					loser, reason = player, "opponent left"
				else
					local root = getRoot(player)
					if not root then
						loser, reason = player, "K.O."
					elseif root.Position.Y < arenaY - D.RingOutDepth then
						loser, reason = player, "RING OUT"
					end
				end
			end
			if loser then
				finish(duel, other(duel, loser), reason)
			elseif duel.FightStart and now - duel.FightStart >= D.Duration then
				local ha, hb = duel.Health[duel.A], duel.Health[duel.B]
				if ha > hb then
					finish(duel, duel.A, "time")
				elseif hb > ha then
					finish(duel, duel.B, "time")
				else
					finish(duel, nil, "time")
				end
			end
		end
	end
end

function Duel.Init(context)
	ctx = context
	ctx.RegisterAction("DuelDash", Duel.Dash)
end

function Duel.Run()
	task.spawn(function()
		local lastUpdate = 0
		while true do
			task.wait(0.1)
			local ok, err = pcall(tick)
			if not ok then
				warn("[SlapTheBlob] Duel tick: " .. tostring(err))
			end
			if os.clock() - lastUpdate > 1 then
				lastUpdate = os.clock()
				for _, duel in ipairs(duels) do
					if duel.FightStart and not duel.Over then
						sendUpdate(duel)
					end
				end
			end
		end
	end)
end

return Duel
