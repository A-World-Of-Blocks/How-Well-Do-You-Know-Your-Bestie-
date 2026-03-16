local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- 🛠️ Admin username whitelist
local admins = { "Cosmix_Productions" }

local function isAdmin(name)
	for _, adminName in ipairs(admins) do
		if string.lower(adminName) == string.lower(name) then
			return true
		end
	end
	return false
end

if not isAdmin(player.Name) then return end

-- ScreenGui and buttons (abbreviated for brevity)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdminGiftUI"
screenGui.Parent = player:WaitForChild("PlayerGui")

local openButton = Instance.new("TextButton")
openButton.Size = UDim2.new(0, 120, 0, 40)
openButton.Position = UDim2.new(1, -130, 1, -50)
openButton.Text = "Gift Packs"
openButton.Parent = screenGui
openButton.ZIndex = 12

-- Gift Frame
local giftFrame = Instance.new("Frame")
giftFrame.Size = UDim2.new(0, 300, 0, 200)
giftFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
giftFrame.Visible = false
giftFrame.Parent = screenGui
giftFrame.ZIndex = 11

-- Player dropdown
local dropdownButton = Instance.new("TextButton")
dropdownButton.Size = UDim2.new(1, -20, 0, 30)
dropdownButton.Position = UDim2.new(0, 10, 0, 10)
dropdownButton.Text = "Select Player ▼"
dropdownButton.Parent = giftFrame
dropdownButton.ZIndex = 12

local dropdownFrame = Instance.new("Frame")
dropdownFrame.Size = UDim2.new(1, -20, 0, 100)
dropdownFrame.Position = UDim2.new(0, 10, 0, 45)
dropdownFrame.Visible = false
dropdownFrame.Parent = giftFrame
dropdownFrame.ZIndex = 13

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = dropdownFrame

-- Gamepass dropdown
local gamepassButton = Instance.new("TextButton")
gamepassButton.Size = UDim2.new(1, -20, 0, 30)
gamepassButton.Position = UDim2.new(0, 10, 0, 70)
gamepassButton.Text = "Select Pack ▼"
gamepassButton.Parent = giftFrame
gamepassButton.ZIndex = 12

local gamepassFrame = Instance.new("Frame")
gamepassFrame.Size = UDim2.new(1, -20, 0, 100)
gamepassFrame.Position = UDim2.new(0, 10, 0, 105)
gamepassFrame.Visible = false
gamepassFrame.Parent = giftFrame
gamepassFrame.ZIndex = 13

local gamepassLayout = Instance.new("UIListLayout")
gamepassLayout.Parent = gamepassFrame

-- Gift button
local giftButton = Instance.new("TextButton")
giftButton.Size = UDim2.new(0, 120, 0, 30)
giftButton.Position = UDim2.new(0.5, -60, 1, -40)
giftButton.Text = "Gift Pack"
giftButton.Parent = giftFrame
giftButton.ZIndex = 12

-- State
local selectedPlayer = nil
local selectedGamepassId = nil

-- Define your gamepass IDs here
local gamepassIDs = { 1432327762, 1432183791, 1430962515, 1431220459, 1432483652, 1294283845, 1294491775, 1295885301, 1295291583, 1295324917, 1540745033 } -- replace with your actual gamepass IDs
local gamepasses = {}

-- Fetch names for the IDs
for _, id in ipairs(gamepassIDs) do
	local success, info = pcall(function()
		return MarketplaceService:GetProductInfo(id, Enum.InfoType.GamePass)
	end)
	if success then
		table.insert(gamepasses, {Id = id, Name = info.Name})
	else
		warn("Failed to get gamepass info for ID:", id)
	end
end

-- Functions to populate dropdowns
local function refreshDropdown()
	for _, child in ipairs(dropdownFrame:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -4, 0, 25)
		btn.Text = plr.Name
		btn.Parent = dropdownFrame
		btn.ZIndex = 14
		btn.MouseButton1Click:Connect(function()
			selectedPlayer = plr
			dropdownButton.Text = "Player: "..plr.Name.." ▼"
			dropdownFrame.Visible = false
		end)
	end
end

local function refreshGamepasses()
	for _, child in ipairs(gamepassFrame:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	for _, gp in ipairs(gamepasses) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -4, 0, 25)
		btn.Text = gp.Name
		btn.Parent = gamepassFrame
		btn.ZIndex = 14
		btn.MouseButton1Click:Connect(function()
			selectedGamepassId = gp.Id
			gamepassButton.Text = "Pack: "..gp.Name.." ▼"
			gamepassFrame.Visible = false
		end)
	end
end

-- Button events
dropdownButton.MouseButton1Click:Connect(function()
	dropdownFrame.Visible = not dropdownFrame.Visible
	if dropdownFrame.Visible then refreshDropdown() end
end)

gamepassButton.MouseButton1Click:Connect(function()
	gamepassFrame.Visible = not gamepassFrame.Visible
	if gamepassFrame.Visible then refreshGamepasses() end
end)

openButton.MouseButton1Click:Connect(function()
	giftFrame.Visible = not giftFrame.Visible
end)

-- Fire gifting event
local giftPackEvent = game.ReplicatedStorage:WaitForChild("GiftPackEvent")
giftButton.Activated:Connect(function()
	if selectedPlayer and selectedGamepassId then
		giftPackEvent:FireServer(selectedPlayer.UserId, selectedGamepassId)
	end
end)

-- Update player dropdown dynamically
Players.PlayerAdded:Connect(function()
	if dropdownFrame.Visible then refreshDropdown() end
end)
Players.PlayerRemoving:Connect(function()
	if dropdownFrame.Visible then refreshDropdown() end
end)
