
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()

-- STATE
local farming = false
local selectedField = "Sunflower Field"
local bagCapacity = 0
local currentBag = 0

-- FIELD POSITIONS (BSS standart field merkezleri)
local FIELDS = {
    ["Sunflower Field"]   = Vector3.new(185, 6, -95),
    ["Clover Field"]      = Vector3.new(118, 6, -120),
    ["Blue Flower Field"] = Vector3.new(150, 6, -200),
    ["Strawberry Field"]  = Vector3.new(230, 6, -200),
    ["Spider Field"]      = Vector3.new(340, 6, -180),
    ["Bamboo Field"]      = Vector3.new(370, 6, -100),
    ["Pineapple Patch"]   = Vector3.new(420, 6, -50),
    ["Stump Field"]       = Vector3.new(280, 6, -60),
    ["Mushroom Field"]    = Vector3.new(100, 6, -280),
    ["Rose Field"]        = Vector3.new(200, 6, -320),
    ["Pine Tree Forest"]  = Vector3.new(450, 6, -200),
    ["Coconut Field"]     = Vector3.new(500, 6, -100),
    ["Pumpkin Patch"]     = Vector3.new(480, 6, 0),
}

local HIVE_POS = Vector3.new(152, 8, -7)

-- UTILS
local function getChar()
    return LP.Character
end

local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function tpTo(pos)
    local hrp = getHRP()
    if hrp then
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0))
    end
end

local function walkTo(pos)
    local hum = getHum()
    if hum then
        hum:MoveTo(pos)
        hum.MoveToFinished:Wait(10)
    end
end

local function distanceTo(pos)
    local hrp = getHRP()
    if not hrp then return 999 end
    return (hrp.Position - pos).Magnitude
end

local function setSpeed(n)
    local hum = getHum()
    if hum then hum.WalkSpeed = n end
end

local function waitFrames(n)
    for _ = 1, n do
        RunService.Heartbeat:Wait()
    end
end

-- BAG CHECK
local function getBagInfo()
    local gui = LP.PlayerGui
    -- BSS bag bilgisi PlayerGui içindeki MainGui'de
    local ok, val = pcall(function()
        local stats = LP:FindFirstChild("PlayerData") or LP:FindFirstChild("leaderstats")
        if stats then
            local pollen = stats:FindFirstChild("Pollen") or stats:FindFirstChild("MyPollen")
            local cap = stats:FindFirstChild("BagSize") or stats:FindFirstChild("Capacity")
            if pollen and cap then
                return tonumber(pollen.Value), tonumber(cap.Value)
            end
        end
        return nil, nil
    end)
    if ok and val then return val end

    -- Alternatif: workspace player data
    local pd = workspace:FindFirstChild("PlayerData")
    if pd then
        local mine = pd:FindFirstChild(LP.Name)
        if mine then
            local pollen = mine:FindFirstChild("Pollen")
            local cap = mine:FindFirstChild("BagSize")
            if pollen and cap then
                return tonumber(pollen.Value), tonumber(cap.Value)
            end
        end
    end
    return 0, 100
end

local function isBagFull()
    local current, cap = getBagInfo()
    if cap and cap > 0 then
        return current >= cap * 0.95
    end
    return false
end

-- SPRINKLER
local function placeSprinkler()
    -- E tuşuna bas (sprinkler place)
    local vInput = game:GetService("VirtualInputManager")
    local ok = pcall(function()
        vInput:SendKeyEvent(true, Enum.KeyCode.E, false, nil)
        task.wait(0.1)
        vInput:SendKeyEvent(false, Enum.KeyCode.E, false, nil)
    end)
    if not ok then
        -- Alternatif: remote fire
        local remotes = RS:FindFirstChild("Remotes") or RS:FindFirstChild("Events")
        if remotes then
            local sprinklerRemote = remotes:FindFirstChild("PlaceSprinkler")
                or remotes:FindFirstChild("Sprinkler")
                or remotes:FindFirstChild("UseSprinkler")
            if sprinklerRemote then
                sprinklerRemote:FireServer()
            end
        end
    end
end

-- AUTO DIG
local function autoDig()
    local remotes = RS:FindFirstChild("Remotes") or RS:FindFirstChild("Events")
    if not remotes then return end
    local digRemote = remotes:FindFirstChild("Dig")
        or remotes:FindFirstChild("AutoDig")
        or remotes:FindFirstChild("DigMutation")
    if digRemote then
        digRemote:FireServer()
    end
end

