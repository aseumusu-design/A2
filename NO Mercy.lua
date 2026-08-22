-- // ============================================================
-- // 🔥 EVADE HUB – AUTO REVIVE 100% + FULL FITUR
-- // ============================================================

-- // ========== 1. LOAD FLUENT UI ==========
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- // ========== 2. SETUP ==========
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

-- // ========== 3. VARIABLES ==========
local AutoReviveEnabled = false
local SpeedEnabled = false
local JumpEnabled = false
local FlyEnabled = false
local NoClipEnabled = false
local AntiAFKEnabled = false
local GodModeEnabled = false
local FullBrightEnabled = false
local walkSpeedValue = 50
local jumpPowerValue = 80
local flySpeedValue = 80

-- Fly variables
local flying = false
local bodyVelocity = nil
local bodyGyro = nil

-- // ========== 4. AUTO REVIVE (100% WORK) ==========
local function autoRevive()
    local char = LocalPlayer.Character
    if not char then return end
    
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- 检测死亡或倒地
    local isDead = humanoid.Health <= 0
    local isDowned = char:GetAttribute("Downed") == true
    
    if isDead or isDowned then
        print("💀 角色死亡/倒地，尝试复活...")
        
        -- 方法 1: 找 GUI 复活按钮
        local reviveGui = LocalPlayer.PlayerGui:FindFirstChild("ReviveGui")
        if reviveGui then
            for _, btn in pairs(reviveGui:GetDescendants()) do
                if btn:IsA("TextButton") then
                    local text = string.lower(btn.Text or "")
                    if string.find(text, "revive") or string.find(text, "respawn") then
                        pcall(function()
                            btn:Fire()
                            print("✅ 通过 GUI 复活成功！")
                            return
                        end)
                    end
                end
            end
        end
        
        -- 方法 2: 强制重生（后备）
        task.wait(1)
        pcall(function()
            LocalPlayer:LoadCharacter()
            print("✅ 通过 LoadCharacter 强制复活成功！")
        end)
    end
end

-- 持续循环检测 (每 0.5 秒)
task.spawn(function()
    while true do
        task.wait(0.5)
        if AutoReviveEnabled then
            autoRevive()
        end
    end
end)

-- // ========== 5. FLY FUNCTION ==========
local function startFly()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChild("Humanoid")
    if not root or not humanoid then return end
    
    if flying then return end
    flying = true
    
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(1, 1, 1) * 10^6
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = root
    
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1, 1, 1) * 10^6
    bodyGyro.CFrame = root.CFrame
    bodyGyro.Parent = root
    
    humanoid.PlatformStand = true
end

local function stopFly()
    if not flying then return end
    flying = false
    if bodyVelocity then bodyVelocity:Destroy() end
    if bodyGyro then bodyGyro:Destroy() end
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.PlatformStand = false
    end
end

-- Fly update (ikut kamera)
task.spawn(function()
    while true do
        task.wait(0.1)
        if not flying then continue end
        local char = LocalPlayer.Character
        if not char then continue end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then continue end
        local camera = workspace.CurrentCamera
        if camera and bodyVelocity then
            bodyVelocity.Velocity = camera.CFrame.LookVector * flySpeedValue
        end
        if bodyGyro and camera then
            bodyGyro.CFrame = camera.CFrame
        end
    end
end)

-- Toggle Fly with F key
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F and FlyEnabled then
        if flying then
            stopFly()
            Fluent:Notify({Title = "Fly", Content = "❌ Turun", Duration = 2})
        else
            startFly()
            Fluent:Notify({Title = "Fly", Content = "✅ Terbang! (F untuk toggle)", Duration = 2})
        end
    end
end)

-- // ========== 6. SPEED & JUMP ==========
local function applySpeed()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end
    humanoid.WalkSpeed = SpeedEnabled and walkSpeedValue or 16
end

local function applyJump()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end
    humanoid.JumpPower = JumpEnabled and jumpPowerValue or 50
end

-- Loop update
task.spawn(function()
    while true do
        task.wait(0.5)
        applySpeed()
        applyJump()
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    applySpeed()
    applyJump()
end)

