
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

local farming = false
local selectedField = "Sunflower Field"

-- FIELD POSİSYONLARI (Y değerleri düzeltildi)
local FIELDS = {
    ["Sunflower Field"]   = Vector3.new(185, 26, -95),
    ["Clover Field"]      = Vector3.new(118, 26, -120),
    ["Blue Flower Field"] = Vector3.new(150, 26, -200),
    ["Strawberry Field"]  = Vector3.new(230, 26, -200),
    ["Spider Field"]      = Vector3.new(340, 26, -180),
    ["Bamboo Field"]      = Vector3.new(370, 26, -100),
    ["Pineapple Patch"]   = Vector3.new(420, 26, -50),
    ["Stump Field"]       = Vector3.new(280, 26, -60),
    ["Mushroom Field"]    = Vector3.new(100, 26, -280),
    ["Rose Field"]        = Vector3.new(200, 26, -320),
    ["Pine Tree Forest"]  = Vector3.new(450, 26, -200),
    ["Coconut Field"]     = Vector3.new(500, 26, -100),
    ["Pumpkin Patch"]     = Vector3.new(480, 26, 0),
}

local HIVE_POS = Vector3.new(152, 26, -7)

-- UTILS
local function getChar() return LP.Character end
local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function setSpeed(n)
    local h = getHum()
    if h then h.WalkSpeed = n end
end

-- TWEEN HAREKET (TP değil)
local function tweenTo(targetPos, speed)
    local hrp = getHRP()
    if not hrp then return end
    speed = speed or 65

    local dist = (hrp.Position - targetPos).Magnitude
    local duration = dist / speed

    -- Çok yakınsa direkt git
    if dist < 5 then
        hrp.CFrame = CFrame.new(targetPos)
        return
    end

    local tween = TweenService:Create(hrp, TweenInfo.new(
        duration,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    ), {CFrame = CFrame.new(targetPos)})

    -- Humanoid'i durdur ki tween çakışmasın
    local hum = getHum()
    if hum then hum:MoveTo(hrp.Position) end

    tween:Play()
    tween.Completed:Wait()
end

