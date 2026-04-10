-- Easter Pack (Premium)
-- Place in ReplicatedStorage/Packs/easter_premium

local pack = {
	name = "Easter Pack (Limited - Ends April 15)",
	type = "paid",
	limited = true,
	endDate = os.time({year = 2026, month = 4, day = 15, hour = 23, min = 59, sec = 59}), -- November 30, 2025
	questions = {
		{
			questionTemplate = "What unique Easter tradition would {player} create?",
			personalQuestion = "What unique Easter tradition would you create?",
			options = {"Night Egg Hunt", "Golden Egg Prize", "Candy Trading", "Egg Art Contest", "Costume Party", "Treasure Hunt"}
		},
		{
			questionTemplate = "What would {player} hide inside a special Easter egg?",
			personalQuestion = "What would you hide inside a special Easter egg?",
			options = {"Money", "Candy", "Mini Toys", "Notes", "Jokes", "Surprises"}
		},
		{
			questionTemplate = "How competitive is {player} during an Easter egg hunt?",
			personalQuestion = "How competitive are you during an Easter egg hunt?",
			options = {"Very Competitive", "Somewhat", "Just for Fun", "Relaxed", "Let Others Win", "Don't Participate"}
		},
		{
			questionTemplate = "What kind of Easter basket would {player} want most?",
			personalQuestion = "What kind of Easter basket would you want most?",
			options = {"All Candy", "Luxury Gifts", "DIY Basket", "Toys & Games", "Healthy Snacks", "Mystery Basket"}
		},
		{
			questionTemplate = "What Easter-themed game would {player} enjoy most?",
			personalQuestion = "What Easter-themed game would you enjoy most?",
			options = {"Egg Toss", "Egg Rolling", "Scavenger Hunt", "Trivia", "Relay Race", "Puzzle Game"}
		},
		{
			questionTemplate = "If {player} were the Easter Bunny, what would they do?",
			personalQuestion = "If you were the Easter Bunny, what would you do?",
			options = {"Hide Eggs Everywhere", "Give Big Prizes", "Play Tricks", "Deliver Candy", "Make It Challenging", "Keep It Easy"}
		},
		{
			questionTemplate = "What Easter dessert would {player create?",
			personalQuestion = "What Easter dessert would you create?",
			options = {"Chocolate Cake", "Cupcakes", "Candy Mix", "Fruit Dessert", "Cookies", "Ice Cream"}
		},
		{
			questionTemplate = "What kind of Easter vibe does {player} like?",
			personalQuestion = "What kind of Easter vibe do you like?",
			options = {"Calm & Cozy", "Fun & Playful", "Family Gathering", "Outdoor Adventure", "Fancy Celebration", "Relaxed"}
		},
		{
			questionTemplate = "What would {player} do after an Easter egg hunt?",
			personalQuestion = "What would you do after an Easter egg hunt?",
			options = {"Eat Candy", "Trade Eggs", "Relax", "Play Games", "Take Photos", "Celebrate"}
		},
		{
			questionTemplate = "What makes Easter special to {player}?",
			personalQuestion = "What makes Easter special to you?",
			options = {"Family", "Traditions", "Candy", "Fun Activities", "Spring Weather", "Relaxing"}
		}
	}
}

return pack
