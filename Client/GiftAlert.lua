local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local giftNotificationEvent = ReplicatedStorage:WaitForChild("GiftNotificationEvent")

-- Function to spawn a quick confetti burst
local function spawnConfetti(parent)
	for i = 1, 30 do
		local confetti = Instance.new("Frame")
		confetti.Size = UDim2.new(0, 6, 0, 6)
		confetti.Position = UDim2.new(0.5, 0, 0.5, 0) -- center burst
		confetti.AnchorPoint = Vector2.new(0.5, 0.5)
		confetti.BackgroundColor3 = Color3.fromHSV(math.random(), 0.8, 1)
		confetti.BorderSizePixel = 0
		confetti.Parent = parent
		confetti.ZIndex = 100

		-- Round corners
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = confetti

		-- Random direction & distance
		local angle = math.random() * math.pi * 2
		local distance = math.random(100, 250)
		local offset = Vector2.new(math.cos(angle), math.sin(angle)) * distance

		-- Animate flying out & fading
		local tween = TweenService:Create(
			confetti,
			TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = UDim2.new(0.5, offset.X, 0.5, offset.Y),
				BackgroundTransparency = 1
			}
		)
		tween:Play()

		game:GetService("Debris"):AddItem(confetti, 1.5)
	end
end

-- Function to show a toast notification
local function showToast(message, gui)
	local toast = Instance.new("TextLabel")
	toast.Size = UDim2.new(0.3, 0, 0, 50)
	toast.Position = UDim2.new(0.7, 0, 1, -60) -- bottom right
	toast.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	toast.TextColor3 = Color3.fromRGB(255, 255, 255)
	toast.Text = message
	toast.Font = Enum.Font.GothamBold
	toast.TextSize = 18
	toast.AnchorPoint = Vector2.new(0, 1)
	toast.BackgroundTransparency = 0
	toast.Parent = gui
	toast.ZIndex = 99

	-- Rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = toast

	-- Slide in
	toast.Position = UDim2.new(0.7, 0, 1.1, 0)
	TweenService:Create(toast, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
		Position = UDim2.new(0.7, 0, 1, -60)
	}):Play()

	-- Hold for 3 sec, then fade/slide out
	task.delay(10, function()
		TweenService:Create(toast, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
			Position = UDim2.new(0.7, 0, 1.1, 0),
			TextTransparency = 1,
			BackgroundTransparency = 1
		}):Play()
		game:GetService("Debris"):AddItem(toast, 1)
	end)
end

-- Listen for gifts
giftNotificationEvent.OnClientEvent:Connect(function(packId, fromAdmin)
	print("Got gift")
	print(packId)
	local gui1 = player:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui")
	gui.Name = 'GiftBurst'
	gui.Enabled = true
	gui.Parent = gui1
	-- 🎉 Confetti Burst
	spawnConfetti(gui)

	-- 🎁 Toast Message
	showToast("🎁 You received Pack " .. tostring(packId) .. " from " .. fromAdmin .. "!", gui)
end)
