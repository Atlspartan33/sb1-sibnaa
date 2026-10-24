-- The shop: unlock looks with coins you earn, or get Robux extras.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.Catalog)
local Clients = require(ReplicatedStorage.Shared.Clients)
local Config = require(ReplicatedStorage.Shared.Config)
local Events = require(ReplicatedStorage.Shared.Events)
local LookRenderer = require(ReplicatedStorage.Shared.LookRenderer)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Theme = require(script.Parent.Theme)

local C = Theme.Colors
local new = Theme.new

local Shop = {}
Shop.__index = Shop

local ROBUX_ITEMS = {
	{ kind = "pass", key = "VIP", icon = "👑", title = "VIP Glam Kit", text = "Rainbow & galaxy hair, Royal Updo, Mermaid Waves, Golden Gala Gown, crown and more - plus a VIP badge on the runway!" },
	{ kind = "pass", key = "Princess", icon = "👸", title = "Princess Pack", text = "Ice Ball Gown, Rose Gown, Princess Curls, Rose Gold hair, a tiara and pink gems!" },
	{ kind = "pass", key = "DoubleCoins", icon = "🪙", title = "2x Coins", text = "Earn double coins after every fashion show, forever." },
	{ kind = "pass", key = "RunwayStar", icon = "🌟", title = "Runway Star", text = "Confetti cannons and sparkles every time your client walks the runway!" },
	{ kind = "pass", key = "RainbowBubbles", icon = "🫧", title = "Rainbow Bubbles", text = "Washing makes rainbow-colored bubbles. Just for fun!" },
	{ kind = "product", key = "CoinsSmall", icon = "💰", title = "500 Coins", text = "Unlock new looks a little faster." },
}

local priceCache: { [string]: string } = {}

-- A model to show hairstyles, lashes, outfits and extras on in the shop
local SAMPLE_CLIENT = Clients.generate(Random.new(7))

function Shop.new(gui: ScreenGui, ctx)
	local self = setmetatable({}, Shop)
	self.ctx = ctx
	self.tab = "Coins"

	self.overlay = new("TextButton", {
		Name = "Shop",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.shadow,
		BackgroundTransparency = 0.45,
		Text = "",
		AutoButtonColor = false,
		Visible = false,
		ZIndex = 60,
		Parent = gui,
	})
	local panel = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.53),
		Size = UDim2.fromScale(0.7, 0.8),
		BackgroundColor3 = C.white,
		ZIndex = 61,
		Parent = self.overlay,
	}, { Theme.corner(26), Theme.stroke(C.purple, 5), Theme.padding(14) })
	self.panel = panel

	new("TextLabel", {
		Size = UDim2.new(1, -60, 0, 40),
		Text = "🛍️ Glow Up Shop",
		TextColor3 = C.purple,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 62,
		Parent = panel,
	}, { Theme.maxText(34) })
	local close = Theme.button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0, 44, 0, 44),
		Text = "✕",
		Color = C.red,
		ZIndex = 62,
		Parent = panel,
	})
	close.Activated:Connect(function()
		self:close()
	end)

	local tabs = new("Frame", {
		Position = UDim2.new(0, 0, 0, 50),
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		ZIndex = 62,
		Parent = panel,
	}, { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }) })
	self.tabButtons = {}
	for _, t in { { "Coins", "🪙 Unlock" }, { "Looks", "📖 My Looks" }, { "Robux", "💎 Extras" } } do
		local b = Theme.button({ Text = t[2], Size = UDim2.new(1 / 3, -6, 1, 0), ZIndex = 63, Parent = tabs })
		b.Activated:Connect(function()
			self.tab = t[1]
			self:render()
		end)
		self.tabButtons[t[1]] = b
	end

	self.list = new("ScrollingFrame", {
		Position = UDim2.new(0, 0, 0, 104),
		Size = UDim2.new(1, 0, 1, -104),
		BackgroundTransparency = 1,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = C.purple,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = 62,
		Parent = panel,
	}, { Theme.padding(6) })

	self:buildConfirm(gui)
	return self
end

------------------------------------------------------------------------------
-- Buying

function Shop:promptPass(key: string)
	local id = Config.GamePasses[key]
	if not id or id == 0 then
		self.ctx.toast("Coming soon! 💖")
		return
	end
	MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, id)
