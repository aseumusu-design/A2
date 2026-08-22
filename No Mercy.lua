--[[
=============================================================
        NO MERCY HUB // NEON UI EDITION
        UI-ONLY DEMO
        RGB • GLOW • ANIMATION • MOBILE FRIENDLY
=============================================================
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

--==========================================================
-- CONFIG
--==========================================================

local Config = {
    UIVisible = true,
    RGBSpeed = 0.35,
    GlowSpeed = 1.2,
}

local Theme = {
    Background = Color3.fromRGB(8, 8, 14),
    Panel = Color3.fromRGB(15, 15, 24),
    Panel2 = Color3.fromRGB(21, 21, 33),
    Text = Color3.fromRGB(245, 245, 255),
    Dim = Color3.fromRGB(145, 145, 165),
    Accent = Color3.fromRGB(160, 60, 255),
    Green = Color3.fromRGB(60, 235, 135),
    Red = Color3.fromRGB(255, 70, 90),
}

--==========================================================
-- CLEAN OLD UI
--==========================================================

local Parent = (gethui and gethui()) or CoreGui

pcall(function()
    local old = Parent:FindFirstChild("NoMercy_NeonUI")
    if old then
        old:Destroy()
    end
end)

--==========================================================
-- SCREEN GUI
--==========================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NoMercy_NeonUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = Parent

--==========================================================
-- MOBILE SCALE
--==========================================================

local UIScale = Instance.new("UIScale")
UIScale.Parent = ScreenGui

local function UpdateScale()
    local camera = workspace.CurrentCamera
    if not camera then return end

    local viewport = camera.ViewportSize

    if viewport.X < 700 then
        UIScale.Scale = 0.78
    else
        UIScale.Scale = 1
    end
end

UpdateScale()

if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale)
end

--==========================================================
-- OPEN BUTTON
--==========================================================

local Bubble = Instance.new("TextButton")
Bubble.Name = "OpenButton"
Bubble.Size = UDim2.fromOffset(58, 58)
Bubble.Position = UDim2.new(0, 16, 0.5, -29)
Bubble.BackgroundColor3 = Theme.Panel
Bubble.Text = "NM"
Bubble.TextColor3 = Theme.Text
Bubble.TextSize = 17
Bubble.Font = Enum.Font.GothamBlack
Bubble.AutoButtonColor = false
Bubble.Parent = ScreenGui

local BubbleCorner = Instance.new("UICorner")
BubbleCorner.CornerRadius = UDim.new(1, 0)
BubbleCorner.Parent = Bubble

local BubbleStroke = Instance.new("UIStroke")
BubbleStroke.Thickness = 2
BubbleStroke.Parent = Bubble

local BubbleGlow = Instance.new("ImageLabel")
BubbleGlow.BackgroundTransparency = 1
BubbleGlow.Size = UDim2.new(1, 24, 1, 24)
BubbleGlow.Position = UDim2.fromOffset(-12, -12)
BubbleGlow.Image = "rbxassetid://4996892231"
BubbleGlow.ImageTransparency = 0.7
BubbleGlow.Parent = Bubble

--==========================================================
-- MAIN WINDOW
--==========================================================

local Window = Instance.new("Frame")
Window.Name = "MainWindow"
Window.Size = UDim2.fromOffset(620, 430)
Window.Position = UDim2.new(0.5, -310, 0.5, -215)
Window.BackgroundColor3 = Theme.Background
Window.BorderSizePixel = 0
Window.Active = true
Window.Draggable = true
Window.Parent = ScreenGui

local WindowCorner = Instance.new("UICorner")
WindowCorner.CornerRadius = UDim.new(0, 16)
WindowCorner.Parent = Window

local WindowStroke = Instance.new("UIStroke")
WindowStroke.Thickness = 2
WindowStroke.Parent = Window

--==========================================================
-- RGB OUTER GLOW
--==========================================================

local Glow = Instance.new("Frame")
Glow.Name = "RGBGlow"
Glow.Size = UDim2.new(1, 8, 1, 8)
Glow.Position = UDim2.fromOffset(-4, -4)
Glow.BackgroundTransparency = 1
Glow.ZIndex = 0
Glow.Parent = Window

local GlowCorner = Instance.new("UICorner")
GlowCorner.CornerRadius = UDim.new(0, 18)
GlowCorner.Parent = Glow

local GlowStroke = Instance.new("UIStroke")
GlowStroke.Thickness = 5
GlowStroke.Transparency = 0.55
GlowStroke.Parent = Glow

--==========================================================
-- HEADER
--==========================================================

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 72)
Header.BackgroundColor3 = Theme.Panel
Header.BorderSizePixel = 0
Header.Parent = Window

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 16)
HeaderCorner.Parent = Header

