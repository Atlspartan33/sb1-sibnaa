-- The fashion show: points the camera at the runway, puts the look on the big screen,
-- and lets everyone else rate it with stars.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Catalog = require(ReplicatedStorage.Shared.Catalog)
local LookRenderer = require(ReplicatedStorage.Shared.LookRenderer)
local Pets = require(ReplicatedStorage.Shared.Pets)
local Progress = require(ReplicatedStorage.Shared.Progress)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Effects = require(script.Parent.Effects)
local Theme = require(script.Parent.Theme)

local C = Theme.Colors
local new = Theme.new

local Showcase = {}
Showcase.__index = Showcase

local CHEERS = { "😍", "👏", "🔥", "✨", "💖" }

function Showcase.new(gui: ScreenGui, ctx)
	local self = setmetatable({}, Showcase)
	self.ctx = ctx
	self.current = nil

	self.panel = new("Frame", {
		Name = "Showcase",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12),
		Size = UDim2.new(0.5, 0, 0, 196),
		BackgroundColor3 = C.white,
		Visible = false,
		ZIndex = 40,
		Parent = gui,
	}, { Theme.corner(22), Theme.stroke(C.pink, 4), Theme.padding(12), new("UISizeConstraint", { MinSize = Vector2.new(340, 0) }) })
	self.title = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 36),
		Text = "",
		TextColor3 = C.hotPink,
		ZIndex = 41,
		Parent = self.panel,
	}, { Theme.maxText(30) })
	self.prompt = new("TextLabel", {
		Position = UDim2.new(0, 0, 0, 38),
		Size = UDim2.new(1, 0, 0, 26),
		Text = "",
		ZIndex = 41,
		Parent = self.panel,
	}, { Theme.maxText(20) })

	local row = new("Frame", {
		Position = UDim2.new(0, 0, 0, 68),
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundTransparency = 1,
		ZIndex = 41,
		Parent = self.panel,
	}, {
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 8),
		}),
	})
	self.starRow = row
	self.voteButtons = {}
	-- Kind voting: every choice is nice. 💖 = 3 stars, 💖💖 = 4, 💖💖💖 = 5
	for i, choice in { { 3, "💖", "Cute!" }, { 4, "💖💖", "So pretty!" }, { 5, "💖💖💖", "WOW!" } } do
		local b = Theme.button({
			Text = choice[2] .. " " .. choice[3],
			Size = UDim2.new(0.3, 0, 1, 0),
			Color = C.softPink,
			TextColor3 = C.hotPink,
			ZIndex = 42,
			MaxText = 24,
			Parent = row,
		})
		b.LayoutOrder = i
		b.Activated:Connect(function()
			self:vote(choice[1])
		end)
		self.voteButtons[choice[1]] = b
	end

	-- Cheer buttons: everyone can tap these, and the emoji float up on every screen
	local cheers = new("Frame", {
		Name = "Cheers",
		Position = UDim2.new(0, 0, 0, 128),
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundTransparency = 1,
		ZIndex = 41,
		Parent = self.panel,
	}, {
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 10),
		}),
	})
	self.cheerRow = cheers
	for i, emoji in CHEERS do
		local b = Theme.button({
			Text = emoji,
			LayoutOrder = i,
			Size = UDim2.new(0, 60, 1, 0),
			Color = C.softPink,
			ZIndex = 42,
			MaxText = 34,
			Parent = cheers,
		})
		b.Activated:Connect(function()
			Remotes.React:FireServer(emoji)
		end)
	end
	self.gui = gui

	task.spawn(function()
		self:buildScreen()
	end)
	return self
end

------------------------------------------------------------------------------
-- Big screen behind the runway

function Showcase:buildScreen()
	-- WaitForChild in case the place streams parts in later
	local part = Workspace:WaitForChild("GlowUpWorld"):WaitForChild("Runway"):WaitForChild("Screen")
	local surface = new("SurfaceGui", {
		Name = "RunwayScreen",
		Adornee = part,
		Face = Enum.NormalId.Back,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = 25,
		LightInfluence = 0,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})
	local bg = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(40, 20, 60),
		Parent = surface,
	}, { Theme.gradient(Color3.fromRGB(70, 30, 100), Color3.fromRGB(20, 10, 35)) })
	self.screenPortrait = new("Frame", {
		Position = UDim2.fromScale(0.04, 0.06),
		Size = UDim2.fromScale(0.45, 0.88),
		BackgroundColor3 = Color3.fromRGB(255, 235, 245),
		Parent = bg,
	}, { new("UIAspectRatioConstraint", { AspectRatio = 1 }), Theme.corner(40) })
	self.screenTitle = new("TextLabel", {
		Position = UDim2.fromScale(0.5, 0.05),
		Size = UDim2.fromScale(0.46, 0.2),
		TextColor3 = C.white,
		Text = "✨ 5 Minute Glow Up ✨",
		Parent = bg,
	})
	self.screenSub = new("TextLabel", {
		Position = UDim2.fromScale(0.5, 0.26),
		Size = UDim2.fromScale(0.46, 0.13),
		TextColor3 = C.pink,
		Text = "",
		Parent = bg,
	})
	self.screenTheme = new("TextLabel", {
		Position = UDim2.fromScale(0.5, 0.41),
		Size = UDim2.fromScale(0.46, 0.1),
		TextColor3 = C.gold,
		Text = "",
		Parent = bg,
	})
