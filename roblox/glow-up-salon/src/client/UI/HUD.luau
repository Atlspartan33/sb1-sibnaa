-- The always-on parts of the screen: round timer, coins, shop button, pop-up messages,
-- and the "next show" card between rounds.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Catalog = require(ReplicatedStorage.Shared.Catalog)
local Config = require(ReplicatedStorage.Shared.Config)
local Events = require(ReplicatedStorage.Shared.Events)
local Progress = require(ReplicatedStorage.Shared.Progress)
local Theme = require(script.Parent.Theme)

local C = Theme.Colors
local new = Theme.new

local HUD = {}

-- How to play, on the lobby card (phones get a row of icons instead)
local STEPS_TEXT = "Walk to each station:\n💇 Hair   💄 Makeup   👗 Wardrobe\n🦸 Costume   🐶 Pet Park   💃 Pose Stage\nMatch the theme ⭐ then 📸 walk the runway!"
HUD.__index = HUD

local PHASE_LABELS = {
	Waiting = "⏳ Waiting for stylists",
	Intermission = "🌟 Next show in",
	Makeover = "💄 Makeover time!",
	Showcase = "📸 Fashion Show",
	Results = "🏆 Results",
}

function HUD.new(gui: ScreenGui, onShop: () -> (), onLookBook: () -> ())
	local self = setmetatable({}, HUD)
	self.state = { phase = "Waiting", endsAt = 0, themeId = Catalog.Themes[1].id }

	self.pill = new("Frame", {
		Name = "Timer",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.new(0.3, 0, 0, 46),
		BackgroundColor3 = C.white,
		ZIndex = 50,
		Parent = gui,
	}, { Theme.round(), Theme.stroke(C.pink, 3), new("UISizeConstraint", { MinSize = Vector2.new(220, 0) }) })
	self.pillText = new("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		Text = "",
		ZIndex = 51,
		Parent = self.pill,
	}, { Theme.maxText(26), Theme.padding(6) })

	-- Coins and shop sit in the top bar, just right of the timer
	local right = new("Frame", {
		Position = UDim2.new(0.65, 8, 0, 10),
		Size = UDim2.new(0, 206, 0, 42),
		BackgroundTransparency = 1,
		ZIndex = 50,
		Parent = gui,
	}, { new("UIListLayout", { Padding = UDim.new(0, 8), FillDirection = Enum.FillDirection.Horizontal }) })
	local coinPill = new("Frame", {
		LayoutOrder = 1,
		Size = UDim2.new(0, 100, 1, 0),
		BackgroundColor3 = C.white,
		ZIndex = 50,
		Parent = right,
	}, { Theme.round(), Theme.stroke(C.gold, 3) })
	self.coinText = new("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		Text = "💰 0",
		ZIndex = 51,
		Parent = coinPill,
	}, { Theme.maxText(24), Theme.padding(6) })
	local shop = Theme.button({
		Text = "🛍️ Shop",
		LayoutOrder = 2,
		Size = UDim2.new(0, 98, 1, 0),
		Color = C.purple,
		ZIndex = 50,
		Parent = right,
	})
	shop.Activated:Connect(onShop)
	self.shopButton = shop

	-- Stylist level, just left of the timer
	local levelPill = new("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(0.35, -8, 0, 10),
		Size = UDim2.new(0, 104, 0, 42),
		BackgroundColor3 = C.white,
		ZIndex = 50,
		Parent = gui,
	}, { Theme.round(), Theme.stroke(C.purple, 3) })
	self.levelFill = new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = C.lavender,
		ZIndex = 50,
		Parent = levelPill,
	}, { Theme.round() })
	self.levelText = new("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		Text = "⭐ Lv 1",
		ZIndex = 51,
		Parent = levelPill,
	}, { Theme.maxText(22), Theme.padding(6) })

	-- Little messages pop up near the bottom of the screen
	self.toasts = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 60),
		Size = UDim2.new(0.5, 0, 0, 200),
		BackgroundTransparency = 1,
		ZIndex = 90,
		Parent = gui,
	}, {
		new("UIListLayout", {
			Padding = UDim.new(0, 6),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Top,
		}),
	})

	-- Between rounds
	self.lobby = new("Frame", {
		Name = "Lobby",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -24),
		Size = UDim2.new(0.5, 0, 0, 262),
		BackgroundColor3 = C.white,
		BackgroundTransparency = 0.05,
		Visible = false,
		ZIndex = 40,
		Parent = gui,
	}, {
		Theme.corner(22),
		Theme.stroke(C.pink, 4),
		Theme.padding(14),
		new("UISizeConstraint", { MinSize = Vector2.new(320, 0) }),
	})
	-- The rows stack in their own frame, so the corner "My Looks" button isn't pulled into the list.
	local rows = new("Frame", {
		Name = "Rows",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 40,
		Parent = self.lobby,
	}, {
		new("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center }),
	})
	local book = Theme.button({
		-- Sits on the card's top edge, clear of the event bar.
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 0, 0, -6),
		Size = UDim2.new(0, 132, 0, 44),
		Text = "📖 My Looks",
		Color = C.purple,
		ZIndex = 45,
		MaxText = 20,
		Parent = self.lobby,
	})
	book.Activated:Connect(onLookBook)
	self.lobbyEvent = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 0,
		BackgroundColor3 = C.gold,
		TextColor3 = C.text,
		Text = "",
		Visible = false,
		LayoutOrder = 1,
		ZIndex = 41,
		Parent = rows,
	}, { Theme.round(), Theme.maxText(22), Theme.padding(4) })
	self.lobbyWeekly = new("TextLabel", {
		LayoutOrder = 3,
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 0,
		BackgroundColor3 = C.lavender,
		Text = "",
		ZIndex = 41,
		Parent = rows,
	}, { Theme.round(), Theme.maxText(20), Theme.padding(4) })
	self.lobbyTheme = new("TextLabel", {
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, 44),
		Text = "",
		TextColor3 = C.hotPink,
		ZIndex = 41,
		Parent = rows,
	}, { Theme.maxText(40) })
	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 104),
		LayoutOrder = 4,
		Name = "Steps",
		Text = STEPS_TEXT,
		TextColor3 = C.text,
		ZIndex = 41,
		Parent = rows,
	}, { Theme.maxText(20) })

	return self