-- TOKEN COLLECTOR
local function collectTokensNearby(radius)
    radius = radius or 25
    local hrp = getHRP()
    if not hrp then return end

    local tokenFolder = workspace:FindFirstChild("Tokens")
        or workspace:FindFirstChild("DroppedTokens")
        or workspace:FindFirstChild("Drops")

    if tokenFolder then
        for _, token in ipairs(tokenFolder:GetChildren()) do
            if not farming then break end
            local pos
            if token:IsA("BasePart") then
                pos = token.Position
            elseif token:IsA("Model") then
                local p = token.PrimaryPart or token:FindFirstChildOfClass("BasePart")
                if p then pos = p.Position end
            end

            if pos and (pos - hrp.Position).Magnitude <= radius then
                tpTo(pos)
                task.wait(0.05)
            end
        end
    end
end

-- HIVE: CONVERT HONEY
local function goHiveAndConvert()
    -- Hive'a git
    tpTo(HIVE_POS)
    task.wait(1)

    -- E bas (convert)
    local vInput = game:GetService("VirtualInputManager")
    pcall(function()
        vInput:SendKeyEvent(true, Enum.KeyCode.E, false, nil)
        task.wait(0.2)
        vInput:SendKeyEvent(false, Enum.KeyCode.E, false, nil)
    end)

    -- Remote alternatif
    local remotes = RS:FindFirstChild("Remotes") or RS:FindFirstChild("Events")
    if remotes then
        local convert = remotes:FindFirstChild("Convert")
            or remotes:FindFirstChild("ConvertHoney")
            or remotes:FindFirstChild("DepositPollen")
        if convert then
            convert:FireServer()
        end
    end

    task.wait(1)
end

-- FIELD SWEEP (orta nokta etrafında grid taraması)
local function sweepField(center)
    local points = {}
    for x = -15, 15, 8 do
        for z = -15, 15, 8 do
            table.insert(points, center + Vector3.new(x, 0, z))
        end
    end

    for _, pt in ipairs(points) do
        if not farming then break end
        if isBagFull() then break end

        tpTo(pt)
        task.wait(0.08)

        -- Her noktada token topla
        collectTokensNearby(20)

        -- Dig dene
        autoDig()
    end
end

-- ANTİ AFK
local function startAntiAFK()
    local VU = game:GetService("VirtualUser")
    LP.Idled:Connect(function()
        VU:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VU:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end

LP.CharacterAdded:Connect(function(c)
    task.wait(1)
    if farming then setSpeed(65) end
end)

-- ─────────────────────────────────────────
-- MAIN FARM LOOP
-- ─────────────────────────────────────────
local function farmLoop()
    startAntiAFK()
    setSpeed(65)

    while farming do
        local fieldPos = FIELDS[selectedField]
        if not fieldPos then
            task.wait(1)
            continue
        end

        -- 1. Field'a git
        tpTo(fieldPos)
        task.wait(0.5)

        -- 2. Sprinkler koy
        placeSprinkler()
        task.wait(0.3)

        -- 3. Field sweep — token topla + dig
        sweepField(fieldPos)

        -- 4. Bag dolu mu?
        if isBagFull() then
            -- Hive'a git, convert et
            goHiveAndConvert()
        end

        task.wait(0.1)
    end

    setSpeed(16)
end

-- ─────────────────────────────────────────
-- GUI
-- ─────────────────────────────────────────
local old = LP.PlayerGui:FindFirstChild("BSSv2")
if old then old:Destroy() end

local SG = Instance.new("ScreenGui")
SG.Name = "BSSv2"
SG.ResetOnSpawn = false
SG.Parent = LP.PlayerGui

local THEME = {
    BG      = Color3.fromRGB(12, 12, 18),
    Panel   = Color3.fromRGB(20, 20, 28),
    Accent  = Color3.fromRGB(255, 185, 30),
    Green   = Color3.fromRGB(50, 200, 90),
    Red     = Color3.fromRGB(215, 65, 65),
    Text    = Color3.fromRGB(235, 235, 235),
    Sub     = Color3.fromRGB(130, 130, 150),
    Border  = Color3.fromRGB(38, 38, 52),
}

local function C(p, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 8) c.Parent = p end
local function S(p, col, t) local s = Instance.new("UIStroke") s.Color = col or THEME.Border s.Thickness = t or 1 s.Parent = p end
local function TW(o, pr, t) TweenService:Create(o, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad), pr):Play() end

