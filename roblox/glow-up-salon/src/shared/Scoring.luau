-- The judges! Gives a look 1-5 stars, says what they liked (or what to fix next time),
-- and finds an award for every look.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.Catalog)

local Scoring = {}

export type Wish = { key: string, tag: string, text: string }

export type Entry = {
	look: { [string]: string },
	clean: number,
	rinsed: boolean,
	client: any, -- the client (for their wishes)
}

local MAKEUP_KEYS = { "eyeshadow", "lashes", "blush", "lipstick" }
-- Things that can match the theme. 4 matches = full theme points.
local THEME_SLOTS = {
	"hairStyle", "hairColor", "eyeshadow", "blush", "lipstick", "outfit", "accessory", "gems",
	"costumeBack", "costumeFace", "costumeWaist", "costumeShoulder", "pet", "pose", "effect",
}
-- The fun stuff that makes a runway walk a show
local SHOW_KEYS = { "costumeBack", "costumeFace", "costumeWaist", "costumeShoulder", "pet", "pose", "effect" }
local THEME_MATCHES_NEEDED = 4

function Scoring.roundToHalf(stars: number): number
	return math.clamp(math.floor(stars * 2 + 0.5) / 2, 1, 5)
end

-- "Pink Party 🎀" -> "Pink Party"
function Scoring.themeWord(theme: Catalog.Theme): string
	return (string.gsub(theme.name, "%s*[^%w%s']+$", ""))
end

local function slotMatches(look, key: string, theme: Catalog.Theme): boolean
	if key == "outfit" then
		if Catalog.isNone(look.outfit) then
			return false -- work overalls never match, even recolored
		end
		-- a 🎨 custom color counts for the outfit too
		return Catalog.matchesTheme(Catalog.byId[look.outfit], theme) or Catalog.matchesTheme(Catalog.byId[look.outfitColor or ""], theme)
	end
	return Catalog.matchesTheme(Catalog.byId[look[key] or ""], theme)
end

-- How many parts of the look match the theme.
function Scoring.themeMatches(look, theme: Catalog.Theme): number
	local n = 0
	for _, key in THEME_SLOTS do
		if slotMatches(look, key, theme) then
			n += 1
		end
	end
	return n
end

function Scoring.wishMet(wish: Wish, look): boolean
	local it = Catalog.byId[look[wish.key] or ""]
	if not it or Catalog.isNone(it.id) then
		return false
	end
	if wish.tag == "any" then
		return true
	elseif wish.tag == "dress" then
		return it.dress == true
	end
	return Catalog.hasTag(it, wish.tag)
end

local function wishesMet(entry: Entry): (number, number)
	local wishes = entry.client and entry.client.wishes or {}
	local met = 0
	for _, w in wishes do
		if Scoring.wishMet(w, entry.look) then
			met += 1
		end
	end
	return met, #wishes
end

-- Returns stars (1..5, in half steps) and a list of judge comments.
function Scoring.judge(entry: Entry, theme: Catalog.Theme): (number, { string })
	local look = entry.look
	local points = 0
	local comments = {}

	-- The show (1 point): costume pieces, a pet, a pose, an effect
	local show = 0
	for _, key in SHOW_KEYS do
		if not Catalog.isNone(look[key]) then
			show += 1
		end
	end
	points += math.min(show, 4) / 4
	if show == 0 then
		table.insert(comments, "Add a costume, a pet or a pose to WOW the crowd! 🐶💃")
	elseif show >= 4 then
		table.insert(comments, "What a show! 🔥")
	end

	-- Hair, makeup, outfit (1.75 points for doing each part)
	if Catalog.isNone(look.hairStyle) then
		table.insert(comments, "Pick a hairstyle! 💇")
	else
		points += 0.5
	end
	local applied = 0
	for _, key in MAKEUP_KEYS do
		if not Catalog.isNone(look[key]) then
			applied += 1
		end
	end
	points += 0.75 * applied / #MAKEUP_KEYS
	if applied == 0 then
		table.insert(comments, "Don't forget the makeup! 💄")
	end
	if Catalog.isNone(look.outfit) then
		table.insert(comments, "Pick an outfit! 👗")
	else
		points += 0.5
	end

	-- Matching the theme (2.25 points): the more ⭐ items, the better
	local matches = Scoring.themeMatches(look, theme)
	points += 2.25 * math.min(matches, THEME_MATCHES_NEEDED) / THEME_MATCHES_NEEDED
	local word = Scoring.themeWord(theme)
	if matches >= THEME_MATCHES_NEEDED then
		table.insert(comments, "That's SO " .. word .. "! ⭐")
	elseif matches >= 2 then
		table.insert(comments, "Pretty! Pick more ⭐ " .. word .. " things!")
	else
		table.insert(comments, "Look for the ⭐ items to match " .. word .. "!")
	end

	-- The client's wishes (bonus)
	local met, total = wishesMet(entry)
	points += 0.25 * met
	if total > 0 and met == total then
		table.insert(comments, "You made their wishes come true! 💌")
	end

	-- Little extras (bonus)
	if not Catalog.isNone(look.gems) then
		points += 0.1
	end
	if not Catalog.isNone(look.accessory) then
		points += 0.1
	end

	local stars = Scoring.roundToHalf(points)
	if stars >= 4.5 then
		table.insert(comments, 1, "ABSOLUTELY STUNNING! 😍")
	elseif stars >= 3.5 then
		table.insert(comments, 1, "Looking great!")
	end
	return stars, comments
