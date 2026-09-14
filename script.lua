local Players    = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local Player    = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

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

local Equipped = false
local AttackInterval = 0.5
local LastAttack = 0
local TargetCurrency  = "Golden Shell"
local LastInventory   = nil
local EventCurrent    = 0

local BlockCache = {}

--// Character
local function updateCharacter()
	Character = Player.Character

	if not Character then
		Humanoid = nil
		RootPart = nil
		return
	end

	Humanoid = Character:FindFirstChildOfClass("Humanoid")
	RootPart = Character:FindFirstChild("HumanoidRootPart")
end

updateCharacter()

Player.CharacterAdded:Connect(function()
	task.wait()
	currentTarget = 1
	task.delay(0.5, function()
		Equipped = false
	end)
	updateCharacter()
end)

--// UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoWalkUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = Player:WaitForChild("PlayerGui")

local Panel = Instance.new("Frame")
Panel.Name = "Panel"
Panel.Size = UDim2.new(0.25, 0, 0.29, 0)
Panel.Position = UDim2.new(0.73, 0, 0.32, 0)
Panel.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
Panel.BorderSizePixel = 0
Panel.Parent = ScreenGui

local PanelCorner = Instance.new("UICorner")
PanelCorner.CornerRadius = UDim.new(0.08, 0)
PanelCorner.Parent = Panel

local PanelStroke = Instance.new("UIStroke")
PanelStroke.Color = Color3.fromRGB(70, 70, 78)
PanelStroke.Thickness = 1
PanelStroke.Transparency = 0.2
PanelStroke.Parent = Panel

local Padding = Instance.new("UIPadding")
Padding.PaddingTop = UDim.new(0.07, 0)
Padding.PaddingBottom = UDim.new(0.07, 0)
Padding.PaddingLeft = UDim.new(0.07, 0)
Padding.PaddingRight = UDim.new(0.07, 0)
Padding.Parent = Panel

--// Title
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0.16, 0)
Title.BackgroundTransparency = 1
Title.Text = "AUTO WALK"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Panel

--// Status
local Status = Instance.new("TextLabel")
Status.Name = "Status"
Status.Size = UDim2.new(1, 0, 0.11, 0)
Status.Position = UDim2.new(0, 0, 0.17, 0)
Status.BackgroundTransparency = 1
Status.TextColor3 = Color3.fromRGB(150, 150, 158)
Status.TextSize = 12
Status.Font = Enum.Font.GothamMedium
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Panel

--// Toggle
local Toggle = Instance.new("TextButton")
Toggle.Name = "Toggle"
Toggle.Size = UDim2.new(1, 0, 0.19, 0)
Toggle.Position = UDim2.new(0, 0, 0.30, 0)
Toggle.BorderSizePixel = 0
Toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
Toggle.TextSize = 13
Toggle.Font = Enum.Font.GothamBold
Toggle.AutoButtonColor = false
Toggle.Parent = Panel

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0.2, 0)
ToggleCorner.Parent = Toggle

--// Position
local PositionLabel = Instance.new("TextLabel")
PositionLabel.Name = "Position"
PositionLabel.Size = UDim2.new(1, 0, 0.14, 0)
PositionLabel.Position = UDim2.new(0, 0, 0.53, 0)
PositionLabel.BackgroundTransparency = 1
PositionLabel.TextColor3 = Color3.fromRGB(205, 205, 210)
PositionLabel.TextSize = 12
PositionLabel.Font = Enum.Font.GothamMedium
PositionLabel.TextXAlignment = Enum.TextXAlignment.Left
PositionLabel.TextTruncate = Enum.TextTruncate.AtEnd
PositionLabel.Parent = Panel

--// Place ID
local PlaceIDLabel = Instance.new("TextLabel")
PlaceIDLabel.Name = "PlaceId"
PlaceIDLabel.Size = UDim2.new(1, 0, 0.14, 0)
PlaceIDLabel.Position = UDim2.new(0, 0, 0.69, 0)
PlaceIDLabel.BackgroundTransparency = 1
PlaceIDLabel.TextColor3 = Color3.fromRGB(205, 205, 210)
PlaceIDLabel.TextSize = 12
PlaceIDLabel.Font = Enum.Font.GothamMedium
PlaceIDLabel.TextXAlignment = Enum.TextXAlignment.Left
PlaceIDLabel.TextTruncate = Enum.TextTruncate.AtEnd
PlaceIDLabel.Parent = Panel