-- MAIN FRAME
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 280, 0, 360)
Main.Position = UDim2.new(0, 16, 0.5, -180)
Main.BackgroundColor3 = THEME.BG
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = SG
C(Main, 12) S(Main, THEME.Border, 1.5)

-- HEADER
local Hdr = Instance.new("Frame")
Hdr.Size = UDim2.new(1, 0, 0, 44)
Hdr.BackgroundColor3 = THEME.Panel
Hdr.BorderSizePixel = 0
Hdr.Parent = Main
C(Hdr, 12)

local HdrFix = Instance.new("Frame")
HdrFix.Size = UDim2.new(1, 0, 0, 12)
HdrFix.Position = UDim2.new(0, 0, 1, -12)
HdrFix.BackgroundColor3 = THEME.Panel
HdrFix.BorderSizePixel = 0
HdrFix.Parent = Hdr

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -46, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🐝  BSS FARM v2"
Title.TextColor3 = THEME.Accent
Title.TextSize = 13
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Hdr

local MinB = Instance.new("TextButton")
MinB.Size = UDim2.new(0, 26, 0, 26)
MinB.Position = UDim2.new(1, -34, 0.5, -13)
MinB.BackgroundColor3 = THEME.Border
MinB.Text = "—"
MinB.TextColor3 = THEME.Sub
MinB.TextSize = 11
MinB.Font = Enum.Font.GothamBold
MinB.BorderSizePixel = 0
MinB.Parent = Hdr
C(MinB, 6)

-- CONTENT
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, 0, 1, -44)
Content.Position = UDim2.new(0, 0, 0, 44)
Content.BackgroundTransparency = 1
Content.Parent = Main

local minimized = false
MinB.MouseButton1Click:Connect(function()
    minimized = not minimized
    TW(Main, {Size = minimized and UDim2.new(0,280,0,44) or UDim2.new(0,280,0,360)}, 0.2)
    MinB.Text = minimized and "+" or "—"
end)

-- SCROLL
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, 0, 1, -32)
Scroll.Position = UDim2.new(0, 0, 0, 4)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 2
Scroll.ScrollBarImageColor3 = THEME.Accent
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.CanvasSize = UDim2.new(0,0,0,0)
Scroll.Parent = Content

local UIPad = Instance.new("UIPadding")
UIPad.PaddingLeft = UDim.new(0, 10)
UIPad.PaddingRight = UDim.new(0, 10)
UIPad.PaddingTop = UDim.new(0, 6)
UIPad.Parent = Scroll

local UIL = Instance.new("UIListLayout")
UIL.Padding = UDim.new(0, 6)
UIL.SortOrder = Enum.SortOrder.LayoutOrder
UIL.Parent = Scroll

-- START/STOP
local FarmBtn = Instance.new("TextButton")
FarmBtn.Size = UDim2.new(1, 0, 0, 44)
FarmBtn.BackgroundColor3 = THEME.Green
FarmBtn.Text = "▶  START FARMING"
FarmBtn.TextColor3 = Color3.fromRGB(8,8,8)
FarmBtn.TextSize = 13
FarmBtn.Font = Enum.Font.GothamBold
FarmBtn.BorderSizePixel = 0
FarmBtn.LayoutOrder = 1
FarmBtn.Parent = Scroll
C(FarmBtn, 8)

FarmBtn.MouseButton1Click:Connect(function()
    farming = not farming
    if farming then
        FarmBtn.BackgroundColor3 = THEME.Red
        FarmBtn.Text = "■  STOP FARMING"
        task.spawn(farmLoop)
    else
        FarmBtn.BackgroundColor3 = THEME.Green
        FarmBtn.Text = "▶  START FARMING"
    end
end)

-- FIELD SEÇİMİ LABEL
local FieldLbl = Instance.new("TextLabel")
FieldLbl.Size = UDim2.new(1, 0, 0, 16)
FieldLbl.BackgroundTransparency = 1
FieldLbl.Text = "  TARGET FIELD"
FieldLbl.TextColor3 = THEME.Sub
FieldLbl.TextSize = 10
FieldLbl.Font = Enum.Font.GothamBold
FieldLbl.TextXAlignment = Enum.TextXAlignment.Left
FieldLbl.LayoutOrder = 2
FieldLbl.Parent = Scroll

-- DROPDOWN
local fieldNames = {}
for k in pairs(FIELDS) do table.insert(fieldNames, k) end
table.sort(fieldNames)

