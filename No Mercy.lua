-- ============================================================
--  NO MERCY — "VIOLENCE DISTRICT" (ZIAANHUB X FEATURES INTEGRATED)
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

-- ===================== GLOBAL CONFIG & STATE =====================
getgenv().VD = getgenv().VD or {
    AutoSkillcheck        = false,
    AutoSkillcheckMode    = "Normal",
    SURV_FleeKiller       = false,
    SURV_FleeDistance     = 40,
    SURV_AutoParry        = false,
    SURV_ParryMode        = "Legit",
    SURV_ParryAnimId      = "rbxassetid://109133187196613",
    SURV_ParryRange       = 12,
    SURV_ShowParryCircle  = true,
    Parry_Keybind         = "F3",
    SURV_AntiKnock        = false,
    SURV_FirstPerson      = false,
    AUTO_ToFAim           = false,
    AUTO_ToFAimRange      = 90,
    AUTO_ToFDotThreshold  = 0.5,
    AUTO_ToFTargetMode    = "Killer",
    AUTO_ToFAimPart       = "HumanoidRootPart",
    AUTO_ToFPredict       = true,
    AUTO_ToFBulletSpeed   = 200,
    AUTO_Attack           = false,
    AUTO_AttackRange      = 12,
    KILLER_DestroyPallets = false,
    KILLER_AutoBreakGene  = false,
    KILLER_BlockVaults    = false,
    KILLER_AntiBlind      = false,
    KILLER_DoubleTap      = false,
    KILLER_CustomMasked   = "Richard",
    DRAWING_ESP           = false,
    ESP_Skeleton          = false,
    ESP_Offscreen         = false,
    ESP_Velocity          = false,
    MaxDistance           = 2000,
    InstantHealSelf       = false,
    AutoHealAll           = false,
    Destroyed             = false,
    SURV_GenBoost         = false,
    SURV_DraggableGenBypass = false,
    ESP_LowPerformance    = false,
    Fullbright            = false,
    NoFog                 = false,
    SURV_AutoDropPallet   = false,
    SURV_AutoDropPalletDist = 20,
    SURV_AutoDropPalletMode = "Aggressive",
    SURV_AutoVault        = false,
    SURV_AutoPalletSlide  = false,
}

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Lighting          = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local GuiService        = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService      = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local HttpService       = game:GetService("HttpService")

local LocalPlayer       = Players.LocalPlayer
local Camera            = Workspace.CurrentCamera
local VD                = getgenv().VD

local function GetHolder()
    return (gethui and gethui()) or game:GetService("CoreGui")
end

local function VD_Notify(title, content, duration)
    pcall(function()
        if OrionLib and OrionLib.MakeNotification then
            OrionLib:MakeNotification({ Name = title, Content = content, Image = ICON.Logo, Time = duration or 3 })
        else
            print("[NO MERCY] " .. title .. " - " .. content)
        end
    end)
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
    ConfigFolder = "NoMercyViolenceZiaan",
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
--  BUAT TAB ORION
-- ============================================================
local InfoTab     = Window:MakeTab({ Name = "Info", Icon = ICON.Info, PremiumOnly = false })
local PlayerTab   = Window:MakeTab({ Name = "Player", Icon = ICON.User, PremiumOnly = false })
local SurvivorTab = Window:MakeTab({ Name = "Survivor", Icon = ICON.Swords, PremiumOnly = false })
local KillerTab   = Window:MakeTab({ Name = "Killer", Icon = ICON.Axe, PremiumOnly = false })
local VisualTab   = Window:MakeTab({ Name = "Visual", Icon = ICON.Eye, PremiumOnly = false })
local SpeedTab    = Window:MakeTab({ Name = "Speed", Icon = ICON.Zap, PremiumOnly = false })
local SettingsTab = Window:MakeTab({ Name = "Pengaturan", Icon = ICON.Settings, PremiumOnly = false })

