--[[
	SlapClient (LocalScript in StarterPlayer > StarterPlayerScripts)

	Startet die komplette Client-Seite von "Slap the Blob":
	Menues, HUD, Effekte, Pets, Welt-Animationen.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("SlapShared")
local Config = require(Shared:WaitForChild("Config"))
local Calc = require(Shared:WaitForChild("Calc"))
local remotes = ReplicatedStorage:WaitForChild("SlapRemotes")

local UI = require(script:WaitForChild("UI"))
local Hud = require(script:WaitForChild("Hud"))
local Menus = require(script:WaitForChild("Menus"))
local Effects = require(script:WaitForChild("Effects"))
local WorldFx = require(script:WaitForChild("WorldFx"))
local PetsFx = require(script:WaitForChild("PetsFx"))
local Hatch = require(script:WaitForChild("Hatch"))

local old = playerGui:FindFirstChild("SlapUI")
if old then
	old:Destroy()
end
local screen = UI.Create("ScreenGui", {
	Name = "SlapUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = playerGui,
})

--------------------------------------------------------------------------
-- Kontext
--------------------------------------------------------------------------
local ctx = {
	Player = player,
	Config = Config,
	Calc = Calc,
	UI = UI,
	Screen = screen,
	Remotes = remotes,
	State = nil,
	TimeOffset = 0,
}

local listeners = {}
function ctx.OnState(fn)
	table.insert(listeners, fn)
end

function ctx.Request(action, a, b)
	remotes.Request:FireServer(action, a, b)
end

function ctx.Now()
	return os.time() + ctx.TimeOffset
end

function ctx.Setting(name)
	local state = ctx.State
	if state and state.Settings and state.Settings[name] ~= nil then
		return state.Settings[name]
	end
	return true
end

-- Sounds (nur eingebaute Roblox-Sounds, damit garantiert nichts fehlt)
local SOUNDS = {
	Click = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.35, Speed = 1.6 },
	Buy = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.6, Speed = 1.2 },
	Denied = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.5, Speed = 0.6 },
	Crit = { Id = "rbxasset://sounds/swordlunge.wav", Volume = 0.7, Speed = 1 },
	Popup = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.7, Speed = 0.9 },
	Hatch = { Id = "rbxasset://sounds/unsheath.wav", Volume = 0.7, Speed = 1 },
	Whoosh = { Id = "rbxasset://sounds/swordslash.wav", Volume = 0.5, Speed = 0.7 },
}
local soundTemplates = {}
for name, info in pairs(SOUNDS) do
	local sound = Instance.new("Sound")
	sound.Name = "Slap_" .. name
	sound.SoundId = info.Id
	sound.Volume = info.Volume
	sound.PlaybackSpeed = info.Speed
	sound.Parent = SoundService
	soundTemplates[name] = sound
end

function ctx.PlaySound(name, speedFactor)
	if not ctx.Setting("Sounds") then
		return
	end
	local template = soundTemplates[name]
	if not template then
		return
	end
	local sound = template:Clone()
	sound.PlaybackSpeed = template.PlaybackSpeed * (speedFactor or 1)
	sound.Parent = SoundService
	sound:Play()
	Debris:AddItem(sound, 3)
end

--------------------------------------------------------------------------
-- Module starten
--------------------------------------------------------------------------
ctx.Hud = Hud
ctx.Menus = Menus
ctx.Effects = Effects
ctx.WorldFx = WorldFx
ctx.PetsFx = PetsFx
ctx.Hatch = Hatch

Hud.Init(ctx)
Menus.Init(ctx)
Effects.Init(ctx)
WorldFx.Init(ctx)
PetsFx.Init(ctx)
Hatch.Init(ctx)

UI.OnWindowOpened = function()
	ctx.PlaySound("Click")
end

--------------------------------------------------------------------------
-- Spielstand vom Server
--------------------------------------------------------------------------
remotes.State.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end
	if type(payload.ServerTime) == "number" then
		ctx.TimeOffset = payload.ServerTime - os.time()
	end
	if payload.Full or not ctx.State then
		ctx.State = payload
	else
		for key, value in pairs(payload) do
			ctx.State[key] = value
		end
	end
	for _, fn in ipairs(listeners) do
		local ok, err = pcall(fn, ctx.State, payload.Full == true)
		if not ok then
			warn("[SlapTheBlob] UI error: " .. tostring(err))
		end
	end
end)

remotes.Notify.OnClientEvent:Connect(function(text, color)
	Hud.Notify(text, color)
end)

remotes.Popup.OnClientEvent:Connect(function(title, subtitle, color)
	Hud.Popup(title, subtitle, color)
	ctx.PlaySound("Popup")
end)

remotes.Event.OnClientEvent:Connect(function(kind, a, b)
	if kind == "Purchased" then
		ctx.PlaySound("Buy")
	elseif kind == "Denied" then
		ctx.PlaySound("Denied")
	elseif kind == "GoldenStart" then
		Hud.SetGoldenEvent(a, b)
		ctx.PlaySound("Popup", 1.3)
	elseif kind == "GoldenEnd" then
		Hud.SetGoldenEvent(nil, nil)
	end
end)

remotes.SlapFx.OnClientEvent:Connect(function(info)
	if type(info) == "table" then
		Effects.OnSlap(info)
		WorldFx.OnSlap(info)
		if info.UserId == player.UserId and info.Kind == "Gyatt" then
			Hud.SetCombo(info.Combo)
		end
	end
end)

remotes.Defeat.OnClientEvent:Connect(function(key, position, radius, isGolden)
	Effects.OnDefeat(key, position, radius, isGolden)
end)

remotes.Knockback.OnClientEvent:Connect(function(velocity, attackerName)
	Effects.OnKnockback(velocity, attackerName)
end)

remotes.Hatch.OnClientEvent:Connect(function(result)
	Hatch.Play(result)
end)

remotes.Request:FireServer("RequestState")
