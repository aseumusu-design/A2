-- ============================================================
--  NO MERCY — "VIOLENCE DISTRICT"
--  UI: Orion (MarV) — hide/show via bubble + konfirmasi tutup
-- ============================================================

local ICON = {
    Info     = "rbxassetid://7733964719",
    Crosshair= "rbxassetid://7733765307",
    Swords   = "rbxassetid://7734056608",
    Globe    = "rbxassetid://7733954760",
    Axe      = "rbxassetid://7733674079",
    User     = "rbxassetid://7743875962",
    Eye      = "rbxassetid://7733774602",
    Zap      = "rbxassetid://7733771628",
    Settings = "rbxassetid://7734053495",
    Logo     = "rbxassetid://102609928046926",
    Banner   = "rbxassetid://138968189462646",
}

local TweenService = game:GetService("TweenService")

local function GetHolder()
    return (gethui and gethui()) or game:GetService("CoreGui")
end

-- ============================================================
--  WELCOME INTRO ANIMATION (Garis Hitam-Putih Elegan)
-- ============================================================
local function ShowWelcomeIntro()
    local holder = GetHolder()
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "NoMercyWelcome"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    gui.Parent = holder
    if syn and syn.protect_gui then pcall(syn.protect_gui, gui) end

    local img = Instance.new("ImageLabel")
    img.Size = UDim2.fromOffset(0, 0)
    img.Position = UDim2.new(0.5, 0, 0.5, 0)
    img.AnchorPoint = Vector2.new(0.5, 0.5)
    img.Image = ICON.Logo
    img.BackgroundTransparency = 1
    img.ZIndex = 999
    img.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = img

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(220, 220, 220) -- Garis Hitam-Putih / Abu terang
    stroke.Thickness = 4
    stroke.Transparency = 1
    stroke.Parent = img

    local tweenIn = TweenService:Create(img, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(180, 180)
    })
    local strokeIn = TweenService:Create(stroke, TweenInfo.new(0.4), { Transparency = 0 })
    
    tweenIn:Play()
    strokeIn:Play()
    tweenIn.Completed:Wait()

    task.wait(1.2)

    local tweenOut = TweenService:Create(img, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.fromOffset(0, 0)
    })
    local strokeOut = TweenService:Create(stroke, TweenInfo.new(0.3), { Transparency = 1 })
    
    tweenOut:Play()
    strokeOut:Play()
    tweenOut.Completed:Wait()

    gui:Destroy()
end

ShowWelcomeIntro()

local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Marpiii/UiLib/refs/heads/main/source.lua"))()

local onCloseRequest

local Window = OrionLib:MakeWindow({
    Name = "NO MERCY — VIOLENCE DISTRICT",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "NoMercyViolence",
    IntroEnabled = false,
    Icon = ICON.Logo,
    CloseCallback = function()
        if onCloseRequest then onCloseRequest() end
    end,
})

local function FindMainWindow()
    local root = GetHolder()
    if not root then return nil end
    local marv = root:FindFirstChild("MarV")
    if not marv then return nil end

    for _, child in ipairs(marv:GetChildren()) do
        if child:IsA("Frame") and child.AbsoluteSize.X > 300 then
            return child
        end
    end
    return nil
end

local bubbleGui = nil

local function makeBubble()
    if bubbleGui then bubbleGui:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "NoMercyBubble"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    gui.Parent = GetHolder()
    if syn and syn.protect_gui then pcall(syn.protect_gui, gui) end

    local btn = Instance.new("ImageButton")
    btn.Parent = gui
    btn.BackgroundColor3 = Color3.fromRGB(25, 30, 35)
    btn.Position = UDim2.new(0.02, 0, 0.2, 0)
    btn.Size = UDim2.fromOffset(48, 48)
    btn.Image = ICON.Logo
    btn.ScaleType = Enum.ScaleType.Fit
    btn.Active = true
    btn.Draggable = true
    btn.ZIndex = 10

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(200, 200, 200) -- Garis Hitam-Putih
    stroke.Thickness = 2
    stroke.Parent = btn

    btn.MouseButton1Click:Connect(function()
        local main = FindMainWindow()
        if main then
            main.Visible = true
        end
        bubbleGui:Destroy()
        bubbleGui = nil
    end)

    bubbleGui = gui
end

local function closeUI()
    local main = FindMainWindow()
    if main then
        main.Visible = false
    end
    makeBubble()
end

local function showUI()
    local main = FindMainWindow()
    if main then
        main.Visible = true
    end
end

