-- Draws a client's face (and shoulders) out of UI shapes, so the game needs no uploaded images.
-- The same drawing is used in the makeover screen, the item previews, the runway screen,
-- and the face of the client walking the runway.
--
-- Everything is placed in a square, using 0..1 coordinates (0.5, 0.5 is the middle).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.Catalog)

local LookRenderer = {}

export type Options = {
	headOnly: boolean?, -- skip neck and outfit (used for the runway head)
	dirtHealth: { number }?, -- per-spot dirt left (1 = dirty, 0 = clean); used while washing
	clean: number?, -- 0..1 overall cleanliness, used when dirtHealth isn't given
	mood: string?, -- "sad", "neutral", "smile" (default) or "grin"
	zoom: number?, -- >1 zooms in on the face (the container should clip)
}

-- Layers, back to front
local Z = {
	hairBack = 1,
	neck = 2,
	outfit = 3,
	ears = 4,
	face = 5,
	makeup = 6,
	eyes = 7,
	details = 8,
	gems = 9,
	hairFront = 10,
	accessory = 11,
	dirt = 12,
}

local WHITE = Color3.new(1, 1, 1)
local LASH = Color3.fromRGB(30, 25, 30)
local TIE = Color3.fromRGB(255, 110, 170)

local SPARKLE_SPOTS = { { 0.25, 0.3 }, { 0.7, 0.22 }, { 0.5, 0.65 }, { 0.3, 0.8 }, { 0.8, 0.7 } }

local function darken(c: Color3, f: number): Color3
	return Color3.new(c.R * f, c.G * f, c.B * f)
end

local function shape(
	parent: Instance,
	x: number,
	y: number,
	w: number,
	h: number,
	color: Color3,
	z: number,
	radius: number?,
	transparency: number?,
	rotation: number?
): Frame
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(x, y)
	f.Size = UDim2.fromScale(w, h)
	f.BackgroundColor3 = color
	f.BackgroundTransparency = transparency or 0
	f.BorderSizePixel = 0
	f.ZIndex = z
	f.Rotation = rotation or 0
	if radius and radius > 0 then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(radius, 0)
		corner.Parent = f
	end
	f.Parent = parent
	return f
end

local function glyph(parent: Instance, text: string, x: number, y: number, size: number, color: Color3, z: number): TextLabel
	local t = Instance.new("TextLabel")
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.Position = UDim2.fromScale(x, y)
	t.Size = UDim2.fromScale(size, size)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextColor3 = color
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.ZIndex = z
	t.Parent = parent
	return t
end

-- Colors a shape with an item's color, gradient and sparkles.
local function paint(f: Frame, it: Catalog.Item?, fallback: Color3?)
	if not it then
		if fallback then
			f.BackgroundColor3 = fallback
		end
		return
	end
	f.BackgroundColor3 = it.color or fallback or WHITE
	if it.gradient then
		local keypoints = {}
		local n = #it.gradient
		for i, c in it.gradient do
			table.insert(keypoints, ColorSequenceKeypoint.new((i - 1) / math.max(n - 1, 1), c))
		end
		f.BackgroundColor3 = WHITE
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new(keypoints)
		g.Rotation = 90
		g.Parent = f
	end
	if it.sparkle then
		for _, spot in SPARKLE_SPOTS do
			local dot = shape(f, spot[1], spot[2], 0.12, 0.12, WHITE, f.ZIndex, 0.5, 0.15)
			local aspect = Instance.new("UIAspectRatioConstraint")
			aspect.AspectRatio = 1
			aspect.Parent = dot
		end
	end
end

------------------------------------------------------------------------------
-- Hair