-- YER TESPET (raycast ile gerçek zemin Y'si)
local function getGroundY(pos)
    local rayOrigin = Vector3.new(pos.X, 500, pos.Z)
    local rayDir = Vector3.new(0, -1000, 0)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local char = getChar()
    if char then params.FilterDescendantsInstances = {char} end

    local result = workspace:Raycast(rayOrigin, rayDir, params)
    if result then
        return result.Position.Y + 4
    end
    return pos.Y
end

-- GERÇEK ZEMİN Y'Sİ İLE HEDEFE GİT
local function moveTo(pos)
    local groundY = getGroundY(pos)
    local fixedPos = Vector3.new(pos.X, groundY, pos.Z)
    tweenTo(fixedPos)
end

-- BAG DOLULUK
local function isBagFull()
    local pd = workspace:FindFirstChild("PlayerData")
    if pd then
        local mine = pd:FindFirstChild(LP.Name)
        if mine then
            local pollen = mine:FindFirstChild("Pollen")
            local cap = mine:FindFirstChild("BagSize")
            if pollen and cap and tonumber(cap.Value) > 0 then
                return tonumber(pollen.Value) >= tonumber(cap.Value) * 0.95
            end
        end
    end
    local stats = LP:FindFirstChild("leaderstats") or LP:FindFirstChild("PlayerData")
    if stats then
        local pollen = stats:FindFirstChild("Pollen") or stats:FindFirstChild("MyPollen")
        local cap = stats:FindFirstChild("BagSize") or stats:FindFirstChild("Capacity")
        if pollen and cap and tonumber(cap.Value) > 0 then
            return tonumber(pollen.Value) >= tonumber(cap.Value) * 0.95
        end
    end
    return false
end

-- SPRINKLER
local function placeSprinkler()
    local remotes = RS:FindFirstChild("Remotes") or RS:FindFirstChild("Events")
    if remotes then
        local r = remotes:FindFirstChild("PlaceSprinkler")
            or remotes:FindFirstChild("Sprinkler")
            or remotes:FindFirstChild("UseSprinkler")
        if r then r:FireServer() return end
    end
    pcall(function()
        local vi = game:GetService("VirtualInputManager")
        vi:SendKeyEvent(true, Enum.KeyCode.E, false, nil)
        task.wait(0.15)
        vi:SendKeyEvent(false, Enum.KeyCode.E, false, nil)
    end)
end

-- AUTO DIG
local function autoDig()
    local remotes = RS:FindFirstChild("Remotes") or RS:FindFirstChild("Events")
    if remotes then
        local r = remotes:FindFirstChild("Dig")
            or remotes:FindFirstChild("AutoDig")
            or remotes:FindFirstChild("DigMutation")
        if r then r:FireServer() end
    end
end

-- TOKEN TOPLA
local function collectTokens()
    local hrp = getHRP()
    if not hrp then return end
    local folders = {"Tokens", "DroppedTokens", "Drops", "CollectItems"}
    for _, fname in ipairs(folders) do
        local f = workspace:FindFirstChild(fname)
        if f then
            for _, token in ipairs(f:GetChildren()) do
                if not farming then return end
                local pos
                if token:IsA("BasePart") then
                    pos = token.Position
                elseif token:IsA("Model") then
                    local p = token.PrimaryPart or token:FindFirstChildOfClass("BasePart")
                    if p then pos = p.Position end
                end
                if pos and (pos - hrp.Position).Magnitude <= 30 then
                    tweenTo(pos, 80)
                    task.wait(0.05)
                end
            end
        end
    end
end

-- HİVE: DÖNÜP CONVERT ET
local function goHiveAndConvert()
    local hiveGroundY = getGroundY(HIVE_POS)
    local hiveFixed = Vector3.new(HIVE_POS.X, hiveGroundY, HIVE_POS.Z)
    tweenTo(hiveFixed, 65)
    task.wait(0.8)

    -- Remote dene
    local remotes = RS:FindFirstChild("Remotes") or RS:FindFirstChild("Events")
    if remotes then
        local r = remotes:FindFirstChild("Convert")
            or remotes:FindFirstChild("ConvertHoney")
            or remotes:FindFirstChild("DepositPollen")
        if r then r:FireServer() end
    end

    -- E bas
    pcall(function()
        local vi = game:GetService("VirtualInputManager")
        vi:SendKeyEvent(true, Enum.KeyCode.E, false, nil)
        task.wait(0.2)
        vi:SendKeyEvent(false, Enum.KeyCode.E, false, nil)
    end)

    task.wait(0.8)
end

-- FIELD SWEEP
local function sweepField(center)
    local groundY = getGroundY(center)
    local points = {}
    for x = -15, 15, 8 do
        for z = -15, 15, 8 do
            table.insert(points, Vector3.new(center.X + x, groundY, center.Z + z))
        end
    end

    for _, pt in ipairs(points) do
        if not farming then break end
        if isBagFull() then break end
        tweenTo(pt, 65)
        task.wait(0.1)
        collectTokens()
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

-- MAIN LOOP
local function farmLoop()
    startAntiAFK()
    setSpeed(65)

    while farming do
        local fieldPos = FIELDS[selectedField]
        if not fieldPos then task.wait(1) continue end

        -- 1. Field'a git
        moveTo(fieldPos)
        task.wait(0.3)

        -- 2. Sprinkler koy
        placeSprinkler()
        task.wait(0.3)

        -- 3. Sweep et
        sweepField(fieldPos)

        -- 4. Bag doluysa hive'a git
        if isBagFull() then
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
    BG     = Color3.fromRGB(12, 12, 18),
    Panel  = Color3.fromRGB(20, 20, 28),
    Accent = Color3.fromRGB(255, 185, 30),
    Green  = Color3.fromRGB(50, 200, 90),
    Red    = Color3.fromRGB(215, 65, 65),
    Text   = Color3.fromRGB(235, 235, 235),
    Sub    = Color3.fromRGB(130, 130, 150),
    Border = Color3.fromRGB(38, 38, 52),
}

local function C(p,r) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r or 8) c.Parent=p end
local function S(p,col,t) local s=Instance.new("UIStroke") s.Color=col or THEME.Border s.Thickness=t or 1 s.Parent=p end
local function TW(o,pr,t) TweenService:Create(o,TweenInfo.new(t or 0.15,Enum.EasingStyle.Quad),pr):Play() end

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0,280,0,340)
Main.Position = UDim2.new(0,16,0.5,-170)
Main.BackgroundColor3 = THEME.BG
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = SG
C(Main,12) S(Main,THEME.Border,1.5)

local Hdr = Instance.new("Frame")
Hdr.Size = UDim2.new(1,0,0,44)
Hdr.BackgroundColor3 = THEME.Panel
Hdr.BorderSizePixel = 0
Hdr.Parent = Main
C(Hdr,12)

Instance.new("Frame", Hdr).Size = UDim2.new(1,0,0,12)
local hfix = Hdr:FindFirstChildOfClass("Frame")
hfix.Position = UDim2.new(0,0,1,-12)
hfix.BackgroundColor3 = THEME.Panel
hfix.BorderSizePixel = 0

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,-46,1,0)
Title.Position = UDim2.new(0,12,0,0)
Title.BackgroundTransparency = 1
Title.Text = "🐝  BSS FARM v2"
Title.TextColor3 = THEME.Accent
Title.TextSize = 13
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Hdr

