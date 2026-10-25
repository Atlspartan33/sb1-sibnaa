-- Runs the game loop that everyone in the server plays together:
--   Intermission -> Makeover (5 minutes) -> Fashion Show -> Results -> repeat

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Avatar = require(ReplicatedStorage.Shared.Avatar)
local Catalog = require(ReplicatedStorage.Shared.Catalog)
local Clients = require(ReplicatedStorage.Shared.Clients)
local Config = require(ReplicatedStorage.Shared.Config)
local Events = require(ReplicatedStorage.Shared.Events)
local Progress = require(ReplicatedStorage.Shared.Progress)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Pets = require(ReplicatedStorage.Shared.Pets)
local RunService = game:GetService("RunService")
local Scoring = require(ReplicatedStorage.Shared.Scoring)

local DataService = require(script.Parent.DataService)
local WorldBuilder = require(script.Parent.WorldBuilder)

local RoundService = {}

type Entry = {
	player: Player,
	client: Clients.Client,
	look: { [string]: string },
	clean: number,
	rinsed: boolean,
	done: boolean,
	votes: { [number]: number }, -- voter UserId -> stars
	assignedAt: number,
	pet: Model?, -- their pet, trotting after them during the round
}

local world: WorldBuilder.World
local rng = Random.new()

local state = {
	phase = "Waiting",
	endsAt = 0,
	themeId = Catalog.Themes[1].id,
	eventId = nil :: string?,
}
local entries: { [number]: Entry } = {} -- by UserId
local showcase = nil -- payload of the look currently on the runway
local results = nil -- payload of the last results
local spawnedModels: { Model } = {}
local resultsFor, sendResults, strikePose -- defined below
local decorated = false

local WALK_ANIMATION = "rbxassetid://507777826" -- Roblox's default R15 walk
local REACTIONS = { ["😍"] = true, ["👏"] = true, ["🔥"] = true, ["✨"] = true, ["💖"] = true }
local lastReaction: { [Player]: number } = {}
local lastCheer: { [Player]: number } = {}

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function setState(phase: string, seconds: number)
	state.phase = phase
	state.endsAt = now() + seconds
	Remotes.State:FireAllClients(state)
end

local function theme(): Catalog.Theme
	return Catalog.themeById[state.themeId]
end

local function entryPayload(entry: Entry)
	return {
		client = entry.client,
		look = entry.look,
		clean = entry.clean,
		rinsed = entry.rinsed,
		done = entry.done,
	}
end

local function hasPass(player: Player, pass: string): boolean
	local profile = DataService.get(player)
	return profile ~= nil and profile.passes[pass] == true
end

------------------------------------------------------------------------------
-- Makeover

-- Puts the entry's look on the player's real character (everyone sees it), and keeps their pet.
local function dressCharacter(entry: Entry)
	local character = entry.player.Character
	if not character or not character.Parent then
		return
	end
	-- always a happy face: a smile, and a big grin once the look is really good
	local stars = Scoring.judge(entry, theme())
	Avatar.dress(character, entry.client, entry.look, { clean = 1, mood = if stars >= 4 then "grin" else "smile", brushed = true })
	local petId = entry.look.pet
	if not entry.pet or entry.pet:GetAttribute("PetId") ~= petId then
		if entry.pet then
			entry.pet:Destroy()
			entry.pet = nil
		end
		local pet = Pets.build(petId)
		local root = character:FindFirstChild("HumanoidRootPart")
		if pet and root and root:IsA("BasePart") then
			pet:SetAttribute("PetId", petId)
			pet.Name = entry.player.Name .. "'s Pet"
			pet:PivotTo(root.CFrame * CFrame.new(2.6, -3, 0.6))
			pet.Parent = world.folder
			entry.pet = pet
		end
	end
end

-- Gets the character ready for the round (own body and skin, classic head, own hair and clothes
-- off) and puts the look on. Also used when someone respawns in the middle of a round.
local function prepareCharacter(entry: Entry)
	local character = entry.player.Character
	if not character then
		return
	end
	local skin = Avatar.prepareCharacter(character)
	if skin then
		entry.client.skin = skin
		local index = tonumber(string.match(Catalog.closestSkin(skin), "%d+"))
		entry.client.skinIndex = index or entry.client.skinIndex
	end
	dressCharacter(entry)
