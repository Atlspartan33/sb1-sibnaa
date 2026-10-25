local E = require("./engine")
local W = require("./world")
W.loadProject(require("./project"))
W.startServer()
E.runFor(1)
local p, ctx = W.addPlayer("Gallery")
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
	local function look(t)
		local l = Catalog.defaultLook()
		for k, v in t do l[k] = v end
		return l
	end
	local rng = E.Random.new(42)
	local cs = {}
	for i = 1, 6 do cs[i] = Clients.generate(rng) end
	local items = {
		{ "Walks in dirty 😫", cs[1], look({}), { clean = 0, mood = "sad" } },
		{ "Washed", cs[1], look({}), { clean = 1, mood = "neutral" } },
		{ "Pink Party 🎀", cs[1], look({ hairStyle = "hair_long", hairColor = "hc_pink", eyeshadow = "es_pink", lashes = "lash_glam", blush = "bl_rosy", lipstick = "lip_gloss", outfit = "outfit_party", accessory = "acc_bow", gems = "gem_hearts" }), { clean = 1, mood = "grin" } },
		{ "Rock Star 🎸", cs[2], look({ hairStyle = "hair_pixie", hairColor = "hc_purple", eyeshadow = "es_smoky", lashes = "lash_glam", lipstick = "lip_black", outfit = "outfit_rock", accessory = "acc_catears", gems = "gem_stars" }), { clean = 1, mood = "smile" } },
		{ "Under the Sea 🐚", cs[3], look({ hairStyle = "hair_mermaid", hairColor = "hc_mint", eyeshadow = "es_ice", lashes = "lash_natural", blush = "bl_peach", lipstick = "lip_blue", outfit = "outfit_mermaid", gems = "gem_rhinestones" }), { clean = 1, mood = "grin" } },
		{ "Royal Ball 👑", cs[4], look({ hairStyle = "hair_updo", hairColor = "hc_galaxy", eyeshadow = "es_gold", lashes = "lash_star", blush = "bl_shimmer", lipstick = "lip_gold", outfit = "outfit_gold", accessory = "acc_crown" }), { clean = 1, mood = "grin" } },
		{ "Sunny Beach 🌴", cs[5], look({ hairStyle = "hair_puff", hairColor = "hc_blonde", eyeshadow = "es_peach", lashes = "lash_natural", blush = "bl_peach", lipstick = "lip_coral", outfit = "outfit_sunny", accessory = "acc_flower", gems = "gem_freckles" }), { clean = 1, mood = "smile" } },
		{ "Candy Land 🍭", cs[6], look({ hairStyle = "hair_buns", hairColor = "hc_rainbow", eyeshadow = "es_purple", lashes = "lash_natural", blush = "bl_rosy", lipstick = "lip_pink", outfit = "outfit_party", gems = "gem_hearts" }), { clean = 1, mood = "grin" } },
		{ "Winter ❄️", cs[2], look({ hairStyle = "hair_braid", hairColor = "hc_silver", eyeshadow = "es_ice", lashes = "lash_natural", lipstick = "lip_berry", outfit = "outfit_snow", accessory = "acc_headband" }), { clean = 1, mood = "smile" } },
		{ "Red Carpet 🌟", cs[3], look({ hairStyle = "hair_curls", hairColor = "hc_black", eyeshadow = "es_gold", lashes = "lash_glam", lipstick = "lip_red", outfit = "outfit_red", accessory = "acc_earrings" }), { clean = 1, mood = "grin" } },
		{ "Spooky Glam 🦇", cs[4], look({ hairStyle = "hair_bob", hairColor = "hc_black", eyeshadow = "es_green", lashes = "lash_glam", lipstick = "lip_black", outfit = "outfit_black", accessory = "acc_catears" }), { clean = 1, mood = "smile" } },
		{ "Forgot to wash! 🙈", cs[5], look({ hairStyle = "hair_pigtails", hairColor = "hc_ginger", lipstick = "lip_red", outfit = "outfit_denim" }), { clean = 0.3, mood = "sad" } },
	}
	for i, it in items do
		local col, row = (i - 1) % 4, (i - 1) // 4
		local cell = E.Instance.new("Frame")
		cell.Position = E.UDim2.fromOffset(12 + col * 262, 12 + row * 292)
		cell.Size = E.UDim2.fromOffset(250, 280)
		cell.BackgroundColor3 = E.Color3.new(1, 1, 1)
		local cr = E.Instance.new("UICorner"); cr.CornerRadius = E.UDim.new(0, 16); cr.Parent = cell
		cell.Parent = gui
		local pic = E.Instance.new("Frame")
		pic.Position = E.UDim2.fromOffset(8, 8)
		pic.Size = E.UDim2.fromOffset(234, 234)
		pic.BackgroundColor3 = E.Color3.fromRGB(255, 236, 246)
		local cr2 = E.Instance.new("UICorner"); cr2.CornerRadius = E.UDim.new(0, 14); cr2.Parent = pic
		pic.Parent = cell
		LR.render(pic, it[2], it[3], it[4])
		local label = E.Instance.new("TextLabel")
		label.Position = E.UDim2.fromOffset(0, 244)
		label.Size = E.UDim2.fromOffset(250, 32)
		label.BackgroundTransparency = 1
		label.Text = it[1]
		label.TextScaled = true
		label.TextColor3 = E.Color3.fromRGB(80, 40, 100)
		label.Parent = cell
	end
end)
print("@@SHOT gallery " .. W.dumpScreen(p, 1060, 890))
print("errors", #E.errors)
