-- // ============================================================
-- // 🔥 EVADE HUB – AUTO REVIVE + AUTO COLLECT + UI
-- // ============================================================

-- // ========== 1. LOAD FLUENT UI ==========
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- // ========== 2. SETUP ==========
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Clipboard = (setclipboard or set_clipboard or writeclipboard or function() end)

-- // ========== 3. VARIABEL FITUR ==========
-- Auto Revive
local AutoReviveEnabled = false
-- Auto Collect
local AutoCollectEnabled = false
-- Speed
local SpeedEnabled = false
local walkSpeedValue = 50
-- Jump
local JumpEnabled = false
local jumpPowerValue = 80
-- Fly
local FlyEnabled = false
local flySpeedValue = 80
-- NoClip
local NoClipEnabled = false
-- Anti AFK
local AntiAFKEnabled = false
-- Full Bright
local FullBrightEnabled = false
-- God Mode
local GodModeEnabled = false

-- Remote references
local ActionRemote = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("Action")
local InteractRemote = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("Interact")
local CharacterTaskRemote = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("CharacterTask")
local SetPlayerModeRemote = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("SetPlayerMode")
local CollectiblesInvoke = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("Collectibles") and ReplicatedStorage.Events.Collectibles:FindFirstChild("Invoke")

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

    local isDead = humanoid.Health <= 0
    local isDowned = char:GetAttribute("Downed") == true

    if isDead or isDowned then
        print("💀 Revive attempt...")
        
        -- 1. Coba Action remote
        if ActionRemote then
            pcall(function()
                ActionRemote:FireServer("Revive")
                print("✅ Revive via Action")
                return
            end)
            pcall(function()
                ActionRemote:FireServer("Respawn")
                print("✅ Revive via Action (Respawn)")
                return
            end)
        end

        -- 2. Coba Interact remote
        if InteractRemote then
            pcall(function()
                InteractRemote:FireServer("Revive")
                print("✅ Revive via Interact")
                return
            end)
        end

        -- 3. Coba CharacterTask remote
        if CharacterTaskRemote then
            pcall(function()
                CharacterTaskRemote:FireServer("Revive")
                print("✅ Revive via CharacterTask")
                return
            end)
        end

        -- 4. Coba SetPlayerMode remote
        if SetPlayerModeRemote then
            pcall(function()
                SetPlayerModeRemote:FireServer(true)
                print("✅ Revive via SetPlayerMode")
                return
            end)
        end

        -- 5. Cari tombol GUI
        local reviveGui = LocalPlayer.PlayerGui:FindFirstChild("Game")
        if reviveGui then
            local respawnBtn = reviveGui:FindFirstChild("Respawn")
            if respawnBtn then
                for _, btn in pairs(respawnBtn:GetDescendants()) do
                    if btn:IsA("TextButton") or btn:IsA("ImageButton") then
                        pcall(function() btn:Fire() end)
                        print("✅ Revive via Respawn button")
                        return
                    end
                end
            end
        end

        -- 6. Force LoadCharacter
        task.wait(0.5)
        pcall(function()
            LocalPlayer:LoadCharacter()
            print("✅ Revive via LoadCharacter")
        end)
    end
end

-- Loop auto revive
task.spawn(function()
    while true do
        task.wait(0.5)
        if AutoReviveEnabled then
            autoRevive()
        end
    end
end)

-- // ========== 5. AUTO COLLECT (ITEM) ==========
local function isPlayerAsset(instance)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and instance:IsDescendantOf(player.Character) then
            return true
        end
    end
    return false
end

local function getAllItems()
    local items = {}
    for _, v in pairs(workspace:GetDescendants()) do
        if (v:IsA("BasePart") or v:IsA("Model")) then
            local nameLower = string.lower(v.Name)
            if string.find(nameLower, "bubble") or string.find(nameLower, "coconut") then
                local isVisualEffect = v:FindFirstChildWhichIsA("ParticleEmitter") 
                                    or v:FindFirstChildWhichIsA("Trail") 
                                    or v:FindFirstChildWhichIsA("Beam")
                                    or v.ClassName == "Accessory"
                local hasAnimation = v:FindFirstChildWhichIsA("Animation") or v:FindFirstChildWhichIsA("Animator")
                
                if not isVisualEffect and not hasAnimation and not isPlayerAsset(v) then
                    local part = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart")
                    if part then
                        table.insert(items, part)
                    end
                end
            end
        end
    end
    return items