end

function Shop:promptProduct(key: string)
	local id = Config.DevProducts[key]
	if not id or id == 0 then
		self.ctx.toast("Coming soon! 💖")
		return
	end
	MarketplaceService:PromptProductPurchase(Players.LocalPlayer, id)
end

function Shop:buy(it: Catalog.Item)
	local called, ok, message = pcall(function()
		return Remotes.BuyItem:InvokeServer(it.id)
	end)
	if not called then
		self.ctx.toast("Oops! Try again in a moment.", C.red)
		return
	end
	self.ctx.toast(message, if ok then C.green else C.red)
end

function Shop:buildConfirm(gui: ScreenGui)
	self.confirm = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 380, 0, 190),
		BackgroundColor3 = C.white,
		Visible = false,
		ZIndex = 80,
		Parent = gui,
	}, { Theme.corner(22), Theme.stroke(C.hotPink, 5), Theme.padding(16) })
	self.confirmText = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 90),
		Text = "",
		ZIndex = 81,
		Parent = self.confirm,
	}, { Theme.maxText(26) })
	self.confirmYes = Theme.button({
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(0.48, 0, 0, 52),
		Text = "Yes!",
		Color = C.green,
		ZIndex = 82,
		Parent = self.confirm,
	})
	local no = Theme.button({
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(1, 1),
		Size = UDim2.new(0.48, 0, 0, 52),
		Text = "Not now",
		Color = C.textLight,
		ZIndex = 82,
		Parent = self.confirm,
	})
	no.Activated:Connect(function()
		self.confirm.Visible = false
	end)
	self.confirmYes.Activated:Connect(function()
		self.confirm.Visible = false
		if self.onConfirm then
			self.onConfirm()
		end
	end)
end

-- Asks before buying a Developer Product (like Super Soap), showing the Robux price.
function Shop:askProduct(key: string)
	local id = Config.DevProducts[key]
	if not id or id == 0 then
		self.ctx.toast("Coming soon! 💖")
		return
	end
	local entry
	for _, e in ROBUX_ITEMS do
		if e.key == key then
			entry = e
		end
	end
	local price = priceCache["product:" .. key]
	self.confirmText.Text = (entry and entry.icon .. " " .. entry.title or key) .. "\n" .. (entry and entry.text or "") .. (if price then "\n" .. price else "")
	self.confirmYes.Text = "Buy" .. (if price then " (" .. price .. ")" else "")
	self.onConfirm = function()
		self:promptProduct(key)
	end
	self.confirm.Visible = true
	Theme.pop(self.confirm)
	if not price and entry then
		self:fetchPrice(entry, "product:" .. key, self.confirmYes)
	end
end

-- Called when a player taps a locked item.
function Shop:askUnlock(it: Catalog.Item)
	if it.level then
		self.ctx.toast("⭐ " .. it.name .. " unlocks free at Level " .. it.level .. "! Keep styling!", C.green)
		return
	elseif it.pass then
		local packName = if it.pass == "VIP" then "👑 VIP Glam Kit" elseif it.pass == "Princess" then "👸 Princess Pack" else it.pass
		self.confirmText.Text = it.name .. " comes with the " .. packName .. ". Take a look?"
		self.confirmYes.Text = "Take a look"
		self.onConfirm = function()
			self:promptPass(it.pass :: string)
		end
	else
		local coins = self.ctx.profile.coins or 0
		if coins < it.price then
			self.ctx.toast("You need " .. (it.price - coins) .. " more coins for " .. it.name .. ". Win shows to earn more!", C.purple)
			return
		end
		self.confirmText.Text = "Unlock " .. it.name .. " for 🪙 " .. it.price .. "?"
		self.confirmYes.Text = "Unlock!"
		self.onConfirm = function()
			self:buy(it)
		end
	end
	self.confirm.Visible = true
	Theme.pop(self.confirm)
end

------------------------------------------------------------------------------
-- Shop window

function Shop:open()
	self.overlay.Visible = true
	Theme.pop(self.panel)
	self:render()
end

function Shop:close()
	self.overlay.Visible = false
end

function Shop:refreshProfile()
	if self.overlay.Visible then
		self:render()
	end
end

