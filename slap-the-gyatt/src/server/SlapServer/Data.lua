--[[
	Data: Spielstaende laden, pruefen, speichern und an den Client senden.
]]

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SlapShared")
local Config = require(Shared:WaitForChild("Config"))
local Calc = require(Shared:WaitForChild("Calc"))

local Data = {}
Data.Profiles = {} -- [Player] = profile

local Remotes -- wird in Init gesetzt

local store = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if ok then
		store = result
	else
		warn("[SlapTheBlob] DataStore not available: " .. tostring(result))
	end
end

--------------------------------------------------------------------------
-- Standardwerte & Pruefung
--------------------------------------------------------------------------
local SETTINGS = { "Sounds", "DamageNumbers", "Shake", "OtherPets" }
Data.SettingNames = SETTINGS

function Data.Default()
	local upgrades = {}
	for _, id in ipairs(Config.UpgradeOrder) do
		upgrades[id] = 0
	end
	local boosts = {}
	for _, id in ipairs(Config.BoostOrder) do
		boosts[id] = 0
	end
	local settings = {}
	for _, name in ipairs(SETTINGS) do
		settings[name] = true
	end
	return {
		Slaps = 0,
		Gems = 0,
		Rebirths = 0,
		TotalSlaps = 0,
		TotalEarned = 0,
		TotalDefeats = 0,
		BestCombo = 0,
		Upgrades = upgrades,
		Hand = Config.Hands[1].Id,
		OwnedHands = { [Config.Hands[1].Id] = true },
		Zones = 1,
		Pets = {},
		NextPetUid = 1,
		GemShop = { AutoSlap = 0, PetSlot = 0, Inventory = 0 },
		AutoSlapOn = false,
		Boosts = boosts,
		Daily = { Last = 0, Streak = 0 },
		Quests = { Day = -1, Progress = {}, Claimed = {} },
		Codes = {},
		Settings = settings,
		PlayTime = 0,
		TutorialDone = false,
		DuelWins = 0,
		TotalTrades = 0,
		Receipts = {}, -- bereits gutgeschriebene Robux-Kaeufe (PurchaseId -> Zeit)
	}
end

local function num(value, maxValue)
	value = tonumber(value)
	if not value or value ~= value or value == math.huge or value == -math.huge or value < 0 then
		return 0
	end
	value = math.floor(value)
	if maxValue and value > maxValue then
		value = maxValue
	end
	return value
end

