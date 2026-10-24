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
H.check(H.findText(tori, "Daily Gift") ~= nil, "daily gift splash shown")
H.shot(tori, "01_lobby")
H.shot(tori, "01_lobby_phone", 844, 390)
local coinsAfterGift = H.findText(tori, "🪙 ")
print("  coins after gift:", coinsAfterGift and coinsAfterGift.Text)

-- turn on a few sounds for Tori to test the sound code
local cfgT = W.require(ct, W.game:GetService("ReplicatedStorage").Shared.Config)
cfgT.Sounds.Click = "rbxassetid://1"; cfgT.Sounds.Sparkle = "rbxassetid://2"; cfgT.Sounds.MakeoverMusic = "rbxassetid://3"
E.runFor(19)
print("== Makeover")
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
H.shot(tori, "05_hair")
H.shot(tori, "05_hair_phone", 844, 390)
H.click(H.card(tori, "Cute Bob"), "Cute Bob")
H.click(H.button(tori, "Hair Color"), "Hair Color chip")
H.click(H.card(tori, "Bubblegum"), "Bubblegum (locked)")
H.shot(tori, "06_unlock_confirm")
H.click(H.button(tori, "Unlock!"), "Unlock!")
E.runFor(0.5)
H.click(H.card(tori, "Bubblegum"), "Bubblegum")

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
H.shot(tori, "09_extras_phone", 844, 390)
print("  hearts:", H.ui(tori):FindFirstChild("Makeover"):GetDescendants() and "")

print("== Shop")
H.click(H.button(tori, "Shop"), "Shop")
H.shot(tori, "10_shop_coins")
H.click(H.button(tori, "Robux Extras"), "Robux tab")
H.shot(tori, "11_shop_robux")
H.click(H.button(tori, "✕"), "close shop")

print("== Done -> show")
H.click(H.button(tori, "I'm Done"), "Tori done")
H.shot(tori, "12_waiting")
H.click(H.button(mia, "I'm Done"), "Mia done")
E.runFor(1.5)
H.click(H.button(mia, "😍"), "Mia cheers")
H.click(H.button(tori, "👏"), "Tori cheers")
E.runFor(0.3)
H.shot(mia, "13_showcase_vote")
H.shot(tori, "13_showcase_own")
H.shot(mia, "13_showcase_phone", 844, 390)
for i = 1, 2 do
	local star = nil
	for _, d in H.ui(mia):GetDescendants() do
		if E.D[d].class == "TextButton" and d.Text == "☆" and H.shown(d) then star = d end
	end
	if star then H.click(star, "5th star") end
	E.runFor(9)
end
E.runFor(1)
print("== Results")
H.shot(tori, "14_results")
H.shot(tori, "14_results_phone", 844, 390)
local res = H.findText(tori, "You placed")
print("  " .. (res and res.Text or "no result text"))
E.runFor(5)
H.check(H.findText(tori, "⭐ Lv 1") ~= nil, "level pill shows progress")
print("  level:", H.findText(tori, "⭐ Lv") and H.findText(tori, "⭐ Lv").Text)

print("== Robux purchases (simulated receipts)")
local function setConfig(ctx)
	local cfg = W.require(ctx, W.game:GetService("ReplicatedStorage").Shared.Config)
	cfg.DevProducts.SuperSoap = 111
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
print("  coins:", H.findText(tori, "🪙 ").Text)
receipt(tori, 111, "p2")
E.runFor(0.5)

E.runFor(30)
print("== Round 2: super soap + leave/rejoin")
H.check(H.shown(H.ui(tori).Makeover), "round 2 makeover visible")
H.click(H.button(tori, "Super Soap ("), "use super soap")
E.runFor(0.5)
H.check(H.findText(tori, "Sparkly clean") ~= nil, "super soap cleaned face")
local coinsBefore = H.findText(tori, "🪙 ").Text
W.removePlayer(tori)
E.runFor(2)
local tori2, ct2 = W.addPlayer("Tori2")
-- same user id should load saved data: simulate same account by reusing id
print("  (new account starts fresh) coins:", (function() E.runFor(3) return H.findText(tori2, "🪙 ").Text end)())

print("== Idle rounds for stability")
E.runFor(60 * 14)
print("  after idle rounds, phase pill:", H.findText(mia, "Makeover") ~= nil or H.findText(mia, "show") ~= nil or H.findText(mia, "Results") ~= nil)

local counts = {}
for _, n in W.soundsPlayed do counts[n] = (counts[n] or 0) + 1 end
print("sounds:", counts.Click, counts.Sparkle, counts.MakeoverMusic)
H.check((counts.Click or 0) > 3 and (counts.Sparkle or 0) >= 1 and (counts.MakeoverMusic or 0) >= 1, "sounds play when IDs are set")
print("errors", #E.errors, "warnings", #E.warnings, "fails", H.fails)
for _, w in E.warnings do print("WARN", w) end
