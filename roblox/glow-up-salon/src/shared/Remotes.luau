-- All the messages the server and players send each other.
-- The server creates them; players wait for them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EVENTS = {
	"State", -- server -> all: round phase, timer, theme
	"AssignClient", -- server -> player: your new customer for this round
	"UpdateLook", -- player -> server: (lookKey, itemId)
	"WashProgress", -- player -> server: (clean 0..1, rinsed)
	"Done", -- player -> server: (isDone)
	"Showcase", -- server -> all: who is on the runway now
	"Vote", -- player -> server: (targetUserId, stars)
	"Results", -- server -> all: fashion show results
	"Profile", -- server -> player: coins, unlocked items, passes
	"Notify", -- server -> player: a little message
	"React", -- player -> server: cheer emoji during the fashion show
	"Reaction", -- server -> all: someone cheered (emoji)
	"Celebrate", -- server -> player: daily gift, level up
	"SetBots", -- player -> server: turn the Style Bots (pretend friends) on or off
}

local FUNCTIONS = {
	"Hello", -- player -> server: returns everything a newly joined player needs
	"BuyItem", -- player -> server: unlock an item with coins
}

local Remotes = {}

local folder: Instance
if RunService:IsServer() then
	folder = Instance.new("Folder")
	folder.Name = "Remotes"
	for _, name in EVENTS do
		local e = Instance.new("RemoteEvent")
		e.Name = name
		e.Parent = folder
	end
	for _, name in FUNCTIONS do
		local f = Instance.new("RemoteFunction")
		f.Name = name
		f.Parent = folder
	end
	folder.Parent = ReplicatedStorage
else
	folder = ReplicatedStorage:WaitForChild("Remotes")
end

for _, name in EVENTS do
	Remotes[name] = folder:WaitForChild(name) :: RemoteEvent
end
for _, name in FUNCTIONS do
	Remotes[name] = folder:WaitForChild(name) :: RemoteFunction
end

return Remotes
