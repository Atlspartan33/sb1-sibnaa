-- Builds the salon, runway, big screen, audience seats and winners' podium when the game starts.
-- Building with code means the place works straight away; you can still decorate around it in Studio.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Stations = require(ReplicatedStorage.Shared.Stations)

local WorldBuilder = {}

export type World = {
	folder: Folder,
	screen: BasePart,
	runwayStart: Vector3, -- runway floor height where clients start walking
	runwayEnd: Vector3,
	podium: { Vector3 }, -- top of 1st, 2nd, 3rd place blocks
	confetti: { ParticleEmitter },
}

local rgb = Color3.fromRGB
local PINK = rgb(255, 120, 190)
local PURPLE = rgb(150, 90, 220)
local GOLD = rgb(245, 200, 70)

local function part(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function sign(p: BasePart, face: Enum.NormalId, text: string, textColor: Color3)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = textColor
	label.Parent = gui
	gui.Parent = p
end

local function ball(parent: Instance, name: string, diameter: number, position: Vector3, color: Color3, material: Enum.Material?): Part
	local p = part(parent, name, Vector3.new(diameter, diameter, diameter), CFrame.new(position), color, material)
	p.Shape = Enum.PartType.Ball
	return p
end

local function plant(parent: Instance, position: Vector3)
	local pot = part(parent, "Pot", Vector3.new(2.4, 2.6, 2.6), CFrame.new(position + Vector3.new(0, 1.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), rgb(255, 255, 255))
	pot.Shape = Enum.PartType.Cylinder
	ball(parent, "Leaves", 4, position + Vector3.new(0, 4, 0), rgb(110, 200, 120), Enum.Material.Grass)
	ball(parent, "Flower", 1, position + Vector3.new(0.8, 5.6, 0.6), rgb(255, 120, 180))
	ball(parent, "Flower", 0.9, position + Vector3.new(-1, 5.2, -0.4), rgb(255, 220, 90))
end

-- Lighting for everyday and for each holiday event
local LOOKS = {
	everyday = { clock = 14.5, tint = rgb(255, 245, 252), air = rgb(255, 214, 236), decay = rgb(200, 170, 255), strip = PINK },
	halloween = { clock = 18.4, tint = rgb(250, 230, 255), air = rgb(200, 150, 255), decay = rgb(255, 140, 60), strip = rgb(255, 130, 30) },
	thanksgiving = { clock = 16.8, tint = rgb(255, 238, 220), air = rgb(255, 210, 160), decay = rgb(230, 140, 80), strip = rgb(255, 160, 50) },
	christmas = { clock = 15.5, tint = rgb(245, 250, 255), air = rgb(225, 240, 255), decay = rgb(180, 210, 255), strip = rgb(230, 40, 50) },
}

-- Soft, glowy, pastel look for the whole game
local function setupLighting(look)
	for _, effect in Lighting:GetChildren() do
		if effect.Name == "GlowUp" then
			effect:Destroy()
		end
	end
	Lighting.ClockTime = look.clock
	local bloom = Instance.new("BloomEffect")
	bloom.Name = "GlowUp"
	bloom.Intensity = 0.45
	bloom.Size = 28
	bloom.Threshold = 1.9
	bloom.Parent = Lighting
	local color = Instance.new("ColorCorrectionEffect")
	color.Name = "GlowUp"
	color.Saturation = 0.15
	color.Brightness = 0.03
	color.Contrast = 0.05
	color.TintColor = look.tint
	color.Parent = Lighting
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "GlowUp"
	atmosphere.Density = 0.28
	atmosphere.Color = look.air
	atmosphere.Decay = look.decay
	atmosphere.Haze = 0.6
	atmosphere.Glare = 0
	atmosphere.Parent = Lighting
end

-- An emoji floating in the air (bats, ghosts, leaves, snowflakes)
local function floater(parent: Instance, emoji: string, position: Vector3, size: number)
	local anchor = part(parent, "Floater", Vector3.new(0.2, 0.2, 0.2), CFrame.new(position), rgb(255, 255, 255))
	anchor.Transparency = 1
	anchor.CanCollide = false
	anchor.CanQuery = false
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(size, size)
	gui.LightInfluence = 0
	gui.MaxDistance = 300
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = emoji
	label.TextScaled = true
	label.Parent = gui
	gui.Parent = anchor
end

local function pumpkin(parent: Instance, position: Vector3, size: number)
	local body = ball(parent, "Pumpkin", size, position + Vector3.new(0, size / 2, 0), rgb(245, 130, 30))
	local stem = part(parent, "Stem", Vector3.new(size * 0.25, size * 0.12, size * 0.12), CFrame.new(position + Vector3.new(0, size * 1.02, 0)) * CFrame.Angles(0, 0, math.rad(90)), rgb(70, 130, 50))
	stem.Shape = Enum.PartType.Cylinder
	local face = Instance.new("SurfaceGui")
	face.Face = Enum.NormalId.Back
	face.LightInfluence = 0
	face.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	face.PixelsPerStud = 40
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "▲ ▲\n◡◡◡"
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = rgb(60, 25, 10)
	label.Parent = face
	face.Parent = body
end

local function christmasTree(parent: Instance, position: Vector3, height: number)
	local trunk = part(parent, "Trunk", Vector3.new(height * 0.15, height * 0.12, height * 0.12), CFrame.new(position + Vector3.new(0, height * 0.075, 0)) * CFrame.Angles(0, 0, math.rad(90)), rgb(110, 70, 40))
	trunk.Shape = Enum.PartType.Cylinder
	local layers = 8
	for i = 0, layers - 1 do
		local w = height * (0.66 - i * 0.075)
		local y = height * (0.2 + i * 0.09)
		local green = if i % 2 == 0 then rgb(40, 140, 70) else rgb(55, 165, 85)
		local layer = part(parent, "Branches", Vector3.new(height * 0.1, w, w), CFrame.new(position + Vector3.new(0, y, 0)) * CFrame.Angles(0, 0, math.rad(90)), green)
		layer.Shape = Enum.PartType.Cylinder
		local colors = { rgb(230, 40, 50), GOLD, rgb(90, 170, 255), PINK }
		for j = 0, (if i % 2 == 0 then 4 else -1) do
			local a = math.rad(j * 72 + i * 25)
			ball(parent, "Ornament", height * 0.05, position + Vector3.new(math.cos(a) * w * 0.47, y - height * 0.05, math.sin(a) * w * 0.47), colors[(i + j) % #colors + 1], Enum.Material.Neon)
		end
	end
	ball(parent, "TreeStar", height * 0.1, position + Vector3.new(0, height * 0.95, 0), GOLD, Enum.Material.Neon)
end

local function present(parent: Instance, position: Vector3, size: number, color: Color3)
	part(parent, "Present", Vector3.new(size, size * 0.8, size), CFrame.new(position + Vector3.new(0, size * 0.4, 0)), color)
	part(parent, "Ribbon", Vector3.new(size * 1.02, size * 0.82, size * 0.18), CFrame.new(position + Vector3.new(0, size * 0.4, 0)), rgb(255, 255, 255))
	part(parent, "Ribbon", Vector3.new(size * 0.18, size * 0.82, size * 1.02), CFrame.new(position + Vector3.new(0, size * 0.4, 0)), rgb(255, 255, 255))
end

local function autumnTree(parent: Instance, position: Vector3)
	local trunk = part(parent, "Trunk", Vector3.new(7, 1.4, 1.4), CFrame.new(position + Vector3.new(0, 3.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), rgb(110, 70, 40))
	trunk.Shape = Enum.PartType.Cylinder
	ball(parent, "Leaves", 7, position + Vector3.new(0, 9, 0), rgb(230, 110, 30), Enum.Material.Grass)
	ball(parent, "Leaves", 5, position + Vector3.new(1.8, 10.5, 1), rgb(200, 60, 30), Enum.Material.Grass)
	ball(parent, "Leaves", 4.5, position + Vector3.new(-2, 10, -1), rgb(240, 180, 40), Enum.Material.Grass)
end

-- Spots around the salon, runway and podium where decorations go
local DECOR_SPOTS = {
	Vector3.new(-42, 0, 38), Vector3.new(42, 0, 38), Vector3.new(-42, 0, 62), Vector3.new(42, 0, 62),
	Vector3.new(-18, 0, -30), Vector3.new(18, 0, -30), Vector3.new(-22, 0, -50), Vector3.new(22, 0, -50),
	Vector3.new(-52, 0, -8), Vector3.new(-16, 0, 6), Vector3.new(10, 0, 20), Vector3.new(-10, 0, 20),
}

local built = nil

-- The salon is a rooftop party: the building's edge drops away to a glowing city, glass railings
-- run round the roof, string lights hang over the plaza, and a red carpet leads from the Dressing
-- Hall to the runway.
local function buildRooftop(parent: Instance)
	local roof = Instance.new("Folder")
	roof.Name = "Rooftop"
	roof.Parent = parent
	local minX, maxX, minZ, maxZ = -80, 80, -80, 110
	local midZ = (minZ + maxZ) / 2

	-- the building under the roof (so the floor doesn't end in thin air)
	local facade = rgb(64, 44, 92)
	part(roof, "RoofEdge", Vector3.new(maxX - minX + 2, 80, 2), CFrame.new(0, -41, minZ - 1), facade)
	part(roof, "RoofEdge", Vector3.new(maxX - minX + 2, 80, 2), CFrame.new(0, -41, maxZ + 1), facade)
	part(roof, "RoofEdge", Vector3.new(2, 80, maxZ - minZ + 2), CFrame.new(minX - 1, -41, midZ), facade)
	part(roof, "RoofEdge", Vector3.new(2, 80, maxZ - minZ + 2), CFrame.new(maxX + 1, -41, midZ), facade)

	-- glass railings with a glowing gold top rail
	local function railing(a: Vector3, b: Vector3)
		local cf = CFrame.lookAt((a + b) / 2, b)
		local length = (b - a).Magnitude
		local glass = part(roof, "RailGlass", Vector3.new(0.3, 3.4, length), cf + Vector3.new(0, 1.7, 0), rgb(200, 230, 255), Enum.Material.Glass)
		glass.Transparency = 0.6
		local rail = part(roof, "RailTop", Vector3.new(0.5, 0.4, length), cf + Vector3.new(0, 3.5, 0), GOLD, Enum.Material.Neon)
		rail.CastShadow = false
	end
	local inset = 0.5
	railing(Vector3.new(minX + inset, 0, minZ + inset), Vector3.new(maxX - inset, 0, minZ + inset))
	railing(Vector3.new(minX + inset, 0, maxZ - inset), Vector3.new(maxX - inset, 0, maxZ - inset))
	railing(Vector3.new(minX + inset, 0, minZ + inset), Vector3.new(minX + inset, 0, maxZ - inset))
	railing(Vector3.new(maxX - inset, 0, minZ + inset), Vector3.new(maxX - inset, 0, maxZ - inset))

	-- the city at night: towers all around, with rows of lit windows
	local rng = Random.new(7) -- the same city every time
	local windowColors = { rgb(255, 214, 140), rgb(255, 150, 205), rgb(150, 220, 255), rgb(205, 170, 255) }
	for i = 1, 44 do
		local a = (i / 44) * math.pi * 2 + rng:NextNumber(-0.04, 0.04)
		local distance = rng:NextNumber(135, 185)
		local x, z = math.cos(a) * distance, midZ + math.sin(a) * distance * 1.1
		local w, d = rng:NextNumber(14, 26), rng:NextNumber(14, 26)
		local top = rng:NextNumber(-30, 55)
		local bottom = -140
		local tone = rng:NextInteger(0, 18)
		part(roof, "Tower", Vector3.new(w, top - bottom, d), CFrame.new(x, (top + bottom) / 2, z), rgb(30 + tone, 24 + tone, 58 + tone)).CastShadow = false
		local glow = windowColors[rng:NextInteger(1, #windowColors)]
		for y = top - 5, math.max(top - 48, -70), -6 do
			if rng:NextNumber() < 0.7 then
				local band = part(roof, "Windows", Vector3.new(w + 0.2, 0.9, d + 0.2), CFrame.new(x, y, z), glow, Enum.Material.Neon)
				band.CastShadow = false
				band.Color = glow:Lerp(rgb(40, 30, 70), 0.25) -- (a little dimmer instead of see-through: cheaper on tablets)
			end
		end
		if top > 35 then
			-- a little red light on the tallest roofs
			ball(roof, "BeaconLight", 1.4, Vector3.new(x, top + 1, z), rgb(255, 70, 90), Enum.Material.Neon)
		end
	end

	-- string lights over the plaza between the Dressing Hall and the runway
	local bulbColors = { rgb(255, 230, 150), PINK, rgb(140, 220, 255), GOLD }
	for i, z in { 24, 12, 0 } do
		for _, x in { -46, 46 } do
			part(roof, "LightPole", Vector3.new(0.7, 19, 0.7), CFrame.new(x, 9.5, z), rgb(60, 48, 84), Enum.Material.Metal)
			ball(roof, "PoleCap", 1.2, Vector3.new(x, 19.2, z), GOLD, Enum.Material.Neon)
		end
		for k = 0, 30 do
			local t = k / 30
			local bulb = ball(roof, "Bulb", 0.55, Vector3.new(-46 + 92 * t, 18 - math.sin(t * math.pi) * 3.5, z), bulbColors[(k + i) % #bulbColors + 1], Enum.Material.Neon)
			bulb.CanCollide = false
			bulb.CastShadow = false
		end
	end

	-- a red carpet out of the Dressing Hall, with gold posts and velvet ropes (it ends behind the
	-- show camera so the posts never get in the runway shot)
	part(roof, "RedCarpet", Vector3.new(6, 0.12, 15), CFrame.new(0, 0.06, 22.5), rgb(196, 28, 78), Enum.Material.Fabric)
	for _, x in { -3.8, 3.8 } do
		local last: Vector3? = nil
		for z = 28, 16, -6 do
			local post = Vector3.new(x, 0, z)
			local pole = part(roof, "Stanchion", Vector3.new(0.35, 3, 0.35), CFrame.new(post + Vector3.new(0, 1.5, 0)), GOLD, Enum.Material.Metal)
			pole.CanCollide = false
			ball(roof, "StanchionTop", 0.7, post + Vector3.new(0, 3.1, 0), GOLD, Enum.Material.Metal).CanCollide = false
			if last then
				local a, b = last + Vector3.new(0, 2.2, 0), post + Vector3.new(0, 2.2, 0)
				local rope = part(roof, "VelvetRope", Vector3.new(0.25, 0.25, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), rgb(140, 0, 45), Enum.Material.Fabric)
				rope.CanCollide = false
			end
			last = post
		end
	end
end

-- Swaps in the decorations and lighting for a holiday event (or nil for everyday).
function WorldBuilder.setDecor(eventId: string?)
	if not built then
		return
	end
	local old = built.folder:FindFirstChild("Decor")
	if old then
		old:Destroy()
	end
	local look = LOOKS[eventId or "everyday"] or LOOKS.everyday
	setupLighting(look)
	for _, p in built.folder:GetDescendants() do
		if p:IsA("BasePart") and p.Name == "LightStrip" then
			p.Color = look.strip
			local light = p:FindFirstChildOfClass("PointLight")
			if light then
				light.Color = look.strip
			end
		end
	end
	if not eventId then
		return
	end

	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	if eventId == "halloween" then
		for i, spot in DECOR_SPOTS do
			pumpkin(decor, spot, if i % 3 == 0 then 3.2 else 2.4)
			pumpkin(decor, spot + Vector3.new(2.6, 0, 1), 1.6)
		end
		for i = 1, 10 do
			floater(decor, if i % 3 == 0 then "👻" else "🦇", Vector3.new(-16 + (i % 5) * 8, 16 + (i % 3) * 3, -50 + i * 6), 3)
		end
		for i = 1, 6 do
			local side = if i % 2 == 0 then 1 else -1
			floater(decor, "🦇", Vector3.new(side * (24 + i * 2), 13 + (i % 3) * 2.5, 52), 2.5)
		end
	elseif eventId == "thanksgiving" then
		for i, spot in DECOR_SPOTS do
			if i % 2 == 0 then
				autumnTree(decor, spot)
			else
				part(decor, "HayBale", Vector3.new(4, 2.4, 2.6), CFrame.new(spot + Vector3.new(0, 1.2, 0)), rgb(230, 200, 110), Enum.Material.Sand)
				pumpkin(decor, spot + Vector3.new(0, 2.4, 0), 1.6)
			end
			for j = 0, 4 do
				ball(decor, "Leaf", 0.9, spot + Vector3.new(3 + (j % 3) * 0.8, 0.2, -1 + j * 0.5), ({ rgb(220, 90, 30), rgb(200, 50, 30), rgb(240, 180, 40) })[j % 3 + 1])
			end
		end
		for i = 1, 12 do
			floater(decor, if i % 2 == 0 then "🍂" else "🍁", Vector3.new(-18 + (i % 6) * 7, 12 + (i % 4) * 3, -52 + i * 8), 2.2)
		end
	elseif eventId == "christmas" then
		for i, spot in DECOR_SPOTS do
			if i % 2 == 1 then
				christmasTree(decor, spot, if i <= 4 then 16 else 12)
			end
			local colors = { rgb(230, 40, 50), rgb(40, 150, 70), GOLD, PURPLE }
			present(decor, spot + Vector3.new(3, 0, 2), 1.8, colors[i % #colors + 1])
			present(decor, spot + Vector3.new(-2.5, 0, 2.5), 1.3, colors[(i + 1) % #colors + 1])
			part(decor, "Snow", Vector3.new(10, 0.25, 8), CFrame.new(spot + Vector3.new(0, 0.12, 0)), rgb(250, 252, 255), Enum.Material.Snow)
		end
		local cloud = part(decor, "SnowCloud", Vector3.new(160, 1, 190), CFrame.new(0, 60, 10), rgb(255, 255, 255))
		cloud.Transparency = 1
		cloud.CanCollide = false
		cloud.CanQuery = false
		local snow = Instance.new("ParticleEmitter")
		snow.Rate = 120
		snow.Lifetime = NumberRange.new(10, 14)
		snow.Speed = NumberRange.new(4, 7)
		snow.Size = NumberSequence.new(0.35)
		snow.EmissionDirection = Enum.NormalId.Bottom
		snow.SpreadAngle = Vector2.new(15, 15)
		snow.LightEmission = 0.3
		snow.Texture = Config.Textures.Circle
		snow.Parent = cloud
		for i = 1, 8 do
			floater(decor, "❄️", Vector3.new(-16 + (i % 4) * 10, 15 + (i % 3) * 3, -50 + i * 8), 2.4)
		end
	end
	decor.Parent = built.folder
end

local function cameraMarker(parent: Instance, name: string, from: Vector3, to: Vector3)
	local p = part(parent, name, Vector3.new(1, 1, 1), CFrame.lookAt(from, to), Color3.new(1, 1, 1))
	p.Transparency = 1
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
end

-- The Dressing Hall: a glowing pad, a sign and a few props for each station (see Shared.Stations).
local function buildStations(salon: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "Stations"
	folder.Parent = salon
	for _, s in Stations.list do
		local pad = part(folder, "Pad_" .. s.id, Vector3.new(0.3, Stations.PAD_RADIUS * 2, Stations.PAD_RADIUS * 2), CFrame.new(s.pad) * CFrame.Angles(0, 0, math.rad(90)), s.color, Enum.Material.Neon)
		pad.Shape = Enum.PartType.Cylinder
		pad.Transparency = 0.35
		pad.CanCollide = false
		pad:SetAttribute("Station", s.id)
		-- A floating sign over each pad, readable from the salon floor
		local board = part(folder, "Sign_" .. s.id, Vector3.new(9, 2.4, 0.4), CFrame.lookAt(s.pad + Vector3.new(0, 10.5, 0), s.pad + Vector3.new(0, 10.5, 0) + s.facing), rgb(255, 255, 255))
		board.CanCollide = false
		sign(board, Enum.NormalId.Front, s.icon .. " " .. s.name, s.color:Lerp(rgb(40, 20, 60), 0.35))
		local beam = Instance.new("PointLight")
		beam.Color = s.color
		beam.Range = 10
		beam.Brightness = 0.7
		beam.Parent = pad
	end

	-- Props that say what each station is for
	local hair = Stations.byTab.Hair.pad
	part(folder, "Dryer", Vector3.new(2.2, 1.6, 2.2), CFrame.new(hair + Vector3.new(0, 5.6, 4.6)), rgb(240, 240, 250), Enum.Material.Metal).Shape = Enum.PartType.Ball
	local face = Stations.byTab.Face.pad
	for i, c in { rgb(255, 60, 120), rgb(200, 30, 60), rgb(255, 140, 180) } do
		part(folder, "Lipstick", Vector3.new(0.5, 1.4, 0.5), CFrame.new(face + Vector3.new(-2 + i, 3.9, 9.3)), c)
	end
	local outfit = Stations.byTab.Outfit.pad
	part(folder, "RackBar", Vector3.new(8, 0.2, 0.2), CFrame.new(outfit + Vector3.new(0, 6.2, 8.6)), rgb(200, 200, 210), Enum.Material.Metal)
	for i, c in { rgb(255, 120, 190), rgb(90, 160, 255), rgb(245, 200, 70), rgb(130, 210, 90), rgb(170, 120, 230) } do
		part(folder, "Shirt", Vector3.new(1.2, 2.2, 0.3), CFrame.new(outfit + Vector3.new(-3.2 + i * 1.3, 4.9, 8.6)), c, Enum.Material.Fabric)
	end
	local costume = Stations.byTab.Costume.pad
	part(folder, "Trunk", Vector3.new(4, 2, 2.4), CFrame.new(costume + Vector3.new(3.5, 1, 6)), rgb(140, 80, 40), Enum.Material.Wood)
	part(folder, "Cape", Vector3.new(2.4, 3.6, 0.2), CFrame.new(costume + Vector3.new(-3.6, 3.6, 8.2)), rgb(220, 30, 50), Enum.Material.Fabric)
	local show = Stations.byTab.Show.pad
	local stage = part(folder, "PoseStage", Vector3.new(0.5, 9.5, 9.5), CFrame.new(show + Vector3.new(0, -0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)), GOLD, Enum.Material.SmoothPlastic)
	stage.Shape = Enum.PartType.Cylinder
	stage.CanCollide = false
	local light = part(folder, "StageLight", Vector3.new(1.2, 1.2, 1.2), CFrame.new(show + Vector3.new(0, 13, 0)), rgb(255, 250, 230), Enum.Material.Neon)
	local spot = Instance.new("SpotLight")
	spot.Face = Enum.NormalId.Bottom
	spot.Color = rgb(255, 240, 220)
	spot.Range = 16
	spot.Brightness = 1.6
	spot.Angle = 45
	spot.Parent = light
	local pet = Stations.byTab.Pet.pad
	local grass = part(folder, "PetGrass", Vector3.new(14, 0.15, 12), CFrame.new(pet + Vector3.new(2, -0.12, 0)), rgb(120, 200, 110), Enum.Material.Grass)
	grass.CanCollide = false
	for _, z in { -6, 6 } do
		part(folder, "Fence", Vector3.new(14, 1.4, 0.3), CFrame.new(pet + Vector3.new(2, 0.7, z)), rgb(255, 255, 255), Enum.Material.Wood)
	end
	local house = pet + Vector3.new(7, 0, 0)
	part(folder, "DogHouse", Vector3.new(3.4, 2.8, 3.4), CFrame.new(house + Vector3.new(0, 1.4, 0)), rgb(255, 176, 96), Enum.Material.WoodPlanks)
	part(folder, "DogDoor", Vector3.new(0.12, 1.8, 1.4), CFrame.new(house + Vector3.new(-1.72, 0.95, 0)), rgb(70, 36, 40))
	-- a beam turned on its edge makes the pitched roof (the lower half hides inside the walls)
	part(folder, "DogRoof", Vector3.new(4, 2.7, 2.7), CFrame.new(house + Vector3.new(0, 2.8, 0)) * CFrame.Angles(math.rad(45), 0, 0), rgb(214, 60, 96), Enum.Material.WoodPlanks)
	ball(folder, "DogBowl", 0.9, pet + Vector3.new(4.6, 0.2, 2.2), rgb(90, 160, 255))
end

-- Somewhere to hang out between rounds: step on the floor and you dance (see Main.client)
local function buildDanceFloor(salon: Instance)
	local floor = Instance.new("Folder")
	floor.Name = "DanceFloor"
	floor.Parent = salon
	local center = Vector3.new(-24, 0.25, 39)
	local colors = { PINK, PURPLE, GOLD, rgb(90, 200, 255) }
	local tiles = {}
	for ix = -2, 1 do
		for iz = -2, 1 do
			local t = part(floor, "DanceTile", Vector3.new(2.9, 0.3, 2.9), CFrame.new(center + Vector3.new(ix * 3 + 1.5, 0, iz * 3 + 1.5)), colors[(ix + iz) % 4 + 1], Enum.Material.Neon)
			t.CanCollide = false
			table.insert(tiles, t)
		end
	end
	local board = part(floor, "DanceSign", Vector3.new(9, 2.4, 0.4), CFrame.lookAt(center + Vector3.new(0, 9, 0), center + Vector3.new(1, 9, 0)), rgb(255, 255, 255))
	board.CanCollide = false
	sign(board, Enum.NormalId.Front, "🕺 Dance Floor 💃", PURPLE)
	floor:SetAttribute("Center", center)
	floor:SetAttribute("Radius", 6)
	local marker = part(floor, "DanceHere", Vector3.new(0.5, 0.5, 0.5), CFrame.new(center + Vector3.new(0, 5.5, 0)), PINK)
	marker.Transparency = 1
	marker.CanCollide = false
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(150, 54)
	billboard.LightInfluence = 0
	billboard.MaxDistance = 90
	billboard.Parent = marker
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = rgb(190, 20, 105)
	label.TextColor3 = rgb(255, 255, 255)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = "💃 Dance here!"
	label.Parent = billboard
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = label
	-- the tiles twinkle through the colors
	task.spawn(function()
		local step = 0
		while floor.Parent do
			step += 1
			for i, t in tiles do
				t.Color = colors[(i + step) % #colors + 1]
			end
			task.wait(0.6)
		end
	end)
end

-- Life in the Dressing Hall: a disco ball over the dance floor, string lights, wall lights that
-- drift through the colors, floating sparkles, balloon bunches, and a photo booth (Main.client
-- does the 3-2-1 and the flash when you step on its pad).
local function buildAtmosphere(salon: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "Atmosphere"
	folder.Parent = salon
	local colors = { PINK, PURPLE, GOLD, rgb(90, 200, 255), rgb(120, 220, 140) }

	-- Disco ball with spinning colored spots over the dance floor
	local floor = salon:FindFirstChild("DanceFloor")
	local center = floor and floor:GetAttribute("Center") or Vector3.new(-24, 0, 39)
	local disco = part(folder, "DiscoBall", Vector3.new(3.4, 3.4, 3.4), CFrame.new(center + Vector3.new(0, 12, 0)), rgb(232, 232, 245), Enum.Material.Foil)
	disco.Shape = Enum.PartType.Ball
	disco.Reflectance = 0.45
	local shine = Instance.new("PointLight")
	shine.Range = 8
	shine.Brightness = 0.8
	shine.Color = rgb(255, 240, 255)
	shine.Parent = disco
	disco.CanCollide = false
	part(folder, "DiscoString", Vector3.new(0.1, 6, 0.1), CFrame.new(center + Vector3.new(0, 16.6, 0)), rgb(200, 200, 210)).CanCollide = false
	local spots = {}
	for i, c in { PINK, rgb(90, 200, 255), GOLD } do
		local s = Instance.new("SpotLight")
		s.Color = c
		s.Range = 18
		s.Brightness = 1.4
		s.Angle = 35
		s.Face = Enum.NormalId.Bottom
		local holder = part(folder, "DiscoSpot" .. i, Vector3.new(0.2, 0.2, 0.2), disco.CFrame, c)
		holder.Transparency = 1
		holder.CanCollide = false
		s.Parent = holder
		table.insert(spots, holder)
	end
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Texture = Config.Textures.Star
	sparkle.Color = ColorSequence.new(rgb(255, 240, 255), rgb(255, 190, 230))
	sparkle.Size = NumberSequence.new(0.35, 0)
	sparkle.Lifetime = NumberRange.new(1.5, 2.5)
	sparkle.Speed = NumberRange.new(2, 4)
	sparkle.SpreadAngle = Vector2.new(180, 180)
	sparkle.Rate = 6
	sparkle.LightEmission = 0.7
	sparkle.Parent = disco

	-- String lights along the top of the back wall and over the entrance
	for x = -34, 34, 2 do
		local bulb = part(folder, "Bulb", Vector3.new(0.6, 0.6, 0.6), CFrame.new(x, 20.5 - math.abs(math.sin(x / 4)) * 0.8, 69.2), colors[(x // 2) % #colors + 1], Enum.Material.Neon)
		bulb.Shape = Enum.PartType.Ball
		bulb.CanCollide = false
		bulb.CastShadow = false
	end

	-- Wall lights that drift slowly through the colors
	local wallLights = {}
	for _, x in { -30, -10, 10, 30 } do
		local lamp = part(folder, "WallLamp", Vector3.new(1.4, 1.4, 0.4), CFrame.new(x, 13, 69.4), rgb(255, 255, 255), Enum.Material.Neon)
		lamp.CanCollide = false
		local l = Instance.new("PointLight")
		l.Range = 22
		l.Brightness = 0.7
		l.Parent = lamp
		table.insert(wallLights, { lamp = lamp, light = l })
	end

	-- Sparkles floating in the air of the hall
	local air = part(folder, "HallSparkles", Vector3.new(60, 1, 30), CFrame.new(0, 16, 50), rgb(255, 255, 255))
	air.Transparency = 1
	air.CanCollide = false
	local float = Instance.new("ParticleEmitter")
	float.Texture = Config.Textures.Star
	float.Color = ColorSequence.new(rgb(255, 220, 245), rgb(220, 200, 255))
	float.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.35), NumberSequenceKeypoint.new(1, 0) })
	float.Lifetime = NumberRange.new(4, 7)
	float.Speed = NumberRange.new(0.5, 1.5)
	float.SpreadAngle = Vector2.new(180, 180)
	float.Rate = 10
	float.LightEmission = 0.6
	float.Shape = Enum.ParticleEmitterShape.Box
	float.Parent = air

	-- Balloon bunches beside each station
	for i, s in Stations.list do
		local base = s.pad + Vector3.new(if i % 2 == 0 then 5.5 else -5.5, 0, 2)
		for k = 0, 2 do
			local c = colors[(i + k) % #colors + 1]
			local pos = base + Vector3.new((k - 1) * 0.9, 7 + (k % 2) * 0.8, 0)
			ball(folder, "Balloon", 1.6, pos, c).Reflectance = 0.15
			part(folder, "BalloonString", Vector3.new(0.05, 6, 0.05), CFrame.new(pos - Vector3.new(0, 3.6, 0)), rgb(255, 255, 255)).CanCollide = false
		end
	end

	-- Photo booth by the entrance, facing into the hall: a frame, a backdrop and a glowing pad to stand on
	local booth = Vector3.new(8, 0.2, 36)
	local back = part(folder, "BoothBackdrop", Vector3.new(9, 9, 0.4), CFrame.new(booth + Vector3.new(0, 4.5, -3.4)) * CFrame.Angles(0, math.pi, 0), rgb(255, 235, 245))
	sign(back, Enum.NormalId.Front, "📸", PINK)
	part(folder, "BoothFrameTop", Vector3.new(9.6, 0.6, 0.6), CFrame.new(booth + Vector3.new(0, 9.2, -3.2)), GOLD, Enum.Material.Neon).CanCollide = false
	for _, x in { -4.8, 4.8 } do
		part(folder, "BoothFrameSide", Vector3.new(0.6, 9, 0.6), CFrame.new(booth + Vector3.new(x, 4.5, -3.2)), GOLD, Enum.Material.Neon)
	end
	local boothPad = part(folder, "BoothPad", Vector3.new(0.3, 5, 5), CFrame.new(booth) * CFrame.Angles(0, 0, math.rad(90)), GOLD, Enum.Material.Neon)
	boothPad.Shape = Enum.PartType.Cylinder
	boothPad.Transparency = 0.35
	boothPad.CanCollide = false
	local boothSign = part(folder, "BoothSign", Vector3.new(8, 2, 0.4), CFrame.lookAt(booth + Vector3.new(0, 10.8, -3), booth + Vector3.new(0, 10.8, 0)), rgb(190, 20, 105))
	boothSign.CanCollide = false
	sign(boothSign, Enum.NormalId.Front, "📸 Photo Booth", rgb(255, 255, 255))
	folder:SetAttribute("BoothCenter", booth)

	-- Slow motion: the disco spots sweep around and the wall lights change color
	task.spawn(function()
		local t = 0
		while folder.Parent do
			t += 0.1
			disco.CFrame = CFrame.new(disco.Position) * CFrame.Angles(0, t * 0.6, 0)
			for i, holder in spots do
				local a = t * 0.8 + i * 2.1
				holder.CFrame = CFrame.lookAt(disco.Position, center + Vector3.new(math.cos(a) * 5, 0, math.sin(a) * 5))
			end
			for i, w in wallLights do
				local c = Color3.fromHSV((t * 0.02 + i * 0.25) % 1, 0.45, 1)
				w.lamp.Color = c
				w.light.Color = c
			end
			task.wait(0.1)
		end
	end)
end

-- Fireworks over the runway when the crowd goes wild for a walk.
function WorldBuilder.fireworks()
	if not built then
		return
	end
	local colors = { PINK, GOLD, rgb(120, 220, 255), rgb(190, 130, 255), rgb(140, 255, 170) }
	local rng = Random.new()
	for i = 1, 7 do
		task.delay((i - 1) * 0.28, function()
			if not built then
				return
			end
			local burst = part(built.folder, "Firework", Vector3.new(1, 1, 1), CFrame.new(rng:NextNumber(-16, 16), rng:NextNumber(13, 21), rng:NextNumber(-46, -20)), Color3.new(1, 1, 1))
			burst.Transparency = 1
			burst.CanCollide = false
			burst.CanQuery = false
			burst.CanTouch = false
			local color = colors[rng:NextInteger(1, #colors)]
			local sparks = Instance.new("ParticleEmitter")
			sparks.Texture = Config.Textures.Star
			sparks.Color = ColorSequence.new(color, rgb(255, 255, 255))
			sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0) })
			sparks.Lifetime = NumberRange.new(1.2, 1.8)
			sparks.Speed = NumberRange.new(16, 24)
			sparks.SpreadAngle = Vector2.new(180, 180)
			sparks.Drag = 2.5
			sparks.Acceleration = Vector3.new(0, -6, 0)
			sparks.LightEmission = 1
			sparks.Rate = 0
			sparks.Parent = burst
			local flash = Instance.new("PointLight")
			flash.Color = color
			flash.Range = 40
			flash.Brightness = 2
			flash.Parent = burst
			sparks:Emit(80)
			task.delay(0.35, function()
				flash.Enabled = false
			end)
			task.delay(2.5, function()
				burst:Destroy()
			end)
		end)
	end
end

function WorldBuilder.build(): World
	local old = Workspace:FindFirstChild("GlowUpWorld")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "GlowUpWorld"

	-- Floor
	part(folder, "Floor", Vector3.new(160, 1, 190), CFrame.new(0, -0.5, 15), rgb(255, 225, 238))
	buildRooftop(folder)

	-- Salon (where everyone spawns)
	local salon = Instance.new("Folder")
	salon.Name = "Salon"
	salon.Parent = folder
	-- Checkerboard salon floor
	local tile = 5
	for ix = 0, 13 do
		for iz = 0, 7 do
			local color = if (ix + iz) % 2 == 0 then rgb(255, 255, 255) else rgb(255, 205, 228)
			part(salon, "Tile", Vector3.new(tile, 0.2, tile), CFrame.new(-32.5 + ix * tile, 0.1, 32.5 + iz * tile), color, Enum.Material.SmoothPlastic)
		end
	end
	part(salon, "BackWall", Vector3.new(72, 22, 1), CFrame.new(0, 11, 70), rgb(74, 36, 96))
	-- a pink and white striped awning over the stations
	for i = 0, 17 do
		local x = -34 + i * 4
		local stripe = part(salon, "Awning", Vector3.new(4, 0.3, 8), CFrame.new(x, 20.4, 66.2) * CFrame.Angles(math.rad(-18), 0, 0), if i % 2 == 0 then PINK else rgb(255, 255, 255), Enum.Material.Fabric)
		stripe.CastShadow = false
		local scallop = part(salon, "AwningScallop", Vector3.new(0.3, 3.6, 3.6), CFrame.new(x, 19.1, 62.4) * CFrame.Angles(0, 0, math.rad(90)), if i % 2 == 0 then PINK else rgb(255, 255, 255), Enum.Material.Fabric)
		scallop.Shape = Enum.PartType.Cylinder
		scallop.CastShadow = false
	end
	for _, x in { -34, 34 } do
		plant(salon, Vector3.new(x, 0, 66))
		plant(salon, Vector3.new(x, 0, 34))
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.new(0, 0.5, 42)
	spawn.Color = PINK
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.Parent = salon

	for i = -2, 2 do
		local x = i * 13
		part(salon, "Mirror", Vector3.new(6, 8, 0.4), CFrame.new(x, 6, 66), rgb(200, 230, 255), Enum.Material.Glass).Reflectance = 0.35
		part(salon, "MirrorFrame", Vector3.new(7, 9, 0.3), CFrame.new(x, 6, 66.4), PINK, Enum.Material.Neon)
		part(salon, "Counter", Vector3.new(8, 3, 2.5), CFrame.new(x, 1.5, 64.5), rgb(255, 255, 255))
		local seat = Instance.new("Seat")
		seat.Name = "SalonChair"
		seat.Anchored = true
		seat.Disabled = true -- scenery: you stand on the glowing pad in front of it
		seat.Size = Vector3.new(3, 1, 3)
		seat.CFrame = CFrame.new(x, 2, 59) * CFrame.Angles(0, math.pi, 0)
		seat.Color = PURPLE
		seat.Parent = salon
		part(salon, "ChairBack", Vector3.new(3, 3, 0.6), CFrame.new(x, 3.5, 60.3), PURPLE)
		part(salon, "ChairBase", Vector3.new(1, 1.5, 1), CFrame.new(x, 0.75, 59), rgb(200, 200, 210), Enum.Material.Metal)
	end
	local salonSign = part(salon, "SalonSign", Vector3.new(36, 6, 1), CFrame.new(0, 14.6, 67), rgb(190, 20, 105))
	sign(salonSign, Enum.NormalId.Front, "✨ 5 Minute Glow Up Salon ✨", rgb(255, 255, 255))
	part(salon, "SalonSignFrame", Vector3.new(37, 7, 0.6), CFrame.new(0, 14.6, 67.6), GOLD, Enum.Material.Neon)
	buildStations(salon)
	buildDanceFloor(salon)
	buildAtmosphere(salon)

	-- Runway
	local runway = Instance.new("Folder")
	runway.Name = "Runway"
	runway.Parent = folder
	local runwayTopY = 2
	local runwayStartZ, runwayEndZ = -50, -12
	local length = math.abs(runwayEndZ - runwayStartZ) + 6
	local midZ = (runwayStartZ + runwayEndZ) / 2
	part(runway, "Catwalk", Vector3.new(8, runwayTopY, length), CFrame.new(0, runwayTopY / 2, midZ), rgb(255, 255, 255), Enum.Material.Marble)
	part(runway, "Carpet", Vector3.new(4, 0.1, length), CFrame.new(0, runwayTopY + 0.05, midZ), rgb(255, 90, 170), Enum.Material.Fabric)
	for side = -1, 1, 2 do
		local strip = part(runway, "LightStrip", Vector3.new(0.4, 0.3, length), CFrame.new(side * 4.2, runwayTopY + 0.15, midZ), PINK, Enum.Material.Neon)
		local light = Instance.new("PointLight")
		light.Color = PINK
		light.Range = 12
		light.Brightness = 0.5
		light.Parent = strip
	end

	-- Big screen behind the runway
	local screen = part(runway, "Screen", Vector3.new(44, 24, 1), CFrame.new(0, 14, -57), rgb(25, 18, 35))
	part(runway, "ScreenFrame", Vector3.new(46, 26, 0.8), CFrame.new(0, 14, -57.6), PURPLE, Enum.Material.Neon)
	for side = -1, 1, 2 do
		part(runway, "Pillar", Vector3.new(4, 28, 4), CFrame.new(side * 25, 14, -56), PURPLE)
		local cap = part(runway, "PillarLight", Vector3.new(4.4, 1, 4.4), CFrame.new(side * 25, 28.5, -56), GOLD, Enum.Material.Neon)
		local spot = Instance.new("SpotLight")
		spot.Face = Enum.NormalId.Bottom
		spot.Angle = 60
		spot.Range = 60
		spot.Brightness = 1
		spot.Color = rgb(255, 230, 245)
		spot.Parent = cap
	end

	-- Balloon arch where clients come out
	local balloonColors = { PINK, rgb(255, 255, 255), PURPLE, GOLD, rgb(140, 210, 255) }
	for i = 0, 22 do
		local a = math.rad(i * (180 / 22))
		local pos = Vector3.new(math.cos(a) * 9, runwayTopY + math.sin(a) * 11, runwayStartZ - 1)
		ball(runway, "Balloon", 2.8, pos, balloonColors[i % #balloonColors + 1]).Reflectance = 0.15
		ball(runway, "Balloon", 2, pos + Vector3.new(0, 0, 1.6), balloonColors[(i + 2) % #balloonColors + 1]).Reflectance = 0.15
	end
	for side = -1, 1, 2 do
		plant(runway, Vector3.new(side * 18, 0, -50))
		plant(runway, Vector3.new(side * 18, 0, -12))
	end

	-- Confetti cannons for Runway Star pass holders
	local confetti = {}
	for side = -1, 1, 2 do
		local cannon = part(runway, "ConfettiCannon", Vector3.new(1.5, 1.5, 1.5), CFrame.new(side * 6, 1, runwayEndZ), GOLD, Enum.Material.Neon)
		local emitter = Instance.new("ParticleEmitter")
		emitter.Enabled = false
		emitter.Rate = 0
		emitter.Lifetime = NumberRange.new(2, 3)
		emitter.Speed = NumberRange.new(25, 40)
		emitter.SpreadAngle = Vector2.new(30, 30)
		emitter.Acceleration = Vector3.new(0, -20, 0)
		emitter.Size = NumberSequence.new(0.5)
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.RotSpeed = NumberRange.new(-200, 200)
		emitter.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, rgb(255, 100, 170)),
			ColorSequenceKeypoint.new(0.33, rgb(255, 220, 80)),
			ColorSequenceKeypoint.new(0.66, rgb(100, 200, 255)),
			ColorSequenceKeypoint.new(1, rgb(180, 120, 255)),
		})
		emitter.EmissionDirection = Enum.NormalId.Top
		emitter.Texture = Config.Textures.Star
		emitter.Parent = cannon
		table.insert(confetti, emitter)
	end

	-- Audience seats along both sides of the runway
	for _, x in { -9, -13, 9, 13 } do
		for z = runwayStartZ + 4, runwayEndZ - 2, 6 do
			local seat = Instance.new("Seat")
			seat.Name = "AudienceSeat"
			seat.Anchored = true
			seat.Size = Vector3.new(3, 1, 3)
			seat.CFrame = CFrame.new(x, 0.5, z) * CFrame.Angles(0, if x < 0 then -math.pi / 2 else math.pi / 2, 0)
			seat.Color = if math.abs(x) == 9 then PINK else PURPLE
			seat.Parent = runway
			local outward = if x < 0 then -1 else 1
			part(runway, "SeatBack", Vector3.new(0.5, 2.6, 3), CFrame.new(x + outward * 1.3, 1.8, z), seat.Color)
		end
	end

	-- Winners' podium, off to the side so it never blocks the runway
	local podiumFolder = Instance.new("Folder")
	podiumFolder.Name = "Podium"
	podiumFolder.Parent = folder
	local podiumX, podiumZ = -32, -8
	local blocks = {
		{ x = podiumX, h = 5, color = GOLD, label = "1" },
		{ x = podiumX - 7, h = 3.5, color = rgb(200, 205, 215), label = "2" },
		{ x = podiumX + 7, h = 2.5, color = rgb(215, 140, 80), label = "3" },
	}
	local podium = {}
	for _, b in blocks do
		local block = part(podiumFolder, "Place" .. b.label, Vector3.new(6, b.h, 6), CFrame.new(b.x, b.h / 2, podiumZ), b.color)
		sign(block, Enum.NormalId.Back, b.label, rgb(255, 255, 255))
		table.insert(podium, Vector3.new(b.x, b.h, podiumZ))
	end

	-- Where the camera goes during the show and the results
	local cameras = Instance.new("Folder")
	cameras.Name = "Cameras"
	cameras.Parent = folder
	cameraMarker(cameras, "Showcase", Vector3.new(0, 9, 14), Vector3.new(0, 6, -36))
	cameraMarker(cameras, "Results", Vector3.new(podiumX + 7, 9, podiumZ + 19), Vector3.new(podiumX + 7, 5.5, podiumZ))
	part(podiumFolder, "PodiumStage", Vector3.new(26, 0.4, 12), CFrame.new(podiumX, 0.2, podiumZ), rgb(255, 235, 245), Enum.Material.Marble)
	for i = 0, 24 do
		local a = math.rad(i * (180 / 24))
		local pos = Vector3.new(podiumX + math.cos(a) * 12, 0.5 + math.sin(a) * 11, podiumZ - 4)
		ball(podiumFolder, "Balloon", 2.6, pos, balloonColors[i % #balloonColors + 1]).Reflectance = 0.15
		ball(podiumFolder, "Balloon", 1.9, pos + Vector3.new(0, 0, 1.4), balloonColors[(i + 2) % #balloonColors + 1]).Reflectance = 0.15
	end

	folder.Parent = Workspace
	setupLighting(LOOKS.everyday)

	built = {
		folder = folder,
		screen = screen,
		runwayStart = Vector3.new(0, runwayTopY, runwayStartZ),
		runwayEnd = Vector3.new(0, runwayTopY, runwayEndZ),
		podium = podium,
		confetti = confetti,
	}
	return built
end

return WorldBuilder
