-- Stylist levels: every star a stylist earns in a show adds up, and every 5 stars is a new level.

local Progress = {}

local TITLES = {
	{ level = 1, title = "Newbie Stylist" },
	{ level = 3, title = "Rising Star" },
	{ level = 5, title = "Pro Stylist" },
	{ level = 8, title = "Glam Queen" },
	{ level = 12, title = "Superstar Stylist" },
	{ level = 20, title = "Legendary Stylist" },
}

Progress.STARS_PER_LEVEL = 5

function Progress.level(totalStars: number): number
	return 1 + math.floor((totalStars or 0) / Progress.STARS_PER_LEVEL)
end

function Progress.title(level: number): string
	local title = TITLES[1].title
	for _, t in TITLES do
		if level >= t.level then
			title = t.title
		end
	end
	return title
end

-- 0..1 progress toward the next level
function Progress.fraction(totalStars: number): number
	return ((totalStars or 0) % Progress.STARS_PER_LEVEL) / Progress.STARS_PER_LEVEL
end

return Progress