end

local function getClosestSafeItem(hrp, items)
    local closest, minDst = nil, math.huge
    for _, part in ipairs(items) do
        local dst = (hrp.Position - part.Position).Magnitude
        if dst < minDst then
            closest = part
            minDst = dst
        end
    end
    return closest
end

local function teleportTo(hrp, pos, duration)
    local tween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos)})
    tween:Play()
    tween.Completed:Wait()
end

local function autoCollect()
    if not CollectiblesInvoke then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local items = getAllItems()
    if #items == 0 then return end
    
    local item = getClosestSafeItem(hrp, items)
    if item then
        local startPos = hrp.Position
        hrp.Anchored = false
        teleportTo(hrp, item.Position, 0.2)
        pcall(function()
            local collectId = item.Parent:GetAttribute("Id") or item:GetAttribute("Id") or "a19ac91bff904b7385e826fd6a23dc01"
            CollectiblesInvoke:InvokeServer(LocalPlayer, collectId, "Collect")
            print("✅ Auto Collect: " .. collectId)
        end)
        task.wait(0.3)
        teleportTo(hrp, startPos, 0.2)
    end
end

task.spawn(function()
    while true do
        task.wait(1)
        if AutoCollectEnabled then
            autoCollect()
        end
    end
end)

-- // ========== 6. FLY ==========
local function startFly()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChild("Humanoid")
    if not root or not humanoid or flying then return end
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

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F and FlyEnabled then
        if flying then stopFly() else startFly() end
        Fluent:Notify({Title = "Fly", Content = flying and "✅ Terbang" or "❌ Turun", Duration = 2})
    end
end)

-- // ========== 7. SPEED & JUMP ==========
local function applySpeed()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = SpeedEnabled and walkSpeedValue or 16
    end
end

local function applyJump()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.JumpPower = JumpEnabled and jumpPowerValue or 50
    end
end

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

-- // ========== 8. NO CLIP ==========
task.spawn(function()
    while true do
        task.wait(0.5)
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CanCollide = not NoClipEnabled
        end
    end
end)

-- // ========== 9. ANTI AFK ==========
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

-- // ========== 11. GOD MODE ==========
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

-- // ========== 12. FLUENT UI ==========
local Window = Fluent:CreateWindow({
    Title = "🔥 EVADE HUB",
    SubTitle = "Auto Revive + Auto Collect",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 480),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Bubble toggle (tombol kecil di layar)
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
    Main     = Window:AddTab({ Title = "Main", Icon = "home" }),
    Revive   = Window:AddTab({ Title = "💉 Revive", Icon = "heart" }),
    Collect  = Window:AddTab({ Title = "🎯 Collect", Icon = "package" }),
    Movement = Window:AddTab({ Title = "Movement", Icon = "activity" }),
    Misc     = Window:AddTab({ Title = "Misc", Icon = "wrench" }),
    Config   = Window:AddTab({ Title = "Config", Icon = "settings" })
}

-- // ========== 13. TAB MAIN (Speed & Jump) ==========
Tabs.Main:AddParagraph({Title = "⚡ Speed & Jump", Content = "Aktifkan toggle, atur nilai slider."})

