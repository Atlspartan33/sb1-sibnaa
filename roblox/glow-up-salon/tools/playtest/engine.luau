-- A small fake Roblox engine for running the game's real scripts outside Studio.
-- Properties/events/enums are validated against Roblox's API dump.
local API = require("./api")

local E = {}
E.errors = {}
E.warnings = {}
E.logs = {}
E.NOW = 0
E.SCREEN = { 1280, 720 }
E.studio = true

local CUR = nil -- current context
E.contexts = {}

local function report(kind, msg)
	table.insert(kind == "error" and E.errors or E.warnings, msg)
	if kind == "error" then
		print("\27[31m[ERROR]\27[0m " .. msg)
	end
end

------------------------------------------------------------------------------
-- typeof
local realTypeof = typeof
local function typeof2(v)
	if type(v) == "table" then
		local mt = getmetatable(v)
		if type(mt) == "table" and rawget(mt, "__type") then
			return rawget(mt, "__type")
		end
	end
	return realTypeof(v)
end
E.typeof = typeof2

------------------------------------------------------------------------------
-- Datatypes
local function dt(name)
	local mt = { __type = name }
	return mt
end

-- Vector2
local V2 = dt("Vector2")
local Vector2 = {}
function Vector2.new(x, y)
	return setmetatable({ X = x or 0, Y = y or 0 }, V2)
end
V2.__index = function(v, k)
	if k == "Magnitude" then
		return math.sqrt(v.X * v.X + v.Y * v.Y)
	elseif k == "Unit" then
		local m = math.sqrt(v.X * v.X + v.Y * v.Y)
		return Vector2.new(v.X / m, v.Y / m)
	end
	error(tostring(k) .. " is not a valid member of Vector2", 2)
end
V2.__add = function(a, b) return Vector2.new(a.X + b.X, a.Y + b.Y) end
V2.__sub = function(a, b) return Vector2.new(a.X - b.X, a.Y - b.Y) end
V2.__mul = function(a, b)
	if type(a) == "number" then return Vector2.new(b.X * a, b.Y * a) end
	if type(b) == "number" then return Vector2.new(a.X * b, a.Y * b) end
	return Vector2.new(a.X * b.X, a.Y * b.Y)
end
V2.__div = function(a, b)
	if type(b) == "number" then return Vector2.new(a.X / b, a.Y / b) end
	return Vector2.new(a.X / b.X, a.Y / b.Y)
end
V2.__unm = function(a) return Vector2.new(-a.X, -a.Y) end
V2.__eq = function(a, b) return a.X == b.X and a.Y == b.Y end
V2.__tostring = function(a) return a.X .. ", " .. a.Y end
Vector2.zero = Vector2.new(0, 0)
Vector2.one = Vector2.new(1, 1)

-- Vector3
local V3 = dt("Vector3")
local Vector3 = {}
function Vector3.new(x, y, z)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, V3)
end
V3.__index = function(v, k)
	if k == "Magnitude" then
		return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
	elseif k == "Unit" then
		local m = math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
		return Vector3.new(v.X / m, v.Y / m, v.Z / m)
	elseif k == "Cross" then
		return function(a, b) return Vector3.new(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X) end
	elseif k == "Dot" then
		return function(a, b) return a.X * b.X + a.Y * b.Y + a.Z * b.Z end
	elseif k == "Lerp" then
		return function(a, b, t) return Vector3.new(a.X + (b.X - a.X) * t, a.Y + (b.Y - a.Y) * t, a.Z + (b.Z - a.Z) * t) end
	end
	error(tostring(k) .. " is not a valid member of Vector3", 2)