function Data.Sanitize(raw)
	local data = Data.Default()
	if type(raw) ~= "table" then
		return data
	end

	data.Slaps = num(raw.Slaps)
	data.Gems = num(raw.Gems)
	data.Rebirths = num(raw.Rebirths, 100000)
	data.TotalSlaps = num(raw.TotalSlaps)
	data.TotalEarned = num(raw.TotalEarned)
	data.TotalDefeats = num(raw.TotalDefeats)
	data.BestCombo = num(raw.BestCombo)
	data.PlayTime = num(raw.PlayTime)
	data.DuelWins = num(raw.DuelWins)
	data.TotalTrades = num(raw.TotalTrades)
	if type(raw.Receipts) == "table" then
		local list = {}
		for purchaseId, time in pairs(raw.Receipts) do
			if type(purchaseId) == "string" then
				table.insert(list, { purchaseId, num(time) })
			end
		end
		table.sort(list, function(x, y)
			return x[2] > y[2]
		end)
		for i = 1, math.min(#list, 100) do
			data.Receipts[list[i][1]] = list[i][2]
		end
	end
	data.TutorialDone = raw.TutorialDone == true
	data.AutoSlapOn = raw.AutoSlapOn == true

	if type(raw.Upgrades) == "table" then
		for _, id in ipairs(Config.UpgradeOrder) do
			data.Upgrades[id] = Calc.ClampLevel(id, raw.Upgrades[id])
		end
	end

	if type(raw.OwnedHands) == "table" then
		for handId, owned in pairs(raw.OwnedHands) do
			if owned == true and Calc.IsHand(handId) and not Calc.IsRobuxHand(handId) then
				data.OwnedHands[handId] = true
			end
		end
	end
	-- Robux-Haende werden nach dem Laden ueber den Game Pass geprueft
	if type(raw.Hand) == "string" and (data.OwnedHands[raw.Hand] or Calc.IsRobuxHand(raw.Hand)) then
		data.Hand = raw.Hand
	end

	data.Zones = math.max(1, math.min(#Config.Zones, num(raw.Zones)))

	if type(raw.GemShop) == "table" then
		for _, item in ipairs(Config.GemShop) do
			if not item.Repeatable then
				data.GemShop[item.Id] = num(raw.GemShop[item.Id], #item.Prices)
			end
		end
	end

	-- Pets
	local maxPets = Calc.GetInventorySize(data)
	local slots = Calc.GetPetSlots(data)
	local equippedCount = 0
	local seenUids = {}
	local highestUid = 0
	if type(raw.Pets) == "table" then
		for _, pet in ipairs(raw.Pets) do
			if #data.Pets >= maxPets then
				break
			end
			if type(pet) == "table" and type(pet.Id) == "string" and Config.Pets[pet.Id] then
				local uid = num(pet.Uid)
				if uid > 0 and not seenUids[uid] then
					seenUids[uid] = true
					if uid > highestUid then
						highestUid = uid
					end
					local equipped = pet.Equipped == true and equippedCount < slots
					if equipped then
						equippedCount = equippedCount + 1
					end
					table.insert(data.Pets, { Uid = uid, Id = pet.Id, Equipped = equipped })
				end
			end
		end
	end
	data.NextPetUid = math.max(num(raw.NextPetUid), highestUid + 1, 1)

	if type(raw.Boosts) == "table" then
		for _, id in ipairs(Config.BoostOrder) do
			data.Boosts[id] = num(raw.Boosts[id])
		end
	end

	if type(raw.Daily) == "table" then
		data.Daily.Last = num(raw.Daily.Last)
		data.Daily.Streak = num(raw.Daily.Streak, #Config.DailyRewards)
	end

	if type(raw.Quests) == "table" then
		data.Quests.Day = tonumber(raw.Quests.Day) or -1
		for i = 1, Config.QuestsPerDay do
			data.Quests.Progress[i] = type(raw.Quests.Progress) == "table" and num(raw.Quests.Progress[i]) or 0
			data.Quests.Claimed[i] = type(raw.Quests.Claimed) == "table" and raw.Quests.Claimed[i] == true
		end
	end

	if type(raw.Codes) == "table" then
		for code, used in pairs(raw.Codes) do
			if type(code) == "string" and used == true then
				data.Codes[code] = true
			end
		end
	end

	if type(raw.Settings) == "table" then
		for _, name in ipairs(SETTINGS) do
			if type(raw.Settings[name]) == "boolean" then
				data.Settings[name] = raw.Settings[name]
			end
		end
	end

	return data
end

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in pairs(value) do
		copy[k] = deepCopy(v)
	end
	return copy
end
Data.DeepCopy = deepCopy

--------------------------------------------------------------------------
-- Laden & Speichern
--------------------------------------------------------------------------
local function key(userId)
	return "Player_" .. tostring(userId)
end

function Data.Load(player)
	if not store then
		return true, Data.Default()
	end
	local attempts = RunService:IsStudio() and 1 or 3
	for attempt = 1, attempts do
		local ok, result = pcall(function()
			return store:GetAsync(key(player.UserId))
		end)
		if ok then
			return true, Data.Sanitize(result)
		end
		warn("[SlapTheBlob] Load failed (" .. attempt .. "/" .. attempts .. "): " .. tostring(result))
		if attempt < attempts then
			task.wait(2)
		end
	end
	return false, Data.Default()
end

function Data.Save(profile)
	if not store or not profile or not profile.CanSave then
		return false
	end
	local snapshot = deepCopy(profile.Data)
	for attempt = 1, 3 do
		local ok, err = pcall(function()
			store:SetAsync(key(profile.UserId), snapshot)
		end)
		if ok then
			return true
		end
		warn("[SlapTheBlob] Save failed (" .. attempt .. "/3): " .. tostring(err))
		if attempt < 3 then
			task.wait(1)
		end
	end
	return false
end

function Data.HasStore()
	return store ~= nil
end

--------------------------------------------------------------------------
-- Profile
--------------------------------------------------------------------------
function Data.Get(player)
	local profile = Data.Profiles[player]
	if profile and profile.Loaded then
		return profile
	end
	return nil
end

function Data.CreateProfile(player)
	local profile = {
		Player = player,
		UserId = player.UserId,
		Data = Data.Default(),
		Loaded = false,
		CanSave = false,
		-- nur zur Laufzeit:
		LastSlap = 0,
		LastWarning = 0,
		Combo = 0,
		LastHit = 0,
		JoinTime = os.clock(),
		RobuxHands = {}, -- [HandId] = true (aus Game Pass, wird nie gespeichert)
		Leaderstats = nil,
	}
	Data.Profiles[player] = profile
	return profile
end

function Data.RemoveProfile(player)
	local profile = Data.Profiles[player]
	Data.Profiles[player] = nil
	return profile
end

--------------------------------------------------------------------------
-- Geld & Statistiken
--------------------------------------------------------------------------
function Data.AddSlaps(profile, amount)
	amount = math.floor(tonumber(amount) or 0)
	if amount <= 0 or amount ~= amount or amount == math.huge then
		return 0
	end
	profile.Data.Slaps = profile.Data.Slaps + amount
	profile.Data.TotalEarned = profile.Data.TotalEarned + amount
	return amount
end

function Data.AddGems(profile, amount)
	amount = math.floor(tonumber(amount) or 0)
	if amount <= 0 then
		return 0
	end
	profile.Data.Gems = profile.Data.Gems + amount
	return amount
end

function Data.AddBoost(profile, boostId, seconds)
	if not Config.Boosts[boostId] then
		return
	end
	local now = os.time()
	local current = tonumber(profile.Data.Boosts[boostId]) or 0
	if current < now then
		current = now
	end
	profile.Data.Boosts[boostId] = current + math.floor(seconds)
end

-- Stellt sicher, dass die Quests zum heutigen Tag gehoeren
function Data.RefreshQuests(profile)
	local today = Calc.GetDayNumber(os.time())
	local quests = profile.Data.Quests
	if quests.Day ~= today then
		quests.Day = today
		quests.Progress = {}
		quests.Claimed = {}
		for i = 1, Config.QuestsPerDay do
			quests.Progress[i] = 0
			quests.Claimed[i] = false
		end
		return true
	end
	return false
end

-- Quest-Fortschritt erhoehen. "BestCombo" zaehlt den Hoechstwert.
function Data.AddStat(profile, stat, amount)
	Data.RefreshQuests(profile)
	local quests = Calc.GetQuests(profile.Data.Quests.Day, profile.UserId)
	local changed = false
	for i, quest in ipairs(quests) do
		if quest.Stat == stat and not profile.Data.Quests.Claimed[i] then
			local before = profile.Data.Quests.Progress[i] or 0
			local after
			if stat == "BestCombo" then
				after = math.max(before, amount)
			else
				after = before + amount
			end
			if after > quest.Amount then
				after = quest.Amount
			end
			if after ~= before then
				profile.Data.Quests.Progress[i] = after
				changed = true
				if after >= quest.Amount and before < quest.Amount then
					Remotes.Notify(profile.Player, "📜 Quest complete: " .. quest.Text .. " - claim your reward!", { 255, 230, 120 })
				end
			end
		end
	end
	return changed
end

--------------------------------------------------------------------------
-- An den Client senden
--------------------------------------------------------------------------
local function updateLeaderstats(profile)
	if profile.Leaderstats then
		profile.Leaderstats.Slaps.Value = Calc.FormatNumber(profile.Data.Slaps)
		profile.Leaderstats.Rebirths.Value = profile.Data.Rebirths
		profile.Leaderstats.Gems.Value = profile.Data.Gems
	end
end

-- full = true: alles senden (nach Kaeufen). false: nur Zahlen (nach Slaps).
function Data.Push(player, full)
	local profile = Data.Get(player)
	if not profile then
		return
	end
	updateLeaderstats(profile)
	local payload
	if full then
		Data.RefreshQuests(profile)
		payload = deepCopy(profile.Data)
		payload.Full = true
		payload.RobuxHands = deepCopy(profile.RobuxHands)
	else
		local d = profile.Data
		payload = {
			Full = false,
			Slaps = d.Slaps,
			Gems = d.Gems,
			TotalSlaps = d.TotalSlaps,
			TotalEarned = d.TotalEarned,
			TotalDefeats = d.TotalDefeats,
			BestCombo = d.BestCombo,
			Quests = deepCopy(d.Quests),
		}
	end
	payload.ServerTime = os.time()
	Remotes.Fire("State", player, payload)
end

function Data.CreateLeaderstats(profile)
	local player = profile.Player
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"

	local slaps = Instance.new("StringValue")
	slaps.Name = "Slaps"
	slaps.Value = "0"
	slaps.Parent = folder

	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Parent = folder

	local gems = Instance.new("IntValue")
	gems.Name = "Gems"
	gems.Parent = folder

	folder.Parent = player
	profile.Leaderstats = { Slaps = slaps, Rebirths = rebirths, Gems = gems }
end

function Data.Init(ctx)
	Remotes = ctx.Remotes
end

-- Alle 2 Minuten speichern
function Data.StartAutosave()
	task.spawn(function()
		while true do
			task.wait(Config.AutosaveInterval)
			for _, profile in pairs(Data.Profiles) do
				if profile.Loaded then
					task.spawn(Data.Save, profile)
				end
			end
		end
	end)
end

function Data.SaveAllBlocking()
	local pending = 0
	for _, profile in pairs(Data.Profiles) do
		if profile.Loaded then
			pending = pending + 1
			task.spawn(function()
				Data.Save(profile)
				pending = pending - 1
			end)
		end
	end
	local started = os.clock()
	while pending > 0 and os.clock() - started < 25 do
		task.wait(0.1)
	end
end


return Data
