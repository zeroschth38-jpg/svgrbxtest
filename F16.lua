local Players               = game:GetService("Players")
local Replicated             = game:GetService("ReplicatedStorage")
local StarterGui             = game:GetService("StarterGui")
local RunService              = game:GetService("RunService")
local UserInputService        = game:GetService("UserInputService")
local MarketplaceService      = game:GetService("MarketplaceService")

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
	Vector3.new(-1654, 174, 2619),
	Vector3.new(-1792, 175, 2769),
}

local VERSION = "v0.97"

--// Farm Area
local FARM_CENTER = Vector3.new(-1715, 173, 2798)
local FARM_RADIUS = 200

--// Farm Deadzone
local FARM_DEADZONE_CENTER = Vector3.new(-1681, 173, 2821)
local FARM_DEADZONE_RADIUS = 30

local Character
local Humanoid
local RootPart

local CURRENT_WAYPOINT_TARGET = 1
local MAX_SERVER_AGE          = 8 * 60 * 60

--// Combat
local TARGET_ENTITY_PRIORITY = {
	[1] = "Goblin",
	[2] = "Leader Goblin",
}

local ClosestTarget = nil

local REACH_DISTANCE        = 5
local GOBLIN_REACH_DISTANCE = 8
local JUMP_HEIGHT           = 3
local BLOCK_COOLDOWN        = 3
local DEATH_COUNT           = 0

--// Retreat
local RETREAT_DISTANCE   = 30
local RETREAT_DIRECTIONS = 16
local RETREATING         = false

--// Player Combat
local ATTACK_INTERVAL  = 0.2
local LAST_ATTACK_TIME = 0
local SKILL_INTERVAL   = 3
local LAST_SKILL_TIME  = 0

--// Potion Consume
local CONSUME_INTERVAL  = 10
local LAST_CONSUME_TIME = 0

--// Interaction
local INTERACTION_INTERVAL  = 0.5
local LAST_INTERACTION_TIME = 0

--// InputBindableFunction
local InputBindableFunction = nil
local BlockValue            = nil

local Enabled       = true
local Equipped      = false
local TargetCurrency = "Golden Shell"
local LastInventory  = nil
local EventCurrency  = 0

local TargetPlaceID = 11987539001

local BlockCache   = {}
local BlockEnabled = true

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

	task.defer(function()
		if not Humanoid then
			return
		end

		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	end)
end

updateCharacter()

Player.CharacterAdded:Connect(function()
	task.wait()

	DEATH_COUNT += 1
	CURRENT_WAYPOINT_TARGET = 1
	ClosestTarget = nil
	InputBindableFunction = nil
	BlockValue = nil
	Equipped = false

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
ScreenGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
ScreenGui.Parent = PlayerGui

if game.PlaceId == TargetPlaceID then
	ScreenGui.DisplayOrder = 1
end

--// Theme
local UI_PANEL   = Color3.fromRGB(22, 23, 29)
local UI_SURFACE = Color3.fromRGB(29, 31, 38)
local UI_HOVER   = Color3.fromRGB(38, 40, 48)
local UI_BORDER  = Color3.fromRGB(55, 58, 68)
local UI_TEXT    = Color3.fromRGB(238, 239, 244)
local UI_MUTED   = Color3.fromRGB(145, 149, 162)
local UI_ACCENT  = Color3.fromRGB(112, 126, 255)

local Panel = Instance.new("Frame")
Panel.Name = "Panel"
Panel.AnchorPoint = Vector2.new(1, 0.5)
Panel.Size = UDim2.fromScale(0.25, 0.70)
Panel.Position = UDim2.fromScale(0.95, 0.55)
Panel.BackgroundColor3 = UI_PANEL
Panel.BorderSizePixel = 0
Panel.ClipsDescendants = true
Panel.Parent = ScreenGui

local PanelCorner = Instance.new("UICorner")
PanelCorner.CornerRadius = UDim.new(0, 1)
PanelCorner.Parent = Panel

local PanelStroke = Instance.new("UIStroke")
PanelStroke.Color = UI_BORDER
PanelStroke.Thickness = 1
PanelStroke.Transparency = 0.1
PanelStroke.Parent = Panel

--// Header
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.fromScale(1, 0.1346)
Header.BackgroundColor3 = UI_SURFACE
Header.BorderSizePixel = 0
Header.Parent = Panel

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0.25, 0)
HeaderCorner.Parent = Header

local HeaderMask = Instance.new("Frame")
HeaderMask.Size = UDim2.fromScale(1, 0.25)
HeaderMask.Position = UDim2.fromScale(0, 0, 1, -0.25)
HeaderMask.BackgroundColor3 = UI_SURFACE
HeaderMask.BorderSizePixel = 0
HeaderMask.Parent = Header

local Accent = Instance.new("Frame")
Accent.Size = UDim2.fromScale(0.0103, 0.6667)
Accent.Position = UDim2.fromScale(0.0359, 0.1667)
Accent.BackgroundColor3 = UI_ACCENT
Accent.BorderSizePixel = 0
Accent.Parent = Header

local AccentCorner = Instance.new("UICorner")
AccentCorner.CornerRadius = UDim.new(1, 0)
AccentCorner.Parent = Accent

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.fromScale(0.8205, 0.3889)
Title.Position = UDim2.fromScale(0.0769, 0.1528)
Title.BackgroundTransparency = 1
Title.Text = "AUTO FARMING (F16)"
Title.TextColor3 = UI_TEXT
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextTruncate = Enum.TextTruncate.AtEnd
Title.Parent = Header

local PlaceNameLabel = Instance.new("TextLabel")
PlaceNameLabel.Name = "PlaceName"
PlaceNameLabel.Size = UDim2.fromScale(0.8205, 0.25)
PlaceNameLabel.Position = UDim2.fromScale(0.0769, 0.5556)
PlaceNameLabel.BackgroundTransparency = 1
PlaceNameLabel.Text = MarketplaceService:GetProductInfoAsync(TargetPlaceID).Name .. "  •  " .. VERSION
PlaceNameLabel.TextColor3 = UI_MUTED
PlaceNameLabel.TextScaled = true
PlaceNameLabel.Font = Enum.Font.GothamMedium
PlaceNameLabel.TextXAlignment = Enum.TextXAlignment.Left
PlaceNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
PlaceNameLabel.Parent = Header

local DragHint = Instance.new("TextLabel")
DragHint.Size = UDim2.fromScale(0.0821, 0.3889)
DragHint.Position = UDim2.fromScale(0.8897, 0.3056)
DragHint.BackgroundTransparency = 1
DragHint.Text = "⋮⋮"
DragHint.TextColor3 = UI_MUTED
DragHint.TextScaled = true
DragHint.Font = Enum.Font.GothamBold
DragHint.Parent = Header

