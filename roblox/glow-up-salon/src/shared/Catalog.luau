-- Everything a stylist can put on a client: hairstyles, colors, makeup, outfits and extras.
--
-- Item fields:
--   id      unique id (also what gets saved when a player unlocks it)
--   name    shown to players
--   price   coins to unlock (0 = free)
--   pass    "VIP" means it comes with the VIP Glam Kit Game Pass
--   hidden  starting items that can't be picked from the menu
--   color / accent / gradient / sparkle   how it's drawn
--   tags    used by the judges to check if a look matches the show's theme

local Catalog = {}

export type Item = {
	id: string,
	name: string,
	category: string,
	price: number,
	pass: string?,
	hidden: boolean?,
	color: Color3?,
	accent: Color3?,
	gradient: { Color3 }?,
	sparkle: boolean?,
	dress: boolean?, -- outfits that get a skirt on the runway
	tags: { string },
}

export type Category = {
	key: string,
	label: string,
	tab: string,
	preview: string, -- "portrait" (mini face preview) or "swatch" (color dot)
	items: { Item },
}

export type Theme = {
	id: string,
	name: string,
	tags: { string },
	color: Color3,
}

local rgb = Color3.fromRGB

local function item(def): Item
	def.price = def.price or 0
	def.tags = def.tags or {}
	return def :: Item
end

Catalog.Tabs = {
	{ id = "Wash", label = "Wash", icon = "🧼" },
	{ id = "Hair", label = "Hair", icon = "💇" },
	{ id = "Makeup", label = "Makeup", icon = "💄" },
	{ id = "Outfit", label = "Outfit", icon = "👗" },
	{ id = "Extras", label = "Extras", icon = "✨" },
}

