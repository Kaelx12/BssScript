-- BSS Auto Farm — GUI Edition
-- Delta Compatible

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local CONFIG = {
    AutoCollect = true,
    AutoConvert = true,
    FarmField = "Sunflower Field",
    CollectRadius = 20,
    WalkSpeed = 65,
    TeleportMode = false,
    ConvertInterval = 30,
    AntiAFK = true,
}

local farming = false
local lastConvert = 0

local function getCharacter()
    Character = LocalPlayer.Character
    if Character then
        HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    end
    return Character
end

local function setWalkSpeed(speed)
    local hum = Character and Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = speed end
end

local function teleportTo(position)
    HumanoidRootPart.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
end

local function getFieldPosition(fieldName)
    local fields = workspace:FindFirstChild("Fields")
    if not fields then return nil end
    for _, field in ipairs(fields:GetChildren()) do
        if field.Name:find(fieldName) then
            return field:GetModelCFrame().Position
        end
    end
    return nil
end

local function collectNearby()
    local root = HumanoidRootPart
    if not root then return end
    local tokens = workspace:FindFirstChild("Tokens")
    if tokens then
        for _, token in ipairs(tokens:GetChildren()) do
            local pos
            if token:IsA("Model") then
                pos = token:GetModelCFrame().Position
            elseif token:IsA("BasePart") then
                pos = token.Position
            end
            if pos and (pos - root.Position).Magnitude <= CONFIG.CollectRadius then
                if CONFIG.TeleportMode then teleportTo(pos) end
            end
        end
    end
    local fieldPos = getFieldPosition(CONFIG.FarmField)
    if fieldPos and CONFIG.TeleportMode then
        for x = -10, 10, 5 do
            for z = -10, 10, 5 do
                teleportTo(fieldPos + Vector3.new(x, 0, z))
                task.wait(0.05)
            end
        end
    end
end

local function convertHoney()
    local now = tick()
    if now - lastConvert < CONFIG.ConvertInterval then return end
    lastConvert = now
    local hive = workspace:FindFirstChild("Hive") or workspace:FindFirstChild("MyHive")
    if not hive then return end
    local hivePos = hive:IsA("Model") and hive:GetModelCFrame().Position or hive.Position
    if CONFIG.TeleportMode then teleportTo(hivePos) end
    local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
        or game:GetService("ReplicatedStorage"):FindFirstChild("Events")
    if remotes then
        local convertRemote = remotes:FindFirstChild("Convert")
            or remotes:FindFirstChild("ConvertHoney")
        if convertRemote and convertRemote:IsA("RemoteEvent") then
            convertRemote:FireServer()
        end
    end
end

local function antiAFK()
    if not CONFIG.AntiAFK then return end
    local VirtualUser = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end

LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
    task.wait(1)
    if farming then setWalkSpeed(CONFIG.WalkSpeed) end
end)

-- GUI
local function waitForPlayerGui()
    local pg = LocalPlayer:WaitForChild("PlayerGui", 10)
    return pg
end

local PlayerGui = waitForPlayerGui()
if not PlayerGui then return end

-- Eski GUI varsa temizle
local old = PlayerGui:FindFirstChild("BSSFarmGUI")
if old then old:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BSSFarmGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local THEME = {
    BG         = Color3.fromRGB(15, 15, 20),
    Panel      = Color3.fromRGB(22, 22, 30),
    Accent     = Color3.fromRGB(255, 180, 30),
    Text       = Color3.fromRGB(240, 240, 240),
    SubText    = Color3.fromRGB(140, 140, 160),
    Green      = Color3.fromRGB(60, 200, 100),
    Red        = Color3.fromRGB(220, 70, 70),
    Border     = Color3.fromRGB(40, 40, 55),
}

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
end

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or THEME.Border
    s.Thickness = thickness or 1
    s.Parent = parent
end

local function label(parent, text, size, color, props)
    local l = Instance.new("TextLabel")
    l.Text = text
    l.TextSize = size or 13
    l.TextColor3 = color or THEME.Text
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamBold
    l.TextXAlignment = Enum.TextXAlignment.Left
    for k, v in pairs(props or {}) do l[k] = v end
    l.Parent = parent
    return l