end

function HUD:setState(state)
	self.state = state
	local theme = Catalog.themeById[state.themeId]
	local showLobby = state.phase == "Intermission" or state.phase == "Waiting"
	if showLobby and not self.lobby.Visible then
		Theme.pop(self.lobby)
	end
	self.lobby.Visible = showLobby
	-- On short phone screens, skip the how-to steps so the card doesn't cover everything
	local compact = self.lobby.Parent and (self.lobby.Parent :: GuiObject).AbsoluteSize.Y < 500
	local steps = (self.lobby.Rows :: any).Steps
	steps.Visible = true
	steps.Text = if compact then "💇 → 💄 → 👗 → 🦸 → 🐶 → 💃 → 📸" else STEPS_TEXT
	steps.Size = UDim2.new(1, 0, 0, if compact then 40 else 104)
	self.lobby.Size = UDim2.new(0.5, 0, 0, if compact then 196 else 262)
	-- No shopping while the 5-minute timer runs (items can still be unlocked from the menus)
	self.shopButton.Visible = state.phase ~= "Makeover"
	self.lobbyTheme.Text = "Next theme: " .. (theme and theme.name or "")
	local event = state.eventId and Events.byId[state.eventId]
	self.lobbyEvent.Visible = event ~= nil
	if event then
		self.lobbyEvent.Text = event.icon .. " " .. event.name .. " event! New looks " .. event.endsText .. " " .. event.icon
	end
end

-- "🎯 Weekly goal: 2/5 shows → 🍀 Lucky Clover"
function HUD:setWeekly(profile)
	local goal = Config.WEEKLY_GOAL_SHOWS
	local done = math.min(profile.weekShows or 0, goal)
	if profile.weekClaimed then
		self.lobbyWeekly.Text = "🎯 Weekly goal done! New prize next week 🎁"
	else
		local prize = profile.weeklyNext and Catalog.byId[profile.weeklyNext]
		local prizeText = if prize then (prize.icon or "🎁") .. " " .. prize.name else Config.WEEKLY_GOAL_COINS .. " 💰"
		self.lobbyWeekly.Text = "🎯 Weekly goal: " .. done .. "/" .. goal .. " shows → " .. prizeText
	end
end

function HUD:setCoins(coins: number)
	self.coinText.Text = "💰 " .. tostring(coins)
end

function HUD:setLevel(totalStars: number)
	self.levelText.Text = "⭐ Lv " .. Progress.level(totalStars)
	self.levelFill.Size = UDim2.fromScale(Progress.fraction(totalStars), 1)
end

function HUD:toast(message: string, color: Color3?)
	local toast = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = color or C.hotPink,
		BackgroundTransparency = 0,
		TextColor3 = C.white,
		Text = message,
		ZIndex = 91,
		Parent = self.toasts,
	}, { Theme.round(), Theme.maxText(22), Theme.padding(6) })
	Theme.pop(toast)
	task.delay(3, function()
		local fade = TweenInfo.new(0.4)
		TweenService:Create(toast, fade, { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
		task.wait(0.45)
		toast:Destroy()
	end)
end

function HUD:secondsLeft(): number
	return self.state.endsAt - Workspace:GetServerTimeNow()
end

-- Called every frame to tick the timer.
function HUD:update()
	local phase = self.state.phase
	local left = self:secondsLeft()
	local label = PHASE_LABELS[phase] or phase
	if phase == "Waiting" or phase == "Showcase" or phase == "Results" then
		self.pillText.Text = label
	else
		self.pillText.Text = label .. "  " .. Theme.formatTime(left)
	end
	local hurry = phase == "Makeover" and left <= 30
	self.pillText.TextColor3 = if hurry then C.red else C.text
	if hurry then
		local pulse = 1 + 0.04 * math.sin(os.clock() * 10)
		self.pill.Size = UDim2.new(0.3 * pulse, 0, 0, 46)
	else
		self.pill.Size = UDim2.new(0.3, 0, 0, 46)
	end
end

return HUD
