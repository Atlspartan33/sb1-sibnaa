-- Shows who won the fashion show, what the judges said, and the coins you earned.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.Catalog)
local LookRenderer = require(ReplicatedStorage.Shared.LookRenderer)
local Effects = require(script.Parent.Effects)
local Theme = require(script.Parent.Theme)

local C = Theme.Colors
local new = Theme.new

local Results = {}
Results.__index = Results

local MEDALS = { "🥇", "🥈", "🥉" }

function Results.new(gui: ScreenGui)
	local self = setmetatable({}, Results)
	self.gui = gui
	self.panel = new("Frame", {
		Name = "Results",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.55, 0),
		Size = UDim2.new(0.4, 0, 0.78, 0),
		BackgroundColor3 = C.white,
		Visible = false,
		ZIndex = 40,
		Parent = gui,
	}, { Theme.corner(24), Theme.stroke(C.gold, 4), Theme.padding(14), new("UISizeConstraint", { MinSize = Vector2.new(320, 0) }) })

	self.title = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 40),
		Text = "🏆 Fashion Show Results",
		TextColor3 = C.hotPink,
		ZIndex = 41,
		Parent = self.panel,
	}, { Theme.maxText(32) })
	-- Your own client, big, with what the judges said (only you see this)
	local mineCard = new("Frame", {
		Position = UDim2.new(0, 0, 0, 44),
		Size = UDim2.new(1, 0, 0, 130),
		BackgroundColor3 = C.softPink,
		ZIndex = 41,
		Parent = self.panel,
	}, { Theme.corner(14) })
	self.minePortrait = new("Frame", {
		Position = UDim2.new(0, 6, 0, 6),
		Size = UDim2.new(0, 118, 0, 118),
		BackgroundColor3 = C.white,
		ZIndex = 42,
		Parent = mineCard,
	}, { Theme.corner(12) })
	self.mine = new("TextLabel", {
		Position = UDim2.new(0, 130, 0, 0),
		Size = UDim2.new(1, -134, 1, 0),
		Text = "",
		TextWrapped = true,
		ZIndex = 42,
		Parent = mineCard,
	}, { Theme.maxText(19), Theme.padding(6) })
	self.list = new("ScrollingFrame", {
		Position = UDim2.new(0, 0, 0, 182),
		Size = UDim2.new(1, 0, 1, -182),
		BackgroundTransparency = 1,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = 41,
		Parent = self.panel,
	}, { new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })
	return self
end

function Results:show(results)
	local theme = Catalog.themeById[results.themeId]
	self.title.Text = "🏆 Results: " .. (theme and theme.name or "")
	for _, child in self.list:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	self.mine.Text = "Watch the show, then style a client next round! 👀"
	local old = self.minePortrait:FindFirstChild("Portrait")
	if old then
		old:Destroy()
	end
	for _, row in results.rows do
		local isMe = row.userId == Players.LocalPlayer.UserId
		if isMe then
			local comments = table.concat(row.comments, "  ", 1, math.min(#row.comments, 3))
			self.mine.Text = string.format("Your %s: %s\n%s  +%d 🪙\n%s", row.client.name, Theme.stars(row.stars), row.award or "", row.coins, comments)
			LookRenderer.render(self.minePortrait, row.client, row.look, { clean = 1, mood = if row.stars >= 4 then "grin" else "smile" })
			self:celebrate(row, #results.rows)
		end

		local card = new("Frame", {
			LayoutOrder = row.rank,
			Size = UDim2.new(1, -8, 0, 76),
			BackgroundColor3 = if isMe then C.softPink else C.lavender,
			ZIndex = 42,
			Parent = self.list,
		}, { Theme.corner(14) })
		new("TextLabel", {
			Position = UDim2.new(0, 6, 0, 0),
			Size = UDim2.new(0, 44, 1, 0),
			-- top 3 get a medal; everyone else shows their award's emoji (never a "last place" number)
			Text = MEDALS[row.rank] or (string.match(row.award or "", "^(%S+)") or "💖"),
			ZIndex = 43,
			Parent = card,
		}, { Theme.maxText(34) })
		local face = new("Frame", {
			Position = UDim2.new(0, 54, 0, 4),
			Size = UDim2.new(0, 68, 0, 68),
			BackgroundColor3 = C.white,
			ZIndex = 43,
			Parent = card,
		}, { Theme.corner(12) })
		LookRenderer.render(face, row.client, row.look, { clean = 1, mood = if row.stars >= 4 then "grin" else "smile" })
		new("TextLabel", {
			Position = UDim2.new(0, 130, 0, 6),
			Size = UDim2.new(1, -136, 0, 32),
			Text = row.stylist .. "'s " .. row.client.name,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 43,
			Parent = card,
		}, { Theme.maxText(22) })
		new("TextLabel", {
			Position = UDim2.new(0, 130, 0, 40),
			Size = UDim2.new(1, -136, 0, 30),
			-- Everyone sees the award; stars only show when they're great (or it's your own look)
			Text = (row.award or "") .. (if row.stars >= 4 or isMe then "  " .. Theme.stars(row.stars) else ""),
			TextColor3 = C.gold,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 43,
			Parent = card,
		}, { Theme.maxText(24) })
	end

	self.panel.Visible = true
	Theme.pop(self.panel)
end

-- A big pop-up for your own result, with confetti for good scores.
function Results:celebrate(row, players: number)
	local title
	if players >= 2 and row.rank == 1 then
		title = "🏆 You WON! 🏆"
	elseif players >= 2 and row.rank <= 3 then
		title = MEDALS[row.rank] .. " #" .. row.rank .. " Place!"
	elseif row.stars >= 4.5 then
		title = "😍 STUNNING!"
	elseif row.stars >= 3 then
		title = "✨ Great job!"
	else
		title = "💪 Nice try!"
	end
	Effects.splash(self.gui, title, Theme.stars(row.stars) .. "   +" .. row.coins .. " 🪙", C.hotPink, 3)
	if row.stars >= 3.5 or (players >= 2 and row.rank == 1) then
		Effects.confetti(self.gui, 60)
	end
end

function Results:hide()
	self.panel.Visible = false
end

return Results
