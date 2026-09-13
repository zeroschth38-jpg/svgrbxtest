local Players    = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer

local Targets = {
	Vector3.new(-778, 176, 25),
	Vector3.new(-462, 174, -220),
	Vector3.new(-150, 139, -609),
	Vector3.new(222, 154, -1054),
	Vector3.new(357, 141, -1201),
	Vector3.new(379, 84, -1226),
	Vector3.new(321, 59, -1321),
	Vector3.new(269, 59, -1438),
}

local REACH_DISTANCE = 5
local JUMP_HEIGHT    = 3
local BLOCK_COOLDOWN = 3

local Character
local Humanoid
local RootPart

local currentTarget = 1
local Enabled        = true

local BlockCache = {}

local function updateCharacter()
	Character = Player.Character

	if not Character then
		return
	end

	Humanoid = Character:FindFirstChildOfClass("Humanoid")
	RootPart = Character:FindFirstChild("HumanoidRootPart")
end

updateCharacter()

Player.CharacterAdded:Connect(function()
	task.wait()
	updateCharacter()
end)

--// UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoWalkUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = Player:WaitForChild("PlayerGui")

local Button = Instance.new("TextButton")
Button.Name = "Toggle"
Button.Size = UDim2.new(0.12, 0, 0.06, 0)
Button.Position = UDim2.new(0.86, 0, 0.45, 0)
Button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Button.BorderSizePixel = 0
Button.TextColor3 = Color3.new(1, 1, 1)
Button.TextScaled = true
Button.Font = Enum.Font.GothamBold
Button.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0.15, 0)
Corner.Parent = Button

local function updateButton()
	Button.Text = Enabled and "Enabled" or "Disabled"
end

Button.Activated:Connect(function()
	Enabled = not Enabled
	updateButton()
end)

updateButton()

--// Teleport
local function TeleportToPlace()
	local TeleportService = game:GetService("TeleportService")

	TeleportService:Teleport(game.PlaceId, Player)
end

--// Block
local function isBlocked(userId)
	local success, blockedUserIds = pcall(function()
		return StarterGui:GetCore("GetBlockedUserIds")
	end)

	if not success or not blockedUserIds then
		return false
	end

	for _, blockedUserId in blockedUserIds do
		if blockedUserId == userId then
			return true
		end
	end

	return false
end

local function promptBlockPlayer(plr)
	local userId = plr.UserId

	if BlockCache[userId] then
		return
	end

	if isBlocked(userId) then
		return
	end

	BlockCache[userId] = true

	local success, err = pcall(function()
		StarterGui:SetCore("PromptBlockPlayer", plr)
	end)

	if not success then
		warn("PromptBlockPlayer failed:", err)
		BlockCache[userId] = nil
		return
	end

	task.delay(BLOCK_COOLDOWN, function()
		if isBlocked(userId) then
			BlockCache[userId] = nil
		else
			BlockCache[userId] = nil
		end
	end)
end

--// Movement + Block
RunService.Heartbeat:Connect(function()
	if not Enabled then
		return
	end

	local HasOtherPlayer = false
	local HasBlockedPlayer = false

	for _, plr in Players:GetPlayers() do
		if plr == Player then
			continue
		end

		HasOtherPlayer = true

		if isBlocked(plr.UserId) then
			HasBlockedPlayer = true
			BlockCache[plr.UserId] = nil
			break
		end
	end

	if HasBlockedPlayer then
		TeleportToPlace()
		return
	end

	if HasOtherPlayer then
		for _, plr in Players:GetPlayers() do
			if plr == Player then
				continue
			end

			if not isBlocked(plr.UserId) then
				promptBlockPlayer(plr)
				return
			end
		end
	end

	--// Movement
	if not Humanoid or not RootPart then
		updateCharacter()
		return
	end

	if Humanoid.Health <= 0 then
		return
	end

	local target = Targets[currentTarget]

	if (RootPart.Position - target).Magnitude <= REACH_DISTANCE then
		if currentTarget < #Targets then
			currentTarget += 1
		end

		target = Targets[currentTarget]
	end

	if currentTarget ~= #Targets then
		local heightDifference = target.Y - RootPart.Position.Y

		if heightDifference >= JUMP_HEIGHT
			and Humanoid.FloorMaterial ~= Enum.Material.Air
			and Humanoid:GetState() ~= Enum.HumanoidStateType.Jumping
		then
			Humanoid.Jump = true
			Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end

	Humanoid.WalkSpeed = 32
	Humanoid:MoveTo(target)
end)
