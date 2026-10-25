local E = require("./engine")
local W = require("./world")
local H = require("./helpers")
W.loadProject(require("./project"))
W.startServer()
E.runFor(1)
local tori, ct = W.addPlayer("Tori")
local mia, cm = W.addPlayer("Mia")
E.runFor(3.5)
print("== Lobby + daily gift")
H.check(H.findText(tori, "Day 1 Gift") ~= nil, "daily gift calendar shown")
H.shot(tori, "01_lobby")
H.shot(tori, "01_lobby_phone", 844, 390)
local coinsAfterGift = H.findText(tori, "💰 ")
print("  coins after gift:", coinsAfterGift and coinsAfterGift.Text)

-- turn on a few sounds for Tori to test the sound code
local cfgT = W.require(ct, W.game:GetService("ReplicatedStorage").Shared.Config)
cfgT.Sounds.Click = "rbxassetid://1"; cfgT.Sounds.Sparkle = "rbxassetid://2"; cfgT.Sounds.MakeoverMusic = "rbxassetid://3"
E.runFor(19)
print("== Makeover")
-- A cheating client claims a spotless face right away (server should not believe it)
local remotesMia = W.require(cm, W.game:GetService("ReplicatedStorage").Shared.Remotes)
E.runAs(cm, function() remotesMia.WashProgress:FireServer(1, true) end)
local ui = H.ui(tori)
H.check(H.shown(ui.Makeover), "makeover screen visible")
E.runFor(0.3)
H.shot(tori, "02_wash_start")
H.shot(tori, "02_wash_phone", 844, 390)
H.shot(tori, "02_wash_tablet", 1024, 768)
E.runFor(2.6)
local dirtyFirst = H.ui(tori):FindFirstChild("PortraitHolder", true).Portrait
for _, c in dirtyFirst:GetChildren() do
	if c.Name == "Dirt1" or c.Name == "Dirt2" then H.rub(ct, H.center(c), 25, 14) end
end
E.runFor(0.05)
H.shot(tori, "02b_wash_dirty")