end

-- Each player dresses up themselves, in their own avatar.
local function assignClient(player: Player)
	local entry: Entry = {
		player = player,
		client = Clients.forPlayer(player.DisplayName, 7),
		look = Catalog.defaultLook(),
		clean = 1, -- no washing: you come in fresh
		rinsed = true,
		done = false,
		votes = {},
		assignedAt = now(),
	}
	entries[player.UserId] = entry
	-- their real skin goes in the payload, so the menus' little faces match them
	prepareCharacter(entry)
	Remotes.AssignClient:FireClient(player, entryPayload(entry))
end

local function activeEntry(player: Player): Entry?
	if state.phase ~= "Makeover" then
		return nil
	end
	return entries[player.UserId]
end

local function allDone(): boolean
	local any = false
	for _, entry in entries do
		if entry.player.Parent then
			any = true
			if not entry.done then
				return false
			end
		end
	end
	return any
end

local function onUpdateLook(player: Player, key: unknown, itemId: unknown)
	local entry = activeEntry(player)
	if not entry or type(key) ~= "string" or type(itemId) ~= "string" then
		return
	end
	local it = Catalog.byId[itemId]
	if not it or it.category ~= key then
		return
	end
	if not Catalog.isUnlocked(it, DataService.get(player), state.eventId) then
		Remotes.Notify:FireClient(player, "Unlock " .. it.name .. " in the shop first!")
		return
	end
	entry.look[key] = itemId
	dressCharacter(entry)
	-- Holiday items you used during the event are yours to keep afterwards
	if it.event then
		local profile = DataService.get(player)
		if profile and not profile.owned[it.id] then
			profile.owned[it.id] = true
		end
	end
end

local function onWashProgress(player: Player, clean: unknown, rinsed: unknown)
	local entry = activeEntry(player)
	if not entry or type(clean) ~= "number" or clean ~= clean then
		return
	end
	-- Nobody can really wash a face in under 4 seconds, so don't trust faster claims
	local possible = (now() - entry.assignedAt) / 4
	entry.clean = math.max(entry.clean, math.min(math.clamp(clean, 0, 1), possible))
	entry.rinsed = rinsed == true
end

local function onDone(player: Player, isDone: unknown)
	local entry = activeEntry(player)
	if entry then
		entry.done = isDone == true
	end
end

------------------------------------------------------------------------------
-- Runway models

local function buildBlockModel(skin: Color3, top: Color3, bottom: Color3): Model
	local model = Instance.new("Model")
	local function block(name, size, offset, color)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.CanCollide = false
		p.CFrame = CFrame.new(offset)
		p.Parent = model
		return p
	end
	local root = block("HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0), top)
	root.Transparency = 1
	local parts = {
		block("Torso", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0), top),
		block("LeftLeg", Vector3.new(1, 2, 1), Vector3.new(-0.5, 1, 0), bottom),
		block("RightLeg", Vector3.new(1, 2, 1), Vector3.new(0.5, 1, 0), bottom),
		block("LeftArm", Vector3.new(1, 2, 1), Vector3.new(-1.5, 3, 0), skin),
		block("RightArm", Vector3.new(1, 2, 1), Vector3.new(1.5, 3, 0), skin),
		block("Head", Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 4.6, 0), skin),
	}
	for _, p in parts do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = p
		weld.Parent = p
	end
	model.PrimaryPart = root
	return model
end

local function rootHeight(model: Model): number
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") :: BasePart
	if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then
		return humanoid.HipHeight + root.Size.Y / 2
	end
	return 3
end

