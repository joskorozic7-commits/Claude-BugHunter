--[[
	Menus: alle Fenster.
	  Shop (Upgrades), Haende, Pets, Zonen, Gem-Shop, Rebirth,
	  Quests, Taegliche Belohnung, Codes, Optionen
]]

local Menus = {}
local ctx, UI, Config, Calc, Create, C

local function state()
	return ctx.State
end

local function smallLabel(props)
	props.Font = props.Font or UI.BodyFont
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	props.ZIndex = props.ZIndex or 6
	return UI.Label(props)
end

local function title(props)
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	props.ZIndex = props.ZIndex or 6
	local label = UI.Label(props)
	UI.TextStroke(1.5).Parent = label
	return label
end

local function money(amount, currency)
	return (currency == "Gems" and "💎 " or "👋 ") .. Calc.FormatNumber(amount)
end

--------------------------------------------------------------------------
-- Shop (Upgrades)
--------------------------------------------------------------------------
local function buildShop()
	local win = UI.CreateWindow(ctx.Screen, "Shop", "Hand Upgrades", "🛒", Vector2.new(580, 470))
	local list = UI.ScrollList(win.Content, {})
	local rows = {}
	for order, id in ipairs(Config.UpgradeOrder) do
		local upgrade = Config.Upgrades[id]
		local row = UI.Row(list, 92, order)
		title({ Position = UDim2.new(0, 12, 0, 6), Size = UDim2.new(0.58, -12, 0, 26), Text = upgrade.Icon .. " " .. upgrade.DisplayName, Parent = row })
		local level = smallLabel({ Position = UDim2.new(0, 12, 0, 33), Size = UDim2.new(0.58, -12, 0, 16), TextColor3 = UI.Colors.SubText, Parent = row })
		local stat = smallLabel({ Position = UDim2.new(0, 12, 0, 51), Size = UDim2.new(0.58, -12, 0, 16), TextColor3 = UI.Colors.Text, Parent = row })
		local _, fill = UI.ProgressBar({ Position = UDim2.new(0, 12, 0, 72), Size = UDim2.new(0.58, -12, 0, 10), Parent = row })
		local buy = UI.Button({
			Name = "Buy",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -10, 0, 8),
			Size = UDim2.new(0.4, -14, 0, 44),
			Color = UI.Colors.Green,
			ZIndex = 6,
			Parent = row,
		}, function()
			ctx.Request("BuyUpgrade", id)
		end)
		local max = UI.Button({
			Name = "Max",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -10, 0, 56),
			Size = UDim2.new(0.4, -14, 0, 28),
			Color = UI.Colors.Purple,
			Text = "Buy MAX",
			ZIndex = 6,
			Parent = row,
		}, function()
			ctx.Request("BuyUpgradeMax", id)
		end)
		rows[id] = { Level = level, Stat = stat, Fill = fill, Buy = buy, Max = max }
	end

	win.Refresh = function()
		local s = state()
		if not s or not s.Upgrades then
			return
		end
		for _, id in ipairs(Config.UpgradeOrder) do
			local row = rows[id]
			local upgrade = Config.Upgrades[id]
			local level = Calc.ClampLevel(id, s.Upgrades[id])
			local cost = Calc.GetUpgradeCost(id, level)
			row.Level.Text = "Level " .. level .. " / " .. upgrade.MaxLevel .. "  -  " .. upgrade.Description
			UI.SetProgress(row.Fill, level / upgrade.MaxLevel)
			if cost then
				row.Stat.Text = Calc.DescribeUpgrade(id, level) .. "  ➜  " .. Calc.DescribeUpgrade(id, level + 1)
				row.Buy.Text = money(cost, "Slaps")
				UI.SetButtonColor(row.Buy, s.Slaps >= cost and UI.Colors.Green or UI.Colors.Gray)
				row.Max.Visible = true
			else
				row.Stat.Text = Calc.DescribeUpgrade(id, level)
				row.Buy.Text = "MAX"
				UI.SetButtonColor(row.Buy, UI.Colors.Gold)
				row.Max.Visible = false
			end
		end
	end
	return win
end

