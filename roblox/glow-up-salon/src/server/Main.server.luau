-- Starts the game on the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Avatar = require(ReplicatedStorage.Shared.Avatar)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DataService = require(script.Parent.DataService)
local RoundService = require(script.Parent.RoundService)
local ShopService = require(script.Parent.ShopService)
local WorldBuilder = require(script.Parent.WorldBuilder)

local world = WorldBuilder.build()
task.spawn(Avatar.preload) -- the clients' bodies and hair, for the makeover, runway and podium

DataService.init()
ShopService.init()
RoundService.init(world)

Remotes.Hello.OnServerInvoke = function(player: Player)
	local snapshot = RoundService.snapshot(player)
	DataService.push(player)
	return snapshot
end
