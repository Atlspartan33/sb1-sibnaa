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
-- Daily gift calendar: coins on days 1-6, a special accessory on day 7 (missing a day just pauses it)
Config.CALENDAR_COINS = { 30, 40, 50, 60, 70, 80 }
Config.CALENDAR_DAY7_COINS = 200 -- once every day-7 accessory has been collected
Config.RETURNING_CLIENT_CHANCE = 0.35 -- how often a client you styled before comes back
Config.BEST_FRIEND_VISITS = { 3, 5, 10 } -- visits that earn a best-friend bonus
Config.BEST_FRIEND_COINS = 25
Config.LOOKBOOK_SIZE = 24 -- looks saved in the Look Book
Config.WEEKLY_GOAL_SHOWS = 5 -- shows to play each week for the weekly prize
Config.WEEKLY_GOAL_COINS = 150 -- weekly prize once every weekly clip is collected

-- Robux monetization.
-- Create these on the Creator Dashboard (create.roblox.com) after publishing,
-- then paste the IDs here. While an ID is 0 the store shows "Coming soon".
Config.GamePasses = {
	VIP = 0, -- "VIP Glam Kit": exclusive hair, makeup and gowns + VIP badge on the runway
	Princess = 0, -- "Princess Pack": 2 gowns, Princess Curls, Rose Gold hair, tiara, pink gems
	DoubleCoins = 0, -- "2x Coins": earn double coins every show
	RunwayStar = 0, -- "Runway Star": sparkles and confetti when your client walks the runway
	RainbowBubbles = 0, -- "Rainbow Bubbles": washing makes rainbow bubbles (just for looks)
}

Config.DevProducts = {
	CoinsSmall = 0, -- 500 coins
}

Config.CoinPackAmounts = {
	CoinsSmall = 500,
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

-- Holiday events (Halloween, Harvest Festival, Christmas) turn on by date - see Shared/Events.
-- To preview one in Studio, set this to "halloween", "thanksgiving" or "christmas".
Config.FORCE_EVENT = nil :: string?
Config.EVENT_THEME_CHANCE = 0.5 -- during an event, how often the show uses the holiday theme

-- Studio testing: pretend you own every Game Pass while testing in Roblox Studio.
-- This never applies in the live game.
Config.STUDIO_OWNS_ALL_PASSES = true

-- Saving. Changing the name starts everyone over with fresh data.
Config.DATASTORE_NAME = "GlowUpSalon_v1"
Config.AUTOSAVE_SECONDS = 120

return Config
