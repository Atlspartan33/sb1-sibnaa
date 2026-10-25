-- Starts the game on each player's screen and connects it to the server.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Avatar = require(ReplicatedStorage.Shared.Avatar)
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
	-- You walk around the Dressing Hall while getting ready and between rounds; during the show and
	-- the results you sit in the audience (or stand on the podium), so your controls rest
	local canWalk = state.phase ~= "Showcase" and state.phase ~= "Results"
	if state.phase ~= oldPhase then
		setCharacterControls(canWalk)
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

Remotes.Reaction.OnClientEvent:Connect(function(emoji, cheers, goal)
	showcase:reaction(emoji, cheers, goal)
end)

-- You grabbed one of the lobby stars
Remotes.Collected.OnClientEvent:Connect(function(coins)
	Sounds.play("Sparkle", 0.8)
	Effects.floatEmoji(gui, "⭐")
	Effects.floatEmoji(gui, "💰")
	hud:toast("⭐ You found a star! +" .. tostring(coins) .. " 💰")
end)

Remotes.Celebrate.OnClientEvent:Connect(function(info)
	if info.kind == "daily" then
		local title = if info.item then "🎁 Day 7: " .. info.item .. "!" else "🎁 Day " .. info.day .. " Gift! +" .. info.coins .. " 💰"
		-- The 7-day calendar row
		Effects.splash(gui, title, " ", Theme.Colors.goldText, 4, function(card)
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
		local unlocked = {}
		for _, category in Catalog.Categories do
			for _, it in category.items do
				if it.level == info.level then
					table.insert(unlocked, it.name)
				end
			end
		end
		local subtitle = if #unlocked > 0 then "You unlocked: " .. table.concat(unlocked, ", ") .. "! Try it on next round!" else "You're a " .. info.title .. "!"
		Effects.splash(gui, "⭐ Level " .. info.level .. "! ⭐", subtitle, Theme.Colors.purple, 4.5)
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

-- The server asks this screen to walk your character down the runway and to strike poses (your
-- own device moves your character, so it has to happen here).
local function watchCharacter(character: Model)
	character:GetAttributeChangedSignal("WalkTarget"):Connect(function()
		local target = character:GetAttribute("WalkTarget")
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			if typeof(target) == "Vector3" then
				local speed = character:GetAttribute("RunwaySpeed")
				humanoid.WalkSpeed = if type(speed) == "number" then speed else 10
				humanoid:MoveTo(target)
			else
				humanoid.WalkSpeed = 16
				local root = character:FindFirstChild("HumanoidRootPart")
				if root and root:IsA("BasePart") then
					-- a twirl at the end of the runway, ending face to the crowd
					task.spawn(function()
						local pos = root.Position
						for i = 1, 16 do
							root.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.pi + i / 16 * math.pi * 2, 0)
							task.wait(0.05)
						end
						root.CFrame = CFrame.lookAt(pos, pos + Vector3.new(0, 0, 1))
					end)
				end
			end
		end
	end)
	character:GetAttributeChangedSignal("Pose"):Connect(function()
		local value = character:GetAttribute("Pose")
		local poseId = type(value) == "string" and string.match(value, "^[^|]+")
		if poseId then
			Avatar.pose(character, poseId)
		end
	end)
end
Players.LocalPlayer.CharacterAdded:Connect(watchCharacter)
if Players.LocalPlayer.Character then
	watchCharacter(Players.LocalPlayer.Character)
end

-- Step onto the dance floor and you dance (everyone sees it); step off and you stop.
local danceTrack: AnimationTrack? = nil
local function updateDance()
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local floor = workspace:FindFirstChild("GlowUpWorld") and workspace.GlowUpWorld:FindFirstChild("DanceFloor", true)
	local center, radius = floor and floor:GetAttribute("Center"), floor and floor:GetAttribute("Radius")
	local on = false
	if root and root:IsA("BasePart") and typeof(center) == "Vector3" and type(radius) == "number" then
		on = Vector3.new(root.Position.X - center.X, 0, root.Position.Z - center.Z).Magnitude <= radius and state.phase ~= "Showcase"
	end
	if on and not danceTrack then
		local animator = character:FindFirstChildOfClass("Humanoid") and character:FindFirstChildOfClass("Humanoid"):FindFirstChildOfClass("Animator")
		if animator then
			local anim = Instance.new("Animation")
			anim.AnimationId = "rbxassetid://507771019" -- Roblox's default dance
			local ok, track = pcall(function()
				return animator:LoadAnimation(anim)
			end)
			if ok and track then
				track.Looped = true
				track:Play(0.3)
				danceTrack = track
			end
		end
	elseif not on and danceTrack then
		danceTrack:Stop(0.3)
		danceTrack = nil
	end
end

-- The photo booth: stand on the gold pad for a 3-2-1, a flash, your pose and a polaroid frame.
local inBooth, snapping = false, false
local BOOTH_PHASES = { Makeover = true, Intermission = true, Waiting = true }
local function snapPhoto(center: Vector3)
	snapping = true
	local phase = state.phase
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	-- the photographer stands in front of the booth, so the picture is of their face, not the back of their head
	local camera = workspace.CurrentCamera
	local lens = center + Vector3.new(0, 5, 9)
	camera.CameraType = Enum.CameraType.Scriptable
	local shot = CFrame.lookAt(lens, center + Vector3.new(0, 3.5, 0))
	camera.CFrame = shot
	local number: TextLabel? = nil
	local photo: ScreenGui? = nil
	local function finish()
		if number then
			number:Destroy()
		end
		if photo then
			photo:Destroy()
		end
		gui.Enabled = true
		if camera.CameraType == Enum.CameraType.Scriptable and camera.CFrame == shot then -- (unless the show took the camera meanwhile)
			camera.CameraType = Enum.CameraType.Custom
		end
		snapping = false
	end
	-- the round moved on (the show is starting): stop right away
	local function interrupted(): boolean
		return state.phase ~= phase
	end
	local function faceCamera()
		if root and root:IsA("BasePart") and root.Parent then
			root.CFrame = CFrame.lookAt(root.Position, Vector3.new(lens.X, root.Position.Y, lens.Z))
		end
	end
	-- a big 3-2-1 off to the side (a card in the middle would cover the kid)
	for _, n in { "3", "2", "1" } do
		faceCamera()
		local outline = Theme.stroke(Theme.Colors.hotPink, 6)
		outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		local label = Theme.new("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.8, 0.45),
			Size = UDim2.fromScale(0.2, 0.3),
			Text = n,
			TextColor3 = Theme.Colors.white,
			ZIndex = 260,
			Parent = gui,
		}, { outline })
		number = label
		Theme.pop(label)
		Sounds.play("Pop", 0.5)
		task.wait(0.8)
		label:Destroy()
		number = nil
		if interrupted() then
			finish()
			return
		end
	end
	faceCamera()
	if character then
		local pose = makeover.look and makeover.look.pose
		Avatar.pose(character, if pose and not Catalog.isNone(pose) then pose else "pose_cheer")
	end
	-- the picture: just you, in a white polaroid border with a caption strip (the game's buttons step aside)
	local theme = Catalog.themeById[state.themeId]
	photo = Instance.new("ScreenGui")
	local frame = photo :: ScreenGui
	frame.Name = "GlowUpPhoto"
	frame.IgnoreGuiInset = true
	frame.DisplayOrder = 20
	frame.Parent = gui.Parent
	gui.Enabled = false
	Effects.flash(frame)
	local polaroid = Theme.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = frame,
	}, { Theme.stroke(Theme.Colors.white, 18) })
	Theme.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.new(1, 0, 0, 76),
		BackgroundColor3 = Theme.Colors.white,
		Parent = polaroid,
	}, {
		Theme.new("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			Text = "📸 " .. Players.LocalPlayer.DisplayName .. (if theme then "  •  " .. theme.name else ""),
			TextColor3 = Theme.Colors.hotPink,
		}, { Theme.padding(12), Theme.maxText(40) }),
	})
	local started = os.clock()
	while os.clock() - started < 3 and not interrupted() do
		task.wait(0.1)
	end
	finish()
end
local function updateBooth()
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local atmosphere = workspace:FindFirstChild("GlowUpWorld") and workspace.GlowUpWorld:FindFirstChild("Atmosphere", true)
	local center = atmosphere and atmosphere:GetAttribute("BoothCenter")
	local on = false
	if root and root:IsA("BasePart") and typeof(center) == "Vector3" then
		on = Vector3.new(root.Position.X - center.X, 0, root.Position.Z - center.Z).Magnitude <= 2.5
	end
	-- (not in the last few seconds of a phase: the photo would run into the show)
	local timeLeft = state.endsAt - workspace:GetServerTimeNow()
	if on and not inBooth and not snapping and BOOTH_PHASES[state.phase] and (state.phase == "Waiting" or timeLeft > 8) then
		task.spawn(snapPhoto, center :: Vector3)
	end
	inBooth = on
end

RunService.RenderStepped:Connect(function()
	hud:update()
	showcase:updateWalkers()
	showcase:followWalker()
	updateDance()
	updateBooth()
end)
