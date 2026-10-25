-- Saves each player's coins, unlocked items and Super Soaps between visits.

local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Catalog = require(ReplicatedStorage.Shared.Catalog)
local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DataService = {}

export type Profile = {
	coins: number,
	owned: { [string]: boolean },
	stats: { shows: number, wins: number, bestStars: number, totalStars: number },
	lastDay: number, -- last day a daily gift was given (days since 1970)
	streak: number, -- days played in total (the gift calendar never resets)
	giftsGiven: number, -- day-7 accessories collected
	friends: { [string]: { visits: number, skin: number, eyes: number } }, -- regular clients
	lookbook: { any }, -- saved finished looks, newest first
	week: number, -- which week the weekly goal counts (weeks since 1970)
	weekShows: number,
	weekClaimed: boolean,
	weeklyGiven: number, -- weekly prizes collected
	lookbookChanged: boolean?, -- not saved: send the Look Book with the next push
	lookbookSent: boolean?, -- not saved: the player has the Look Book already
	receipts: { string },
	passes: { [string]: boolean }, -- not saved; checked with Roblox every visit
	canSave: boolean, -- false if loading failed, so we never overwrite good data with an empty profile
}

local profiles: { [Player]: Profile } = {}

-- While a server has a player's data open it stamps it with its JobId, so a second server
-- (e.g. the player quickly hopped servers) waits instead of loading old coins.
local LOCK_SECONDS = Config.AUTOSAVE_SECONDS + 60

local store: DataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DATASTORE_NAME)
	end)
	if ok then
		store = result
	else
		warn("[GlowUp] Saving is off (turn on 'Enable Studio Access to API Services' to test it):", result)
	end
end

local function keyFor(player: Player): string
	return "player_" .. player.UserId
end

local function newProfile(saved): Profile
	saved = saved or {}
	local stats = saved.stats or {}
	return {
		coins = tonumber(saved.coins) or Config.STARTING_COINS,
		owned = saved.owned or {},
		stats = {
			shows = stats.shows or 0,
			wins = stats.wins or 0,
			bestStars = stats.bestStars or 0,
			totalStars = stats.totalStars or 0,
		},
		lastDay = tonumber(saved.lastDay) or 0,
		streak = tonumber(saved.streak) or 0,
		giftsGiven = tonumber(saved.giftsGiven) or 0,
		friends = saved.friends or {},
		lookbook = saved.lookbook or {},
		week = tonumber(saved.week) or 0,
		weekShows = tonumber(saved.weekShows) or 0,
		weekClaimed = saved.weekClaimed == true,
		weeklyGiven = tonumber(saved.weeklyGiven) or 0,
		receipts = saved.receipts or {},
		passes = {},
		canSave = true,
	}
end

local function checkPasses(player: Player, profile: Profile)
	for name, id in Config.GamePasses do
		if RunService:IsStudio() and Config.STUDIO_OWNS_ALL_PASSES then
			profile.passes[name] = true
		elseif id ~= 0 then
			local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, id)
			profile.passes[name] = ok and owns == true
		end
	end
end

function DataService.get(player: Player): Profile?
	return profiles[player]
end

-- Waits (a little) for a player's data to finish loading.
function DataService.waitFor(player: Player): Profile?
	local deadline = os.clock() + 15
	while not profiles[player] and player.Parent and os.clock() < deadline do
		task.wait(0.1)
	end
	return profiles[player]
end