local MinB = Instance.new("TextButton")
MinB.Size = UDim2.new(0,26,0,26)
MinB.Position = UDim2.new(1,-34,0.5,-13)
MinB.BackgroundColor3 = THEME.Border
MinB.Text = "—"
MinB.TextColor3 = THEME.Sub
MinB.TextSize = 11
MinB.Font = Enum.Font.GothamBold
MinB.BorderSizePixel = 0
MinB.Parent = Hdr
C(MinB,6)

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1,0,1,-44)
Content.Position = UDim2.new(0,0,0,44)
Content.BackgroundTransparency = 1
Content.Parent = Main

local minimized = false
MinB.MouseButton1Click:Connect(function()
    minimized = not minimized
    TW(Main,{Size=minimized and UDim2.new(0,280,0,44) or UDim2.new(0,280,0,340)},0.2)
    MinB.Text = minimized and "+" or "—"
end)

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1,0,1,-32)
Scroll.Position = UDim2.new(0,0,0,4)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 2
Scroll.ScrollBarImageColor3 = THEME.Accent
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.CanvasSize = UDim2.new(0,0,0,0)
Scroll.Parent = Content

local UIPad = Instance.new("UIPadding")
UIPad.PaddingLeft = UDim.new(0,10)
UIPad.PaddingRight = UDim.new(0,10)
UIPad.PaddingTop = UDim.new(0,6)
UIPad.Parent = Scroll

local UIL = Instance.new("UIListLayout")
UIL.Padding = UDim.new(0,6)
UIL.SortOrder = Enum.SortOrder.LayoutOrder
UIL.Parent = Scroll

-- START/STOP
local FarmBtn = Instance.new("TextButton")
FarmBtn.Size = UDim2.new(1,0,0,44)
FarmBtn.BackgroundColor3 = THEME.Green
FarmBtn.Text = "▶  START FARMING"
FarmBtn.TextColor3 = Color3.fromRGB(8,8,8)
FarmBtn.TextSize = 13
FarmBtn.Font = Enum.Font.GothamBold
FarmBtn.BorderSizePixel = 0
FarmBtn.LayoutOrder = 1
FarmBtn.Parent = Scroll
C(FarmBtn,8)

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

-- FIELD LABEL
local FieldLbl = Instance.new("TextLabel")
FieldLbl.Size = UDim2.new(1,0,0,16)
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
DDRow.Size = UDim2.new(1,0,0,36)
DDRow.BackgroundColor3 = THEME.Panel
DDRow.BorderSizePixel = 0
DDRow.LayoutOrder = 3
DDRow.ClipsDescendants = false
DDRow.ZIndex = 10
DDRow.Parent = Scroll
C(DDRow,8) S(DDRow,THEME.Border)

local SelText = Instance.new("TextLabel")
SelText.Size = UDim2.new(1,-30,1,0)
SelText.Position = UDim2.new(0,10,0,0)
SelText.BackgroundTransparency = 1
SelText.Text = selectedField
SelText.TextColor3 = THEME.Accent
SelText.TextSize = 11
SelText.Font = Enum.Font.GothamBold
SelText.TextXAlignment = Enum.TextXAlignment.Left
SelText.ZIndex = 11
SelText.Parent = DDRow

local Arrow = Instance.new("TextLabel")
Arrow.Size = UDim2.new(0,20,1,0)
Arrow.Position = UDim2.new(1,-22,0,0)
Arrow.BackgroundTransparency = 1
Arrow.Text = "▾"
Arrow.TextColor3 = THEME.Sub
Arrow.TextSize = 12
Arrow.Font = Enum.Font.GothamBold
Arrow.ZIndex = 11
Arrow.Parent = DDRow

local DropList = Instance.new("Frame")
DropList.Size = UDim2.new(1,0,0,#fieldNames*28)
DropList.Position = UDim2.new(0,0,1,2)
DropList.BackgroundColor3 = THEME.Panel
DropList.BorderSizePixel = 0
DropList.Visible = false
DropList.ZIndex = 20
DropList.Parent = DDRow
C(DropList,8) S(DropList,THEME.Accent,1)

local DL = Instance.new("UIListLayout")
DL.SortOrder = Enum.SortOrder.LayoutOrder
DL.Parent = DropList

for i, name in ipairs(fieldNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,28)
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

-- STATUS BAR
local StatBar = Instance.new("Frame")
StatBar.Size = UDim2.new(1,0,0,26)
StatBar.BackgroundColor3 = THEME.Panel
StatBar.BorderSizePixel = 0
StatBar.Position = UDim2.new(0,0,1,-26)
StatBar.Parent = Main
C(StatBar,8)

local Dot = Instance.new("Frame")
Dot.Size = UDim2.new(0,8,0,8)
Dot.Position = UDim2.new(0,10,0.5,-4)
Dot.BackgroundColor3 = THEME.Red
Dot.BorderSizePixel = 0
Dot.Parent = StatBar
C(Dot,4)

local StatTxt = Instance.new("TextLabel")
StatTxt.Size = UDim2.new(1,-28,1,0)
StatTxt.Position = UDim2.new(0,24,0,0)
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
