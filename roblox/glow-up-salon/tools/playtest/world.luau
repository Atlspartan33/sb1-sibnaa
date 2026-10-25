-- Services, contexts (server + players), script loading and test helpers for the fake engine.
local E = require("./engine")
local D, M, DYN, task = E.D, E.CLASS_METHODS, E.DYNAMIC, E.task
local Vector2, Vector3, CFrame, Color3, Enum = E.Vector2, E.Vector3, E.CFrame, E.Color3, E.Enum
local new = E.newInstance

local W = {}
local SOURCES = setmetatable({}, { __mode = "k" })
W.SOURCES = SOURCES

local CURctx -- mirror: we access the engine's current context through a getter
local function cur()
	return E.current()
end

------------------------------------------------------------------------------
-- Contexts
local contexts = {}
W.contexts = contexts
local function newContext(name, isServer, player)
	local ctx = { name = name, isServer = isServer, player = player, modules = {}, uis = {}, mouse = Vector2.new(0, 0) }
	for _, ev in { "InputBegan", "InputChanged", "InputEnded" } do
		ctx.uis[ev] = E.Signal(ev)
	end
	table.insert(contexts, ctx)
	return ctx
end
W.newContext = newContext

------------------------------------------------------------------------------
-- DataModel & services
local game = new("DataModel")
D[game].props.Name = "Game"
W.game = game
local services = {}
local function getService(_, name)
	if services[name] then return services[name] end
	local info = E.isA(name, "Instance")
	assert(info, "no service " .. name)
	local s = new(name)
	D[s].props.Name = name
	s.Parent = game
	services[name] = s
	return s
end
M.DataModel = {
	GetService = getService,
	FindService = function(_, n) return services[n] end,
	BindToClose = function(_, fn) W.bindToClose = fn end,
	IsLoaded = function() return true end,
}
for _, n in { "Workspace", "ReplicatedStorage", "ServerScriptService", "StarterPlayer", "Players", "Lighting", "RunService", "TweenService", "UserInputService", "GuiService", "MarketplaceService", "DataStoreService" } do
	getService(game, n)
end
local Workspace, Players, ReplicatedStorage = services.Workspace, services.Players, services.ReplicatedStorage
local sps = new("StarterPlayerScripts")
sps.Parent = services.StarterPlayer
D[sps].props.Name = "StarterPlayerScripts"

-- Workspace / Camera
M.WorldRoot = {}
M.Workspace = {
	GetServerTimeNow = function() return 1000000 + E.NOW end,
}
DYN.Workspace = {
	CurrentCamera = function()
		local ctx = cur()
		if not ctx.camera then
			ctx.camera = new("Camera")
		end
		return ctx.camera
	end,
}

-- RunService
M.RunService = {
	IsServer = function() return cur().isServer end,
	IsClient = function() return not cur().isServer end,
	IsStudio = function() return E.studio end,
	IsRunning = function() return true end,
}
local frameSigs = {}
DYN.RunService = {}
for _, n in { "Heartbeat", "RenderStepped", "Stepped", "PreRender", "PostSimulation" } do
	local s = E.Signal(n)
	frameSigs[n] = s
	DYN.RunService[n] = function() return s end
