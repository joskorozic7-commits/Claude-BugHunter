--[[
	TradeUI: Pets handeln.
	  * "Trade"-Fenster: Spielerliste mit "Request"-Knopf
	  * Anfrage-Popup (Annehmen / Ablehnen)
	  * Handelsfenster: eigene Pets anklicken, beide Angebote, Bereit / Bestaetigen / Abbrechen
]]

local Players = game:GetService("Players")

local TradeUI = {}
local ctx, UI, Config, Calc, Create

local player = Players.LocalPlayer
local listWindow, playerList
local requestFrame, requestLabel, requestFrom
local tradeWindow, myGrid, myOfferGrid, theirOfferGrid, statusLabel, readyButton, confirmButton, partnerLabel
local current = nil -- letztes Update vom Server
local myOffer = {} -- Liste von Uids

local function petCard(parent, petId, order, onClick, highlight)
	local cfg = Config.Pets[petId]
	if not cfg then
		return
	end
	local rarity = Config.Rarities[cfg.Rarity]
	local card = Create("TextButton", {
		LayoutOrder = order,
		BackgroundColor3 = highlight and UI.Colors.GreenDark or UI.Colors.Panel,
		AutoButtonColor = onClick ~= nil,
		Text = "",
		ZIndex = 6,
		Parent = parent,
	}, { UI.Corner(10), UI.Stroke(2, UI.rgb(rarity.Color)) })
	local face = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 4),
		Size = UDim2.new(0, 30, 0, 30),
		BackgroundColor3 = UI.rgb(cfg.Color),
		ZIndex = 7,
		Parent = card,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }), UI.Stroke(1.5) })
	UI.Label({ Size = UDim2.fromScale(1, 1), Text = "👀", ZIndex = 8, Parent = face })
	UI.Label({ Position = UDim2.new(0, 2, 0, 36), Size = UDim2.new(1, -4, 0, 16), Text = cfg.DisplayName, ZIndex = 7, Parent = card })
	UI.Label({ Position = UDim2.new(0, 2, 0, 52), Size = UDim2.new(1, -4, 0, 12), Font = UI.BodyFont, TextColor3 = UI.rgb(rarity.Color), Text = rarity.DisplayName, ZIndex = 7, Parent = card })
	if onClick then
		card.Activated:Connect(onClick)
	end
	return card
end

local function clear(container)
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

local function isOffered(uid)
	for _, u in ipairs(myOffer) do
		if u == uid then
			return true
		end
	end
	return false
end

local function sendOffer()
	ctx.Request("TradeSetOffer", myOffer)
end

local function refreshTrade()
	if not current then
		return
	end
	partnerLabel.Text = "🤝 Trading with " .. tostring(current.Partner)
	-- eigene Pets
	clear(myGrid)
	local state = ctx.State
	if state and state.Pets then
		local sorted = {}
		for _, pet in ipairs(state.Pets) do
			table.insert(sorted, pet)
		end
		table.sort(sorted, function(a, b)
			local ba, bb = Config.Pets[a.Id] and Config.Pets[a.Id].Boost or 0, Config.Pets[b.Id] and Config.Pets[b.Id].Boost or 0
			if ba ~= bb then
				return ba > bb
			end
			return a.Uid < b.Uid
		end)
		for order, pet in ipairs(sorted) do
			local uid = pet.Uid
			petCard(myGrid, pet.Id, order, function()
				if isOffered(uid) then
					for i, u in ipairs(myOffer) do
						if u == uid then
							table.remove(myOffer, i)
							break
						end
					end
				elseif #myOffer < Config.Trade.MaxPets then
					table.insert(myOffer, uid)
				end
				ctx.PlaySound("Click")
				sendOffer()
			end, isOffered(uid))
		end
	end
	clear(myOfferGrid)
	for order, pet in ipairs(current.MyOffer or {}) do
		petCard(myOfferGrid, pet.Id, order, nil, false)
	end
	clear(theirOfferGrid)
	for order, pet in ipairs(current.TheirOffer or {}) do
		petCard(theirOfferGrid, pet.Id, order, nil, false)
	end

	local status
	if current.MyConfirmed and not current.TheirConfirmed then
		status = "✅ Confirmed - waiting for " .. tostring(current.Partner) .. "..."
	elseif current.CountdownLeft and current.CountdownLeft > 0 then
		status = "⏱️ Check the offers! Confirm in " .. math.ceil(current.CountdownLeft) .. "..."
	elseif current.CountdownLeft then
		status = "👉 Both ready - press CONFIRM to trade!"
	else
		status = (current.MyReady and "✅ You are ready" or "⏳ You are not ready") .. "   |   " .. (current.TheirReady and "✅ They are ready" or "⏳ They are not ready")
	end
	statusLabel.Text = status
	readyButton.Text = current.MyReady and "❌ Not Ready" or "✅ Ready"
	UI.SetButtonColor(readyButton, current.MyReady and UI.Colors.Gray or UI.Colors.Green)
	local canConfirm = current.CountdownLeft ~= nil and current.CountdownLeft <= 0 and not current.MyConfirmed
	confirmButton.Visible = current.CountdownLeft ~= nil
	UI.SetButtonColor(confirmButton, canConfirm and UI.Colors.Gold or UI.Colors.Gray)