Catalog.Categories = {
	{
		key = "hairStyle",
		label = "Hairstyle",
		tab = "Hair",
		preview = "portrait",
		items = {
			item({ id = "hair_messy", name = "Messy", hidden = true }),
			item({ id = "hair_long", name = "Long & Silky" }),
			item({ id = "hair_bob", name = "Cute Bob" }),
			item({ id = "hair_pixie", name = "Pixie Cut" }),
			item({ id = "hair_puff", name = "High Puff" }),
			item({ id = "hair_curls", name = "Big Curls" }),
			item({ id = "hair_pigtails", name = "Pigtails", price = 60 }),
			item({ id = "hair_buns", name = "Space Buns", price = 80 }),
			item({ id = "hair_braid", name = "Side Braid", price = 120 }),
			item({ id = "hair_updo", name = "Royal Updo", pass = "VIP", tags = { "sparkle" } }),
			item({ id = "hair_mermaid", name = "Mermaid Waves", pass = "VIP", tags = { "sparkle" } }),
		},
	},
	{
		key = "hairColor",
		label = "Hair Color",
		tab = "Hair",
		preview = "swatch",
		items = {
			item({ id = "hc_black", name = "Black", color = rgb(35, 30, 32), tags = { "dark" } }),
			item({ id = "hc_brown", name = "Brown", color = rgb(105, 66, 40) }),
			item({ id = "hc_blonde", name = "Blonde", color = rgb(240, 205, 120), tags = { "gold", "bright" } }),
			item({ id = "hc_ginger", name = "Ginger", color = rgb(200, 95, 45), tags = { "red", "bright" } }),
			item({ id = "hc_pink", name = "Bubblegum", color = rgb(255, 130, 190), price = 50, tags = { "pink", "pastel" } }),
			item({ id = "hc_blue", name = "Ocean Blue", color = rgb(70, 140, 235), price = 50, tags = { "blue" } }),
			item({ id = "hc_purple", name = "Grape", color = rgb(145, 80, 210), price = 50, tags = { "purple" } }),
			item({ id = "hc_mint", name = "Mint", color = rgb(120, 220, 180), price = 50, tags = { "green", "pastel" } }),
			item({ id = "hc_silver", name = "Silver", color = rgb(215, 220, 230), price = 75, tags = { "white" } }),
			item({
				id = "hc_rainbow",
				name = "Rainbow",
				pass = "VIP",
				color = rgb(255, 120, 160),
				gradient = { rgb(255, 90, 120), rgb(255, 200, 80), rgb(90, 210, 140), rgb(90, 150, 255), rgb(190, 110, 255) },
				tags = { "bright", "sparkle", "pink", "blue" },
			}),
			item({
				id = "hc_galaxy",
				name = "Galaxy",
				pass = "VIP",
				color = rgb(90, 60, 170),
				gradient = { rgb(40, 20, 90), rgb(120, 60, 200), rgb(240, 110, 200) },
				tags = { "purple", "blue", "sparkle", "dark" },
			}),
		},
	},
	{
		key = "eyeshadow",
		label = "Eyeshadow",
		tab = "Makeup",
		preview = "swatch",
		items = {
			item({ id = "es_none", name = "None" }),
			item({ id = "es_pink", name = "Pink", color = rgb(255, 150, 200), tags = { "pink", "pastel" } }),
			item({ id = "es_peach", name = "Peach", color = rgb(255, 180, 140), tags = { "pastel", "bright" } }),
			item({ id = "es_blue", name = "Sky Blue", color = rgb(110, 170, 255), tags = { "blue" } }),
			item({ id = "es_purple", name = "Lilac", color = rgb(170, 120, 230), tags = { "purple" } }),
			item({ id = "es_green", name = "Emerald", color = rgb(60, 180, 120), tags = { "green" } }),
			item({ id = "es_smoky", name = "Smoky", color = rgb(70, 60, 75), price = 40, tags = { "dark" } }),
			item({ id = "es_gold", name = "Gold Glitter", color = rgb(235, 190, 80), sparkle = true, price = 100, tags = { "gold", "sparkle" } }),
			item({ id = "es_ice", name = "Ice Glitter", color = rgb(200, 230, 255), sparkle = true, price = 100, tags = { "white", "blue", "sparkle" } }),
			item({
				id = "es_galaxy",
				name = "Galaxy Glitter",
				pass = "VIP",
				color = rgb(120, 70, 200),
				gradient = { rgb(60, 40, 160), rgb(200, 90, 220) },
				sparkle = true,
				tags = { "purple", "dark", "sparkle" },
			}),
		},
	},
	{
		key = "lashes",
		label = "Lashes",
		tab = "Makeup",
		preview = "portrait",
		items = {
			item({ id = "lash_none", name = "None" }),
			item({ id = "lash_natural", name = "Natural" }),
			item({ id = "lash_glam", name = "Glam Flick", price = 60 }),
			item({ id = "lash_star", name = "Starry Lashes", pass = "VIP", tags = { "sparkle", "gold" } }),
		},
	},
	{
		key = "blush",
		label = "Blush",
		tab = "Makeup",
		preview = "swatch",
		items = {
			item({ id = "bl_none", name = "None" }),
			item({ id = "bl_rosy", name = "Rosy", color = rgb(255, 120, 140), tags = { "pink" } }),
			item({ id = "bl_peach", name = "Peachy", color = rgb(255, 160, 120), tags = { "pastel", "bright" } }),
			item({ id = "bl_berry", name = "Berry", color = rgb(190, 60, 110), price = 30, tags = { "purple", "red" } }),
			item({ id = "bl_shimmer", name = "Shimmer", color = rgb(255, 170, 210), sparkle = true, price = 80, tags = { "pink", "sparkle" } }),
		},
	},
	{
		key = "lipstick",
		label = "Lipstick",
		tab = "Makeup",
		preview = "swatch",
		items = {
			item({ id = "lip_none", name = "None" }),
			item({ id = "lip_nude", name = "Nude", color = rgb(200, 130, 115) }),
			item({ id = "lip_pink", name = "Pink", color = rgb(250, 110, 170), tags = { "pink", "pastel" } }),
			item({ id = "lip_red", name = "Classic Red", color = rgb(210, 30, 50), tags = { "red" } }),
			item({ id = "lip_coral", name = "Coral", color = rgb(255, 120, 90), tags = { "bright" } }),
			item({ id = "lip_berry", name = "Berry", color = rgb(150, 40, 100), tags = { "purple", "red" } }),
			item({ id = "lip_black", name = "Midnight", color = rgb(40, 30, 45), price = 40, tags = { "dark" } }),
			item({ id = "lip_blue", name = "Mermaid Blue", color = rgb(60, 150, 220), price = 40, tags = { "blue", "green" } }),
			item({ id = "lip_gloss", name = "Pink Gloss", color = rgb(255, 150, 200), sparkle = true, price = 80, tags = { "pink", "pastel", "sparkle" } }),
			item({ id = "lip_gold", name = "Golden Glam", color = rgb(225, 175, 60), sparkle = true, pass = "VIP", tags = { "gold", "sparkle" } }),
		},
	},
	{
		key = "outfit",
		label = "Outfit",
		tab = "Outfit",
		preview = "portrait",
		items = {
			item({ id = "outfit_work", name = "Work Overalls", hidden = true, color = rgb(110, 120, 135), accent = rgb(80, 85, 95) }),
			item({ id = "outfit_tee", name = "Comfy Tee", color = rgb(245, 245, 250), accent = rgb(255, 150, 190), tags = { "white" } }),
			item({ id = "outfit_denim", name = "Denim Jacket", color = rgb(80, 120, 190), accent = rgb(230, 230, 240), tags = { "blue" } }),
			item({ id = "outfit_party", dress = true, name = "Pink Party Dress", color = rgb(255, 140, 195), accent = rgb(255, 230, 240), tags = { "pink", "pastel" } }),
			item({ id = "outfit_sunny", dress = true, name = "Sunny Sundress", color = rgb(255, 210, 70), accent = rgb(255, 255, 255), price = 60, tags = { "bright", "gold" } }),
			item({ id = "outfit_black", dress = true, name = "Little Black Dress", color = rgb(30, 28, 35), accent = rgb(200, 200, 210), price = 60, tags = { "dark" } }),
			item({ id = "outfit_rock", name = "Rockstar Jacket", color = rgb(110, 40, 160), accent = rgb(20, 20, 25), price = 100, tags = { "purple", "dark" } }),
			item({ id = "outfit_mermaid", name = "Mermaid Top", color = rgb(60, 190, 170), accent = rgb(120, 200, 255), sparkle = true, price = 100, tags = { "green", "blue", "sparkle" } }),
			item({ id = "outfit_red", dress = true, name = "Red Carpet Gown", color = rgb(200, 25, 45), accent = rgb(240, 200, 90), price = 120, tags = { "red", "gold" } }),
			item({ id = "outfit_snow", dress = true, name = "Snow Princess", color = rgb(200, 230, 255), accent = rgb(255, 255, 255), sparkle = true, price = 150, tags = { "white", "blue", "sparkle" } }),
			item({ id = "outfit_gold", dress = true, name = "Golden Gala Gown", color = rgb(230, 180, 60), accent = rgb(255, 240, 180), sparkle = true, pass = "VIP", tags = { "gold", "sparkle" } }),
			item({
				id = "outfit_galaxy", dress = true,
				name = "Galaxy Gown",
				pass = "VIP",
				color = rgb(70, 40, 150),
				accent = rgb(240, 120, 220),
				gradient = { rgb(30, 20, 80), rgb(110, 50, 190), rgb(230, 100, 200) },
				sparkle = true,
				tags = { "purple", "dark", "sparkle", "blue" },
			}),
		},
	},
	{
		key = "gems",
		label = "Face Art",
		tab = "Extras",
		preview = "portrait",
		items = {
			item({ id = "gem_none", name = "None" }),
			item({ id = "gem_freckles", name = "Freckles" }),
			item({ id = "gem_hearts", name = "Heart Stickers", price = 40, color = rgb(255, 80, 130), tags = { "pink", "red" } }),
			item({ id = "gem_stars", name = "Star Stickers", price = 40, color = rgb(255, 200, 60), tags = { "gold", "bright" } }),
			item({ id = "gem_rhinestones", name = "Rhinestones", pass = "VIP", color = rgb(220, 240, 255), tags = { "sparkle", "white" } }),
		},
	},
	{
		key = "accessory",
		label = "Accessory",
		tab = "Extras",
		preview = "portrait",
		items = {
			item({ id = "acc_none", name = "None" }),
			item({ id = "acc_bow", name = "Big Bow", color = rgb(255, 110, 170), tags = { "pink" } }),
			item({ id = "acc_headband", name = "Headband", color = rgb(90, 150, 255), tags = { "blue" } }),
			item({ id = "acc_flower", name = "Flower", color = rgb(255, 120, 90), tags = { "bright" } }),
			item({ id = "acc_earrings", name = "Gold Hoops", color = rgb(240, 195, 70), price = 50, tags = { "gold" } }),
			item({ id = "acc_catears", name = "Cat Ears", color = rgb(40, 35, 45), price = 80, tags = { "dark" } }),
			item({ id = "acc_crown", name = "Royal Crown", color = rgb(245, 200, 60), pass = "VIP", tags = { "gold", "sparkle" } }),
		},
	},
}