--------------------------------------------------------------------------
-- Haende
--------------------------------------------------------------------------
local function buildHands()
	local win = UI.CreateWindow(ctx.Screen, "Hands", "Hands", "✋", Vector2.new(580, 470))
	local list = UI.ScrollList(win.Content, {})
	local rows = {}
	for order, hand in ipairs(Config.Hands) do
		local row = UI.Row(list, 70, order)
		local swatch = Create("Frame", {
			Position = UDim2.new(0, 10, 0.5, -24),
			Size = UDim2.new(0, 48, 0, 48),
			BackgroundColor3 = UI.rgb(hand.Color),
			ZIndex = 6,
			Parent = row,
		}, { UI.Corner(12), UI.Stroke(2) })
		UI.Label({ Size = UDim2.fromScale(1, 1), Text = "✋", ZIndex = 7, Parent = swatch })
		title({ Position = UDim2.new(0, 68, 0, 8), Size = UDim2.new(0.55, -68, 0, 28), Text = hand.DisplayName, Parent = row })
		local effectNames = { sparkles = "Sparkles", fire = "Fire", smoke = "Frost Mist", rainbow = "Rainbow" }
		local effect = effectNames[hand.Effect] and ("  ✨ " .. effectNames[hand.Effect]) or ""
		smallLabel({ Position = UDim2.new(0, 68, 0, 38), Size = UDim2.new(0.55, -68, 0, 20), TextColor3 = UI.Colors.Gold,
			Text = "x" .. hand.Damage .. " Damage" .. effect, Parent = row })
		local button = UI.Button({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.new(0.38, -10, 0, 46),
			ZIndex = 6,
			Parent = row,
		}, function()
			local s = state()
			if s and s.OwnedHands and s.OwnedHands[hand.Id] then
				ctx.Request("EquipHand", hand.Id)
			else
				ctx.Request("BuyHand", hand.Id)
			end
		end)
		rows[hand.Id] = { Row = row, Button = button }
	end

	win.Refresh = function()
		local s = state()
		if not s or not s.OwnedHands then
			return
		end
		for _, hand in ipairs(Config.Hands) do
			local r = rows[hand.Id]
			local stroke = r.Row:FindFirstChildOfClass("UIStroke")
			if s.Hand == hand.Id then
				r.Button.Text = "✅ Equipped"
				UI.SetButtonColor(r.Button, UI.Colors.GreenDark)
				if stroke then
					stroke.Color = UI.Colors.Gold
				end
			elseif s.OwnedHands[hand.Id] then
				r.Button.Text = "Equip"
				UI.SetButtonColor(r.Button, UI.Colors.Blue)
				if stroke then
					stroke.Color = UI.Colors.PanelLight
				end
			else
				local balance = hand.Currency == "Gems" and s.Gems or s.Slaps
				r.Button.Text = money(hand.Price, hand.Currency)
				UI.SetButtonColor(r.Button, balance >= hand.Price and UI.Colors.Green or UI.Colors.Gray)
				if stroke then
					stroke.Color = UI.Colors.PanelLight
				end
			end
		end
	end
	return win
end