--// Content
local Content = Instance.new("ScrollingFrame")
Content.Name = "Content"
Content.Size = UDim2.fromScale(0.9385, 0.843)
Content.Position = UDim2.fromScale(0.0308, 0.1458)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.ScrollBarImageColor3 = UI_BORDER
Content.CanvasSize = UDim2.fromScale(0, 0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.ScrollingDirection = Enum.ScrollingDirection.Y
Content.Parent = Panel

local ContentPadding = Instance.new("UIPadding")
ContentPadding.PaddingLeft = UDim.new(0.005, 0)
ContentPadding.PaddingRight = UDim.new(0.005, 0)
ContentPadding.PaddingBottom = UDim.new(0, 0)
ContentPadding.Parent = Content

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Padding = UDim.new(0, 5)
ContentLayout.Parent = Content

--// Main Toggle
local Toggle = Instance.new("TextButton")
Toggle.Name = "Toggle"
Toggle.LayoutOrder = 1
Toggle.Size = UDim2.fromScale(0.9949, 0.0822)
Toggle.BorderSizePixel = 0
Toggle.TextColor3 = UI_TEXT
Toggle.TextScaled = true
Toggle.Font = Enum.Font.GothamBold
Toggle.AutoButtonColor = false
Toggle.Parent = Content

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0.205, 0)
ToggleCorner.Parent = Toggle

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = UI_BORDER
ToggleStroke.Thickness = 1
ToggleStroke.Transparency = 0.3
ToggleStroke.Parent = Toggle

local Status = Instance.new("TextLabel")
Status.Name = "Status"
Status.LayoutOrder = 2
Status.Size = UDim2.fromScale(0.9949, 0.0374)
Status.BackgroundTransparency = 1
Status.TextColor3 = UI_MUTED
Status.TextScaled = true
Status.Font = Enum.Font.GothamMedium
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Content

--// Live Status
local StatsCollapsed = false

local StatsHeader = Instance.new("TextButton")
StatsHeader.Name = "StatsHeader"
StatsHeader.LayoutOrder = 3
StatsHeader.Size = UDim2.fromScale(0.9949, 0.0374)
StatsHeader.BackgroundTransparency = 1
StatsHeader.Text = "LIVE STATUS  ▼"
StatsHeader.TextColor3 = UI_TEXT
StatsHeader.TextScaled = true
StatsHeader.Font = Enum.Font.GothamBold
StatsHeader.TextXAlignment = Enum.TextXAlignment.Left
StatsHeader.AutoButtonColor = false
StatsHeader.Parent = Content

local Stats = Instance.new("Frame")
Stats.Name = "Stats"
Stats.LayoutOrder = 4
Stats.Size = UDim2.fromScale(0.9949, 0.2766)
Stats.BackgroundTransparency = 1
Stats.Parent = Content

local StatsGrid = Instance.new("UIGridLayout")
StatsGrid.CellSize = UDim2.fromScale(0.5, 0.3108)
StatsGrid.CellPadding = UDim2.fromScale(0, 0.005)
StatsGrid.SortOrder = Enum.SortOrder.LayoutOrder
StatsGrid.Parent = Stats

local function UpdateStatsLayout()
	if StatsCollapsed then
		return
	end

	local CardCount = 0

	for _, Child in Stats:GetChildren() do
		if Child:IsA("GuiObject") and Child ~= StatsGrid then
			CardCount += 1
		end
	end

	if CardCount <= 0 then
		Stats.Size = UDim2.fromScale(0.9949, 0)
		return
	end

	local ColumnCount = 2
	local RowCount    = math.ceil(CardCount / ColumnCount)

	local BaseHeight = 0.095
	local PaddingY   = 0.005

	local StatsHeight = (BaseHeight * RowCount) + (PaddingY * (RowCount - 1))

	Stats.Size = UDim2.fromScale(0.9949, StatsHeight)

	local CellHeight = BaseHeight / StatsHeight

	StatsGrid.CellSize    = UDim2.fromScale(0.5, CellHeight)
	StatsGrid.CellPadding = UDim2.fromScale(0, PaddingY / StatsHeight)
end

local function SetStatsCollapsed(Collapsed)
	StatsCollapsed = Collapsed

	if StatsCollapsed then
		StatsHeader.Text = "LIVE STATUS  ▶"
		Stats.Visible = false
	else
		StatsHeader.Text = "LIVE STATUS  ▼"
		Stats.Visible = true
		UpdateStatsLayout()
	end
end

StatsHeader.Activated:Connect(function()
	SetStatsCollapsed(not StatsCollapsed)
end)

local function CreateStat(Name, DefaultText, Order)
	local Card = Instance.new("Frame")
	Card.Name = Name
	Card.LayoutOrder = Order
	Card.BackgroundColor3 = UI_SURFACE
	Card.BorderSizePixel = 0
	Card.Parent = Stats

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0.02, 0)
	Corner.Parent = Card

	local Label = Instance.new("TextLabel")
	Label.Name = "Label"
	Label.Size = UDim2.fromScale(0.9158, 0.2826)
	Label.Position = UDim2.fromScale(0.0421, 0.1087)
	Label.BackgroundTransparency = 1
	Label.Text = Name
	Label.TextColor3 = UI_MUTED
	Label.TextScaled = true
	Label.Font = Enum.Font.GothamMedium
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Card

	local Value = Instance.new("TextLabel")
	Value.Name = "Value"
	Value.Size = UDim2.fromScale(0.9158, 0.4130)
	Value.Position = UDim2.fromScale(0.0421, 0.4348)
	Value.BackgroundTransparency = 1
	Value.Text = DefaultText
	Value.TextColor3 = UI_TEXT
	Value.TextScaled = true
	Value.Font = Enum.Font.GothamBold
	Value.TextXAlignment = Enum.TextXAlignment.Left
	Value.TextTruncate = Enum.TextTruncate.AtEnd
	Value.Parent = Card

	return Value
end

local function neededExp(lvl)
	lvl = lvl-1
	local total = 9
	for i=1,lvl do
		total = total + (6 * (i + 2))
	end
	return total
end

