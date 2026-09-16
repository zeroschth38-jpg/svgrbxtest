local Players    = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local Player    = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Targets = {
	Vector3.new(-2326, 163, -1412),
	Vector3.new(-2271, 148, -1298),
	Vector3.new(-2171, 168, -914),
	Vector3.new(-2044, 167, -429),
	Vector3.new(-1971, 157, 59),
	Vector3.new(-1831, 164, 168),
	Vector3.new(-1681, 184, 879),
	Vector3.new(-1520, 179, 1452),
	Vector3.new(-1409, 179, 1846),
	Vector3.new(-1365, 179, 1905),
	Vector3.new(-1364, 172, 1962),
	Vector3.new(-1363, 174, 2068),
	Vector3.new(-1437, 176, 2494),
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
local EventCurrency    = 0

local TotalBlock = 0


local TargetPlaceID = 11987539001
local MAX_SERVER_AGE = 8 * 60 * 60

--// Combat
local REACH_DISTANCE       = 5
local GOBLIN_REACH_DISTANCE = 7
local JUMP_HEIGHT          = 3
local BLOCK_COOLDOWN       = 3

local OBSTACLE_DISTANCE    = 8
local SIDE_DISTANCE        = 6
local STUCK_DISTANCE       = 1.5
local STUCK_TIME           = 1.2

local ClosestTarget = nil
local LastMovePosition = nil
local StuckSince = 0
local AvoidDirection = 1

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

	currentTarget    = 1
	ClosestTarget    = nil
	LastMovePosition = nil
	StuckSince       = 0
	AvoidDirection   = 1

	task.delay(0.5, function()
		Equipped = false
	end)

	updateCharacter()
end)

--// UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoFarmUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

local Panel = Instance.new("Frame")
Panel.Name = "Panel"
Panel.Size = UDim2.new(0.25, 0, 0.40, 0)
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
Padding.PaddingTop    = UDim.new(0.07, 0)
Padding.PaddingBottom = UDim.new(0.07, 0)
Padding.PaddingLeft   = UDim.new(0.07, 0)
Padding.PaddingRight  = UDim.new(0.07, 0)
Padding.Parent = Panel

local Layout = Instance.new("UIListLayout")
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Padding = UDim.new(0, 0)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Layout.VerticalAlignment = Enum.VerticalAlignment.Center
Layout.Parent = Panel

--// Title
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.LayoutOrder = 1
Title.Size = UDim2.new(1, 0, 0.16, 0)
Title.BackgroundTransparency = 1
Title.Text = "AUTO FARMING (F8)"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Panel

--// Status
local Status = Instance.new("TextLabel")
Status.Name = "Status"
Status.LayoutOrder = 2
Status.Size = UDim2.new(1, 0, 0.11, 0)
Status.BackgroundTransparency = 1
Status.TextColor3 = Color3.fromRGB(150, 150, 158)
Status.TextSize = 12
Status.Font = Enum.Font.GothamMedium
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Panel

--// Toggle
local Toggle = Instance.new("TextButton")
Toggle.Name = "Toggle"
Toggle.LayoutOrder = 3
Toggle.Size = UDim2.new(1, 0, 0.19, 0)
Toggle.BorderSizePixel = 0
Toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
Toggle.TextSize = 13
Toggle.Font = Enum.Font.GothamBold
Toggle.AutoButtonColor = false
Toggle.Parent = Panel

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0.2, 0)
ToggleCorner.Parent = Toggle

--// Place ID
local PlaceIDLabel = Instance.new("TextLabel")
PlaceIDLabel.Name = "PlaceId"
PlaceIDLabel.LayoutOrder = 4
PlaceIDLabel.Size = UDim2.new(1, 0, 0.11, 0)
PlaceIDLabel.BackgroundTransparency = 1
PlaceIDLabel.TextColor3 = Color3.fromRGB(205, 205, 210)
PlaceIDLabel.TextSize = 12
PlaceIDLabel.Font = Enum.Font.GothamMedium
PlaceIDLabel.TextXAlignment = Enum.TextXAlignment.Left
PlaceIDLabel.TextTruncate = Enum.TextTruncate.AtEnd
PlaceIDLabel.Parent = Panel