--------------------------------------------------------------------------
-- Pets
--------------------------------------------------------------------------
local function buildPets()
	local win = UI.CreateWindow(ctx.Screen, "Pets", "Pets", "🐾", Vector2.new(620, 500))
	local header = smallLabel({ Size = UDim2.new(1, 0, 0, 22), TextColor3 = UI.Colors.Gold, Parent = win.Content })
	local buttons = Create("Frame", {
		Position = UDim2.new(0, 0, 0, 26),
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		ZIndex = 5,
		Parent = win.Content,
	}, { UI.List(8, true) })
	UI.Button({ Size = UDim2.new(0, 170, 1, 0), Color = UI.Colors.Green, Text = "⭐ Equip Best", LayoutOrder = 1, ZIndex = 6, Parent = buttons }, function()
		ctx.Request("EquipBestPets")
	end)
	UI.Button({ Size = UDim2.new(0, 200, 1, 0), Color = UI.Colors.Red, Text = "🗑️ Delete Commons", LayoutOrder = 2, ZIndex = 6, Parent = buttons }, function()
		ctx.Request("DeleteRarity", "Common")
	end)

	local grid = UI.ScrollList(win.Content, {
		Position = UDim2.new(0, 0, 0, 68),
		Size = UDim2.new(1, 0, 1, -128),
		Grid = UDim2.new(0, 108, 0, 112),
	})

	-- Auswahl unten
	local detail = Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 54),
		BackgroundColor3 = UI.Colors.Panel,
		ZIndex = 5,
		Parent = win.Content,
	}, { UI.Corner(12) })
	local detailText = smallLabel({ Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(0.45, -10, 1, 0), Text = "Click a pet", Parent = detail })
	local selectedUid = nil
	local equipButton = UI.Button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -118, 0.5, 0), Size = UDim2.new(0, 140, 0, 40), Color = UI.Colors.Blue, Text = "Equip", ZIndex = 6, Parent = detail }, function()
		local s = state()
		if not selectedUid or not s then
			return
		end
		for _, pet in ipairs(s.Pets or {}) do
			if pet.Uid == selectedUid then
				ctx.Request(pet.Equipped and "UnequipPet" or "EquipPet", selectedUid)
				return
			end
		end
	end)
	local deleteButton = UI.Button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 104, 0, 40), Color = UI.Colors.Red, Text = "🗑️ Delete", ZIndex = 6, Parent = detail }, function()
		if selectedUid then
			ctx.Request("DeletePet", selectedUid)
			selectedUid = nil
		end
	end)

	local function refreshDetail(s)
		local selected = nil
		for _, pet in ipairs(s.Pets or {}) do
			if pet.Uid == selectedUid then
				selected = pet
			end
		end
		if not selected then
			selectedUid = nil
			detailText.Text = "Click a pet"
			equipButton.Visible = false
			deleteButton.Visible = false
			return
		end
		local cfg = Config.Pets[selected.Id]
		local rarity = Config.Rarities[cfg.Rarity]
		detailText.Text = cfg.DisplayName .. " (" .. rarity.DisplayName .. ")  +" .. Calc.FormatNumber(math.floor(cfg.Boost * 100)) .. "% Slaps"
		detailText.TextColor3 = UI.rgb(rarity.Color)
		equipButton.Visible = true
		deleteButton.Visible = not selected.Equipped
		equipButton.Text = selected.Equipped and "Unequip" or "Equip"
		UI.SetButtonColor(equipButton, selected.Equipped and UI.Colors.Gray or UI.Colors.Blue)
	end

	local lastSignature = nil
	win.Refresh = function()
		local s = state()
		if not s or not s.Pets then
			return
		end
		local equipped = Calc.GetEquippedPetIds(s)
		header.Text = "🐾 Equipped: " .. #equipped .. "/" .. Calc.GetPetSlots(s)
			.. "    🎒 " .. #s.Pets .. "/" .. Calc.GetInventorySize(s)
			.. "    💰 Pet Bonus: " .. Calc.FormatMultiplier(Calc.GetPetBoost(equipped))

		-- Karten nur neu bauen, wenn sich die Pets geaendert haben
		local parts = {}
		for _, pet in ipairs(s.Pets) do
			table.insert(parts, pet.Uid .. (pet.Equipped and "E" or "") .. ((pet.Uid == selectedUid) and "S" or ""))
		end
		local signature = table.concat(parts, ",")
		if signature ~= lastSignature then
			lastSignature = signature
			for _, child in ipairs(grid:GetChildren()) do
				if child:IsA("TextButton") then
					child:Destroy()
				end
			end
			local sorted = {}
			for _, pet in ipairs(s.Pets) do
				table.insert(sorted, pet)
			end
			table.sort(sorted, function(a, b)
				if a.Equipped ~= b.Equipped then
					return a.Equipped
				end
				local ba, bb = Config.Pets[a.Id].Boost, Config.Pets[b.Id].Boost
				if ba ~= bb then
					return ba > bb
				end
				return a.Uid < b.Uid
			end)
			for order, pet in ipairs(sorted) do
				local cfg = Config.Pets[pet.Id]
				local rarity = Config.Rarities[cfg.Rarity]
				local card = Create("TextButton", {
					Name = "Pet_" .. pet.Uid,
					LayoutOrder = order,
					BackgroundColor3 = UI.Colors.Panel,
					AutoButtonColor = true,
					Text = "",
					ZIndex = 6,
					Parent = grid,
				}, {
					UI.Corner(12),
					UI.Stroke(pet.Uid == selectedUid and 4 or 2.5, pet.Uid == selectedUid and UI.Colors.White or UI.rgb(rarity.Color)),
				})
				local face = Create("Frame", {
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.new(0.5, 0, 0, 8),
					Size = UDim2.new(0, 44, 0, 44),
					BackgroundColor3 = UI.rgb(cfg.Color),
					ZIndex = 7,
					Parent = card,
				}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }), UI.Stroke(2) })
				UI.Label({ Size = UDim2.fromScale(1, 1), Text = "👀", ZIndex = 8, Parent = face })
				local nameLabel = UI.Label({ Position = UDim2.new(0, 4, 0, 54), Size = UDim2.new(1, -8, 0, 20), Text = cfg.DisplayName, ZIndex = 7, Parent = card })
				UI.TextStroke(1).Parent = nameLabel
				UI.Label({ Position = UDim2.new(0, 4, 0, 74), Size = UDim2.new(1, -8, 0, 16), Font = UI.BodyFont, TextColor3 = UI.rgb(rarity.Color), Text = rarity.DisplayName, ZIndex = 7, Parent = card })
				UI.Label({ Position = UDim2.new(0, 4, 0, 90), Size = UDim2.new(1, -8, 0, 16), Font = UI.BodyFont, TextColor3 = UI.Colors.Gold, Text = "+" .. Calc.FormatNumber(math.floor(cfg.Boost * 100)) .. "%", ZIndex = 7, Parent = card })
				if pet.Equipped then
					UI.Label({ Position = UDim2.new(0, 4, 0, 4), Size = UDim2.new(0, 22, 0, 22), Text = "✅", ZIndex = 8, Parent = card })
				end
				card.Activated:Connect(function()
					selectedUid = pet.Uid
					ctx.PlaySound("Click")
					lastSignature = nil
					win.Refresh()
				end)
			end
		end
		refreshDetail(s)
	end
	return win
