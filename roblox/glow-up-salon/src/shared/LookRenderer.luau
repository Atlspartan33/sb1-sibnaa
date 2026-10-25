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
	brushed: boolean?, -- messy hair with the tangles brushed out
	tangle: number?, -- 0..1 how tangled messy hair still is (while brushing)
	zoom: number?, -- >1 zooms in on the face (the container should clip)
	faceOnly: boolean?, -- just the features and makeup, for the face on a 3D head (no skin, hair or accessory)
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

local function drawHair(root: Frame, look, hairItem: Catalog.Item?, options: Options?)
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

	local styleItem = Catalog.byId[look.hairStyle]
	local style = if styleItem and styleItem.draw then styleItem.draw else look.hairStyle
	if style == "hair_messy" then
		hair(0.5, 0.3, 0.56, 0.36, Z.hairBack, 0.5)
		cap()
		if not (options and options.brushed) then
			-- tangles and frizz (they fade away while the stylist brushes)
			local tangle = if options and options.tangle then options.tangle else 1
			local tufts = { { 0.27, 0.17, 30 }, { 0.36, 0.11, -20 }, { 0.49, 0.09, 10 }, { 0.62, 0.11, 35 }, { 0.73, 0.18, -30 }, { 0.76, 0.3, 15 }, { 0.24, 0.31, -10 } }
			local bits = {}
			for _, t in tufts do
				table.insert(bits, hair(t[1], t[2], 0.1, 0.07, Z.hairFront, 0.4, t[3]))
			end
			table.insert(bits, hair(0.3, 0.06, 0.02, 0.09, Z.hairFront, 0.5, -30))
			table.insert(bits, hair(0.68, 0.05, 0.02, 0.1, Z.hairFront, 0.5, 25))
			table.insert(bits, hair(0.45, 0.29, 0.14, 0.05, Z.hairFront, 0.5, 25))
			table.insert(bits, hair(0.58, 0.28, 0.12, 0.045, Z.hairFront, 0.5, -30))
			for _, b in bits do
				b.Name = "Tuft"
				b.BackgroundTransparency = 1 - tangle
			end
		end
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
	local it = Catalog.byId[look.gems]
	local gems = if it and it.draw then it.draw else look.gems
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
	elseif gems == "gem_bats" then
		glyph(root, "🦇", 0.34, 0.47, 0.07, WHITE, Z.gems)
		glyph(root, "🦇", 0.67, 0.4, 0.05, WHITE, Z.gems)
	elseif gems == "gem_web" then
		glyph(root, "🕸️", 0.65, 0.48, 0.09, WHITE, Z.gems)
	elseif gems == "gem_leaves" then
		glyph(root, "🍁", 0.34, 0.48, 0.06, WHITE, Z.gems)
		glyph(root, "🍂", 0.66, 0.48, 0.06, WHITE, Z.gems)
	elseif gems == "gem_snowflakes" then
		glyph(root, "❄️", 0.34, 0.47, 0.06, WHITE, Z.gems)
		glyph(root, "❄️", 0.665, 0.41, 0.045, WHITE, Z.gems)
		glyph(root, "❄️", 0.68, 0.5, 0.035, WHITE, Z.gems)
	elseif gems == "gem_rhinestones" and it then
		for side = -1, 1, 2 do
			for i = 0, 3 do
				shape(root, 0.5 + side * (0.06 + i * 0.022), 0.46 + i * 0.006, 0.016, 0.016, it.color or WHITE, Z.gems, 0.5)
			end
		end
	end
end

