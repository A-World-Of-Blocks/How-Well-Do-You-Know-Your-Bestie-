-- St. Patricks Day Pack
-- Place in ReplicatedStorage/Packs/st_patricks

local pack = {
	name = "St. Patricks Day Pack",
	type = "ad",
	Image = "94953319800016", -- Replace with your asset ID
	questions = {
		{
			questionTemplate = "What would {player} do if they found a pot of gold?",
			personalQuestion = "What would you do if you found a pot of gold?",
			options = {"Save It", "Buy Robux", "Share with Friends", "Buy a Car", "Hide It"}
		},
		{
			questionTemplate = "Which 'Lucky' item fits {player} best?",
			personalQuestion = "Which 'Lucky' item fits you best?",
			options = {"4-Leaf Clover", "Lucky Penny", "Horseshoe", "Rabbit's Foot", "None"}
		},
		{
			questionTemplate = "How much green is {player} wearing today?",
			personalQuestion = "How much green are you wearing today?",
			options = {"Head to Toe", "Just a Little", "One Item", "None (Pinch Me)", "Green Eyes!"}
		},
		{
			questionTemplate = "What is {player}'s favorite St. Paddy's treat?",
			personalQuestion = "What is your favorite St. Paddy's treat?",
			options = {"Green Cookies", "Gold Chocolate", "Mint Shake", "Green Soda", "Apple"}
		},
		{
			questionTemplate = "What would {player} do if they caught a Leprechaun?",
			personalQuestion = "What would you do if you caught a Leprechaun?",
			options = {"Ask for Gold", "Ask for 3 Wishes", "Let it Go", "Take a Selfie", "Ask for Luck"}
		},
		{
			questionTemplate = "Which green emoji fits {player}'s vibe?",
			personalQuestion = "Which green emoji fits your vibe?",
			options = {"🍀", "☘️", "🦖", "🍏", "🤢"}
		},
		{
			questionTemplate = "Where would {player} look for a rainbow's end?",
			personalQuestion = "Where would you look for a rainbow's end?",
			options = {"The Mountains", "The Ocean", "My Backyard", "The Forest", "Outer Space"}
		},
		{
			questionTemplate = "Does {player} consider themselves a lucky person?",
			personalQuestion = "Do you consider yourself a lucky person?",
			options = {"Super Lucky", "Often Lucky", "Sometimes", "Rarely", "I Make My Own Luck"}
		},
		{
			questionTemplate = "What St. Paddy's activity would {player} enjoy most?",
			personalQuestion = "What St. Paddy's activity would you enjoy most?",
			options = {"A Parade", "Searching for Clovers", "Dressing Up", "Eating Green Food", "Gaming"}
		}
	}
}

return pack
