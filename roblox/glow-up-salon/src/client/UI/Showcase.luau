-- The fashion show: points the camera at the runway, puts the look on the big screen,
-- and lets everyone else rate it with stars.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Catalog = require(ReplicatedStorage.Shared.Catalog)
local LookRenderer = require(ReplicatedStorage.Shared.LookRenderer)
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
		Position = UDim2.new(0.5, 0, 1, -20),
		Size = UDim2.new(0.55, 0, 0, 196),
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
	self.starButtons = {}
	for i = 1, 5 do
		local b = new("TextButton", {
			Size = UDim2.new(0, 56, 0, 56),
			Text = "☆",
			TextColor3 = C.gold,
			ZIndex = 42,
			Parent = row,
		})
		b.Activated:Connect(function()
			self:vote(i)
		end)
		b.MouseEnter:Connect(function()
			if not self.voted then
				self:showStars(i)
			end
		end)
		b.MouseLeave:Connect(function()
			if not self.voted then
				self:showStars(0)
			end
		end)
		self.starButtons[i] = b
	end

	task.spawn(function()
		-- Cheer buttons: everyone can tap these, and the emoji float up on every screen
	local cheers = new("Frame", {
		Position = UDim2.new(0, 0, 0, 128),
		Size = UDim2.new(1, 0, 0, 44),
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
	for _, emoji in CHEERS do
		local b = Theme.button({
			Text = emoji,
			Size = UDim2.new(0, 56, 1, 0),
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
		Position = UDim2.fromScale(0.5, 0.1),
		Size = UDim2.fromScale(0.46, 0.22),
		TextColor3 = C.white,
		Text = "✨ 5 Minute Glow Up ✨",
		Parent = bg,
	})
	self.screenSub = new("TextLabel", {
		Position = UDim2.fromScale(0.5, 0.36),
		Size = UDim2.fromScale(0.46, 0.14),
		TextColor3 = C.pink,
		Text = "",
		Parent = bg,
	})
	self.screenTheme = new("TextLabel", {
		Position = UDim2.fromScale(0.5, 0.6),
		Size = UDim2.fromScale(0.46, 0.12),
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
		LookRenderer.render(self.screenPortrait, client, look, { clean = clean or 1 })
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

-- Moves runway models smoothly on this screen, using the walk the server described in attributes.
function Showcase:updateWalkers()
	local world = Workspace:FindFirstChild("GlowUpWorld")
	if not world then
		return
	end
	local now = Workspace:GetServerTimeNow()
	for _, m in world:GetChildren() do
		local from, to, start, walkTime = m:GetAttribute("WalkFrom"), m:GetAttribute("WalkTo"), m:GetAttribute("WalkStart"), m:GetAttribute("WalkTime")
		local root = m:FindFirstChild("HumanoidRootPart")
		if typeof(from) == "Vector3" and typeof(to) == "Vector3" and type(start) == "number" and type(walkTime) == "number" and root and root:IsA("BasePart") then
			local t = now - start
			local forward = Vector3.new(0, 0, 1)
			if t < walkTime then
				local pos = from:Lerp(to, math.max(t, 0) / walkTime)
				root.CFrame = CFrame.lookAt(pos, pos + forward)
			elseif t < walkTime + 1 then
				-- twirl!
				root.CFrame = CFrame.lookAt(to, to + forward) * CFrame.Angles(0, (t - walkTime) * math.pi * 2, 0)
			else
				root.CFrame = CFrame.lookAt(to, to + forward)
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
	local walker = nil
	for _, m in world:GetChildren() do
		if m:IsA("Model") and m:GetAttribute("Walking") then
			walker = m
		end
	end
	local root = walker and walker:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		local pos = root.Position
		local goal = CFrame.lookAt(pos + Vector3.new(6, 3, 13), pos + Vector3.new(0, 1.5, 0))
		local camera = Workspace.CurrentCamera
		camera.CFrame = camera.CFrame:Lerp(goal, 0.08)
	end
end

------------------------------------------------------------------------------
-- Voting

function Showcase:showStars(n: number)
	for i, b in self.starButtons do
		b.Text = if i <= n then "★" else "☆"
	end
end

function Showcase:vote(stars: number)
	local current = self.current
	if not current or current.userId == Players.LocalPlayer.UserId then
		return
	end
	local first = not self.voted
	self.voted = true
	self:showStars(stars)
	Remotes.Vote:FireServer(current.userId, stars)
	self.prompt.Text = "Thanks for voting! 💖 Tap to cheer!"
	if first then
		self.ctx.toast("+2 🪙 for voting!", C.gold)
	end
end

function Showcase:show(payload)
	self.current = payload
	self.voted = false
	self:showStars(0)
	self.panel.Visible = true
	Theme.pop(self.panel)
	self:setCamera("Showcase")

	local mine = payload.userId == Players.LocalPlayer.UserId
	self.title.Text = "💃 " .. payload.client.name .. " is on the runway! (" .. payload.index .. "/" .. payload.total .. ")"
	local level = payload.level or 1
	local stylist = "Styled by " .. payload.stylist .. (if payload.vip then " 👑" else "") .. "  •  Lv " .. level .. " " .. Progress.title(level)
	if mine then
		self.prompt.Text = "This is YOUR client! Cheer for them! 📣"
		self.starRow.Visible = false
	else
		self.prompt.Text = "How many stars? ⭐"
		self.starRow.Visible = true
	end
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