local function drawHair(root: Frame, look, hairItem: Catalog.Item?)
	local hc = hairItem and hairItem.color or Color3.fromRGB(105, 66, 40)
	local function hair(x, y, w, h, z, r, rot): Frame
		local f = shape(root, x, y, w, h, hc, z, r, 0, rot)
		paint(f, hairItem, hc)
		return f
	end
	local function cap()
		hair(0.5, 0.215, 0.5, 0.16, Z.hairFront, 0.5)
	end
	local function fringe()
		hair(0.42, 0.265, 0.24, 0.07, Z.hairFront, 0.5, -14)
	end

	local style = look.hairStyle
	if style == "hair_messy" then
		hair(0.5, 0.3, 0.56, 0.36, Z.hairBack, 0.5)
		cap()
		local tufts = { { 0.27, 0.17, 30 }, { 0.36, 0.11, -20 }, { 0.49, 0.09, 10 }, { 0.62, 0.11, 35 }, { 0.73, 0.18, -30 }, { 0.76, 0.3, 15 }, { 0.24, 0.31, -10 } }
		for _, t in tufts do
			hair(t[1], t[2], 0.1, 0.07, Z.hairFront, 0.4, t[3])
		end
		hair(0.3, 0.06, 0.02, 0.09, Z.hairFront, 0.5, -30)
		hair(0.68, 0.05, 0.02, 0.1, Z.hairFront, 0.5, 25)
		hair(0.45, 0.29, 0.14, 0.05, Z.hairFront, 0.5, 25)
		hair(0.58, 0.28, 0.12, 0.045, Z.hairFront, 0.5, -30)
	elseif style == "hair_long" then
		hair(0.5, 0.52, 0.62, 0.72, Z.hairBack, 0.25)
		cap()
		fringe()
	elseif style == "hair_bob" then
		hair(0.5, 0.43, 0.6, 0.5, Z.hairBack, 0.35)
		cap()
		fringe()
		hair(0.285, 0.45, 0.075, 0.38, Z.hairFront, 0.5)
		hair(0.715, 0.45, 0.075, 0.38, Z.hairFront, 0.5)
	elseif style == "hair_pixie" then
		hair(0.5, 0.3, 0.52, 0.3, Z.hairBack, 0.5)
		hair(0.5, 0.2, 0.48, 0.13, Z.hairFront, 0.5)
		hair(0.4, 0.25, 0.26, 0.07, Z.hairFront, 0.5, -22)
		hair(0.28, 0.36, 0.05, 0.12, Z.hairFront, 0.5)
		hair(0.72, 0.36, 0.05, 0.12, Z.hairFront, 0.5)
	elseif style == "hair_puff" then
		hair(0.5, 0.08, 0.32, 0.32, Z.hairBack, 0.5)
		hair(0.5, 0.21, 0.48, 0.13, Z.hairFront, 0.5)
		shape(root, 0.5, 0.17, 0.12, 0.03, TIE, Z.hairFront, 0.5)
	elseif style == "hair_curls" then
		hair(0.5, 0.4, 0.8, 0.8, Z.hairBack, 0.5)
		for i = 0, 6 do
			hair(0.29 + i * 0.07, 0.17 + (i % 2) * 0.03, 0.11, 0.11, Z.hairFront, 0.5)
		end
		for _, p in { { 0.2, 0.3 }, { 0.8, 0.35 }, { 0.17, 0.55 }, { 0.83, 0.58 }, { 0.3, 0.1 }, { 0.7, 0.1 } } do
			local curl = hair(p[1], p[2], 0.08, 0.08, Z.hairBack, 0.5)
			curl.BackgroundTransparency = 0.6
			curl.BackgroundColor3 = darken(hc, 0.6)
		end
	elseif style == "hair_pigtails" then
		hair(0.5, 0.35, 0.54, 0.42, Z.hairBack, 0.5)
		hair(0.19, 0.56, 0.2, 0.2, Z.hairBack, 0.5)
		hair(0.81, 0.56, 0.2, 0.2, Z.hairBack, 0.5)
		hair(0.19, 0.74, 0.14, 0.18, Z.hairBack, 0.5)
		hair(0.81, 0.74, 0.14, 0.18, Z.hairBack, 0.5)
		cap()
		fringe()
		shape(root, 0.24, 0.45, 0.05, 0.05, TIE, Z.hairFront, 0.5)
		shape(root, 0.76, 0.45, 0.05, 0.05, TIE, Z.hairFront, 0.5)
	elseif style == "hair_buns" then
		hair(0.5, 0.38, 0.56, 0.46, Z.hairBack, 0.4)
		hair(0.3, 0.11, 0.2, 0.2, Z.hairBack, 0.5)
		hair(0.7, 0.11, 0.2, 0.2, Z.hairBack, 0.5)
		cap()
		fringe()
	elseif style == "hair_braid" then
		hair(0.5, 0.38, 0.58, 0.44, Z.hairBack, 0.4)
		cap()
		hair(0.56, 0.26, 0.3, 0.07, Z.hairFront, 0.5, 14)
		for i = 0, 5 do
			local s = 0.11 - i * 0.008
			hair(0.73 + (i % 2) * 0.015, 0.5 + i * 0.075, s, s, Z.hairFront, 0.5)
		end
		shape(root, 0.74, 0.9, 0.05, 0.03, TIE, Z.hairFront, 0.5)
	elseif style == "hair_updo" then
		hair(0.5, 0.07, 0.28, 0.26, Z.hairBack, 0.5)
		hair(0.5, 0.21, 0.5, 0.14, Z.hairFront, 0.5)
		hair(0.275, 0.42, 0.02, 0.18, Z.hairFront, 0.5, 8)
		hair(0.725, 0.42, 0.02, 0.18, Z.hairFront, 0.5, -8)
		glyph(root, "✦", 0.38, 0.12, 0.06, Color3.fromRGB(255, 240, 170), Z.hairFront)
		glyph(root, "✦", 0.62, 0.12, 0.05, Color3.fromRGB(255, 240, 170), Z.hairFront)
	elseif style == "hair_mermaid" then
		hair(0.5, 0.55, 0.7, 0.8, Z.hairBack, 0.3)
		for i = 0, 4 do
			hair(0.155, 0.3 + i * 0.13, 0.13, 0.13, Z.hairBack, 0.5)
			hair(0.845, 0.3 + i * 0.13, 0.13, 0.13, Z.hairBack, 0.5)
		end
		cap()
		fringe()
		glyph(root, "🐚", 0.68, 0.16, 0.08, WHITE, Z.hairFront)
	end
