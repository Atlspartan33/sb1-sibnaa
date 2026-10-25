-- The client as a real Roblox character: an R15 body in the client's skin tone, real hair from the
-- avatar shop recolored to the chosen hair color, the makeover face (makeup, dirt, smile) on the
-- head, the outfit colors and pattern on the body, a skirt for dresses, and the accessory.
--
-- The server loads the body and every hairstyle once (Avatar.preload) into ReplicatedStorage, so
-- the server (runway, podium) and each player's screen (the makeover) can build clients instantly.

local InsertService = game:GetService("InsertService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.Catalog)
local Config = require(ReplicatedStorage.Shared.Config)
local LookRenderer = require(ReplicatedStorage.Shared.LookRenderer)

local Avatar = {}

-- How far each hairstyle sticks up above the head (studs), so hats and bows sit on the hair.
local HAIR_LIFT = {
	hair_curls = 0.9,
	hair_puff = 0.8,
	hair_updo = 0.55,
	hair_buns = 0.45,
	hair_messy = 0.35,
	hair_pigtails = 0.3,
}

local ASSETS = "GlowUpAvatar"
local IDLE_ANIMATION = "rbxassetid://507766388" -- Roblox's default R15 idle
local DEFAULT_HAIR = Color3.fromRGB(105, 66, 40)
local WHITE = Color3.new(1, 1, 1)

------------------------------------------------------------------------------
-- Loading (server)

local function stripTexture(handle: BasePart)
	if handle:IsA("MeshPart") then
		handle.TextureID = ""
	end
	for _, d in handle:GetDescendants() do
		if d:IsA("SpecialMesh") then
			d.TextureId = ""
		elseif d:IsA("SurfaceAppearance") or d:IsA("Decal") or d:IsA("Texture") then
			d:Destroy()
		end
	end
	handle.Material = Enum.Material.SmoothPlastic
end

-- Loads the body and hairstyles into ReplicatedStorage. Call once on the server.
function Avatar.preload()
	if ReplicatedStorage:FindFirstChild(ASSETS) then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = ASSETS
	local hairFolder = Instance.new("Folder")
	hairFolder.Name = "Hair"
	hairFolder.Parent = folder

	local desc = Instance.new("HumanoidDescription")
	-- Colors are replaced when a look is put on; these are just a neutral start
	local start = Color3.fromRGB(161, 102, 66)
	desc.HeadColor, desc.TorsoColor = start, start
	desc.LeftArmColor, desc.RightArmColor, desc.LeftLegColor, desc.RightLegColor = start, start, start, start
	-- A slimmer, more doll-like shape than the default blocky body
	desc.WidthScale = 0.8
	desc.DepthScale = 0.85
	desc.HeightScale = 1
	desc.ProportionScale = 1
	desc.BodyTypeScale = 0.3
	local ok, rig = pcall(Players.CreateHumanoidModelFromDescription, Players, desc, Enum.HumanoidRigType.R15)
	if ok and rig then
		rig.Name = "Rig"
		for _, d in rig:GetDescendants() do
			-- The stock face goes (the makeover face replaces it), and so do any scripts
			if d:IsA("Decal") or d:IsA("Script") or d:IsA("LocalScript") then
				d:Destroy()
			elseif d:IsA("BasePart") then
				d.CanCollide = false
				d.CanQuery = false
				d.CanTouch = false
			end
		end
		local humanoid = rig:FindFirstChildOfClass("Humanoid") :: Humanoid
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		rig.Parent = folder
	else
		warn("[GlowUp] Could not build the client body:", rig)
	end

	-- Avatar-shop items load side by side; each one that fails is simply skipped.
	local pending = 0
	-- Hairstyles lose their textures so any hair color can be used; costume pieces (wings, capes,
	-- masks, tails, buddies, hats) keep their own colors
	local costumeFolder = Instance.new("Folder")
	costumeFolder.Name = "Costume"
	costumeFolder.Parent = folder
	for _, category in Catalog.Categories do
		for _, it in category.items do
			local assetId = it.asset
			if assetId then
				pending += 1
				task.spawn(function()
					local loaded, model = pcall(InsertService.LoadAsset, InsertService, assetId)
					local acc = loaded and model and model:FindFirstChildWhichIsA("Accessory", true)
					local handle = acc and acc:FindFirstChild("Handle")
					if acc and handle and handle:IsA("BasePart") then
						for _, p in acc:GetDescendants() do
							if p:IsA("BasePart") then
								p.CanCollide = false
								p.CanQuery = false
								p.CanTouch = false
								p.Massless = true
							end
						end
						acc.Name = it.id
						if it.category == "hairStyle" then
							stripTexture(handle)
							acc.Parent = hairFolder
						else
							acc.Parent = costumeFolder
						end
					else
						warn("[GlowUp] Could not load", it.id, assetId, model)
					end
					pending -= 1
				end)
			end
		end
	end

	pending += 1
	task.spawn(function()
		local loaded, model = pcall(InsertService.LoadAsset, InsertService, Config.Catwalk.Walk)
		local anim = loaded and model and model:FindFirstChildWhichIsA("Animation", true)
		if anim then
			folder:SetAttribute("CatwalkWalk", anim.AnimationId)
		end
		pending -= 1
	end)

	local started = os.clock()
	while pending > 0 and os.clock() - started < 20 do
		task.wait(0.1)
	end
	folder:SetAttribute("Ready", true)
	folder.Parent = ReplicatedStorage
end

-- The loaded body and hair. Waits up to `timeout` seconds for them (0 = don't wait).
function Avatar.assets(timeout: number?): Folder?
	local wait = timeout or 30
	local folder = if wait > 0 then ReplicatedStorage:WaitForChild(ASSETS, wait) else ReplicatedStorage:FindFirstChild(ASSETS)
	return folder :: Folder?
end

------------------------------------------------------------------------------
-- Building

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, shape: Enum.PartType?, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.Parent = parent
	return p
end

-- Welds `p` to `to` where it is now, so it follows the body (on the runway, while twirling).
local function attach(p: BasePart, to: BasePart)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = to
	weld.Part1 = p
	weld.Parent = p
end

-- The makeover face goes on the front of the head as a SurfaceGui, scaled so its eyes and mouth
-- land where a face would be.
local function addFaceGui(head: BasePart)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "GlamFace"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 260
	gui.LightInfluence = 0.5
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local holder = Instance.new("Frame")
	holder.Name = "Holder"
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.6)
	holder.Size = UDim2.fromScale(1.8, 1.8)
	holder.BackgroundTransparency = 1
	holder.Parent = gui
	gui.Parent = head
end

-- A fresh client body. Returns nil if the body couldn't be loaded.
function Avatar.new(client): Model?
	local assets = Avatar.assets()
	local rig = assets and assets:FindFirstChild("Rig")
	if not rig then
		return nil
	end
	local model = rig:Clone() :: Model
	model.Name = client.name
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Color = client.skin
		end
	end
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
	root.Anchored = true
	model.PrimaryPart = root
	addFaceGui(model:FindFirstChild("Head") :: BasePart)
	return model
end

-- Gets a player's own character ready for a round. They keep their own body, skin and
-- animations; the round swaps in a classic head (so makeup lines up with the drawn face) and
-- takes off their own hair, clothes and accessories (the round adds new ones). Their normal look
-- comes back when they respawn after the show. Server only. Returns their skin color.
function Avatar.prepareCharacter(character: Model): Color3?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil
	end
	local ok, desc = pcall(function()
		return humanoid:GetAppliedDescription()
	end)
	if not ok or not desc then
		return nil
	end
	local base = desc:Clone()
	base.Head = 0
	base.Face = 0
	-- strut like a model for the round
	base.WalkAnimation = Config.Catwalk.Walk
	base.RunAnimation = Config.Catwalk.Run
	base.IdleAnimation = Config.Catwalk.Idle
	base.Shirt, base.Pants, base.GraphicTShirt = 0, 0, 0
	base.HatAccessory, base.HairAccessory, base.FaceAccessory, base.NeckAccessory = "", "", "", ""
	base.ShouldersAccessory, base.FrontAccessory, base.BackAccessory, base.WaistAccessory = "", "", "", ""
	pcall(function()
		base:SetAccessories({}, true) -- layered clothing too
	end)
	local applied = pcall(function()
		humanoid:ApplyDescription(base)
	end)
	if not applied then
		-- still take off their own hair and hats so the round's look can go on
		for _, d in character:GetChildren() do
			if d:IsA("Accessory") or d:IsA("Shirt") or d:IsA("Pants") or d:IsA("ShirtGraphic") then
				d:Destroy()
			end
		end
	end
	local head = character:FindFirstChild("Head")
	if head and head:IsA("BasePart") and not head:FindFirstChild("GlamFace") then
		for _, d in head:GetChildren() do
			if d:IsA("Decal") then
				d:Destroy()
			end
		end
		addFaceGui(head)
	end
	return desc.HeadColor
end

-- Plays the default idle on a client standing somewhere (makeover screen, podium).
function Avatar.idle(model: Model): AnimationTrack?
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	local anim = Instance.new("Animation")
	anim.AnimationId = IDLE_ANIMATION
	local ok, track = pcall(function()
		return (animator :: Animator):LoadAnimation(anim)
	end)
	if ok and track then
		track.Looped = true
		track:Play()
		return track
	end
	return nil
end

------------------------------------------------------------------------------
-- Dressing

local function colorOf(it: Catalog.Item?, fallback: Color3): Color3
	return if it and it.color then it.color else fallback
end

local function sparkles(p: BasePart, color: Color3, rate: number)
	local e = Instance.new("ParticleEmitter")
	e.Name = "Sparkle"
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(color:Lerp(WHITE, 0.5))
	e.LightEmission = 0.8
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(0.6, 1)
	e.Speed = NumberRange.new(0.3, 0.8)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Rate = rate
	e.Parent = p
end

local function emoji(parent: Instance, adornee: BasePart, text: string, offset: Vector3, size: number)
	local bb = Instance.new("BillboardGui")
	bb.Name = "Emoji"
	bb.Adornee = adornee
	bb.Size = UDim2.fromScale(size, size)
	bb.StudsOffset = offset
	bb.LightInfluence = 0
	bb.MaxDistance = 150
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextScaled = true
	t.Parent = bb
	bb.Parent = parent
end

local function addHair(glam: Folder, head: BasePart, look, options: LookRenderer.Options?)
	local assets = Avatar.assets(0)
	local style = look.hairStyle
	local template = assets and assets:FindFirstChild("Hair") and assets.Hair:FindFirstChild(style or "")
	if not template then
		return
	end
	local acc = template:Clone() :: Accessory
	local handle = acc:FindFirstChild("Handle") :: BasePart
	local hairItem = Catalog.byId[look.hairColor]
	local color = colorOf(hairItem, DEFAULT_HAIR)
	handle.Color = color
	-- Line the hair's attachment up with the same attachment on the head
	local accAttachment = handle:FindFirstChildWhichIsA("Attachment")
	local headAttachment = accAttachment and head:FindFirstChild(accAttachment.Name)
	if accAttachment and headAttachment and headAttachment:IsA("Attachment") then
		handle.CFrame = headAttachment.WorldCFrame * accAttachment.CFrame:Inverse()
	else
		handle.CFrame = head.CFrame * CFrame.new(0, head.Size.Y * 0.35, 0)
	end
	handle.Anchored = false
	for _, w in handle:GetChildren() do
		if w:IsA("JointInstance") or w:IsA("WeldConstraint") then
			w:Destroy()
		end
	end
	attach(handle, head)
	handle.Name = "Hair"
	handle.Parent = glam
	acc:Destroy()
	if hairItem and hairItem.sparkle or (hairItem and hairItem.gradient) then
		sparkles(handle, color, 6)
	end

	-- Messy hair has frizzy tufts until it's brushed
	if style == "hair_messy" and not (options and options.brushed) then
		local tangle = if options and options.tangle then options.tangle else 1
		local top = head.CFrame * CFrame.new(0, head.Size.Y * 0.5 + 0.25, 0)
		for i = 1, 9 do
			local a = (i / 9) * math.pi * 2
			local tuft = part(glam, "Tuft", Vector3.new(0.32, 0.32, 0.32), top * CFrame.new(math.cos(a) * 0.55, (i % 3) * 0.12, math.sin(a) * 0.45), color, Enum.PartType.Ball)
			tuft.Transparency = 1 - tangle
			attach(tuft, head)
		end
	end
end

-- An avatar-shop costume piece, lined up with the matching attachment on the body.
local function addCostume(glam: Folder, model: Model, itemId: string?)
	local assets = Avatar.assets(0)
	local costumes = assets and assets:FindFirstChild("Costume")
	local template = costumes and costumes:FindFirstChild(itemId or "")
	if not template then
		return
	end
	local acc = template:Clone() :: Accessory
	local handle = acc:FindFirstChild("Handle") :: BasePart
	local accAttachment = handle:FindFirstChildWhichIsA("Attachment")
	local bodyAttachment = nil
	if accAttachment then
		for _, d in model:GetDescendants() do
			if d:IsA("Attachment") and d.Name == accAttachment.Name and d.Parent and d.Parent:IsA("BasePart") and not d:IsDescendantOf(glam) then
				bodyAttachment = d
				break
			end
		end
	end
	local anchor = (if bodyAttachment then bodyAttachment.Parent else model:FindFirstChild("Head")) :: BasePart
	if bodyAttachment and accAttachment then
		handle.CFrame = bodyAttachment.WorldCFrame * accAttachment.CFrame:Inverse()
	else
		handle.CFrame = anchor.CFrame
	end
	for _, p in acc:GetDescendants() do
		if p:IsA("JointInstance") or p:IsA("WeldConstraint") then
			p:Destroy()
		elseif p:IsA("BasePart") then
			p.Anchored = false
			if p ~= handle then
				attach(p, handle)
			end
		end
	end
	attach(handle, anchor)
	acc.Parent = glam
end

-- Runway effects that follow the avatar around.
local EFFECTS = {
	fx_sparkles = { texture = "rbxasset://textures/particles/sparkles_main.dds", colors = { Color3.fromRGB(255, 240, 160), WHITE }, rate = 14, speed = 1.5, size = 0.5 },
	fx_hearts = { texture = "rbxassetid://5857851618", colors = { Color3.fromRGB(255, 90, 150), Color3.fromRGB(255, 160, 200) }, rate = 6, speed = 2, size = 0.6, up = true },
	fx_bubbles = { texture = "rbxassetid://6711256324", colors = { Color3.fromRGB(170, 220, 255), WHITE }, rate = 8, speed = 2, size = 0.5, up = true, transparency = 0.5 },
	fx_stars = { texture = "rbxassetid://6772783963", colors = { Color3.fromRGB(255, 220, 80), WHITE }, rate = 8, speed = 2.5, size = 0.6 },
	fx_snow = { texture = "rbxasset://textures/particles/sparkles_main.dds", colors = { WHITE, Color3.fromRGB(210, 235, 255) }, rate = 30, speed = 3, size = 0.35, down = true },
	fx_leaves = { texture = "rbxassetid://6772783963", colors = { Color3.fromRGB(90, 200, 90), Color3.fromRGB(170, 230, 90) }, rate = 8, speed = 2, size = 0.45, down = true },
	fx_confetti = { texture = "rbxasset://textures/particles/sparkles_main.dds", colors = { Color3.fromRGB(255, 90, 150), Color3.fromRGB(255, 210, 60), Color3.fromRGB(90, 170, 255), Color3.fromRGB(120, 220, 120) }, rate = 25, speed = 5, size = 0.4, down = true },
}

local function addEffect(glam: Folder, model: Model, effectId: string?)
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	local chest = (model:FindFirstChild("UpperTorso") or root) :: BasePart?
	if not root or not chest or not effectId or Catalog.isNone(effectId) then
		return
	end
	local spot = part(glam, "EffectSpot", Vector3.new(0.1, 0.1, 0.1), chest.CFrame, WHITE)
	spot.Transparency = 1
	attach(spot, chest)
	if effectId == "fx_fire" then
		-- a friendly pink-and-gold fire, all around
		local fire = Instance.new("Fire")
		fire.Color = Color3.fromRGB(255, 120, 60)
		fire.SecondaryColor = Color3.fromRGB(255, 80, 180)
		fire.Size = 6
		fire.Heat = 6
		fire.Parent = spot
	elseif effectId == "fx_smoke" then
		-- a puff of smoke for a big entrance, then it clears
		local smoke = Instance.new("Smoke")
		smoke.Color = Color3.fromRGB(220, 210, 255)
		smoke.Opacity = 0.35
		smoke.Size = 3
		smoke.RiseVelocity = 2
		smoke.Parent = spot
		task.delay(2.5, function()
			smoke.Enabled = false
		end)
	elseif effectId == "fx_rainbow" then
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0, 0.6, 0.3)
		a0.Parent = spot
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, -1.4, 0.3)
		a1.Parent = spot
		local trail = Instance.new("Trail")
		trail.Attachment0, trail.Attachment1 = a0, a1
		trail.Lifetime = 1.2
		trail.LightEmission = 0.5
		trail.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 120)),
			ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 200, 80)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(110, 220, 140)),
			ColorSequenceKeypoint.new(0.75, Color3.fromRGB(100, 160, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 110, 255)),
		})
		trail.Transparency = NumberSequence.new(0.1, 1)
		trail.Parent = spot
	else
		local def = EFFECTS[effectId]
		if not def then
			return
		end
		local e = Instance.new("ParticleEmitter")
		e.Texture = def.texture
		local keypoints = {}
		for i, c in def.colors do
			table.insert(keypoints, ColorSequenceKeypoint.new((i - 1) / math.max(#def.colors - 1, 1), c))
		end
		e.Color = ColorSequence.new(keypoints)
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, def.size), NumberSequenceKeypoint.new(1, def.size * 0.4) })
		e.Transparency = NumberSequence.new(def.transparency or 0, 1)
		e.Lifetime = NumberRange.new(1.2, 2)
		e.Rate = def.rate
		e.Speed = NumberRange.new(def.speed * 0.6, def.speed)
		e.SpreadAngle = Vector2.new(60, 60)
		e.LightEmission = 0.4
		e.EmissionDirection = if def.down then Enum.NormalId.Bottom else Enum.NormalId.Top
		if def.down then
			-- falls from above the head
			spot.CFrame = chest.CFrame * CFrame.new(0, 4, 0)
			e.Shape = Enum.ParticleEmitterShape.Box
			spot.Size = Vector3.new(4, 0.1, 4)
		end
		e.Parent = spot
	end