-- cover lower rounded corners
local HeaderCover = Instance.new("Frame")
HeaderCover.Size = UDim2.new(1, 0, 0, 18)
HeaderCover.Position = UDim2.new(0, 0, 1, -18)
HeaderCover.BackgroundColor3 = Theme.Panel
HeaderCover.BorderSizePixel = 0
HeaderCover.Parent = Header

--==========================================================
-- TITLE
--==========================================================

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Position = UDim2.fromOffset(20, 9)
Title.Size = UDim2.new(1, -100, 0, 27)
Title.Text = "NO MERCY"
Title.TextColor3 = Theme.Text
Title.TextSize = 22
Title.Font = Enum.Font.GothamBlack
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.BackgroundTransparency = 1
Subtitle.Position = UDim2.fromOffset(21, 38)
Subtitle.Size = UDim2.new(1, -110, 0, 20)
Subtitle.Text = "NEON CONTROL // SYSTEM ONLINE"
Subtitle.TextColor3 = Theme.Dim
Subtitle.TextSize = 9
Subtitle.Font = Enum.Font.GothamMedium
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

--==========================================================
-- STATUS DOT
--==========================================================

local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.fromOffset(10, 10)
StatusDot.Position = UDim2.new(1, -78, 0, 18)
StatusDot.BackgroundColor3 = Theme.Green
StatusDot.Parent = Header

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(1, 0)
StatusCorner.Parent = StatusDot

local StatusText = Instance.new("TextLabel")
StatusText.BackgroundTransparency = 1
StatusText.Position = UDim2.new(1, -62, 0, 14)
StatusText.Size = UDim2.fromOffset(55, 18)
StatusText.Text = "ONLINE"
StatusText.TextColor3 = Theme.Green
StatusText.TextSize = 9
StatusText.Font = Enum.Font.GothamBold
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.Parent = Header

--==========================================================
-- CLOSE BUTTON
--==========================================================

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(30, 30)
Close.Position = UDim2.new(1, -42, 1, -46)
Close.BackgroundColor3 = Theme.Red
Close.Text = "×"
Close.TextColor3 = Theme.Text
Close.TextSize = 20
Close.Font = Enum.Font.GothamBold
Close.AutoButtonColor = false
Close.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = Close

--==========================================================
-- SIDEBAR
--==========================================================

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 145, 1, -88)
Sidebar.Position = UDim2.fromOffset(12, 78)
Sidebar.BackgroundColor3 = Theme.Panel
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Window

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 12)
SidebarCorner.Parent = Sidebar

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.Padding = UDim.new(0, 6)
SidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Parent = Sidebar

local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingTop = UDim.new(0, 10)
SidebarPadding.PaddingLeft = UDim.new(0, 8)
SidebarPadding.PaddingRight = UDim.new(0, 8)
SidebarPadding.Parent = Sidebar

--==========================================================
-- CONTENT
--==========================================================

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -170, 1, -88)
Content.Position = UDim2.fromOffset(158, 78)
Content.BackgroundColor3 = Theme.Panel
Content.BorderSizePixel = 0
Content.Parent = Window

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 12)
ContentCorner.Parent = Content

--==========================================================
-- TAB SYSTEM
--==========================================================

local Tabs = {}
local CurrentTab = nil

