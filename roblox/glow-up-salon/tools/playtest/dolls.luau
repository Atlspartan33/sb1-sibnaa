-- Renders runway "paper doll" bodies for a quick look
local E = require("./engine")
local W = require("./world")
W.loadProject(require("./project"))
W.startServer()
E.runFor(1)
local p, ctx = W.addPlayer("Dolls")
E.runFor(2)
E.runAs(ctx, function()
	local RS = W.game:GetService("ReplicatedStorage")
	local LR = W.require(ctx, RS.Shared.LookRenderer)
	local Catalog = W.require(ctx, RS.Shared.Catalog)
	local Clients = W.require(ctx, RS.Shared.Clients)
	for _, g in p.PlayerGui:GetChildren() do g.Enabled = false end
	local gui = E.Instance.new("ScreenGui")
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = E.Enum.ZIndexBehavior.Sibling
	gui.Parent = p.PlayerGui
	local function look(t) local l = Catalog.defaultLook() for k, v in t do l[k] = v end return l end
	local rng = E.Random.new(9)
	local looks = {
		look({ hairStyle = "hair_long", hairColor = "hc_pink", eyeshadow = "es_pink", lipstick = "lip_gloss", blush = "bl_rosy", outfit = "outfit_party", outfitPattern = "pat_dots", accessory = "acc_bow" }),
		look({ hairStyle = "hair_curls", hairColor = "hc_black", eyeshadow = "es_gold", lipstick = "lip_red", outfit = "outfit_red", accessory = "acc_earrings" }),
		look({ hairStyle = "hair_pixie", hairColor = "hc_purple", lipstick = "lip_black", outfit = "outfit_rock", accessory = "acc_catears" }),
		look({ hairStyle = "hair_updo", hairColor = "hc_galaxy", lipstick = "lip_gold", outfit = "outfit_galaxy", accessory = "acc_crown" }),
		look({ hairStyle = "hair_buns", hairColor = "hc_blonde", outfit = "outfit_denim", outfitColor = "oc_mint", outfitPattern = "pat_stripes" }),
		look({}),
	}
	for i, l in looks do
		local f = E.Instance.new("Frame")
		f.Position = E.UDim2.fromOffset(10 + (i - 1) * 205, 20)
		f.Size = E.UDim2.fromOffset(195, 390)
		f.BackgroundColor3 = E.Color3.fromRGB(255, 236, 246)
		f.Parent = gui
		LR.renderBody(f, Clients.generate(rng), l, { mood = "grin", clean = 1 })
	end
end)
print("@@SHOT dolls " .. W.dumpScreen(p, 1240, 430))
print("errors", #E.errors)