-- Sends the player's latest coins/unlocks to their screen.
function DataService.push(player: Player)
	local p = profiles[player]
	if p then
		Remotes.Profile:FireClient(player, {
			coins = p.coins,
			owned = p.owned,
			passes = p.passes,
			totalStars = p.stats.totalStars,
			calendarDay = p.streak,
			-- the Look Book is only sent when it changed (it's the biggest part)
			lookbook = if p.lookbookChanged or not p.lookbookSent then p.lookbook else nil,
			weekShows = if p.week == DataService.weekNumber() then p.weekShows else 0,
			weekClaimed = p.week == DataService.weekNumber() and p.weekClaimed,
			weeklyNext = Catalog.WeeklyItems[p.weeklyGiven + 1],
		})
		p.lookbookChanged = false
		p.lookbookSent = true
	end
end

function DataService.addCoins(player: Player, amount: number)
	local p = profiles[player]
	if amount ~= amount or math.abs(amount) == math.huge then
		return
	end
	if p then
		p.coins = math.max(0, p.coins + math.floor(amount))
		DataService.push(player)
	end
end

-- True when coins and unlocks are really being saved (false in Studio without API access).
function DataService.savingEnabled(): boolean
	return store ~= nil
end

local function lockedByOtherServer(old): boolean
	return old ~= nil and old.session ~= nil and old.session ~= game.JobId and os.time() - (old.lockTime or 0) < LOCK_SECONDS
end

-- Saves a player's data. `release` clears this server's lock (when the player leaves).
function DataService.save(player: Player, release: boolean?): boolean
	local p = profiles[player]
	if not p or not p.canSave or not store then
		return false
	end
	for attempt = 1, 3 do
		local wrote = false
		local ok, err = pcall(function()
			(store :: DataStore):UpdateAsync(keyFor(player), function(old)
				if lockedByOtherServer(old) then
					return nil -- another server has newer data; don't overwrite it
				end
				wrote = true
				-- Built here (not before the loop) so a retry always saves the newest values
				return {
					coins = p.coins,
					owned = p.owned,
							stats = p.stats,
					receipts = p.receipts,
					lastDay = p.lastDay,
					streak = p.streak,
					giftsGiven = p.giftsGiven,
					friends = p.friends,
					lookbook = p.lookbook,
					week = p.week,
					weekShows = p.weekShows,
					weekClaimed = p.weekClaimed,
					weeklyGiven = p.weeklyGiven,
					session = if release then nil else game.JobId,
					lockTime = os.time(),
				}
			end)
		end)
		if ok then
			if not wrote then
				warn("[GlowUp] Not saving " .. player.Name .. ": their data is open on another server")
			end
			return wrote
		end
		warn("[GlowUp] Save failed (try " .. attempt .. "):", err)
		task.wait(attempt)
	end
	return false
end

-- Days and weeks change at 05:00 UTC (midnight in New York, 9pm in Los Angeles) so most kids
-- in the US get a new day in the morning. Weeks start on Monday.
local DAY_OFFSET = 5 * 3600
function DataService.dayNumber(): number
	return (os.time() - DAY_OFFSET) // 86400
end
function DataService.weekNumber(): number
	return (os.time() - DAY_OFFSET + 3 * 86400) // 604800
end

-- The daily gift calendar: a prize for each new day played. Missing a day just pauses it.
local function giveDailyGift(player: Player, profile: Profile)
	local today = DataService.dayNumber()
	if profile.lastDay >= today then
		return
	end
	profile.lastDay = today
	profile.streak += 1
	local day = (profile.streak - 1) % 7 + 1
	local info = { kind = "daily", day = day, coins = 0, item = nil :: string? }
	if day < 7 then
		info.coins = Config.CALENDAR_COINS[day]
	else
		local giftId = Catalog.GiftItems[profile.giftsGiven + 1]
		if giftId then
			profile.giftsGiven += 1
			profile.owned[giftId] = true
			info.item = Catalog.byId[giftId].name
		else
			info.coins = Config.CALENDAR_DAY7_COINS
		end
	end
	profile.coins += info.coins
	task.delay(3, function()
		if player.Parent then
			Remotes.Celebrate:FireClient(player, info)
			DataService.push(player)
		end
	end)
end

-- Called at the start of each round for players who stayed past midnight.
function DataService.checkDaily(player: Player)
	local profile = profiles[player]
	if profile then
		giveDailyGift(player, profile)
	end
end

local function load(player: Player)
	local saved = nil
	local loaded = store == nil -- no store (e.g. Studio without API access): play with a fresh profile
	if store then
		for attempt = 1, 8 do
			local claimed = false
			local ok, result = pcall(function()
				(store :: DataStore):UpdateAsync(keyFor(player), function(old)
					-- After ~20 seconds of waiting, take over a lock that was never released
					if lockedByOtherServer(old) and attempt < 8 then
						saved = old
						return nil
					end
					claimed = true
					saved = old
					local new = old or {}
					new.session = game.JobId
					new.lockTime = os.time()
					return new
				end)
			end)
			if ok and claimed then
				loaded = true
				break
			end
			if not ok and RunService:IsStudio() then
				-- Usually "Enable Studio Access to API Services" is off. Play without saving.
				warn("[GlowUp] Saving is off in Studio:", result)
				store = nil
				loaded = true
				saved = nil
				break
			end
			if not ok then
				warn("[GlowUp] Load failed (try " .. attempt .. "):", result)
			end
			task.wait(3)
		end
	end
	if not player.Parent then
		return
	end

	local profile = newProfile(saved)
	profile.canSave = loaded and store ~= nil
	if not loaded then
		Remotes.Notify:FireClient(player, "Couldn't load your saved coins. Progress this visit won't be saved.")
	end
	checkPasses(player, profile)
	giveDailyGift(player, profile)
	profiles[player] = profile
	DataService.push(player)
end

function DataService.init()
	Players.PlayerAdded:Connect(load)
	for _, player in Players:GetPlayers() do
		task.spawn(load, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		DataService.save(player, true)
		profiles[player] = nil
	end)

	game:BindToClose(function()
		local pending = 0
		for player in profiles do
			pending += 1
			task.spawn(function()
				DataService.save(player, true)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.2)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(Config.AUTOSAVE_SECONDS)
			for player in profiles do
				task.spawn(DataService.save, player)
			end
		end
	end)
end

return DataService
