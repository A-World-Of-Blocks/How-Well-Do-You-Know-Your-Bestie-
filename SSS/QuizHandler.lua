-- Best Friend Quiz Game for Roblox
-- Place this script in ServerScriptService
local MASTER_GAMEPASS_ID = 1567823362

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local DataStoreService = game:GetService("DataStoreService")
local highscoreStore = DataStoreService:GetDataStore("BestFriendQuizHighscores")
local AnalyticsService = game:GetService("AnalyticsService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

-- Setup leaderstats for each player
Players.PlayerAdded:Connect(function(player)
	AnalyticsService:LogOnboardingFunnelStepEvent(
		player,
		1,
		"Player Joined"
	)

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local highscore = Instance.new("IntValue")
	highscore.Name = "Highscore(%)"
	highscore.Value = 0
	highscore.Parent = leaderstats

	local success, data = pcall(function()
		return highscoreStore:GetAsync(player.UserId)
	end)
	if success and data then
		highscore.Value = data
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local success, err = pcall(function()
		highscoreStore:SetAsync(player.UserId, player.leaderstats.Highscore.Value)
	end)
	if not success then
		warn("Failed to save highscore for " .. player.Name .. ": " .. err)
	end
end)

-- Create RemoteEvents
local remoteEvents = Instance.new("Folder")
remoteEvents.Name = "RemoteEvents"
remoteEvents.Parent = ReplicatedStorage

local sendQuizRequest = Instance.new("RemoteEvent")
sendQuizRequest.Name = "SendQuizRequest"
sendQuizRequest.Parent = remoteEvents

local respondToRequest = Instance.new("RemoteEvent")
respondToRequest.Name = "RespondToRequest"
respondToRequest.Parent = remoteEvents

local submitAnswer = Instance.new("RemoteEvent")
submitAnswer.Name = "SubmitAnswer"
submitAnswer.Parent = remoteEvents

local getPlayerList = Instance.new("RemoteFunction")
getPlayerList.Name = "GetPlayerList"
getPlayerList.Parent = remoteEvents

local requestEvent = Instance.new("RemoteEvent")
requestEvent.Name = "QuizRequest"
requestEvent.Parent = ReplicatedStorage

local resultsEvent = Instance.new("RemoteEvent")
resultsEvent.Name = "QuizResults"
resultsEvent.Parent = ReplicatedStorage

local startQuizEvent = Instance.new("RemoteEvent")
startQuizEvent.Name = "StartQuiz"
startQuizEvent.Parent = ReplicatedStorage

local declineEvent = Instance.new("RemoteEvent")
declineEvent.Name = "QuizDeclined"
declineEvent.Parent = ReplicatedStorage

-- NEW: Load all question packs from modules
local questionPacks = {}

local function loadQuestionPacks()
	local packsFolder = ReplicatedStorage:FindFirstChild("Packs")

	if not packsFolder then
		warn("Packs folder not found in ReplicatedStorage!")
		return
	end

	for _, module in ipairs(packsFolder:GetChildren()) do
		if module:IsA("ModuleScript") then
			local success, packData = pcall(function()
				return require(module)
			end)

			if success and packData and packData.questions then
				local packId = module.Name
				questionPacks[packId] = packData.questions
				local limitedText = packData.limited and " (LIMITED TIME)" or ""
				print("Loaded pack: " .. (packData.name or packId) .. limitedText .. " with " .. #packData.questions .. " questions")
			else
				warn("Failed to load pack module: " .. module.Name)
			end
		end
	end

	print("Total packs loaded: " .. tostring(#questionPacks))
end

-- Load packs on startup
loadQuestionPacks()

-- Game State
local gameState = {}
local activeQuizzes = {}

-- Functions
local function getPlayersInServer()
	local playerList = {}
	for _, player in pairs(Players:GetPlayers()) do
		table.insert(playerList, player.Name)
	end
	return playerList
end

local function createCustomQuestions(baseQuestions, targetPlayerName, isPersonal)
	local customQuestions = {}

	for _, questionData in pairs(baseQuestions) do
		local customQuestion = {
			options = questionData.options
		}

		if isPersonal then
			customQuestion.question = questionData.personalQuestion
		else
			customQuestion.question = questionData.questionTemplate:gsub("{player}", targetPlayerName)
		end

		table.insert(customQuestions, customQuestion)
	end

	return customQuestions
end

local function copyTable(original)
	local copy = {}
	for key, value in pairs(original) do
		if type(value) == "table" then
			copy[key] = copyTable(value)
		else
			copy[key] = value
		end
	end
	return copy
end

local function calculateCompatibility(answers1, answers2)
	local matches = 0
	local total = #answers1

	for i = 1, total do
		if answers1[i] == answers2[i] then
			matches = matches + 1
		end
	end

	return math.floor((matches / total) * 100)
end

local playerListUpdate = ReplicatedStorage:WaitForChild("PlayerListUpdate")

local function sendPlayerList(targetPlayer)
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= targetPlayer then
			table.insert(list, p.Name)
		end
	end
	playerListUpdate:FireClient(targetPlayer, list)
end

Players.PlayerAdded:Connect(function(player)
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			sendPlayerList(p)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			sendPlayerList(p)
		end
	end
end)

-- Initial request
getPlayerList.OnServerInvoke = function(player)
	local players = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			table.insert(players, p.Name)
		end
	end
	return players
end


-- Remote Event Handlers
--getPlayerList.OnServerInvoke = function(player)
--	local players = {}
--	for _, p in pairs(Players:GetPlayers()) do
--		if p ~= player then
--			table.insert(players, p.Name)
--		end
--	end
--	return players
--end

local giftedStore = DataStoreService:GetDataStore("GiftedPacks")

sendQuizRequest.OnServerEvent:Connect(function(player, targetPlayerName, selectedPackId)
	local targetPlayer = Players:FindFirstChild(targetPlayerName)
	if not targetPlayer then return false end

	print("Selected Pack ID: " .. tostring(selectedPackId))

	AnalyticsService:LogOnboardingFunnelStepEvent(
		player,
		2,
		"Sent Quiz Request",
		{
			[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = "Pack - " .. tostring(selectedPackId),
		}
	)

	-- NEW: Check pack type and validate ownership
	local packsFolder = ReplicatedStorage:FindFirstChild("Packs")
	if packsFolder then
		local packModule = packsFolder:FindFirstChild(tostring(selectedPackId))
		if packModule and packModule:IsA("ModuleScript") then
			local success, packData = pcall(function()
				return require(packModule)
			end)

			if success and packData then
				local packType = string.lower(packData.type or "free")

				-- Only validate ownership for paid packs
				if packType == "paid" then
					local packIdNum = tonumber(selectedPackId)
					if packIdNum then
						local ownsPack = false

						-- Check Marketplace ownership
						local ownershipSuccess, owns = pcall(function()
							return MarketplaceService:UserOwnsGamePassAsync(player.UserId, packIdNum)
								or MarketplaceService:UserOwnsGamePassAsync(player.UserId, MASTER_GAMEPASS_ID)
						end)

						if ownershipSuccess and owns then
							ownsPack = true
						end

						-- Check gifted datastore if not owned
						if not ownsPack then
							local dsSuccess, giftedData = pcall(function()
								return giftedStore:GetAsync(tostring(player.UserId))
							end)
							if dsSuccess and type(giftedData) == "table" then
								for _, id in ipairs(giftedData) do
									if id == packIdNum then
										ownsPack = true
										break
									end
								end
							end
						end

						-- Prompt purchase if neither owned nor gifted
						if not ownsPack then
							MarketplaceService:PromptGamePassPurchase(player, packIdNum)
							return false
						end
					end
				end
				-- Free and ad packs don't need validation here
			end
		end
	end

	-- Send request with pack ID
	print('Sent request with pack: ' .. tostring(selectedPackId))
	requestEvent:FireClient(targetPlayer, player.Name, selectedPackId)
	return true
end)

respondToRequest.OnServerEvent:Connect(function(player, requesterName, accepted, selectedPackId)
	local requester = Players:FindFirstChild(requesterName)
	if requester and accepted then
		local quizId = requester.Name .. "_" .. player.Name .. "_" .. tick()

		-- NEW: Get questions from loaded packs
		local questions = questionPacks[tostring(selectedPackId)]

		if not questions then
			warn("Pack not found: " .. tostring(selectedPackId) .. ", using default")
			questions = questionPacks["default"]
		end

		if not questions then
			warn("No questions available! Make sure packs are loaded.")
			return
		end

		print("Using pack: " .. tostring(selectedPackId) .. " with " .. #questions .. " questions")

		local requesterQuestions = createCustomQuestions(questions, player.Name, false)
		local challengedQuestions = createCustomQuestions(questions, requester.Name, true)

		activeQuizzes[quizId] = {
			player1 = requester,
			player2 = player,
			answers1 = {},
			answers2 = {},
			questions = questions
		}

		startQuizEvent:FireClient(requester, quizId, requesterQuestions, player.Name)
		startQuizEvent:FireClient(player, quizId, challengedQuestions, requester.Name)

		print("Quiz started")
		AnalyticsService:LogOnboardingFunnelStepEvent(
			requester,
			2,
			"Started Quiz"
		)

		AnalyticsService:LogOnboardingFunnelStepEvent(
			player,
			2,
			"Started Quiz"
		)
	elseif requester then
		declineEvent:FireClient(requester, player.Name)
	end
end)

-- Forward declaration — defined in full inside the XP system block below
local awardQuizXP

submitAnswer.OnServerEvent:Connect(function(player, quizId, questionIndex, answer)
	if activeQuizzes[quizId] then
		local quiz = activeQuizzes[quizId]

		if player == quiz.player1 then
			quiz.answers1[questionIndex] = answer
		elseif player == quiz.player2 then
			quiz.answers2[questionIndex] = answer
		end

		AnalyticsService:LogOnboardingFunnelStepEvent(
			quiz.player1,
			3,
			"Completed Test"
		)

		AnalyticsService:LogOnboardingFunnelStepEvent(
			quiz.player2,
			3,
			"Completed Test"
		)

		-- Check if both players have completed the quiz
		local function countAnswers(answers, questionCount)
			local count = 0
			for i = 1, questionCount do
				if answers[i] ~= nil then
					count = count + 1
				end
			end
			return count
		end

		local totalQuestions = #quiz.questions
		if countAnswers(quiz.answers1, totalQuestions) == totalQuestions and countAnswers(quiz.answers2, totalQuestions) == totalQuestions then
			local compatibility = calculateCompatibility(quiz.answers1, quiz.answers2)

			print("Compatibility: " .. compatibility)

			-- Update highscores
			if quiz.player1:FindFirstChild("leaderstats") then
				local hs1 = quiz.player1.leaderstats:FindFirstChild("Highscore")
				if hs1 and compatibility > hs1.Value then
					hs1.Value = compatibility
				end
			end

			if quiz.player2:FindFirstChild("leaderstats") then
				local hs2 = quiz.player2.leaderstats:FindFirstChild("Highscore")
				if hs2 and compatibility > hs2.Value then
					hs2.Value = compatibility
				end
			end

			-- Create display questions for results
			local requesterDisplayQuestions = createCustomQuestions(quiz.questions, quiz.player2.Name, false)
			local challengedDisplayQuestions = createCustomQuestions(quiz.questions, quiz.player1.Name, true)

			local baseResults = {
				compatibility = compatibility,
				requesterQuestions = requesterDisplayQuestions,
				challengedQuestions = challengedDisplayQuestions,
				player1Answers = quiz.answers1,
				player2Answers = quiz.answers2,
				player1Name = quiz.player1.Name,
				player2Name = quiz.player2.Name
			}

			-- Send results with context of who was the requester
			local resultsForRequester = copyTable(baseResults)
			resultsForRequester.player1IsRequester = true
			resultsForRequester.questions = resultsForRequester.requesterQuestions
			resultsEvent:FireClient(quiz.player1, resultsForRequester)

			local resultsForChallenged = copyTable(baseResults)
			resultsForChallenged.player1IsRequester = false
			resultsForChallenged.questions = resultsForChallenged.challengedQuestions
			resultsEvent:FireClient(quiz.player2, resultsForChallenged)

			-- ── Award XP to both players ──────────────────────────────
			local function countCorrect(answers, correctAnswers)
				local n = 0
				for i, ans in pairs(answers) do
					if correctAnswers[i] == ans then n = n + 1 end
				end
				return n
			end

			-- Correct answers = where player1 and player2 matched
			local matchCount = 0
			for i = 1, totalQuestions do
				if quiz.answers1[i] == quiz.answers2[i] then
					matchCount = matchCount + 1
				end
			end

			task.spawn(function()
				awardQuizXP(quiz.player1, matchCount, totalQuestions)
				awardQuizXP(quiz.player2, matchCount, totalQuestions)
			end)

			-- Clean up
			activeQuizzes[quizId] = nil

			local completedBadge = 1076564770815567
			local b = game:GetService("BadgeService")
			b:AwardBadge(quiz.player1.UserId, completedBadge)
			b:AwardBadge(quiz.player2.UserId, completedBadge)
		end
	end
end)

-- ============================================================
-- ADMIN LIST
-- ============================================================
-- Add Roblox User IDs here to grant someone full admin perks:
--   • All levels unlocked (totalXP set to a huge value on join)
--   • Exclusive admin cosmetics auto-equipped on join
-- ============================================================
local ADMIN_USER_IDS = {
	-- Example:  1234567890,
	1796242043
	-- Add your own user IDs below:
}

-- Quick lookup set so IsAdmin is O(1)
local _adminSet = {}
for _, id in ipairs(ADMIN_USER_IDS) do _adminSet[id] = true end

local function isAdmin(userId)
	return _adminSet[userId] == true
end

-- The cosmetic IDs that are auto-equipped for admins.
-- These IDs must also be listed in the client UNLOCKS table.
local ADMIN_COSMETIC_IDS = {
	"admin_crown_border",
	"admin_galaxy_ring",
	"admin_meteor_anim",
}

-- XP value that puts an admin at a very high level
-- (the level curve is 200 * n^1.5, so ~50 million covers level 300+)
local ADMIN_XP = 50000000

-- ============================================================
-- XP / PROGRESSION SYSTEM
-- ============================================================

local XPStore      = DataStoreService:GetDataStore("PlayerXP_v1")
local XPUpdated    = Instance.new("RemoteEvent")
XPUpdated.Name     = "XPUpdated"
XPUpdated.Parent   = ReplicatedStorage

local GetXPData    = Instance.new("RemoteFunction")
GetXPData.Name     = "GetXPData"
GetXPData.Parent   = ReplicatedStorage

-- ============================================================
-- COSMETICS SYNC SYSTEM
-- ============================================================

local CosmeticsStore = DataStoreService:GetDataStore("PlayerCosmetics_v1")

-- Client → Server: save + broadcast new equipped set
local SetCosmetics = Instance.new("RemoteEvent")
SetCosmetics.Name  = "SetCosmetics"
SetCosmetics.Parent = ReplicatedStorage

-- Client → Server → Client: ask for a specific player's equipped ids
local GetCosmetics = Instance.new("RemoteFunction")
GetCosmetics.Name  = "GetCosmetics"
GetCosmetics.Parent = ReplicatedStorage

-- Server → All Clients: a player's cosmetics changed
local CosmeticsChanged = Instance.new("RemoteEvent")
CosmeticsChanged.Name  = "CosmeticsChanged"
CosmeticsChanged.Parent = ReplicatedStorage

-- In-memory cache so we don't hit DataStore on every GetCosmetics call
local _cosmeticsCache = {}   -- [userId] = { equippedIds = {id,...} }

local function loadCosmeticsData(userId)
	if _cosmeticsCache[userId] then return _cosmeticsCache[userId] end
	local ok, data = pcall(function()
		return CosmeticsStore:GetAsync(tostring(userId))
	end)
	local result = (ok and type(data) == "table") and data or { equippedIds = {} }
	_cosmeticsCache[userId] = result
	return result
end

local function saveCosmeticsData(userId, data)
	_cosmeticsCache[userId] = data
	pcall(function()
		CosmeticsStore:SetAsync(tostring(userId), data)
	end)
end

-- When a client equips/unequips cosmetics, save and broadcast to everyone
-- Admin cosmetic IDs as a quick-lookup set
local _adminCosmeticSet = {}
for _, id in ipairs(ADMIN_COSMETIC_IDS) do _adminCosmeticSet[id] = true end

SetCosmetics.OnServerEvent:Connect(function(player, equippedIds)
	if type(equippedIds) ~= "table" then return end

	-- Admins always wear their exclusive set; ignore client requests
	if isAdmin(player.UserId) then
		saveCosmeticsData(player.UserId, { equippedIds = ADMIN_COSMETIC_IDS })
		CosmeticsChanged:FireAllClients(player.Name, ADMIN_COSMETIC_IDS)
		return
	end

	-- Sanitise: only allow strings, max 20 entries, strip admin-only ids
	local clean = {}
	for _, id in ipairs(equippedIds) do
		if type(id) == "string" and #clean < 20 and not _adminCosmeticSet[id] then
			table.insert(clean, id)
		end
	end
	saveCosmeticsData(player.UserId, { equippedIds = clean })
	-- Broadcast to ALL clients so rings update in real time for everyone
	CosmeticsChanged:FireAllClients(player.Name, clean)
end)

-- Any client can ask for another player's cosmetics
GetCosmetics.OnServerInvoke = function(_, targetPlayerName)
	-- Try online player first (cheaper)
	local target = Players:FindFirstChild(targetPlayerName)
	if target then
		local data = loadCosmeticsData(target.UserId)
		return data.equippedIds or {}
	end
	-- Offline lookup by name → userId via Players service
	local ok, userId = pcall(function()
		return Players:GetUserIdFromNameAsync(targetPlayerName)
	end)
	if ok and userId then
		local data = loadCosmeticsData(userId)
		print(data)
		return data.equippedIds or {}
	end
	return {}
end

-- Client → Server → Client: fetch cosmetics for ALL currently online players at once.
-- Returns a dict { [playerName] = { id, id, ... } } so the client can populate
-- _G.playerCosmetics in a single round-trip instead of one call per player.
local GetAllCosmetics = Instance.new("RemoteFunction")
GetAllCosmetics.Name   = "GetAllCosmetics"
GetAllCosmetics.Parent = ReplicatedStorage

GetAllCosmetics.OnServerInvoke = function(_)
	local result = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local data = loadCosmeticsData(p.UserId)
		result[p.Name] = data.equippedIds or {}
	end
	print(result)
	return result
end

-- When a player joins, broadcast THEIR cosmetics to everyone already online,
-- AND send ALL existing players' cosmetics back to the joining player.
Players.PlayerAdded:Connect(function(newPlayer)
	task.delay(1, function()
		--if not (newPlayer and newPlayer.Parent) then return end

		-- 1) Tell everyone about the new player's cosmetics
		local newData = loadCosmeticsData(newPlayer.UserId)
		if newData.equippedIds and #newData.equippedIds > 0 then
			CosmeticsChanged:FireAllClients(newPlayer.Name, newData.equippedIds)
		end

		-- 2) Push every existing player's cosmetics to the joining client
		--    so they immediately see everyone's effects
		for _, existing in ipairs(Players:GetPlayers()) do
			if existing ~= newPlayer then
				local existingData = loadCosmeticsData(existing.UserId)
				if existingData.equippedIds and #existingData.equippedIds > 0 then
					CosmeticsChanged:FireClient(newPlayer, existing.Name, existingData.equippedIds)
				end
			end
		end
	end)
end)

-- ── XP CONFIG ────────────────────────────────────────────────
local XP_DAILY_LOGIN    = 50     -- XP for logging in today
local XP_QUIZ_BASE      = 100    -- XP just for finishing a quiz
local XP_PER_CORRECT    = 25     -- XP for each correct answer
local XP_STREAK_BONUS   = {      -- bonus multiplier per streak day (caps at index 7)
	[1] = 1.0,
	[2] = 1.0,
	[3] = 1.25,
	[4] = 1.35,
	[5] = 1.5,
	[6] = 1.6,
	[7] = 2.0,
}

-- XP needed to reach each level: level n needs XP_FOR_LEVEL(n)
-- Simple quadratic curve: 200 * n^1.5
local function xpForLevel(level)
	return math.floor(200 * (level ^ 1.5))
end

-- Given total accumulated XP return { level, currentXP, neededXP }
local function calculateLevel(totalXP)
	local level = 1
	local spent = 0
	while true do
		local needed = xpForLevel(level)
		if spent + needed > totalXP then
			return level, totalXP - spent, needed
		end
		spent = spent + needed
		level = level + 1
	end
end

-- Safely read a player's XP data from DataStore
local function loadXPData(userId)
	local success, data = pcall(function()
		return XPStore:GetAsync(tostring(userId))
	end)
	if success and type(data) == "table" then
		return data
	end
	-- Default new-player data
	return {
		totalXP        = 0,
		lastLoginDay   = 0,   -- os.time() day index (floor(os.time()/86400))
		loginStreak    = 0,
	}
end

-- Safely save XP data
local function saveXPData(userId, data)
	pcall(function()
		XPStore:SetAsync(tostring(userId), data)
	end)
end

-- Build the client-facing payload
local function buildXPPayload(data)
	local level, currentXP, neededXP = calculateLevel(data.totalXP)
	return {
		totalXP      = data.totalXP,
		level        = level,
		currentXP    = currentXP,
		neededXP     = neededXP,
		loginStreak  = data.loginStreak,
	}
end

-- Award XP to a player, fire update to client, return XP gained
local function awardXP(player, amount, reason)
	local data = loadXPData(player.UserId)
	data.totalXP = (data.totalXP or 0) + math.max(0, amount)
	saveXPData(player.UserId, data)

	local payload = buildXPPayload(data)
	payload.gained = amount
	payload.reason = reason or "XP Earned"
	XPUpdated:FireClient(player, payload)
	return amount
end

-- Handle daily login XP + streak on join
local function handleDailyLogin(player)
	local data = loadXPData(player.UserId)
	local todayIndex = math.floor(os.time() / 86400)

	-- ── Admin override ────────────────────────────────────────
	-- Admins always get max XP and their exclusive cosmetics,
	-- regardless of daily-login state.
	if isAdmin(player.UserId) then
		-- Ensure admin XP is always at least ADMIN_XP
		if (data.totalXP or 0) < ADMIN_XP then
			data.totalXP = ADMIN_XP
			saveXPData(player.UserId, data)
		end
		-- Push max-level payload to admin's client
		local adminPayload = buildXPPayload(data)
		XPUpdated:FireClient(player, adminPayload)

		-- Force admin cosmetics into the cosmetics store and broadcast
		saveCosmeticsData(player.UserId, { equippedIds = ADMIN_COSMETIC_IDS })
		CosmeticsChanged:FireAllClients(player.Name, ADMIN_COSMETIC_IDS)
		return
	end
	-- ─────────────────────────────────────────────────────────

	if data.lastLoginDay == todayIndex then
		-- Already logged in today – just send current data
		XPUpdated:FireClient(player, buildXPPayload(data))
		return
	end

	local yesterday = todayIndex - 1
	if data.lastLoginDay == yesterday then
		data.loginStreak = (data.loginStreak or 0) + 1
	else
		data.loginStreak = 1  -- Reset streak
	end

	data.lastLoginDay = todayIndex

	-- Streak multiplier (cap at 7)
	local streakDay    = math.min(data.loginStreak, 7)
	local multiplier   = XP_STREAK_BONUS[streakDay] or 2.0
	local gained       = math.floor(XP_DAILY_LOGIN * multiplier)
	data.totalXP       = (data.totalXP or 0) + gained
	saveXPData(player.UserId, data)

	local payload      = buildXPPayload(data)
	payload.gained     = gained
	payload.reason     = data.loginStreak >= 3
		and ("🔥 " .. data.loginStreak .. "-Day Streak! +" .. gained .. " XP")
		or  ("📅 Daily Login! +" .. gained .. " XP")
	payload.isLogin    = true
	XPUpdated:FireClient(player, payload)
end

-- Remote: client requests its own XP data on load
GetXPData.OnServerInvoke = function(player)
	local data = loadXPData(player.UserId)
	return buildXPPayload(data)
end

-- Fire daily-login check shortly after character loads (client fires CharacterAdded first)
Players.PlayerAdded:Connect(function(player)
	task.delay(3, function()
		if player and player.Parent then
			handleDailyLogin(player)
		end
	end)
end)

-- ── QUIZ XP AWARD ────────────────────────────────────────────
-- Called from within submitAnswer handler when quiz finishes
awardQuizXP = function(player, correctAnswers, totalQuestions)
	local base    = XP_QUIZ_BASE
	local bonus   = correctAnswers * XP_PER_CORRECT
	local total   = base + bonus

	local data    = loadXPData(player.UserId)
	local streakDay = math.min(data.loginStreak or 1, 7)
	local streakMult = XP_STREAK_BONUS[streakDay] or 1.0
	local awarded = math.floor(total * streakMult)

	local reason  = "🎯 Quiz Complete! +" .. awarded .. " XP"
		.. " (" .. correctAnswers .. "/" .. totalQuestions .. " correct"
		.. (streakMult > 1.0 and (", +" .. math.floor((streakMult - 1) * 100) .. "% streak bonus") or "")
		.. ")"

	awardXP(player, awarded, reason)
end

-- ============================================================
-- END XP SYSTEM
-- ============================================================

local DataStore = game:GetService("DataStoreService"):GetDataStore("Rewards")

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end

	if receiptInfo.ProductId == 3459901460 then
		local success, err = pcall(function()
			DataStore:UpdateAsync(player.UserId, function(currentData)
				currentData = currentData or {}
				currentData.allowFreeWithAdsPacks = true
				return currentData
			end)
		end)

		if not success then
			warn("Failed to update datastore for player "..player.Name..": "..tostring(err))
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end
