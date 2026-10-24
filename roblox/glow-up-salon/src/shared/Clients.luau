-- Makes the customers who walk into the salon: who they are, where they've been,
-- and how dirty their face is.

local Clients = {}

export type DirtSpot = {
	x: number, -- 0..1 across the portrait
	y: number, -- 0..1 down the portrait
	size: number, -- 0..1 of the portrait width
	color: Color3,
}

export type Client = {
	name: string,
	story: string,
	skin: Color3,
	eyes: Color3,
	skinIndex: number,
	eyesIndex: number,
	visits: number, -- how many times this stylist has styled them (1 = first time)
	wishes: { Wish },
	dirt: { DirtSpot },
}

-- Something the client asks for ("💗 hair!"). Each one can be done with free items.
export type Wish = { key: string, tag: string, text: string }

local WISHES = {
	{ key = "hairColor", tag = "pink", text = "💗 hair" },
	{ key = "hairColor", tag = "blue", text = "💙 hair" },
	{ key = "hairColor", tag = "gold", text = "💛 hair" },
	{ key = "eyeshadow", tag = "purple", text = "💜 eyes" },
	{ key = "eyeshadow", tag = "blue", text = "💙 eyes" },
	{ key = "lipstick", tag = "red", text = "❤️ lips" },
	{ key = "lipstick", tag = "pink", text = "💗 lips" },
	{ key = "nailColor", tag = "any", text = "💅 nails" },
	{ key = "nailColor", tag = "pink", text = "💗 nails" },
	{ key = "outfit", tag = "dress", text = "👗 a dress" },
	{ key = "accessory", tag = "any", text = "🎀 a hair clip" },
	{ key = "gems", tag = "any", text = "⭐ stickers" },
	{ key = "outfitPattern", tag = "any", text = "🔵 a pattern" },
}

