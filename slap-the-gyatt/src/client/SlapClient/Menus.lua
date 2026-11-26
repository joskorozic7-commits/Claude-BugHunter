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
	local win = UI.CreateWindow(ctx.Screen, "Shop", "Hand Upgrades", "🛒", Vector2.new(600, 480))
	local list = UI.ScrollList(win.Content, {})
	UI.Label({ Size = UDim2.new(1, -10, 0, 34), LayoutOrder = 0, Font = UI.BodyFont, TextWrapped = true, TextColor3 = UI.Colors.SubText,
		Text = "Every 10 levels you need a ⚡ TIER UP (Slaps + Gems). Each new tier gives a much bigger bonus!", ZIndex = 6, Parent = list })
	local rows = {}
	for order, id in ipairs(Config.UpgradeOrder) do
		local upgrade = Config.Upgrades[id]
		local row = UI.Row(list, 104, order)
		title({ Position = UDim2.new(0, 12, 0, 6), Size = UDim2.new(0.42, -12, 0, 26), Text = upgrade.Icon .. " " .. upgrade.DisplayName, Parent = row })
		local tierBadge = UI.Label({ Position = UDim2.new(0.42, 0, 0, 9), Size = UDim2.new(0.18, -6, 0, 20), BackgroundTransparency = 0, Font = UI.Font,
			TextColor3 = Color3.fromRGB(30, 15, 35), Text = "", ZIndex = 7, Parent = row })
		UI.Corner(6).Parent = tierBadge
		local level = smallLabel({ Position = UDim2.new(0, 12, 0, 35), Size = UDim2.new(0.6, -12, 0, 16), TextColor3 = UI.Colors.SubText, Parent = row })
		local stat = smallLabel({ Position = UDim2.new(0, 12, 0, 53), Size = UDim2.new(0.6, -12, 0, 16), TextColor3 = UI.Colors.Text, Parent = row })
		local _, fill = UI.ProgressBar({ Position = UDim2.new(0, 12, 0, 76), Size = UDim2.new(0.6, -12, 0, 12), Parent = row })
		local buy = UI.Button({
			Name = "Buy",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -10, 0, 8),
			Size = UDim2.new(0.38, -14, 0, 52),
			Color = UI.Colors.Green,
			ZIndex = 6,
			Parent = row,
		}, function()
			ctx.Request("BuyUpgrade", id)
		end)
		local max = UI.Button({
			Name = "Max",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -10, 0, 66),
			Size = UDim2.new(0.38, -14, 0, 30),
			Color = UI.Colors.Purple,
			Text = "Buy MAX",
			ZIndex = 6,
			Parent = row,
		}, function()
			ctx.Request("BuyUpgradeMax", id)
		end)
		rows[id] = { Level = level, Stat = stat, Fill = fill, Buy = buy, Max = max, Tier = tierBadge }
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
			local cost, gems = Calc.GetUpgradeCost(id, level)
			local tierInfo = Calc.GetTierInfo(Calc.GetTier(level))
			row.Tier.Text = string.upper(tierInfo.Name)
			row.Tier.BackgroundColor3 = UI.rgb(tierInfo.Color)
			row.Level.Text = "Level " .. level .. " / " .. upgrade.MaxLevel .. "  -  " .. upgrade.Description
			-- Fortschritt innerhalb der aktuellen Tier
			UI.SetProgress(row.Fill, (level % Config.TierSize) / Config.TierSize)
			if level >= upgrade.MaxLevel then
				UI.SetProgress(row.Fill, 1)
			end
			if cost then
				row.Stat.Text = Calc.DescribeUpgrade(id, level) .. "  ➜  " .. Calc.DescribeUpgrade(id, level + 1)
				if gems > 0 then
					local nextTier = Calc.GetTierInfo(Calc.GetTier(level + 1))
					row.Buy.Text = "⚡ TIER UP → " .. nextTier.Name .. "\n" .. money(cost, "Slaps") .. " + " .. money(gems, "Gems")
					UI.SetButtonColor(row.Buy, (s.Slaps >= cost and s.Gems >= gems) and UI.Colors.Gold or UI.Colors.Gray)
				else
					row.Buy.Text = money(cost, "Slaps")
					UI.SetButtonColor(row.Buy, s.Slaps >= cost and UI.Colors.Green or UI.Colors.Gray)
				end
				row.Max.Visible = gems == 0
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
	local win = UI.CreateWindow(ctx.Screen, "Hands", "Gloves", "✋", Vector2.new(620, 500))
	local tabBar = Create("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, ZIndex = 5, Parent = win.Content }, { UI.List(8, true) })
	local list = UI.ScrollList(win.Content, { Position = UDim2.new(0, 0, 0, 44), Size = UDim2.new(1, 0, 1, -44) })
	local rows = {}
	local currentTab = "Slaps"
	local tabButtons = {}
	local function applyFilter()
		for _, hand in ipairs(Config.Hands) do
			local r = rows[hand.Id]
			if r then
				r.Row.Visible = hand.Currency == currentTab
			end
		end
		for name, button in pairs(tabButtons) do
			UI.SetButtonColor(button, name == currentTab and UI.Colors.Pink or UI.Colors.Gray)
		end
	end
	for order, info in ipairs({ { "Slaps", "👋 Slaps (60)" }, { "Gems", "💎 Gems" }, { "Robux", "👑 Robux" } }) do
		tabButtons[info[1]] = UI.Button({ Size = UDim2.new(0, 150, 1, 0), LayoutOrder = order, Text = info[2], ZIndex = 6, Parent = tabBar }, function()
			currentTab = info[1]
			applyFilter()
			list.CanvasPosition = Vector2.new(0, 0)
		end)
	end
	local effectNames = { sparkles = "Sparkles", fire = "Fire", smoke = "Frost Mist", rainbow = "Rainbow", dragon = "Dragon Fire", thanos = "Cosmic Stones",
		ultragod = "Divine Aura", aura = "Glow Aura", electric = "Lightning", shadow = "Shadow Smoke", orbit = "Orbiting Orbs", omni = "OMNI Aura" }
	for order, hand in ipairs(Config.Hands) do
		local rarity = Config.Rarities[hand.Rarity] or Config.Rarities.Common
		local rarityColor = UI.rgb(rarity.Color)
		local isUltra = hand.Currency == "Robux"
		local height = (hand.Perk and 104) or 84
		local row = UI.Row(list, height, order)
		if isUltra then
			row.BackgroundColor3 = Color3.fromRGB(70, 40, 20)
			UI.Create("UIGradient", {
				Color = ColorSequence.new(Color3.fromRGB(255, 230, 150), Color3.fromRGB(200, 120, 255)),
				Rotation = 0,
				Transparency = NumberSequence.new(0.6),
				Parent = row,
			})
		end
		local swatch = Create("Frame", {
			Position = UDim2.new(0, 10, 0, 12),
			Size = UDim2.new(0, 56, 0, 56),
			BackgroundColor3 = UI.rgb(hand.Color),
			ZIndex = 6,
			Parent = row,
		}, { UI.Corner(12), UI.Stroke(isUltra and 3.5 or 2, isUltra and UI.Colors.Gold or nil) })
		UI.Label({ Size = UDim2.fromScale(1, 1), Text = isUltra and (hand.Effect == "thanos" and "🫰" or "👑") or "✋", ZIndex = 7, Parent = swatch })

		title({ Position = UDim2.new(0, 76, 0, 6), Size = UDim2.new(0.58, -76, 0, 26), Text = (hand.Number and ("#" .. hand.Number .. "  ") or "") .. hand.DisplayName, Parent = row })
		local badge = UI.Label({
			Position = UDim2.new(0, 76, 0, 34),
			Size = UDim2.new(0, 96, 0, 18),
			BackgroundTransparency = 0,
			BackgroundColor3 = rarityColor,
			Font = UI.Font,
			TextColor3 = Color3.fromRGB(30, 15, 35),
			Text = string.upper(rarity.DisplayName),
			ZIndex = 7,
			Parent = row,
		})
		UI.Corner(6).Parent = badge
		local effect = effectNames[hand.Effect] and ("  ✨ " .. effectNames[hand.Effect]) or ""
		smallLabel({ Position = UDim2.new(0, 178, 0, 34), Size = UDim2.new(0.58, -178, 0, 18), TextColor3 = UI.Colors.SubText, Text = effect, Parent = row })
		smallLabel({ Position = UDim2.new(0, 76, 0, 56), Size = UDim2.new(0.58, -76, 0, 18), TextColor3 = UI.Colors.Gold, Text = Calc.DescribeHandPerks(hand), Parent = row })
		if hand.Perk then
			smallLabel({ Position = UDim2.new(0, 10, 0, 78), Size = UDim2.new(1, -20, 0, 20), TextColor3 = Color3.fromRGB(255, 240, 160), Text = hand.Perk, Parent = row })
		end
		local button = UI.Button({
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -10, 0, 14),
			Size = UDim2.new(0.36, -10, 0, 50),
			ZIndex = 6,
			Parent = row,
		}, function()
			local s = state()
			if s and Calc.OwnsHand(s, hand.Id) then
				ctx.Request("EquipHand", hand.Id)
			else
				ctx.Request("BuyHand", hand.Id)
			end
		end)
		rows[hand.Id] = { Row = row, Button = button }
	end
	applyFilter()

	win.Refresh = function()
		local s = state()
		if not s or not s.OwnedHands then
			return
		end
		for _, hand in ipairs(Config.Hands) do
			local r = rows[hand.Id]
			local stroke = r.Row:FindFirstChildOfClass("UIStroke")
			local isUltra = hand.Currency == "Robux"
			if stroke then
				stroke.Color = isUltra and UI.Colors.Gold or UI.Colors.PanelLight
			end
			if s.Hand == hand.Id then
				r.Button.Text = "✅ Equipped"
				UI.SetButtonColor(r.Button, UI.Colors.GreenDark)
				if stroke then
					stroke.Color = UI.Colors.White
				end
			elseif Calc.OwnsHand(s, hand.Id) then
				r.Button.Text = "Equip"
				UI.SetButtonColor(r.Button, UI.Colors.Blue)
			elseif isUltra then
				r.Button.Text = "R$ " .. hand.Price
				UI.SetButtonColor(r.Button, UI.Colors.Gold)
			else
				local balance = hand.Currency == "Gems" and s.Gems or s.Slaps
				r.Button.Text = money(hand.Price, hand.Currency)
				UI.SetButtonColor(r.Button, balance >= hand.Price and UI.Colors.Green or UI.Colors.Gray)
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
		local dimName = Calc.GetDimension(index).Name
		title({ Position = UDim2.new(0, 18, 0, 6), Size = UDim2.new(0.6, -18, 0, 28), Text = (index > 6 and "🌀 " or "") .. "Zone " .. index .. ": " .. zone.Name, Parent = row })
		if index > 6 then
			smallLabel({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(0.62, 0, 0, 2), Size = UDim2.new(0.25, 0, 0, 12), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = Color3.fromRGB(200, 150, 255), Text = dimName, Parent = row })
		end
		local names = {}
		for _, g in ipairs(zone.Gyatts) do
			table.insert(names, g.DisplayName)
		end
		local egg = Config.Eggs[zone.Egg]
		local mech = Config.MechanicInfo[zone.Mechanic or "none"]
		local mechText = (mech and zone.Mechanic ~= "none") and (mech.Icon .. " " .. mech.Name .. "  •  ") or ""
		smallLabel({ Position = UDim2.new(0, 18, 0, 36), Size = UDim2.new(0.6, -18, 0, 16), TextScaled = true, TextColor3 = UI.Colors.SubText, Text = mechText .. table.concat(names, ", ") .. "  •  " .. (egg and egg.DisplayName or ""), Parent = row })
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
	-- Gems fuer Robux
	UI.Label({ Size = UDim2.new(1, -10, 0, 28), LayoutOrder = -100, TextXAlignment = Enum.TextXAlignment.Left, Text = "💎 BUY GEMS", TextColor3 = Color3.fromRGB(140, 220, 255), ZIndex = 6, Parent = list })
	local packGrid = Create("Frame", { Size = UDim2.new(1, -10, 0, 236), LayoutOrder = -99, BackgroundTransparency = 1, ZIndex = 5, Parent = list }, {
		Create("UIGridLayout", { CellSize = UDim2.new(0.32, 0, 0, 110), CellPadding = UDim2.new(0.02, 0, 0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	for order, pack in ipairs(Config.GemPacks) do
		local card = Create("Frame", { LayoutOrder = order, BackgroundColor3 = UI.Colors.Panel, ZIndex = 6, Parent = packGrid }, { UI.Corner(12), UI.Stroke(2.5, Color3.fromRGB(120, 210, 255)) })
		local amount = UI.Label({ Position = UDim2.new(0, 4, 0, 6), Size = UDim2.new(1, -8, 0, 30), Text = "💎 " .. Calc.FormatNumber(pack.Gems), TextColor3 = Color3.fromRGB(150, 225, 255), ZIndex = 7, Parent = card })
		UI.TextStroke(1.5).Parent = amount
		if pack.Tag then
			local tag = UI.Label({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 38), Size = UDim2.new(0.8, 0, 0, 16), BackgroundTransparency = 0,
				BackgroundColor3 = UI.Colors.Gold, Font = UI.Font, TextColor3 = Color3.fromRGB(40, 20, 10), Text = pack.Tag, ZIndex = 7, Parent = card })
			UI.Corner(6).Parent = tag
		end
		UI.Button({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -8), Size = UDim2.new(0.86, 0, 0, 38), Color = UI.Colors.Green,
			Text = "R$ " .. pack.Robux, ZIndex = 7, Parent = card }, function()
			ctx.Request("BuyGemPack", pack.Id)
		end)
	end
	UI.Label({ Size = UDim2.new(1, -10, 0, 28), LayoutOrder = -98, TextXAlignment = Enum.TextXAlignment.Left, Text = "🛒 SPEND GEMS", TextColor3 = UI.Colors.Gold, ZIndex = 6, Parent = list })
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
		Text = "💡 You get Gems from defeated Blobs, quests, daily rewards, codes, rebirths and the Golden Blob!", Parent = list })

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
		Text = "💡 Tip: Try BLOB, SLAP or RELEASE!", Parent = win.Content })
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
	local statsRow = UI.Row(list, 220, 10)
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
			.. "💥 Blobs defeated: " .. Calc.FormatNumber(s.TotalDefeats) .. "\n"
			.. "🔥 Best combo: " .. Calc.FormatNumber(s.BestCombo) .. "\n"
			.. "♻️ Rebirths: " .. tostring(s.Rebirths) .. "\n"
			.. "✋ Hand: " .. hand.DisplayName .. "   🐾 Pets: " .. #(s.Pets or {}) .. "\n"
			.. "⏱️ Playtime: " .. Calc.FormatTime(s.PlayTime or 0) .. "\n"
			.. "⚔️ Duel wins: " .. tostring(s.DuelWins or 0) .. "   🤝 Trades: " .. tostring(s.TotalTrades or 0)
	end
	return win