end

local function makeTween(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad), props):Play()
end

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 300, 0, 400)
Main.Position = UDim2.new(0, 20, 0.5, -200)
Main.BackgroundColor3 = THEME.BG
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui
corner(Main, 12)
stroke(Main, THEME.Border, 1.5)

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 46)
Header.BackgroundColor3 = THEME.Panel
Header.BorderSizePixel = 0
Header.Parent = Main
corner(Header, 12)

local HFix = Instance.new("Frame")
HFix.Size = UDim2.new(1, 0, 0, 12)
HFix.Position = UDim2.new(0, 0, 1, -12)
HFix.BackgroundColor3 = THEME.Panel
HFix.BorderSizePixel = 0
HFix.Parent = Header

label(Header, "🐝 BSS AUTO FARM", 13, THEME.Accent, {
    Size = UDim2.new(1, -50, 1, 0),
    Position = UDim2.new(0, 12, 0, 0),
})

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -36, 0, 9)
MinBtn.BackgroundColor3 = THEME.Border
MinBtn.Text = "—"
MinBtn.TextColor3 = THEME.SubText
MinBtn.TextSize = 11
MinBtn.Font = Enum.Font.GothamBold
MinBtn.BorderSizePixel = 0
MinBtn.Parent = Header
corner(MinBtn, 6)

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, 0, 1, -46)
Content.Position = UDim2.new(0, 0, 0, 46)
Content.BackgroundTransparency = 1
Content.Parent = Main

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        makeTween(Main, {Size = UDim2.new(0, 300, 0, 46)}, 0.2)
        MinBtn.Text = "+"
    else
        makeTween(Main, {Size = UDim2.new(0, 300, 0, 400)}, 0.2)
        MinBtn.Text = "—"
    end
end)

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, 0, 1, -36)
Scroll.Position = UDim2.new(0, 0, 0, 4)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = THEME.Accent
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = Content

local UIPad = Instance.new("UIPadding")
UIPad.PaddingLeft = UDim.new(0, 10)
UIPad.PaddingRight = UDim.new(0, 10)
UIPad.PaddingTop = UDim.new(0, 6)
UIPad.Parent = Scroll

local UIList = Instance.new("UIListLayout")
UIList.Padding = UDim.new(0, 7)
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Parent = Scroll

local function sectionLbl(txt, order)
    local l = label(Scroll, txt, 10, THEME.SubText, {
        Size = UDim2.new(1, 0, 0, 18),
        LayoutOrder = order,
        Font = Enum.Font.GothamBold,
    })
    l.Parent = Scroll
end

local function makeToggle(labelTxt, default, order, cb)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundColor3 = THEME.Panel
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.Parent = Scroll
    corner(row, 8)
    stroke(row, THEME.Border)

    label(row, labelTxt, 12, THEME.Text, {
        Size = UDim2.new(1, -56, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
    })

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 38, 0, 19)
    track.Position = UDim2.new(1, -48, 0.5, -9)
    track.BackgroundColor3 = default and THEME.Green or THEME.Border
    track.BorderSizePixel = 0
    track.Parent = row
    corner(track, 10)

    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.new(0, 15, 0, 15)
    thumb.Position = default and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    thumb.BackgroundColor3 = Color3.fromRGB(255,255,255)
    thumb.BorderSizePixel = 0
    thumb.Parent = track
    corner(thumb, 8)

    local state = default
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row
    btn.MouseButton1Click:Connect(function()
        state = not state
        makeTween(track, {BackgroundColor3 = state and THEME.Green or THEME.Border})
        makeTween(thumb, {Position = state and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,2,0.5,-7)})
        if cb then cb(state) end
    end)
end

