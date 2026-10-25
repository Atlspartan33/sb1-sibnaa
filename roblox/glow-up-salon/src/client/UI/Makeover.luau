-- The Dressing Hall: walk your own avatar from station to station and style yourself for the
-- theme. Hair, face, outfit, costume pieces, a pet to walk with you, and your runway pose and
-- effect. A guide on the left shows what's done and walks you to the next station; you react as
-- you go (speech, a bigger smile, happy hearts).

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Avatar = require(ReplicatedStorage.Shared.Avatar)
local Catalog = require(ReplicatedStorage.Shared.Catalog)
local Events = require(ReplicatedStorage.Shared.Events)
local LookRenderer = require(ReplicatedStorage.Shared.LookRenderer)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Scoring = require(ReplicatedStorage.Shared.Scoring)
local Stations = require(ReplicatedStorage.Shared.Stations)
local Effects = require(script.Parent.Effects)
local Sounds = require(script.Parent.Sounds)
local Theme = require(script.Parent.Theme)

local C = Theme.Colors
local new = Theme.new

local Makeover = {}
Makeover.__index = Makeover

-- The stations in the order the guide suggests them
local STEPS = { { "Hair", "💇" }, { "Face", "💄" }, { "Outfit", "👗" }, { "Costume", "🦸" }, { "Pet", "🐶" }, { "Show", "💃" } }
local COSTUME_KEYS = { "costumeBack", "costumeFace", "costumeWaist", "costumeShoulder", "accessory" }
local MAKEUP_KEYS = { "eyeshadow", "lashes", "blush", "lipstick" }
local MAX_BUBBLES = 24
local SEND_INTERVAL = 0.25

-- How much of your avatar fills the space next to the menu at each station (studs tall).
local FRAMING = {
	Face = { height = 3.4, focus = "face" },
	Hair = { height = 4, focus = "hair" },
	Outfit = { height = 8.6, focus = "body" },
	Costume = { height = 8.6, focus = "body" },
	Pet = { height = 9.5, focus = "body" },
	Show = { height = 8.6, focus = "body" },
}

