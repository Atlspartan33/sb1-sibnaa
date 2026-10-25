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
	bloom.Intensity = 0.7
	bloom.Size = 28
	bloom.Threshold = 1.6
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
	atmosphere.Haze = 1.2
	atmosphere.Glare = 0.4
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
			floater(decor, "🦇", Vector3.new(-20 + i * 6, 14 + (i % 2) * 3, 50), 2.5)
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
		beam.Brightness = 1.2
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
	spot.Brightness = 3
	spot.Angle = 45
	spot.Parent = light
	local pet = Stations.byTab.Pet.pad
	local grass = part(folder, "PetGrass", Vector3.new(14, 0.15, 12), CFrame.new(pet + Vector3.new(2, -0.12, 0)), rgb(120, 200, 110), Enum.Material.Grass)
	grass.CanCollide = false
	for _, z in { -6, 6 } do
		part(folder, "Fence", Vector3.new(14, 1.4, 0.3), CFrame.new(pet + Vector3.new(2, 0.7, z)), rgb(255, 255, 255), Enum.Material.Wood)
	end
	part(folder, "DogHouse", Vector3.new(3, 3, 3), CFrame.new(pet + Vector3.new(7, 1.5, 0)), rgb(255, 160, 80), Enum.Material.Wood)
	part(folder, "DogRoof", Vector3.new(3.6, 1.2, 3.6), CFrame.new(pet + Vector3.new(7, 3.6, 0)), rgb(200, 60, 80), Enum.Material.Wood)
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

function WorldBuilder.build(): World
	local old = Workspace:FindFirstChild("GlowUpWorld")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "GlowUpWorld"

	-- Floor
	part(folder, "Floor", Vector3.new(160, 1, 190), CFrame.new(0, -0.5, 15), rgb(255, 225, 238))

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
	part(salon, "BackWall", Vector3.new(72, 22, 1), CFrame.new(0, 11, 70), rgb(235, 220, 255))
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
	local salonSign = part(salon, "SalonSign", Vector3.new(36, 7, 1), CFrame.new(0, 15, 67), rgb(255, 255, 255))
	sign(salonSign, Enum.NormalId.Front, "✨ 5 Minute Glow Up Salon ✨", PINK)
	buildStations(salon)
	buildDanceFloor(salon)

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
		light.Brightness = 1.5
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
		spot.Brightness = 3
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
