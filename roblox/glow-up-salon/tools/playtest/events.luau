-- Holiday events: switches the forced event each round and checks themes, items and decorations.
local E = require("./engine")
local W = require("./world")
local H = require("./helpers")
W.loadProject(require("./project"))
W.startServer()
local RS = W.game:GetService("ReplicatedStorage")
local function force(eventId, ...)
	for _, ctx in { W.server, ... } do
		W.require(ctx, RS.Shared.Config).FORCE_EVENT = eventId
	end
end
force("halloween")
E.runFor(1)
local tori, ct = W.addPlayer("Tori")
W.viewer = tori
force("halloween", ct)
local function camCF(c) return { c.x, c.y, c.z, c.m[1], c.m[2], c.m[3], c.m[4], c.m[5], c.m[6], c.m[7], c.m[8], c.m[9] } end
local runway = E.CFrame.lookAt(E.Vector3.new(14, 12, 4), E.Vector3.new(0, 5, -40))
local salon = E.CFrame.lookAt(E.Vector3.new(0, 14, 20), E.Vector3.new(0, 4, 55))

for i, eventId in { "halloween", "thanksgiving", "christmas" } do
	print("== " .. eventId)
	force(eventId, ct)
	-- wait for the lobby
	local waited = 0
	while not H.shown(H.ui(tori).Lobby) and waited < 600 do E.runFor(1); waited += 1 end
	E.runFor(2)
	H.check(H.findText(tori, " event!") ~= nil, "lobby shows the event banner")
	local decor = W.game:GetService("Workspace").GlowUpWorld:FindFirstChild("Decor")
	H.check(decor ~= nil and #decor:GetChildren() > 20, "holiday decorations built (" .. (decor and #decor:GetChildren() or 0) .. " parts)")
	local w = W.dumpWorld()
	w.camera = camCF(runway)
	print("@@WORLD e" .. i .. "_" .. eventId .. "_runway " .. W.json(w))
	w = W.dumpWorld()
	w.camera = camCF(salon)
	print("@@WORLD e" .. i .. "_" .. eventId .. "_salon " .. W.json(w))
	-- into the makeover: holiday items should be in the menus
	while not H.shown(H.ui(tori).Makeover) and waited < 900 do E.runFor(1); waited += 1 end
	E.runFor(3)
	H.click(H.tab(tori, "GoCostume"), "walk to Costume Closet")
	E.runFor(0.2)
	H.click(H.button(tori, "Hats & Clips"), "Hats & Clips chip")
	local holidayAcc = ({ halloween = "Pumpkin Clip", thanksgiving = "Leaf Crown", christmas = "Reindeer Antlers" })[eventId]
	H.check(H.card(tori, holidayAcc) ~= nil, holidayAcc .. " is in the menu")
	H.click(H.card(tori, holidayAcc), holidayAcc)
	H.click(H.tab(tori, "GoOutfit"), "walk to Wardrobe")
	E.runFor(0.2)
	print("@@SHOT e" .. i .. "_" .. eventId .. "_outfits " .. W.dumpScreen(tori, 1280, 720))
	E.SCREEN = { 1280, 720 }
	H.click(H.button(tori, "I'm Done"), "done")
	E.runFor(5)
end
-- after events end, holiday items disappear unless unlocked
force(nil, ct)
local waited = 0
while not H.shown(H.ui(tori).Makeover) and waited < 900 do E.runFor(1); waited += 1 end
E.runFor(2)
H.click(H.tab(tori, "GoCostume"), "walk to Costume Closet")
	E.runFor(0.2)
H.click(H.button(tori, "Hats & Clips"), "Hats & Clips chip")
H.check(H.card(tori, "Santa Hat") == nil, "unused holiday items hidden after the event")
H.check(H.card(tori, "Reindeer Antlers") ~= nil, "holiday items you used are yours to keep")
H.check(W.game:GetService("Workspace").GlowUpWorld:FindFirstChild("Decor") == nil, "decorations removed after the event")
print("errors", #E.errors, "fails", H.fails)
