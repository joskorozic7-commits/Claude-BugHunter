--[[
	Remotes: legt alle RemoteEvents an und bietet kleine Helfer.

	Client -> Server:  Request(action, ...)
	Server -> Client:  State, Notify, SlapFx, Hatch, Popup, Knockback, Event, Defeat
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}
Remotes.Events = {}

local folder = ReplicatedStorage:FindFirstChild("SlapRemotes")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "SlapRemotes"
	folder.Parent = ReplicatedStorage
end

local NAMES = { "Request", "State", "Notify", "SlapFx", "Hatch", "Popup", "Knockback", "Event", "Defeat" }

for _, name in ipairs(NAMES) do
	local remote = folder:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end
	Remotes.Events[name] = remote
end

local WHITE = { 255, 255, 255 }

function Remotes.Notify(player, text, color)
	if player and player.Parent then
		Remotes.Events.Notify:FireClient(player, text, color or WHITE)
	end
end

function Remotes.NotifyAll(text, color)
	Remotes.Events.Notify:FireAllClients(text, color or WHITE)
end

-- Grosses Popup in der Bildschirmmitte (z.B. "NEW HAND!")
function Remotes.Popup(player, title, subtitle, color)
	if player and player.Parent then
		Remotes.Events.Popup:FireClient(player, title, subtitle or "", color or WHITE)
	end
end

function Remotes.Fire(name, player, ...)
	if player and player.Parent then
		Remotes.Events[name]:FireClient(player, ...)
	end
end

function Remotes.FireAll(name, ...)
	Remotes.Events[name]:FireAllClients(...)
end

return Remotes
