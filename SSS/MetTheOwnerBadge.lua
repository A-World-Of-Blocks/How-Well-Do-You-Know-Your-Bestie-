local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")

local OWNER_USER_ID = 1796242043
local BADGE_ID = 53120573835464 

-- Function to award badge safely
local function awardBadge(player)
	-- Don't try to award the badge to the owner themselves (optional)
	if player.UserId == OWNER_USER_ID then return end

	local success, hasBadge = pcall(function()
		return BadgeService:UserHasBadgeAsync(player.UserId, BADGE_ID)
	end)

	if success and not hasBadge then
		local awardSuccess, result = pcall(function()
			return BadgeService:AwardBadgeAsync(player.UserId, BADGE_ID)
		end)
		if awardSuccess then
			print("Awarded badge to: " .. player.Name)
		end
	end
end

-- Function to check if owner is currently in the server
local function isOwnerInGame()
	for _, player in ipairs(Players:GetPlayers()) do
		if player.UserId == OWNER_USER_ID then
			return true
		end
	end
	return false
end

-- Main logic
Players.PlayerAdded:Connect(function(newPlayer)
	-- 1. If the person joining IS the owner
	if newPlayer.UserId == OWNER_USER_ID then
		print("Owner has joined! Awarding badges to everyone in server...")
		for _, player in ipairs(Players:GetPlayers()) do
			awardBadge(player)
		end
	else
		-- 2. If a regular player joins, check if owner is already here
		task.wait(2) -- Brief wait to ensure data is ready
		if isOwnerInGame() then
			awardBadge(newPlayer)
		end
	end
end)
