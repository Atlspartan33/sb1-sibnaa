-- Real clothes, the catwalk walk and the poses only work on R15 (jointed) avatars. If the game's
-- Avatar Settings ever let someone in with an old blocky R6 avatar, rebuild them as R15 from their
-- own look (their own skin, body, hair and clothes) the moment they spawn.

local Players = game:GetService("Players")

local R15Guard = {}

local function upgrade(player: Player, character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
	if not humanoid or not humanoid:IsA("Humanoid") or humanoid.RigType ~= Enum.HumanoidRigType.R6 then
		return
	end
	local ok, err = pcall(function()
		local description = humanoid:GetAppliedDescription()
		local root = character:FindFirstChild("HumanoidRootPart")
		local where = if root and root:IsA("BasePart") then root.CFrame else nil
		local model = Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
		model.Name = player.Name
		if where then
			model:PivotTo(where)
		end
		player.Character = model
		model.Parent = workspace
		character:Destroy()
	end)
	if not ok then
		warn("[GlowUp] Couldn't rebuild an R6 avatar as R15:", err)
	end
end

function R15Guard.init()
	local function watch(player: Player)
		player.CharacterAdded:Connect(function(character)
			upgrade(player, character)
		end)
		if player.Character then
			task.spawn(upgrade, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
end

return R15Guard