end

local function buildListWindow()
	listWindow = UI.CreateWindow(ctx.Screen, "Trade", "Trade Pets", "🤝", Vector2.new(480, 420))
	UI.Label({ Size = UDim2.new(1, 0, 0, 24), Font = UI.BodyFont, TextColor3 = UI.Colors.SubText, Text = "Pick a player to send a trade request:", ZIndex = 6, Parent = listWindow.Content })
	playerList = UI.ScrollList(listWindow.Content, { Position = UDim2.new(0, 0, 0, 30), Size = UDim2.new(1, 0, 1, -30) })
	listWindow.Refresh = function()
		for _, child in ipairs(playerList:GetChildren()) do
			if child:IsA("Frame") or child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		local count = 0
		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= player then
				count = count + 1
				local row = UI.Row(playerList, 56, count)
				UI.Label({ Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0.6, -12, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Text = "👤 " .. other.DisplayName, ZIndex = 6, Parent = row })
				local userId = other.UserId
				UI.Button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0.35, 0, 0, 40), Color = UI.Colors.Blue, Text = "Request", ZIndex = 6, Parent = row }, function()
					ctx.Request("TradeRequest", userId)
				end)
			end
		end
		if count == 0 then
			UI.Label({ Size = UDim2.new(1, -10, 0, 40), Font = UI.BodyFont, TextColor3 = UI.Colors.SubText, Text = "Nobody else is on this server yet.", ZIndex = 6, Parent = playerList })
		end
	end
end

local function buildRequestPopup()
	requestFrame = Create("Frame", {
		Name = "TradeRequest",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 110),
		Size = UDim2.new(0, 280, 0, 110),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Visible = false,
		ZIndex = 15,
		Parent = ctx.Screen,
	}, { UI.Corner(14), UI.Stroke(3, UI.Colors.Blue), UI.Gradient(UI.Colors.Dark, UI.Colors.Darker) })
	requestLabel = UI.Label({ Position = UDim2.new(0, 10, 0, 8), Size = UDim2.new(1, -20, 0, 40), TextWrapped = true, Text = "", ZIndex = 16, Parent = requestFrame })
	UI.Button({ Position = UDim2.new(0, 10, 1, -50), Size = UDim2.new(0.5, -15, 0, 40), Color = UI.Colors.Green, Text = "Accept", ZIndex = 16, Parent = requestFrame }, function()
		requestFrame.Visible = false
		if requestFrom then
			ctx.Request("TradeRespond", requestFrom, true)
		end
	end)
	UI.Button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 1, -50), Size = UDim2.new(0.5, -15, 0, 40), Color = UI.Colors.Red, Text = "Decline", ZIndex = 16, Parent = requestFrame }, function()
		requestFrame.Visible = false
		if requestFrom then
			ctx.Request("TradeRespond", requestFrom, false)
		end
	end)
end

