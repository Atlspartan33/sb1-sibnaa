-- Saves each player's coins, unlocked items and Super Soaps between visits.

local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DataService = {}

export type Profile = {
	coins: number,
	owned: { [string]: boolean },
	superSoaps: number,
	stats: { shows: number, wins: number, bestStars: number },
	receipts: { string },
	passes: { [string]: boolean }, -- not saved; checked with Roblox every visit
	canSave: boolean, -- false if loading failed, so we never overwrite good data with an empty profile
}

local profiles: { [Player]: Profile } = {}

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
		superSoaps = tonumber(saved.superSoaps) or 0,
		stats = {
			shows = stats.shows or 0,
			wins = stats.wins or 0,
			bestStars = stats.bestStars or 0,
		},
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
			superSoaps = p.superSoaps,
		})
	end
end

function DataService.addCoins(player: Player, amount: number)
	local p = profiles[player]
	if p then
		p.coins = math.max(0, p.coins + math.floor(amount))
		DataService.push(player)
	end
end

function DataService.save(player: Player): boolean
	local p = profiles[player]
	if not p or not p.canSave or not store then
		return false
	end
	local data = {
		coins = p.coins,
		owned = p.owned,
		superSoaps = p.superSoaps,
		stats = p.stats,
		receipts = p.receipts,
	}
	for attempt = 1, 3 do
		local ok, err = pcall(function()
			(store :: DataStore):UpdateAsync(keyFor(player), function()
				return data
			end)
		end)
		if ok then
			return true
		end
		warn("[GlowUp] Save failed (try " .. attempt .. "):", err)
		task.wait(attempt)
	end
	return false
end

local function load(player: Player)
	local saved = nil
	local loaded = store == nil -- no store (e.g. Studio without API access): play with a fresh profile
	if store then
		for attempt = 1, 3 do
			local ok, result = pcall(function()
				return (store :: DataStore):GetAsync(keyFor(player))
			end)
			if ok then
				saved = result
				loaded = true
				break
			end
			if RunService:IsStudio() then
				-- Usually "Enable Studio Access to API Services" is off. Play without saving.
				warn("[GlowUp] Saving is off in Studio:", result)
				store = nil
				loaded = true
				break
			end
			warn("[GlowUp] Load failed (try " .. attempt .. "):", result)
			task.wait(attempt)
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
	profiles[player] = profile
	DataService.push(player)
end

function DataService.init()
	Players.PlayerAdded:Connect(load)
	for _, player in Players:GetPlayers() do
		task.spawn(load, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		DataService.save(player)
		profiles[player] = nil
	end)

	game:BindToClose(function()
		local pending = 0
		for player in profiles do
			pending += 1
			task.spawn(function()
				DataService.save(player)
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