-- Fashion show themes. The judges reward looks whose tags match.
Catalog.Themes = {
	{ id = "pink_party", name = "Pink Party 🎀", tags = { "pink", "pastel", "sparkle" }, color = rgb(255, 130, 190) },
	{ id = "rock_star", name = "Rock Star 🎸", tags = { "dark", "red", "purple" }, color = rgb(120, 40, 160) },
	{ id = "under_sea", name = "Under the Sea 🐚", tags = { "blue", "green", "sparkle" }, color = rgb(50, 170, 200) },
	{ id = "royal_ball", name = "Royal Ball 👑", tags = { "gold", "purple", "sparkle" }, color = rgb(220, 170, 60) },
	{ id = "candy_land", name = "Candy Land 🍭", tags = { "pink", "pastel", "bright" }, color = rgb(255, 160, 210) },
	{ id = "spooky", name = "Spooky Glam 🦇", tags = { "dark", "purple", "green" }, color = rgb(90, 50, 130) },
	{ id = "beach", name = "Sunny Beach 🌴", tags = { "bright", "gold", "blue" }, color = rgb(255, 200, 70) },
	{ id = "winter", name = "Winter Wonderland ❄️", tags = { "white", "blue", "sparkle" }, color = rgb(150, 200, 255) },
	{ id = "red_carpet", name = "Red Carpet 🌟", tags = { "red", "gold", "dark" }, color = rgb(200, 30, 50) },
} :: { Theme }