end
V3.__add = function(a, b) return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V3.__sub = function(a, b) return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
V3.__mul = function(a, b)
	if type(a) == "number" then return Vector3.new(b.X * a, b.Y * a, b.Z * a) end
	if type(b) == "number" then return Vector3.new(a.X * b, a.Y * b, a.Z * b) end
	return Vector3.new(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
V3.__div = function(a, b) return Vector3.new(a.X / b, a.Y / b, a.Z / b) end
V3.__unm = function(a) return Vector3.new(-a.X, -a.Y, -a.Z) end
V3.__eq = function(a, b) return a.X == b.X and a.Y == b.Y and a.Z == b.Z end
Vector3.zero = Vector3.new(0, 0, 0)
Vector3.one = Vector3.new(1, 1, 1)
Vector3.yAxis = Vector3.new(0, 1, 0)

-- UDim / UDim2
local UD = dt("UDim")
UD.__index = function(_, k) error(tostring(k) .. " is not a valid member of UDim", 2) end
local UDim = {}
function UDim.new(s, o) return setmetatable({ Scale = s or 0, Offset = o or 0 }, UD) end
UD.__add = function(a, b) return UDim.new(a.Scale + b.Scale, a.Offset + b.Offset) end
local U2 = dt("UDim2")
local UDim2 = {}
function UDim2.new(xs, xo, ys, yo)
	if type(xs) == "table" then
		return setmetatable({ X = xs, Y = xo }, U2)
	end
	return setmetatable({ X = UDim.new(xs, xo), Y = UDim.new(ys, yo) }, U2)
end
function UDim2.fromScale(x, y) return UDim2.new(x, 0, y, 0) end
function UDim2.fromOffset(x, y) return UDim2.new(0, x, 0, y) end
U2.__index = function(u, k)
	if k == "Width" then return u.X elseif k == "Height" then return u.Y end
	error(tostring(k) .. " is not a valid member of UDim2", 2)
end
U2.__add = function(a, b) return UDim2.new(a.X.Scale + b.X.Scale, a.X.Offset + b.X.Offset, a.Y.Scale + b.Y.Scale, a.Y.Offset + b.Y.Offset) end
U2.__eq = function(a, b) return a.X.Scale == b.X.Scale and a.X.Offset == b.X.Offset and a.Y.Scale == b.Y.Scale and a.Y.Offset == b.Y.Offset end

-- Color3
local C3 = dt("Color3")
local Color3 = {}
function Color3.new(r, g, b) return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, C3) end
function Color3.fromRGB(r, g, b) return Color3.new((r or 0) / 255, (g or 0) / 255, (b or 0) / 255) end
function Color3.fromHSV(h, s, v)
	local i = math.floor(h * 6)
	local f = h * 6 - i
	local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
	i = i % 6
	if i == 0 then return Color3.new(v, t, p) elseif i == 1 then return Color3.new(q, v, p) elseif i == 2 then return Color3.new(p, v, t)
	elseif i == 3 then return Color3.new(p, q, v) elseif i == 4 then return Color3.new(t, p, v) else return Color3.new(v, p, q) end
end
C3.__index = function(c, k)
	if k == "Lerp" then
		return function(a, b, t) return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t) end
	elseif k == "ToHSV" then
		return function(a)
			local mx, mn = math.max(a.R, a.G, a.B), math.min(a.R, a.G, a.B)
			local d = mx - mn
			local h = 0
			if d > 0 then
				if mx == a.R then h = ((a.G - a.B) / d) % 6 elseif mx == a.G then h = (a.B - a.R) / d + 2 else h = (a.R - a.G) / d + 4 end
				h = h / 6
			end
			return h, (mx == 0 and 0 or d / mx), mx
		end
	elseif k == "ToHex" then
		return function(a) return string.format("%02x%02x%02x", math.floor(a.R * 255 + 0.5), math.floor(a.G * 255 + 0.5), math.floor(a.B * 255 + 0.5)) end
	end
	error(tostring(k) .. " is not a valid member of Color3", 2)
end
C3.__eq = function(a, b) return a.R == b.R and a.G == b.G and a.B == b.B end

-- CFrame (position + 3x3 rotation, rows)
local CFm = dt("CFrame")
local CFrame = {}
local function cf(x, y, z, m)
	return setmetatable({ x = x, y = y, z = z, m = m }, CFm)
end
local I3 = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }
function CFrame.new(x, y, z)
	if type(x) == "table" then return cf(x.X, x.Y, x.Z, I3) end
	return cf(x or 0, y or 0, z or 0, I3)
end
local function mmul(a, b)
	local r = {}
	for i = 0, 2 do
		for j = 0, 2 do
			local s = 0
			for k = 0, 2 do s += a[i * 3 + k + 1] * b[k * 3 + j + 1] end
			r[i * 3 + j + 1] = s
		end
	end
	return r
end
function CFrame.Angles(rx, ry, rz)
	local cx, sx, cy, sy, cz, sz = math.cos(rx), math.sin(rx), math.cos(ry), math.sin(ry), math.cos(rz), math.sin(rz)
	local Rx = { 1, 0, 0, 0, cx, -sx, 0, sx, cx }
	local Ry = { cy, 0, sy, 0, 1, 0, -sy, 0, cy }
	local Rz = { cz, -sz, 0, sz, cz, 0, 0, 0, 1 }
	return cf(0, 0, 0, mmul(mmul(Rx, Ry), Rz))
end
CFrame.fromEulerAnglesXYZ = CFrame.Angles
function CFrame.lookAt(at, target, up)
	up = up or Vector3.new(0, 1, 0)
	local f = (target - at).Unit
	local r = f:Cross(up).Unit
	local u = r:Cross(f)
	-- columns: right, up, back(-forward)
	return cf(at.X, at.Y, at.Z, { r.X, u.X, -f.X, r.Y, u.Y, -f.Y, r.Z, u.Z, -f.Z })
