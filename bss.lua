--[[
    Sharc-Inspired Soft & Minimalist Roblox UI Library
    Crafted with smooth TweenService animations & modern acrylic aesthetic
    Theme: Pitch Black & Electric Blue (#0000FF)
--]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local SharcUI = {}
SharcUI.__index = SharcUI

-- Theme & Palette Configuration (Siyah & Elektrik Mavisi #0000FF Theme)
SharcUI.Theme = {
    Background = Color3.fromRGB(10, 10, 14),
    Sidebar = Color3.fromRGB(15, 15, 22),
    Topbar = Color3.fromRGB(18, 18, 26),
    Card = Color3.fromRGB(22, 22, 32),
    CardHover = Color3.fromRGB(30, 30, 45),
    Accent = Color3.fromRGB(0, 102, 255),       -- Electric Blue (#0066FF / Vibrant Electric)
    AccentGlow = Color3.fromRGB(0, 170, 255),
    TextPrimary = Color3.fromRGB(245, 245, 255),
    TextSecondary = Color3.fromRGB(140, 145, 170),
    Border = Color3.fromRGB(0, 80, 200),        -- Electric Blue Border Accent
    BorderSoft = Color3.fromRGB(35, 40, 60),
    Success = Color3.fromRGB(0, 230, 150),
    Font = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold
}

-- Helpers
local function createTween(instance, info, properties)
    local tween = TweenService:Create(instance, info, properties)
    tween:Play()
    return tween
end

local function addCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

local function addStroke(parent, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or SharcUI.Theme.BorderSoft
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

local function makeDraggable(topbar, mainFrame)
    local dragging = false
    local dragInput, dragStart, startPos

    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            createTween(mainFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            })
        end
    end)
end

-- Create Window Function
function SharcUI.CreateWindow(title, subtitle)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SharcUI_" .. math.random(1000, 9999)
    ScreenGui.ResetOnSpawn = false
    
    -- Safe Parent Assignment
    pcall(function()
        if gethui then
            ScreenGui.Parent = gethui()
        elseif syn and syn.protect_gui then
            syn.protect_gui(ScreenGui)
            ScreenGui.Parent = CoreGui
        else
            ScreenGui.Parent = CoreGui
        end
    end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end

    -- Main Container Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 680, 0, 440)
    MainFrame.Position = UDim2.new(0.5, -340, 0.5, -220)
    MainFrame.BackgroundColor3 = SharcUI.Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Transparency = 1
    MainFrame.Parent = ScreenGui

    addCorner(MainFrame, 12)

    -- Soft Glow Shadow (Electric Blue Tint)
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    Shadow.Size = UDim2.new(1, 45, 1, 45)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://6015897843"
    Shadow.ImageColor3 = SharcUI.Theme.Accent
    Shadow.ImageTransparency = 0.7
    Shadow.ZIndex = 0
    Shadow.Parent = MainFrame

    -- Intro Animation
    createTween(MainFrame, TweenInfo.new(0.4), {BackgroundTransparency = 0})

    -- Top Bar Container (Clean Header Bar)
    local Topbar = Instance.new("Frame")
    Topbar.Name = "Topbar"
    Topbar.Position = UDim2.new(0, 0, 0, 0)
    Topbar.Size = UDim2.new(1, 0, 0, 40)
    Topbar.BackgroundColor3 = SharcUI.Theme.Topbar
    Topbar.BorderSizePixel = 0
    Topbar.Parent = MainFrame

    addCorner(Topbar, 12)
    
    -- Square out bottom corners of Topbar to sit seamlessly inside MainFrame
    local TopbarBottomSquare = Instance.new("Frame")
    TopbarBottomSquare.Position = UDim2.new(0, 0, 1, -8)
    TopbarBottomSquare.Size = UDim2.new(1, 0, 0, 8)
    TopbarBottomSquare.BackgroundColor3 = SharcUI.Theme.Topbar
    TopbarBottomSquare.BorderSizePixel = 0
    TopbarBottomSquare.Parent = Topbar

    makeDraggable(Topbar, MainFrame)

    -- Brand / Title in Topbar
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "Title"
    TitleLabel.Position = UDim2.new(0, 16, 0, 0)
    TitleLabel.Size = UDim2.new(0, 150, 1, 0)
    TitleLabel.Font = SharcUI.Theme.FontBold
    TitleLabel.Text = title or "Sharc"
    TitleLabel.TextColor3 = SharcUI.Theme.TextPrimary
    TitleLabel.TextSize = 13
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Parent = Topbar

    -- Minimize Button (Yukarı/Aşağı Ok Butonu)
    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Name = "MinimizeBtn"
    MinimizeBtn.Position = UDim2.new(1, -36, 0.5, -11)
    MinimizeBtn.Size = UDim2.new(0, 22, 0, 22)
    MinimizeBtn.BackgroundColor3 = SharcUI.Theme.Card
    MinimizeBtn.AutoButtonColor = false
    MinimizeBtn.Font = SharcUI.Theme.FontBold
    MinimizeBtn.Text = "▲"
    MinimizeBtn.TextColor3 = SharcUI.Theme.Accent
    MinimizeBtn.TextSize = 11
    MinimizeBtn.Parent = Topbar
    addCorner(MinimizeBtn, 6)
    addStroke(MinimizeBtn, SharcUI.Theme.BorderSoft, 1, 0.6)

    -- Body Wrapper (Contains Sidebar and Content Container)
    local BodyFrame = Instance.new("Frame")
    BodyFrame.Name = "BodyFrame"
    BodyFrame.Position = UDim2.new(0, 0, 0, 40)
    BodyFrame.Size = UDim2.new(1, 0, 1, -40)
    BodyFrame.BackgroundTransparency = 1
    BodyFrame.ClipsDescendants = true
    BodyFrame.Parent = MainFrame

    -- Sidebar Container (Compact Width: 140px with soft corner match)
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Position = UDim2.new(0, 0, 0, 0)
    Sidebar.Size = UDim2.new(0, 140, 1, 0)
    Sidebar.BackgroundColor3 = SharcUI.Theme.Sidebar
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = BodyFrame

    addCorner(Sidebar, 12)
    
    -- Square out top corners of Sidebar so it connects smoothly with Topbar
    local SidebarTopSquare = Instance.new("Frame")
    SidebarTopSquare.Position = UDim2.new(0, 0, 0, 0)
    SidebarTopSquare.Size = UDim2.new(1, 0, 0, 10)
    SidebarTopSquare.BackgroundColor3 = SharcUI.Theme.Sidebar
    SidebarTopSquare.BorderSizePixel = 0
    SidebarTopSquare.Parent = Sidebar

    -- Tab Button Scroll Holder
    local TabHolder = Instance.new("ScrollingFrame")
    TabHolder.Name = "TabHolder"
    TabHolder.Position = UDim2.new(0, 6, 0, 8)
    TabHolder.Size = UDim2.new(1, -12, 1, -16)
    TabHolder.BackgroundTransparency = 1
    TabHolder.BorderSizePixel = 0
    TabHolder.ScrollBarThickness = 2
    TabHolder.ScrollBarImageColor3 = SharcUI.Theme.Accent
    TabHolder.AutomaticCanvasSize = Enum.AutomaticSize.Y
    TabHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabHolder.Parent = Sidebar

    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.Parent = TabHolder
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 4)

    TabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabHolder.CanvasSize = UDim2.new(0, 0, 0, TabListLayout.AbsoluteContentSize.Y + 10)
    end)

    -- Content Area Container
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Position = UDim2.new(0, 140, 0, 0)
    ContentContainer.Size = UDim2.new(1, -140, 1, 0)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Parent = BodyFrame

    -- Active Tab Title Header inside Content Area
    local ActiveTabTitle = Instance.new("TextLabel")
    ActiveTabTitle.Name = "ActiveTabTitle"
    ActiveTabTitle.Position = UDim2.new(0, 18, 0, 10)
    ActiveTabTitle.Size = UDim2.new(0, 200, 0, 20)
    ActiveTabTitle.Font = SharcUI.Theme.FontBold
    ActiveTabTitle.Text = "Overview"
    ActiveTabTitle.TextColor3 = SharcUI.Theme.TextPrimary
    ActiveTabTitle.TextSize = 14
    ActiveTabTitle.TextXAlignment = Enum.TextXAlignment.Left
    ActiveTabTitle.BackgroundTransparency = 1
    ActiveTabTitle.Parent = ContentContainer

    -- Minimize Toggle Logic
    local isMinimized = false
    MinimizeBtn.MouseEnter:Connect(function()
        createTween(MinimizeBtn, TweenInfo.new(0.2), {BackgroundColor3 = SharcUI.Theme.Accent, TextColor3 = SharcUI.Theme.TextPrimary})
    end)
    MinimizeBtn.MouseLeave:Connect(function()
        createTween(MinimizeBtn, TweenInfo.new(0.2), {BackgroundColor3 = SharcUI.Theme.Card, TextColor3 = SharcUI.Theme.Accent})
    end)

    MinimizeBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            BodyFrame.Visible = false
            MinimizeBtn.Text = "▼"
            createTween(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 680, 0, 40)
            })
        else
            MinimizeBtn.Text = "▲"
            local tween = createTween(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 680, 0, 440)
            })
            tween.Completed:Connect(function()
                if not isMinimized then
                    BodyFrame.Visible = true
                end
            end)
        end
    end)

    local WindowObj = {
        ScreenGui = ScreenGui,
        MainFrame = MainFrame,
        TabHolder = TabHolder,
        ContentContainer = ContentContainer,
        ActiveTabTitle = ActiveTabTitle,
        Tabs = {},
        CurrentTab = nil
    }

    -- Notification Toast System
    function WindowObj:Notify(config)
        local title = config.Title or "Notification"
        local message = config.Content or ""
        local duration = config.Duration or 4

        local Toast = Instance.new("Frame")
        Toast.Name = "Toast"
        Toast.Size = UDim2.new(0, 260, 0, 60)
        Toast.Position = UDim2.new(1, 280, 1, -80)
        Toast.BackgroundColor3 = SharcUI.Theme.Card
        Toast.Parent = ScreenGui

        addCorner(Toast, 10)
        addStroke(Toast, SharcUI.Theme.Accent, 1, 0.6)

        local ToastTitle = Instance.new("TextLabel")
        ToastTitle.Position = UDim2.new(0, 15, 0, 10)
        ToastTitle.Size = UDim2.new(1, -30, 0, 18)
        ToastTitle.Font = SharcUI.Theme.FontBold
        ToastTitle.Text = title
        ToastTitle.TextColor3 = SharcUI.Theme.Accent
        ToastTitle.TextSize = 13
        ToastTitle.TextXAlignment = Enum.TextXAlignment.Left
        ToastTitle.BackgroundTransparency = 1
        ToastTitle.Parent = Toast

        local ToastDesc = Instance.new("TextLabel")
        ToastDesc.Position = UDim2.new(0, 15, 0, 30)
        ToastDesc.Size = UDim2.new(1, -30, 0, 20)
        ToastDesc.Font = SharcUI.Theme.Font
        ToastDesc.Text = message
        ToastDesc.TextColor3 = SharcUI.Theme.TextSecondary
        ToastDesc.TextSize = 11
        ToastDesc.TextXAlignment = Enum.TextXAlignment.Left
        ToastDesc.BackgroundTransparency = 1
        ToastDesc.Parent = Toast

        -- Toast Entrance Animation
        createTween(Toast, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(1, -280, 1, -80)
        })

        task.delay(duration, function()
            local tween = createTween(Toast, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 280, 1, -80)
            })
            tween.Completed:Connect(function()
                Toast:Destroy()
            end)
        end)
    end

    -- Tab Creation
    function WindowObj:CreateTab(tabName, iconId)
        local TabButton = Instance.new("TextButton")
        TabButton.Name = tabName .. "_Btn"
        TabButton.Size = UDim2.new(1, 0, 0, 36)
        TabButton.BackgroundColor3 = SharcUI.Theme.Card
        TabButton.BackgroundTransparency = 1
        TabButton.AutoButtonColor = false
        TabButton.Text = ""
        TabButton.Parent = TabHolder

        addCorner(TabButton, 8)

        local hasIcon = (iconId ~= nil and iconId ~= "")
        local IconLabel

        if hasIcon then
            IconLabel = Instance.new("ImageLabel")
            IconLabel.Name = "TabIcon"
            IconLabel.Position = UDim2.new(0, 8, 0.5, -7)
            IconLabel.Size = UDim2.new(0, 14, 0, 14)
            IconLabel.BackgroundTransparency = 1
            IconLabel.ScaleType = Enum.ScaleType.Fit
            IconLabel.Image = iconId
            IconLabel.ImageColor3 = SharcUI.Theme.TextSecondary
            IconLabel.Parent = TabButton
        end

        local TabText = Instance.new("TextLabel")
        TabText.Name = "TabText"
        TabText.Position = hasIcon and UDim2.new(0, 28, 0, 0) or UDim2.new(0, 10, 0, 0)
        TabText.Size = hasIcon and UDim2.new(1, -30, 1, 0) or UDim2.new(1, -12, 1, 0)
        TabText.Font = SharcUI.Theme.Font
        TabText.Text = tabName
        TabText.TextColor3 = SharcUI.Theme.TextSecondary
        TabText.TextSize = 12
        TabText.TextXAlignment = Enum.TextXAlignment.Left
        TabText.BackgroundTransparency = 1
        TabText.Parent = TabButton

        local ActiveIndicator = Instance.new("Frame")
        ActiveIndicator.Name = "Indicator"
        ActiveIndicator.Position = UDim2.new(0, 0, 0.2, 0)
        ActiveIndicator.Size = UDim2.new(0, 3, 0.6, 0)
        ActiveIndicator.BackgroundColor3 = SharcUI.Theme.Accent
        ActiveIndicator.BackgroundTransparency = 1
        ActiveIndicator.Parent = TabButton
        addCorner(ActiveIndicator, 4)

        -- Tab Content Scroll View
        local TabContent = Instance.new("ScrollingFrame")
        TabContent.Name = tabName .. "_Content"
        TabContent.Position = UDim2.new(0, 20, 0, 38)
        TabContent.Size = UDim2.new(1, -40, 1, -48)
        TabContent.BackgroundTransparency = 1
        TabContent.BorderSizePixel = 0
        TabContent.ScrollBarThickness = 3
        TabContent.ScrollBarImageColor3 = SharcUI.Theme.Border
        TabContent.Visible = false
        TabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
        TabContent.Parent = ContentContainer

        local ContentLayout = Instance.new("UIListLayout")
        ContentLayout.Parent = TabContent
        ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ContentLayout.Padding = UDim.new(0, 10)

        ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabContent.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 15)
        end)

        local TabObj = {
            Button = TabButton,
            Content = TabContent,
            Name = tabName
        }

        local function activateTab()
            for _, t in pairs(WindowObj.Tabs) do
                createTween(t.Button, TweenInfo.new(0.2), {BackgroundTransparency = 1})
                createTween(t.Button.TabText, TweenInfo.new(0.2), {TextColor3 = SharcUI.Theme.TextSecondary})
                if t.Button:FindFirstChild("TabIcon") then
                    createTween(t.Button.TabIcon, TweenInfo.new(0.2), {ImageColor3 = SharcUI.Theme.TextSecondary})
                end
                createTween(t.Button.Indicator, TweenInfo.new(0.2), {BackgroundTransparency = 1})
                t.Content.Visible = false
            end

            WindowObj.CurrentTab = TabObj
            WindowObj.ActiveTabTitle.Text = tabName

            createTween(TabButton, TweenInfo.new(0.2), {BackgroundTransparency = 0.8})
            createTween(TabText, TweenInfo.new(0.2), {TextColor3 = SharcUI.Theme.TextPrimary})
            if IconLabel then
                createTween(IconLabel, TweenInfo.new(0.2), {ImageColor3 = SharcUI.Theme.Accent})
            end
            createTween(ActiveIndicator, TweenInfo.new(0.2), {BackgroundTransparency = 0})

            TabContent.Visible = true
        end

        TabButton.MouseEnter:Connect(function()
            if WindowObj.CurrentTab ~= TabObj then
                createTween(TabButton, TweenInfo.new(0.2), {BackgroundTransparency = 0.9})
            end
        end)

        TabButton.MouseLeave:Connect(function()
            if WindowObj.CurrentTab ~= TabObj then
                createTween(TabButton, TweenInfo.new(0.2), {BackgroundTransparency = 1})
            end
        end)

        TabButton.MouseButton1Click:Connect(activateTab)

        -- Activate first created tab automatically
        if #WindowObj.Tabs == 0 then
            activateTab()
        end

        table.insert(WindowObj.Tabs, TabObj)

        -- Component Elements Creator Methods
        local Elements = {}

        -- 1. Section Header
        function Elements:AddSection(sectionTitle)
            local SectionLabel = Instance.new("TextLabel")
            SectionLabel.Size = UDim2.new(1, 0, 0, 25)
            SectionLabel.Font = SharcUI.Theme.FontBold
            SectionLabel.Text = sectionTitle
            SectionLabel.TextColor3 = SharcUI.Theme.Accent
            SectionLabel.TextSize = 11
            SectionLabel.TextXAlignment = Enum.TextXAlignment.Left
            SectionLabel.BackgroundTransparency = 1
            SectionLabel.Parent = TabContent
        end

        -- Stat Card Component for Live Stats
        function Elements:AddStatCard(titleText, initialValue)
            local Card = Instance.new("Frame")
            Card.Size = UDim2.new(1, 0, 0, 48)
            Card.BackgroundColor3 = SharcUI.Theme.Card
            Card.Parent = TabContent
            addCorner(Card, 8)
            addStroke(Card, SharcUI.Theme.BorderSoft, 1, 0.8)

            local Label = Instance.new("TextLabel")
            Label.Position = UDim2.new(0, 14, 0, 8)
            Label.Size = UDim2.new(0.6, 0, 0, 16)
            Label.Font = SharcUI.Theme.Font
            Label.Text = titleText
            Label.TextColor3 = SharcUI.Theme.TextSecondary
            Label.TextSize = 11
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.BackgroundTransparency = 1
            Label.Parent = Card

            local ValLabel = Instance.new("TextLabel")
            ValLabel.Position = UDim2.new(0, 14, 0, 24)
            ValLabel.Size = UDim2.new(1, -28, 0, 18)
            ValLabel.Font = SharcUI.Theme.FontBold
            ValLabel.Text = tostring(initialValue or "0")
            ValLabel.TextColor3 = SharcUI.Theme.Accent
            ValLabel.TextSize = 14
            ValLabel.TextXAlignment = Enum.TextXAlignment.Left
            ValLabel.BackgroundTransparency = 1
            ValLabel.Parent = Card

            return {
                Update = function(newVal)
                    ValLabel.Text = tostring(newVal)
                end
            }
        end

        -- 2. Soft Toggle Switch
        function Elements:AddToggle(toggleName, default, callback)
            callback = callback or function() end
            local state = default or false

            local Card = Instance.new("Frame")
            Card.Size = UDim2.new(1, 0, 0, 42)
            Card.BackgroundColor3 = SharcUI.Theme.Card
            Card.Parent = TabContent
            addCorner(Card, 8)
            addStroke(Card, SharcUI.Theme.BorderSoft, 1, 0.8)

            local Label = Instance.new("TextLabel")
            Label.Position = UDim2.new(0, 14, 0, 0)
            Label.Size = UDim2.new(0.7, 0, 1, 0)
            Label.Font = SharcUI.Theme.Font
            Label.Text = toggleName
            Label.TextColor3 = SharcUI.Theme.TextPrimary
            Label.TextSize = 13
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.BackgroundTransparency = 1
            Label.Parent = Card

            local SwitchTrack = Instance.new("Frame")
            SwitchTrack.Position = UDim2.new(1, -50, 0.5, -10)
            SwitchTrack.Size = UDim2.new(0, 38, 0, 20)
            SwitchTrack.BackgroundColor3 = state and SharcUI.Theme.Accent or Color3.fromRGB(40, 44, 60)
            SwitchTrack.Parent = Card
            addCorner(SwitchTrack, 10)

            local Knob = Instance.new("Frame")
            Knob.Position = state and UDim2.new(1, -18, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
            Knob.Size = UDim2.new(0, 14, 0, 14)
            Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Knob.Parent = SwitchTrack
            addCorner(Knob, 10)

            local ClickBtn = Instance.new("TextButton")
            ClickBtn.Size = UDim2.new(1, 0, 1, 0)
            ClickBtn.BackgroundTransparency = 1
            ClickBtn.Text = ""
            ClickBtn.Parent = Card

            local function updateToggle()
                state = not state
                createTween(SwitchTrack, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
                    BackgroundColor3 = state and SharcUI.Theme.Accent or Color3.fromRGB(40, 44, 60)
                })
                createTween(Knob, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
                    Position = state and UDim2.new(1, -18, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
                })
                pcall(callback, state)
            end

            ClickBtn.MouseButton1Click:Connect(updateToggle)

            Card.MouseEnter:Connect(function()
                createTween(Card, TweenInfo.new(0.2), {BackgroundColor3 = SharcUI.Theme.CardHover})
            end)
            Card.MouseLeave:Connect(function()
                createTween(Card, TweenInfo.new(0.2), {BackgroundColor3 = SharcUI.Theme.Card})
            end)
        end

        -- 3. Smooth Interactive Slider
        function Elements:AddSlider(sliderName, min, max, default, callback)
            callback = callback or function() end
            local value = math.clamp(default or min, min, max)

            local Card = Instance.new("Frame")
            Card.Size = UDim2.new(1, 0, 0, 55)
            Card.BackgroundColor3 = SharcUI.Theme.Card
            Card.Parent = TabContent
            addCorner(Card, 8)
            addStroke(Card, SharcUI.Theme.BorderSoft, 1, 0.8)

            local Label = Instance.new("TextLabel")
            Label.Position = UDim2.new(0, 14, 0, 8)
            Label.Size = UDim2.new(0.6, 0, 0, 20)
            Label.Font = SharcUI.Theme.Font
            Label.Text = sliderName
            Label.TextColor3 = SharcUI.Theme.TextPrimary
            Label.TextSize = 13
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.BackgroundTransparency = 1
            Label.Parent = Card

            local ValLabel = Instance.new("TextLabel")
            ValLabel.Position = UDim2.new(1, -70, 0, 8)
            ValLabel.Size = UDim2.new(0, 56, 0, 20)
            ValLabel.Font = SharcUI.Theme.FontBold
            ValLabel.Text = tostring(value)
            ValLabel.TextColor3 = SharcUI.Theme.Accent
            ValLabel.TextSize = 12
            ValLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValLabel.BackgroundTransparency = 1
            ValLabel.Parent = Card

            local SliderTrack = Instance.new("Frame")
            SliderTrack.Position = UDim2.new(0, 14, 0.7, -4)
            SliderTrack.Size = UDim2.new(1, -28, 0, 6)
            SliderTrack.BackgroundColor3 = Color3.fromRGB(40, 44, 60)
            SliderTrack.Parent = Card
            addCorner(SliderTrack, 4)

            local SliderFill = Instance.new("Frame")
            local initialPct = (value - min) / (max - min)
            SliderFill.Size = UDim2.new(initialPct, 0, 1, 0)
            SliderFill.BackgroundColor3 = SharcUI.Theme.Accent
            SliderFill.Parent = SliderTrack
            addCorner(SliderFill, 4)

            local dragging = false
            local function updateSlider(input)
                local pct = math.clamp((input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
                value = math.floor(min + (max - min) * pct)
                ValLabel.Text = tostring(value)
                createTween(SliderFill, TweenInfo.new(0.1), {Size = UDim2.new(pct, 0, 1, 0)})
                pcall(callback, value)
            end

            SliderTrack.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    updateSlider(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateSlider(input)
                end
            end)
        end

        -- 4. Sleek Button Component
        function Elements:AddButton(btnText, callback)
            callback = callback or function() end

            local Card = Instance.new("Frame")
            Card.Size = UDim2.new(1, 0, 0, 40)
            Card.BackgroundColor3 = SharcUI.Theme.Card
            Card.Parent = TabContent
            addCorner(Card, 8)
            addStroke(Card, SharcUI.Theme.BorderSoft, 1, 0.8)

            local Button = Instance.new("TextButton")
            Button.Size = UDim2.new(1, 0, 1, 0)
            Button.Font = SharcUI.Theme.FontBold
            Button.Text = btnText
            Button.TextColor3 = SharcUI.Theme.TextPrimary
            Button.TextSize = 13
            Button.BackgroundTransparency = 1
            Button.Parent = Card

            Button.MouseEnter:Connect(function()
                createTween(Card, TweenInfo.new(0.2), {BackgroundColor3 = SharcUI.Theme.CardHover})
                createTween(Button, TweenInfo.new(0.2), {TextColor3 = SharcUI.Theme.Accent})
            end)
            Button.MouseLeave:Connect(function()
                createTween(Card, TweenInfo.new(0.2), {BackgroundColor3 = SharcUI.Theme.Card})
                createTween(Button, TweenInfo.new(0.2), {TextColor3 = SharcUI.Theme.TextPrimary})
            end)
            Button.MouseButton1Click:Connect(function()
                -- Button Click Ripple Animation
                createTween(Card, TweenInfo.new(0.1), {Size = UDim2.new(0.98, 0, 0, 38)}).Completed:Connect(function()
                    createTween(Card, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 40)})
                end)
                pcall(callback)
            end)
        end

        -- 5. Animated Dropdown Component
        function Elements:AddDropdown(dropdownName, options, default, callback)
            callback = callback or function() end
            local selected = default or options[1] or "Select..."
            local expanded = false

            local Card = Instance.new("Frame")
            Card.Size = UDim2.new(1, 0, 0, 42)
            Card.BackgroundColor3 = SharcUI.Theme.Card
            Card.ClipsDescendants = true
            Card.Parent = TabContent
            addCorner(Card, 8)
            addStroke(Card, SharcUI.Theme.BorderSoft, 1, 0.8)

            local HeaderBtn = Instance.new("TextButton")
            HeaderBtn.Size = UDim2.new(1, 0, 0, 42)
            HeaderBtn.BackgroundTransparency = 1
            HeaderBtn.Text = ""
            HeaderBtn.Parent = Card

            local Label = Instance.new("TextLabel")
            Label.Position = UDim2.new(0, 14, 0, 0)
            Label.Size = UDim2.new(0.5, 0, 0, 42)
            Label.Font = SharcUI.Theme.Font
            Label.Text = dropdownName
            Label.TextColor3 = SharcUI.Theme.TextPrimary
            Label.TextSize = 13
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.BackgroundTransparency = 1
            Label.Parent = HeaderBtn

            local SelectedLabel = Instance.new("TextLabel")
            SelectedLabel.Position = UDim2.new(0.5, -25, 0, 0)
            SelectedLabel.Size = UDim2.new(0.5, 0, 0, 42)
            SelectedLabel.Font = SharcUI.Theme.Font
            SelectedLabel.Text = selected
            SelectedLabel.TextColor3 = SharcUI.Theme.Accent
            SelectedLabel.TextSize = 12
            SelectedLabel.TextXAlignment = Enum.TextXAlignment.Right
            SelectedLabel.BackgroundTransparency = 1
            SelectedLabel.Parent = HeaderBtn

            local OptionsContainer = Instance.new("Frame")
            OptionsContainer.Position = UDim2.new(0, 10, 0, 42)
            OptionsContainer.Size = UDim2.new(1, -20, 0, #options * 32)
            OptionsContainer.BackgroundTransparency = 1
            OptionsContainer.Parent = Card

            local OptionsLayout = Instance.new("UIListLayout")
            OptionsLayout.Parent = OptionsContainer
            OptionsLayout.Padding = UDim.new(0, 4)

            for _, opt in ipairs(options) do
                local OptBtn = Instance.new("TextButton")
                OptBtn.Size = UDim2.new(1, 0, 0, 28)
                OptBtn.BackgroundColor3 = Color3.fromRGB(30, 32, 48)
                OptBtn.Font = SharcUI.Theme.Font
                OptBtn.Text = opt
                OptBtn.TextColor3 = (opt == selected) and SharcUI.Theme.Accent or SharcUI.Theme.TextSecondary
                OptBtn.TextSize = 12
                OptBtn.Parent = OptionsContainer
                addCorner(OptBtn, 6)

                OptBtn.MouseButton1Click:Connect(function()
                    selected = opt
                    SelectedLabel.Text = selected
                    expanded = false
                    createTween(Card, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
                        Size = UDim2.new(1, 0, 0, 42)
                    })
                    pcall(callback, selected)
                end)
            end

            HeaderBtn.MouseButton1Click:Connect(function()
                expanded = not expanded
                local targetHeight = expanded and (46 + #options * 32) or 42
                createTween(Card, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
                    Size = UDim2.new(1, 0, 0, targetHeight)
                })
            end)
        end

        return Elements
    end

    return WindowObj
