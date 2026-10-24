-- The makeover screen: wash the client's face, then do their hair, makeup, outfit and extras.

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Catalog = require(ReplicatedStorage.Shared.Catalog)
local LookRenderer = require(ReplicatedStorage.Shared.LookRenderer)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Theme = require(script.Parent.Theme)

local C = Theme.Colors
local new = Theme.new

local Makeover = {}
Makeover.__index = Makeover

local MAKEUP_KEYS = { "eyeshadow", "lashes", "blush", "lipstick" }
local MAX_BUBBLES = 40
local SEND_INTERVAL = 0.25

local function screenPosition(input: InputObject): Vector2
	local inset = GuiService:GetGuiInset()
	return Vector2.new(input.Position.X, input.Position.Y) + inset
end

function Makeover.new(gui: ScreenGui, ctx)
	local self = setmetatable({}, Makeover)
	self.ctx = ctx
	self.client = nil
	self.look = Catalog.defaultLook()
	self.dirtHealth = {}
	self.bubbles = {}
	self.tool = "soap"
	self.tab = "Wash"
	self.subcategory = {} -- tab id -> selected category key
	self.done = false
	self.scrubbing = false
	self.lastSent = 0
	self.wasClean = false

	self.frame = new("Frame", {
		Name = "Makeover",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.white,
		Visible = false,
		ZIndex = 10,
		Parent = gui,
	}, { Theme.gradient(C.softPink, C.lavender, 45) })

	self:buildLeft()
	self:buildRight()
	self:connectInput()
	return self
end

------------------------------------------------------------------------------
-- Layout

function Makeover:buildLeft()
	local left = new("Frame", {
		Position = UDim2.new(0.02, 0, 0, 62),
		Size = UDim2.new(0.42, 0, 1, -74),
		BackgroundColor3 = C.white,
		ZIndex = 11,
		Parent = self.frame,
	}, { Theme.corner(24), Theme.stroke(C.pink, 4), Theme.padding(12) })

	self.nameLabel = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 34),
		Text = "",
		TextColor3 = C.hotPink,
		ZIndex = 12,
		Parent = left,
	}, { Theme.maxText(32) })
	self.storyLabel = new("TextLabel", {
		Position = UDim2.new(0, 0, 0, 36),
		Size = UDim2.new(1, 0, 0, 40),
		Text = "",
		TextColor3 = C.textLight,
		ZIndex = 12,
		Parent = left,
	}, { Theme.maxText(18) })

	self.portraitHolder = new("Frame", {
		Name = "PortraitHolder",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 80),
		Size = UDim2.new(1, 0, 1, -130),
		BackgroundColor3 = Color3.fromRGB(255, 245, 250),
		ZIndex = 12,
		Parent = left,
	}, {
		new("UIAspectRatioConstraint", { AspectRatio = 1 }),
		Theme.corner(24),
		Theme.gradient(Color3.fromRGB(255, 250, 253), Color3.fromRGB(255, 225, 240)),
	})
	self.bubbleLayer = new("Frame", {
		Name = "Bubbles",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 100,
		Parent = self.portraitHolder,
	})

	self.cursor = new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0, 56, 0, 56),
		Text = "🧽",
		Visible = false,
		ZIndex = 200,
		Parent = self.frame,
	})

	local checklist = new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		ZIndex = 12,
		Parent = left,
	}, {
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 6),
		}),
	})
	self.checks = {}
	for _, step in { { "Wash", "🧼" }, { "Hair", "💇" }, { "Makeup", "💄" }, { "Outfit", "👗" } } do
		self.checks[step[1]] = new("TextLabel", {
			Size = UDim2.new(0.24, 0, 1, 0),
			BackgroundTransparency = 0,
			BackgroundColor3 = C.lavender,
			Text = step[2] .. " " .. step[1],
			ZIndex = 13,
			Parent = checklist,
		}, { Theme.round(), Theme.maxText(18), Theme.padding(5) })
	end
end