end

--------------------------------------------------------------------------
-- Shop-Uebersicht (ein Knopf fuer alle Laeden)
--------------------------------------------------------------------------
local function buildShopHub()
	local win = UI.CreateWindow(ctx.Screen, "ShopHub", "Shops", "🛒", Vector2.new(560, 430))
	local grid = Create("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = 5,
		Parent = win.Content,
	}, {
		Create("UIGridLayout", { CellSize = UDim2.new(0.31, 0, 0, 108), CellPadding = UDim2.new(0.025, 0, 0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
		UI.Padding(4, 4),
	})
	local shops = {
		{ "Shop", "🛒", "Upgrades", "Slaps", { 255, 105, 180 } },
		{ "Hands", "✋", "Gloves", "Slaps · Gems · R$", { 255, 160, 60 } },
		{ "EggShop", "🥚", "Egg Shop", "Gems · R$ · Event", { 90, 190, 255 } },
		{ "ItemShop", "🎁", "Item Crates", "Slaps · Gems · R$", { 170, 110, 255 } },
		{ "Items", "🔨", "Items & Forge", "Equip · Merge", { 255, 90, 90 } },
		{ "Gems", "💎", "Gem Shop", "Gems · R$", { 80, 220, 255 } },
		{ "Codes", "🎟️", "Codes", "Free rewards", { 120, 120, 255 } },
	}
	for order, info in ipairs(shops) do
		local button = UI.Button({ LayoutOrder = order, Color = UI.rgb(info[5]), Text = "", ZIndex = 6, Parent = grid }, function()
			UI.Open(info[1])
		end)
		UI.Label({ Size = UDim2.new(1, 0, 0.45, 0), Text = info[2], ZIndex = 7, Parent = button })
		local name = UI.Label({ Position = UDim2.new(0, 0, 0.45, 0), Size = UDim2.new(1, 0, 0.3, 0), Text = info[3], ZIndex = 7, Parent = button })
		UI.TextStroke(1.5).Parent = name
		UI.Label({ Position = UDim2.new(0, 0, 0.75, 0), Size = UDim2.new(1, 0, 0.22, 0), Font = UI.BodyFont, Text = info[4], TextColor3 = Color3.fromRGB(255, 245, 255), ZIndex = 7, Parent = button })
	end
	return win
end

local function chanceText(eggId)
	local parts = {}
	for _, entry in ipairs(Calc.GetEggChances(eggId, false)) do
		local pet = Config.Pets[entry.PetId]
		table.insert(parts, pet.DisplayName .. " " .. Calc.FormatChance(entry.Chance))
	end
	return table.concat(parts, " · ")
end

local function rarityRange(eggId)
	local egg = Config.Eggs[eggId]
	local best = nil
	for _, entry in ipairs(egg.Pets) do
		local r = Config.Rarities[Config.Pets[entry[1]].Rarity]
		if not best or r.Order > best.Order then
			best = r
		end
	end
	return best
end

--------------------------------------------------------------------------
-- Eier-Shop: Event-Ei, Gem-Eier, Robux-Eier
--------------------------------------------------------------------------
local function buildEggShop()
	local win = UI.CreateWindow(ctx.Screen, "EggShop", "Egg Shop", "🥚", Vector2.new(620, 520))
	local balance = smallLabel({ Size = UDim2.new(1, 0, 0, 22), TextColor3 = Color3.fromRGB(140, 220, 255), Parent = win.Content })
	local list = UI.ScrollList(win.Content, { Position = UDim2.new(0, 0, 0, 26), Size = UDim2.new(1, 0, 1, -26) })
	local eventRows = {}

	local function eggRow(order, eggId, buttonText, onBuy, onBuy3)
		local egg = Config.Eggs[eggId]
		local best = rarityRange(eggId)
		local row = UI.Row(list, 112, order)
		Create("Frame", { Size = UDim2.new(0, 10, 1, 0), BackgroundColor3 = UI.rgb(egg.Color), ZIndex = 6, Parent = row }, { UI.Corner(8) })
		local name = title({ Position = UDim2.new(0, 18, 0, 6), Size = UDim2.new(0.6, -18, 0, 26), Text = "🥚 " .. egg.DisplayName, TextColor3 = UI.rgb(egg.Color), Parent = row })
		smallLabel({ Position = UDim2.new(0, 18, 0, 32), Size = UDim2.new(0.6, -18, 0, 16), TextColor3 = UI.rgb(best.Color), Text = "Up to " .. string.upper(best.DisplayName) .. " pets!", Parent = row })
		smallLabel({ Position = UDim2.new(0, 18, 0, 50), Size = UDim2.new(0.6, -18, 0, 56), TextWrapped = true, TextScaled = true, TextYAlignment = Enum.TextYAlignment.Top,
			TextColor3 = UI.Colors.SubText, Text = chanceText(eggId), Parent = row })
		local b1 = UI.Button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.new(0.36, 0, 0, onBuy3 and 44 or 90), Color = UI.Colors.Green,
			Text = buttonText, ZIndex = 6, Parent = row }, onBuy)
		local b3 = nil
		if onBuy3 then
			b3 = UI.Button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 58), Size = UDim2.new(0.36, 0, 0, 44), Color = UI.Colors.Purple,
				Text = "Hatch x3", ZIndex = 6, Parent = row }, onBuy3)
		end
		return { Row = row, Name = name, Buy = b1, Buy3 = b3 }
	end

	UI.Label({ Size = UDim2.new(1, -10, 0, 28), LayoutOrder = 1, TextXAlignment = Enum.TextXAlignment.Left, Text = "⭐ WEEKLY EVENT (exclusive pets!)", TextColor3 = UI.Colors.Gold, ZIndex = 6, Parent = list })
	local eventTimer = smallLabel({ Size = UDim2.new(1, -10, 0, 18), LayoutOrder = 2, TextColor3 = UI.Colors.SubText, Parent = list })
	for i, event in ipairs(Config.WeeklyEvents) do
		local eggId = event.EggId
		eventRows[event.Id] = eggRow(10 + i, eggId, "💎 " .. Calc.FormatNumber(Config.EventEggPrice), function()
			ctx.Request("Hatch", eggId, 1)
		end, function()
			ctx.Request("Hatch", eggId, 3)
		end)
	end
	UI.Label({ Size = UDim2.new(1, -10, 0, 28), LayoutOrder = 100, TextXAlignment = Enum.TextXAlignment.Left, Text = "💎 GEM EGGS", TextColor3 = Color3.fromRGB(140, 220, 255), ZIndex = 6, Parent = list })
	local gemRows = {}
	local order = 101
	for _, eggId in ipairs(Config.EggOrder) do
		local egg = Config.Eggs[eggId]
		if egg.Shop then
			gemRows[eggId] = eggRow(order, eggId, "💎 " .. Calc.FormatNumber(egg.Price), function()
				ctx.Request("Hatch", eggId, 1)
			end, function()
				ctx.Request("Hatch", eggId, 3)
			end)
			order = order + 1
		end
	end
	UI.Label({ Size = UDim2.new(1, -10, 0, 28), LayoutOrder = 200, TextXAlignment = Enum.TextXAlignment.Left, Text = "💸 ROBUX EGGS (best pets!)", TextColor3 = Color3.fromRGB(120, 255, 140), ZIndex = 6, Parent = list })
	for i, robuxEgg in ipairs(Config.RobuxEggs) do
		eggRow(200 + i, robuxEgg.Id, "R$ " .. robuxEgg.Robux, function()
			ctx.Request("BuyRobuxEgg", robuxEgg.Id)
		end, nil)
	end

	win.Refresh = function()
		local s = state()
		if not s then
			return
		end
		balance.Text = "Your Gems: 💎 " .. Calc.FormatNumber(s.Gems) .. "    Pets: " .. #(s.Pets or {}) .. " / " .. Calc.GetInventorySize(s)
		local current, endsAt = Calc.GetCurrentEvent(ctx.Now())
		for id, r in pairs(eventRows) do
			r.Row.Visible = current ~= nil and current.Id == id
		end
		if current then
			eventTimer.Text = current.Name .. " ends in " .. Calc.FormatTime(math.max(0, endsAt - ctx.Now()))
		end
		for eggId, r in pairs(gemRows) do
			UI.SetButtonColor(r.Buy, s.Gems >= Config.Eggs[eggId].Price and UI.Colors.Green or UI.Colors.Gray)
		end
		if current and eventRows[current.Id] then
			UI.SetButtonColor(eventRows[current.Id].Buy, s.Gems >= Config.EventEggPrice and UI.Colors.Green or UI.Colors.Gray)
		end
	end
	return win
