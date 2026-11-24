--[[
	SlapServer (Script in ServerScriptService)

	Startet alle Server-Module von "Slap the Gyatt" und verbindet sie.
	Die einzelnen Systeme liegen als ModuleScripts unter diesem Skript.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SlapShared")
local Config = require(Shared:WaitForChild("Config"))

local Remotes = require(script:WaitForChild("Remotes"))
local Data = require(script:WaitForChild("Data"))
local World = require(script:WaitForChild("World"))
local Gyatts = require(script:WaitForChild("Gyatts"))
local Hands = require(script:WaitForChild("Hands"))
local Combat = require(script:WaitForChild("Combat"))
local Shop = require(script:WaitForChild("Shop"))
local Pets = require(script:WaitForChild("Pets"))
local Rewards = require(script:WaitForChild("Rewards"))
local Leaderboards = require(script:WaitForChild("Leaderboards"))

--------------------------------------------------------------------------
-- Gemeinsamer Kontext fuer alle Module
--------------------------------------------------------------------------
local actions = {}

local ctx = {
	Players = Players,
	Remotes = Remotes,
	Data = Data,
	World = World,
	Gyatts = Gyatts,
	Hands = Hands,
	Combat = Combat,
	Shop = Shop,
	Pets = Pets,
	Rewards = Rewards,
	Leaderboards = Leaderboards,
}

function ctx.RegisterAction(name, handler)
	actions[name] = handler
end

-- Karte zuerst bauen (andere Module brauchen die Positionen)
World.Build()

for _, module in ipairs({ Data, Gyatts, Hands, Combat, Shop, Pets, Rewards, Leaderboards }) do
	module.Init(ctx)
end

Gyatts.Start()
Combat.Start()
Shop.Start()
Pets.Start()
Leaderboards.Start()
Data.StartAutosave()

--------------------------------------------------------------------------
-- Anfragen vom Client (mit Schutz gegen Spam)
--------------------------------------------------------------------------
local requestBudget = {} -- [Player] = { count, windowStart }

ctx.RegisterAction("RequestState", function(player)
	Data.Push(player, true)
	Gyatts.SendEventState(player)
end)

Remotes.Events.Request.OnServerEvent:Connect(function(player, action, a, b)
	if type(action) ~= "string" then
		return
	end
	local now = os.clock()
	local budget = requestBudget[player]
	if not budget or now - budget.Start > 1 then
		budget = { Count = 0, Start = now }
		requestBudget[player] = budget
	end
	budget.Count = budget.Count + 1
	if budget.Count > 25 then
		return -- zu viele Anfragen pro Sekunde
	end
	local handler = actions[action]
	if not handler then
		return
	end
	local ok, err = pcall(handler, player, a, b)
	if not ok then
		warn("[SlapTheGyatt] Error in action '" .. action .. "': " .. tostring(err))
	end
end)

--------------------------------------------------------------------------
-- Spieler
--------------------------------------------------------------------------
local function onCharacterAdded(player, character)
	local profile = Data.Get(player)
	if not profile then
		return
	end
	character:WaitForChild("Humanoid", 10)
	player:WaitForChild("Backpack", 10)
	if player.Character ~= character or not player.Parent then
		return
	end
	Hands.Give(player, true)
end

local function onPlayerAdded(player)
	local profile = Data.CreateProfile(player)
	Data.CreateLeaderstats(profile)

	local ok, data = Data.Load(player)
	if not player.Parent then
		Data.RemoveProfile(player)
		return
	end
	profile.Data = data
	profile.Loaded = true
	profile.CanSave = ok
	Data.RefreshQuests(profile)

	if not ok then
		if RunService:IsStudio() then
			Remotes.Notify(player, "⚠️ Saving off: in Studio turn on 'Game Settings > Security > Enable Studio Access to API Services'.", { 255, 200, 120 })
		else
			Remotes.Notify(player, "⚠️ Your data could not be loaded. Progress will not be saved this session.", { 255, 120, 120 })
		end
	end

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end

	Pets.UpdateAttribute(player)
	Data.Push(player, true)
	Gyatts.SendEventState(player)
	Remotes.Notify(player, "👋 Welcome to " .. Config.GameName .. "! Slap the Gyatts and become the strongest!", { 255, 170, 220 })
	if data.TotalSlaps == 0 then
		Remotes.Popup(player, "WELCOME!", "Walk to the Baby Gyatt and click to slap it!", { 255, 170, 220 })
	end
end

local function onPlayerRemoving(player)
	requestBudget[player] = nil
	local profile = Data.RemoveProfile(player)
	if profile and profile.Loaded then
		profile.Data.PlayTime = profile.Data.PlayTime + math.floor(os.clock() - profile.JoinTime)
		Data.Save(profile)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

game:BindToClose(function()
	Data.SaveAllBlocking()
end)

print("[SlapTheGyatt] Server v" .. Config.Version .. " started - have fun slapping!")
