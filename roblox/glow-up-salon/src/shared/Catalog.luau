-- Everything you can put on your avatar: hairstyles, makeup, outfits, costume pieces,
-- a pet to walk with, and a runway pose and effect.
--
-- Item fields:
--   id      unique id (also what gets saved when a player unlocks it)
--   name    shown to players
--   price   coins to unlock (0 = free)
--   pass    "VIP" means it comes with the VIP Glam Kit Game Pass
--   hidden  starting items that can't be picked from the menu
--   color / accent / gradient / sparkle   how it's drawn
--   tags    used by the judges to check if a look matches the show's theme

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Progress = require(ReplicatedStorage.Shared.Progress)

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
	event: string?, -- holiday event id: only available during that event (unless already unlocked)
	level: number?, -- unlocks for free at this stylist level
	gift: boolean?, -- only from the daily gift calendar
	draw: string?, -- draw it like another item (e.g. a gold bow uses "acc_bow")
	icon: string?, -- symbol for nail art, or the picture on a menu card
	asset: number?, -- an avatar-shop accessory (costume pieces) loaded when the game starts
	anim: string?, -- a runway pose's animation
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
	event: string?, -- only shows up during this holiday event
}

local rgb = Color3.fromRGB

local function item(def): Item
	def.price = def.price or 0
	def.tags = def.tags or {}
	return def :: Item
end