end

--------------------------------------------------------------------------
-- Zonen
--------------------------------------------------------------------------
local function buildZones()
	local win = UI.CreateWindow(ctx.Screen, "Zones", "Zones & Teleport", "🗺️", Vector2.new(580, 480))
	local list = UI.ScrollList(win.Content, {})
	local hubRow = UI.Row(list, 56, 0)
	title({ Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0.6, -12, 1, 0), Text = "🏠 Hub (Spawn, Arena, Leaderboards)", Parent = hubRow })
	UI.Button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0.35, 0, 0, 40), Color = UI.Colors.Blue, Text = "Teleport", ZIndex = 6, Parent = hubRow }, function()
		ctx.Request("Teleport", 0)
		UI.Close("Zones")
	end)
	local rows = {}
	for index, zone in ipairs(Config.Zones) do
		local row = UI.Row(list, 76, index)
		Create("Frame", { Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(0, 10, 1, 0), BackgroundColor3 = UI.rgb(zone.Accent), ZIndex = 6, Parent = row }, { UI.Corner(8) })
		title({ Position = UDim2.new(0, 18, 0, 6), Size = UDim2.new(0.6, -18, 0, 28), Text = "Zone " .. index .. ": " .. zone.Name, Parent = row })
		local names = {}
		for _, g in ipairs(zone.Gyatts) do
			table.insert(names, g.DisplayName)
		end
		local egg = Config.Eggs[zone.Egg]
		smallLabel({ Position = UDim2.new(0, 18, 0, 36), Size = UDim2.new(0.6, -18, 0, 16), TextColor3 = UI.Colors.SubText, Text = table.concat(names, " & ") .. "  •  " .. (egg and egg.DisplayName or ""), Parent = row })
		local status = smallLabel({ Position = UDim2.new(0, 18, 0, 54), Size = UDim2.new(0.6, -18, 0, 16), Parent = row })
		local button = UI.Button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0.35, 0, 0, 46), ZIndex = 6, Parent = row }, function()
			local s = state()
			if s and index <= (s.Zones or 1) then
				ctx.Request("Teleport", index)
				UI.Close("Zones")
			else
				ctx.Request("UnlockZone", index)
			end
		end)
		rows[index] = { Status = status, Button = button }
	end
	win.Refresh = function()
		local s = state()
		if not s then
			return
		end
		local unlocked = s.Zones or 1
		for index, zone in ipairs(Config.Zones) do
			local r = rows[index]
			if index <= unlocked then
				r.Status.Text = "✅ Unlocked"
				r.Status.TextColor3 = UI.Colors.Green
				r.Button.Text = "Teleport"
				UI.SetButtonColor(r.Button, UI.Colors.Blue)
			elseif index == unlocked + 1 then
				r.Status.Text = "🔒 Unlock for " .. money(zone.Price, "Slaps")
				r.Status.TextColor3 = UI.Colors.Gold
				r.Button.Text = money(zone.Price, "Slaps")
				UI.SetButtonColor(r.Button, s.Slaps >= zone.Price and UI.Colors.Green or UI.Colors.Gray)
			else
				r.Status.Text = "🔒 Unlock Zone " .. (index - 1) .. " first"
				r.Status.TextColor3 = UI.Colors.SubText
				r.Button.Text = "🔒"
				UI.SetButtonColor(r.Button, UI.Colors.Gray)
			end
		end
	end
	return win