local function confirmClose(fromCloseBtn)
    if fromCloseBtn then
        showUI()
    end

    local holder = GetHolder()
    local gui = Instance.new("ScreenGui")
    gui.Name = "NoMercyConfirm"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    gui.Parent = holder
    if syn and syn.protect_gui then pcall(syn.protect_gui, gui) end

    local fade = Instance.new("Frame")
    fade.Size = UDim2.new(1, 0, 1, 0)
    fade.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    fade.BackgroundTransparency = 0.4
    fade.ZIndex = 99
    fade.Parent = gui

    local box = Instance.new("Frame")
    box.Size = UDim2.fromOffset(280, 150)
    box.Position = UDim2.new(0.5, 0, 0.5, 0)
    box.AnchorPoint = Vector2.new(0.5, 0.5)
    box.BackgroundColor3 = Color3.fromRGB(28, 32, 38)
    box.BorderSizePixel = 0
    box.ZIndex = 100
    box.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = box

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 30)
    title.Position = UDim2.new(0, 20, 0, 15)
    title.BackgroundTransparency = 1
    title.Text = "Tutup NO MERCY?"
    title.TextColor3 = Color3.fromRGB(240, 240, 240)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 101
    title.Parent = box

    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, -40, 0, 30)
    desc.Position = UDim2.new(0, 20, 0, 48)
    desc.BackgroundTransparency = 1
    desc.Text = "Klik bubble untuk buka lagi."
    desc.TextColor3 = Color3.fromRGB(150, 150, 150)
    desc.TextSize = 14
    desc.Font = Enum.Font.Gotham
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.ZIndex = 101
    desc.Parent = box

    local function destroy()
        gui:Destroy()
    end

    local function cancel()
        destroy()
        if fromCloseBtn then
            showUI()
        end
    end

    local btnYa = Instance.new("TextButton")
    btnYa.Size = UDim2.fromOffset(90, 36)
    btnYa.Position = UDim2.new(1, -200, 1, -50)
    btnYa.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btnYa.BorderSizePixel = 0
    btnYa.Text = "Ya"
    btnYa.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnYa.TextSize = 15
    btnYa.Font = Enum.Font.GothamBold
    btnYa.ZIndex = 101
    btnYa.Parent = box
    local cYa = Instance.new("UICorner"); cYa.CornerRadius = UDim.new(0, 8); cYa.Parent = btnYa

    btnYa.MouseButton1Click:Connect(function()
        destroy()
        closeUI()
    end)

    local btnTidak = Instance.new("TextButton")
    btnTidak.Size = UDim2.fromOffset(90, 36)
    btnTidak.Position = UDim2.new(1, -100, 1, -50)
    btnTidak.BackgroundColor3 = Color3.fromRGB(40, 45, 52)
    btnTidak.BorderSizePixel = 0
    btnTidak.Text = "Tidak"
    btnTidak.TextColor3 = Color3.fromRGB(240, 240, 240)
    btnTidak.TextSize = 15
    btnTidak.Font = Enum.Font.GothamBold
    btnTidak.ZIndex = 101
    btnTidak.Parent = box
    local cT = Instance.new("UICorner"); cT.CornerRadius = UDim.new(0, 8); cT.Parent = btnTidak

    btnTidak.MouseButton1Click:Connect(cancel)
    fade.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            cancel()
        end
    end)
end

onCloseRequest = function()
    confirmClose(true)
end

-- ============================================================
--  TAB
-- ============================================================
local InfoTab     = Window:MakeTab({ Name = "Info", Icon = ICON.Info, PremiumOnly = false })
local ParryTab    = Window:MakeTab({ Name = "Parry", Icon = ICON.Swords, PremiumOnly = false })
local TeleportTab = Window:MakeTab({ Name = "Teleport", Icon = ICON.Globe, PremiumOnly = false })
local KillerTab   = Window:MakeTab({ Name = "Killer", Icon = ICON.Axe, PremiumOnly = false })
local SurvivorTab = Window:MakeTab({ Name = "Survivor", Icon = ICON.User, PremiumOnly = false })
local VisualTab   = Window:MakeTab({ Name = "Visual", Icon = ICON.Eye, PremiumOnly = false })
local SpeedTab    = Window:MakeTab({ Name = "Speed", Icon = ICON.Zap, PremiumOnly = false })
local SettingsTab = Window:MakeTab({ Name = "Pengaturan", Icon = ICON.Settings, PremiumOnly = false })

-- ============================================================
--  INFO (Dengan Banner Foto No Mercy yang Dijamin Muncul)
-- ============================================================
local InfoSec = InfoTab:AddSection({ Name = "Tentang" })

InfoSec:AddLabel("NO MERCY — Violence District")
InfoSec:AddLabel("Game: Bola Pedang (Blade Ball)")
InfoSec:AddButton({
    Name = "Copy Link Discord",
    Callback = function()
        if setclipboard then setclipboard("https://discord.gg/pbg6g79Hp") end
        OrionLib:MakeNotification({ Name = "NO MERCY", Content = "Link Discord di-copy!", Image = ICON.Logo, Time = 3 })
    end,
})