-- Nails and their items are kept for later, but have no tab (you can't see nails on the runway).
Catalog.Tabs = {
	{ id = "Hair", label = "Hair", icon = "💇" },
	{ id = "Face", label = "Face", icon = "💄" },
	{ id = "Outfit", label = "Outfit", icon = "👗" },
	{ id = "Costume", label = "Costume", icon = "🦸" },
	{ id = "Pet", label = "Pet", icon = "🐶" },
	{ id = "Show", label = "Show", icon = "💃" },
}

-- Skin tones, light to deep. There's no skin picker: everyone plays in their own avatar's skin.
-- These only help save a look (the Look Book stores the closest tone).
Catalog.SkinTones = {
	{ "Cream", rgb(255, 224, 196) },
	{ "Peach", rgb(250, 205, 175) },
	{ "Honey", rgb(241, 194, 160) },
	{ "Caramel", rgb(224, 172, 128) },
	{ "Bronze", rgb(198, 134, 94) },
	{ "Cocoa", rgb(161, 102, 66) },
	{ "Chestnut", rgb(124, 78, 50) },
	{ "Espresso", rgb(92, 57, 38) },
}

Catalog.Categories = {
	{
		key = "hairStyle",
		label = "Hairstyle",
		tab = "Hair",
		preview = "portrait",
		items = {
			item({ id = "hair_messy", asset = 12342908716, name = "Messy", hidden = true }),
			item({ id = "hair_long", asset = 15946668750, name = "Long & Silky" }),
			item({ id = "hair_bob", asset = 12794888069, name = "Cute Bob" }),
			item({ id = "hair_pixie", asset = 7323152045, name = "Pixie Cut" }),
			item({ id = "hair_puff", asset = 6203040671, name = "High Puff" }),
			item({ id = "hair_curls", asset = 117879284859863, name = "Big Curls" }),
			item({ id = "hair_pigtails", asset = 103016744198849, name = "Pigtails", price = 60 }),
			item({ id = "hair_buns", asset = 15951713439, name = "Space Buns", price = 80 }),
			item({ id = "hair_braid", asset = 115091588498903, name = "Side Braid", price = 120 }),
			item({ id = "hair_updo", asset = 78492501747860, name = "Royal Updo", pass = "VIP", tags = { "sparkle", "princess" } }),
			item({ id = "hair_mermaid", asset = 13353394855, name = "Mermaid Waves", pass = "VIP", tags = { "sparkle", "ocean" } }),
			item({ id = "hair_princess", asset = 18376297830, name = "Princess Curls", pass = "Princess", draw = "hair_curls", tags = { "sparkle", "princess" } }),
			-- Black hairstyles from the avatar shop (each borrows a similar drawing for the little faces)
			item({ id = "hair_boxbraids", asset = 8828670109, name = "Box Braids", draw = "hair_long", tags = { "dark" } }),
			item({ id = "hair_longbraids", asset = 5132599285, name = "Long Braids", draw = "hair_long", tags = {  } }),
			item({ id = "hair_braidbuns", asset = 5132605131, name = "Braids + Buns", draw = "hair_buns", tags = { "party" } }),
			item({ id = "hair_knotless", asset = 112586356873829, name = "Knotless Braids", draw = "hair_long", price = 40, tags = { "fairy" } }),
			item({ id = "hair_goddess", asset = 11708540153, name = "Goddess Braids", draw = "hair_mermaid", price = 60, tags = { "princess" } }),
			item({ id = "hair_beadedbraids", asset = 77702057442605, name = "Beaded Braids", draw = "hair_long", tags = { "bright" } }),
			item({ id = "hair_cornrows", asset = 15475827398, name = "Cornrow Braids", draw = "hair_braid", tags = { "superhero" } }),
			item({ id = "hair_heartrows", asset = 117064685486156, name = "Heart Cornrows", draw = "hair_braid", price = 40, tags = { "pink" } }),
			item({ id = "hair_fulani", asset = 117962258187267, name = "Fulani Braids", draw = "hair_long", price = 40, tags = {  } }),
			item({ id = "hair_braidbob", asset = 113958214135872, name = "Braid Bob", draw = "hair_bob", tags = {  } }),
			item({ id = "hair_twists", asset = 11506622360, name = "Twists", draw = "hair_curls", tags = {  } }),
			item({ id = "hair_twistout", asset = 15774206246, name = "Twist Out", draw = "hair_curls", price = 40, tags = {  } }),
			item({ id = "hair_shortlocs", asset = 11341159679, name = "Short Locs", draw = "hair_pixie", tags = {  } }),
			item({ id = "hair_longlocs", asset = 13514851277, name = "Long Locs", draw = "hair_long", price = 40, tags = { "rockstar" } }),
			item({ id = "hair_playlocs", asset = 13908388320, name = "Playful Locs", draw = "hair_bob", tags = { "rockstar" } }),
			item({ id = "hair_beadedlocs", asset = 7184385830, name = "Beaded Locs", draw = "hair_long", price = 60, tags = { "ocean" } }),
			item({ id = "hair_locbuns", asset = 92054620932635, name = "Loc Buns", draw = "hair_buns", price = 40, tags = {  } }),
			item({ id = "hair_bantu", asset = 94192611966704, name = "Bantu Knots", draw = "hair_buns", tags = {  } }),
			item({ id = "hair_halfknots", asset = 18247698974, name = "Half-Up Knots", draw = "hair_buns", price = 40, tags = {  } }),
			item({ id = "hair_miniafro", asset = 6905430450, name = "Mini Afro", draw = "hair_curls", tags = {  } }),
			item({ id = "hair_sideafro", asset = 6471990109, name = "Side Part Afro", draw = "hair_curls", tags = { "animal" } }),
			item({ id = "hair_bigafro", asset = 16179369065, name = "Big Afro", draw = "hair_curls", tags = { "rockstar", "party" } }),
			item({ id = "hair_onepuff", asset = 86812348209728, name = "One Puff", draw = "hair_puff", tags = {  } }),
			item({ id = "hair_twopuffs", asset = 8705233070, name = "Two Puffs", draw = "hair_pigtails", tags = { "animal" } }),
			item({ id = "hair_coils", asset = 122559201360323, name = "Short Coils", draw = "hair_pixie", tags = {  } }),
			item({ id = "hair_fluffy", asset = 15069727041, name = "Fluffy Curls", draw = "hair_curls", price = 40, tags = {  } }),
			item({ id = "hair_bouncy", asset = 18757370852, name = "Bouncy Curls", draw = "hair_curls", price = 40, tags = {  } }),
			item({ id = "hair_silkpress", asset = 15960674286, name = "Silk Press", draw = "hair_long", tags = { "princess" } }),
			item({ id = "hair_silkbangs", asset = 119865951138422, name = "Silk Press Bangs", draw = "hair_long", price = 40, tags = {  } }),
			item({ id = "hair_curlybuns", asset = 96572495518172, name = "Curly Space Buns", draw = "hair_buns", price = 40, tags = { "space" } }),
			item({ id = "hair_sleekpony", asset = 113300721819171, name = "Sleek Pony", draw = "hair_puff", price = 40, tags = { "superhero" } }),
			item({ id = "hair_braidpony", asset = 5318621744, name = "Braided Pony", draw = "hair_puff", tags = { "pirate" } }),
			item({ id = "hair_braidbun", asset = 136697234614741, name = "Braided Bun", draw = "hair_updo", price = 60, tags = { "princess" } }),
		},
	},
	{
		key = "hairColor",
		label = "Hair Color",
		tab = "Hair",
		preview = "swatch",
		items = {
			item({ id = "hc_black", name = "Black", color = rgb(35, 30, 32), tags = { "dark" } }),
			item({ id = "hc_brown", name = "Brown", color = rgb(105, 66, 40) }), -- no tags: it's the starting color
			item({ id = "hc_blonde", name = "Blonde", color = rgb(240, 205, 120), tags = { "gold", "bright" } }),
			item({ id = "hc_strawberry", name = "Strawberry", color = rgb(250, 160, 170), tags = { "pink", "pastel" } }),
			item({ id = "hc_teal", name = "Teal", color = rgb(60, 170, 180), tags = { "blue", "green", "ocean" } }),
			item({ id = "hc_ginger", name = "Ginger", color = rgb(200, 95, 45), tags = { "red", "bright", "orange" } }),
			item({ id = "hc_pink", name = "Bubblegum", color = rgb(255, 130, 190), price = 50, tags = { "pink", "pastel" } }),
			item({ id = "hc_blue", name = "Ocean Blue", color = rgb(70, 140, 235), price = 50, tags = { "blue" } }),
			item({ id = "hc_purple", name = "Grape", color = rgb(145, 80, 210), price = 50, tags = { "purple" } }),
			item({ id = "hc_mint", name = "Mint", color = rgb(120, 220, 180), price = 50, tags = { "green", "pastel", "fairy" } }),
			item({ id = "hc_silver", name = "Silver", color = rgb(215, 220, 230), price = 75, tags = { "white", "space", "winter" } }),
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
				tags = { "purple", "blue", "sparkle", "dark", "space" },
			}),
			item({ id = "hc_cottoncandy", name = "Cotton Candy", level = 3, color = rgb(255, 170, 220), gradient = { rgb(255, 160, 215), rgb(170, 210, 255) }, tags = { "pink", "pastel", "blue" } }),
			item({
				id = "hc_unicorn",
				name = "Unicorn",
				level = 15,
				color = rgb(230, 170, 255),
				gradient = { rgb(255, 170, 220), rgb(200, 160, 255), rgb(150, 210, 255), rgb(160, 240, 200) },
				tags = { "pastel", "pink", "purple", "sparkle", "fairy", "princess" },
			}),
			item({ id = "hc_rosegold", name = "Rose Gold", pass = "Princess", color = rgb(240, 170, 150), gradient = { rgb(250, 200, 170), rgb(230, 140, 150) }, tags = { "pink", "gold", "sparkle" } }),
			-- Holiday colors
			item({ id = "hc_pumpkin", name = "Pumpkin", color = rgb(245, 130, 30), price = 40, event = "halloween", tags = { "orange", "bright" } }),
			item({ id = "hc_witch", name = "Witchy Purple", color = rgb(90, 40, 140), price = 40, event = "halloween", tags = { "purple", "dark" } }),
			item({ id = "hc_maple", name = "Maple Red", color = rgb(160, 50, 30), price = 40, event = "thanksgiving", tags = { "red", "brown", "orange" } }),
			item({ id = "hc_frost", name = "Frosty", color = rgb(220, 240, 255), price = 60, event = "christmas", tags = { "white", "blue", "sparkle" } }),
			item({
				id = "hc_candycane",
				name = "Candy Cane",
				pass = "VIP",
				event = "christmas",
				color = rgb(230, 40, 60),
				gradient = { rgb(230, 40, 60), rgb(255, 255, 255), rgb(230, 40, 60), rgb(255, 255, 255) },
				tags = { "red", "white", "sparkle" },
			}),
		},
	},
	{
		key = "eyeshadow",
		label = "Eyeshadow",
		tab = "Face",
		preview = "swatch",
		items = {
			item({ id = "es_none", name = "None" }),
			item({ id = "es_pink", name = "Pink", color = rgb(255, 150, 200), tags = { "pink", "pastel" } }),
			item({ id = "es_peach", name = "Peach", color = rgb(255, 180, 140), tags = { "pastel", "bright", "orange" } }),
			item({ id = "es_ruby", name = "Ruby", color = rgb(200, 40, 70), tags = { "red" } }),
			item({ id = "es_bronze", name = "Bronze", color = rgb(180, 120, 70), tags = { "gold", "brown" } }),
			item({ id = "es_blue", name = "Sky Blue", color = rgb(110, 170, 255), tags = { "blue" } }),
			item({ id = "es_purple", name = "Lilac", color = rgb(170, 120, 230), tags = { "purple" } }),
			item({ id = "es_green", name = "Emerald", color = rgb(60, 180, 120), tags = { "green", "dino", "fairy" } }),
			item({ id = "es_smoky", name = "Smoky", color = rgb(70, 60, 75), price = 40, tags = { "dark", "rockstar" } }),
			item({ id = "es_gold", name = "Gold Glitter", color = rgb(235, 190, 80), sparkle = true, price = 100, tags = { "gold", "sparkle" } }),
			item({ id = "es_ice", name = "Ice Glitter", color = rgb(200, 230, 255), sparkle = true, price = 100, tags = { "white", "blue", "sparkle" } }),
			item({
				id = "es_galaxy",
				name = "Galaxy Glitter",
				pass = "VIP",
				color = rgb(120, 70, 200),
				gradient = { rgb(60, 40, 160), rgb(200, 90, 220) },
				sparkle = true,
				tags = { "purple", "dark", "sparkle", "space" },
			}),
			item({
				id = "es_rainbow",
				name = "Rainbow Shimmer",
				level = 8,
				color = rgb(255, 150, 200),
				gradient = { rgb(255, 120, 150), rgb(255, 220, 100), rgb(120, 220, 160), rgb(130, 170, 255) },
				sparkle = true,
				tags = { "bright", "sparkle", "pink", "blue" },
			}),
			item({ id = "es_pumpkin", name = "Pumpkin Spice", color = rgb(240, 120, 40), price = 30, event = "halloween", tags = { "orange" } }),
			item({ id = "es_harvest", name = "Harvest Gold", color = rgb(200, 140, 50), sparkle = true, price = 40, event = "thanksgiving", tags = { "gold", "orange", "brown" } }),
			item({ id = "es_mistletoe", name = "Mistletoe", color = rgb(40, 160, 80), sparkle = true, price = 40, event = "christmas", tags = { "green", "sparkle" } }),
		},
	},
	{
		key = "lashes",
		label = "Lashes",
		tab = "Face",
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
		tab = "Face",
		preview = "swatch",
		items = {
			item({ id = "bl_none", name = "None" }),
			item({ id = "bl_rosy", name = "Rosy", color = rgb(255, 120, 140), tags = { "pink" } }),
			item({ id = "bl_peach", name = "Peachy", color = rgb(255, 160, 120), tags = { "pastel", "bright", "orange" } }),
			item({ id = "bl_berry", name = "Berry", color = rgb(190, 60, 110), price = 30, tags = { "purple", "red" } }),
			item({ id = "bl_shimmer", name = "Shimmer", color = rgb(255, 170, 210), sparkle = true, price = 80, tags = { "pink", "sparkle" } }),
		},
	},
	{
		key = "lipstick",
		label = "Lipstick",
		tab = "Face",
		preview = "swatch",
		items = {
			item({ id = "lip_none", name = "None" }),
			item({ id = "lip_nude", name = "Nude", color = rgb(200, 130, 115), tags = { "brown" } }),
			item({ id = "lip_seaglass", name = "Sea Glass", color = rgb(90, 190, 180), tags = { "blue", "green", "ocean" } }),
			item({ id = "lip_clear", name = "Clear Gloss", color = rgb(245, 200, 205), sparkle = true, tags = { "sparkle", "white", "pastel" } }),
			item({ id = "lip_pink", name = "Pink", color = rgb(250, 110, 170), tags = { "pink", "pastel" } }),
			item({ id = "lip_red", name = "Classic Red", color = rgb(210, 30, 50), tags = { "red" } }),
			item({ id = "lip_coral", name = "Coral", color = rgb(255, 120, 90), tags = { "bright", "orange" } }),
			item({ id = "lip_berry", name = "Berry", color = rgb(150, 40, 100), tags = { "purple", "red" } }),
			item({ id = "lip_black", name = "Midnight", color = rgb(40, 30, 45), price = 40, tags = { "dark", "rockstar", "spooky" } }),
			item({ id = "lip_blue", name = "Mermaid Blue", color = rgb(60, 150, 220), price = 40, tags = { "blue", "green", "ocean" } }),
			item({ id = "lip_gloss", name = "Pink Gloss", color = rgb(255, 150, 200), sparkle = true, price = 80, tags = { "pink", "pastel", "sparkle" } }),
			item({ id = "lip_gold", name = "Golden Glam", color = rgb(225, 175, 60), sparkle = true, pass = "VIP", tags = { "gold", "sparkle" } }),
			item({ id = "lip_bubblegum", name = "Bubblegum Gloss", level = 4, color = rgb(255, 120, 200), sparkle = true, tags = { "pink", "pastel", "sparkle" } }),
			item({ id = "lip_candycorn", name = "Candy Corn", color = rgb(255, 150, 40), price = 30, event = "halloween", tags = { "orange", "bright" } }),
			item({ id = "lip_cranberry", name = "Cranberry", color = rgb(150, 20, 50), price = 30, event = "thanksgiving", tags = { "red", "purple" } }),
			item({ id = "lip_holly", name = "Holly Red", color = rgb(210, 20, 40), sparkle = true, price = 40, event = "christmas", tags = { "red", "sparkle" } }),
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
			item({ id = "outfit_denim", name = "Denim Jacket", color = rgb(80, 120, 190), accent = rgb(230, 230, 240), tags = { "blue", "pirate" } }),
			item({ id = "outfit_cozy", name = "Cozy Cardigan", color = rgb(160, 105, 70), accent = rgb(245, 225, 200), tags = { "brown", "orange", "pirate", "animal" } }),
			item({ id = "outfit_band", name = "Band Tee", color = rgb(35, 30, 40), accent = rgb(220, 40, 60), tags = { "dark", "red", "rockstar" } }),
			item({ id = "outfit_lilac", name = "Lilac Top", color = rgb(170, 120, 230), accent = rgb(245, 205, 90), tags = { "purple", "gold" } }),
			item({ id = "outfit_lime", name = "Lime Hoodie", color = rgb(130, 210, 90), accent = rgb(255, 255, 255), tags = { "green", "bright", "dino" } }),
			item({ id = "outfit_star", name = "Star Dress", dress = true, level = 6, color = rgb(250, 210, 80), accent = rgb(255, 255, 255), sparkle = true, tags = { "gold", "sparkle", "bright", "space" } }),
			item({ id = "outfit_party", dress = true, name = "Pink Party Dress", color = rgb(255, 140, 195), accent = rgb(255, 230, 240), tags = { "pink", "pastel", "princess" } }),
			item({ id = "outfit_sunny", dress = true, name = "Sunny Sundress", color = rgb(255, 210, 70), accent = rgb(255, 255, 255), price = 60, tags = { "bright", "gold" } }),
			item({ id = "outfit_black", dress = true, name = "Little Black Dress", color = rgb(30, 28, 35), accent = rgb(200, 200, 210), price = 60, tags = { "dark" } }),
			item({ id = "outfit_rock", name = "Rockstar Jacket", color = rgb(110, 40, 160), accent = rgb(20, 20, 25), price = 100, tags = { "purple", "dark", "rockstar" } }),
			item({ id = "outfit_mermaid", name = "Mermaid Top", color = rgb(60, 190, 170), accent = rgb(120, 200, 255), sparkle = true, price = 100, tags = { "green", "blue", "sparkle", "ocean" } }),
			item({ id = "outfit_red", dress = true, name = "Red Carpet Gown", color = rgb(200, 25, 45), accent = rgb(240, 200, 90), price = 120, tags = { "red", "gold", "superhero" } }),
			item({ id = "outfit_snow", dress = true, name = "Snow Princess", color = rgb(200, 230, 255), accent = rgb(255, 255, 255), sparkle = true, price = 150, tags = { "white", "blue", "sparkle", "winter", "princess" } }),
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
			item({
				id = "outfit_ballgown",
				name = "Ice Ball Gown",
				dress = true,
				pass = "Princess",
				color = rgb(140, 190, 255),
				accent = rgb(255, 255, 255),
				gradient = { rgb(200, 230, 255), rgb(120, 170, 255) },
				sparkle = true,
				tags = { "blue", "white", "sparkle" },
			}),
			item({
				id = "outfit_rosegown",
				name = "Rose Gown",
				dress = true,
				pass = "Princess",
				color = rgb(255, 130, 180),
				accent = rgb(255, 230, 150),
				gradient = { rgb(255, 200, 225), rgb(240, 90, 150) },
				sparkle = true,
				tags = { "pink", "gold", "sparkle" },
			}),
			item({
				id = "outfit_legend",
				name = "Legendary Gown",
				dress = true,
				level = 20,
				color = rgb(255, 200, 120),
				accent = rgb(255, 255, 255),
				gradient = { rgb(255, 230, 150), rgb(255, 160, 200), rgb(200, 150, 255) },
				sparkle = true,
				tags = { "gold", "pink", "sparkle" },
			}),
			-- Holiday outfits
			item({ id = "outfit_pumpkin", name = "Pumpkin Dress", dress = true, color = rgb(245, 130, 30), accent = rgb(60, 140, 60), price = 60, event = "halloween", tags = { "orange", "green", "spooky" } }),
			item({ id = "outfit_witch", name = "Witch Dress", dress = true, color = rgb(35, 25, 45), accent = rgb(150, 80, 220), price = 80, event = "halloween", tags = { "dark", "purple", "spooky" } }),
			item({
				id = "outfit_midnight",
				name = "Midnight Witch Gown",
				dress = true,
				pass = "VIP",
				event = "halloween",
				color = rgb(60, 20, 90),
				accent = rgb(255, 140, 40),
				gradient = { rgb(20, 10, 40), rgb(90, 30, 140), rgb(255, 130, 40) },
				sparkle = true,
				tags = { "purple", "dark", "orange", "sparkle" },
			}),
			item({ id = "outfit_sweater", name = "Fall Sweater", color = rgb(200, 100, 40), accent = rgb(250, 220, 170), price = 60, event = "thanksgiving", tags = { "orange", "brown" } }),
			item({ id = "outfit_harvest", name = "Harvest Dress", dress = true, color = rgb(170, 60, 30), accent = rgb(230, 170, 60), price = 80, event = "thanksgiving", tags = { "red", "gold", "orange" } }),
			item({ id = "outfit_xmas", name = "Holiday Sweater", color = rgb(200, 30, 40), accent = rgb(40, 150, 70), price = 60, event = "christmas", tags = { "red", "green" } }),
			item({ id = "outfit_velvet", name = "Red Velvet Dress", dress = true, color = rgb(170, 10, 30), accent = rgb(255, 255, 255), sparkle = true, price = 100, event = "christmas", tags = { "red", "white", "sparkle" } }),
			item({
				id = "outfit_sugarplum",
				name = "Sugar Plum Fairy",
				dress = true,
				pass = "VIP",
				event = "christmas",
				color = rgb(230, 120, 200),
				accent = rgb(255, 255, 255),
				gradient = { rgb(255, 190, 230), rgb(200, 110, 230), rgb(140, 80, 220) },
				sparkle = true,
				tags = { "pink", "purple", "sparkle", "white" },
			}),
		},
	},
	{
		key = "nailColor",
		label = "Polish",
		tab = "Nails",
		preview = "swatch",
		items = {
			item({ id = "nail_none", name = "Natural" }),
			item({ id = "nail_pink", name = "Pink", color = rgb(255, 120, 190), tags = { "pink" } }),
			item({ id = "nail_red", name = "Red", color = rgb(220, 30, 50), tags = { "red" } }),
			item({ id = "nail_coral", name = "Coral", color = rgb(255, 130, 80), tags = { "orange", "bright" } }),
			item({ id = "nail_lilac", name = "Lilac", color = rgb(180, 140, 240), tags = { "purple", "pastel" } }),
			item({ id = "nail_sky", name = "Sky Blue", color = rgb(120, 190, 255), tags = { "blue", "pastel" } }),
			item({ id = "nail_mint", name = "Mint", color = rgb(130, 225, 180), tags = { "green", "pastel" } }),
			item({ id = "nail_white", name = "Snow White", color = rgb(250, 250, 255), tags = { "white" } }),
			item({ id = "nail_black", name = "Midnight", color = rgb(30, 25, 40), price = 30, tags = { "dark" } }),
			item({ id = "nail_gold", name = "Gold Glitter", color = rgb(235, 190, 70), sparkle = true, price = 60, tags = { "gold", "sparkle" } }),
			item({
				id = "nail_rainbow",
				name = "Rainbow Chrome",
				pass = "VIP",
				color = rgb(255, 140, 190),
				gradient = { rgb(255, 100, 140), rgb(255, 220, 90), rgb(110, 220, 160), rgb(120, 160, 255) },
				sparkle = true,
				tags = { "bright", "sparkle", "pink", "blue" },
			}),
			item({ id = "nail_pumpkin", name = "Pumpkin", color = rgb(245, 130, 30), event = "halloween", tags = { "orange" } }),
			item({ id = "nail_cranberry", name = "Cranberry", color = rgb(150, 20, 50), event = "thanksgiving", tags = { "red", "purple" } }),
			item({
				id = "nail_candycane",
				name = "Candy Cane",
				price = 40,
				event = "christmas",
				color = rgb(230, 40, 60),
				gradient = { rgb(230, 40, 60), rgb(255, 255, 255), rgb(230, 40, 60) },
				tags = { "red", "white" },
			}),
		},
	},
	{
		key = "nailArt",
		label = "Nail Art",
		tab = "Nails",
		preview = "icon",
		items = {
			item({ id = "art_none", name = "None" }),
			item({ id = "art_hearts", name = "Hearts", icon = "♥", tags = { "pink" } }),
			item({ id = "art_dots", name = "Dots", icon = "•" }),
			item({ id = "art_stars", name = "Stars", icon = "★", tags = { "gold" } }),
			item({ id = "art_flowers", name = "Flowers", icon = "✿", price = 30, tags = { "bright", "pastel" } }),
			item({ id = "art_gems", name = "Gems", icon = "◆", price = 40, tags = { "sparkle" } }),
			item({ id = "art_pumpkin", name = "Pumpkins", icon = "🎃", event = "halloween", tags = { "orange" } }),
			item({ id = "art_leaf", name = "Leaves", icon = "🍁", event = "thanksgiving", tags = { "orange", "red" } }),
			item({ id = "art_snow", name = "Snowflakes", icon = "❄️", event = "christmas", tags = { "white", "blue" } }),
		},
	},
	{
		key = "outfitColor",
		label = "🎨 Color",
		tab = "Outfit",
		preview = "swatch",
		items = (function()
			local list = { item({ id = "oc_none", name = "Original" }) }
			local palette = {
				{ "Hot Pink", rgb(255, 80, 160), { "pink", "bright" } },
				{ "Baby Pink", rgb(255, 190, 215), { "pink", "pastel" } },
				{ "Cherry", rgb(220, 30, 50), { "red" } },
				{ "Tangerine", rgb(255, 140, 40), { "orange", "bright" } },
				{ "Sunshine", rgb(255, 215, 60), { "gold", "bright" } },
				{ "Gold", rgb(225, 175, 60), { "gold", "sparkle" } },
				{ "Lime", rgb(150, 220, 80), { "green", "bright" } },
				{ "Mint", rgb(150, 230, 190), { "green", "pastel" } },
				{ "Emerald", rgb(30, 150, 90), { "green" } },
				{ "Aqua", rgb(70, 210, 220), { "blue", "bright" } },
				{ "Sky", rgb(140, 200, 255), { "blue", "pastel" } },
				{ "Royal Blue", rgb(50, 80, 200), { "blue" } },
				{ "Lavender", rgb(190, 160, 240), { "purple", "pastel" } },
				{ "Violet", rgb(130, 60, 200), { "purple" } },
				{ "Plum", rgb(90, 30, 90), { "purple", "dark" } },
				{ "Chocolate", rgb(110, 70, 45), { "brown" } },
				{ "Snow", rgb(250, 250, 255), { "white" } },
				{ "Silver", rgb(195, 200, 210), { "white", "sparkle" } },
				{ "Charcoal", rgb(60, 60, 70), { "dark" } },
				{ "Midnight", rgb(20, 18, 30), { "dark" } },
			}
			for i, p in palette do
				-- ids come from the name, so adding colors later never changes saved looks
				local id = "oc_" .. string.lower((string.gsub(p[1], "%s", "")))
				table.insert(list, item({ id = id, name = p[1], color = p[2], tags = p[3] }))
			end
			return list
		end)(),
	},
	{
		key = "outfitPattern",
		label = "Pattern",
		tab = "Outfit",
		preview = "portrait",
		items = {
			item({ id = "pat_none", name = "Plain" }),
			item({ id = "pat_dots", name = "Polka Dots", tags = { "bright" } }),
			item({ id = "pat_stripes", name = "Stripes" }),
			item({ id = "pat_hearts", name = "Hearts", tags = { "pink" } }),
			item({ id = "pat_stars", name = "Stars", price = 40, tags = { "gold", "sparkle" } }),
			item({ id = "pat_flowers", name = "Flowers", price = 40, tags = { "bright", "pastel" } }),
		},
	},
	{
		key = "gems",
		label = "Face Art",
		tab = "Face",
		preview = "portrait",
		items = {
			item({ id = "gem_none", name = "None" }),
			item({ id = "gem_freckles", name = "Freckles", tags = { "animal" } }),
			item({ id = "gem_hearts", name = "Heart Stickers", price = 40, color = rgb(255, 80, 130), tags = { "pink", "red" } }),
			item({ id = "gem_stars", name = "Star Stickers", price = 40, color = rgb(255, 200, 60), tags = { "gold", "bright", "space", "superhero" } }),
			item({ id = "gem_rhinestones", name = "Rhinestones", pass = "VIP", color = rgb(220, 240, 255), tags = { "sparkle", "white", "princess" } }),
			item({ id = "gem_pinkgems", name = "Pink Gems", pass = "Princess", draw = "gem_rhinestones", color = rgb(255, 140, 200), tags = { "pink", "sparkle" } }),
			item({ id = "gem_bats", name = "Bat Stickers", price = 30, event = "halloween", color = rgb(40, 30, 50), tags = { "dark", "purple", "spooky" } }),
			item({ id = "gem_web", name = "Spider Web", price = 30, event = "halloween", color = rgb(255, 255, 255), tags = { "dark", "white", "spooky" } }),
			item({ id = "gem_leaves", name = "Leaf Stickers", price = 30, event = "thanksgiving", color = rgb(220, 110, 30), tags = { "orange", "red", "brown" } }),
			item({ id = "gem_snowflakes", name = "Snowflakes", price = 30, event = "christmas", color = rgb(200, 230, 255), tags = { "white", "blue", "sparkle" } }),
		},
	},
	{
		key = "accessory",
		label = "Hats & Clips",
		tab = "Costume",
		preview = "portrait",
		items = {
			item({ id = "acc_none", name = "None" }),
			item({ id = "acc_bow", name = "Big Bow", color = rgb(255, 110, 170), tags = { "pink" } }),
			item({ id = "acc_headband", name = "Headband", color = rgb(90, 150, 255), tags = { "blue", "superhero" } }),
			item({ id = "acc_redbow", name = "Red Bow", draw = "acc_bow", color = rgb(220, 30, 50), tags = { "red" } }),
			item({ id = "acc_purpleband", name = "Purple Headband", draw = "acc_headband", color = rgb(120, 60, 180), tags = { "purple", "dark" } }),
			item({ id = "acc_flower", name = "Flower", color = rgb(255, 120, 90), tags = { "bright", "orange", "fairy" } }),
			item({ id = "acc_earrings", name = "Gold Hoops", color = rgb(240, 195, 70), price = 50, tags = { "gold" } }),
			item({ id = "acc_catears", name = "Cat Ears", color = rgb(40, 35, 45), price = 80, tags = { "dark", "animal" } }),
			item({ id = "acc_crown", name = "Royal Crown", color = rgb(245, 200, 60), pass = "VIP", tags = { "gold", "sparkle", "princess" } }),
			item({ id = "acc_butterfly", name = "Butterfly Clip", level = 2, color = rgb(120, 180, 255), tags = { "blue", "bright", "fairy" } }),
			item({ id = "acc_halo", name = "Star Halo", level = 10, color = rgb(255, 220, 80), tags = { "gold", "sparkle", "fairy" } }),
			item({ id = "acc_diamondtiara", name = "Diamond Tiara", level = 12, draw = "acc_tiara", color = rgb(210, 235, 255), tags = { "white", "sparkle", "princess" } }),
			item({ id = "acc_tiara", name = "Princess Tiara", pass = "Princess", color = rgb(245, 205, 90), tags = { "gold", "sparkle", "pink", "princess" } }),
			item({ id = "acc_goldbow", name = "Golden Bow", gift = true, draw = "acc_bow", color = rgb(245, 195, 60), tags = { "gold", "sparkle" } }),
			item({ id = "acc_rainbowband", name = "Rainbow Headband", gift = true, draw = "acc_headband", color = rgb(255, 120, 160), gradient = { rgb(255, 90, 120), rgb(255, 210, 80), rgb(90, 210, 140), rgb(110, 150, 255) }, tags = { "bright", "pink", "blue" } }),
			item({ id = "acc_clover", name = "Lucky Clover", gift = true, icon = "🍀", tags = { "green", "bright" } }),
			item({ id = "acc_rainbowclip", name = "Rainbow Clip", gift = true, icon = "🌈", tags = { "bright", "pink", "blue" } }),
			item({ id = "acc_unicorn", name = "Unicorn Clip", gift = true, icon = "🦄", tags = { "pink", "purple", "sparkle", "fairy" } }),
			item({ id = "acc_strawberry", name = "Strawberry Clip", gift = true, icon = "🍓", tags = { "red", "pink" } }),
			item({ id = "acc_pearls", name = "Pearl Earrings", gift = true, draw = "acc_earrings", color = rgb(250, 245, 240), tags = { "white", "sparkle" } }),
			item({ id = "acc_witchhat", name = "Witch Hat", color = rgb(35, 25, 45), accent = rgb(150, 80, 220), price = 60, event = "halloween", tags = { "dark", "purple", "spooky" } }),
			item({ id = "acc_pumpkin", name = "Pumpkin Clip", color = rgb(245, 130, 30), event = "halloween", tags = { "orange", "green", "spooky" } }),
			item({ id = "acc_leafcrown", name = "Leaf Crown", color = rgb(220, 110, 30), price = 50, event = "thanksgiving", tags = { "orange", "red", "gold" } }),
			item({ id = "acc_santahat", name = "Santa Hat", color = rgb(210, 30, 40), price = 60, event = "christmas", tags = { "red", "white" } }),
			item({ id = "acc_antlers", name = "Reindeer Antlers", color = rgb(130, 80, 40), event = "christmas", tags = { "brown", "red", "animal", "winter" } }),
			item({ id = "acc_earmuffs", name = "Fluffy Earmuffs", color = rgb(255, 255, 255), accent = rgb(110, 170, 255), price = 50, event = "christmas", tags = { "white", "blue", "winter" } }),
			-- Hats from the avatar shop
			item({ id = "acc_piratehat", name = "Pirate Hat", asset = 5891628524, tags = { "pirate", "dark" } }),
			item({ id = "acc_captainhat", name = "Captain Hat", asset = 5860059125, price = 60, tags = { "pirate", "gold" } }),
			item({ id = "acc_bandana", name = "Pirate Bandana", asset = 15549772889, price = 40, tags = { "pirate", "red" } }),
			item({ id = "acc_shellcrown", name = "Seashell Crown", asset = 472605748, tags = { "ocean", "princess" } }),
			item({ id = "acc_shelltiara", name = "Seashell Tiara", asset = 18261572591, price = 60, tags = { "ocean", "pink" } }),
			item({ id = "acc_jellyhat", name = "Jellyfish Hat", asset = 32661648, price = 40, tags = { "ocean", "blue" } }),
			item({ id = "acc_dinohood", name = "Dino Hood", asset = 4735353280, tags = { "dino", "green" } }),
			item({ id = "acc_bluedino", name = "Blue Dino Hood", asset = 8405410150, price = 60, tags = { "dino", "blue" } }),
			item({ id = "acc_pinkdino", name = "Pink Dino Hood", asset = 14103824394, price = 60, tags = { "dino", "pink" } }),
			item({ id = "acc_astronaut", name = "Astronaut Helmet", asset = 1081366, tags = { "space", "white" } }),
			item({ id = "acc_pastelhelmet", name = "Pastel Space Helmet", asset = 112810928618923, price = 80, tags = { "space", "pastel" } }),
			item({ id = "acc_antenna", name = "Alien Antenna", asset = 13582999750, tags = { "space", "green" } }),
			item({ id = "acc_heartantenna", name = "Heart Antennas", asset = 103873506199484, price = 40, tags = { "space", "pink" } }),
			item({ id = "acc_saturn", name = "Saturn Headband", asset = 136682175562639, price = 40, tags = { "space", "purple" } }),
			item({ id = "acc_bigcrown", name = "Gold Crown", asset = 138180638995878, tags = { "princess", "gold" } }),
			item({ id = "acc_sparkletiara", name = "Sparkle Tiara", asset = 15170410900, price = 40, tags = { "princess", "sparkle" } }),
			item({ id = "acc_flowercrown", name = "Flower Crown", asset = 8918679960, tags = { "fairy", "pastel", "green" } }),
			item({ id = "acc_unicornhorn", name = "Unicorn Horn", asset = 9255093, price = 40, tags = { "fairy", "princess", "white" } }),
			item({ id = "acc_starshades", name = "Star Shades", asset = 13174877315, price = 40, tags = { "rockstar", "white" } }),
			item({ id = "acc_pumpkinhat", name = "Pumpkin Hat", asset = 5673632543, tags = { "spooky", "orange" } }),
			item({ id = "acc_catears2", name = "Kitty Ears", asset = 9553060342, tags = { "animal", "dark" } }),
			item({ id = "acc_bunnyears", name = "Bunny Ears", asset = 118301166634769, tags = { "animal", "white" } }),
			item({ id = "acc_dogears", name = "Puppy Ears", asset = 11142487, tags = { "animal", "brown" } }),
			item({ id = "acc_bowears", name = "Puppy Ears with Bow", asset = 91964461585164, price = 60, tags = { "animal", "pink" } }),
		},
	},
	-- Costume pieces from the avatar shop (loaded when the game starts; see Avatar.preload)
	{
		key = "costumeBack",
		label = "Wings & Capes",
		tab = "Costume",
		preview = "icon",
		items = {
			item({ id = "back_none", name = "None" }),
			item({ id = "back_herocape", name = "Hero Cape", asset = 417456455, tags = { "superhero", "red" } }),
			item({ id = "back_whitecape", name = "White Cape", asset = 8948936632, price = 40, tags = { "superhero", "white" } }),
			item({ id = "back_fairywings", name = "Fairy Wings", asset = 7002533200, tags = { "fairy", "princess", "sparkle" } }),
			item({ id = "back_butterfly", name = "Butterfly Wings", asset = 124754102, price = 60, tags = { "fairy", "bright" } }),
			item({ id = "back_angel", name = "Angel Wings", asset = 18953818754, price = 60, tags = { "princess", "white", "winter" } }),
			item({ id = "back_pinkwings", name = "Pink Wings", asset = 15302783937, price = 80, tags = { "pink", "fairy", "princess" } }),
			item({ id = "back_rainbow", name = "Rainbow Wings", asset = 335080396, pass = "VIP", tags = { "fairy", "bright", "sparkle" } }),
			item({ id = "back_dragon", name = "Dragon Wings", asset = 17426330725, price = 80, tags = { "dino", "spooky", "dark" } }),
			item({ id = "back_bat", name = "Bat Wings", asset = 13990532463, tags = { "spooky", "dark", "purple" } }),
			item({ id = "back_jetpack", name = "Jetpack", asset = 5768738455, tags = { "space", "superhero" } }),
			item({ id = "back_rocket", name = "Rocket Pack", asset = 15518691268, price = 60, tags = { "space", "red" } }),
			item({ id = "back_guitar", name = "Rock Guitar", asset = 1744123855, tags = { "rockstar", "dark" } }),
			item({ id = "back_redguitar", name = "Red Guitar", asset = 1149571901, price = 60, tags = { "rockstar", "red" } }),
			item({ id = "back_mermaid", name = "Mermaid Tail", asset = 136903969097188, tags = { "ocean", "blue" } }),
			item({ id = "back_bubbles", name = "Bubbles", asset = 12590283275, price = 40, tags = { "ocean", "blue" } }),
			item({ id = "back_dinotail", name = "Dino Tail", asset = 119813106280423, price = 40, tags = { "dino", "green" } }),
			item({ id = "back_dinopack", name = "Dino Backpack", asset = 12610739631, tags = { "dino", "green" } }),
			item({ id = "back_ghost", name = "Friendly Ghost", asset = 5702357673, price = 60, tags = { "spooky", "white" } }),
			item({ id = "back_wand", name = "Big Magic Wand", asset = 6444932602, price = 80, tags = { "princess", "fairy", "pink" } }),
		},
	},
	{
		key = "costumeFace",
		label = "Masks & Glasses",
		tab = "Costume",
		preview = "icon",
		items = {
			item({ id = "mask_none", name = "None" }),
			item({ id = "mask_hero", name = "Hero Mask", asset = 5548522000, tags = { "superhero", "blue" } }),
			item({ id = "mask_super", name = "Super Mask", asset = 6905344185, price = 40, tags = { "superhero", "red" } }),
			item({ id = "mask_eyepatch", name = "Eye Patch", asset = 74970669, tags = { "pirate", "dark" } }),
			item({ id = "mask_popstar", name = "Pop Star Shades", asset = 130883544614317, price = 60, tags = { "rockstar", "sparkle" } }),
			item({ id = "mask_headphones", name = "Headphones", asset = 14253748049, price = 40, tags = { "rockstar", "dark" } }),
			item({ id = "mask_mic", name = "Microphone", asset = 4963997880, tags = { "rockstar", "party" } }),
			item({ id = "mask_starearrings", name = "Star Earrings", asset = 12611548379, price = 40, tags = { "space", "gold", "sparkle" } }),
		},
	},
	{
		key = "costumeWaist",
		label = "Tails & More",
		tab = "Costume",
		preview = "icon",
		items = {
			item({ id = "tail_none", name = "None" }),
			item({ id = "tail_herobelt", name = "Hero Belt", asset = 13073770809, tags = { "superhero", "gold" } }),
			item({ id = "tail_cutlass", name = "Toy Cutlass", asset = 5891629882, price = 40, tags = { "pirate", "gold" } }),
			item({ id = "tail_mermaid", name = "Mermaid Fin", asset = 18209759894, price = 40, tags = { "ocean", "green" } }),
			item({ id = "tail_dino", name = "Dino Tail", asset = 707915127, tags = { "dino", "brown" } }),
			item({ id = "tail_cat", name = "Cat Tail", asset = 13547447399, tags = { "animal", "dark" } }),
			item({ id = "tail_bunny", name = "Bunny Tail", asset = 14447720654, price = 40, tags = { "animal", "white" } }),
			item({ id = "tail_starwand", name = "Star Wand", asset = 13012740693, tags = { "princess", "fairy", "gold" } }),
			item({ id = "tail_candybucket", name = "Candy Bucket", asset = 133612550428411, tags = { "spooky", "orange" } }),
		},
	},
	{
		key = "costumeShoulder",
		label = "Buddies",
		tab = "Costume",
		preview = "icon",
		items = {
			item({ id = "pal_none", name = "None" }),
			item({ id = "pal_parrot", name = "Parrot", asset = 9794669285, tags = { "pirate", "red", "green" } }),
			item({ id = "pal_jellyfish", name = "Jellyfish", asset = 112156305935859, price = 40, tags = { "ocean", "pink" } }),
			item({ id = "pal_puffer", name = "Puffer Fish", asset = 15812592051, tags = { "ocean", "orange" } }),
			item({ id = "pal_bubbles", name = "Bubble Pal", asset = 16396460602, price = 40, tags = { "ocean", "blue" } }),
			item({ id = "pal_dino", name = "Baby Dino Pal", asset = 11449705506, tags = { "dino", "green" } }),
			item({ id = "pal_catghost", name = "Kitty Ghost", asset = 16444910191, price = 40, tags = { "spooky", "white" } }),
			item({ id = "pal_ghost", name = "Little Ghost", asset = 94072997357023, tags = { "spooky", "white" } }),
			item({ id = "pal_dragon", name = "Neon Dragon", asset = 14972209282, price = 60, tags = { "dino", "fairy", "bright" } }),
		},
	},
	{
		key = "pet",
		label = "Pet",
		tab = "Pet",
		preview = "icon",
		items = {
			item({ id = "pet_none", name = "No Pet", icon = "⚪" }),
			item({ id = "pet_bean", name = "Bean", icon = "🐶", tags = { "animal", "dark", "white" } }),
			item({ id = "pet_kitty", name = "Kitty", icon = "🐱", tags = { "animal", "orange" } }),
			item({ id = "pet_bunny", name = "Bunny", icon = "🐰", tags = { "animal", "white", "fairy" } }),
			item({ id = "pet_dino", name = "Baby Dino", icon = "🦖", price = 60, tags = { "dino", "green" } }),
			item({ id = "pet_dragon", name = "Baby Dragon", icon = "🐉", price = 100, tags = { "fairy", "purple", "spooky", "dino" } }),
			item({ id = "pet_unicorn", name = "Unicorn", icon = "🦄", pass = "Princess", tags = { "princess", "fairy", "sparkle", "pink" } }),
		},
	},
	{
		key = "pose",
		label = "Pose",
		tab = "Show",
		preview = "icon",
		items = {
			item({ id = "pose_none", name = "Just Walk", icon = "🚶" }),
			item({ id = "pose_wave", name = "Wave", icon = "👋", anim = "rbxassetid://507770239", tags = { "princess" } }),
			item({ id = "pose_cheer", name = "Hero Cheer", icon = "🙌", anim = "rbxassetid://507770677", tags = { "superhero" } }),
			item({ id = "pose_point", name = "Point", icon = "👉", anim = "rbxassetid://507770453", tags = { "pirate", "space" } }),
			item({ id = "pose_dance", name = "Dance", icon = "💃", anim = "rbxassetid://507771019", tags = { "rockstar", "party" } }),
			item({ id = "pose_dance2", name = "Groove", icon = "🕺", anim = "rbxassetid://507776043", price = 40, tags = { "rockstar", "ocean" } }),
			item({ id = "pose_dance3", name = "Robot", icon = "🤖", anim = "rbxassetid://507777268", price = 40, tags = { "space", "dino" } }),
			item({ id = "pose_laugh", name = "Giggle", icon = "😆", anim = "rbxassetid://507770818", tags = { "animal", "fairy" } }),
		},
	},
	{
		key = "effect",
		label = "Effect",
		tab = "Show",
		preview = "icon",
		items = {
			item({ id = "fx_none", name = "None", icon = "⚪" }),
			item({ id = "fx_sparkles", name = "Sparkles", icon = "✨", tags = { "sparkle", "fairy", "princess" } }),
			item({ id = "fx_hearts", name = "Hearts", icon = "💖", tags = { "pink", "princess" } }),
			item({ id = "fx_bubbles", name = "Bubbles", icon = "💧", tags = { "ocean", "blue" } }),
			item({ id = "fx_stars", name = "Stars", icon = "⭐", tags = { "space", "superhero", "gold" } }),
			item({ id = "fx_snow", name = "Snow", icon = "❄️", tags = { "winter", "white" } }),
			item({ id = "fx_leaves", name = "Leaves", icon = "🍃", tags = { "dino", "fairy", "green" } }),
			item({ id = "fx_fire", name = "Fire", icon = "🔥", price = 60, tags = { "rockstar", "superhero", "dino", "red" } }),
			item({ id = "fx_smoke", name = "Smoke Entrance", icon = "💨", price = 60, tags = { "spooky", "superhero", "pirate" } }),
			item({ id = "fx_confetti", name = "Confetti", icon = "🎉", price = 40, tags = { "party", "bright" } }),
			item({ id = "fx_rainbow", name = "Rainbow Trail", icon = "🌈", pass = "VIP", tags = { "bright", "fairy", "pink", "blue" } }),
		},
	},
}

