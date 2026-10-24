-- "Monkey test": 4 kids tap random buttons and rub random spots for an hour of game time.
-- Anything that errors is a bug a real kid could hit.
local E = require("./engine")
local W = require("./world")
local H = require("./helpers")
W.loadProject(require("./project"))
W.startServer()
E.runFor(1)
local kids = {}
for _, name in { "Ava", "Bea", "Cleo", "Dot" } do
	local p, ctx = W.addPlayer(name)
	table.insert(kids, { p = p, ctx = ctx })
end
local seed = tonumber((...)) or 1234
math.randomseed(seed)
local clicks, rubs, leaves = 0, 0, 0
local function buttons(p)
	local list = {}
	for _, d in H.ui(p):GetDescendants() do
		if E.D[d].class == "TextButton" and H.shown(d) then table.insert(list, d) end
	end
	return list
end
for step = 1, 60 * 60 * 2 do -- one action every half second, for an hour
	local kid = kids[math.random(1, #kids)]
	if kid.p.Parent then
		local r = math.random()
		if r < 0.7 then
			local list = buttons(kid.p)
			if #list > 0 then
				local b = list[math.random(1, #list)]
				b.Activated:Fire(nil, 1)
				clicks += 1
			end
		else
			local holder = H.ui(kid.p):FindFirstChild("PortraitHolder", true)
			if holder and H.shown(holder) then
				local c = holder.AbsolutePosition + holder.AbsoluteSize * E.Vector2.new(math.random(), math.random())
				H.rub(kid.ctx, c, 20 + math.random() * 40, 8)
				rubs += 1
			end
		end
	end
	-- now and then someone leaves and comes back
	if step % 1500 == 0 then
		local kid2 = kids[math.random(1, #kids)]
		if kid2.p.Parent then
			local id = kid2.p.UserId
			W.removePlayer(kid2.p)
			E.runFor(3)
			kid2.p, kid2.ctx = W.addPlayer(kid2.p.Name, id)
			leaves += 1
		end
	end
	E.runFor(0.5)
end
print(string.format("monkey: %d taps, %d rubs, %d rejoins, %d prompts", clicks, rubs, leaves, #W.prompts))
print("errors", #E.errors, "warnings", #E.warnings)
for i = 1, math.min(5, #E.errors) do print(E.errors[i]) end
for i = 1, math.min(5, #E.warnings) do print("WARN", E.warnings[i]) end