end

-- Plays a runway pose (an emote) once. Returns the track, or nil.
function Avatar.pose(model: Model, poseId: string?): AnimationTrack?
	local it = Catalog.byId[poseId or ""]
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not (it and it.anim and humanoid) then
		return nil
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	local anim = Instance.new("Animation")
	anim.AnimationId = it.anim
	local ok, track = pcall(function()
		return (animator :: Animator):LoadAnimation(anim)
	end)
	if ok and track then
		track.Priority = Enum.AnimationPriority.Action
		track:Play(0.2)
		return track
	end
	return nil
end

-- Accessories are built from simple shapes so they match the colors in the menus.
local function addAccessory(glam: Folder, head: BasePart, look)
	local it = Catalog.byId[look.accessory]
	if not it or Catalog.isNone(it.id) then
		return
	end
	if it.asset then
		addCostume(glam, head.Parent :: Model, it.id)
		return
	end
	local acc = it.draw or it.id
	local c = it.color or WHITE
	local gradient = it.gradient
	local hs = head.Size
	local styleItem = Catalog.byId[look.hairStyle or ""]
	local lift = HAIR_LIFT[look.hairStyle or ""] or (styleItem and styleItem.draw and HAIR_LIFT[styleItem.draw]) or 0.2
	local topY = hs.Y * 0.5 + lift
	local cf = head.CFrame
	local function p(name, size, offset: CFrame, color, shape, material)
		local x = part(glam, name, size, cf * offset, color, shape, material)
		attach(x, head)
		return x
	end
	local function band(radius: number, y: number, z: number, count: number, size: Vector3, color: Color3?)
		-- an arc over the top of the head, ear to ear
		for i = 0, count - 1 do
			local a = math.rad(-80 + 160 * i / (count - 1))
			local col = color or c
			if gradient then
				col = gradient[i % #gradient + 1]
			end
			p("Band", size, CFrame.new(math.sin(a) * radius, y + math.cos(a) * radius * 0.85, z) * CFrame.Angles(0, 0, -a), col)
		end
	end

	if acc == "acc_bow" then
		local at = CFrame.new(hs.X * 0.38, topY - 0.15, -0.15)
		p("BowL", Vector3.new(0.5, 0.36, 0.2), at * CFrame.new(-0.24, 0, 0) * CFrame.Angles(0, 0, math.rad(-18)), c, Enum.PartType.Ball)
		p("BowR", Vector3.new(0.5, 0.36, 0.2), at * CFrame.new(0.24, 0, 0) * CFrame.Angles(0, 0, math.rad(18)), c, Enum.PartType.Ball)
		p("BowKnot", Vector3.new(0.2, 0.2, 0.2), at, c:Lerp(Color3.new(0, 0, 0), 0.2), Enum.PartType.Ball)
	elseif acc == "acc_headband" then
		band(hs.X * 0.62 + lift * 0.3, hs.Y * 0.05, -0.1, 11, Vector3.new(0.22, 0.12, 0.3))
	elseif acc == "acc_flower" then
		local at = CFrame.new(hs.X * 0.45, topY - 0.25, -0.25)
		for i = 0, 4 do
			local a = i / 5 * math.pi * 2
			p("Petal", Vector3.new(0.22, 0.22, 0.12), at * CFrame.new(math.cos(a) * 0.17, math.sin(a) * 0.17, 0), c, Enum.PartType.Ball)
		end
		p("FlowerMiddle", Vector3.new(0.16, 0.16, 0.16), at * CFrame.new(0, 0, -0.04), Color3.fromRGB(255, 220, 80), Enum.PartType.Ball)
	elseif acc == "acc_earrings" then
		for side = -1, 1, 2 do
			for i = 0, 7 do
				local a = i / 8 * math.pi * 2
				p("Hoop", Vector3.new(0.07, 0.07, 0.07), CFrame.new(side * hs.X * 0.52, -hs.Y * 0.28 + math.sin(a) * 0.13, math.cos(a) * 0.13), c, Enum.PartType.Ball, Enum.Material.Metal)
			end
		end
	elseif acc == "acc_catears" then
		for side = -1, 1, 2 do
			local at = CFrame.new(side * hs.X * 0.3, topY + 0.05, 0) * CFrame.Angles(0, 0, math.rad(-side * 15))
			p("Ear", Vector3.new(0.12, 0.45, 0.4), at * CFrame.Angles(0, math.rad(90), 0), c, nil)
			p("EarInside", Vector3.new(0.13, 0.28, 0.24), at * CFrame.new(0, -0.04, -0.05) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(255, 160, 190))
		end
	elseif acc == "acc_crown" or acc == "acc_tiara" then
		local isCrown = acc == "acc_crown"
		local r = hs.X * (if isCrown then 0.32 else 0.5)
		local y = if isCrown then topY + 0.05 else topY - 0.15
		local count = if isCrown then 8 else 5
		for i = 0, count - 1 do
			local a = if isCrown then i / count * math.pi * 2 else math.rad(-60 + 120 * i / (count - 1))
			local tall = if isCrown or i == 2 then 0.4 else 0.24
			local at = CFrame.new(math.sin(a) * r, y + tall / 2, -math.cos(a) * r)
			p("Point", Vector3.new(0.12, tall, 0.12), at, c, nil, Enum.Material.Metal)
			p("Jewel", Vector3.new(0.12, 0.12, 0.12), at * CFrame.new(0, tall / 2 + 0.04, 0), if i % 2 == 0 then Color3.fromRGB(255, 120, 190) else Color3.fromRGB(140, 200, 255), Enum.PartType.Ball, Enum.Material.Neon)
		end
		if isCrown then
			p("CrownBand", Vector3.new(0.16, r * 2.1, r * 2.1), CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.rad(90)), c, Enum.PartType.Cylinder, Enum.Material.Metal)
		end
	elseif acc == "acc_halo" then
		local ring = p("Halo", Vector3.new(0.08, hs.X * 1.1, hs.X * 1.1), CFrame.new(0, topY + 0.45, 0) * CFrame.Angles(0, 0, math.rad(90)), c, Enum.PartType.Cylinder, Enum.Material.Neon)
		local light = Instance.new("PointLight")
		light.Color = c
		light.Range = 6
		light.Brightness = 1
		light.Parent = ring
		sparkles(ring, c, 5)
	elseif acc == "acc_witchhat" or acc == "acc_santahat" then
		local witch = acc == "acc_witchhat"
		local brim = if witch then c else WHITE
		p("Brim", Vector3.new(0.15, hs.X * (if witch then 1.9 else 1.3), hs.X * (if witch then 1.9 else 1.3)), CFrame.new(0, topY - 0.1, 0) * CFrame.Angles(0, 0, math.rad(90)), brim, Enum.PartType.Cylinder)
		local h, w = topY, hs.X * 0.95
		for i = 0, 3 do
			local s = w * (1 - i * 0.23)
			local bend = if witch then i * 0.06 else i * 0.12
			p("Cone", Vector3.new(0.38, s, s), CFrame.new(bend, h + 0.12 + i * 0.32, bend * 0.3) * CFrame.Angles(0, 0, math.rad(90 + i * (if witch then 4 else 10))), c, Enum.PartType.Cylinder)
		end
		if witch then
			p("HatBand", Vector3.new(0.14, w * 1.02, w * 1.02), CFrame.new(0, h + 0.05, 0) * CFrame.Angles(0, 0, math.rad(90)), it.accent or Color3.fromRGB(150, 80, 220), Enum.PartType.Cylinder)
		else
			p("Pompom", Vector3.new(0.35, 0.35, 0.35), CFrame.new(0.45, h + 1.35, 0.1), WHITE, Enum.PartType.Ball)
		end
	elseif acc == "acc_antlers" then
		for side = -1, 1, 2 do
			local base = CFrame.new(side * hs.X * 0.28, topY, 0) * CFrame.Angles(0, 0, math.rad(-side * 20))
			p("Antler", Vector3.new(0.12, 0.8, 0.12), base * CFrame.new(0, 0.4, 0), c)
			p("Antler", Vector3.new(0.1, 0.45, 0.1), base * CFrame.new(side * 0.15, 0.55, 0) * CFrame.Angles(0, 0, math.rad(-side * 50)), c)
			p("Antler", Vector3.new(0.1, 0.35, 0.1), base * CFrame.new(-side * 0.1, 0.65, 0) * CFrame.Angles(0, 0, math.rad(side * 35)), c)
		end
		p("RedNose", Vector3.new(0.22, 0.22, 0.22), CFrame.new(0, -hs.Y * 0.02, -hs.Z * 0.52), Color3.fromRGB(230, 30, 40), Enum.PartType.Ball, Enum.Material.Neon)
	elseif acc == "acc_earmuffs" then
		band(hs.X * 0.62 + lift * 0.3, hs.Y * 0.0, 0, 9, Vector3.new(0.18, 0.1, 0.18), it.accent or Color3.fromRGB(110, 170, 255))
		for side = -1, 1, 2 do
			p("Muff", Vector3.new(0.45, 0.55, 0.55), CFrame.new(side * hs.X * 0.55, -0.05, 0), c, Enum.PartType.Ball)
		end
	elseif acc == "acc_leafcrown" then
		local holder = p("LeafHolder", Vector3.new(0.1, 0.1, 0.1), CFrame.new(0, topY, 0), c)
		holder.Transparency = 1
		for i, leaf in { "🍂", "🍁", "🍂", "🍁", "🍂" } do
			local a = math.rad(-70 + 35 * (i - 1))
			emoji(holder, holder, leaf, Vector3.new(math.sin(a) * hs.X * 0.55, math.cos(a) * 0.2, -0.3), 0.55)
		end
	else
		-- A hair clip with a picture on it (🍀 🦄 🌈 🍓 🦋 🎃)
		local icon = it.icon or ({ acc_butterfly = "🦋", acc_pumpkin = "🎃" })[acc]
		if icon then
			local holder = p("Clip", Vector3.new(0.1, 0.1, 0.1), CFrame.new(hs.X * 0.45, topY - 0.25, -0.2), c)
			holder.Transparency = 1
			emoji(holder, holder, icon, Vector3.zero, 0.7)
		end
	end
