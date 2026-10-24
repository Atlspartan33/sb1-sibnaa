-- The judges! Gives a look 1-5 stars and says what they liked (or what to fix next time).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.Catalog)

local Scoring = {}

export type Entry = {
	look: { [string]: string },
	clean: number,
	rinsed: boolean,
}

local MAKEUP_KEYS = { "eyeshadow", "lashes", "blush", "lipstick" }
local COLOR_MAKEUP_KEYS = { "eyeshadow", "blush", "lipstick" }

function Scoring.roundToHalf(stars: number): number
	return math.clamp(math.floor(stars * 2 + 0.5) / 2, 1, 5)
end

-- Returns stars (1..5, in half steps) and a list of judge comments.
function Scoring.judge(entry: Entry, theme: Catalog.Theme): (number, { string })
	local look = entry.look
	local points = 0
	local comments = {}

	-- Washing (1 point)
	local clean = math.clamp(entry.clean or 0, 0, 1)
	points += clean
	if clean < 0.5 then
		table.insert(comments, "Their face is still dirty! Wash it first 🧼")
	elseif clean < 0.98 then
		table.insert(comments, "Almost clean... you missed a spot!")
	elseif not entry.rinsed then
		points -= 0.2
		table.insert(comments, "Squeaky clean, but rinse off the soap bubbles! 🚿")
	else
		table.insert(comments, "Squeaky clean! ✨")
	end

	-- Hair (1.25 points)
	if Catalog.isNone(look.hairStyle) then
		table.insert(comments, "That hair is still a mess! 💇")
	else
		points += 0.75
	end
	if Catalog.matchesTheme(Catalog.byId[look.hairColor], theme) then
		points += 0.5
		table.insert(comments, "Love the hair color for " .. theme.name .. "!")
	end

	-- Makeup (1.75 points)
	local applied = 0
	for _, key in MAKEUP_KEYS do
		if not Catalog.isNone(look[key]) then
			applied += 1
		end
	end
	points += applied / #MAKEUP_KEYS
	if applied == 0 then
		table.insert(comments, "Don't forget the makeup! 💄")
	end
	local matched = 0
	for _, key in COLOR_MAKEUP_KEYS do
		if Catalog.matchesTheme(Catalog.byId[look[key]], theme) then
			matched += 1
		end
	end
	points += 0.75 * matched / #COLOR_MAKEUP_KEYS
	if matched >= 2 then
		table.insert(comments, "The makeup totally fits the theme!")
	end

	-- Outfit (1 point)
	if Catalog.isNone(look.outfit) then
		table.insert(comments, "They walked the runway in work overalls! 👗")
	else
		points += 0.5
		if Catalog.matchesTheme(Catalog.byId[look.outfit], theme) or Catalog.matchesTheme(Catalog.byId[look.outfitColor or ""], theme) then
			points += 0.5
		else
			table.insert(comments, "Try an outfit that matches " .. theme.name)
		end
	end

	-- Nails (bonus)
	if not Catalog.isNone(look.nailColor) then
		points += 0.25
		if Catalog.matchesTheme(Catalog.byId[look.nailColor], theme) then
			points += 0.25
		end
	end

	-- Extras (bonus, up to 0.75)
	if not Catalog.isNone(look.gems) then
		points += 0.25
	end
	if not Catalog.isNone(look.accessory) then
		points += 0.25
		if Catalog.matchesTheme(Catalog.byId[look.accessory], theme) then
			points += 0.25
		end
	end

	local stars = Scoring.roundToHalf(points)
	if stars >= 4.5 then
		table.insert(comments, 1, "ABSOLUTELY STUNNING! 😍")
	elseif stars >= 3.5 then
		table.insert(comments, 1, "What a glow up!")
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

return Scoring