-- Makes the 3D client wearing the look the stylist designed: a real Roblox character with
-- their hair, makeup face, outfit and accessory.
local function buildClientModel(entry: Entry): Model
	local stars = Scoring.judge(entry, theme())
	local model = Avatar.new(entry.client)
	if model then
		-- everyone sees the client washed and happy; the judges' tips stay private
		Avatar.dress(model, entry.client, entry.look, {
			clean = 1,
			mood = if stars >= 4 then "grin" else "smile",
			brushed = entry.look.hairStyle ~= "hair_messy",
		})
	else
		local outfit = Catalog.byId[entry.look.outfit]
		local top = if outfit and outfit.color then outfit.color else Color3.new(0.5, 0.5, 0.5)
		model = buildBlockModel(entry.client.skin, top, outfit and outfit.accent or top)
	end
	model.Name = entry.client.name
	model:SetAttribute("Pet", entry.look.pet) -- each screen walks the pet alongside (Showcase)

	-- a little trail of stars behind every look, and the player's name over their head
	local root = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
	local head = model:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		local tag = Instance.new("BillboardGui")
		tag.Name = "NameTag"
		tag.Size = UDim2.fromScale(6, 1)
		tag.StudsOffset = Vector3.new(0, 3.2, 0)
		tag.LightInfluence = 0
		tag.MaxDistance = 120
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.Text = entry.client.name
		label.TextScaled = true
		label.TextColor3 = Color3.fromRGB(176, 18, 91)
		label.TextStrokeColor3 = Color3.new(1, 1, 1)
		label.TextStrokeTransparency = 0
		label.Parent = tag
		tag.Parent = head
	end
	if root then
		local trail = Instance.new("ParticleEmitter")
		trail.Name = "StarTrail"
		trail.Texture = Config.Textures.Star
		trail.Rate = 8
		trail.Lifetime = NumberRange.new(1, 1.6)
		trail.Speed = NumberRange.new(1, 2)
		trail.SpreadAngle = Vector2.new(180, 180)
		trail.Size = NumberSequence.new(0.5, 0)
		trail.LightEmission = 0.6
		trail.Color = ColorSequence.new(theme().color, Color3.new(1, 1, 1))
		trail.Parent = root
	end

	if root and hasPass(entry.player, "RunwayStar") then
		Instance.new("Sparkles").Parent = root
	end

	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.CanCollide = false
			p.CanQuery = false
		end
	end
	model.Parent = world.folder
	table.insert(spawnedModels, model)
	return model
end


local function placeModel(model: Model, groundPosition: Vector3, facing: Vector3): BasePart
	local root = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") :: BasePart
	root.Anchored = true
	local pos = groundPosition + Vector3.new(0, rootHeight(model), 0)
	root.CFrame = CFrame.lookAt(pos, pos + facing)
	return root
end

local function playWalk(model: Model): AnimationTrack?
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	local anim = Instance.new("Animation")
	anim.AnimationId = WALK_ANIMATION
	local ok, track = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	if ok and track then
		track:Play()
		return track
	end
	return nil
end

local function clearModels()
	for _, m in spawnedModels do
		m:Destroy()
	end
	table.clear(spawnedModels)
end

-- Asks a player's screen to play a pose on their own character (it replicates to everyone).
function strikePose(character: Model, poseId: string?)
	if poseId and not Catalog.isNone(poseId) then
		character:SetAttribute("Pose", poseId .. "|" .. tostring(os.clock()))
	end
end

-- Everyone not on the runway sits in the audience seats along it.
local function seatAudience(except: Player?)
	local seats = {}
	for _, d in world.folder.Runway:GetChildren() do
		if d:IsA("Seat") and d.Name == "AudienceSeat" and not d.Occupant then
			table.insert(seats, d)
		end
	end
	for _, player in Players:GetPlayers() do
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if player ~= except and humanoid and not humanoid.SeatPart and #seats > 0 then
			local seat = table.remove(seats, 1)
			player.Character:PivotTo(seat.CFrame + Vector3.new(0, 3, 0))
			seat:Sit(humanoid)
		end
	end
end

