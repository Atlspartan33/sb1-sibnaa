local E = require("./engine")
local W = require("./world")
local H = {}
H.fails = 0
function H.check(cond, msg)
	if cond then print("  PASS " .. msg) else H.fails += 1; print("\27[31m  FAIL " .. msg .. "\27[0m") end
end
function H.shown(i)
	while i do
		local cls = E.D[i].class
		if cls == "ScreenGui" then return i.Enabled end
		if E.isA(cls, "GuiObject") and not i.Visible then return false end
		i = i.Parent
	end
	return false
end
function H.ui(p) return p.PlayerGui:FindFirstChild("GlowUpUI") end
function H.findText(p, pattern, cls)
	for _, d in H.ui(p):GetDescendants() do
		local c = E.D[d].class
		if (c == "TextButton" or c == "TextLabel") and (not cls or c == cls) and H.shown(d) and string.find(d.Text, pattern, 1, true) then
			return d
		end
	end
	return nil
end
function H.button(p, pattern)
	return H.findText(p, pattern, "TextButton")
end
-- a card is a TextButton whose descendant label has this text
function H.card(p, name)
	for _, d in H.ui(p):GetDescendants() do
		if E.D[d].class == "TextLabel" and d.Text == name and H.shown(d) then
			local b = d.Parent
			while b and E.D[b].class ~= "TextButton" do b = b.Parent end
			if b then return b end
		end
	end
	return nil
end
function H.tab(p, id)
	for _, d in H.ui(p):GetDescendants() do
		if E.D[d].class == "TextButton" and d.Name == id and H.shown(d) then return d end
	end
	return nil
end
function H.click(b, label)
	if not b then H.check(false, "button exists: " .. tostring(label)); return end
	b.Activated:Fire(nil, 1)
	E.runFor(0.2)
end
function H.shot(p, name, w, h)
	print("@@SHOT " .. name .. " " .. W.dumpScreen(p, w or 1280, h or 720))
	E.SCREEN = { 1280, 720 }
end
local inset = 58
local function input(kind, pos)
	return { UserInputType = E.Enum.UserInputType[kind], Position = E.Vector3.new(pos.X, pos.Y - inset, 0), KeyCode = E.Enum.KeyCode.None }
end
function H.rub(ctx, center, radius, strokes)
	ctx.uis.InputBegan:Fire(input("MouseButton1", center), false)
	for i = 1, strokes or 12 do
		local a = i * 2.1
		local pos = center + E.Vector2.new(math.cos(a) * radius, math.sin(a) * radius)
		ctx.mouse = pos
		ctx.uis.InputChanged:Fire(input("MouseMovement", pos), false)
	end
	ctx.uis.InputEnded:Fire(input("MouseButton1", center), false)
	E.runFor(0.1)
end
function H.center(gui) return gui.AbsolutePosition + gui.AbsoluteSize / 2 end
return H
