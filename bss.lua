-- BSS Auto Farm v3 -- Kaelx12
-- Object-based positioning, no hardcoded coords

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

local farming = false
local selectedField = "Sunflower Field"

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

-- WORKSPACE'TEN GERÇEK FIELD POZİSYONU BUL
local function findFieldPosition(fieldName)
    -- Önce workspace'te Fields klasörünü ara
    local fieldsFolder = workspace:FindFirstChild("Fields")
        or workspace:FindFirstChild("Map")
        or workspace:FindFirstChild("World")

    if fieldsFolder then
        -- Direkt isim eşleşmesi
        local field = fieldsFolder:FindFirstChild(fieldName)
        if field then
            if field:IsA("Model") and field.PrimaryPart then
                return field.PrimaryPart.Position
            elseif field:IsA("Model") then
                local part = field:FindFirstChildOfClass("BasePart")
                if part then return part.Position end
            elseif field:IsA("BasePart") then
                return field.Position
            end
        end

        -- Kısmi isim eşleşmesi
        for _, obj in ipairs(fieldsFolder:GetDescendants()) do
            if obj.Name:lower():find(fieldName:lower():sub(1,5)) then
                if obj:IsA("BasePart") then
                    return obj.Position
                end
            end
        end
    end

    -- Tüm workspace'te ara
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == fieldName then
            if obj:IsA("Model") then
                local p = obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")
                if p then return p.Position end
            elseif obj:IsA("BasePart") then
                return obj.Position
            end
        end
    end

    return nil
end

-- HİVE POZİSYONU BUL
local function findHivePosition()
    -- Kendi hive'ını bul
    local hiveNames = {"Hive", "MyHive", "BasicHive", "PlayerHive"}
    for _, name in ipairs(hiveNames) do
        local h = workspace:FindFirstChild(name)
            or workspace:FindFirstDescendant and workspace:FindFirstDescendant(name)
        if h then
            if h:IsA("Model") then
                local p = h.PrimaryPart or h:FindFirstChildOfClass("BasePart")
                if p then return p.Position end
            elseif h:IsA("BasePart") then
                return h.Position
            end
        end
    end

    -- LP adıyla ara
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name:lower():find("hive") and obj:IsA("Model") then
            local p = obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")
            if p then return p.Position end
        end
    end

    return nil
end

-- HUMANOID MOVETO (fizikle uyumlu)
local function moveTo(targetPos)
    local hrp = getHRP()
    local hum = getHum()
    if not hrp or not hum then return end

    local dist = (hrp.Position - targetPos).Magnitude
    if dist < 4 then return end

    setSpeed(65)
    hum:MoveTo(targetPos)

    local timeout = tick() + 20
    while farming do
        task.wait(0.3)
        local cur = getHRP()
        if not cur then break end
        local remaining = (cur.Position - targetPos).Magnitude
        if remaining < 6 then break end
        if tick() > timeout then break end
        -- Takılıp kalmışsa tekrar bas
        hum:MoveTo(targetPos)
    end
end

-- BAG DOLU MU
local function isBagFull()
    -- Yöntem 1: leaderstats
    local stats = LP:FindFirstChild("leaderstats")
    if stats then
        local pollen = stats:FindFirstChild("Pollen")
        local cap = stats:FindFirstChild("Capacity") or stats:FindFirstChild("BagSize")
        if pollen and cap then
            local p = tonumber(pollen.Value) or 0
            local c = tonumber(cap.Value) or 1
            if c > 0 then return p >= c * 0.95 end
        end
    end

    -- Yöntem 2: PlayerData
    local pd = workspace:FindFirstChild("PlayerData")
    if pd then
        local mine = pd:FindFirstChild(LP.Name)
        if mine then
            local pollen = mine:FindFirstChild("Pollen")
            local cap = mine:FindFirstChild("BagSize") or mine:FindFirstChild("Capacity")
            if pollen and cap then
                local p = tonumber(pollen.Value) or 0
                local c = tonumber(cap.Value) or 1
                if c > 0 then return p >= c * 0.95 end
            end
        end
    end

    -- Yöntem 3: GUI'den oku
    local gui = LP.PlayerGui
    for _, sg in ipairs(gui:GetChildren()) do
        for _, obj in ipairs(sg:GetDescendants()) do
            if obj:IsA("TextLabel") and obj.Text:find("/") then
                local cur, max = obj.Text:match("(%d+)/(%d+)")
                if cur and max then
                    local p = tonumber(cur) or 0
                    local c = tonumber(max) or 1
                    if c > 100 then -- bag değerleri genelde büyük
                        return p >= c * 0.95
                    end
                end
            end
        end
    end

    return false
