-- Holiday events: limited-time themes, items, client stories and decorations.
-- Dates are in UTC. Set Config.FORCE_EVENT to preview an event in Studio (it's ignored in the live game).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local Events = {}

export type Event = {
	id: string,
	name: string,
	icon: string,
	theme: string, -- the special fashion show theme
	from: { number }, -- { month, day }
	to: { number }, -- { month, day } (inclusive)
	endsText: string,
}

Events.List = {
	{ id = "halloween", name = "Halloween", icon = "🎃", theme = "halloween", from = { 10, 10 }, to = { 11, 2 }, endsText = "until Nov 2" },
	{ id = "thanksgiving", name = "Harvest Festival", icon = "🍂", theme = "thanksgiving", from = { 11, 3 }, to = { 11, 30 }, endsText = "until Nov 30" },
	{ id = "christmas", name = "Christmas", icon = "🎄", theme = "christmas", from = { 12, 1 }, to = { 12, 31 }, endsText = "until Dec 31" },
} :: { Event }

Events.byId = {} :: { [string]: Event }
for _, e in Events.List do
	Events.byId[e.id] = e
end

local function dayNumber(month: number, day: number): number
	return month * 100 + day
end

-- The event happening at `timestamp` (seconds since 1970, UTC), or nil.
function Events.current(timestamp: number): Event?
	if Config.FORCE_EVENT and RunService:IsStudio() then
		local forced = Events.byId[Config.FORCE_EVENT]
		if not forced then
			warn("[GlowUp] Config.FORCE_EVENT is not a known event:", Config.FORCE_EVENT)
		end
		return forced
	end
	local date = os.date("!*t", math.floor(timestamp))
	local today = dayNumber(date.month, date.day)
	for _, e in Events.List do
		if today >= dayNumber(e.from[1], e.from[2]) and today <= dayNumber(e.to[1], e.to[2]) then
			return e
		end
	end
	return nil
end

return Events