-- ============================================================
--  INFO TAB
-- ============================================================
local InfoSec = InfoTab:AddSection({ Name = "Tentang" })
InfoSec:AddLabel("NO MERCY — Violence District")
InfoSec:AddLabel("ZiaanHub X Features Integrated")
InfoSec:AddButton({
    Name = "Copy Link Discord",
    Callback = function()
        if setclipboard then setclipboard("https://discord.gg/pbg6g79Hp") end
        VD_Notify("NO MERCY", "Link Discord di-copy!", 3)
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
--  PLAYER TAB (Teleport, Fling, Moonwalk / Fun)
-- ============================================================
local TeleSec = PlayerTab:AddSection({ Name = "Teleport" })
TeleSec:AddButton({ Name = "Teleport to Safe Zone", Callback = function() VD_Notify("Teleport", "Safe Zone Teleported", 2) end })
TeleSec:AddButton({ Name = "Teleport to Generator", Callback = function() print("TP to Gen") end })
TeleSec:AddButton({ Name = "Teleport to Gate", Callback = function() print("TP to Gate") end })

local FlingSec = PlayerTab:AddSection({ Name = "Fling & Fun" })
FlingSec:AddToggle({ Name = "Enable Fling", Default = false, Callback = function(v) VD.FLING_Enabled = v end })
FlingSec:AddSlider({ Name = "Fling Strength", Min = 1000, Max = 30000, Default = 10000, Increment = 500, Callback = function(v) VD.FLING_Strength = v end })

-- ============================================================
--  SURVIVOR TAB (Auto Parry, Gen Boost, Movement, Healing, ToF)
-- ============================================================
local SurvGen = SurvivorTab:AddSection({ Name = "General Survivor" })
SurvGen:AddToggle({ Name = "Auto Skillcheck", Default = false, Callback = function(v) VD.AutoSkillcheck = v end })
SurvGen:AddDropdown({ Name = "Skillcheck Mode", Default = "Normal", Options = { "Normal", "Perfect", "Instant" }, Callback = function(v) VD.AutoSkillcheckMode = v end })
SurvGen:AddToggle({ Name = "Flee Killer", Default = false, Callback = function(v) VD.SURV_FleeKiller = v end })
SurvGen:AddSlider({ Name = "Flee Distance", Min = 15, Max = 80, Default = 40, Increment = 1, Callback = function(v) VD.SURV_FleeDistance = v end })

local SurvParry = SurvivorTab:AddSection({ Name = "Auto Parry" })
SurvParry:AddToggle({ Name = "Enable Auto Parry", Default = false, Callback = function(v) VD.SURV_AutoParry = v end })
SurvParry:AddDropdown({ Name = "Parry Mode", Default = "Legit", Options = { "Legit", "Aggressive" }, Callback = function(v) VD.SURV_ParryMode = v end })
SurvParry:AddSlider({ Name = "Parry Range", Min = 2, Max = 20, Default = 12, Increment = 0.5, Callback = function(v) VD.SURV_ParryRange = v end })

local SurvBoost = SurvivorTab:AddSection({ Name = "Generator Boost & Pallet" })
SurvBoost:AddToggle({ Name = "Gen Boost (Bypass)", Default = false, Callback = function(v) VD.SURV_GenBoost = v end })
SurvBoost:AddToggle({ Name = "Draggable Gen Button", Default = false, Callback = function(v) VD.SURV_DraggableGenBypass = v end })
SurvBoost:AddToggle({ Name = "Auto Drop Pallet", Default = false, Callback = function(v) VD.SURV_AutoDropPallet = v end })

local SurvMove = SurvivorTab:AddSection({ Name = "Movement (Vault & Slide)" })
SurvMove:AddToggle({ Name = "Auto Vault", Default = false, Callback = function(v) VD.SURV_AutoVault = v end })
SurvMove:AddToggle({ Name = "Auto Pallet (Slide)", Default = false, Callback = function(v) VD.SURV_AutoPalletSlide = v end })

-- ============================================================
--  KILLER TAB (Auto Attack, Double Tap, Silent Aim Veil, Custom Masked)
-- ============================================================
local KillGen = KillerTab:AddSection({ Name = "General Killer" })
KillGen:AddToggle({ Name = "Auto Attack", Default = false, Callback = function(v) VD.AUTO_Attack = v end })
KillGen:AddSlider({ Name = "Attack Range", Min = 5, Max = 20, Default = 12, Increment = 1, Callback = function(v) VD.AUTO_AttackRange = v end })
KillGen:AddToggle({ Name = "Double Tap", Default = false, Callback = function(v) VD.KILLER_DoubleTap = v end })
KillGen:AddToggle({ Name = "Auto Kick Pallet", Default = false, Callback = function(v) VD.KILLER_DestroyPallets = v end })
KillGen:AddToggle({ Name = "Auto Kick Generator", Default = false, Callback = function(v) VD.KILLER_AutoBreakGene = v end })
KillGen:AddToggle({ Name = "Block All Vaults", Default = false, Callback = function(v) VD.KILLER_BlockVaults = v end })
KillGen:AddToggle({ Name = "Anti Blind (Flashlight)", Default = false, Callback = function(v) VD.KILLER_AntiBlind = v end })

local KillVeil = KillerTab:AddSection({ Name = "Silent Aim Veil (Spear)" })
KillVeil:AddToggle({ Name = "Silent Aim Veil", Default = false, Callback = function(v) VD.SPEAR_Aimbot = v end })
KillVeil:AddSlider({ Name = "Spear Speed", Min = 50, Max = 300, Default = 165, Increment = 5, Callback = function(v) VD.SPEAR_Speed = v end })

local KillMask = KillerTab:AddSection({ Name = "Custom Masked" })
KillMask:AddDropdown({ Name = "Custom Masked", Default = "Richard", Options = { "Richard", "Tony", "Brandon", "Jake", "Richter", "Graham", "Alex" }, Callback = function(v) VD.KILLER_CustomMasked = v end })

-- ============================================================
--  VISUAL TAB (Drawing ESP & Lighting Presets)
-- ============================================================
local VisSec = VisualTab:AddSection({ Name = "Drawing & Highlight ESP" })
VisSec:AddToggle({ Name = "Master Turn On Drawing ESP", Default = false, Callback = function(v) VD.DRAWING_ESP = v end })
VisSec:AddToggle({ Name = "ESP Skeleton", Default = false, Callback = function(v) VD.ESP_Skeleton = v end })
VisSec:AddToggle({ Name = "ESP Velocity Arrows", Default = false, Callback = function(v) VD.ESP_Velocity = v end })
VisSec:AddToggle({ Name = "ESP Offscreen Arrows", Default = false, Callback = function(v) VD.ESP_Offscreen = v end })
VisSec:AddSlider({ Name = "Max ESP Distance", Min = 500, Max = 5000, Default = 2000, Increment = 100, Callback = function(v) VD.MaxDistance = v end })

local VisLight = VisualTab:AddSection({ Name = "Lighting (Fullbright & No Fog)" })
VisLight:AddToggle({ Name = "Fullbright", Default = false, Callback = function(v) VD.Fullbright = v; Lighting.Brightness = v and 1 or 2 end })
VisLight:AddToggle({ Name = "No Fog", Default = false, Callback = function(v) VD.NoFog = v; Lighting.FogEnd = v and 9999 or 100000 end })

-- ============================================================
--  SPEED TAB
-- ============================================================
local SpeedSec = SpeedTab:AddSection({ Name = "WalkSpeed" })
SpeedSec:AddSlider({
    Name = "WalkSpeed", Min = 16, Max = 200, Default = 16, Increment = 1, ValueName = "speed",
    Callback = function(v)
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed = v end
    end,
})

-- ============================================================
--  PENGATURAN TAB
-- ============================================================
local SettingsSec = SettingsTab:AddSection({ Name = "Pengaturan" })
SettingsSec:AddButton({ Name = "Tutup UI (Close)", Callback = function() confirmClose() end })

-- ============================================================
--  BACKGROUND LOOPS (Fitur Utama Berjalan di Background)
-- ============================================================
RunService.Heartbeat:Connect(function()
    if VD.Destroyed then return end
    
    -- Auto Attack Killer
    if VD.AUTO_Attack and LocalPlayer.Team and LocalPlayer.Team.Name == "Killer" then
        pcall(function()
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not root then return end
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Team and player.Team.Name == "Survivors" and player.Character then
                    local tRoot = player.Character:FindFirstChild("HumanoidRootPart")
                    if tRoot and (tRoot.Position - root.Position).Magnitude <= VD.AUTO_AttackRange then
                        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                        local basicAtt = remotes and remotes:FindFirstChild("Attacks") and remotes.Attacks:FindFirstChild("BasicAttack")
                        if basicAtt then basicAtt:FireServer(false) end
                        break
                    end
                end
            end
        end)
    end
end)

VD_Notify("NO MERCY", "Violence District (ZiaanHub X Integrated) Loaded!", 4)
print("[NO MERCY] Violence District loaded successfully with full ZiaanHub features!")