function Makeover:buildRight()
	local right = new("Frame", {
		Position = UDim2.new(0.46, 0, 0, 62),
		Size = UDim2.new(0.52, 0, 1, -74),
		BackgroundColor3 = C.white,
		ZIndex = 11,
		Parent = self.frame,
	}, { Theme.corner(24), Theme.stroke(C.purple, 4), Theme.padding(12) })
	self.right = right

	local tabs = new("Frame", {
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundTransparency = 1,
		ZIndex = 12,
		Parent = right,
	}, {
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 6),
		}),
	})
	self.tabButtons = {}
	for _, tab in Catalog.Tabs do
		local b = Theme.button({
			Text = tab.icon .. " " .. tab.label,
			Size = UDim2.new(0.19, -5, 1, 0),
			Color = C.lavender,
			TextColor3 = C.text,
			ZIndex = 13,
			MaxText = 22,
			Parent = tabs,
		})
		b.Activated:Connect(function()
			self:setTab(tab.id)
		end)
		self.tabButtons[tab.id] = b
	end

	self.chips = new("Frame", {
		Position = UDim2.new(0, 0, 0, 56),
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		ZIndex = 12,
		Parent = right,
	}, {
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 6),
		}),
	})

	self.grid = new("ScrollingFrame", {
		Position = UDim2.new(0, 0, 0, 98),
		Size = UDim2.new(1, 0, 1, -164),
		BackgroundTransparency = 1,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = C.pink,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = 12,
		Parent = right,
	}, { Theme.padding(6) })
	new("UIGridLayout", {
		CellSize = UDim2.new(0.235, 0, 0, 0),
		CellPadding = UDim2.new(0.02, 0, 0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = self.grid,
	}, { new("UIAspectRatioConstraint", { AspectRatio = 0.8 }) })

	self:buildWashPanel(right)

	self.doneButton = Theme.button({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.new(0.6, 0, 0, 54),
		Text = "I'm Done! ✨",
		Color = C.hotPink,
		ZIndex = 13,
		MaxText = 30,
		Parent = right,
	})
	self.doneButton.Activated:Connect(function()
		self:setDone(not self.done)
	end)

	self.waiting = new("TextLabel", {
		Position = UDim2.new(0, 0, 0, 56),
		Size = UDim2.new(1, 0, 1, -122),
		BackgroundColor3 = C.white,
		BackgroundTransparency = 0.1,
		Text = "Looking fabulous! 💅\nWaiting for the other stylists to finish...",
		TextColor3 = C.purple,
		Visible = false,
		ZIndex = 30,
		Parent = right,
	}, { Theme.corner(18), Theme.maxText(30), Theme.padding(20) })
end

function Makeover:buildWashPanel(parent: GuiObject)
	local panel = new("Frame", {
		Position = UDim2.new(0, 0, 0, 56),
		Size = UDim2.new(1, 0, 1, -122),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 12,
		Parent = parent,
	}, {
		new("UIListLayout", {
			Padding = UDim.new(0, 10),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	self.washPanel = panel

	self.washHint = new("TextLabel", {
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 60),
		Text = "",
		ZIndex = 13,
		Parent = panel,
	}, { Theme.maxText(24) })

	local tools = new("Frame", {
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, 90),
		BackgroundTransparency = 1,
		ZIndex = 13,
		Parent = panel,
	}, {
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 14),
		}),
	})
	self.toolButtons = {}
	for _, tool in { { id = "soap", text = "🧽 Soap" }, { id = "rinse", text = "🚿 Rinse" } } do
		local b = Theme.button({
			Text = tool.text,
			Size = UDim2.new(0.4, 0, 1, 0),
			Color = C.lavender,
			TextColor3 = C.text,
			ZIndex = 14,
			MaxText = 34,
			Parent = tools,
		})
		b.Activated:Connect(function()
			self.tool = tool.id
			self:refreshWash()
		end)
		self.toolButtons[tool.id] = b
	end

	local bar = new("Frame", {
		LayoutOrder = 3,
		Size = UDim2.new(0.85, 0, 0, 34),
		BackgroundColor3 = C.lavender,
		ZIndex = 13,
		Parent = panel,
	}, { Theme.round() })
	self.cleanFill = new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = C.green,
		ZIndex = 14,
		Parent = bar,
	}, { Theme.round() })
	self.cleanText = new("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		Text = "",
		ZIndex = 15,
		Parent = bar,
	}, { Theme.maxText(20), Theme.padding(4) })

	self.soapButton = Theme.button({
		LayoutOrder = 4,
		Size = UDim2.new(0.7, 0, 0, 50),
		Text = "",
		Color = C.purple,
		ZIndex = 14,
		MaxText = 24,
		Parent = panel,
	})
	self.soapButton.Activated:Connect(function()
		if (self.ctx.profile.superSoaps or 0) > 0 then
			Remotes.UseSuperSoap:FireServer()
		else
			self.ctx.promptProduct("SuperSoap")
		end
	end)
end

------------------------------------------------------------------------------
-- State

