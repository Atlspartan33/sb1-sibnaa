-- Plays the sounds and music listed in Config.Sounds (empty ones are skipped).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage.Shared.Config)

local Sounds = {}

local cache: { [string]: Sound } = {}
local music: Sound? = nil
local lastPlayed: { [string]: number } = {}

local function get(name: string): Sound?
	local id = Config.Sounds[name]
	if not id or id == "" then
		return nil
	end
	local sound = cache[name]
	if not sound then
		sound = Instance.new("Sound")
		sound.Name = name
		sound.SoundId = id
		sound.Volume = Config.SoundVolumes[name] or 0.6
		sound.Parent = SoundService
		cache[name] = sound
	end
	return sound
end

-- Plays a short sound effect. `gap` stops it from playing too often (e.g. while scrubbing).
function Sounds.play(name: string, gap: number?)
	local now = os.clock()
	if gap and lastPlayed[name] and now - lastPlayed[name] < gap then
		return
	end
	lastPlayed[name] = now
	local sound = get(name)
	if sound then
		SoundService:PlayLocalSound(sound)
	end
end

-- Starts looping background music (or stops it with nil).
function Sounds.music(name: string?)
	local sound = name and get(name)
	if sound == music then
		return
	end
	if music then
		music:Stop()
	end
	music = sound
	if sound then
		sound.Looped = true
		sound.Volume = 0.35
		sound:Play()
	end
end

return Sounds