-- Fashion show themes. The judges reward looks whose tags match.
Catalog.Themes = {
	{ id = "superhero", name = "Superhero 🦸", tags = { "superhero", "red", "blue" }, color = rgb(220, 40, 60) },
	{ id = "pirate", name = "Pirate Adventure 🦜", tags = { "pirate", "brown", "gold" }, color = rgb(150, 90, 40) },
	{ id = "under_sea", name = "Under the Sea 🐚", tags = { "ocean", "blue", "green" }, color = rgb(50, 170, 200) },
	{ id = "dino_party", name = "Dinosaur Party 🦖", tags = { "dino", "green", "orange" }, color = rgb(80, 180, 80) },
	{ id = "space", name = "Outer Space 🚀", tags = { "space", "purple", "dark" }, color = rgb(90, 60, 180) },
	{ id = "royal_ball", name = "Princess Ball 👑", tags = { "princess", "gold", "sparkle" }, color = rgb(220, 170, 60) },
	{ id = "fairy", name = "Fairy Garden 🧚", tags = { "fairy", "green", "pastel" }, color = rgb(150, 210, 140) },
	{ id = "rock_star", name = "Rock Star 🎸", tags = { "rockstar", "dark", "red" }, color = rgb(120, 40, 160) },
	{ id = "animals", name = "Animal Friends 🐾", tags = { "animal", "brown", "orange" }, color = rgb(200, 130, 60) },
	{ id = "pink_party", name = "Pink Party 🎀", tags = { "pink", "sparkle", "party" }, color = rgb(255, 130, 190) },
	{ id = "candy_land", name = "Candy Land 🍭", tags = { "pastel", "bright" }, color = rgb(255, 160, 210) },
	{ id = "winter", name = "Winter Wonderland ❄️", tags = { "winter", "white", "blue" }, color = rgb(150, 200, 255) },
	{ id = "halloween", name = "Halloween Party 🎃", tags = { "spooky", "orange", "dark" }, color = rgb(245, 130, 30), event = "halloween" },
	{ id = "thanksgiving", name = "Harvest Festival 🍂", tags = { "orange", "brown" }, color = rgb(200, 110, 40), event = "thanksgiving" },
	{ id = "christmas", name = "Christmas Party 🎄", tags = { "red", "green", "winter" }, color = rgb(200, 30, 40), event = "christmas" },
} :: { Theme }

