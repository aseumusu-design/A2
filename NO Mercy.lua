--[[
  NO MERCY — "VIOLENCE DISTRICT" (Dengan Efek Teks Bercahaya / Glow Pulse)
  UI: Orion (MarV) — hide/show via bubble + konfirmasi tutup
]]

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
local RunService = game:GetService("RunService")

local function GetHolder()
    return (gethui and gethui()) or game:GetService("CoreGui")
end

-- ============================================================
--  WELCOME INTRO
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

    local centerFrame = Instance.new("Frame")
    centerFrame.Size = UDim2.fromOffset(260, 260)
    centerFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    centerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    centerFrame.BackgroundTransparency = 1
    centerFrame.ZIndex = 999
    centerFrame.Parent = gui

    local img = Instance.new("ImageLabel")
    img.Size = UDim2.fromOffset(0, 0)
    img.Position = UDim2.new(0.5, 0, 0.4, 0)
    img.AnchorPoint = Vector2.new(0.5, 0.5)
    img.Image = ICON.Logo
    img.BackgroundTransparency = 1
    img.ZIndex = 999
    img.Parent = centerFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = img

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 4
    stroke.Transparency = 1
    stroke.Parent = img

    local introText = Instance.new("TextLabel")
    introText.Size = UDim2.new(1, 0, 0, 40)
    introText.Position = UDim2.new(0.5, 0, 0.75, 0)
    introText.AnchorPoint = Vector2.new(0.5, 0)
    introText.BackgroundTransparency = 1
    introText.Text = "WELCOME NO MERCY"
    introText.TextColor3 = Color3.fromRGB(255, 255, 255)
    introText.TextSize = 18
    introText.Font = Enum.Font.GothamBold
    introText.TextTransparency = 1
    introText.ZIndex = 999
    introText.Parent = centerFrame

    local tweenIn = TweenService:Create(img, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(150, 150) })
    local strokeIn = TweenService:Create(stroke, TweenInfo.new(0.4), { Transparency = 0 })
    local textIn = TweenService:Create(introText, TweenInfo.new(0.4), { TextTransparency = 0 })
    
    tweenIn:Play(); strokeIn:Play(); textIn:Play()
    tweenIn.Completed:Wait()

    local pulsing = true
    task.spawn(function()
        while pulsing do
            local t1 = TweenService:Create(stroke, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Transparency = 0.8, Thickness = 6 })
            t1:Play(); t1.Completed:Wait()
            if not pulsing then break end
            local t2 = TweenService:Create(stroke, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Transparency = 0, Thickness = 2 })
            t2:Play(); t2.Completed:Wait()
        end
    end)

    task.wait(1.5)
    pulsing = false

    local tweenOut = TweenService:Create(img, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = UDim2.fromOffset(0, 0) })
    local strokeOut = TweenService:Create(stroke, TweenInfo.new(0.3), { Transparency = 1 })
    local textOut = TweenService:Create(introText, TweenInfo.new(0.3), { TextTransparency = 1 })
    
    tweenOut:Play(); strokeOut:Play(); textOut:Play()
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

-- ============================================================
--  BUBBLE LOGO
-- ============================================================
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
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 2
    stroke.Transparency = 0
    stroke.Parent = btn

    local bubblePulsing = true
    task.spawn(function()
        while bubblePulsing and stroke and stroke.Parent do
            local t1 = TweenService:Create(stroke, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Transparency = 0.8, Thickness = 4 })
            t1:Play(); t1.Completed:Wait()
            if not bubblePulsing or not stroke or not stroke.Parent then break end
            local t2 = TweenService:Create(stroke, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Transparency = 0, Thickness = 2 })
            t2:Play(); t2.Completed:Wait()
        end
    end)

    btn.MouseButton1Click:Connect(function()
        bubblePulsing = false
        local main = FindMainWindow()
        if main then main.Visible = true end
        bubbleGui:Destroy()
        bubbleGui = nil
    end)

    bubbleGui = gui
end

local function closeUI()
    local main = FindMainWindow()
    if main then main.Visible = false end
    makeBubble()
end

local function showUI()
    local main = FindMainWindow()
    if main then main.Visible = true end
end