end

-- A flared skirt made of panels around the hips.
local function addSkirt(glam: Folder, model: Model, color: Color3, accent: Color3, long: boolean, pattern: string?, patternColor: Color3, sparkly: boolean)
	local hips = model:FindFirstChild("LowerTorso") :: BasePart?
	if not hips then
		return
	end
	local count = 14
	local length = if long then 2.6 else 1.5
	local tilt = math.rad(if long then 16 else 22)
	local r0 = hips.Size.X * 0.48
	local topY = hips.Size.Y * 0.25
	local rm = r0 + math.sin(tilt) * length / 2
	local width = 2 * math.pi * rm / count * 1.12
	for i = 0, count - 1 do
		local base = hips.CFrame * CFrame.Angles(0, i / count * math.pi * 2, 0)
		local center = Vector3.new(0, topY - math.cos(tilt) * length / 2, -(r0 + math.sin(tilt) * length / 2))
		-- tipped outward at the bottom, so the skirt flares
		local panelCf = base * CFrame.new(center) * CFrame.Angles(tilt, 0, 0)
		local pleat = if i % 2 == 0 then color else color:Lerp(Color3.new(0, 0, 0), 0.08)
		local panel = part(glam, "Skirt", Vector3.new(width, length, 0.08), panelCf, pleat)
		attach(panel, hips)
		local hem = part(glam, "Hem", Vector3.new(width, 0.12, 0.1), panelCf * CFrame.new(0, -length / 2 + 0.06, -0.02), accent)
		attach(hem, hips)
		if pattern and i % 2 == 0 then
			local g = Instance.new("SurfaceGui")
			g.Face = Enum.NormalId.Front
			g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			g.PixelsPerStud = 60
			g.LightInfluence = 1
			local f = Instance.new("Frame")
			f.Size = UDim2.fromScale(1, 1)
			f.BackgroundTransparency = 1
			f.Parent = g
			LookRenderer.drawPattern(f, pattern, patternColor)
			g.Parent = panel
		end
		if sparkly and i % 4 == 0 then
			sparkles(panel, color, 3)
		end
	end
