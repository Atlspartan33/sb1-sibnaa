-- Builds the salon, runway, big screen, audience seats and winners' podium when the game starts.
-- Building with code means the place works straight away; you can still decorate around it in Studio.

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
	part(salon, "SalonFloor", Vector3.new(70, 0.2, 40), CFrame.new(0, 0.1, 50), rgb(250, 250, 255), Enum.Material.Marble)
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

	-- Winners' podium at the front of the runway
	local podiumFolder = Instance.new("Folder")
	podiumFolder.Name = "Podium"
	podiumFolder.Parent = folder
	local podiumZ = -2
	local blocks = {
		{ x = 0, h = 5, color = GOLD, label = "1" },
		{ x = -7, h = 3.5, color = rgb(200, 205, 215), label = "2" },
		{ x = 7, h = 2.5, color = rgb(215, 140, 80), label = "3" },
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
	cameraMarker(cameras, "Results", Vector3.new(0, 8, 16), Vector3.new(0, 5, -2))

	folder.Parent = Workspace

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