end

function Showcase:setScreen(title: string, sub: string, client, look, clean: number?)
	if not self.screenTitle then
		return
	end
	self.screenTitle.Text = title
	self.screenSub.Text = sub
	local theme = Catalog.themeById[self.ctx.state().themeId]
	self.screenTheme.Text = if theme then "Theme: " .. theme.name else ""
	if client and look then
		local holder = self.screenPortrait:FindFirstChild("Idle")
		if holder then
			holder:Destroy()
		end
		LookRenderer.render(self.screenPortrait, client, look, { clean = clean or 1, mood = "grin" })
	end
end

-- Between shows the big screen shows sparkles instead of the last client.
function Showcase:clearScreenPortrait()
	if not self.screenPortrait then
		return
	end
	local old = self.screenPortrait:FindFirstChild("Portrait")
	if old then
		old:Destroy()
	end
	if not self.screenPortrait:FindFirstChild("Idle") then
		new("TextLabel", { Name = "Idle", Size = UDim2.fromScale(1, 1), Text = "💄✨👗", Parent = self.screenPortrait }, { Theme.maxText(200) })
	end
end

------------------------------------------------------------------------------
-- Camera

function Showcase:setCamera(view: string?)
	local camera = Workspace.CurrentCamera
	local world = Workspace:FindFirstChild("GlowUpWorld")
	local marker = view and world and world:FindFirstChild("Cameras") and world.Cameras:FindFirstChild(view)
	self.view = view
	if marker then
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = marker.CFrame
	else
		camera.CameraType = Enum.CameraType.Custom
	end
end

-- Each runway or podium look with a pet gets that pet trotting next to it, on this screen.
function Showcase:updatePets(world: Instance)
	local t = os.clock()
	local dt = math.min(t - (self.petClock or t), 0.1)
	self.petClock = t
	self.pets = self.pets or {}
	for owner, pet in self.pets do
		if not owner.Parent then
			pet:Destroy()
			self.pets[owner] = nil
		end
	end
	for _, m in world:GetChildren() do
		local petId = m:IsA("Model") and m:GetAttribute("Pet")
		if type(petId) == "string" and not Catalog.isNone(petId) then
			local pet = self.pets[m]
			if not pet then
				pet = Pets.build(petId)
				if not pet then
					continue
				end
				local root = m:FindFirstChild("HumanoidRootPart")
				if root and root:IsA("BasePart") then
					pet:PivotTo(root.CFrame * CFrame.new(2.6, -3, 0.6))
				end
				pet.Parent = Workspace
				self.pets[m] = pet
			end
			Pets.follow(pet, m, dt)
		end
	end
end

-- Moves runway models smoothly on this screen, using the walk the server described in attributes.
function Showcase:updateWalkers()
	local world = Workspace:FindFirstChild("GlowUpWorld")
	if not world then
		return
	end
	self:updatePets(world)
	local now = Workspace:GetServerTimeNow()
	for _, m in world:GetChildren() do
		local from, to, start, walkTime = m:GetAttribute("WalkFrom"), m:GetAttribute("WalkTo"), m:GetAttribute("WalkStart"), m:GetAttribute("WalkTime")
		local root = m:FindFirstChild("HumanoidRootPart")
		if typeof(from) == "Vector3" and typeof(to) == "Vector3" and type(start) == "number" and type(walkTime) == "number" and root and root:IsA("BasePart") then
			local t = now - start
			local forward = Vector3.new(0, 0, 1)
			local bob, squeeze = 0, 1
			if t < walkTime then
				local pos = from:Lerp(to, math.max(t, 0) / walkTime)
				root.CFrame = CFrame.lookAt(pos, pos + forward)
				bob = 0.15 * math.abs(math.sin(t * 7)) -- a bouncy little walk
			elseif t < walkTime + 1 then
				-- twirl! (the paper doll squeezes thin and back, like turning around)
				local angle = (t - walkTime) * math.pi * 2
				root.CFrame = CFrame.lookAt(to, to + forward) * CFrame.Angles(0, angle, 0)
				squeeze = math.abs(math.cos(angle))
			else
				root.CFrame = CFrame.lookAt(to, to + forward)
			end
			local billboard = root:FindFirstChild("Doll")
			if billboard and billboard:IsA("BillboardGui") then
				local baseY = billboard:GetAttribute("BaseY")
				if type(baseY) ~= "number" then
					baseY = billboard.StudsOffset.Y
					billboard:SetAttribute("BaseY", baseY)
				end
				billboard.StudsOffset = Vector3.new(0, baseY + bob, 0)
				local doll = billboard:FindFirstChild("Doll", true)
				local aspect = doll and doll:FindFirstChildOfClass("UIAspectRatioConstraint")
				if aspect then
					aspect.AspectRatio = math.max(0.03, 0.5 * squeeze)
				end
			end
		end
	end