end

-- Dresses `model` in `look`. Safe to call again whenever the look changes.
-- options: clean / dirtHealth / mood / brushed / tangle, like LookRenderer.render.
function Avatar.dress(model: Model, client, look, options: LookRenderer.Options?)
	client = LookRenderer.withSkin(client, look)
	local old = model:FindFirstChild("Glam")
	if old then
		old:Destroy()
	end
	local glam = Instance.new("Folder")
	glam.Name = "Glam"
	local head = model:FindFirstChild("Head") :: BasePart?
	if not head then
		return
	end

	-- Body colors: outfit on the torso and upper arms, pants or bare legs under a dress
	local outfit = Catalog.byId[look.outfit]
	local custom = Catalog.byId[look.outfitColor or ""]
	local top = if custom and custom.color then custom.color else colorOf(outfit, Color3.fromRGB(110, 120, 135))
	local accent = if outfit and outfit.accent then outfit.accent else WHITE
	local dress = outfit ~= nil and outfit.dress == true
	local pants = if custom and custom.color then custom.color:Lerp(Color3.new(0, 0, 0), 0.3) else accent
	local skinParts = { Head = true, LeftLowerArm = true, RightLowerArm = true, LeftHand = true, RightHand = true }
	for _, p in model:GetChildren() do
		if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
			if skinParts[p.Name] then
				p.Color = client.skin
			elseif p.Name:find("Foot") then
				p.Color = if dress then accent else Color3.fromRGB(250, 250, 255)
			elseif p.Name:find("Leg") then
				p.Color = if dress then client.skin else pants
			else
				p.Color = top
			end
		end
	end
	local patternColor = accent
	if custom and custom.color then
		local _, _, v = custom.color:ToHSV()
		patternColor = if v > 0.8 then Color3.fromRGB(255, 120, 190) else WHITE
	end
	local chest = model:FindFirstChild("UpperTorso") :: BasePart?
	if chest then
		local oldPattern = chest:FindFirstChild("Pattern")
		if oldPattern then
			oldPattern:Destroy()
		end
		if look.outfitPattern and not Catalog.isNone(look.outfitPattern) then
			local g = Instance.new("SurfaceGui")
			g.Name = "Pattern"
			g.Face = Enum.NormalId.Front
			g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			g.PixelsPerStud = 60
			local f = Instance.new("Frame")
			f.Size = UDim2.fromScale(1, 1)
			f.BackgroundTransparency = 1
			f.Parent = g
			LookRenderer.drawPattern(f, look.outfitPattern, patternColor)
			g.Parent = chest
		end
		if outfit and outfit.sparkle then
			local spot = part(glam, "ShirtSparkle", Vector3.new(0.1, 0.1, 0.1), chest.CFrame, top)
			spot.Transparency = 1
			attach(spot, chest)
			sparkles(spot, top, 4)
		end
	end
	if dress then
		local long = outfit ~= nil and (outfit.name:find("Gown") ~= nil or outfit.name:find("Princess") ~= nil)
		addSkirt(glam, model, top, accent, long, look.outfitPattern, patternColor, outfit ~= nil and outfit.sparkle == true)
	end

	addHair(glam, head, look, options)
	addAccessory(glam, head, look)
	for _, key in { "costumeBack", "costumeFace", "costumeWaist", "costumeShoulder" } do
		addCostume(glam, model, look[key])
	end
	addEffect(glam, model, look.effect)
	glam.Parent = model
	Avatar.setFace(model, client, look, options)
