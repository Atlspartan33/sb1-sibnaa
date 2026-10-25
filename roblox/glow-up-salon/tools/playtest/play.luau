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
print("== Dressing room")
local remotesMia = W.require(cm, W.game:GetService("ReplicatedStorage").Shared.Remotes)
local ui = H.ui(tori)
H.check(H.shown(ui.Makeover), "dressing room visible")
E.runFor(0.3)
H.check(H.findText(tori, "Rub the dirt off") == nil, "no washing: you come in fresh")
H.check(H.card(tori, "Cute Bob") == nil, "no menu until you walk to a station")
H.click(H.tab(tori, "GoHair"), "walk to the Hair Chair")
E.runFor(0.2)
H.check(H.card(tori, "Cute Bob") ~= nil, "the Hair Chair opens the hair menu")
local function countBots()
	local n = 0
	for _, d in W.game:GetService("Workspace").GlowUpWorld:GetChildren() do
		if string.find(d.Name, "(Style Bot)", 1, true) then n += 1 end
	end
	return n
end
H.check(countBots() == 1, "one Style Bot joins two players")
H.shot(tori, "02_dressing_room")
H.shot(tori, "02_dressing_phone", 844, 390)
H.shot(tori, "02_dressing_tablet", 1024, 768)

print("== Hair")
H.click(H.card(tori, "Cute Bob"), "Cute Bob")
H.click(H.button(tori, "Hair Color"), "Hair Color chip")
H.click(H.card(tori, "Bubblegum"), "Bubblegum (locked)")
H.shot(tori, "06_unlock_confirm")
H.click(H.button(tori, "Unlock!"), "Unlock!")
E.runFor(0.5)
H.click(H.card(tori, "Bubblegum"), "Bubblegum")
H.check(H.findText(tori, "🛍️ Shop") == nil, "shop button hidden during the makeover")

print("== Face")
H.click(H.tab(tori, "GoFace"), "walk to the Makeup Vanity")
E.runFor(0.2)
H.check(H.button(tori, "Skin") == nil, "no skin picker: you play in your own skin")
H.click(H.button(tori, "Eyeshadow"), "Eyeshadow chip")
H.click(H.card(tori, "Pink"), "Pink eyeshadow")
H.click(H.button(tori, "Lashes"), "Lashes chip")
H.click(H.card(tori, "Natural"), "Natural lashes")
H.click(H.button(tori, "Blush"), "Blush chip")
H.click(H.card(tori, "Rosy"), "Rosy")
H.click(H.button(tori, "Lipstick"), "Lipstick chip")
H.click(H.card(tori, "Pink"), "Pink lipstick")
H.shot(tori, "07_face")
H.click(H.tab(tori, "GoOutfit"), "walk to the Wardrobe")
E.runFor(0.2)
H.click(H.card(tori, "Pink Party Dress"), "Party dress")
H.shot(tori, "08_outfit")

print("== Costume, pet, show")
H.click(H.tab(tori, "GoCostume"), "walk to the Costume Closet")
E.runFor(0.2)
H.click(H.button(tori, "Hats & Clips"), "Hats & Clips chip")
H.click(H.card(tori, "Big Bow"), "Bow")
H.click(H.button(tori, "Wings & Capes"), "Wings & Capes chip")
H.click(H.card(tori, "Fairy Wings"), "Fairy Wings")
H.click(H.button(tori, "Buddies"), "Buddies chip")
H.click(H.card(tori, "Parrot"), "Parrot")
E.runFor(0.3)
H.shot(tori, "09_costume")
H.click(H.tab(tori, "GoPet"), "walk to the Pet Park")
E.runFor(0.2)
H.click(H.card(tori, "Bean"), "Bean")
H.click(H.tab(tori, "GoShow"), "walk to the Pose Stage")
E.runFor(0.2)
H.click(H.card(tori, "Dance"), "Dance pose")
H.click(H.button(tori, "Effect"), "Effect chip")
H.click(H.card(tori, "Sparkles"), "Sparkles")
E.runFor(0.3)
H.shot(tori, "09b_show")
local me = W.game:GetService("Workspace"):FindFirstChild("Tori")
H.check(me ~= nil and me:FindFirstChild("Glam") ~= nil and me.Glam:FindFirstChild("Hair") ~= nil, "your own avatar wears the look")
local pets = 0
for _, d in W.game:GetService("Workspace").GlowUpWorld:GetChildren() do if d.Name == "Tori's Pet" then pets += 1 end end
H.check(pets == 1, "Bean follows you around")
H.click(H.tab(tori, "GoOutfit"), "walk to the Wardrobe")
E.runFor(0.2)
H.click(H.button(tori, "Color"), "Color chip")
H.click(H.card(tori, "Violet"), "Violet color")
H.click(H.button(tori, "Pattern"), "Pattern chip")
H.click(H.card(tori, "Polka Dots"), "Polka dots")
E.runFor(0.3)
H.shot(tori, "09c_outfit_pattern")
H.shot(tori, "09_extras_phone", 844, 390)
-- Mia brings a pet (so her show counts toward the weekly goal)
H.click(H.tab(mia, "GoPet"), "Mia walks to the Pet Park")
E.runFor(0.2)
H.click(H.card(mia, "Kitty"), "Mia kitty")