local function pickWishes(r: Random): { Wish }
	local first = WISHES[r:NextInteger(1, #WISHES)]
	local second = first
	while second.key == first.key do
		second = WISHES[r:NextInteger(1, #WISHES)]
	end
	return { first, second }
end

-- What a stylist remembers about a regular client (saved, so no Color3s)
export type Friend = { visits: number, skin: number, eyes: number }

local rgb = Color3.fromRGB

local NAMES = {
	"Jasmine", "Mia", "Zoe", "Aaliyah", "Sofia", "Kayla", "Nia", "Lily", "Maya", "Chloe",
	"Ava", "Destiny", "Riley", "Jordan", "Grace", "Imani", "Bella", "Harper", "Luna", "Ruby",
	"Kai", "Leo", "Amara", "Skye", "Isla", "Nova", "Ellie", "Jada", "Rosa", "Mila",
}

local SKIN_TONES = {
	rgb(255, 224, 196),
	rgb(250, 205, 175),
	rgb(241, 194, 160),
	rgb(224, 172, 128),
	rgb(198, 134, 94),
	rgb(161, 102, 66),
	rgb(124, 78, 50),
	rgb(92, 57, 38),
}

local EYE_COLORS = {
	rgb(101, 67, 33),
	rgb(60, 40, 25),
	rgb(142, 118, 40),
	rgb(60, 140, 80),
	rgb(70, 130, 200),
	rgb(115, 125, 140),
}

-- Where the client is coming from, and what's all over their face.
local STORIES = {
	{ text = "I fixed cars at the auto shop all day. I'm SO greasy! 😫", colors = { rgb(55, 55, 58), rgb(35, 32, 30) } },
	{ text = "I fixed bikes at the bike shop. Oil got everywhere! 🚲", colors = { rgb(45, 40, 35), rgb(80, 70, 55) } },
	{ text = "We had a frosting fight at the bakery shop! 🧁", colors = { rgb(255, 180, 210), rgb(90, 50, 30), rgb(255, 250, 240) } },
	{ text = "I cleaned the chimney at the hardware shop. Soot! 🧹", colors = { rgb(35, 35, 38), rgb(70, 70, 75) } },
	{ text = "Oops! I spilled paint at the paint shop! 🎨", colors = { rgb(235, 80, 80), rgb(80, 140, 235), rgb(250, 205, 60) } },
	{ text = "I fell in the mud at the garden shop! 🌻", colors = { rgb(110, 75, 40), rgb(90, 140, 60) } },
	{ text = "The blender exploded at the smoothie shop! 🍓", colors = { rgb(200, 60, 120), rgb(120, 200, 80), rgb(255, 170, 60) } },
	{ text = "I made pizza at the pizza shop. Sauce everywhere! 🍕", colors = { rgb(200, 50, 40), rgb(250, 210, 90) } },
	{ text = "Slime exploded at the toy shop! So sticky! 🟢", colors = { rgb(120, 220, 90), rgb(90, 200, 160), rgb(200, 120, 255) } },
}

-- Extra stories during holiday events (about half the clients use one).
local EVENT_STORIES = {
	halloween = {
		{ text = "I carved pumpkins at the pumpkin shop. Pumpkin goo! 🎃", colors = { rgb(245, 130, 30), rgb(250, 190, 70) } },
		{ text = "I tried ALL the face paint at the costume shop! 🧛", colors = { rgb(120, 220, 90), rgb(150, 80, 220), rgb(30, 30, 30) } },
		{ text = "I made caramel apples at the candy shop! 🍎", colors = { rgb(170, 100, 40), rgb(210, 40, 40) } },
	},
	thanksgiving = {
		{ text = "I baked pies at the pie shop. Flour everywhere! 🥧", colors = { rgb(250, 245, 235), rgb(220, 140, 60) } },
		{ text = "I jumped in a leaf pile at the garden shop! 🍂", colors = { rgb(200, 90, 30), rgb(150, 90, 40), rgb(230, 170, 50) } },
		{ text = "I made cranberry sauce at the diner! 🍒", colors = { rgb(170, 20, 50), rgb(210, 60, 80) } },
	},
	christmas = {
		{ text = "I baked gingerbread at the cookie shop! 🍪", colors = { rgb(170, 100, 50), rgb(255, 255, 255) } },
		{ text = "I wrapped presents at the toy shop. Glitter everywhere! 🎁", colors = { rgb(240, 200, 60), rgb(200, 210, 230), rgb(230, 50, 60) } },
		{ text = "I made hot cocoa at the cafe. Chocolate mustache! ☕", colors = { rgb(90, 50, 30), rgb(255, 250, 245) } },
	},
}

-- Face area (matches LookRenderer's face oval) so dirt lands on the face.
local FACE_MIN_X, FACE_MAX_X = 0.31, 0.69
local FACE_MIN_Y, FACE_MAX_Y = 0.24, 0.7

function Clients.generate(rng: Random?, eventId: string?, avoidNames: { [string]: any }?): Client
	local r = rng or Random.new()
	local story = STORIES[r:NextInteger(1, #STORIES)]
	local special = eventId and EVENT_STORIES[eventId]
	if special and r:NextNumber() < 0.5 then
		story = special[r:NextInteger(1, #special)]
	end

	local dirt = {}
	for _ = 1, r:NextInteger(9, 13) do
		table.insert(dirt, {
			x = r:NextNumber(FACE_MIN_X, FACE_MAX_X),
			y = r:NextNumber(FACE_MIN_Y, FACE_MAX_Y),
			size = r:NextNumber(0.05, 0.11),
			color = story.colors[r:NextInteger(1, #story.colors)],
		})
	end

	local skinIndex = r:NextInteger(1, #SKIN_TONES)
	local eyesIndex = r:NextInteger(1, #EYE_COLORS)
	return {
		name = (function()
			local name = NAMES[r:NextInteger(1, #NAMES)]
			for _ = 1, 20 do
				if not (avoidNames and avoidNames[name]) then
					break
				end
				name = NAMES[r:NextInteger(1, #NAMES)]
			end
			return name
		end)(),
		story = story.text,
		skin = SKIN_TONES[skinIndex],
		eyes = EYE_COLORS[eyesIndex],
		skinIndex = skinIndex,
		eyesIndex = eyesIndex,
		visits = 1,
		wishes = pickWishes(r),
		dirt = dirt,
	}
end

-- A regular coming back: same name and face, new mess.
function Clients.returning(name: string, friend: Friend, rng: Random?, eventId: string?): Client
	local client = Clients.generate(rng, eventId)
	client.name = name
	client.skinIndex = math.clamp(friend.skin, 1, #SKIN_TONES)
	client.eyesIndex = math.clamp(friend.eyes, 1, #EYE_COLORS)
	client.skin = SKIN_TONES[client.skinIndex]
	client.eyes = EYE_COLORS[client.eyesIndex]
	client.visits = friend.visits + 1
	return client
end

-- Rebuilds a client's face colors from saved indices (for the Look Book).
function Clients.colors(skinIndex: number, eyesIndex: number): (Color3, Color3)
	return SKIN_TONES[math.clamp(skinIndex, 1, #SKIN_TONES)], EYE_COLORS[math.clamp(eyesIndex, 1, #EYE_COLORS)]
end

return Clients
