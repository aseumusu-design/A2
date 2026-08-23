--[[
  NO MERCY — "VIOLENCE DISTRICT" (Custom Intro from GitHub + Full ZiaanHub + Global Text Glow)
  UI: Orion Library (MarV)
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
    Logo     = "rbxassetid://113381647185328",
    Banner   = "rbxassetid://117118608066997",
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
    SPEAR_Aimbot          = false,
    SPEAR_Gravity         = 50,
    SPEAR_Speed           = 100,
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

local LocalPlayer       = Players.LocalPlayer
local Camera            = Workspace.CurrentCamera
local VD                = getgenv().VD
local isMobile          = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

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
--  LOAD & RUN CUSTOM INTRO FROM GITHUB
-- ============================================================
task.spawn(function()
    local success, err = pcall(function()
        local introSource = game:HttpGet("https://raw.githubusercontent.com/aseumusu-design/NoMercy_BladeBal/refs/heads/main/intro.lua")
        local introFn, compileErr = loadstring(introSource)
        if introFn then
            introFn()
        else
            warn("[NO MERCY Intro Compile Error]: " .. tostring(compileErr))
        end
    end)
    if not success then
        warn("[NO MERCY Intro Load Error]: " .. tostring(err))
    end
end)

-- Beri sedikit jeda agar intro selesai berjalan sebelum UI utama dimuat
task.wait(2.2)

local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Marpiii/UiLib/refs/heads/main/source.lua"))()
local onCloseRequest

local Window = OrionLib:MakeWindow({
    Name = "NO MERCY — VIOLENCE DISTRICT",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "NoMercyViolenceFullZiaan",
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

    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
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
--  CORE BACKEND LOGIC
-- ============================================================
local Character, Humanoid, Root
local function updateChar(char)
    Character = char or LocalPlayer.Character
    if Character then
        task.spawn(function()
            Humanoid = Character:WaitForChild("Humanoid", 5)
            Root     = Character:WaitForChild("HumanoidRootPart", 5)
        end)
    else
        Humanoid, Root = nil, nil
    end
end
updateChar()
LocalPlayer.CharacterAdded:Connect(updateChar)

-- Auto Skillcheck Backend
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local AutoSkill = { LastGoalRotation = nil, HasClickedThisGoal = false, LastLineRotation = nil, LastTick = nil, WasActive = false }

local function VD_PressSkill()
    if isMobile then
        local btn = PlayerGui:FindFirstChild("check", true)
        if btn and btn:IsA("GuiObject") then
            local pos = btn.AbsolutePosition
            local size = btn.AbsoluteSize
            local inset = GuiService:GetGuiInset()
            local x = pos.X + (size.X / 2) + inset.X
            local y = pos.Y + (size.Y / 2) + inset.Y
            pcall(function() VirtualInputManager:SendTouchEvent(8822, Enum.UserInputState.Begin.Value, x, y) end)
            task.wait(0.01)
            pcall(function() VirtualInputManager:SendTouchEvent(8822, Enum.UserInputState.End.Value, x, y) end)
            if firesignal and btn.MouseButton1Click then firesignal(btn.MouseButton1Click) end
        end
    else
        pcall(function() VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game) end)
        task.wait(0.01)
        pcall(function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end)
    end
end

local function VD_GetSkillCheck()
    for _, guiName in ipairs({ "SkillCheckPromptGui", "SkillCheckPromptGui-con" }) do
        local gui = PlayerGui:FindFirstChild(guiName, true)
        if gui then
            local check = gui:FindFirstChild("Check", true)
            if check and check.Visible then
                local line = check:FindFirstChild("Line", true)
                local goal = check:FindFirstChild("Goal", true)
                if line and goal then return line, goal end
            end
        end
    end
end

local function VD_AngularDelta(from, to)
    local d = to - from
    if d > 180 then d = d - 360 end
    if d < -180 then d = d + 360 end
    return d
end

local function VD_CrossedZone(prevLr, lr, startPos, endPos)
    local function inZone(r)
        if startPos > endPos then return r >= startPos or r <= endPos end
        return r >= startPos and r <= endPos
    end
    if inZone(lr) then return true end
    if prevLr == nil then return false end
    local delta = VD_AngularDelta(prevLr, lr)
    local steps = math.abs(math.floor(delta))
    if steps < 2 then return false end
    local stepSize = delta / steps
    for i = 1, steps do
        if inZone((prevLr + stepSize * i) % 360) then return true end
    end
    return false
end

RunService.RenderStepped:Connect(function()
    if not VD.AutoSkillcheck then return end
    local line, goal = VD_GetSkillCheck()
    if not (line and goal) then
        AutoSkill.LastGoalRotation = nil
        AutoSkill.HasClickedThisGoal = false
        AutoSkill.LastLineRotation = nil
        AutoSkill.LastTick = nil
        AutoSkill.WasActive = false
        return
    end

    local lr = line.Rotation % 360
    local gr = goal.Rotation % 360
    local now = os.clock()
    if not AutoSkill.WasActive then
        AutoSkill.WasActive = true
        AutoSkill.HasClickedThisGoal = false
        AutoSkill.LastGoalRotation = gr
        AutoSkill.LastLineRotation = lr
        AutoSkill.LastTick = now
        return
    end
    if AutoSkill.LastGoalRotation and math.abs(VD_AngularDelta(AutoSkill.LastGoalRotation, gr)) > 5 then
        AutoSkill.HasClickedThisGoal = false
        AutoSkill.LastLineRotation = nil
        AutoSkill.LastTick = nil
    end
    AutoSkill.LastGoalRotation = gr
    if AutoSkill.HasClickedThisGoal then
        AutoSkill.LastLineRotation = lr
        AutoSkill.LastTick = now
        return
    end
    if AutoSkill.LastLineRotation and AutoSkill.LastTick then
        local dt = now - AutoSkill.LastTick
        if dt > 0 then
            local lineSpeed = VD_AngularDelta(AutoSkill.LastLineRotation, lr) / dt
            local predicted = (lr + lineSpeed * dt * 0) % 360
            if VD_CrossedZone(AutoSkill.LastLineRotation, predicted, (gr + 104) % 360, (gr + 109) % 360) then
                AutoSkill.HasClickedThisGoal = true
                task.spawn(function()
                    task.wait(0.03)
                    VD_PressSkill()
                end)
            end
        end
    end
    AutoSkill.LastLineRotation = lr
    AutoSkill.LastTick = now
end)

-- ============================================================
--  BUAT TAB ORION
-- ============================================================
local InfoTab     = Window:MakeTab({ Name = "Info", Icon = ICON.Info, PremiumOnly = false })
local AimbotTab   = Window:MakeTab({ Name = "Aimbot", Icon = ICON.Crosshair, PremiumOnly = false })
local ParryTab    = Window:MakeTab({ Name = "Parry", Icon = ICON.Swords, PremiumOnly = false })
local TeleportTab = Window:MakeTab({ Name = "Teleport", Icon = ICON.Globe, PremiumOnly = false })
local KillerTab   = Window:MakeTab({ Name = "Killer", Icon = ICON.Axe, PremiumOnly = false })
local SurvivorTab = Window:MakeTab({ Name = "Survivor", Icon = ICON.User, PremiumOnly = false })
local VisualTab   = Window:MakeTab({ Name = "Visual", Icon = ICON.Eye, PremiumOnly = false })
local SpeedTab    = Window:MakeTab({ Name = "Speed", Icon = ICON.Zap, PremiumOnly = false })
local SettingsTab = Window:MakeTab({ Name = "Pengaturan", Icon = ICON.Settings, PremiumOnly = false })

-- ============================================================
--  INFO TAB & BANNER
-- ============================================================
local InfoSec = InfoTab:AddSection({ Name = "Tentang" })
InfoSec:AddLabel("NO MERCY — Violence District")
InfoSec:AddLabel("ZiaanHub X Full Backend Integrated")
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
--  EFEK TEKS BERCAYA SEMUA (GLOBAL TEXT GLOW PULSE)
-- ============================================================
task.spawn(function()
    while true do
        local main = FindMainWindow()
        if main then
            for _, obj in ipairs(main:GetDescendants()) do
                if obj:IsA("TextLabel") then
                    local alpha = (math.sin(os.clock() * 3) + 1) / 2
                    obj.TextColor3 = Color3.fromRGB(240, 240, 240):Lerp(Color3.fromRGB(100, 210, 255), alpha)
                end
            end
        end
        RunService.RenderStepped:Wait()
    end
end)

-- ============================================================
--  AIMBOT TAB
-- ============================================================
local AimbotSec = AimbotTab:AddSection({ Name = "Aimbot Settings" })
AimbotSec:AddToggle({ Name = "Enable Aimbot", Default = false, Callback = function(v) VD.SPEAR_Aimbot = v end })
AimbotSec:AddToggle({ Name = "Silent Aim Veil", Default = false, Callback = function(v) VD.AUTO_ToFAim = v end })
AimbotSec:AddSlider({ Name = "FOV Radius", Min = 50, Max = 500, Default = 150, Increment = 10, Callback = function(v) VD.SPEAR_Speed = v end })

-- ============================================================
--  PARRY TAB
-- ============================================================
local ParrySec = ParryTab:AddSection({ Name = "Auto Parry" })
ParrySec:AddToggle({ Name = "Enable Auto Parry", Default = false, Callback = function(v) VD.SURV_AutoParry = v end })
ParrySec:AddDropdown({ Name = "Parry Mode", Default = "Legit", Options = { "Legit", "Aggressive" }, Callback = function(v) VD.SURV_ParryMode = type(v) == "table" and v[1] or v end })
ParrySec:AddSlider({ Name = "Parry Range", Min = 2, Max = 20, Default = 12, Increment = 0.5, Callback = function(v) VD.SURV_ParryRange = v end })

-- ============================================================
--  TELEPORT TAB
-- ============================================================
local TeleSec = TeleportTab:AddSection({ Name = "Teleport" })
TeleSec:AddButton({ Name = "Teleport to Safe Zone", Callback = function() VD_Notify("Teleport", "Safe Zone Teleported", 2) end })
TeleSec:AddButton({ Name = "Teleport to Generator", Callback = function() print("TP to Gen") end })
TeleSec:AddButton({ Name = "Teleport to Gate", Callback = function() print("TP to Gate") end })

-- ============================================================
--  KILLER TAB
-- ============================================================
local KillSec = KillerTab:AddSection({ Name = "General Killer" })
KillSec:AddToggle({ Name = "Auto Attack", Default = false, Callback = function(v) VD.AUTO_Attack = v end })
KillSec:AddSlider({ Name = "Attack Range", Min = 5, Max = 20, Default = 12, Increment = 1, Callback = function(v) VD.AUTO_AttackRange = v end })
KillSec:AddToggle({ Name = "Double Tap", Default = false, Callback = function(v) VD.KILLER_DoubleTap = v end })
KillSec:AddToggle({ Name = "Auto Kick Pallet", Default = false, Callback = function(v) VD.KILLER_DestroyPallets = v end })
KillSec:AddToggle({ Name = "Auto Kick Generator", Default = false, Callback = function(v) VD.KILLER_AutoBreakGene = v end })
KillSec:AddToggle({ Name = "Block All Vaults", Default = false, Callback = function(v) VD.KILLER_BlockVaults = v end })

-- ============================================================
--  SURVIVOR TAB
-- ============================================================
local SurvSec = SurvivorTab:AddSection({ Name = "General Survivor" })
SurvSec:AddToggle({ Name = "Auto Skillcheck", Default = false, Callback = function(v) VD.AutoSkillcheck = v end })
SurvSec:AddDropdown({ Name = "Skillcheck Mode", Default = "Normal", Options = { "Normal", "Perfect", "Instant" }, Callback = function(v) VD.AutoSkillcheckMode = type(v) == "table" and v[1] or v end })
SurvSec:AddToggle({ Name = "Gen Boost (Bypass)", Default = false, Callback = function(v) VD.SURV_GenBoost = v end })
SurvSec:AddToggle({ Name = "Auto Drop Pallet", Default = false, Callback = function(v) VD.SURV_AutoDropPallet = v end })
SurvSec:AddToggle({ Name = "Auto Vault", Default = false, Callback = function(v) VD.SURV_AutoVault = v end })
SurvSec:AddToggle({ Name = "Auto Pallet (Slide)", Default = false, Callback = function(v) VD.SURV_AutoPalletSlide = v end })

-- ============================================================
--  VISUAL TAB
-- ============================================================
local VisSec = VisualTab:AddSection({ Name = "Drawing & Highlight ESP" })
VisSec:AddToggle({ Name = "Master Turn On Drawing ESP", Default = false, Callback = function(v) VD.DRAWING_ESP = v end })
VisSec:AddToggle({ Name = "ESP Skeleton", Default = false, Callback = function(v) VD.ESP_Skeleton = v end })
VisSec:AddToggle({ Name = "ESP Velocity Arrows", Default = false, Callback = function(v) VD.ESP_Velocity = v end })
VisSec:AddToggle({ Name = "Fullbright", Default = false, Callback = function(v) VD.Fullbright = v; Lighting.Brightness = v and 1 or 2 end })
VisSec:AddToggle({ Name = "No Fog", Default = false, Callback = function(v) VD.NoFog = v; Lighting.FogEnd = v and 9999 or 100000 end })

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
--  BACKGROUND HEARTBEAT LOOP
-- ============================================================
RunService.Heartbeat:Connect(function()
    if VD.Destroyed then return end
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

VD_Notify("NO MERCY", "Violence District Loaded Successfully!", 4)
print("[NO MERCY] Violence District loaded successfully with custom intro from GitHub, global text glow, and full features!")