--// Event Current
local EventCurrentLabel = Instance.new("TextLabel")
EventCurrentLabel.Name = "EventCurrent"
EventCurrentLabel.Size = UDim2.new(1, 0, 0.12, 0)
EventCurrentLabel.Position = UDim2.new(0, 0, 0.84, 0)
EventCurrentLabel.BackgroundTransparency = 1
EventCurrentLabel.Text = "Event Current   0"
EventCurrentLabel.TextColor3 = Color3.fromRGB(205, 205, 210)
EventCurrentLabel.TextSize = 12
EventCurrentLabel.Font = Enum.Font.GothamMedium
EventCurrentLabel.TextXAlignment = Enum.TextXAlignment.Left
EventCurrentLabel.TextTruncate = Enum.TextTruncate.AtEnd
EventCurrentLabel.Parent = Panel

--// UI Update
local function updateButton()
	if Enabled then
		Toggle.Text = "●  AUTO WALK  •  ENABLED"
		Toggle.BackgroundColor3 = Color3.fromRGB(42, 95, 68)
		Status.Text = "Movement system is active"
	else
		Toggle.Text = "●  AUTO WALK  •  DISABLED"
		Toggle.BackgroundColor3 = Color3.fromRGB(75, 43, 43)
		Status.Text = "Movement system is paused"
	end
end

local function GetItem(String, ItemName)
	for Item in string.gmatch(String, "([^,]+)") do
		local Name, Amount = string.match(Item, "([^|]+)|(.+)")

		if Name == ItemName then
			return Name, tonumber(Amount) or 0
		end
	end

	return ItemName, 0
end

local function updateEventCurrent()
	local PlayerStats = Player:FindFirstChild("PlayerStats")
	if not PlayerStats then
		EventCurrent = 0
		EventCurrentLabel.Text = "Event Current   0"
		return
	end
	local Inventory = PlayerStats:FindFirstChild("Inventory")

	if not Inventory then
		EventCurrent = 0
		EventCurrentLabel.Text = "Event Current   0"
		return
	end

	local InventoryValue = Inventory.Value

	if InventoryValue == LastInventory then
		return
	end

	LastInventory = InventoryValue

	local _, Amount = GetItem(InventoryValue, TargetCurrency)

	EventCurrent = Amount
	EventCurrentLabel.Text = "Event Current   " .. EventCurrent
end

local function updatePosition()
	if RootPart then
		local Position = RootPart.Position

		PositionLabel.Text = string.format(
			"Position   X %.1f   Y %.1f   Z %.1f",
			Position.X,
			Position.Y,
			Position.Z
		)
	else
		PositionLabel.Text = "Position   --"
	end
end

PlaceIDLabel.Text = "Place ID   " .. game.PlaceId

Toggle.Activated:Connect(function()
	Enabled = not Enabled
	updateButton()
end)

updateButton()
updatePosition()

--// Teleport
local function TeleportToPlace(placeId: number)
	local TeleportService = game:GetService("TeleportService")

	TeleportService:Teleport(placeId or game.PlaceId, Player)
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
		BlockCache[userId] = nil
	end)
end

--// Position Update
RunService.RenderStepped:Connect(function()
	updatePosition()
end)

--// Movement + Block
RunService.Heartbeat:Connect(function()
	if not Humanoid or not RootPart then
		updateCharacter()
		return
	end

	if Humanoid.Health <= 0 then
		return
	end

	updateEventCurrent()

	if not Enabled then
		Humanoid:MoveTo(RootPart.Position)
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

	--// อย่างน้อย 1 คนถูก Block → Teleport
	if HasBlockedPlayer then
		TeleportToPlace()
		return
	end

	--// มีผู้เล่นอื่น แต่ยังไม่มีใครถูก Block
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
	local target = Targets[currentTarget]

	if (RootPart.Position - target).Magnitude <= REACH_DISTANCE then
		if currentTarget < #Targets then
			currentTarget += 1
		end

		target = Targets[currentTarget]
	end

	--// Jump
	if currentTarget ~= #Targets then
		local heightDifference = target.Y - RootPart.Position.Y

		if heightDifference >= JUMP_HEIGHT
			and Humanoid.FloorMaterial ~= Enum.Material.Air
			and Humanoid:GetState() ~= Enum.HumanoidStateType.Jumping
		then
			Humanoid.Jump = true
			Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	else
		local InputBindableFunction = PlayerGui:FindFirstChild("InputBindableFunction", true) :: BindableFunction

		if not Equipped then
			InputBindableFunction:Invoke("EquipButton", Enum.UserInputState.Begin)
			Equipped = true
		else
			if os.clock() - LastAttack >= AttackInterval then
				InputBindableFunction:Invoke("AttackButton", Enum.UserInputState.Begin)
				InputBindableFunction:Invoke("SkillButton", Enum.UserInputState.Begin)
				LastAttack = os.clock()
			end
		end
	end

	Humanoid.WalkSpeed = 40
	Humanoid:MoveTo(target)
end)