end

--------------------------------------------------------------------------
-- Item-Kisten
--------------------------------------------------------------------------
local function weightText(weights)
	local total = 0
	for _, w in pairs(weights) do
		total = total + w
	end
	local parts = {}
	for _, rarity in ipairs(Config.RarityOrder) do
		local w = weights[rarity]
		if w and w > 0 then
			table.insert(parts, Config.Rarities[rarity].DisplayName .. " " .. Calc.FormatChance(w / total))
		end
	end
	return table.concat(parts, " · ")
end

local function buildItemShop()
	local win = UI.CreateWindow(ctx.Screen, "ItemShop", "Item Crates", "🎁", Vector2.new(600, 500))
	local balance = smallLabel({ Size = UDim2.new(1, 0, 0, 22), TextColor3 = UI.Colors.SubText, Parent = win.Content })
	local list = UI.ScrollList(win.Content, { Position = UDim2.new(0, 0, 0, 26), Size = UDim2.new(1, 0, 1, -26) })
	smallLabel({ Size = UDim2.new(1, -10, 0, 34), LayoutOrder = 0, TextWrapped = true, TextColor3 = UI.Colors.SubText,
		Text = "Hats, wings and auras change your look and give bonuses. Merge 3 of the same item in the Forge for a stronger one!", Parent = list })
	local rows = {}
	for order, crate in ipairs(Config.ItemCrates) do
		local row = UI.Row(list, 84, order)
		local best = nil
		for rarity in pairs(crate.Weights) do
			local r = Config.Rarities[rarity]
			if not best or r.Order > best.Order then
				best = r
			end
		end
		Create("Frame", { Size = UDim2.new(0, 10, 1, 0), BackgroundColor3 = UI.rgb(best.Color), ZIndex = 6, Parent = row }, { UI.Corner(8) })
		title({ Position = UDim2.new(0, 18, 0, 6), Size = UDim2.new(0.6, -18, 0, 26), Text = "🎁 " .. crate.Name .. ((crate.Count or 1) > 1 and ("  x" .. crate.Count) or ""), TextColor3 = UI.rgb(best.Color), Parent = row })
		smallLabel({ Position = UDim2.new(0, 18, 0, 34), Size = UDim2.new(0.6, -18, 0, 44), TextWrapped = true, TextScaled = true, TextYAlignment = Enum.TextYAlignment.Top,
			TextColor3 = UI.Colors.SubText, Text = weightText(crate.Weights), Parent = row })
		local text
		if crate.Currency == "Robux" then
			text = "R$ " .. Calc.FormatNumber(crate.Robux)
		else
			text = money(crate.Price, crate.Currency)
		end
		local button = UI.Button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0.34, 0, 0, 50),
			Color = crate.Currency == "Robux" and UI.Colors.Green or UI.Colors.Blue, Text = text, ZIndex = 6, Parent = row }, function()
			ctx.Request("BuyCrate", crate.Id)
		end)
		rows[crate.Id] = button
	end
	win.Refresh = function()
		local s = state()
		if not s then
			return
		end
		balance.Text = money(s.Slaps, "Slaps") .. "    " .. money(s.Gems, "Gems") .. "    🎒 " .. #(s.Items or {}) .. " / " .. Config.ItemInventory
		for _, crate in ipairs(Config.ItemCrates) do
			if crate.Currency ~= "Robux" then
				local have = crate.Currency == "Gems" and s.Gems or s.Slaps
				UI.SetButtonColor(rows[crate.Id], have >= crate.Price and UI.Colors.Blue or UI.Colors.Gray)
			end
		end
	end
	return win