end

-- SPRINKLER KOY
local function placeSprinkler()
    local remotes = RS:FindFirstChild("Remotes")
        or RS:FindFirstChild("Events")
        or RS:FindFirstChild("RemoteEvents")
    if remotes then
        for _, r in ipairs(remotes:GetChildren()) do
            if r:IsA("RemoteEvent") and (
                r.Name:lower():find("sprinkler") or
                r.Name:lower():find("plant")
            ) then
                r:FireServer()
                return
            end
        end
    end
    -- E tuşu
    pcall(function()
        local vi = game:GetService("VirtualInputManager")
        vi:SendKeyEvent(true, Enum.KeyCode.E, false, nil)
        task.wait(0.15)
        vi:SendKeyEvent(false, Enum.KeyCode.E, false, nil)
    end)
end

-- AUTO DIG
local function autoDig()
    local remotes = RS:FindFirstChild("Remotes")
        or RS:FindFirstChild("Events")
        or RS:FindFirstChild("RemoteEvents")
    if remotes then
        for _, r in ipairs(remotes:GetChildren()) do
            if r:IsA("RemoteEvent") and (
                r.Name:lower():find("dig") or
                r.Name:lower():find("mutation")
            ) then
                r:FireServer()
                return
            end
        end
    end
end

-- TOKEN TOPLA
local function collectTokens(centerPos)
    local hrp = getHRP()
    if not hrp then return end

    local scanRadius = 35
    local tokenFolders = {"Tokens", "DroppedTokens", "Drops", "CollectItems", "Collectibles"}

    for _, fname in ipairs(tokenFolders) do
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
                if pos then
                    local distToCenter = centerPos and (pos - centerPos).Magnitude or 0
                    local distToMe = (hrp.Position - pos).Magnitude
                    if distToMe <= scanRadius or distToCenter <= scanRadius then
                        moveTo(pos)
                        task.wait(0.05)
                    end
                end
            end
        end
    end

    -- Workspace direkt altındaki tokenler
    for _, obj in ipairs(workspace:GetChildren()) do
        if not farming then return end
        if obj:IsA("BasePart") and (
            obj.Name:lower():find("token") or
            obj.Name:lower():find("pollen") or
            obj.Name:lower():find("coin") or
            obj.Name:lower():find("drop")
        ) then
            local dist = (hrp.Position - obj.Position).Magnitude
            if dist <= scanRadius then
                moveTo(obj.Position)
                task.wait(0.05)
            end
        end
    end
end

-- HİVEYE GİT VE CONVERT ET
local function goHiveAndConvert()
    local hivePos = findHivePosition()
    if not hivePos then
        -- Hive bulunamazsa başlangıç noktasına dön
        hivePos = Vector3.new(0, 10, 0)
    end

    moveTo(hivePos)
    task.wait(1)

    -- Remote ara
    local remotes = RS:FindFirstChild("Remotes")
        or RS:FindFirstChild("Events")
        or RS:FindFirstChild("RemoteEvents")
    if remotes then
        for _, r in ipairs(remotes:GetChildren()) do
            if r:IsA("RemoteEvent") and (
                r.Name:lower():find("convert") or
                r.Name:lower():find("deposit") or
                r.Name:lower():find("pollen") or
                r.Name:lower():find("honey")
            ) then
                r:FireServer()
            end
        end
    end

    -- E bas
    pcall(function()
        local vi = game:GetService("VirtualInputManager")
        vi:SendKeyEvent(true, Enum.KeyCode.E, false, nil)
        task.wait(0.2)
        vi:SendKeyEvent(false, Enum.KeyCode.E, false, nil)
    end)

    task.wait(1)
end