end

------------------------------------------------------------------------------
-- Face

local function drawEyes(root: Frame, client, look, hairItem: Catalog.Item?)
	local shadow = Catalog.byId[look.eyeshadow]
	local lashes = look.lashes
	local browColor = darken(hairItem and hairItem.color or Color3.fromRGB(80, 50, 30), 0.7)

	for side = -1, 1, 2 do
		local x = 0.5 + side * 0.09

		if shadow and shadow.color then
			local s = shape(root, x, 0.405, 0.115, 0.07, shadow.color, Z.makeup, 0.5, 0.1)
			paint(s, shadow)
		end

		local eye = shape(root, x, 0.42, 0.085, 0.055, WHITE, Z.eyes, 0.5)
		eye.Name = "Eye"
		local iris = shape(eye, 0.5, 0.5, 0.5, 0.85, client.eyes, Z.eyes, 0.5)
		shape(iris, 0.5, 0.5, 0.5, 0.5, Color3.fromRGB(20, 15, 20), Z.eyes, 0.5)
		shape(iris, 0.68, 0.3, 0.3, 0.3, WHITE, Z.eyes, 0.5)

		shape(root, x, 0.355, 0.085, 0.016, browColor, Z.details, 0.5, 0, side * 8)

		if lashes == "lash_natural" or lashes == "lash_star" then
			shape(root, x, 0.395, 0.09, 0.012, LASH, Z.details, 0.5)
		elseif lashes == "lash_glam" then
			shape(root, x, 0.395, 0.095, 0.018, LASH, Z.details, 0.5)
			shape(root, x + side * 0.05, 0.385, 0.035, 0.013, LASH, Z.details, 0.5, -side * 28)
		end
		if lashes == "lash_star" then
			glyph(root, "★", x + side * 0.055, 0.38, 0.035, Color3.fromRGB(255, 215, 80), Z.details)
		end
	end
end

-- Half of an ellipse, cut off by a clipping frame: the lower half makes a smile, the upper half a frown.
local function halfMouth(root: Frame, y: number, w: number, h: number, lower: boolean): Frame
	local clip = Instance.new("Frame")
	clip.Name = "Mouth"
	clip.AnchorPoint = Vector2.new(0.5, 0.5)
	clip.Position = UDim2.fromScale(0.5, y)
	clip.Size = UDim2.fromScale(w, h)
	clip.BackgroundTransparency = 1
	clip.ClipsDescendants = true
	clip.ZIndex = Z.details
	clip.Parent = root
	return clip
end

local function drawMouth(root: Frame, client, mood: string, lipColor: Color3, glossy: boolean)
	if mood == "smile" or mood == "grin" then
		local big = mood == "grin"
		local clip = halfMouth(root, if big then 0.605 else 0.6, if big then 0.15 else 0.12, if big then 0.07 else 0.05, true)
		shape(clip, 0.5, 0, 1, 2, lipColor, 1, 0.5)
		shape(clip, 0.5, 0, 0.8, 1.5, Color3.fromRGB(110, 30, 50), 2, 0.5)
		shape(clip, 0.5, 0.13, 0.62, 0.24, WHITE, 3, 0.3)
		if big then
			shape(clip, 0.5, 0.78, 0.38, 0.4, Color3.fromRGB(255, 120, 140), 3, 0.5)
		end
		if glossy then
			shape(clip, 0.62, 0.8, 0.18, 0.12, WHITE, 4, 0.5, 0.3)
		end
	elseif mood == "sad" then
		local clip = halfMouth(root, 0.615, 0.1, 0.035, false)
		shape(clip, 0.5, 1, 1, 2, lipColor, 1, 0.5)
		shape(clip, 0.5, 1.3, 0.72, 2, client.skin, 2, 0.5)
	else
		local lips = shape(root, 0.5, 0.6, 0.11, 0.042, lipColor, Z.details, 0.5)
		shape(root, 0.5, 0.598, 0.08, 0.005, darken(lips.BackgroundColor3, 0.6), Z.gems, 0.5)
		if glossy then
			shape(root, 0.52, 0.612, 0.03, 0.009, WHITE, Z.gems, 0.5, 0.3)
		end
	end
