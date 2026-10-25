-- Something to chase between rounds: glowing stars pop up around the rooftop during the lobby.
-- Run into one to grab it for a couple of coins (first one there gets it). They vanish when the
-- makeover starts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DataService = require(script.Parent.DataService)

local StarHunt = {}

local rng = Random.new()
local folder: Folder? = nil

-- Open floor where a star can sit: the plaza between the Dressing Hall and the runway, and the
-- front of the hall (clear of the stations, the runway and the podium).
local AREAS = {
	{ minX = -40, maxX = 40, minZ = 2, maxZ = 28 },
	{ minX = -34, maxX = 34, minZ = 31, maxZ = 49 },
}

local function spot(): Vector3
	local area = AREAS[rng:NextInteger(1, #AREAS)]
	return Vector3.new(rng:NextNumber(area.minX, area.maxX), 2.4, rng:NextNumber(area.minZ, area.maxZ))
end

function StarHunt.clear()
	if folder then
		folder:Destroy()
		folder = nil
	end
end

function StarHunt.spawn(parent: Instance)
	StarHunt.clear()
	local stars = Instance.new("Folder")
	stars.Name = "StarHunt"
	folder = stars
	for _ = 1, Config.HUNT_STARS do
		local position = spot()
		local star = Instance.new("Part")
		star.Name = "HuntStar"
		star.Shape = Enum.PartType.Ball
		star.Size = Vector3.new(1.6, 1.6, 1.6)
		star.Material = Enum.Material.Neon
		star.Color = Color3.fromRGB(255, 214, 80)
		star.Transparency = 0.25
		star.Anchored = true
		star.CanCollide = false
		star.CastShadow = false
		star.Position = position
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.fromScale(3.2, 3.2)
		billboard.LightInfluence = 0
		billboard.Parent = star
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = "⭐"
		label.TextScaled = true
		label.Parent = billboard
		local glitter = Instance.new("ParticleEmitter")
		glitter.Texture = Config.Textures.Star
		glitter.Color = ColorSequence.new(Color3.fromRGB(255, 240, 160))
		glitter.Size = NumberSequence.new(0.3, 0)
		glitter.Lifetime = NumberRange.new(0.6, 1)
		glitter.Speed = NumberRange.new(1, 2)
		glitter.SpreadAngle = Vector2.new(180, 180)
		glitter.Rate = 5
		glitter.LightEmission = 1
		glitter.Parent = star
		star.Parent = stars
		-- bob up and down so they catch the eye
		TweenService:Create(star, TweenInfo.new(0.9 + rng:NextNumber(0, 0.4), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
			Position = position + Vector3.new(0, 0.9, 0),
		}):Play()
		local taken = false
		star.Touched:Connect(function(hit)
			if taken then
				return
			end
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if not player then
				return
			end
			taken = true
			DataService.addCoins(player, Config.COINS_PER_HUNT_STAR)
			Remotes.Collected:FireClient(player, Config.COINS_PER_HUNT_STAR)
			star:Destroy()
		end)
	end
	stars.Parent = parent
end

return StarHunt