-- FIELD SWEEP
local function sweepField(centerPos)
    local offsets = {
        Vector3.new(0,0,0),
        Vector3.new(8,0,0), Vector3.new(-8,0,0),
        Vector3.new(0,0,8), Vector3.new(0,0,-8),
        Vector3.new(8,0,8), Vector3.new(-8,0,8),
        Vector3.new(8,0,-8), Vector3.new(-8,0,-8),
        Vector3.new(16,0,0), Vector3.new(-16,0,0),
        Vector3.new(0,0,16), Vector3.new(0,0,-16),
    }

    for _, offset in ipairs(offsets) do
        if not farming then break end
        if isBagFull() then break end

        local target = centerPos + offset
        moveTo(target)
        task.wait(0.15)
        collectTokens(centerPos)
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

LP.CharacterAdded:Connect(function()
    task.wait(1)
    if farming then setSpeed(65) end
end)

-- MAIN LOOP
local function farmLoop()
    startAntiAFK()
    setSpeed(65)

    -- Field pozisyonunu bir kez bul
    local fieldPos = findFieldPosition(selectedField)

    while farming do
        -- Her döngüde tekrar bul (field değişmiş olabilir)
        fieldPos = findFieldPosition(selectedField)

        if not fieldPos then
            -- Field bulunamadı, GUI'ye yansıt
            task.wait(2)
            continue
        end

        -- 1. Field'a git
        moveTo(fieldPos)
        task.wait(0.4)

        -- 2. Sprinkler koy
        placeSprinkler()
        task.wait(0.3)

        -- 3. Sweep
        sweepField(fieldPos)

        -- 4. Bag doluysa hive
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
    BG     = Color3.fromRGB(12,12,18),
    Panel  = Color3.fromRGB(20,20,28),
    Accent = Color3.fromRGB(255,185,30),
    Green  = Color3.fromRGB(50,200,90),
    Red    = Color3.fromRGB(215,65,65),
    Text   = Color3.fromRGB(235,235,235),
    Sub    = Color3.fromRGB(130,130,150),
    Border = Color3.fromRGB(38,38,52),
}

local function C(p,r) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r or 8) c.Parent=p end
local function S(p,col,t) local s=Instance.new("UIStroke") s.Color=col or THEME.Border s.Thickness=t or 1 s.Parent=p end
local function TW(o,pr,t) TweenService:Create(o,TweenInfo.new(t or 0.15,Enum.EasingStyle.Quad),pr):Play() end

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0,280,0,320)
Main.Position = UDim2.new(0,16,0.5,-160)
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

local HdrFix = Instance.new("Frame")
HdrFix.Size = UDim2.new(1,0,0,12)
HdrFix.Position = UDim2.new(0,0,1,-12)
HdrFix.BackgroundColor3 = THEME.Panel
HdrFix.BorderSizePixel = 0
HdrFix.Parent = Hdr

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
    TW(Main,{Size=minimized and UDim2.new(0,280,0,44) or UDim2.new(0,280,0,320)},0.2)
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
local FIELD_LIST = {
    "Bamboo Field","Blue Flower Field","Clover Field",
    "Coconut Field","Mushroom Field","Pine Tree Forest",
    "Pineapple Patch","Pumpkin Patch","Rose Field",
    "Spider Field","Strawberry Field","Stump Field","Sunflower Field"
}

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
DropList.Size = UDim2.new(1,0,0,#FIELD_LIST*28)
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

for i, name in ipairs(FIELD_LIST) do
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

-- DEBUG LABEL (field pozisyonunu göster)
local DbgLbl = Instance.new("TextLabel")
DbgLbl.Size = UDim2.new(1,0,0,28)
DbgLbl.BackgroundTransparency = 1
DbgLbl.Text = "Field pos: searching..."
DbgLbl.TextColor3 = THEME.Sub
DbgLbl.TextSize = 9
DbgLbl.Font = Enum.Font.Gotham
DbgLbl.TextXAlignment = Enum.TextXAlignment.Left
DbgLbl.TextWrapped = true
DbgLbl.LayoutOrder = 4
DbgLbl.Parent = Scroll

-- Debug: field pozisyonunu sürekli göster
task.spawn(function()
    while task.wait(2) do
        local pos = findFieldPosition(selectedField)
        if pos then
            DbgLbl.Text = string.format("Field: %.0f, %.0f, %.0f", pos.X, pos.Y, pos.Z)
            DbgLbl.TextColor3 = THEME.Green
        else
            DbgLbl.Text = "Field bulunamadı: " .. selectedField
            DbgLbl.TextColor3 = THEME.Red
        end
    end
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
