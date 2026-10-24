-- The makeover screen: wash the client's face, then do their hair, makeup, outfit and extras.
-- The client reacts as you go: they talk, smile more, and fill up their happy hearts.

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Catalog = require(ReplicatedStorage.Shared.Catalog)
local LookRenderer = require(ReplicatedStorage.Shared.LookRenderer)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Scoring = require(ReplicatedStorage.Shared.Scoring)
local Effects = require(script.Parent.Effects)
local Sounds = require(script.Parent.Sounds)
local Theme = require(script.Parent.Theme)

local C = Theme.Colors
local new = Theme.new

local Makeover = {}
Makeover.__index = Makeover

local STEPS = { { "Wash", "🧼" }, { "Hair", "💇" }, { "Makeup", "💄" }, { "Outfit", "👗" } }
local MAKEUP_KEYS = { "eyeshadow", "lashes", "blush", "lipstick" }
local MAX_BUBBLES = 24
local SEND_INTERVAL = 0.25

local WASH_LINES = { "That tickles! 😆", "Scrub scrub! 🧽", "Ooh, bubbles!", "Keep going! 💪", "I can see my face again!" }
local LIKE_LINES = { "Ooh, cute! 💕", "I like it!", "So pretty! ✨", "Ooh la la!", "Wow!" }
local THEME_LINES = { "Perfect for %s! 😍", "So %s! I love it!", "That's so %s! 💖" }
local NONE_LINES = { "Hmm, okay!", "Plain is nice too!", "Let's try something else!" }

local function pick(list: { string }): string
	return list[math.random(1, #list)]
end

local function screenPosition(input: InputObject): Vector2
	local inset = GuiService:GetGuiInset()
	return Vector2.new(input.Position.X, input.Position.Y) + inset
end

local function themeWord(theme: Catalog.Theme): string
	-- "Pink Party 🎀" -> "Pink Party"
	return (string.gsub(theme.name, "%s*[^%w%s']+$", ""))
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
	self.hearts = 0
	self.bestShown = false

	self.frame = new("Frame", {
		Name = "Makeover",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.white,
		Active = true, -- touches here are for styling, not for moving the character
		Visible = false,
		ZIndex = 10,
		Parent = gui,
	}, { Theme.gradient(C.softPink, C.lavender, 45) })

	self:buildLeft()
	self:buildRight()
	self:connectInput()
	self:startAnimations()
	return self
end

------------------------------------------------------------------------------
-- Layout (all in scale so it fits phones, tablets and computers)

function Makeover:buildLeft()
	local left = new("Frame", {
		Position = UDim2.new(0.015, 0, 0, 62),
		Size = UDim2.new(0.43, 0, 1, -70),
		BackgroundColor3 = C.white,
		ZIndex = 11,
		Parent = self.frame,
	}, { Theme.corner(24), Theme.stroke(C.pink, 4), Theme.padding(10) })
	self.left = left

	self.portraitHolder = new("Frame", {
		Name = "PortraitHolder",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.135),
		Size = UDim2.fromScale(1, 0.66),
		BackgroundColor3 = Color3.fromRGB(255, 245, 250),
		ZIndex = 12,
		Parent = left,
	}, {
		new("UIAspectRatioConstraint", { AspectRatio = 1 }),
		Theme.corner(24),
		Theme.gradient(Color3.fromRGB(255, 250, 253), Color3.fromRGB(255, 220, 238)),
	})
	self.bubbleLayer = new("Frame", {
		Name = "Bubbles",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 100,
		Parent = self.portraitHolder,
	})
	self.nameTag = new("TextLabel", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0.03, 0.97),
		Size = UDim2.fromScale(0.42, 0.1),
		BackgroundTransparency = 0,
		BackgroundColor3 = C.hotPink,
		TextColor3 = C.white,
		Text = "",
		ZIndex = 110,
		Parent = self.portraitHolder,
	}, { Theme.round(), Theme.padding(4) })

	-- What the client says
	self.speech = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromScale(0.94, 0.115),
		BackgroundColor3 = C.white,
		Visible = false,
		ZIndex = 150,
		Parent = left,
	}, { Theme.corner(18), Theme.stroke(C.purple, 3) })
	new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.fromScale(0.05, 0.3),
		BackgroundColor3 = C.white,
		Rotation = 45,
		ZIndex = 150,
		Parent = self.speech,
	}, { new("UIAspectRatioConstraint", { AspectRatio = 1 }) })
	self.speechText = new("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		Text = "",
		ZIndex = 152,
		Parent = self.speech,
	}, { Theme.maxText(24), Theme.padding(6) })

	self.cursor = new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0, 56, 0, 56),
		Text = "🧽",
		Visible = false,
		ZIndex = 200,
		Parent = self.frame,
	})

	self.heartsLabel = new("TextLabel", {
		Position = UDim2.fromScale(0, 0.8),
		Size = UDim2.fromScale(1, 0.085),
		Text = "",
		ZIndex = 12,
		Parent = left,
	}, { Theme.maxText(30) })

	local checklist = new("Frame", {
		Position = UDim2.fromScale(0, 0.895),
		Size = UDim2.fromScale(1, 0.105),
		BackgroundTransparency = 1,
		ZIndex = 12,
		Parent = left,
	}, {
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0.015, 0),
		}),
	})
	self.checks = {}
	for _, step in STEPS do
		local chip = new("TextButton", {
			Size = UDim2.fromScale(0.235, 1),
			BackgroundTransparency = 0,
			BackgroundColor3 = C.lavender,
			Text = step[2] .. " " .. step[1],
			AutoButtonColor = true,
			ZIndex = 13,
			Parent = checklist,
		}, { Theme.round(), Theme.maxText(20), Theme.padding(4) })
		chip.Activated:Connect(function()
			self:setTab(step[1])
		end)
		self.checks[step[1]] = chip
	end