end
E.setFrameSignals({ frameSigs.Heartbeat, frameSigs.RenderStepped, frameSigs.Stepped })
-- BindToRenderStep runs every frame like RenderStepped (priorities don't matter here)
local bound = {}
M.RunService.BindToRenderStep = function(_, name, _priority, fn)
	bound[name] = frameSigs.RenderStepped:Connect(fn)
end
M.RunService.UnbindFromRenderStep = function(_, name)
	if bound[name] then
		bound[name]:Disconnect()
		bound[name] = nil
	end
end

-- InsertService: avatar-shop items arrive as a model holding an accessory with a handle
W.assetsLoaded = 0
M.InsertService = {
	LoadAsset = function(_, id)
		assert(type(id) == "number", "LoadAsset needs a number")
		W.assetsLoaded += 1
		local model = new("Model")
		local acc = new("Accessory")
		acc.Name = "Asset" .. id
		local handle = new("MeshPart")
		handle.Name = "Handle"
		handle.Size = Vector3.new(1, 1, 1)
		local att = new("Attachment")
		att.Name = "HatAttachment"
		att.Parent = handle
		handle.Parent = acc
		acc.Parent = model
		return model
	end,
}

-- UserInputService (per player)
DYN.UserInputService = {
	InputBegan = function() return cur().uis.InputBegan end,
	InputChanged = function() return cur().uis.InputChanged end,
	InputEnded = function() return cur().uis.InputEnded end,
	TouchEnabled = function() return false end,
	KeyboardEnabled = function() return true end,
}
M.UserInputService = {
	GetMouseLocation = function() return cur().mouse end,
}
M.GuiService = {
	GetGuiInset = function() return Vector2.new(0, 58), Vector2.new(0, 0) end,
}

-- TweenService
local tweens = {}
W.tweens = tweens
M.TweenService = {
	Create = function(_, inst, info, goals)
		assert(E.typeof(inst) == "Instance", "Tween target must be an Instance")
		assert(E.typeof(info) == "TweenInfo", "TweenInfo expected")
		for k, v in goals do
			inst[k] = v -- validates now; real value applied on completion
		end
		local completed = E.Signal("Completed")
		local tw = {}
		tw.Completed = completed
		function tw.Play()
			task.delay(info.Time, function()
				if D[inst] and not D[inst].destroyed then
					for k, v in goals do inst[k] = v end
				end
				completed:Fire(Enum.PlaybackState.Completed)
			end)
		end
		function tw.Cancel() end
		function tw.Pause() end
		tweens[#tweens + 1] = tw
		return setmetatable(tw, { __index = function(_, k) return tw[k] end })
	end,
}

-- Players
W.nextUserId = 1000
M.Players = {
	GetPlayers = function(self)
		local out = {}
		for _, c in D[self].children do
			if D[c].class == "Player" then table.insert(out, c) end
		end
		return out
	end,
	GetPlayerByUserId = function(self, id)
		for _, c in D[self].children do
			if D[c].class == "Player" and c.UserId == id then return c end
		end
		return nil
	end,
	CreateHumanoidModelFromDescription = function(_, desc, rig)
		assert(E.typeof(desc) == "Instance" and desc:IsA("HumanoidDescription"), "desc must be HumanoidDescription")
		local model = new("Model")
		local root = new("Part")
		root.Name = "HumanoidRootPart"
		root.Size = Vector3.new(2, 2, 1)
		root.Transparency = 1
		root.Parent = model
		local function part(name, size, offset, color)
			local p = new("MeshPart")
			p.Name = name
			p.Size = size
			p.Color = color
			p.Parent = model
			D[p].rig = { root = root, offset = CFrame.new(offset.X, offset.Y, offset.Z) }
			return p
		end
		local head = part("Head", Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 1.9, 0), desc.HeadColor)
		local face = new("Decal")
		face.Name = "face"
		face.Parent = head
		part("UpperTorso", Vector3.new(2, 1.6, 1), Vector3.new(0, 0.4, 0), desc.TorsoColor)
		part("LowerTorso", Vector3.new(2, 0.4, 1), Vector3.new(0, -0.6, 0), desc.TorsoColor)
		part("LeftUpperArm", Vector3.new(1, 1.2, 1), Vector3.new(-1.5, 0.6, 0), desc.LeftArmColor)
		part("LeftLowerArm", Vector3.new(1, 1, 1), Vector3.new(-1.5, -0.5, 0), desc.LeftArmColor)
		part("RightUpperArm", Vector3.new(1, 1.2, 1), Vector3.new(1.5, 0.6, 0), desc.RightArmColor)
		part("RightLowerArm", Vector3.new(1, 1, 1), Vector3.new(1.5, -0.5, 0), desc.RightArmColor)
		part("LeftUpperLeg", Vector3.new(1, 1.2, 1), Vector3.new(-0.5, -1.4, 0), desc.LeftLegColor)
		part("LeftLowerLeg", Vector3.new(1, 0.9, 1), Vector3.new(-0.5, -2.45, 0), desc.LeftLegColor)
		part("RightUpperLeg", Vector3.new(1, 1.2, 1), Vector3.new(0.5, -1.4, 0), desc.RightLegColor)
		part("RightLowerLeg", Vector3.new(1, 0.9, 1), Vector3.new(0.5, -2.45, 0), desc.RightLegColor)
		local hum = new("Humanoid")
		hum.RigType = rig
		hum.Parent = model
		local animator = new("Animator")
		animator.Parent = hum
		model.PrimaryPart = root
		return model
	end,
}
DYN.Players = {
	LocalPlayer = function()
		local ctx = cur()
		return ctx.player
	end,
}
DYN.BasePart = {
	Position = function(p)
		local d = D[p]
		local c = d.props.CFrame or CFrame.new()
		if d.rig then c = d.rig.root.CFrame * d.rig.offset end
		return c.Position
	end,
}
W.soundsPlayed = {}
M.SoundService = {
	PlayLocalSound = function(_, sound) table.insert(W.soundsPlayed, sound.Name) end,
}
M.Sound = {
	Play = function(self) table.insert(W.soundsPlayed, self.Name) end,
	Stop = function() end,
}
M.Animator = {
	LoadAnimation = function(_, anim)
		assert(anim:IsA("Animation"), "LoadAnimation needs Animation")
		local t = new("AnimationTrack")
		return t
	end,
}
M.Humanoid = {
	LoadAnimation = M.Animator.LoadAnimation,
}
M.AnimationTrack = {
	Play = function() end,
	Stop = function() end,
	AdjustSpeed = function() end,
}
W.emitted = 0
M.ParticleEmitter = {
	Emit = function(_, n) W.emitted += n end,
	Clear = function() end,
}
M.Model = {
	GetPivot = function(self) return self.PrimaryPart.CFrame end,
	PivotTo = function(self, c) self.PrimaryPart.CFrame = c end,
}
M.BindableEvent = {
	Fire = function(self, ...) self.Event:Fire(...) end,
}

------------------------------------------------------------------------------
-- Remotes (with Roblox-like argument copying and validation)
local function copyArg(v, path, seen)
	local t = E.typeof(v)
	if t == "function" or t == "thread" then
		error("Cannot send a " .. t .. " over a remote (" .. path .. ")", 0)
	end
	if t ~= "table" then return v end
	seen = seen or {}
	if seen[v] then error("Cyclic table sent over remote at " .. path, 0) end
	seen[v] = true
	local hasNumber, hasString, n = false, false, 0
	for k in v do
		n += 1
		if type(k) == "number" then hasNumber = true elseif type(k) == "string" then hasString = true
		else error("Table key of type " .. type(k) .. " at " .. path .. " can't be sent", 0) end
	end
	if hasNumber and hasString then
		error("Mixed table (number + string keys) sent over remote at " .. path, 0)
	end
	if hasNumber and #v ~= n then
		error("Sparse array / non-sequential number keys at " .. path .. " (Roblox would drop data)", 0)
	end
	local out = {}
	for k, x in v do
		out[k] = copyArg(x, path .. "." .. tostring(k), seen)
	end
	seen[v] = nil
	return out
end
local function copyArgs(...)
	local args = table.pack(...)
	for i = 1, args.n do
		args[i] = copyArg(args[i], "arg" .. i)
	end
	return args
end
W.copyArg = copyArg

local function remoteSignal(inst, key, clientSide)
	local d = D[inst]
	if not d.signals[key] then
		local s = E.Signal(key)
		d.signals[key] = s
		d.pending = d.pending or {}
		if clientSide then
			s.onConnect = function(h)
				local ctx = h.ctx
				local queued = d.pending[ctx.player]
				if queued then
					d.pending[ctx.player] = nil
					for _, args in queued do
						task.defer(function()
							s:FireFilter(function(c) return c == ctx end, table.unpack(args, 1, args.n))
						end)
					end
				end
			end
		end
	end
	return d.signals[key]
end
DYN.RemoteEvent = {
	OnServerEvent = function(i) return remoteSignal(i, "OnServerEvent", false) end,
	OnClientEvent = function(i) return remoteSignal(i, "OnClientEvent", true) end,
}
W.remoteLog = {}
local function logRemote(dir, inst, args)
	table.insert(W.remoteLog, { dir = dir, name = D[inst].props.Name, n = args.n })
end
local function deliverToClient(inst, player, args)
	if not player.Parent then return end
	local s = remoteSignal(inst, "OnClientEvent", true)
	local function isTarget(c) return c.player == player and not c.dead end
	if s:hasHandlerFor(isTarget) then
		s:FireFilter(isTarget, table.unpack(args, 1, args.n))
	else
		local d = D[inst]
		d.pending[player] = d.pending[player] or {}
		table.insert(d.pending[player], args)
	end
end
M.RemoteEvent = {
	FireServer = function(self, ...)
		local ctx = cur()
		assert(not ctx.isServer, "FireServer called on the server")
		local args = copyArgs(...)
		logRemote("C->S", self, args)
		local player = ctx.player
		remoteSignal(self, "OnServerEvent", false):FireFilter(function(c) return c.isServer end, player, table.unpack(args, 1, args.n))
	end,
	FireClient = function(self, player, ...)
		assert(cur().isServer, "FireClient called on a client")
		assert(E.typeof(player) == "Instance" and player:IsA("Player"), "FireClient needs a Player")
		local args = copyArgs(...)
		logRemote("S->C", self, args)
		deliverToClient(self, player, args)
	end,
	FireAllClients = function(self, ...)
		assert(cur().isServer, "FireAllClients called on a client")
		local args = copyArgs(...)
		logRemote("S->all", self, args)
		for _, p in Players:GetPlayers() do
			deliverToClient(self, p, copyArgs(table.unpack(args, 1, args.n)))
		end
	end,
}
M.RemoteFunction = {
	InvokeServer = function(self, ...)
		local ctx = cur()
		assert(not ctx.isServer, "InvokeServer called on the server")
		local args = copyArgs(...)
		local fn = D[self].props.OnServerInvoke
		local waited = 0
		while not fn do
			task.wait(0.1)
			waited += 0.1
			fn = D[self].props.OnServerInvoke
			if waited > 30 then error("InvokeServer never answered: " .. D[self].props.Name) end
		end
		local results = table.pack(E.runAs(W.server, fn, ctx.player, table.unpack(args, 1, args.n)))
		for i = 1, results.n do
			results[i] = copyArg(results[i], "result" .. i)
		end
		return table.unpack(results, 1, results.n)
	end,
}

------------------------------------------------------------------------------
-- Marketplace & DataStores
W.ownedPasses = {}
W.prompts = {}
M.MarketplaceService = {
	UserOwnsGamePassAsync = function(_, userId, passId)
		assert(type(userId) == "number" and type(passId) == "number")
		return W.ownedPasses[userId .. ":" .. passId] == true
	end,
	PromptGamePassPurchase = function(_, player, id)
		assert(not cur().isServer or true)
		table.insert(W.prompts, { kind = "pass", player = player, id = id })
	end,
	PromptProductPurchase = function(_, player, id)
		table.insert(W.prompts, { kind = "product", player = player, id = id })
	end,
	GetProductInfo = function(_, id, infoType)
		return { PriceInRobux = 99, Name = "Item " .. id }
	end,
}
W.stores = {}
W.dataStoreFail = false
local function checkJson(v, path)
	local t = E.typeof(v)
	if t == "table" then
		for k, x in v do
			if type(k) ~= "string" and type(k) ~= "number" then error("DataStore: bad key at " .. path) end
			checkJson(x, path .. "." .. tostring(k))
		end
	elseif t ~= "string" and t ~= "number" and t ~= "boolean" and t ~= "nil" then
		error("DataStore can't save " .. t .. " at " .. path, 0)
	end
end
M.DataStoreService = {
	GetDataStore = function(_, name)
		local s = new("DataStore")
		D[s].props.Name = name
		W.stores[name] = W.stores[name] or {}
		D[s].data = W.stores[name]
		return s
	end,
}
M.DataStore = {
	GetAsync = function(self, key)
		task.wait(0.05)
		if W.dataStoreFail then error("DataStore request failed (simulated)") end
		local v = D[self].data[key]
		return v and copyArg(v, "load") or nil
	end,
	SetAsync = function(self, key, v)
		task.wait(0.05)
		if W.dataStoreFail then error("DataStore request failed (simulated)") end
		checkJson(v, key)
		D[self].data[key] = copyArg(v, "save")
	end,
	UpdateAsync = function(self, key, fn)
		task.wait(0.05)
		if W.dataStoreFail then error("DataStore request failed (simulated)") end
		local old = D[self].data[key]
		local v = fn(old and copyArg(old, "old") or nil)
		if v ~= nil then
			checkJson(v, key)
			D[self].data[key] = copyArg(v, "save")
		end
		return v
	end,
}
M.GlobalDataStore = M.DataStore

------------------------------------------------------------------------------
-- Script loading
local function makeEnv(ctx, scriptInst)
	local env = {}
	env.script = scriptInst
	env.game = game
	env.workspace = Workspace
	env.Workspace = Workspace
	env.task = task
	env.typeof = E.typeof
	env.Instance = E.Instance
	env.Enum = E.Enum
	env.Vector2, env.Vector3, env.UDim, env.UDim2, env.Color3, env.CFrame = E.Vector2, E.Vector3, E.UDim, E.UDim2, E.Color3, E.CFrame
	env.ColorSequence, env.ColorSequenceKeypoint, env.NumberSequence, env.NumberSequenceKeypoint = E.ColorSequence, E.ColorSequenceKeypoint, E.NumberSequence, E.NumberSequenceKeypoint
	env.NumberRange, env.TweenInfo, env.Random = E.NumberRange, E.TweenInfo, E.Random
	env.tick = function() return E.NOW end
	env.time = function() return E.NOW end
	env.os = setmetatable({ clock = function() return E.NOW end, time = function() return 1700000000 + math.floor(E.NOW) end }, { __index = os })
	env.print = function(...)
		local parts = {}
		for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
		table.insert(E.logs, "[" .. ctx.name .. "] " .. table.concat(parts, " "))
	end
	env.warn = function(...)
		local parts = {}
		for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
		local msg = "[" .. ctx.name .. "] " .. table.concat(parts, " ")
		table.insert(E.warnings, msg)
	end
	env.require = function(m)
		return W.require(ctx, m)
	end
	return setmetatable(env, { __index = _G })
end

function W.require(ctx, m)
	assert(E.typeof(m) == "Instance" and m:IsA("ModuleScript"), "require expects a ModuleScript")
	local cached = ctx.modules[m]
	if cached then
		if cached.loading then error("Recursive require of " .. m:GetFullName()) end
		return cached.value
	end
	local entry = { loading = true }
	ctx.modules[m] = entry
	local src = assert(SOURCES[m], "no source for " .. m:GetFullName())
	local fn, err = loadstring(src, "=" .. m:GetFullName())
	if not fn then error(err) end
	setfenv(fn, makeEnv(ctx, m))
	local value = fn()
	entry.loading = false
	entry.value = value
	return value
end

function W.runScript(ctx, scriptInst)
	local src = SOURCES[scriptInst]
	local fn, err = loadstring(src, "=" .. scriptInst:GetFullName())
	if not fn then error(err) end
	setfenv(fn, makeEnv(ctx, scriptInst))
	E.runAs(ctx, function()
		task.spawn(fn)
	end)
end

-- Builds the game tree from a list of { path = {...}, class = "...", source = "..." }
function W.loadProject(files)
	for _, f in files do
		local parent = game
		for i = 1, #f.path - 1 do
			local name = f.path[i]
			local child = parent:FindFirstChild(name)
			if not child then
				child = new("Folder")
				D[child].props.Name = name
				child.Parent = parent
			end
			parent = child
		end
		local inst = new(f.class)
		D[inst].props.Name = f.path[#f.path]
		SOURCES[inst] = f.source
		inst.Parent = parent
	end
end

local cloneOrig = M.Instance.Clone
M.Instance.Clone = function(self)
	local c = new(D[self].class)
	for k, v in D[self].props do D[c].props[k] = v end
	SOURCES[c] = SOURCES[self]
	for _, ch in D[self].children do ch:Clone().Parent = c end
	return c
end

------------------------------------------------------------------------------
-- Server + players
function W.startServer()
	local ctx = newContext("server", true, nil)
	W.server = ctx
	for _, s in services.ServerScriptService:GetDescendants() do
		if D[s].class == "Script" then
			W.runScript(ctx, s)
		end
	end
	return ctx
end

-- A simple R15 character standing on the salon spawn (players walk around the Dressing Hall)
local function spawnCharacter(p)
	local desc = new("HumanoidDescription")
	local skin = Color3.fromRGB(124, 78, 50)
	desc.HeadColor, desc.TorsoColor = skin, skin
	desc.LeftArmColor, desc.RightArmColor, desc.LeftLegColor, desc.RightLegColor = skin, skin, skin, skin
	local character = M.Players.CreateHumanoidModelFromDescription(nil, desc, Enum.HumanoidRigType.R15)
	character.Name = p.Name
	character.PrimaryPart.CFrame = CFrame.new(0, 3, 42)
	D[character].ownerPlayer = p
	character.Parent = W.game:GetService("Workspace")
	D[p].props.Character = character
	local s = D[p].signals.CharacterAdded
	if s then s:Fire(character) end
	return character
end
M.Player = {
	LoadCharacter = function(self)
		local old = D[self].props.Character
		if old then old:Destroy() end
		spawnCharacter(self)
	end,
}
M.Humanoid.GetAppliedDescription = function(self)
	local desc = new("HumanoidDescription")
	local head = self.Parent and self.Parent:FindFirstChild("Head")
	local skin = head and head.Color or Color3.fromRGB(124, 78, 50)
	desc.HeadColor, desc.TorsoColor = skin, skin
	desc.LeftArmColor, desc.RightArmColor, desc.LeftLegColor, desc.RightLegColor = skin, skin, skin, skin
	return desc
end
M.Humanoid.ApplyDescription = function(_, desc)
	assert(E.typeof(desc) == "Instance" and desc:IsA("HumanoidDescription"), "ApplyDescription needs a HumanoidDescription")
end
-- Walking is instant here: MoveTo puts the character on the spot
M.Humanoid.MoveTo = function(self, pos)
	local root = self.Parent and self.Parent:FindFirstChild("HumanoidRootPart")
	if root then
		root.CFrame = CFrame.new(pos.X, root.CFrame.Position.Y, pos.Z)
	end
	self.MoveToFinished:Fire(true)
end
M.Humanoid.Move = function() end
M.HumanoidDescription = {
	SetAccessories = function() end,
}
M.Seat = {
	Sit = function() end,
}

function W.addPlayer(name, userId)
	W.nextUserId += 1
	userId = userId or W.nextUserId
	local p = new("Player")
	D[p].props.Name = name
	D[p].props.UserId = userId
	D[p].props.DisplayName = name
	local pg = new("PlayerGui")
	D[pg].props.Name = "PlayerGui"
	pg.Parent = p
	local scripts = new("PlayerScripts")
	D[scripts].props.Name = "PlayerScripts"
	scripts.Parent = p
	E.runAs(W.server, function()
		p.Parent = Players
		Players.PlayerAdded:Fire(p)
		spawnCharacter(p)
	end)
	local ctx = newContext(name, false, p)
	for _, c in sps:GetChildren() do
		c:Clone().Parent = scripts
	end
	for _, s in scripts:GetDescendants() do
		if D[s].class == "LocalScript" then
			W.runScript(ctx, s)
		end
	end
	return p, ctx
end

function W.removePlayer(p)
	for _, c in contexts do
		if c.player == p then c.dead = true end
	end
	E.runAs(W.server, function()
		Players.PlayerRemoving:Fire(p)
		p.Parent = nil
	end)
end

------------------------------------------------------------------------------
-- JSON + dumps
local function json(v)
	local t = type(v)
	if t == "table" then
		if next(v) == nil then return "[]" end
		if #v > 0 then
			local parts = {}
			for _, x in v do table.insert(parts, json(x)) end
			return "[" .. table.concat(parts, ",") .. "]"
		end
		local parts = {}
		for k, x in v do table.insert(parts, string.format("%q", tostring(k)) .. ":" .. json(x)) end
		return "{" .. table.concat(parts, ",") .. "}"
	elseif t == "string" then
		return '"' .. v:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\t", " ") .. '"'
	elseif t == "number" then
		if v ~= v or v == math.huge or v == -math.huge then return "0" end
		return string.format("%.3f", v)
	elseif t == "boolean" then
		return tostring(v)
	end
	return "null"
end
W.json = json

local function hex(c) return "#" .. c:ToHex() end

local function dumpGui(inst, px, py)
	local d = D[inst]
	local out = {}
	for _, c in d.children do
		local cd = D[c]
		if E.isA(cd.class, "GuiObject") and c.Visible then
			local x, y, w, h = E.getRect(c)
			local node = {
				cls = cd.class, name = c.Name, x = x - px, y = y - py, w = w, h = h, z = c.ZIndex, rot = c.Rotation,
				bg = hex(c.BackgroundColor3), bt = c.BackgroundTransparency, clip = c.ClipsDescendants or cd.class == "ScrollingFrame",
			}
			for _, m in cd.children do
				local mc = D[m].class
				if mc == "UICorner" then
					node.radius = m.CornerRadius.Scale * math.min(w, h) + m.CornerRadius.Offset
				elseif mc == "UIStroke" and m.Enabled then
					node.stroke = { color = hex(m.Color), thick = m.Thickness, t = m.Transparency }
				elseif mc == "UIGradient" and m.Enabled then
					local cols = {}
					for _, kp in m.Color.Keypoints do table.insert(cols, { t = kp.Time, c = hex(kp.Value) }) end
					node.grad = { cols = cols, rot = m.Rotation }
				elseif mc == "UITextSizeConstraint" then
					node.maxText = m.MaxTextSize
				end
			end
			if cd.class == "TextLabel" or cd.class == "TextButton" then
				node.text = tostring(c.Text)
				node.tc = hex(c.TextColor3)
				node.tt = c.TextTransparency
				node.scaled = c.TextScaled
				node.size = c.TextSize
				node.xa = c.TextXAlignment and c.TextXAlignment.Name or "Center"
			end
			node.kids = dumpGui(c, x, y)
			table.insert(out, node)
		end
	end
	return out
end

function W.dumpScreen(player, w, h)
	E.SCREEN = { w, h }
	local guis = {}
	for _, g in player.PlayerGui:GetChildren() do
		if D[g].class == "ScreenGui" and g.Enabled then
			table.insert(guis, { name = g.Name, order = g.DisplayOrder, kids = dumpGui(g, 0, 0) })
		end
	end
	return json({ w = w, h = h, guis = guis })
end

function W.dumpSurface(gui)
	local _, _, w, h = E.getRect(gui)
	return json({ w = w, h = h, guis = { { name = gui.Name, order = 0, kids = dumpGui(gui, 0, 0) } } })
end

local function cfJson(c)
	return { c.x, c.y, c.z, c.m[1], c.m[2], c.m[3], c.m[4], c.m[5], c.m[6], c.m[7], c.m[8], c.m[9] }
end
function W.dumpWorld(cameraName)
	local parts, billboards = {}, {}
	for _, p in Workspace:GetDescendants() do
		local d = D[p]
		if E.isA(d.class, "BasePart") then
			local function worldCF(part)
				local pd = D[part]
				if pd.rig then return pd.rig.root.CFrame * pd.rig.offset end
				for _, ch in pd.children do
					if D[ch].class == "WeldConstraint" and ch.Part1 == part and ch.Part0 then
						return worldCF(ch.Part0) * (ch.Part0.CFrame:Inverse() * part.CFrame)
					end
				end
				return part.CFrame
			end
			local cframe = worldCF(p)
			local light
			for _, ch in d.children do
				local cc = D[ch].class
				if cc == "PointLight" or cc == "SpotLight" then light = { color = hex(ch.Color), range = ch.Range } end
			end
			table.insert(parts, {
				name = p.Name, cls = d.class, size = { p.Size.X, p.Size.Y, p.Size.Z }, cf = cfJson(cframe), color = hex(p.Color),
				t = p.Transparency, mat = p.Material.Name, light = light, refl = p.Reflectance,
				shape = (d.class == "Part" or d.class == "SpawnLocation" or d.class == "Seat") and p.Shape.Name or "Block",
			})
		elseif d.class == "BillboardGui" then
			local adornee = p.Adornee or d.parent
			local c = adornee.CFrame
			if D[adornee].rig then c = D[adornee].rig.root.CFrame * D[adornee].rig.offset end
			local off = p.StudsOffset
			table.insert(billboards, { pos = { c.x + off.X, c.y + off.Y, c.z + off.Z }, size = { p.Size.X.Scale, p.Size.Y.Scale }, gui = W.dumpSurface(p) })
		end
	end
	local surfaces = {}
	local function addSurface(g)
		local part = g.Adornee or D[g].parent
		if part and E.isA(D[part].class, "BasePart") and g.Enabled then
			table.insert(surfaces, { cf = cfJson(part.CFrame), size = { part.Size.X, part.Size.Y, part.Size.Z }, face = g.Face.Name, gui = W.dumpSurface(g) })
		end
	end
	for _, g in Workspace:GetDescendants() do
		if D[g].class == "SurfaceGui" then addSurface(g) end
	end
	if W.viewer then
		for _, g in W.viewer.PlayerGui:GetChildren() do
			if D[g].class == "SurfaceGui" then addSurface(g) end
		end
	end
	return { parts = parts, billboards = billboards, surfaces = surfaces }
end

return W