local function drawAccessory(root: Frame, look)
	local it = Catalog.byId[look.accessory]
	local acc = if it and it.draw then it.draw else look.accessory
	local c = it and it.color or WHITE
	-- paints a shape with the item's color, or its rainbow gradient
	local function tint(f: Frame): Frame
		if it and it.gradient then
			paint(f, it)
		end
		return f
	end
	if acc == "acc_bow" then
		shape(root, 0.32, 0.14, 0.09, 0.07, c, Z.accessory, 0.4, 0, -20)
		shape(root, 0.42, 0.14, 0.09, 0.07, c, Z.accessory, 0.4, 0, 20)
		shape(root, 0.37, 0.14, 0.035, 0.035, darken(c, 0.8), Z.accessory, 0.5)
	elseif acc == "acc_headband" then
		tint(shape(root, 0.5, 0.2, 0.52, 0.035, c, Z.accessory, 0.5))
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
	elseif it and it.icon then
		-- a cute hair clip
		glyph(root, it.icon, 0.69, 0.17, 0.12, WHITE, Z.accessory)
	elseif acc == "acc_butterfly" then
		glyph(root, "🦋", 0.68, 0.17, 0.12, WHITE, Z.accessory)
	elseif acc == "acc_halo" then
		local ring = shape(root, 0.5, 0.06, 0.4, 0.06, c, Z.accessory, 0.5)
		shape(ring, 0.5, 0.5, 0.8, 0.45, Color3.fromRGB(255, 250, 225), Z.accessory, 0.5)
		for i = 0, 4 do
			glyph(root, "✦", 0.34 + i * 0.08, 0.06, 0.04, Color3.fromRGB(255, 240, 150), Z.accessory)
		end
	elseif acc == "acc_tiara" then
		shape(root, 0.5, 0.17, 0.36, 0.025, c, Z.accessory, 0.5)
		for i = -2, 2 do
			local h = if i == 0 then 0.07 else (if math.abs(i) == 1 then 0.05 else 0.035)
			shape(root, 0.5 + i * 0.07, 0.165 - h / 2, 0.025, h, c, Z.accessory, 0.5)
		end
		shape(root, 0.5, 0.12, 0.035, 0.035, Color3.fromRGB(255, 120, 190), Z.accessory, 0.5)
		shape(root, 0.43, 0.135, 0.022, 0.022, Color3.fromRGB(140, 200, 255), Z.accessory, 0.5)
		shape(root, 0.57, 0.135, 0.022, 0.022, Color3.fromRGB(140, 200, 255), Z.accessory, 0.5)
	elseif acc == "acc_witchhat" then
		local band = it and it.accent or Color3.fromRGB(150, 80, 220)
		shape(root, 0.5, 0.165, 0.66, 0.05, c, Z.accessory, 0.5)
		shape(root, 0.5, 0.115, 0.34, 0.07, c, Z.accessory, 0.3)
		shape(root, 0.51, 0.065, 0.25, 0.06, c, Z.accessory, 0.3, 0, 4)
		shape(root, 0.53, 0.025, 0.16, 0.05, c, Z.accessory, 0.3, 0, 10)
		shape(root, 0.57, 0.0, 0.08, 0.04, c, Z.accessory, 0.5, 0, 25)
		shape(root, 0.5, 0.14, 0.35, 0.022, band, Z.accessory, 0.2)
		glyph(root, "⭐", 0.6, 0.11, 0.04, WHITE, Z.accessory)
	elseif acc == "acc_pumpkin" then
		glyph(root, "🎃", 0.69, 0.17, 0.12, WHITE, Z.accessory)
	elseif acc == "acc_leafcrown" then
		for i, p in { { 0.31, 0.19, "🍂" }, { 0.39, 0.14, "🍁" }, { 0.5, 0.12, "🍂" }, { 0.61, 0.14, "🍁" }, { 0.69, 0.19, "🍂" } } do
			glyph(root, p[3], p[1], p[2], if i == 3 then 0.1 else 0.08, WHITE, Z.accessory)
		end
	elseif acc == "acc_santahat" then
		shape(root, 0.5, 0.135, 0.5, 0.11, c, Z.accessory, 0.45)
		shape(root, 0.61, 0.075, 0.3, 0.08, c, Z.accessory, 0.45, 0, 22)
		shape(root, 0.72, 0.06, 0.12, 0.06, c, Z.accessory, 0.45, 0, 50)
		shape(root, 0.5, 0.185, 0.56, 0.055, WHITE, Z.accessory, 0.5)
		shape(root, 0.79, 0.09, 0.075, 0.075, WHITE, Z.accessory, 0.5)
	elseif acc == "acc_antlers" then
		for side = -1, 1, 2 do
			shape(root, 0.5 + side * 0.17, 0.09, 0.03, 0.15, c, Z.accessory, 0.5, 0, side * 18)
			shape(root, 0.5 + side * 0.215, 0.07, 0.025, 0.08, c, Z.accessory, 0.5, 0, side * 55)
			shape(root, 0.5 + side * 0.14, 0.04, 0.022, 0.07, c, Z.accessory, 0.5, 0, -side * 25)
		end
		shape(root, 0.5, 0.505, 0.055, 0.05, Color3.fromRGB(230, 30, 40), Z.accessory, 0.5)
		shape(root, 0.49, 0.495, 0.015, 0.013, WHITE, Z.accessory, 0.5, 0.2)
	elseif acc == "acc_earmuffs" then
		local band = it and it.accent or Color3.fromRGB(110, 170, 255)
		shape(root, 0.5, 0.15, 0.56, 0.03, band, Z.accessory, 0.5)
		for side = -1, 1, 2 do
			shape(root, 0.5 + side * 0.24, 0.45, 0.11, 0.13, c, Z.accessory, 0.5)
			shape(root, 0.5 + side * 0.24, 0.45, 0.06, 0.07, Color3.fromRGB(230, 240, 255), Z.accessory, 0.5)
		end
	end
