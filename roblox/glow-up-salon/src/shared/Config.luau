-- Game settings. Change numbers here to tune the game without touching the rest of the code.

local Config = {}

-- Round timing (seconds)
Config.MAKEOVER_SECONDS = 5 * 60 -- Tori's rule: 5 minutes to do everything!
Config.INTERMISSION_SECONDS = 20
Config.SHOWCASE_SECONDS_PER_LOOK = 9
Config.RESULTS_SECONDS = 15
Config.MIN_PLAYERS = 1
-- Style Bots (pretend friends) fill the show up to this many contestants, if they're turned on
Config.BOTS_FILL_TO = 3

-- Coins
Config.STARTING_COINS = 100
Config.COINS_PARTICIPATION = 20
Config.COINS_PER_STAR = 10
Config.COINS_SPOTLESS_BONUS = 0 -- (washing is on the shelf, so there's no spotless bonus)
Config.COINS_PER_VOTE = 2
Config.HUNT_STARS = 12 -- stars to chase around the rooftop in the lobby
Config.COINS_PER_HUNT_STAR = 2
Config.CHEER_GOAL = 12 -- cheers for one walk that set off the fireworks
Config.COINS_CROWD_FAVORITE = 5 -- for the walker when the crowd goes wild
Config.COINS_PER_WISH = 15 -- each of the client's wishes you make come true
Config.COINS_PLACEMENT = { 50, 30, 15 } -- 1st, 2nd, 3rd (only when 2+ real players were in the show)
Config.FRIEND_BONUS = 0.2 -- extra coins when a Roblox friend is in the server with you
Config.HURRY_SECONDS = 30 -- once half the real players are done, everyone else gets this long
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
	VIP = 2052240115, -- "VIP Glam Kit": exclusive hair, makeup and gowns + VIP badge on the runway
	Princess = 2052696043, -- "Princess Pack": 2 gowns, Princess Curls, Rose Gold hair, tiara, pink gems
	DoubleCoins = 2052744112, -- "2x Coins": earn double coins every show
	RunwayStar = 2054184060, -- "Runway Star": sparkles and confetti when your client walks the runway
	FashionWeek = 2054016100, -- "Fashion Week Pack": 6 real designer dresses and a puffer jacket
	PetPalace = 2052168030, -- "Pet Palace": Winged Bunny, Glitter Kitty, Baby Pegasus, Bubble Turtle
}

Config.DevProducts = {
	CoinsSmall = 3722236554, -- 500 coins (49 R$)
	CoinsMedium = 3722236788, -- 1,500 coins (99 R$)
	CoinsLarge = 3722236989, -- 4,000 coins (199 R$)
}

Config.CoinPackAmounts = {
	CoinsSmall = 500,
	CoinsMedium = 1500,
	CoinsLarge = 4000,
}

-- Sounds and music. The filled-in ones are free sounds from Roblox's own audio tutorials.
-- Add more in Studio: Toolbox -> Audio (or the Creator Store), right-click one ->
-- "Copy Asset ID", and paste it here like "rbxassetid://1234567". Empty ones are skipped.
Config.Sounds = {
	Click = "rbxassetid://122966251252708", -- tapping a button or item (a 0.1s soft UI tap)
	Pop = "rbxassetid://4110925712", -- pop-ups and speech bubbles (the same gentle chime)
	Scrub = "", -- rubbing with soap or brushing hair
	Rinse = "rbxasset://sounds/impact_water.mp3", -- rinsing the bubbles (a water splash built into Roblox)
	Sparkle = "rbxassetid://4110925712", -- a dirt spot comes off (Roblox tutorial "simple chime")
	Cheer = "rbxassetid://3422389728", -- results, level up, daily gift (Roblox tutorial "retro jingle")
	Camera = "rbxassetid://17208312548", -- camera flash on the runway and in the photo booth (Roblox GUI camera shutter)
	MakeoverMusic = "rbxassetid://1841461968", -- loops during the makeover (Roblox tutorial "upbeat" track)
	RunwayMusic = "rbxassetid://1846248593", -- loops during the fashion show (Roblox tutorial "cheerful, celebratory" track)
}

-- Volume for each sound (0-1). Sounds not listed play at 0.6.
Config.SoundVolumes = {
	Rinse = 0.25,
	Click = 0.35,
} :: { [string]: number }

-- A model's strut (Roblox's Catwalk Glam animation pack): everyone walks like this during a round.
Config.Catwalk = {
	Walk = 103190462987721,
	Run = 75036746190467,
	Idle = 101279640971758,
}

-- Particle pictures from Roblox's own particle tutorial
Config.Textures = {
	Star = "rbxassetid://6772783963",
	Heart = "rbxassetid://5857851618",
	Circle = "rbxassetid://6711256324",
	Spark = "rbxassetid://5833323391",
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