end

--------------------------------------------------------------------------
-- Gem-Shop
--------------------------------------------------------------------------
local function buildGems()
	local win = UI.CreateWindow(ctx.Screen, "Gems", "Gem Shop", "💎", Vector2.new(580, 470))
	local balance = smallLabel({ Size = UDim2.new(1, 0, 0, 24), TextColor3 = Color3.fromRGB(140, 220, 255), Parent = win.Content })
	local list = UI.ScrollList(win.Content, { Position = UDim2.new(0, 0, 0, 30), Size = UDim2.new(1, 0, 1, -30) })
	local rows = {}
	for order, item in ipairs(Config.GemShop) do
		local row = UI.Row(list, 72, order)
		title({ Position = UDim2.new(0, 12, 0, 6), Size = UDim2.new(0.6, -12, 0, 28), Text = item.Icon .. " " .. item.DisplayName, Parent = row })
		local desc = smallLabel({ Position = UDim2.new(0, 12, 0, 38), Size = UDim2.new(0.6, -12, 0, 26), TextColor3 = UI.Colors.SubText, TextWrapped = true, Text = item.Description, Parent = row })
		local button = UI.Button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0.35, 0, 0, 46), ZIndex = 6, Parent = row }, function()
			ctx.Request("BuyGemItem", item.Id)
		end)
		rows[item.Id] = { Button = button, Desc = desc }
	end
	smallLabel({ Size = UDim2.new(1, -10, 0, 40), LayoutOrder = 100, TextWrapped = true, TextColor3 = UI.Colors.SubText,
		Text = "💡 You get Gems from defeated Gyatts, quests, daily rewards, codes, rebirths and the Golden Gyatt!", Parent = list })

	win.Refresh = function()
		local s = state()
		if not s or not s.GemShop then
			return
		end
		balance.Text = "Your Gems: 💎 " .. Calc.FormatNumber(s.Gems)
		local now = ctx.Now()
		for _, item in ipairs(Config.GemShop) do
			local r = rows[item.Id]
			local owned = s.GemShop[item.Id] or 0
			local price = Calc.GetGemItemPrice(item.Id, owned)
			local extra = ""
			if item.Boost and s.Boosts then
				local left = (tonumber(s.Boosts[item.Boost]) or 0) - now
				if left > 0 then
					extra = "  ⏱️ active: " .. Calc.FormatTime(left)
				end
			elseif not item.Repeatable then
				extra = "  (" .. owned .. "/" .. #item.Prices .. ")"
			end
			r.Desc.Text = item.Description .. extra
			if price then
				r.Button.Text = "💎 " .. Calc.FormatNumber(price)
				UI.SetButtonColor(r.Button, s.Gems >= price and UI.Colors.Green or UI.Colors.Gray)
			else
				r.Button.Text = "✅ Bought"
				UI.SetButtonColor(r.Button, UI.Colors.Gold)
			end
		end
	end
	return win
end

