local Library = loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/tlredz/Library/refs/heads/main/redz-V5-remake/main.luau"
))()

-- Fetch game name from MarketplaceService
local MarketplaceService = game:GetService("MarketplaceService")
local gameName = "Loading..."

local success, productInfo = pcall(function()
	return MarketplaceService:GetProductInfo(game.PlaceId)
end)

if success and productInfo then
	gameName = productInfo.Name
else
	gameName = game.Name -- Fallback to game.Name if fetch fails
end

local Window = Library:MakeWindow({
	Title = "ivory : " .. gameName,
	SubTitle = "by rbnwonknui",
	ScriptFolder = "ivory"
})

local Minimizer = Window:NewMinimizer({ KeyCode = Enum.KeyCode.LeftControl })
local mobileMinimizer = Minimizer:CreateMobileMinimizer({
	Image = "rbxassetid://116276437871529",
	BackgroundColor3 = Color3.fromRGB(0, 0, 0)
})

-- Add rounded corners to mobile minimizer
pcall(function()
	if mobileMinimizer then
		local uiCorner = Instance.new("UICorner")
		uiCorner.CornerRadius = UDim.new(0, 12)
		uiCorner.Parent = mobileMinimizer
	end
end)

Library:SetUIScale(1)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

local function FormatNumber(num)
	if num >= 1000000000 then
		return string.format("%.2fB", num / 1000000000)
	elseif num >= 1000000 then
		return string.format("%.2fM", num / 1000000)
	elseif num >= 1000 then
		return string.format("%.2fK", num / 1000)
	else
		return tostring(math.floor(num))
	end
end

local function ConvertCostString(text)
	if not text then return nil end
	if type(text) == "number" then return text end
	if type(text) ~= "string" then return nil end
	
	text = text:gsub("¢", ""):gsub("%s+", ""):gsub(",", ""):upper()
	local number, suffix = text:match("([%d%.]+)([KMBT]?)")
	number = tonumber(number)
	if not number then return nil end

	if suffix == "K" then
		return number * 1000
	elseif suffix == "M" then
		return number * 1000000
	elseif suffix == "B" then
		return number * 1000000000
	elseif suffix == "T" then
		return number * 1000000000000
	else
		return number
	end
end

local function GetLabelText(label)
	if not label then return nil end
	if label.Text ~= nil then
		return label.Text
	elseif label.ContentText ~= nil then
		return label.ContentText
	end
	return nil
end

local Config = {
	AutoPlaceBest = false,
	PlaceBestSpeed = 10,
	SelectedDice = {},
	AutoBuyDice = false,
	AutoRollDice = false,
	SelectedPotions = {},
	AutoBuyPotions = false,
	AutoUsePotions = false,
	SelectedUpgrades = {},
	AutoBuyUpgrades = false,
	AutoCollectQuest = false,
	AutoClaimAllRewards = false,
	AutoTimeRewards = false,
	AutoSpin = false,
	AutoRebirth = false,
	AntiAFK = true, -- Enabled by default
}

-- Anti-AFK enabled automatically
LocalPlayer.Idled:Connect(function()
	if Config.AntiAFK then
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end
end)

-- Notification Remover System (VERSÃO INSTANTÂNEA)
local notificationConnections = {}
local isRemovingNotifications = false

local function StartRemovingNotifications()
	if isRemovingNotifications then return end
	isRemovingNotifications = true
	
	-- Remove notificações existentes
	pcall(function()
		local botNot = LocalPlayer.PlayerGui:FindFirstChild("bot_not")
		if botNot then
			local frame = botNot:FindFirstChild("Frame")
			if frame then
				for _, child in pairs(frame:GetChildren()) do
					if child.Name == "ActiveNotification" then
						child:Destroy()
					end
				end
			end
		end
	end)
	
	-- Monitora e remove novas notificações instantaneamente
	local connection = task.spawn(function()
		while isRemovingNotifications do
			pcall(function()
				local botNot = LocalPlayer.PlayerGui:FindFirstChild("bot_not")
				if botNot then
					local frame = botNot:FindFirstChild("Frame")
					if frame then
						for _, child in pairs(frame:GetChildren()) do
							if child.Name == "ActiveNotification" then
								child:Destroy()
							end
						end
					end
				end
			end)
			task.wait() -- Sem delay, loop mais rápido possível
		end
	end)
	
	table.insert(notificationConnections, connection)
end