end

-- Dots, stripes, hearts... drawn on top of the outfit
local PATTERN_SPOTS = { { 0.14, 0.2 }, { 0.32, 0.36 }, { 0.5, 0.18 }, { 0.68, 0.36 }, { 0.86, 0.2 }, { 0.23, 0.52 }, { 0.77, 0.52 }, { 0.5, 0.5 } }

local function drawPattern(body: Frame, patternId: string?, color: Color3)
	if patternId == "pat_dots" then
		for _, p in PATTERN_SPOTS do
			local dot = shape(body, p[1], p[2], 0.05, 0.13, color, body.ZIndex, 0.5, 0.1)
			dot.Name = "Pattern"
		end
	elseif patternId == "pat_stripes" then
		for i = 0, 3 do
			local stripe = shape(body, 0.5, 0.14 + i * 0.15, 0.86, 0.055, color, body.ZIndex, 0.5, 0.15)
			stripe.Name = "Pattern"
		end
	else
		local symbol = ({ pat_hearts = "♥", pat_stars = "★", pat_flowers = "✿" })[patternId or ""]
		if symbol then
			for _, p in PATTERN_SPOTS do
				local t = glyph(body, symbol, p[1], p[2], 0.12, color, body.ZIndex)
				t.Size = UDim2.fromScale(0.09, 0.22)
				t.Name = "Pattern"
			end
		end
	end
end

local function drawOutfit(root: Frame, client, look)
	local outfit = Catalog.byId[look.outfit]
	shape(root, 0.5, 0.77, 0.15, 0.14, client.skin, Z.neck, 0.3)
	local body = shape(root, 0.5, 0.97, 0.78, 0.3, Color3.new(), Z.outfit, 0.35)
	-- A custom color from the 🎨 palette replaces the outfit's own colors
	local custom = Catalog.byId[look.outfitColor or ""]
	if custom and custom.color then
		body.BackgroundColor3 = custom.color
	else
		paint(body, outfit, Color3.fromRGB(110, 120, 135))
	end
	local patternColor = if outfit and outfit.accent then outfit.accent else WHITE
	if custom and custom.color then
		local _, _, v = custom.color:ToHSV()
		patternColor = if v > 0.8 then Color3.fromRGB(255, 120, 190) else WHITE
	end
	drawPattern(body, look.outfitPattern, patternColor)
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