local WASH_LINES = { "That tickles! 😆", "Scrub scrub! 🧽", "Ooh, bubbles!", "Keep going! 💪", "I can see my face again!" }
local LIKE_LINES = { "Ooh, cute! 💕", "I like it!", "So pretty! ✨", "Ooh la la!", "Wow!" }
local THEME_LINES = { "Perfect for %s! 😍", "So %s! I love it!", "That's so %s! 💖" }
local PERFUME_LINES = { "Hee hee! 🌸", "Ooh, I smell like flowers!", "Achoo! 😆", "Mmm, so fancy! 💕", "Again! Again!" }
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
		BackgroundTransparency = 1, -- the hall shows around the panels
		Active = false, -- touches outside the panels still walk you around
		Visible = false,
		ZIndex = 10,
		Parent = gui,
	})
	self.spin = 0

	self:buildLeft()
	self:buildRight()
	self:buildGuide()
	self.frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self:layoutForScreen()
	end)
	self:connectInput()
	self:startAnimations()
	self:startStage()
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
	self.spinHint = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(0.97, 0.03),
		Size = UDim2.fromScale(0.4, 0.08),
		BackgroundTransparency = 0.15,
		BackgroundColor3 = C.white,
		Text = "👆 Drag to spin",
		Visible = false,
		ZIndex = 110,
		Parent = self.portraitHolder,
	}, { Theme.round(), Theme.padding(4) })
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
	-- What the client wishes for
	self.wishLabel = new("TextLabel", {
		Position = UDim2.fromScale(0.5, 0.805),
		Size = UDim2.fromScale(0.5, 0.075),
		BackgroundTransparency = 0,
		BackgroundColor3 = C.softPink,
		TextColor3 = C.purple,
		Text = "",
		ZIndex = 12,
		Parent = left,
	}, { Theme.round(), Theme.maxText(22), Theme.padding(4) })

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
		Size = UDim2.fromScale(0.49, 0.085),
		Text = "",
		ZIndex = 12,
		Parent = left,
	}, { Theme.maxText(30) })

	local checklist = new("Frame", {
		Name = "Checklist",
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
	for i, step in STEPS do
		local chip = new("TextButton", {
			LayoutOrder = i,
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
		Position = UDim2.new(0.52, 0, 0, 62),
		Size = UDim2.new(0.465, 0, 1, -70),
		BackgroundColor3 = C.white,
		Active = true,
		Visible = false, -- opens when you step onto a station
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

	-- The station decides the tab, so the tab row stays hidden (the guide does the switching)
	local tabs = new("Frame", {
		Position = UDim2.fromScale(0, 0.09),
		Size = UDim2.fromScale(1, 0.135),
		BackgroundTransparency = 1,
		Visible = false,
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
	for i, tab in Catalog.Tabs do
		local b = Theme.button({
			Text = "",
			LayoutOrder = i,
			Size = UDim2.fromScale(0.155, 1),
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

	-- Sub-categories: big enough for small fingers, and they scroll sideways if they don't fit
	self.chips = new("ScrollingFrame", {
		Position = UDim2.new(0, 0, 0.075, 6),
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundTransparency = 1,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.X,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(),
		ZIndex = 12,
		Parent = right,
	}, {
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 6),
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

	-- Messy hair has to be brushed before picking a style
	self.brushHint = new("TextLabel", {
		Position = UDim2.fromScale(0, 0.24),
		Size = UDim2.fromScale(1, 0.61),
		Text = "🖌️\nBrush out the tangles!\nRub the messy hair",
		TextColor3 = C.purple,
		Visible = false,
		ZIndex = 20,
		Parent = right,
	}, { Theme.maxText(40), Theme.padding(20) })

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
	self.doneButton.Visible = false -- the guide has the Done button
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

	self.waiting = new("Frame", {
		Position = UDim2.fromScale(0, 0.09),
		Size = UDim2.fromScale(1, 0.77),
		BackgroundColor3 = C.white,
		BackgroundTransparency = 0.05,
		Visible = false,
		ZIndex = 30,
		Parent = right,
	}, { Theme.corner(18), Theme.padding(16) })
	new("TextLabel", {
		Size = UDim2.fromScale(1, 0.5),
		Text = "Looking fabulous! 💅\nWaiting for the other stylists...",
		TextColor3 = C.purple,
		ZIndex = 31,
		Parent = self.waiting,
	}, { Theme.maxText(34) })
	-- Something fun to do while waiting
	local perfume = Theme.button({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.58),
		Size = UDim2.fromScale(0.7, 0.3),
		Text = "🌸 Spritz perfume!",
		Color = C.pink,
		ZIndex = 32,
		MaxText = 34,
		Parent = self.waiting,
	})
	perfume.Activated:Connect(function()
		for _ = 1, 4 do
			Effects.sparkle(self.bubbleLayer, 0.25 + math.random() * 0.5, 0.15 + math.random() * 0.5, if math.random() < 0.5 then "🌸" else "💕")
		end
		self:say(pick(PERFUME_LINES), 1.5)
	end)
end

-- The guide down the left: your happy hearts, a button for each station (green with a check when
-- it's done, glowing when it's next; tap one to walk there) and the I'm Done button.
function Makeover:buildGuide()
	self.left.Visible = false -- the old portrait card isn't used in the Dressing Hall
	local guide = new("Frame", {
		Name = "Guide",
		Position = UDim2.new(0, 10, 0, 62),
		Size = UDim2.new(0, 152, 0, 300),
		BackgroundColor3 = C.white,
		BackgroundTransparency = 0.08,
		Active = true,
		ZIndex = 11,
		Parent = self.frame,
	}, { Theme.corner(20), Theme.stroke(C.pink, 3), Theme.padding(6) })
	self.guide = guide
	self.heartsLabel.Parent = guide
	self.heartsLabel.Position = UDim2.new(0, 0, 0, 0)
	self.heartsLabel.Size = UDim2.new(1, 0, 0, 26)
	self.heartsLabel.ZIndex = 12

	local grid = new("Frame", {
		Position = UDim2.new(0, 0, 0, 30),
		Size = UDim2.new(1, 0, 0, 198),
		BackgroundTransparency = 1,
		ZIndex = 12,
		Parent = guide,
	}, {
		new("UIGridLayout", { CellSize = UDim2.new(0.5, -4, 0, 62), CellPadding = UDim2.fromOffset(6, 6) }),
	})
	self.checks = {}
	self.tabStrokes = {}
	for i, step in STEPS do
		local station = Stations.byTab[step[1]]
		local b = Theme.button({
			Text = "",
			LayoutOrder = i,
			Color = C.lavender,
			ZIndex = 13,
			Parent = grid,
		})
		b.Name = "Go" .. step[1]
		new("TextLabel", { Name = "Icon", Size = UDim2.fromScale(1, 0.6), Text = step[2], ZIndex = 14, Parent = b }, { Theme.maxText(30) })
		new("TextLabel", {
			Name = "Label",
			Position = UDim2.fromScale(0, 0.58),
			Size = UDim2.fromScale(1, 0.4),
			Text = step[1],
			TextColor3 = C.text,
			ZIndex = 14,
			Parent = b,
		}, { Theme.maxText(16) })
		self.tabStrokes[step[1]] = Theme.new("UIStroke", {
			Color = C.gold,
			Thickness = 4,
			Transparency = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = b,
		})
		b.Activated:Connect(function()
			if station then
				self:walkTo(station)
			end
		end)
		self.checks[step[1]] = b
	end

	local done = Theme.button({
		Position = UDim2.new(0, 0, 1, -60),
		Size = UDim2.new(1, 0, 0, 60),
		Text = "I'm Done! ✨",
		Color = C.hotPink,
		ZIndex = 13,
		MaxText = 24,
		Parent = guide,
	})
	done.Activated:Connect(function()
		if not self.done and self:stepsDoneCount() < 3 then
			local t = os.clock()
			if not self.confirmDoneAt or t - self.confirmDoneAt > 4 then
				self.confirmDoneAt = t
				self:say("There's still time to style! 💖 Tap again to go to the runway", 3.5)
				return
			end
		end
		self.confirmDoneAt = nil
		self:setDone(not self.done)
	end)
	self.doneButton = done
	self.doneStroke = Theme.new("UIStroke", {
		Color = C.gold,
		Thickness = 4,
		Transparency = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = done,
	})

	-- What you say pops up at the top of the hall
	self.speech.Parent = self.frame
	self.speech.AnchorPoint = Vector2.new(0, 0)
	self.speech.Position = UDim2.new(0, 172, 0, 66)
	self.speech.Size = UDim2.new(0.3, 0, 0, 58)
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
		Position = UDim2.fromScale(0.5, 0.74),
		Size = UDim2.fromScale(0.88, 0.13),
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
	self.tab = "Hair"
	self.brushed = self.look.hairStyle ~= "hair_messy"
	self.tangle = if self.brushed then 0 else 1
	self.nameTag.Text = "💖 " .. self.client.name
	self:setDone(self.done, true)
	self.spin = 0
	self:renderPortrait()
	self:setTab("Hair")
	local theme = self:theme()
	self:say(if theme then "Let's get ready for " .. theme.name .. "! ✨" else "Let's get ready for the show! ✨", 4)
	local wishes = self.client.wishes or {}
	if #wishes > 0 then
		local client = self.client
		task.delay(4.2, function()
			if self.client == client then
				local texts = {}
				for _, w in wishes do
					table.insert(texts, w.text)
				end
				self:say("I wish for " .. table.concat(texts, " and ") .. "! 💌", 4)
			end
		end)
	end
end

-- On short screens (phones), hide the checklist so the client's face can be bigger.
-- On short screens (phones) the guide's buttons get a little shorter so it all fits.
function Makeover:layoutForScreen()
	if not self.guide then
		return
	end
	local compact = self.frame.AbsoluteSize.Y > 0 and self.frame.AbsoluteSize.Y < 500
	local cell = if compact then 56 else 62
	local grid = self.guide:FindFirstChildOfClass("Frame")
	local layout = grid and grid:FindFirstChildOfClass("UIGridLayout")
	if grid and layout then
		layout.CellSize = UDim2.new(0.5, -4, 0, cell)
		grid.Size = UDim2.new(1, 0, 0, cell * 3 + 12)
	end
	self.guide.Size = UDim2.new(0, 152, 0, 30 + cell * 3 + 12 + 6 + 60 + 12)
end

function Makeover:setVisible(visible: boolean)
	local wasVisible = self.frame.Visible
	self.frame.Visible = visible and self.client ~= nil
	if self.frame.Visible then
		self:layoutForScreen()
	end
	if not self.frame.Visible then
		self.cursor.Visible = false
		self.scrubbing = false
		if self.station then
			self:closeStation()
		end
	end
	if self.frame.Visible and not wasVisible then
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
	self:styleDone()
	if not silent then
		Remotes.Done:FireServer(done)
		if done then
			-- ready for the runway! a burst of confetti and a cheer
			Effects.confetti(self.frame, 40)
			Sounds.play("Cheer", 0.6)
			self:say("I'm runway ready! 💃", 2.5)
		end
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
	local stars = Scoring.judge({ look = self.look, clean = self:cleanAmount(), rinsed = #self.bubbles == 0, client = self.client }, theme)
	return stars
end

function Makeover:renderPortrait()
	if not self.client then
		return
	end
	local stars = self:previewStars()
	if self.tab == "Nails" then
		self.portraitRoot = LookRenderer.renderHand(self.portraitHolder, self.client, self.look)
	else
		self.portraitRoot = LookRenderer.render(self.portraitHolder, self.client, self.look, {
			dirtHealth = self.dirtHealth,
			mood = Scoring.mood(stars, self:cleanAmount()),
			brushed = self.brushed,
			tangle = self.tangle,
		})
	end
	self.dirtFrames = {}
	for i = 1, #self.client.dirt do
		self.dirtFrames[i] = self.portraitRoot:FindFirstChild("Dirt" .. i)
	end
	local full = math.floor(stars)
	self.heartsLabel.Text = "😊" .. string.rep("💖", full) .. string.rep("🤍", 5 - full)
	if full > self.hearts and self.hearts > 0 then
		Theme.pop(self.heartsLabel)
	end
	self.hearts = full
	self:refreshWishes()
	self:refreshChecklist()
end

function Makeover:wishesMet(): number
	local met = 0
	for _, w in self.client.wishes or {} do
		if Scoring.wishMet(w, self.look) then
			met += 1
		end
	end
	return met
end

function Makeover:refreshWishes()
	local parts = {}
	for _, w in self.client.wishes or {} do
		table.insert(parts, (if Scoring.wishMet(w, self.look) then "✅" else "") .. w.text)
	end
	self.wishLabel.Visible = #parts > 0
	self.wishLabel.Text = "💌 " .. table.concat(parts, "  ")
end

function Makeover:needsBrush(): boolean
	return self.look.hairStyle == "hair_messy" and not self.brushed
end

-- Which rubbing tool is in use right now ("wash", "brush" or nil)
function Makeover:rubMode(): string?
	if self.tab == "Wash" then
		return "wash"
	elseif self.tab == "Hair" and self:needsBrush() then
		return "brush"
	end
	return nil
end

function Makeover:brush(pos: Vector2, moved: number)
	local root = self.portraitRoot
	if not root then
		return
	end
	local size = root.AbsoluteSize.X
	local rel = (pos - root.AbsolutePosition) / math.max(size, 1)
	if rel.X < 0.15 or rel.X > 0.85 or rel.Y < 0 or rel.Y > 0.45 then
		return
	end
	self.tangle = math.max(0, self.tangle - moved / (size * 1.6))
	for _, t in root:GetChildren() do
		if t.Name == "Tuft" and t:IsA("GuiObject") then
			t.BackgroundTransparency = 1 - self.tangle
		end
	end
	Sounds.play("Scrub", 0.35)
	if math.random() < 0.08 then
		Effects.sparkle(self.bubbleLayer, rel.X, rel.Y, "💨")
	end
	if self.tangle <= 0 then
		self.brushed = true
		self.scrubbing = false
		Effects.sparkle(self.bubbleLayer, 0.5, 0.2)
		self:say("Ahh, no more tangles! Now pick a hairstyle! 💇", 3)
		self:renderPortrait()
		self:setTab("Hair")
	end
end

function Makeover:stepsDone()
	local makeupCount = 0
	for _, key in MAKEUP_KEYS do
		if not Catalog.isNone(self.look[key]) then
			makeupCount += 1
		end
	end
	local costume = false
	for _, key in COSTUME_KEYS do
		if not Catalog.isNone(self.look[key]) then
			costume = true
		end
	end
	return {
		Hair = not Catalog.isNone(self.look.hairStyle),
		Face = makeupCount >= 2,
		Outfit = not Catalog.isNone(self.look.outfit),
		Costume = costume,
		Pet = not Catalog.isNone(self.look.pet),
		Show = not Catalog.isNone(self.look.pose) or not Catalog.isNone(self.look.effect),
	}
end

function Makeover:stepsDoneCount(): number
	local n = 0
	for _, ok in self:stepsDone() do
		if ok then
			n += 1
		end
	end
	return n
end

-- "I'm Done!" stays quiet (lavender) until three stations are done, then turns hot pink.
function Makeover:styleDone()
	local ready = self.done or self:stepsDoneCount() >= 3
	self.doneButton.Text = if self.done then "Keep Styling ✏️" else "I'm Done! ✨"
	self.doneButton.BackgroundColor3 = if self.done then C.purple elseif ready then C.hotPink else C.lavender
	self.doneButton.TextColor3 = if self.done or ready then C.white else C.text
end

function Makeover:refreshChecklist()
	local done = self:stepsDone()
	for step, chip in self.checks do
		chip.BackgroundColor3 = if done[step] then C.green else C.lavender
		chip.TextColor3 = if done[step] then C.white else C.text
		-- a check mark too, so done isn't shown by color alone
		local label = chip:FindFirstChild("Label")
		if label and label:IsA("TextLabel") then
			label.Text = step .. (if done[step] then " ✓" else "")
			label.TextColor3 = if done[step] then C.white else C.text
		end
	end
	self.nextStep = "Done"
	for _, step in STEPS do
		if not done[step[1]] then
			self.nextStep = step[1]
			break
		end
	end
	self:styleDone()
end

function Makeover:setTab(tabId: string)
	local wasNails = self.tab == "Nails"
	self.tab = tabId
	self.bubbleLayer.Visible = tabId ~= "Nails" -- soap bubbles belong on the face, not the hand
	if (tabId == "Nails") ~= wasNails and self.client then
		self:renderPortrait() -- switch between the face and the hand
	end
	self.cursor.Visible = false
	for id, b in self.tabButtons do
		local active = id == tabId
		b.BackgroundColor3 = if active then C.pink else C.lavender
		b.Label.TextColor3 = if active then C.white else C.text
	end
	local isWash = tabId == "Wash"
	local brushing = tabId == "Hair" and self:needsBrush()
	self.washPanel.Visible = isWash
	self.brushHint.Visible = brushing
	self.grid.Visible = not isWash and not brushing
	self.chips.Visible = not isWash and not brushing
	if brushing then
		return
	end

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
	-- Without sub-category chips, the grid moves up to use their space
	self.grid.Position = UDim2.new(0, 0, 0.075, if #categories > 1 then 66 else 6)
	self.grid.Size = UDim2.new(1, 0, 0.925, if #categories > 1 then -66 else -6)
	for i, category in categories do
		local active = self.subcategory[tabId] == category.key
		local chip = Theme.button({
			LayoutOrder = i,
			Size = UDim2.new(0, 124, 0, 52),
			Color = if active then C.purple else C.lavender,
			TextColor3 = if active then C.white else C.text,
			-- the chosen one is marked with a dot too, not just its color
			Text = (if active then "● " else "") .. category.label,
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
	local cols = if width >= 600 then 5 elseif width >= 470 then 4 else 3
	local gap = 8
	local cell = math.max(40, math.floor((width - gap * (cols - 1)) / cols))
	self.gridLayout.CellSize = UDim2.fromOffset(cell, math.floor(cell * 1.08))
	self.gridLayout.CellPadding = UDim2.fromOffset(gap, gap)
end

function Makeover:renderGrid()
	if self.tab == "Wash" or not self.client then
		return
	end
	local key = self.subcategory[self.tab]
	local category = Catalog.categoryByKey[key or ""]
	if not category or (self.tab == "Hair" and self:needsBrush()) then
		return -- still brushing out the tangles; the grid is hidden
	end
	self:layoutGrid()
	local theme = self:theme()
	for _, child in self.grid:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	local order = 0
	self.cards = {}
	local eventId = self.ctx.eventId()
	for _, it in category.items do
		if not Catalog.isAvailable(it, self.ctx.profile, eventId) then
			continue
		end
		order += 1
		local selected = self.look[key] == it.id
		local unlocked = Catalog.isUnlocked(it, self.ctx.profile, eventId)

		local card = new("TextButton", {
			-- what you can wear that fits the theme first, then everything else you can wear,
			-- then locked items, and "None" last
			LayoutOrder = if Catalog.isNone(it.id)
				then 9999
				elseif not unlocked then order + 4000
				elseif theme and Catalog.matchesTheme(it, theme) then order
				else order + 2000,
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
		-- avatar-shop items (hair, costume pieces, hats) show a picture of the real thing
		if category.preview == "portrait" and not it.asset then
			local previewLook = table.clone(self.look)
			previewLook[key] = it.id
			if key == "outfit" or key == "outfitPattern" then
				-- outfits show head to toe, so the whole dress or pattern is visible
				LookRenderer.renderBody(preview, self.client, previewLook, { clean = 1, mood = "smile" })
			else
				local zoom = if key == "hairStyle" or key == "accessory" then 1.1 else 1.45
				LookRenderer.render(preview, self.client, previewLook, { headOnly = true, clean = 1, mood = "smile", zoom = zoom })
			end
		elseif it.asset then
			new("ImageLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Image = "rbxthumb://type=Asset&id=" .. it.asset .. "&w=150&h=150",
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 15,
				Parent = preview,
			})
		elseif category.preview == "icon" and it.icon then
			new("TextLabel", { Size = UDim2.fromScale(1, 1), Text = it.icon, TextColor3 = C.hotPink, ZIndex = 15, Parent = preview }, { Theme.maxText(56) })
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
			new("TextLabel", { Size = UDim2.fromScale(1, 1), Text = "⚪", ZIndex = 15, Parent = preview }, { Theme.maxText(48) })
		end

		new("TextLabel", {
			Position = UDim2.fromScale(0.04, 0.77),
			Size = UDim2.fromScale(0.92, 0.2),
			Text = if Catalog.isNone(it.id) then "None" else it.name,
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
		-- 💌 when this item would make one of the client's wishes come true
		for _, w in self.client.wishes or {} do
			if w.key == key and not Scoring.wishMet(w, self.look) and Scoring.wishMet(w, { [key] = it.id }) then
				new("TextLabel", {
					Position = UDim2.new(0.24, 3, 0, 3),
					Size = UDim2.fromScale(0.24, 0.22),
					Text = "💌",
					ZIndex = 18,
					Parent = card,
				})
				break
			end
		end
		if it.event or it.gift then
			new("TextLabel", {
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, 3, 0.76, 0),
				Size = UDim2.fromScale(0.22, 0.2),
				Text = if it.gift then "🎁" else (Events.byId[it.event] and Events.byId[it.event].icon or "✨"),
				ZIndex = 18,
				Parent = card,
			})
		end

		if not unlocked then
			new("Frame", {
				Size = UDim2.fromScale(1, 0.76),
				BackgroundColor3 = C.white,
				BackgroundTransparency = 0.6,
				ZIndex = 16,
				Parent = card,
			}, { Theme.corner(16) })
			new("TextLabel", {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -3, 0, 3),
				Size = UDim2.fromScale(0.62, 0.18),
				BackgroundTransparency = 0,
				BackgroundColor3 = if it.pass then C.gold elseif it.level then C.green else C.purple,
				TextColor3 = if it.pass then C.text else C.white,
				Text = "🔒 " .. (if it.pass == "VIP" then "VIP" elseif it.pass then "Pack" elseif it.level then "Lv " .. it.level else "💰" .. it.price),
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
	local wishesBefore = self:wishesMet()
	self.look[key] = itemId
	Remotes.UpdateLook:FireServer(key, itemId)
	self:renderPortrait()
	self:refreshSelection(key)
	if key == "pose" then
		self:previewPose()
	elseif key == "costumeBack" and not Catalog.isNone(itemId) then
		-- wings and capes are on your back: turn around to show them off, then turn back
		self.spin = math.pi
		local picked = itemId
		task.delay(2.2, function()
			if self.look.costumeBack == picked then
				self.spin = 0
			end
		end)
	end
	Theme.pop(self.heartsLabel)

	local theme = self:theme()
	local it = Catalog.byId[itemId]
	if key == "nailColor" or key == "nailArt" then
		-- paint each nail with a little sparkle, one after another
		local nails = {}
		for _, n in self.portraitRoot:GetChildren() do
			if n.Name == "Nail" and n:IsA("GuiObject") then
				table.insert(nails, n)
			end
		end
		for i, n in nails do
			task.delay(i * 0.08, function()
				Effects.sparkle(self.bubbleLayer, n.Position.X.Scale, n.Position.Y.Scale, if key == "nailArt" then "💫" else "✨")
			end)
		end
	end
	if self:wishesMet() > wishesBefore then
		self:say("Yay! My wish came true! 💌", 2.5)
		Effects.confetti(self.frame, 15)
	elseif self.hearts >= 5 and not self.bestShown then
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
	local rainbow = self.ctx.profile.passes and self.ctx.profile.passes.RainbowBubbles
	local frame = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(rel.X, rel.Y),
		Size = UDim2.fromScale(size, size),
		BackgroundColor3 = if rainbow then Color3.fromHSV(math.random(), 0.35, 1) else C.white,
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
		if #self.bubbles > 0 then
			Sounds.play("Rinse", 1.2)
		end
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

------------------------------------------------------------------------------
-- The Dressing Hall: you walk around in your own avatar. Step on a station's glowing pad and its
-- menu slides in on the right while the camera frames you on the left; walk off and it closes.
-- The look itself is put on by the server, so everyone in the hall sees it.

function Makeover:is3D(): boolean
	return self.station ~= nil
end

function Makeover:character(): Model?
	return Players.LocalPlayer.Character
end

-- The guide buttons walk you over to a station.
function Makeover:walkTo(station: Stations.Station)
	local character = self:character()
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:MoveTo(station.pad)
	end
end

function Makeover:openStation(station: Stations.Station)
	self.station = station
	self.spin = 0
	self.stationOpenedAt = os.clock()
	self:setTab(station.tab)
	self.right.Visible = true
	Theme.pop(self.right)
	Sounds.play("Pop", 0.6)
	local character = self:character()
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and root and root:IsA("BasePart") then
		humanoid.AutoRotate = false
		humanoid:Move(Vector3.zero)
		-- turn to face the camera
		root.CFrame = CFrame.lookAt(root.Position, root.Position + station.facing)
		self.standRotation = root.CFrame.Rotation
		self.spinShown = 0
	end
	self:previewPose()
end

-- At the Pose Stage your pose keeps playing so you can see it; anywhere else it stops.
function Makeover:previewPose()
	if self.poseTrack then
		self.poseTrack:Stop(0.3)
		self.poseTrack = nil
	end
	local me = self:character()
	if me and self.station and self.station.tab == "Show" and not Catalog.isNone(self.look.pose) then
		local track = Avatar.pose(me, self.look.pose)
		if track then
			track.Looped = true
			self.poseTrack = track
		end
	end
end

function Makeover:closeStation()
	self.station = nil
	self.spinning = false
	self.right.Visible = false
	if self.poseTrack then
		self.poseTrack:Stop(0.3)
		self.poseTrack = nil
	end
	local character = self:character()
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.AutoRotate = true
	end
end

-- The part of the screen your avatar is framed in: between the guide and the station menu.
function Makeover:stageRect(viewport: Vector2): (Vector2, Vector2)
	local left = self.guide.AbsolutePosition.X + self.guide.AbsoluteSize.X
	local right = if self.right.Visible then self.right.AbsolutePosition.X else viewport.X
	local top, bottom = 64, viewport.Y
	return Vector2.new(left, top), Vector2.new(math.max(right - left, 1), bottom - top)
end

-- Where the camera goes so your avatar fills the space next to the station menu.
function Makeover:cameraTarget(camera: Camera): CFrame?
	local character = self:character()
	local head = character and character:FindFirstChild("Head")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local station = self.station
	if not (station and head and root and head:IsA("BasePart") and root:IsA("BasePart")) then
		return nil
	end
	local viewport = camera.ViewportSize
	if not viewport or viewport.X <= 0 then
		return nil
	end
	local framing = FRAMING[self.tab] or FRAMING.Hair
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local feet = root.Position.Y - (if humanoid then humanoid.HipHeight + root.Size.Y / 2 else 3)
	local focus = if framing.focus == "body"
		then Vector3.new(root.Position.X, (feet + head.Position.Y + head.Size.Y) / 2 + 0.3, root.Position.Z)
		else head.Position + Vector3.new(0, 0.45, 0)
	local origin, size = self:stageRect(viewport)
	local center = origin + size / 2
	local tanV = math.tan(math.rad(camera.FieldOfView) / 2)
	local tanH = tanV * viewport.X / viewport.Y
	-- far enough back that the framing height fills most of that space
	local distance = framing.height * viewport.Y / (2 * tanV * math.min(size.Y, size.X * 1.3) * 0.9)
	local position = focus + station.facing * distance
	-- then turn the camera so you sit in that space instead of the middle of the screen
	local ndcX = center.X / viewport.X * 2 - 1
	local ndcY = 1 - center.Y / viewport.Y * 2
	return CFrame.lookAt(position, focus) * CFrame.Angles(0, math.atan(ndcX * tanH), 0) * CFrame.Angles(-math.atan(ndcY * tanV), 0, 0)
end

function Makeover:startStage()
	local controlling = false
	RunService:BindToRenderStep("GlowUpStage", Enum.RenderPriority.Camera.Value + 1, function(dt)
		local camera = Workspace.CurrentCamera
		local character = self:character()
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local here = if self.frame.Visible and root and root:IsA("BasePart") then Stations.at(root.Position) else nil
		if here ~= self.station then
			if self.station then
				self:closeStation()
			end
			if here then
				self:openStation(here)
			end
		end
		self.spinHint.Visible = self.station ~= nil and not self.spinning and os.clock() - (self.stationOpenedAt or 0) < 4

		if not self.station then
			if controlling then
				controlling = false
				camera.CameraType = Enum.CameraType.Custom
			end
			return
		end
		-- turned however far the player spun themselves (smoothly, so turning to show a cape glides)
		self.spinShown = (self.spinShown or 0) + (self.spin - (self.spinShown or 0)) * (1 - math.exp(-dt * 6))
		if root and root:IsA("BasePart") and self.standRotation then
			root.CFrame = CFrame.new(root.Position) * self.standRotation * CFrame.Angles(0, self.spinShown, 0)
		end
		local target = self:cameraTarget(camera)
		if target then
			camera.CameraType = Enum.CameraType.Scriptable
			camera.CFrame = if controlling then camera.CFrame:Lerp(target, 1 - math.exp(-dt * 8)) else target
			controlling = true
		end
	end)
end

function Makeover:connectInput()
	local lastPos: Vector2? = nil
	local activeTouch: InputObject? = nil -- only follow the first finger

	-- Drag across the 3D client to spin them around
	UserInputService.InputBegan:Connect(function(input)
		local isPress = input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
		if isPress and self.frame.Visible and self:is3D() and not self.ctx.isModalOpen() then
			local pos = screenPosition(input)
			local origin, size = self:stageRect(Workspace.CurrentCamera.ViewportSize)
			if pos.X >= origin.X and pos.X <= origin.X + size.X and pos.Y >= origin.Y then
				self.spinning = true
				self.spinFrom = pos.X
			end
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		local isMove = input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
		if self.spinning and isMove then
			local pos = screenPosition(input)
			self.spin += (pos.X - (self.spinFrom or pos.X)) * 0.012
			self.spinFrom = pos.X
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self.spinning = false
		end
	end)

	UserInputService.InputBegan:Connect(function(input)
		if not self:rubMode() or not self.frame.Visible or self.ctx.isModalOpen() then
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
		local mode = self:rubMode()
		if self.scrubbing and mode then
			local moved = if lastPos then (pos - lastPos).Magnitude else 0
			lastPos = pos
			if moved > 0 then
				if mode == "wash" then
					self:scrub(pos, moved)
				else
					self:brush(pos, moved)
				end
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
	local mode = self:rubMode()
	self.cursor.Visible = self:isOverPortrait(pos) and mode ~= nil and self.frame.Visible
	self.cursor.Text = if mode == "brush" then "🖌️" elseif self.tool == "soap" then "🧽" else "🚿"
	local f = self.frame.AbsolutePosition
	self.cursor.Position = UDim2.fromOffset(pos.X - f.X, pos.Y - f.Y)
end

return Makeover