local function StopRemovingNotifications()
	isRemovingNotifications = false
	
	-- Cancela todos os loops de remoção
	for _, connection in pairs(notificationConnections) do
		pcall(function()
			task.cancel(connection)
		end)
	end
	
	table.clear(notificationConnections)
end

local DiscordTab = Window:MakeTab({ "Discord", "alertcircle" })

local discordData = {
	Title = "𐙚 ivory",
	Description = "Loading Discord info...",
	Banner = Color3.fromRGB(139, 69, 255),
	Logo = "rbxassetid://116276437871529",
	Invite = "https://discord.gg/XQVcQFrzpc",
	Members = 0,
	Online = 0,
}

local discordInvite = DiscordTab:AddDiscordInvite(discordData)

task.spawn(function()
	local success, result = pcall(function()
		local response = game:HttpGet("https://next-api.squareweb.app/api/discord/invite/XQVcQFrzpc")
		return HttpService:JSONDecode(response)
	end)
	
	if success and result then
		local newData = {
			Title = result.guild.name or "𐙚 ivory",
			Description = result.guild.description or "Join our community!",
			Banner = Color3.fromRGB(139, 69, 255),
			Logo = "rbxassetid://116276437871529",
			Invite = "https://discord.gg/" .. result.code,
			Members = result.approximate_member_count or 0,
			Online = result.approximate_presence_count or 0,
		}

		if discordInvite then
			pcall(function()
				discordInvite:Destroy()
			end)
		end

		discordInvite = DiscordTab:AddDiscordInvite(newData)
	end
end)

local Main = Window:MakeTab({ "Main", "Home" })
local MainSection = Main:AddSection("Main")

local autoPlaceBestToggle = nil
local autoSellToggleRef = nil

Main:AddSlider({
	Name = "Place Best Speed",
	Min = 5,
	Max = 30,
	Increment = 1,
	Default = 10,
	Callback = function(Value)
		Config.PlaceBestSpeed = Value
	end
})

autoPlaceBestToggle = Main:AddToggle({
	Name = "Auto Place Best",
	Description = "Automatically places best baddies",
	Default = false,
	Callback = function(Value)
		Config.AutoPlaceBest = Value
		if Value then
			if Config.AutoSell and autoSellToggleRef then
				StopAutoSell()
				autoSellToggleRef:SetValue(false)
				Window:Notify({ Title = "Conflict", Content = "Auto Sell desativado: conflita com Auto Place Best.", Duration = 4 })
			end
			task.spawn(function()
				while Config.AutoPlaceBest do
					pcall(function()
						ReplicatedStorage.Events.PlaceBestBaddies:InvokeServer()
					end)
					task.wait(Config.PlaceBestSpeed)
				end
			end)
		end
	end
})

-- ============================================
-- DICE TAB
-- ============================================
local DiceTab = Window:MakeTab({ "Dice", "dices" })
local DiceSection = DiceTab:AddSection("Dice Management")

local dropdownOptions = {}
local labelToData = {}

local function ExtractLuck(rarityText)
	if not rarityText then return 0 end
	local luckNumber = rarityText:match("([%d%.]+)%%")
	return tonumber(luckNumber) or 0
end

local function ExtractRarity(rarityText)
	if not rarityText then return "Unknown" end
	local rarity = rarityText:match("^(.-)%s*%-")
	return rarity or rarityText
end

local function LoadDices()
	table.clear(dropdownOptions)
	table.clear(labelToData)
	local dices = {}

	pcall(function()
		local scrollingFrame = LocalPlayer.PlayerGui.Main.Restock.ScrollingFrame
		for _, diceFrame in pairs(scrollingFrame:GetChildren()) do
			if diceFrame:IsA("Frame") and diceFrame:FindFirstChild("rarity") then
				local diceName = diceFrame.Name
				local rarityText = diceFrame.rarity.Text
				local luckValue = ExtractLuck(rarityText)
				local rarityOnly = ExtractRarity(rarityText)

				if diceName ~= "Template" then
					table.insert(dices, {
						Name = diceName,
						Rarity = rarityOnly,
						Luck = luckValue
					})
				end
			end
		end
	end)

	table.sort(dices, function(a, b)
		return a.Luck < b.Luck
	end)

	for _, dice in ipairs(dices) do
		local label = dice.Name .. " (" .. dice.Rarity .. ")"
		table.insert(dropdownOptions, label)
		labelToData[label] = {
			name = dice.Name,
			rarity = dice.Rarity,
			luck = dice.Luck
		}
	end

	if #dropdownOptions == 0 then
		table.insert(dropdownOptions, "No dices found")
	end
