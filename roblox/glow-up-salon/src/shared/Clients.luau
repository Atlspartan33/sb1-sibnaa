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
	dirt: { DirtSpot },
}

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

-- Face area (matches LookRenderer's face oval) so dirt lands on the face.
local FACE_MIN_X, FACE_MAX_X = 0.31, 0.69
local FACE_MIN_Y, FACE_MAX_Y = 0.24, 0.7

function Clients.generate(rng: Random?): Client
	local r = rng or Random.new()
	local story = STORIES[r:NextInteger(1, #STORIES)]

	local dirt = {}
	for _ = 1, r:NextInteger(9, 13) do
		table.insert(dirt, {
			x = r:NextNumber(FACE_MIN_X, FACE_MAX_X),
			y = r:NextNumber(FACE_MIN_Y, FACE_MAX_Y),
			size = r:NextNumber(0.05, 0.11),
			color = story.colors[r:NextInteger(1, #story.colors)],
		})
	end

	return {
		name = NAMES[r:NextInteger(1, #NAMES)],
		story = story.text,
		skin = SKIN_TONES[r:NextInteger(1, #SKIN_TONES)],
		eyes = EYE_COLORS[r:NextInteger(1, #EYE_COLORS)],
		dirt = dirt,
	}
end

return Clients