function Makeover:assign(payload)
	self.client = payload.client
	self.look = payload.look
	self.done = payload.done == true
	self.dirtHealth = {}
	local n = #self.client.dirt
	local cleaned = math.floor((payload.clean or 0) * n + 0.5)
	for i = 1, n do
		self.dirtHealth[i] = if i <= cleaned then 0 else 1
	end
	self:clearBubbles()
	self.wasClean = false
	self.tool = "soap"
	self.tab = "Wash"
	self.nameLabel.Text = "Meet " .. self.client.name .. "!"
	self.storyLabel.Text = self.client.name .. " " .. self.client.story
	self:setDone(self.done, true)
	self:renderPortrait()
	self:setTab("Wash")
end

function Makeover:setVisible(visible: boolean)
	self.frame.Visible = visible and self.client ~= nil
	if not self.frame.Visible then
		self.cursor.Visible = false
		self.scrubbing = false
	end
end

function Makeover:setDone(done: boolean, silent: boolean?)
	self.done = done
	self.waiting.Visible = done
	self.doneButton.Text = if done then "Keep Styling ✏️" else "I'm Done! ✨"
	self.doneButton.BackgroundColor3 = if done then C.purple else C.hotPink
	if not silent then
		Remotes.Done:FireServer(done)
	end
end

function Makeover:cleanAmount(): number
	local n = #self.dirtHealth
	if n == 0 then
		return 1
	end
	local left = 0
	for _, h in self.dirtHealth do
		left += h
	end
	return 1 - left / n
end

function Makeover:isWashed(): boolean
	return self:cleanAmount() >= 0.98 and #self.bubbles == 0
end

function Makeover:renderPortrait()
	if not self.client then
		return
	end
	self.portraitRoot = LookRenderer.render(self.portraitHolder, self.client, self.look, { dirtHealth = self.dirtHealth })
	self.dirtFrames = {}
	for i = 1, #self.client.dirt do
		self.dirtFrames[i] = self.portraitRoot:FindFirstChild("Dirt" .. i)
	end
	self:refreshChecklist()
end

function Makeover:refreshChecklist()
	local makeupCount = 0
	for _, key in MAKEUP_KEYS do
		if not Catalog.isNone(self.look[key]) then
			makeupCount += 1
		end
	end
	local done = {
		Wash = self:isWashed(),
		Hair = not Catalog.isNone(self.look.hairStyle),
		Makeup = makeupCount >= 2,
		Outfit = not Catalog.isNone(self.look.outfit),
	}
	for step, label in self.checks do
		label.BackgroundColor3 = if done[step] then C.green else C.lavender
		label.TextColor3 = if done[step] then C.white else C.text
	end
end