end

LoadDices()

DiceTab:AddDropdown({
	Name = "Select Dice",
	MultiSelect = true,
	Options = dropdownOptions,
	Default = {},
	Callback = function(Value)
		table.clear(Config.SelectedDice)
		if typeof(Value) == "table" then
			for diceName, selected in pairs(Value) do
				if selected then
					local data = labelToData[diceName]
					if data then
						table.insert(Config.SelectedDice, data.name)
					end
				end
			end
		end
	end
})

DiceTab:AddButton({
	Name = "Refresh Dice List",
	Description = "Atualiza a lista de dices",
	Callback = function()
		LoadDices()
		Window:Notify({ Title = "Dices Refreshed", Content = "Lista atualizada!", Duration = 3 })
	end
})

DiceTab:AddToggle({
	Name = "Auto Buy Selected Dice",
	Description = "Spam buy all selected dice",
	Default = false,
	Callback = function(Value)
		Config.AutoBuyDice = Value
		if Value then
			StartRemovingNotifications() -- Inicia remoção de notificações
			task.spawn(function()
				while Config.AutoBuyDice do
					for _, diceName in ipairs(Config.SelectedDice) do
						pcall(function()
							ReplicatedStorage.Events.buy:InvokeServer(diceName, 1, "dice")
						end)
						task.wait(0.05) -- Pequeno delay entre cada compra
					end
					task.wait(0.1) -- Delay após comprar todos
				end
			end)
		else
			-- Só para se as outras funções também não estiverem ativas
			if not Config.AutoBuyPotions and not Config.AutoClaimAllRewards then
				StopRemovingNotifications()
			end
		end
	end
})

DiceTab:AddToggle({
	Name = "Auto Roll Dice",
	Description = "Spam roll dice",
	Default = false,
	Callback = function(Value)
		Config.AutoRollDice = Value
		if Value then
			task.spawn(function()
				while Config.AutoRollDice do
					pcall(function()
						LocalPlayer.PlayerGui.Main.Dice.RollState:InvokeServer()
					end)
					task.wait()
				end
			end)
		end
	end
})

-- ============================================
-- END OF DICE TAB
-- ============================================

-- ============================================
-- POTION TAB
-- ============================================
local PotionTab = Window:MakeTab({ "Potion", "flaskround" })
local PotionSection = PotionTab:AddSection("Potion Management")

local potionDropdownOptions = {}
local potionLabelToData = {}

local function LoadPotions()
	table.clear(potionDropdownOptions)
	table.clear(potionLabelToData)
	local potions = {}

	pcall(function()
		local potionFrame = LocalPlayer.PlayerGui.Main.Potions.ScrollingFrame
		for _, child in pairs(potionFrame:GetChildren()) do
			if child:IsA("Frame") and child:FindFirstChild("itemname") then
				local fullName = child.Name
				local displayName = child.itemname.Text
				if fullName ~= "Template" and not string.find(string.lower(displayName), "prismatic") then
					table.insert(potions, {
						Name = fullName,
						Display = displayName
					})
				end
			end
		end
	end)

	table.sort(potions, function(a, b)
		return a.Display < b.Display
	end)

	for _, potion in ipairs(potions) do
		table.insert(potionDropdownOptions, potion.Display)
		potionLabelToData[potion.Display] = potion.Name
	end

	if #potionDropdownOptions == 0 then
		table.insert(potionDropdownOptions, "No potions found")
	end
end

LoadPotions()

PotionTab:AddDropdown({
	Name = "Select Potions",
	MultiSelect = true,
	Options = potionDropdownOptions,
	Default = {},
	Callback = function(Value)
		table.clear(Config.SelectedPotions)
		if typeof(Value) == "table" then
			for label, selected in pairs(Value) do
				if selected then
					local potionName = potionLabelToData[label]
					if potionName then
						table.insert(Config.SelectedPotions, potionName)
					end
				end
			end
		end
	end
})

PotionTab:AddToggle({
	Name = "Auto Buy Potions",
	Description = "Compra repetidamente as potions selecionadas",
	Default = false,
	Callback = function(Value)
		Config.AutoBuyPotions = Value
		if Value then
			StartRemovingNotifications() -- Inicia remoção de notificações
			task.spawn(function()
				while Config.AutoBuyPotions do
					for _, potionName in ipairs(Config.SelectedPotions) do
						pcall(function()
							ReplicatedStorage.Events.buy:InvokeServer(potionName, 1, "potion")
						end)
						task.wait(0.05) -- Pequeno delay entre cada compra
					end
					task.wait(0.1) -- Delay após comprar todas
				end
			end)
		else
			-- Só para se as outras funções também não estiverem ativas
			if not Config.AutoBuyDice and not Config.AutoClaimAllRewards then
				StopRemovingNotifications()
			end
		end
	end
})