-- Sistem Injeksi Banner Stabil untuk Orion UI
task.spawn(function()
    task.wait(0.4)
    local main = FindMainWindow()
    if not main then return end

    for _, v in ipairs(main:GetDescendants()) do
        if v:IsA("TextLabel") and v.Text == "NO MERCY — Violence District" then
            local scrollingFrame = v.Parent.Parent
            if scrollingFrame and scrollingFrame:IsA("ScrollingFrame") then
                local bannerFrame = Instance.new("Frame")
                bannerFrame.Name = "NoMercyBanner"
                bannerFrame.Size = UDim2.new(1, -10, 0, 110)
                bannerFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
                bannerFrame.BorderSizePixel = 0
                bannerFrame.LayoutOrder = -5 -- Biar posisi otomatis ditaruh paling atas
                bannerFrame.Parent = scrollingFrame

                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 8)
                corner.Parent = bannerFrame

                local bannerImg = Instance.new("ImageLabel")
                bannerImg.Size = UDim2.new(1, 0, 1, 0)
                bannerImg.Image = ICON.Banner
                bannerImg.BackgroundTransparency = 1
                bannerImg.ScaleType = Enum.ScaleType.Crop
                bannerImg.Parent = bannerFrame

                local imgCorner = Instance.new("UICorner")
                imgCorner.CornerRadius = UDim.new(0, 8)
                imgCorner.Parent = bannerImg
                break
            end
        end
    end
end)

-- ============================================================
--  PARRY
-- ============================================================
local ParrySec = ParryTab:AddSection({ Name = "Auto Parry" })
ParrySec:AddToggle({ Name = "Enable Auto Parry", Default = false, Callback = function(v) print("AutoParry:", v) end })
ParrySec:AddDropdown({
    Name = "Parry Mode",
    Default = "Always",
    Options = { "Always", "On Distance", "Hold Key" },
    Callback = function(v) print("ParryMode:", v) end,
})
ParrySec:AddSlider({ Name = "Parry Distance", Min = 5, Max = 50, Default = 15, Increment = 1, ValueName = "studs", Callback = function(v) print("ParryDistance:", v) end })

-- ============================================================
--  TELEPORT
-- ============================================================
local TeleSec = TeleportTab:AddSection({ Name = "Teleport" })
TeleSec:AddButton({
    Name = "Teleport to Safe Zone",
    Callback = function()
        OrionLib:MakeNotification({ Name = "NO MERCY", Content = "Teleporting...", Image = ICON.Logo, Time = 2 })
    end,
})

-- ============================================================
--  KILLER
-- ============================================================
local KillerSec = KillerTab:AddSection({ Name = "Killer" })
KillerSec:AddToggle({ Name = "Killer Mode", Default = false, Callback = function(v) print("KillerMode:", v) end })
KillerSec:AddButton({ Name = "Kill All", Callback = function() print("Kill all") end })

-- ============================================================
--  SURVIVOR
-- ============================================================
local SurvivorSec = SurvivorTab:AddSection({ Name = "Survivor" })
SurvivorSec:AddToggle({ Name = "Survivor Mode", Default = false, Callback = function(v) print("SurvivorMode:", v) end })

-- ============================================================
--  VISUAL
-- ============================================================
local VisualSec = VisualTab:AddSection({ Name = "Visual" })
VisualSec:AddToggle({ Name = "ESP Players", Default = false, Callback = function(v) print("ESP:", v) end })
VisualSec:AddToggle({ Name = "Show FOV Circle", Default = true, Callback = function(v) print("FOVCircle:", v) end })

-- ============================================================
--  SPEED
-- ============================================================
local SpeedSec = SpeedTab:AddSection({ Name = "Speed" })
SpeedSec:AddSlider({
    Name = "WalkSpeed", Min = 16, Max = 200, Default = 16, Increment = 1, ValueName = "speed",
    Callback = function(v)
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed = v end
    end,
})

-- ============================================================
--  PENGATURAN
-- ============================================================
local SettingsSec = SettingsTab:AddSection({ Name = "Pengaturan" })

SettingsSec:AddButton({
    Name = "Tutup UI (Close)",
    Callback = function()
        confirmClose()
    end,
})

-- ============================================================
--  NOTIFIKASI LOAD
-- ============================================================
OrionLib:MakeNotification({ Name = "NO MERCY", Content = "Violence District dimuat!", Image = ICON.Logo, Time = 4 })

print("[NO MERCY] Violence District loaded successfully!")