local function makeSlider(labelTxt, min, max, default, order, cb)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 54)
    row.BackgroundColor3 = THEME.Panel
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.Parent = Scroll
    corner(row, 8)
    stroke(row, THEME.Border)

    label(row, labelTxt, 12, THEME.Text, {
        Size = UDim2.new(0.6, 0, 0, 20),
        Position = UDim2.new(0, 10, 0, 7),
    })

    local valLbl = label(row, tostring(default), 12, THEME.Accent, {
        Size = UDim2.new(0.35, 0, 0, 20),
        Position = UDim2.new(0.62, 0, 0, 7),
        TextXAlignment = Enum.TextXAlignment.Right,
    })

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -20, 0, 4)
    track.Position = UDim2.new(0, 10, 0, 36)
    track.BackgroundColor3 = THEME.Border
    track.BorderSizePixel = 0
    track.Parent = row
    corner(track, 2)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = THEME.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    corner(fill, 2)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new((default-min)/(max-min), -6, 0.5, -6)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knob.BorderSizePixel = 0
    knob.Parent = track
    corner(knob, 6)

    local dragging = false
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch) then
            local rel = math.clamp((inp.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + rel*(max-min))
            valLbl.Text = tostring(val)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            knob.Position = UDim2.new(rel, -6, 0.5, -6)
            if cb then cb(val) end
        end
    end)
end