local function CreateTab(name, icon)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 0, 42)
    Button.BackgroundColor3 = Theme.Panel2
    Button.Text = "   " .. icon .. "   " .. name
    Button.TextColor3 = Theme.Dim
    Button.TextSize = 10
    Button.Font = Enum.Font.GothamBold
    Button.TextXAlignment = Enum.TextXAlignment.Left
    Button.AutoButtonColor = false
    Button.Parent = Sidebar

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 9)
    Corner.Parent = Button

    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.fromOffset(3, 22)
    Indicator.Position = UDim2.new(0, 4, 0.5, -11)
    Indicator.BackgroundColor3 = Theme.Accent
    Indicator.BackgroundTransparency = 1
    Indicator.Parent = Button

    local IndicatorCorner = Instance.new("UICorner")
    IndicatorCorner.CornerRadius = UDim.new(1, 0)
    IndicatorCorner.Parent = Indicator

    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.new(1, -20, 1, -20)
    Page.Position = UDim2.fromOffset(10, 10)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 2
    Page.CanvasSize = UDim2.new()
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.Visible = false
    Page.Parent = Content

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 9)
    Layout.Parent = Page

    local Padding = Instance.new("UIPadding")
    Padding.PaddingBottom = UDim.new(0, 12)
    Padding.Parent = Page

    local tab = {
        Button = Button,
        Page = Page,
        Indicator = Indicator,
    }

    Tabs[name] = tab

    Button.MouseButton1Click:Connect(function()
        for _, t in pairs(Tabs) do
            t.Page.Visible = false

            TweenService:Create(
                t.Button,
                TweenInfo.new(0.2),
                {
                    BackgroundColor3 = Theme.Panel2,
                    TextColor3 = Theme.Dim,
                }
            ):Play()

            TweenService:Create(
                t.Indicator,
                TweenInfo.new(0.2),
                {
                    BackgroundTransparency = 1,
                }
            ):Play()
        end

        Page.Visible = true
        CurrentTab = name

        TweenService:Create(
            Button,
            TweenInfo.new(0.2),
            {
                BackgroundColor3 = Theme.Accent,
                TextColor3 = Theme.Text,
            }
        ):Play()

        TweenService:Create(
            Indicator,
            TweenInfo.new(0.2),
            {
                BackgroundTransparency = 0,
            }
        ):Play()
    end)

    return Page
end

local MainTab = CreateTab("Dashboard", "◆")
local VisualTab = CreateTab("Visuals", "◈")
local SettingsTab = CreateTab("Settings", "⚙")

--==========================================================
-- CARD
--==========================================================

local function CreateCard(parent, title, description)
    local Card = Instance.new("Frame")
    Card.Size = UDim2.new(1, 0, 0, 70)
    Card.BackgroundColor3 = Theme.Panel2
    Card.BorderSizePixel = 0
    Card.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = Card

    local Stroke = Instance.new("UIStroke")
    Stroke.Thickness = 1
    Stroke.Transparency = 0.7
    Stroke.Parent = Card

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Position = UDim2.fromOffset(13, 10)
    TitleLabel.Size = UDim2.new(1, -25, 0, 20)
    TitleLabel.Text = title
    TitleLabel.TextColor3 = Theme.Text
    TitleLabel.TextSize = 12
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Card

    local Desc = Instance.new("TextLabel")
    Desc.BackgroundTransparency = 1
    Desc.Position = UDim2.fromOffset(13, 33)
    Desc.Size = UDim2.new(1, -25, 0, 25)
    Desc.Text = description
    Desc.TextColor3 = Theme.Dim
    Desc.TextSize = 9
    Desc.Font = Enum.Font.Gotham
    Desc.TextXAlignment = Enum.TextXAlignment.Left
    Desc.TextWrapped = true
    Desc.Parent = Card

    return Card
end

--==========================================================
-- TOGGLE
--==========================================================