end
local function cfApply(c, v)
	local m = c.m
	return Vector3.new(m[1] * v.X + m[2] * v.Y + m[3] * v.Z + c.x, m[4] * v.X + m[5] * v.Y + m[6] * v.Z + c.y, m[7] * v.X + m[8] * v.Y + m[9] * v.Z + c.z)
end
CFm.__mul = function(a, b)
	if typeof2(b) == "Vector3" then return cfApply(a, b) end
	local p = cfApply(a, Vector3.new(b.x, b.y, b.z))
	return cf(p.X, p.Y, p.Z, mmul(a.m, b.m))
end
CFm.__add = function(a, v) return cf(a.x + v.X, a.y + v.Y, a.z + v.Z, a.m) end
CFm.__index = function(c, k)
	if k == "Position" or k == "p" then return Vector3.new(c.x, c.y, c.z)
	elseif k == "X" then return c.x elseif k == "Y" then return c.y elseif k == "Z" then return c.z
	elseif k == "LookVector" then return Vector3.new(-c.m[3], -c.m[6], -c.m[9])
	elseif k == "RightVector" then return Vector3.new(c.m[1], c.m[4], c.m[7])
	elseif k == "UpVector" then return Vector3.new(c.m[2], c.m[5], c.m[8])
	elseif k == "Rotation" then return cf(0, 0, 0, c.m)
	elseif k == "Inverse" then
		return function(a)
			local m = a.m
			local t = { m[1], m[4], m[7], m[2], m[5], m[8], m[3], m[6], m[9] }
			local px = -(t[1] * a.x + t[2] * a.y + t[3] * a.z)
			local py = -(t[4] * a.x + t[5] * a.y + t[6] * a.z)
			local pz = -(t[7] * a.x + t[8] * a.y + t[9] * a.z)
			return cf(px, py, pz, t)
		end
	elseif k == "Lerp" then
		return function(a, b, t)
			local m = {}
			for i = 1, 9 do m[i] = a.m[i] + (b.m[i] - a.m[i]) * t end
			return cf(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, a.z + (b.z - a.z) * t, m)
		end
	end
	error(tostring(k) .. " is not a valid member of CFrame", 2)
end
CFrame.identity = CFrame.new()

-- Sequences etc
local function simple(name, fields)
	local mt = dt(name)
	mt.__index = function(_, k) error(tostring(k) .. " is not a valid member of " .. name, 2) end
	return function(...)
		local t = { ... }
		local o = {}
		for i, f in fields do o[f] = t[i] end
		return setmetatable(o, mt)
	end
