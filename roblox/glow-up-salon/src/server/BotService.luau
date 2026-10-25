-- Style Bots: pretend friends for when you play alone (or with just one friend). They're clearly
-- robots (🤖 on their name tags, never passed off as real players). Between rounds they dance on
-- the dance floor; during the makeover they walk from station to station and put their look
-- together piece by piece; then they sit in the audience, walk the runway, strike a pose, and vote
-- (kindly) on real players' looks. They always place below the real kids. Turn them on or off from the lobby card.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Avatar = require(ReplicatedStorage.Shared.Avatar)
local Catalog = require(ReplicatedStorage.Shared.Catalog)
local Clients = require(ReplicatedStorage.Shared.Clients)
local Config = require(ReplicatedStorage.Shared.Config)
local Pets = require(ReplicatedStorage.Shared.Pets)
local Stations = require(ReplicatedStorage.Shared.Stations)

local BotService = {}

export type Bot = {
	bot: true,
	userId: number, -- negative, so it never matches a real player
	name: string,
	client: Clients.Client,
	look: { [string]: string },
	clean: number,
	rinsed: boolean,
	votes: { [number]: number },
	model: Model?,
	pet: Model?,
	skill: number, -- 0..1: how closely they follow the theme (so real players can win too)
	walkTrack: AnimationTrack?,
	danceTrack: AnimationTrack?,
	busy: boolean, -- walking the runway or on the podium (the wander loop leaves them alone)
}

local NAMES = { "Kiki", "Zara", "Jojo", "Amani", "Coco", "Nala", "Rosie", "Imani", "Bibi", "Lulu" }
local WALK_ANIMATION = "rbxassetid://507777826"
local rng = Random.new()
local bots: { Bot } = {}
local world = nil
local themeOf: () -> Catalog.Theme = nil :: any

-- The keys a bot styles at each station, in the order they visit them.
local STATION_KEYS = {
	Hair = { "hairStyle", "hairColor" },
	Face = { "eyeshadow", "lashes", "blush", "lipstick", "gems" },
	Outfit = { "outfit", "outfitColor", "outfitPattern" },
	Costume = { "accessory", "costumeBack", "costumeFace", "costumeWaist", "costumeShoulder" },
	Pet = { "pet" },
	Show = { "pose", "effect" },
}
-- How likely a bot is to bother with a key at all (so not every bot wears everything)
local KEY_CHANCE = {
	gems = 0.35, lashes = 0.6, outfitColor = 0.35, outfitPattern = 0.35,
	costumeBack = 0.6, costumeFace = 0.35, costumeWaist = 0.3, costumeShoulder = 0.35, accessory = 0.55,
	pet = 0.6, effect = 0.6,
}

-- A free (no coins, no pass, no level) item for this key, picking theme matches by skill.
local function pickItem(key: string, theme: Catalog.Theme, skill: number): string?
	local category = Catalog.categoryByKey[key]
	if not category then
		return nil
	end
	local matches, others = {}, {}
	for _, it in category.items do
		local free = not it.hidden and not it.gift and not it.pass and not it.level and it.price <= 0 and not it.event
		if free and not Catalog.isNone(it.id) then
			if Catalog.matchesTheme(it, theme) then
				table.insert(matches, it.id)
			else
				table.insert(others, it.id)
			end
		end
	end
	local pool = if #matches > 0 and rng:NextNumber() < skill then matches else others
	if #pool == 0 then
		pool = matches
	end
	return if #pool > 0 then pool[rng:NextInteger(1, #pool)] else nil
end

local function dress(bot: Bot)
	if bot.model and bot.model.Parent then
		Avatar.dress(bot.model, bot.client, bot.look, { clean = 1, mood = "smile", brushed = true })
	end
	-- the pet trots after them
	local petId = bot.look.pet
	if not bot.pet or bot.pet:GetAttribute("PetId") ~= petId then
		if bot.pet then
			bot.pet:Destroy()
			bot.pet = nil
		end
		local pet = Pets.build(petId)
		if pet and bot.model then
			pet:SetAttribute("PetId", petId)
			pet.Name = bot.name .. "'s Pet"
			pet:PivotTo(bot.model:GetPivot() * CFrame.new(2.6, -3, 0.6))
			pet.Parent = world.folder
			bot.pet = pet
		end
	end
end

local function nameTag(model: Model, text: string)
	local head = model:FindFirstChild("Head")
	if not (head and head:IsA("BasePart")) then
		return
	end
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
	label.Text = text
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(106, 63, 181)
	label.TextStrokeColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Parent = tag
	tag.Parent = head
end

