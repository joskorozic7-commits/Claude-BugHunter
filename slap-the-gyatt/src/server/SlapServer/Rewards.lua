--[[
	Rewards: taegliche Belohnung, taegliche Quests und Codes.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SlapShared")
local Config = require(Shared:WaitForChild("Config"))
local Calc = require(Shared:WaitForChild("Calc"))

local Rewards = {}
local ctx

local RED = { 255, 120, 120 }
local GOLD = { 255, 220, 100 }

-- Belohnungstabelle anwenden: { Gems=, Boost=, Duration= }
local function grant(profile, reward)
	local parts = {}
	if reward.Gems and reward.Gems > 0 then
		ctx.Data.AddGems(profile, reward.Gems)
		table.insert(parts, "+" .. reward.Gems .. " 💎")
	end
	if reward.Boost and Config.Boosts[reward.Boost] then
		ctx.Data.AddBoost(profile, reward.Boost, reward.Duration or 300)
		local boost = Config.Boosts[reward.Boost]
		table.insert(parts, boost.Icon .. " " .. boost.DisplayName .. " " .. Calc.FormatTime(reward.Duration or 300))
	end
	return table.concat(parts, "   ")
end

function Rewards.ClaimDaily(player)
	local profile = ctx.Data.Get(player)
	if not profile then
		return
	end
	local now = os.time()
	local canClaim, day, waitSeconds = Calc.GetDailyStatus(profile.Data, now)
	if not canClaim then
		ctx.Remotes.Notify(player, "🎁 Naechste Belohnung in " .. Calc.FormatTime(waitSeconds), RED)
		return
	end
	profile.Data.Daily.Last = now
	profile.Data.Daily.Streak = day
	local text = grant(profile, Config.DailyRewards[day])
	ctx.Remotes.Popup(player, "TAG " .. day .. " BELOHNUNG!", text, GOLD)
	ctx.Remotes.Fire("Event", player, "Purchased")
	ctx.Data.Push(player, true)
end

function Rewards.ClaimQuest(player, index)
	local profile = ctx.Data.Get(player)
	if not profile or type(index) ~= "number" then
		return
	end
	index = math.floor(index)
	ctx.Data.RefreshQuests(profile)
	local quests = Calc.GetQuests(profile.Data.Quests.Day, profile.UserId)
	local quest = quests[index]
	if not quest then
		return
	end
	if profile.Data.Quests.Claimed[index] then
		ctx.Remotes.Notify(player, "Diese Quest hast du schon abgeholt!", { 255, 220, 120 })
		return
	end
	if (profile.Data.Quests.Progress[index] or 0) < quest.Amount then
		ctx.Remotes.Notify(player, "📜 Diese Quest ist noch nicht fertig!", RED)
		return
	end
	profile.Data.Quests.Claimed[index] = true
	local text = grant(profile, { Gems = quest.Gems })
	ctx.Remotes.Popup(player, "QUEST GESCHAFFT!", text, GOLD)
	ctx.Remotes.Fire("Event", player, "Purchased")
	ctx.Data.Push(player, true)
end

function Rewards.RedeemCode(player, text)
	local profile = ctx.Data.Get(player)
	if not profile or type(text) ~= "string" then
		return
	end
	local code = string.upper((text:gsub("%s", "")))
	if #code == 0 or #code > 30 then
		return
	end
	local now = os.clock()
	if profile.LastCode and now - profile.LastCode < 1.5 then
		return
	end
	profile.LastCode = now
	local reward = Config.Codes[code]
	if not reward then
		ctx.Remotes.Notify(player, "❌ Diesen Code gibt es nicht.", RED)
		ctx.Remotes.Fire("Event", player, "Denied")
		return
	end
	if profile.Data.Codes[code] then
		ctx.Remotes.Notify(player, "Diesen Code hast du schon benutzt!", { 255, 220, 120 })
		return
	end
	profile.Data.Codes[code] = true
	local rewardText = grant(profile, reward)
	ctx.Remotes.Popup(player, "CODE EINGELOEST!", rewardText, GOLD)
	ctx.Remotes.Fire("Event", player, "Purchased")
	ctx.Data.Push(player, true)
end

function Rewards.Init(context)
	ctx = context
	ctx.RegisterAction("ClaimDaily", Rewards.ClaimDaily)
	ctx.RegisterAction("ClaimQuest", Rewards.ClaimQuest)
	ctx.RegisterAction("RedeemCode", Rewards.RedeemCode)
end

return Rewards