end

local function drawCheeksAndLips(root: Frame, client, look, mood: string?)
	local blush = Catalog.byId[look.blush]
	if blush and blush.color then
		for side = -1, 1, 2 do
			local b = shape(root, 0.5 + side * 0.14, 0.53, 0.08, 0.05, blush.color, Z.makeup, 0.5, 0.45)
			paint(b, blush)
		end
	end

	shape(root, 0.5, 0.5, 0.035, 0.045, darken(client.skin, 0.88), Z.makeup, 0.5)

	local lipstick = Catalog.byId[look.lipstick]
	local natural = client.skin:Lerp(Color3.fromRGB(190, 80, 85), 0.4)
	local lipColor = if lipstick and lipstick.color then lipstick.color else natural
	drawMouth(root, client, mood or "smile", lipColor, lipstick ~= nil and lipstick.sparkle == true)
end

local function drawGems(root: Frame, client, look)
	local gems = look.gems
	local it = Catalog.byId[gems]
	if gems == "gem_freckles" then
		local c = darken(client.skin, 0.72)
		for _, p in { { 0.42, 0.49 }, { 0.445, 0.51 }, { 0.41, 0.515 }, { 0.58, 0.49 }, { 0.555, 0.51 }, { 0.59, 0.515 } } do
			shape(root, p[1], p[2], 0.012, 0.012, c, Z.gems, 0.5)
		end
	elseif gems == "gem_hearts" and it then
		glyph(root, "♥", 0.345, 0.47, 0.06, it.color or WHITE, Z.gems)
		glyph(root, "♥", 0.655, 0.47, 0.06, it.color or WHITE, Z.gems)
	elseif gems == "gem_stars" and it then
		glyph(root, "★", 0.335, 0.41, 0.06, it.color or WHITE, Z.gems)
		glyph(root, "★", 0.665, 0.41, 0.06, it.color or WHITE, Z.gems)
		glyph(root, "★", 0.355, 0.47, 0.035, it.color or WHITE, Z.gems)
	elseif gems == "gem_rhinestones" and it then
		for side = -1, 1, 2 do
			for i = 0, 3 do
				shape(root, 0.5 + side * (0.06 + i * 0.022), 0.46 + i * 0.006, 0.016, 0.016, it.color or WHITE, Z.gems, 0.5)
			end
		end
	end
end

local function drawAccessory(root: Frame, look)
	local acc = look.accessory
	local it = Catalog.byId[acc]
	local c = it and it.color or WHITE
	if acc == "acc_bow" then
		shape(root, 0.32, 0.14, 0.09, 0.07, c, Z.accessory, 0.4, 0, -20)
		shape(root, 0.42, 0.14, 0.09, 0.07, c, Z.accessory, 0.4, 0, 20)
		shape(root, 0.37, 0.14, 0.035, 0.035, darken(c, 0.8), Z.accessory, 0.5)
	elseif acc == "acc_headband" then
		shape(root, 0.5, 0.2, 0.52, 0.03, c, Z.accessory, 0.5)
	elseif acc == "acc_flower" then
		glyph(root, "✿", 0.68, 0.18, 0.13, c, Z.accessory)
		shape(root, 0.68, 0.185, 0.025, 0.025, Color3.fromRGB(255, 220, 80), Z.accessory, 0.5)
	elseif acc == "acc_earrings" then
		shape(root, 0.275, 0.55, 0.03, 0.03, c, Z.accessory, 0.5)
		shape(root, 0.725, 0.55, 0.03, 0.03, c, Z.accessory, 0.5)
	elseif acc == "acc_catears" then
		for side = -1, 1, 2 do
			shape(root, 0.5 + side * 0.17, 0.12, 0.09, 0.09, c, Z.accessory, 0.15, 0, 45)
			shape(root, 0.5 + side * 0.17, 0.125, 0.045, 0.045, Color3.fromRGB(255, 160, 190), Z.accessory, 0.15, 0, 45)
		end
	elseif acc == "acc_crown" then
		glyph(root, "👑", 0.5, 0.09, 0.18, c, Z.accessory)
	end
