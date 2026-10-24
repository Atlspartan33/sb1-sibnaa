-- Starts the game on the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DataService = require(script.Parent.DataService)
local RoundService = require(script.Parent.RoundService)
local ShopService = require(script.Parent.ShopService)
local WorldBuilder = require(script.Parent.WorldBuilder)

local world = WorldBuilder.build()

DataService.init()
ShopService.init()
RoundService.init(world)

Remotes.Hello.OnServerInvoke = function(player: Player)
	local snapshot = RoundService.snapshot(player)
	DataService.push(player)
	return snapshot
end