PotionTab:AddToggle({
	Name = "Auto Use Selected Potions",
	Description = "Usa automaticamente as potions selecionadas quando não estiverem ativas",
	Default = false,
	Callback = function(Value)
		Config.AutoUsePotions = Value
		if Value then
			task.spawn(function()
				local VirtualInputManager = game:GetService("VirtualInputManager")
				
				while Config.AutoUsePotions do
					pcall(function()
						local buffsFrame = LocalPlayer.PlayerGui.Main:FindFirstChild("BUFFS")
						if not buffsFrame then return end

						if #Config.SelectedPotions == 0 then return end

						for _, potionName in ipairs(Config.SelectedPotions) do
							local buffIcon = buffsFrame:FindFirstChild(potionName)
							local isPotionActive = buffIcon and buffIcon:FindFirstChild("TIMER")
							
							if not isPotionActive then
								local success = pcall(function()
									ReplicatedStorage.Events.equip:InvokeServer(potionName, true)
									task.wait(0.1)
									VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
									task.wait(0.05)
									VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
									task.wait(0.3)
								end)
							end
						end
					end)
					
					task.wait(1)
				end
			end)
		end
	end
})

-- ============================================
-- END OF POTION TAB
-- ============================================

local UpgradeSection = Main:AddSection("Upgrades")

local upgradeDropdownOptions = {}
local upgradeLabelToData = {}

local function LoadUpgrades()
	table.clear(upgradeDropdownOptions)
	table.clear(upgradeLabelToData)
	local upgrades = {}

	pcall(function()
		local upgradeFrame = LocalPlayer.PlayerGui.Main.Upgrades.ScrollingFrame
		for _, child in pairs(upgradeFrame:GetChildren()) do
			if child:IsA("Frame") and child:FindFirstChild("itemname") then
				local realName = child.Name
				local displayName = child.itemname.Text
				if realName ~= "Template" then
					table.insert(upgrades, {
						Name = realName,
						Display = displayName
					})
				end
			end
		end
	end)

	table.sort(upgrades, function(a, b)
		return a.Display < b.Display
	end)

	for _, upgrade in ipairs(upgrades) do
		table.insert(upgradeDropdownOptions, upgrade.Display)
		upgradeLabelToData[upgrade.Display] = upgrade.Name
	end

	if #upgradeDropdownOptions == 0 then
		table.insert(upgradeDropdownOptions, "No upgrades found")
	end
end

LoadUpgrades()

Main:AddDropdown({
	Name = "Select Upgrades",
	MultiSelect = true,
	Options = upgradeDropdownOptions,
	Default = {},
	Callback = function(Value)
		table.clear(Config.SelectedUpgrades)
		if typeof(Value) == "table" then
			for label, selected in pairs(Value) do
				if selected then
					local upgradeKey = upgradeLabelToData[label]
					if upgradeKey then
						table.insert(Config.SelectedUpgrades, upgradeKey)
					end
				end
			end
		end
	end
})

Main:AddButton({
	Name = "Refresh Upgrades List",
	Description = "Atualiza a lista de upgrades",
	Callback = function()
		LoadUpgrades()
		Window:Notify({ Title = "Upgrades Refreshed", Content = "Lista atualizada!", Duration = 3 })
	end
})