--// WalkSpeed
local WalkSpeedLabel = Instance.new("TextLabel")
WalkSpeedLabel.Name = "WalkSpeed"
WalkSpeedLabel.LayoutOrder = 5
WalkSpeedLabel.Size = UDim2.new(1, 0, 0.11, 0)
WalkSpeedLabel.BackgroundTransparency = 1
WalkSpeedLabel.Text = "WalkSpeed   0"
WalkSpeedLabel.TextColor3 = Color3.fromRGB(205, 205, 210)
WalkSpeedLabel.TextSize = 12
WalkSpeedLabel.Font = Enum.Font.GothamMedium
WalkSpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
WalkSpeedLabel.TextTruncate = Enum.TextTruncate.AtEnd
WalkSpeedLabel.Parent = Panel

--// Position
local PositionLabel = Instance.new("TextLabel")
PositionLabel.Name = "Position"
PositionLabel.LayoutOrder = 6
PositionLabel.Size = UDim2.new(1, 0, 0.11, 0)
PositionLabel.BackgroundTransparency = 1
PositionLabel.TextColor3 = Color3.fromRGB(205, 205, 210)
PositionLabel.TextSize = 12
PositionLabel.Font = Enum.Font.GothamMedium
PositionLabel.TextXAlignment = Enum.TextXAlignment.Left
PositionLabel.TextTruncate = Enum.TextTruncate.AtEnd
PositionLabel.Parent = Panel

--// Event Currency
local EventCurrencyLabel = Instance.new("TextLabel")
EventCurrencyLabel.Name = "EventCurrency"
EventCurrencyLabel.LayoutOrder = 7
EventCurrencyLabel.Size = UDim2.new(1, 0, 0.11, 0)
EventCurrencyLabel.BackgroundTransparency = 1
EventCurrencyLabel.Text = "Event Currency   0"
EventCurrencyLabel.TextColor3 = Color3.fromRGB(205, 205, 210)
EventCurrencyLabel.TextSize = 12
EventCurrencyLabel.Font = Enum.Font.GothamMedium
EventCurrencyLabel.TextXAlignment = Enum.TextXAlignment.Left
EventCurrencyLabel.TextTruncate = Enum.TextTruncate.AtEnd
EventCurrencyLabel.Parent = Panel

--// Server Age
local ServerAgeLabel = Instance.new("TextLabel")
ServerAgeLabel.Name = "ServerAge"
ServerAgeLabel.LayoutOrder = 8
ServerAgeLabel.Size = UDim2.new(1, 0, 0.11, 0)
ServerAgeLabel.BackgroundTransparency = 1
ServerAgeLabel.Text = "Server Age   00:00:00"
ServerAgeLabel.TextColor3 = Color3.fromRGB(205, 205, 210)
ServerAgeLabel.TextSize = 12
ServerAgeLabel.Font = Enum.Font.GothamMedium
ServerAgeLabel.TextXAlignment = Enum.TextXAlignment.Left
ServerAgeLabel.TextTruncate = Enum.TextTruncate.AtEnd
ServerAgeLabel.Parent = Panel

--// GUI Toggle
local GUIToggle = Instance.new("TextButton")
GUIToggle.Name = "GUIToggle"
GUIToggle.Size = UDim2.new(0, 100, 0, 32)
GUIToggle.Position = UDim2.new(1, -110, 0, 10)
GUIToggle.BackgroundColor3 = Color3.fromRGB(42, 42, 48)
GUIToggle.BorderSizePixel = 0
GUIToggle.Text = "HIDE GUI"
GUIToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
GUIToggle.TextSize = 12
GUIToggle.Font = Enum.Font.GothamBold
GUIToggle.AutoButtonColor = true
GUIToggle.Parent = ScreenGui

local GUIToggleCorner = Instance.new("UICorner")
GUIToggleCorner.CornerRadius = UDim.new(0, 6)
GUIToggleCorner.Parent = GUIToggle

local GUIVisible = true

GUIToggle.Activated:Connect(function()
	GUIVisible = not GUIVisible

	Panel.Visible = GUIVisible

	if GUIVisible then
		GUIToggle.Text = "HIDE GUI"
	else
		GUIToggle.Text = "SHOW GUI"
	end
end)

--// UI Update
local function updateButton()
	if Enabled then
		Toggle.Text = "●  AUTO FARMING  •  ENABLED"
		Toggle.BackgroundColor3 = Color3.fromRGB(42, 95, 68)
		Status.Text = "Farming system is active"
	else
		Toggle.Text = "●  AUTO FARMING  •  DISABLED"
		Toggle.BackgroundColor3 = Color3.fromRGB(75, 43, 43)
		Status.Text = "Farming system is paused"
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