local function buildTradeWindow()
	tradeWindow = UI.CreateWindow(ctx.Screen, "TradeSession", "Trade", "🤝", Vector2.new(700, 520))
	local content = tradeWindow.Content
	partnerLabel = UI.Label({ Size = UDim2.new(1, 0, 0, 24), TextXAlignment = Enum.TextXAlignment.Left, Text = "", ZIndex = 6, Parent = content })
	UI.Label({ Position = UDim2.new(0, 0, 0, 28), Size = UDim2.new(0.5, -6, 0, 18), Font = UI.BodyFont, TextColor3 = UI.Colors.SubText, Text = "Your offer (max " .. Config.Trade.MaxPets .. ")", ZIndex = 6, Parent = content })
	UI.Label({ Position = UDim2.new(0.5, 6, 0, 28), Size = UDim2.new(0.5, -6, 0, 18), Font = UI.BodyFont, TextColor3 = UI.Colors.SubText, Text = "Their offer", ZIndex = 6, Parent = content })
	local offerBoxProps = { Size = UDim2.new(0.5, -6, 0, 150), Grid = UDim2.new(0, 70, 0, 68) }
	offerBoxProps.Position = UDim2.new(0, 0, 0, 48)
	myOfferGrid = UI.ScrollList(content, offerBoxProps)
	theirOfferGrid = UI.ScrollList(content, { Position = UDim2.new(0.5, 6, 0, 48), Size = UDim2.new(0.5, -6, 0, 150), Grid = UDim2.new(0, 70, 0, 68) })
	for _, grid in ipairs({ myOfferGrid, theirOfferGrid }) do
		grid.BackgroundTransparency = 0.4
		grid.BackgroundColor3 = UI.Colors.Darker
	end
	UI.Label({ Position = UDim2.new(0, 0, 0, 204), Size = UDim2.new(1, 0, 0, 18), Font = UI.BodyFont, TextColor3 = UI.Colors.SubText, Text = "Your pets - click to add or remove:", ZIndex = 6, Parent = content })
	myGrid = UI.ScrollList(content, { Position = UDim2.new(0, 0, 0, 224), Size = UDim2.new(1, 0, 1, -300), Grid = UDim2.new(0, 70, 0, 68) })
	statusLabel = UI.Label({ AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, -50), Size = UDim2.new(1, 0, 0, 22), Font = UI.BodyFont, TextColor3 = UI.Colors.Gold, Text = "", ZIndex = 6, Parent = content })
	readyButton = UI.Button({ AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, -4), Size = UDim2.new(0.32, -6, 0, 42), Color = UI.Colors.Green, Text = "✅ Ready", ZIndex = 6, Parent = content }, function()
		ctx.Request("TradeReady", not (current and current.MyReady))
	end)
	confirmButton = UI.Button({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -4), Size = UDim2.new(0.32, -6, 0, 42), Color = UI.Colors.Gold, Text = "🤝 CONFIRM", ZIndex = 6, Parent = content }, function()
		ctx.Request("TradeConfirm")
	end)
	UI.Button({ AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 0, 1, -4), Size = UDim2.new(0.32, -6, 0, 42), Color = UI.Colors.Red, Text = "Cancel", ZIndex = 6, Parent = content }, function()
		ctx.Request("TradeCancel")
	end)
	tradeWindow.Refresh = refreshTrade
	-- Schliessen ueber das X bricht den Handel ab
	local close = tradeWindow.Frame:FindFirstChild("Close")
	if close then
		close.Activated:Connect(function()
			if current then
				ctx.Request("TradeCancel")
			end
		end)
	end
end

function TradeUI.OnEvent(info)
	if type(info) ~= "table" then
		return
	end
	if info.Kind == "Request" then
		requestFrom = info.FromUserId
		requestLabel.Text = "🤝 " .. tostring(info.FromName) .. " wants to trade!"
		requestFrame.Visible = true
		ctx.PlaySound("Popup", 1.2)
		local myFrom = requestFrom
		task.delay(tonumber(info.Timeout) or 30, function()
			if requestFrom == myFrom then
				requestFrame.Visible = false
			end
		end)
	elseif info.Kind == "Update" then
		local firstUpdate = current == nil
		current = info
		myOffer = {}
		for _, pet in ipairs(info.MyOffer or {}) do
			table.insert(myOffer, pet.Uid)
		end
		if firstUpdate or UI.OpenWindow ~= "TradeSession" then
			UI.Open("TradeSession")
		else
			refreshTrade()
		end
		-- Countdown im Text weiterzaehlen
		if info.CountdownLeft and info.CountdownLeft > 0 then
			local mine = info
			task.spawn(function()
				local endsAt = os.clock() + info.CountdownLeft
				while current == mine and os.clock() < endsAt do
					current.CountdownLeft = endsAt - os.clock()
					refreshTrade()
					task.wait(0.25)
				end
				if current == mine then
					current.CountdownLeft = 0
					refreshTrade()
				end
			end)
		end
	elseif info.Kind == "Closed" then
		current = nil
		myOffer = {}
		UI.Close("TradeSession")
		if info.Reason ~= "Done" then
			ctx.Hud.Notify("🤝 Trade closed: " .. tostring(info.Reason), { 255, 180, 120 })
		end
	end
end

function TradeUI.Init(context)
	ctx = context
	UI = ctx.UI
	Config = ctx.Config
	Calc = ctx.Calc
	Create = UI.Create
	buildListWindow()
	buildRequestPopup()
	buildTradeWindow()
	ctx.OnState(function(_, full)
		if full and current and UI.OpenWindow == "TradeSession" then
			refreshTrade()
		end
	end)
end

return TradeUI