Main:AddToggle({
	Name = "Auto Buy Selected Upgrades",
	Description = "Compra automaticamente os upgrades selecionados",
	Default = false,
	Callback = function(Value)
		Config.AutoBuyUpgrades = Value

		if Value then
			task.spawn(function()
				while Config.AutoBuyUpgrades do
					task.spawn(function()
						local coinsStat = LocalPlayer:FindFirstChild("leaderstats") and LocalPlayer.leaderstats:FindFirstChild("Coins")
						if not coinsStat then return end

						local currentCoins = ConvertCostString(coinsStat.Value) or 0
						if #Config.SelectedUpgrades == 0 then return end

						-- Ordena por menor custo primeiro (batch priority)
						local sortedUpgrades = {}
						for _, upgradeName in ipairs(Config.SelectedUpgrades) do
							local upgradeFrame = LocalPlayer.PlayerGui.Main.Upgrades.ScrollingFrame:FindFirstChild(upgradeName)
							if upgradeFrame then
								local costLabel = upgradeFrame:FindFirstChild("PURCHASE") and upgradeFrame.PURCHASE:FindFirstChild("TextButton") and upgradeFrame.PURCHASE.TextButton:FindFirstChild("cost")
								local cost = costLabel and ConvertCostString(costLabel.Text) or math.huge
								table.insert(sortedUpgrades, { name = upgradeName, cost = cost })
							end
						end
						table.sort(sortedUpgrades, function(a, b) return a.cost < b.cost end)

						for _, upgradeData in ipairs(sortedUpgrades) do
							local upgradeName = upgradeData.name
							local upgradeFrame = LocalPlayer.PlayerGui.Main.Upgrades.ScrollingFrame:FindFirstChild(upgradeName)
							if not upgradeFrame then continue end

							local purchaseFrame = upgradeFrame:FindFirstChild("PURCHASE")
							if not purchaseFrame then continue end
							
							local textButton = purchaseFrame:FindFirstChild("TextButton")
							if not textButton then continue end
							
							local costLabel = textButton:FindFirstChild("cost")
							if not costLabel then continue end

							local costText = tostring(costLabel.Text)
							local cost = ConvertCostString(costText)
							if not cost then continue end

							if currentCoins >= cost then
								ReplicatedStorage.Events.upgrade:InvokeServer(upgradeName)
								task.wait(0.1)
							end
						end
					end)
					
					task.wait(2)
				end
			end)
		end
	end
})

-- ============================================
-- REWARDS TAB
-- ============================================
local RewardsTab = Window:MakeTab({ "Rewards", "gift" })
local RewardsSection = RewardsTab:AddSection("Reward Collection")

RewardsTab:AddToggle({
	Name = "Auto Collect Quest",
	Description = "Spam collect all quest rewards (1-1000)",
	Default = false,
	Callback = function(Value)
		Config.AutoCollectQuest = Value
		if Value then
			task.spawn(function()
				while Config.AutoCollectQuest do
					for i = 1, 1000 do
						if not Config.AutoCollectQuest then break end
						pcall(function()
							local result = ReplicatedStorage.Events.QuestRemote:InvokeServer("ClaimReward", i)
							if result and typeof(result) == "table" and result[1] == true and result[2] then
								local rewardData = result[2]
								if rewardData.amount and rewardData.type then
									Window:Notify({
										Title = "Quest Collected!",
										Content = "Collected " .. FormatNumber(rewardData.amount) .. " " .. rewardData.type,
										Duration = 3,
										Image = "rbxassetid://10723396000"
									})
								end
							end
						end)
					end
					task.wait()
				end
			end)
		end
	end
})

RewardsTab:AddToggle({
	Name = "Auto Claim Index Rewards",
	Description = "Claim all rewards every 1 second",
	Default = false,
	Callback = function(Value)
		Config.AutoClaimAllRewards = Value

		if Value then
			StartRemovingNotifications() -- Inicia remoção de notificações
			task.spawn(function()
				while Config.AutoClaimAllRewards do
					pcall(function()
						ReplicatedStorage.Events.claimAll:InvokeServer()
					end)
					task.wait(1)
				end
			end)
		else
			-- Só para se as outras funções também não estiverem ativas
			if not Config.AutoBuyDice and not Config.AutoBuyPotions then
				StopRemovingNotifications()
			end
		end
	end
})

RewardsTab:AddToggle({
	Name = "Auto Time Rewards",
	Description = "Claim Time Rewards (1–20) every 1 minute",
	Default = false,
	Callback = function(Value)
		Config.AutoTimeRewards = Value

		if Value then
			task.spawn(function()
				while Config.AutoTimeRewards do
					for i = 1, 20 do
						if not Config.AutoTimeRewards then break end
						pcall(function()
							ReplicatedStorage.Events.ClaimTimeReward:InvokeServer(i)
						end)
					end
					task.wait(60)
				end
			end)
		end
	end
})

RewardsTab:AddToggle({
	Name = "Auto Spin",
	Description = "Automatically spins the wheel when available",
	Default = false,
	Callback = function(Value)
		Config.AutoSpin = Value
		if Value then
			task.spawn(function()
				while Config.AutoSpin do
					pcall(function()
						ReplicatedStorage.Events.spinrequest:InvokeServer()
					end)
					task.wait(2) -- Espera 2 segundos entre cada tentativa
				end
			end)
		end
	end
})