--------------------------------------------------------------------------
-- Rebirth
--------------------------------------------------------------------------
local function buildRebirth()
	local win = UI.CreateWindow(ctx.Screen, "Rebirth", "Rebirth", "♻️", Vector2.new(520, 400))
	local info = smallLabel({ Size = UDim2.new(1, 0, 0, 170), TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, TextScaled = true, Parent = win.Content })
	local _, fill = UI.ProgressBar({ Position = UDim2.new(0, 0, 0, 182), Size = UDim2.new(1, 0, 0, 22), Color = UI.Colors.Purple, Parent = win.Content })
	local progressText = UI.Label({ Position = UDim2.new(0, 0, 0, 182), Size = UDim2.new(1, 0, 0, 22), ZIndex = 8, Text = "", Parent = win.Content })
	UI.TextStroke(1.5).Parent = progressText
	local button = UI.Button({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -6),
		Size = UDim2.new(0.8, 0, 0, 60),
		Color = UI.Colors.Purple,
		ZIndex = 6,
		Parent = win.Content,
	}, function()
		ctx.Request("Rebirth")
	end)
	win.Refresh = function()
		local s = state()
		if not s then
			return
		end
		local cost = Calc.GetRebirthCost(s.Rebirths)
		local nextCount = (s.Rebirths or 0) + 1
		info.Text = "You have " .. (s.Rebirths or 0) .. " rebirths.\n\n"
			.. "A rebirth resets your Slaps, upgrades and zones.\n"
			.. "Hands, pets and Gems are kept!\n\n"
			.. "After that, forever:\n"
			.. "💰 " .. Calc.FormatMultiplier(Calc.GetRebirthSlapMultiplier(nextCount)) .. " Slaps   "
			.. "💪 " .. Calc.FormatMultiplier(Calc.GetRebirthDamageMultiplier(nextCount)) .. " Damage   "
			.. "💎 +" .. Calc.GetRebirthGems(nextCount) .. " Gems"
		UI.SetProgress(fill, s.Slaps / cost)
		progressText.Text = Calc.FormatNumber(s.Slaps) .. " / " .. Calc.FormatNumber(cost)
		if s.Slaps >= cost then
			button.Text = "♻️ REBIRTH NOW!"
			UI.SetButtonColor(button, UI.Colors.Purple)
		else
			button.Text = "Need " .. money(cost - s.Slaps, "Slaps")
			UI.SetButtonColor(button, UI.Colors.Gray)
		end
	end
	return win
end

--------------------------------------------------------------------------
-- Quests
--------------------------------------------------------------------------
local function buildQuests()
	local win = UI.CreateWindow(ctx.Screen, "Quests", "Daily Quests", "📜", Vector2.new(560, 400))
	local timer = smallLabel({ Size = UDim2.new(1, 0, 0, 22), TextColor3 = UI.Colors.SubText, Parent = win.Content })
	local list = UI.ScrollList(win.Content, { Position = UDim2.new(0, 0, 0, 28), Size = UDim2.new(1, 0, 1, -28) })
	local rows = {}
	for i = 1, Config.QuestsPerDay do
		local row = UI.Row(list, 84, i)
		local text = title({ Position = UDim2.new(0, 12, 0, 8), Size = UDim2.new(0.6, -12, 0, 26), Parent = row })
		local reward = smallLabel({ Position = UDim2.new(0, 12, 0, 36), Size = UDim2.new(0.6, -12, 0, 16), TextColor3 = Color3.fromRGB(140, 220, 255), Parent = row })
		local _, fill = UI.ProgressBar({ Position = UDim2.new(0, 12, 0, 58), Size = UDim2.new(0.6, -12, 0, 16), Color = UI.Colors.Gold, Parent = row })
		local progress = UI.Label({ Position = UDim2.new(0, 12, 0, 58), Size = UDim2.new(0.6, -12, 0, 16), ZIndex = 8, Font = UI.BodyFont, Parent = row })
		local button = UI.Button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0.34, 0, 0, 46), ZIndex = 6, Parent = row }, function()
			ctx.Request("ClaimQuest", i)
		end)
		rows[i] = { Text = text, Reward = reward, Fill = fill, Progress = progress, Button = button }
	end
	win.Refresh = function()
		local s = state()
		if not s or not s.Quests then
			return
		end
		local now = ctx.Now()
		local secondsLeft = 86400 - (now % 86400)
		timer.Text = "⏱️ New quests in " .. Calc.FormatTime(secondsLeft)
		local quests = Calc.GetQuests(s.Quests.Day, ctx.Player.UserId)
		for i, quest in ipairs(quests) do
			local r = rows[i]
			if r then
				local value = (s.Quests.Progress and s.Quests.Progress[i]) or 0
				local claimed = s.Quests.Claimed and s.Quests.Claimed[i]
				r.Text.Text = quest.Text
				r.Reward.Text = "Reward: 💎 " .. quest.Gems
				UI.SetProgress(r.Fill, value / quest.Amount)
				r.Progress.Text = Calc.FormatNumber(value) .. " / " .. Calc.FormatNumber(quest.Amount)
				if claimed then
					r.Button.Text = "✅ Done"
					UI.SetButtonColor(r.Button, UI.Colors.GreenDark)
				elseif value >= quest.Amount then
					r.Button.Text = "🎁 Claim!"
					UI.SetButtonColor(r.Button, UI.Colors.Green)
				else
					r.Button.Text = "In progress..."
					UI.SetButtonColor(r.Button, UI.Colors.Gray)
				end
			end
		end
	end
	return win