local function confirmClose(fromCloseBtn)
    if fromCloseBtn then showUI() end
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

    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 12)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 30)
    title.Position = UDim2.new(0, 20, 0, 15)
    title.BackgroundTransparency = 1
    title.Text = "Tutup NO MERCY?"
    title.TextColor3 = Color3.fromRGB(240, 240, 240)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
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
    desc.ZIndex = 101
    desc.Parent = box

    local function destroy() gui:Destroy() end
    local function cancel() destroy(); if fromCloseBtn then showUI() end end

    local btnYa = Instance.new("TextButton")
    btnYa.Size = UDim2.fromOffset(90, 36)
    btnYa.Position = UDim2.new(1, -200, 1, -50)
    btnYa.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btnYa.Text = "Ya"
    btnYa.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnYa.Font = Enum.Font.GothamBold
    btnYa.ZIndex = 101
    btnYa.Parent = box
    Instance.new("UICorner", btnYa).CornerRadius = UDim.new(0, 8)
    btnYa.MouseButton1Click:Connect(function() destroy(); closeUI() end)

    local btnTidak = Instance.new("TextButton")
    btnTidak.Size = UDim2.fromOffset(90, 36)
    btnTidak.Position = UDim2.new(1, -100, 1, -50)
    btnTidak.BackgroundColor3 = Color3.fromRGB(40, 45, 52)
    btnTidak.Text = "Tidak"
    btnTidak.TextColor3 = Color3.fromRGB(240, 240, 240)
    btnTidak.Font = Enum.Font.GothamBold
    btnTidak.ZIndex = 101
    btnTidak.Parent = box
    Instance.new("UICorner", btnTidak).CornerRadius = UDim.new(0, 8)
    btnTidak.MouseButton1Click:Connect(cancel)
end

onCloseRequest = function() confirmClose(true) end

-- ============================================================
--  TAB
-- ============================================================
local InfoTab     = Window:MakeTab({ Name = "Info", Icon = ICON.Info, PremiumOnly = false })
local AimbotTab   = Window:MakeTab({ Name = "Aimbot", Icon = ICON.Crosshair, PremiumOnly = false })[span_0](start_span)[span_0](end_span)
local ParryTab    = Window:MakeTab({ Name = "Parry", Icon = ICON.Swords, PremiumOnly = false })
local TeleportTab = Window:MakeTab({ Name = "Teleport", Icon = ICON.Globe, PremiumOnly = false })
local KillerTab   = Window:MakeTab({ Name = "Killer", Icon = ICON.Axe, PremiumOnly = false })
local SurvivorTab = Window:MakeTab({ Name = "Survivor", Icon = ICON.User, PremiumOnly = false })
local VisualTab   = Window:MakeTab({ Name = "Visual", Icon = ICON.Eye, PremiumOnly = false })
local SpeedTab    = Window:MakeTab({ Name = "Speed", Icon = ICON.Zap, PremiumOnly = false })
local SettingsTab = Window:MakeTab({ Name = "Pengaturan", Icon = ICON.Settings, PremiumOnly = false })

-- ============================================================
--  INFO (Banner & Glow Effect Otomatis pada Teks Judul UI)
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

task.spawn(function()
    task.wait(0.3)
    local main = FindMainWindow()
    if not main then return end

    for _, v in ipairs(main:GetDescendants()) do
        if v:IsA("TextLabel") and v.Text == "Tentang" then
            local container = v.Parent.Parent
            if container and container:IsA("ScrollingFrame") then
                for _, child in ipairs(container:GetChildren()) do
                    if child.Name == "AbsoluteTopBanner" then child:Destroy() end
                end

                local bannerFrame = Instance.new("Frame")
                bannerFrame.Name = "AbsoluteTopBanner"
                bannerFrame.Size = UDim2.new(1, -10, 0, 115)
                bannerFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
                bannerFrame.BorderSizePixel = 0
                bannerFrame.LayoutOrder = -999
                bannerFrame.Parent = container

                Instance.new("UICorner", bannerFrame).CornerRadius = UDim.new(0, 8)
                local bannerImg = Instance.new("ImageLabel")
                bannerImg.Size = UDim2.new(1, 0, 1, 0)
                bannerImg.Image = ICON.Banner
                bannerImg.BackgroundTransparency = 1
                bannerImg.ScaleType = Enum.ScaleType.Fit
                bannerImg.Parent = bannerFrame
                Instance.new("UICorner", bannerImg).CornerRadius = UDim.new(0, 8)
                break
            end
        end
    end
end)