local function updateEventCurrency()
	local PlayerStats = Player:FindFirstChild("PlayerStats")
	if not PlayerStats then
		EventCurrency = 0
		EventCurrencyLabel.Text = "Event Currency   0"
		return
	end
	local Inventory = PlayerStats:FindFirstChild("Inventory")

	if not Inventory then
		EventCurrency = 0
		EventCurrencyLabel.Text = "Event Currency   0"
		return
	end

	local InventoryValue = Inventory.Value

	if InventoryValue == LastInventory then
		return
	end

	LastInventory = InventoryValue

	local _, Amount = GetItem(InventoryValue, TargetCurrency)

	EventCurrency = Amount
	EventCurrencyLabel.Text = "Event Currency   " .. EventCurrency
end

local function updateServerAge()
	local ServerAge = math.floor(workspace.DistributedGameTime)

	local Hours   = math.floor(ServerAge / 3600)
	local Minutes = math.floor((ServerAge % 3600) / 60)
	local Seconds = ServerAge % 60

	ServerAgeLabel.Text = string.format(
		"Server Age   %02d:%02d:%02d",
		Hours,
		Minutes,
		Seconds
	)
end

local function updatePosition()
	if RootPart then
		local Position = RootPart.Position

		PositionLabel.Text = string.format(
			"Position XYZ   %.1f, %.1f, %.1f",
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
local function TeleportToPlace(placeId: number?)
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

local function GetClosestGoblin()
	local MobFolder = workspace:FindFirstChild("Mobs")

	if not MobFolder or not RootPart then
		return nil
	end

	local ClosestMob = nil
	local ClosestDistance = math.huge

	for _, mob in MobFolder:GetChildren() do
		if not mob:IsA("Model") then
			continue
		end

		local Config = mob:FindFirstChild("Config")
		if not Config then
			continue
		end

		local MobHumanoid = mob:FindFirstChildOfClass("Humanoid")
		local MobRoot = mob:FindFirstChild("HumanoidRootPart")

		if not MobHumanoid or not MobRoot then
			continue
		end

		if MobHumanoid.Health <= 0 then
			continue
		end

		if not Config:FindFirstChild("Entity") then
			continue
		end
		if Config.Entity.Value == "Goblin" then
			continue
		end

		local Distance = (MobRoot.Position - RootPart.Position).Magnitude

		if Distance < ClosestDistance then
			ClosestDistance = Distance
			ClosestMob = mob
		end
	end

	ClosestTarget = ClosestMob

	return ClosestMob
end

local RaycastParams = RaycastParams.new()
RaycastParams.FilterType = Enum.RaycastFilterType.Exclude

local function GetAvoidanceDirection(TargetPosition)
	if not RootPart then
		return nil
	end

	RaycastParams.FilterDescendantsInstances = {
		Character,
		ClosestTarget
	}

	local Origin = RootPart.Position + Vector3.new(0, 2, 0)

	local TargetDirection = TargetPosition - RootPart.Position
	TargetDirection = Vector3.new(TargetDirection.X, 0, TargetDirection.Z)

	if TargetDirection.Magnitude <= 0.01 then
		return nil
	end

	TargetDirection = TargetDirection.Unit

	local ForwardResult = workspace:Raycast(
		Origin,
		TargetDirection * OBSTACLE_DISTANCE,
		RaycastParams
	)

	if not ForwardResult then
		return TargetDirection
	end

	local Right = Vector3.new(-TargetDirection.Z, 0, TargetDirection.X)
	local Left = -Right

	local RightResult = workspace:Raycast(
		Origin,
		Right * SIDE_DISTANCE,
		RaycastParams
	)

	local LeftResult = workspace:Raycast(
		Origin,
		Left * SIDE_DISTANCE,
		RaycastParams
	)

	if not RightResult and not LeftResult then
		if AvoidDirection > 0 then
			return (TargetDirection + Right * 0.9).Unit
		else
			return (TargetDirection + Left * 0.9).Unit
		end
	end

	if not RightResult then
		AvoidDirection = 1
		return (TargetDirection + Right * 0.9).Unit
	end

	if not LeftResult then
		AvoidDirection = -1
		return (TargetDirection + Left * 0.9).Unit
	end

	local RightDistance = SIDE_DISTANCE
	local LeftDistance = SIDE_DISTANCE

	if RightResult then
		RightDistance = RightResult.Distance
	end

	if LeftResult then
		LeftDistance = LeftResult.Distance
	end

	if RightDistance > LeftDistance then
		AvoidDirection = 1
		return Right
	else
		AvoidDirection = -1
		return Left
	end
end

local function CheckStuck()
	if not RootPart then
		return false
	end

	local CurrentPosition = RootPart.Position

	if not LastMovePosition then
		LastMovePosition = CurrentPosition
		StuckSince = os.clock()
		return false
	end

	local DistanceMoved = (CurrentPosition - LastMovePosition).Magnitude

	if DistanceMoved < STUCK_DISTANCE then
		if os.clock() - StuckSince >= STUCK_TIME then
			AvoidDirection *= -1
			StuckSince = os.clock()

			return true
		end
	else
		LastMovePosition = CurrentPosition
		StuckSince = os.clock()
	end

	return false
end

local function MoveToGoblin(Goblin)
	if not Goblin or not RootPart then
		return
	end

	local MobHumanoid = Goblin:FindFirstChildOfClass("Humanoid")
	local MobRoot = Goblin:FindFirstChild("HumanoidRootPart")

	if not MobHumanoid or not MobRoot or MobHumanoid.Health <= 0 then
		ClosestTarget = nil
		return
	end

	local TargetPosition = MobRoot.Position

	if (RootPart.Position - TargetPosition).Magnitude <= GOBLIN_REACH_DISTANCE then
		Humanoid:Move(Vector3.zero)
		return
	end

	local MoveDirection = GetAvoidanceDirection(TargetPosition)

	if not MoveDirection then
		return
	end

	CheckStuck()

	Humanoid:Move(MoveDirection, false)
end

--// Position Update
RunService.RenderStepped:Connect(function()
	updatePosition()
end)

--// Movement + Block
RunService.Heartbeat:Connect(function()
	if game.PlaceId ~= TargetPlaceID then
		Enabled = false
		updateButton()
		return
	end

	if not Humanoid or not RootPart then
		updateCharacter()
		return
	end

	if Humanoid.Health <= 0 then
		return
	end

	updateServerAge()
	updateEventCurrency()
	WalkSpeedLabel.Text = "WalkSpeed   " .. Humanoid.WalkSpeed

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

	if workspace.DistributedGameTime >= MAX_SERVER_AGE then
		TeleportToPlace()
		return
	end

	--// Movement
	local target = Targets[currentTarget]

	if currentTarget < #Targets then
		if (RootPart.Position - target).Magnitude <= REACH_DISTANCE then
			currentTarget += 1
			target = Targets[currentTarget]
		end
	else
		if not ClosestTarget then
			GetClosestGoblin()
		end

		local GoblinHumanoid = ClosestTarget and ClosestTarget:FindFirstChildOfClass("Humanoid")
		local GoblinRoot = ClosestTarget and ClosestTarget:FindFirstChild("HumanoidRootPart")

		if not ClosestTarget
			or not GoblinHumanoid
			or not GoblinRoot
			or GoblinHumanoid.Health <= 0
			or not GoblinRoot:IsDescendantOf(workspace)
		then
			ClosestTarget = GetClosestGoblin()
		end

		if ClosestTarget then
			MoveToGoblin(ClosestTarget)
		end

		target = nil
	end

	--// Jump
	if currentTarget < #Targets then
		local heightDifference = target.Y - RootPart.Position.Y

		if heightDifference >= JUMP_HEIGHT
			and Humanoid.FloorMaterial ~= Enum.Material.Air
			and Humanoid:GetState() ~= Enum.HumanoidStateType.Jumping
		then
			Humanoid.Jump = true
			Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
    InputBindableFunction:Invoke("InteractButton", Enum.UserInputState.Begin)
	end

	if currentTarget == #Targets then
		local InputBindableFunction = PlayerGui:FindFirstChild("InputBindableFunction", true) :: BindableFunction

		if InputBindableFunction then
			if not Equipped then
				InputBindableFunction:Invoke("EquipButton", Enum.UserInputState.Begin)
				Equipped = true
			end

			if ClosestTarget then
				local MobHumanoid = ClosestTarget:FindFirstChildOfClass("Humanoid")
				local MobRoot = ClosestTarget:FindFirstChild("HumanoidRootPart")

				if MobHumanoid and MobRoot and MobHumanoid.Health > 0 then
					local Distance = (RootPart.Position - MobRoot.Position).Magnitude

					if Distance <= GOBLIN_REACH_DISTANCE then
						if os.clock() - LastAttack >= AttackInterval then
							InputBindableFunction:Invoke("AttackButton", Enum.UserInputState.Begin)
							InputBindableFunction:Invoke("SkillButton", Enum.UserInputState.Begin)

							LastAttack = os.clock()
						end
					end
				end
			end
		end
	end


	Humanoid.WalkSpeed = 40
	Humanoid:MoveTo(target)
end)
