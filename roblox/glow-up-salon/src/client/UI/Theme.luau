-- Colors, fonts and little helpers for building the game's screens in code.

local TweenService = game:GetService("TweenService")

local Theme = {}

local rgb = Color3.fromRGB

Theme.Font = Enum.Font.FredokaOne

-- White text on pink, hotPink, purple and green, and dark text on everything light, all measure
-- at least 4.5:1 contrast. Gold is a background for dark text only (goldText is gold you can read).
Theme.Colors = {
	pink = rgb(212, 47, 134),
	hotPink = rgb(190, 20, 105),
	softPink = rgb(255, 228, 242),
	purple = rgb(106, 63, 181),
	lavender = rgb(235, 225, 255),
	white = rgb(255, 255, 255),
	text = rgb(31, 18, 53),
	textLight = rgb(110, 80, 130),
	gold = rgb(255, 200, 60),
	goldText = rgb(138, 90, 0),
	green = rgb(22, 120, 64),
	red = rgb(240, 70, 90),
	shadow = rgb(0, 0, 0),
}

function Theme.new(className: string, props: { [string]: any }?, children: { Instance }?): any
	local inst = Instance.new(className)
	-- Instance.new layouts sort by Name in real Roblox; every list here is ordered by LayoutOrder.
	if inst:IsA("UIGridStyleLayout") then
		(inst :: UIGridStyleLayout).SortOrder = Enum.SortOrder.LayoutOrder
	end
	if inst:IsA("GuiObject") then
		inst.BorderSizePixel = 0
	end
	if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
		inst.Font = Theme.Font
		inst.TextColor3 = Theme.Colors.text
		inst.TextScaled = true
		inst.BackgroundTransparency = 1
	end
	local parent = nil
	if props then
		for key, value in props do
			if key == "Parent" then
				parent = value
			else
				(inst :: any)[key] = value
			end
		end
	end
	if children then
		for _, child in children do
			child.Parent = inst
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

function Theme.corner(radius: number?): UICorner
	return Theme.new("UICorner", { CornerRadius = UDim.new(0, radius or 16) })
end

function Theme.round(): UICorner
	return Theme.new("UICorner", { CornerRadius = UDim.new(0.5, 0) })
end

function Theme.stroke(color: Color3?, thickness: number?): UIStroke
	return Theme.new("UIStroke", {
		Color = color or Theme.Colors.pink,
		Thickness = thickness or 3,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function Theme.padding(px: number): UIPadding
	local u = UDim.new(0, px)
	return Theme.new("UIPadding", { PaddingTop = u, PaddingBottom = u, PaddingLeft = u, PaddingRight = u })
end

function Theme.maxText(size: number): UITextSizeConstraint
	return Theme.new("UITextSizeConstraint", { MaxTextSize = size, MinTextSize = math.min(14, size) })
end

function Theme.gradient(a: Color3, b: Color3, rotation: number?): UIGradient
	return Theme.new("UIGradient", { Color = ColorSequence.new(a, b), Rotation = rotation or 90 })
end

-- A bouncy, rounded button.
function Theme.button(props: { [string]: any }): TextButton
	local color = props.Color or Theme.Colors.pink
	props.Color = nil
	local maxText = props.MaxText or 28
	props.MaxText = nil
	local merged = {
		BackgroundColor3 = color,
		BackgroundTransparency = 0,
		TextColor3 = Theme.Colors.white,
		AutoButtonColor = false,
	}
	for k, v in props do
		merged[k] = v
	end
	local button = Theme.new("TextButton", merged, {
		Theme.corner(14),
		Theme.maxText(maxText),
		Theme.new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
	})
	local scale = Theme.new("UIScale", { Parent = button })
	local info = TweenInfo.new(0.12, Enum.EasingStyle.Quad)
	button.MouseEnter:Connect(function()
		TweenService:Create(scale, info, { Scale = 1.05 }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(scale, info, { Scale = 1 }):Play()
	end)
	button.MouseButton1Down:Connect(function()
		TweenService:Create(scale, info, { Scale = 0.94 }):Play()
	end)
	button.Activated:Connect(function()
		Theme.onClick()
	end)
	button.MouseButton1Up:Connect(function()
		TweenService:Create(scale, info, { Scale = 1 }):Play()
	end)
	return button
end

-- Set by the sound module so every button can make a click sound.
function Theme.onClick() end

function Theme.pop(gui: GuiObject)
	local scale = gui:FindFirstChildOfClass("UIScale") or Theme.new("UIScale", { Parent = gui })
	scale.Scale = 0.6
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

function Theme.formatTime(seconds: number): string
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

function Theme.stars(stars: number): string
	local full = math.floor(stars)
	local half = stars - full >= 0.5
	return string.rep("★", full) .. (if half then "½" else "") .. string.rep("☆", 5 - full - (if half then 1 else 0))
end

return Theme
