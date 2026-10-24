-- Fun screen effects: confetti, floating emoji, camera flashes, sparkles and big pop-up cards.

local TweenService = game:GetService("TweenService")

local Sounds = require(script.Parent.Sounds)
local Theme = require(script.Parent.Theme)

local C = Theme.Colors
local new = Theme.new

local Effects = {}

local CONFETTI_COLORS = { C.pink, C.gold, C.purple, Color3.fromRGB(110, 200, 255), C.green, C.white }

local function fadeAndDestroy(gui: GuiObject, delay: number, time: number)
	task.delay(delay, function()
		if not gui.Parent then
			return
		end
		local props = { BackgroundTransparency = 1 }
		if gui:IsA("TextLabel") or gui:IsA("TextButton") then
			props.TextTransparency = 1
		end
		TweenService:Create(gui, TweenInfo.new(time), props):Play()
		task.wait(time)
		gui:Destroy()
	end)
end

-- Colorful paper pieces falling from the top of the screen.
function Effects.confetti(gui: GuiObject, count: number?)
	Sounds.play("Cheer", 1)
	for _ = 1, count or 40 do
		local x = math.random()
		local size = math.random(8, 16)
		local piece = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(x, 0, 0, -20),
			Size = UDim2.fromOffset(size, size * 0.6),
			BackgroundColor3 = CONFETTI_COLORS[math.random(1, #CONFETTI_COLORS)],
			Rotation = math.random(0, 360),
			ZIndex = 300,
			Parent = gui,
		})
		local fall = 1.8 + math.random() * 1.6
		TweenService:Create(piece, TweenInfo.new(fall, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(x + (math.random() - 0.5) * 0.25, 0, 1, 30),
			Rotation = piece.Rotation + math.random(-540, 540),
		}):Play()
		task.delay(fall, function()
			piece:Destroy()
		end)
	end
end

-- An emoji that floats up from the bottom of the screen and fades away.
function Effects.floatEmoji(gui: GuiObject, emoji: string)
	local x = 0.1 + math.random() * 0.8
	local label = new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(x, 0, 1, -40),
		Size = UDim2.fromOffset(56, 56),
		Text = emoji,
		ZIndex = 250,
		Parent = gui,
	})
	TweenService:Create(label, TweenInfo.new(2.2, Enum.EasingStyle.Sine), {
		Position = UDim2.new(x + (math.random() - 0.5) * 0.1, 0, 0.35, 0),
		Rotation = math.random(-25, 25),
	}):Play()
	fadeAndDestroy(label, 1.4, 0.8)
end

-- A quick white camera flash.
function Effects.flash(gui: GuiObject)
	Sounds.play("Camera")
	local flash = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.white,
		BackgroundTransparency = 0.35,
		ZIndex = 280,
		Parent = gui,
	})
	fadeAndDestroy(flash, 0, 0.3)
end

-- A little "✨" (or another emoji) that pops at a spot inside `parent` (0..1 position).
function Effects.sparkle(parent: GuiObject, x: number, y: number, emoji: string?)
	Sounds.play("Sparkle", 0.15)
	local s = new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(x, y),
		Size = UDim2.fromScale(0.14, 0.14),
		Text = emoji or "✨",
		ZIndex = 120,
		Parent = parent,
	}, { new("UIAspectRatioConstraint", { AspectRatio = 1 }) })
	Theme.pop(s)
	fadeAndDestroy(s, 0.4, 0.4)
end

local splashFreeAt = 0

-- A big card in the middle of the screen. Cards wait their turn so they never pile up.
-- `build` can add extra things to the card.
function Effects.splash(gui: GuiObject, title: string, subtitle: string?, color: Color3?, seconds: number?, build: ((Frame) -> ())?)
	local now = os.clock()
	local waitFor = math.max(0, splashFreeAt - now)
	splashFreeAt = now + waitFor + (seconds or 2.5) + 0.4
	task.delay(waitFor, function()
		local card = Effects.showSplash(gui, title, subtitle, color, seconds)
		if build then
			build(card)
		end
	end)
end

function Effects.showSplash(gui: GuiObject, title: string, subtitle: string?, color: Color3?, seconds: number?): Frame
	Sounds.play("Pop")
	local card = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromScale(0.5, 0.34),
		BackgroundColor3 = C.white,
		ZIndex = 260,
		Parent = gui,
	}, {
		Theme.corner(28),
		Theme.stroke(color or C.hotPink, 6),
		Theme.padding(14),
		new("UISizeConstraint", { MinSize = Vector2.new(300, 150), MaxSize = Vector2.new(620, 300) }),
	})
	new("TextLabel", {
		Size = UDim2.fromScale(1, if subtitle then 0.58 else 1),
		Text = title,
		TextColor3 = color or C.hotPink,
		ZIndex = 261,
		Parent = card,
	}, { Theme.maxText(64) })
	if subtitle then
		new("TextLabel", {
			Position = UDim2.fromScale(0, 0.6),
			Size = UDim2.fromScale(1, 0.4),
			Text = subtitle,
			TextColor3 = C.text,
			ZIndex = 261,
			Parent = card,
		}, { Theme.maxText(30) })
	end
	Theme.pop(card)
	task.delay(seconds or 2.5, function()
		if card.Parent then
			for _, d in card:GetDescendants() do
				if d:IsA("TextLabel") then
					TweenService:Create(d, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
				elseif d:IsA("UIStroke") then
					TweenService:Create(d, TweenInfo.new(0.3), { Transparency = 1 }):Play()
				end
			end
			TweenService:Create(card, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
			task.wait(0.35)
			card:Destroy()
		end
	end)
	return card
end

return Effects
