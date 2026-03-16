-- Server: Handle checking if player has dev product
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local DevProductStore = DataStoreService:GetDataStore("Rewards")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create RemoteFunction for checking dev product
local CheckDevProduct = Instance.new("RemoteFunction")
CheckDevProduct.Name = "CheckDevProduct"
CheckDevProduct.Parent = ReplicatedStorage

CheckDevProduct.OnServerInvoke = function(player)
	local success, data = pcall(function()
		return DevProductStore:GetAsync(player.UserId)
	end)

	if success and data and data.allowFreeWithAdsPacks then
		return true
	else
		return false
	end
end