-- ============================================================
--  FUNGSI EFEK TEKS BERCABAHA / GLOW PULSE BERKESINAMBUNGAN
-- ============================================================
task.spawn(function()
    while true do
        local main = FindMainWindow()
        if main then
            -- Mencari teks judul atau bagian tertentu untuk diberi efek pendar (Glow)
            for _, obj in ipairs(main:GetDescendants()) do
                if obj:IsA("TextLabel") and (obj.Text == "NO MERCY — VIOLENCE DISTRICT" or obj.Text:find("Aimbot") or obj.Text:find("Killer") or obj.Text:find("Survivor")) then
                    -- Menambahkan efek pendar warna putih/terang secara halus menggunakan fungsi matematika gelombang sinus (Sine wave)
                    local alpha = (math.sin(os.clock() * 3) + 1) / 2 -- Nilai berosilasi antara 0 dan 1
                    obj.TextColor3 = Color3.fromRGB(255, 255, 255):Lerp(Color3.fromRGB(120, 200, 255), alpha)
                end
            end
        end
        RunService.RenderStepped:Wait()
    end
end)

-- ============================================================
--  SECTIONS & FEATURES
-- ============================================================
local AimbotSec = AimbotTab:AddSection({ Name = "Aimbot Settings" })
AimbotSec:AddToggle({ Name = "Enable Aimbot", Default = false, Callback = function(v) print("Aimbot:", v) end })
AimbotSec:AddToggle({ Name = "Silent Aim Veil", Default = false, Callback = function(v) print("SilentAimVeil:", v) end })
AimbotSec:AddSlider({ Name = "FOV Radius", Min = 50, Max = 500, Default = 150, Increment = 10, Callback = function(v) print("FOV:", v) end })

local ParrySec = ParryTab:AddSection({ Name = "Auto Parry" })
ParrySec:AddToggle({ Name = "Enable Auto Parry", Default = false, Callback = function(v) print("AutoParry:", v) end })
ParrySec:AddDropdown({ Name = "Parry Mode", Default = "Always", Options = { "Always", "On Distance", "Hold Key" }, Callback = function(v) print("ParryMode:", v) end })
ParrySec:AddSlider({ Name = "Parry Distance", Min = 5, Max = 50, Default = 15, Increment = 1, ValueName = "studs", Callback = function(v) print("ParryDistance:", v) end })

local TeleSec = TeleportTab:AddSection({ Name = "Teleport" })
TeleSec:AddButton({ Name = "Teleport to Safe Zone", Callback = function() OrionLib:MakeNotification({ Name = "NO MERCY", Content = "Teleporting...", Image = ICON.Logo, Time = 2 }) end })

local KillerSec = KillerTab:AddSection({ Name = "Killer" })
KillerSec:AddToggle({ Name = "Killer Mode", Default = false, Callback = function(v) print("KillerMode:", v) end })
KillerSec:AddButton({ Name = "Kill All", Callback = function() print("Kill all") end })

local SurvivorSec = SurvivorTab:AddSection({ Name = "Survivor" })
SurvivorSec:AddToggle({ Name = "Survivor Mode", Default = false, Callback = function(v) print("SurvivorMode:", v) end })

local VisualSec = VisualTab:AddSection({ Name = "Visual" })
VisualSec:AddToggle({ Name = "ESP Players", Default = false, Callback = function(v) print("ESP:", v) end })
VisualSec:AddToggle({ Name = "Show FOV Circle", Default = true, Callback = function(v) print("FOVCircle:", v) end })

local SpeedSec = SpeedTab:AddSection({ Name = "Speed" })
SpeedSec:AddSlider({ Name = "WalkSpeed", Min = 16, Max = 200, Default = 16, Increment = 1, ValueName = "speed", Callback = function(v) local char = game.Players.LocalPlayer.Character if char and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed = v end end })

local SettingsSec = SettingsTab:AddSection({ Name = "Pengaturan" })
SettingsSec:AddButton({ Name = "Tutup UI (Close)", Callback = function() confirmClose() end })

OrionLib:MakeNotification({ Name = "NO MERCY", Content = "Violence District dimuat!", Image = ICON.Logo, Time = 4 })
print("[NO MERCY] Violence District loaded successfully!")