-- ============================================
-- END OF REWARDS TAB
-- ============================================

local RebirthSection = Main:AddSection("Rebirth")

Main:AddToggle({
	Name = "Auto Rebirth",
	Description = "Auto rebirth when you have enough money (500ms)",
	Default = false,
	Callback = function(Value)
		Config.AutoRebirth = Value

		if Value then
			task.spawn(function()
				while Config.AutoRebirth do
					pcall(function()
						local mainGui = LocalPlayer.PlayerGui:FindFirstChild("Main")
						if not mainGui then return end

						local rebirthFrame = mainGui:FindFirstChild("Rebirth")
						if not rebirthFrame then return end

						local costLabel = rebirthFrame:FindFirstChild("Cost")
						if not costLabel then return end

						local costText = GetLabelText(costLabel)
						local cost = ConvertCostString(costText)

						local coinsStat = LocalPlayer.leaderstats:FindFirstChild("Coins")
						if not coinsStat then return end

						local money = ConvertCostString(coinsStat.Value)

						if cost and money and money >= cost then
							ReplicatedStorage.Events.rebirth:InvokeServer()
						end
					end)

					task.wait(0.5)
				end
			end)
		end
	end
})

-- SELL TAB (COMPLETA E FUNCIONAL)
-- ============================================
local SellTab = Window:MakeTab({ "Sell", "Piggybank" })
local SellSection = SellTab:AddSection("Sell")

-- Auto Sell (ALL)
local autoSellThread = nil

local function StartAutoSell()
    if autoSellThread then return end
    autoSellThread = task.spawn(function()
        while Config.AutoSell do
            pcall(function()
                local result = ReplicatedStorage.Events.sell:InvokeServer("all")
                if typeof(result) == "table" then
                    local data = result[1] or result
                    if data and data.coinsEarned and data.coinsEarned > 0 then
                        Window:Notify({
                            Title = "Auto Sell",
                            Content = "Sold pets for " .. FormatNumber(data.coinsEarned) .. " Coins!",
                            Duration = 3,
                            Image = "rbxassetid://10723343321"
                        })
                    end
                end
            end)
            task.wait(2)
        end
    end)
end

local function StopAutoSell()
    Config.AutoSell = false
    if autoSellThread then
        task.cancel(autoSellThread)
        autoSellThread = nil
    end
end

autoSellToggle = SellTab:AddToggle({
    Name = "Auto Sell (All Pets)",
    Description = "Automatically sells all sellable pets you own.",
    Default = false,
    Callback = function(Value)
        if Value then
            Window:Dialog({
                Title = "Critical Warning",
                Content = "Auto Sell will sell every pet in your inventory. This conflicts with Place Best and may sell your most valuable baddies. Disable Place Best first or use Auto Sell In Hand instead. Continue?",
                Options = {
                    {
                        Name = "No, Thanks",
                        Callback = function()
                            Config.AutoSell = false
                            autoSellToggle:SetValue(false)
                        end
                    },
                    {
                        Name = "Yes, Enable",
                        Callback = function()
                            if Config.AutoPlaceBest and autoPlaceBestToggle then
                                Config.AutoPlaceBest = false
                                autoPlaceBestToggle:SetValue(false)
                                Window:Notify({ Title = "Conflict", Content = "Auto Place Best desativado: conflita com Auto Sell.", Duration = 4 })
                            end
                            Config.AutoSell = true
                            StartAutoSell()
                            
                            Window:Notify({
                                Title = "Auto Sell Enabled",
                                Content = "Auto Sell is now active. Monitor your inventory carefully.",
                                Duration = 4
                            })
                        end
                    }
                }
            })
        else
            StopAutoSell()
        end
    end
})
autoSellToggleRef = autoSellToggle

-- Auto Sell (In Hand)
local autoSellInHandThread = nil

local function StartAutoSellInHand()
    if autoSellInHandThread then return end
    autoSellInHandThread = task.spawn(function()
        while Config.AutoSellInHand do
            pcall(function()
                local result = ReplicatedStorage.Events.sell:InvokeServer("specific")
                if typeof(result) == "table" then
                    local data = result[1] or result
                    if data and data.coinsEarned and data.coinsEarned > 0 then
                        Window:Notify({
                            Title = "Auto Sell (In Hand)",
                            Content = "Sold for " .. FormatNumber(data.coinsEarned) .. " Coins!",
                            Duration = 3,
                            Image = "rbxassetid://10723343321"
                        })
                    end
                end
            end)
            task.wait(1)
        end
    end)