function Makeover:setTab(tabId: string)
	self.tab = tabId
	for id, b in self.tabButtons do
		local active = id == tabId
		b.BackgroundColor3 = if active then C.pink else C.lavender
		b.TextColor3 = if active then C.white else C.text
	end
	local isWash = tabId == "Wash"
	self.washPanel.Visible = isWash
	self.grid.Visible = not isWash
	self.chips.Visible = not isWash

	if isWash then
		self:refreshWash()
		return
	end

	local categories = {}
	for _, category in Catalog.Categories do
		if category.tab == tabId then
			table.insert(categories, category)
		end
	end
	if not self.subcategory[tabId] then
		self.subcategory[tabId] = categories[1].key
	end

	for _, child in self.chips:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	for _, category in categories do
		local active = self.subcategory[tabId] == category.key
		local chip = Theme.button({
			Text = category.label,
			Size = UDim2.new(math.min(0.32, 1 / #categories), -6, 1, 0),
			Color = if active then C.purple else C.lavender,
			TextColor3 = if active then C.white else C.text,
			ZIndex = 13,
			MaxText = 20,
			Parent = self.chips,
		})
		chip.Activated:Connect(function()
			self.subcategory[tabId] = category.key
			self:setTab(tabId)
		end)
	end
	self:renderGrid()
end

------------------------------------------------------------------------------
-- Item grid

function Makeover:renderGrid()
	if self.tab == "Wash" or not self.client then
		return
	end
	local key = self.subcategory[self.tab]
	local category = Catalog.categoryByKey[key]
	for _, child in self.grid:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	local order = 0
	for _, it in category.items do
		if it.hidden then
			continue
		end
		order += 1
		local selected = self.look[key] == it.id
		local unlocked = Catalog.isUnlocked(it, self.ctx.profile)

		local card = new("TextButton", {
			LayoutOrder = order,
			Text = "",
			BackgroundTransparency = 0,
			BackgroundColor3 = if selected then C.softPink else C.white,
			AutoButtonColor = true,
			ZIndex = 13,
			Parent = self.grid,
		}, {
			Theme.corner(16),
			Theme.stroke(if selected then C.hotPink else C.lavender, if selected then 4 else 2),
		})

		local preview = new("Frame", {
			Position = UDim2.fromScale(0.05, 0.04),
			Size = UDim2.fromScale(0.9, 0.7),
			BackgroundTransparency = 1,
			ZIndex = 14,
			Parent = card,
		})
		if category.preview == "portrait" then
			local previewLook = table.clone(self.look)
			previewLook[key] = it.id
			LookRenderer.render(preview, self.client, previewLook, { headOnly = key ~= "outfit", clean = 1 })
		elseif it.color then
			local dot = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.75, 0.75),
				ZIndex = 15,
				Parent = preview,
			}, { new("UIAspectRatioConstraint", { AspectRatio = 1 }), Theme.round(), Theme.stroke(C.white, 3) })
			LookRenderer.paint(dot, it)
		else
			new("TextLabel", { Size = UDim2.fromScale(1, 1), Text = "🚫", ZIndex = 15, Parent = preview })
		end

		new("TextLabel", {
			Position = UDim2.fromScale(0.05, 0.76),
			Size = UDim2.fromScale(0.9, 0.2),
			Text = it.name,
			ZIndex = 15,
			Parent = card,
		}, { Theme.maxText(18) })

		if not unlocked then
			new("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = C.white,
				BackgroundTransparency = 0.45,
				ZIndex = 16,
				Parent = card,
			}, { Theme.corner(16) })
			new("TextLabel", {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -4, 0, 4),
				Size = UDim2.fromScale(0.6, 0.17),
				BackgroundTransparency = 0,
				BackgroundColor3 = if it.pass then C.gold else C.purple,
				TextColor3 = C.white,
				Text = if it.pass then "👑 VIP" else "🔒 " .. it.price,
				ZIndex = 17,
				Parent = card,
			}, { Theme.round(), Theme.padding(3) })
		elseif selected then
			new("TextLabel", {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -4, 0, 4),
				Size = UDim2.fromScale(0.22, 0.17),
				BackgroundTransparency = 0,
				BackgroundColor3 = C.hotPink,
				TextColor3 = C.white,
				Text = "✓",
				ZIndex = 17,
				Parent = card,
			}, { Theme.round() })
		end

		card.Activated:Connect(function()
			if unlocked then
				self:choose(key, it.id)
			else
				self.ctx.askUnlock(it)
			end
		end)
	end
end

function Makeover:choose(key: string, itemId: string)
	if self.done then
		self:setDone(false)
	end
	self.look[key] = itemId
	Remotes.UpdateLook:FireServer(key, itemId)
	self:renderPortrait()
	self:renderGrid()
end

-- Re-draw locks after coins/unlocks change.
function Makeover:refreshProfile()
	if self.frame.Visible then
		if self.tab == "Wash" then
			self:refreshWash()
		else
			self:renderGrid()
		end
	end
end

------------------------------------------------------------------------------
-- Washing

function Makeover:refreshWash()
	local clean = self:cleanAmount()
	local bubbles = #self.bubbles
	if clean < 0.98 then
		self.washHint.Text = "Pick the 🧽 Soap, then hold and rub the dirty spots on " .. (self.client and self.client.name or "their") .. "'s face!"
	elseif bubbles > 0 then
		self.washHint.Text = "Now pick 🚿 Rinse and rub away all the soap bubbles!"
	else
		self.washHint.Text = "Sparkling clean! ✨ Head to the Hair tab next."
	end
	for id, b in self.toolButtons do
		local active = id == self.tool
		b.BackgroundColor3 = if active then C.pink else C.lavender
		b.TextColor3 = if active then C.white else C.text
	end
	self.cleanFill.Size = UDim2.fromScale(math.clamp(clean, 0, 1), 1)
	self.cleanText.Text = "Clean: " .. math.floor(clean * 100 + 0.5) .. "%" .. (if bubbles > 0 then "  🫧 " .. bubbles else "")
	local soaps = self.ctx.profile.superSoaps or 0
	self.soapButton.Text = if soaps > 0 then "✨ Use Super Soap (" .. soaps .. ")" else "✨ Get Super Soap (instant clean)"
	self.soapButton.Visible = not self:isWashed()
	self:refreshChecklist()
end

function Makeover:clearBubbles()
	for _, b in self.bubbles do
		b.frame:Destroy()
	end
	table.clear(self.bubbles)