end

local function drawOutfit(root: Frame, client, look)
	local outfit = Catalog.byId[look.outfit]
	shape(root, 0.5, 0.77, 0.15, 0.14, client.skin, Z.neck, 0.3)
	local body = shape(root, 0.5, 0.97, 0.78, 0.3, Color3.new(), Z.outfit, 0.35)
	paint(body, outfit, Color3.fromRGB(110, 120, 135))
	shape(root, 0.5, 0.83, 0.14, 0.06, client.skin, Z.ears, 0.5)
	local accent = outfit and outfit.accent or WHITE
	shape(root, 0.43, 0.86, 0.06, 0.02, accent, Z.ears, 0.5, 0, 25)
	shape(root, 0.57, 0.86, 0.06, 0.02, accent, Z.ears, 0.5, 0, -25)
	if look.outfit == "outfit_work" then
		-- overall straps
		shape(root, 0.38, 0.92, 0.05, 0.12, accent, Z.ears, 0.2)
		shape(root, 0.62, 0.92, 0.05, 0.12, accent, Z.ears, 0.2)
	end
end

local function drawDirt(root: Frame, client, options: Options?)
	local health = options and options.dirtHealth
	local n = #client.dirt
	local cleanedCount = math.floor(((options and options.clean) or 0) * n + 0.5)
	for i, spot in client.dirt do
		local h = if health then health[i] or 0 else (if i <= cleanedCount then 0 else 1)
		-- A splat: one big blob and two little ones
		local f = shape(root, spot.x, spot.y, spot.size * 1.3, spot.size * 1.1, spot.color, Z.dirt, 0, 1, (i * 47) % 180)
		f.Name = "Dirt" .. i
		shape(f, 0.45, 0.5, 0.75, 0.75, spot.color, Z.dirt, 0.5)
		shape(f, 0.82, 0.22, 0.3, 0.3, spot.color, Z.dirt, 0.5)
		shape(f, 0.18, 0.85, 0.24, 0.24, darken(spot.color, 0.85), Z.dirt, 0.5)
		LookRenderer.setDirtHealth(f, h)
	end
end

------------------------------------------------------------------------------

-- Colors any UI frame like an item (used for the color swatches in the menus).
LookRenderer.paint = paint

function LookRenderer.setDirtHealth(f: GuiObject, health: number)
	local t = 1 - 0.92 * math.clamp(health, 0, 1)
	for _, blob in f:GetChildren() do
		if blob:IsA("GuiObject") then
			blob.BackgroundTransparency = t
		end
	end
	f.Visible = health > 0.02
end

-- Draws the client into `container`, replacing any older drawing. Returns the square root frame.
function LookRenderer.render(container: GuiObject, client, look, options: Options?): Frame
	local old = container:FindFirstChild("Portrait")
	if old then
		old:Destroy()
	end

	local root = Instance.new("Frame")
	root.Name = "Portrait"
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	local zoom = options and options.zoom or 1
	-- keep the middle of the face (0.5, 0.42) in the middle of the container
	root.Position = UDim2.fromScale(0.5, 0.5 + 0.08 * (zoom - 1))
	root.Size = UDim2.fromScale(zoom, zoom)
	root.BackgroundTransparency = 1
	root.ClipsDescendants = true
	root.ZIndex = container.ZIndex
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1
	aspect.Parent = root

	local hairItem = Catalog.byId[look.hairColor]

	drawHair(root, look, hairItem)
	if not (options and options.headOnly) then
		drawOutfit(root, client, look)
	end
	for side = -1, 1, 2 do
		local ear = shape(root, 0.5 + side * 0.22, 0.47, 0.06, 0.09, client.skin, Z.ears, 0.5)
		shape(ear, 0.5, 0.5, 0.45, 0.55, darken(client.skin, 0.85), Z.ears, 0.5)
	end
	shape(root, 0.5, 0.46, 0.44, 0.56, client.skin, Z.face, 0.5)
	drawEyes(root, client, look, hairItem)
	drawCheeksAndLips(root, client, look, options and options.mood)
	drawGems(root, client, look)
	drawAccessory(root, look)
	if (options and options.dirtHealth) or ((options and options.clean) or 0) < 1 then
		drawDirt(root, client, options)
	end

	root.Parent = container
	return root
end

return LookRenderer
