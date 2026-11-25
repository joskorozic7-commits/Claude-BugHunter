--[[
	Trade: Pets zwischen Spielern tauschen.

	Ablauf:
	  1. Spieler A schickt eine Anfrage an B
	  2. B nimmt an -> beide sehen das Handelsfenster
	  3. Jeder waehlt bis zu 8 Pets
	  4. Beide druecken "Bereit" -> 3 Sekunden Countdown
	  5. Beide bestaetigen -> der Server prueft alles nochmal und tauscht

	Jede Aenderung am Angebot setzt "Bereit" bei beiden zurueck (Schutz vor Betrug).
	Alles wird auf dem Server geprueft, der Client zeigt nur an.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SlapShared")
local Config = require(Shared:WaitForChild("Config"))
local Calc = require(Shared:WaitForChild("Calc"))

local Trade = {}
local ctx

local T = Config.Trade
local RED = { 255, 120, 120 }
local GREEN = { 120, 255, 140 }

local requests = {} -- [Ziel-Spieler] = { [Absender-Spieler] = Zeit }
local trades = {} -- [Spieler] = Handel

function Trade.IsTrading(player)
	return trades[player] ~= nil
end

local function partner(trade, player)
	if trade.A == player then
		return trade.B
	end
	return trade.A
end

local function findPet(data, uid)
	for i, pet in ipairs(data.Pets) do
		if pet.Uid == uid then
			return pet, i
		end
	end
	return nil
end

local function offerPayload(data, uids)
	local list = {}
	for _, uid in ipairs(uids) do
		local pet = findPet(data, uid)
		if pet then
			table.insert(list, { Uid = pet.Uid, Id = pet.Id })
		end
	end
	return list
end

local function push(trade)
	local now = os.clock()
	for _, player in ipairs({ trade.A, trade.B }) do
		local other = partner(trade, player)
		local myProfile = ctx.Data.Get(player)
		local otherProfile = ctx.Data.Get(other)
		if myProfile and otherProfile then
			ctx.Remotes.Fire("Trade", player, {
				Kind = "Update",
				Partner = other.DisplayName,
				MyOffer = offerPayload(myProfile.Data, trade.Offers[player]),
				TheirOffer = offerPayload(otherProfile.Data, trade.Offers[other]),
				MyReady = trade.Ready[player] == true,
				TheirReady = trade.Ready[other] == true,
				MyConfirmed = trade.Confirmed[player] == true,
				TheirConfirmed = trade.Confirmed[other] == true,
				CountdownLeft = trade.CountdownEnd and math.max(0, trade.CountdownEnd - now) or nil,
			})
		end
	end
end

local function close(trade, reason)
	if trade.Closed then
		return
	end
	trade.Closed = true
	for _, player in ipairs({ trade.A, trade.B }) do
		if trades[player] == trade then
			trades[player] = nil
		end
		ctx.Remotes.Fire("Trade", player, { Kind = "Closed", Reason = reason })
	end
end

local function resetReady(trade)
	trade.Ready = {}
	trade.Confirmed = {}
	trade.CountdownEnd = nil
end

function Trade.Request(player, targetUserId)
	local profile = ctx.Data.Get(player)
	if not profile or type(targetUserId) ~= "number" then
		return
	end
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target or target == player or not ctx.Data.Get(target) then
		return
	end
	if trades[player] or trades[target] then
		ctx.Remotes.Notify(player, "🤝 One of you is already trading.", RED)
		return
	end
	if ctx.Duel.IsInDuel(player) or ctx.Duel.IsInDuel(target) then
		ctx.Remotes.Notify(player, "🤝 You can't trade during a duel.", RED)
		return
	end
	local now = os.clock()
	if profile.LastTradeRequest and now - profile.LastTradeRequest < 3 then
		return
	end
	profile.LastTradeRequest = now
	requests[target] = requests[target] or {}
	requests[target][player] = now
	ctx.Remotes.Fire("Trade", target, { Kind = "Request", FromUserId = player.UserId, FromName = player.DisplayName, Timeout = T.RequestTimeout })
	ctx.Remotes.Notify(player, "🤝 Trade request sent to " .. target.DisplayName .. ".", GREEN)
end

function Trade.Respond(player, fromUserId, accept)
	if type(fromUserId) ~= "number" then
		return
	end
	local from = Players:GetPlayerByUserId(fromUserId)
	local pending = requests[player]
	local sentAt = pending and from and pending[from]
	if pending and from then
		pending[from] = nil
	end
	if not from or not sentAt or os.clock() - sentAt > T.RequestTimeout then
		ctx.Remotes.Notify(player, "🤝 That trade request expired.", RED)
		return
	end
	if accept ~= true then
		ctx.Remotes.Notify(from, "🤝 " .. player.DisplayName .. " declined your trade.", RED)
		return
	end
	if trades[player] or trades[from] or not ctx.Data.Get(from) or not ctx.Data.Get(player) then
		ctx.Remotes.Notify(player, "🤝 The trade could not start.", RED)
		return
	end
	if ctx.Duel.IsInDuel(player) or ctx.Duel.IsInDuel(from) then
		return
	end
	local trade = { A = from, B = player, Offers = { [from] = {}, [player] = {} }, Ready = {}, Confirmed = {}, CountdownEnd = nil, Closed = false }
	trades[from] = trade
	trades[player] = trade
	push(trade)
end

function Trade.SetOffer(player, uids)
	local trade = trades[player]
	local profile = ctx.Data.Get(player)
	if not trade or not profile or type(uids) ~= "table" then
		return
	end
	local clean = {}
	local seen = {}
	for _, uid in ipairs(uids) do
		if #clean >= T.MaxPets then
			break
		end
		if type(uid) == "number" and not seen[uid] and findPet(profile.Data, uid) then
			seen[uid] = true
			table.insert(clean, uid)
		end
	end
	trade.Offers[player] = clean
	resetReady(trade)
	push(trade)
end

function Trade.SetReady(player, ready)
	local trade = trades[player]
	if not trade then
		return
	end
	trade.Ready[player] = ready == true
	trade.Confirmed = {}
	if trade.Ready[trade.A] and trade.Ready[trade.B] then
		trade.CountdownEnd = os.clock() + T.Countdown
		local myTrade = trade
		task.delay(T.Countdown + 0.05, function()
			if not myTrade.Closed and trades[myTrade.A] == myTrade then
				push(myTrade)
			end
		end)
	else
		trade.CountdownEnd = nil
	end
	push(trade)
end

local function execute(trade)
	local a, b = trade.A, trade.B
	local pa, pb = ctx.Data.Get(a), ctx.Data.Get(b)
	if not pa or not pb then
		close(trade, "A player left.")
		return
	end
	-- nochmal alles pruefen
	for _, side in ipairs({ { pa, trade.Offers[a] }, { pb, trade.Offers[b] } }) do
		for _, uid in ipairs(side[2]) do
			if not findPet(side[1].Data, uid) then
				close(trade, "A pet in the trade is gone.")
				return
			end
		end
	end
	local sizeA = #pa.Data.Pets - #trade.Offers[a] + #trade.Offers[b]
	local sizeB = #pb.Data.Pets - #trade.Offers[b] + #trade.Offers[a]
	if sizeA > Calc.GetInventorySize(pa.Data) or sizeB > Calc.GetInventorySize(pb.Data) then
		close(trade, "Not enough pet storage.")
		return
	end
	if #trade.Offers[a] == 0 and #trade.Offers[b] == 0 then
		close(trade, "Nothing to trade.")
		return
	end

	local function take(profile, uids)
		local taken = {}
		for _, uid in ipairs(uids) do
			local pet, index = findPet(profile.Data, uid)
			if pet then
				table.remove(profile.Data.Pets, index)
				table.insert(taken, pet.Id)
			end
		end
		return taken
	end
	local function give(profile, petIds)
		for _, petId in ipairs(petIds) do
			table.insert(profile.Data.Pets, { Uid = profile.Data.NextPetUid, Id = petId, Equipped = false })
			profile.Data.NextPetUid = profile.Data.NextPetUid + 1
		end
	end
	local fromA = take(pa, trade.Offers[a])
	local fromB = take(pb, trade.Offers[b])
	give(pa, fromB)
	give(pb, fromA)
	pa.Data.TotalTrades = (pa.Data.TotalTrades or 0) + 1
	pb.Data.TotalTrades = (pb.Data.TotalTrades or 0) + 1

	close(trade, "Done")
	for _, info in ipairs({ { a, pa, #fromB }, { b, pb, #fromA } }) do
		local player, profile, count = info[1], info[2], info[3]
		ctx.Pets.UpdateAttribute(player)
		ctx.Remotes.Popup(player, "TRADE COMPLETE!", "You got " .. count .. " pet" .. (count == 1 and "" or "s") .. ".", { 120, 255, 160 })
		ctx.Remotes.Fire("Event", player, "Purchased")
		ctx.Data.Push(player, true)
		task.spawn(ctx.Data.Save, profile)
	end
end

function Trade.Confirm(player)
	local trade = trades[player]
	if not trade or not trade.CountdownEnd then
		return
	end
	if not (trade.Ready[trade.A] and trade.Ready[trade.B]) or os.clock() < trade.CountdownEnd then
		return
	end
	trade.Confirmed[player] = true
	if trade.Confirmed[trade.A] and trade.Confirmed[trade.B] then
		execute(trade)
	else
		push(trade)
	end
end

function Trade.Cancel(player)
	local trade = trades[player]
	if trade then
		close(trade, player.DisplayName .. " cancelled the trade.")
	end
end

function Trade.OnLeave(player)
	requests[player] = nil
	for _, pending in pairs(requests) do
		pending[player] = nil
	end
	local trade = trades[player]
	if trade then
		close(trade, player.DisplayName .. " left the game.")
	end
end

function Trade.Init(context)
	ctx = context
	ctx.RegisterAction("TradeRequest", Trade.Request)
	ctx.RegisterAction("TradeRespond", Trade.Respond)
	ctx.RegisterAction("TradeSetOffer", Trade.SetOffer)
	ctx.RegisterAction("TradeReady", Trade.SetReady)
	ctx.RegisterAction("TradeConfirm", Trade.Confirm)
	ctx.RegisterAction("TradeCancel", Trade.Cancel)
end

return Trade