end

-- Redraws just the face (makeup, dirt, mood): cheap enough to call while scrubbing.
function Avatar.setFace(model: Model, client, look, options: LookRenderer.Options?)
	local head = model:FindFirstChild("Head")
	local gui = head and head:FindFirstChild("GlamFace")
	local holder = gui and gui:FindFirstChild("Holder")
	if not holder then
		return
	end
	local faceOptions = table.clone(options or {})
	faceOptions.faceOnly = true
	LookRenderer.render(holder :: GuiObject, client, look, faceOptions)
	local portrait = holder:FindFirstChild("Portrait")
	if portrait and portrait:IsA("GuiObject") then
		portrait.ClipsDescendants = false
	end
end

-- Fades the messy-hair tufts while the stylist brushes (1 = fully tangled).
function Avatar.setTangle(model: Model, tangle: number)
	local glam = model:FindFirstChild("Glam")
	if glam then
		for _, t in glam:GetChildren() do
			if t.Name == "Tuft" and t:IsA("BasePart") then
				t.Transparency = 1 - tangle
			end
		end
	end
end

-- Gets a model out of its seat so it can walk again (a server-owned model also needs a nudge out of the Seated state).
function Avatar.unseat(model: Model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local seat = humanoid.SeatPart
	humanoid.Sit = false
	if seat then
		local weld = seat:FindFirstChild("SeatWeld")
		if weld then
			weld:Destroy()
		end
	end
	if humanoid:GetState() == Enum.HumanoidStateType.Seated then
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

-- Puts a client on the floor at `ground`, facing `facing` (a direction).
function Avatar.place(model: Model, ground: Vector3, facing: Vector3)
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local height = if humanoid then humanoid.HipHeight + root.Size.Y / 2 else 3
	local pos = ground + Vector3.new(0, height, 0)
	model:PivotTo(CFrame.lookAt(pos, pos + facing))
end

return Avatar