local DDRow = Instance.new("Frame")
DDRow.Size = UDim2.new(1, 0, 0, 36)
DDRow.BackgroundColor3 = THEME.Panel
DDRow.BorderSizePixel = 0
DDRow.LayoutOrder = 3
DDRow.ClipsDescendants = false
DDRow.ZIndex = 10
DDRow.Parent = Scroll
C(DDRow, 8) S(DDRow, THEME.Border)

local SelText = Instance.new("TextLabel")
SelText.Size = UDim2.new(1, -30, 1, 0)
SelText.Position = UDim2.new(0, 10, 0, 0)
SelText.BackgroundTransparency = 1
SelText.Text = selectedField
SelText.TextColor3 = THEME.Accent
SelText.TextSize = 11
SelText.Font = Enum.Font.GothamBold
SelText.TextXAlignment = Enum.TextXAlignment.Left
SelText.ZIndex = 11
SelText.Parent = DDRow

local Arrow = Instance.new("TextLabel")
Arrow.Size = UDim2.new(0, 20, 1, 0)
Arrow.Position = UDim2.new(1, -22, 0, 0)
Arrow.BackgroundTransparency = 1
Arrow.Text = "▾"
Arrow.TextColor3 = THEME.Sub
Arrow.TextSize = 12
Arrow.Font = Enum.Font.GothamBold
Arrow.ZIndex = 11
Arrow.Parent = DDRow

local DropList = Instance.new("Frame")
DropList.Size = UDim2.new(1, 0, 0, #fieldNames * 28)
DropList.Position = UDim2.new(0, 0, 1, 2)
DropList.BackgroundColor3 = THEME.Panel
DropList.BorderSizePixel = 0
DropList.Visible = false
DropList.ZIndex = 20
DropList.Parent = DDRow
C(DropList, 8) S(DropList, THEME.Accent, 1)

local DL = Instance.new("UIListLayout")
DL.SortOrder = Enum.SortOrder.LayoutOrder
DL.Parent = DropList

for i, name in ipairs(fieldNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 28)
    btn.BackgroundTransparency = 1
    btn.Text = name
    btn.TextColor3 = name == selectedField and THEME.Accent or THEME.Text
    btn.TextSize = 10
    btn.Font = Enum.Font.Gotham
    btn.LayoutOrder = i
    btn.ZIndex = 21
    btn.Parent = DropList
    btn.MouseButton1Click:Connect(function()
        selectedField = name
        SelText.Text = name
        DropList.Visible = false
        Arrow.Text = "▾"
    end)
end

local DDBtn = Instance.new("TextButton")
DDBtn.Size = UDim2.new(1,0,1,0)
DDBtn.BackgroundTransparency = 1
DDBtn.Text = ""
DDBtn.ZIndex = 12
DDBtn.Parent = DDRow
DDBtn.MouseButton1Click:Connect(function()
    DropList.Visible = not DropList.Visible
    Arrow.Text = DropList.Visible and "▴" or "▾"
end)

-- STATUS
local StatBar = Instance.new("Frame")
StatBar.Size = UDim2.new(1, 0, 0, 26)
StatBar.BackgroundColor3 = THEME.Panel
StatBar.BorderSizePixel = 0
StatBar.Position = UDim2.new(0, 0, 1, -26)
StatBar.Parent = Main
C(StatBar, 8)

local Dot = Instance.new("Frame")
Dot.Size = UDim2.new(0, 8, 0, 8)
Dot.Position = UDim2.new(0, 10, 0.5, -4)
Dot.BackgroundColor3 = THEME.Red
Dot.BorderSizePixel = 0
Dot.Parent = StatBar
C(Dot, 4)

local StatTxt = Instance.new("TextLabel")
StatTxt.Size = UDim2.new(1, -28, 1, 0)
StatTxt.Position = UDim2.new(0, 24, 0, 0)
StatTxt.BackgroundTransparency = 1
StatTxt.Text = "Idle"
StatTxt.TextColor3 = THEME.Sub
StatTxt.TextSize = 10
StatTxt.Font = Enum.Font.Gotham
StatTxt.TextXAlignment = Enum.TextXAlignment.Left
StatTxt.Parent = StatBar

RunService.Heartbeat:Connect(function()
    if farming then
        Dot.BackgroundColor3 = THEME.Green
        StatTxt.Text = "Farming — " .. selectedField
        StatTxt.TextColor3 = THEME.Green
    else
        Dot.BackgroundColor3 = THEME.Red
        StatTxt.Text = "Idle"
        StatTxt.TextColor3 = THEME.Sub
    end
end)
