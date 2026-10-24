-- Stylist levels: stars earned in shows add up. Each level needs a few more stars than the last,
-- so there's always something to work toward.

local Progress = {}

local TITLES = {
	{ level = 1, title = "Newbie Stylist" },
	{ level = 3, title = "Rising Star" },
	{ level = 5, title = "Pro Stylist" },
	{ level = 8, title = "Glam Queen" },
	{ level = 12, title = "Superstar Stylist" },
	{ level = 20, title = "Legendary Stylist" },
}

-- Total stars needed to reach a level: Lv2 = 6, Lv3 = 14, Lv5 = 36, Lv10 = 126, Lv20 = 456
function Progress.starsFor(level: number): number
	return (level - 1) * (level + 4)
end

function Progress.level(totalStars: number): number
	local level = 1
	while Progress.starsFor(level + 1) <= (totalStars or 0) do
		level += 1
	end
	return level
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
	local level = Progress.level(totalStars)
	local from, to = Progress.starsFor(level), Progress.starsFor(level + 1)
	return ((totalStars or 0) - from) / (to - from)
end

return Progress
