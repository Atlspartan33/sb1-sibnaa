-- Starts the game on each player's screen and connects it to the server.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local UI = script.Parent:WaitForChild("UI")
local Catalog = require(ReplicatedStorage.Shared.Catalog)
local Effects = require(UI.Effects)
local HUD = require(UI.HUD)
local Makeover = require(UI.Makeover)
local Results = require(UI.Results)
local Shop = require(UI.Shop)
local Showcase = require(UI.Showcase)
local Sounds = require(UI.Sounds)
local Theme = require(UI.Theme)

local gui = Instance.new("ScreenGui")
gui.Name = "GlowUpUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local state = { phase = "Waiting", endsAt = 0, themeId = "", eventId = nil :: string? }
local hud, shop

-- Shared helpers every screen can use
local ctx = {
	profile = { coins = 0, owned = {}, passes = {}, totalStars = 0, lookbook = {} } :: any,
	state = function()
		return state
	end,
	toast = function(message: string, color: Color3?)
		hud:toast(message, color)
	end,
	askUnlock = function(item)
		shop:askUnlock(item)
	end,
	promptProduct = function(key: string)
		shop:askProduct(key)
	end,
	-- the server decides the event when a round starts, so use that (not this device's clock)
	eventId = function(): string?
		return state.eventId
	end,
	isModalOpen = function(): boolean
		return shop.overlay.Visible or shop.confirm.Visible
	end,
}

hud = HUD.new(gui, function()
	shop:open()
end, function()
	shop:open("Looks")
end)
shop = Shop.new(gui, ctx)
local makeover = Makeover.new(gui, ctx)
local showcase = Showcase.new(gui, ctx)
local results = Results.new(gui)

Theme.onClick = function()
	Sounds.play("Click")
end

-- While styling, touching the screen should only wash and style, not walk the character around.
local function setCharacterControls(enabled: boolean)
	pcall(function()
		local module = Players.LocalPlayer:WaitForChild("PlayerScripts"):FindFirstChild("PlayerModule")
		if module then
			local controls = (require :: any)(module):GetControls()
			if enabled then
				controls:Enable()
			else
				controls:Disable()
			end
		end
	end)
	pcall(function()
		GuiService.TouchControlsEnabled = enabled
	end)
end

local function applyState(newState)
	local oldPhase = state.phase
	state = newState
	hud:setState(state)
	if state.phase ~= oldPhase and (state.phase == "Makeover" or oldPhase == "Makeover") then
		setCharacterControls(state.phase ~= "Makeover")
	end
	Sounds.music(if state.phase == "Makeover" then "MakeoverMusic" elseif state.phase == "Showcase" then "RunwayMusic" else nil)

	makeover:setVisible(state.phase == "Makeover")
	if state.phase ~= "Showcase" then
		showcase:hide()
	end
	if state.phase ~= "Results" then
		results:hide()
	end
	if state.phase == "Results" then
		showcase:setCamera("Results")
	elseif state.phase ~= "Showcase" then
		showcase:setCamera(nil)
	end
	if state.phase == "Intermission" and oldPhase ~= "Intermission" then
		showcase:setScreen("✨ 5 Minute Glow Up ✨", "Next show starting soon!", nil, nil)
		showcase:clearScreenPortrait()
	end
	if state.phase == "Makeover" and oldPhase ~= "Makeover" then
		local theme = Catalog.themeById[state.themeId]
		Effects.splash(gui, "5 minutes! GO! 💨", theme and ("Theme: " .. theme.name) or nil, Theme.Colors.purple, 2.2)
	end
end

Remotes.State.OnClientEvent:Connect(applyState)

Remotes.AssignClient.OnClientEvent:Connect(function(payload)
	makeover:assign(payload)
	makeover:setVisible(state.phase == "Makeover")
end)

Remotes.Showcase.OnClientEvent:Connect(function(payload)
	showcase:show(payload)
end)

Remotes.Results.OnClientEvent:Connect(function(payload)
	results:show(payload)
	local winner = payload.rows[1]
	if winner then
		-- Shown to everyone: always the happy, washed look and an award (never low stars)
		showcase:setScreen("🏆 " .. winner.stylist .. " wins!", winner.client.name .. "  " .. (winner.award or ""), winner.client, winner.look, 1)
	end
end)

Remotes.Profile.OnClientEvent:Connect(function(profile)
	local lookbookChanged = profile.lookbook ~= nil
	if not lookbookChanged then
		profile.lookbook = ctx.profile.lookbook -- unchanged, so it wasn't sent again
	end
	ctx.profile = profile
	hud:setCoins(profile.coins)
	hud:setLevel(profile.totalStars or 0)
	hud:setWeekly(profile)
	makeover:refreshProfile()
	shop:refreshProfile(lookbookChanged)
end)

Remotes.Reaction.OnClientEvent:Connect(function(emoji)
	showcase:reaction(emoji)
end)

Remotes.Celebrate.OnClientEvent:Connect(function(info)
	if info.kind == "daily" then
		local title = if info.item then "🎁 Day 7: " .. info.item .. "!" else "🎁 Day " .. info.day .. " Gift! +" .. info.coins .. " 💰"
		-- The 7-day calendar row
		Effects.splash(gui, title, " ", Theme.Colors.gold, 4, function(card)
			local row = Theme.new("Frame", {
				Position = UDim2.fromScale(0, 0.62),
				Size = UDim2.fromScale(1, 0.36),
				BackgroundTransparency = 1,
				ZIndex = 262,
				Parent = card,
			}, {
				Theme.new("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					Padding = UDim.new(0.015, 0),
				}),
			})
			for d = 1, 7 do
				local past, today = d < info.day, d == info.day
				Theme.new("TextLabel", {
					LayoutOrder = d,
					Size = UDim2.fromScale(0.125, 1),
					BackgroundTransparency = 0,
					BackgroundColor3 = if today then Theme.Colors.gold elseif past then Theme.Colors.green else Theme.Colors.lavender,
					TextColor3 = if today or past then Theme.Colors.white else Theme.Colors.text,
					Text = if past then "✓" elseif d == 7 then "🎁" else tostring(d),
					ZIndex = 263,
					Parent = row,
				}, { Theme.corner(10), Theme.maxText(30) })
			end
		end)
		Effects.confetti(gui, 40)
	elseif info.kind == "weekly" then
		Effects.splash(gui, "🎯 Weekly goal done!", if info.item then "You got the " .. info.item .. "! 🎁" else "+" .. info.coins .. " 💰", Theme.Colors.purple, 4)
		Effects.confetti(gui, 60)
	elseif info.kind == "friend" then
		Effects.splash(gui, "💞 " .. info.name .. " is your BEST friend!", "Visit #" .. info.visits .. "  +" .. info.coins .. " 💰", Theme.Colors.hotPink, 3.5)
		Effects.confetti(gui, 40)
	elseif info.kind == "level" then
		Effects.splash(gui, "⭐ Level " .. info.level .. "! ⭐", "You're a " .. info.title .. "!", Theme.Colors.purple, 3.5)
		Effects.confetti(gui, 60)
	end
end)

Remotes.Notify.OnClientEvent:Connect(function(message)
	hud:toast(message)
end)

-- Catch up on whatever is happening right now
task.spawn(function()
	local snapshot = Remotes.Hello:InvokeServer()
	if snapshot.entry then
		makeover:assign(snapshot.entry)
	end
	applyState(snapshot.state)
	if snapshot.showcase then
		showcase:show(snapshot.showcase)
	end
	if snapshot.results then
		results:show(snapshot.results)
	end
end)

RunService.RenderStepped:Connect(function()
	hud:update()
	showcase:updateWalkers()
	showcase:followWalker()
end)
