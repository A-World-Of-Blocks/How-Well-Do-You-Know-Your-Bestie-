-- Services
local AdService = game:GetService("AdService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RewardedAdEvent = ReplicatedStorage:WaitForChild("RewardedAdEvent")

-- Provide a developer product ID for the video ad reward
-- This developer product must be created for the specific universe that this place is in
local DEV_PRODUCT_ID = 3459901460

RewardedAdEvent.OnServerEvent:Connect(function(player)
	local isSuccess, result = pcall(function()
		local reward = AdService:CreateAdRewardFromDevProductId(DEV_PRODUCT_ID)
		return AdService:ShowRewardedVideoAdAsync(player, reward)
	end)

	RewardedAdEvent:FireClient(player, isSuccess, result)
end)

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if receiptInfo.ProductId == DEV_PRODUCT_ID then

		-- Include the logic for granting rewards here

		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end