local function newBot(index: number): Bot?
	-- skin tones lean deep (most Style Bots are Black girls, like the players this was made for)
	local skinIndex = rng:NextInteger(if rng:NextNumber() < 0.75 then 5 else 1, #Catalog.SkinTones)
	local name = NAMES[(index - 1) % #NAMES + 1]
	-- the robot rides along in the name, so the runway card, results and podium all show it's a bot
	local client = Clients.forPlayer(name .. " 🤖", skinIndex)
	local model = Avatar.new(client)
	if not model then
		return nil
	end
	local bot: Bot = {
		bot = true,
		userId = -index,
		name = name,
		client = client,
		look = Catalog.defaultLook(),
		clean = 1,
		rinsed = true,
		votes = {},
		model = model,
		pet = nil,
		skill = rng:NextNumber(0.45, 0.85),
		walkTrack = nil,
		danceTrack = nil,
		busy = false,
	}
	model.Name = name .. " (Style Bot)"
	-- start with their own hair, so they don't all look alike between rounds
	bot.look.hairStyle = pickItem("hairStyle", themeOf(), 0) or bot.look.hairStyle
	bot.look.hairColor = pickItem("hairColor", themeOf(), 0.3) or bot.look.hairColor
	local spot = Stations.byTab.Show.pad + Vector3.new(rng:NextNumber(-20, -10), 0, rng:NextNumber(-12, -6))
	Avatar.place(model, spot, Vector3.new(0, 0, -1))
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
	root.Anchored = false
	model.Parent = world.folder
	pcall(function()
		root:SetNetworkOwner(nil)
	end)
	nameTag(model, name .. " 🤖")
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	humanoid.WalkSpeed = 10
	-- walk animation while moving, idle while standing
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		-- the same catwalk strut the players have (or the plain walk until it has loaded)
		local loadedId: string? = nil
		local function walkTrack(): AnimationTrack?
			local assets = Avatar.assets(0)
			local strut = assets and assets:GetAttribute("CatwalkWalk")
			local id = if type(strut) == "string" then strut else WALK_ANIMATION
			if id ~= loadedId then
				local anim = Instance.new("Animation")
				anim.AnimationId = id
				local ok, track = pcall(function()
					return animator:LoadAnimation(anim)
				end)
				if ok and track then
					if bot.walkTrack then
						bot.walkTrack:Stop(0)
					end
					bot.walkTrack = track
					loadedId = id
				end
			end
			return bot.walkTrack
		end
		walkTrack()
		humanoid.Running:Connect(function(speed)
			local track = walkTrack()
			if not track then
				return
			end
			if speed > 0.5 and not track.IsPlaying then
				track:Play(0.2)
			elseif speed <= 0.5 and track.IsPlaying then
				track:Stop(0.2)
			end
		end)
	end
	Avatar.idle(model)
	dress(bot)
	return bot
end

local function walkTo(bot: Bot, target: Vector3, timeout: number)
	local model = bot.model
	local humanoid = model and model:FindFirstChildOfClass("Humanoid")
	local root = model and model:FindFirstChild("HumanoidRootPart")
	if not (humanoid and root and root:IsA("BasePart")) then
		return
	end
	if humanoid.SeatPart or humanoid:GetState() == Enum.HumanoidStateType.Seated then
		Avatar.unseat(model)
		task.wait(0.1)
	end
	humanoid:MoveTo(target)
	local started = os.clock()
	while os.clock() - started < timeout and model.Parent do
		local here = Vector3.new(root.Position.X, 0, root.Position.Z)
		if (here - Vector3.new(target.X, 0, target.Z)).Magnitude < 2 then
			break
		end
		task.wait(0.2)
	end
end

------------------------------------------------------------------------------

function BotService.init(builtWorld, theme: () -> Catalog.Theme)
	world = builtWorld
	themeOf = theme
end

-- Makes sure there are `count` Style Bots (adds or removes some).
function BotService.ensure(count: number)
	while #bots > count do
		BotService.remove(bots[#bots])
	end
	local index = 1
	while #bots < count and index <= 20 do
		local used = false
		for _, b in bots do
			if b.userId == -index then
				used = true
			end
		end
		if not used then
			local bot = newBot(index)
			if not bot then
				break
			end
			table.insert(bots, bot)
		end
		index += 1
	end
end

function BotService.remove(bot: Bot)
	local i = table.find(bots, bot)
	if i then
		table.remove(bots, i)
	end
	if bot.pet then
		bot.pet:Destroy()
	end
	if bot.model then
		bot.model:Destroy()
	end
end

function BotService.list(): { Bot }
	return bots
end

function BotService.byUserId(userId: number): Bot?
	for _, b in bots do
		if b.userId == userId then
			return b
		end
	end
	return nil
end

-- Between rounds: everyone off to the dance floor.
function BotService.hangOut()
	local floor = world.folder:FindFirstChild("DanceFloor", true)
	local center = floor and floor:GetAttribute("Center")
	for i, bot in bots do
		bot.busy = false
		bot.votes = {}
		task.spawn(function()
			if typeof(center) == "Vector3" then
				local a = i / math.max(#bots, 1) * math.pi * 2
				walkTo(bot, center + Vector3.new(math.cos(a) * 3, 0, math.sin(a) * 3), 8)
				if bot.model then
					local track = Avatar.pose(bot.model, if i % 2 == 0 then "pose_dance2" else "pose_dance")
					if track then
						track.Looped = true
						bot.danceTrack = track
					end
				end
			end
		end)
	end
end

-- Is a real player standing on this station's pad?
local function playerOn(station: Stations.Station): boolean
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local d = Vector3.new(root.Position.X - station.pad.X, 0, root.Position.Z - station.pad.Z)
			if d.Magnitude <= Stations.PAD_RADIUS + 1 then
				return true
			end
		end
	end
	return false
end

-- The makeover: each bot starts fresh, then walks station to station building the look.
function BotService.startMakeover(endsIn: number)
	local theme = themeOf()
	for _, bot in bots do
		if bot.danceTrack then
			bot.danceTrack:Stop(0.3)
			bot.danceTrack = nil
		end
		bot.look = Catalog.defaultLook()
		bot.look.hairStyle = pickItem("hairStyle", theme, 0) or bot.look.hairStyle
		bot.votes = {}
		bot.busy = false
		dress(bot)
		task.spawn(function()
			local order = { "Hair", "Face", "Outfit", "Costume", "Pet", "Show" }
			-- not everyone goes in the same order
			if rng:NextNumber() < 0.5 then
				order = { "Outfit", "Hair", "Costume", "Face", "Show", "Pet" }
			end
			local perStation = math.max(4, (endsIn - 20) / #order)
			for _, tab in order do
				if not bot.model or not bot.model.Parent or bot.busy then
					return
				end
				local station = Stations.byTab[tab]
				local offset = Vector3.new(rng:NextNumber(-2, 2), 0, rng:NextNumber(-2, 2))
				-- a real kid is styling here: wait a bit, then style from beside the pad instead
				local waited = 0
				while playerOn(station) and waited < 8 do
					task.wait(1)
					waited += 1
				end
				if playerOn(station) then
					offset = Vector3.new(if rng:NextNumber() < 0.5 then -6 else 6, 0, 2)
				end
				walkTo(bot, station.pad + offset, 12)
				task.wait(rng:NextNumber(1.5, 3))
				for _, key in STATION_KEYS[tab] do
					if rng:NextNumber() < (KEY_CHANCE[key] or 1) then
						local id = pickItem(key, theme, bot.skill)
						if id then
							bot.look[key] = id
							dress(bot)
							task.wait(rng:NextNumber(0.6, 1.4))
						end
					end
				end
				if bot.model and not Catalog.isNone(bot.look.pose) and tab == "Show" then
					Avatar.pose(bot.model, bot.look.pose)
				end
				task.wait(math.max(0, perStation - 6))
			end
		end)
	end
end

-- The bot walks the runway, strikes a pose, and then waits at the end.
function BotService.walkRunway(bot: Bot)
	local model = bot.model
	if not model then
		return
	end
	bot.busy = true
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
	Avatar.unseat(model)
	task.wait(0.1)
	Avatar.place(model, world.runwayStart, Vector3.new(0, 0, 1))
	if bot.pet then
		bot.pet:PivotTo(CFrame.new(world.runwayStart + Vector3.new(2.6, 0, 0)))
	end
	model:SetAttribute("Walking", true) -- the runway camera follows them
	local walkTime = Config.SHOWCASE_SECONDS_PER_LOOK * 0.6
	humanoid.WalkSpeed = (world.runwayEnd - world.runwayStart).Magnitude / walkTime
	walkTo(bot, world.runwayEnd, walkTime + 1.5)
	humanoid.WalkSpeed = 10
	if root.Parent then
		BotService.twirl(root)
		Avatar.pose(model, if Catalog.isNone(bot.look.pose) then "pose_wave" else bot.look.pose)
	end
	task.delay(Config.SHOWCASE_SECONDS_PER_LOOK - walkTime - 0.5, function()
		if model.Parent then
			model:SetAttribute("Walking", nil)
		end
	end)
end

-- A twirl at the end of the runway (one full turn, ending face to the crowd).
function BotService.twirl(root: BasePart)
	local pos = root.Position
	for i = 1, 16 do
		root.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.pi + i / 16 * math.pi * 2, 0)
		task.wait(0.05)
	end
	root.CFrame = CFrame.lookAt(pos, pos + Vector3.new(0, 0, 1))
end

-- Bots are kind judges: every real look gets 4 or 5 hearts from them.
function BotService.voteFor(entry)
	for _, bot in bots do
		task.delay(rng:NextNumber(1.5, 5), function()
			if entry.votes then
				entry.votes[bot.userId] = if rng:NextNumber() < 0.6 then 5 else 4
			end
		end)
	end
end

-- Pets trot after their bots (called every frame with the others).
function BotService.followPets(dt: number)
	for _, bot in bots do
		if bot.pet and bot.pet.Parent and bot.model then
			Pets.follow(bot.pet, bot.model, dt)
		end
	end
end

return BotService