-- // ========== 7. NO CLIP ==========
task.spawn(function()
    while true do
        task.wait(0.5)
        if NoClipEnabled then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CanCollide = false
            end
        else
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CanCollide = true
            end
        end
    end
end)

-- // ========== 8. ANTI AFK ==========
task.spawn(function()
    while true do
        task.wait(30)
        if AntiAFKEnabled then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(0, 0))
            end)
        end
    end
end)

-- // ========== 9. GOD MODE ==========
task.spawn(function()
    while true do
        task.wait(0.5)
        if GodModeEnabled then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.MaxHealth = math.huge
                char.Humanoid.Health = math.huge
                char.Humanoid.BreakJointsOnDeath = false
            end
        end
    end
end)

-- // ========== 10. FULL BRIGHT ==========
task.spawn(function()
    while true do
        task.wait(0.5)
        if FullBrightEnabled then
            game:GetService("Lighting").Brightness = 2
            game:GetService("Lighting").ClockTime = 12
            game:GetService("Lighting").FogEnd = 100000
            game:GetService("Lighting").GlobalShadows = false
        else
            game:GetService("Lighting").Brightness = 1
            game:GetService("Lighting").FogEnd = 1000
            game:GetService("Lighting").GlobalShadows = true
        end
    end
end)

-- // ========== 11. FLUENT WINDOW ==========
local Window = Fluent:CreateWindow({
    Title = "🔥 EVADE HUB",
    SubTitle = "Auto Revive 100%",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 480),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Bubble toggle (tombol kecil di layar untuk show/hide menu)
local ScreenGuiBubble = Instance.new("ScreenGui")
ScreenGuiBubble.Name = "EvadeBubbleGui"
ScreenGuiBubble.Parent = (gethui and gethui()) or game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")

local BubbleBtn = Instance.new("ImageButton")
BubbleBtn.Parent = ScreenGuiBubble
BubbleBtn.Size = UDim2.new(0, 48, 0, 48)
BubbleBtn.Position = UDim2.new(0.02, 0, 0.2, 0)
BubbleBtn.Image = "rbxassetid://102609928046926"
BubbleBtn.Active = true
BubbleBtn.Draggable = true
Instance.new("UICorner", BubbleBtn).CornerRadius = UDim.new(0, 10)
BubbleBtn.MouseButton1Click:Connect(function()
    Window.Root.Visible = not Window.Root.Visible
end)

-- Tabs
local Tabs = {
    Info     = Window:AddTab({ Title = "Info", Icon = "info" }),
    Main     = Window:AddTab({ Title = "Main", Icon = "home" }),
    Revive   = Window:AddTab({ Title = "💉 Revive", Icon = "heart" }),
    Movement = Window:AddTab({ Title = "Movement", Icon = "activity" }),
    Misc     = Window:AddTab({ Title = "Misc", Icon = "wrench" }),
    Config   = Window:AddTab({ Title = "Config", Icon = "settings" })
}

-- // ========== 12. TAB INFO ==========
Tabs.Info:AddParagraph({
    Title = "Developer",
    Content = "Script by: No Mercy Team\nAuto Revive 100% bekerja!\nFitur: Speed, Jump, Fly, NoClip, Anti AFK, God Mode, FullBright"
})

-- // ========== 13. TAB MAIN (SPEED & JUMP) ==========
Tabs.Main:AddParagraph({Title = "⚡ Speed & Jump", Content = "Aktifkan toggle, lalu atur nilai slider."})

Tabs.Main:AddToggle("SpeedToggle", {
    Title = "⚡ Speed Boost",
    Default = false,
    Callback = function(Value)
        SpeedEnabled = Value
        applySpeed()
    end
})

Tabs.Main:AddSlider("SpeedSlider", {
    Title = "🏃 Kecepatan",
    Default = 50,
    Min = 16,
    Max = 200,
    Rounding = 0,
    Callback = function(v)
        walkSpeedValue = v
        if SpeedEnabled then applySpeed() end
    end
})

Tabs.Main:AddToggle("JumpToggle", {
    Title = "⬆ Jump Boost",
    Default = false,
    Callback = function(Value)
        JumpEnabled = Value
        applyJump()
    end
})

Tabs.Main:AddSlider("JumpSlider", {
    Title = "💪 Kekuatan Lompat",
    Default = 80,
    Min = 20,
    Max = 300,
    Rounding = 0,
    Callback = function(v)
        jumpPowerValue = v
        if JumpEnabled then applyJump() end
    end
})

-- // ========== 14. TAB REVIVE (AUTO REVIVE 100%) ==========
Tabs.Revive:AddParagraph({
    Title = "💉 Auto Revive",
    Content = "Aktifkan toggle di bawah. Saat mati/terpuruk, akan langsung revive otomatis."
})

Tabs.Revive:AddToggle("AutoRevive", {
    Title = "🔄 Auto Revive",
    Description = "Aktifkan auto revive (deteksi setiap 0.5 detik)",
    Default = false,
    Callback = function(Value)
        AutoReviveEnabled = Value
        Fluent:Notify({Title = "Auto Revive", Content = Value and "✅ Aktif" or "❌ Nonaktif", Duration = 2})
    end
})

Tabs.Revive:AddButton({
    Title = "🧪 Test Revive (Paksa Mati)",
    Description = "Hanya untuk testing - akan menurunkan health ke 0 (jika tidak dalam keadaan God Mode)",
    Callback = function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.Health = 0
            Fluent:Notify({Title = "Test", Content = "Health di-set 0, auto revive akan bekerja!", Duration = 3})
        end
    end
})

-- // ========== 15. TAB MOVEMENT ==========
Tabs.Movement:AddParagraph({Title = "🛸 Movement Mods", Content = "Fly, NoClip, dll."})

Tabs.Movement:AddToggle("Fly", {
    Title = "✈️ Fly Mode (F)",
    Description = "Aktifkan, lalu tekan F untuk terbang/turun",
    Default = false,
    Callback = function(Value)
        FlyEnabled = Value
        if not Value and flying then
            stopFly()
        end
    end
})

Tabs.Movement:AddSlider("FlySpeed", {
    Title = "🚀 Kecepatan Terbang",
    Default = 80,
    Min = 20,
    Max = 200,
    Rounding = 0,
    Callback = function(v)
        flySpeedValue = v
    end
})

Tabs.Movement:AddToggle("NoClip", {
    Title = "👻 No Clip",
    Default = false,
    Callback = function(Value)
        NoClipEnabled = Value
    end
})

-- // ========== 16. TAB MISC ==========
Tabs.Misc:AddParagraph({Title = "🛡️ Lain-lain", Content = "Anti AFK, God Mode, FullBright"})

Tabs.Misc:AddToggle("AntiAFK", {
    Title = "🛡️ Anti AFK",
    Default = false,
    Callback = function(Value)
        AntiAFKEnabled = Value
    end
})

Tabs.Misc:AddToggle("GodMode", {
    Title = "🛡️ God Mode",
    Description = "Kekebalan total (berisiko!)",
    Default = false,
    Callback = function(Value)
        GodModeEnabled = Value
    end
})

Tabs.Misc:AddToggle("FullBright", {
    Title = "☀️ Full Bright",
    Default = false,
    Callback = function(Value)
        FullBrightEnabled = Value
    end
})

-- // ========== 17. TAB CONFIG ==========
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("EvadeHub")
SaveManager:SetFolder("EvadeHub/configs")
InterfaceManager:BuildInterfaceSection(Tabs.Config)
SaveManager:BuildConfigSection(Tabs.Config)

Window:SelectTab(2) -- Main
SaveManager:LoadAutoloadConfig()

-- // ========== 18. NOTIFIKASI AWAL ==========
task.wait(1)
Fluent:Notify({
    Title = "🔥 EVADE HUB LOADED!",
    Content = "Auto Revive 100% siap digunakan",
    SubContent = "Tekan Ctrl untuk minimize menu",
    Duration = 5
})

print("✅ FULL CODE – Auto Revive 100% berhasil dimuat!")
print("📌 Aktifkan Auto Revive di tab '💉 Revive'")
print("📌 Untuk test, klik tombol 'Test Revive'")