end

function Makeover:buildRight()
	local right = new("Frame", {
		Position = UDim2.new(0.46, 0, 0, 62),
		Size = UDim2.new(0.525, 0, 1, -70),
		BackgroundColor3 = C.white,
		ZIndex = 11,
		Parent = self.frame,
	}, { Theme.corner(24), Theme.stroke(C.purple, 4), Theme.padding(10) })
	self.right = right

	self.themeBar = new("TextLabel", {
		Size = UDim2.fromScale(1, 0.075),
		BackgroundTransparency = 0,
		BackgroundColor3 = C.softPink,
		Text = "",
		ZIndex = 12,
		Parent = right,
	}, { Theme.round(), Theme.maxText(22), Theme.padding(3) })

	local tabs = new("Frame", {
		Position = UDim2.fromScale(0, 0.09),
		Size = UDim2.fromScale(1, 0.135),
		BackgroundTransparency = 1,
		ZIndex = 12,
		Parent = right,
	}, {
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0.012, 0),
		}),
	})
	self.tabButtons = {}
	self.tabStrokes = {}
	for _, tab in Catalog.Tabs do
		local b = Theme.button({
			Text = "",
			Size = UDim2.fromScale(0.19, 1),
			Color = C.lavender,
			ZIndex = 13,
			Parent = tabs,
		})
		b.Name = tab.id
		new("TextLabel", { Name = "Icon", Size = UDim2.fromScale(1, 0.62), Text = tab.icon, ZIndex = 14, Parent = b }, { Theme.maxText(40) })
		new("TextLabel", {
			Name = "Label",
			Position = UDim2.fromScale(0, 0.6),
			Size = UDim2.fromScale(1, 0.38),
			Text = tab.label,
			ZIndex = 14,
			Parent = b,
		}, { Theme.maxText(20) })
		self.tabStrokes[tab.id] = Theme.new("UIStroke", {
			Color = C.gold,
			Thickness = 4,
			Transparency = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = b,
		})
		b.Activated:Connect(function()
			self:setTab(tab.id)
		end)
		self.tabButtons[tab.id] = b
	end

	self.chips = new("Frame", {
		Position = UDim2.fromScale(0, 0.24),
		Size = UDim2.fromScale(1, 0.075),
		BackgroundTransparency = 1,
		ZIndex = 12,
		Parent = right,
	}, {
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0.012, 0),
		}),
	})

	self.grid = new("ScrollingFrame", {
		Position = UDim2.fromScale(0, 0.33),
		Size = UDim2.fromScale(1, 0.52),
		BackgroundTransparency = 1,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = C.pink,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = 12,
		Parent = right,
	}, { Theme.padding(4) })
	self.gridLayout = new("UIGridLayout", {
		CellSize = UDim2.fromOffset(100, 112),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = self.grid,
	})
	self.grid:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if self.frame.Visible and self.tab ~= "Wash" then
			self:renderGrid()
		end
	end)

	self:buildWashPanel(right)

	self.doneButton = Theme.button({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.fromScale(0.6, 0.12),
		Text = "I'm Done! ✨",
		Color = C.hotPink,
		ZIndex = 13,
		MaxText = 32,
		Parent = right,
	})
	self.doneStroke = Theme.new("UIStroke", {
		Color = C.gold,
		Thickness = 4,
		Transparency = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = self.doneButton,
	})
	self.doneButton.Activated:Connect(function()
		self:setDone(not self.done)
	end)

	self.waiting = new("TextLabel", {
		Position = UDim2.fromScale(0, 0.09),
		Size = UDim2.fromScale(1, 0.77),
		BackgroundColor3 = C.white,
		BackgroundTransparency = 0.05,
		Text = "Looking fabulous! 💅\nWaiting for the other stylists...",
		TextColor3 = C.purple,
		Visible = false,
		ZIndex = 30,
		Parent = right,
	}, { Theme.corner(18), Theme.maxText(34), Theme.padding(20) })