local function CreateToggle(parent, text, default, callback)
    local Holder = Instance.new("Frame")
    Holder.Size = UDim2.new(1, 0, 0, 50)
    Holder.BackgroundColor3 = Theme.Panel2
    Holder.BorderSizePixel = 0
    Holder.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = Holder

    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.fromOffset(14, 0)
    Label.Size = UDim2.new(1, -75, 1, 0)
    Label.Text = text
    Label.TextColor3 = Theme.Text
    Label.TextSize = 10
    Label.Font = Enum.Font.GothamBold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Holder

    local Switch = Instance.new("TextButton")
    Switch.Size = UDim2.fromOffset(42, 22)
    Switch.Position = UDim2.new(1, -55, 0.5, -11)
    Switch.BackgroundColor3 = default and Theme.Green or Color3.fromRGB(55, 55, 70)
    Switch.Text = ""
    Switch.AutoButtonColor = false
    Switch.Parent = Holder

    local SwitchCorner = Instance.new("UICorner")
    SwitchCorner.CornerRadius = UDim.new(1, 0)
    SwitchCorner.Parent = Switch

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.fromOffset(16, 16)
    Knob.Position = default
        and UDim2.new(1, -19, 0.5, -8)
        or UDim2.new(0, 3, 0.5, -8)
    Knob.BackgroundColor3 = Theme.Text
    Knob.Parent = Switch

    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(1, 0)
    KnobCorner.Parent = Knob

    local State = default

    Switch.MouseButton1Click:Connect(function()
        State = not State

        TweenService:Create(
            Switch,
            TweenInfo.new(0.22, Enum.EasingStyle.Quint),
            {
                BackgroundColor3 = State
                    and Theme.Green
                    or Color3.fromRGB(55, 55, 70),
            }
        ):Play()

        TweenService:Create(
            Knob,
            TweenInfo.new(0.22, Enum.EasingStyle.Back),
            {
                Position = State
                    and UDim2.new(1, -19, 0.5, -8)
                    or UDim2.new(0, 3, 0.5, -8),
            }
        ):Play()

        if callback then
            callback(State)
        end
    end)

    return Holder
end

--==========================================================
-- DASHBOARD
--==========================================================

CreateCard(
    MainTab,
    "NO MERCY // CONTROL CENTER",
    "Futuristic interface initialized successfully."
)

CreateToggle(
    MainTab,
    "Neon Interface",
    true,
    function(state)
        WindowStroke.Transparency = state and 0 or 1
    end
)

CreateToggle(
    MainTab,
    "RGB LED Animation",
    true,
    function(state)
        Config.RGBEnabled = state
    end
)

CreateToggle(
    MainTab,
    "UI Glow",
    true,
    function(state)
        GlowStroke.Transparency = state and 0.55 or 1
    end
)

--==========================================================
-- VISUALS
--==========================================================

CreateCard(
    VisualTab,
    "VISUAL ENGINE",
    "Animated neon effects and futuristic HUD elements."
)

CreateToggle(
    VisualTab,
    "RGB Border",
    true,
    function(state)
        Config.RGBEnabled = state
    end
)

CreateToggle(
    VisualTab,
    "Pulse Status",
    true,
    function(state)
        Config.Pulse = state
    end
)

CreateToggle(
    VisualTab,
    "Glow Effects",
    true,
    function(state)
        Config.Glow = state
        GlowStroke.Transparency = state and 0.55 or 1
    end
)

--==========================================================
-- SETTINGS
--==========================================================

CreateCard(
    SettingsTab,
    "INTERFACE SETTINGS",
    "Customize the appearance of No Mercy."
)

CreateToggle(
    SettingsTab,
    "Compact Mode",
    false,
    function(state)
        if state then
            UIScale.Scale = 0.68
        else
            UpdateScale()
        end
    end
)

CreateToggle(
    SettingsTab,
    "Animated Header",
    true,
    function(state)
        Config.HeaderAnimation = state
    end
)

--==========================================================
-- DEFAULT TAB
--==========================================================

