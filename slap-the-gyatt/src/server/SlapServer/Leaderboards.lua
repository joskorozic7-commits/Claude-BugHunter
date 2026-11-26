--[[
	Leaderboards: globale Bestenlisten auf den Tafeln im Hub.
	Wenn keine DataStores verfuegbar sind (z.B. in Studio ohne API-Zugriff),
	zeigen die Tafeln die Spieler auf diesem Server.
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SlapShared")
local Config = require(Shared:WaitForChild("Config"))
local Calc = require(Shared:WaitForChild("Calc"))

local Leaderboards = {}
local ctx

local stores = {}
local nameCache = {}

-- Slaps koennen riesig werden -> logarithmisch speichern (passt immer in 64 Bit)
local SCALE = 1e9
local function encode(value)
	return math.floor(math.log10(math.max(0, value) + 1) * SCALE)
end
local function decode(value)
	return math.floor(10 ^ (value / SCALE) - 1 + 0.5)
end

local function getName(userId)
	if nameCache[userId] then
		return nameCache[userId]
	end
	local player = Players:GetPlayerByUserId(userId)
	if player then
		nameCache[userId] = player.DisplayName
		return player.DisplayName
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	if ok and type(name) == "string" then
		nameCache[userId] = name
		return name
	end
	return "Player " .. tostring(userId)
end

local function fill(boardId, entries, formatValue, title)
	local rows = ctx.World.Leaderboards and ctx.World.Leaderboards[boardId]
	if not rows then
		return
	end
	for i, row in ipairs(rows) do
		local entry = entries[i]
		if entry then
			local medal = (i == 1 and "🥇") or (i == 2 and "🥈") or (i == 3 and "🥉") or (i .. ".")
			row.Text = "  " .. medal .. "  " .. entry.Name .. "  -  " .. formatValue(entry.Value)
		elseif i == 1 and title then
			row.Text = "  " .. title
		else
			row.Text = "  " .. i .. ".  ..."
		end
	end
end

local function fromServer(field)
	local entries = {}
	for _, profile in pairs(ctx.Data.Profiles) do
		if profile.Loaded then
			table.insert(entries, { Name = profile.Player.DisplayName, Value = profile.Data[field], UserId = profile.UserId })
		end
	end
	table.sort(entries, function(a, b)
		return a.Value > b.Value
	end)
	return entries
end

local function readGlobal(store, isEncoded)
	local ok, pages = pcall(function()
		return store:GetSortedAsync(false, 10)
	end)
	if not ok or not pages then
		return nil
	end
	local ok2, page = pcall(function()
		return pages:GetCurrentPage()
	end)
	if not ok2 or type(page) ~= "table" then
		return nil
	end
	local entries = {}
	for _, item in ipairs(page) do
		local userId = tonumber(string.match(tostring(item.key), "%d+"))
		local value = tonumber(item.value) or 0
		if userId then
			table.insert(entries, { Name = getName(userId), Value = isEncoded and decode(value) or value, UserId = userId })
		end
	end
	return entries
end

-- Top 3 als Avatar-Statuen auf das Siegertreppchen stellen
local podiumUsers = {}
local function updatePodium(entries)
	local podium = ctx.World.Podium
	if not podium then
		return
	end
	for rank = 1, 3 do
		local spot = podium[rank]
		local entry = entries[rank]
		local userId = entry and entry.UserId or nil
		if spot then
			spot.Label.Text = (rank == 1 and "👑 " or "") .. "#" .. rank .. "  " .. (entry and (entry.Name .. "\n" .. Calc.FormatNumber(entry.Value) .. " Slaps") or "...")
			if podiumUsers[rank] ~= userId then
				podiumUsers[rank] = userId
				if spot.Model then
					spot.Model:Destroy()
					spot.Model = nil
				end
				if userId and userId > 0 then
					local ok, model = pcall(function()
						return Players:CreateHumanoidModelFromUserId(userId)
					end)
					if ok and model then
						model.Name = "PodiumAvatar" .. rank
						for _, d in ipairs(model:GetDescendants()) do
							if d:IsA("BasePart") then
								d.Anchored = true
								d.CanCollide = false
							elseif d:IsA("Script") or d:IsA("LocalScript") then
								d:Destroy()
							end
						end
						local humanoid = model:FindFirstChildOfClass("Humanoid")
						if humanoid then
							humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
						end
						local hipHeight = (humanoid and humanoid.HipHeight or 2) + 1
						pcall(function()
							model:PivotTo(spot.Top * CFrame.new(0, hipHeight + 0.6, 0))
						end)
						model.Parent = ctx.World.Root
						spot.Model = model
					end
				end
			end
		end
	end
end

function Leaderboards.Refresh()
	-- eigene Werte hochladen
	for _, profile in pairs(ctx.Data.Profiles) do
		if profile.Loaded and profile.CanSave then
			local key = "Player_" .. profile.UserId
			if stores.Earned then
				pcall(function()
					stores.Earned:SetAsync(key, encode(profile.Data.TotalEarned))
				end)
			end
			if stores.Rebirths then
				pcall(function()
					stores.Rebirths:SetAsync(key, profile.Data.Rebirths)
				end)
			end
		end
	end

	local earned = stores.Earned and readGlobal(stores.Earned, true)
	if not earned then
		earned = fromServer("TotalEarned")
		fill("Earned", earned, Calc.FormatNumber, "(this server only)")
	else
		fill("Earned", earned, Calc.FormatNumber, nil)
	end
	local okPodium, errPodium = pcall(updatePodium, earned)
	if not okPodium then
		warn("[SlapTheBlob] Podium: " .. tostring(errPodium))
	end
	local rebirths = stores.Rebirths and readGlobal(stores.Rebirths, false)
	if rebirths then
		fill("Rebirths", rebirths, tostring, nil)
	else
		fill("Rebirths", fromServer("Rebirths"), tostring, "(this server only)")
	end
end

function Leaderboards.Init(context)
	ctx = context
	if ctx.Data.HasStore() then
		local ok1, s1 = pcall(function()
			return DataStoreService:GetOrderedDataStore(Config.LeaderboardSlapsStore)
		end)
		local ok2, s2 = pcall(function()
			return DataStoreService:GetOrderedDataStore(Config.LeaderboardRebirthStore)
		end)
		stores.Earned = ok1 and s1 or nil
		stores.Rebirths = ok2 and s2 or nil
	end
end

function Leaderboards.Start()
	task.spawn(function()
		task.wait(5)
		while true do
			local ok, err = pcall(Leaderboards.Refresh)
			if not ok then
				warn("[SlapTheBlob] Leaderboard: " .. tostring(err))
			end
			task.wait(Config.LeaderboardRefresh)
		end
	end)
end

return Leaderboards
