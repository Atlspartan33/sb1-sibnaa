-- Game settings. Change numbers here to tune the game without touching the rest of the code.

local Config = {}

-- Round timing (seconds)
Config.MAKEOVER_SECONDS = 5 * 60 -- Tori's rule: 5 minutes to do everything!
Config.INTERMISSION_SECONDS = 20
Config.SHOWCASE_SECONDS_PER_LOOK = 9
Config.RESULTS_SECONDS = 15
Config.MIN_PLAYERS = 1

-- Coins
Config.STARTING_COINS = 100
Config.COINS_PARTICIPATION = 20
Config.COINS_PER_STAR = 10
Config.COINS_SPOTLESS_BONUS = 10
Config.COINS_PER_VOTE = 2
Config.COINS_PLACEMENT = { 50, 30, 15 } -- 1st, 2nd, 3rd (only when 2+ stylists played)
Config.DAILY_GIFT_COINS = 50 -- coming back each day
Config.DAILY_STREAK_BONUS = 10 -- extra per day in a row (up to 5 days)

-- Robux monetization.
-- Create these on the Creator Dashboard (create.roblox.com) after publishing,
-- then paste the IDs here. While an ID is 0 the store shows "Coming soon".
Config.GamePasses = {
	VIP = 0, -- "VIP Glam Kit": exclusive hair, makeup and gowns + VIP badge on the runway
	DoubleCoins = 0, -- "2x Coins": earn double coins every show
	RunwayStar = 0, -- "Runway Star": sparkles and confetti when your client walks the runway
}

Config.DevProducts = {
	SuperSoap = 0, -- one Super Soap: instantly washes a client's face
	CoinsSmall = 0, -- 500 coins
	CoinsLarge = 0, -- 2000 coins
}

Config.CoinPackAmounts = {
	CoinsSmall = 500,
	CoinsLarge = 2000,
}

-- Sounds and music. Find free ones in Studio: Toolbox -> Audio (or the Creator Store),
-- right-click one -> "Copy Asset ID", and paste it here like "rbxassetid://1234567".
-- Empty ones are skipped, so the game works without them.
Config.Sounds = {
	Click = "", -- tapping a button or item
	Pop = "", -- pop-ups and speech bubbles
	Scrub = "", -- rubbing with soap
	Sparkle = "", -- a dirt spot comes off, face is clean
	Cheer = "", -- results, level up, daily gift
	Camera = "", -- camera flash on the runway
	MakeoverMusic = "", -- loops during the makeover
	RunwayMusic = "", -- loops during the fashion show
}

-- Studio testing: pretend you own every Game Pass while testing in Roblox Studio.
-- This never applies in the live game.
Config.STUDIO_OWNS_ALL_PASSES = true

-- Saving. Changing the name starts everyone over with fresh data.
Config.DATASTORE_NAME = "GlowUpSalon_v1"
Config.AUTOSAVE_SECONDS = 120

return Config
