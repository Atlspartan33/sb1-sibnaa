-- Runway buddies, built from simple shapes: Bean the Boston terrier, a kitty, a bunny, a baby
-- dragon, a unicorn and a dino. Each pet is a small model whose pivot sits on the ground under it,
-- facing forward (-Z), so it can trot along next to its owner.

local Pets = {}

local rgb = Color3.fromRGB
local BLACK = rgb(28, 26, 30)
local WHITE = rgb(250, 250, 252)
local PINK = rgb(255, 150, 185)
local GOLD = rgb(250, 200, 70)

local function part(model: Model, name: string, size: Vector3, offset: CFrame, color: Color3, shape: Enum.PartType?, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.CFrame = offset
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = true
	p.Parent = model
	return p
end

local function ball(model, name, size: Vector3, pos: Vector3, color, material: Enum.Material?)
	return part(model, name, size, CFrame.new(pos), color, Enum.PartType.Ball, material)
end

-- Eyes with a shine, looking forward (-Z)
local function eyes(model, at: Vector3, spread: number, size: number)
	for side = -1, 1, 2 do
		ball(model, "Eye", Vector3.one * size, at + Vector3.new(side * spread, 0, 0), BLACK)
		ball(model, "Shine", Vector3.one * size * 0.35, at + Vector3.new(side * spread + 0.04, size * 0.2, -size * 0.4), WHITE, Enum.Material.Neon)
	end
end

local function legs(model, color: Color3, paw: Color3, width: number, length: number, height: number)
	for _, x in { -width, width } do
		for _, z in { -length, length } do
			part(model, "Leg", Vector3.new(height, 0.28, 0.28), CFrame.new(x, height / 2, z) * CFrame.Angles(0, 0, math.rad(90)), color, Enum.PartType.Cylinder)
			ball(model, "Paw", Vector3.new(0.32, 0.2, 0.36), Vector3.new(x, 0.1, z - 0.04), paw)
		end
	end
end

local BUILDERS = {}

-- Bean: Tori's Boston terrier. Black with a white blaze, white chest and white paws, tall bat ears.
function BUILDERS.pet_bean(m: Model)
	legs(m, BLACK, WHITE, 0.32, 0.45, 0.55)
	ball(m, "Body", Vector3.new(1.05, 0.85, 1.5), Vector3.new(0, 0.95, 0), BLACK)
	ball(m, "Chest", Vector3.new(0.7, 0.7, 0.5), Vector3.new(0, 0.95, -0.55), WHITE)
	ball(m, "Head", Vector3.new(0.95, 0.85, 0.85), Vector3.new(0, 1.6, -0.75), BLACK)
	part(m, "Blaze", Vector3.new(0.18, 0.55, 0.12), CFrame.new(0, 1.72, -1.15), WHITE)
	ball(m, "Muzzle", Vector3.new(0.5, 0.38, 0.35), Vector3.new(0, 1.42, -1.13), WHITE)
	ball(m, "Nose", Vector3.new(0.16, 0.12, 0.12), Vector3.new(0, 1.5, -1.3), BLACK)
	eyes(m, Vector3.new(0, 1.72, -1.12), 0.24, 0.16)
	for side = -1, 1, 2 do
		part(m, "Ear", Vector3.new(0.12, 0.55, 0.32), CFrame.new(side * 0.3, 2.12, -0.72) * CFrame.Angles(0, 0, math.rad(-side * 18)), BLACK)
		part(m, "EarInside", Vector3.new(0.13, 0.38, 0.18), CFrame.new(side * 0.3, 2.08, -0.75) * CFrame.Angles(0, 0, math.rad(-side * 18)), PINK)
	end
	ball(m, "Tail", Vector3.new(0.18, 0.18, 0.25), Vector3.new(0, 1.15, 0.78), BLACK)
end

function BUILDERS.pet_kitty(m: Model)
	local orange, cream = rgb(245, 150, 60), rgb(255, 230, 200)
	legs(m, orange, cream, 0.28, 0.45, 0.5)
	ball(m, "Body", Vector3.new(0.9, 0.8, 1.45), Vector3.new(0, 0.9, 0), orange)
	ball(m, "Head", Vector3.new(0.95, 0.85, 0.85), Vector3.new(0, 1.55, -0.72), orange)
	ball(m, "Muzzle", Vector3.new(0.45, 0.3, 0.3), Vector3.new(0, 1.42, -1.1), cream)
	ball(m, "Nose", Vector3.new(0.12, 0.09, 0.09), Vector3.new(0, 1.5, -1.24), PINK)
	eyes(m, Vector3.new(0, 1.67, -1.08), 0.22, 0.17)
	for side = -1, 1, 2 do
		part(m, "Ear", Vector3.new(0.1, 0.4, 0.4), CFrame.new(side * 0.3, 2.0, -0.7) * CFrame.Angles(math.rad(45), 0, math.rad(-side * 10)), orange)
	end
	for i = 0, 4 do
		ball(m, "Tail", Vector3.one * 0.24, Vector3.new(0, 1.0 + i * 0.22, 0.75 + math.sin(i * 0.6) * 0.15), if i == 4 then cream else orange)
	end
end

function BUILDERS.pet_bunny(m: Model)
	legs(m, WHITE, WHITE, 0.26, 0.38, 0.4)
	ball(m, "Body", Vector3.new(0.95, 0.9, 1.2), Vector3.new(0, 0.85, 0), WHITE)
	ball(m, "Head", Vector3.new(0.85, 0.8, 0.8), Vector3.new(0, 1.5, -0.55), WHITE)
	ball(m, "Nose", Vector3.new(0.12, 0.09, 0.09), Vector3.new(0, 1.42, -0.95), PINK)
	eyes(m, Vector3.new(0, 1.6, -0.9), 0.2, 0.15)
	for side = -1, 1, 2 do
		ball(m, "Ear", Vector3.new(0.24, 0.85, 0.14), Vector3.new(side * 0.18, 2.25, -0.5), WHITE)
		ball(m, "EarInside", Vector3.new(0.13, 0.6, 0.1), Vector3.new(side * 0.18, 2.25, -0.54), PINK)
	end
	ball(m, "Tail", Vector3.one * 0.35, Vector3.new(0, 0.95, 0.62), WHITE)
end

function BUILDERS.pet_dragon(m: Model)
	local purple, belly = rgb(140, 80, 220), rgb(255, 210, 120)
	legs(m, purple, purple, 0.3, 0.42, 0.5)
	ball(m, "Body", Vector3.new(1, 0.9, 1.4), Vector3.new(0, 0.95, 0), purple)
	ball(m, "Belly", Vector3.new(0.6, 0.6, 0.6), Vector3.new(0, 0.85, -0.45), belly)
	ball(m, "Head", Vector3.new(0.9, 0.8, 0.95), Vector3.new(0, 1.62, -0.8), purple)
	ball(m, "Snout", Vector3.new(0.55, 0.4, 0.5), Vector3.new(0, 1.48, -1.2), purple)
	eyes(m, Vector3.new(0, 1.78, -1.15), 0.22, 0.17)
	for side = -1, 1, 2 do
		part(m, "Horn", Vector3.new(0.12, 0.4, 0.12), CFrame.new(side * 0.22, 2.1, -0.7) * CFrame.Angles(math.rad(-20), 0, 0), belly)
		local wing = part(m, "Wing", Vector3.new(1.0, 0.06, 0.7), CFrame.new(side * 0.85, 1.45, 0.05) * CFrame.Angles(0, 0, math.rad(side * 30)), rgb(200, 150, 255))
		wing.Transparency = 0.1
	end
	for i = 0, 3 do
		ball(m, "Tail", Vector3.one * (0.34 - i * 0.05), Vector3.new(0, 0.85 - i * 0.08, 0.75 + i * 0.25), purple)
	end
end

function BUILDERS.pet_unicorn(m: Model)
	legs(m, WHITE, rgb(220, 200, 255), 0.32, 0.5, 0.7)
	ball(m, "Body", Vector3.new(1, 0.95, 1.6), Vector3.new(0, 1.15, 0), WHITE)
	part(m, "Neck", Vector3.new(0.5, 0.75, 0.5), CFrame.new(0, 1.7, -0.6) * CFrame.Angles(math.rad(-25), 0, 0), WHITE)
	ball(m, "Head", Vector3.new(0.7, 0.7, 0.95), Vector3.new(0, 2.12, -0.9), WHITE)
	eyes(m, Vector3.new(0, 2.22, -1.22), 0.22, 0.14)
	part(m, "Horn", Vector3.new(0.13, 0.55, 0.13), CFrame.new(0, 2.6, -1.0) * CFrame.Angles(math.rad(-15), 0, 0), GOLD, nil, Enum.Material.Neon)
	local mane = { rgb(255, 120, 170), rgb(255, 200, 90), rgb(120, 210, 255), rgb(190, 130, 255) }
	for i, c in mane do
		ball(m, "Mane", Vector3.one * 0.32, Vector3.new(0, 2.35 - i * 0.18, -0.65 + i * 0.12), c)
		ball(m, "Tail", Vector3.one * 0.3, Vector3.new(0, 1.3 - i * 0.15, 0.85 + i * 0.05), c)
	end
end

function BUILDERS.pet_dino(m: Model)
	local green, belly = rgb(90, 190, 90), rgb(240, 230, 140)
	for side = -1, 1, 2 do
		part(m, "Leg", Vector3.new(0.35, 0.6, 0.4), CFrame.new(side * 0.3, 0.3, 0.1), green)
	end
	ball(m, "Body", Vector3.new(1, 1.1, 1.3), Vector3.new(0, 1.0, 0), green)
	ball(m, "Belly", Vector3.new(0.6, 0.75, 0.4), Vector3.new(0, 0.95, -0.45), belly)
	ball(m, "Head", Vector3.new(0.85, 0.75, 1.0), Vector3.new(0, 1.8, -0.55), green)
	eyes(m, Vector3.new(0, 1.95, -0.95), 0.24, 0.16)
	for i = 0, 3 do
		part(m, "Spike", Vector3.new(0.08, 0.3, 0.3), CFrame.new(0, 2.15 - i * 0.28, -0.25 + i * 0.33) * CFrame.Angles(math.rad(45), 0, 0), rgb(255, 150, 60))
	end
	for i = 0, 3 do
		ball(m, "Tail", Vector3.one * (0.45 - i * 0.08), Vector3.new(0, 0.75 - i * 0.12, 0.65 + i * 0.3), green)
	end
	for side = -1, 1, 2 do
		ball(m, "Arm", Vector3.new(0.18, 0.18, 0.3), Vector3.new(side * 0.35, 1.25, -0.55), green)
	end
end

-- A fresh pet model, or nil for "no pet".
function Pets.build(petId: string?): Model?
	local builder = petId and BUILDERS[petId]
	if not builder then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = "Pet"
	builder(model)
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(0.2, 0.2, 0.2)
	root.CFrame = CFrame.new()
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.Parent = model
	model.PrimaryPart = root
	return model
end

-- Trots `pet` beside `owner` (any model with a HumanoidRootPart), a little hop in each step.
-- Call every frame; dt is the frame time.
function Pets.follow(pet: Model, owner: Model, dt: number, side: number?)
	local root = owner:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) or not pet.PrimaryPart then
		return
	end
	local humanoid = owner:FindFirstChildOfClass("Humanoid")
	local feet = root.Position.Y - (if humanoid then humanoid.HipHeight + root.Size.Y / 2 else 3)
	local spot = root.CFrame * CFrame.new((side or 1) * 2.6, 0, 0.6)
	local goal = Vector3.new(spot.Position.X, feet, spot.Position.Z)
	local current = pet:GetPivot()
	local pos = current.Position:Lerp(goal, 1 - math.exp(-dt * 6))
	local moving = (goal - current.Position).Magnitude > 0.2
	local hop = if moving then math.abs(math.sin(os.clock() * 10)) * 0.35 else math.abs(math.sin(os.clock() * 2)) * 0.06
	local facing = root.CFrame.LookVector
	pet:PivotTo(CFrame.lookAt(Vector3.new(pos.X, feet + hop, pos.Z), Vector3.new(pos.X, feet + hop, pos.Z) + Vector3.new(facing.X, 0, facing.Z)))
end

return Pets