-- The whole client, head to toe, for the runway and podium (a "paper doll").
-- `container` should be twice as tall as it is wide.
function LookRenderer.renderBody(container: GuiObject, client, look, options: Options?): Frame
	local old = container:FindFirstChild("Doll")
	if old then
		old:Destroy()
	end
	local root = Instance.new("Frame")
	root.Name = "Doll"
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.ZIndex = container.ZIndex
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 0.5
	aspect.Parent = root

	local skin = client.skin
	local outfit = Catalog.byId[look.outfit]
	local custom = Catalog.byId[look.outfitColor or ""]
	local dress = outfit ~= nil and outfit.dress == true
	local accent = if outfit and outfit.accent then outfit.accent else WHITE
	local function clothes(f: Frame)
		if custom and custom.color then
			f.BackgroundColor3 = custom.color
		else
			paint(f, outfit, Color3.fromRGB(110, 120, 135))
		end
		drawPattern(f, look.outfitPattern, if custom and custom.color then WHITE else accent)
	end

	-- legs and shoes (y is 0..1 down a body that's twice as tall as wide)
	for side = -1, 1, 2 do
		local leg = shape(root, 0.5 + side * 0.08, 0.8, 0.13, 0.26, if dress then skin else accent, 1, 0.5)
		if not dress then
			leg.BackgroundColor3 = if custom and custom.color then darken(custom.color, 0.7) else accent
		end
		shape(root, 0.5 + side * 0.095, 0.94, 0.17, 0.045, if dress then accent else Color3.fromRGB(250, 250, 255), 2, 0.5)
	end
	-- arms with sleeves and hands
	for side = -1, 1, 2 do
		local arm = shape(root, 0.5 + side * 0.29, 0.51, 0.11, 0.2, skin, 2, 0.5, 0, side * -10)
		arm.Name = "Arm"
		local sleeve = shape(root, 0.5 + side * 0.28, 0.45, 0.13, 0.09, Color3.new(), 3, 0.5, 0, side * -10)
		clothes(sleeve)
		shape(root, 0.5 + side * 0.31, 0.61, 0.11, 0.055, skin, 3, 0.5)
	end
	shape(root, 0.5, 0.385, 0.14, 0.05, skin, 3, 0.4) -- neck
	local top = shape(root, 0.5, 0.48, 0.5, 0.16, Color3.new(), 4, 0.3)
	clothes(top)
	shape(root, 0.5, 0.41, 0.16, 0.025, skin, 5, 0.5) -- neckline
	if dress then
		local skirt = shape(root, 0.5, 0.64, 0.8, 0.2, Color3.new(), 4, 0.35)
		clothes(skirt)
		shape(root, 0.5, 0.735, 0.78, 0.018, accent, 5, 0.5) -- hem trim
	else
		local pants = if custom and custom.color then darken(custom.color, 0.7) else accent
		shape(root, 0.5, 0.62, 0.32, 0.11, pants, 2, 0.25) -- hips
		local belt = shape(root, 0.5, 0.565, 0.5, 0.03, darken(top.BackgroundColor3, 0.75), 5, 0.3)
		belt.Name = "Belt"
	end

	-- the head is the same drawing as the makeover portrait
	local head = Instance.new("Frame")
	head.Name = "Head"
	head.AnchorPoint = Vector2.new(0.5, 0)
	head.Position = UDim2.fromScale(0.5, -0.05)
	head.Size = UDim2.fromScale(1.05, 0.525)
	head.BackgroundTransparency = 1
	head.ZIndex = 6
	head.Parent = root
	LookRenderer.render(head, client, look, {
		headOnly = true,
		clean = if options and options.clean then options.clean else 1,
		mood = if options and options.mood then options.mood else "smile",
	})
	local headRoot = head:FindFirstChild("Portrait")
	if headRoot and headRoot:IsA("GuiObject") then
		headRoot.ClipsDescendants = false
	end

	root.Parent = container
	return root
end

-- The nail station: a close-up of the client's hand.
local FINGERS = { { 0.335, 0.27 }, { 0.445, 0.17 }, { 0.555, 0.2 }, { 0.665, 0.28 } } -- x, fingertip y

function LookRenderer.renderHand(container: GuiObject, client, look): Frame
	local old = container:FindFirstChild("Portrait")
	if old then
		old:Destroy()
	end
	local root = Instance.new("Frame")
	root.Name = "Portrait"
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.ClipsDescendants = true
	root.ZIndex = container.ZIndex
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1
	aspect.Parent = root

	local skin = client.skin
	local polish = Catalog.byId[look.nailColor]
	local art = Catalog.byId[look.nailArt]
	local natural = skin:Lerp(Color3.fromRGB(255, 220, 225), 0.55)

	local outfit = Catalog.byId[look.outfit]
	local sleeve = shape(root, 0.5, 1.02, 0.46, 0.16, Color3.new(), 1, 0.3)
	paint(sleeve, outfit, Color3.fromRGB(110, 120, 135))
	shape(root, 0.5, 0.92, 0.34, 0.2, skin, 2, 0.3)
	shape(root, 0.5, 0.72, 0.46, 0.38, skin, 3, 0.3)

	local nails = {}
	for _, f in FINGERS do
		local x, top = f[1], f[2]
		local h = 0.62 - top
		shape(root, x, top + h / 2, 0.1, h, skin, 3, 0.5)
		table.insert(nails, { x = x, y = top + 0.055, rot = 0 })
	end
	shape(root, 0.255, 0.6, 0.1, 0.28, skin, 3, 0.5, 0, -38)
	table.insert(nails, { x = 0.185, y = 0.505, rot = -38 })
	-- little knuckle lines
	for _, f in FINGERS do
		shape(root, f[1], 0.47, 0.05, 0.008, darken(skin, 0.85), 4, 0.5)
	end

	for _, n in nails do
		local nail = shape(root, n.x, n.y, 0.074, 0.09, natural, 5, 0.45, 0, n.rot)
		nail.Name = "Nail"
		if polish and polish.color then
			paint(nail, polish)
		end
		shape(nail, 0.3, 0.3, 0.2, 0.35, WHITE, 6, 0.5, 0.45)
		if art and art.icon then
			local dark = polish and polish.color and select(3, polish.color:ToHSV()) > 0.75
			local t = glyph(nail, art.icon, 0.5, 0.55, 0.9, if dark then Color3.fromRGB(80, 40, 100) else WHITE, 7)
			t.Size = UDim2.fromScale(0.9, 0.7)
		end
	end
	root.Parent = container
	return root
end

-- Colors any UI frame like an item (used for the color swatches in the menus).
LookRenderer.paint = paint
-- Dots, stripes, hearts... on any frame (used on the 3D client's shirt and skirt).
LookRenderer.drawPattern = drawPattern

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

	local faceOnly = options and options.faceOnly
	if not faceOnly then
		drawHair(root, look, hairItem, options)
		if not (options and options.headOnly) then
			drawOutfit(root, client, look)
		end
		for side = -1, 1, 2 do
			local ear = shape(root, 0.5 + side * 0.22, 0.47, 0.06, 0.09, client.skin, Z.ears, 0.5)
			shape(ear, 0.5, 0.5, 0.45, 0.55, darken(client.skin, 0.85), Z.ears, 0.5)
		end
		shape(root, 0.5, 0.46, 0.44, 0.56, client.skin, Z.face, 0.5)
	end
	drawEyes(root, client, look, hairItem)
	drawCheeksAndLips(root, client, look, options and options.mood)
	drawGems(root, client, look)
	if not faceOnly then
		drawAccessory(root, look)
	end
	if (options and options.dirtHealth) or ((options and options.clean) or 0) < 1 then
		drawDirt(root, client, options)
	end

	root.Parent = container
	return root
end

return LookRenderer