end

-- How the client feels about their look (used to draw their mouth).
function Scoring.mood(stars: number, clean: number): string
	if clean < 0.5 then
		return "sad"
	elseif stars < 2.5 then
		return "neutral"
	elseif stars < 4 then
		return "smile"
	end
	return "grin"
end

-- Mixes the judges' stars with the other players' votes (half and half).
function Scoring.final(judgeStars: number, votes: { number }): number
	if #votes == 0 then
		return judgeStars
	end
	local total = 0
	for _, v in votes do
		total += v
	end
	return (judgeStars + total / #votes) / 2
end

------------------------------------------------------------------------------
-- Awards: every look gets one, so every kid wins something

Scoring.AWARDS = {
	{ id = "theme", emoji = "⭐" }, -- named "Most <theme>"
	{ id = "costume", name = "Best Costume", emoji = "🎭" },
	{ id = "pet", name = "Best Buddy", emoji = "🐶" },
	{ id = "show", name = "Showstopper", emoji = "🔥" },
	{ id = "hair", name = "Best Hair", emoji = "💇" },
	{ id = "makeup", name = "Makeup Star", emoji = "💄" },
	{ id = "sparkle", name = "Sparkliest", emoji = "✨" },
	{ id = "colorful", name = "Most Colorful", emoji = "🌈" },
	{ id = "extras", name = "Cutest Extras", emoji = "🎀" },
}
Scoring.FALLBACK_AWARD = { id = "star", name = "Super Stylist", emoji = "💖" }

function Scoring.awardName(awardId: string, theme: Catalog.Theme): string
	for _, a in Scoring.AWARDS do
		if a.id == awardId then
			return a.emoji .. " " .. (a.name or ("Most " .. Scoring.themeWord(theme)))
		end
	end
	return Scoring.FALLBACK_AWARD.emoji .. " " .. Scoring.FALLBACK_AWARD.name
end

-- How strongly this look deserves each award (0 = not at all).
function Scoring.awardScores(entry: Entry, theme: Catalog.Theme): { [string]: number }
	local look = entry.look
	local function has(key)
		return not Catalog.isNone(look[key])
	end
	local sparkles, distinct = 0, 0
	for _, key in THEME_SLOTS do
		local it = Catalog.byId[look[key] or ""]
		if it and not Catalog.isNone(it.id) then
			distinct += 1
			if it.sparkle or Catalog.hasTag(it, "sparkle") then
				sparkles += 1
			end
		end
	end
	local applied = 0
	for _, key in MAKEUP_KEYS do
		if has(key) then
			applied += 1
		end
	end
	local costume = 0
	for _, key in { "costumeBack", "costumeFace", "costumeWaist", "costumeShoulder" } do
		if has(key) then
			costume += 1
		end
	end
	return {
		theme = Scoring.themeMatches(look, theme) / THEME_MATCHES_NEEDED,
		costume = math.min(costume / 2, 1),
		pet = if has("pet") then 0.8 else 0,
		show = (if has("pose") then 0.4 else 0) + (if has("effect") then 0.4 else 0),
		hair = (if has("hairStyle") then 0.5 else 0) + (if slotMatches(look, "hairColor", theme) then 0.3 else 0) + (if has("accessory") then 0.1 else 0),
		makeup = applied / #MAKEUP_KEYS,
		sparkle = math.min(sparkles / 3, 1),
		colorful = distinct / #THEME_SLOTS,
		extras = (if has("accessory") then 0.5 else 0) + (if has("gems") then 0.4 else 0),
	}
end

return Scoring