Tabs["Dashboard"].Page.Visible = true
Tabs["Dashboard"].Button.BackgroundColor3 = Theme.Accent
Tabs["Dashboard"].Button.TextColor3 = Theme.Text
Tabs["Dashboard"].Indicator.BackgroundTransparency = 0
CurrentTab = "Dashboard"

--==========================================================
-- BUTTON HOVER EFFECT
--==========================================================

local function AddHover(button)
    local original = button.BackgroundColor3

    button.MouseEnter:Connect(function()
        TweenService:Create(
            button,
            TweenInfo.new(0.15),
            {
                BackgroundTransparency = 0.15,
            }
        ):Play()
    end)

    button.MouseLeave:Connect(function()
        TweenService:Create(
            button,
            TweenInfo.new(0.15),
            {
                BackgroundTransparency = 0,
            }
        ):Play()
    end)
end

AddHover(Close)
AddHover(Bubble)

--==========================================================
-- OPEN / CLOSE ANIMATION
--==========================================================

local OpenSize = Window.Size

local function OpenUI()
    Window.Visible = true

    Window.Size = UDim2.fromOffset(
        OpenSize.X.Offset * 0.88,
        OpenSize.Y.Offset * 0.88
    )

    Window.BackgroundTransparency = 1

    TweenService:Create(
        Window,
        TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = OpenSize,
            BackgroundTransparency = 0,
        }
    ):Play()
end

local function CloseUI()
    local tween = TweenService:Create(
        Window,
        TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
        {
            Size = UDim2.fromOffset(
                OpenSize.X.Offset * 0.88,
                OpenSize.Y.Offset * 0.88
            ),
            BackgroundTransparency = 1,
        }
    )

    tween:Play()

    tween.Completed:Connect(function()
        Window.Visible = false
    end)
end

Close.MouseButton1Click:Connect(CloseUI)

Bubble.MouseButton1Click:Connect(function()
    if Window.Visible then
        CloseUI()
    else
        OpenUI()
    end
end)

--==========================================================
-- RGB ENGINE
--==========================================================

local Hue = 0
local PulseTime = 0

RunService.RenderStepped:Connect(function(dt)
    Hue = (Hue + dt * Config.RGBSpeed) % 1
    PulseTime += dt

    local rgb = Color3.fromHSV(Hue, 0.85, 1)

    if Config.RGBEnabled ~= false then
        WindowStroke.Color = rgb
        GlowStroke.Color = rgb
        BubbleStroke.Color = rgb
    end

    if Config.Pulse ~= false then
        local pulse = (math.sin(PulseTime * Config.GlowSpeed) + 1) / 2

        StatusDot.BackgroundTransparency = pulse * 0.25
        GlowStroke.Transparency = 0.35 + pulse * 0.35
    end

    if Config.HeaderAnimation ~= false then
        local titlePulse =
            (math.sin(PulseTime * 1.5) + 1) / 2

        Title.TextColor3 = Color3.new(
            0.88 + titlePulse * 0.12,
            0.88 + titlePulse * 0.12,
            1
        )
    end
end)

--==========================================================
-- STATUS ANIMATION
--==========================================================

task.spawn(function()
    while ScreenGui.Parent do
        StatusText.Text = "ONLINE"
        task.wait(1)

        StatusText.Text = "READY"
        task.wait(1)

        StatusText.Text = "ONLINE"
        task.wait(1)
    end
end)

--==========================================================
-- STARTUP ANIMATION
--==========================================================

Window.Visible = true
Window.Size = UDim2.fromOffset(540, 375)
Window.BackgroundTransparency = 1

TweenService:Create(
    Window,
    TweenInfo.new(
        0.55,
        Enum.EasingStyle.Back,
        Enum.EasingDirection.Out
    ),
    {
        Size = OpenSize,
        BackgroundTransparency = 0,
    }
):Play()

--==========================================================
-- DONE
--==========================================================

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("   NO MERCY NEON UI")
print("   RGB ENGINE : ONLINE")
print("   GLOW FX    : ONLINE")
print("   MOBILE UI  : READY")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
