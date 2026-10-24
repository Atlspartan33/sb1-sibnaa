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

local state = { phase = "Waiting", endsAt = 0, themeId = "" }
local hud, shop

-- Shared helpers every screen can use
local ctx = {
	profile = { coins = 0, owned = {}, passes = {}, superSoaps = 0 },
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
	isModalOpen = function(): boolean
		return shop.overlay.Visible or shop.confirm.Visible
	end,
}

hud = HUD.new(gui, function()
	shop:open()
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
		showcase:setScreen("🏆 " .. winner.stylist .. " wins!", winner.client.name .. " - " .. Theme.stars(winner.stars), winner.client, winner.look, winner.clean)
	end
end)

Remotes.Profile.OnClientEvent:Connect(function(profile)
	ctx.profile = profile
	hud:setCoins(profile.coins)
	hud:setLevel(profile.totalStars or 0)
	makeover:refreshProfile()
	shop:refreshProfile()
end)

Remotes.PowerUp.OnClientEvent:Connect(function(kind)
	if kind == "SuperSoap" then
		makeover:superSoap()
		hud:toast("Super Soap! Squeaky clean in one swipe! 🧼✨", Theme.Colors.green)
	end
end)

Remotes.Reaction.OnClientEvent:Connect(function(emoji)
	showcase:reaction(emoji)
end)

Remotes.Celebrate.OnClientEvent:Connect(function(info)
	if info.kind == "daily" then
		local streak = if info.streak > 1 then "Day " .. info.streak .. " in a row! 🔥" else "Come back tomorrow for more!"
		Effects.splash(gui, "🎁 Daily Gift! +" .. info.coins .. " 🪙", streak, Theme.Colors.gold, 3.5)
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