end

function Makeover:sendWash(force: boolean?)
	if force or os.clock() - self.lastSent > SEND_INTERVAL then
		self.lastSent = os.clock()
		Remotes.WashProgress:FireServer(self:cleanAmount(), #self.bubbles == 0)
	end
	local washed = self:isWashed()
	if washed and not self.wasClean then
		self.ctx.toast("Sparkling clean! ✨", C.green)
	end
	self.wasClean = washed
end

function Makeover:addBubble(rel: Vector2)
	if #self.bubbles >= MAX_BUBBLES then
		return
	end
	local size = 0.05 + math.random() * 0.05
	local frame = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(rel.X, rel.Y),
		Size = UDim2.fromScale(size, size),
		BackgroundColor3 = C.white,
		BackgroundTransparency = 0.25,
		ZIndex = 101,
		Parent = self.bubbleLayer,
	}, { Theme.round(), Theme.stroke(Color3.fromRGB(180, 220, 255), 2) })
	table.insert(self.bubbles, { frame = frame, pos = rel, size = size })
end

function Makeover:scrub(pos: Vector2, moved: number)
	local root = self.portraitRoot
	if not root or not self.client then
		return
	end
	local size = root.AbsoluteSize.X
	local origin = root.AbsolutePosition
	if size <= 0 then
		return
	end
	local rel = (pos - origin) / size
	if rel.X < 0 or rel.X > 1 or rel.Y < 0 or rel.Y > 1 then
		return
	end
	local brush = 0.06
	local changed = false

	if self.tool == "soap" then
		for i, spot in self.client.dirt do
			local h = self.dirtHealth[i]
			if h > 0 and (rel - Vector2.new(spot.x, spot.y)).Magnitude < spot.size / 2 + brush then
				self.dirtHealth[i] = math.max(0, h - moved / (size * 0.45))
				local f = self.dirtFrames[i]
				if f then
					LookRenderer.setDirtHealth(f, self.dirtHealth[i])
				end
				changed = true
			end
		end
		self.bubbleTravel = (self.bubbleTravel or 0) + moved
		if self.bubbleTravel > size * 0.05 then
			self.bubbleTravel = 0
			self:addBubble(rel)
			changed = true
		end
	else
		for i = #self.bubbles, 1, -1 do
			local b = self.bubbles[i]
			if (rel - b.pos).Magnitude < b.size / 2 + brush then
				b.frame:Destroy()
				table.remove(self.bubbles, i)
				changed = true
			end
		end
	end

	if changed then
		self:refreshWash()
		self:sendWash()
	end
end

function Makeover:superSoap()
	for i = 1, #self.dirtHealth do
		self.dirtHealth[i] = 0
	end
	self:clearBubbles()
	self:renderPortrait()
	self:refreshWash()
	self:sendWash(true)
end

function Makeover:connectInput()
	local lastPos: Vector2? = nil

	UserInputService.InputBegan:Connect(function(input)
		if self.tab ~= "Wash" or not self.frame.Visible or self.ctx.isModalOpen() then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local pos = screenPosition(input)
			if self:isOverPortrait(pos) then
				self.scrubbing = true
				lastPos = pos
				self:moveCursor(pos)
			end
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		local isMove = input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
		if not isMove or not self.frame.Visible then
			return
		end
		local pos = screenPosition(input)
		self:moveCursor(pos)
		if self.scrubbing and self.tab == "Wash" then
			local moved = if lastPos then (pos - lastPos).Magnitude else 0
			lastPos = pos
			if moved > 0 then
				self:scrub(pos, moved)
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if self.scrubbing then
				self.scrubbing = false
				lastPos = nil
				self:sendWash(true)
			end
			if input.UserInputType == Enum.UserInputType.Touch then
				self.cursor.Visible = false
			end
		end
	end)
end

function Makeover:isOverPortrait(pos: Vector2): boolean
	local holder = self.portraitHolder
	local a, s = holder.AbsolutePosition, holder.AbsoluteSize
	return pos.X >= a.X and pos.X <= a.X + s.X and pos.Y >= a.Y and pos.Y <= a.Y + s.Y
end

function Makeover:moveCursor(pos: Vector2)
	self.cursor.Visible = self:isOverPortrait(pos) and self.tab == "Wash" and self.frame.Visible
	self.cursor.Text = if self.tool == "soap" then "🧽" else "🚿"
	local f = self.frame.AbsolutePosition
	self.cursor.Position = UDim2.fromOffset(pos.X - f.X, pos.Y - f.Y)
end

return Makeover