end

--------------------------------------------------------------------------
-- Taegliche Belohnung
--------------------------------------------------------------------------
local function buildDaily()
	local win = UI.CreateWindow(ctx.Screen, "Daily", "Daily Reward", "🎁", Vector2.new(600, 380))
	local grid = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 200),
		BackgroundTransparency = 1,
		ZIndex = 5,
		Parent = win.Content,
	}, {
		Create("UIGridLayout", { CellSize = UDim2.new(0.23, 0, 0, 92), CellPadding = UDim2.new(0.02, 0, 0, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }),
	})
	local cards = {}
	for day, reward in ipairs(Config.DailyRewards) do
		local card = Create("Frame", { LayoutOrder = day, BackgroundColor3 = UI.Colors.Panel, ZIndex = 6, Parent = grid }, { UI.Corner(12), UI.Stroke(2.5, UI.Colors.PanelLight) })
		title({ Size = UDim2.new(1, 0, 0, 24), Position = UDim2.new(0, 0, 0, 4), TextXAlignment = Enum.TextXAlignment.Center, Text = "Day " .. day, Parent = card })
		local text = "💎 " .. reward.Gems
		if reward.Boost then
			text = text .. "\n" .. Config.Boosts[reward.Boost].Icon .. " " .. Calc.FormatTime(reward.Duration)
		end
		smallLabel({ Position = UDim2.new(0, 4, 0, 30), Size = UDim2.new(1, -8, 0, 54), TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = true, Text = text, Parent = card })
		cards[day] = card
	end
	local status = smallLabel({ Position = UDim2.new(0, 0, 0, 206), Size = UDim2.new(1, 0, 0, 24), TextXAlignment = Enum.TextXAlignment.Center, Parent = win.Content })
	local button = UI.Button({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -4), Size = UDim2.new(0.6, 0, 0, 54), Color = UI.Colors.Green, ZIndex = 6, Parent = win.Content }, function()
		ctx.Request("ClaimDaily")
	end)
	win.Refresh = function()
		local s = state()
		if not s then
			return
		end
		local canClaim, day, waitSeconds = Calc.GetDailyStatus(s, ctx.Now())
		local streak = (s.Daily and s.Daily.Streak) or 0
		for d, card in ipairs(cards) do
			local stroke = card:FindFirstChildOfClass("UIStroke")
			local claimedAlready = (not canClaim and d <= streak) or (canClaim and d < day)
			if (canClaim and d == day) then
				card.BackgroundColor3 = UI.Colors.GreenDark
				if stroke then
					stroke.Color = UI.Colors.Gold
				end
			elseif claimedAlready then
				card.BackgroundColor3 = UI.Colors.Darker
				if stroke then
					stroke.Color = UI.Colors.Green
				end
			else
				card.BackgroundColor3 = UI.Colors.Panel
				if stroke then
					stroke.Color = UI.Colors.PanelLight
				end
			end
		end
		if canClaim then
			status.Text = "Streak: Day " .. day .. " is ready!"
			button.Text = "🎁 Claim!"
			UI.SetButtonColor(button, UI.Colors.Green)
		else
			status.Text = "Streak: " .. streak .. " days  •  Next reward in " .. Calc.FormatTime(waitSeconds)
			button.Text = "⏱️ " .. Calc.FormatTime(waitSeconds)
			UI.SetButtonColor(button, UI.Colors.Gray)
		end
	end
	return win
end