print("== Done -> show")
H.click(H.button(tori, "I'm Done"), "Tori done")
H.shot(tori, "12_waiting")
H.click(H.button(mia, "I'm Done"), "Mia done")
H.check(H.findText(mia, "still time to style") ~= nil, "Done asks once before ending early")
H.click(H.button(mia, "Tap again"), "Mia done (yes, really)")
E.runFor(1.5)
-- A cheater sends a NaN vote (should be ignored, not wipe anyone's coins)
E.runAs(cm, function() remotesMia.Vote:FireServer(tori.UserId, 0 / 0); remotesMia.Vote:FireServer(tori.UserId, 99) end)
-- (whoever is on the runway gets pose buttons instead of cheers)
H.click(H.button(mia, "😍") or H.button(mia, "Wave"), "Mia cheers")
H.click(H.button(tori, "👏") or H.button(tori, "Wave"), "Tori cheers")
E.runFor(0.3)
H.shot(mia, "13_showcase_vote")
H.shot(tori, "13_showcase_own")
H.shot(mia, "13_showcase_phone", 844, 390)
for i = 1, 3 do -- Tori, Mia and one Style Bot walk
	local heart = H.button(mia, "WOW")
	if heart then H.click(heart, "💖💖💖 vote") end
	E.runFor(9)
end
E.runFor(1)
print("== Results")
H.shot(tori, "14_results")
H.shot(tori, "14_results_phone", 844, 390)
local res = H.findText(tori, "Tori:")
print("  " .. (res and res.Text or "no result text"))
H.check(res ~= nil and string.find(res.Text, "show", 1, true) ~= nil, "judges loved the costume, pet and pose")
H.check(res ~= nil and not string.find(res.Text, "nan", 1, true), "NaN vote ignored")
E.runFor(5)
H.check(H.findText(tori, "⭐ Lv") ~= nil, "level pill shows progress")
print("  level:", H.findText(tori, "⭐ Lv") and H.findText(tori, "⭐ Lv").Text)

print("== Style Bots switch")
local waitedLobby = 0
while not H.button(tori, "Robot friends ✓") and waitedLobby < 30 do E.runFor(1); waitedLobby += 1 end
H.click(H.button(tori, "Robot friends ✓"), "turn Style Bots off")
E.runFor(1)
H.check(countBots() == 0 and H.button(tori, "Robot friends ✗") ~= nil, "the lobby switch sends the Style Bots home")
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
local waitedRound2 = 0
while not H.shown(H.ui(tori).Makeover) and waitedRound2 < 60 do E.runFor(1); waitedRound2 += 1 end
print("== Round 2: leave/rejoin")
H.check(H.shown(H.ui(tori).Makeover), "round 2 dressing room visible")
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
		H.click(H.tab(mia, "GoFace"), "Mia walks to the Makeup Vanity")
		E.runFor(0.2)
		H.click(H.button(mia, "Eyeshadow"), "Mia eyeshadow chip")
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
print("sounds:", counts.Click, counts.MakeoverMusic)
H.check((counts.Click or 0) > 3 and (counts.MakeoverMusic or 0) >= 1, "sounds play when IDs are set")
print("errors", #E.errors, "warnings", #E.warnings, "fails", H.fails)
for _, w in E.warnings do print("WARN", w) end