end

local function StopAutoSellInHand()
    Config.AutoSellInHand = false
    if autoSellInHandThread then
        task.cancel(autoSellInHandThread)
        autoSellInHandThread = nil
    end
end

SellTab:AddToggle({
    Name = "Auto Sell (In Hand)",
    Description = "Automatically sells the item you are currently holding.",
    Default = false,
    Callback = function(Value)
        if Value then
            Config.AutoSellInHand = true
            StartAutoSellInHand()
        else
            StopAutoSellInHand()
        end
    end
})

--------------------------------------------------

-- Show Baddie Valude (In Hand) (In Hand)
local showValueThread = nil

local function StartShowValue()
    if showValueThread then return end
    showValueThread = task.spawn(function()
        while Config.ShowPetValue do
            pcall(function()
                local result = ReplicatedStorage.Events.sell:InvokeServer("appraise")
                if typeof(result) == "table" then
                    local data = result[1] or result
                    if data and data.value and data.value > 0 then
                        Window:Notify({
                            Title = "Baddie Valude (In Hand)",
                            Content = "Current pet worth: " .. FormatNumber(data.value) .. " Coins",
                            Duration = 3,
                            Image = "rbxassetid://10723343321"
                        })
                    elseif data and data.value == 0 then
                        Window:Notify({
                            Title = "Baddie Valude (In Hand)",
                            Content = "No pet in hand or pet has no value",
                            Duration = 2
                        })
                    end
                end
            end)
            task.wait(1) -- Verifica a cada 5 segundos
        end
    end)
end

local function StopShowValue()
    Config.ShowPetValue = false
    if showValueThread then
        task.cancel(showValueThread)
        showValueThread = nil
    end
end

SellTab:AddToggle({
    Name = "Show Baddie Valude (In Hand)",
    Description = "Displays the current value of the pet in your hand.",
    Default = false,
    Callback = function(Value)
        if Value then
            Config.ShowPetValue = true
            StartShowValue()
        else
            StopShowValue()
        end
    end
})

-- ============================================
-- EGGS TAB
-- ============================================
local EggsTab = Window:MakeTab({ "Eggs", "Egg" })
local EggsSection = EggsTab:AddSection("Egg")

-- Funções para processar ovos
local function convertToNumber(valueText)
    valueText = valueText:gsub("%s+", ""):lower()
    local num, suffix = valueText:match("([%d%.]+)(%a*)")
    num = tonumber(num) or 0
    
    local multipliers = {
        [""] = 1, ["k"] = 1e3, ["m"] = 1e6, ["b"] = 1e9, 
        ["t"] = 1e12, ["qd"] = 1e15, ["qn"] = 1e18, 
        ["sx"] = 1e21, ["sp"] = 1e24, ["oc"] = 1e27, ["no"] = 1e30
    }
    
    return num * (multipliers[suffix] or 1)
end

