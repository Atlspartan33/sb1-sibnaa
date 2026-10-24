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
	icon: string?, -- symbol for nail art
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

Catalog.Tabs = {
	{ id = "Wash", label = "Wash", icon = "🧼" },
	{ id = "Hair", label = "Hair", icon = "💇" },
	{ id = "Makeup", label = "Makeup", icon = "💄" },
	{ id = "Nails", label = "Nails", icon = "💅" },
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
			item({ id = "hair_princess", name = "Princess Curls", pass = "Princess", draw = "hair_curls", tags = { "sparkle" } }),
		},
	},
	{
		key = "hairColor",
		label = "Hair Color",
		tab = "Hair",
		preview = "swatch",
		items = {
			item({ id = "hc_black", name = "Black", color = rgb(35, 30, 32), tags = { "dark" } }),
			item({ id = "hc_brown", name = "Brown", color = rgb(105, 66, 40), tags = { "brown" } }),
			item({ id = "hc_blonde", name = "Blonde", color = rgb(240, 205, 120), tags = { "gold", "bright" } }),
			item({ id = "hc_strawberry", name = "Strawberry", color = rgb(250, 160, 170), tags = { "pink", "pastel" } }),
			item({ id = "hc_teal", name = "Teal", color = rgb(60, 170, 180), tags = { "blue", "green" } }),
			item({ id = "hc_ginger", name = "Ginger", color = rgb(200, 95, 45), tags = { "red", "bright", "orange" } }),
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
			item({ id = "hc_cottoncandy", name = "Cotton Candy", level = 3, color = rgb(255, 170, 220), gradient = { rgb(255, 160, 215), rgb(170, 210, 255) }, tags = { "pink", "pastel", "blue" } }),
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
		tab = "Makeup",
		preview = "swatch",
		items = {
			item({ id = "es_none", name = "None" }),
			item({ id = "es_pink", name = "Pink", color = rgb(255, 150, 200), tags = { "pink", "pastel" } }),
			item({ id = "es_peach", name = "Peach", color = rgb(255, 180, 140), tags = { "pastel", "bright", "orange" } }),
			item({ id = "es_bronze", name = "Bronze", color = rgb(180, 120, 70), tags = { "gold", "brown" } }),
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
			item({
				id = "es_rainbow",
				name = "Rainbow Shimmer",
				level = 6,
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
			item({ id = "bl_peach", name = "Peachy", color = rgb(255, 160, 120), tags = { "pastel", "bright", "orange" } }),
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
			item({ id = "lip_nude", name = "Nude", color = rgb(200, 130, 115), tags = { "brown" } }),
			item({ id = "lip_clear", name = "Clear Gloss", color = rgb(245, 200, 205), sparkle = true, tags = { "sparkle", "white", "pastel" } }),
			item({ id = "lip_pink", name = "Pink", color = rgb(250, 110, 170), tags = { "pink", "pastel" } }),
			item({ id = "lip_red", name = "Classic Red", color = rgb(210, 30, 50), tags = { "red" } }),
			item({ id = "lip_coral", name = "Coral", color = rgb(255, 120, 90), tags = { "bright", "orange" } }),
			item({ id = "lip_berry", name = "Berry", color = rgb(150, 40, 100), tags = { "purple", "red" } }),
			item({ id = "lip_black", name = "Midnight", color = rgb(40, 30, 45), price = 40, tags = { "dark" } }),
			item({ id = "lip_blue", name = "Mermaid Blue", color = rgb(60, 150, 220), price = 40, tags = { "blue", "green" } }),
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
			item({ id = "outfit_denim", name = "Denim Jacket", color = rgb(80, 120, 190), accent = rgb(230, 230, 240), tags = { "blue" } }),
			item({ id = "outfit_cozy", name = "Cozy Cardigan", color = rgb(160, 105, 70), accent = rgb(245, 225, 200), tags = { "brown", "orange" } }),
			item({ id = "outfit_band", name = "Band Tee", color = rgb(35, 30, 40), accent = rgb(220, 40, 60), tags = { "dark", "red" } }),
			item({ id = "outfit_lilac", name = "Lilac Top", color = rgb(170, 120, 230), accent = rgb(245, 205, 90), tags = { "purple", "gold" } }),
			item({ id = "outfit_lime", name = "Lime Hoodie", color = rgb(130, 210, 90), accent = rgb(255, 255, 255), tags = { "green", "bright" } }),
			item({ id = "outfit_star", name = "Star Dress", dress = true, level = 5, color = rgb(250, 210, 80), accent = rgb(255, 255, 255), sparkle = true, tags = { "gold", "sparkle", "bright" } }),
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
			-- Holiday outfits
			item({ id = "outfit_pumpkin", name = "Pumpkin Dress", dress = true, color = rgb(245, 130, 30), accent = rgb(60, 140, 60), price = 60, event = "halloween", tags = { "orange", "green" } }),
			item({ id = "outfit_witch", name = "Witch Dress", dress = true, color = rgb(35, 25, 45), accent = rgb(150, 80, 220), price = 80, event = "halloween", tags = { "dark", "purple" } }),
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
				table.insert(list, item({ id = "oc_" .. i, name = p[1], color = p[2], tags = p[3] }))
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
		tab = "Extras",
		preview = "portrait",
		items = {
			item({ id = "gem_none", name = "None" }),
			item({ id = "gem_freckles", name = "Freckles" }),
			item({ id = "gem_hearts", name = "Heart Stickers", price = 40, color = rgb(255, 80, 130), tags = { "pink", "red" } }),
			item({ id = "gem_stars", name = "Star Stickers", price = 40, color = rgb(255, 200, 60), tags = { "gold", "bright" } }),
			item({ id = "gem_rhinestones", name = "Rhinestones", pass = "VIP", color = rgb(220, 240, 255), tags = { "sparkle", "white" } }),
			item({ id = "gem_pinkgems", name = "Pink Gems", pass = "Princess", draw = "gem_rhinestones", color = rgb(255, 140, 200), tags = { "pink", "sparkle" } }),
			item({ id = "gem_bats", name = "Bat Stickers", price = 30, event = "halloween", color = rgb(40, 30, 50), tags = { "dark", "purple" } }),
			item({ id = "gem_web", name = "Spider Web", price = 30, event = "halloween", color = rgb(255, 255, 255), tags = { "dark", "white" } }),
			item({ id = "gem_leaves", name = "Leaf Stickers", price = 30, event = "thanksgiving", color = rgb(220, 110, 30), tags = { "orange", "red", "brown" } }),
			item({ id = "gem_snowflakes", name = "Snowflakes", price = 30, event = "christmas", color = rgb(200, 230, 255), tags = { "white", "blue", "sparkle" } }),
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
			item({ id = "acc_redbow", name = "Red Bow", draw = "acc_bow", color = rgb(220, 30, 50), tags = { "red" } }),
			item({ id = "acc_purpleband", name = "Purple Headband", draw = "acc_headband", color = rgb(120, 60, 180), tags = { "purple", "dark" } }),
			item({ id = "acc_flower", name = "Flower", color = rgb(255, 120, 90), tags = { "bright", "orange" } }),
			item({ id = "acc_earrings", name = "Gold Hoops", color = rgb(240, 195, 70), price = 50, tags = { "gold" } }),
			item({ id = "acc_catears", name = "Cat Ears", color = rgb(40, 35, 45), price = 80, tags = { "dark" } }),
			item({ id = "acc_crown", name = "Royal Crown", color = rgb(245, 200, 60), pass = "VIP", tags = { "gold", "sparkle" } }),
			item({ id = "acc_butterfly", name = "Butterfly Clip", level = 2, color = rgb(120, 180, 255), tags = { "blue", "bright" } }),
			item({ id = "acc_halo", name = "Star Halo", level = 8, color = rgb(255, 220, 80), tags = { "gold", "sparkle" } }),
			item({ id = "acc_tiara", name = "Princess Tiara", pass = "Princess", color = rgb(245, 205, 90), tags = { "gold", "sparkle", "pink" } }),
			item({ id = "acc_goldbow", name = "Golden Bow", gift = true, draw = "acc_bow", color = rgb(245, 195, 60), tags = { "gold", "sparkle" } }),
			item({ id = "acc_rainbowband", name = "Rainbow Headband", gift = true, draw = "acc_headband", color = rgb(255, 120, 160), gradient = { rgb(255, 90, 120), rgb(255, 210, 80), rgb(90, 210, 140), rgb(110, 150, 255) }, tags = { "bright", "pink", "blue" } }),
			item({ id = "acc_pearls", name = "Pearl Earrings", gift = true, draw = "acc_earrings", color = rgb(250, 245, 240), tags = { "white", "sparkle" } }),
			item({ id = "acc_witchhat", name = "Witch Hat", color = rgb(35, 25, 45), accent = rgb(150, 80, 220), price = 60, event = "halloween", tags = { "dark", "purple" } }),
			item({ id = "acc_pumpkin", name = "Pumpkin Clip", color = rgb(245, 130, 30), event = "halloween", tags = { "orange", "green" } }),
			item({ id = "acc_leafcrown", name = "Leaf Crown", color = rgb(220, 110, 30), price = 50, event = "thanksgiving", tags = { "orange", "red", "gold" } }),
			item({ id = "acc_santahat", name = "Santa Hat", color = rgb(210, 30, 40), price = 60, event = "christmas", tags = { "red", "white" } }),
			item({ id = "acc_antlers", name = "Reindeer Antlers", color = rgb(130, 80, 40), event = "christmas", tags = { "brown", "red" } }),
			item({ id = "acc_earmuffs", name = "Fluffy Earmuffs", color = rgb(255, 255, 255), accent = rgb(110, 170, 255), price = 50, event = "christmas", tags = { "white", "blue" } }),
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
	{ id = "halloween", name = "Halloween Party 🎃", tags = { "orange", "dark", "purple", "green" }, color = rgb(245, 130, 30), event = "halloween" },
	{ id = "thanksgiving", name = "Harvest Festival 🍂", tags = { "orange", "brown", "gold", "red" }, color = rgb(200, 110, 40), event = "thanksgiving" },
	{ id = "christmas", name = "Christmas Party 🎄", tags = { "red", "green", "white", "sparkle" }, color = rgb(200, 30, 40), event = "christmas" },
} :: { Theme }

-- Day-7 prizes of the daily gift calendar, given in this order
Catalog.GiftItems = { "acc_goldbow", "acc_rainbowband", "acc_pearls" }

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
		outfitColor = "oc_none",
		nailColor = "nail_none",
		nailArt = "art_none",
		outfitPattern = "pat_none",
		gems = "gem_none",
		accessory = "acc_none",
	}
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