local function unseat(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local seat = humanoid.SeatPart
		humanoid.Sit = false
		if seat then
			local weld = seat:FindFirstChild("SeatWeld")
			if weld then
				weld:Destroy()
			end
		end
	end
end

-- The player's own character walks the runway (their pet trots along), then strikes their pose.
-- If they have no character (just left), a stand-in model walks instead.
local function walkRunway(entry: Entry)
	local character = entry.player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (character and humanoid and root and root:IsA("BasePart")) then
		local model = buildClientModel(entry)
		model:SetAttribute("Walking", true)
		local r = placeModel(model, world.runwayStart, Vector3.new(0, 0, 1))
		local walk = playWalk(model)
		local walkTime = Config.SHOWCASE_SECONDS_PER_LOOK * 0.6
		local target = world.runwayEnd + Vector3.new(0, rootHeight(model), 0)
		model:SetAttribute("WalkFrom", r.Position)
		model:SetAttribute("WalkTo", target)
		model:SetAttribute("WalkStart", now())
		model:SetAttribute("WalkTime", walkTime)
		task.wait(walkTime)
		if walk then
			walk:Stop()
		end
		Avatar.pose(model, entry.look.pose)
		return
	end

	unseat(character)
	task.wait(0.1)
	local height = humanoid.HipHeight + root.Size.Y / 2
	local start = world.runwayStart + Vector3.new(0, height, 0)
	character:PivotTo(CFrame.lookAt(start, start + Vector3.new(0, 0, 1)))
	if entry.pet then
		entry.pet:PivotTo(CFrame.new(world.runwayStart + Vector3.new(2.6, 0, 0)))
	end
	character:SetAttribute("Walking", true) -- the runway camera follows them
	if hasPass(entry.player, "RunwayStar") then
		for _, emitter in world.confetti do
			emitter:Emit(80)
		end
		local sparkles = Instance.new("Sparkles")
		sparkles.Name = "RunwayStar"
		sparkles.Parent = root
		task.delay(Config.SHOWCASE_SECONDS_PER_LOOK, function()
			sparkles:Destroy()
		end)
	end

	-- A player's own device moves their character, so the walk and the pose are asked for with
	-- attributes, and their screen does them (see Main.client)
	local walkTime = Config.SHOWCASE_SECONDS_PER_LOOK * 0.6
	character:SetAttribute("RunwaySpeed", (world.runwayEnd - world.runwayStart).Magnitude / walkTime)
	character:SetAttribute("WalkTarget", world.runwayEnd)
	local started = os.clock()
	while os.clock() - started < walkTime + 1.5 and (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(world.runwayEnd.X, 0, world.runwayEnd.Z)).Magnitude > 1.5 do
		task.wait(0.1)
	end
	character:SetAttribute("WalkTarget", nil)
	strikePose(character, entry.look.pose)
	task.delay(Config.SHOWCASE_SECONDS_PER_LOOK - walkTime - 0.5, function()
		if character.Parent then
			character:SetAttribute("Walking", nil)
		end
	end)
end

-- Pets trot after their owners all round long.
local function followPets(dt: number)
	for _, entry in entries do
		local character = entry.player.Character
		if entry.pet and entry.pet.Parent and character then
			Pets.follow(entry.pet, character, dt)
		end
	end
end

-- After the show everyone gets their own look back.
local function restoreEveryone()
	for _, entry in entries do
		if entry.pet then
			entry.pet:Destroy()
			entry.pet = nil
		end
		if entry.player.Parent then
			task.spawn(function()
				pcall(function()
					entry.player:LoadCharacter()
				end)
			end)
		end
	end
end

------------------------------------------------------------------------------
-- Voting

local function onVote(player: Player, targetUserId: unknown, stars: unknown)
	if state.phase ~= "Showcase" or not showcase or showcase.userId ~= targetUserId then
		return
	end
	-- Votes are kind: only 3, 4 or 5 stars (this also rejects NaN, which would break scores and coins)
	if player.UserId == targetUserId or type(stars) ~= "number" or not (stars >= 3 and stars <= 5) or stars % 1 ~= 0 then
		return
	end
	local entry = entries[targetUserId :: number]
	if not entry then
		return
	end
	local firstVote = entry.votes[player.UserId] == nil
	entry.votes[player.UserId] = stars
	if firstVote then
		DataService.addCoins(player, Config.COINS_PER_VOTE)
	end
end

local function onReact(player: Player, emoji: unknown)
	if state.phase ~= "Showcase" and state.phase ~= "Results" then
		return
	end
	if type(emoji) ~= "string" or not REACTIONS[emoji] then
		return
	end
	local t = os.clock()
	if lastReaction[player] and t - lastReaction[player] < 0.35 then
		return
	end
	lastReaction[player] = t
	Remotes.Reaction:FireAllClients(emoji)
	-- the cheering player's avatar cheers in the audience too (at most every few seconds)
	if player.Character and (not lastCheer[player] or t - lastCheer[player] > 2.5) then
		lastCheer[player] = t
		strikePose(player.Character, "pose_cheer")
	end
end

------------------------------------------------------------------------------
-- Results

local function scoreAll()
	local rows = {}
	local count = 0
	for userId, entry in entries do
		if entry.player.Parent then
			count += 1
			local judgeStars, comments = Scoring.judge(entry, theme())
			local votes = {}
			for _, v in entry.votes do
				table.insert(votes, v)
			end
			local final = Scoring.final(judgeStars, votes)
			table.insert(rows, {
				userId = userId,
				stylist = entry.player.DisplayName,
				client = entry.client,
				look = entry.look,
				clean = entry.clean,
				judgeStars = judgeStars,
				voteCount = #votes,
				score = final,
				stars = Scoring.roundToHalf(final),
				comments = comments,
				coins = 0,
				spotless = entry.clean >= 0.98 and entry.rinsed,
			})
		end
	end
	table.sort(rows, function(a, b)
		return a.score > b.score
	end)

	-- Everyone gets a different award (best scorers pick first)
	local taken = {}
	for _, row in rows do
		local entry = entries[row.userId]
		local scores = Scoring.awardScores(entry, theme())
		local best, bestScore = nil, 0.2
		for _, award in Scoring.AWARDS do
			local score = scores[award.id] or 0
			if not taken[award.id] and score > bestScore then
				best, bestScore = award.id, score
			end
		end
		if best then
			taken[best] = true
		end
		row.award = Scoring.awardName(best or Scoring.FALLBACK_AWARD.id, theme())
	end

	for rank, row in rows do
		row.rank = rank
		local player = entries[row.userId].player
		local coins = Config.COINS_PARTICIPATION + math.floor(row.score * Config.COINS_PER_STAR)
		if row.spotless then
			coins += Config.COINS_SPOTLESS_BONUS
		end
		-- coins for each wish the client got
		for _, w in entries[row.userId].client.wishes do
			if Scoring.wishMet(w, entries[row.userId].look) then
				coins += Config.COINS_PER_WISH
			end
		end
		if count >= 2 and Config.COINS_PLACEMENT[rank] then
			coins += Config.COINS_PLACEMENT[rank]
		end
		if hasPass(player, "DoubleCoins") then
			coins *= 2
		end
		row.coins = coins
		DataService.addCoins(player, coins)

		local profile = DataService.get(player)
		if profile then
			local oldLevel = Progress.level(profile.stats.totalStars)
			profile.stats.shows += 1
			profile.stats.totalStars += row.stars
			profile.stats.bestStars = math.max(profile.stats.bestStars, row.stars)
			if rank == 1 and count >= 2 then
				profile.stats.wins += 1
			end
			local newLevel = Progress.level(profile.stats.totalStars)
			row.level = newLevel

			local entry = entries[row.userId]
			local client = entry.client

			-- Idle players (nothing changed) don't fill the Look Book or the weekly goal
			local default = Catalog.defaultLook()
			local touched = false
			for k, v in entry.look do
				if default[k] ~= v then
					touched = true
				end
			end

			-- Weekly goal: play a few shows this week for a prize
			local week = DataService.weekNumber()
			if profile.week ~= week then
				profile.week, profile.weekShows, profile.weekClaimed = week, 0, false
			end
			if touched then
				profile.weekShows += 1
			end
			if profile.weekShows >= Config.WEEKLY_GOAL_SHOWS and not profile.weekClaimed then
				profile.weekClaimed = true
				local prizeId = Catalog.WeeklyItems[profile.weeklyGiven + 1]
				local info = { kind = "weekly", coins = 0, item = nil :: string? }
				if prizeId then
					profile.weeklyGiven += 1
					profile.owned[prizeId] = true
					info.item = Catalog.byId[prizeId].name
				else
					info.coins = Config.WEEKLY_GOAL_COINS
					profile.coins += info.coins
				end
				task.delay(8, function()
					if player.Parent then
						Remotes.Celebrate:FireClient(player, info)
					end
				end)
			end

			-- Save the look in the Look Book (newest first)
			table.insert(profile.lookbook, if touched then 1 else #profile.lookbook + 1, {
				name = client.name,
				skin = client.skinIndex,
				eyes = client.eyesIndex,
				look = table.clone(entry.look),
				theme = state.themeId,
				stars = row.stars,
				award = row.award,
			})
			if not touched then
				table.remove(profile.lookbook) -- don't keep untouched looks
			end
			while #profile.lookbook > Config.LOOKBOOK_SIZE do
				table.remove(profile.lookbook)
			end
			profile.lookbookChanged = true
			if newLevel > oldLevel then
				task.delay(4, function()
					if player.Parent then
						Remotes.Celebrate:FireClient(player, { kind = "level", level = newLevel, title = Progress.title(newLevel) })
					end
				end)
			end
			DataService.push(player)
		end
	end
	return rows