-- Day-7 prizes of the daily gift calendar, given in this order
Catalog.GiftItems = { "acc_goldbow", "acc_rainbowband", "acc_pearls" }

-- Prizes for finishing the weekly goal, given in this order
Catalog.WeeklyItems = { "acc_clover", "acc_unicorn", "acc_rainbowclip", "acc_strawberry" }

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

-- What every avatar starts with in the dressing room.
function Catalog.defaultLook(): { [string]: string }
	return {
		hairStyle = "hair_puff",
		hairColor = "hc_black",
		eyeshadow = "es_none",
		lashes = "lash_none",
		blush = "bl_none",
		lipstick = "lip_none",
		outfit = "outfit_work",
		outfitColor = "oc_none",
		nailColor = "nail_none",
		nailArt = "art_none",
		outfitPattern = "pat_none",
		gems = "gem_none",
		accessory = "acc_none",
		costumeBack = "back_none",
		costumeFace = "mask_none",
		costumeWaist = "tail_none",
		costumeShoulder = "pal_none",
		pet = "pet_none",
		pose = "pose_none",
		effect = "fx_none",
	}
end

-- The skin color of a look (or the fallback when it has none).
function Catalog.skinColor(look, fallback: Color3): Color3
	local it = Catalog.byId[look and look.skin or ""]
	return if it and it.color then it.color else fallback
