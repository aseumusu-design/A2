local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- WINDOW UTAMA
local Window = Fluent:CreateWindow({
    Title = "NO MERCY",
    SubTitle = "Violence District",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- BUBBLE TOGGLE BUTTON (LOGO NINJA)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NoMercyBubbleGui"
ScreenGui.Parent = (gethui and gethui()) or game:GetService("CoreGui") or game.Players.LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

local BubbleBtn = Instance.new("ImageButton")
BubbleBtn.Name = "BubbleButton"
BubbleBtn.Parent = ScreenGui
BubbleBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 35)
BubbleBtn.Position = UDim2.new(0.02, 0, 0.2, 0)
BubbleBtn.Size = UDim2.new(0, 48, 0, 48)

BubbleBtn.Image = "rbxassetid://102609928046926"
BubbleBtn.ScaleType = Enum.ScaleType.Fit
BubbleBtn.Active = true
BubbleBtn.Draggable = true

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = BubbleBtn

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(50, 60, 70)
UIStroke.Thickness = 2
UIStroke.Parent = BubbleBtn

-- KLIK BUBBLE UNTUK BUKA / TUTUP MENU
BubbleBtn.MouseButton1Click:Connect(function()
    if Window.Root then
        Window.Root.Visible = not Window.Root.Visible
    end
end)

-- TAB & IKON (TAMBAH TAB AIMBOT DENGAN IKON CROSSHAIR/PISTOL)
local Tabs = {
    Info     = Window:AddTab({ Title = "Info", Icon = "info" }),
    Aimbot   = Window:AddTab({ Title = "Aimbot", Icon = "crosshair" }), -- TAB AIMBOT
    Parry    = Window:AddTab({ Title = "Parry", Icon = "swords" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "disc" }),
    Killer   = Window:AddTab({ Title = "Killer", Icon = "sword" }),
    Survivor = Window:AddTab({ Title = "Survivor", Icon = "user" }),
    Visual   = Window:AddTab({ Title = "Visual", Icon = "eye" }),
    Misc     = Window:AddTab({ Title = "Misc", Icon = "settings" }),
    Config   = Window:AddTab({ Title = "Config", Icon = "save" })
}

do
    Fluent:Notify({
        Title = "NO MERCY",
        Content = "Script berhasil dimuat!",
        Duration = 5
    })

    -- TAB INFO
    Tabs.Info:AddParagraph({
        Title = "NO MERCY Hub  |  v1.0.0",
        Content = "Hi! Welcome to NO MERCY Script."
    })

    Tabs.Info:AddParagraph({
        Title = "💬 Community NO MERCY",
        Content = "Gabung untuk update & support.\nMade by No Mercy Team — features: Aimbot, Parry, Teleport, ESP, Hitbox & many more."
    })

    Tabs.Info:AddButton({
        Title = "Copy Invite Discord",
        Description = "https://discord.gg/pbg6g79Hp",
        Callback = function()
            if setclipboard then
                setclipboard("https://discord.gg/pbg6g79Hp")
                Fluent:Notify({ Title = "NO MERCY", Content = "Link Discord berhasil di-copy!", Duration = 3 })
            end
        end
    })

    Tabs.Info:AddButton({
        Title = "Copy Link TikTok",
        Description = "@mlbb1vs1_mode.id",
        Callback = function()
            if setclipboard then
                setclipboard("https://www.tiktok.com/@mlbb1vs1_mode.id?_r=1&_t=ZS-98nR50clSKY")
                Fluent:Notify({ Title = "NO MERCY", Content = "Link Discord berhasil di-copy!", Duration = 3 })
            end
        end
    })

    -- ==================== TAB AIMBOT ====================
    local AimbotToggle = Tabs.Aimbot:AddToggle("EnableAimbot", { Title = "Enable Aimbot", Default = false })
    
    local TargetPartDropdown = Tabs.Aimbot:AddDropdown("TargetPart", {
        Title = "Target Body Part",
        Values = {"Head", "HumanoidRootPart", "Torso"},
        Multi = false,
        Default = 1,
    })

    local FOVSlider = Tabs.Aimbot:AddSlider("FOVRadius", {
        Title = "Aimbot FOV Radius",
        Description = "Ukuran lingkaran pemicu lock target",
        Default = 100,
        Min = 20,
        Max = 500,
        Rounding = 0,
        Callback = function(Value) end
    })

    local SmoothSlider = Tabs.Aimbot:AddSlider("AimbotSmoothness", {
        Title = "Smoothness",
        Description = "Kehalusan gerakan aim (makin kecil makin patah/cepet)",
        Default = 5,
        Min = 1,
        Max = 20,
        Rounding = 0,
        Callback = function(Value) end
    })

    local ShowFOVToggle = Tabs.Aimbot:AddToggle("ShowFOVCircle", { Title = "Show FOV Circle", Default = true })

    -- TAB PARRY
    Tabs.Parry:AddToggle("AutoParry", { Title = "Enable Auto Parry", Default = false })
    Tabs.Parry:AddDropdown("ParryMode", { Title = "Parry Mode", Values = {"Always", "On Distance", "Hold Key"}, Default = 1 })
    Tabs.Parry:AddSlider("ParryDistance", { Title = "Parry Distance", Default = 15, Min = 5, Max = 50, Rounding = 0 })

    -- TAB TELEPORT
    Tabs.Teleport:AddButton({ Title = "Teleport to Safe Zone", Callback = function() end })

    -- TAB SURVIVOR
    Tabs.Survivor:AddSlider("WalkSpeed", {
        Title = "WalkSpeed", Default = 16, Min = 16, Max = 200, Rounding = 0,
        Callback = function(Value)
            if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
                game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
            end
        end
    })
end

-- Save & Interface Manager
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder("NoMercyHub")
SaveManager:SetFolder("NoMercyHub/violence-district")

InterfaceManager:BuildInterfaceSection(Tabs.Config)
SaveManager:BuildConfigSection(Tabs.Config)

Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()
