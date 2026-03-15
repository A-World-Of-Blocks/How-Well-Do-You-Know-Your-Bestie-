local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local giftedStore = DataStoreService:GetDataStore("GiftedPacks")

-- Remotes
local checkGiftedRemote = Instance.new("RemoteFunction")
checkGiftedRemote.Name = "CheckGiftedRemote"
checkGiftedRemote.Parent = ReplicatedStorage

local giftPackEvent = Instance.new("RemoteEvent")
giftPackEvent.Name = "GiftPackEvent"
giftPackEvent.Parent = ReplicatedStorage

local giftNotificationEvent = Instance.new("RemoteEvent")
giftNotificationEvent.Name = "GiftNotificationEvent"
giftNotificationEvent.Parent = ReplicatedStorage

-- Check gifted packs
checkGiftedRemote.OnServerInvoke = function(player, targetUserId, packId)
	local success, data = pcall(function()
		return giftedStore:GetAsync(tostring(targetUserId))
	end)

	if success and type(data) == "table" then
		for _, giftedPackId in ipairs(data) do
			if tonumber(giftedPackId) == tonumber(packId) then
				return true
			end
		end
	end
	return false
end

-- Admin gifting
giftPackEvent.OnServerEvent:Connect(function(player, targetUserId, packId)
	print("Attempting to gift pack")

	-- Check if admin
	if not (player:GetRankInGroup(8591143) >= 200) then
		print("Failed admin check")
		return
	end

	local key = tostring(targetUserId)
	local success, data = pcall(function()
		return giftedStore:GetAsync(key)
	end)

	if not success then
		data = {}
	end

	-- Ensure data is a table
	if type(data) ~= "table" then
		data = {}
	end

	-- Add pack if not already gifted
	packId = tonumber(packId)
	local alreadyGifted = false
	for _, id in ipairs(data) do
		if id == packId then
			alreadyGifted = true
			break
		end
	end

	if not alreadyGifted then
		table.insert(data, packId)
		pcall(function()
			giftedStore:SetAsync(key, data)
		end)
		print("Pack gifted successfully")

		-- 🔹 Notify the recipient if they're online
		local targetPlayer = Players:GetPlayerByUserId(tonumber(targetUserId))
		if targetPlayer then
			giftNotificationEvent:FireClient(targetPlayer, packId, player.Name)
		end
	else
		print("Pack already gifted to this user")
	end
end)
