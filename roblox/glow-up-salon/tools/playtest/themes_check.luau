-- Every theme should be winnable with free items: checks each styling category has a free match.
local E = require("./engine")
local W = require("./world")
W.loadProject(require("./project"))
local ctx = W.newContext("check", false, nil)
local Catalog
E.runAs(ctx, function()
	Catalog = W.require(ctx, W.game:GetService("ReplicatedStorage").Shared.Catalog)
end)
local gaps = 0
for _, theme in Catalog.Themes do
	for _, key in { "hairColor", "eyeshadow", "lipstick", "outfit", "accessory" } do
		local found = {}
		for _, it in Catalog.categoryByKey[key].items do
			local free = not it.hidden and not it.pass and not it.level and not it.gift and it.price <= 0
			local inSeason = it.event == nil or it.event == theme.event
			if free and inSeason and Catalog.matchesTheme(it, theme) then
				table.insert(found, it.name)
			end
		end
		if #found == 0 then
			gaps += 1
			print("NO FREE MATCH", theme.id, key)
		end
	end
end
local ids = {}
for id in Catalog.byId do table.insert(ids, id) end
print("items", #ids, "themes", #Catalog.Themes, "gaps", gaps)