end

-- During the show the camera glides along next to the client walking the runway.
function Showcase:followWalker()
	if self.view ~= "Showcase" then
		return
	end
	local world = Workspace:FindFirstChild("GlowUpWorld")
	if not world then
		return
	end
	-- the player walking the runway in their own avatar (or a stand-in model if they left)
	local walker = nil
	for _, player in Players:GetPlayers() do
		if player.Character and player.Character:GetAttribute("Walking") then
			walker = player.Character
		end
	end
	for _, m in world:GetChildren() do
		if m:IsA("Model") and m:GetAttribute("Walking") then
			walker = m
		end
	end
	local root = walker and walker:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		local pos = root.Position
		-- aimed below the walker, so they're in the top of the screen above the voting card
		local goal = CFrame.lookAt(pos + Vector3.new(6, 4, 14), pos + Vector3.new(0, -2.4, 0))
		local camera = Workspace.CurrentCamera
		camera.CFrame = camera.CFrame:Lerp(goal, 0.08)
	end
end

------------------------------------------------------------------------------
-- Voting

function Showcase:showVote(stars: number)
	for value, b in self.voteButtons do
		b.BackgroundColor3 = if value == stars then C.hotPink else C.softPink
		b.TextColor3 = if value == stars then C.white else C.hotPink
	end
end

function Showcase:vote(stars: number)
	local current = self.current
	if not current or current.userId == Players.LocalPlayer.UserId then
		return
	end
	local first = not self.voted
	self.voted = true
	self:showVote(stars)
	Remotes.Vote:FireServer(current.userId, stars)
	self.prompt.Text = "Thanks for voting! 💖 Tap to cheer!"
	if first then
		self.ctx.toast("+2 💰 for voting!", C.green)
	end
end

function Showcase:show(payload)
	self.current = payload
	self.voted = false
	self:showVote(0)
	self.panel.Visible = true
	Theme.pop(self.panel)
	self:setCamera("Showcase")

	local mine = payload.userId == Players.LocalPlayer.UserId
	self.title.Text = "💃 " .. payload.client.name .. " is on the runway! (" .. payload.index .. "/" .. payload.total .. ")"
	local level = payload.level or 1
	local stylist = "Styled by " .. payload.stylist .. (if payload.vip then " 👑" else "") .. "  •  Lv " .. level .. " " .. Progress.title(level)
	-- The card stays short so it doesn't hide the walk; it only grows for the vote buttons
	if mine then
		self.prompt.Text = "That's YOU! Strike a pose! 📸"
		self.starRow.Visible = false
	else
		self.prompt.Text = "How much do you love it?"
		self.starRow.Visible = true
	end
	-- on short (phone) screens the prompt line goes, so the card stays under ~40% of the height
	local short = self.gui.AbsoluteSize.Y > 0 and self.gui.AbsoluteSize.Y < 500
	self.prompt.Visible = not short
	self.starRow.Position = UDim2.new(0, 0, 0, if short then 40 else 68)
	self.cheerRow.Position = UDim2.new(0, 0, 0, if mine then (if short then 40 else 68) else (if short then 100 else 128))
	self.panel.Size = UDim2.new(0.5, 0, 0, (if mine then 68 else 128) + 56 + 24 - (if short then 28 else 0))
	-- Camera flashes from the photographers
	task.spawn(function()
		local current = payload
		for _ = 1, 4 do
			task.wait(0.8 + math.random() * 1.2)
			if self.current ~= current then
				break
			end
			Effects.flash(self.gui)
		end
	end)
	self:setScreen(payload.client.name, stylist, payload.client, payload.look, payload.clean)
end

function Showcase:reaction(emoji: string)
	Effects.floatEmoji(self.gui, emoji)
end

function Showcase:hide()
	self.current = nil
	self.panel.Visible = false
end

return Showcase