end

function Makeover:buildWashPanel(parent: GuiObject)
	local panel = new("Frame", {
		Position = UDim2.fromScale(0, 0.24),
		Size = UDim2.fromScale(1, 0.61),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 12,
		Parent = parent,
	})
	self.washPanel = panel

	self.washHint = new("TextLabel", {
		Size = UDim2.fromScale(1, 0.2),
		Text = "",
		ZIndex = 13,
		Parent = panel,
	}, { Theme.maxText(34) })

	self.toolButtons = {}
	for i, tool in { { id = "soap", icon = "🧽", label = "Soap" }, { id = "rinse", icon = "🚿", label = "Rinse" } } do
		local b = Theme.button({
			Text = "",
			Position = UDim2.fromScale(if i == 1 then 0.06 else 0.53, 0.23),
			Size = UDim2.fromScale(0.41, 0.4),
			Color = C.lavender,
			ZIndex = 14,
			Parent = panel,
		})
		new("TextLabel", { Size = UDim2.fromScale(1, 0.65), Text = tool.icon, ZIndex = 15, Parent = b }, { Theme.maxText(64) })
		new("TextLabel", { Name = "Label", Position = UDim2.fromScale(0, 0.62), Size = UDim2.fromScale(1, 0.34), Text = tool.label, ZIndex = 15, Parent = b }, { Theme.maxText(30) })
		b.Activated:Connect(function()
			self.tool = tool.id
			self:refreshWash()
		end)
		self.toolButtons[tool.id] = b
	end

	local bar = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.67),
		Size = UDim2.fromScale(0.88, 0.11),
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
	}, { Theme.maxText(22), Theme.padding(3) })

	self.soapButton = Theme.button({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.82),
		Size = UDim2.fromScale(0.7, 0.16),
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
-- Animations: blinking eyes and the glowing "do this next" hint

function Makeover:startAnimations()
	task.spawn(function()
		while true do
			task.wait(2.5 + math.random() * 2.5)
			if self.frame.Visible and self.portraitRoot then
				local eyes = {}
				for _, d in self.portraitRoot:GetChildren() do
					if d.Name == "Eye" then
						table.insert(eyes, { frame = d, size = d.Size })
						d.Size = UDim2.new(d.Size.X.Scale, 0, d.Size.Y.Scale * 0.15, 0)
					end
				end
				task.wait(0.13)
				for _, e in eyes do
					if e.frame.Parent then
						e.frame.Size = e.size
					end
				end
			end
		end
	end)

	RunService.RenderStepped:Connect(function()
		if not self.frame.Visible then
			return
		end
		local glow = 0.15 + 0.35 * (0.5 + 0.5 * math.sin(os.clock() * 6))
		for id, stroke in self.tabStrokes do
			stroke.Transparency = if id == self.nextStep and id ~= self.tab then glow else 1
		end
		self.doneStroke.Transparency = if self.nextStep == "Done" and not self.done then glow else 1
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
	self.bestShown = false
	self.hearts = 0
	self.tool = "soap"
	self.tab = "Wash"
	self.nameTag.Text = "💖 " .. self.client.name
	self:setDone(self.done, true)
	self:renderPortrait()
	self:setTab("Wash")
	self:say(self.client.story, 5)
end

function Makeover:setVisible(visible: boolean)
	local wasVisible = self.frame.Visible
	self.frame.Visible = visible and self.client ~= nil
	if not self.frame.Visible then
		self.cursor.Visible = false
		self.scrubbing = false
	elseif not wasVisible then
		self:refreshTheme()
		self:setTab(self.tab)
	end
end

function Makeover:refreshTheme()
	local theme = self:theme()
	if theme then
		self.themeBar.Text = "Theme: " .. theme.name .. "   ⭐ = matches!"
		self.themeBar.BackgroundColor3 = theme.color:Lerp(C.white, 0.75)
	end
end

function Makeover:theme(): Catalog.Theme?
	return Catalog.themeById[self.ctx.state().themeId]
end

function Makeover:say(text: string, seconds: number?)
	self.speechText.Text = text
	self.speech.Visible = true
	Sounds.play("Pop", 0.5)
	Theme.pop(self.speech)
	self.sayId = (self.sayId or 0) + 1
	local id = self.sayId
	task.delay(seconds or 3, function()
		if self.sayId == id then
			self.speech.Visible = false
		end
	end)
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

-- How the judges would score the look right now (shown as happy hearts).
function Makeover:previewStars(): number
	local theme = self:theme()
	if not theme then
		return 1
	end
	local stars = Scoring.judge({ look = self.look, clean = self:cleanAmount(), rinsed = #self.bubbles == 0 }, theme)
	return stars
end

function Makeover:renderPortrait()
	if not self.client then
		return
	end
	local stars = self:previewStars()
	self.portraitRoot = LookRenderer.render(self.portraitHolder, self.client, self.look, {
		dirtHealth = self.dirtHealth,
		mood = Scoring.mood(stars, self:cleanAmount()),
	})
	self.dirtFrames = {}
	for i = 1, #self.client.dirt do
		self.dirtFrames[i] = self.portraitRoot:FindFirstChild("Dirt" .. i)
	end
	local full = math.floor(stars)
	self.heartsLabel.Text = string.rep("💖", full) .. string.rep("🤍", 5 - full)
	if full > self.hearts and self.hearts > 0 then
		Theme.pop(self.heartsLabel)
	end
	self.hearts = full
	self:refreshChecklist()
end

function Makeover:stepsDone()
	local makeupCount = 0
	for _, key in MAKEUP_KEYS do
		if not Catalog.isNone(self.look[key]) then
			makeupCount += 1
		end
	end
	return {
		Wash = self:isWashed(),
		Hair = not Catalog.isNone(self.look.hairStyle),
		Makeup = makeupCount >= 2,
		Outfit = not Catalog.isNone(self.look.outfit),
	}
end

function Makeover:refreshChecklist()
	local done = self:stepsDone()
	for step, chip in self.checks do
		chip.BackgroundColor3 = if done[step] then C.green else C.lavender
		chip.TextColor3 = if done[step] then C.white else C.text
	end
	self.nextStep = "Done"
	for _, step in STEPS do
		if not done[step[1]] then
			self.nextStep = step[1]
			break
		end
	end
end

function Makeover:setTab(tabId: string)
	self.tab = tabId
	self.cursor.Visible = false
	for id, b in self.tabButtons do
		local active = id == tabId
		b.BackgroundColor3 = if active then C.pink else C.lavender
		b.Label.TextColor3 = if active then C.white else C.text
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
	self.chips.Visible = #categories > 1
	for _, category in categories do
		local active = self.subcategory[tabId] == category.key
		local chip = Theme.button({
			Text = category.label,
			Size = UDim2.fromScale(math.min(0.32, 1 / #categories - 0.015), 1),
			Color = if active then C.purple else C.lavender,
			TextColor3 = if active then C.white else C.text,
			ZIndex = 13,
			MaxText = 22,
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

function Makeover:layoutGrid()
	local width = self.grid.AbsoluteSize.X - 8 - self.grid.ScrollBarThickness - 2
	local cols = if width >= 560 then 5 elseif width >= 380 then 4 else 3
	local gap = 8
	local cell = math.max(40, math.floor((width - gap * (cols - 1)) / cols))
	self.gridLayout.CellSize = UDim2.fromOffset(cell, math.floor(cell * 1.08))
	self.gridLayout.CellPadding = UDim2.fromOffset(gap, gap)
end

function Makeover:renderGrid()
	if self.tab == "Wash" or not self.client then
		return
	end
	self:layoutGrid()
	local key = self.subcategory[self.tab]
	local category = Catalog.categoryByKey[key]
	local theme = self:theme()
	for _, child in self.grid:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	local order = 0
	self.cards = {}
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
		})
		local stroke = Theme.stroke(if selected then C.hotPink else C.lavender, if selected then 4 else 2)
		stroke.Parent = card

		local preview = new("Frame", {
			Position = UDim2.fromScale(0.05, 0.04),
			Size = UDim2.fromScale(0.9, 0.72),
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			ZIndex = 14,
			Parent = card,
		})
		if category.preview == "portrait" then
			local previewLook = table.clone(self.look)
			previewLook[key] = it.id
			local zoom = if key == "outfit" then 1 elseif key == "hairStyle" or key == "accessory" then 1.1 else 1.45
			LookRenderer.render(preview, self.client, previewLook, { headOnly = key ~= "outfit", clean = 1, mood = "smile", zoom = zoom })
		elseif it.color then
			local dot = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.8, 0.8),
				ZIndex = 15,
				Parent = preview,
			}, { new("UIAspectRatioConstraint", { AspectRatio = 1 }), Theme.round(), Theme.stroke(C.white, 3) })
			LookRenderer.paint(dot, it)
		else
			new("TextLabel", { Size = UDim2.fromScale(1, 1), Text = "🚫", ZIndex = 15, Parent = preview }, { Theme.maxText(48) })
		end

		new("TextLabel", {
			Position = UDim2.fromScale(0.04, 0.77),
			Size = UDim2.fromScale(0.92, 0.2),
			Text = if Catalog.isNone(it.id) then "Remove" else it.name,
			ZIndex = 15,
			Parent = card,
		}, { Theme.maxText(18) })

		if theme and Catalog.matchesTheme(it, theme) then
			new("TextLabel", {
				Position = UDim2.new(0, 3, 0, 3),
				Size = UDim2.fromScale(0.24, 0.22),
				Text = "⭐",
				ZIndex = 18,
				Parent = card,
			})
		end

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
				Position = UDim2.new(1, -3, 0, 3),
				Size = UDim2.fromScale(0.62, 0.18),
				BackgroundTransparency = 0,
				BackgroundColor3 = if it.pass then C.gold else C.purple,
				TextColor3 = C.white,
				Text = if it.pass then "👑 VIP" else "🪙 " .. it.price,
				ZIndex = 17,
				Parent = card,
			}, { Theme.round(), Theme.padding(2) })
		else
			local check = new("TextLabel", {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -3, 0, 3),
				Size = UDim2.fromScale(0.22, 0.2),
				BackgroundTransparency = 0,
				BackgroundColor3 = C.hotPink,
				TextColor3 = C.white,
				Text = "✓",
				Visible = selected,
				ZIndex = 17,
				Parent = card,
			}, { Theme.round() })
			self.cards[it.id] = { card = card, stroke = stroke, check = check }
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
	local before = self.hearts
	self.look[key] = itemId
	Remotes.UpdateLook:FireServer(key, itemId)
	self:renderPortrait()
	self:refreshSelection(key)

	local theme = self:theme()
	local it = Catalog.byId[itemId]
	if self.hearts >= 5 and not self.bestShown then
		self.bestShown = true
		self:say("This is my BEST look EVER! 💖", 3)
		Effects.confetti(self.frame, 30)
	elseif Catalog.isNone(itemId) then
		self:say(pick(NONE_LINES), 2)
	elseif theme and Catalog.matchesTheme(it, theme) then
		self:say(string.format(pick(THEME_LINES), themeWord(theme)), 2.5)
	elseif self.hearts >= before then
		self:say(pick(LIKE_LINES), 2)
	end