end

-- ====================================================================
-- DEMO IMPLEMENTATION FOR BEE SWARM SIMULATOR (SHARC MINIMALIST STYLE)
-- ====================================================================

local Window = SharcUI.CreateWindow("Sharc", "Bee Swarm Simulator")

-- Clean High-Quality Roblox Icons (Exact Match for Tris's Request)
local Icons = {
    Home     = "rbxassetid://10723407389", -- Home Icon
    Farming  = "rbxassetid://131589148478599", -- Leaf Icon (Yaprak)
    Combat   = "rbxassetid://10723356507", -- Swords Icon (Kılıç)
    Quest    = "rbxassetid://10723371531", -- Eye Icon (Göz)
    Planters = "rbxassetid://10723346959", -- Plant Pot Icon (Saksı)
    Toys     = "rbxassetid://10723380004", -- Toy Gamepad Icon (Oyuncak)
    RBC      = "rbxassetid://10723374120", -- Robot Head Icon (Robot Kafası)
    Config   = "rbxassetid://10723346553", -- Settings Gear / Cog Icon (Ayar Çarkı)
    Debug    = "rbxassetid://10723375480"  -- Ladybug Icon (Uğur Böceği)
}

-- Number Formatting Helper (M = Million, B = Billion, T = Trillion)
local function formatNumber(n)
    if not n or n ~= n or n < 0 then return "0" end
    if n >= 1e12 then
        return string.format("%.2fT", n / 1e12)
    elseif n >= 1e9 then
        return string.format("%.2fB", n / 1e9)
    elseif n >= 1e6 then
        return string.format("%.2fM", n / 1e6)
    elseif n >= 1e3 then
        return string.format("%.1fK", n / 1e3)
    else
        return tostring(math.floor(n))
    end
end

-- Global Macro State Flag
SharcUI.MacroActive = true

-- 1. Home Tab (Honey & Pollen Live Tracker + Stop Everything Toggle)
local HomeTab = Window:CreateTab("Home", Icons.Home)

HomeTab:AddSection("Session Statistics")

local TotalEarnedCard = HomeTab:AddStatCard("Honey Earned (Session)", "0 M")
local HoneyPerHrCard  = HomeTab:AddStatCard("Honey / Hour", "0 M/hr")
local PollenCard      = HomeTab:AddStatCard("Current Pollen", "0 / 0")
local ElapsedTimeCard = HomeTab:AddStatCard("Session Time", "00:00:00")

HomeTab:AddSection("Macro Controls")

-- Stop Everything Toggle Switch
HomeTab:AddToggle("STOP EVERYTHING", false, function(state)
    SharcUI.MacroActive = not state
    print("[Sharc] STOP EVERYTHING toggled:", state)
end)

-- Live Honey & Pollen Tracker Logic
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local startTime = os.time()

local initialHoney = nil

local function fetchPlayerStats()
    local honeyVal = 0
    local pollenVal = 0
    local maxPollenVal = 0

    pcall(function()
        -- Bee Swarm Simulator CoreStats check
        if LocalPlayer:FindFirstChild("CoreStats") then
            local cs = LocalPlayer.CoreStats
            if cs:FindFirstChild("Honey") then honeyVal = cs.Honey.Value end
            if cs:FindFirstChild("Pollen") then pollenVal = cs.Pollen.Value end
            if cs:FindFirstChild("Capacity") then maxPollenVal = cs.Capacity.Value end
        elseif LocalPlayer:FindFirstChild("leaderstats") then
            local ls = LocalPlayer.leaderstats
            if ls:FindFirstChild("Honey") then honeyVal = ls.Honey.Value end
            if ls:FindFirstChild("Pollen") then pollenVal = ls.Pollen.Value end
        end
    end)

    return honeyVal, pollenVal, maxPollenVal
end

RunService.Heartbeat:Connect(function()
    local currentHoney, currentPollen, maxPollen = fetchPlayerStats()

    if not initialHoney and currentHoney > 0 then
        initialHoney = currentHoney
    end

    local currentTime = os.time()
    local elapsed = math.max(1, currentTime - startTime)
    
    local earned = initialHoney and math.max(0, currentHoney - initialHoney) or 0
    local honeyPerHr = (earned / elapsed) * 3600

    local hours = math.floor(elapsed / 3600)
    local mins = math.floor((elapsed % 3600) / 60)
    local secs = elapsed % 60

    TotalEarnedCard.Update(formatNumber(earned))
    HoneyPerHrCard.Update(formatNumber(honeyPerHr) .. " / hr")
    PollenCard.Update(formatNumber(currentPollen) .. " / " .. formatNumber(maxPollen))
    ElapsedTimeCard.Update(string.format("%02d:%02d:%02d", hours, mins, secs))
end)

-- 2. Farming Tab
local FarmTab = Window:CreateTab("Farming", Icons.Farming)
FarmTab:AddSection("Auto Farming")
FarmTab:AddToggle("Enable Auto Farm", false, function(val)
    print("[Sharc] Auto Farm:", val)
end)
FarmTab:AddDropdown("Select Field", {"Pine Tree Forest", "Sunflower Field", "Dandelion Field", "Coconut Field", "Pepper Patch"}, "Pine Tree Forest", function(field)
    print("[Sharc] Selected Field:", field)
end)
FarmTab:AddSlider("Convert Honey at %", 10, 100, 90, function(pct)
    print("[Sharc] Convert at:", pct, "%")
end)

-- 3. Combat Tab
local CombatTab = Window:CreateTab("Combat", Icons.Combat)
CombatTab:AddSection("Mob & Boss Killer")
CombatTab:AddToggle("Kill Mobs", false, function(val)
    print("[Sharc] Auto Kill Mobs:", val)
end)
CombatTab:AddToggle("Kill Vicious Bee", false, function(val)
    print("[Sharc] Vicious Bee Farm:", val)
end)

-- 4. Quest Tab
local QuestTab = Window:CreateTab("Quest", Icons.Quest)
QuestTab:AddSection("Quest Automation")
QuestTab:AddToggle("Auto Complete Quests", false, function(val)
    print("[Sharc] Auto Quests:", val)
end)

-- 5. Planters Tab
local PlantersTab = Window:CreateTab("Planters", Icons.Planters)
PlantersTab:AddSection("Planter Management")
PlantersTab:AddToggle("Auto Plant Planters", false, function(val)
    print("[Sharc] Auto Planters:", val)
end)

-- 6. Toys Tab
local ToysTab = Window:CreateTab("Toys", Icons.Toys)
ToysTab:AddSection("Toy Memory Match & Boosters")
ToysTab:AddToggle("Auto Memory Match", false, function(val)
    print("[Sharc] Memory Match:", val)
end)

-- 7. RBC Tab
local RBCTab = Window:CreateTab("RBC", Icons.RBC)
RBCTab:AddSection("Robo Bear Challenge")
RBCTab:AddToggle("Auto RBC Farm", false, function(val)
    print("[Sharc] RBC Farm:", val)
end)

-- 8. Config Tab
local ConfigTab = Window:CreateTab("Config", Icons.Config)
ConfigTab:AddSection("UI & Preset Configuration")
ConfigTab:AddButton("Save Configuration", function()
    print("[Sharc] Configuration saved.")
end)

-- 9. Debug Tab
local DebugTab = Window:CreateTab("Debug", Icons.Debug)
DebugTab:AddSection("Developer Utilities")
DebugTab:AddButton("Unload Sharc UI", function()
    Window.ScreenGui:Destroy()
end)

-- ====================================================================
-- AUTO CLAIM HIVE LOGIC FOR BEE SWARM SIMULATOR (REFINED)
-- ====================================================================

local function autoClaimHive()
    task.spawn(function()
        local player = game:GetService("Players").LocalPlayer
        local workspace = game:GetService("Workspace")
        local replicatedStorage = game:GetService("ReplicatedStorage")

        local function getChar()
            return player.Character or player.CharacterAdded:Wait()
        end

        -- Helper to locate Honeycombs / Hives container in Workspace
        local function getHoneycombsFolder()
            return workspace:FindFirstChild("Honeycombs") or workspace:FindFirstChild("Hives")
        end

        -- Check if player already owns a hive
        local function checkOwnedHive()
            local folder = getHoneycombsFolder()
            if folder then
                for _, hive in ipairs(folder:GetChildren()) do
                    -- Check Owner ObjectValue or StringValue
                    local owner = hive:FindFirstChild("Owner")
                    if owner then
                        if owner:IsA("ObjectValue") and owner.Value == player then
                            return hive
                        elseif owner:IsA("StringValue") and (owner.Value == player.Name or owner.Value == tostring(player.UserId)) then
                            return hive
                        end
                    end
                end
            end
            return nil
        end

        if checkOwnedHive() then
            print("[Sharc] Player already has a Hive.")
            return
        end

        print("[Sharc] Searching for an unowned Hive...")

        local folder = getHoneycombsFolder()
        if not folder then
            warn("[Sharc] Honeycombs folder not found in Workspace!")
            return
        end

        for _, hive in ipairs(folder:GetChildren()) do
            local owner = hive:FindFirstChild("Owner")
            local isUnowned = false

            if owner then
                if owner:IsA("ObjectValue") and (owner.Value == nil) then
                    isUnowned = true
                elseif owner:IsA("StringValue") and (owner.Value == "" or owner.Value == "nil") then
                    isUnowned = true
                end
            else
                isUnowned = true
            end

            if isUnowned then
                local char = getChar()
                local hrp = char:FindFirstChild("HumanoidRootPart")
                
                -- Target position to teleport
                local targetCFrame = nil
                if hive:FindFirstChild("SpawnPos") then
                    targetCFrame = hive.SpawnPos.CFrame
                elseif hive:FindFirstChild("Platform") then
                    targetCFrame = hive.Platform.CFrame
                elseif hive:IsA("Model") and hive.PrimaryPart then
                    targetCFrame = hive.PrimaryPart.CFrame
                end

                if targetCFrame and hrp then
                    print("[Sharc] Teleporting to claim Hive:", hive.Name)
                    hrp.CFrame = targetCFrame + Vector3.new(0, 3, 0)
                    task.wait(0.3)

                    -- 1. Try BSS Remote Event (ClaimHive)
                    local events = replicatedStorage:FindFirstChild("Events")
                    local claimRemote = events and (events:FindFirstChild("ClaimHive") or events:FindFirstChild("ClaimHiveRequest"))
                    
                    if claimRemote then
                        local hiveNum = tonumber(string.match(hive.Name, "%d+")) or hive:FindFirstChild("HiveID") and hive.HiveID.Value
                        if hiveNum then
                            claimRemote:FireServer(hiveNum)
                        else
                            claimRemote:FireServer(hive)
                        end
                    end

                    -- 2. Try ProximityPrompts & TouchInterests inside Hive
                    for _, obj in ipairs(hive:GetDescendants()) do
                        if obj:IsA("ProximityPrompt") then
                            fireproximityprompt(obj)
                        elseif obj.Name == "Pad" or obj.Name == "ClaimPad" or obj.Name == "Platform" then
                            firetouchinterest(hrp, obj, 0)
                            task.wait(0.1)
                            firetouchinterest(hrp, obj, 1)
                        end
                    end

                    task.wait(1.5)
                    if checkOwnedHive() then
                        print("[Sharc] Successfully claimed Hive:", hive.Name)
                        break
                    end
                end
            end
        end
    end)
end

autoClaimHive()

return SharcUI
