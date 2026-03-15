BadgetId = 784443634014846 

game.Players.PlayerAdded:connect(function(p)
wait(0.1) 
local b = game:GetService("BadgeService")
b:AwardBadge(p.userId,BadgetId)
end)