local function clear(frame: Instance)
	for _, child in frame:GetChildren() do
		if child:IsA("GuiObject") or child:IsA("UIGridLayout") or child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
end

function Shop:render()
	for id, b in self.tabButtons do
		b.BackgroundColor3 = if id == self.tab then C.purple else C.lavender
		b.TextColor3 = if id == self.tab then C.white else C.text
	end
	clear(self.list)
	if self.tab == "Coins" then
		self:renderCoinItems()
	elseif self.tab == "Looks" then
		self:renderLookBook()
	else
		self:renderRobuxItems()
	end
end

function Shop:renderCoinItems()
	-- Cell sizes in pixels: an aspect constraint inside a grid would shrink cells to nothing
	local width = self.list.AbsoluteSize.X - 12 - self.list.ScrollBarThickness
	local cols = if width >= 700 then 5 elseif width >= 480 then 4 else 3
	local gap = 10
	local cell = math.max(60, math.floor((width - gap * (cols - 1)) / cols))
	new("UIGridLayout", {
		CellSize = UDim2.fromOffset(cell, math.floor(cell * 1.3)),
		CellPadding = UDim2.fromOffset(gap, gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = self.list,
	})

	local order = 0
	local eventId = self.ctx.eventId()
	for _, category in Catalog.Categories do
		for _, it in category.items do
			if it.pass or it.level or it.price <= 0 or not Catalog.isAvailable(it, self.ctx.profile, eventId) then
				continue
			end
			order += 1
			local owned = Catalog.isUnlocked(it, self.ctx.profile, eventId)
			local card = new("Frame", {
				LayoutOrder = if it.event then order else order + 1000, -- holiday items first
				BackgroundColor3 = if owned then C.softPink else C.white,
				ZIndex = 63,
				Parent = self.list,
			}, { Theme.corner(14), Theme.stroke(C.lavender, 2) })
			local icon = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.06),
				Size = UDim2.fromScale(0.5, 0.5),
				BackgroundColor3 = C.lavender,
				ZIndex = 64,
				Parent = card,
			}, { new("UIAspectRatioConstraint", { AspectRatio = 1 }), Theme.round() })
			if category.preview == "portrait" then
				icon.BackgroundColor3 = C.softPink
				icon.ClipsDescendants = true
				local look = Catalog.defaultLook()
				look.hairStyle = "hair_bob"
				look.hairColor = "hc_blonde"
				look.outfit = "outfit_tee"
				look[category.key] = it.id
				LookRenderer.render(icon, SAMPLE_CLIENT, look, { headOnly = category.key ~= "outfit", clean = 1, mood = "smile" })
			elseif it.color then
				LookRenderer.paint(icon, it)
			end
			new("TextLabel", {
				Position = UDim2.fromScale(0.05, 0.4),
				Size = UDim2.fromScale(0.9, 0.3),
				Text = (if it.event and Events.byId[it.event] then Events.byId[it.event].icon .. " " else "") .. category.label .. "\n" .. it.name,
				ZIndex = 64,
				Parent = card,
			}, { Theme.maxText(16) })
			local b = Theme.button({
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -6),
				Size = UDim2.new(0.9, 0, 0.2, 0),
				Text = if owned then "Owned ✓" else "🪙 " .. it.price,
				Color = if owned then C.green else C.hotPink,
				ZIndex = 64,
				MaxText = 18,
				Parent = card,
			})
			if not owned then
				b.Activated:Connect(function()
					self:askUnlock(it)
				end)
			end
		end
	end
end