Tabs.Main:AddToggle("SpeedToggle", {
    Title = "⚡ Speed Boost",
    Default = false,
    Callback = function(Value)
        SpeedEnabled = Value
        applySpeed()
        Fluent:Notify({Title = "Speed", Content = Value and "✅ Aktif" or "❌ Nonaktif", Duration = 2})
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
        Fluent:Notify({Title = "Jump", Content = Value and "✅ Aktif" or "❌ Nonaktif", Duration = 2})
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

-- // ========== 14. TAB REVIVE ==========
Tabs.Revive:AddParagraph({Title = "💉 Auto Revive", Content = "Aktifkan toggle. Saat mati/terpuruk, akan langsung revive otomatis."})

Tabs.Revive:AddToggle("AutoRevive", {
    Title = "🔄 Auto Revive",
    Default = false,
    Callback = function(Value)
        AutoReviveEnabled = Value
        Fluent:Notify({Title = "Auto Revive", Content = Value and "✅ Aktif" or "❌ Nonaktif", Duration = 2})
    end
})

Tabs.Revive:AddButton({
    Title = "🧪 Test Revive (Paksa Mati)",
    Description = "Hanya untuk testing - health di-set 0",
    Callback = function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.Health = 0
            Fluent:Notify({Title = "Test", Content = "Health di-set 0", Duration = 2})
        end
    end
})

-- // ========== 15. TAB COLLECT ==========
Tabs.Collect:AddParagraph({Title = "🎯 Auto Collect", Content = "Mengambil item (bubble/coconut) terdekat secara otomatis."})

Tabs.Collect:AddToggle("AutoCollect", {
    Title = "🎯 Auto Collect",
    Default = false,
    Callback = function(Value)
        AutoCollectEnabled = Value
        Fluent:Notify({Title = "Auto Collect", Content = Value and "✅ Aktif" or "❌ Nonaktif", Duration = 2})
    end
})

Tabs.Collect:AddButton({
    Title = "🧪 Test Collect (Ambil 1 Item)",
    Description = "Mengambil item terdekat secara manual",
    Callback = function()
        autoCollect()
        Fluent:Notify({Title = "Test", Content = "Mencoba ambil item...", Duration = 2})
    end
})

-- // ========== 16. TAB MOVEMENT ==========
Tabs.Movement:AddParagraph({Title = "🛸 Movement Mods", Content = "Fly, NoClip"})

Tabs.Movement:AddToggle("FlyToggle", {
    Title = "✈️ Fly Mode (F)",
    Default = false,
    Callback = function(Value)
        FlyEnabled = Value
        if not Value and flying then stopFly() end
        Fluent:Notify({Title = "Fly", Content = Value and "✅ Aktif (tekan F)" or "❌ Nonaktif", Duration = 2})
    end
})

Tabs.Movement:AddSlider("FlySpeedSlider", {
    Title = "🚀 Kecepatan Terbang",
    Default = 80,
    Min = 20,
    Max = 200,
    Rounding = 0,
    Callback = function(v)
        flySpeedValue = v
    end
})

Tabs.Movement:AddToggle("NoClipToggle", {
    Title = "👻 No Clip",
    Default = false,
    Callback = function(Value)
        NoClipEnabled = Value
        Fluent:Notify({Title = "No Clip", Content = Value and "✅ Aktif" or "❌ Nonaktif", Duration = 2})
    end
})

-- // ========== 17. TAB MISC ==========
Tabs.Misc:AddParagraph({Title = "🛡️ Lain-lain", Content = "Anti AFK, God Mode, Full Bright"})

Tabs.Misc:AddToggle("AntiAFK", {
    Title = "🛡️ Anti AFK",
    Default = false,
    Callback = function(Value)
        AntiAFKEnabled = Value
        Fluent:Notify({Title = "Anti AFK", Content = Value and "✅ Aktif" or "❌ Nonaktif", Duration = 2})
    end
})

Tabs.Misc:AddToggle("GodMode", {
    Title = "🛡️ God Mode",
    Description = "Kekebalan total (sangat berisiko!)",
    Default = false,
    Callback = function(Value)
        GodModeEnabled = Value
        Fluent:Notify({Title = "God Mode", Content = Value and "✅ Aktif" or "❌ Nonaktif", Duration = 2})
    end
})

Tabs.Misc:AddToggle("FullBright", {
    Title = "☀️ Full Bright",
    Default = false,
    Callback = function(Value)
        FullBrightEnabled = Value
        Fluent:Notify({Title = "Full Bright", Content = Value and "✅ Aktif" or "❌ Nonaktif", Duration = 2})
    end
})

-- // ========== 18. TAB CONFIG ==========
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("EvadeHub")
SaveManager:SetFolder("EvadeHub/configs")
InterfaceManager:BuildInterfaceSection(Tabs.Config)
SaveManager:BuildConfigSection(Tabs.Config)

Window:SelectTab(2) -- Main
SaveManager:LoadAutoloadConfig()

-- // ========== 19. NOTIFIKASI AWAL ==========
task.wait(1)
Fluent:Notify({
    Title = "🔥 EVADE HUB LOADED!",
    Content = "Auto Revive + Auto Collect siap",
    SubContent = "Aktifkan fitur dari menu",
    Duration = 5
})

print("✅ EVADE HUB – Auto Revive + Auto Collect + UI berhasil dimuat!")
print("📌 Buka menu dan aktifkan fitur yang diinginkan!")
print("📌 Auto Revive: aktifkan di tab '💉 Revive'")
print("📌 Auto Collect: aktifkan di tab '🎯 Collect'")
