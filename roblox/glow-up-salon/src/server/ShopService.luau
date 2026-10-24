-- Unlocking items with coins, plus Robux Game Passes and Developer Products.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.Catalog)
local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DataService = require(script.Parent.DataService)
local RoundService = require(script.Parent.RoundService)

local ShopService = {}

local MAX_RECEIPTS = 50

local function buyItem(player: Player, itemId: unknown): (boolean, string)
	if type(itemId) ~= "string" then
		return false, "That item doesn't exist."
	end
	local profile = DataService.get(player)
	local it = Catalog.byId[itemId]
	if not profile or not it or it.hidden or it.pass or it.price <= 0 then
		return false, "That item can't be bought with coins."
	end
	if profile.owned[it.id] then
		return true, "You already have " .. it.name .. "!"
	end
	if profile.coins < it.price then
		return false, "You need " .. (it.price - profile.coins) .. " more coins."
	end
	profile.coins -= it.price
	profile.owned[it.id] = true
	DataService.push(player)
	return true, "Unlocked " .. it.name .. "! ✨"
end

local function useSuperSoap(player: Player)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	if profile.superSoaps <= 0 then
		Remotes.Notify:FireClient(player, "You don't have any Super Soap yet.")
		return
	end
	if RoundService.applySuperSoap(player) then
		profile.superSoaps -= 1
		DataService.push(player)
	else
		Remotes.Notify:FireClient(player, "Super Soap works during a makeover on a dirty face!")
	end
end

local function productName(productId: number): string?
	for name, id in Config.DevProducts do
		if id ~= 0 and id == productId then
			return name
		end
	end
	return nil
end

local function processReceipt(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local profile = player and DataService.get(player)
	if not player or not profile then
		-- They left or their data isn't loaded yet; Roblox will try again next time they join.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if table.find(profile.receipts, receipt.PurchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local name = productName(receipt.ProductId)
	if name == "SuperSoap" then
		profile.superSoaps += 1
		Remotes.Notify:FireClient(player, "You got a Super Soap! 🧼✨")
		-- Use it right away if they're in the middle of washing
		if RoundService.applySuperSoap(player) then
			profile.superSoaps -= 1
		end
	elseif name and Config.CoinPackAmounts[name] then
		profile.coins += Config.CoinPackAmounts[name]
		Remotes.Notify:FireClient(player, "+" .. Config.CoinPackAmounts[name] .. " coins! 🪙")
	else
		warn("[GlowUp] Unknown product purchased:", receipt.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	table.insert(profile.receipts, receipt.PurchaseId)
	while #profile.receipts > MAX_RECEIPTS do
		table.remove(profile.receipts, 1)
	end
	DataService.push(player)

	-- Only confirm the purchase once it's safely saved (or saving is off in Studio).
	if profile.canSave and not DataService.save(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function ShopService.init()
	Remotes.BuyItem.OnServerInvoke = buyItem
	Remotes.UseSuperSoap.OnServerEvent:Connect(useSuperSoap)
	MarketplaceService.ProcessReceipt = processReceipt

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		local profile = DataService.get(player)
		if not profile then
			return
		end
		for name, id in Config.GamePasses do
			if id == passId then
				profile.passes[name] = true
				Remotes.Notify:FireClient(player, "Thank you! Your Game Pass is ready to use! 💖")
			end
		end
		DataService.push(player)
	end)
end

return ShopService