end

-- Moves the pink "selected" outline and ✓ without rebuilding the whole grid (fast on phones).
function Makeover:refreshSelection(key: string)
	for itemId, c in self.cards or {} do
		local selected = self.look[key] == itemId
		c.card.BackgroundColor3 = if selected then C.softPink else C.white
		c.stroke.Color = if selected then C.hotPink else C.lavender
		c.stroke.Thickness = if selected then 4 else 2
		c.check.Visible = selected
	end
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
		self.washHint.Text = if self.tool == "soap" then "Rub the dirt off! 🧽" else "Pick the Soap to scrub! 🧽"
	elseif bubbles > 0 then
		self.washHint.Text = "Rinse off the bubbles! 🚿"
	else
		self.washHint.Text = "Sparkly clean! ✨ Now do the hair! 💇"
	end
	for id, b in self.toolButtons do
		local active = id == self.tool
		b.BackgroundColor3 = if active then C.pink else C.lavender
		b.Label.TextColor3 = if active then C.white else C.text
	end
	self.cleanFill.Size = UDim2.fromScale(math.clamp(clean, 0, 1), 1)
	self.cleanText.Text = "Clean: " .. math.floor(clean * 100 + 0.5) .. "%" .. (if bubbles > 0 then "  🫧 " .. bubbles else "")
	local soaps = self.ctx.profile.superSoaps or 0
	self.soapButton.Text = if soaps > 0 then "✨ Use Super Soap (" .. soaps .. " left)" else "✨ Super Soap (Robux)"
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
		self:say("Ahh! I feel SO fresh! ✨", 3)
		Effects.confetti(self.frame, 20)
		self:renderPortrait()
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
	local brush = 0.05
	local changed = false
	local wasDirty = self:cleanAmount() < 0.98

	if self.tool == "soap" then
		Sounds.play("Scrub", 0.35)
		for i, spot in self.client.dirt do
			local h = self.dirtHealth[i]
			if h > 0 and (rel - Vector2.new(spot.x, spot.y)).Magnitude < spot.size / 2 + brush then
				self.dirtHealth[i] = math.max(0, h - moved / (size * 0.4))
				local f = self.dirtFrames[i]
				if f then
					LookRenderer.setDirtHealth(f, self.dirtHealth[i])
				end
				if self.dirtHealth[i] <= 0 then
					Effects.sparkle(self.bubbleLayer, spot.x, spot.y)
					if math.random() < 0.3 then
						self:say(pick(WASH_LINES), 1.6)
					end
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
		-- All the dirt is gone: wipe the last specks and switch to rinsing for the player
		if wasDirty and self:cleanAmount() >= 0.98 then
			for i, f in self.dirtFrames do
				self.dirtHealth[i] = 0
				LookRenderer.setDirtHealth(f, 0)
			end
			self.tool = "rinse"
			self.scrubbing = false
			self:say("No more dirt! Now rinse the bubbles! 🚿", 3)
			self:refreshWash()
			self:sendWash(true)
		end
	else
		for i = #self.bubbles, 1, -1 do
			local b = self.bubbles[i]
			if (rel - b.pos).Magnitude < b.size / 2 + brush * 2 then
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
	local activeTouch: InputObject? = nil -- only follow the first finger

	UserInputService.InputBegan:Connect(function(input)
		if self.tab ~= "Wash" or not self.frame.Visible or self.ctx.isModalOpen() then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local pos = screenPosition(input)
			if self:isOverPortrait(pos) and not self.scrubbing then
				self.scrubbing = true
				activeTouch = if input.UserInputType == Enum.UserInputType.Touch then input else nil
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
		if input.UserInputType == Enum.UserInputType.Touch and activeTouch and input ~= activeTouch then
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
			if input.UserInputType == Enum.UserInputType.Touch and activeTouch and input ~= activeTouch then
				return
			end
			activeTouch = nil
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