local holder = ui:FindFirstChild("PortraitHolder", true)
local portrait = holder.Portrait
local dirt = {}
for _, c in portrait:GetChildren() do if string.sub(c.Name, 1, 4) == "Dirt" then table.insert(dirt, c) end end
print("  dirt spots:", #dirt, "portrait size", portrait.AbsoluteSize.X)
for i = 1, math.floor(#dirt / 2) do H.rub(ct, H.center(dirt[i]), 25, 14) end
H.shot(tori, "03_wash_mid")
local rubs = 0
for pass = 1, 4 do
	for i = 1, #dirt do
		if dirt[i].Visible then H.rub(ct, H.center(dirt[i]), 25, 14); rubs += 1 end
	end
end
print("  extra rubs needed:", rubs)
local cleanText = H.findText(tori, "Clean:")
print("  " .. (cleanText and cleanText.Text or "?"))
H.check(H.findText(tori, "Rinse off the bubbles") ~= nil or H.findText(tori, "Sparkly clean") ~= nil, "rinse step reached")
for _, b in ui:FindFirstChild("Bubbles", true):GetChildren() do
	if b.Parent and E.D[b].class == "Frame" then H.rub(ct, H.center(b), 10, 6) end
end
E.runFor(0.5)
H.check(#ui:FindFirstChild("Bubbles", true):GetChildren() <= 1, "all bubbles rinsed")
H.check(H.findText(tori, "Sparkly clean") ~= nil, "wash complete hint")
H.shot(tori, "04_wash_done")

print("== Hair")
H.click(H.tab(tori, "Hair"), "Hair tab")
H.check(H.findText(tori, "Brush out the tangles") ~= nil, "messy hair must be brushed first")
H.shot(tori, "05a_brush")
local root = H.ui(tori):FindFirstChild("PortraitHolder", true).Portrait
local top = root.AbsolutePosition + E.Vector2.new(root.AbsoluteSize.X * 0.5, root.AbsoluteSize.X * 0.22)
for _ = 1, 12 do
	if not H.findText(tori, "Brush out the tangles") then break end
	H.rub(ct, top, 60, 16)
end
H.check(H.findText(tori, "Brush out the tangles") == nil, "brushing unlocks the hairstyles")
H.shot(tori, "05_hair")
H.shot(tori, "05_hair_phone", 844, 390)
H.click(H.card(tori, "Cute Bob"), "Cute Bob")
H.click(H.button(tori, "Hair Color"), "Hair Color chip")
H.click(H.card(tori, "Bubblegum"), "Bubblegum (locked)")
H.shot(tori, "06_unlock_confirm")
H.click(H.button(tori, "Unlock!"), "Unlock!")
E.runFor(0.5)
H.click(H.card(tori, "Bubblegum"), "Bubblegum")
H.check(H.findText(tori, "🛍️ Shop") == nil, "shop button hidden during the makeover")

print("== Makeup")
H.click(H.tab(tori, "Makeup"), "Makeup tab")
H.click(H.card(tori, "Pink"), "Pink eyeshadow")
H.click(H.button(tori, "Lashes"), "Lashes chip")
H.click(H.card(tori, "Natural"), "Natural lashes")
H.click(H.button(tori, "Blush"), "Blush chip")
H.click(H.card(tori, "Rosy"), "Rosy")
H.click(H.button(tori, "Lipstick"), "Lipstick chip")
H.click(H.card(tori, "Pink"), "Pink lipstick")
H.shot(tori, "07_makeup")
H.click(H.tab(tori, "Outfit"), "Outfit tab")
H.click(H.card(tori, "Pink Party Dress"), "Party dress")
H.shot(tori, "08_outfit")
H.click(H.tab(tori, "Extras"), "Extras tab")
H.click(H.button(tori, "Accessory"), "Accessory chip")
H.click(H.card(tori, "Big Bow"), "Bow")
E.runFor(0.3)
H.shot(tori, "09_extras")

print("== Nails + outfit colors")
H.click(H.tab(tori, "Nails"), "Nails tab")
H.click(H.card(tori, "Pink"), "Pink polish")
H.click(H.button(tori, "Nail Art"), "Nail Art chip")
H.click(H.card(tori, "Hearts"), "Heart nail art")
E.runFor(0.6)
local nails = 0
for _, d in H.ui(tori):FindFirstChild("PortraitHolder", true).Portrait:GetChildren() do
	if d.Name == "Nail" then nails += 1 end
end
H.check(nails == 5, "hand shows 5 painted nails")
H.shot(tori, "09b_nails")
H.click(H.tab(tori, "Outfit"), "Outfit tab")
H.click(H.button(tori, "Color"), "Color chip")
H.click(H.card(tori, "Violet"), "Violet color")
H.click(H.button(tori, "Pattern"), "Pattern chip")
H.click(H.card(tori, "Polka Dots"), "Polka dots")
E.runFor(0.3)
H.shot(tori, "09c_outfit_pattern")
H.shot(tori, "09_extras_phone", 844, 390)
print("  hearts:", H.ui(tori):FindFirstChild("Makeover"):GetDescendants() and "")

print("== Done -> show")
H.click(H.button(tori, "I'm Done"), "Tori done")
H.shot(tori, "12_waiting")
H.click(H.button(mia, "I'm Done"), "Mia done")
E.runFor(1.5)
-- A cheater sends a NaN vote (should be ignored, not wipe anyone's coins)
E.runAs(cm, function() remotesMia.Vote:FireServer(tori.UserId, 0 / 0); remotesMia.Vote:FireServer(tori.UserId, 99) end)
H.click(H.button(mia, "😍"), "Mia cheers")
H.click(H.button(tori, "👏"), "Tori cheers")
E.runFor(0.3)
H.shot(mia, "13_showcase_vote")
H.shot(tori, "13_showcase_own")
H.shot(mia, "13_showcase_phone", 844, 390)
for i = 1, 2 do
	local heart = H.button(mia, "WOW")
	if heart then H.click(heart, "💖💖💖 vote") end
	E.runFor(9)
end
E.runFor(1)
print("== Results")
H.shot(tori, "14_results")
H.shot(tori, "14_results_phone", 844, 390)
local res = H.findText(tori, "Your ")
print("  " .. (res and res.Text or "no result text"))
local miaRes = H.findText(mia, "Your ")
H.check(miaRes ~= nil and string.find(miaRes.Text, "Wash the face", 1, true) ~= nil, "instant-wash cheat ignored")
H.check(res ~= nil and not string.find(res.Text, "nan", 1, true), "NaN vote ignored")
E.runFor(5)
H.check(H.findText(tori, "⭐ Lv") ~= nil, "level pill shows progress")
print("  level:", H.findText(tori, "⭐ Lv") and H.findText(tori, "⭐ Lv").Text)

print("== Shop (between rounds)")
H.click(H.button(tori, "Shop"), "Shop")
H.shot(tori, "10_shop_coins")
local shopCard = H.card(tori, "Hairstyle\nPigtails") or H.findText(tori, "Pigtails")
H.check(shopCard ~= nil and shopCard.AbsoluteSize.Y > 20, "shop coin cards have a real size")
H.click(H.button(tori, "💎 Extras"), "Robux tab")
H.shot(tori, "11_shop_robux")
H.click(H.button(tori, "✕"), "close shop")

print("== Robux purchases (simulated receipts)")
local function setConfig(ctx)
	local cfg = W.require(ctx, W.game:GetService("ReplicatedStorage").Shared.Config)
	cfg.DevProducts.CoinsSmall = 222
end
setConfig(W.server); setConfig(ct)
local mps = W.game:GetService("MarketplaceService")
local function receipt(player, productId, purchaseId)
	local result
	E.runAs(W.server, function()
		E.task.spawn(function()
			result = E.D[mps].props.ProcessReceipt({ PlayerId = player.UserId, ProductId = productId, PurchaseId = purchaseId })
		end)
	end)
	E.runFor(1)
	return result
end
local r1 = receipt(tori, 222, "p1")
local r1b = receipt(tori, 222, "p1")
E.runFor(0.5)
H.check(tostring(r1) == "Enum.ProductPurchaseDecision.PurchaseGranted" and tostring(r1b) == "Enum.ProductPurchaseDecision.PurchaseGranted", "coin pack granted, duplicate receipt safe")
print("  coins:", H.findText(tori, "💰 ").Text)
H.click(H.button(tori, "Shop"), "Shop")
H.click(H.button(tori, "My Looks"), "Look Book tab")
E.runFor(0.3)
H.check(H.findText(tori, "Amara") ~= nil or H.findText(tori, "★") ~= nil, "look saved in the Look Book")
H.shot(tori, "15_lookbook")
H.click(H.button(tori, "✕"), "close shop")

E.runFor(30)
print("== Round 2: super soap + leave/rejoin")
H.check(H.shown(H.ui(tori).Makeover), "round 2 makeover visible")
H.check(H.findText(tori, "Rub the dirt off") ~= nil, "round 2 starts with a dirty face")
local coinsBefore = H.findText(tori, "💰 ").Text
local toriId = tori.UserId
W.removePlayer(tori)
E.runFor(2)
local tori2, ct2 = W.addPlayer("Tori", toriId)
E.runFor(4)
local coinsAfter = H.findText(tori2, "💰 ").Text
print("  coins before leaving:", coinsBefore, " after rejoining:", coinsAfter)
H.check(coinsBefore == coinsAfter, "rejoining loads saved coins")

print("== Idle rounds for stability")
local function weeklyText(p)
	for _, d in H.ui(p):GetDescendants() do
		if E.D[d].class == "TextLabel" and string.find(d.Text, "Weekly goal", 1, true) then return d.Text end
	end
	return ""
end
print("  " .. weeklyText(mia))
H.check(string.find(weeklyText(mia), "/5 shows", 1, true) ~= nil and not string.find(weeklyText(mia), "0/5", 1, true), "weekly goal counts shows")
-- Mia keeps playing (picks some makeup each round); idle rounds don't count for the weekly goal
local acted = false
for _ = 1, 26 * 12 do
	E.runFor(5)
	local mv = H.ui(mia):FindFirstChild("Makeover")
	if H.shown(mv) and not acted then
		H.click(H.tab(mia, "Makeup"), "Mia makeup tab")
		H.click(H.card(mia, "Pink"), "Mia pink")
		acted = true
	elseif not H.shown(mv) then
		acted = false
	end
end
print("  " .. weeklyText(mia))
H.check(string.find(weeklyText(mia), "done", 1, true) ~= nil, "weekly goal completes after 5 shows")
print("  after idle rounds, phase pill:", H.findText(mia, "Makeover") ~= nil or H.findText(mia, "show") ~= nil or H.findText(mia, "Results") ~= nil)

local counts = {}
for _, n in W.soundsPlayed do counts[n] = (counts[n] or 0) + 1 end
print("sounds:", counts.Click, counts.Sparkle, counts.Rinse, counts.MakeoverMusic)
H.check((counts.Click or 0) > 3 and (counts.Sparkle or 0) >= 1 and (counts.Rinse or 0) >= 1 and (counts.MakeoverMusic or 0) >= 1, "sounds play when IDs are set")
print("errors", #E.errors, "warnings", #E.warnings, "fails", H.fails)
for _, w in E.warnings do print("WARN", w) end
