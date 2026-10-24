-- Builds the salon, runway, big screen, audience seats and winners' podium when the game starts.
-- Building with code means the place works straight away; you can still decorate around it in Studio.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

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

-- Soft, glowy, pastel look for the whole game
local function setupLighting()
	for _, effect in Lighting:GetChildren() do
		if effect.Name == "GlowUp" then
			effect:Destroy()
		end
	end
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
	color.TintColor = rgb(255, 245, 252)
	color.Parent = Lighting
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "GlowUp"
	atmosphere.Density = 0.28
	atmosphere.Color = rgb(255, 214, 236)
	atmosphere.Decay = rgb(200, 170, 255)
	atmosphere.Haze = 1.2
	atmosphere.Glare = 0.4
	atmosphere.Parent = Lighting
end

local function cameraMarker(parent: Instance, name: string, from: Vector3, to: Vector3)
	local p = part(parent, name, Vector3.new(1, 1, 1), CFrame.lookAt(from, to), Color3.new(1, 1, 1))
	p.Transparency = 1
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
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
		seat.Size = Vector3.new(3, 1, 3)
		seat.CFrame = CFrame.new(x, 2, 59) * CFrame.Angles(0, math.pi, 0)
		seat.Color = PURPLE
		seat.Parent = salon
		part(salon, "ChairBack", Vector3.new(3, 3, 0.6), CFrame.new(x, 3.5, 60.3), PURPLE)
		part(salon, "ChairBase", Vector3.new(1, 1.5, 1), CFrame.new(x, 0.75, 59), rgb(200, 200, 210), Enum.Material.Metal)
	end
	local salonSign = part(salon, "SalonSign", Vector3.new(36, 7, 1), CFrame.new(0, 15, 67), rgb(255, 255, 255))
	sign(salonSign, Enum.NormalId.Front, "✨ 5 Minute Glow Up Salon ✨", PINK)

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
	setupLighting()

	return {
		folder = folder,
		screen = screen,
		runwayStart = Vector3.new(0, runwayTopY, runwayStartZ),
		runwayEnd = Vector3.new(0, runwayTopY, runwayEndZ),
		podium = podium,
		confetti = confetti,
	}
end

return WorldBuilder
