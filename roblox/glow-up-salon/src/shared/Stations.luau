-- The Dressing Hall: walk up to a station and its menu opens. One list drives both the 3D world
-- (WorldBuilder builds a glowing pad, sign and props for each) and the menus (Makeover opens the
-- matching tab when you stand on a pad).

local Stations = {}

export type Station = {
	id: string,
	tab: string, -- the Makeover tab this station opens
	name: string,
	icon: string,
	pad: Vector3, -- center of the glowing pad on the floor
	facing: Vector3, -- the way you face while standing on it (the camera looks back at you)
	color: Color3,
}

local rgb = Color3.fromRGB

-- Five stations along the mirrors at the back of the salon, and the Pet Park by the door.
Stations.list = {
	{ id = "hair", tab = "Hair", name = "Hair Chair", icon = "💇", pad = Vector3.new(-26, 0.2, 55), facing = Vector3.new(0, 0, -1), color = rgb(255, 120, 190) },
	{ id = "face", tab = "Face", name = "Makeup Vanity", icon = "💄", pad = Vector3.new(-13, 0.2, 55), facing = Vector3.new(0, 0, -1), color = rgb(255, 90, 120) },
	{ id = "outfit", tab = "Outfit", name = "Wardrobe", icon = "👗", pad = Vector3.new(0, 0.2, 55), facing = Vector3.new(0, 0, -1), color = rgb(90, 160, 255) },
	{ id = "costume", tab = "Costume", name = "Costume Closet", icon = "🦸", pad = Vector3.new(13, 0.2, 55), facing = Vector3.new(0, 0, -1), color = rgb(150, 90, 220) },
	{ id = "show", tab = "Show", name = "Pose Stage", icon = "💃", pad = Vector3.new(26, 0.2, 55), facing = Vector3.new(0, 0, -1), color = rgb(245, 200, 70) },
	{ id = "pet", tab = "Pet", name = "Pet Park", icon = "🐶", pad = Vector3.new(24, 0.2, 39), facing = Vector3.new(-1, 0, 0), color = rgb(90, 200, 120) },
} :: { Station }

Stations.PAD_RADIUS = 4.5

Stations.byTab = {} :: { [string]: Station }
for _, s in Stations.list do
	Stations.byTab[s.tab] = s
end

-- The station whose pad this position is standing on, if any.
function Stations.at(position: Vector3): Station?
	for _, s in Stations.list do
		local d = Vector3.new(position.X - s.pad.X, 0, position.Z - s.pad.Z)
		if d.Magnitude <= Stations.PAD_RADIUS then
			return s
		end
	end
	return nil
end

return Stations