--------------------------------------------------------------------------
-- Codes
--------------------------------------------------------------------------
local function buildCodes()
	local win = UI.CreateWindow(ctx.Screen, "Codes", "Codes", "🎟️", Vector2.new(480, 300))
	smallLabel({ Size = UDim2.new(1, 0, 0, 26), TextXAlignment = Enum.TextXAlignment.Center, Text = "Enter a code and get rewards!", Parent = win.Content })
	local box = Create("TextBox", {
		Position = UDim2.new(0.1, 0, 0, 40),
		Size = UDim2.new(0.8, 0, 0, 54),
		BackgroundColor3 = UI.Colors.Darker,
		Font = UI.Font,
		TextScaled = true,
		TextColor3 = UI.Colors.White,
		PlaceholderText = "Enter code here...",
		PlaceholderColor3 = UI.Colors.SubText,
		Text = "",
		ClearTextOnFocus = false,
		ZIndex = 6,
		Parent = win.Content,
	}, { UI.Corner(12), UI.Stroke(3, UI.Colors.Pink), UI.Padding(10, 8) })
	UI.Button({ Position = UDim2.new(0.25, 0, 0, 108), Size = UDim2.new(0.5, 0, 0, 52), Color = UI.Colors.Green, Text = "✅ Redeem", ZIndex = 6, Parent = win.Content }, function()
		if #box.Text > 0 then
			ctx.Request("RedeemCode", box.Text)
			box.Text = ""
		end
	end)
	smallLabel({ Position = UDim2.new(0, 0, 0, 172), Size = UDim2.new(1, 0, 0, 40), TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = true, TextColor3 = UI.Colors.Gold,
		Text = "💡 Tip: Try GYATT, SLAP or RELEASE!", Parent = win.Content })
	return win
end

--------------------------------------------------------------------------
-- Optionen & Statistik
--------------------------------------------------------------------------
local SETTING_TEXT = {
	{ "Sounds", "🔊 Sounds" },
	{ "DamageNumbers", "🔢 Damage Numbers" },
	{ "Shake", "📳 Camera Shake" },
	{ "OtherPets", "🐾 Other Players' Pets" },
}

local function buildSettings()
	local win = UI.CreateWindow(ctx.Screen, "Settings", "Settings & Stats", "⚙️", Vector2.new(540, 470))
	local list = UI.ScrollList(win.Content, {})
	local toggles = {}
	for order, info in ipairs(SETTING_TEXT) do
		local name, text = info[1], info[2]
		local row = UI.Row(list, 56, order)
		title({ Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0.6, -12, 1, 0), Text = text, Parent = row })
		toggles[name] = UI.Button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0, 110, 0, 40), ZIndex = 6, Parent = row }, function()
			ctx.Request("SetSetting", name, not ctx.Setting(name))
		end)
	end
	local statsRow = UI.Row(list, 190, 10)
	local stats = smallLabel({ Position = UDim2.new(0, 12, 0, 8), Size = UDim2.new(1, -24, 1, -16), TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Parent = statsRow })
	win.Refresh = function()
		local s = state()
		if not s then
			return
		end
		for name, button in pairs(toggles) do
			local on = ctx.Setting(name)
			button.Text = on and "AN" or "AUS"
			UI.SetButtonColor(button, on and UI.Colors.Green or UI.Colors.Gray)
		end
		local hand = Calc.GetHand(s.Hand)
		stats.Text = "📊 YOUR STATS\n"
			.. "👋 Total slaps: " .. Calc.FormatNumber(s.TotalSlaps) .. "\n"
			.. "💰 Total earned: " .. Calc.FormatNumber(s.TotalEarned) .. "\n"
			.. "💥 Gyatts defeated: " .. Calc.FormatNumber(s.TotalDefeats) .. "\n"
			.. "🔥 Best combo: " .. Calc.FormatNumber(s.BestCombo) .. "\n"
			.. "♻️ Rebirths: " .. tostring(s.Rebirths) .. "\n"
			.. "✋ Hand: " .. hand.DisplayName .. "   🐾 Pets: " .. #(s.Pets or {}) .. "\n"
			.. "⏱️ Playtime: " .. Calc.FormatTime(s.PlayTime or 0)
	end
	return win
end

--------------------------------------------------------------------------
function Menus.Init(context)
	ctx = context
	UI = ctx.UI
	Config = ctx.Config
	Calc = ctx.Calc
	Create = UI.Create
	C = UI.Colors

	buildShop()
	buildHands()
	buildPets()
	buildZones()
	buildGems()
	buildRebirth()
	buildQuests()
	buildDaily()
	buildCodes()
	buildSettings()

	-- offenes Fenster bei jeder Aenderung aktualisieren
	ctx.OnState(function()
		local open = UI.OpenWindow
		if open and UI.Windows[open] and UI.Windows[open].Refresh then
			UI.Windows[open].Refresh()
		end
	end)
	-- Timer in offenen Fenstern weiterlaufen lassen
	task.spawn(function()
		while true do
			task.wait(1)
			local open = UI.OpenWindow
			if (open == "Daily" or open == "Quests" or open == "Gems") and UI.Windows[open].Refresh and ctx.State then
				UI.Windows[open].Refresh()
			end
		end
	end)
end

return Menus