end
local ColorSequenceKeypoint = { new = simple("ColorSequenceKeypoint", { "Time", "Value" }) }
local NumberSequenceKeypoint = { new = simple("NumberSequenceKeypoint", { "Time", "Value", "Envelope" }) }
local CSm = dt("ColorSequence")
local ColorSequence = {
	new = function(a, b)
		local kps
		if typeof2(a) == "Color3" then
			kps = { ColorSequenceKeypoint.new(0, a), ColorSequenceKeypoint.new(1, b or a) }
		else
			assert(type(a) == "table" and #a >= 2, "ColorSequence needs 2+ keypoints")
			kps = a
		end
		return setmetatable({ Keypoints = kps }, CSm)
	end,
}
local NSm = dt("NumberSequence")
local NumberSequence = {
	new = function(a, b)
		if type(a) == "number" then
			return setmetatable({ Keypoints = { NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(1, b or a) } }, NSm)
		end
		return setmetatable({ Keypoints = a }, NSm)
	end,
}
local NumberRange = { new = function(a, b) return setmetatable({ Min = a, Max = b or a }, dt("NumberRange")) end }
local TIm = dt("TweenInfo")
local TweenInfo = {
	new = function(t, style, dir, rep, rev, delay)
		return setmetatable({ Time = t or 1, EasingStyle = style, EasingDirection = dir, RepeatCount = rep or 0, Reverses = rev or false, DelayTime = delay or 0 }, TIm)
	end,
}

-- Random (deterministic)
local Rm = dt("Random")
Rm.__index = Rm
local Random = {}
local seedCounter = 12345
function Random.new(seed)
	seedCounter += 7919
	return setmetatable({ s = (seed or seedCounter) % 2147483647 + 1 }, Rm)
end
function Rm.NextNumber(self, a, b)
	self.s = (self.s * 16807) % 2147483647
	local r = self.s / 2147483647
	if a then return a + r * (b - a) end
	return r
end
function Rm.NextInteger(self, a, b)
	assert(a <= b, "NextInteger: min > max")
	return a + math.floor(self:NextNumber() * (b - a + 1))
end
function Rm.Shuffle(self, t)
	for i = #t, 2, -1 do
		local j = self:NextInteger(1, i)
		t[i], t[j] = t[j], t[i]
	end
end

------------------------------------------------------------------------------
-- Enums
local enumCache = {}
local EIm = { __type = "EnumItem" }
EIm.__tostring = function(e) return "Enum." .. e.EnumType .. "." .. e.Name end
local Enum = setmetatable({}, {
	__index = function(_, typeName)
		local items = API.enums[typeName]
		if not items then error("Enum." .. tostring(typeName) .. " does not exist", 2) end
		enumCache[typeName] = enumCache[typeName] or setmetatable({}, {
			__index = function(t, itemName)
				local v = items[itemName]
				if v == nil then error(tostring(itemName) .. " is not a valid member of Enum." .. typeName, 2) end
				local item = setmetatable({ Name = itemName, Value = v, EnumType = typeName }, EIm)
				rawset(t, itemName, item)
				return item
			end,
		})
		return enumCache[typeName]
	end,
})

------------------------------------------------------------------------------
-- Scheduler
local queue = {}
local seq = 0
local threadCtx = setmetatable({}, { __mode = "k" })
local cancelled = setmetatable({}, { __mode = "k" })

local function resume(co, ctx, ...)
	if cancelled[co] or coroutine.status(co) == "dead" or (ctx and ctx.dead) then return end
	local prev = CUR
	CUR = ctx
	threadCtx[co] = ctx
	local ok, err = coroutine.resume(co, ...)
	CUR = prev
	if not ok then
		report("error", "[" .. (ctx and ctx.name or "?") .. "] " .. tostring(err) .. "\n" .. debug.traceback(co))
	end
end
E.resume = resume

local function schedule(time, co, ctx, ...)
	seq += 1
	table.insert(queue, { time = time, seq = seq, co = co, ctx = ctx, args = table.pack(...) })
end

local task = {}
function task.spawn(f, ...)
	local co = if type(f) == "thread" then f else coroutine.create(f)
	resume(co, CUR, ...)
	return co
end
function task.defer(f, ...)
	local co = if type(f) == "thread" then f else coroutine.create(f)
	schedule(E.NOW, co, CUR, ...)
	return co
end
function task.delay(t, f, ...)
	local co = if type(f) == "thread" then f else coroutine.create(f)
	schedule(E.NOW + (t or 0), co, CUR, ...)
	return co
end
function task.wait(t)
	t = math.max(t or 0, 1 / 60)
	local co, isMain = coroutine.running()
	assert(not isMain, "task.wait called outside a game thread")
	local start = E.NOW
	schedule(E.NOW + t, co, CUR)
	coroutine.yield()
	return E.NOW - start
end
function task.cancel(co)
	cancelled[co] = true
end
E.task = task

local frameSignals = {}
function E.setFrameSignals(list) frameSignals = list end
function E.current() return CUR end
function E.runAs(ctx, fn, ...)
	local prev = CUR
	CUR = ctx
	local r = table.pack(pcall(fn, ...))
	CUR = prev
	if not r[1] then error(r[2], 0) end
	return table.unpack(r, 2, r.n)
end
function E.runFor(seconds)
	local target = E.NOW + seconds
	while E.NOW < target - 1e-9 do
		local stepEnd = math.min(target, E.NOW + 0.1)
		while true do
			table.sort(queue, function(a, b)
				if a.time == b.time then return a.seq < b.seq end
				return a.time < b.time
			end)
			local item = queue[1]
			if not item or item.time > stepEnd + 1e-9 then break end
			table.remove(queue, 1)
			E.NOW = math.max(E.NOW, item.time)
			resume(item.co, item.ctx, table.unpack(item.args, 1, item.args.n))
		end
		E.NOW = stepEnd
		for _, s in frameSignals do
			s:Fire(0.1)
		end
	end
end

------------------------------------------------------------------------------
-- Signals
local SigM = { __type = "RBXScriptSignal" }
SigM.__index = SigM
local function Signal(name)
	return setmetatable({ name = name, handlers = {}, waiters = {} }, SigM)
end
E.Signal = Signal
function SigM.Connect(self, fn)
	assert(type(fn) == "function", "Connect expects a function")
	local h = { fn = fn, ctx = CUR, connected = true }
	table.insert(self.handlers, h)
	if self.onConnect then self.onConnect(h) end
	local conn = setmetatable({}, { __type = "RBXScriptConnection", __index = function(_, k)
		if k == "Connected" then return h.connected end
		if k == "Disconnect" then return function() h.connected = false end end
		error(k .. " is not a valid member of RBXScriptConnection")
	end })
	return conn
end
function SigM.Once(self, fn)
	local conn
	conn = self:Connect(function(...)
		conn:Disconnect()
		fn(...)
	end)
	return conn
end
function SigM.Wait(self)
	local co = coroutine.running()
	table.insert(self.waiters, { co = co, ctx = CUR })
	return coroutine.yield()
end
function SigM.FireFilter(self, filter, ...)
	local list = table.clone(self.handlers)
	for _, h in list do
		if h.connected and (not filter or filter(h.ctx)) then
			local co = coroutine.create(h.fn)
			resume(co, h.ctx, ...)
		end
	end
	local waiters = self.waiters
	self.waiters = {}
	for _, w in waiters do
		if not filter or filter(w.ctx) then
			resume(w.co, w.ctx, ...)
		else
			table.insert(self.waiters, w)
		end
	end
end
function SigM.Fire(self, ...)
	self:FireFilter(nil, ...)
end
function SigM.hasHandlerFor(self, filter)
	for _, h in self.handlers do
		if h.connected and filter(h.ctx) then return true end
	end
	return false
end

------------------------------------------------------------------------------
-- Instances
local D = setmetatable({}, { __mode = "k" })
local IM = { __type = "Instance" }
E.D = D

local function classInfo(name)
	return API.classes[name]
end
local function isA(className, target)
	local c = className
	while c and c ~= "<<<ROOT>>>" do
		if c == target then return true end
		local info = classInfo(c)
		c = info and info.super
	end
	return false
end
E.isA = isA
local function findMember(className, kind, name)
	local c = className
	while c and c ~= "<<<ROOT>>>" do
		local info = classInfo(c)
		if not info then return nil end
		local v = info[kind][name]
		if v then return v, c end
		c = info.super
	end
	return nil
end

local DEFAULTS = {
	GuiObject = {
		Size = UDim2.new(0, 100, 0, 100), Position = UDim2.new(0, 0, 0, 0), AnchorPoint = Vector2.new(0, 0), BackgroundColor3 = Color3.fromRGB(163, 162, 165),
		BackgroundTransparency = 0, Visible = true, ZIndex = 1, LayoutOrder = 0, Rotation = 0, ClipsDescendants = false, BorderSizePixel = 1, Active = false,
	},
	TextLabel = { Text = "Label", TextColor3 = Color3.new(0, 0, 0), TextSize = 14, TextScaled = false, TextWrapped = false, TextTransparency = 0 },
	TextButton = { Text = "Button", TextColor3 = Color3.new(0, 0, 0), TextSize = 14, TextScaled = false, TextWrapped = false, TextTransparency = 0, AutoButtonColor = true },
	ScrollingFrame = { CanvasSize = UDim2.new(0, 0, 2, 0), ScrollBarThickness = 12 },
	LayerCollector = { Enabled = true, ResetOnSpawn = true },
	ScreenGui = { IgnoreGuiInset = false, DisplayOrder = 0 },
	SurfaceGui = { PixelsPerStud = 50, SizingMode = Enum.SurfaceGuiSizingMode.FixedSize },
	BillboardGui = { Size = UDim2.new(0, 0, 0, 0), StudsOffset = Vector3.new(0, 0, 0), AlwaysOnTop = false },
	UICorner = { CornerRadius = UDim.new(0, 8) },
	UIStroke = { Color = Color3.new(0, 0, 0), Thickness = 1, Transparency = 0, Enabled = true },
	UIPadding = { PaddingTop = UDim.new(0, 0), PaddingBottom = UDim.new(0, 0), PaddingLeft = UDim.new(0, 0), PaddingRight = UDim.new(0, 0) },
	UIListLayout = { Padding = UDim.new(0, 0), FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Left, VerticalAlignment = Enum.VerticalAlignment.Top, SortOrder = Enum.SortOrder.LayoutOrder },
	UIGridLayout = { CellSize = UDim2.new(0, 100, 0, 100), CellPadding = UDim2.new(0, 5, 0, 5), FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Left, VerticalAlignment = Enum.VerticalAlignment.Top, SortOrder = Enum.SortOrder.LayoutOrder },
	UIAspectRatioConstraint = { AspectRatio = 1, AspectType = Enum.AspectType.FitWithinMaxSize, DominantAxis = Enum.DominantAxis.Width },
	UISizeConstraint = { MinSize = Vector2.new(0, 0), MaxSize = Vector2.new(math.huge, math.huge) },
	UITextSizeConstraint = { MaxTextSize = 100, MinTextSize = 1 },
	UIGradient = { Rotation = 0, Offset = Vector2.new(0, 0), Enabled = true },
	UIScale = { Scale = 1 },
	BasePart = { Size = Vector3.new(4, 1, 2), CFrame = CFrame.new(), Color = Color3.fromRGB(163, 162, 165), Transparency = 0, Anchored = false, CanCollide = true, Material = Enum.Material.Plastic, Reflectance = 0 },
	Part = { Shape = Enum.PartType.Block },
	Humanoid = { HipHeight = 2, RigType = Enum.HumanoidRigType.R15, Health = 100 },
	Instance = {},
	DataModel = { JobId = "sim-server" },
	Camera = { CFrame = CFrame.new(), CameraType = Enum.CameraType.Custom, FieldOfView = 70 },
	Lighting = { ClockTime = 14 },
	ParticleEmitter = { Enabled = true },
}

local function defaultFor(className, prop)
	local c = className
	while c and c ~= "<<<ROOT>>>" do
		local t = DEFAULTS[c]
		if t and t[prop] ~= nil then return t[prop] end
		local info = classInfo(c)
		c = info and info.super
	end
	return nil
end

local CLASS_METHODS = {} -- className -> { name -> fn }
local DYNAMIC = {} -- className -> { prop -> getter }
E.CLASS_METHODS = CLASS_METHODS
E.DYNAMIC = DYNAMIC

local function findImpl(tbl, className, name)
	local c = className
	while c and c ~= "<<<ROOT>>>" do
		local t = tbl[c]
		if t and t[name] then return t[name] end
		local info = classInfo(c)
		c = info and info.super
	end
	return nil
end

local VALIDATE_DT = { Color3 = true, UDim2 = true, UDim = true, Vector2 = true, Vector3 = true, CFrame = true, ColorSequence = true, NumberSequence = true, NumberRange = true }

local function checkType(inst, prop, vt, v)
	local cat, name = vt[1], vt[2]
	local t = typeof2(v)
	local ok = true
	if cat == "Primitive" then
		if name == "bool" then ok = t == "boolean"
		elseif name == "string" then ok = t == "string" or t == "number"
		elseif name == "float" or name == "double" or name == "int" or name == "int64" then ok = t == "number"
		end
	elseif cat == "DataType" then
		if name == "Content" or name == "ContentId" then ok = t == "string"
		elseif VALIDATE_DT[name] then ok = t == name end
	elseif cat == "Enum" then
		ok = t == "EnumItem" and v.EnumType == name
	elseif cat == "Class" then
		ok = v == nil or (t == "Instance" and isA(D[v].class, name))
	end
	if not ok then
		error(string.format("Bad value for %s.%s: expected %s %s, got %s", D[inst].class, prop, cat, name, t), 3)
	end
end

local function new(className)
	local info = classInfo(className)
	if not info then error("Unable to create an Instance of type \"" .. tostring(className) .. "\"", 2) end
	local inst = setmetatable({}, IM)
	D[inst] = { class = className, props = { Name = className }, children = {}, parent = nil, signals = {}, attrs = {} }
	return inst
end
E.newInstance = new

local function setParent(inst, parent)
	local d = D[inst]
	if parent ~= nil and typeof2(parent) ~= "Instance" then error("Parent must be an Instance", 3) end
	if d.destroyed and parent ~= nil then error("The Parent property of " .. d.props.Name .. " is locked", 3) end
	local old = d.parent
	if old == parent then return end
	if old then
		local kids = D[old].children
		local i = table.find(kids, inst)
		if i then table.remove(kids, i) end
		local s = D[old].signals.ChildRemoved
		if s then s:Fire(inst) end
	end
	d.parent = parent
	if parent then
		table.insert(D[parent].children, inst)
		local s = D[parent].signals.ChildAdded
		if s then s:Fire(inst) end
		local p = parent
		while p do
			local ds = D[p].signals.DescendantAdded
			if ds then ds:Fire(inst) end
			p = D[p].parent
		end
	end
end

IM.__index = function(inst, k)
	local d = D[inst]
	if not d then error("not an instance") end
	local impl = findImpl(CLASS_METHODS, d.class, k)
	if impl then return impl end
	local dyn = findImpl(DYNAMIC, d.class, k)
	if dyn then return dyn(inst) end
	if k == "Parent" then return d.parent end
	if k == "ClassName" then return d.class end
	local vt = findMember(d.class, "props", k)
	if vt then
		local v = d.props[k]
		if v == nil then v = defaultFor(d.class, k) end
		return v
	end
	if findMember(d.class, "events", k) then
		d.signals[k] = d.signals[k] or Signal(k)
		return d.signals[k]
	end
	if findMember(d.class, "methods", k) then
		error("SIM: method " .. d.class .. ":" .. k .. " is not implemented in the simulator", 2)
	end
	for _, c in d.children do
		if D[c].props.Name == k then return c end
	end
	error(tostring(k) .. " is not a valid member of " .. d.class .. " \"" .. tostring(d.props.Name) .. "\"", 2)
end
IM.__newindex = function(inst, k, v)
	local d = D[inst]
	if k == "Parent" then
		setParent(inst, v)
		return
	end
	if API.callbacks[d.class .. "." .. k] then
		d.props[k] = v
		if d.onCallbackSet then d.onCallbackSet(k, v) end
		return
	end
	local vt = findMember(d.class, "props", k)
	if not vt then
		error(tostring(k) .. " is not a valid member of " .. d.class, 2)
	end
	checkType(inst, k, vt, v)
	d.props[k] = v
	local changed = d.signals["Changed:" .. k]
	if changed then changed:Fire() end
end
IM.__tostring = function(inst) return D[inst].props.Name end

local INST = {}
CLASS_METHODS.Instance = INST
function INST.FindFirstChild(self, name, recursive)
	for _, c in D[self].children do
		if D[c].props.Name == name then return c end
	end
	if recursive then
		for _, c in D[self].children do
			local f = c:FindFirstChild(name, true)
			if f then return f end
		end
	end
	return nil
end
function INST.FindFirstChildOfClass(self, cls)
	for _, c in D[self].children do
		if D[c].class == cls then return c end
	end
	return nil
end
function INST.FindFirstChildWhichIsA(self, cls)
	for _, c in D[self].children do
		if isA(D[c].class, cls) then return c end
	end
	return nil
end
function INST.WaitForChild(self, name, timeout)
	local c = self:FindFirstChild(name)
	if c then return c end
	local deadline = E.NOW + (timeout or 1e9)
	while E.NOW < deadline do
		task.wait(0.05)
		c = self:FindFirstChild(name)
		if c then return c end
	end
	if not timeout then report("warn", "Infinite yield on WaitForChild " .. name) end
	return nil
end
function INST.GetChildren(self) return table.clone(D[self].children) end
function INST.GetDescendants(self)
	local out = {}
	local function walk(i)
		for _, c in D[i].children do
			table.insert(out, c)
			walk(c)
		end
	end
	walk(self)
	return out
end
function INST.IsA(self, cls) return isA(D[self].class, cls) end
function INST.IsDescendantOf(self, other)
	local p = D[self].parent
	while p do
		if p == other then return true end
		p = D[p].parent
	end
	return false
end
function INST.Destroy(self)
	for _, c in table.clone(D[self].children) do c:Destroy() end
	setParent(self, nil)
	D[self].destroyed = true
end
function INST.ClearAllChildren(self)
	for _, c in table.clone(D[self].children) do c:Destroy() end
end
function INST.GetFullName(self)
	local parts = {}
	local i = self
	while i and D[i].class ~= "DataModel" do
		table.insert(parts, 1, D[i].props.Name)
		i = D[i].parent
	end
	return table.concat(parts, ".")
end
function INST.GetAttribute(self, k) return D[self].attrs[k] end
function INST.SetAttribute(self, k, v) D[self].attrs[k] = v end
function INST.GetPropertyChangedSignal(self, prop)
	local key = "Changed:" .. prop
	D[self].signals[key] = D[self].signals[key] or Signal(key)
	return D[self].signals[key]
end
function INST.Clone(self)
	local c = new(D[self].class)
	for k, v in D[self].props do D[c].props[k] = v end
	for _, ch in D[self].children do ch:Clone().Parent = c end
	return c
end

local Instance = {
	new = function(className, parent)
		local i = new(className)
		if parent then i.Parent = parent end
		return i
	end,
}

E.Vector2, E.Vector3, E.UDim, E.UDim2, E.Color3, E.CFrame = Vector2, Vector3, UDim, UDim2, Color3, CFrame
E.ColorSequence, E.ColorSequenceKeypoint, E.NumberSequence, E.NumberSequenceKeypoint, E.NumberRange, E.TweenInfo, E.Random, E.Enum, E.Instance =
	ColorSequence, ColorSequenceKeypoint, NumberSequence, NumberSequenceKeypoint, NumberRange, TweenInfo, Random, Enum, Instance

------------------------------------------------------------------------------
-- GUI layout (AbsolutePosition / AbsoluteSize)
local function childOfClass(inst, cls)
	for _, c in D[inst].children do
		if D[c].class == cls then return c end
	end
	return nil
end

local function insetY() return 58 end

local getRect
local function contentRect(p)
	local x, y, w, h = getRect(p)
	local pad = childOfClass(p, "UIPadding")
	if pad then
		local l, r, t, b = pad.PaddingLeft, pad.PaddingRight, pad.PaddingTop, pad.PaddingBottom
		local pl, pr, pt, pb = l.Scale * w + l.Offset, r.Scale * w + r.Offset, t.Scale * h + t.Offset, b.Scale * h + b.Offset
		x, y, w, h = x + pl, y + pt, math.max(0, w - pl - pr), math.max(0, h - pt - pb)
	end
	return x, y, w, h
end

local function constrain(inst, w, h)
	local sc = childOfClass(inst, "UISizeConstraint")
	if sc then
		w = math.clamp(w, sc.MinSize.X, math.max(sc.MinSize.X, sc.MaxSize.X))
		h = math.clamp(h, sc.MinSize.Y, math.max(sc.MinSize.Y, sc.MaxSize.Y))
	end
	local ar = childOfClass(inst, "UIAspectRatioConstraint")
	if ar then
		local r = ar.AspectRatio
		if h <= 0 or w / h > r then w = h * r else h = w / r end
	end
	return w, h
end

local function ownSize(inst, cw, ch)
	local s = inst.Size
	local w, h = s.X.Scale * cw + s.X.Offset, s.Y.Scale * ch + s.Y.Offset
	return constrain(inst, w, h)
end

local function layoutChildren(p, layout, cx, cy, cw, ch)
	local kids = {}
	for i, c in D[p].children do
		if isA(D[c].class, "GuiObject") and c.Visible then
			table.insert(kids, { c = c, i = i })
		end
	end
	table.sort(kids, function(a, b)
		local la, lb = a.c.LayoutOrder, b.c.LayoutOrder
		if la == lb then return a.i < b.i end
		return la < lb
	end)
	local res = {}
	if D[layout].class == "UIListLayout" then
		local horiz = layout.FillDirection == Enum.FillDirection.Horizontal
		local pad = layout.Padding.Scale * (horiz and cw or ch) + layout.Padding.Offset
		local sizes, total = {}, 0
		for k, e in kids do
			local w, h = ownSize(e.c, cw, ch)
			sizes[k] = { w, h }
			total += (horiz and w or h) + (k > 1 and pad or 0)
		end
		local mainAlign = horiz and layout.HorizontalAlignment.Name or layout.VerticalAlignment.Name
		local start = 0
		local avail = horiz and cw or ch
		if mainAlign == "Center" then start = (avail - total) / 2 elseif mainAlign == "Right" or mainAlign == "Bottom" then start = avail - total end
		local pos = start
		for k, e in kids do
			local w, h = sizes[k][1], sizes[k][2]
			local x, y
			if horiz then
				x = cx + pos
				local va = layout.VerticalAlignment.Name
				y = cy + (va == "Center" and (ch - h) / 2 or va == "Bottom" and (ch - h) or 0)
				pos += w + pad
			else
				y = cy + pos
				local ha = layout.HorizontalAlignment.Name
				x = cx + (ha == "Center" and (cw - w) / 2 or ha == "Right" and (cw - w) or 0)
				pos += h + pad
			end
			res[e.c] = { x, y, w, h }
		end
	else -- grid
		local cs, cp = layout.CellSize, layout.CellPadding
		local w, h = cs.X.Scale * cw + cs.X.Offset, cs.Y.Scale * ch + cs.Y.Offset
		w, h = constrain(layout, w, h)
		local px, py = cp.X.Scale * cw + cp.X.Offset, cp.Y.Scale * ch + cp.Y.Offset
		local perRow = math.max(1, math.floor((cw + px + 1e-6) / (w + px)))
		for k, e in kids do
			local col, row = (k - 1) % perRow, (k - 1) // perRow
			res[e.c] = { cx + col * (w + px), cy + row * (h + py), w, h }
		end
	end
	return res
end

local partFaceSize = function(part, face)
	local s = part.Size
	local n = face.Name
	if n == "Front" or n == "Back" then return s.X, s.Y
	elseif n == "Left" or n == "Right" then return s.Z, s.Y
	else return s.X, s.Z end
end

getRect = function(inst)
	local d = D[inst]
	local cls = d.class
	if cls == "ScreenGui" then
		if inst.IgnoreGuiInset then return 0, 0, E.SCREEN[1], E.SCREEN[2] end
		return 0, insetY(), E.SCREEN[1], E.SCREEN[2] - insetY()
	elseif cls == "SurfaceGui" then
		local part = inst.Adornee or d.parent
		if part and isA(D[part].class, "BasePart") then
			local w, h = partFaceSize(part, inst.Face)
			local pps = inst.PixelsPerStud
			return 0, 0, w * pps, h * pps
		end
		return 0, 0, 800, 600
	elseif cls == "BillboardGui" then
		local s = inst.Size
		return 0, 0, s.X.Scale * 60 + s.X.Offset, s.Y.Scale * 60 + s.Y.Offset
	end
	local p = d.parent
	if not p or not (isA(D[p].class, "GuiBase2d")) then return 0, 0, 0, 0 end
	local cx, cy, cw, ch = contentRect(p)
	local layout = childOfClass(p, "UIListLayout") or childOfClass(p, "UIGridLayout")
	if layout then
		local res = layoutChildren(p, layout, cx, cy, cw, ch)
		local r = res[inst]
		if r then return r[1], r[2], r[3], r[4] end
	end
	local w, h = ownSize(inst, cw, ch)
	local pos, ap = inst.Position, inst.AnchorPoint
	return cx + pos.X.Scale * cw + pos.X.Offset - ap.X * w, cy + pos.Y.Scale * ch + pos.Y.Offset - ap.Y * h, w, h
end
E.getRect = getRect
DYNAMIC.GuiBase2d = {
	AbsolutePosition = function(i) local x, y = getRect(i) return Vector2.new(x, y) end,
	AbsoluteSize = function(i) local _, _, w, h = getRect(i) return Vector2.new(w, h) end,
}

return E