-- Every finished look is saved here, like a photo album.
function Shop:renderLookBook()
	local looks = self.ctx.profile.lookbook or {}
	if #looks == 0 then
		new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 120),
			Text = "📖 Your Look Book is empty.\nFinish a fashion show and your look gets saved here!",
			ZIndex = 63,
			Parent = self.list,
		}, { Theme.maxText(26) })
		return
	end
	local width = self.list.AbsoluteSize.X - 12 - self.list.ScrollBarThickness
	local cols = if width >= 700 then 4 elseif width >= 420 then 3 else 2
	local gap = 10
	local cell = math.max(80, math.floor((width - gap * (cols - 1)) / cols))
	new("UIGridLayout", {
		CellSize = UDim2.fromOffset(cell, math.floor(cell * 1.3)),
		CellPadding = UDim2.fromOffset(gap, gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = self.list,
	})
	for i, saved in looks do
		local skin, eyes = Clients.colors(saved.skin or 1, saved.eyes or 1)
		local client = { name = saved.name, skin = skin, eyes = eyes, dirt = {} }
		local theme = Catalog.themeById[saved.theme]
		local card = new("Frame", {
			LayoutOrder = i,
			BackgroundColor3 = if theme then theme.color:Lerp(C.white, 0.7) else C.softPink,
			ZIndex = 63,
			Parent = self.list,
		}, { Theme.corner(16), Theme.stroke(C.gold, 3) })
		local pic = new("Frame", {
			Position = UDim2.fromScale(0.05, 0.04),
			Size = UDim2.fromScale(0.9, 0.7),
			BackgroundColor3 = C.white,
			ZIndex = 64,
			Parent = card,
		}, { Theme.corner(12) })
		LookRenderer.render(pic, client, saved.look, { clean = 1, mood = if (saved.stars or 0) >= 4 then "grin" else "smile" })
		new("TextLabel", {
			Position = UDim2.fromScale(0.04, 0.75),
			Size = UDim2.fromScale(0.92, 0.12),
			Text = saved.name .. "  " .. Theme.stars(saved.stars or 1),
			ZIndex = 64,
			Parent = card,
		}, { Theme.maxText(18) })
		new("TextLabel", {
			Position = UDim2.fromScale(0.04, 0.87),
			Size = UDim2.fromScale(0.92, 0.11),
			Text = theme and theme.name or "",
			TextColor3 = C.textLight,
			ZIndex = 64,
			Parent = card,
		}, { Theme.maxText(16) })
	end
end

function Shop:renderRobuxItems()
	new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.list })
	for i, entry in ROBUX_ITEMS do
		local owned = entry.kind == "pass" and self.ctx.profile.passes and self.ctx.profile.passes[entry.key]
		local card = new("Frame", {
			LayoutOrder = i,
			Size = UDim2.new(1, -8, 0, 90),
			BackgroundColor3 = if entry.kind == "pass" then C.lavender else C.softPink,
			ZIndex = 63,
			Parent = self.list,
		}, { Theme.corner(16) })
		new("TextLabel", { Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(0, 70, 1, 0), Text = entry.icon, ZIndex = 64, Parent = card }, { Theme.maxText(48) })
		new("TextLabel", {
			Position = UDim2.new(0, 84, 0, 6),
			Size = UDim2.new(1, -250, 0, 30),
			Text = entry.title,
			TextColor3 = C.purple,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 64,
			Parent = card,
		}, { Theme.maxText(26) })
		new("TextLabel", {
			Position = UDim2.new(0, 84, 0, 38),
			Size = UDim2.new(1, -250, 0, 46),
			Text = entry.text,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = C.textLight,
			ZIndex = 64,
			Parent = card,
		}, { Theme.maxText(17) })

		local key = entry.kind .. ":" .. entry.key
		local b = Theme.button({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.new(0, 150, 0, 52),
			Text = if owned then "Owned ✓" else (priceCache[key] or "Buy"),
			Color = if owned then C.green else C.hotPink,
			ZIndex = 64,
			Parent = card,
		})
		if not owned then
			b.Activated:Connect(function()
				if entry.kind == "pass" then
					self:promptPass(entry.key)
				else
					self:promptProduct(entry.key)
				end
			end)
			if not priceCache[key] then
				self:fetchPrice(entry, key, b)
			end
		end
	end
end

function Shop:fetchPrice(entry, key: string, button: TextButton)
	local id = if entry.kind == "pass" then Config.GamePasses[entry.key] else Config.DevProducts[entry.key]
	if not id or id == 0 then
		button.Text = "Soon!"
		return
	end
	task.spawn(function()
		local infoType = if entry.kind == "pass" then Enum.InfoType.GamePass else Enum.InfoType.Product
		local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id, infoType)
		if ok and info and info.PriceInRobux then
			priceCache[key] = "R$ " .. info.PriceInRobux
			if button.Parent then
				button.Text = priceCache[key]
			end
		end
	end)
end

return Shop