local PlaceIDLabel       = CreateStat("PLACE ID", tostring(game.PlaceId), 1)
local WalkSpeedLabel     = CreateStat("WALKSPEED", "0", 2)
local WayPointLabel      = CreateStat("WAYPOINT", "0/" .. #Targets, 3)
local EventCurrencyLabel = CreateStat("EVENT CURRENCY", "0", 4)
local ServerAgeLabel     = CreateStat("SERVER AGE", "00:00:00", 5)
local PositionLabel      = CreateStat("POSITION", "--", 6)
local DeathLabel         = CreateStat("DEATH", "0", 7)
local ExpLabel           = CreateStat("EXP", "0/0", 8)

UpdateStatsLayout()

Stats.ChildAdded:Connect(function(Child)
	if Child:IsA("GuiObject") and Child ~= StatsGrid then
		task.defer(UpdateStatsLayout)
	end
end)

Stats.ChildRemoved:Connect(function(Child)
	if Child:IsA("GuiObject") and Child ~= StatsGrid then
		task.defer(UpdateStatsLayout)
	end
end)

--// Block Toggle
local BlockToggle = Instance.new("TextButton")
BlockToggle.Name = "BlockToggle"
BlockToggle.LayoutOrder = 5
BlockToggle.Size = UDim2.fromScale(0.9949, 0.0785)
BlockToggle.BorderSizePixel = 0
BlockToggle.TextColor3 = UI_TEXT
BlockToggle.TextScaled = true
BlockToggle.Font = Enum.Font.GothamBold
BlockToggle.AutoButtonColor = false
BlockToggle.Parent = Content

local BlockToggleCorner = Instance.new("UICorner")
BlockToggleCorner.CornerRadius = UDim.new(0.205, 0)
BlockToggleCorner.Parent = BlockToggle

local BlockToggleStroke = Instance.new("UIStroke")
BlockToggleStroke.Color = UI_BORDER
BlockToggleStroke.Thickness = 1
BlockToggleStroke.Transparency = 0.3
BlockToggleStroke.Parent = BlockToggle

--// Enemy Priority
local PriorityHeader = Instance.new("TextLabel")
PriorityHeader.Name = "PriorityHeader"
PriorityHeader.LayoutOrder = 6
PriorityHeader.Size = UDim2.fromScale(0.9949, 0.0374)
PriorityHeader.BackgroundTransparency = 1
PriorityHeader.Text = "ENEMY PRIORITY"
PriorityHeader.TextColor3 = UI_TEXT
PriorityHeader.TextScaled = true
PriorityHeader.Font = Enum.Font.GothamBold
PriorityHeader.TextXAlignment = Enum.TextXAlignment.Left
PriorityHeader.Parent = Content

local PriorityHint = Instance.new("TextLabel")
PriorityHint.Name = "PriorityHint"
PriorityHint.LayoutOrder = 7
PriorityHint.Size = UDim2.fromScale(0.9949, 0.0318)
PriorityHint.BackgroundTransparency = 1
PriorityHint.Text = "▲ / ▼   Change targeting order"
PriorityHint.TextColor3 = UI_MUTED
PriorityHint.TextScaled = true
PriorityHint.Font = Enum.Font.GothamMedium
PriorityHint.TextXAlignment = Enum.TextXAlignment.Left
PriorityHint.Parent = Content

local PriorityRows = {}

local AddEnemyButton
local EnemyPicker
local EnemyPickerList
local EnemyPickerListLayout
local EnemyPickerPadding

local RefreshEnemyPicker

local function IsEntityInPriority(EntityName: string): boolean
	for _, PriorityName in ipairs(TARGET_ENTITY_PRIORITY) do
		if PriorityName == EntityName then
			return true
		end
	end

	return false
end

local function CreatePriorityRow(Index)
	local Row = Instance.new("Frame")
	Row.Name = "Priority" .. Index
	Row.LayoutOrder = 7 + Index
	Row.Size = UDim2.fromScale(0.9949, 0.0822)
	Row.BackgroundColor3 = UI_SURFACE
	Row.BorderSizePixel = 0
	Row.Parent = Content

	local RowCorner = Instance.new("UICorner")
	RowCorner.CornerRadius = UDim.new(0.02, 0)
	RowCorner.Parent = Row

	local NumberLabel = Instance.new("TextLabel")
	NumberLabel.Name = "Number"
	NumberLabel.Size = UDim2.fromScale(0.0872, 1)
	NumberLabel.Position = UDim2.fromScale(0.0205, 0)
	NumberLabel.BackgroundTransparency = 1
	NumberLabel.TextColor3 = UI_ACCENT
	NumberLabel.TextScaled = true
	NumberLabel.Font = Enum.Font.GothamBold
	NumberLabel.TextXAlignment = Enum.TextXAlignment.Center
	NumberLabel.Parent = Row

	local NameLabel = Instance.new("TextLabel")
	NameLabel.Name = "Name"
	NameLabel.Size = UDim2.fromScale(0.5687, 1)
	NameLabel.Position = UDim2.fromScale(0.1231, 0)
	NameLabel.BackgroundTransparency = 1
	NameLabel.TextColor3 = UI_TEXT
	NameLabel.TextSize = 14
	NameLabel.Font = Enum.Font.GothamMedium
	NameLabel.TextXAlignment = Enum.TextXAlignment.Left
	NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	NameLabel.Parent = Row

	local RemoveButton = Instance.new("TextButton")
	RemoveButton.Name = "Remove"
	RemoveButton.Size = UDim2.fromScale(0.0821, 0.6818)
	RemoveButton.Position = UDim2.fromScale(0.708, 0.1591)
	RemoveButton.BackgroundColor3 = UI_HOVER
	RemoveButton.BorderSizePixel = 0
	RemoveButton.Text = "×"
	RemoveButton.TextColor3 = UI_TEXT
	RemoveButton.TextScaled = true
	RemoveButton.Font = Enum.Font.GothamBold
	RemoveButton.AutoButtonColor = true
	RemoveButton.Parent = Row

	local RemoveCorner = Instance.new("UICorner")
	RemoveCorner.CornerRadius = UDim.new(0.159, 0)
	RemoveCorner.Parent = RemoveButton

	local UpButton = Instance.new("TextButton")
	UpButton.Name = "Up"
	UpButton.Size = UDim2.fromScale(0.0821, 0.6818)
	UpButton.Position = UDim2.fromScale(0.8051, 0.1591)
	UpButton.BackgroundColor3 = UI_HOVER
	UpButton.BorderSizePixel = 0
	UpButton.Text = "▲"
	UpButton.TextColor3 = UI_TEXT
	UpButton.TextScaled = true
	UpButton.Font = Enum.Font.GothamBold
	UpButton.AutoButtonColor = true
	UpButton.Parent = Row

	local UpCorner = Instance.new("UICorner")
	UpCorner.CornerRadius = UDim.new(0.159, 0)
	UpCorner.Parent = UpButton

	local DownButton = Instance.new("TextButton")
	DownButton.Name = "Down"
	DownButton.Size = UDim2.fromScale(0.0821, 0.6818)
	DownButton.Position = UDim2.fromScale(0.9026, 0.1591)
	DownButton.BackgroundColor3 = UI_HOVER
	DownButton.BorderSizePixel = 0
	DownButton.Text = "▼"
	DownButton.TextColor3 = UI_TEXT
	DownButton.TextScaled = true
	DownButton.Font = Enum.Font.GothamBold
	DownButton.AutoButtonColor = true
	DownButton.Parent = Row

	local DownCorner = Instance.new("UICorner")
	DownCorner.CornerRadius = UDim.new(0.159, 0)
	DownCorner.Parent = DownButton

	PriorityRows[Index] = {
		Row    = Row,
		Number = NumberLabel,
		Name   = NameLabel,
		Remove = RemoveButton,
		Up     = UpButton,
		Down   = DownButton,
	}

	RemoveButton.Activated:Connect(function()
		if not TARGET_ENTITY_PRIORITY[Index] then
			return
		end

		local WasPickerVisible = EnemyPicker.Visible

		table.remove(TARGET_ENTITY_PRIORITY, Index)

		ClosestTarget = nil

		for _, RowData in PriorityRows do
			RowData.Row:Destroy()
		end

		table.clear(PriorityRows)

		for NewIndex = 1, #TARGET_ENTITY_PRIORITY do
			CreatePriorityRow(NewIndex)
		end

		AddEnemyButton.LayoutOrder = 8 + #TARGET_ENTITY_PRIORITY
		EnemyPicker.LayoutOrder = 9 + #TARGET_ENTITY_PRIORITY

		updatePriorityUI()

		if WasPickerVisible then
			EnemyPicker.Visible = true
			RefreshEnemyPicker()
		end
	end)

	UpButton.Activated:Connect(function()
		if Index <= 1 then
			return
		end

		TARGET_ENTITY_PRIORITY[Index], TARGET_ENTITY_PRIORITY[Index - 1] =
			TARGET_ENTITY_PRIORITY[Index - 1], TARGET_ENTITY_PRIORITY[Index]

		ClosestTarget = nil

		updatePriorityUI()

		if EnemyPicker.Visible then
			RefreshEnemyPicker()
		end
	end)

	DownButton.Activated:Connect(function()
		if Index >= #TARGET_ENTITY_PRIORITY then
			return
		end

		TARGET_ENTITY_PRIORITY[Index], TARGET_ENTITY_PRIORITY[Index + 1] =
			TARGET_ENTITY_PRIORITY[Index + 1], TARGET_ENTITY_PRIORITY[Index]

		ClosestTarget = nil

		updatePriorityUI()

		if EnemyPicker.Visible then
			RefreshEnemyPicker()
		end
	end)
end

function updatePriorityUI()
	for Index, RowData in PriorityRows do
		RowData.Number.Text = tostring(Index)
		RowData.Name.Text = TARGET_ENTITY_PRIORITY[Index] or "--"

		local IsFirst = Index == 1
		local IsLast  = Index == #TARGET_ENTITY_PRIORITY

		RowData.Up.Active = not IsFirst
		RowData.Down.Active = not IsLast

		RowData.Up.TextTransparency = IsFirst and 0.65 or 0
		RowData.Down.TextTransparency = IsLast and 0.65 or 0
	end
end

for Index = 1, #TARGET_ENTITY_PRIORITY do
	CreatePriorityRow(Index)
end

updatePriorityUI()

--// Add Enemy
AddEnemyButton = Instance.new("TextButton")
AddEnemyButton.Name = "AddEnemy"
AddEnemyButton.LayoutOrder = 8 + #TARGET_ENTITY_PRIORITY
AddEnemyButton.Size = UDim2.fromScale(0.9949, 0.0785)
AddEnemyButton.BackgroundColor3 = UI_SURFACE
AddEnemyButton.BorderSizePixel = 0
AddEnemyButton.Text = "+  ADD ENEMY TO PRIORITY"
AddEnemyButton.TextColor3 = UI_TEXT
AddEnemyButton.TextScaled = true
AddEnemyButton.Font = Enum.Font.GothamBold
AddEnemyButton.AutoButtonColor = true
AddEnemyButton.Parent = Content

local AddEnemyCorner = Instance.new("UICorner")
AddEnemyCorner.CornerRadius = UDim.new(0.205, 0)
AddEnemyCorner.Parent = AddEnemyButton

local AddEnemyStroke = Instance.new("UIStroke")
AddEnemyStroke.Color = UI_BORDER
AddEnemyStroke.Thickness = 1
AddEnemyStroke.Transparency = 0.3
AddEnemyStroke.Parent = AddEnemyButton

--// Enemy Picker
EnemyPicker = Instance.new("Frame")
EnemyPicker.Name = "EnemyPicker"
EnemyPicker.LayoutOrder = 9 + #TARGET_ENTITY_PRIORITY
EnemyPicker.Size = UDim2.fromScale(0.9949, 0)
EnemyPicker.BackgroundColor3 = UI_SURFACE
EnemyPicker.BorderSizePixel = 0
EnemyPicker.Visible = false
EnemyPicker.ClipsDescendants = true
EnemyPicker.Parent = Content

local EnemyPickerCorner = Instance.new("UICorner")
EnemyPickerCorner.CornerRadius = UDim.new(0.02, 0)
EnemyPickerCorner.Parent = EnemyPicker

local EnemyPickerStroke = Instance.new("UIStroke")
EnemyPickerStroke.Color = UI_BORDER
EnemyPickerStroke.Thickness = 1
EnemyPickerStroke.Transparency = 0.2
EnemyPickerStroke.Parent = EnemyPicker

EnemyPickerList = Instance.new("Frame")
EnemyPickerList.Name = "List"
EnemyPickerList.Size = UDim2.fromScale(0.958, 1)
EnemyPickerList.Position = UDim2.fromScale(0.021, 0)
EnemyPickerList.BackgroundTransparency = 1
EnemyPickerList.BorderSizePixel = 0
EnemyPickerList.Parent = EnemyPicker

EnemyPickerListLayout = Instance.new("UIListLayout")
EnemyPickerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
EnemyPickerListLayout.FillDirection = Enum.FillDirection.Vertical
EnemyPickerListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
EnemyPickerListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
EnemyPickerListLayout.Padding = UDim.new(0, 5)
EnemyPickerListLayout.Parent = EnemyPickerList

EnemyPickerPadding = Instance.new("UIPadding")
EnemyPickerPadding.PaddingTop = UDim.new(0, 15)
EnemyPickerPadding.PaddingBottom = UDim.new(0, 15)
EnemyPickerPadding.PaddingLeft = UDim.new(0, 5)
EnemyPickerPadding.PaddingRight = UDim.new(0, 5)
EnemyPickerPadding.Parent = EnemyPicker

--// Detected Entity List
local DetectedEntities = {}

local function GetDetectedEnemyEntities()
	local MobFolder = workspace:FindFirstChild("Mobs")

	if not MobFolder then
		return {}
	end

	local EntitySet = {}

	for _, Mob in MobFolder:GetChildren() do
		if not Mob:IsA("Model") then
			continue
		end

		local Config = Mob:FindFirstChild("Config")

		if not Config then
			continue
		end

		local Entity = Config:FindFirstChild("Entity")

		if not Entity then
			continue
		end

		if typeof(Entity.Value) ~= "string" then
			continue
		end

		if Entity.Value == "" then
			continue
		end

		EntitySet[Entity.Value] = true
	end

	local Result = {}

	for EntityName in EntitySet do
		table.insert(Result, EntityName)
	end

	table.sort(Result, function(A, B)
		local APriority = table.find(TARGET_ENTITY_PRIORITY, A)
		local BPriority = table.find(TARGET_ENTITY_PRIORITY, B)

		if APriority and BPriority then
			return APriority < BPriority
		end

		if APriority then
			return true
		end

		if BPriority then
			return false
		end

		return A < B
	end)

	return Result
end

--// Auto Scale Enemy Picker

local function UpdateEnemyPickerLayout()
	local Rows = {}

	for _, Child in EnemyPickerList:GetChildren() do
		if Child:IsA("GuiObject") then
			table.insert(Rows, Child)
		end
	end

	local Count = #Rows

	if Count == 0 then
		EnemyPicker.Size = UDim2.fromScale(0.9949, 0)
		return
	end

	local RowHeight = 1 / Count

	EnemyPicker.Size     = UDim2.fromScale(0.9949, Count * 0.0822)
	EnemyPickerList.Size = UDim2.fromScale(0.958, 1.05)

	for Index, Row in Rows do
		Row.Size     = UDim2.fromScale(1, RowHeight)
		Row.Position = UDim2.fromScale(0, (Index - 1) * RowHeight)
	end
end

local function ClearEnemyPicker()
	for _, Child in EnemyPickerList:GetChildren() do
		if Child:IsA("GuiObject") and Child ~= EnemyPickerListLayout then
			Child:Destroy()
		end
	end
end

local function CreateEnemyPickerRow(EntityName, Index)
	local Row = Instance.new("TextButton")
	Row.Name = "Enemy_" .. EntityName
	Row.LayoutOrder = Index
	Row.Size = UDim2.fromScale(1, 0.0822)
	Row.BackgroundColor3 = UI_PANEL
	Row.BorderSizePixel = 0
	Row.Text = ""
	Row.AutoButtonColor = false
	Row.Parent = EnemyPickerList

	local RowCorner = Instance.new("UICorner")
	RowCorner.CornerRadius = UDim.new(0.02, 0)
	RowCorner.Parent = Row

	local NameLabel = Instance.new("TextLabel")
	NameLabel.Name = "Name"
	NameLabel.Size = UDim2.fromScale(0.68, 1)
	NameLabel.Position = UDim2.fromScale(0.025, 0)
	NameLabel.BackgroundTransparency = 1
	NameLabel.Text = EntityName
	NameLabel.TextColor3 = UI_TEXT
	NameLabel.TextScaled = false
	NameLabel.TextSize = 14
	NameLabel.Font = Enum.Font.GothamMedium
	NameLabel.TextXAlignment = Enum.TextXAlignment.Left
	NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	NameLabel.Parent = Row

	local IsPriority = IsEntityInPriority(EntityName)

	local ActionLabel = Instance.new("TextLabel")
	ActionLabel.Name = "Action"
	ActionLabel.Size = UDim2.fromScale(0.265, 1)
	ActionLabel.Position = UDim2.fromScale(0.71, 0)
	ActionLabel.BackgroundTransparency = 1
	ActionLabel.Text = IsPriority and "✓  IN PRIORITY" or "+  ADD"
	ActionLabel.TextColor3 = IsPriority and UI_MUTED or UI_ACCENT
	ActionLabel.TextScaled = true
	ActionLabel.Font = Enum.Font.GothamBold
	ActionLabel.TextXAlignment = Enum.TextXAlignment.Right
	ActionLabel.Parent = Row

	Row.MouseEnter:Connect(function()
		Row.BackgroundColor3 = UI_HOVER
	end)

	Row.MouseLeave:Connect(function()
		Row.BackgroundColor3 = UI_PANEL
	end)

	Row.Activated:Connect(function()
		if IsEntityInPriority(EntityName) then
			return
		end

		table.insert(TARGET_ENTITY_PRIORITY, EntityName)

		ClosestTarget = nil

		for _, RowData in PriorityRows do
			RowData.Row:Destroy()
		end

		table.clear(PriorityRows)

		for NewIndex = 1, #TARGET_ENTITY_PRIORITY do
			CreatePriorityRow(NewIndex)
		end

		AddEnemyButton.LayoutOrder = 8 + #TARGET_ENTITY_PRIORITY
		EnemyPicker.LayoutOrder = 9 + #TARGET_ENTITY_PRIORITY

		updatePriorityUI()
		RefreshEnemyPicker()
	end)
end

RefreshEnemyPicker = function()
	if not EnemyPicker.Visible then
		return
	end

	ClearEnemyPicker()

	DetectedEntities = GetDetectedEnemyEntities()

	for Index, EntityName in ipairs(DetectedEntities) do
		CreateEnemyPickerRow(EntityName, Index)
	end

	task.defer(UpdateEnemyPickerLayout)
end

AddEnemyButton.Activated:Connect(function()
	EnemyPicker.Visible = not EnemyPicker.Visible

	if EnemyPicker.Visible then
		RefreshEnemyPicker()
	else
		EnemyPicker.Size = UDim2.fromScale(0.9949, 0)
	end
end)

--// Mob Watcher
local MobConnections       = {}
local MobFolderConnections = {}
local RefreshQueued        = false

local function QueueEnemyPickerRefresh()
	if not EnemyPicker.Visible then
		return
	end

	if RefreshQueued then
		return
	end

	RefreshQueued = true

	task.defer(function()
		RefreshQueued = false

		if EnemyPicker.Visible then
			RefreshEnemyPicker()
		end
	end)
end

local function DisconnectMob(Mob)
	local Connections = MobConnections[Mob]

	if not Connections then
		return
	end

	for _, Connection in Connections do
		Connection:Disconnect()
	end

	MobConnections[Mob] = nil
end

local function WatchMob(Mob)
	if not Mob:IsA("Model") then
		return
	end

	DisconnectMob(Mob)

	local Connections = {}
	MobConnections[Mob] = Connections

	local function WatchConfig(Config)
		if not Config then
			return
		end

		local Entity = Config:FindFirstChild("Entity")

		if Entity and Entity:IsA("StringValue") then
			table.insert(Connections, Entity:GetPropertyChangedSignal("Value"):Connect(function()
				QueueEnemyPickerRefresh()
			end))
		end

		table.insert(Connections, Config.ChildAdded:Connect(function(Child)
			if Child.Name ~= "Entity" then
				return
			end

			if Child:IsA("StringValue") then
				table.insert(Connections, Child:GetPropertyChangedSignal("Value"):Connect(function()
					QueueEnemyPickerRefresh()
				end))
			end

			QueueEnemyPickerRefresh()
		end))

		table.insert(Connections, Config.ChildRemoved:Connect(function(Child)
			if Child.Name == "Entity" then
				QueueEnemyPickerRefresh()
			end
		end))
	end

	local Config = Mob:FindFirstChild("Config")

	if Config then
		WatchConfig(Config)
	end

	table.insert(Connections, Mob.ChildAdded:Connect(function(Child)
		if Child.Name == "Config" then
			WatchConfig(Child)
			QueueEnemyPickerRefresh()
		end
	end))

	table.insert(Connections, Mob.ChildRemoved:Connect(function(Child)
		if Child.Name == "Config" then
			QueueEnemyPickerRefresh()
		end
	end))

	QueueEnemyPickerRefresh()
end

local function WatchMobFolder(MobFolder)
	for _, Connection in MobFolderConnections do
		Connection:Disconnect()
	end

	table.clear(MobFolderConnections)

	for Mob in MobConnections do
		DisconnectMob(Mob)
	end

	for _, Mob in MobFolder:GetChildren() do
		WatchMob(Mob)
	end

	table.insert(MobFolderConnections, MobFolder.ChildAdded:Connect(function(Mob)
		WatchMob(Mob)
		QueueEnemyPickerRefresh()
	end))

	table.insert(MobFolderConnections, MobFolder.ChildRemoved:Connect(function(Mob)
		DisconnectMob(Mob)
		QueueEnemyPickerRefresh()
	end))
end

local ExistingMobFolder = workspace:FindFirstChild("Mobs")

if ExistingMobFolder then
	WatchMobFolder(ExistingMobFolder)
end

workspace.ChildAdded:Connect(function(Child)
	if Child.Name == "Mobs" then
		WatchMobFolder(Child)
		QueueEnemyPickerRefresh()
	end
end)

workspace.ChildRemoved:Connect(function(Child)
	if Child.Name ~= "Mobs" then
		return
	end

	for _, Connection in MobFolderConnections do
		Connection:Disconnect()
	end

	table.clear(MobFolderConnections)

	for Mob in MobConnections do
		DisconnectMob(Mob)
	end

	QueueEnemyPickerRefresh()
end)

--// Toggle Screen GUI
local ToggleScreenGUI = PlayerGui:FindFirstChild("ToggleScreenGUI")

if not ToggleScreenGUI then
	ToggleScreenGUI = Instance.new("ScreenGui")
	ToggleScreenGUI.Name = "ToggleScreenGUI"
	ToggleScreenGUI.IgnoreGuiInset = true
	ToggleScreenGUI.Parent = PlayerGui
end

local ToggleContainer = ToggleScreenGUI:FindFirstChild("ToggleContainer")

if not ToggleContainer then
	ToggleContainer = Instance.new("Frame")
	ToggleContainer.Name = "ToggleContainer"
	ToggleContainer.Size = UDim2.new(1, -4, 0, 48)
	ToggleContainer.Position = UDim2.fromOffset(0, 10)
	ToggleContainer.BackgroundTransparency = 1
	ToggleContainer.Parent = ToggleScreenGUI
end

local ToggleUIListLayout = ToggleContainer:FindFirstChild("UIListLayout")

if not ToggleUIListLayout then
	ToggleUIListLayout = Instance.new("UIListLayout")
	ToggleUIListLayout.Padding = UDim.new(0, 10)
	ToggleUIListLayout.FillDirection = Enum.FillDirection.Horizontal
	ToggleUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ToggleUIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	ToggleUIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	ToggleUIListLayout.Parent = ToggleContainer
end

--// GUI Toggle
local GUIToggle = Instance.new("TextButton")
GUIToggle.Name = "GUIToggle"
GUIToggle.Size = UDim2.new(0, 44, 0, 44)
GUIToggle.BackgroundColor3 = Color3.fromRGB(18, 18, 21)
GUIToggle.BackgroundTransparency = 0.08
GUIToggle.BorderSizePixel = 0
GUIToggle.Text = "≡"
GUIToggle.LayoutOrder = 16
GUIToggle.TextTransparency = 0
GUIToggle.TextColor3 = UI_TEXT
GUIToggle.TextScaled = true
GUIToggle.Font = Enum.Font.Gotham
GUIToggle.AutoButtonColor = true
GUIToggle.Parent = ToggleContainer

local GUIToggleCorner = Instance.new("UICorner")
GUIToggleCorner.CornerRadius = UDim.new(0, 8)
GUIToggleCorner.Parent = GUIToggle

local GUIVisible = true

GUIToggle.Activated:Connect(function()
	GUIVisible = not GUIVisible
	Panel.Visible = GUIVisible
end)

--// Panel Dragging
local Dragging     = false
local DragStart    = nil
local StartPosition = nil

Header.InputBegan:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1
		or Input.UserInputType == Enum.UserInputType.Touch
	then
		Dragging = true
		DragStart = Input.Position
		StartPosition = Panel.Position

		Input.Changed:Connect(function()
			if Input.UserInputState == Enum.UserInputState.End then
				Dragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(Input)
	if not Dragging then
		return
	end

	if Input.UserInputType ~= Enum.UserInputType.MouseMovement
		and Input.UserInputType ~= Enum.UserInputType.Touch
	then
		return
	end

	local Delta = Input.Position - DragStart
	local Camera = workspace.CurrentCamera

	if not Camera then
		return
	end

	local Viewport = Camera.ViewportSize

	local DeltaScaleX = Delta.X / Viewport.X
	local DeltaScaleY = Delta.Y / Viewport.Y

	Panel.Position = UDim2.fromScale(
		StartPosition.X.Scale + DeltaScaleX,
		StartPosition.Y.Scale + DeltaScaleY
	)
end)

--// Block Button
local function updateBlockButton()
	if BlockEnabled then
		BlockToggle.Text = "●  AUTO BLOCKING  •  ENABLED"
		BlockToggle.BackgroundColor3 = Color3.fromRGB(60, 125, 50)
	else
		BlockToggle.Text = "●  AUTO BLOCKING  •  DISABLED"
		BlockToggle.BackgroundColor3 = Color3.fromRGB(255, 65, 65)
	end
end

BlockToggle.Activated:Connect(function()
	BlockEnabled = not BlockEnabled
	updateBlockButton()
end)

updateBlockButton()

--// Farm Button
local function updateButton()
	if Enabled then
		Toggle.Text = "●  AUTO FARMING  •  ENABLED"
		Toggle.BackgroundColor3 = Color3.fromRGB(60, 125, 50)
		Status.Text = "Farming system is active"
	else
		Toggle.Text = "●  AUTO FARMING  •  DISABLED"
		Toggle.BackgroundColor3 = Color3.fromRGB(255, 65, 65)
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
		EventCurrencyLabel.Text = "0"
		return
	end

	local Inventory = PlayerStats:FindFirstChild("Inventory")

	if not Inventory then
		EventCurrency = 0
		EventCurrencyLabel.Text = "0"
		return
	end

	local InventoryValue = Inventory.Value

	if InventoryValue == LastInventory then
		return
	end

	LastInventory = InventoryValue

	local _, Amount = GetItem(InventoryValue, TargetCurrency)

	EventCurrency = Amount
	EventCurrencyLabel.Text = EventCurrency

	local PlayerLvl = PlayerStats:FindFirstChild("Level")
	local PlayerExp = PlayerStats:FindFirstChild("EXP")
	if not PlayerLvl or not PlayerExp then
		return
	end
	ExpLabel.Text = PlayerExp.Value.."/"..neededExp(PlayerLvl.Value)
end

local function updateServerAge()
	local ServerAge = math.floor(workspace.DistributedGameTime)

	local Hours   = math.floor(ServerAge / 3600)
	local Minutes = math.floor((ServerAge % 3600) / 60)
	local Seconds = ServerAge % 60

	ServerAgeLabel.Text = string.format(
		"%02d:%02d:%02d",
		Hours,
		Minutes,
		Seconds
	)
end

local function updatePosition()
	if RootPart then
		local Position = RootPart.Position

		PositionLabel.Text = string.format(
			"%.1f, %.1f, %.1f",
			Position.X,
			Position.Y,
			Position.Z
		)
	else
		PositionLabel.Text = "--"
	end
end

PlaceIDLabel.Text = `{game.PlaceId} {game.PlaceId ~= TargetPlaceID and "(NOT MATCH)" or ""}`

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

--// Farm Area Check
local function IsInsideFarmArea(Position)
	if not Position then
		return false
	end

	local Offset = Position - FARM_CENTER
	local Distance = Vector3.new(Offset.X, 0, Offset.Z).Magnitude

	if Distance > FARM_RADIUS then
		return false
	end

	local DeadzoneOffset   = Position - FARM_DEADZONE_CENTER
	local DeadzoneDistance = Vector3.new(DeadzoneOffset.X, 0, DeadzoneOffset.Z).Magnitude

	if DeadzoneDistance <= FARM_DEADZONE_RADIUS then
		return false
	end

	return true
end

--// Water Check
local WATER_SAMPLE_DISTANCE = 4

local function IsWaterAtPosition(Position, IgnoreModel)
	if not Position then
		return false
	end

	local FilterInstances = {
		Character,
	}

	if IgnoreModel then
		table.insert(FilterInstances, IgnoreModel)
	end

	local RaycastParams = RaycastParams.new()
	RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	RaycastParams.FilterDescendantsInstances = FilterInstances

	local Origin    = Position + Vector3.new(0, 10, 0)
	local Direction = Vector3.new(0, -30, 0)

	local Result = workspace:Raycast(
		Origin,
		Direction,
		RaycastParams
	)

	return Result and Result.Material == Enum.Material.Water
end

local function IsPathThroughWater(TargetPosition)
	if not RootPart then
		return true
	end

	local Origin   = RootPart.Position
	local Offset   = TargetPosition - Origin
	local Distance = Offset.Magnitude

	if Distance <= 0 then
		return IsWaterAtPosition(TargetPosition)
	end

	local Direction = Offset.Unit

	for DistanceTravelled = 0, Distance, WATER_SAMPLE_DISTANCE do
		local Position = Origin + Direction * DistanceTravelled

		if IsWaterAtPosition(Position) then
			return true
		end
	end

	return IsWaterAtPosition(TargetPosition)
end

--// Deadzone Path Check
local DEADZONE_SAMPLE_DISTANCE = 2

local function IsPathThroughDeadzone(TargetPosition)
	if not RootPart or not TargetPosition then
		return false
	end

	local Origin   = RootPart.Position
	local Offset   = TargetPosition - Origin
	local Distance = Offset.Magnitude

	if Distance <= 0 then
		local DeadzoneOffset   = Origin - FARM_DEADZONE_CENTER
		local DeadzoneDistance = Vector3.new(DeadzoneOffset.X, 0, DeadzoneOffset.Z).Magnitude

		return DeadzoneDistance <= FARM_DEADZONE_RADIUS
	end

	local Direction = Offset.Unit

	for DistanceTravelled = 0, Distance, DEADZONE_SAMPLE_DISTANCE do
		local Position = Origin + Direction * DistanceTravelled
		local DeadzoneOffset   = Position - FARM_DEADZONE_CENTER
		local DeadzoneDistance = Vector3.new(DeadzoneOffset.X, 0, DeadzoneOffset.Z).Magnitude

		if DeadzoneDistance <= FARM_DEADZONE_RADIUS then
			return true
		end
	end

	return false
end

--// Line Of Sight
local function CanSeeGoblin(Goblin)
	if not RootPart or not Goblin then
		return false
	end

	local MobRoot = Goblin:FindFirstChild("HumanoidRootPart")

	if not MobRoot then
		return false
	end

	local Origin    = RootPart.Position
	local Direction = MobRoot.Position - Origin

	local RaycastParams = RaycastParams.new()
	RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	RaycastParams.FilterDescendantsInstances = {
		Character,
	}

	local Result = workspace:Raycast(Origin, Direction, RaycastParams)

	if not Result then
		return true
	end

	return Result.Instance:IsDescendantOf(Goblin)
end

--// Closest Visible Goblin
local function GetClosestGoblin()
	local MobFolder = workspace:FindFirstChild("Mobs")

	if not MobFolder or not RootPart then
		return nil
	end

	for _, EntityPriority in TARGET_ENTITY_PRIORITY do
		local ClosestMob      = nil
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
			local MobRoot     = mob:FindFirstChild("HumanoidRootPart")

			if not MobHumanoid or not MobRoot then
				continue
			end

			if MobHumanoid.Health <= 0 then
				continue
			end

			local Entity = Config:FindFirstChild("Entity")

			if not Entity or Entity.Value ~= EntityPriority then
				continue
			end

			local Distance = (MobRoot.Position - RootPart.Position).Magnitude

			if not IsInsideFarmArea(MobRoot.Position) then
				continue
			end

			if IsWaterAtPosition(MobRoot.Position, mob) then
				continue
			end

			if not CanSeeGoblin(mob) or IsPathThroughWater(MobRoot.Position) then
				continue
			end

			if Distance < ClosestDistance then
				ClosestDistance = Distance
				ClosestMob      = mob
			end
		end

		if ClosestMob then
			return ClosestMob
		end
	end

	return nil
end

--// Retreat Obstacle Check
local function IsPathClear(TargetPosition)
	if not RootPart then
		return false
	end

	if IsWaterAtPosition(TargetPosition) then
		return false
	end

	if IsPathThroughWater(TargetPosition) then
		return false
	end

	if IsPathThroughDeadzone(TargetPosition) then
		return false
	end

	local Origin    = RootPart.Position
	local Direction = TargetPosition - Origin

	local RaycastParams = RaycastParams.new()
	RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	RaycastParams.FilterDescendantsInstances = {
		Character,
	}

	local Result = workspace:Raycast(Origin, Direction, RaycastParams)

	return Result == nil
end

--// Get All Living Goblins
local function GetLivingGoblins()
	local MobFolder = workspace:FindFirstChild("Mobs")

	if not MobFolder then
		return {}
	end

	local Goblins = {}

	for _, mob in MobFolder:GetChildren() do
		if not mob:IsA("Model") then
			continue
		end

		local Config      = mob:FindFirstChild("Config")
		local MobHumanoid = mob:FindFirstChildOfClass("Humanoid")
		local MobRoot     = mob:FindFirstChild("HumanoidRootPart")

		if not Config or not MobHumanoid or not MobRoot then
			continue
		end

		local Entity = Config:FindFirstChild("Entity")

		if not Entity then
			continue
		end

		if not IsEntityInPriority(Entity.Value) then
			continue
		end

		if MobHumanoid.Health <= 0 then
			continue
		end

		table.insert(Goblins, mob)
	end

	return Goblins
end

--// Calculate Retreat Position
local RETREAT_DISTANCE   = 30
local RETREAT_DIRECTIONS = 16

local function GetRetreatPosition()
	if not RootPart then
		return nil
	end

	local Goblins = GetLivingGoblins()

	if #Goblins == 0 then
		return nil
	end

	local RetreatDirection = Vector3.zero

	if ClosestTarget
		and ClosestTarget:IsDescendantOf(workspace)
	then
		local TargetHumanoid = ClosestTarget:FindFirstChildOfClass("Humanoid")
		local TargetRoot     = ClosestTarget:FindFirstChild("HumanoidRootPart")

		if TargetHumanoid
			and TargetRoot
			and TargetHumanoid.Health > 0
		then
			local Offset   = RootPart.Position - TargetRoot.Position
			local Distance = Offset.Magnitude

			if Distance > 0 then
				RetreatDirection = Offset.Unit
			end
		end
	end

	if RetreatDirection.Magnitude <= 0 then
		for _, Goblin in Goblins do
			local MobRoot = Goblin:FindFirstChild("HumanoidRootPart")

			if MobRoot then
				local Offset   = RootPart.Position - MobRoot.Position
				local Distance = Offset.Magnitude

				if Distance > 0 then
					RetreatDirection += Offset.Unit / math.max(Distance, 1)
				end
			end
		end

		if RetreatDirection.Magnitude <= 0 then
			return nil
		end

		RetreatDirection = RetreatDirection.Unit
	end

	local BestPosition = nil
	local BestScore    = -math.huge

	for Index = 0, RETREAT_DIRECTIONS - 1 do
		local Angle = (math.pi * 2 / RETREAT_DIRECTIONS) * Index

		local Direction = Vector3.new(
			math.cos(Angle),
			0,
			math.sin(Angle)
		)

		local TargetPosition = RootPart.Position + Direction * RETREAT_DISTANCE

		if not IsInsideFarmArea(TargetPosition) then
			continue
		end

		if not IsPathClear(TargetPosition) then
			continue
		end

		local Score = Direction:Dot(RetreatDirection)

		if Score > BestScore then
			BestScore    = Score
			BestPosition = TargetPosition
		end
	end

	return BestPosition
end

--// Retreat
local function RetreatFromGoblins()
	local RetreatPosition = GetRetreatPosition()

	if RetreatPosition then
		Humanoid:MoveTo(RetreatPosition)
		return
	end

	if RootPart and RetreatDirection.Magnitude > 0 then
		Humanoid:MoveTo(RetreatDirection or Vector3.zero)
	end
end

--// Move To Goblin
local function MoveToGoblin(Goblin)
	if not Goblin or not RootPart then
		return
	end

	local MobHumanoid = Goblin:FindFirstChildOfClass("Humanoid")
	local MobRoot     = Goblin:FindFirstChild("HumanoidRootPart")

	if not MobHumanoid or not MobRoot or MobHumanoid.Health <= 0 then
		ClosestTarget = nil
		return
	end

	if IsWaterAtPosition(MobRoot.Position, Goblin) then
		ClosestTarget = nil
		return
	end

	local TargetPosition = MobRoot.Position

	if not IsInsideFarmArea(TargetPosition) then
		ClosestTarget = nil
		return
	end

	if (RootPart.Position - TargetPosition).Magnitude <= GOBLIN_REACH_DISTANCE then
		Humanoid:Move(Vector3.zero)
		return
	end

	if IsPathThroughWater(TargetPosition) then
		Humanoid:Move(Vector3.zero)
		return
	end

	if IsPathThroughDeadzone(TargetPosition) then
		Humanoid:Move(Vector3.zero)
		return
	end

	Humanoid:MoveTo(TargetPosition)
end

local function DoJump()
	if not Humanoid then
		return
	end

	if Humanoid.FloorMaterial ~= Enum.Material.Air
		and Humanoid:GetState() ~= Enum.HumanoidStateType.Jumping
	then
		Humanoid.Jump = true
		Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end

--// Position Update
RunService.RenderStepped:Connect(function()
	updatePosition()
	if Humanoid and Humanoid.WalkSpeed < 38 then
		Humanoid.WalkSpeed = 38
	end
end)

--// Movement + Block
RunService.Heartbeat:Connect(function()
	local now = os.clock()

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

	WayPointLabel.Text  = CURRENT_WAYPOINT_TARGET .. "/" .. #Targets
	WalkSpeedLabel.Text = Humanoid.WalkSpeed
	DeathLabel.Text     = DEATH_COUNT

	if not Enabled then
		Humanoid:Move(Vector3.zero)
		return
	end

	if not InputBindableFunction then
		InputBindableFunction = PlayerGui:FindFirstChild("InputBindableFunction", true) :: BindableFunction
		return
	end

	local Sword = Character:FindFirstChild("Sword")

	if not Sword or not Sword:FindFirstChild("MainWeld", true) then
		return
	end

	local MainWeld = Sword:FindFirstChild("MainWeld", true)

	--// Emergency Retreat
	if Humanoid.Health <= Humanoid.MaxHealth * 0.4 then
		RETREATING = true
	elseif RETREATING and Humanoid.Health >= Humanoid.MaxHealth * 0.8 then
		RETREATING = false
	end
	
	if RETREATING then
		local UseConsumable = Replicated:FindFirstChild("UseConsumable", true)
		local PlayerStats   = Player:FindFirstChild("PlayerStats")
	
		DoJump()
		RetreatFromGoblins()
	
		if InputBindableFunction
			and (Equipped or (MainWeld.Part1 and MainWeld.Part1.Name ~= "UpperTorso"))
		then
			Equipped = false
			InputBindableFunction:Invoke("EquipButton", Enum.UserInputState.Begin)
			return
		end
	
		if UseConsumable and PlayerStats and not Equipped then
			local LastConsumed = PlayerStats:FindFirstChild("LastConsumed")
	
			if LastConsumed
				and LastConsumed.Value ~= ""
				and now - LAST_CONSUME_TIME >= CONSUME_INTERVAL
			then
				LAST_CONSUME_TIME = now
				UseConsumable:InvokeServer(LastConsumed.Value)
			end
		end
	
		return
	end

	--// Player Check
	if BlockEnabled then
		local HasOtherPlayer   = false
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
	end

	--// Server Age
	if workspace.DistributedGameTime >= MAX_SERVER_AGE then
		TeleportToPlace()
		return
	end

	--// Movement
	local target = Targets[CURRENT_WAYPOINT_TARGET]

	if CURRENT_WAYPOINT_TARGET < #Targets then
		if (RootPart.Position - target).Magnitude <= REACH_DISTANCE then
			CURRENT_WAYPOINT_TARGET += 1
			target = Targets[CURRENT_WAYPOINT_TARGET]
		end

		Humanoid:MoveTo(target)
	else
		if not ClosestTarget then
			ClosestTarget = GetClosestGoblin()
		end

		local GoblinHumanoid = ClosestTarget and ClosestTarget:FindFirstChildOfClass("Humanoid")
		local GoblinRoot     = ClosestTarget and ClosestTarget:FindFirstChild("HumanoidRootPart")

		if ClosestTarget
			and (
				not GoblinHumanoid
					or not GoblinRoot
					or GoblinHumanoid.Health <= 0
					or not GoblinRoot:IsDescendantOf(workspace)
					or not IsInsideFarmArea(GoblinRoot.Position)
					or IsWaterAtPosition(GoblinRoot.Position, ClosestTarget)
			)
		then
			ClosestTarget = GetClosestGoblin()
		end

		if ClosestTarget then
			MoveToGoblin(ClosestTarget)
		end
	end

	--// Jump
	if CURRENT_WAYPOINT_TARGET < #Targets then
		local heightDifference = target.Y - RootPart.Position.Y

		if heightDifference >= JUMP_HEIGHT then
			DoJump()
		end
	end

	--// Swim Recovery
	if Humanoid:GetState() == Enum.HumanoidStateType.Swimming then
		DoJump()
		return
	end

	--// Combat
	if CURRENT_WAYPOINT_TARGET == #Targets then
		if ClosestTarget then
			if not Equipped
				or (MainWeld.Part1 and MainWeld.Part1.Name == "UpperTorso")
			then
				Equipped = true
				InputBindableFunction:Invoke("EquipButton", Enum.UserInputState.Begin)
				return
			end

			local MobHumanoid = ClosestTarget:FindFirstChildOfClass("Humanoid")
			local MobRoot     = ClosestTarget:FindFirstChild("HumanoidRootPart")
			local PlayerOffset = ClosestTarget:FindFirstChild("PlayerOffset", true)

			if MobHumanoid and MobRoot and MobHumanoid.Health > 0 then
				local Distance = (RootPart.Position - MobRoot.Position).Magnitude

				-- if Distance <= GOBLIN_REACH_DISTANCE then
				if Distance <= (PlayerOffset and PlayerOffset.Value + 2 or GOBLIN_REACH_DISTANCE) then
					--// ATTACK
					if now - LAST_ATTACK_TIME >= ATTACK_INTERVAL then
						LAST_ATTACK_TIME = now

						InputBindableFunction:Invoke(
							"AttackButton",
							Enum.UserInputState.Begin
						)
					end

					--// SKILL
					if now - LAST_SKILL_TIME >= SKILL_INTERVAL then
						LAST_SKILL_TIME = now

						InputBindableFunction:Invoke(
							"SkillButton",
							Enum.UserInputState.Begin
						)
					end
				end
			end
		end
	else
		if now - LAST_INTERACTION_TIME >= INTERACTION_INTERVAL then
			LAST_INTERACTION_TIME = now
			InputBindableFunction:Invoke(
				"InteractButton",
				Enum.UserInputState.Begin
			)
		end
	end
end)