end

--------------------------------------------------------------------------
-- Items & Schmiede: ausruesten, verschmelzen, loeschen
--------------------------------------------------------------------------
local function buildItems()
	local win = UI.CreateWindow(ctx.Screen, "Items", "Items & Forge", "🔨", Vector2.new(660, 520))
	local bonusLabel = smallLabel({ Size = UDim2.new(1, 0, 0, 22), TextColor3 = UI.Colors.Gold, Parent = win.Content })
	local tabBar = Create("Frame", { Position = UDim2.new(0, 0, 0, 26), Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, ZIndex = 5, Parent = win.Content }, { UI.List(6, true) })
	local list = UI.ScrollList(win.Content, { Position = UDim2.new(0, 0, 0, 66), Size = UDim2.new(0.58, -6, 1, -66), Grid = UDim2.new(0, 84, 0, 96) })
	local detail = Create("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 66), Size = UDim2.new(0.42, 0, 1, -66), BackgroundColor3 = UI.Colors.Panel, ZIndex = 5, Parent = win.Content },
		{ UI.Corner(14), UI.Stroke(2, UI.Colors.PanelLight) })
	local dName = title({ Position = UDim2.new(0, 10, 0, 8), Size = UDim2.new(1, -20, 0, 28), TextWrapped = true, Text = "Select an item", Parent = detail })
	local dRarity = smallLabel({ Position = UDim2.new(0, 10, 0, 38), Size = UDim2.new(1, -20, 0, 18), Text = "", Parent = detail })
	local dStat = smallLabel({ Position = UDim2.new(0, 10, 0, 58), Size = UDim2.new(1, -20, 0, 18), TextColor3 = UI.Colors.Text, Text = "", Parent = detail })
	local dNext = smallLabel({ Position = UDim2.new(0, 10, 0, 78), Size = UDim2.new(1, -20, 0, 34), TextWrapped = true, TextColor3 = UI.Colors.SubText, Text = "", Parent = detail })
	local selected = nil
	local equipButton = UI.Button({ Position = UDim2.new(0, 10, 0, 118), Size = UDim2.new(1, -20, 0, 42), Color = UI.Colors.Green, Text = "Equip", ZIndex = 6, Parent = detail }, function()
		local s = state()
		if not selected or not s then
			return
		end
		for _, item in ipairs(s.Items or {}) do
			if item.Uid == selected then
				ctx.Request(item.Equipped and "UnequipItem" or "EquipItem", selected)
				return
			end
		end
	end)
	local mergeButton = UI.Button({ Position = UDim2.new(0, 10, 0, 166), Size = UDim2.new(1, -20, 0, 42), Color = UI.Colors.Gold, Text = "🔨 Merge 3", ZIndex = 6, Parent = detail }, function()
		if selected then
			ctx.Request("MergeItem", selected)
		end
	end)
	local deleteArmed = false
	local deleteButton
	deleteButton = UI.Button({ Position = UDim2.new(0, 10, 0, 214), Size = UDim2.new(1, -20, 0, 36), Color = UI.Colors.Red, Text = "🗑️ Delete", ZIndex = 6, Parent = detail }, function()
		if not selected then
			return
		end
		if deleteArmed then
			deleteArmed = false
			ctx.Request("DeleteItem", selected)
			selected = nil
		else
			deleteArmed = true
			deleteButton.Text = "Tap again to delete"
			task.delay(2.5, function()
				deleteArmed = false
				deleteButton.Text = "🗑️ Delete"
			end)
		end
	end)
	smallLabel({ AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 10, 1, -6), Size = UDim2.new(1, -20, 0, 40), TextWrapped = true, TextScaled = true,
		TextColor3 = UI.Colors.SubText, Text = "Find items by defeating targets (chests & piñatas drop the most), from crates and rebirths.", Parent = detail })

	local filter = "All"
	local tabs = {}
	local refresh
	local tabDefs = { { "All", "All" } }
	for _, cat in ipairs(Config.ItemCategories) do
		local info = Config.ItemCategoryInfo[cat]
		table.insert(tabDefs, { cat, info.Icon .. " " .. info.Name })
	end
	for order, def in ipairs(tabDefs) do
		tabs[def[1]] = UI.Button({ LayoutOrder = order, Size = UDim2.new(0, def[1] == "All" and 60 or 140, 1, 0), Color = UI.Colors.Panel, Text = def[2], ZIndex = 6, Parent = tabBar }, function()
			filter = def[1]
			refresh()
		end)
	end

	local function sameCount(items, base)
		local n = 0
		for _, other in ipairs(items) do
			if other.Id == base.Id and other.Level == base.Level then
				n = n + 1
			end
		end
		return n
	end

	refresh = function()
		local s = state()
		if not s then
			return
		end
		local items = s.Items or {}
		local b = Calc.GetItemBonuses(s)
		bonusLabel.Text = "Bonuses: 💪 +" .. math.floor(b.Damage * 100 + 0.5) .. "%  💰 +" .. math.floor(b.Slaps * 100 + 0.5) .. "%  🦵 +"
			.. string.format("%.1f", math.min(30, b.Speed * 10)) .. "  🍀 +" .. string.format("%.1f", b.Luck * 10) .. "%  💎 +" .. math.floor(b.Gems * 100 + 0.5) .. "%"
			.. "   🎒 " .. #items .. "/" .. Config.ItemInventory
		for id, button in pairs(tabs) do
			UI.SetButtonColor(button, id == filter and UI.Colors.Pink or UI.Colors.Panel)
		end
		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("GuiButton") or child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		local sorted = {}
		for _, item in ipairs(items) do
			local cfg = Config.Items[item.Id]
			if cfg and (filter == "All" or cfg.Category == filter) then
				table.insert(sorted, item)
			end
		end
		table.sort(sorted, function(a, b2)
			if a.Equipped ~= b2.Equipped then
				return a.Equipped == true
			end
			local va, vb = Calc.GetItemValue(a.Id, a.Level), Calc.GetItemValue(b2.Id, b2.Level)
			if va ~= vb then
				return va > vb
			end
			return a.Uid < b2.Uid
		end)
		local selectedItem = nil
		for order, item in ipairs(sorted) do
			local cfg = Config.Items[item.Id]
			local rarity = Config.Rarities[cfg.Rarity]
			if item.Uid == selected then
				selectedItem = item
			end
			local card = UI.Button({ LayoutOrder = order, Color = UI.Colors.Darker, Text = "", ZIndex = 6, Parent = list }, function()
				selected = item.Uid
				refresh()
			end)
			UI.Stroke(item.Uid == selected and 4 or 2.5, item.Uid == selected and UI.Colors.White or UI.rgb(rarity.Color)).Parent = card
			UI.Label({ Size = UDim2.new(1, 0, 0, 40), Text = Config.ItemCategoryInfo[cfg.Category].Icon, ZIndex = 7, Parent = card })
			UI.Label({ Position = UDim2.new(0, 0, 0, 40), Size = UDim2.new(1, 0, 0, 26), Font = UI.BodyFont, TextWrapped = true, TextColor3 = UI.rgb(cfg.Color), Text = cfg.DisplayName, ZIndex = 7, Parent = card })
			UI.Label({ Position = UDim2.new(0, 0, 0, 68), Size = UDim2.new(1, 0, 0, 18), Text = string.rep("★", item.Level), TextColor3 = UI.Colors.Gold, ZIndex = 7, Parent = card })
			if item.Equipped then
				UI.Label({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -2, 0, 2), Size = UDim2.new(0, 22, 0, 22), Text = "✅", ZIndex = 8, Parent = card })
			end
		end
		if not selectedItem then
			selected = nil
		end
		equipButton.Visible = selectedItem ~= nil
		mergeButton.Visible = selectedItem ~= nil
		deleteButton.Visible = selectedItem ~= nil
		if selectedItem then
			local cfg = Config.Items[selectedItem.Id]
			local rarity = Config.Rarities[cfg.Rarity]
			dName.Text = cfg.DisplayName .. " " .. string.rep("★", selectedItem.Level)
			dName.TextColor3 = UI.rgb(cfg.Color)
			dRarity.Text = rarity.DisplayName .. " " .. Config.ItemCategoryInfo[cfg.Category].Name
			dRarity.TextColor3 = UI.rgb(rarity.Color)
			dStat.Text = Calc.DescribeItem(selectedItem.Id, selectedItem.Level)
			local count = sameCount(items, selectedItem)
			if selectedItem.Level >= Config.ItemMaxLevel then
				dNext.Text = "⭐ Max stars reached!"
				mergeButton.Text = "MAX"
				UI.SetButtonColor(mergeButton, UI.Colors.Gray)
			else
				dNext.Text = "Merge 3 (" .. count .. "/3 owned) → " .. Calc.DescribeItem(selectedItem.Id, selectedItem.Level + 1)
				mergeButton.Text = "🔨 Merge 3  (" .. math.min(count, 3) .. "/3)"
				UI.SetButtonColor(mergeButton, count >= 3 and UI.Colors.Gold or UI.Colors.Gray)
			end
			equipButton.Text = selectedItem.Equipped and "Unequip" or "Equip"
			UI.SetButtonColor(equipButton, selectedItem.Equipped and UI.Colors.Gray or UI.Colors.Green)
		else
			dName.Text = #items == 0 and "No items yet" or "Select an item"
			dName.TextColor3 = UI.Colors.Text
			dRarity.Text = ""
			dStat.Text = ""
			dNext.Text = ""
		end
	end
	win.Refresh = refresh
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
	buildShopHub()
	buildEggShop()
	buildItemShop()
	buildItems()

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
			if (open == "Daily" or open == "Quests" or open == "Gems" or open == "EggShop") and UI.Windows[open].Refresh and ctx.State then
				UI.Windows[open].Refresh()
			end
		end
	end)
end

return Menus