end

-- The skin tone item closest to a color (used to start from the player's own avatar).
function Catalog.closestSkin(color: Color3): string
	local best, bestDistance = 1, math.huge
	for i, tone in Catalog.SkinTones do
		local c = tone[2]
		local d = (c.R - color.R) ^ 2 + (c.G - color.G) ^ 2 + (c.B - color.B) ^ 2
		if d < bestDistance then
			best, bestDistance = i, d
		end
	end
	return "skin_" .. best
end

-- Can this item be shown and used right now? Holiday items show up during their event,
-- and stay forever for players who unlocked them.
local function owns(profile, itemId: string): boolean
	return profile ~= nil and profile.owned ~= nil and profile.owned[itemId] == true
end

-- Total stars earned (the client gets it as `totalStars`, the server keeps it in `stats`).
function Catalog.playerLevel(profile): number
	local stars = 0
	if profile then
		stars = profile.totalStars or (profile.stats and profile.stats.totalStars) or 0
	end
	return Progress.level(stars)
end

function Catalog.isAvailable(it: Item, profile, eventId: string?): boolean
	if it.hidden then
		return false
	end
	if it.gift then
		return owns(profile, it.id)
	end
	if it.event and it.event ~= eventId then
		return profile ~= nil and profile.owned ~= nil and profile.owned[it.id] == true
	end
	return true
end

-- Is this item usable by a player with this profile?
-- profile = { owned = { [itemId] = true }, passes = { VIP = true } }
function Catalog.isUnlocked(it: Item, profile, eventId: string?): boolean
	if not Catalog.isAvailable(it, profile, eventId) then
		return false
	end
	if it.level then
		return Catalog.playerLevel(profile) >= it.level
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