local function makeDropdown(labelTxt, options, default, order, cb)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundColor3 = THEME.Panel
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.ClipsDescendants = false
    row.ZIndex = 10
    row.Parent = Scroll
    corner(row, 8)
    stroke(row, THEME.Border)

    label(row, labelTxt, 11, THEME.SubText, {
        Size = UDim2.new(0.35, 0, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        ZIndex = 11,
    })

    local sel = Instance.new("TextLabel")
    sel.Size = UDim2.new(0.55, 0, 1, 0)
    sel.Position = UDim2.new(0.38, 0, 0, 0)
    sel.BackgroundTransparency = 1
    sel.Text = default
    sel.TextColor3 = THEME.Accent
    sel.TextSize = 10
    sel.Font = Enum.Font.GothamBold
    sel.TextXAlignment = Enum.TextXAlignment.Right
    sel.ZIndex = 11
    sel.Parent = row

    local arrow = label(row, "▾", 12, THEME.SubText, {
        Size = UDim2.new(0, 18, 1, 0),
        Position = UDim2.new(1, -20, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 11,
    })

    local dropFrame = Instance.new("Frame")
    dropFrame.Size = UDim2.new(1, 0, 0, #options * 28)
    dropFrame.Position = UDim2.new(0, 0, 1, 2)
    dropFrame.BackgroundColor3 = THEME.Panel
    dropFrame.BorderSizePixel = 0
    dropFrame.Visible = false
    dropFrame.ZIndex = 20
    dropFrame.Parent = row
    corner(dropFrame, 8)
    stroke(dropFrame, THEME.Accent, 1)

    local dList = Instance.new("UIListLayout")
    dList.SortOrder = Enum.SortOrder.LayoutOrder
    dList.Parent = dropFrame

    for i, opt in ipairs(options) do
        local ob = Instance.new("TextButton")
        ob.Size = UDim2.new(1, 0, 0, 28)
        ob.BackgroundTransparency = 1
        ob.Text = opt
        ob.TextColor3 = opt == default and THEME.Accent or THEME.Text
        ob.TextSize = 10
        ob.Font = Enum.Font.Gotham
        ob.LayoutOrder = i
        ob.ZIndex = 21
        ob.Parent = dropFrame
        ob.MouseButton1Click:Connect(function()
            sel.Text = opt
            dropFrame.Visible = false
            arrow.Text = "▾"
            if cb then cb(opt) end
        end)
    end

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(1,0,1,0)
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.Text = ""
    toggleBtn.ZIndex = 12
    toggleBtn.Parent = row
    toggleBtn.MouseButton1Click:Connect(function()
        dropFrame.Visible = not dropFrame.Visible
        arrow.Text = dropFrame.Visible and "▴" or "▾"
    end)
end

-- POPULATE
sectionLbl("  FARM CONTROLS", 1)

local FarmBtn = Instance.new("TextButton")
FarmBtn.Size = UDim2.new(1, 0, 0, 42)
FarmBtn.BackgroundColor3 = THEME.Green
FarmBtn.Text = "▶  START FARMING"
FarmBtn.TextColor3 = Color3.fromRGB(10,10,10)
FarmBtn.TextSize = 13
FarmBtn.Font = Enum.Font.GothamBold
FarmBtn.BorderSizePixel = 0
FarmBtn.LayoutOrder = 2
FarmBtn.Parent = Scroll
corner(FarmBtn, 8)

FarmBtn.MouseButton1Click:Connect(function()
    farming = not farming
    if farming then
        FarmBtn.BackgroundColor3 = THEME.Red
        FarmBtn.Text = "■  STOP FARMING"
        antiAFK()
        setWalkSpeed(CONFIG.WalkSpeed)
        task.spawn(function()
            while farming do
                if getCharacter() then
                    if CONFIG.AutoCollect then collectNearby() end
                    if CONFIG.AutoConvert then convertHoney() end
                end
                task.wait(0.1)
            end
            setWalkSpeed(16)
        end)
    else
        FarmBtn.BackgroundColor3 = THEME.Green
        FarmBtn.Text = "▶  START FARMING"
    end
end)

sectionLbl("  TOGGLES", 3)

makeToggle("Auto Collect", CONFIG.AutoCollect, 4, function(v) CONFIG.AutoCollect = v end)
makeToggle("Auto Convert Honey", CONFIG.AutoConvert, 5, function(v) CONFIG.AutoConvert = v end)
makeToggle("Teleport Mode", CONFIG.TeleportMode, 6, function(v) CONFIG.TeleportMode = v end)
makeToggle("Anti-AFK", CONFIG.AntiAFK, 7, function(v) CONFIG.AntiAFK = v end)

sectionLbl("  SETTINGS", 8)

makeSlider("Walk Speed", 16, 200, CONFIG.WalkSpeed, 9, function(v)
    CONFIG.WalkSpeed = v
    if farming then setWalkSpeed(v) end
end)
makeSlider("Collect Radius", 5, 60, CONFIG.CollectRadius, 10, function(v)
    CONFIG.CollectRadius = v
end)
makeSlider("Convert Interval (s)", 5, 120, CONFIG.ConvertInterval, 11, function(v)
    CONFIG.ConvertInterval = v
end)

sectionLbl("  TARGET FIELD", 12)

makeDropdown("Field", {
    "Sunflower Field","Clover Field","Blue Flower Field",
    "Strawberry Field","Spider Field","Bamboo Field",
    "Pineapple Patch","Stump Field","Mushroom Field",
    "Rose Field","Pine Tree Forest","Coconut Field","Pumpkin Patch",
}, CONFIG.FarmField, 13, function(v) CONFIG.FarmField = v end)

-- STATUS BAR
local StatusBar = Instance.new("Frame")
StatusBar.Size = UDim2.new(1, 0, 0, 26)
StatusBar.BackgroundColor3 = THEME.Panel
StatusBar.BorderSizePixel = 0
StatusBar.Position = UDim2.new(0, 0, 1, -26)
StatusBar.Parent = Main
corner(StatusBar, 8)

local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.new(0, 8, 0, 8)
StatusDot.Position = UDim2.new(0, 10, 0.5, -4)
StatusDot.BackgroundColor3 = THEME.Red
StatusDot.BorderSizePixel = 0
StatusDot.Parent = StatusBar
corner(StatusDot, 4)

local StatusText = label(StatusBar, "Idle", 10, THEME.SubText, {
    Size = UDim2.new(1, -28, 1, 0),
    Position = UDim2.new(0, 24, 0, 0),
    Font = Enum.Font.Gotham,
})

RunService.Heartbeat:Connect(function()
    if farming then
        StatusDot.BackgroundColor3 = THEME.Green
        StatusText.Text = "Farming — " .. CONFIG.FarmField
        StatusText.TextColor3 = THEME.Green
    else
        StatusDot.BackgroundColor3 = THEME.Red
        StatusText.Text = "Idle"
        StatusText.TextColor3 = THEME.SubText
    end
end)
