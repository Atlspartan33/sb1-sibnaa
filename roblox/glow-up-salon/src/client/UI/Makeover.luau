-- The makeover screen: wash the client's face, then do their hair, makeup, outfit and extras.
-- The client reacts as you go: they talk, smile more, and fill up their happy hearts.

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Catalog = require(ReplicatedStorage.Shared.Catalog)
local Events = require(ReplicatedStorage.Shared.Events)
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
		Active = true, -- touches here are for styling, not for moving the character
		Visible = false,
		ZIndex = 10,
		Parent = gui,
	}, { Theme.gradient(C.softPink, C.lavender, 45) })

	self:buildLeft()
	self:buildRight()
	self.frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self:layoutForScreen()
	end)
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
	self.tab = "Wash"
	self.brushed = self.look.hairStyle ~= "hair_messy"
	self.tangle = if self.brushed then 0 else 1
	local visits = self.client.visits or 1
	self.nameTag.Text = "💖 " .. self.client.name .. (if visits > 1 then "  ⭐" .. visits else "")
	self:setDone(self.done, true)
	self:renderPortrait()
	self:setTab("Wash")
	if visits > 1 then
		self:say("Hi again! It's me, " .. self.client.name .. "! 💖 " .. self.client.story, 6)
	else
		self:say(self.client.story, 5)
	end
	local wishes = self.client.wishes or {}
	if #wishes > 0 then
		local client = self.client
		task.delay(if visits > 1 then 6.2 else 5.2, function()
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
function Makeover:layoutForScreen()
	local compact = self.frame.AbsoluteSize.Y > 0 and self.frame.AbsoluteSize.Y < 500
	self.left.Checklist.Visible = not compact
	self.portraitHolder.Size = UDim2.fromScale(1, if compact then 0.72 else 0.66)
	self.heartsLabel.Position = UDim2.fromScale(0, if compact then 0.87 else 0.8)
	self.heartsLabel.Size = UDim2.fromScale(0.49, if compact then 0.13 else 0.085)
	self.wishLabel.Position = UDim2.fromScale(0.5, if compact then 0.88 else 0.805)
	self.wishLabel.Size = UDim2.fromScale(0.5, if compact then 0.11 else 0.075)
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
	self.grid.Position = UDim2.fromScale(0, if #categories > 1 then 0.33 else 0.24)
	self.grid.Size = UDim2.fromScale(1, if #categories > 1 then 0.52 else 0.61)
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
			-- "Remove" first, then holiday items, then everything else
			LayoutOrder = if Catalog.isNone(it.id) then 0 elseif it.event then order else order + 1000,
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
			local body = key == "outfit" or key == "outfitPattern"
			local zoom = if body then 1 elseif key == "hairStyle" or key == "accessory" then 1.1 else 1.45
			LookRenderer.render(preview, self.client, previewLook, { headOnly = not body, clean = 1, mood = "smile", zoom = zoom })
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
				TextColor3 = C.white,
				Text = if it.pass == "VIP" then "👑 VIP" elseif it.pass then "👸 Pack" elseif it.level then "⭐ Lv " .. it.level else "🪙 " .. it.price,
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

function Makeover:connectInput()
	local lastPos: Vector2? = nil
	local activeTouch: InputObject? = nil -- only follow the first finger

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