-- Lookup tables -------------------------------------------------------------

Catalog.byId = {} :: { [string]: Item }
Catalog.categoryByKey = {} :: { [string]: Category }
Catalog.themeById = {} :: { [string]: Theme }

for _, category in Catalog.Categories do
	Catalog.categoryByKey[category.key] = category
	for _, it in category.items do
		it.category = category.key
		Catalog.byId[it.id] = it
	end
end

for _, theme in Catalog.Themes do
	Catalog.themeById[theme.id] = theme
end

-- What every client looks like when they walk in the door.
function Catalog.defaultLook(): { [string]: string }
	return {
		hairStyle = "hair_messy",
		hairColor = "hc_brown",
		eyeshadow = "es_none",
		lashes = "lash_none",
		blush = "bl_none",
		lipstick = "lip_none",
		outfit = "outfit_work",
		gems = "gem_none",
		accessory = "acc_none",
	}
end

-- Is this item usable by a player with this profile?
-- profile = { owned = { [itemId] = true }, passes = { VIP = true } }
function Catalog.isUnlocked(it: Item, profile): boolean
	if it.hidden then
		return false
	end
	if it.pass then
		return profile ~= nil and profile.passes ~= nil and profile.passes[it.pass] == true
	end
	if it.price <= 0 then
		return true
	end
	return profile ~= nil and profile.owned ~= nil and profile.owned[it.id] == true
end

function Catalog.hasTag(it: Item?, tag: string): boolean
	if not it then
		return false
	end
	for _, t in it.tags do
		if t == tag then
			return true
		end
	end
	return false
end

function Catalog.matchesTheme(it: Item?, theme: Theme): boolean
	if not it then
		return false
	end
	for _, tag in theme.tags do
		if Catalog.hasTag(it, tag) then
			return true
		end
	end
	return false
end

function Catalog.isNone(itemId: string?): boolean
	return itemId == nil or string.sub(itemId, -5) == "_none" or itemId == "hair_messy" or itemId == "outfit_work"
end

return Catalog