local function getAllEggs()
    local eggs = {}
    
    pcall(function()
        -- Pega os nomes dos ovos de workspace.Eggs
        local eggObjects = workspace.Eggs:GetChildren()
        
        -- Pega os custos dos stands
        local stands = workspace.Eggs.Stands:GetChildren()
        
        -- Associa cada ovo com seu custo (mesmo índice)
        for i = 1, math.min(#eggObjects, #stands) do
            local eggObject = eggObjects[i]
            local stand = stands[i]
            
            -- Ignora se não for Model ou Folder
            if eggObject.ClassName == "Model" or eggObject.ClassName == "Folder" then
                local eggName = eggObject.Name
                local costText = "N/A"
                
                -- Pega o custo do stand correspondente
                if stand:FindFirstChild("Sign") then
                    local sign = stand.Sign
                    if sign:FindFirstChild("EggCost") and sign.EggCost:FindFirstChild("Amount") then
                        costText = sign.EggCost.Amount.Text
                    end
                end
                
                table.insert(eggs, {
                    name = eggName,
                    cost = costText,
                    numericValue = convertToNumber(costText),
                    index = i
                })
            end
        end
    end)
    
    -- Ordena por valor (menor para maior)
    table.sort(eggs, function(a, b) return a.numericValue < b.numericValue end)
    
    return eggs
end

-- Carrega os ovos
local eggList = getAllEggs()

-- Cria o texto formatado para o Paragraph
local function createEggListText()
    if #eggList == 0 then
        return "No eggs found\nMake sure you're in the game!"
    end
    
    local lines = {}
    table.insert(lines, "")
    
    for i, egg in ipairs(eggList) do
        -- Formata: NomeDoOvo (Custo)
        local line = string.format("%d. %s (%s)", i, egg.name, egg.cost)
        table.insert(lines, line)
    end
    
    table.insert(lines, "\nTotal eggs: " .. #eggList)
    
    return table.concat(lines, "\n")
end

-- Adiciona o Paragraph com a lista de ovos
local eggListParagraph = EggsTab:AddParagraph("", createEggListText())

-- Prepara opções para o Dropdown
local eggDropdownOptions = {}
local eggLabelToName = {}

for _, egg in ipairs(eggList) do
    local label = egg.name .. " (" .. egg.cost .. ")"
    table.insert(eggDropdownOptions, label)
    eggLabelToName[label] = egg.name
end

if #eggDropdownOptions == 0 then
    table.insert(eggDropdownOptions, "No eggs available")
end

-- Adiciona ao Config
Config.SelectedEggs = {}
Config.AutoBuyEggs = false

-- Adiciona o Dropdown
EggsTab:AddDropdown({
    Name = "Select Eggs",
    MultiSelect = true,
    Options = eggDropdownOptions,
    Default = {},
    Callback = function(Value)
        table.clear(Config.SelectedEggs)
        if typeof(Value) == "table" then
            for label, selected in pairs(Value) do
                if selected then
                    local eggName = eggLabelToName[label]
                    if eggName then
                        table.insert(Config.SelectedEggs, eggName)
                    end
                end
            end
        end
    end
})

-- Adiciona Toggle para Auto Buy Eggs
EggsTab:AddToggle({
    Name = "Auto Buy Selected Eggs",
    Description = "Automatically buys the selected eggs",
    Default = false,
    Callback = function(Value)
        Config.AutoBuyEggs = Value
        if Value then
            StartRemovingNotifications() -- Remove notificações
            task.spawn(function()
                while Config.AutoBuyEggs do
                    for _, eggName in ipairs(Config.SelectedEggs) do
                        local success, result = pcall(function()
                            return ReplicatedStorage.Events.RegularPet:InvokeServer(eggName, 1)
                        end)
                        
                        if success and result then
                            local petName = "Unknown"
                            
                            if type(result) == "table" and result[1] then
                                if type(result[1]) == "table" then
                                    petName = result[1][1] or "Unknown"
                                else
                                    petName = result[1]
                                end
                            end
                            
                            -- Só mostra notificação se conseguir identificar o pet
                            if petName ~= "Unknown" then
                                Window:Notify({
                                    Title = "Egg Hatched!",
                                    Content = "You got: " .. petName .. " from " .. eggName,
                                    Duration = 3,
                                    Image = "rbxassetid://10709775704"
                                })
                            end
                        end
                        
                        task.wait() -- Delay entre compras
                    end
                    task.wait()
                end
            end)
        else
            -- Para remoção de notificações se nenhuma outra função estiver ativa
            if not Config.AutoBuyDice and not Config.AutoBuyPotions and not Config.AutoClaimAllRewards then
                StopRemovingNotifications()
            end
        end
    end
})

-- Botão para atualizar a lista de ovos
EggsTab:AddButton({
    Name = "Refresh Egg List",
    Description = "Updates the egg list if new eggs are added",
    Callback = function()
        -- Recarrega a lista
        eggList = getAllEggs()
        
        -- Atualiza o Paragraph
        pcall(function()
            if eggListParagraph and eggListParagraph.SetText then
                eggListParagraph:SetText(createEggListText())
            end
        end)
        
        -- Atualiza o Dropdown
        table.clear(eggDropdownOptions)
        table.clear(eggLabelToName)
        
        for _, egg in ipairs(eggList) do
            local label = egg.name .. " (" .. egg.cost .. ")"
            table.insert(eggDropdownOptions, label)
            eggLabelToName[label] = egg.name
        end
        
        Window:Notify({
            Title = "Eggs Refreshed",
            Content = "Found " .. #eggList .. " eggs!",
            Duration = 3,
            Image = "rbxassetid://10723343321"
        })
    end
})

-- Salva globalmente para acesso externo
getgenv().EggList = eggList

-- ============================================
-- END OF EGGS TAB
-- ============================================