end

-- Each player gets the results with only their OWN judge tips (the others' stay private).
function resultsFor(player: Player, all)
	local rows = {}
	for _, row in all.rows do
		local copy = table.clone(row)
		if row.userId ~= player.UserId then
			copy.comments = {}
		end
		table.insert(rows, copy)
	end
	return { themeId = all.themeId, rows = rows }
end

function sendResults()
	for _, player in Players:GetPlayers() do
		Remotes.Results:FireClient(player, resultsFor(player, results))
	end
end

------------------------------------------------------------------------------
-- Main loop

local function runRound()
	-- Intermission: everyone back in their own look
	results = nil
	showcase = nil
	restoreEveryone()
	table.clear(entries)
	while #Players:GetPlayers() < Config.MIN_PLAYERS do
		setState("Waiting", 0)
		task.wait(2)
	end
	-- A new day may have started for players who stayed in the game
	for _, player in Players:GetPlayers() do
		DataService.checkDaily(player)
	end

	-- Holiday events: switch decorations, and use the holiday theme about half the time
	local event = Events.current(now())
	local eventId = event and event.id or nil
	if eventId ~= state.eventId or not decorated then
		state.eventId = eventId
		decorated = true
		WorldBuilder.setDecor(eventId)
	end
	if event and rng:NextNumber() < Config.EVENT_THEME_CHANCE then
		state.themeId = event.theme
	else
		local everyday = {}
		for _, t in Catalog.Themes do
			if not t.event then
				table.insert(everyday, t.id)
			end
		end
		state.themeId = everyday[rng:NextInteger(1, #everyday)]
	end
	setState("Intermission", Config.INTERMISSION_SECONDS)
	task.wait(Config.INTERMISSION_SECONDS)

	-- Makeover: 5 minutes!
	setState("Makeover", Config.MAKEOVER_SECONDS)
	-- getting each avatar ready takes a moment, so everyone is set up side by side
	for _, player in Players:GetPlayers() do
		task.spawn(assignClient, player)
	end
	while now() < state.endsAt do
		task.wait(0.5)
		if allDone() then
			break
		end
	end

	-- Fashion show
	local order = {}
	for _, entry in entries do
		table.insert(order, entry)
	end
	rng:Shuffle(order)
	local index = 0
	for _, entry in order do
		if entry.player.Parent then
			index += 1
			local total = 0
			for _, e in order do
				if e.player.Parent then
					total += 1
				end
			end
			showcase = {
				userId = entry.player.UserId,
				stylist = entry.player.DisplayName,
				vip = hasPass(entry.player, "VIP"),
				level = Progress.level((DataService.get(entry.player) or { stats = { totalStars = 0 } }).stats.totalStars),
				client = entry.client,
				look = entry.look,
				clean = 1, -- shown tidy on the big screen
				index = index,
				total = math.max(total, index),
			}
			setState("Showcase", Config.SHOWCASE_SECONDS_PER_LOOK)
			Remotes.Showcase:FireAllClients(showcase)
			seatAudience(entry.player)
			local started = os.clock()
			walkRunway(entry)
			task.wait(math.max(0, Config.SHOWCASE_SECONDS_PER_LOOK - (os.clock() - started)))
			clearModels()
		end
	end
	showcase = nil

	-- Results
	local rows = scoreAll()
	if #rows > 0 then
		results = { themeId = state.themeId, rows = rows }
		sendResults()
		setState("Results", Config.RESULTS_SECONDS)
		-- The top 3 stand on the podium in their looks; everyone else gathers in front
		for _, row in rows do
			local entry = entries[row.userId]
			local character = entry and entry.player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if character and humanoid and root and root:IsA("BasePart") then
				unseat(character)
				local spot = world.podium[row.rank] or (world.podium[1] + Vector3.new((row.rank - 5) * 3, -world.podium[1].Y, 9))
				local pos = spot + Vector3.new(0, humanoid.HipHeight + root.Size.Y / 2 + 0.1, 0)
				character:PivotTo(CFrame.lookAt(pos, pos + Vector3.new(0, 0, 1)))
				if row.rank == 1 then
					strikePose(character, "pose_cheer")
				end
			elseif entry and row.rank <= 3 then
				local model = buildClientModel(entry)
				placeModel(model, world.podium[row.rank], Vector3.new(0, 0, 1))
				Avatar.idle(model)
			end
		end
		task.wait(Config.RESULTS_SECONDS)
		clearModels()
	end
end

-- Everything a player needs when they join or their screen restarts.
function RoundService.snapshot(player: Player)
	local entry = entries[player.UserId]
	return {
		state = state,
		entry = if entry and state.phase == "Makeover" then entryPayload(entry) else nil,
		showcase = if state.phase == "Showcase" then showcase else nil,
		results = if state.phase == "Results" and results then resultsFor(player, results) else nil,
	}
end

function RoundService.init(builtWorld: WorldBuilder.World)
	world = builtWorld

	Remotes.UpdateLook.OnServerEvent:Connect(onUpdateLook)
	Remotes.WashProgress.OnServerEvent:Connect(onWashProgress)
	Remotes.Done.OnServerEvent:Connect(onDone)
	Remotes.Vote.OnServerEvent:Connect(onVote)
	Remotes.React.OnServerEvent:Connect(onReact)

	-- Late joiners still get a client if a makeover is running
	Players.PlayerAdded:Connect(function(player)
		if state.phase == "Makeover" and not entries[player.UserId] then
			DataService.waitFor(player)
			if state.phase == "Makeover" and player.Parent then
				assignClient(player)
			end
		end
	end)
	-- Respawning in the middle of a round puts the look straight back on
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			local entry = entries[player.UserId]
			if entry and (state.phase == "Makeover" or state.phase == "Showcase") then
				task.wait(0.5)
				prepareCharacter(entry)
			end
		end)
	end)
	RunService.Heartbeat:Connect(followPets)
	Players.PlayerRemoving:Connect(function(player)
		local entry = entries[player.UserId]
		if entry and entry.pet then
			entry.pet:Destroy()
		end
		entries[player.UserId] = nil
		lastReaction[player] = nil
		lastCheer[player] = nil
	end)

	task.spawn(function()
		while true do
			local ok, err = pcall(runRound)
			if not ok then
				warn("[GlowUp] Round error:", err)
				clearModels()
				task.wait(3)
			end
		end
	end)
end

return RoundService
